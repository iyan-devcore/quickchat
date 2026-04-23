import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../home/home_screen.dart';
import 'verify_email_screen.dart';

/// Authentication screen with Login and Register tabs.
///
/// Wired to real backend API via [UserProvider]:
/// - Login: validates credentials against MongoDB
/// - Register: creates a new account with hashed password
///
/// On success: initializes ChatProvider and navigates to HomeScreen.
/// On failure: displays error message via SnackBar.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  /// Handle login: call API, show errors, navigate on success.
  void _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.login(email, password);

    if (!mounted) return;

    if (success) {
      if (userProvider.isAwaitingVerification) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(email: email, password: password),
          ),
        );
        return;
      }

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
      _showError(userProvider.errorMessage ?? 'Login failed');
    }
  }

  /// Handle registration: call API, show errors, navigate on success.
  void _handleRegister() async {
    final name = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.register(name, email, password);

    if (!mounted) return;

    if (success) {
      if (userProvider.isAwaitingVerification) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Verify Email',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            ),
            content: Text(
              'Registration successful! Please verify your email and then login to continue.',
              style: GoogleFonts.nunito(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _tabController.animateTo(0);
                  _loginEmailController.text = email;
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.nunito(
                    color: AppColors.snapBlack,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }

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
      _showError(userProvider.errorMessage ?? 'Registration failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.nunito()),
        backgroundColor: AppColors.snapBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 56),
                // Snapchat-style yellow logo circle
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 48,
                    color: AppColors.snapBlack,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'QuickChat',
                  style: GoogleFonts.nunito(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.snapBlack,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Talk fast. Chat smarter.',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),
                // Tab bar — Snapchat pill style
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: AppColors.primary,
                    ),
                    labelColor: AppColors.snapBlack,
                    unselectedLabelColor: AppColors.textGrey,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Log In'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 320,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(),
                      _buildRegisterForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Column(
          children: [
            CustomTextField(
              controller: _loginEmailController,
              hintText: 'Email address',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _loginPasswordController,
              hintText: 'Password',
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.nunito(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Log In',
              isLoading: userProvider.isLoading,
              onPressed: _handleLogin,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRegisterForm() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Column(
          children: [
            CustomTextField(
              controller: _registerNameController,
              hintText: 'Full Name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _registerEmailController,
              hintText: 'Email address',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _registerPasswordController,
              hintText: 'Password',
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              text: 'Create Account',
              isLoading: userProvider.isLoading,
              onPressed: _handleRegister,
            ),
          ],
        );
      },
    );
  }
}
