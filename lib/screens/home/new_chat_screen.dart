import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import 'create_group_screen.dart';
import '../chat/chat_screen.dart';

/// Screen for starting a new chat conversation.
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.snapBlack,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Chat',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.snapBlack),
            ),
            Text(
              _isLoading ? 'Loading...' : '${_users.length} contacts',
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.snapBlack, strokeWidth: 2.5))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textGrey),
                      const SizedBox(height: 16),
                      Text(_error!, style: GoogleFonts.nunito(color: AppColors.textGrey, fontSize: 15)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() { _isLoading = true; _error = null; });
                          _loadUsers();
                        },
                        child: Text('Retry', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.people_rounded, size: 40, color: AppColors.snapBlack),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No contacts yet',
                            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.snapBlack),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask a friend to sign up!',
                            style: GoogleFonts.nunito(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        // New group
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            tileColor: AppColors.primary,
                            leading: const Icon(Icons.group_rounded, color: AppColors.snapBlack, size: 26),
                            title: Text('New Group', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.snapBlack)),
                            subtitle: Text('Chat with multiple people', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.snapBlack.withOpacity(0.6))),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                          child: Text(
                            'CONTACTS ON QUICKCHAT',
                            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 0.8),
                          ),
                        ),

                        ..._users.map((user) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(user.avatarUrl),
                                  backgroundColor: AppColors.surfaceVariant,
                                ),
                                if (user.isOnline)
                                  Positioned(
                                    bottom: 1, right: 1,
                                    child: Container(
                                      width: 12, height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.online,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(user.name, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.snapBlack)),
                            subtitle: Text(user.about, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textGrey)),
                            onTap: () {
                              final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
                              if (currentUser == null) return;
                              final roomId = ChatProvider.generateRoomId(currentUser.id, user.id);
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
