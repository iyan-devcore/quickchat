import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../profile/profile_screen.dart';
import '../auth/auth_screen.dart';

/// Settings screen with user profile, app settings, and logout.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      children: [
        if (user != null)
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(user.avatarUrl),
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              user.about,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.qr_code, color: AppColors.primary),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.key),
          title: const Text('Account'),
          subtitle: const Text('Security notifications, change number'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Privacy'),
          subtitle: const Text('Block contacts, disappearing messages'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.chat),
          title: const Text('Chats'),
          subtitle: const Text('Theme, wallpapers, chat history'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          subtitle: const Text('Message, group & call tones'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.data_usage),
          title: const Text('Storage and data'),
          subtitle: const Text('Network usage, auto-download'),
          onTap: () {},
        ),

        // Theme Switcher
        const Divider(),
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: const Text('Theme'),
          subtitle: Text(isDark ? 'Dark Mode' : 'Light Mode'),
          trailing: Switch(
            value: isDark,
            onChanged: (value) {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            activeColor: AppColors.secondary,
          ),
        ),

        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Help'),
          subtitle: const Text('Help center, contact us, privacy policy'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Invite a friend'),
          onTap: () {},
        ),

        // Logout
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: () async {
            // Show confirmation dialog
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              // Reset chat provider state
              Provider.of<ChatProvider>(context, listen: false).reset();
              // Logout and disconnect socket
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
      ],
    );
  }
}
