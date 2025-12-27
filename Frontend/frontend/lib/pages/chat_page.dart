import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../handlers/chat_handler.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

/// Trang Chat với Bot
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  // Danh sách Models từ JSON config
  final List<Map<String, dynamic>> _availableModels = [
    {
      "name": "OpenAI-High",
      "model_name": "gpt-5",
      "client_name": "OpenAI",
      "description":
          "From OpenAI API, the highest intellegents GPT model, which is slowest and most expensive. Great for complex, deep logic task like planning, writing, creativity, solving problem...",
    },
    {
      "name": "OpenAI-Medium",
      "model_name": "gpt-5-mini",
      "client_name": "OpenAI",
      "description":
          "From OpenAI API, balance between intellegents and speed + cost. Great for most task like thinking, seperating,...",
    },
    {
      "name": "OpenAI-Medium-Structured",
      "model_name": "gpt-5-mini",
      "client_name": "OpenAI",
      "creativity": 0.05,
      "description":
          "From OpenAI API, same as OpenAI-Medium, but more structured and predictable.",
    },
    {
      "name": "OpenAI-High-Structured",
      "model_name": "gpt-5",
      "client_name": "OpenAI",
      "creativity": 0.05,
      "description":
          "From OpenAI API, same as OpenAI-High, but more structured and predictable.",
    },
    {
      "name": "OpenAI-Low",
      "model_name": "gpt-5-nano",
      "client_name": "OpenAI",
      "description":
          "From OpenAI API, the fastest, cheapest and lowest intellegents. Great for basic, repetitive task.",
    },
    {
      "name": "Gemini-Low",
      "model_name": "gemini-2.5-flash-lite",
      "client_name": "Gemini",
      "description":
          "From Gemini, the quickest, cheapest, fastest and lowest intellegents model.",
    },
    {
      "name": "Gemini-Medium",
      "model_name": "gemini-2.5-flash",
      "client_name": "Gemini",
      "description":
          "From Gemini, the balance between intellegent and speed + cost.",
    },
    {
      "name": "Gemini-High",
      "model_name": "gemini-3-pro-preview",
      "client_name": "Gemini",
      "description":
          "From Gemimi, the newest and highest intellegent and slowest model.",
    },
    {
      "name": "Default",
      "model_name": "gemini-2.5-flash",
      "client_name": "Gemini",
      "description":
          "From Gemini, the quickest, cheapest, fastest and lowest intellegents model.",
    },
  ];

  late Map<String, dynamic> _selectedModel;
  final ScrollController _scrollController = ScrollController();
  List<String>? _currentQuickReplies;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedModel = _availableModels.last; // Default
    _initChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Khởi tạo chat với tin nhắn chào mừng
  void _initChat() {
    final welcome = ChatHandler.getWelcomeMessage();
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: welcome.message,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _currentQuickReplies = welcome.quickReplies;
    });
  }

  /// Gửi tin nhắn
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Thêm tin nhắn của user
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _currentQuickReplies = null;
      _isLoading = true;
    });

    _scrollToBottom();

    // Gọi handler để lấy phản hồi (Mock)
    try {
      final response = await ChatHandler.sendMessage(
        text,
        modelName: _selectedModel['name'],
      );

      // Thêm tin nhắn phản hồi từ bot
      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response.message,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(botMessage);
        _currentQuickReplies = response.quickReplies;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại')),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showModelSelectionSheet(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Chọn Model AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedModel['name'],
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableModels.length,
                  itemBuilder: (context, index) {
                    final model = _availableModels[index];
                    final isSelected = model['name'] == _selectedModel['name'];
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        model['name'],
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        model['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedModel = model;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Trợ lý ảo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(
              'Model: ${_selectedModel['name']}',
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showModelSelectionSheet(isDarkMode),
            tooltip: 'Chọn Model',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bắt đầu cuộc trò chuyện',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(message: _messages[index]);
                    },
                  ),
          ),

          // Quick Replies
          if (_currentQuickReplies != null && _currentQuickReplies!.isNotEmpty)
            QuickReplyChips(
              quickReplies: _currentQuickReplies!,
              onTap: _sendMessage,
            ),

          // Typing Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(),
                        const SizedBox(width: 4),
                        _buildTypingDot(delay: 200),
                        const SizedBox(width: 4),
                        _buildTypingDot(delay: 400),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input Field
          ChatInput(onSend: _sendMessage, isLoading: _isLoading),
        ],
      ),
    );
  }

  Widget _buildTypingDot({int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        // Loop animation
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted && _isLoading) {
            setState(() {});
          }
        });
      },
    );
  }
}
