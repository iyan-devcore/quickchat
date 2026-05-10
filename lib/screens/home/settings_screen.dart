import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../profile/profile_screen.dart';
import '../settings/chat_customization_screen.dart';
import '../auth/auth_screen.dart';

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
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.about,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),

        _sectionLabel('Account'),
        _snapTile(context, icon: Icons.key_rounded, label: 'Account', subtitle: 'Security, change number'),
        _snapTile(context, icon: Icons.lock_rounded, label: 'Privacy', subtitle: 'Block contacts, messages'),
        _snapTile(context, icon: Icons.chat_bubble_rounded, label: 'Chats', subtitle: 'Wallpapers, bubble color',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatCustomizationScreen()))),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: AppColors.surfaceVariant,
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text('Log Out', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 16)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text('Log Out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textLight)),
                  content: Text('Are you sure you want to log out?', style: GoogleFonts.plusJakartaSans(color: AppColors.textGrey)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textGrey, fontWeight: FontWeight.w600)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Log Out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
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
        const SizedBox(height: 100), // Spacing for floating navbar
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textGrey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _snapTile(BuildContext context, {required IconData icon, required String label, required String? subtitle, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: AppColors.surfaceVariant,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textLight)),
        subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textGrey)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
        onTap: onTap ?? () {},
      ),
    );
  }
}
