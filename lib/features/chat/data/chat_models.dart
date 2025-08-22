import 'package:flutter/foundation.dart';

/// نوع پیام
enum MessageType { text, image }

/// مدل پیام
@immutable
class Message {
  final String id;
  final String chatId;

  final String senderId;
  final String? senderDisplayName;
  final String? senderAvatar;

  final String? text;
  final String? imageUrl;

  final DateTime sentAt;
  final MessageType type;

  final Map<String, bool> readBy;
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
    this.type = MessageType.text,
    this.readBy = const {},
    this.replyToMessageId,
  });

  bool isMine(String myUid) => senderId == myUid;

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderDisplayName: map['senderDisplayName'],
      senderAvatar: map['senderAvatar'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      sentAt: DateTime.tryParse('${map['sentAt']}') ?? DateTime.now(),
      type: map['type'] == 'image' ? MessageType.image : MessageType.text,
      readBy: Map<String, bool>.from(map['readBy'] ?? {}),
      replyToMessageId: map['replyToMessageId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'senderDisplayName': senderDisplayName,
        'senderAvatar': senderAvatar,
        'text': text,
        'imageUrl': imageUrl,
        'sentAt': sentAt.toIso8601String(),
        'type': type == MessageType.image ? 'image' : 'text',
        'readBy': readBy,
        'replyToMessageId': replyToMessageId,
      };
}

/// مدل گفتگو (Chat)
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
