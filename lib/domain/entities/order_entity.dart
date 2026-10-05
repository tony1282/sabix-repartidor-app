// lib/domain/entities/order_entity.dart
class OrderEntity {
  final int id;
  final String status;
  final String statusDisplay;
  final double total;
  final double deliveryFee;
  final String? clientName;
  final String? restaurantName;
  final String? deliveryPersonName;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final int? estimatedDeliveryTime; // ← int? (no String)
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final int? assignmentId;
  final List<OrderItemEntity>? items;
  final String? paymentMethod;
  final DateTime? confirmedAt;
  final DateTime? preparingAt;
  final DateTime? readyAt;
  final DateTime? inDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final int? clientRating;
  final String? clientComment;
  final int? totalItems; // ← NUEVO CAMPO

  OrderEntity({
    required this.id,
    required this.status,
    required this.statusDisplay,
    required this.total,
    required this.deliveryFee,
    this.clientName,
    this.restaurantName,
    this.deliveryPersonName,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.estimatedDeliveryTime,
    required this.isPaid,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.assignmentId,
    this.items,
    this.paymentMethod,
    this.confirmedAt,
    this.preparingAt,
    this.readyAt,
    this.inDeliveryAt,
    this.deliveredAt,
    this.cancelledAt,
    this.clientRating,
    this.clientComment,
    this.totalItems, // ← NUEVO PARÁMETRO
  });
}

class OrderItemEntity {
  final int id;
  final String productName;
  final double productPrice;
  final int quantity;
  final double total;
  final Map<String, dynamic>? selectedOptions;
  final String? notes;

  OrderItemEntity({
    required this.id,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.total,
    this.selectedOptions,
    this.notes,
  });
}
