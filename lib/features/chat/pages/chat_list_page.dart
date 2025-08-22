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
  List<Chat> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chats = await _repo.getChats();
    setState(() {
      _items = chats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("پیام‌ها")),
      body: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, i) {
          final c = _items[i];
          return ListTile(
            title: Text(c.title),
            subtitle: Text(c.subtitle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomPage(
                    chatId: c.id,
                    meId: 'me', // TODO: از AuthService بگیر
                    peerTitle: c.title,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
