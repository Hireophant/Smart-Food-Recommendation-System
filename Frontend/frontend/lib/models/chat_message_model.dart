/// Model cho tin nhắn chat
class ChatMessage {
  final String id;
  final String content;
  final bool isUser; // true = user, false = bot
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
  });
}

/// Loại tin nhắn
enum MessageType {
  text, // Tin nhắn văn bản
  suggestion, // Gợi ý nhanh
  restaurantCard, // Card nhà hàng
}

/// Mock Response từ Bot
class BotResponse {
  final String message;
  final List<String>? quickReplies;

  BotResponse({required this.message, this.quickReplies});
}
