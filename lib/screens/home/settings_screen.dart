import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../profile/profile_screen.dart';
import '../auth/auth_screen.dart';

/// Settings screen — Snapchat light theme.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;

    return ListView(
      children: [
        // Profile header
        if (user != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage: NetworkImage(user.avatarUrl),
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.snapBlack,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.about,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: AppColors.snapBlack.withOpacity(0.65),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.snapBlack.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_rounded, color: AppColors.snapBlack, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),

        _sectionLabel('Account'),
        _snapTile(context, icon: Icons.key_rounded, label: 'Account', subtitle: 'Security, change number'),
        _snapTile(context, icon: Icons.lock_rounded, label: 'Privacy', subtitle: 'Block contacts, messages'),
        _snapTile(context, icon: Icons.chat_bubble_rounded, label: 'Chats', subtitle: 'Wallpapers, chat history'),
        _snapTile(context, icon: Icons.notifications_rounded, label: 'Notifications', subtitle: 'Message & call tones'),
        _snapTile(context, icon: Icons.data_usage_rounded, label: 'Storage & Data', subtitle: 'Network, auto-download'),

        _sectionLabel('Support'),
        _snapTile(context, icon: Icons.help_rounded, label: 'Help', subtitle: 'Help center, privacy policy'),
        _snapTile(context, icon: Icons.people_rounded, label: 'Invite a Friend', subtitle: null),

        _sectionLabel(''),
        // Logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.red.shade50,
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: Text('Log Out', style: GoogleFonts.nunito(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 15)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text('Log Out', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                  content: Text('Are you sure you want to log out?', style: GoogleFonts.nunito()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: GoogleFonts.nunito(color: AppColors.textGrey, fontWeight: FontWeight.w700)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Log Out', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                Provider.of<ChatProvider>(context, listen: false).reset();
                await Provider.of<UserProvider>(context, listen: false).logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textGrey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _snapTile(BuildContext context, {required IconData icon, required String label, required String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: AppColors.surfaceVariant,
        leading: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.snapBlack, size: 20),
        ),
        title: Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.snapBlack)),
        subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textGrey)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
        onTap: () {},
      ),
    );
  }
}
