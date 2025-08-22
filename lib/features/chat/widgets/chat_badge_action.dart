import 'package:flutter/material.dart';
import '../data/chat_repository.dart';
import '../pages/chat_list_page.dart';

class ChatBadgeAction extends StatelessWidget {
  const ChatBadgeAction({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<int>(
      valueListenable: ChatRepository.instance.unreadCount,
      builder: (context, count, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'گفتگوها',
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatListPage()));
              },
            ),
            if (count > 0)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: TextStyle(color: cs.onError, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
