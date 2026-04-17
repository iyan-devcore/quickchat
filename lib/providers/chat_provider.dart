import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/encryption_service.dart';

/// Manages all chat-related state: conversations list, messages, and real-time updates.
///
/// Flow:
/// 1. [init] is called after login with the API service and current user ID
/// 2. [loadConversations] fetches the user's chat list from the backend
/// 3. [loadMessages] fetches history from MongoDB when entering a chat
/// 4. Socket listeners handle real-time incoming messages and typing indicators
///
/// Offline Message Strategy:
/// - All messages are saved to MongoDB server-side before broadcasting
/// - When a user logs in, conversations + last messages are fetched via REST API
/// - When entering a chat, the last 50 messages are fetched via REST API
/// - After the initial fetch, new messages arrive via Socket.io in real-time
class ChatProvider with ChangeNotifier {
  List<Chat> _chats = [];
  final Map<String, List<Message>> _messageCache = {};
  final Set<String> _onlineUsers = {};
  String? _typingUserId;
  String? _typingRoomId;
  bool _isLoading = false;
  final Map<String, String> _userPublicKeyCache = {}; // Cache for userId -> publicKey
  final Map<String, String> _userNameCache = {}; // Cache for userId -> name
  final Map<String, SecretKey> _groupKeys = {}; // Cache for roomId -> decrypted group key

  ApiService? _apiService;
  SocketService? _socketService;
  EncryptionService? _encryptionService;
  String? _currentUserId;

  // ── Getters ──
  List<Chat> get chats => [..._chats];
  bool get isLoading => _isLoading;

  /// Get cached messages for a specific room.
  List<Message> getMessages(String roomId) {
    return _messageCache[roomId] ?? [];
  }

  /// Get a single message by ID
  Message? getMessageById(String roomId, String messageId) {
    if (!_messageCache.containsKey(roomId)) return null;
    try {
      return _messageCache[roomId]!.firstWhere((m) => m.id == messageId);
    } catch (_) {
      return null;
    }
  }

  /// Check if a user is currently online.
  bool isUserOnline(String userId) => _onlineUsers.contains(userId);

  /// Get the typing user ID for a specific room (null if no one is typing).
  String? getTypingUserId(String roomId) {
    return _typingRoomId == roomId ? _typingUserId : null;
  }

  /// Initialize the chat provider with the authenticated API service.
  ///
  /// Called once after login. Sets up socket listeners and loads conversations.
  void init(ApiService apiService, SocketService socketService, EncryptionService encryptionService, String currentUserId) {
    _apiService = apiService;
    _socketService = socketService;
    _encryptionService = encryptionService;
    _currentUserId = currentUserId;

    // Set up socket event listeners
    _setupSocketListeners();

    // Load the user's conversations and groups
    loadConversations();
  }

  /// Set up Socket.io event listeners for real-time updates.
  void _setupSocketListeners() {
    if (_socketService == null) return;

    // Clear any previous listeners to avoid duplicates
    _socketService!.clearListeners();

    // ── New message received ──
    _socketService!.onNewMessage((data) async {
      Message message = Message.fromJson(data);
      message = await _decryptMessage(message);
      _handleNewMessage(message);
    });

    // ── User came online ──
    _socketService!.onUserOnline((userId) {
      _onlineUsers.add(userId);
      // Update the chat list to reflect online status
      _updateUserOnlineStatus(userId, true);
      notifyListeners();
    });

    // ── User went offline ──
    _socketService!.onUserOffline((data) {
      final userId = data['userId'].toString();
      final lastSeenStr = data['lastSeen']?.toString();
      final lastSeen = lastSeenStr != null ? DateTime.tryParse(lastSeenStr)?.toLocal() : null;
      
      _onlineUsers.remove(userId);
      _updateUserOnlineStatus(userId, false, lastSeen: lastSeen);
      notifyListeners();
    });

    // ── Typing indicator ──
    _socketService!.onTyping((data) {
      _typingUserId = data['userId']?.toString();
      final isTyping = data['isTyping'] == true;
      if (isTyping) {
        // Determine which room the typing event is for
        // The typing event is emitted to the room, so we need to find it
        _typingRoomId = _findRoomForUser(_typingUserId!);
      } else {
        _typingUserId = null;
        _typingRoomId = null;
      }
      notifyListeners();
    });

    // ── Message deleted ──
    _socketService!.onMessageDeleted((data) {
      final roomId = data['roomId'].toString();
      final messageId = data['messageId'].toString();
      _handleMessageDeleted(roomId, messageId);
    });

    // ── Message edited ──
    _socketService!.onMessageEdited((data) async {
      final roomId = data['roomId'].toString();
      final messageId = data['messageId'].toString();
      final newContent = data['newContent'].toString();
      final iv = data['iv']?.toString();
      final mac = data['mac']?.toString();
      
      await _handleMessageEdited(roomId, messageId, newContent, iv: iv, mac: mac);
    });
  }

  void _handleMessageDeleted(String roomId, String messageId) {
    if (_messageCache.containsKey(roomId)) {
      final index = _messageCache[roomId]!.indexWhere((m) => m.id == messageId);
      if (index >= 0) {
        _messageCache[roomId]![index] = _messageCache[roomId]![index].copyWith(
          isDeleted: true,
          content: 'This message was deleted',
          isEncrypted: false,
        );
        notifyListeners();
      }
    }
  }

  Future<void> _handleMessageEdited(String roomId, String messageId, String newContent, {String? iv, String? mac}) async {
    if (_messageCache.containsKey(roomId)) {
      final index = _messageCache[roomId]!.indexWhere((m) => m.id == messageId);
      if (index >= 0) {
        var msg = _messageCache[roomId]![index].copyWith(
          content: newContent,
          isEdited: true,
          iv: iv ?? _messageCache[roomId]![index].iv,
          mac: mac ?? _messageCache[roomId]![index].mac,
        );
        msg = await _decryptMessage(msg);
        _messageCache[roomId]![index] = msg;
        notifyListeners();
      }
    }
  }

  /// Handle a newly received message (from socket).
  ///
  /// 1. Add to the message cache for the room
  /// 2. Update (or create) the conversation in the chat list
  /// 3. Move the conversation to the top
  void _handleNewMessage(Message message) {
    final roomId = message.roomId;

    // Add message to room cache
    if (_messageCache.containsKey(roomId)) {
      // Avoid duplicates (message might already exist from send)
      final exists = _messageCache[roomId]!.any((m) => m.id == message.id);
      if (!exists) {
        _messageCache[roomId]!.add(message);
      }
    } else {
      _messageCache[roomId] = [message];
    }

    // Update or create the conversation in the chat list
    final chatIndex = _chats.indexWhere((c) => c.id == roomId);
    if (chatIndex >= 0) {
      // Update existing conversation with new last message
      final existingChat = _chats[chatIndex];
      final updatedMessages = [...existingChat.messages];

      // Replace or add the last message for preview
      if (updatedMessages.isNotEmpty) {
        updatedMessages[updatedMessages.length - 1] = message;
      } else {
        updatedMessages.add(message);
      }

      final updatedChat = existingChat.copyWith(
        messages: [message], // Only keep last message for the list preview
        unreadCount: message.senderId != _currentUserId
            ? existingChat.unreadCount + 1
            : existingChat.unreadCount,
      );

      _chats[chatIndex] = updatedChat;

      // Move to top of list
      final chat = _chats.removeAt(chatIndex);
      _chats.insert(0, chat);
    }
    else {
      loadConversations();
    }

    notifyListeners();
  }

  /// Add users to the public key cache.
  void _updateUserCache(List<dynamic> users) {
    for (final userJson in users) {
      final id = (userJson['id'] ?? userJson['_id']).toString();
      final publicKey = userJson['publicKey']?.toString();
      final name = userJson['name']?.toString();
      
      if (publicKey != null && publicKey.isNotEmpty) {
        _userPublicKeyCache[id] = publicKey;
      }
      if (name != null) {
        _userNameCache[id] = name;
      }
    }
  }

  /// Get the sender name for a message.
  String? getSenderName(String userId) {
    return _userNameCache[userId];
  }

  /// Update the online status of a user in the chat list.
  void _updateUserOnlineStatus(String userId, bool isOnline, {DateTime? lastSeen}) {
    for (int i = 0; i < _chats.length; i++) {
      if (_chats[i].otherUser?.id == userId) {
        _chats[i] = _chats[i].copyWith(
          otherUser: _chats[i].otherUser!.copyWith(
            isOnline: isOnline,
            lastSeen: lastSeen ?? _chats[i].otherUser?.lastSeen,
          ),
        );
      }
    }
  }

  /// Get the last seen time of a user from the chat list.
  DateTime? getUserLastSeen(String userId) {
    for (final chat in _chats) {
      if (chat.otherUser?.id == userId) {
        return chat.otherUser?.lastSeen;
      }
    }
    return null;
  }

  /// Find the room ID for a 1-on-1 conversation with a given user.
  String? _findRoomForUser(String userId) {
    for (final chat in _chats) {
      if (chat.otherUser?.id == userId) {
        return chat.id;
      }
    }
    return null;
  }

  /// Generate a deterministic room ID from two user IDs.
  ///
  /// The IDs are sorted alphabetically and joined with '_' to ensure
  /// both users always compute the same room ID.
  static String generateRoomId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  // ─────────────────────────────────────────
  // API-backed data loading
  // ─────────────────────────────────────────

  /// Load all conversations for the current user from the backend.
  Future<void> loadConversations() async {
    if (_apiService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch group keys first (as they are needed for preview decryption)
      await _loadGroupKeys();

      // 2. Fetch conversations
      final data = await _apiService!.getConversations();
      _chats = data.map((json) => Chat.fromConversationJson(json)).toList();

      // Update public key cache from conversation users
      for (final json in data) {
        if (json['user'] != null) {
          _updateUserCache([json['user']]);
        }
      }

      // Track online users from conversation data
      for (final chat in _chats) {
        if (chat.otherUser?.isOnline == true) {
          _onlineUsers.add(chat.otherUser!.id);
        }
      }
    } catch (e) {
      print('Error loading conversations: $e');
    }

    _isLoading = false;
    _isLoading = false;
    notifyListeners();
  }

  /// Create a new encrypted group.
  Future<void> createGroup({
    required String name,
    required String description,
    required List<User> members,
  }) async {
    if (_apiService == null || _encryptionService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Generate a random group key
      final groupKey = await _encryptionService!.generateGroupKey();

      // 2. Wrap the key for every member (including self)
      final membersData = <Map<String, dynamic>>[];
      
      // Ensure current user is in members list for key wrapping
      // (Though usually they are already selected)
      
      for (final member in members) {
        if (member.publicKey.isEmpty) continue;
        
        final encryptedKey = await _encryptionService!.encryptGroupKey(
          groupKey: groupKey,
          recipientPublicKey: member.publicKey,
        );
        
        membersData.add({
          'userId': member.id,
          'encryptedKey': encryptedKey,
          'isAdmin': member.id == _currentUserId,
        });
      }

      // 3. Send to server
      final groupData = await _apiService!.createGroup(
        name: name,
        description: description,
        members: membersData,
      );

      // 4. Save the group key in memory
      final groupId = groupData['_id'] ?? groupData['id'];
      _groupKeys[groupId.toString()] = groupKey;

      // 5. Reload conversations to show the new group
      await loadConversations();
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all groups and decrypt their group keys.
  Future<void> _loadGroupKeys() async {
    if (_apiService == null || _encryptionService == null) return;

    try {
      final groups = await _apiService!.getGroups();
      
      for (final groupJson in groups) {
        final roomId = groupJson['id'].toString();
        final encryptedKey = groupJson['myEncryptedKey']?.toString();
        
        if (encryptedKey != null && encryptedKey.isNotEmpty) {
          // We need the creator's public key to decrypt? 
          // No, wait, in my EncryptionService.decryptGroupKey, 
          // it uses the sender's public key. 
          // But I'm the recipient! I use the creator's public key.
          
          final creatorId = groupJson['creatorId'].toString();
          
          // Try to find creator's public key
          String? creatorPublicKey;
          final creator = (groupJson['members'] as List).firstWhere(
            (m) => (m['id'] ?? m['_id']).toString() == creatorId,
            orElse: () => null,
          );
          
          if (creator != null) {
            creatorPublicKey = creator['publicKey'];
          }

          if (creatorPublicKey != null && creatorPublicKey.isNotEmpty) {
            try {
              final groupKey = await _encryptionService!.decryptGroupKey(
                encryptedGroupKeyPacked: encryptedKey,
                senderPublicKey: creatorPublicKey,
              );
              _groupKeys[roomId] = groupKey;
            } catch (e) {
              print('Failed to decrypt group key for $roomId: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error loading group keys: $e');
    }
  }

  /// Load message history for a specific room from the backend.
  ///
  /// Called when entering a ChatScreen. Fetches the last 50 messages
  /// from MongoDB, then socket takes over for new real-time messages.
  Future<void> loadMessages(String roomId) async {
    if (_apiService == null) return;

    try {
      final data = await _apiService!.getMessages(roomId);
      final messages = data.map((json) => Message.fromJson(json)).toList();
      
      // Decrypt messages
      final decryptedMessages = <Message>[];
      for (var msg in messages) {
        decryptedMessages.add(await _decryptMessage(msg));
      }
      
      _messageCache[roomId] = decryptedMessages;
      notifyListeners();
    } catch (e) {
      print('Error loading messages for $roomId: $e');
    }
  }

  /// Send a message to a room via Socket.io.
  Future<void> sendMessage(String roomId, String content, {String? otherUserId, bool isGroup = false, String type = 'text', String? replyTo}) async {
    if (_socketService == null || _encryptionService == null || content.trim().isEmpty) return;

    if (isGroup) {
      final groupKey = _groupKeys[roomId];
      if (groupKey != null) {
        try {
          final encryptedData = await _encryptionService!.encryptGroupMessage(
            message: content.trim(),
            groupKey: groupKey,
          );

          _socketService!.sendMessage(
            roomId,
            encryptedData['ciphertext']!,
            iv: encryptedData['nonce'],
            mac: encryptedData['mac'],
            isEncrypted: true,
            type: type,
            replyTo: replyTo,
          );
          return;
        } catch (e) {
          print('Group encryption failed: $e');
        }
      }
    } else {
      // 1-on-1 logic...
      // [Previous implementation continued but I'll update it here]
      String? recipientPublicKey;
      if (otherUserId != null) {
        recipientPublicKey = _userPublicKeyCache[otherUserId];
      }
      if (recipientPublicKey == null) {
        try {
          final chat = _chats.firstWhere((c) => c.id == roomId);
          recipientPublicKey = chat.otherUser?.publicKey;
        } catch (_) {}
      }

      if (recipientPublicKey != null && recipientPublicKey.isNotEmpty) {
        try {
          final encryptedData = await _encryptionService!.encryptMessage(
            message: content.trim(),
            recipientPublicKey: recipientPublicKey,
          );

          _socketService!.sendMessage(
            roomId,
            encryptedData['ciphertext']!,
            iv: encryptedData['nonce'],
            mac: encryptedData['mac'],
            isEncrypted: true,
            type: type,
          );
          return;
        } catch (e) {
          print('1-on-1 encryption failed: $e');
        }
      }
    }

    // Fallback: send unencrypted
    _socketService!.sendMessage(roomId, content.trim(), isEncrypted: false, type: type, replyTo: replyTo);
  }

  void deleteMessage(String messageId, String roomId) {
    _socketService?.deleteMessage(messageId, roomId);
    _handleMessageDeleted(roomId, messageId);
  }

  Future<void> editMessage(String messageId, String roomId, String newContent, {String? otherUserId, bool isGroup = false}) async {
    if (_socketService == null || _encryptionService == null || newContent.trim().isEmpty) return;

    String? finalContent = newContent.trim();
    String? iv;
    String? mac;

    // Encrypt updated message if necessary
    if (isGroup) {
      final groupKey = _groupKeys[roomId];
      if (groupKey != null) {
        try {
          final encryptedData = await _encryptionService!.encryptGroupMessage(
            message: finalContent,
            groupKey: groupKey,
          );
          finalContent = encryptedData['ciphertext']!;
          iv = encryptedData['nonce'];
          mac = encryptedData['mac'];
        } catch (e) {
          print('Group encryption failed: $e');
        }
      }
    } else {
      String? recipientPublicKey;
      if (otherUserId != null) {
        recipientPublicKey = _userPublicKeyCache[otherUserId];
      }
      if (recipientPublicKey == null) {
        try {
          final chat = _chats.firstWhere((c) => c.id == roomId);
          recipientPublicKey = chat.otherUser?.publicKey;
        } catch (_) {}
      }

      if (recipientPublicKey != null && recipientPublicKey.isNotEmpty) {
        try {
          final encryptedData = await _encryptionService!.encryptMessage(
            message: finalContent,
            recipientPublicKey: recipientPublicKey,
          );
          finalContent = encryptedData['ciphertext']!;
          iv = encryptedData['nonce'];
          mac = encryptedData['mac'];
        } catch (e) {
          print('1-on-1 encryption failed: $e');
        }
      }
    }

    _socketService!.editMessage(messageId, roomId, finalContent, iv: iv, mac: mac);

    // Optimistically update UI
    if (_messageCache.containsKey(roomId)) {
      final index = _messageCache[roomId]!.indexWhere((m) => m.id == messageId);
      if (index >= 0) {
        _messageCache[roomId]![index] = _messageCache[roomId]![index].copyWith(
          content: newContent.trim(),
          isEdited: true,
        );
        notifyListeners();
      }
    }
  }

  /// Decrypt a message if it's encrypted.
  Future<Message> _decryptMessage(Message message) async {
    if (!message.isEncrypted || _encryptionService == null) return message;

    String? decryptedContent;

    if (message.isGroup) {
      final groupKey = _groupKeys[message.roomId];
      if (groupKey != null && message.iv != null && message.mac != null) {
        decryptedContent = await _encryptionService!.decryptGroupMessage(
          ciphertext: message.content,
          nonce: message.iv!,
          mac: message.mac!,
          groupKey: groupKey,
        );
      }
    } else {
      // Find the original sender's public key
      String? senderPublicKey = _userPublicKeyCache[message.senderId];

      if (senderPublicKey == null) {
        // Fallback: check chat list
        try {
          final chat = _chats.firstWhere((c) => c.id == message.roomId);
          senderPublicKey = chat.otherUser?.publicKey;
        } catch (_) {}
      }

      if (senderPublicKey != null && senderPublicKey.isNotEmpty && message.iv != null && message.mac != null) {
        decryptedContent = await _encryptionService!.decryptMessage(
          ciphertext: message.content,
          nonce: message.iv!,
          mac: message.mac!,
          senderPublicKey: senderPublicKey,
        );
      }
    }

    if (decryptedContent == null) return message;

    return Message(
      id: message.id,
      roomId: message.roomId,
      senderId: message.senderId,
      content: decryptedContent,
      timestamp: message.timestamp,
      type: message.type,
      status: message.status,
      iv: message.iv,
      mac: message.mac,
      isEncrypted: message.isEncrypted,
      isGroup: message.isGroup,
    );
  }

  /// Send a typing indicator.
  void sendTyping(String roomId, bool isTyping) {
    _socketService?.sendTyping(roomId, isTyping);
  }

  /// Join a chat room to receive real-time messages.
  void joinRoom(String roomId) {
    _socketService?.joinRoom(roomId);
  }

  /// Clear a conversation's unread count (when user opens the chat).
  void clearUnread(String roomId) {
    final index = _chats.indexWhere((c) => c.id == roomId);
    if (index >= 0) {
      _chats[index] = _chats[index].copyWith(unreadCount: 0);
      notifyListeners();
    }
  }

  /// Delete a conversation from the local list.
  void deleteChat(String chatId) {
    _chats.removeWhere((c) => c.id == chatId);
    _messageCache.remove(chatId);
    notifyListeners();
  }

  /// Reset all state (called on logout).
  void reset() {
    _chats = [];
    _messageCache.clear();
    _onlineUsers.clear();
    _userPublicKeyCache.clear();
    _userNameCache.clear();
    _groupKeys.clear();
    _typingUserId = null;
    _typingRoomId = null;
    _apiService = null;
    _socketService = null;
    _encryptionService = null;
    _currentUserId = null;
    notifyListeners();
  }
}
