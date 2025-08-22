import 'dart:async';

class ChatMessage {
  final String id; final String from; final String text; final DateTime ts;
  ChatMessage({required this.id, required this.from, required this.text, required this.ts});
}

class LocalChatService {
  final _controller = StreamController<List<ChatMessage>>.broadcast();
  final List<ChatMessage> _messages = [];

  Stream<List<ChatMessage>> messages() => _controller.stream;

  void send(String from, String text){
    final m = ChatMessage(id: DateTime.now().microsecondsSinceEpoch.toString(), from: from, text: text, ts: DateTime.now());
    _messages.add(m);
    _controller.add(List.unmodifiable(_messages));
  }
}