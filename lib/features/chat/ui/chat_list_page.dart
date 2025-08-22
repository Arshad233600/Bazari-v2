import 'package:flutter/material.dart';
import '../../chat/data/chat_repository.dart';
import '../data/chat_models.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});
  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _repo = ChatRepository.instance;
  List<Chat> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.getChats();
    if (!mounted) return;
    setState(() { _items = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final c = _items[i];
            final initials = _initials(c.title);
            return ListTile(
              leading: CircleAvatar(child: Text(initials)),
              title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(c.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_humanTime(c.updatedAt), style: Theme.of(context).textTheme.labelSmall),
                  if (c.unread>0)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${c.unread}', style: Theme.of(context).textTheme.labelSmall),
                    ),
                ],
              ),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatRoomPage(chatId: c.id, title: c.title),
                ));
                if (!mounted) return;
                _load();
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // ایجاد چت جدید (در فاز بعدی)
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.length>1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (a+b).toUpperCase();
  }

  String _humanTime(DateTime dt) {
    final now = DateTime.now();
    final d = now.difference(dt);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${dt.month}/${dt.day}';
  }
}
