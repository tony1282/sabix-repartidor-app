import 'package:flutter/foundation.dart';

import '../../core/services/chat_socket_service.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/remote/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remote;
  final ChatSocketService socket;
  final int Function() currentUserIdProvider;

  ChatRepositoryImpl({
    required this.remote,
    required this.socket,
    required this.currentUserIdProvider,
  });

  // ============================================
  // CONVERSACIONES
  // ============================================

  @override
  Future<List<ChatConversation>> getConversations() async {
    final models = await remote.getConversations();
    return models.map((m) => m.conversation).toList();
  }

  @override
  Future<ChatConversation> getConversationById(int id) async {
    final model = await remote.getConversationById(id);
    return model.conversation;
  }

  @override
  Future<ChatConversation> getConversationByOrder(int orderId) async {
    final model = await remote.getConversationByOrder(orderId);
    return model.conversation;
  }

  // ============================================
  // MENSAJES
  // ============================================

  @override
  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final models = await remote.getMessages(
      conversationId,
      currentUserId: currentUserIdProvider(),
    );
    return models.map((m) => m.message).toList();
  }

  @override
  Future<ChatMessage> sendMessage(
    int conversationId, {
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    int? replyToId,
  }) async {
    // 1. WS prioritario (si está vivo)
    if (socket.isConnected && socket.conversationId == conversationId) {
      socket.sendMessage(
        content: content,
        messageType: messageType,
        metadata: metadata,
        replyToId: replyToId,
      );
      return _optimisticMessage(
        conversationId: conversationId,
        content: content,
        messageType: messageType,
        metadata: metadata,
        replyToId: replyToId,
      );
    }

    // 2. REST
    try {
      final model = await remote.sendMessage(
        conversationId,
        content: content,
        messageType: messageType,
        metadata: metadata,
        replyToId: replyToId,
        currentUserId: currentUserIdProvider(),
      );
      return model.message;
    } catch (e) {
      // 3. Workaround: si el backend falla con 500 (bug conocido del timezone),
      //    el mensaje SÍ se guardó. Hacemos GET y buscamos el que coincida.
      debugPrint('⚠️ POST falló, intentando recuperar vía GET: $e');

      try {
        final models = await remote.getMessages(
          conversationId,
          currentUserId: currentUserIdProvider(),
        );

        // Buscamos el último mensaje mío con el mismo content
        final mine = models
            .where((m) => m.message.isMine && m.message.content == content)
            .toList();

        if (mine.isNotEmpty) {
          // El último (más reciente)
          mine.sort(
            (a, b) => a.message.createdAt.compareTo(b.message.createdAt),
          );
          debugPrint(
            '✅ Mensaje recuperado vía GET: id=${mine.last.message.id}',
          );
          return mine.last.message;
        }

        // No lo encontramos → propagamos el error original
        rethrow;
      } catch (e2) {
        debugPrint('❌ Tampoco se pudo recuperar: $e2');
        rethrow;
      }
    }
  }

  @override
  Future<ChatMessage> replyToMessage(
    int conversationId,
    int messageId, {
    required String content,
  }) async {
    final model = await remote.replyToMessage(
      conversationId,
      messageId,
      content: content,
      currentUserId: currentUserIdProvider(),
    );
    return model.message;
  }

  @override
  Future<void> deleteMessage(int conversationId, int messageId) =>
      remote.deleteMessage(conversationId, messageId);

  // ============================================
  // UNREAD
  // ============================================

  @override
  Future<int> getConversationUnread(int conversationId) =>
      remote.getConversationUnread(conversationId);

  @override
  Future<int> getTotalUnread() => remote.getTotalUnread();

  // ============================================
  // SOPORTE / CIERRE
  // ============================================

  @override
  Future<void> requestSupport(
    int conversationId, {
    required String reason,
    String priority = 'medium',
  }) =>
      remote.requestSupport(conversationId, reason: reason, priority: priority);

  @override
  Future<void> closeConversation(int conversationId) =>
      remote.closeConversation(conversationId);

  // ============================================
  // HELPERS
  // ============================================

  ChatMessage _optimisticMessage({
    required int conversationId,
    required String content,
    required String messageType,
    Map<String, dynamic>? metadata,
    int? replyToId,
  }) {
    return ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
      senderId: currentUserIdProvider(),
      senderName: '',
      senderType: '',
      type: MessageType.values.firstWhere(
        (e) => e.name == messageType,
        orElse: () => MessageType.text,
      ),
      content: content,
      metadata: metadata ?? const {},
      isMine: true,
      isRead: false,
      createdAt: DateTime.now(),
    );
  }
}
