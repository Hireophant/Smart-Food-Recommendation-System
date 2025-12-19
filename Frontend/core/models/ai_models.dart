import 'dart:convert';

/// Role của tin nhắn trong hội thoại
enum AIRole {
  user,
  assistant,
  system,
}

extension AIRoleExtension on AIRole {
  String toShortString() {
    return toString().split('.').last;
  }
}

/// Model cho một tin nhắn AI (tương thích với Backend AIMessageSchema)
class AIMessage {
  final AIRole role;
  final String? message;
  final List<AIToolCall> toolCalls;
  final List<AIToolResult> toolResults;

  AIMessage({
    required this.role,
    this.message,
    this.toolCalls = const [],
    this.toolResults = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role.toShortString(),
      'message': message,
      'tool_calls': toolCalls.map((e) => e.toJson()).toList(),
      'tool_result': toolResults.map((e) => e.toJson()).toList(),
    };
  }

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      role: AIRole.values.firstWhere(
          (e) => e.toShortString() == json['role'],
          orElse: () => AIRole.user),
      message: json['message'],
      toolCalls: (json['tool_calls'] as List?)
              ?.map((e) => AIToolCall.fromJson(e))
              .toList() ??
          [],
      toolResults: (json['tool_result'] as List?)
              ?.map((e) => AIToolResult.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Định nghĩa công cụ (Tool Definition) gửi lên Backend
class AIToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  AIToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': parameters,
          // Mặc định là required hết cho đơn giản, hoặc tùy chỉnh sau
        }
      }
    };
  }
}

/// Yêu cầu gọi tool từ AI trả về
class AIToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  AIToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  Map<String, dynamic> toJson() {
    return {
      'call_id': id,
      'function_name': name,
      'function_args': jsonEncode(arguments),
    };
  }

  factory AIToolCall.fromJson(Map<String, dynamic> json) {
    // Arguments có thể là String JSON hoặc Map sẵn
    Map<String, dynamic> args = {};
    if (json['function_args'] is String) {
      try {
        args = jsonDecode(json['function_args']);
      } catch (_) {}
    } else if (json['function_args'] is Map) {
      args = json['function_args'];
    }

    return AIToolCall(
      id: json['call_id'] ?? '',
      name: json['function_name'] ?? '',
      arguments: args,
    );
  }
}

/// Kết quả thực hiện tool gửi lên AI
class AIToolResult {
  final String callId;
  final dynamic result;

  AIToolResult({
    required this.callId,
    required this.result,
  });

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'result': result,
    };
  }

  factory AIToolResult.fromJson(Map<String, dynamic> json) {
    return AIToolResult(
      callId: json['call_id'],
      result: json['result'],
    );
  }
}

/// Response trả về từ AI Module cho UI xử lý
class AIResponse {
  final String? message;
  final List<AIToolCall> toolCalls;

  AIResponse({this.message, this.toolCalls = const []});
}
