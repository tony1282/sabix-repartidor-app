import '../entities/order_entity.dart';
// lib/domain/repositories/delivery_repository.dart

abstract class DeliveryRepository {
  Future<List<OrderEntity>> getAvailableOrders();
  Future<List<OrderEntity>> getAssignedOrders(); // 🆕
  Future<OrderEntity> getOrderDetail(int orderId);
  Future<OrderEntity> acceptOrder(int orderId);
  Future<void> rejectOrder(int orderId, {String? reason});
  Future<void> updateLocation(double lat, double lng, {int? orderId});
  Future<void> markAsDelivered(int orderId);
}
