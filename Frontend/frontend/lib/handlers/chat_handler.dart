import '../models/chat_message_model.dart';

/// Chat Handler - Mock implementation
/// TODO: Backend sẽ thay thế bằng API thật
class ChatHandler {
  // Mock responses
  // Mock responses based on USER DEMO script
  static final List<Map<String, dynamic>> _mockResponses = [
    {
      'keywords': ['khẩu vị', 'gợi ý'],
      'response':
          'Dựa trên khẩu vị bạn hay thích món Việt và ăn cay, mình gợi ý: \n(1) Bún bò Huế (cay vừa–cay)\n(2) Bánh canh cua\n(3) Phở bò tái.\n\nBạn đang ở khu vực nào (quận/phường hoặc gửi tọa độ) để mình gợi ý quán gần nhất?',
      'quickReplies': ['Quận 1', 'Quận 3', 'Gửi tọa độ'],
    },
    {
      'keywords': ['quận 1', 'nhà thờ đức bà'],
      'response':
          'Ok! Gần Nhà thờ Đức Bà, bạn muốn ăn món nước hay món khô? Nếu bạn muốn món nước, mình ưu tiên bún bò Huế hoặc phở bò.',
      'quickReplies': ['Món nước', 'Món khô'],
    },
    {
      'keywords': ['món nước', 'cay vừa'],
      'response':
          'Vậy mình gợi ý **bún bò Huế cay vừa** hoặc **phở bò tái** (có thể xin thêm tương ớt). Bạn muốn mình gợi ý theo tiêu chí gần nhất hay rating cao hơn?',
      'quickReplies': ['Rating cao hơn', 'Gần nhất'],
    },
    {
      'keywords': ['rating cao hơn', 'rating'],
      'response':
          'Ok, mình sẽ ưu tiên các quán bún bò/phở có rating cao quanh trung tâm Quận 1. Nếu bạn cho mình vị trí chính xác hơn (tọa độ/địa chỉ), mình sẽ sắp xếp theo khoảng cách và gợi ý 3 quán phù hợp nhất.',
      'quickReplies': ['Gửi tọa độ', 'Nhập địa chỉ'],
    },
    {
      'keywords': ['10.7809, 106.6992', '10.78', 'tọa độ'],
      'response':
          'Ok, mình đã có vị trí của bạn. Bạn muốn bán kính tìm kiếm khoảng bao nhiêu (1–3km hay 5km) và mức giá bình dân hay tầm trung?',
      'quickReplies': ['3km, tầm trung', '1km, bình dân'],
    },
    {
      'keywords': ['3km', 'tầm trung'],
      'response':
          'Ok. Dựa trên khẩu vị ăn cay vừa và ưu tiên rating cao trong bán kính 3km, mình sẽ gợi ý 3 lựa chọn phù hợp nhất.',
      'quickReplies': ['Tôi không ăn hành', 'Đợi chút'],
    },
    {
      'keywords': ['không ăn hành', 'hành'],
      'response':
          'Mình đã ghi nhận bạn không ăn hành. Khi gọi món phở/bún bò, bạn nhớ dặn “không hành” là ổn. Giờ mình sẽ ưu tiên các quán dễ tuỳ chỉnh topping.',
      'quickReplies': ['Cho tôi 3 quán cụ thể'],
    },
    {
      'keywords': ['3 quán cụ thể', 'cụ thể'],
      'response':
          'Demo gợi ý (bán kính ~3km, tầm trung, rating cao):\n(1) Phở A – ~1.2km\n(2) Bún bò B – ~1.8km\n(3) Phở C – ~2.5km.\n\nBạn muốn ưu tiên phở hay bún bò để mình chốt 1 quán phù hợp nhất?',
      'quickReplies': ['Ưu tiên bún bò', 'Ưu tiên phở'],
    },
    {
      'keywords': ['ưu tiên bún bò', 'bún bò'],
      'response':
          'Vậy mình đề xuất **Bún bò B** (gần ~1.8km, hợp khẩu vị cay vừa). Bạn đi một mình hay đi nhóm để mình gợi ý thêm món gọi kèm (chả cua, giò heo, huyết)?',
      'quickReplies': ['Đi một mình', 'Đi nhóm'],
    },
    // Keep some generic ones as fallback
    {
      'keywords': ['xin chào', 'hello', 'hi'],
      'response':
          'Xin chào! Tôi là trợ lý ảo. Bạn có thể hỏi "Theo khẩu vị của tôi, gợi ý món ăn gần đây" để bắt đầu.',
      'quickReplies': ['Gợi ý món ăn gần đây'],
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
