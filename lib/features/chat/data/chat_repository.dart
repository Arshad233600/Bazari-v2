// lib/features/chat/data/chat_repository.dart
import 'chat_models.dart';

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final List<Chat> _chats = [];

  /// همه چت‌ها
  Future<List<Chat>> getChats() async {
    return _chats;
  }

  /// افزودن یا بروزرسانی یک چت
  Chat upsertChat({
    required String id,
    required String title,
    String subtitle = 'شروع گفتگو',
  }) {
    final now = DateTime.now();
    final idx = _chats.indexWhere((c) => c.id == id);

    if (idx >= 0) {
      final old = _chats[idx];
      final updated = old.copyWith(
        subtitle: subtitle,
        updatedAt: now,
      );
      _chats[idx] = updated;
      return updated;
    } else {
      final chat = Chat(
        id: id,
        title: title,
        subtitle: subtitle,
        updatedAt: now,
        unread: 0,
      );
      _chats.add(chat);
      return chat;
    }
  }

  /// شمارش نوتیف نخوانده
  int get totalUnread => _chats.fold(0, (sum, c) => sum + c.unread);
}
