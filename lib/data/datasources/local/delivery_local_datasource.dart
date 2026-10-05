import 'dart:convert';
import '../../../models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
// lib/data/datasources/local/delivery_local_datasource.dart

class DeliveryLocalDataSource {
  static const String _cacheKey = 'delivery_orders_cache';

  Future<void> cacheOrders(List<OrderModel> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = orders.map((order) => order.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error cacheando pedidos: $e');
    }
  }

  Future<List<OrderModel>> getCachedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return [];
      final List data = jsonDecode(jsonString);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      print('Error obteniendo caché: $e');
      return [];
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      print('Error limpiando caché: $e');
    }
  }
}
