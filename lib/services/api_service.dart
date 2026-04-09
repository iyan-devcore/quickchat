import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Centralized HTTP client for all REST API communication.
///
/// Handles:
/// - Authentication (login/register) — returns JWT + user data
/// - Chat data (users list, conversations, message history)
/// - Automatic JWT token injection via [_headers]
///
/// All methods throw exceptions with meaningful error messages
/// which are caught and displayed by the providers/UI layer.
class ApiService {
  /// JWT token set after login/register, included in all subsequent requests
  String? _token;

  /// Update the auth token (called by AuthProvider after login)
  void setToken(String? token) {
    _token = token;
  }

  /// Build headers with optional Bearer token
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ─────────────────────────────────────────
  // Authentication Endpoints
  // ─────────────────────────────────────────

  /// Register a new user account.
  ///
  /// Returns a Map with 'user' and 'token' on success.
  /// Throws an exception with the server error message on failure.
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  /// Login with existing credentials.
  ///
  /// Returns a Map with 'user' and 'token' on success.
  /// Throws an exception with the server error message on failure.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  /// Update the current user's public key for E2E encryption.
  Future<void> updatePublicKey(String publicKey) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/auth/public-key'),
      headers: _headers,
      body: jsonEncode({'publicKey': publicKey}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to update public key');
    }
  }

  // ─────────────────────────────────────────
  // Chat Endpoints (all require auth token)
  // ─────────────────────────────────────────

  /// Fetch all registered users except the current user.
  /// Used to populate the "New Chat" contact list.
  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/chat/users'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  /// Fetch the current user's conversations with the last message.
  /// Each conversation includes the other user's info and unread count.
  Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/chat/conversations'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch conversations');
    }
  }

  /// Fetch message history for a specific chat room.
  ///
  /// Returns the last 50 messages in chronological order.
  /// Supports pagination via [before] message ID for loading older messages.
  Future<List<Map<String, dynamic>>> getMessages(String roomId, {String? before}) async {
    String url = '${AppConstants.baseUrl}/api/chat/messages/$roomId';
    if (before != null) {
      url += '?before=$before';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch messages');
    }
  }

  // ─────────────────────────────────────────
  // Group Endpoints
  // ─────────────────────────────────────────

  /// Create a new encrypted group.
  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String description,
    required List<Map<String, dynamic>> members,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/groups'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'description': description,
        'members': members,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to create group');
    }
  }

  /// Fetch all groups the current user is a member of.
  Future<List<Map<String, dynamic>>> getGroups() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/groups'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch groups');
    }
  }
}
