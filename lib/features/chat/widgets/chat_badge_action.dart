// lib/features/chat/widgets/chat_badge_action.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/chat_repository.dart';
import '../pages/chat_list_page.dart';

class ChatBadgeAction extends StatelessWidget {
  const ChatBadgeAction({super.key});

  @override
  Widget build(BuildContext context) {
    // دسترسی داینامیک: اگر unreadCount وجود داشته باشد، از آن استفاده می‌کنیم
    final repoDyn = ChatRepository.instance as dynamic;
    ValueListenable<int>? badge;
    try {
      final v = repoDyn.unreadCount;
      if (v is ValueListenable<int>) {
        badge = v;
      }
    } catch (_) {
      badge = null;
    }

    final button = IconButton(
      icon: const Icon(Icons.chat_bubble_outline),
      tooltip: 'گفتگوها',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatListPage()),
        );
      },
    );

    if (badge == null) {
      // بدون Badge
      return button;
    }

    // با Badge زنده
    return ValueListenableBuilder<int>(
      valueListenable: badge!,
      builder: (_, v, __) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            button,
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
                  child: Text(
                    '$v',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
