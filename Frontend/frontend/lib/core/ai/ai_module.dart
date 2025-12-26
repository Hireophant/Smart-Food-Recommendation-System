import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_models.dart';

class AIModule {
  /// URL Backend - Có thể configure khi khởi tạo app
  /// Mặc định: localhost cho development
  static String backendUrl = 'http://127.0.0.1:8000';

  /// Configure backend URL cho các môi trường khác nhau
  ///
  /// Example:
  /// ```dart
  /// // Development (iOS Simulator)
  /// AIModule.configure(backendUrl: 'http://localhost:8000');
  ///
  /// // Development (Android Emulator)
  /// AIModule.configure(backendUrl: 'http://10.0.2.2:8000');
  ///
  /// // Production
  /// AIModule.configure(backendUrl: 'https://api.foodrec.com');
  /// ```
  static void configure({required String backendUrl}) {
    AIModule.backendUrl = backendUrl;
  }

  /// Hàm generate chính: Orchestrator gọi xuống Backend
  static Future<AIResponse> generate({
    required String modelName,
    required List<AIMessage> history,
    required List<AIToolDefinition> tools,
  }) async {
    final url = Uri.parse(
      '$backendUrl/ai',
    ).replace(queryParameters: {'model': modelName});

    // 1. Chuẩn bị payload
    final payload = {
      'inputs': history.map((e) => e.toJson()).toList(),
      'tools': tools.map((e) => e.toJson()).toList(),
      'system_prompts': null, // Có thể thêm system prompt nếu cần
    };

    try {
      // 2. Gọi API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer ...' // Thêm token nếu cần
        },
        body: jsonEncode(payload),
      );

      // 3. Xử lý kết quả
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Backend trả về ObjectResponseSchema -> data['data']
        final aiMessageJson = data['data'];
        final aiMessage = AIMessage.fromJson(aiMessageJson);

        // 4. Convert sang AIResponse cho UI dùng
        return AIResponse(
          message: aiMessage.message,
          toolCalls: aiMessage.toolCalls,
        );
      } else {
        throw Exception('AI Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to AI Service: $e');
    }
  }

  /// Lấy danh sách tools mà Frontend hỗ trợ
  /// Tools này sẽ được Frontend thực thi, không phải Backend
  static List<AIToolDefinition> getTools() {
    return [
      // === Restaurant Search & Discovery ===
      AIToolDefinition(
        name: 'search_restaurants',
        description:
            'Tìm kiếm nhà hàng theo từ khóa, loại món ăn, hoặc tên quán. '
            'Hỗ trợ filter theo khoảng cách, rating, tags.',
        parameters: {
          'query': {
            'type': 'string',
            'description': 'Từ khóa tìm kiếm (món ăn, tên quán,...)',
          },
          'max_distance_km': {
            'type': 'number',
            'description': 'Bán kính tìm kiếm tối đa (km). Mặc định 5km.',
          },
          'min_rating': {
            'type': 'number',
            'description': 'Rating tối thiểu (1-5). Mặc định không filter.',
          },
          'tags': {
            'type': 'string',
            'description':
                'Tag của nhà hàng (tìm theo keyword). Mặc định không filter',
          },
          'cuisine_type': {
            'type': 'string',
            'description':
                'Loại món: vietnamese, japanese, korean, western, etc.',
          },
        },
      ),

      AIToolDefinition(
        name: 'get_restaurant_details',
        description:
            'Lấy thông tin chi tiết về một nhà hàng cụ thể (menu, giờ mở cửa, reviews, ảnh).',
        parameters: {
          'restaurant_id': {
            'type': 'string',
            'description': 'ID của nhà hàng cần xem chi tiết',
          },
        },
      ),

      AIToolDefinition(
        name: 'get_restaurants_by_dish',
        description: 'Tìm các nhà hàng phục vụ một món ăn cụ thể.',
        parameters: {
          'dish_name': {
            'type': 'string',
            'description': 'Tên món ăn cần tìm (vd: "phở bò", "bún bò Huế")',
          },
          'max_distance_km': {
            'type': 'number',
            'description': 'Bán kính tìm kiếm (km)',
          },
        },
      ),

      // === User Location & Navigation ===
      AIToolDefinition(
        name: 'get_user_location',
        description:
            'Lấy vị trí GPS hiện tại của người dùng (latitude, longitude).',
        parameters: {}, // Không cần tham số
      ),

      AIToolDefinition(
        name: 'get_route_to_restaurant',
        description: 'Lấy chỉ đường từ vị trí hiện tại đến nhà hàng.',
        parameters: {
          'restaurant_id': {
            'type': 'string',
            'description': 'ID của nhà hàng đích',
          },
          'transport_mode': {
            'type': 'string',
            'description': 'Phương tiện: "walking", "driving", "bicycle"',
          },
        },
      ),

      // === User Preferences & Profile ===
      AIToolDefinition(
        name: 'get_user_preferences',
        description:
            'Lấy thông tin sở thích ăn uống của người dùng từ profile '
            '(món yêu thích, độ cay, dị ứng, dietary restrictions).',
        parameters: {}, // User ID sẽ được inject từ session
      ),

      AIToolDefinition(
        name: 'save_user_preference',
        description:
            'Lưu hoặc cập nhật sở thích của người dùng (món yêu thích, độ cay ưa thích, allergies).',
        parameters: {
          'preference_type': {
            'type': 'string',
            'description':
                'Loại preference: "favorite_dish", "spice_level", "allergy", "dietary"',
          },
          'value': {'type': 'string', 'description': 'Giá trị preference'},
          'action': {'type': 'string', 'description': '"add" hoặc "remove"'},
        },
      ),

      AIToolDefinition(
        name: 'get_user_favorites',
        description: 'Lấy danh sách nhà hàng/món ăn mà user đã lưu yêu thích.',
        parameters: {},
      ),

      // === Context & Utility ===
      AIToolDefinition(
        name: 'get_weather',
        description:
            'Lấy thông tin thời tiết tại vị trí hiện tại (để gợi ý món ăn phù hợp).',
        parameters: {},
      ),

      AIToolDefinition(
        name: 'get_popular_dishes',
        description:
            'Lấy danh sách món ăn đang trending/phổ biến trong khu vực.',
        parameters: {
          'category': {
            'type': 'string',
            'description':
                'Loại món: "breakfast", "lunch", "dinner", "snack", "dessert"',
          },
        },
      ),

      AIToolDefinition(
        name: 'search_dishes',
        description: 'Tìm kiếm món ăn theo tên, tag, hoặc thành phần.',
        parameters: {
          'query': {'type': 'string', 'description': 'Từ khóa tìm kiếm món ăn'},
        },
      ),
    ];
  }
}
