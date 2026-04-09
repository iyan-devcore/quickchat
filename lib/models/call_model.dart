enum CallType { audio, video }
enum CallDirection { incoming, outgoing, missed }

class Call {
  final String id;
  final String userId;
  final DateTime timestamp;
  final CallType type;
  final CallDirection direction;

  Call({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.type,
    required this.direction,
  });
}
