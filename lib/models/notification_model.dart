import 'dart:convert';
import '../domain/entities/notification_entity.dart';
// lib/models/notification_model.dart

class NotificationModel {
  final int id;
  final int? user;
  final int? order; // Este es el campo 'order' del JSON (puede ser null)
  final int? orderId; // Extraído de 'data.order_id' si 'order' es null
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

  NotificationModel({
    required this.id,
    this.user,
    this.order,
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
  });

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static Map<String, dynamic>? _parseData(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      try {
        final parsed = jsonDecode(value);
        if (parsed is Map<String, dynamic>) return parsed;
        return null;
      } catch (_) {
        return null;
      }
    }
    // Si es List o cualquier otra cosa, retornar null
    return null;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parsear data de forma segura
      final Map<String, dynamic>? parsedData = _parseData(json['data']);

      // Extraer orderId de data si order es null
      int? extractedOrderId = _parseInt(json['order']);
      if (extractedOrderId == null && parsedData != null) {
        extractedOrderId = _parseInt(parsedData['order_id']);
      }

      return NotificationModel(
        id: _parseInt(json['id']) ?? 0,
        user: _parseInt(json['user']),
        order: _parseInt(json['order']),
        orderId: extractedOrderId,
        type: json['type'] ?? '',
        typeDisplay: json['type_display'] ?? '',
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        data: parsedData,
        isRead: json['is_read'] ?? false,
        isArchived: json['is_archived'] ?? false,
        priority: _parseInt(json['priority']) ?? 0,
        priorityDisplay: json['priority_display'] ?? 'Normal',
        createdAt: DateTime.parse(json['created_at']),
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'])
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'])
            : null,
        timeAgo: json['time_ago'],
        isExpired: json['is_expired'] ?? false,
      );
    } catch (e) {
      print('❌ ERROR parseando notificación ID ${json['id']}: $e');
      print('❌ JSON problemático: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'order': order,
      'type': type,
      'type_display': typeDisplay,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'is_archived': isArchived,
      'priority': priority,
      'priority_display': priorityDisplay,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'time_ago': timeAgo,
      'is_expired': isExpired,
    };
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      userId: user,
      orderId: orderId ?? order, // Usar orderId extraído, o fallback a order
      type: type,
      typeDisplay: typeDisplay,
      title: title,
      message: message,
      data: data,
      isRead: isRead,
      isArchived: isArchived,
      priority: priority,
      priorityDisplay: priorityDisplay,
      createdAt: createdAt,
      readAt: readAt,
      expiresAt: expiresAt,
      timeAgo: timeAgo,
      isExpired: isExpired,
    );
  }
}
