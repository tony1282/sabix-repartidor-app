import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notifications/mark_as_read_usecase.dart';
import '../../domain/usecases/notifications/mark_all_read_usecase.dart';
import '../../domain/usecases/notifications/register_device_usecase.dart';
import '../../domain/usecases/notifications/get_unread_count_usecase.dart';
import '../../domain/usecases/notifications/get_notifications_usecase.dart';
import '../../domain/usecases/notifications/delete_notification_usecase.dart';
import 'package:sabix_repartidor_app/data/datasources/local/notification_local_datasource.dart';

import '../../domain/usecases/notifications/unregister_device_usecase.dart';
import '../../domain/usecases/notifications/get_devices_usecase.dart';
import '../../domain/usecases/notifications/delete_device_usecase.dart';

import '../../domain/entities/device.dart';

// lib/core/providers/notification_provider.dart

class NotificationProvider extends ChangeNotifier {
  final GetNotificationsUseCase getNotificationsUseCase;
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final MarkAsReadUseCase markAsReadUseCase;
  final MarkAllReadUseCase markAllReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;
  final RegisterDeviceUseCase registerDeviceUseCase;
  final NotificationLocalDataSource localDataSource;

  final UnregisterDeviceUseCase unregisterDeviceUseCase;
  final GetDevicesUseCase getDevicesUseCase;
  final DeleteDeviceUseCase deleteDeviceUseCase;

  NotificationProvider({
    required this.getNotificationsUseCase,
    required this.getUnreadCountUseCase,
    required this.markAsReadUseCase,
    required this.markAllReadUseCase,
    required this.deleteNotificationUseCase,
    required this.registerDeviceUseCase,
    required this.localDataSource,
    required this.unregisterDeviceUseCase,
    required this.getDevicesUseCase,
    required this.deleteDeviceUseCase,
  });

  List<NotificationEntity> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;
  bool _hasMore = true;
  int _currentPage = 1;

  List<NotificationEntity> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
      _hasMore = true;
      print('🔄 Refresh: _notifications limpiada');
    }

    if (!_hasMore || _isLoading) {
      print('⏳ _hasMore: $_hasMore, _isLoading: $_isLoading -> saliendo');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      print('📡 Llamando a getNotificationsUseCase (page: $_currentPage)');
      final result = await getNotificationsUseCase(
        page: _currentPage,
        pageSize: 20,
      );
      print('📡 Resultado: ${result.length} notificaciones');

      if (refresh) {
        _notifications = result;
        print(
          '📡 _notifications asignado (refresh) con ${_notifications.length}',
        );
      } else {
        _notifications.addAll(result);
        print('📡 _notifications.addAll, ahora tiene ${_notifications.length}');
      }

      _hasMore = result.length >= 20;
      _currentPage++;
      print('📡 Notificando listeners...');
      notifyListeners();
      print('✅ notifyListeners ejecutado');
    } catch (e) {
      print('❌ Excepción en loadNotifications: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
      print('📡 _setLoading(false) ejecutado');
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await getUnreadCountUseCase();
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando contador: $e');
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      await markAsReadUseCase(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationEntity(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          orderId: _notifications[index].orderId,
          type: _notifications[index].type,
          typeDisplay: _notifications[index].typeDisplay,
          title: _notifications[index].title,
          message: _notifications[index].message,
          data: _notifications[index].data,
          isRead: true,
          isArchived: _notifications[index].isArchived,
          priority: _notifications[index].priority,
          priorityDisplay: _notifications[index].priorityDisplay,
          createdAt: _notifications[index].createdAt,
          readAt: DateTime.now(),
          expiresAt: _notifications[index].expiresAt,
          timeAgo: _notifications[index].timeAgo,
          isExpired: _notifications[index].isExpired,
        );
        notifyListeners();
      }
      await loadUnreadCount();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await markAllReadUseCase();
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = NotificationEntity(
          id: _notifications[i].id,
          userId: _notifications[i].userId,
          orderId: _notifications[i].orderId,
          type: _notifications[i].type,
          typeDisplay: _notifications[i].typeDisplay,
          title: _notifications[i].title,
          message: _notifications[i].message,
          data: _notifications[i].data,
          isRead: true,
          isArchived: _notifications[i].isArchived,
          priority: _notifications[i].priority,
          priorityDisplay: _notifications[i].priorityDisplay,
          createdAt: _notifications[i].createdAt,
          readAt: DateTime.now(),
          expiresAt: _notifications[i].expiresAt,
          timeAgo: _notifications[i].timeAgo,
          isExpired: _notifications[i].isExpired,
        );
      }
      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      await deleteNotificationUseCase(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> registerDevice({
    required String token,
    required String deviceType,
    String? deviceName,
  }) async {
    try {
      await registerDeviceUseCase(
        token: token,
        deviceType: deviceType,
        deviceName: deviceName,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> clearCache() async {
    print('🧹 Limpiando caché...');
    await localDataSource.clearCache();
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
    print('✅ Caché limpiada');
  }

  void clearError() {
    _clearError();
  }

  Future<bool> unregisterDevice(String token) async {
    try {
      await unregisterDeviceUseCase(token: token);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<List<Device>> getDevices() async {
    try {
      return await getDevicesUseCase();
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  Future<bool> deleteDevice(String deviceId) async {
    try {
      await deleteDeviceUseCase(deviceId: deviceId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
}
