import 'package:flutter/material.dart';
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

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
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

      // Initialize chat provider with the authenticated user's services
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
            title: const Text('Verify Email'),
            content: const Text('Registration successful! Please verify your email and then login to continue.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _tabController.animateTo(0);
                  _loginEmailController.text = email;
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Initialize chat provider
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
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to QuickChat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.dividerDark : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: AppColors.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textGrey,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Login'),
                    Tab(text: 'Register'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
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
    );
  }

  Widget _buildLoginForm() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              CustomTextField(
                controller: _loginEmailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _loginPasswordController,
                hintText: 'Password',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Login',
                isLoading: userProvider.isLoading,
                onPressed: _handleLogin,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegisterForm() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              CustomTextField(
                controller: _registerNameController,
                hintText: 'Full Name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _registerEmailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _registerPasswordController,
                hintText: 'Password',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Register',
                isLoading: userProvider.isLoading,
                onPressed: _handleRegister,
              ),
            ],
          ),
        );
      },
    );
  }
}
