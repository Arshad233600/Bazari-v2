import 'package:flutter/foundation.dart';
import 'chat_models.dart';

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  /// شمارنده‌ی ناخوانده‌ها برای Badge
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  final List<Chat> _chats = [
    Chat(
      id: 'c1',
      title: 'Ali',
      subtitle: 'سلام!',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
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

  /// مجموع ناخوانده‌ها را محاسبه و notify می‌کند
  void _recalcUnread() {
    final total = _chats.fold<int>(0, (sum, c) => sum + (c.unread));
    unreadCount.value = total;
  }

  /// ایجاد/به‌روزرسانی چت در لیست
  Chat upsertChat({required String id, required String title, String subtitle = 'شروع گفتگو'}) {
    final now = DateTime.now();
    final idx = _chats.indexWhere((c) => c.id == id);
    if (idx < 0) {
      _chats.add(Chat(id: id, title: title, subtitle: subtitle, updatedAt: now, unread: 0));
    } else {
      _chats[idx] = _chats[idx].copyWith(title: title, subtitle: subtitle, updatedAt: now);
    }
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _recalcUnread();
    return _chats.firstWhere((e) => e.id == id);
  }

  Future<List<Chat>> getChats() async {
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _recalcUnread();
    return List<Chat>.from(_chats);
  }

  Future<List<Message>> getMessages(String chatId) async {
    return List<Message>.from(_messages[chatId] ?? []);
  }

  /// ارسال پیام از سمت من
  Future<void> sendMyMessage({
    required String chatId,
    required String meId,
    required String text,
  }) async {
    final now = DateTime.now();
    final msg = Message(
      id: now.microsecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: meId,
      senderDisplayName: 'من',
      text: text,
      sentAt: now,
    );
    _messages.putIfAbsent(chatId, () => []).insert(0, msg);

    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx >= 0) {
      _chats[idx] = _chats[idx].copyWith(subtitle: text, updatedAt: now);
    } else {
      _chats.add(Chat(id: chatId, title: chatId, subtitle: text, updatedAt: now, unread: 0));
    }
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _recalcUnread();
  }

  /// شبیه‌سازی دریافت پیام از طرف مقابل (برای تست)
  Future<void> receivePeerMessage({
    required String chatId,
    required String peerName,
    required String text,
  }) async {
    final now = DateTime.now();
    final msg = Message(
      id: now.microsecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'peer',
      senderDisplayName: peerName,
      text: text,
      sentAt: now,
    );
    _messages.putIfAbsent(chatId, () => []).insert(0, msg);

    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx >= 0) {
      _chats[idx] = _chats[idx].copyWith(
        subtitle: text,
        updatedAt: now,
        unread: _chats[idx].unread + 1,
      );
    } else {
      _chats.add(Chat(id: chatId, title: peerName, subtitle: text, updatedAt: now, unread: 1));
    }
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _recalcUnread();
  }
}
