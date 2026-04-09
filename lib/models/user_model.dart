import 'dart:convert';

/// Represents a user in the QuickChat system.
///
/// Used for both the current authenticated user and other users
/// displayed in contact lists and chat headers.
class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String about;
  final bool isOnline;
  final DateTime? lastSeen;
  final String publicKey;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.about,
    this.isOnline = false,
    this.lastSeen,
    this.publicKey = '',
  });

  /// Create a User from a JSON map (API response).
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      about: json['about'] ?? 'Hey there! I am using QuickChat.',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())?.toLocal()
          : null,
      publicKey: json['publicKey'] ?? '',
    );
  }

  /// Convert to JSON map (for SharedPreferences storage).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'about': about,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'publicKey': publicKey,
    };
  }

  /// Serialize to JSON string (for SharedPreferences).
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string (from SharedPreferences).
  factory User.fromJsonString(String jsonString) {
    return User.fromJson(jsonDecode(jsonString));
  }

  /// Create a copy with updated fields.
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? about,
    bool? isOnline,
    DateTime? lastSeen,
    String? publicKey,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      about: about ?? this.about,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      publicKey: publicKey ?? this.publicKey,
    );
  }
}
