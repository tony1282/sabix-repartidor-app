import '../domain/entities/support_request.dart';

class SupportRequestModel {
  final SupportRequest request;
  SupportRequestModel(this.request);

  factory SupportRequestModel.fromJson(Map<String, dynamic> json) {
    return SupportRequestModel(
      SupportRequest(
        id: (json['id'] as num).toInt(),
        conversationId: (json['conversation'] as num).toInt(),
        orderId: (json['order_id'] as num?)?.toInt() ?? 0,
        requestedById: (json['requested_by'] as num).toInt(),
        requestedByName: (json['requested_by_name'] as String?) ?? '',
        reason: (json['reason'] as String?) ?? '',
        priority: (json['priority'] as String?) ?? 'medium',
        priorityDisplay: (json['priority_display'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'pending',
        statusDisplay: (json['status_display'] as String?) ?? '',
        assignedToId: (json['assigned_to'] as num?)?.toInt(),
        assignedToName: json['assigned_to_name'] as String?,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      ),
    );
  }
}
