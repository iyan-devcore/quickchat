import 'package:flutter/material.dart';
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
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // Show empty state if no conversations
        if (chatProvider.chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: AppColors.textGrey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start a new chat by tapping the button below',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          );
        }

        // Show conversation list with pull-to-refresh
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => chatProvider.loadConversations(),
          child: ListView.builder(
            itemCount: chatProvider.chats.length,
            itemBuilder: (context, index) {
              final chat = chatProvider.chats[index];
              return ChatTile(
                chat: chat,
                onTap: () {
                  // Clear unread count when opening the chat
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
                    builder: (context) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.push_pin_outlined),
                            title: Text(chat.isPinned ? 'Unpin chat' : 'Pin chat'),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.volume_off_outlined),
                            title: const Text('Mute notification'),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.archive_outlined),
                            title: const Text('Archive chat'),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline, color: Colors.red),
                            title: const Text('Delete chat', style: TextStyle(color: Colors.red)),
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
