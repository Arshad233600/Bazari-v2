import 'chat_models.dart';

/// ریپازیتوری ساده برای تست و لیست گفتگوها
class ChatRepository {
  final List<Chat> _chats = [
    Chat(
      id: 'c1',
      title: 'Ali',
      subtitle: 'سلام!',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      unread: 2,
    ),
    Chat(
      id: 'c2',
      title: 'Sara',
      subtitle: 'فردا می‌بینمت.',
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      unread: 0,
    ),
  ];

  final Map<String, List<Message>> _messages = {
    'c1': [
      Message(
        id: 'm1',
        chatId: 'c1',
        senderId: 'Ali',
        senderDisplayName: 'Ali',
        text: 'سلام!',
        sentAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      Message(
        id: 'm2',
        chatId: 'c1',
        senderId: 'me',
        senderDisplayName: 'من',
        text: 'خوبی؟',
        sentAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ],
    'c2': [
      Message(
        id: 'm3',
        chatId: 'c2',
        senderId: 'Sara',
        senderDisplayName: 'Sara',
        text: 'فردا می‌بینمت.',
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ],
  };

  Future<List<Chat>> getChats() async {
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<Chat>.from(_chats);
  }

  Future<List<Message>> getMessages(String chatId) async {
    return List<Message>.from(_messages[chatId] ?? []);
  }

  Future<void> sendMessage({
    required String chatId,
    required String meId,
    required String text,
  }) async {
    final msg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: meId,
      senderDisplayName: 'من',
      text: text,
      sentAt: DateTime.now(),
    );
    _messages.putIfAbsent(chatId, () => []).insert(0, msg);

    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx >= 0) {
      _chats[idx] = _chats[idx].copyWith(
        subtitle: text,
        updatedAt: DateTime.now(),
      );
    } else {
      _chats.add(Chat(
        id: chatId,
        title: chatId,
        subtitle: text,
        updatedAt: DateTime.now(),
        unread: 0,
      ));
    }
  }
}
