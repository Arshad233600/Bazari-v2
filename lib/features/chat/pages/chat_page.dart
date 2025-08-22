// lib/features/chat/pages/chat_page.dart
import 'dart:convert';
import 'dart:math' as math; // NEW: برای pi
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback; // NEW

/// نوع پیام
enum ChatMessageType { text, image, sticker }

/// مدل سادهٔ پیام
class ChatMessage {
  final String id;
  final ChatMessageType type;
  final String text;       // متن یا کپشن
  final String? mediaUrl;  // لینک عکس/استیکر (http/https یا data:image/...)
  final bool isMe;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.type,
    required this.text,
    required this.isMe,
    required this.sentAt,
    this.mediaUrl,
  });
}

/// صفحهٔ چت حرفه‌ای با پس‌زمینه واترمارک برند
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.peerName,
    this.peerAvatarUrl,
    this.brandMark = 'BAZARI • 8656', // ← نام برند روی پس‌زمینه (دلخواه)
  });

  final String? peerName;
  final String? peerAvatarUrl;
  final String brandMark;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messages = <ChatMessage>[
    ChatMessage(
      id: '1',
      type: ChatMessageType.text,
      text: 'سلام! 👋',
      isMe: false,
      sentAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    ChatMessage(
      id: '2',
      type: ChatMessageType.text,
      text: 'سلام، حالت خوبه؟',
      isMe: true,
      sentAt: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  final _inputCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  bool _showJumpToBottom = false; // NEW

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScrollToEnd(jump: true));
    _scrollCtl.addListener(_onScrollChanged); // NEW
  }

  @override
  void dispose() {
    _scrollCtl.removeListener(_onScrollChanged); // NEW
    _inputCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  /* -------------------------- Helpers -------------------------- */

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fmtTime(BuildContext context, DateTime dt) {
    final loc = MaterialLocalizations.of(context);
    return loc.formatTimeOfDay(
      TimeOfDay.fromDateTime(dt),
      alwaysUse24HourFormat: true,
    );
  }

  String _fmtDate(BuildContext context, DateTime dt) {
    final loc = MaterialLocalizations.of(context);
    return loc.formatShortDate(dt);
  }

  void _onScrollChanged() { // NEW
    if (!_scrollCtl.hasClients) return;
    final atBottom = (_scrollCtl.position.pixels >=
        _scrollCtl.position.maxScrollExtent - 48);
    if (_showJumpToBottom == !atBottom) {
      setState(() => _showJumpToBottom = !atBottom);
    }
  }

  void _autoScrollToEnd({bool jump = false}) {
    if (!_scrollCtl.hasClients) return;
    final target = _scrollCtl.position.maxScrollExtent + 120;
    if (jump) {
      _scrollCtl.jumpTo(_scrollCtl.position.maxScrollExtent);
    } else {
      _scrollCtl.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendText() {
    final text = _inputCtl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: ChatMessageType.text,
        text: text,
        isMe: true,
        sentAt: DateTime.now(),
      ));
      _inputCtl.clear();
    });
    _autoScrollToEnd();
  }

  Future<void> _openAttachSheet() async {
    final sel = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _BSItem(icon: Icons.image_outlined, label: 'ارسال عکس (لینک یا Base64)', value: 'image'),
            _BSItem(icon: Icons.emoji_emotions_outlined, label: 'ارسال استیکر', value: 'sticker'),
          ],
        ),
      ),
    );

    if (sel == 'image') {
      await _pickImageByUrlOrBase64();
    } else if (sel == 'sticker') {
      await _pickSticker();
    }
  }

  /// بدون پکیج: از کاربر لینک http/https یا data:image/...;base64,... می‌گیرد
  Future<void> _pickImageByUrlOrBase64() async {
    final ctlUrl = TextEditingController();
    final ctlCaption = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ارسال عکس'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctlUrl,
              decoration: const InputDecoration(
                labelText: 'لینک عکس یا Base64',
                hintText: 'https://... یا data:image/jpeg;base64,...',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctlCaption,
              decoration: const InputDecoration(labelText: 'کپشن (اختیاری)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('ارسال')),
        ],
      ),
    );

    if (ok != true) return;

    final raw = ctlUrl.text.trim();
    if (raw.isEmpty) return;

    final valid = raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('data:image/');

    if (!valid) return; // جلوگیری از ورودی نامعتبر

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: ChatMessageType.image,
        text: ctlCaption.text.trim(),
        mediaUrl: raw,
        isMe: true,
        sentAt: DateTime.now(),
      ));
    });
    _autoScrollToEnd();
  }

  /// انتخاب استیکر از مجموعهٔ آماده (CDN) — بدون وابستگی
  Future<void> _pickSticker() async {
    const stickers = <String>[
      'https://raw.githubusercontent.com/twitter/twemoji/master/assets/72x72/1f60a.png', // 😊
      'https://raw.githubusercontent.com/twitter/twemoji/master/assets/72x72/1f44d.png', // 👍
      'https://raw.githubusercontent.com/twitter/twemoji/master/assets/72x72/1f389.png', // 🎉
      'https://raw.githubusercontent.com/twitter/twemoji/master/assets/72x72/2764.png',  // ❤
      'https://raw.githubusercontent.com/twitter/twemoji/master/assets/72x72/1f525.png', // 🔥
      'https://raw.githubusercontent.com/twitter/twemoji/master/assets/72x72/1f44f.png', // 👏
      'https://raw.githubusercontent.com/twitter/twemoji/master/assets/72x72/1f642.png', // 🙂
      'https://raw.githubusercontent.com/twitter/twemoji/master/assets/72x72/1f602.png', // 😂
      'https://raw.githubusercontent.com/twitter/twemoji/master/assets/72x72/1f60d.png', // 😍
      'https://raw.githubusercontent.com/twitter/twemoji/master/assets/72x72/1f44c.png', // 👌
    ];

    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (c) {
        final pad = MediaQuery.of(c).padding.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: pad),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: stickers.length,
              itemBuilder: (_, i) {
                final url = stickers[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(c, url),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(c).colorScheme.surfaceVariant,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(child: Text('⚠')),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (chosen == null) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: ChatMessageType.sticker,
        text: '',
        mediaUrl: chosen,
        isMe: true,
        sentAt: DateTime.now(),
      ));
    });
    _autoScrollToEnd();
  }

  /* -------------------------- UI Parts -------------------------- */

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // پس‌زمینه: گرادیان نرم + واترمارک برند
      body: Stack(
        children: [
          // گرادیان لطیف
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    cs.surfaceVariant.withOpacity(0.28),
                    cs.surfaceVariant.withOpacity(0.12),
                  ],
                ),
              ),
            ),
          ),
          // واترمارک برند (تکرارشونده و مورّب)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WatermarkPainter(
                  text: widget.brandMark,
                  color: cs.onSurface.withOpacity(0.05),
                  angleDegrees: -22,
                  gap: 120,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          // محتوای چت
          Column(
            children: [
              _ChatAppBar(
                title: (widget.peerName?.isNotEmpty ?? false)
                    ? 'چت با ${widget.peerName}'
                    : 'چت',
                avatarUrl: widget.peerAvatarUrl,
                subtitle: 'آنلاین', // می‌توانی وضعیت را پویا کنی
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: ListView.builder(
                    controller: _scrollCtl,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];

                      // نمایش چیپ تاریخ وقتی روز عوض شود یا اولین آیتم است
                      final showDateHeader = i == 0 ||
                          !_sameDay(m.sentAt, _messages[i - 1].sentAt);

                      return Column(
                        crossAxisAlignment:
                        m.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) ...[
                            const SizedBox(height: 6),
                            _DateChip(label: _fmtDate(context, m.sentAt)),
                            const SizedBox(height: 6),
                          ],
                          GestureDetector(
                            onLongPress: m.type == ChatMessageType.text
                                ? () {
                              HapticFeedback.lightImpact(); // NEW
                              _showMessageMenu(m);
                            }
                                : null,
                            child: _buildBubble(context, m),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: EdgeInsets.only(
                              right: m.isMe ? 8 : 0,
                              left: m.isMe ? 0 : 8,
                              bottom: 8,
                            ),
                            child: Text(
                              _fmtTime(context, m.sentAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // نوار ورودی
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'ضمیمه',
                        onPressed: _openAttachSheet,
                        icon: const Icon(Icons.attach_file),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _inputCtl,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendText(),
                          minLines: 1, // NEW
                          maxLines: 4, // NEW
                          decoration: InputDecoration(
                            hintText: 'پیامتان را بنویسید…',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sendText,
                        icon: const Icon(Icons.send_rounded),
                        tooltip: 'ارسال',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // NEW: دکمه پرش به پایین وقتی از انتها دوریم
          if (_showJumpToBottom)
            Positioned(
              right: 12,
              bottom: 88, // بالاتر از نوار ورودی
              child: FloatingActionButton.small(
                onPressed: () => _autoScrollToEnd(jump: false),
                tooltip: 'رفتن به آخر گفتگو',
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, ChatMessage m) {
    final cs = Theme.of(context).colorScheme;
    final textColor = m.isMe ? cs.onPrimary : cs.onSurface;
    final baseBg = m.isMe ? cs.primary : cs.surface;

    final isMedia = m.type == ChatMessageType.image || m.type == ChatMessageType.sticker;
    final bg = isMedia
        ? (m.isMe ? cs.primaryContainer : cs.surface) // مدیا با کانتینر نرم
        : baseBg;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(m.isMe ? 16 : 4),
      bottomRight: Radius.circular(m.isMe ? 4 : 16),
    );

    Widget content;
    switch (m.type) {
      case ChatMessageType.text:
        content = Text(
          m.text,
          textAlign: m.isMe ? TextAlign.right : TextAlign.left, // NEW: کمی بهتر برای RTL
          style: TextStyle(color: textColor, fontSize: 15, height: 1.35),
        );
        break;

      case ChatMessageType.image:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell( // NEW: بازکنندهٔ نمایشگر
                onTap: () => _openImageViewer(m.mediaUrl),
                child: _buildImage(m.mediaUrl),
              ),
            ),
            if (m.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(m.text, style: TextStyle(color: cs.onSurface, fontSize: 14)),
            ],
          ],
        );
        break;

      case ChatMessageType.sticker:
        content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160, maxHeight: 160),
            child: InkWell( // NEW
              onTap: () => _openImageViewer(m.mediaUrl),
              child: _buildImage(m.mediaUrl),
            ),
          ),
        );
        break;
    }

    return Align(
      alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: DecoratedBox(
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMedia ? 8 : 12,
              vertical: isMedia ? 8 : 10,
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('تصویر در دسترس نیست')),
      );
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, p) {
          if (p == null) return child;
          return SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(
                value: p.expectedTotalBytes != null
                    ? p.cumulativeBytesLoaded / (p.expectedTotalBytes ?? 1)
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => const SizedBox(
          height: 140,
          child: Center(child: Text('خطا در بارگذاری تصویر')),
        ),
      );
    }

    if (url.startsWith('data:image/')) {
      try {
        final comma = url.indexOf(',');
        if (comma != -1) {
          final b64 = url.substring(comma + 1);
          final bytes = base64Decode(b64);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 140,
              child: Center(child: Text('Base64 نامعتبر')),
            ),
          );
        }
      } catch (_) {}
      return const SizedBox(
        height: 140,
        child: Center(child: Text('Base64 نامعتبر')),
      );
    }

    return const SizedBox(
      height: 140,
      child: Center(child: Text('فرمت پشتیبانی نمی‌شود')),
    );
  }

  // NEW: نمایشگر سادهٔ عکس/استیکر با زوم (InteractiveViewer)
  void _openImageViewer(String? url) {
    if (url == null || url.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (c) => GestureDetector(
        onTap: () => Navigator.pop(c),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.6,
            maxScale: 4.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(c).size.width,
                maxHeight: MediaQuery.of(c).size.height,
              ),
              child: _buildImage(url),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageMenu(ChatMessage m) {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_all_rounded),
              title: const Text('کپی متن'),
              onTap: () {
                Navigator.pop(c);
                Clipboard.setData(ClipboardData(text: m.text)); // NEW: کپی واقعی
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('متن کپی شد')),
                );
              },
            ),
            if (m.isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('حذف پیام'),
                onTap: () {
                  Navigator.pop(c);
                  setState(() => _messages.removeWhere((x) => x.id == m.id));
                },
              ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------- Sub-widgets & Painters ------------------------- */

class _ChatAppBar extends StatelessWidget {
  const _ChatAppBar({
    required this.title,
    this.subtitle,
    this.avatarUrl,
  });

  final String title;
  final String? subtitle;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.86),
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.surfaceVariant,
              backgroundImage: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: (avatarUrl == null || avatarUrl!.isEmpty)
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              tooltip: 'بستن',
              icon: const Icon(Icons.close),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.75),
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
      ),
    );
  }
}

/// نقاش واترمارک تکراری، مورّب و کمرنگ
class _WatermarkPainter extends CustomPainter {
  _WatermarkPainter({
    required this.text,
    required this.color,
    required this.angleDegrees,
    required this.gap,
    required this.fontSize,
  });

  final String text;
  final Color color;
  final double angleDegrees;
  final double gap;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final radians = angleDegrees * math.pi / 180.0; // NEW
    final tp = TextPainter(
      text: TextSpan(
        text: ' $text ',
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // چرخش کل بوم برای مورّب شدن الگو
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(radians);
    canvas.translate(-size.width / 2, -size.height / 2);

    final stepX = tp.width + gap;
    final stepY = tp.height + gap;

    // شروع از کمی بیرون کادر تا لبه‌ها هم پر شوند
    for (double y = -stepY; y < size.height + stepY; y += stepY) {
      final idx = (y ~/ stepY); // int
      final xOffset = idx.isEven ? 0.0 : stepX / 2; // آفست شطرنجی
      for (double x = -stepX; x < size.width + stepX; x += stepX) {
        tp.paint(canvas, Offset(x + xOffset, y));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WatermarkPainter old) {
    return text != old.text ||
        color != old.color ||
        angleDegrees != old.angleDegrees ||
        gap != old.gap ||
        fontSize != old.fontSize;
  }
}

class _BSItem extends StatelessWidget {
  const _BSItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }
}
