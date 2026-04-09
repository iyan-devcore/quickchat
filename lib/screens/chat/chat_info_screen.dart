import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../utils/app_colors.dart';

/// Contact/Group info screen shown when tapping the chat header.
class ChatInfoScreen extends StatelessWidget {
  final Chat chat;

  const ChatInfoScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(chat.name),
              background: Image.network(
                chat.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary,
                    child: const Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),
                ListTile(
                  title: Text(chat.isGroup ? 'Group Info' : 'Contact Info'),
                  subtitle: Text(
                    chat.isGroup
                        ? '${chat.memberIds.length} members'
                        : chat.otherUser?.email ?? '',
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('About'),
                  subtitle: Text(chat.otherUser?.about ?? 'Hey there! I am using QuickChat.'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Block User', style: TextStyle(color: Colors.red)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.thumb_down, color: Colors.red),
                  title: const Text('Report User', style: TextStyle(color: Colors.red)),
                  onTap: () {},
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
