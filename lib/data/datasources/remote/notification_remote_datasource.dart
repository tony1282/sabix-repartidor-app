import 'package:dio/dio.dart';
import 'package:sabix_repartidor_app/models/device_model.dart';
import '../../../core/network/api_client.dart';
import '../../../models/notification_model.dart';
import '../../../core/network/api_endpoints.dart';
// lib/data/datasources/remote/notification_remote_datasource.dart

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource(this._apiClient);

  /// Extrae la lista de notificaciones sin importar si el backend
  /// responde como lista plana `[...]` o paginada `{results: [...]}`.
  List _extractResultsList(dynamic data) {
    if (data is List) {
      return data;
    }
    if (data is Map) {
      return data['results'] ?? [];
    }
    return [];
  }

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.notifications,
        params: {'page': page, 'page_size': pageSize},
      );
      if (response.statusCode == 200) {
        final List results = _extractResultsList(response.data);
        return results.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('Error al obtener notificaciones');
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<List<NotificationModel>> getUnreadNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.unreadNotifications,
        params: {'page': page, 'page_size': pageSize},
      );
      if (response.statusCode == 200) {
        final List results = _extractResultsList(response.data);
        return results.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('Error al obtener notificaciones no leídas');
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.unreadCount);
      if (response.statusCode == 200) {
        return response.data['count'] ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.markAsRead(notificationId),
      );
      if (response.statusCode != 200) {
        throw Exception('Error al marcar como leída');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.post(ApiEndpoints.markAllRead);
      if (response.statusCode != 200) {
        throw Exception('Error al marcar todas como leídas');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteNotification(notificationId),
      );
      if (response.statusCode != 200) {
        throw Exception('Error al eliminar notificación');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> registerDevice({
    required String token,
    required String deviceType,
    String? deviceName,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerFcmDevice,
        data: {
          'token': token,
          'device_type': deviceType,
          if (deviceName != null) 'device_name': deviceName,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al registrar dispositivo FCM');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> unregisterDevice(String token) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.registerFcmDevice,
        data: {'token': token},
      );

      if (response.statusCode != 200) {
        throw Exception('Error al desregistrar dispositivo');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<List<DeviceModel>> getDevices() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.fcmDevices);

      if (response.statusCode == 200) {
        final List results = _extractResultsList(response.data);

        return results.map((json) => DeviceModel.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteFcmDevice(deviceId),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar dispositivo');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }
}
