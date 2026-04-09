import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../home/home_screen.dart';
import '../../widgets/primary_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String password;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;

  void _handleCheckVerification() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isVerified = await userProvider.checkEmailVerified(widget.email, widget.password);

    if (!mounted) return;

    if (isVerified) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not verified yet. Please check your inbox.')),
      );
    }
  }

  void _handleResendEmail() async {
    setState(() => _isResending = true);
    await Provider.of<UserProvider>(context, listen: false).resendVerificationEmail();
    if (!mounted) return;
    setState(() => _isResending = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email resent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 100,
              color: AppColors.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Verify your email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We have sent a verification email to:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 16,
              ),
            ),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textDark : AppColors.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Please check your inbox (and spam folder) and click the link to verify your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 48),
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                return PrimaryButton(
                  text: 'I have verified',
                  isLoading: userProvider.isLoading,
                  onPressed: _handleCheckVerification,
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isResending ? null : _handleResendEmail,
              child: Text(
                _isResending ? 'Sending...' : 'Resend Verification Email',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Provider.of<UserProvider>(context, listen: false).logout();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
