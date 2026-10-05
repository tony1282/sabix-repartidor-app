import '../domain/entities/order_entity.dart';
// lib/models/order_model.dart

class OrderModel {
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
  final int? estimatedDeliveryTime;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final int? assignmentId;
  final List<OrderItemModel>? items;
  final String? paymentMethod;
  final DateTime? confirmedAt;
  final DateTime? preparingAt;
  final DateTime? readyAt;
  final DateTime? inDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final int? clientRating;
  final String? clientComment;
  final int? totalItems;

  OrderModel({
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
    this.totalItems,
  });

  // ============================================
  // HELPER: Convertir a double de forma segura
  // ============================================
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // ============================================
  // FROM JSON
  // ============================================
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: _toInt(json['id']) ?? 0, // ← CORREGIDO
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      total: _toDouble(json['total']) ?? 0.0,
      deliveryFee: _toDouble(json['delivery_fee']) ?? 0.0,
      clientName: json['client_name'],
      restaurantName: json['restaurant_name'],
      deliveryPersonName: json['delivery_person_name'],
      deliveryAddress: json['delivery_address'],
      deliveryLat: _toDouble(json['delivery_lat']),
      deliveryLng: _toDouble(json['delivery_lng']),
      estimatedDeliveryTime: _toInt(json['estimated_delivery_time']),
      isPaid: json['is_paid'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      notes: json['notes'],
      assignmentId: _toInt(json['assignment_id']), // ← CORREGIDO
      items: json['items'] != null
          ? (json['items'] as List)
                .map((e) => OrderItemModel.fromJson(e))
                .toList()
          : null,
      paymentMethod: json['payment_method'],
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      preparingAt: json['preparing_at'] != null
          ? DateTime.parse(json['preparing_at'])
          : null,
      readyAt: json['ready_at'] != null
          ? DateTime.parse(json['ready_at'])
          : null,
      inDeliveryAt: json['in_delivery_at'] != null
          ? DateTime.parse(json['in_delivery_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      clientRating: _toInt(json['client_rating']), // ← CORREGIDO
      clientComment: json['client_comment'],
      totalItems: _toInt(json['total_items']), // ← CORREGIDO
    );
  }

  // ============================================
  // TO JSON
  // ============================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'status_display': statusDisplay,
      'total': total,
      'delivery_fee': deliveryFee,
      'client_name': clientName,
      'restaurant_name': restaurantName,
      'delivery_person_name': deliveryPersonName,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'estimated_delivery_time': estimatedDeliveryTime,
      'is_paid': isPaid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'notes': notes,
      'assignment_id': assignmentId,
      'items': items?.map((e) => e.toJson()).toList(),
      'payment_method': paymentMethod,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'preparing_at': preparingAt?.toIso8601String(),
      'ready_at': readyAt?.toIso8601String(),
      'in_delivery_at': inDeliveryAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'client_rating': clientRating,
      'client_comment': clientComment,
      'total_items': totalItems,
    };
  }

  // ============================================
  // TO ENTITY
  // ============================================
  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      status: status,
      statusDisplay: statusDisplay,
      total: total,
      deliveryFee: deliveryFee,
      clientName: clientName,
      restaurantName: restaurantName,
      deliveryPersonName: deliveryPersonName,
      deliveryAddress: deliveryAddress,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      estimatedDeliveryTime: estimatedDeliveryTime,
      isPaid: isPaid,
      createdAt: createdAt,
      updatedAt: updatedAt,
      notes: notes,
      assignmentId: assignmentId,
      items: items?.map((e) => e.toEntity()).toList(),
      paymentMethod: paymentMethod,
      confirmedAt: confirmedAt,
      preparingAt: preparingAt,
      readyAt: readyAt,
      inDeliveryAt: inDeliveryAt,
      deliveredAt: deliveredAt,
      cancelledAt: cancelledAt,
      clientRating: clientRating,
      clientComment: clientComment,
      totalItems: totalItems,
    );
  }
}

// ============================================
// ORDER ITEM MODEL
// ============================================
class OrderItemModel {
  final int id;
  final String productName;
  final double productPrice;
  final int quantity;
  final double total;
  final Map<String, dynamic>? selectedOptions;
  final String? notes;

  OrderItemModel({
    required this.id,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.total,
    this.selectedOptions,
    this.notes,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: _toInt(json['id']) ?? 0, // ← CORREGIDO
      productName: json['product_name'] ?? '',
      productPrice: _toDouble(json['product_price']) ?? 0.0,
      quantity: _toInt(json['quantity']) ?? 0, // ← CORREGIDO
      total: _toDouble(json['total']) ?? 0.0,
      selectedOptions: json['selected_options'] as Map<String, dynamic>?,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
      'total': total,
      'selected_options': selectedOptions,
      'notes': notes,
    };
  }

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      id: id,
      productName: productName,
      productPrice: productPrice,
      quantity: quantity,
      total: total,
      selectedOptions: selectedOptions,
      notes: notes,
    );
  }
}
