// lib/core/providers/auth_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/connectivity_service.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_notification_service.dart';

import '../../domain/usecases/notifications/register_device_usecase.dart';

import '../../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final LocalStorageService _storage;
  final ConnectivityService _connectivity;
  final RegisterDeviceUseCase? _registerDeviceUseCase;

  AuthProvider({
    ApiClient? apiClient,
    LocalStorageService? storage,
    ConnectivityService? connectivity,
    RegisterDeviceUseCase? registerDeviceUseCase,
  }) : _apiClient = apiClient ?? ApiClient(),
       _storage = storage ?? LocalStorageService(),
       _connectivity = connectivity ?? ConnectivityService(),
       _registerDeviceUseCase = registerDeviceUseCase {
    print('🔧 AuthProvider iniciado');
    _loadUserFromStorage();
  }

  UserModel? _currentUser;

  bool _isLoading = false;

  String? _errorMessage;

  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _isAuthenticated;

  // ===============================
  // FCM
  // ===============================

  void _registerFcmDevice() {
    final useCase = _registerDeviceUseCase;
    if (useCase == null) return;

    // Fire-and-forget: no bloquea la restauración de sesión.
    // ignore: unawaited_futures
    FirebaseNotificationService(registerDeviceUseCase: useCase).initialize();
  }

  // ===============================
  // CARGAR SESIÓN
  // ===============================

  Future<void> _loadUserFromStorage() async {
    try {
      print('📂 Cargando sesión guardada');

      final token = await _storage.getToken();

      final userData = await _storage.getUser();

      if (token != null && userData != null) {
        _currentUser = UserModel.fromJson(userData);

        _isAuthenticated = true;

        print('✅ Usuario restaurado: ${_currentUser?.username}');

        // ✅ Ya hay token válido de sesión restaurada: registramos el
        // dispositivo FCM aquí también, para cubrir el caso de un
        // usuario que reabre la app sin volver a pasar por login/registro.
        _registerFcmDevice();

        notifyListeners();
      } else {
        print('❌ No existe sesión');
      }
    } catch (e) {
      print('❌ Error cargando sesión: $e');
    }
  }

  // ===============================
  // LOGIN
  // ===============================

  Future<bool> login({
    required String username,

    required String password,
  }) async {
    _setLoading(true);

    _clearError();

    if (!await _connectivity.checkConnection()) {
      _setError('Sin conexión a internet');

      _setLoading(false);

      return false;
    }

    try {
      print('🔑 Login usuario $username');

      final response = await _apiClient.post(
        ApiEndpoints.loginDelivery,

        data: {"username": username, "password": password},
      );

      final data = response.data;

      final responseData = data['data'] ?? data['result'] ?? data;

      final accessToken = responseData['access'] ?? responseData['token'];

      final refreshToken = responseData['refresh'];

      final userData = responseData['user'] ?? responseData;

      final baseUser = UserModel.fromJson(userData);

      final user = UserModel(
        id: baseUser.id,

        username: baseUser.username,

        email: baseUser.email,

        firstName: baseUser.firstName,

        lastName: baseUser.lastName,

        phone: baseUser.phone,

        userType: baseUser.userType,

        isActive: baseUser.isActive,

        profileImage: baseUser.profileImage,

        createdAt: baseUser.createdAt,

        updatedAt: baseUser.updatedAt,

        token: accessToken ?? baseUser.token,

        refreshToken: refreshToken ?? baseUser.refreshToken,

        vehicleType: baseUser.vehicleType,

        vehiclePlate: baseUser.vehiclePlate,

        isAvailable: baseUser.isAvailable,

        currentLocationLat: baseUser.currentLocationLat,

        currentLocationLng: baseUser.currentLocationLng,
      );

      _currentUser = user;

      _isAuthenticated = true;

      if (user.token != null) {
        await _storage.saveToken(user.token!);
      }

      if (user.refreshToken != null) {
        await _storage.saveRefreshToken(user.refreshToken!);
      }

      await _storage.saveUser(user.toJson());

      print('✅ Login correcto');

      notifyListeners();

      _setLoading(false);

      return true;
    } on DioException catch (e) {
      String message = 'Credenciales incorrectas';

      final data = e.response?.data;

      if (data is Map) {
        message = data['message'] ?? data['error'] ?? message;
      }

      _setError(message);

      _setLoading(false);

      return false;
    } catch (e) {
      _setError('Error inesperado: $e');

      _setLoading(false);

      return false;
    }
  }

  // ===============================
  // LOGOUT
  // ===============================

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      print('Logout error: $e');
    }

    await _storage.clearAll();

    _currentUser = null;

    _isAuthenticated = false;

    notifyListeners();
  }

  // ===============================
  // VALIDAR SESIÓN
  // ===============================

  Future<bool> checkAuthStatus() async {
    final token = await _storage.getToken();

    if (token == null) {
      return false;
    }

    try {
      final response = await _apiClient.get(ApiEndpoints.profile);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);

        _currentUser = user;

        _isAuthenticated = true;

        notifyListeners();

        return true;
      }
    } catch (e) {
      print('Token inválido: $e');
    }

    await _storage.clearAll();

    _currentUser = null;

    _isAuthenticated = false;

    notifyListeners();

    return false;
  }

  // ===============================
  // HELPERS
  // ===============================

  void _setLoading(bool value) {
    _isLoading = value;

    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;

    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();

    notifyListeners();
  }

  // ===============================
  // REGISTER
  // ===============================

  Future<bool> register({
    required String username,

    required String email,

    required String password,

    required String firstName,

    required String lastName,

    required String phone,

    String? vehicleType,

    String? vehiclePlate,
  }) async {
    _setLoading(true);

    _clearError();

    if (!await _connectivity.checkConnection()) {
      _setError('Sin conexión a internet');

      _setLoading(false);

      return false;
    }

    try {
      print('📝 Registrando usuario: $username');

      final user = UserModel(
        username: username,

        email: email,

        firstName: firstName,

        lastName: lastName,

        phone: phone,

        userType: 'delivery',

        vehicleType: vehicleType ?? 'Moto',

        vehiclePlate: vehiclePlate ?? '',
      );

      final response = await _apiClient.post(
        ApiEndpoints.register,

        data: user.toRegisterJson(password),
      );

      final data = response.data;

      final responseData = data['data'] ?? data['result'] ?? data;

      final accessToken = responseData['access'] ?? responseData['token'];

      final refreshToken = responseData['refresh'];

      final userData = responseData['user'] ?? responseData;

      final baseUser = UserModel.fromJson(userData);

      final newUser = UserModel(
        id: baseUser.id,

        username: baseUser.username,

        email: baseUser.email,

        firstName: baseUser.firstName,

        lastName: baseUser.lastName,

        phone: baseUser.phone,

        userType: baseUser.userType,

        isActive: baseUser.isActive,

        profileImage: baseUser.profileImage,

        createdAt: baseUser.createdAt,

        updatedAt: baseUser.updatedAt,

        token: accessToken ?? baseUser.token,

        refreshToken: refreshToken ?? baseUser.refreshToken,

        vehicleType: baseUser.vehicleType,

        vehiclePlate: baseUser.vehiclePlate,

        isAvailable: baseUser.isAvailable,

        currentLocationLat: baseUser.currentLocationLat,

        currentLocationLng: baseUser.currentLocationLng,
      );

      _currentUser = newUser;

      _isAuthenticated = true;

      if (newUser.token != null) {
        await _storage.saveToken(newUser.token!);
      }

      if (newUser.refreshToken != null) {
        await _storage.saveRefreshToken(newUser.refreshToken!);
      }

      await _storage.saveUser(newUser.toJson());

      notifyListeners();

      _setLoading(false);

      print('✅ Registro exitoso');

      return true;
    } on DioException catch (e) {
      String message = 'Error al registrarse';

      final data = e.response?.data;

      if (data is Map) {
        if (data['username'] != null) {
          message = data['username'][0];
        } else if (data['email'] != null) {
          message = data['email'][0];
        } else if (data['password'] != null) {
          message = data['password'][0];
        } else if (data['message'] != null) {
          message = data['message'];
        }
      }

      _setError(message);

      _setLoading(false);

      return false;
    } catch (e) {
      _setError('Error inesperado: $e');

      _setLoading(false);

      return false;
    }
  }
}
