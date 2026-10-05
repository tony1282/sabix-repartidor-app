import '../../entities/device.dart';
import '../../repositories/notification_repository.dart';

class GetDevicesUseCase {
  final NotificationRepository repository;

  GetDevicesUseCase(this.repository);

  Future<List<Device>> call() async {
    return await repository.getDevices();
  }
}
