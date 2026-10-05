enum MessageType { text, image, file, system, location }

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderType;
  final String? senderProfileImage;
  final MessageType type;
  final String content;
  final Map<String, dynamic> metadata;
  final ChatMessageReply? replyTo;
  final bool isMine;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    this.senderProfileImage,
    required this.type,
    required this.content,
    this.metadata = const {},
    this.replyTo,
    required this.isMine,
    required this.isRead,
    this.isEdited = false,
    this.isDeleted = false,
    required this.createdAt,
  });

  bool get isSystem => type == MessageType.system;
  bool get isOptimistic =>
      id < 0; // placeholder local mientras llega el eco del WS
}

class ChatMessageReply {
  final int id;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime createdAt;

  const ChatMessageReply({
    required this.id,
    required this.senderName,
    required this.content,
    required this.type,
    required this.createdAt,
  });
}
