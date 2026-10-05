import 'package:sabix_repartidor_app/domain/entities/device.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/local/notification_local_datasource.dart';
import '../datasources/remote/notification_remote_datasource.dart';
import 'package:sabix_repartidor_app/models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<NotificationEntity>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final models = await remoteDataSource.getNotifications(
        page: page,
        pageSize: pageSize,
      );

      print('📦 Modelos recibidos: ${models.length}');

      final entities = <NotificationEntity>[];

      for (var i = 0; i < models.length; i++) {
        try {
          final entity = models[i].toEntity();
          entities.add(entity);

          print(
            '✅ Modelo $i convertido (ID: ${models[i].id}, orderId: ${entity.orderId})',
          );
        } catch (e) {
          print('❌ Error convirtiendo modelo $i: $e');

          try {
            print('❌ JSON del modelo $i: ${models[i].toJson()}');
          } catch (_) {}
        }
      }

      print('✅ Convertidos ${entities.length} de ${models.length}');

      if (entities.length == models.length && models.isNotEmpty) {
        await localDataSource.cacheNotifications(models);
        print('💾 Caché guardada');
      } else if (entities.isNotEmpty) {
        final validModels = <NotificationModel>[];

        for (var model in models) {
          try {
            model.toEntity();
            validModels.add(model);
          } catch (_) {}
        }

        if (validModels.isNotEmpty) {
          await localDataSource.cacheNotifications(validModels);
          print('💾 Caché guardada con ${validModels.length} modelos válidos');
        }
      }

      return entities;
    } catch (e) {
      print('❌ Error general en getNotifications: $e');

      final cached = await localDataSource.getCachedNotifications();

      if (cached.isNotEmpty) {
        final entities = <NotificationEntity>[];

        for (var model in cached) {
          try {
            entities.add(model.toEntity());
          } catch (_) {
            print('⚠️ Error al convertir modelo cacheado');
          }
        }

        print('📦 Usando caché con ${entities.length} notificaciones');
        return entities;
      }

      rethrow;
    }
  }

  @override
  Future<List<NotificationEntity>> getUnreadNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final models = await remoteDataSource.getUnreadNotifications(
        page: page,
        pageSize: pageSize,
      );

      final entities = <NotificationEntity>[];

      for (var model in models) {
        try {
          entities.add(model.toEntity());
        } catch (_) {
          print('⚠️ Omitiendo notificación con error');
        }
      }

      return entities;
    } catch (e) {
      final cached = await localDataSource.getCachedNotifications();

      final unread = cached.where((e) => !e.isRead).toList();

      if (unread.isNotEmpty) {
        return unread.map((e) => e.toEntity()).toList();
      }

      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final count = await remoteDataSource.getUnreadCount();
      await localDataSource.cacheUnreadCount(count);
      return count;
    } catch (e) {
      return await localDataSource.getCachedUnreadCount();
    }
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    await remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() async {
    await remoteDataSource.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(int notificationId) async {
    await remoteDataSource.deleteNotification(notificationId);
  }

  // ======================================================
  // FCM
  // ======================================================

  @override
  Future<void> registerDevice({
    required String token,
    required String deviceType,
    String? deviceName,
  }) async {
    await remoteDataSource.registerDevice(
      token: token,
      deviceType: deviceType,
      deviceName: deviceName,
    );
  }

  @override
  Future<void> unregisterDevice({required String token}) async {
    await remoteDataSource.unregisterDevice(token);
  }

  @override
  Future<List<Device>> getDevices() async {
    final models = await remoteDataSource.getDevices();

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> deleteDevice({required String deviceId}) async {
    await remoteDataSource.deleteDevice(deviceId);
  }
}
