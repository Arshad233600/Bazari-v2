import 'package:flutter/material.dart';

/// صفحه چت فیکس‌شده و حرفه‌ای
/// - ورودی پایین ثابت می‌ماند (با کیبورد بالا نمی‌پرد)
/// - پیام‌ها همیشه اسکرول می‌شوند به آخر
/// - راست‌به‌چپ هم پشتیبانی می‌کند
/// - ساختار ساده ولی آماده‌ی اتصال به دیتابیس (مثلاً Firestore)
class ChatPageFixed extends StatefulWidget {
  const ChatPageFixed({
    super.key,
    required this.peerId,
    this.peerName,
  });

  final String peerId;     // شناسه مخاطب (sellerId یا ...)
  final String? peerName;  // نام مخاطب برای عنوان صفحه

  @override
  State<ChatPageFixed> createState() => _ChatPageFixedState();
}

class _ChatPageFixedState extends State<ChatPageFixed> {
  final _scroll = ScrollController();
  final _text = TextEditingController();
  final _focus = FocusNode();

  /// لیست پیام‌های موقتی (TODO: جایگزین با Stream از دیتابیس)
  final List<_Msg> _messages = <_Msg>[
    _Msg(text: 'سلام! این محصول موجوده؟', isMe: false),
    _Msg(text: 'سلام، بله موجوده 🌟', isMe: true),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToBottom({Duration dur = const Duration(milliseconds: 250)}) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: dur,
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendCurrentText() async {
    final txt = _text.text.trim();
    if (txt.isEmpty) return;
    _text.clear();

    setState(() {
      _messages.add(_Msg(text: txt, isMe: true));
    });

    // TODO: اینجا پیام واقعی را بفرست (مثلاً با Firestore)
    // await ChatService.instance.send(peerId: widget.peerId, text: txt);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Directionality( // برای پشتیبانی از زبان‌های RTL
      textDirection: Directionality.of(context),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(widget.peerName ?? 'گفتگو'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // لیست پیام‌ها
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    return _MessageBubble(msg: m);
                  },
                ),
              ),

              // ورودی + دکمه ارسال
              AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: _ChatInput(
                  controller: _text,
                  focusNode: _focus,
                  onSend: _sendCurrentText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مدل پیام
class _Msg {
  final String text;
  final bool isMe;
  _Msg({required this.text, required this.isMe});
}

/// نمایش یک پیام
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, super.key});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = msg.isMe;
    final bg = isMe
        ? theme.colorScheme.primary.withOpacity(0.85)
        : theme.colorScheme.surfaceVariant;
    final fg = isMe ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 14),
          ),
        ),
        child: Text(msg.text, style: TextStyle(color: fg, height: 1.25)),
      ),
    );
  }
}

/// ویجت ورودی پایین صفحه
class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'پیام بنویسید…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onSend,
              icon: const Icon(Icons.send),
              tooltip: 'ارسال',
            ),
          ],
        ),
      ),
    );
  }
}
