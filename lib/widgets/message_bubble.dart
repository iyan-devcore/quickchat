import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/message_model.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'audio_player_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String? senderName;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderName,
    this.onLongPress,
  });

  List<Widget> _buildReactionsWidgets(Map<String, String> reactions) {
    if (reactions.isEmpty) return [];
    Map<String, int> counts = {};
    for (var emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    List<Widget> widgets = [];
    counts.forEach((emoji, count) {
      widgets.add(Text(count > 1 ? '$emoji $count' : emoji, style: const TextStyle(fontSize: 12)));
      widgets.add(const SizedBox(width: 4));
    });
    if (widgets.isNotEmpty) widgets.removeLast();
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    var extractedUrl = message.content;
    var displayFileName = "File Attachment";

    if (message.type == MessageType.file && message.content.contains('|||')) {
      var parts = message.content.split('|||');
      extractedUrl = parts[0];
      displayFileName = parts[1];
    } else if (message.type == MessageType.file) {
      displayFileName = message.content.split('/').last;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final repliedMessage = message.replyTo != null
        ? chatProvider.getMessageById(message.roomId, message.replyTo!)
        : null;

    // Snapchat bubble colors
    final Color bubbleColor = message.isDeleted
        ? Colors.grey.withOpacity(0.3)
        : isMe
            ? AppColors.myMessageBubble   // Yellow for sent
            : AppColors.otherMessageBubble; // Grey for received

    final Color textColor = isMe ? AppColors.snapBlack : AppColors.snapBlack;
    final Color subtitleColor = isMe
        ? AppColors.snapBlack.withOpacity(0.5)
        : AppColors.textGrey;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 2),
                child: Text(
                  senderName!,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Reply preview
                      if (repliedMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: isMe
                                    ? AppColors.snapBlack.withOpacity(0.5)
                                    : AppColors.textGrey,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chatProvider.getSenderName(repliedMessage.senderId) ??
                                    'User',
                                style: GoogleFonts.nunito(
                                  color: AppColors.snapBlack.withOpacity(0.7),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                repliedMessage.type == MessageType.text
                                    ? repliedMessage.content
                                    : 'Attachment',
                                style: GoogleFonts.nunito(
                                  color: AppColors.snapBlack.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      // Message content
                      if (message.type == MessageType.image)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.black,
                                  appBar: AppBar(
                                    backgroundColor: Colors.black,
                                    iconTheme: const IconThemeData(color: Colors.white),
                                  ),
                                  body: Center(
                                    child: InteractiveViewer(
                                      child: Image.network(message.content),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              message.content,
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          ),
                        )
                      else if (message.type == MessageType.file)
                        GestureDetector(
                          onTap: () async {
                            final Uri uri = Uri.parse(extractedUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insert_drive_file_rounded,
                                color: textColor.withOpacity(0.7),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  displayFileName,
                                  style: GoogleFonts.nunito(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (message.type == MessageType.audio)
                        AudioPlayerWidget(url: message.content, isMe: isMe)
                      else
                        Text(
                          message.content,
                          style: GoogleFonts.nunito(
                            color: message.isDeleted
                                ? AppColors.textGrey
                                : textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontStyle: message.isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Timestamp + status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.isEdited && !message.isDeleted) ...[
                            Text(
                              'edited',
                              style: GoogleFonts.nunito(
                                color: subtitleColor,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            DateFormat('hh:mm a').format(message.timestamp),
                            style: GoogleFonts.nunito(
                              color: subtitleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.status == MessageStatus.sent
                                  ? Icons.done_rounded
                                  : Icons.done_all_rounded,
                              size: 14,
                              color: message.status == MessageStatus.read
                                  ? const Color(0xFF1A9EFF)
                                  : subtitleColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Reactions bubble
                if (message.reactions.isNotEmpty)
                  Positioned(
                    bottom: -8,
                    right: isMe ? 18 : null,
                    left: !isMe ? 18 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildReactionsWidgets(message.reactions),
                      ),
                    ),
                  ),
              ],
            ),
            if (message.reactions.isNotEmpty) const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
