# Frontend Core - AI Module

## 📚 Giới thiệu

AI Module là **Core Frontend Layer** cho việc tích hợp AI vào ứng dụng. Module này hoạt động theo kiến trúc **stateless**, đóng vai trò là **Orchestrator** giữa UI/Handler layer và Backend AI API.

## 🏗️ Kiến trúc

### Pattern 3: Conversation with Thinking Loop
Module tuân thủ **AI-Guide.md** và **Frontend-Guide.md**:
- Hỗ trợ tool calling và reasoning loop
- Stateless Architecture - State được quản lý bởi UI layer
- Frontend thực thi tools, AI Module chỉ orchestrate

```
┌─────────────────────────────────────┐
│  UI/UX Layer (Chat Screen)          │
│  - Quản lý state (messages)         │
│  - Hiển thị chat interface          │
│  - Thực thi tools khi AI yêu cầu    │
└─────────────┬───────────────────────┘
              │ history
              ↓
┌─────────────────────────────────────┐
│  Frontend Core - AI Module          │
│  - Stateless wrapper                │
│  - Tool definitions (11 tools)      │
│  - Parse response                   │
└─────────────┬───────────────────────┘
              │ POST /ai?model=Default
              ↓
┌─────────────────────────────────────┐
│  Backend AI (Port 8000)             │
│  - LLM Processing (Gemini/GPT)      │
└─────────────────────────────────────┘
```

## 📁 Cấu trúc

```
Frontend/core/
├── ai_module.dart           # Core orchestrator
├── models/
│   └── ai_models.dart       # Data models
└── README.md                # Documentation
```

## 🛠️ 11 Tools được hỗ trợ

### Restaurant & Discovery (3 tools)

| Tool | Mô tả | Parameters |
|------|-------|------------|
| `search_restaurants` | Tìm nhà hàng với filters (khoảng cách, giá, rating, cuisine) | `query`, `max_distance_km`, `min_rating`, `price_range`, `cuisine_type` |
| `get_restaurant_details` | Xem chi tiết nhà hàng (menu, reviews, giờ mở cửa) | `restaurant_id` |
| `get_restaurants_by_dish` | Tìm nhà hàng theo món ăn | `dish_name`, `max_distance_km` |

### Location & Navigation (2 tools)

| Tool | Mô tả | Parameters |
|------|-------|------------|
| `get_user_location` | Lấy GPS hiện tại | - |
| `get_route_to_restaurant` | Chỉ đường đến nhà hàng | `restaurant_id`, `transport_mode` |

### User Preferences (3 tools)

| Tool | Mô tả | Parameters |
|------|-------|------------|
| `get_user_preferences` | Lấy sở thích từ profile (độ cay, allergies...) | - |
| `save_user_preference` | Lưu sở thích mới | `preference_type`, `value`, `action` |
| `get_user_favorites` | Danh sách nhà hàng yêu thích | - |

### Context & Utility (3 tools)

| Tool | Mô tả | Parameters |
|------|-------|------------|
| `get_weather` | Thời tiết để gợi ý món phù hợp | - |
| `get_popular_dishes` | Món ăn trending theo category | `category` |
| `search_dishes` | Tìm món ăn theo từ khóa | `query` |

## 🚀 Sử dụng

### 1. Import

```dart
import 'package:path_to_core/ai_module.dart';
import 'package:path_to_core/models/ai_models.dart';
```

### 2. Gọi AI Generate

```dart
List<AIMessage> chatHistory = [
  AIMessage(role: AIRole.user, message: "Tìm quán phở gần đây rating cao"),
];

try {
  final response = await AIModule.generate(
    modelName: 'Default',
    history: chatHistory,
    tools: AIModule.getTools(),
  );
  
  if (response.message != null) {
    print('AI: ${response.message}');
  }
  
  if (response.toolCalls.isNotEmpty) {
    // AI yêu cầu thực thi tools
    for (var toolCall in response.toolCalls) {
      print('Tool: ${toolCall.name}');
      print('Args: ${toolCall.arguments}');
    }
  }
} catch (e) {
  print('Error: $e');
}
```

### 3. Reasoning Loop Pattern

```dart
while (true) {
  final response = await AIModule.generate(
    modelName: 'Default',
    history: chatHistory,
    tools: AIModule.getTools(),
  );
  
  // Thêm response vào history
  chatHistory.add(AIMessage(
    role: AIRole.assistant,
    message: response.message,
    toolCalls: response.toolCalls,
  ));
  
  // Nếu không có tool calls → AI xong → break
  if (response.toolCalls.isEmpty) break;
  
  // Thực thi tools
  List<AIToolResult> results = [];
  for (var call in response.toolCalls) {
    final result = await _executeToolOnFrontend(call);
    results.add(AIToolResult(callId: call.id, result: result));
  }
  
  // Thêm kết quả vào history
  chatHistory.add(AIMessage(
    role: AIRole.assistant,
    toolResults: results,
  ));
}
```

### 4. Ví dụ thực thi Tool

```dart
Future<dynamic> _executeToolOnFrontend(AIToolCall call) async {
  switch (call.name) {
    case 'search_restaurants':
      final query = call.arguments['query'] as String;
      final distance = call.arguments['max_distance_km'] as num?;
      return await RestaurantHandler.search(query, distance?.toDouble());
      
    case 'get_user_location':
      return await LocationService.getCurrentPosition();
      
    case 'get_user_preferences':
      return await SupabaseService.getUserPreferences();
      
    case 'save_user_preference':
      final type = call.arguments['preference_type'];
      final value = call.arguments['value'];
      return await SupabaseService.savePreference(type, value);
      
    default:
      return {'error': 'Unknown tool: ${call.name}'};
  }
}
```

## ⚙️ Cấu hình

### Backend URL

Mặc định: `http://127.0.0.1:8000`

**Configure khi khởi tạo app** (trong `main.dart` hoặc app initialization):

```dart
void main() {
  // Development - iOS Simulator / Desktop
  AIModule.configure(backendUrl: 'http://localhost:8000');
  
  // Development - Android Emulator
  // AIModule.configure(backendUrl: 'http://10.0.2.2:8000');
  
  // Development - Physical Device (LAN)
  // AIModule.configure(backendUrl: 'http://192.168.1.100:8000');
  
  // Production
  // AIModule.configure(backendUrl: 'https://api.yourapp.com');
  
  runApp(MyApp());
}
```

**Hoặc dùng Environment Variables** (khuyến nghị cho production):

```dart
void main() {
  const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  
  AIModule.configure(backendUrl: backendUrl);
  runApp(MyApp());
}

// Chạy với: flutter run --dart-define=BACKEND_URL=https://api.prod.com
```

## 📝 Data Models

### AIMessage
```dart
AIMessage({
  required AIRole role,        // user / assistant / system
  String? message,             // Nội dung tin nhắn
  List<AIToolCall> toolCalls,  // Tools AI muốn gọi
  List<AIToolResult> toolResults, // Kết quả tools
})
```

### AIResponse
```dart
AIResponse({
  String? message,             // Văn bản từ AI
  List<AIToolCall> toolCalls,  // Tools cần thực thi
})
```

### AIToolCall
```dart
AIToolCall({
  required String id,          // ID tool call
  required String name,        // Tên tool
  required Map<String, dynamic> arguments, // Tham số
})
```

## ⚠️ Lưu ý quan trọng

### 1. Stateless Architecture
- Core **KHÔNG lưu state**
- `history` phải truyền từ UI mỗi lần gọi
- UI chịu trách nhiệm quản lý conversation

### 2. Tool Execution
- **11 tools** phải được implement ở Frontend
- Module chỉ định nghĩa, không thực thi
- Xem section "Ví dụ thực thi Tool" ở trên

### 3. Error Handling
- Module throw `Exception` khi lỗi
- UI cần `try-catch` để handle
- Status code `>= 400` được check tự động

### 4. Authentication
- Chưa có auth hiện tại
- Thêm `Authorization` header nếu Backend yêu cầu

## 🎯 Architecture Compliance

✅ **Diagram 1**: Tool def, Tool call->Frontend, Gen, Memory - **PASS**  
✅ **Diagram 2**: Stateless flow, Backend AI integration - **PASS**  
✅ **Error Handling**: Status >= 400 check - **PASS**  
✅ **Tool Count**: 11 comprehensive tools - **COMPLETE**

## 📖 Tài liệu tham khảo

- **[AI-Guide.md](../../AI-Guide.md)** - Pattern 3 và Thinking Loop
- **[Frontend-Guide.md](../Frontend-Guide.md)** - Kiến trúc 3 tầng
- **Backend API Docs** - `http://localhost:8000/docs`

---

**Version:** 2.0 (Enhanced)  
**Last Updated:** 2025-12-19  
**Total Tools:** 11
