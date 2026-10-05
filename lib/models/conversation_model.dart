import '../domain/entities/chat_conversation.dart';

class ConversationModel {
  final ChatConversation conversation;
  ConversationModel(this.conversation);

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    LastMessagePreview? last;
    final rawLast = json['last_message'];
    if (rawLast is Map) {
      final l = rawLast.cast<String, dynamic>();
      last = LastMessagePreview(
        id: (l['id'] as num).toInt(),
        content: (l['content'] as String?) ?? '',
        senderName: (l['sender_name'] as String?) ?? '',
        messageType: (l['message_type'] as String?) ?? 'text',
        createdAt:
            DateTime.tryParse(l['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }

    return ConversationModel(
      ChatConversation(
        id: (json['id'] as num).toInt(),
        orderId: (json['order_id'] as num).toInt(),
        orderStatus: (json['order_status'] as String?) ?? '',
        orderStatusDisplay: (json['order_status_display'] as String?) ?? '',
        clientName: (json['client_name'] as String?) ?? '',
        restaurantName: (json['restaurant_name'] as String?) ?? '',
        deliveryPersonName: json['delivery_person_name'] as String?,
        isActive: (json['is_active'] as bool?) ?? true,
        isSupportRequested: (json['is_support_requested'] as bool?) ?? false,
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
        lastMessage: last,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
      ),
    );
  }
}
