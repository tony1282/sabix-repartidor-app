import '../../domain/entities/notification_entity.dart';
import '../entities/device.dart';
// lib/domain/repositories/notification_repository.dart

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications({int page, int pageSize});
  Future<List<NotificationEntity>> getUnreadNotifications({
    int page,
    int pageSize,
  });

  Future<int> getUnreadCount();

  Future<void> markAsRead(int notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(int notificationId);

  Future<void> registerDevice({
    required String token,
    required String deviceType,
    String? deviceName,
  });

  Future<void> unregisterDevice({required String token});

  Future<List<Device>> getDevices();

  Future<void> deleteDevice({required String deviceId});
}
