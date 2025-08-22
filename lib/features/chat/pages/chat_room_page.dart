import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../data/chat_repository.dart';
import '../data/chat_models.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String title;

  final String? productTitle;
  final String? productImage;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.title,
    this.productTitle,
    this.productImage,
  });

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
        const {'fa','ar','ur','ps','he'}.contains(code);
  }

  Future<void> _load() async {
    await Future.sync(() => _repo.markRead(widget.chatId)); // safe for void/Future<void>
    final list = await _repo.getMessages(widget.chatId);
    if (!mounted) return;
    setState(() {
      _messages = list;
      _loading = false;
    });
    _jumpToBottom(instant: true);
  }

  void _onScrollChanged() {
    if (!_scroll.hasClients) return;
    final atBottom = _scroll.position.pixels >= (_scroll.position.maxScrollExtent - 48);
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
        _scroll.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.sendMessage(widget.chatId, text);
      _ctl.clear();
      await _load();
      _jumpToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

  String _shortDate(BuildContext context, DateTime dt) {
    final loc = MaterialLocalizations.of(context);
    return loc.formatShortDate(dt);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRtl = _isRtl(context);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(radius: 18, child: Text(_initials(widget.title))),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.title, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if ((widget.productTitle?.isNotEmpty ?? false) ||
                    (widget.productImage?.isNotEmpty ?? false))
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        if ((widget.productImage?.isNotEmpty ?? false))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.productImage!,
                              width: 56, height: 56, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 56, height: 56, child: Icon(Icons.image_not_supported_outlined),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 56, height: 56, child: Icon(Icons.image_outlined)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.productTitle ?? '—',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : (_messages.isEmpty)
                      ? _EmptyState(onRefresh: _load)
                      : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) {
                        final m = _messages[i];
                        final isMine = m.sender == 'me';
                        final showDateChip = i == 0 ||
                            !_sameDay(m.createdAt, _messages[i - 1].createdAt);

                        final bubble = Align(
                          alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 340),
                            child: GestureDetector(
                              onLongPress: () {
                                final t = m.text.trim();
                                if (t.isEmpty) return;
                                Clipboard.setData(ClipboardData(text: t));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('متن کپی شد')),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? cs.primaryContainer
                                      : cs.surfaceContainerHighest,
                                  borderRadius:
                                  BorderRadius.circular(12).copyWith(
                                    bottomLeft:
                                    Radius.circular(isMine ? 12 : 2),
                                    bottomRight:
                                    Radius.circular(isMine ? 2 : 12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMine
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    // جهت متن را با RTL/LTR هماهنگ کن
                                    Directionality(
                                      textDirection: isRtl
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                      child: Text(
                                        m.text,
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(fontSize: 15, height: 1.35),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_time(m.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        if (!showDateChip) return bubble;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 4),
                            _DateChip(label: _shortDate(context, m.createdAt)),
                            const SizedBox(height: 8),
                            bubble,
                          ],
                        );
                      },
                    ),
                  ),
                ),

                _Composer(controller: _ctl, sending: _sending, onSend: _send),
              ],
            ),

            if (_showJumpToBottom)
              Positioned(
                right: 12,
                bottom: 86,
                child: FloatingActionButton.small(
                  onPressed: _jumpToBottom,
                  tooltip: 'رفتن به انتهای گفتگو',
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------- Sub-widgets ------------------------- */

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;

  const _Composer({
    required this.controller,
    required this.onSend,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
            Expanded(
              child: Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'یک پیام بنویسید…',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    filled: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: sending
                  ? const Padding(
                key: ValueKey('sending'),
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : FilledButton.icon(
                key: const ValueKey('send'),
                onPressed: onSend,
                icon: const Icon(Icons.send),
                label: const Text('ارسال'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.78),
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.chat_bubble_outline, size: 48),
          SizedBox(height: 12),
          Center(child: Text('هنوز پیامی وجود ندارد', style: TextStyle(fontSize: 15))),
          SizedBox(height: 8),
          Center(child: Text('اولین پیام را شما بفرستید ✨', style: TextStyle(fontSize: 13))),
          SizedBox(height: 400),
        ],
      ),
    );
  }
}
