import 'dart:io';
import 'package:flutter/foundation.dart';

/// Application-wide constants for API and Socket connections.
///
/// Change [baseUrl] to your server's IP/domain when deploying.
/// For local development with Flutter web, localhost works directly.
/// For mobile emulators, use 10.0.2.2 (Android) or localhost (iOS).
class AppConstants {
  static String get _host {
    if (kIsWeb) {
      return 'localhost';
    } else if (Platform.isAndroid) {
      return '10.0.2.2'; // Mapped to the host machine's localhost in Android Emulator
    } else {
      return 'localhost'; // iOS Simulator and Desktop apps
    }
  }

  /// Base URL for REST API calls
  static String get baseUrl => 'http://$_host:5000';

  /// Socket.io server URL (same as API server)
  static String get socketUrl => 'http://$_host:5000';

  /// SharedPreferences key for storing JWT token
  static const String tokenKey = 'auth_token';

  /// SharedPreferences key for storing user data as JSON
  static const String userKey = 'auth_user';
}
