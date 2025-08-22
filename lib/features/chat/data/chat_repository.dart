import 'dart:math';
import 'package:flutter/foundation.dart';
import 'chat_models.dart';

class ChatRepository {
  static final ChatRepository instance = ChatRepository._();
  ChatRepository._();

  /// برای Badge تعداد پیام‌های نخوانده
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  final List<Chat> _chats = [
    Chat(
      id: 'c1',
      title: 'Ali',
      subtitle: 'see you soon!',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      unread: 2,
    ),
    Chat(
      id: 'c2',
      title: 'Sara',
      subtitle: 'ok, thanks ✨',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    Chat(
      id: 'c3',
      title: 'Team',
      subtitle: 'file received',
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  final Map<String, List<Message>> _msgs = {
    'c1': [
      Message(
        id: 'm1',
        chatId: 'c1',
        sender: 'Ali',
        type: MessageType.text,                 // ✅
        text: 'Salaam!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Message(
        id: 'm2',
        chatId: 'c1',
        sender: 'me',
        type: MessageType.text,                 // ✅
        text: 'Salaam ✋',
        createdAt: DateTime.now().subtract(const Duration(minutes: 28)),
      ),
      Message(
        id: 'm3',
        chatId: 'c1',
        sender: 'Ali',
        type: MessageType.text,                 // ✅
        text: 'see you soon!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ],
    'c2': [
      Message(
        id: 'm1',
        chatId: 'c2',
        sender: 'me',
        type: MessageType.text,                 // ✅
        text: 'invoice ro ferestadam',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      ),
      Message(
        id: 'm2',
        chatId: 'c2',
        sender: 'Sara',
        type: MessageType.text,                 // ✅
        text: 'ok, thanks ✨',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
    'c3': [
      Message(
        id: 'm1',
        chatId: 'c3',
        sender: 'me',
        type: MessageType.text,                 // ✅
        text: 'file received',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ],
  };

  void _recalcUnread() {
    final total = _chats.fold<int>(0, (sum, c) => sum + c.unread);
    unreadCount.value = total;
  }

  /// ساخت/به‌روزرسانی کارت چت (برای ورود از صفحهٔ محصول)
  Chat upsertChat({required String id, required String title, String subtitle = 'شروع گفتگو'}) {
    final now = DateTime.now();
    final idx = _chats.indexWhere((c) => c.id == id);
    if (idx == -1) {
      _chats.add(Chat(id: id, title: title, subtitle: subtitle, updatedAt: now, unread: 0));
    } else {
      final c = _chats[idx];
      _chats[idx] = c.copyWith(subtitle: subtitle, updatedAt: now);
    }
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _recalcUnread();
    return _chats.firstWhere((e) => e.id == id);
  }

  Future<List<Chat>> getChats() async {
    await Future.delayed(const Duration(milliseconds: 120));
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _recalcUnread();
    return List.unmodifiable(_chats);
  }

  Future<List<Message>> getMessages(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return List.unmodifiable(_msgs[chatId] ?? const []);
  }

  Future<Message> sendMessage(String chatId, String text) async {
    final msg = Message(
      id: 'm${Random().nextInt(1 << 30)}',
      chatId: chatId,
      sender: 'me',
      type: MessageType.text,                   // ✅
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    _msgs.putIfAbsent(chatId, () => []);
    _msgs[chatId]!.add(msg);

    final idx = _chats.indexWhere((c) => c.id == chatId);
    final now = DateTime.now();
    if (idx == -1) {
      _chats.add(Chat(id: chatId, title: chatId, subtitle: text, updatedAt: now, unread: 0));
    } else {
      final c = _chats[idx];
      _chats[idx] = c.copyWith(subtitle: text, updatedAt: now);
    }
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _recalcUnread();
    await Future.delayed(const Duration(milliseconds: 60));
    return msg;
  }

  /// شبیه‌سازی پیام ورودی (برای تست)
  Future<void> simulateIncoming(String chatId, String text) async {
    final msg = Message(
      id: 'm${Random().nextInt(1 << 30)}',
      chatId: chatId,
      sender: 'peer',
      type: MessageType.text,                   // ✅
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    _msgs.putIfAbsent(chatId, () => []);
    _msgs[chatId]!.add(msg);

    final idx = _chats.indexWhere((c) => c.id == chatId);
    final now = DateTime.now();
    if (idx == -1) {
      _chats.add(Chat(id: chatId, title: chatId, subtitle: text, updatedAt: now, unread: 1));
    } else {
      final c = _chats[idx];
      _chats[idx] = c.copyWith(subtitle: text, updatedAt: now, unread: c.unread + 1);
    }
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _recalcUnread();
  }

  /// صفر کردن پیام‌های نخوانده یک چت (وقتی وارد اتاق می‌شویم)
  void markRead(String chatId) {
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx != -1) {
      final c = _chats[idx];
      if (c.unread != 0) {
        _chats[idx] = c.copyWith(unread: 0);
        _recalcUnread();
      }
    }
  }
}
