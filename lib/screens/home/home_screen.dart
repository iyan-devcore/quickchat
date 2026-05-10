import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/socket_service.dart';
import '../../utils/app_colors.dart';
import 'chats_list_screen.dart';
import 'new_chat_screen.dart';
import 'calls_screen.dart';
import 'settings_screen.dart';
import '../chat/call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _socketService.onIncomingCall((data) {
      if (!mounted) return;
      final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CallScreen(
          callerId: data['from'],
          callerName: data['callerName'] ?? 'Unknown',
          receiverId: currentUser?.id ?? '',
          isVideo: data['isVideo'] ?? false,
          isIncoming: true,
          incomingSignal: data['signal'],
        ),
      ));
    });
  }

  final List<Widget> _screens = [
    const ChatsListScreen(),
    const CallsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Messages',
    'Calls',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      extendBody: true, // Extends body behind bottom nav
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark.withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: AppColors.textLight,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.search_rounded, size: 22),
              color: AppColors.textLight,
              onPressed: () {},
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8, right: 16, left: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.blur_on_rounded, size: 22),
              color: AppColors.textLight,
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
                  _buildNavItem(1, Icons.call_outlined, Icons.call_rounded),
                  _buildNavItem(2, Icons.person_outline_rounded, Icons.person_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primary : AppColors.textGrey,
          size: 26,
        ),
      ),
    );
  }

  Widget? _buildFab() {
    IconData? icon;
    if (_selectedIndex == 0) icon = Icons.edit_rounded;
    if (_selectedIndex == 1) icon = Icons.add_call;

    if (icon == null) return null;

    return Container(
      margin: const EdgeInsets.only(bottom: 80), // Lift above floating nav
      child: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 0) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewChatScreen()));
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Icon(icon, size: 26),
      ),
    );
  }
}

