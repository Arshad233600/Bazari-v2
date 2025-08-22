import 'package:flutter/material.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _repo = ChatRepository.instance;
  List<Chat> _items = <Chat>[];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.getChats();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    setState(() => _items = list);
  }

  List<Chat> get _filtered {
    if (_query.trim().isEmpty) return _items;
    final q = _query.trim().toLowerCase();
    return _items.where((c) {
      final t = c.title.toLowerCase();
      final s = c.subtitle.toLowerCase();
      return t.contains(q) || s.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('گفتگوها'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: _repo.unreadCount,
            builder: (_, v, __) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Center(child: Text('ناخوانده: $v')),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final c = items[i];
            return ListTile(
              leading: CircleAvatar(child: Text(c.title.characters.first.toUpperCase())),
              title: Text(c.title),
              subtitle: Text(c.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: c.unread > 0
                  ? CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text('${c.unread}',
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomPage(
                      chatId: c.id,
                      meId: 'me',
                      peerTitle: c.title, // ← قبلاً اشتباه title: بود
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
