class SupportRequest {
  final int id;
  final int conversationId;
  final int orderId;
  final int requestedById;
  final String requestedByName;
  final String reason;
  final String priority; // low | medium | high | urgent
  final String priorityDisplay;
  final String status; // pending | in_progress | resolved | closed
  final String statusDisplay;
  final int? assignedToId;
  final String? assignedToName;
  final DateTime createdAt;

  const SupportRequest({
    required this.id,
    required this.conversationId,
    required this.orderId,
    required this.requestedById,
    required this.requestedByName,
    required this.reason,
    required this.priority,
    required this.priorityDisplay,
    required this.status,
    required this.statusDisplay,
    this.assignedToId,
    this.assignedToName,
    required this.createdAt,
  });

  bool get isActive => status == 'pending' || status == 'in_progress';
}
