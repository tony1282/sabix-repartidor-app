import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

// ============================================================
// EVENTOS QUE EMITE EL SOCKET
// ============================================================

sealed class ChatWsEvent {}

class NewMessageEvent extends ChatWsEvent {
  final Map<String, dynamic> raw;
  NewMessageEvent(this.raw);
}

class TypingEvent extends ChatWsEvent {
  final int userId;
  final String username;
  final bool isTyping;
  TypingEvent({
    required this.userId,
    required this.username,
    required this.isTyping,
  });
}

class UserOnlineEvent extends ChatWsEvent {
  final int userId;
  final String username;
  UserOnlineEvent({required this.userId, required this.username});
}

class UserOfflineEvent extends ChatWsEvent {
  final int userId;
  final String username;
  UserOfflineEvent({required this.userId, required this.username});
}

class WsErrorEvent extends ChatWsEvent {
  final String message;
  WsErrorEvent(this.message);
}

class ConnectionStateEvent extends ChatWsEvent {
  final ChatSocketState state;
  ConnectionStateEvent(this.state);
}

enum ChatSocketState {
  idle,
  connecting,
  connected,
  disconnected,
  reconnecting,
  failed,
}

// ============================================================
// SERVICIO
// ============================================================

class ChatSocketService {
  final String baseWsUrl;
  final Future<String?> Function() tokenProvider;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  int? _currentConversationId;
  bool _manuallyClosed = false;

  // ✅ Estado REAL del socket (no mentiroso)
  ChatSocketState _state = ChatSocketState.idle;
  ChatSocketState get state => _state;

  final _events = StreamController<ChatWsEvent>.broadcast();
  Stream<ChatWsEvent> get events => _events.stream;

  ChatSocketService({required this.baseWsUrl, required this.tokenProvider});

  // ============================================================
  // CONEXIÓN
  // ============================================================

  Future<void> connect(int conversationId) async {
    _manuallyClosed = false;
    _currentConversationId = conversationId;
    _reconnectAttempts = 0;
    await _open(conversationId);
  }

  Future<void> _open(int conversationId) async {
    _setState(ChatSocketState.connecting);

    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      _events.add(WsErrorEvent('No hay token disponible para el WS'));
      _setState(ChatSocketState.failed);
      return;
    }

    final uri = Uri.parse('$baseWsUrl/ws/chat/$conversationId/?token=$token');

    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready;

      _setState(ChatSocketState.connected);
      _reconnectAttempts = 0;

      _sub = channel.stream.listen(
        _onData,
        onError: (e) => _onError(conversationId, e),
        onDone: () => _onDone(conversationId),
        cancelOnError: true,
      );

      _startHeartbeat();
    } catch (e) {
      _events.add(WsErrorEvent('No se pudo conectar al chat: $e'));
      _scheduleReconnect(conversationId);
    }
  }

  // ============================================================
  // RECEPCIÓN
  // ============================================================

  void _onData(dynamic data) {
    debugPrint('📥 WS raw: $data');
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'new_message':
          final msg = json['message'];
          if (msg is Map) {
            _events.add(NewMessageEvent(msg.cast<String, dynamic>()));
          }
          break;

        case 'typing':
          _events.add(
            TypingEvent(
              userId: (json['user_id'] as num?)?.toInt() ?? 0,
              username: (json['username'] as String?) ?? '',
              isTyping: (json['is_typing'] as bool?) ?? false,
            ),
          );
          break;

        case 'user_online':
          _events.add(
            UserOnlineEvent(
              userId: (json['user_id'] as num?)?.toInt() ?? 0,
              username: (json['username'] as String?) ?? '',
            ),
          );
          break;

        case 'user_offline':
          _events.add(
            UserOfflineEvent(
              userId: (json['user_id'] as num?)?.toInt() ?? 0,
              username: (json['username'] as String?) ?? '',
            ),
          );
          break;

        case 'pong':
          break;

        case 'error':
          _events.add(
            WsErrorEvent((json['message'] as String?) ?? 'Error desconocido'),
          );
          break;

        default:
          break;
      }
    } catch (e) {
      _events.add(WsErrorEvent('Error al parsear mensaje del WS: $e'));
    }
  }

  void _onError(int conversationId, Object error) {
    _events.add(WsErrorEvent('Socket error: $error'));
    _setState(ChatSocketState.disconnected);
    _scheduleReconnect(conversationId);
  }

  void _onDone(int conversationId) {
    _stopHeartbeat();
    _setState(ChatSocketState.disconnected);
    if (!_manuallyClosed) _scheduleReconnect(conversationId);
  }

  // ============================================================
  // RECONEXIÓN
  // ============================================================

  void _scheduleReconnect(int conversationId) {
    if (_manuallyClosed) return;
    _reconnectAttempts++;

    if (_reconnectAttempts > 8) {
      _setState(ChatSocketState.failed);
      return;
    }

    _setState(ChatSocketState.reconnecting);

    final seconds = (1 << _reconnectAttempts).clamp(2, 30);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: seconds),
      () => _open(conversationId),
    );
  }

  // ============================================================
  // HEARTBEAT
  // ============================================================

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      send({'action': 'ping'});
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _setState(ChatSocketState s) {
    if (_state == s) return;
    _state = s;
    _events.add(ConnectionStateEvent(s));
  }

  // ============================================================
  // API PÚBLICA
  // ============================================================

  // ✅ AHORA SÍ es honesto: solo true cuando el handshake terminó
  bool get isConnected => _state == ChatSocketState.connected;

  int? get conversationId => _currentConversationId;

  void send(Map<String, dynamic> payload) {
    if (!isConnected) return;
    final ch = _channel;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode(payload));
    } catch (_) {}
  }

  void sendMessage({
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    int? replyToId,
  }) {
    send({
      'action': 'send_message',
      'content': content,
      'message_type': messageType,
      'metadata': ?metadata,
      'reply_to_id': ?replyToId,
    });
  }

  void sendTyping(bool isTyping) {
    send({'action': 'typing', 'is_typing': isTyping});
  }

  void markRead(int messageId) {
    send({'action': 'mark_read', 'message_id': messageId});
  }

  Future<void> disconnect() async {
    _manuallyClosed = true;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _sub?.cancel();
    _sub = null;

    try {
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {}

    _channel = null;
    _currentConversationId = null;
    _setState(ChatSocketState.disconnected);
  }

  void dispose() {
    disconnect();
    _events.close();
  }
}
