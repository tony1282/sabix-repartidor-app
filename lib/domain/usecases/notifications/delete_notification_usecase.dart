import '../../repositories/notification_repository.dart';
// lib/domain/usecases/notifications/delete_notification_usecase.dart

class DeleteNotificationUseCase {
  final NotificationRepository repository;

  DeleteNotificationUseCase(this.repository);

  Future<void> call(int notificationId) async {
    await repository.deleteNotification(notificationId);
  }
}
