import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  // Conversaciones
  Future<List<ChatConversation>> getConversations();
  Future<ChatConversation> getConversationById(int id);
  Future<ChatConversation> getConversationByOrder(int orderId);

  // Mensajes
  Future<List<ChatMessage>> getMessages(int conversationId);
  Future<ChatMessage> sendMessage(
    int conversationId, {
    required String content,
    String messageType,
    Map<String, dynamic>? metadata,
    int? replyToId,
  });
  Future<ChatMessage> replyToMessage(
    int conversationId,
    int messageId, {
    required String content,
  });
  Future<void> deleteMessage(int conversationId, int messageId);

  // Unread
  Future<int> getConversationUnread(int conversationId);
  Future<int> getTotalUnread();

  // Soporte / cierre
  Future<void> requestSupport(
    int conversationId, {
    required String reason,
    String priority,
  });
  Future<void> closeConversation(int conversationId);
}
