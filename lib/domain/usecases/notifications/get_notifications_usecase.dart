import '../../entities/notification_entity.dart';
import '../../repositories/notification_repository.dart';
// lib/domain/usecases/notifications/get_notifications_usecase.dart

class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<List<NotificationEntity>> call({int page = 1, int pageSize = 20}) async {
    return await repository.getNotifications(page: page, pageSize: pageSize);
  }
}