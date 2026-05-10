import 'package:flutter/material.dart';
import '../models/call_model.dart';
import '../services/api_service.dart';

/// Manages call history state for the Calls tab.
///
/// Loads call logs from the backend REST API and exposes helpers
/// for saving a new log once a call finishes (called from CallScreen).
class CallProvider with ChangeNotifier {
  List<CallLog> _calls = [];
  bool _isLoading = false;
  String? _error;

  ApiService? _apiService;
  String? _currentUserId;

  // ── Getters ──
  List<CallLog> get calls => [..._calls];
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialise with the authenticated API service.
  /// Called once after login (same pattern as ChatProvider).
  void init(ApiService apiService, String currentUserId) {
    _apiService = apiService;
    _currentUserId = currentUserId;
    loadCalls();
  }

  /// Fetch call history from the backend.
  Future<void> loadCalls() async {
    if (_apiService == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService!.getCalls();
      _calls = data.map((json) => CallLog.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      print('Error loading calls: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save a call log to the backend and prepend to the local list.
  ///
  /// [receiverId]   — the other party's userId
  /// [receiverName] — the other party's display name
  /// [callerName]   — the current user's display name
  /// [isVideo]      — true for video call
  /// [status]       — answered | missed | rejected
  /// [startedAt]    — when the call was initiated
  /// [endedAt]      — when it ended (null if missed/rejected before connect)
  /// [duration]     — call duration in seconds
  Future<void> saveCall({
    required String receiverId,
    required String receiverName,
    required String callerName,
    required bool isVideo,
    required CallStatus status,
    required DateTime startedAt,
    DateTime? endedAt,
    int duration = 0,
  }) async {
    if (_apiService == null) return;

    final payload = {
      'receiverId':   receiverId,
      'callerName':   callerName,
      'receiverName': receiverName,
      'isVideo':      isVideo,
      'status':       _statusStr(status),
      'startedAt':    startedAt.toUtc().toIso8601String(),
      'endedAt':      endedAt?.toUtc().toIso8601String(),
      'duration':     duration,
    };

    try {
      await _apiService!.saveCall(payload);
      // Reload to get the server-assigned ID
      await loadCalls();
    } catch (e) {
      print('Error saving call: $e');
    }
  }

  String _statusStr(CallStatus s) {
    switch (s) {
      case CallStatus.answered: return 'answered';
      case CallStatus.rejected: return 'rejected';
      case CallStatus.missed:   return 'missed';
    }
  }

  /// Reset on logout.
  void reset() {
    _calls = [];
    _isLoading = false;
    _error = null;
    _apiService = null;
    _currentUserId = null;
    notifyListeners();
  }

  String? get currentUserId => _currentUserId;
}
