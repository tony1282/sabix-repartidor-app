// lib/core/network/api_endpoints.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  // ============================================
  // URL REAL DE LA API
  // ============================================
  static String get baseUrl => dotenv.env['API_BASE_URL']!;
  static const String _apiVersion = '/api/v1';
  static String get _base => '$baseUrl$_apiVersion';

  // ============================================
  // AUTH - REGISTRO Y LOGIN
  // ============================================
  static String get register => '$_base/users/register/';
  static String get loginDelivery => '$_base/users/login/delivery/';
  static String get logout => '$_base/users/logout/';
  static String get refreshToken => '$_base/users/token/refresh/';

  // ============================================
  // USER - PERFIL
  // ============================================
  static String get profile => '$_base/users/profile/';
  static String get updateProfile => '$_base/users/profile/';
  static String get changePassword => '$_base/users/change-password/';

  // ============================================
  // VALIDACIONES
  // ============================================
  static String checkUsername(String username) =>
      '$_base/users/check-username/?username=$username';
  static String checkEmail(String email) =>
      '$_base/users/check-email/?email=$email';

  // ============================================
  // DELIVERY - REPARTIDOR
  // ============================================
  static String get availableOrders => '$_base/orders/delivery/available/';
  static String get assignedOrders => '$_base/orders/delivery/orders/';
  static String orderDetail(int orderId) =>
      '$_base/orders/delivery/orders/$orderId/';
  static String acceptOrder(int orderId) =>
      '$_base/orders/delivery/orders/$orderId/accept/';
  static String rejectOrder(int orderId) =>
      '$_base/orders/delivery/orders/$orderId/reject/';
  static String get updateLocation => '$_base/orders/delivery/location/';
  static String deliverOrder(int orderId) =>
      '$_base/orders/delivery/orders/$orderId/deliver/';

  // ============================================
  // NOTIFICACIONES
  // ============================================
  static String get notifications => '$_base/notifications/';
  static String get unreadNotifications => '$_base/notifications/unread/';
  static String get unreadCount => '$_base/notifications/unread/count/';
  static String notificationDetail(int id) => '$_base/notifications/$id/';
  static String markAsRead(int id) => '$_base/notifications/$id/read/';
  static String get markAllRead => '$_base/notifications/read-all/';
  static String deleteNotification(int id) => '$_base/notifications/$id/';
  static String get preferences => '$_base/notifications/preferences/';
  static String get devices => '$_base/notifications/devices/';
  static String deleteDevice(int id) => '$_base/notifications/devices/$id/';

  // ============================================
  // CHAT
  // ============================================
  static String get conversations => '$_base/chat/conversations/';
  static String conversationDetail(int id) => '$_base/chat/conversations/$id/';
  static String conversationByOrder(int orderId) =>
      '$_base/chat/conversations/by-order/$orderId/';
  static String messages(int convId) =>
      '$_base/chat/conversations/$convId/messages/';
  static String sendMessage(int convId) =>
      '$_base/chat/conversations/$convId/messages/send/';
  static String replyMessage(int convId, int msgId) =>
      '$_base/chat/conversations/$convId/messages/$msgId/reply/';
  static String readMessage(int convId, int msgId) =>
      '$_base/chat/conversations/$convId/messages/$msgId/read/';
  static String deleteMessage(int convId, int msgId) =>
      '$_base/chat/conversations/$convId/messages/$msgId/';
  static String conversationUnread(int convId) =>
      '$_base/chat/conversations/$convId/unread/';
  static String get totalUnread => '$_base/chat/unread/total/';
  static String requestSupport(int convId) =>
      '$_base/chat/conversations/$convId/request-support/';
  static String closeConversation(int convId) =>
      '$_base/chat/conversations/$convId/close/';

  // ============================================
  // CHAT - WEBSOCKET
  // ============================================
  static String get wsBaseUrl => dotenv.env['WS_BASE_URL']!;

  // ============================================
  // FIREBASE FCM
  // ============================================
  static String get registerFcmDevice => '$_base/notifications/fcm/device/';
  static String get unregisterFcmDevice => '$_base/notifications/fcm/device/';
  static String get fcmDevices => '$_base/notifications/fcm/devices/';
  static String deleteFcmDevice(String deviceId) =>
      '$_base/notifications/fcm/devices/$deviceId/';
}
