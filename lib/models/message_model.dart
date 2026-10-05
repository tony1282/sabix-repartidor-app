import '../domain/entities/chat_message.dart';

class MessageModel {
  final ChatMessage message;
  MessageModel(this.message);

  /// Parser híbrido: acepta tanto la respuesta del REST (con `sender` anidado)
  /// como el evento del WebSocket (con `sender_id` plano).
  factory MessageModel.fromJson(
    Map<String, dynamic> json, {
    required int currentUserId,
  }) {
    // ---- conversation id ----
    // REST lo manda como `conversation`, WS como `conversation_id`
    final int conversationId =
        (json['conversation_id'] as num?)?.toInt() ??
        (json['conversation'] as num?)?.toInt() ??
        0;

    // ---- sender ----
    int senderId;
    String senderName;
    String senderType;
    String? senderImage;

    final rawSender = json['sender'];
    if (rawSender is Map) {
      // Formato REST
      final sender = rawSender.cast<String, dynamic>();
      senderId = (sender['id'] as num).toInt();
      senderName =
          (sender['full_name'] as String?) ??
          (sender['username'] as String?) ??
          'Usuario';
      senderType = (sender['user_type'] as String?) ?? 'unknown';
      senderImage = sender['profile_image'] as String?;
    } else {
      // Formato WS
      senderId = (json['sender_id'] as num?)?.toInt() ?? 0;
      senderName = (json['sender_name'] as String?) ?? 'Usuario';
      senderType = (json['sender_type'] as String?) ?? 'unknown';
      senderImage = null;
    }

    // ---- reply_to ----
    ChatMessageReply? replyTo;
    final rawReply = json['reply_to'];
    if (rawReply is Map) {
      final r = rawReply.cast<String, dynamic>();
      replyTo = ChatMessageReply(
        id: (r['id'] as num).toInt(),
        senderName: (r['sender_name'] as String?) ?? '',
        content: (r['content'] as String?) ?? '',
        type: _parseType(r['message_type'] as String?),
        createdAt:
            DateTime.tryParse(r['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }

    // ---- is_mine ----
    // REST lo manda. WS no → lo calculamos comparando con el usuario actual.
    final bool isMine =
        (json['is_mine'] as bool?) ?? (senderId == currentUserId);

    // ---- is_read ----
    // REST lo manda. WS no → si es mío asumimos true, si no false.
    final bool isRead = (json['is_read'] as bool?) ?? isMine;

    return MessageModel(
      ChatMessage(
        id: (json['id'] as num).toInt(),
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        senderProfileImage: senderImage,
        type: _parseType(json['message_type'] as String?),
        content: (json['content'] as String?) ?? '',
        metadata:
            (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
        replyTo: replyTo,
        isMine: isMine,
        isRead: isRead,
        isEdited: (json['is_edited'] as bool?) ?? false,
        isDeleted: (json['is_deleted'] as bool?) ?? false,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      ),
    );
  }

  static MessageType _parseType(String? raw) {
    switch (raw) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'location':
        return MessageType.location;
      case 'text':
      default:
        return MessageType.text;
    }
  }
}
