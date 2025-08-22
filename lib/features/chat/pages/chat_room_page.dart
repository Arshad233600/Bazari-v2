// lib/features/chat/pages/chat_room_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../data/chat_repository.dart';
import '../data/chat_models.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.title,
    this.productTitle,
    this.productImage,
  });

  final String chatId;
  final String title;
  final String? productTitle;
  final String? productImage;

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _repo = ChatRepository.instance;
  final _ctl = TextEditingController();
  final _scroll = ScrollController();

  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _showJumpToBottom = false;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScrollChanged);
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _isRtl(BuildContext c) {
    final code = Localizations.localeOf(c).languageCode.toLowerCase();
    return Directionality.of(c) == TextDirection.rtl ||
        const {'fa', 'ar', 'ur', 'ps', 'he'}.contains(code);
  }

  /* ====================== DATA ====================== */

  Future<void> _load() async {
    try {
      // نگذار مارک‌خوانده‌شدن UI را نگه دارد
      Future.microtask(() => _repo.markRead(widget.chatId));

      // اگر شبکه کند باشد، صفحه گیر نکند
      final list = await _repo
          .getMessages(widget.chatId)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() {
        _messages = list;
        _loading = false;
      });
      _jumpToBottom(instant: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('مشکل در بارگذاری پیام‌ها: $e')),
      );
    }
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await _repo.sendMessage(widget.chatId, text);
      _ctl.clear();

      // برای تجربه‌ی سریع: محلی اضافه می‌کنیم
      setState(() {
        _messages.add(
          Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: text,
            createdAt: DateTime.now(),
            isMine: true,
            // اگر مدل شما فیلدهای بیشتری دارد (senderId/Name …) اینجا ست کنید
          ),
        );
      });
      _jumpToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ارسال ناموفق بود: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /* ====================== SCROLL ====================== */

  void _onScrollChanged() {
    if (!_scroll.hasClients) return;
    final atBottom =
        _scroll.position.pixels >= (_scroll.position.maxScrollExtent - 48);
    if (_showJumpToBottom == !atBottom) {
      setState(() => _showJumpToBottom = !atBottom);
    }
  }

  void _jumpToBottom({bool instant = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent + 80;
      if (instant) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /* ====================== HELPERS ====================== */

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _initials(String s) {
    final parts =
        s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final a = parts.first[0];
    final b = parts.length > 1 ? parts.last[0] : '';
    return (a + b).toUpperCase();
  }

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _shortDate(BuildContext context, DateTime dt) =>
      MaterialLocalizations.of(context).formatShortDate(dt);

  /* ====================== UI ====================== */

  @override
  Widget build(BuildContext context) {
    final isRtl = _isRtl(context);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text(widget.title)),
        body: SafeArea(
          child: Column(
            children: [
              if ((widget.productTitle?.isNotEmpty ?? false) ||
                  (widget.productImage?.isNotEmpty ?? false))
                _ProductHeader(
                  title: widget.productTitle,
                  imageUrl: widget.productImage,
                ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? const Center(child: Text('گفتگویی ثبت نشده است.'))
                        : ListView.separated(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            itemCount: _messages.length +
                                _dateSeparatorsCount(_messages),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 2),
                            itemBuilder: (_, virtualIndex) {
                              final map = _virtualIndexToRealIndex(
                                  virtualIndex, _messages);
                              if (map.isSeparator) {
                                return _DateChip(
                                    text: _shortDate(context, map.date!));
                              }
                              final i = map.realIndex!;
                              final m = _messages[i];
                              return _MessageBubble(
                                text: m.text,
                                time: _time(m.createdAt),
                                isMe: m.isMine ?? false,
                                senderAvatar: (m.senderName?.isNotEmpty ?? false)
                                    ? _initials(m.senderName!)
                                    : null,
                                onLongPress: () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: m.text));
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('پیام کپی شد')),
                                  );
                                },
                              );
                            },
                          ),
              ),

              AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: _InputBar(
                  controller: _ctl,
                  onSend: _send,
                  sending: _sending,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _showJumpToBottom
            ? FloatingActionButton.small(
                onPressed: () => _jumpToBottom(),
                child: const Icon(Icons.arrow_downward),
              )
            : null,
      ),
    );
  }

  /* --------- منطقِ جداکننده تاریخ بین پیام‌ها --------- */

  int _dateSeparatorsCount(List<Message> list) {
    if (list.isEmpty) return 0;
    int c = 1; // اولین روز
    for (int i = 1; i < list.length; i++) {
      if (!_sameDay(list[i - 1].createdAt, list[i].createdAt)) c++;
    }
    return c;
  }

  _VirtualIndex _virtualIndexToRealIndex(int vIndex, List<Message> list) {
    DateTime? currentDay;
    int separatorsSoFar = 0;
    for (int i = 0; i < list.length; i++) {
      final d = DateTime(list[i].createdAt.year, list[i].createdAt.month,
          list[i].createdAt.day);
      final isNewDay = currentDay == null || d != currentDay;
      if (isNewDay) {
        if (vIndex == separatorsSoFar) {
          return _VirtualIndex.separator(date: d);
        }
        separatorsSoFar++;
        currentDay = d;
      }
      if (vIndex == i + separatorsSoFar) {
        return _VirtualIndex.realIndex(i);
      }
    }
    final lastDay = list.isNotEmpty
        ? DateTime(list.last.createdAt.year, list.last.createdAt.month,
            list.last.createdAt.day)
        : null;
    return _VirtualIndex.separator(date: lastDay);
  }
}

/* =================== مدلِ اندیس مجازی =================== */

class _VirtualIndex {
  final bool isSeparator;
  final int? realIndex;
  final DateTime? date;
  _VirtualIndex.realIndex(this.realIndex)
      : isSeparator = false,
        date = null;
  _VirtualIndex.separator({required this.date})
      : isSeparator = true,
        realIndex = null;
}

/* ======================= ویجت‌ها ======================= */

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({this.title, this.imageUrl});
  final String? title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if ((title?.isEmpty ?? true) && (imageUrl?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          if (imageUrl?.isNotEmpty ?? false)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl!,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 54, height: 54, child: Icon(Icons.image)),
              ),
            ),
          if (imageUrl?.isNotEmpty ?? false) const SizedBox(width: 10),
          Expanded(
            child: Text(
              title ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    this.senderAvatar,
    this.onLongPress,
  });

  final String text;
  final String time;
  final bool isMe;
  final String? senderAvatar;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg =
        isMe ? theme.colorScheme.primary.withOpacity(.88) : theme.colorScheme.surfaceVariant;
    final fg = isMe ? Colors.white : theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && senderAvatar != null && senderAvatar!.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: CircleAvatar(
                radius: 12,
                child: Text(
                  senderAvatar!,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints:
                  BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(text, style: TextStyle(color: fg, height: 1.25)),
                  const SizedBox(height: 4),
                  Text(time, style: TextStyle(color: fg.withOpacity(.85), fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.sending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;

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
            FilledButton.icon(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(sending ? 'در حال ارسال…' : 'ارسال'),
            ),
          ],
        ),
      ),
    );
  }
}
