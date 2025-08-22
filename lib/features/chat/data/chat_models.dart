import 'package:flutter/foundation.dart';

/// نوع پیام
enum MessageType { text, image, sticker, location }

@immutable
class Chat {
  final String id;
  final String title;
  final String subtitle;
  final DateTime updatedAt;
  final int unread;

  const Chat({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    this.unread = 0,
  });

  Chat copyWith({
    String? id,
    String? title,
    String? subtitle,
    DateTime? updatedAt,
    int? unread,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      updatedAt: updatedAt ?? this.updatedAt,
      unread: unread ?? this.unread,
    );
  }
}

@immutable
class Message {
  final String id;
  final String chatId;
  final String sender;        // 'me' یا نام طرف مقابل
  final MessageType type;     // ✅ اجباری
  final String text;          // متن یا کپشن
  final String? mediaUrl;     // برای عکس/استیکر
  final double? lat;          // برای لوکیشن
  final double? lng;          // برای لوکیشن
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.type,       // ✅
    this.text = '',
    this.mediaUrl,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  bool get isMine => sender == 'me';
}
