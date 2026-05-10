import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/call_provider.dart';
import 'providers/chat_prefs_provider.dart';
import 'utils/app_theme.dart';
import 'screens/auth/splash_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Load chat customization preferences from disk
  final chatPrefs = ChatPrefsProvider();
  await chatPrefs.load();
  runApp(MyApp(chatPrefs: chatPrefs));
}

class MyApp extends StatelessWidget {
  final ChatPrefsProvider chatPrefs;
  const MyApp({super.key, required this.chatPrefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider<ChatPrefsProvider>.value(value: chatPrefs),
      ],
      child: MaterialApp(
        title: 'QuickChat',
        debugShowCheckedModeBanner: false,
        // Force dark theme for the new aesthetic
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }
}
