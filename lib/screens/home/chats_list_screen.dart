import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/chat_tile.dart';
import '../chat/chat_screen.dart';

/// Displays the list of conversations for the current user.
///
/// Conversations are loaded from the backend via [ChatProvider].
/// Each tile shows the other user's name, avatar, last message,
/// timestamp, unread count, and online status indicator.
///
/// Pull-to-refresh reloads conversations from the API.
class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Show loading indicator on first load
        if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.snapBlack,
              strokeWidth: 2.5,
            ),
          );
        }

        // Show empty state if no conversations
        if (chatProvider.chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 44,
                    color: AppColors.snapBlack,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No chats yet',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.snapBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation by tapping the\nedit button below',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Show conversation list with pull-to-refresh
        return RefreshIndicator(
          color: AppColors.snapBlack,
          backgroundColor: AppColors.primary,
          onRefresh: () => chatProvider.loadConversations(),
          child: ListView.separated(
            itemCount: chatProvider.chats.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 80,
              endIndent: 0,
              color: AppColors.dividerLight,
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
                    backgroundColor: AppColors.backgroundLight,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.push_pin_outlined, color: AppColors.snapBlack),
                            title: Text(
                              chat.isPinned ? 'Unpin chat' : 'Pin chat',
                              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                            ),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.volume_off_outlined, color: AppColors.snapBlack),
                            title: Text(
                              'Mute notifications',
                              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                            ),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.archive_outlined, color: AppColors.snapBlack),
                            title: Text(
                              'Archive chat',
                              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                            ),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                            title: Text(
                              'Delete chat',
                              style: GoogleFonts.nunito(
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
