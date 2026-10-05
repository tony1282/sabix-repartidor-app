import 'package:flutter/material.dart';

import '../../../../domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(int id)? onDelete;

  const MessageBubble({super.key, required this.message, this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _system(context);

    final isMine = message.isMine;
    final bg = isMine ? Colors.blue[600] : Colors.grey[200];
    final fg = isMine ? Colors.white : Colors.black87;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMine && onDelete != null && !message.isOptimistic
            ? () => onDelete!(message.id)
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                ),
              if (message.replyTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${message.replyTo!.senderName}: ${message.replyTo!.content}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Text(message.content, style: TextStyle(color: fg)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmt(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine ? Colors.white70 : Colors.black45,
                    ),
                  ),
                  if (isMine && message.isOptimistic) ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.2,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _system(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final h = d.toLocal().hour.toString().padLeft(2, '0');
    final m = d.toLocal().minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
