import 'package:flutter/material.dart';
import '../handlers/chat_handler.dart';
import '../handlers/query_system.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final QuerySystem _querySystem = QuerySystem();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _querySystem.getChatHistory();
    setState(() {
      _messages.addAll(history);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _isTyping = true;
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();

    // Listen to the stream
    _querySystem.sendChatMessage(text).listen((message) {
      setState(() {
        _messages.add(message);
        if (!message.isUser) {
          _isTyping = false;
        }
      });
      _scrollToBottom();
    });
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blueAccent
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 16,
              child: Image.asset('assets/images/ai_icon_orange.png'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trợ lý AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isTyping ? 'Đang gõ...' : 'Trực tuyến',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "AI đang suy nghĩ...",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -1),
                  blurRadius: 2,
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () => _handleSubmitted(_textController.text),
                    mini: true,
                    elevation: 0,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
