import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:frontend/core/backend/backend_api.dart';
import 'package:frontend/core/backend/foods_client.dart';
import 'package:frontend/core/backend/foods_models.dart';
import 'package:frontend/core/backend/maps_client.dart';
import 'package:frontend/core/backend/maps_models.dart';
import 'package:frontend/core/backend/restaurants_client.dart';
import 'package:frontend/core/backend/restaurants_models.dart';
import 'package:frontend/core/backend/search_client.dart';
import 'package:frontend/core/backend/search_models.dart';
import 'package:frontend/core/backend/weather_client.dart';
import 'package:frontend/core/backend/weather_models.dart';
import 'package:frontend/core/data/data_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message_model.dart';
import '../core/ai/ai_models.dart';
import '../core/ai/ai_module.dart';

class ChatToolExecutor {
  static final String backendUrl = 'http://localhost:8000';

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String>? _asStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final mapped = value.map((e) => e.toString()).toList();
      return mapped;
    }
    return null;
  }

  static final List<AIToolDefinition> chatTools = [
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
          'description':
              'Bán kính tìm kiếm tối đa (km), nếu có sẽ lấy GPS của người dùng để tìm. Mặc định không filter.',
        },
        'min_rating': {
          'type': 'number',
          'description': 'Rating tối thiểu (0-5). Mặc định không filter.',
        },
        'tags': {
          'type': 'string',
          'description':
              'Tag của nhà hàng (tìm theo keyword). Mặc định không filter.',
        },
        'limit': {
          'type': 'integer',
          'description': 'Số kết quả tìm kiếm tối đa. Mặc định là 5.',
        },
      },
      requires: [],
    ),

    // === User Location & Navigation ===
    AIToolDefinition(
      name: 'get_user_location',
      description:
          'Lấy vị trí GPS hiện tại của người dùng (latitude, longitude).',
      parameters: {}, // Không cần tham số
      requires: [],
    ),

    // === User Preferences & Profile ===
    AIToolDefinition(
      name: 'get_user_taste_profile',
      description: 'Lấy thông tin sở thích ăn uống của người dùng từ profile.',
      parameters: {}, // User ID sẽ được inject từ session
      requires: [],
    ),

    AIToolDefinition(
      name: 'save_user_taste_profile',
      description:
          'Lưu hoặc cập nhật sở thích của người dùng (chỉ chỉnh nhưng cái được cung cấp)',
      parameters: {
        'cuisines': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Danh sách các phong cách nấu ăn ưa thích',
        },
        'spiceLevel': {'type': 'string', 'description': 'Độ cay ưa thích'},
        'dietary_restrictions': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Danh sách các hạn chế về chế độ ăn uống',
        },
        'allergies': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Danh sách các thứ mà người dùng bị dị ứng',
        },
        'price_preference': {
          'type': 'string',
          'description': 'Giá cả mong muốn',
        },
        'favorite_dishes': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'Danh sách các món ưa thích (có thể không nhất thiết phải giống data thật, làm reference thôi)',
        },
        'dislikes': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Danh sách các món người dùng không thích',
        },
      },
      requires: [],
    ),

    AIToolDefinition(
      name: 'get_user_favorites_restaurants',
      description: 'Lấy danh sách nhà hàng mà user đã lưu yêu thích.',
      parameters: {
        'limit': {
          'type': 'integer',
          'description': "Số lượng tối đa sẽ lấy. Mặc định là 5",
        },
      },
      requires: [],
    ),

    AIToolDefinition(
      name: 'get_user_favorites_dishes',
      description: 'Lấy danh sách món ăn mà user đã lưu yêu thích.',
      parameters: {
        'limit': {
          'type': 'integer',
          'description': "Số lượng tối đa sẽ lấy. Mặc định là 5",
        },
      },
      requires: [],
    ),

    // === Context & Utility ===
    AIToolDefinition(
      name: 'get_weather',
      description:
          'Lấy thông tin thời tiết tại vị trí nhất định (để gợi ý món ăn phù hợp).',
      parameters: {
        'lat': {'type': 'number', 'description': "Vĩ độ (Latitude) của vị trí"},
        'lng': {
          'type': 'number',
          'description': "Kinh độ (Longitude) của vị trí",
        },
      },
      requires: ['lat', 'lng'],
    ),

    AIToolDefinition(
      name: 'search_dishes',
      description: 'Tìm kiếm món ăn theo từ khóa.',
      parameters: {
        'query': {'type': 'string', 'description': 'Từ khóa tìm kiếm món ăn'},
        'tags': {
          'type': 'string',
          'description':
              'Từ khóa tìm kiếm theo tags. Mặc định không có filter.',
        },
        'limit': {
          'type': 'integer',
          'description': 'Giới hạn kết quả tìm kiếm. Mặc định là 5.',
        },
      },
      requires: ['query'],
    ),

    AIToolDefinition(
      name: 'search_google',
      description:
          'Tìm kiếm Google (SERP) theo từ khóa, có thể kèm location. Trả về kết quả đã được format để AI dùng trực tiếp.',
      parameters: {
        'query': {
          'type': 'string',
          'description': 'Từ khóa tìm kiếm (bắt buộc).',
        },
        'location': {
          'type': 'string',
          'description':
              'Khu vực tìm kiếm (ví dụ: "Ho Chi Minh", "Vietnam"). Mặc định: Vietnam.',
        },
        'max_locations': {
          'type': 'integer',
          'description':
              'Giới hạn số địa điểm (maps results) trả về. Mặc định theo backend.',
        },
        'max_results': {
          'type': 'integer',
          'description':
              'Giới hạn số organic results trả về. Mặc định theo backend.',
        },
      },
      requires: ['query'],
    ),
  ];

  static Future<AIToolResult> _executeGetWeather(AIToolCall toolCall) async {
    final lat = _asDouble(toolCall.arguments['lat']);
    final lng = _asDouble(toolCall.arguments['lng']);

    if (lat == null || lng == null) {
      return AIToolResult(
        callId: toolCall.id,
        result:
            "Cần cả Vĩ độ (Latitude, lat) và Kinh độ (Longitude, lon) để lấy thông tin thời tiết",
      );
    }
    if (lat <= -90 || lat >= 90 || lng <= -180 || lng >= 180) {
      return AIToolResult(
        callId: toolCall.id,
        result:
            "Vĩ độ (Latitude, lat) phải nằm trong (-90, 90) và Kinh độ (Longitude, lon) phải nằm trong (-180, 180) để lấy thông tin thời tiết",
      );
    }

    try {
      WeatherClient client = WeatherClient(BackendAPI(baseUrl: backendUrl));
      var result = await client.formatted(WeatherParams(lat: lat, lon: lng));
      return AIToolResult(callId: toolCall.id, result: result.result);
    } catch (e) {
      return AIToolResult(callId: toolCall.id, result: "Lỗi: ${e.toString()}");
    }
  }

  static Future<AIToolResult> _executeSearchDishes(AIToolCall toolCall) async {
    final query = toolCall.arguments['query']?.toString();
    final tags = toolCall.arguments['tags']?.toString();
    final limit = max(_asInt(toolCall.arguments['limit']) ?? 5, 1);

    if (query == null || query.isEmpty) {
      return AIToolResult(
        callId: toolCall.id,
        result: "Từ khóa (query) không thể bỏ trống!",
      );
    }
    try {
      FoodsClient client = FoodsClient(BackendAPI(baseUrl: backendUrl));
      var result = await client.searchFormatted(
        FoodSearchParams(
          query: query,
          tags: (tags == null || tags.isEmpty) ? null : tags,
          limit: max(limit, 1),
        ),
      );
      return AIToolResult(callId: toolCall.id, result: result.result);
    } catch (e) {
      return AIToolResult(callId: toolCall.id, result: "Lỗi: ${e.toString()}");
    }
  }

  static Future<AIToolResult> _executeGetUserFavoritesDishes(
    AIToolCall toolCall,
  ) async {
    final limit = max(_asInt(toolCall.arguments['limit']) ?? 5, 1);
    try {
      var profiles = await DataClient.getCurrentUserProfile();
      var dishIds = profiles.favoritesFoodIds.take(limit);

      FoodsClient client = FoodsClient(BackendAPI(baseUrl: backendUrl));
      var result = await client.byIdsFormatted(
        FoodsByIdsParams(ids: dishIds.toList()),
      );
      return AIToolResult(callId: toolCall.id, result: result.result);
    } catch (e) {
      return AIToolResult(callId: toolCall.id, result: "Lỗi: ${e.toString()}");
    }
  }

  static Future<AIToolResult> _executeGetUserFavoritesRestaurants(
    AIToolCall toolCall,
  ) async {
    final limit = max(_asInt(toolCall.arguments['limit']) ?? 5, 1);
    try {
      var profiles = await DataClient.getCurrentUserProfile();
      var restaurantIds = profiles.favoritesRestaurantsIds.take(limit);

      RestaurantsClient client = RestaurantsClient(
        BackendAPI(baseUrl: backendUrl),
      );
      var result = await client.byIdsFormatted(
        RestaurantsByIdsParams(ids: restaurantIds.toList()),
      );
      return AIToolResult(callId: toolCall.id, result: result.result);
    } catch (e) {
      return AIToolResult(callId: toolCall.id, result: "Lỗi: ${e.toString()}");
    }
  }

  static Future<AIToolResult> _executeSaveUserTasteProfile(
    AIToolCall toolCall,
  ) async {
    final cuisines = _asStringList(toolCall.arguments['cuisines']);
    final spiceLevel = toolCall.arguments['spiceLevel']?.toString();
    final dietaryRestrictions = _asStringList(
      toolCall.arguments['dietary_restrictions'],
    );
    final allergies = _asStringList(toolCall.arguments['allergies']);
    final pricePreference = toolCall.arguments['price_preference']?.toString();
    final favoriteDishes = _asStringList(toolCall.arguments['favorite_dishes']);
    final dislikes = _asStringList(toolCall.arguments['dislikes']);

    try {
      await DataClient.setCurrentTasteProfile(
        cuisines: cuisines,
        spiceLevel: spiceLevel,
        dietaryRestrictions: dietaryRestrictions,
        allergies: allergies,
        pricePreference: pricePreference,
        favoriteDishes: favoriteDishes,
        dislikes: dislikes,
      );
      return AIToolResult(
        callId: toolCall.id,
        result: "Cập nhật khẩu vị người dùng thành công!",
      );
    } catch (e) {
      return AIToolResult(callId: toolCall.id, result: "Lỗi: ${e.toString()}");
    }
  }

  static Future<AIToolResult> _executeGetUserTasteProfile(
    AIToolCall toolCall,
  ) async {
    try {
      var result = await DataClient.getCurrentTasteProfile();
      return AIToolResult(
        callId: toolCall.id,
        result: result.toVietnameseReadableText(),
      );
    } catch (e) {
      return AIToolResult(callId: toolCall.id, result: "Lỗi: ${e.toString()}");
    }
  }

  static List<double>? _getGPSLocation() {
    // Mock since currently have no GPS
    return [10.762962070528253, 106.68248239592286];
  }

  static Future<AIToolResult> _executeGetUserLocation(
    AIToolCall toolCall,
  ) async {
    try {
      var res = _getGPSLocation();
      if (res == null || res.length != 2) {
        return AIToolResult(
          callId: toolCall.id,
          result: "Không lấy được GPS vị trí người dùng!",
        );
      }
      double lat = res[0];
      double lng = res[1];

      MapsClient client = MapsClient(BackendAPI(baseUrl: backendUrl));
      var reverseGeocodeRes = await client.reverseGeocoding(
        MapsReverseParams(lat: lat, lon: lng),
      );
      var result = reverseGeocodeRes.firstOrNull;
      return AIToolResult(
        callId: toolCall.id,
        result:
            "Thông tin vị trí hiện tại (từ GPS):"
            "\n- Vĩ độ (Latitude): $lat"
            "\n- Kinh độ (Longitude): $lng"
            "\n- Địa chỉ (Nếu có): ${result?.display ?? 'Không rõ'}",
      );
    } catch (e) {
      return AIToolResult(callId: toolCall.id, result: "Lỗi: ${e.toString()}");
    }
  }

  static Future<AIToolResult> _executeSearchRestaurants(
    AIToolCall toolCall,
  ) async {
    final query = toolCall.arguments['query']?.toString();
    final maxDistanceKm = _asDouble(toolCall.arguments['max_distance_km']);
    final minRating = _asDouble(toolCall.arguments['min_rating']);
    final tags = toolCall.arguments['tags']?.toString();
    final limit = max(_asInt(toolCall.arguments['limit']) ?? 5, 1);

    if (minRating != null && (minRating < 0 || minRating > 5)) {
      return AIToolResult(
        callId: toolCall.id,
        result: "min_rating phải nằm trong khoảng 0 đến 5.",
      );
    }

    try {
      bool failGetGps = false;
      List<double>? location;
      if (maxDistanceKm != null) {
        location = _getGPSLocation();
        failGetGps = location == null || (location.length != 2);
        if (failGetGps) location = null;
      }

      // Backend expects radius in meters (default 5000m = 5km).
      final double? radiusMeters = (location != null && maxDistanceKm != null)
          ? (maxDistanceKm * 1000)
          : null;

      RestaurantsClient client = RestaurantsClient(
        BackendAPI(baseUrl: backendUrl),
      );
      var result = await client.searchFormatted(
        RestaurantSearchParams(
          focusLat: location?.first,
          focusLon: location?.last,
          query: query?.trim(),
          radius: radiusMeters,
          minRating: minRating,
          tags: tags,
          limit: limit,
        ),
      );
      return AIToolResult(callId: toolCall.id, result: result.result);
    } catch (e) {
      return AIToolResult(callId: toolCall.id, result: "Lỗi: ${e.toString()}");
    }
  }

  static Future<AIToolResult> _executeSearchGoogle(AIToolCall toolCall) async {
    final query = toolCall.arguments['query']?.toString();
    final location = toolCall.arguments['location']?.toString();
    final maxLocations = _asInt(toolCall.arguments['max_locations']);
    final maxResults = _asInt(toolCall.arguments['max_results']);

    if (query == null || query.trim().isEmpty) {
      return AIToolResult(
        callId: toolCall.id,
        result: 'Từ khóa (query) không thể bỏ trống!',
      );
    }
    if (maxLocations != null && maxLocations < 0) {
      return AIToolResult(
        callId: toolCall.id,
        result: 'max_locations phải >= 0.',
      );
    }
    if (maxResults != null && maxResults < 0) {
      return AIToolResult(
        callId: toolCall.id,
        result: 'max_results phải >= 0.',
      );
    }

    try {
      SearchClient client = SearchClient(BackendAPI(baseUrl: backendUrl));
      var result = await client.formatted(
        SearchParams(
          query: query.trim(),
          location: (location == null || location.trim().isEmpty)
              ? null
              : location.trim(),
          maxLocations: maxLocations,
          maxResults: maxResults,
        ),
      );
      return AIToolResult(callId: toolCall.id, result: result.result);
    } catch (e) {
      return AIToolResult(callId: toolCall.id, result: "Lỗi: ${e.toString()}");
    }
  }

  static Future<AIToolResult> executeTools(AIToolCall toolCall) async {
    switch (toolCall.name) {
      case 'get_weather':
        return await _executeGetWeather(toolCall);
      case 'search_dishes':
        return await _executeSearchDishes(toolCall);
      case 'search_google':
        return await _executeSearchGoogle(toolCall);
      case 'get_user_favorites_dishes':
        return await _executeGetUserFavoritesDishes(toolCall);
      case 'get_user_favorites_restaurants':
        return await _executeGetUserFavoritesRestaurants(toolCall);
      case 'save_user_taste_profile':
        return await _executeSaveUserTasteProfile(toolCall);
      case 'get_user_taste_profile':
        return await _executeGetUserTasteProfile(toolCall);
      case 'get_user_location':
        return await _executeGetUserLocation(toolCall);
      case 'search_restaurants':
        return await _executeSearchRestaurants(toolCall);
      default:
        return AIToolResult(
          callId: toolCall.id,
          result: "Unknown tools '${toolCall.name}'",
        );
    }
  }
}

/// Chat Handler
/// TODO: Backend sẽ thay thế bằng API thật
class ChatHandler {
  /// Lấy danh sách tools mà Frontend hỗ trợ
  static final Map<String, List<AIMessage>> _chatHistories = {};

  static BotResponse convertMessageToBotResponse(AIMessage message) {
    return BotResponse(message: message.message ?? "", quickReplies: null);
  }

  static Future<AIMessage?> generateNextTurn(AIMessage inputMessage) async {
    var supabaseClient = Supabase.instance.client;
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    _chatHistories.putIfAbsent(userId, () => []);
    List<AIMessage> inputs = List.from(_chatHistories[userId] ?? []);
    inputs.add(inputMessage);

    debugPrint(userId);
    try {
      var result = await AIModule.generate(
        modelName: "OpenAI-Low",
        history: inputs,
        tools: ChatToolExecutor.chatTools,
      );

      var resMessage = AIMessage(
        role: AIRole.assistant,
        message: result.message,
        toolCalls: result.toolCalls,
        toolResults: [],
      );

      _chatHistories[userId]?.addAll([inputMessage, resMessage]);

      return resMessage;
    } catch (e) {
      return null;
    }
  }

  static Future<List<AIToolResult>> executeTools(
    List<AIToolCall> toolCalls,
  ) async {
    List<AIToolResult> res = [];
    for (AIToolCall tool in toolCalls) {
      debugPrint("- AI Tool Call: ${tool.name}");
      debugPrint("  + Params: ${tool.arguments.toString()}");
      var result = await ChatToolExecutor.executeTools(tool);
      debugPrint("  -> Result: ${result.result}");

      res.add(result);
    }

    return res;
  }

  static Future<BotResponse> sendMessage(String userMessage) async {
    AIMessage input = AIMessage(role: AIRole.user, message: userMessage);
    AIMessage? output = await generateNextTurn(input);
    debugPrint("AI Output: ${output?.message}");
    while (output != null && output.toolCalls.isNotEmpty) {
      debugPrint("AI Outputs: ${output.message}");
      debugPrint("AI Tool Called:");

      AIMessage nextInput = AIMessage(
        role: null,
        message: null,
        toolCalls: [],
        toolResults: await executeTools(output.toolCalls),
      );

      output = await generateNextTurn(nextInput);
    }

    return BotResponse(
      message: output?.message ?? "Fail to generate response!",
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
