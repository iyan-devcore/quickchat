import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class DummyData {
  static final User currentUser = User(
    id: 'u1',
    name: 'John Doe',
    email: 'john@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?u=u1',
    about: 'Hey there! I am using QuickChat.',
  );

  static final List<User> users = [
    User(id: 'u2', name: 'Alice Smith', email: 'alice@test.com', avatarUrl: 'https://i.pravatar.cc/150?u=u2', about: 'Busy'),
    User(id: 'u3', name: 'Bob Johnson', email: 'bob@test.com', avatarUrl: 'https://i.pravatar.cc/150?u=u3', about: 'At work'),
    User(id: 'u4', name: 'Charlie Brown', email: 'charlie@test.com', avatarUrl: 'https://i.pravatar.cc/150?u=u4', about: 'Available'),
    User(id: 'u5', name: 'David Lee', email: 'david@test.com', avatarUrl: 'https://i.pravatar.cc/150?u=u5', about: 'Sleeping'),
  ];

  static List<Chat> chats = [
    Chat(
      id: 'c1',
      name: 'Alice Smith',
      avatarUrl: 'https://i.pravatar.cc/150?u=u2',
      memberIds: ['u1', 'u2'],
      messages: [
        Message(id: 'm1', senderId: 'u2', content: 'Hey John!', timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
        Message(id: 'm2', senderId: 'u1', content: 'Hi Alice, how are you?', timestamp: DateTime.now().subtract(const Duration(minutes: 4))),
        Message(id: 'm3', senderId: 'u2', content: 'I am good, thanks! And you?', timestamp: DateTime.now().subtract(const Duration(minutes: 3))),
      ],
      unreadCount: 1,
    ),
    Chat(
      id: 'c2',
      name: 'Bob Johnson',
      avatarUrl: 'https://i.pravatar.cc/150?u=u3',
      memberIds: ['u1', 'u3'],
      messages: [
        Message(id: 'm4', senderId: 'u3', content: 'Meeting at 3 PM?', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
      ],
      unreadCount: 0,
    ),
    Chat(
      id: 'c3',
      name: 'Flutter Devs',
      avatarUrl: 'https://via.placeholder.com/150',
      isGroup: true,
      memberIds: ['u1', 'u2', 'u3', 'u4'],
      messages: [
        Message(id: 'm5', senderId: 'u4', content: 'Has anyone tried the new Flutter version?', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
      ],
      unreadCount: 5,
    ),
  ];
}
