import 'package:flutter/material.dart';

class ChatRoomDemo extends StatefulWidget {
  const ChatRoomDemo({super.key, this.title = 'Demo Chat'});
  final String title;

  @override
  State<ChatRoomDemo> createState() => _ChatRoomDemoState();
}

class _ChatRoomDemoState extends State<ChatRoomDemo> {
  final _ctl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[
    _Msg('سلام! این محصول موجوده؟', false, DateTime.now().subtract(const Duration(minutes: 3))),
    _Msg('سلام، بله موجوده 🌟', true, DateTime.now().subtract(const Duration(minutes: 2))),
  ];

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void initState() {
    super.initState();
    _jump();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _msgs.length,
                itemBuilder: (_, i) {
                  final m = _msgs[i];
                  final bg = m.isMe
                      ? Theme.of(context).colorScheme.primary.withOpacity(.88)
                      : Theme.of(context).colorScheme.surfaceVariant;
                  final fg = m.isMe ? Colors.white : Theme.of(context).colorScheme.onSurface;
                  return Align(
                    alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(m.isMe ? 14 : 4),
                          bottomRight: Radius.circular(m.isMe ? 4 : 14),
                        ),
                      ),
                      child: Text(m.text, style: TextStyle(color: fg)),
                    ),
                  );
                },
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctl,
                        decoration: const InputDecoration(
                          hintText: 'پیام…', border: OutlineInputBorder(), isDense: true),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(onPressed: _send, icon: const Icon(Icons.send), label: const Text('ارسال')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final t = _ctl.text.trim();
    if (t.isEmpty) return;
    setState(() => _msgs.add(_Msg(t, true, DateTime.now())));
    _ctl.clear();
    _jump();
  }
}

class _Msg {
  final String text; final bool isMe; final DateTime at;
  _Msg(this.text, this.isMe, this.at);
}

