import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

/// Singleton service managing the Socket.io WebSocket connection.
///
/// Lifecycle:
/// 1. [connect] — Called after login with the JWT token
/// 2. [joinRoom] — Called when entering a chat screen
/// 3. [sendMessage] — Called when the user sends a message
/// 4. [disconnect] — Called on logout
///
/// The server authenticates the socket using the JWT token passed
/// during the handshake. All messages are persisted server-side
/// to MongoDB before being broadcast, ensuring offline delivery.
class SocketService {
  // Singleton pattern — one socket connection per app session
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  /// Whether the socket is currently connected
  bool get isConnected => _socket?.connected ?? false;

  /// The underlying socket instance (for advanced usage)
  IO.Socket? get socket => _socket;

  /// Connect to the Socket.io server with JWT authentication.
  ///
  /// [token] — The JWT token obtained from login/register.
  /// This is sent in the handshake auth payload and verified server-side.
  void connect(String token) {
    // Disconnect any existing connection first
    disconnect();

    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Use WebSocket transport only (no polling)
          .disableAutoConnect()         // We'll connect manually after setup
          .setAuth({'token': token})    // JWT sent during handshake
          .build(),
    );

    _socket!.connect();

    // ── Connection lifecycle logging ──
    _socket!.onConnect((_) {
      print('🔌 Socket connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      print('🔌 Socket disconnected');
    });

    _socket!.onConnectError((error) {
      print('🔌 Socket connection error: $error');
    });

    _socket!.onError((error) {
      print('🔌 Socket error: $error');
    });
  }

  /// Join a chat room to receive messages for that conversation.
  ///
  /// [roomId] — The deterministic room ID (sorted user ID pair).
  /// Must be called when navigating to a ChatScreen.
  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  /// Mark all messages from other users in the room as read
  void markRoomRead(String roomId) {
    _socket?.emit('mark_room_read', {'roomId': roomId});
  }

  /// Send a text message to a chat room.
  ///
  /// The server will:
  /// 1. Save the message to MongoDB
  /// 2. Broadcast it to all users in the room via 'receive_message'
  void sendMessage(
    String roomId,
    String content, {
    String type = 'text',
    String? iv,
    String? mac,
    bool isEncrypted = false,
    bool isGroup = false,
    String? replyTo,
    String? fileName,
    int? fileSize,
  }) {
    _socket?.emit('send_message', {
      'roomId': roomId,
      'content': content,
      'type': type,
      'iv': iv,
      'mac': mac,
      'isEncrypted': isEncrypted,
      'isGroup': isGroup,
      'replyTo': replyTo,
      'fileName': fileName,
      'fileSize': fileSize,
    });
  }

  /// Send a typing indicator to a chat room.
  void sendTyping(String roomId, bool isTyping) {
    _socket?.emit('typing', {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }

  void toggleReaction(String roomId, String messageId, String emoji) {
    _socket?.emit('toggle_reaction', {
      'roomId': roomId,
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  /// Listen for incoming messages in any joined room.
  ///
  /// [callback] receives the message data as a Map containing:
  /// id, roomId, senderId, content, type, status, timestamp
  void onNewMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('receive_message', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen for typing indicators from other users.
  void onTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on('user_typing', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen for a user coming online.
  void onUserOnline(Function(String userId) callback) {
    _socket?.on('user_online', (data) {
      callback(data['userId'].toString());
    });
  }

  /// Listen for a user going offline.
  void onUserOffline(Function(Map<String, dynamic> data) callback) {
    _socket?.on('user_offline', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen for read receipts.
  void onRoomMessagesRead(Function(Map<String, dynamic> data) callback) {
    _socket?.on('room_messages_read', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen for reaction updates.
  void onMessageReactionUpdated(Function(Map<String, dynamic> data) callback) {
    _socket?.on('message_reaction_updated', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void deleteMessage(String messageId, String roomId) {
    _socket?.emit('delete_message', {
      'messageId': messageId,
      'roomId': roomId,
    });
  }

  void editMessage(String messageId, String roomId, String newContent, {String? iv, String? mac}) {
    _socket?.emit('edit_message', {
      'messageId': messageId,
      'roomId': roomId,
      'newContent': newContent,
      'iv': iv,
      'mac': mac,
    });
  }

  void onMessageDeleted(Function(Map<String, dynamic> data) callback) {
    _socket?.on('message_deleted', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onMessageEdited(Function(Map<String, dynamic> data) callback) {
    _socket?.on('message_edited', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  // ─────────────────────────────────────────
  // WebRTC Calling Signaling
  // ─────────────────────────────────────────

  void callUser(String userToCall, Map<String, dynamic> signalData, String callerName, bool isVideo) {
    _socket?.emit('call_user', {
      'userToCall': userToCall,
      'signalData': signalData,
      'callerName': callerName,
      'isVideo': isVideo,
    });
  }

  void answerCall(String to, Map<String, dynamic> signalData) {
    _socket?.emit('answer_call', {
      'to': to,
      'signal': signalData,
    });
  }

  void sendIceCandidate(String to, Map<String, dynamic> candidate) {
    _socket?.emit('ice_candidate', {
      'to': to,
      'candidate': candidate,
    });
  }

  void endCall(String to) {
    _socket?.emit('end_call', {'to': to});
  }

  void rejectCall(String to) {
    _socket?.emit('reject_call', {'to': to});
  }

  void onIncomingCall(Function(Map<String, dynamic> data) callback) {
    _socket?.on('incoming_call', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onCallAnswered(Function(Map<String, dynamic> data) callback) {
    _socket?.on('call_answered', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onIceCandidate(Function(Map<String, dynamic> data) callback) {
    _socket?.on('ice_candidate', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onCallEnded(Function(Map<String, dynamic> data) callback) {
    _socket?.on('call_ended', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onCallRejected(Function(Map<String, dynamic> data) callback) {
    _socket?.on('call_rejected', (data) => callback(Map<String, dynamic>.from(data)));
  }

  /// Remove all event listeners (call before setting up new ones).
  void clearListeners() {
    _socket?.clearListeners();
    
    // Re-attach connection lifecycle handlers after clearing
    _socket?.onConnect((_) {
      print('🔌 Socket reconnected: ${_socket!.id}');
    });
    _socket?.onDisconnect((_) {
      print('🔌 Socket disconnected');
    });
  }

  /// Disconnect from the server and clean up.
  /// Called on logout.
  void disconnect() {
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
