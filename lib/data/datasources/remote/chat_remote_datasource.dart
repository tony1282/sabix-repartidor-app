import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/message_model.dart';
import '../../../models/conversation_model.dart';

class ChatRemoteDataSource {
  final ApiClient _client;
  ChatRemoteDataSource({ApiClient? client}) : _client = client ?? ApiClient();

  // ============================================
  // CONVERSACIONES
  // ============================================

  Future<List<ConversationModel>> getConversations() async {
    final Response res = await _client.get(ApiEndpoints.conversations);
    final List data = _unwrapList(res.data);
    return data
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationModel> getConversationById(int id) async {
    final Response res = await _client.get(ApiEndpoints.conversationDetail(id));
    return ConversationModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ConversationModel> getConversationByOrder(int orderId) async {
    final Response res = await _client.get(
      ApiEndpoints.conversationByOrder(orderId),
    );
    return ConversationModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ============================================
  // MENSAJES
  // ============================================

  /// ⚠️ Este GET marca automáticamente los mensajes como leídos en el backend.
  Future<List<MessageModel>> getMessages(
    int conversationId, {
    required int currentUserId,
  }) async {
    final Response res = await _client.get(
      ApiEndpoints.messages(conversationId),
    );
    final List data = _unwrapList(res.data);
    return data
        .map(
          (e) => MessageModel.fromJson(
            e as Map<String, dynamic>,
            currentUserId: currentUserId,
          ),
        )
        .toList();
  }

  /// Fallback REST para enviar mensaje (se usa cuando el WS está caído).
  Future<MessageModel> sendMessage(
    int conversationId, {
    required String content,
    required String messageType,
    Map<String, dynamic>? metadata,
    int? replyToId,
    required int currentUserId,
  }) async {
    final Response res = await _client.post(
      ApiEndpoints.sendMessage(conversationId),
      data: {
        'content': content,
        'message_type': messageType,
        if (metadata != null) 'metadata': metadata,
        if (replyToId != null) 'reply_to_id': replyToId,
      },
    );
    // 🛡 Blindaje contra respuestas no-JSON (ej: HTML de error 500)
    final data = res.data;
    if (data is! Map) {
      throw Exception(
        'El servidor no devolvió JSON. Posible error 500. '
        '¿Falta el import de `timezone` en el serializers.py del backend?',
      );
    }

    return MessageModel.fromJson(
      data.cast<String, dynamic>(),
      currentUserId: currentUserId,
    );
  }

  Future<MessageModel> replyToMessage(
    int conversationId,
    int messageId, {
    required String content,
    required int currentUserId,
  }) async {
    final Response res = await _client.post(
      ApiEndpoints.replyMessage(conversationId, messageId),
      data: {'content': content},
    );
    return MessageModel.fromJson(
      res.data as Map<String, dynamic>,
      currentUserId: currentUserId,
    );
  }

  Future<void> deleteMessage(int conversationId, int messageId) async {
    await _client.delete(ApiEndpoints.deleteMessage(conversationId, messageId));
  }

  Future<void> markMessageAsRead(int conversationId, int messageId) async {
    await _client.post(ApiEndpoints.readMessage(conversationId, messageId));
  }

  // ============================================
  // UNREAD
  // ============================================

  Future<int> getConversationUnread(int conversationId) async {
    final Response res = await _client.get(
      ApiEndpoints.conversationUnread(conversationId),
    );
    final data = res.data as Map<String, dynamic>;
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> getTotalUnread() async {
    final Response res = await _client.get(ApiEndpoints.totalUnread);
    final data = res.data as Map<String, dynamic>;
    return (data['total_unread'] as num?)?.toInt() ?? 0;
  }

  // ============================================
  // SOPORTE
  // ============================================

  Future<void> requestSupport(
    int conversationId, {
    required String reason,
    String priority = 'medium',
  }) async {
    await _client.post(
      ApiEndpoints.requestSupport(conversationId),
      data: {'reason': reason, 'priority': priority},
    );
  }

  Future<void> closeConversation(int conversationId) async {
    await _client.post(ApiEndpoints.closeConversation(conversationId));
  }

  // ============================================
  // HELPERS
  // ============================================

  /// El backend puede devolver un array plano o paginado (`{results: [...]}`).
  /// Esto cubre ambos casos.
  List _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['results'] is List) return raw['results'] as List;
    return const [];
  }
}
