import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';

/// A single conversation tile in the chat list.
///
/// Displays: avatar (with online dot), name, last message preview,
/// timestamp, unread badge, and pin indicator.
class ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = chat.otherUser?.isOnline ?? false;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(chat.avatarUrl),
          ),
          // Online status indicator
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.backgroundDark : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              chat.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.lastMessage != null)
            Text(
              _formatTimestamp(chat.lastMessage!.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: chat.unreadCount > 0 ? AppColors.secondary : AppColors.textGrey,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chat.lastMessage?.content ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textGrey,
              ),
            ),
          ),
          if (chat.isPinned)
            Transform.rotate(
              angle: 45 * 3.14 / 180,
              child: const Icon(Icons.push_pin, size: 16, color: AppColors.textGrey),
            ),
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.unreadBadge,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Format timestamp for display: "HH:mm" for today, "Yesterday", or date.
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0 && now.day == timestamp.day) {
      return DateFormat('hh:mm a').format(timestamp);
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != timestamp.day)) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yy').format(timestamp);
    }
  }
}
