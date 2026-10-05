import 'dart:convert';
import '../../../models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
// lib/data/datasources/local/notification_local_datasource.dart

class NotificationLocalDataSource {
  static const String _cacheKey = 'notifications_cache';
  static const String _unreadCountKey = 'unread_count_cache';

  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      print('💾 Caché guardada con ${notifications.length} notificaciones');
    } catch (e) {
      print('❌ Error cacheando notificaciones: $e');
    }
  }

  Future<List<NotificationModel>> getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) {
        print('📭 No hay caché de notificaciones');
        return [];
      }
      final List data = jsonDecode(jsonString);
      final models = <NotificationModel>[];
      for (var json in data) {
        try {
          models.add(NotificationModel.fromJson(json));
        } catch (e) {
          print('⚠️ Error al parsear notificación cacheada: $e');
        }
      }
      print('📦 Caché cargada con ${models.length} notificaciones');
      return models;
    } catch (e) {
      print('❌ Error obteniendo caché de notificaciones: $e');
      return [];
    }
  }

  Future<void> cacheUnreadCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_unreadCountKey, count);
    } catch (e) {
      print('❌ Error cacheando contador: $e');
    }
  }

  Future<int> getCachedUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_unreadCountKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_unreadCountKey);
      print('🧹 Caché eliminada correctamente');
    } catch (e) {
      print('❌ Error limpiando caché: $e');
    }
  }
}