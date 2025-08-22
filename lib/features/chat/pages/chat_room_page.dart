import 'dart:async';
import 'package:flutter/material.dart';
import '../data/chat_models.dart';

/// قرارداد سرویس چت (جایگزین‌پذیر: لوکال / فایراستور)
abstract class IChatService {
  Stream<List<Message>> watchMessages(String chatId);
  Future<void> sendText({
    required String chatId,
    required String senderId,
    String? senderDisplayName,
    String? senderAvatar,
    required String text,
  });
  Future<void> markAllRead(String chatId, String myUid);
}

/// سرویس لوکال ساده (برای اجرا بدون Firebase)
class LocalChatService implements IChatService {
  final _store = <String, List<Message>>{};
  final _controllers = <String, StreamController<List<Message>>>{};

  StreamController<List<Message>> _ctrl(String chatId) =>
      _controllers.putIfAbsent(chatId, () => StreamController.broadcast());

  List<Message> _list(String chatId) =>
      _store.putIfAbsent(chatId, () => <Message>[]);

  @override
  Stream<List<Message>> watchMessages(String chatId) {
    // استریم معکوس‌شده (جدیدها بالا) در UI مدیریت می‌شود
    Future.microtask(() => _ctrl(chatId).add(_list(chatId)));
    return _ctrl(chatId).stream;
  }

  @override
  Future<void> sendText({
    required String chatId,
    required String senderId,
    String? senderDisplayName,
    String? senderAvatar,
    required String text,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final m = Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderDisplayName: senderDisplayName,
      senderAvatar: senderAvatar,
      text: text.trim(),
      sentAt: DateTime.now(),
    );
    _list(chatId).insert(0, m); // جدیدها ابتدای لیست
    _ctrl(chatId).add(List<Message>.from(_list(chatId)));
  }

  @override
  Future<void> markAllRead(String chatId, String myUid) async {
    // برای لوکال کاری نمی‌کنیم
  }
}

/// صفحهٔ چت
class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.meId,
    this.meDisplayName,
    this.meAvatar,
    this.peerTitle,
    IChatService? service,
  }) : service = service ?? const _ServiceFactory.local();

  final String chatId;
  final String meId;
  final String? meDisplayName;
  final String? meAvatar;
  final String? peerTitle;
  final IChatService service;

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ServiceFactory implements IChatService {
  const _ServiceFactory.local();
  // یک نمایندهٔ لوکال singleton
  static final _local = LocalChatService();
  @override
  Stream<List<Message>> watchMessages(String chatId) => _local.watchMessages(chatId);
  @override
  Future<void> sendText({
    required String chatId,
    required String senderId,
    String? senderDisplayName,
    String? senderAvatar,
    required String text,
  }) =>
      _local.sendText(
        chatId: chatId,
        senderId: senderId,
        senderDisplayName: senderDisplayName,
        senderAvatar: senderAvatar,
        text: text,
      );
  @override
  Future<void> markAllRead(String chatId, String myUid) => _local.markAllRead(chatId, myUid);
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.service.sendText(
        chatId: widget.chatId,
        senderId: widget.meId,
        senderDisplayName: widget.meDisplayName,
        senderAvatar: widget.meAvatar,
        text: text,
      );
      _controller.clear();
      // اسکرول به بالا (چون reverse: true داریم)
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerTitle ?? 'Chat'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // لیست پیام‌ها
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: widget.service.watchMessages(widget.chatId),
                builder: (context, snap) {
                  final items = snap.data ?? const <Message>[];
                  // پیام‌ها به صورت reverse رندر می‌شوند (جدیدترین پایین صفحه)
                  return ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final m = items[i];
                      final mine = m.isMine(widget.meId);
                      return MessageBubble(
                        text: m.text ?? '',
                        imageUrl: m.imageUrl,
                        mine: mine,
                        senderName: m.senderDisplayName,
                        avatarUrl: m.senderAvatar,
                        sentAt: m.sentAt,
                      );
                    },
                  );
                },
              ),
            ),

            // نوار ورودی
            _InputBar(
              controller: _controller,
              sending: _sending,
              onSendPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// ویجت حباب پیام
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.mine,
    required this.sentAt,
    this.senderName,
    this.imageUrl,
    this.avatarUrl,
  });

  final String text;
  final bool mine;
  final DateTime sentAt;
  final String? senderName;
  final String? imageUrl;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = Radius.circular(14);
    final bg = mine ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant;
    final fg = mine ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;

    final avatar = avatarUrl == null
        ? CircleAvatar(radius: 12, child: Text((senderName ?? '?').characters.first.toUpperCase()))
        : CircleAvatar(radius: 12, backgroundImage: NetworkImage(avatarUrl!));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) avatar,
          if (!mine) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                  bottomLeft: mine ? radius : Radius.zero,
                  bottomRight: mine ? Radius.zero : radius,
                ),
              ),
              child: Column(
                crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!mine && (senderName?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        senderName!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: fg.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  if (imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(imageUrl!, width: 220, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg)),
                  const SizedBox(height: 4),
                  Text(
                    _fmtTime(sentAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: fg.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (mine) const SizedBox(width: 8),
          if (mine) avatar,
        ],
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// نوار ورودی پیام
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSendPressed,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSendPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'پیام بنویس…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSendPressed,
              icon: sending
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
