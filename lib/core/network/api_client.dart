// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'connectivity_service.dart';
import '../services/local_storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  final ConnectivityService _connectivity = ConnectivityService();
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) {
      print('ℹ️ ApiClient ya fue inicializado');
      return;
    }

    print('🔧 Inicializando ApiClient...');

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_loggingInterceptor());
    _dio.interceptors.add(_errorInterceptor());

    _isInitialized = true;
    print('✅ ApiClient inicializado correctamente');
  }

  // ============================================
  // INTERCEPTOR DE AUTENTICACIÓN
  // ============================================
  Interceptor _authInterceptor() => InterceptorsWrapper(
    onRequest: (options, handler) async {
      print('🔑 Interceptor onRequest ejecutándose para: ${options.path}');

      final token = await LocalStorageService().getToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        print('✅ Token agregado a la cabecera (${token.substring(0, 20)}...)');
      } else {
        print('! Token no encontrado o vacío');
      }

      print('📋 Headers finales: ${options.headers}');
      return handler.next(options);
    },
    onError: (error, handler) async {
      print('❌ Error en petición: ${error.response?.statusCode}');

      if (error.response?.statusCode == 401) {
        final refreshToken = await LocalStorageService().getRefreshToken();
        if (refreshToken != null) {
          try {
            print('🔄 Intentando refrescar token...');
            final response = await _dio.post(
              ApiEndpoints.refreshToken,
              data: {'refresh': refreshToken},
            );
            if (response.statusCode == 200) {
              final newToken = response.data['access'];
              await LocalStorageService().saveToken(newToken);
              print('✅ Token refrescado correctamente');

              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              final retryResponse = await _dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          } catch (e) {
            print('❌ Falló el refresh token: $e');
            await LocalStorageService().clearAll();
          }
        } else {
          print('! Refresh token no encontrado');
        }
      }
      return handler.next(error);
    },
  );

  // ============================================
  // INTERCEPTOR DE LOGGING
  // ============================================
  Interceptor _loggingInterceptor() => InterceptorsWrapper(
    onRequest: (options, handler) {
      print('📤 REQUEST: ${options.method} ${options.path}');
      if (options.headers.isNotEmpty) {
        final headers = Map<String, String>.from(options.headers);
        if (headers.containsKey('Authorization')) {
          final auth = headers['Authorization']!;
          headers['Authorization'] = '${auth.substring(0, 20)}...';
        }
        print('Headers: $headers');
      }
      if (options.data != null) {
        print('Data: ${options.data}');
      }
      return handler.next(options);
    },
    onResponse: (response, handler) {
      print('📥 RESPONSE: ${response.statusCode} ${response.realUri.path}');
      return handler.next(response);
    },
    onError: (error, handler) {
      print('❌ ERROR: ${error.message}');
      if (error.response != null) {
        print('Status: ${error.response?.statusCode}');
        print('Data: ${error.response?.data}');
      }
      return handler.next(error);
    },
  );

  // ============================================
  // INTERCEPTOR DE ERRORES
  // ============================================
  Interceptor _errorInterceptor() => InterceptorsWrapper(
    onError: (error, handler) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw Exception('Tiempo de conexión agotado');
      } else if (error.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión a internet');
      } else if (error.type == DioExceptionType.badResponse) {
        throw Exception(
          error.response?.data['message'] ?? 'Error en el servidor',
        );
      }
      return handler.next(error);
    },
  );

  // ============================================
  // MÉTODOS PÚBLICOS
  // ============================================

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    if (!await _connectivity.checkConnection()) {
      throw Exception('Se requiere conexión a internet');
    }
    return _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) async {
    if (!await _connectivity.checkConnection()) {
      throw Exception('Se requiere conexión a internet');
    }
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    if (!await _connectivity.checkConnection()) {
      throw Exception('Se requiere conexión a internet');
    }
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    if (!await _connectivity.checkConnection()) {
      throw Exception('Se requiere conexión a internet');
    }
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
  }) async {
    if (!await _connectivity.checkConnection()) {
      throw Exception('Se requiere conexión a internet');
    }

    return _dio.delete(path, data: data, queryParameters: params);
  }

  Dio get dio => _dio;
}
