class PushMessageModel {
  final String title;
  final String body;
  final Map<String, dynamic> data;

  PushMessageModel({
    required this.title,
    required this.body,
    required this.data,
  });

  factory PushMessageModel.fromFirebase({
    required String? title,
    required String? body,
    required Map<String, dynamic> data,
  }) {
    return PushMessageModel(title: title ?? '', body: body ?? '', data: data);
  }

  int? get orderId {
    final value = data['order_id'];

    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  String? get type {
    return data['type'];
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'body': body, 'data': data};
  }
}
