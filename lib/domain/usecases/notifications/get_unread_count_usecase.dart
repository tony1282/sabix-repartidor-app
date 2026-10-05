import '../../repositories/notification_repository.dart';
// lib/domain/usecases/notifications/get_unread_count_usecase.dart

class GetUnreadCountUseCase {
  final NotificationRepository repository;

  GetUnreadCountUseCase(this.repository);

  Future<int> call() async {
    return await repository.getUnreadCount();
  }
}