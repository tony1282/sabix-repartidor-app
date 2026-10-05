import '../../repositories/delivery_repository.dart';
// lib/domain/usecases/deliveries/reject_order_usecase.dart

class RejectOrderUseCase {
  final DeliveryRepository repository;

  RejectOrderUseCase(this.repository);

  Future<void> call(int orderId, {String? reason}) async { // ✅ SIN assignmentId
    await repository.rejectOrder(orderId, reason: reason);
  }
}