/// Application-wide constants for API and Socket connections.
///
/// Change [baseUrl] to your server's IP/domain when deploying.
/// For local development with Flutter web, localhost works directly.
/// For mobile emulators, use 10.0.2.2 (Android) or localhost (iOS).
class AppConstants {
  /// Base URL for REST API calls
  static const String baseUrl = 'http://localhost:5000';

  /// Socket.io server URL (same as API server)
  static const String socketUrl = 'http://localhost:5000';

  /// SharedPreferences key for storing JWT token
  static const String tokenKey = 'auth_token';

  /// SharedPreferences key for storing user data as JSON
  static const String userKey = 'auth_user';
}
