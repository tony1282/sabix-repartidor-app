import '../domain/entities/chat_participant.dart';

class ParticipantModel {
  final ChatParticipant participant;
  ParticipantModel(this.participant);

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map).cast<String, dynamic>();
    return ParticipantModel(
      ChatParticipant(
        id: (json['id'] as num).toInt(),
        userId: (user['id'] as num).toInt(),
        username: (user['username'] as String?) ?? '',
        fullName:
            (user['full_name'] as String?) ??
            (user['username'] as String?) ??
            '',
        userType: (user['user_type'] as String?) ?? 'unknown',
        profileImage: user['profile_image'] as String?,
        phone: user['phone'] as String?,
        role: (json['role'] as String?) ?? 'unknown',
        roleDisplay: (json['role_display'] as String?) ?? '',
        isActive: (json['is_active'] as bool?) ?? true,
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        lastReadAt: DateTime.tryParse(json['last_read_at'] as String? ?? ''),
      ),
    );
  }
}
