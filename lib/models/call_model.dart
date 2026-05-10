enum CallType { audio, video }
enum CallStatus { answered, missed, rejected }

class CallLog {
  final String id;
  final String callerId;
  final String receiverId;
  final String callerName;
  final String receiverName;
  final CallType type;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int duration; // seconds

  CallLog({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callerName,
    required this.receiverName,
    required this.type,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.duration = 0,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id:           (json['id'] ?? json['_id'] ?? '').toString(),
      callerId:     (json['callerId'] ?? '').toString(),
      receiverId:   (json['receiverId'] ?? '').toString(),
      callerName:   json['callerName'] ?? '',
      receiverName: json['receiverName'] ?? '',
      type:         (json['isVideo'] == true) ? CallType.video : CallType.audio,
      status:       _statusFromString(json['status']?.toString()),
      startedAt:    DateTime.tryParse(json['startedAt'] ?? '')?.toLocal() ?? DateTime.now(),
      endedAt:      json['endedAt'] != null ? DateTime.tryParse(json['endedAt'])?.toLocal() : null,
      duration:     (json['duration'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'receiverId':   receiverId,
    'callerName':   callerName,
    'receiverName': receiverName,
    'isVideo':      type == CallType.video,
    'status':       _statusToString(status),
    'startedAt':    startedAt.toUtc().toIso8601String(),
    'endedAt':      endedAt?.toUtc().toIso8601String(),
    'duration':     duration,
  };

  static CallStatus _statusFromString(String? s) {
    switch (s) {
      case 'answered': return CallStatus.answered;
      case 'rejected': return CallStatus.rejected;
      default:         return CallStatus.missed;
    }
  }

  static String _statusToString(CallStatus s) {
    switch (s) {
      case CallStatus.answered: return 'answered';
      case CallStatus.rejected: return 'rejected';
      case CallStatus.missed:   return 'missed';
    }
  }

  /// Whether the current user was the caller
  bool isOutgoing(String currentUserId) => callerId == currentUserId;

  String formattedDuration() {
    if (duration <= 0) return '';
    final m = duration ~/ 60;
    final s = duration % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}
