class Status {
  final String id;
  final String userId;
  final String imageUrl;
  final String caption;
  final DateTime timestamp;

  Status({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.caption = '',
    required this.timestamp,
  });
}
