import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import 'chats_list_screen.dart';
import 'new_chat_screen.dart';
import 'status_screen.dart';
import 'calls_screen.dart';
import 'settings_screen.dart';

/// Main home screen with bottom navigation.
///
/// Tabs: Chats | Updates | Calls | Settings
/// The FAB action changes based on the active tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ChatsListScreen(),
    const StatusScreen(),
    const CallsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Chats',
    'Stories',
    'Calls',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: AppColors.snapBlack,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          // Snapchat-style icon buttons — no background
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 26),
            color: AppColors.snapBlack,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, size: 26),
            color: AppColors.snapBlack,
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _screens[_selectedIndex],
      // Bottom nav — Snapchat style: white bar, yellow circle indicator
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded),
              label: 'Stories',
            ),
            NavigationDestination(
              icon: Icon(Icons.call_outlined),
              selectedIcon: Icon(Icons.call_rounded),
              label: 'Calls',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NewChatScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.snapBlack,
              elevation: 2,
              child: const Icon(Icons.edit_rounded, size: 24),
            )
          : _selectedIndex == 1
              ? FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.snapBlack,
                  elevation: 2,
                  child: const Icon(Icons.add_a_photo_rounded, size: 24),
                )
              : _selectedIndex == 2
                  ? FloatingActionButton(
                      onPressed: () {},
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.snapBlack,
                      elevation: 2,
                      child: const Icon(Icons.add_call, size: 24),
                    )
                  : null,
    );
  }
}
