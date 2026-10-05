class Device {
  final int id;
  final String token;
  final String deviceType;
  final String? deviceName;
  final bool active;
  final DateTime? lastUsed;
  final DateTime? createdAt;

  Device({
    required this.id,
    required this.token,
    required this.deviceType,
    this.deviceName,
    required this.active,
    this.lastUsed,
    this.createdAt,
  });
}
