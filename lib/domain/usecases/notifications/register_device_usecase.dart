import '../../repositories/notification_repository.dart';

class RegisterDeviceUseCase {
  final NotificationRepository repository;

  RegisterDeviceUseCase(this.repository);

  Future<void> call({
    required String token,
    required String deviceType,
    String? deviceName,
  }) async {
    await repository.registerDevice(
      token: token,
      deviceType: deviceType,
      deviceName: deviceName,
    );
  }
}
