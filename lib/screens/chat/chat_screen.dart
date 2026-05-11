import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_prefs_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/message_bubble.dart';
import '../../models/message_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:swipe_to/swipe_to.dart';
import '../../utils/constants.dart';
import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String chatAvatarUrl;
  final String otherUserId;
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

  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.joinRoom(widget.chatId);
      chatProvider.loadMessages(widget.chatId).then((_) => _scrollToBottom());
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_isTyping) {
      Provider.of<ChatProvider>(context, listen: false).sendTyping(widget.chatId, false);
    }
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (_editingMessage != null) {
      Provider.of<ChatProvider>(context, listen: false).editMessage(
        _editingMessage!.id, widget.chatId, content,
        otherUserId: widget.otherUserId, isGroup: widget.isGroup,
      );
      setState(() => _editingMessage = null);
    } else {
      Provider.of<ChatProvider>(context, listen: false).sendMessage(
        widget.chatId, content,
        otherUserId: widget.otherUserId, isGroup: widget.isGroup,
        replyTo: _replyingMessage?.id,
      );
      setState(() => _replyingMessage = null);
    }

    _messageController.clear();
    setState(() => _isTyping = false);
    Provider.of<ChatProvider>(context, listen: false).sendTyping(widget.chatId, false);
    _scrollToBottom();
  }

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
          request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
          var response = await request.send();
          if (response.statusCode == 200) {
            var responseData = await response.stream.bytesToString();
            var json = jsonDecode(responseData);
            var url = json['url'];
            var fileSize = result.files.first.size;
            if (mounted) {
              Provider.of<ChatProvider>(context, listen: false).sendMessage(
                widget.chatId, url,
                otherUserId: widget.otherUserId, isGroup: widget.isGroup,
                type: type, replyTo: _replyingMessage?.id,
                fileName: fileName,
                fileSize: fileSize,
              );
              setState(() => _replyingMessage = null);
              _scrollToBottom();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Upload error: $e");
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      final Directory tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);
      setState(() { _isRecording = true; _recordingSeconds = 0; });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _recordingSeconds++);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission required', style: GoogleFonts.plusJakartaSans(color: Colors.white))),
      );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) _uploadAudio(path);
  }

  Future<void> _uploadAudio(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/api/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        var url = json['url'];
        if (mounted) {
          Provider.of<ChatProvider>(context, listen: false).sendMessage(
            widget.chatId, url,
            otherUserId: widget.otherUserId, isGroup: widget.isGroup,
            type: 'audio', replyTo: _replyingMessage?.id,
          );
          setState(() => _replyingMessage = null);
          _scrollToBottom();
        }
      }
    } catch (e) { debugPrint("Audio upload error: $e"); }
  }

  String _formatDuration(int seconds) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(seconds ~/ 60)}:${two(seconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
    final chatPrefs  = context.watch<ChatPrefsProvider>();

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.getMessages(widget.chatId);
        final isOtherUserOnline = chatProvider.isUserOnline(widget.otherUserId);
        final typingUserId = chatProvider.getTypingUserId(widget.chatId);

        if (messages.isNotEmpty) _scrollToBottom();

        return Scaffold(
          backgroundColor: AppColors.chatBackgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: AppColors.textLight,
              onPressed: () {
                chatProvider.loadConversations();
                Navigator.of(context).pop();
              },
            ),
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.chatAvatarUrl),
                      radius: 19,
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                    if (isOtherUserOnline)
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.online,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.backgroundDark, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textLight,
                        ),
                      ),
                      Builder(builder: (context) {
                        String subtitle() {
                          if (typingUserId != null) return 'typing...';
                          if (widget.isGroup) return 'Group Chat';
                          if (isOtherUserOnline) return 'Online';
                          final lastSeen = chatProvider.getUserLastSeen(widget.otherUserId);
                          if (lastSeen != null) {
                            final now = DateTime.now();
                            final isToday = now.year == lastSeen.year && now.month == lastSeen.month && now.day == lastSeen.day;
                            return isToday
                                ? 'last seen today at ${DateFormat('hh:mm a').format(lastSeen)}'
                                : 'last seen ${DateFormat('MMM d, hh:mm a').format(lastSeen)}';
                          }
                          return 'Offline';
                        }
                        return Text(
                          subtitle(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: typingUserId != null ? AppColors.primary : AppColors.textGrey,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.videocam_rounded, size: 24),
                color: AppColors.textLight,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CallScreen(
                      callerId: currentUser!.id,
                      callerName: currentUser.name,
                      receiverId: widget.otherUserId,
                      isVideo: true,
                    ),
                  ));
                },
              ),
              IconButton(
                icon: const Icon(Icons.call_rounded, size: 22),
                color: AppColors.textLight,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CallScreen(
                      callerId: currentUser!.id,
                      callerName: currentUser.name,
                      receiverId: widget.otherUserId,
                      isVideo: false,
                    ),
                  ));
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textLight),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (_) {},
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'search', child: Text('Search', style: GoogleFonts.plusJakartaSans(color: Colors.white))),
                  PopupMenuItem(value: 'mute', child: Text('Mute notifications', style: GoogleFonts.plusJakartaSans(color: Colors.white))),
                  PopupMenuItem(value: 'wallpaper', child: Text('Wallpaper', style: GoogleFonts.plusJakartaSans(color: Colors.white))),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _buildChatBackground(
                  chatPrefs,
                  child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20)],
                              ),
                              child: const Icon(Icons.waving_hand_rounded, size: 36, color: Colors.white),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Say hi to ${widget.chatName}! 👋',
                              style: GoogleFonts.plusJakartaSans(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUser?.id;
                          return SwipeTo(
                            key: Key(message.id),
                            iconOnRightSwipe: Icons.reply_rounded,
                            iconOnLeftSwipe: Icons.reply_rounded,
                            iconColor: AppColors.primary,
                            onRightSwipe: (details) {
                              if (message.isDeleted) return;
                              setState(() { _replyingMessage = message; _editingMessage = null; });
                            },
                            onLeftSwipe: (details) {
                              if (message.isDeleted) return;
                              setState(() { _replyingMessage = message; _editingMessage = null; });
                            },
                            child: MessageBubble(
                              message: message,
                              isMe: isMe,
                              senderName: widget.isGroup ? chatProvider.getSenderName(message.senderId) : null,
                              bubbleColor: isMe ? chatPrefs.myBubbleColor : null,
                              onLongPress: () {
                                if (!message.isDeleted) _showMessageOptions(context, message, chatProvider, isMe);
                              },
                            ),
                          );
                        },
                      ),
                ),
              ),
              _buildInputArea(context),
            ],
          ),
        );
      },
    );
  }

  /// Wraps [child] in the appropriate wallpaper background.
  Widget _buildChatBackground(ChatPrefsProvider prefs, {required Widget child}) {
    switch (prefs.wallpaperType) {
      case WallpaperType.gradient:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: ChatPrefsProvider.gradients[prefs.wallpaperGradientIndex],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      case WallpaperType.image:
        if (prefs.wallpaperImagePath != null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(prefs.wallpaperImagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
              child,
            ],
          );
        }
        return child;
      default:
        return child;
    }
  }

  Widget _buildInputArea(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
    return Container(
      color: AppColors.backgroundDark,
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Column(
        children: [
          if (_editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Editing message', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600))),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                    onPressed: () => setState(() { _editingMessage = null; _messageController.clear(); }),
                  ),
                ],
              ),
            )
          else if (_replyingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyingMessage!.senderId == currentUser?.id ? 'Replying to yourself' : 'Replying',
                          style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        Text(
                          _replyingMessage!.type == MessageType.text ? _replyingMessage!.content : 'Attachment',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                    onPressed: () => setState(() => _replyingMessage = null),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputBackgroundDark,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _isRecording
                        ? Row(
                            children: [
                              const SizedBox(width: 20),
                              const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Recording... ${_formatDuration(_recordingSeconds)}',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, color: AppColors.textGrey, size: 22),
                                onPressed: () async {
                                  _recordingTimer?.cancel();
                                  await _audioRecorder.stop();
                                  setState(() => _isRecording = false);
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.emoji_emotions_outlined, size: 24),
                                color: AppColors.textGrey,
                                onPressed: () {},
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    hintText: 'Message...',
                                    hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textGrey, fontSize: 15),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onChanged: (val) {
                                    final nowTyping = val.isNotEmpty;
                                    if (_isTyping != nowTyping) {
                                      setState(() => _isTyping = nowTyping);
                                      Provider.of<ChatProvider>(context, listen: false).sendTyping(widget.chatId, nowTyping);
                                    }
                                  },
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.attach_file_rounded, size: 22),
                                color: AppColors.textGrey,
                                onPressed: () => _pickAndUploadFile('file'),
                              ),
                              if (!_isTyping)
                                IconButton(
                                  icon: const Icon(Icons.camera_alt_rounded, size: 22),
                                  color: AppColors.textGrey,
                                  onPressed: () => _pickAndUploadFile('image'),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : (_isTyping ? _sendMessage : _startRecording),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : (_isTyping ? Icons.send_rounded : Icons.mic_rounded),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Message message, ChatProvider chatProvider, bool isMe) {
    final List<String> emojis = ['❤️', '😂', '👍', '😮', '😢', '👏'];
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reaction Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: emojis.map((emoji) => GestureDetector(
                    onTap: () {
                      chatProvider.toggleReaction(message.roomId, message.id, emoji);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Options Menu
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMe && message.type == MessageType.text)
                      ListTile(
                        leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
                        title: Text('Edit message', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _editingMessage = message;
                            _messageController.text = message.content;
                            _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
                            _isTyping = true;
                          });
                        },
                      ),
                    if (isMe && message.type == MessageType.text)
                      const Divider(height: 1, color: AppColors.dividerDark),
                    if (isMe)
                      ListTile(
                        leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                        title: Text('Delete for everyone', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                        onTap: () {
                          Navigator.pop(context);
                          chatProvider.deleteMessage(message.id, message.roomId);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
