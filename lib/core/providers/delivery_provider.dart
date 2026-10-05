// lib/core/providers/delivery_provider.dart
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../services/local_storage_service.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/deliveries/accept_order_usecase.dart';
import '../../domain/usecases/deliveries/reject_order_usecase.dart';
import '../../domain/usecases/deliveries/update_location_usecase.dart';
import '../../domain/usecases/deliveries/get_order_detail_usecase.dart';
import '../../domain/usecases/deliveries/mark_as_delivered_usecase.dart';
import '../../domain/usecases/deliveries/get_available_orders_usecase.dart';
import '../../domain/usecases/deliveries/get_assigned_orders_usecase.dart'; // 🆕

class DeliveryProvider extends ChangeNotifier {
  final GetAvailableOrdersUseCase getAvailableOrdersUseCase;
  final GetAssignedOrdersUseCase getAssignedOrdersUseCase; // 🆕
  final GetOrderDetailUseCase getOrderDetailUseCase;
  final AcceptOrderUseCase acceptOrderUseCase;
  final RejectOrderUseCase rejectOrderUseCase;
  final UpdateLocationUseCase updateLocationUseCase;
  final MarkAsDeliveredUseCase markAsDeliveredUseCase;

  DeliveryProvider({
    required this.getAvailableOrdersUseCase,
    required this.getAssignedOrdersUseCase, // 🆕
    required this.getOrderDetailUseCase,
    required this.acceptOrderUseCase,
    required this.rejectOrderUseCase,
    required this.updateLocationUseCase,
    required this.markAsDeliveredUseCase,
  });

  List<OrderEntity> _availableOrders = [];
  List<OrderEntity> _assignedOrders = [];
  OrderEntity? _selectedOrder;
  bool _isLoading = false;
  String? _errorMessage;
  int? _currentOrderId;
  String? _currentDeliveryName;

  // Getters
  List<OrderEntity> get availableOrders => _availableOrders;
  List<OrderEntity> get assignedOrders => _assignedOrders;
  OrderEntity? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentOrderId => _currentOrderId;
  bool get hasAssignedOrders => _assignedOrders.isNotEmpty;
  String? get currentDeliveryName => _currentDeliveryName;

  Stream<Position>? _locationStream;
  bool _isTracking = false;
  bool _hasActiveOrder = false;

  bool get isTracking => _isTracking;
  bool get hasActiveOrder => _hasActiveOrder;

  // ============================================
  // ESTABLECER NOMBRE DEL REPARTIDOR
  // ============================================
  void setCurrentDeliveryName(String name) {
    _currentDeliveryName = name;
  }

  // ============================================
  // CARGAR PEDIDOS ASIGNADOS (🆕 CONECTADO AL BACKEND)
  // ============================================
  Future<void> loadAssignedOrders() async {
    // 🔥 Recuperar nombre si es necesario
    if (_currentDeliveryName == null) {
      try {
        final userData = await LocalStorageService().getUser();
        if (userData != null) {
          final name = userData['full_name'] ?? userData['username'] ?? '';
          if (name.isNotEmpty) {
            _currentDeliveryName = name;
            print(
              '✅ Nombre recuperado desde LocalStorage: $_currentDeliveryName',
            );
          }
        }
      } catch (e) {
        print('⚠️ Error al recuperar nombre desde LocalStorage: $e');
      }
    }

    if (_currentDeliveryName == null) {
      _setError('Usuario no autenticado');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // 🆕 Traer los pedidos asignados reales desde el backend
      // (in_delivery + delivered de los últimos 7 días)
      final orders = await getAssignedOrdersUseCase();
      _assignedOrders = orders;

      // Determinar si hay un pedido en curso (in_delivery) entre los
      // que devolvió el backend, y mantener sincronizado el storage
      // local que usa el tracking de ubicación.
      OrderEntity? activeOrder;
      for (final order in orders) {
        if (order.status == 'in_delivery') {
          activeOrder = order;
          break;
        }
      }

      final storage = LocalStorageService();

      if (activeOrder != null) {
        _currentOrderId = activeOrder.id;
        _hasActiveOrder = true;
        await storage.saveActiveOrderId(activeOrder.id);
        print('✅ Pedido activo detectado: ${activeOrder.id}');
      } else {
        _currentOrderId = null;
        _hasActiveOrder = false;
        await storage.clearActiveOrderId();
        print('📦 Sin pedido en curso entre los pedidos asignados');
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error cargando pedidos asignados desde backend: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ============================================
  // RESTAURAR PEDIDO ACTIVO (para tracking)
  // ============================================
  Future<void> restoreActiveOrder() async {
    final storage = LocalStorageService();
    final savedOrderId = storage.getActiveOrderId();

    if (savedOrderId == null) return;

    try {
      final order = await getOrderDetailUseCase(savedOrderId);
      if (order.status == 'in_delivery') {
        _currentOrderId = savedOrderId;
        _hasActiveOrder = true;
        _assignedOrders = [order];
        await startLocationTracking(hasActiveOrder: true);
        notifyListeners();
        print('✅ Pedido activo restaurado: ${order.id}');
      } else {
        await storage.clearActiveOrderId();
        _hasActiveOrder = false;
        _currentOrderId = null;
        _assignedOrders = [];
        notifyListeners();
        print('⚠️ Pedido activo ya no es válido (${order.status})');
      }
    } catch (e) {
      print('⚠️ No se pudo restaurar el pedido activo: $e');
      await storage.clearActiveOrderId();
      _hasActiveOrder = false;
      _currentOrderId = null;
      _assignedOrders = [];
      notifyListeners();
    }
  }

  // ============================================
  // MÉTODOS DE PEDIDOS
  // ============================================
  Future<void> loadAvailableOrders() async {
    _setLoading(true);
    _clearError();
    try {
      _availableOrders = await getAvailableOrdersUseCase();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOrderDetail(int orderId) async {
    _setLoading(true);
    _clearError();
    try {
      _selectedOrder = await getOrderDetailUseCase(orderId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptOrder(int orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final order = await acceptOrderUseCase(orderId);

      _availableOrders.removeWhere((item) => item.id == orderId);

      _assignedOrders = [order];

      _currentOrderId = order.id;
      _hasActiveOrder = true;

      await LocalStorageService().saveActiveOrderId(order.id);

      await startLocationTracking(hasActiveOrder: true);

      notifyListeners();

      print('✅ Pedido aceptado y guardado: ${order.id}');

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectOrder(int orderId, {String? reason}) async {
    _setLoading(true);
    _clearError();
    try {
      await rejectOrderUseCase(orderId, reason: reason);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markAsDelivered(int orderId) async {
    _setLoading(true);
    _clearError();
    try {
      await markAsDeliveredUseCase(orderId);

      // 🔥 Limpiar todo
      _assignedOrders = [];
      _currentOrderId = null;
      _hasActiveOrder = false;
      await LocalStorageService().clearActiveOrderId();
      await startLocationTracking(hasActiveOrder: false);
      notifyListeners();
      print('✅ Pedido entregado: $orderId');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================
  // GEOLOCALIZACIÓN
  // ============================================
  Future<void> startLocationTracking({bool hasActiveOrder = false}) async {
    if (_isTracking) {
      stopLocationTracking();
    }

    _hasActiveOrder = hasActiveOrder;

    final hasPermission = await LocationService.requestPermissions();
    if (!hasPermission) {
      print('❌ Permiso de ubicación denegado');
      return;
    }

    _isTracking = true;

    final accuracy = hasActiveOrder
        ? LocationAccuracy.high
        : LocationAccuracy.medium;
    final distanceFilter = hasActiveOrder ? 10 : 50;
    final timeLimit = hasActiveOrder
        ? const Duration(seconds: 10)
        : const Duration(seconds: 30);

    _locationStream = LocationService.getLocationStream(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
    );

    _locationStream!.listen(
      (Position position) async {
        final userData = await LocalStorageService().getUser();
        if (userData != null && userData['is_available'] != false) {
          final int? orderId = (_hasActiveOrder && _currentOrderId != null)
              ? _currentOrderId
              : null;
          await updateLocation(
            position.latitude,
            position.longitude,
            orderId: orderId,
          );
        }
      },
      onError: (error) {
        print('❌ Error en stream de ubicación: $error');
      },
    );
  }

  void stopLocationTracking({bool notify = true}) {
    _isTracking = false;
    _locationStream = null;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> updateLocation(double lat, double lng, {int? orderId}) async {
    if (orderId == null) return;
    try {
      await updateLocationUseCase(lat, lng, orderId: orderId);
    } catch (e) {
      print('Error al actualizar ubicación: $e');
    }
  }

  // ============================================
  // LIMPIAR ESTADO (LOGOUT)
  // ============================================
  void clearState() {
    _availableOrders = [];
    _assignedOrders = [];
    _selectedOrder = null;
    _isLoading = false;
    _errorMessage = null;
    _currentOrderId = null;
    _hasActiveOrder = false;
    _currentDeliveryName = null;
    stopLocationTracking(notify: false);
    notifyListeners();
  }

  // ============================================
  // HELPERS
  // ============================================
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
  }
}
