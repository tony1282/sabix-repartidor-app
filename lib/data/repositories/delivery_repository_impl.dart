import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../datasources/local/delivery_local_datasource.dart';
import '../datasources/remote/delivery_remote_datasource.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  final DeliveryRemoteDataSource remoteDataSource;
  final DeliveryLocalDataSource localDataSource;

  DeliveryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<OrderEntity>> getAvailableOrders() async {
    try {
      final models = await remoteDataSource.getAvailableOrders();
      await localDataSource.cacheOrders(models);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      final cached = await localDataSource.getCachedOrders();
      if (cached.isNotEmpty) {
        return cached.map((model) => model.toEntity()).toList();
      }
      rethrow;
    }
  }

  // 🆕 Pedidos asignados al repartidor (in_delivery + delivered recientes)
  @override
  Future<List<OrderEntity>> getAssignedOrders() async {
    final models = await remoteDataSource.getAssignedOrders();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<OrderEntity> getOrderDetail(int orderId) async {
    final model = await remoteDataSource.getOrderDetail(orderId);
    return model.toEntity();
  }

  @override
  Future<OrderEntity> acceptOrder(int orderId) async {
    final model = await remoteDataSource.acceptOrder(orderId);

    return model.toEntity();
  }

  @override
  Future<void> rejectOrder(int orderId, {String? reason}) async {
    await remoteDataSource.rejectOrder(orderId, reason: reason);
  }

  // ✅ CORREGIDO: Asegurar que siempre se pase un orderId (0 si null)
  @override
  Future<void> updateLocation(double lat, double lng, {int? orderId}) async {
    await remoteDataSource.updateLocation(lat, lng, orderId: orderId ?? 0);
  }

  @override
  Future<void> markAsDelivered(int orderId) async {
    await remoteDataSource.markAsDelivered(orderId);
  }
}
