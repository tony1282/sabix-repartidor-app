import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../domain/usecases/notifications/register_device_usecase.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final RegisterDeviceUseCase registerDeviceUseCase;

  FirebaseNotificationService({required this.registerDeviceUseCase});

  Future<void> initialize() async {
    debugPrint("🚀 FirebaseNotificationService.initialize() INICIANDO");

    await _requestPermission();

    debugPrint("🔓 _requestPermission() terminó, pidiendo token...");

    final token = await _messaging.getToken();

    debugPrint("🎯 _messaging.getToken() devolvió: $token");

    if (token != null) {
      debugPrint("🔥 TOKEN FCM:");
      debugPrint(token);

      try {
        await registerDeviceUseCase(
          token: token,
          deviceType: "android",
          deviceName: "Sabix Repartidor",
        );
        debugPrint("✅ registerDeviceUseCase completado sin errores");
      } catch (e) {
        debugPrint("❌ registerDeviceUseCase FALLÓ: $e");
      }
    } else {
      debugPrint("⚠️ Token FCM vino null, no se registró nada");
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint("🔄 Token actualizado:");
      debugPrint(newToken);

      await registerDeviceUseCase(
        token: newToken,
        deviceType: "android",
        deviceName: "Sabix Repartidor",
      );
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("📩 ${message.notification?.title}");

      debugPrint(message.notification?.body);
    });

    debugPrint("🏁 FirebaseNotificationService.initialize() TERMINÓ");
  }

  Future<void> _requestPermission() async {
    debugPrint("🔔 Pidiendo permiso de notificaciones...");

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("🔔 Permiso FCM: ${settings.authorizationStatus}");
  }
}
