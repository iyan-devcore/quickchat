import 'dart:io';
import 'package:flutter/foundation.dart';

/// Application-wide constants for API and Socket connections.
///
/// Change [baseUrl] to your server's IP/domain when deploying.
/// For local development with Flutter web, localhost works directly.
/// For mobile emulators, use 10.0.2.2 (Android) or localhost (iOS).
class AppConstants {
  // The live backend deployed on Railway
  static const String _productionUrl = 'https://quickchat-production-f3b8.up.railway.app';

  /// Base URL for REST API calls
  static String get baseUrl => _productionUrl;

  /// Socket.io server URL (same as API server)
  static String get socketUrl => _productionUrl;

  /// SharedPreferences key for storing JWT token
  static const String tokenKey = 'auth_token';

  /// SharedPreferences key for storing user data as JSON
  static const String userKey = 'auth_user';
}
