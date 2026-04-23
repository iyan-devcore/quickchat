import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final isOnline = chat.otherUser?.isOnline ?? false;
    final hasUnread = chat.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: AppColors.primary.withOpacity(0.1),
      highlightColor: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasUnread ? AppColors.primary : Colors.transparent,
                      width: hasUnread ? 2.5 : 0,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(chat.avatarUrl),
                    backgroundColor: AppColors.surfaceVariant,
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Name and message preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          style: GoogleFonts.nunito(
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.snapBlack,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessage != null)
                        Text(
                          _formatTimestamp(chat.lastMessage!.timestamp),
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: hasUnread ? AppColors.snapBlack : AppColors.textGrey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage?.content ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                            color: hasUnread ? AppColors.textSecondary : AppColors.textGrey,
                          ),
                        ),
                      ),
                      if (chat.isPinned)
                        Transform.rotate(
                          angle: 45 * 3.14 / 180,
                          child: const Icon(
                            Icons.push_pin,
                            size: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: GoogleFonts.nunito(
                              color: AppColors.snapBlack,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
