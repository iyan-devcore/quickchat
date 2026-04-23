import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/chat_tile.dart';
import '../chat/chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          );
        }

        if (chatProvider.chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Messages Yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation by tapping the\nnew chat button below',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => chatProvider.loadConversations(),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 100), // padding for the floating nav bar
            itemCount: chatProvider.chats.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 84,
              endIndent: 0,
              color: AppColors.dividerDark,
            ),
            itemBuilder: (context, index) {
              final chat = chatProvider.chats[index];
              return ChatTile(
                chat: chat,
                onTap: () {
                  chatProvider.clearUnread(chat.id);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        chatName: chat.name,
                        chatAvatarUrl: chat.avatarUrl,
                        otherUserId: chat.otherUser?.id ?? '',
                        isGroup: chat.isGroup,
                      ),
                    ),
                  );
                },
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.push_pin_outlined, color: AppColors.textLight),
                            title: Text(
                              chat.isPinned ? 'Unpin chat' : 'Pin chat',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textLight),
                            ),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.volume_off_outlined, color: AppColors.textLight),
                            title: Text(
                              'Mute notifications',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textLight),
                            ),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.archive_outlined, color: AppColors.textLight),
                            title: Text(
                              'Archive chat',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textLight),
                            ),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                            title: Text(
                              'Delete chat',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: AppColors.red,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              chatProvider.deleteChat(chat.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
