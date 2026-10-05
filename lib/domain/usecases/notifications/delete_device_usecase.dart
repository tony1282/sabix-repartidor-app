import '../../repositories/notification_repository.dart';

class DeleteDeviceUseCase {
  final NotificationRepository repository;

  DeleteDeviceUseCase(this.repository);

  Future<void> call({required String deviceId}) async {
    await repository.deleteDevice(deviceId: deviceId);
  }
}
