import '../../entities/order_entity.dart';
import '../../repositories/delivery_repository.dart';
// lib/domain/usecases/deliveries/get_available_orders_usecase.dart

class GetAvailableOrdersUseCase {
  final DeliveryRepository repository;
  GetAvailableOrdersUseCase(this.repository);
  Future<List<OrderEntity>> call() => repository.getAvailableOrders();
}
