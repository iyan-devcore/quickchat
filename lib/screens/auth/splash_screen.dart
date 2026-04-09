import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import 'auth_screen.dart';
import '../home/home_screen.dart';

/// Splash screen shown on app launch.
///
/// Attempts auto-login using stored JWT credentials:
/// - If successful → navigates directly to HomeScreen
/// - If no stored credentials → navigates to AuthScreen
///
/// Shows a branded loading animation during the check.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Attempt auto-login after splash animation
    _checkAuth();
  }

  /// Check if the user has stored credentials and auto-login.
  Future<void> _checkAuth() async {
    // Wait for the splash animation to play
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isLoggedIn = await userProvider.tryAutoLogin();

    if (!mounted) return;

    if (isLoggedIn) {
      // Initialize chat provider with authenticated services
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.init(
        userProvider.apiService,
        userProvider.socketService,
        userProvider.encryptionService,
        userProvider.currentUser!.id,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'QuickChat',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 30),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
