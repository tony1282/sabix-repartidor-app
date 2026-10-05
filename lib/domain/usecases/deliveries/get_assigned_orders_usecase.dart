import '../../entities/order_entity.dart';
import '../../repositories/delivery_repository.dart';
// lib/domain/usecases/deliveries/get_assigned_orders_usecase.dart

class GetAssignedOrdersUseCase {
  final DeliveryRepository repository;

  GetAssignedOrdersUseCase(this.repository);

  Future<List<OrderEntity>> call() => repository.getAssignedOrders();
}
