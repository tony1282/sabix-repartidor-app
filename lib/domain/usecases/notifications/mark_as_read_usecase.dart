import '../../repositories/notification_repository.dart';
// lib/domain/usecases/notifications/mark_as_read_usecase.dart

class MarkAsReadUseCase {
  final NotificationRepository repository;

  MarkAsReadUseCase(this.repository);

  Future<void> call(int notificationId) async {
    await repository.markAsRead(notificationId);
  }
}
