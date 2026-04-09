import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/encryption_service.dart';
import '../utils/constants.dart';

/// Manages authentication state: login, register, auto-login, and logout.
///
/// On successful auth:
/// 1. Stores JWT token + user data in SharedPreferences (persistence)
/// 2. Configures ApiService with the token (for authenticated API calls)
/// 3. Connects SocketService (for real-time messaging)
///
/// On logout:
/// 1. Clears stored credentials
/// 2. Disconnects socket
/// 3. Resets ApiService token
class UserProvider with ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAwaitingVerification = false;

  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  final EncryptionService _encryptionService = EncryptionService();

  // ── Getters ──
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;
  bool get isAwaitingVerification => _isAwaitingVerification;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ApiService get apiService => _apiService;
  SocketService get socketService => _socketService;
  EncryptionService get encryptionService => _encryptionService;

  /// Try to auto-login from stored credentials on app startup.
  ///
  /// Returns true if a valid token and user were found in SharedPreferences.
  /// This allows the splash screen to skip the auth flow.
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(AppConstants.tokenKey);
    final storedUser = prefs.getString(AppConstants.userKey);

    if (storedToken == null || storedUser == null) {
      return false;
    }

    _token = storedToken;
    _currentUser = User.fromJsonString(storedUser);
    _apiService.setToken(_token);

    // Connect socket with the stored token
    _socketService.connect(_token!);

    // Initialize encryption
    await _initEncryption();

    notifyListeners();
    return true;
  }

  /// Register a new user account.
  ///
  /// Calls Firebase Auth to create a user and sends an email verification.
  /// Also notifies the Node.js backend to create a local record.
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isAwaitingVerification = false;
    notifyListeners();

    try {
      // 1. Create User in Firebase
      final userCredential = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Firebase registration failed');

      // 2. Update display name and send verification email
      await firebaseUser.updateDisplayName(name);
      await firebaseUser.sendEmailVerification();

      // 3. Register user in Node.js Backend (for MongoDB storage)
      // This ensures the local database is in sync with Firebase
      await _apiService.register(name, email, password);

      _isAwaitingVerification = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll(RegExp(r'^\[.*\]\s*'), '').replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with existing credentials.
  ///
  /// Verifies credentials in Firebase and ensures the user has verified their email.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isAwaitingVerification = false;
    notifyListeners();

    try {
      // 1. Login with Firebase
      final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Firebase login failed');

      // 2. Check if email is verified
      await firebaseUser.reload();
      if (!firebase_auth.FirebaseAuth.instance.currentUser!.emailVerified) {
        _isAwaitingVerification = true;
        _isLoading = false;
        notifyListeners();
        return true; // Return true but set isAwaitingVerification to true
      }

      // 3. Login to Node.js Backend to get the JWT token
      final Map<String, dynamic> data = await _apiService.login(email, password);

      // 4. Parse user and token
      _token = data['token'];
      _currentUser = User.fromJson(data['user'] ?? {});

      // 5. Persist credentials
      await _saveCredentials();

      // 6. Configure services
      _apiService.setToken(_token);
      _socketService.connect(_token!);

      // 7. Initialize encryption and sync public key
      await _initEncryption();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll(RegExp(r'^\[.*\]\s*'), '').replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if the current Firebase user has verified their email.
  /// If verified, proceed to login to the Node.js backend.
  Future<bool> checkEmailVerified(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (firebase_auth.FirebaseAuth.instance.currentUser!.emailVerified) {
          _isAwaitingVerification = false;
          // Now login to backend
          final Map<String, dynamic> data = await _apiService.login(email, password);
          _token = data['token'];
          _currentUser = User.fromJson(data['user'] ?? {});
          await _saveCredentials();
          _apiService.setToken(_token);
          _socketService.connect(_token!);
          
          // Initialize encryption
          await _initEncryption();

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll(RegExp(r'^\[.*\]\s*'), '').replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend verification email to the current Firebase user.
  Future<void> resendVerificationEmail() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      _errorMessage = 'Failed to resend verification email: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Logout: clear everything and disconnect.
  Future<void> logout() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (_) {}

    // Disconnect socket
    _socketService.disconnect();

    // Reset encryption
    _encryptionService.reset();

    // Clear API token
    _apiService.setToken(null);

    // Clear stored credentials
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);

    // Reset state
    _currentUser = null;
    _token = null;
    _errorMessage = null;
    _isAwaitingVerification = false;

    notifyListeners();
  }

  /// Update the user's profile (name, about).
  void updateProfile(String name, String about) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(name: name, about: about);
      _saveCredentials(); // Persist updated user data
      notifyListeners();
    }
  }

  /// Save JWT token and user data to SharedPreferences.
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(AppConstants.tokenKey, _token!);
    }
    if (_currentUser != null) {
      await prefs.setString(AppConstants.userKey, _currentUser!.toJsonString());
    }
  }

  /// Initialize E2E encryption and ensure public key is shared with the backend.
  Future<void> _initEncryption() async {
    try {
      await _encryptionService.init();

      // If the backend doesn't have our public key, or it's different (e.g. new device), update it
      if (_currentUser != null && _currentUser!.publicKey != _encryptionService.publicKey) {
        await _apiService.updatePublicKey(_encryptionService.publicKey!);
        // Update local user object too
        _currentUser = _currentUser!.copyWith(publicKey: _encryptionService.publicKey);
        await _saveCredentials();
      }
    } catch (e) {
      print('Encryption initialization error: $e');
    }
  }
}
