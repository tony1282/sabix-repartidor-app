import 'dart:convert';
import 'package:sabix_repartidor_app/models/order_model.dart';
import 'package:sabix_repartidor_app/core/network/api_client.dart';
import 'package:sabix_repartidor_app/core/network/api_endpoints.dart';

class DeliveryRemoteDataSource {
  final ApiClient _apiClient;

  DeliveryRemoteDataSource(this._apiClient);

  Future<List<OrderModel>> getAvailableOrders() async {
    final response = await _apiClient.get(ApiEndpoints.availableOrders);
    final List data = response.data;
    return data.map((json) => OrderModel.fromJson(json)).toList();
  }

  // 🆕 Pedidos asignados al repartidor (in_delivery + delivered recientes)
  Future<List<OrderModel>> getAssignedOrders() async {
    final response = await _apiClient.get(ApiEndpoints.assignedOrders);
    final List data = response.data;
    return data.map((json) => OrderModel.fromJson(json)).toList();
  }

  Future<OrderModel> getOrderDetail(int orderId) async {
    final response = await _apiClient.get(ApiEndpoints.orderDetail(orderId));
    return OrderModel.fromJson(response.data);
  }

  Future<OrderModel> acceptOrder(int orderId) async {
    final response = await _apiClient.post(ApiEndpoints.acceptOrder(orderId));

    return OrderModel.fromJson(response.data['order']);
  }

  Future<void> rejectOrder(int orderId, {String? reason}) async {
    final Map<String, dynamic> body = {};
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }
    await _apiClient.post(ApiEndpoints.rejectOrder(orderId), data: body);
  }

  // ✅ CORREGIDO: Incluir order_id siempre
  Future<void> updateLocation(double lat, double lng, {int? orderId}) async {
    final Map<String, dynamic> body = {
      'lat': lat,
      'lng': lng,
      'order_id': orderId ?? 0, // 🔥 Siempre enviar order_id
    };

    await _apiClient.post(ApiEndpoints.updateLocation, data: body);
  }

  Future<void> markAsDelivered(int orderId) async {
    await _apiClient.post(ApiEndpoints.deliverOrder(orderId));
  }
}
