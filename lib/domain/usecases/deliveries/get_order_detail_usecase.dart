import '../../repositories/delivery_repository.dart';
import '../../entities/order_entity.dart'; // <-- CAMBIO
// lib/domain/usecases/deliveries/get_order_detail_usecase.dart

class GetOrderDetailUseCase {
  final DeliveryRepository repository;

  GetOrderDetailUseCase(this.repository);

  Future<OrderEntity> call(int orderId) async {
    // <-- CAMBIO
    return await repository.getOrderDetail(orderId);
  }
}
