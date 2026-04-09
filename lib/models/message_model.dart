/// Message types supported by the chat system.
enum MessageType { text, image, audio, video }

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
  final String? iv;
  final String? mac;
  final bool isEncrypted;
  final bool isGroup;

  Message({
    required this.id,
    this.roomId = '',
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.isDeleted = false,
    this.iv,
    this.mac,
    this.isEncrypted = false,
    this.isGroup = false,
  });

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
      iv: json['iv'],
      mac: json['mac'],
      isEncrypted: json['isEncrypted'] ?? false,
      isGroup: json['isGroup'] ?? false,
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
      'iv': iv,
      'mac': mac,
      'isEncrypted': isEncrypted,
      'isGroup': isGroup,
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
