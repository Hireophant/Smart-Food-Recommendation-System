import '../models/chat_message_model.dart';

/// Chat Handler - Mock implementation
/// TODO: Backend sẽ thay thế bằng API thật
class ChatHandler {
  // Mock responses
  static final List<Map<String, dynamic>> _mockResponses = [
    {
      'keywords': ['xin chào', 'hello', 'hi', 'chào'],
      'response':
          'Xin chào! Tôi là trợ lý ảo của Gợi ý Món Ngon. Tôi có thể giúp bạn tìm nhà hàng, gợi ý món ăn. Bạn cần gì nhỉ?',
      'quickReplies': ['Tìm nhà hàng', 'Gợi ý món ăn', 'Món gì ngon?'],
    },
    {
      'keywords': ['tìm nhà hàng', 'nhà hàng', 'quán'],
      'response':
          'Bạn muốn tìm nhà hàng ở khu vực nào? Hoặc bạn có món ăn yêu thích nào không?',
      'quickReplies': ['Phở', 'Bún bò', 'Cơm tấm', 'Cafe'],
    },
    {
      'keywords': ['phở', 'pho'],
      'response':
          'Phở là món ăn tuyệt vời! Tôi tìm thấy 12 nhà hàng phở gần bạn. Bạn thích phở bò hay phở gà?',
      'quickReplies': ['Phở bò', 'Phở gà', 'Xem trên bản đồ'],
    },
    {
      'keywords': ['gợi ý', 'món gì', 'ăn gì'],
      'response':
          'Hôm nay bạn có thể thử các món này: Phở bò, Bún chả, Cơm tấm, hoặc Bánh mì. Bạn thích món nào?',
      'quickReplies': ['Phở bò', 'Bún chả', 'Cơm tấm', 'Bánh mì'],
    },
    {
      'keywords': ['cảm ơn', 'thank', 'thanks'],
      'response': 'Không có gì! Nếu cần gì thêm, cứ hỏi tôi nhé! 😊',
      'quickReplies': ['Tìm món khác', 'Xem bản đồ'],
    },
  ];

  /// Gửi tin nhắn và nhận phản hồi từ bot (Mock)
  static Future<BotResponse> sendMessage(String userMessage) async {
    // Giả lập delay network
    await Future.delayed(const Duration(milliseconds: 800));

    // Tìm response phù hợp
    final lowerMessage = userMessage.toLowerCase();

    for (var mockResponse in _mockResponses) {
      final keywords = mockResponse['keywords'] as List<String>;
      if (keywords.any((keyword) => lowerMessage.contains(keyword))) {
        return BotResponse(
          message: mockResponse['response'] as String,
          quickReplies: (mockResponse['quickReplies'] as List?)?.cast<String>(),
        );
      }
    }

    // Default response
    return BotResponse(
      message:
          'Hmm, tôi không hiểu lắm. Bạn có thể hỏi tôi về nhà hàng, món ăn, hoặc địa điểm ăn uống nhé!',
      quickReplies: ['Tìm nhà hàng', 'Gợi ý món ăn', 'Trợ giúp'],
    );
  }

  /// Lấy tin nhắn chào mừng
  static BotResponse getWelcomeMessage() {
    return BotResponse(
      message:
          'Xin chào! Tôi là trợ lý ảo. Tôi có thể giúp bạn tìm nhà hàng và gợi ý món ăn. Bạn muốn làm gì?',
      quickReplies: ['Tìm nhà hàng', 'Gợi ý món ăn', 'Món ngon gần đây'],
    );
  }
}
