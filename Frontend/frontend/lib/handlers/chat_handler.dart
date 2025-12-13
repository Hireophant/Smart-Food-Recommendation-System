import 'dart:async';

/// Model cho tin nhắn chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Interface cho Chat Handler
abstract class ChatHandler {
  /// Gửi tin nhắn và nhận phản hồi (Stream để hỗ trợ typing effect hoặc multi-part response)
  Stream<ChatMessage> sendMessage(String message);

  /// Lấy lịch sử chat (nếu có lưu trữ)
  Future<List<ChatMessage>> getChatHistory();
}

/// Mock Implementation giả lập AI
class MockChatHandler implements ChatHandler {
  final List<ChatMessage> _history = [
    ChatMessage(
      text: "Chào bạn! Mình có thể giúp gì cho bạn hôm nay?",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  Future<List<ChatMessage>> getChatHistory() async {
    // Giả lập delay loading
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_history);
  }

  @override
  Stream<ChatMessage> sendMessage(String message) async* {
    // 1. Lưu tin nhắn user
    final userMsg = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _history.add(userMsg);

    // 2. Giả lập "AI đang suy nghĩ..."
    await Future.delayed(const Duration(seconds: 1));

    // 3. Logic phản hồi giả
    String responseText;
    final lowerMsg = message.toLowerCase();

    if (lowerMsg.contains("frontend") || lowerMsg.contains("giao diện")) {
      responseText =
          "Về Frontend, mình được xây dựng bằng Flutter. Mình tuân thủ kiến trúc 'Interface First' trong Guideline.md, sử dụng QuerySystem làm trung tâm điều phối.";
    } else if (lowerMsg.contains("tìm") || lowerMsg.contains("search")) {
      responseText =
          "Bạn có thể tìm kiếm món ăn bằng cách nhập tên hoặc tag (như 'Cay', 'Nóng') vào thanh tìm kiếm ở trang Khám phá.";
    } else if (lowerMsg.contains("hello") || lowerMsg.contains("chào")) {
      responseText = "Chào bạn! Rất vui được gặp bạn.";
    } else {
      responseText =
          "Thú vị quá! Hiện tại mình chỉ là bản demo nên chưa hiểu hết ý bạn, nhưng mình có thể giúp bạn giải đáp về kiến trúc Frontend của dự án này.";
    }

    // 4. Trả về phản hồi AI
    final aiMsg = ChatMessage(
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _history.add(aiMsg);

    yield aiMsg;
  }
}
