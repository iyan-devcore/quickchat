import 'message_model.dart';
import 'user_model.dart';

/// Represents a conversation (chat) between two users.
///
/// In the backend, conversations are derived from messages sharing
/// the same [roomId]. This model combines the conversation metadata
/// with the other user's info and the last message for display
/// in the chat list screen.
class Chat {
  final String id;          // Same as roomId
  final String name;        // Display name (other user's name)
  final String avatarUrl;   // Other user's avatar
  final bool isGroup;
  final List<String> memberIds;
  final List<Message> messages;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final User? otherUser;    // The other participant's full profile

  Chat({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.isGroup = false,
    required this.memberIds,
    this.messages = const [],
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.otherUser,
  });

  /// The most recent message in this conversation (for chat list preview).
  Message? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Create a Chat from the /api/chat/conversations API response.
  factory Chat.fromConversationJson(Map<String, dynamic> json) {
    final isGroup = json['isGroup'] == true || json['roomId'].toString().startsWith('group_') || json['creatorId'] != null;
    
    if (isGroup) {
      final lastMessageData = json['lastMessage'];
      return Chat(
        id: (json['id'] ?? json['roomId'] ?? '').toString(),
        name: json['name'] ?? 'Group Chat',
        avatarUrl: json['avatarUrl'] ?? '',
        isGroup: true,
        memberIds: (json['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
        messages: lastMessageData != null ? [Message.fromJson(lastMessageData)] : [],
        unreadCount: json['unreadCount'] ?? 0,
        otherUser: null, // Groups don't have a single "other user"
      );
    }

    final otherUser = User.fromJson(json['user'] ?? {});
    final lastMessageData = json['lastMessage'];

    return Chat(
      id: json['roomId'] ?? '',
      name: otherUser.name,
      avatarUrl: otherUser.avatarUrl,
      isGroup: false,
      memberIds: [],
      messages: lastMessageData != null
          ? [Message.fromJson(lastMessageData)]
          : [],
      unreadCount: json['unreadCount'] ?? 0,
      otherUser: otherUser,
    );
  }

  /// Create a copy of this chat with updated fields.
  Chat copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isGroup,
    List<String>? memberIds,
    List<Message>? messages,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    User? otherUser,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGroup: isGroup ?? this.isGroup,
      memberIds: memberIds ?? this.memberIds,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      otherUser: otherUser ?? this.otherUser,
    );
  }
}
