import '../../repositories/delivery_repository.dart';
// lib/domain/usecases/deliveries/update_location_usecase.dart

class UpdateLocationUseCase {
  final DeliveryRepository repository;

  UpdateLocationUseCase(this.repository);

  Future<void> call(double lat, double lng, {int? orderId}) async {
    // Asegurar que siempre se pase un orderId (0 si es null)
    await repository.updateLocation(lat, lng, orderId: orderId ?? 0);
  }
}
