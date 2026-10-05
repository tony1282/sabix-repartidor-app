import 'package:flutter/material.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(int id)? onDelete;

  const MessageBubble({super.key, required this.message, this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _system();

    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMine && onDelete != null && !message.isOptimistic
            ? () => onDelete!(message.id)
            : null,
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isMine ? 64 : 12,
            right: isMine ? 12 : 64,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            border: isMine
                ? null
                : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (message.replyTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMine
                        ? Colors.white.withOpacity(0.15)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${message.replyTo!.senderName}: ${message.replyTo!.content}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isMine ? Colors.white70 : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isMine ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmt(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine ? Colors.white60 : AppColors.textLight,
                    ),
                  ),
                  if (isMine && message.isOptimistic) ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.2,
                        color: Colors.white60,
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

  Widget _system() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
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
