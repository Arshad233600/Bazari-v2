import 'package:flutter/material.dart';
import '../data/chat_repository.dart';

class ChatBadgeAction extends StatelessWidget {
  const ChatBadgeAction({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ChatRepository.instance;
    return ValueListenableBuilder<int>(
      valueListenable: repo.unreadCount,
      builder: (_, v, __) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                // TODO: برو به ChatListPage
              },
            ),
            if (v > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$v', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              )
          ],
        );
      },
    );
  }
}
