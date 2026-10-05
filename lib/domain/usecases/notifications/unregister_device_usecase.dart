import '../../repositories/notification_repository.dart';

class UnregisterDeviceUseCase {
  final NotificationRepository repository;

  UnregisterDeviceUseCase(this.repository);

  Future<void> call({required String token}) async {
    await repository.unregisterDevice(token: token);
  }
}
