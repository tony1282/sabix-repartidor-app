import '../../entities/order_entity.dart';
import '../../repositories/delivery_repository.dart';

class AcceptOrderUseCase {
  final DeliveryRepository repository;

  AcceptOrderUseCase(this.repository);

  Future<OrderEntity> call(int orderId) async {
    return await repository.acceptOrder(orderId);
  }
}
