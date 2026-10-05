// lib/domain/entities/notification_entity.dart
class NotificationEntity {
  final int id;
  final int? userId;
  final int? orderId;
  final String type;
  final String typeDisplay;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final bool isArchived;
  final int priority;
  final String priorityDisplay;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final String? timeAgo;
  final bool isExpired;
  final String? actionUrl;

  NotificationEntity({
    required this.id,
    this.userId,
    this.orderId,
    required this.type,
    required this.typeDisplay,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.isArchived,
    required this.priority,
    required this.priorityDisplay,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
    this.timeAgo,
    required this.isExpired,
    this.actionUrl,
  });
}
