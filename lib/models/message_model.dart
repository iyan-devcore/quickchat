/// Message types supported by the chat system.
enum MessageType { text, image, audio, video, file }

/// Delivery status of a message.
enum MessageStatus { sent, delivered, read }

/// Represents a single chat message.
///
/// Messages are stored in MongoDB and delivered via Socket.io.
/// Each message belongs to a [roomId] which identifies the conversation.
class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final bool isDeleted;
  final bool isEdited;
  final String? iv;
  final String? mac;
  final bool isEncrypted;
  final bool isGroup;
  final String? replyTo;
  final Map<String, String> reactions;

  Message({
    required this.id,
    this.roomId = '',
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.isDeleted = false,
    this.isEdited = false,
    this.iv,
    this.mac,
    this.isEncrypted = false,
    this.isGroup = false,
    this.replyTo,
    this.reactions = const {},
  });

  Message copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    MessageStatus? status,
    bool? isDeleted,
    bool? isEdited,
    String? iv,
    String? mac,
    bool? isEncrypted,
    bool? isGroup,
    String? replyTo,
    Map<String, String>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      iv: iv ?? this.iv,
      mac: mac ?? this.mac,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isGroup: isGroup ?? this.isGroup,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
    );
  }

  /// Create a Message from a JSON map (API or Socket response).
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      roomId: (json['roomId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString()).toLocal()
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : DateTime.now()),
      type: _parseMessageType(json['type']),
      status: _parseMessageStatus(json['status']),
      isDeleted: json['isDeleted'] ?? false,
      isEdited: json['isEdited'] ?? false,
      iv: json['iv'],
      mac: json['mac'],
      isEncrypted: json['isEncrypted'] ?? false,
      isGroup: json['isGroup'] ?? false,
      replyTo: json['replyTo']?.toString(),
      reactions: json['reactions'] != null
          ? Map.fromEntries(
              (json['reactions'] as List).map((r) => MapEntry(r['userId'].toString(), r['emoji'].toString()))
            )
          : {},
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'iv': iv,
      'mac': mac,
      'isEncrypted': isEncrypted,
      'isGroup': isGroup,
      'replyTo': replyTo,
      'reactions': reactions.entries.map((e) => {'userId': e.key, 'emoji': e.value}).toList(),
    };
  }

  /// Parse message type string to enum.
  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    switch (type.toString()) {
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  /// Parse message status string to enum.
  static MessageStatus _parseMessageStatus(dynamic status) {
    if (status == null) return MessageStatus.sent;
    switch (status.toString()) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }
}
