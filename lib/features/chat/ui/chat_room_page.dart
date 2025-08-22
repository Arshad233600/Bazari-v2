import 'package:flutter/material.dart';
import '../../chat/data/chat_repository.dart';     // re-export از ChatRepository (پایین فایل 2 را ببین)
import '../data/chat_models.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String title;
  const ChatRoomPage({super.key, required this.chatId, required this.title});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

// ✨ افزودن یک اکستنشن کوچک تا m.isMine کار کند، بدون تغییر مدل‌ها
extension _MessageMineX on Message {
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _repo = ChatRepository.instance;
  final _ctl = TextEditingController();
  final _scroll = ScrollController();

  List<Message> _messages = <Message>[];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _repo.getMessages(widget.chatId);
    if (!mounted) return;
    setState(() {
      _messages = list;
      _loading = false;
    });
    _jumpToBottom();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.sendMessage(widget.chatId, text);
      _ctl.clear();
      await _load(); // پیام‌های جدید + پرش به پایین
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(child: Text(_initials(widget.title))),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.call_outlined)),
          IconButton(onPressed: (){}, icon: const Icon(Icons.videocam_outlined)),
          IconButton(onPressed: (){}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isMine = m.isMine;

                final bubbleColor = isMine
                    ? cs.primaryContainer
                // جایگزین امن به جای surfaceContainerHighest که بعضی SDKها ندارند:
                    : cs.surfaceVariant;

                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(12).copyWith(
                          bottomLeft: Radius.circular(isMine ? 12 : 2),
                          bottomRight: Radius.circular(isMine ? 2 : 12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(m.text, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(_time(m.createdAt), style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _Composer(
            controller: _ctl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final a = parts.first[0];
    final b = parts.length > 1 ? parts.last[0] : '';
    return (a + b).toUpperCase();
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  const _Composer({required this.controller, required this.onSend, required this.sending});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.emoji_emotions_outlined)),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  filled: true,
                  fillColor: cs.surfaceVariant.withOpacity(0.6),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: sending ? null : onSend,
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
