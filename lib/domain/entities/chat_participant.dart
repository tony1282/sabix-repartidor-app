class ChatParticipant {
  final int id;
  final int userId;
  final String username;
  final String fullName;
  final String userType;
  final String? profileImage;
  final String? phone;
  final String role; // client | restaurant | delivery | support
  final String roleDisplay;
  final bool isActive;
  final int unreadCount;
  final DateTime? lastReadAt;

  const ChatParticipant({
    required this.id,
    required this.userId,
    required this.username,
    required this.fullName,
    required this.userType,
    this.profileImage,
    this.phone,
    required this.role,
    required this.roleDisplay,
    required this.isActive,
    required this.unreadCount,
    this.lastReadAt,
  });

  bool get isDelivery => role == 'delivery';
  bool get isSupport => role == 'support';
}
