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
  final Color? bubbleColor; // optional override for outgoing bubble colour

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderName,
    this.onLongPress,
    this.bubbleColor,
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

    final Color textColor = Colors.white;
    final Color subtitleColor = isMe
        ? Colors.white70
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
                padding: const EdgeInsets.only(left: 14, bottom: 4),
                child: Text(
                  senderName!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe && !message.isDeleted && bubbleColor == null
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe && !message.isDeleted && bubbleColor != null
                        ? bubbleColor
                        : (!isMe && !message.isDeleted ? AppColors.surfaceVariant : (message.isDeleted ? AppColors.border : null)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(6),
                      bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(20),
                    ),
                    boxShadow: [
                      if (isMe && !message.isDeleted)
                        BoxShadow(
                          color: (bubbleColor ?? AppColors.primary).withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 10,
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              left: BorderSide(
                                color: isMe ? Colors.white54 : AppColors.primary,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chatProvider.getSenderName(repliedMessage.senderId) ?? 'User',
                                style: GoogleFonts.plusJakartaSans(
                                  color: isMe ? Colors.white : AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                repliedMessage.type == MessageType.text
                                    ? repliedMessage.content
                                    : 'Attachment',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 13,
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
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              message.content,
                              width: 220,
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
                                color: textColor.withOpacity(0.8),
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  displayFileName,
                                  style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
                            color: message.isDeleted ? AppColors.textGrey : textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      const SizedBox(height: 6),
                      // Timestamp + status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.isEdited && !message.isDeleted) ...[
                            Text(
                              'edited',
                              style: GoogleFonts.plusJakartaSans(
                                color: subtitleColor,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            DateFormat('hh:mm a').format(message.timestamp),
                            style: GoogleFonts.plusJakartaSans(
                              color: subtitleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Icon(
                              message.status == MessageStatus.sent
                                  ? Icons.done_rounded
                                  : Icons.done_all_rounded,
                              size: 15,
                              color: message.status == MessageStatus.read
                                  ? Colors.blueAccent
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
                    bottom: -6,
                    right: isMe ? 20 : null,
                    left: !isMe ? 20 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
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
            if (message.reactions.isNotEmpty) const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
