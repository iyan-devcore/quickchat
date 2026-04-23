import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import 'create_group_screen.dart';
import '../chat/chat_screen.dart';

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
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textLight,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Chat',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textLight),
            ),
            Text(
              _isLoading ? 'Loading...' : '${_users.length} contacts',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textGrey),
                      const SizedBox(height: 16),
                      Text(_error!, style: GoogleFonts.plusJakartaSans(color: AppColors.textGrey, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() { _isLoading = true; _error = null; });
                          _loadUsers();
                        },
                        child: Text('Retry', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white)),
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
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15)],
                            ),
                            child: const Icon(Icons.people_rounded, size: 40, color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No contacts yet',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textLight),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask a friend to sign up!',
                            style: GoogleFonts.plusJakartaSans(color: AppColors.textGrey, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        // New group
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            tileColor: AppColors.surfaceVariant,
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                              ),
                              child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 24),
                            ),
                            title: Text('New Group', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textLight)),
                            subtitle: Text('Chat with multiple people', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textGrey)),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                          child: Text(
                            'CONTACTS ON QUICKCHAT',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textGrey, letterSpacing: 1.0),
                          ),
                        ),

                        ..._users.map((user) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(user.avatarUrl),
                                  backgroundColor: AppColors.surfaceVariant,
                                ),
                                if (user.isOnline)
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: Container(
                                      width: 14, height: 14,
                                      decoration: BoxDecoration(
                                        color: AppColors.online,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.backgroundDark, width: 2.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(user.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textLight)),
                            subtitle: Text(user.about, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textGrey)),
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
                        const SizedBox(height: 32),
                      ],
                    ),
    );
  }
}
