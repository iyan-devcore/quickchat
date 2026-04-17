import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/message_bubble.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../utils/constants.dart';

/// The main chat screen where real-time messaging happens.
///
/// Lifecycle:
/// 1. On mount: joins the socket room and fetches message history from MongoDB
/// 2. During use: new messages arrive via Socket.io in real-time
/// 3. On send: message is emitted via socket → server saves to DB → broadcasts
///
/// This screen receives metadata as constructor parameters instead of
/// looking up from a dummy data list, allowing it to work for both
/// existing and new conversations.
class ChatScreen extends StatefulWidget {
  final String chatId;        // Room ID
  final String chatName;      // Display name
  final String chatAvatarUrl; // Avatar
  final String otherUserId;   // The other user's ID (empty for groups)
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.chatAvatarUrl,
    required this.otherUserId,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  Message? _editingMessage;
  Message? _replyingMessage;

  @override
  void initState() {
    super.initState();
    // Join the room and load message history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // 1. Join the socket room to receive real-time messages
      chatProvider.joinRoom(widget.chatId);

      // 2. Fetch the last 50 messages from MongoDB
      chatProvider.loadMessages(widget.chatId).then((_) {
        // 3. Scroll to bottom after messages are loaded
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Stop typing indicator if user leaves while typing
    if (_isTyping) {
      Provider.of<ChatProvider>(context, listen: false)
          .sendTyping(widget.chatId, false);
    }
    super.dispose();
  }

  /// Send or edit a text message via Socket.io.
  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (_editingMessage != null) {
      Provider.of<ChatProvider>(context, listen: false).editMessage(
        _editingMessage!.id,
        widget.chatId,
        content,
        otherUserId: widget.otherUserId,
        isGroup: widget.isGroup,
      );
      setState(() {
        _editingMessage = null;
      });
    } else {
      Provider.of<ChatProvider>(context, listen: false).sendMessage(
        widget.chatId,
        content,
        otherUserId: widget.otherUserId,
        isGroup: widget.isGroup,
        replyTo: _replyingMessage?.id,
      );
      setState(() {
        _replyingMessage = null;
      });
    }

    _messageController.clear();
    setState(() => _isTyping = false);

    // Send typing stopped indicator
    Provider.of<ChatProvider>(context, listen: false)
        .sendTyping(widget.chatId, false);

    // Scroll to bottom after sending
    _scrollToBottom();
  }

  /// Smooth scroll to the bottom of the message list.
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndUploadFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: type == 'image' ? FileType.image : FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        var fileBytes = result.files.first.bytes;
        var fileName = result.files.first.name;

        if (fileBytes != null) {
          var request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/api/upload'));
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: fileName,
          ));
          var response = await request.send();
          if (response.statusCode == 200) {
            var responseData = await response.stream.bytesToString();
            var json = jsonDecode(responseData);
            var url = json['url'];
            var contentToSend = type == 'file' ? '$url|||$fileName' : url;
            
            Provider.of<ChatProvider>(context, listen: false).sendMessage(
              widget.chatId,
              contentToSend,
              otherUserId: widget.otherUserId,
              isGroup: widget.isGroup,
              type: type,
            );
            
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      print("Upload error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.getMessages(widget.chatId);
        final isOtherUserOnline = chatProvider.isUserOnline(widget.otherUserId);
        final typingUserId = chatProvider.getTypingUserId(widget.chatId);

        // Auto-scroll when new messages arrive
        if (messages.isNotEmpty) {
          _scrollToBottom();
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Refresh conversations when going back (to update last message)
                chatProvider.loadConversations();
                Navigator.of(context).pop();
              },
            ),
            title: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.chatAvatarUrl),
                      radius: 18,
                    ),
                    if (isOtherUserOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.online,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Builder(builder: (context) {
                        String getSubtitle() {
                          if (typingUserId != null) return 'typing...';
                          if (widget.isGroup) return 'Group Chat';
                          if (isOtherUserOnline) return 'Online';
                          
                          final lastSeen = chatProvider.getUserLastSeen(widget.otherUserId);
                          if (lastSeen != null) {
                            // If today, just show time, else show date and time
                            final now = DateTime.now();
                            final isToday = now.year == lastSeen.year && now.month == lastSeen.month && now.day == lastSeen.day;
                            if (isToday) {
                              return 'last seen today at ${DateFormat('hh:mm a').format(lastSeen)}';
                            }
                            return 'last seen ${DateFormat('MMM d, hh:mm a').format(lastSeen)}';
                          }
                          return 'Offline';
                        }
                        
                        return Text(
                          getSubtitle(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: typingUserId != null
                                ? AppColors.secondary
                                : Colors.white70,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
              IconButton(icon: const Icon(Icons.call), onPressed: () {}),
              PopupMenuButton<String>(
                onSelected: (value) {},
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(value: 'search', child: Text('Search')),
                    const PopupMenuItem(value: 'mute', child: Text('Mute notifications')),
                    const PopupMenuItem(value: 'wallpaper', child: Text('Wallpaper')),
                  ];
                },
              ),
            ],
          ),
          body: Container(
            color: isDark ? AppColors.chatBackgroundDark : AppColors.chatBackgroundLight,
            child: Column(
              children: [
                // Message list
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.waving_hand_outlined,
                                size: 64,
                                color: AppColors.textGrey.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Say hello to ${widget.chatName}! 👋',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == currentUser?.id;

                            return Dismissible(
                              key: Key(message.id),
                              direction: DismissDirection.startToEnd,
                              confirmDismiss: (direction) async {
                                if (message.isDeleted) return false;
                                setState(() {
                                  _replyingMessage = message;
                                  _editingMessage = null; // Cancel edit if replying
                                });
                                return false; // snap back
                              },
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child: const Icon(Icons.reply, color: Colors.grey),
                              ),
                              child: MessageBubble(
                                message: message,
                                isMe: isMe,
                                senderName: widget.isGroup ? chatProvider.getSenderName(message.senderId) : null,
                                onLongPress: () {
                                  if (isMe && !message.isDeleted) {
                                    _showMessageOptions(context, message, chatProvider);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
                // Input area
                _buildInputArea(context, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context, bool isDark) {
    return Column(
      children: [
        if (_editingMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.edit, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Editing message',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      _editingMessage = null;
                      _messageController.clear();
                    });
                  },
                ),
              ],
            ),
          )
        else if (_replyingMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.reply, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _replyingMessage!.senderId == currentUser?.id ? 'Replying to yourself' : 'Replying to user',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        _replyingMessage!.type == MessageType.text ? _replyingMessage!.content : 'Attachment',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      _replyingMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.transparent,
          child: Row(
            children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.inputBackgroundDark : AppColors.inputBackgroundLight,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.textGrey),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                      ),
                      onChanged: (val) {
                        final wasTyping = _isTyping;
                        final nowTyping = val.isNotEmpty;

                        if (wasTyping != nowTyping) {
                          setState(() => _isTyping = nowTyping);
                          // Send typing indicator to the other user
                          Provider.of<ChatProvider>(context, listen: false)
                              .sendTyping(widget.chatId, nowTyping);
                        }
                      },
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: AppColors.textGrey),
                    onPressed: () => _pickAndUploadFile('file'),
                  ),
                  if (!_isTyping)
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: AppColors.textGrey),
                      onPressed: () => _pickAndUploadFile('image'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 24,
            child: IconButton(
              icon: Icon(_isTyping ? Icons.send : Icons.mic, color: Colors.white),
              onPressed: _isTyping ? _sendMessage : () {},
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Message message, ChatProvider chatProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.type == MessageType.text)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit message'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _editingMessage = message;
                      _messageController.text = message.content;
                      // Move cursor to end
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length),
                      );
                      _isTyping = true;
                    });
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete for everyone'),
                onTap: () {
                  Navigator.pop(context);
                  chatProvider.deleteMessage(message.id, widget.chatId);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
