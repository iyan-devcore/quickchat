import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../utils/app_colors.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String? senderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                senderName!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary.withOpacity(0.9) : Theme.of(context).brightness == Brightness.dark ? AppColors.dividerDark : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(message.timestamp),
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.status == MessageStatus.read ? Icons.done_all : Icons.done,
                        size: 12,
                        color: message.status == MessageStatus.read ? Colors.lightBlueAccent : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
