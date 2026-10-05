class ChatConversation {
  final int id;
  final int orderId;
  final String orderStatus;
  final String orderStatusDisplay;
  final String clientName;
  final String restaurantName;
  final String? deliveryPersonName;
  final bool isActive;
  final bool isSupportRequested;
  final int unreadCount;
  final int participantCount;
  final LastMessagePreview? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatConversation({
    required this.id,
    required this.orderId,
    required this.orderStatus,
    required this.orderStatusDisplay,
    required this.clientName,
    required this.restaurantName,
    this.deliveryPersonName,
    required this.isActive,
    required this.isSupportRequested,
    required this.unreadCount,
    required this.participantCount,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });
}

class LastMessagePreview {
  final int id;
  final String content;
  final String senderName;
  final String messageType;
  final DateTime createdAt;

  const LastMessagePreview({
    required this.id,
    required this.content,
    required this.senderName,
    required this.messageType,
    required this.createdAt,
  });
}
