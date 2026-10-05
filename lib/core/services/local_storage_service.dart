import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ============================================
  // INICIALIZAR
  // ============================================
  static Future<LocalStorageService> init() async {
    print('🔧 Inicializando LocalStorageService');
    _prefs = await SharedPreferences.getInstance();
    print('✅ SharedPreferences inicializado');
    return _instance;
  }

  // ============================================
  // TOKEN (Guardado seguro)
  // ============================================

  Future<void> saveToken(String token) async {
    print(
      '💾 Guardando token en secure storage... (${token.substring(0, 20)}...)',
    );
    try {
      await _secureStorage.write(key: 'auth_token', value: token);
      // Verificar que se guardó
      final saved = await _secureStorage.read(key: 'auth_token');
      print(
        '✅ Token guardado correctamente. Verificado: ${saved != null ? saved.substring(0, 20) + '...' : '❌ FALLÓ'}',
      );
    } catch (e) {
      print('❌ Error guardando token: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    print('🔍 Leyendo token de secure storage...');
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        print('✅ Token leído correctamente (${token.substring(0, 20)}...)');
        return token;
      } else {
        print('❌ Token no encontrado o vacío');
        return null;
      }
    } catch (e) {
      print('❌ Error leyendo token: $e');
      return null;
    }
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    print('💾 Guardando refresh token en secure storage...');
    try {
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      print('✅ Refresh token guardado correctamente');
    } catch (e) {
      print('❌ Error guardando refresh token: $e');
      rethrow;
    }
  }

  Future<String?> getRefreshToken() async {
    print('🔍 Leyendo refresh token de secure storage...');
    try {
      final token = await _secureStorage.read(key: 'refresh_token');
      if (token != null && token.isNotEmpty) {
        print('✅ Refresh token leído correctamente');
        return token;
      } else {
        print('❌ Refresh token no encontrado o vacío');
        return null;
      }
    } catch (e) {
      print('❌ Error leyendo refresh token: $e');
      return null;
    }
  }

  Future<void> deleteTokens() async {
    print('🗑️ Eliminando tokens...');
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
    print('✅ Tokens eliminados');
  }

  // ============================================
  // USUARIO (Guardado seguro)
  // ============================================

  Future<void> saveUser(Map<String, dynamic> userData) async {
    print('💾 Guardando usuario en secure storage...');
    try {
      final json = jsonEncode(userData);
      await _secureStorage.write(key: 'user_data', value: json);
      print('✅ Usuario guardado correctamente (${userData['username']})');
    } catch (e) {
      print('❌ Error guardando usuario: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    print('🔍 Leyendo usuario de secure storage...');
    try {
      final data = await _secureStorage.read(key: 'user_data');
      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data);
        print('✅ Usuario leído correctamente (${decoded['username']})');
        return decoded;
      } else {
        print('❌ Usuario no encontrado');
        return null;
      }
    } catch (e) {
      print('❌ Error leyendo usuario: $e');
      return null;
    }
  }

  Future<void> deleteUser() async {
    print('🗑️ Eliminando usuario...');
    await _secureStorage.delete(key: 'user_data');
    print('✅ Usuario eliminado');
  }

  // ============================================
  // DATOS DE SESIÓN (SharedPreferences)
  // ============================================

  Future<void> saveIsAuthenticated(bool value) async {
    await _prefs?.setBool('is_authenticated', value);
  }

  bool getIsAuthenticated() {
    return _prefs?.getBool('is_authenticated') ?? false;
  }

  Future<void> saveRememberMe(bool value) async {
    await _prefs?.setBool('remember_me', value);
  }

  bool getRememberMe() {
    return _prefs?.getBool('remember_me') ?? false;
  }

  Future<void> saveLastSync(DateTime date) async {
    await _prefs?.setString('last_sync', date.toIso8601String());
  }

  DateTime? getLastSync() {
    final dateStr = _prefs?.getString('last_sync');
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  // ============================================
  // CONFIGURACIÓN DEL USUARIO
  // ============================================

  Future<void> saveThemeMode(String themeMode) async {
    await _prefs?.setString('theme_mode', themeMode);
  }

  String getThemeMode() {
    return _prefs?.getString('theme_mode') ?? 'system';
  }

  Future<void> saveLanguage(String language) async {
    await _prefs?.setString('language', language);
  }

  String getLanguage() {
    return _prefs?.getString('language') ?? 'es';
  }

  // ============================================
  // DATOS DEL DISPOSITIVO
  // ============================================

  Future<void> saveDeviceId(String deviceId) async {
    await _prefs?.setString('device_id', deviceId);
  }

  String? getDeviceId() {
    return _prefs?.getString('device_id');
  }

  Future<void> saveFcmToken(String token) async {
    await _prefs?.setString('fcm_token', token);
  }

  String? getFcmToken() {
    return _prefs?.getString('fcm_token');
  }

  // ============================================
  // PEDIDO ACTIVO DEL REPARTIDOR
  // ============================================

  Future<void> saveActiveOrderId(int orderId) async {
    print('💾 Guardando pedido activo: $orderId');
    await _prefs?.setInt('active_order_id', orderId);
    print('✅ Pedido activo guardado');
  }

  int? getActiveOrderId() {
    final id = _prefs?.getInt('active_order_id');
    print('📦 Pedido activo recuperado: $id');
    return id;
  }

  Future<void> clearActiveOrderId() async {
    print('🗑️ Limpiando pedido activo');
    await _prefs?.remove('active_order_id');
    print('✅ Pedido activo limpiado');
  }

  // ============================================
  // DATOS DE ENTREGAS (Cache)
  // ============================================

  Future<void> cacheDeliveries(List<Map<String, dynamic>> deliveries) async {
    final json = jsonEncode(deliveries);
    await _prefs?.setString('cached_deliveries', json);
    await _prefs?.setInt(
      'deliveries_cache_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  List<Map<String, dynamic>>? getCachedDeliveries() {
    final json = _prefs?.getString('cached_deliveries');
    if (json != null && json.isNotEmpty) {
      try {
        final List<dynamic> data = jsonDecode(json);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool isDeliveriesCacheValid() {
    final cacheTime = _prefs?.getInt('deliveries_cache_time');
    if (cacheTime == null) return false;
    final diff = DateTime.now().millisecondsSinceEpoch - cacheTime;
    return diff < 5 * 60 * 1000;
  }

  // ============================================
  // LIMPIAR TODOS LOS DATOS
  // ============================================

  Future<void> clearAll() async {
    print('🧹 Limpiando todos los datos de sesión...');
    await deleteTokens();
    await deleteUser();
    await _prefs?.remove('is_authenticated');
    await _prefs?.remove('cached_deliveries');
    await _prefs?.remove('deliveries_cache_time');
    await _prefs?.remove('active_order_id');
    print('✅ Sesión limpiada (configuración conservada)');
  }

  Future<void> clearEverything() async {
    print('🧹 Limpiando TODO (incluyendo configuración)...');
    await _secureStorage.deleteAll();
    await _prefs?.clear();
    print('✅ Todo limpiado');
  }

  // ============================================
  // UTILIDADES
  // ============================================

  Future<bool> hasSession() async {
    final token = await getToken();
    final user = await getUser();
    return token != null && user != null;
  }

  Future<Map<String, String>> getAllSecureKeys() async {
    try {
      final token = await getToken();
      final refresh = await getRefreshToken();
      final user = await getUser();
      return {
        'auth_token': token != null ? '${token.substring(0, 20)}...' : 'null',
        'refresh_token': refresh != null
            ? '${refresh.substring(0, 20)}...'
            : 'null',
        'user_data': user != null ? jsonEncode(user) : 'null',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
