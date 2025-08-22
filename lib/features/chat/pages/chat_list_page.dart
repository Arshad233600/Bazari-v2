// lib/features/chat/pages/chat_list_page.dart
import 'package:flutter/material.dart';
import '../data/chat_repository.dart';
import '../data/chat_models.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _repo = ChatRepository.instance;

  List<Chat> _items = <Chat>[];
  bool _loading = true;
  String _q = ''; // عبارت جستجو

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.getChats();
      // مرتب‌سازی نزولی بر اساس آخرین بروزرسانی
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در دریافت گفتگوها: $e')),
      );
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fmtWhen(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final loc = MaterialLocalizations.of(context);
    if (_sameDay(dt, now)) {
      return loc.formatTimeOfDay(TimeOfDay.fromDateTime(dt), alwaysUse24HourFormat: true);
    }
    return loc.formatShortDate(dt);
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final a = parts.first[0];
    final b = parts.length > 1 ? parts.last[0] : '';
    return (a + b).toUpperCase();
  }

  Color _avatarBg(String s, ColorScheme cs) {
    // رنگ پس‌زمینهٔ آواتار بر اساس hash ساده
    final palettes = <Color>[
      cs.primaryContainer,
      cs.secondaryContainer,
      cs.tertiaryContainer,
      cs.surfaceContainerHighest,
    ];
    final i = s.hashCode.abs() % palettes.length;
    return palettes[i];
  }

  Color _avatarFg(Color bg, ColorScheme cs) {
    // متن آواتار با کنتراست مناسب
    final map = {
      cs.primaryContainer: cs.onPrimaryContainer,
      cs.secondaryContainer: cs.onSecondaryContainer,
      cs.tertiaryContainer: cs.onTertiaryContainer,
      cs.surfaceContainerHighest: cs.onSurface,
    };
    return map[bg] ?? cs.onSurface;
  }

  List<Chat> get _filtered {
    if (_q.trim().isEmpty) return _items;
    final q = _q.trim().toLowerCase();
    return _items.where((c) {
      final t = c.title.toLowerCase();
      final s = c.subtitle.toLowerCase();
      return t.contains(q) || s.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sepColor = Theme.of(context).dividerColor;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('گفتگوها'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'جستجو در عنوان یا آخرین پیام…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'به‌روزرسانی',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: _filtered.isEmpty
            ? const _EmptyChats()
            : ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _filtered.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: sepColor),
          itemBuilder: (context, i) {
            final c = _filtered[i];
            final bg = _avatarBg(c.title, cs);
            final fg = _avatarFg(bg, cs);
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: bg,
                child: Text(_initials(c.title), style: TextStyle(color: fg)),
              ),
              title: Text(
                c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                c.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtWhen(context, c.updatedAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  if (c.unread > 0) _UnreadDot(count: c.unread),
                ],
              ),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatRoomPage(
                      chatId: c.id,
                      title: c.title,
                      // اگر خواستی: productTitle/image را هم پاس بده
                    ),
                  ),
                );
                await _load(); // پس از برگشت، نخوانده‌ها را بروزرسانی کن
              },
            );
          },
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.count});
  final int count;

  String _cap(int n) => n > 99 ? '99+' : '$n';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _cap(count),
        style: TextStyle(
          color: cs.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.forum_outlined, size: 56, color: cs.outline),
        const SizedBox(height: 12),
        const Center(
          child: Text('هنوز گفتگویی ندارید', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text('برای شروع، وارد یک محصول شوید و پیام بدهید.',
              style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 420),
      ],
    );
  }
}

