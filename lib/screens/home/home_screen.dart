import 'package:flutter/material.dart';
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
    'QuickChat',
    'Updates',
    'Calls',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        indicatorColor: isDark ? AppColors.secondary.withOpacity(0.2) : AppColors.secondary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.update),
            selectedIcon: Icon(Icons.update),
            label: 'Updates',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call),
            label: 'Calls',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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
              child: const Icon(Icons.message),
            )
          : _selectedIndex == 1
              ? FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.camera_alt),
                )
              : _selectedIndex == 2
                  ? FloatingActionButton(
                      onPressed: () {},
                      child: const Icon(Icons.add_call),
                    )
                  : null,
    );
  }
}
