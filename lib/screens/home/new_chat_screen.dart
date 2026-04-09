import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import 'create_group_screen.dart';
import '../chat/chat_screen.dart';

/// Screen for starting a new chat conversation.
///
/// Fetches registered users from the backend API.
/// Tapping a contact generates a deterministic room ID and navigates
/// to the ChatScreen, effectively creating (or resuming) a conversation.
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Fetch all registered users from the backend.
  Future<void> _loadUsers() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final data = await userProvider.apiService.getUsers();
      setState(() {
        _users = data.map((json) => User.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load contacts';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Contact'),
            Text(
              _isLoading ? 'Loading...' : '${_users.length} contacts',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.textGrey),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: AppColors.textGrey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadUsers();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(
                      child: Text(
                        'No other users registered yet.\nAsk a friend to sign up!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textGrey, fontSize: 16),
                      ),
                    )
                  : ListView(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.group, color: Colors.white),
                          ),
                          title: const Text('New group', style: TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                            );
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Contacts on QuickChat',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._users.map((user) {
                          return ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(user.avatarUrl),
                                ),
                                // Online status indicator
                                if (user.isOnline)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
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
                            title: Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(user.about),
                            onTap: () {
                              // Generate deterministic room ID
                              final currentUser = Provider.of<UserProvider>(
                                context,
                                listen: false,
                              ).currentUser;
                              if (currentUser == null) return;

                              final roomId = ChatProvider.generateRoomId(
                                currentUser.id,
                                user.id,
                              );

                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatId: roomId,
                                    chatName: user.name,
                                    chatAvatarUrl: user.avatarUrl,
                                    otherUserId: user.id,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
    );
  }
}
