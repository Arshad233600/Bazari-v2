import 'package:flutter/foundation.dart';

/// مدل واحد پیام چت (سازگار با Firestore هم هست)
@immutable
class Message {
  final String id;
  final String chatId;

  final String senderId;
  final String? senderDisplayName; // ← بجای senderName
  final String? senderAvatar;      // url اختیاری

  final String? text;
  final String? imageUrl;

  final DateTime sentAt;

  /// نقشهٔ خوانده‌شدن‌ها: {uid: true}
  final Map<String, bool> readBy;

  /// برای ریپلای/کوت (اختیاری)
  final String? replyToMessageId;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderDisplayName,
    this.senderAvatar,
    this.text,
    this.imageUrl,
    required this.sentAt,
    this.readBy = const {},
    this.replyToMessageId,
  });

  /// کمکی: آیا این پیام متعلق به کاربر جاری است؟
  bool isMine(String myUid) => senderId == myUid;

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderDisplayName,
    String? senderAvatar,
    String? text,
    String? imageUrl,
    DateTime? sentAt,
    Map<String, bool>? readBy,
    String? replyToMessageId,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      sentAt: sentAt ?? this.sentAt,
      readBy: readBy ?? this.readBy,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }

  /// مبدل Firestore → مدل
  factory Message.fromMap(String id, Map<String, dynamic> map) {
    DateTime _dt(dynamic v) {
      if (v is DateTime) return v;
      // Timestamp(seconds, nanoseconds) یا millisecondsSinceEpoch
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      final t = map['sentAt'];
      // اگر از cloud_firestore استفاده می‌کنی، اینجا:
      // if (t is Timestamp) return t.toDate();
      // ولی برای مستقل بودن از Firebase:
      return DateTime.tryParse('$t') ?? DateTime.now();
    }

    final rb = <String, bool>{};
    final rawRb = map['readBy'];
    if (rawRb is Map) {
      rawRb.forEach((k, v) {
        rb['$k'] = v == true;
      });
    }

    return Message(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderDisplayName: map['senderDisplayName'] as String?,
      senderAvatar: map['senderAvatar'] as String?,
      text: map['text'] as String?,
      imageUrl: map['imageUrl'] as String?,
      sentAt: _dt(map['sentAt']),
      readBy: rb,
      replyToMessageId: map['replyToMessageId'] as String?,
    );
  }

  /// مدل → Map (برای ذخیره در Firestore)
  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'senderDisplayName': senderDisplayName,
        'senderAvatar': senderAvatar,
        'text': text,
        'imageUrl': imageUrl,
        // اگر از Firestore استفاده می‌کنی و Timestamp می‌خواهی، بجایش FieldValue.serverTimestamp()
        'sentAt': sentAt.millisecondsSinceEpoch,
        'readBy': readBy,
        'replyToMessageId': replyToMessageId,
      };
}

class Chat {
  final String id;
  final String title;        // نام مخاطب یا گروه
  final String subtitle;     // آخرین پیام
  final DateTime updatedAt;  // آخرین آپدیت
  final int unread;          // تعداد پیام‌های ناخوانده

  const Chat({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.unread,
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
