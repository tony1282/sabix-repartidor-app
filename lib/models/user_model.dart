// lib/models/user_model.dart
class UserModel {
  final int? id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? userType;
  final bool? isActive;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? token;
  final String? refreshToken;

  // Campos de repartidor
  final String? vehicleType;
  final String? vehiclePlate;
  final bool? isAvailable;
  final double? currentLocationLat;
  final double? currentLocationLng;

  UserModel({
    this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.userType,
    this.isActive,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
    this.token,
    this.refreshToken,
    this.vehicleType,
    this.vehiclePlate,
    this.isAvailable,
    this.currentLocationLat,
    this.currentLocationLng,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'],
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      phone: json['phone'],
      userType: json['user_type'] ?? json['userType'],
      isActive: json['is_active'] ?? json['isActive'],
      profileImage: json['profile_image'] ?? json['profileImage'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      token: json['access'] ?? json['token'],
      refreshToken: json['refresh'],
      vehicleType: json['vehicle_type'] ?? json['vehicleType'],
      vehiclePlate: json['vehicle_plate'] ?? json['vehiclePlate'],
      isAvailable: json['is_available'] ?? json['isAvailable'],
      currentLocationLat: json['current_location_lat'] != null
          ? double.parse(json['current_location_lat'].toString())
          : null,
      currentLocationLng: json['current_location_lng'] != null
          ? double.parse(json['current_location_lng'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'full_name': fullName, // 🔥 Campo calculado agregado
      if (email != null) 'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (userType != null) 'user_type': userType,
      if (profileImage != null) 'profile_image': profileImage,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (vehiclePlate != null) 'vehicle_plate': vehiclePlate,
      if (isAvailable != null) 'is_available': isAvailable,
      if (currentLocationLat != null)
        'current_location_lat': currentLocationLat,
      if (currentLocationLng != null)
        'current_location_lng': currentLocationLng,
    };
  }

  // ✅ REGISTRO - SIEMPRE DELIVERY
  Map<String, dynamic> toRegisterJson(String password) {
    return {
      'username': username,
      'password': password,
      'password2': password,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (firstName != null && firstName!.isNotEmpty) 'first_name': firstName,
      if (lastName != null && lastName!.isNotEmpty) 'last_name': lastName,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'user_type': 'delivery',
      'vehicle_type': vehicleType ?? 'Moto',
      'vehicle_plate': vehiclePlate ?? 'ABC-123',
    };
  }

  bool get isDelivery => userType == 'delivery';

  // 🔥 CORREGIDO: Manejar null correctamente
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    if (first.isEmpty && last.isEmpty) return '';
    return '$first $last'.trim();
  }

  // 🔥 displayName ahora funciona correctamente
  String get displayName => fullName.isNotEmpty ? fullName : username;
}
