import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/chat_socket_service.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../models/message_model.dart';

class ChatRoomProvider extends ChangeNotifier {
  final ChatRepositoryImpl repo;
  final ChatSocketService socket;
  final int currentUserId;

  ChatRoomProvider({
    required this.repo,
    required this.socket,
    required this.currentUserId,
  });

  ChatConversation? _conversation;
  List<ChatMessage> _messages = [];
  bool _loading = false;
  String? _error;
  ChatSocketState _connectionState = ChatSocketState.idle;

  // typing por usuario: { userId: username }
  final Map<int, String> _typingUsers = {};
  Timer? _typingDebounce;
  bool _sentTypingTrue = false;

  StreamSubscription<ChatWsEvent>? _socketSub;

  // ---------------- GETTERS ----------------

  ChatConversation? get conversation => _conversation;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _loading;
  String? get error => _error;
  ChatSocketState get connectionState => _connectionState;
  List<String> get typingUsernames => _typingUsers.values.toList();

  // ---------------- CICLO DE VIDA ----------------

  Future<void> open(int conversationId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Metadata + histórico (REST)
      _conversation = await repo.getConversationById(conversationId);
      _messages = await repo.getMessages(conversationId);

      // 2. Suscribirse a eventos WS
      _socketSub = socket.events.listen(_onWsEvent);

      // 3. Conectar WS
      await socket.connect(conversationId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _socketSub?.cancel();
    socket.disconnect();
    super.dispose();
  }

  // ---------------- WS ----------------

  void _onWsEvent(ChatWsEvent event) {
    if (event is NewMessageEvent) {
      _handleIncoming(event.raw);
    } else if (event is TypingEvent) {
      if (event.userId == currentUserId) return;
      if (event.isTyping) {
        _typingUsers[event.userId] = event.username;
      } else {
        _typingUsers.remove(event.userId);
      }
      notifyListeners();
    } else if (event is ConnectionStateEvent) {
      _connectionState = event.state;
      notifyListeners();
    } else if (event is WsErrorEvent) {
      // opcional: log
      // debugPrint('[Chat WS] ${event.message}');
    }
  }

  void _handleIncoming(Map<String, dynamic> raw) {
    final incoming = MessageModel.fromJson(
      raw,
      currentUserId: currentUserId,
    ).message;

    // ¿Es el eco de un mensaje optimista?
    final optimisticIdx = _messages.indexWhere(
      (m) => m.id < 0 && m.content == incoming.content && m.isMine,
    );

    if (optimisticIdx != -1) {
      _messages[optimisticIdx] = incoming;
    } else if (!_messages.any((m) => m.id == incoming.id)) {
      _messages.add(incoming);
    }

    notifyListeners();
  }

  // ---------------- ENVÍO ----------------

  Future<void> send(String content, {int? replyToId}) async {
    final text = content.trim();
    if (text.isEmpty) return;

    final optimistic = await repo.sendMessage(
      _conversation!.id,
      content: text,
      replyToId: replyToId,
    );

    // Si es optimista (WS) → insertar
    // Si vino por REST → también insertar (el eco por WS puede o no llegar)
    if (!_messages.any((m) => m.id == optimistic.id)) {
      _messages.add(optimistic);
      notifyListeners();
    }

    // Ya dejamos de "escribir"
    _typingDebounce?.cancel();
    if (_sentTypingTrue) {
      socket.sendTyping(false);
      _sentTypingTrue = false;
    }
  }

  void onUserTyping(String text) {
    _typingDebounce?.cancel();

    if (!_sentTypingTrue && text.trim().isNotEmpty) {
      _sentTypingTrue = true;
      socket.sendTyping(true);
    }

    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (_sentTypingTrue) {
        socket.sendTyping(false);
        _sentTypingTrue = false;
      }
    });
  }

  // ---------------- ACCIONES ----------------

  Future<void> deleteMessage(int messageId) async {
    if (_conversation == null) return;
    await repo.deleteMessage(_conversation!.id, messageId);
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  Future<void> requestSupport(
    String reason, {
    String priority = 'medium',
  }) async {
    if (_conversation == null) return;
    await repo.requestSupport(
      _conversation!.id,
      reason: reason,
      priority: priority,
    );
  }

  Future<void> closeConversation() async {
    if (_conversation == null) return;
    await repo.closeConversation(_conversation!.id);
    _conversation = null;
    notifyListeners();
  }
}
