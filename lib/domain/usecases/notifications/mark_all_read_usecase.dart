import '../../repositories/notification_repository.dart';
// lib/domain/usecases/notifications/mark_all_read_usecase.dart

class MarkAllReadUseCase {
  final NotificationRepository repository;

  MarkAllReadUseCase(this.repository);

  Future<void> call() async {
    await repository.markAllAsRead();
  }
}