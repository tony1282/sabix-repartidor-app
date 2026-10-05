import 'package:flutter/foundation.dart';

import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_conversation.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepositoryImpl repo;
  ChatProvider({required this.repo});

  List<ChatConversation> _conversations = [];
  bool _loading = false;
  String? _error;
  int _totalUnread = 0;

  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _loading;
  String? get error => _error;
  int get totalUnread => _totalUnread;

  Future<void> loadConversations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = await repo.getConversations();
      await refreshTotalUnread();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTotalUnread() async {
    try {
      _totalUnread = await repo.getTotalUnread();
      notifyListeners();
    } catch (_) {
      // silencioso: si falla, mantenemos el valor anterior
    }
  }

  /// Para llamar desde el push handler cuando llega un `chat_message`.
  void decrementUnread(int amount) {
    _totalUnread = (_totalUnread - amount).clamp(0, 1 << 30);
    notifyListeners();
  }
}
