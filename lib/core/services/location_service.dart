import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
// lib/core/services/location_service.dart

class LocationService {
  // ============================================
  // SOLICITAR PERMISOS
  // ============================================
  static Future<bool> requestPermissions() async {
    // Para Android 12+ necesitamos permisos específicos
    if (await Permission.location.isGranted) {
      return true;
    }

    // Solicitar permiso de ubicación en primer plano
    final status = await Permission.location.request();
    if (status.isGranted) {
      // Para Android, solicitar también permiso de fondo si es necesario
      if (await Permission.locationAlways.isDenied) {
        await Permission.locationAlways.request();
      }
      return true;
    }
    return false;
  }

  // ============================================
  // OBTENER UBICACIÓN ACTUAL (única vez)
  // ============================================
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  // ============================================
  // STREAM DE UBICACIÓN - CONFIGURABLE
  // ============================================
  static Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    int distanceFilter = 50, // metros (más alto = menos consumo)
    Duration timeLimit = const Duration(seconds: 30),
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: timeLimit,
      ),
    );
  }
}
