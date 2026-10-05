import '../../repositories/delivery_repository.dart';
// lib/domain/usecases/deliveries/mark_as_delivered_usecase.dart

class MarkAsDeliveredUseCase {
  final DeliveryRepository repository;

  MarkAsDeliveredUseCase(this.repository);

  Future<void> call(int orderId) async {
    await repository.markAsDelivered(orderId);
  }
}