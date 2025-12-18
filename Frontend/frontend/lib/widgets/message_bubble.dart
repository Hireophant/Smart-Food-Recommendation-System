import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';

/// Widget hiển thị tin nhắn dạng bubble
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 60 : 12,
          right: isUser ? 12 : 60,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).primaryColor
              : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black87),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isUser
                    ? Colors.white70
                    : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Widget cho Quick Replies (gợi ý nhanh)
class QuickReplyChips extends StatelessWidget {
  final List<String> quickReplies;
  final Function(String) onTap;

  const QuickReplyChips({
    super.key,
    required this.quickReplies,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: quickReplies.map((reply) {
          return ActionChip(
            label: Text(reply),
            onPressed: () => onTap(reply),
            backgroundColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.1),
            labelStyle: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
            side: BorderSide(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
          );
        }).toList(),
      ),
    );
  }
}
