import 'package:dio/dio.dart';
import '../../../models/order_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
// lib/data/datasources/remote/delivery_remote_datasource.dart

class DeliveryRemoteDataSource {
  final ApiClient _apiClient;

  DeliveryRemoteDataSource(this._apiClient);

  Future<List<OrderModel>> getAvailableOrders() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.availableOrders);
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => OrderModel.fromJson(json)).toList();
      }
      throw Exception('Error al obtener pedidos disponibles');
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<OrderModel> getOrderDetail(int orderId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.orderDetail(orderId));
      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data);
      }
      throw Exception('Error al obtener detalle del pedido');
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> acceptOrder(int orderId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.acceptOrder(orderId),
        data: {},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al aceptar la entrega');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> rejectOrder(int orderId, {String? reason}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.rejectOrder(orderId),
        data: {
          if (reason != null) 'reason': reason,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al rechazar la entrega');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> updateLocation(double lat, double lng, {int? orderId}) async {
    try {
      // Siempre enviar order_id (usar 0 si no viene)
      final data = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'order_id': orderId ?? 0,
      };
      final response = await _apiClient.post(
        ApiEndpoints.updateLocation,
        data: data,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al actualizar ubicación');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  Future<void> markAsDelivered(int orderId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.deliverOrder(orderId),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al marcar como entregado');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }
}