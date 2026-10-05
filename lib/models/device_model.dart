import '../domain/entities/device.dart';

class DeviceModel extends Device {
  DeviceModel({
    required super.id,
    required super.token,
    required super.deviceType,
    super.deviceName,
    required super.active,
    super.lastUsed,
    super.createdAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      token: json['token'],
      deviceType: json['device_type'],
      deviceName: json['device_name'],
      active: json['is_active'] ?? true,

      lastUsed: json['last_used'] != null
          ? DateTime.parse(json['last_used'])
          : null,

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Device toEntity() {
    return Device(
      id: id,
      token: token,
      deviceType: deviceType,
      deviceName: deviceName,
      active: active,
      lastUsed: lastUsed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'device_type': deviceType,
      'device_name': deviceName,
      'is_active': active,
      'last_used': lastUsed?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
