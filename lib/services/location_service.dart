// lib/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Data class to hold location information
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? address;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.address,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      if (address != null) 'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Service to handle location permissions and GPS capture
class LocationService {
  /// Check current location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission from the user
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current GPS location with error handling
  /// Returns LocationData or throws Exception with user-friendly message
  Future<LocationData> getCurrentLocation({bool includeAddress = true}) async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable GPS in your device settings.',
        );
      }

      // 2. Check permission status
      LocationPermission permission = await checkPermission();
      
      print('📍 Location Permission Status: $permission');

      // 3. Request permission if needed
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        print('📍 Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          throw Exception(
            'Location permission denied. ClockEase needs location access to verify your attendance location.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Please enable location access in your device Settings > Apps > ClockEase > Permissions.',
        );
      }

      // 4. Get current position with BEST accuracy
      print('📍 Fetching GPS coordinates with high accuracy...');
      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,  // Maximum GPS accuracy
          distanceFilter: 0,                // Get every position update
          timeLimit: Duration(seconds: 15), // More time for GPS lock
        ),
      );

      print(
        '📍 GPS Coordinates: lat=${position.latitude.toStringAsFixed(6)}, '
        'lng=${position.longitude.toStringAsFixed(6)}, '
        'accuracy=${position.accuracy.toStringAsFixed(1)}m',
      );

      // 5. Validate accuracy
      if (position.accuracy > 50) {
        print('⚠️ GPS accuracy too low: ${position.accuracy.toStringAsFixed(1)}m');
        throw Exception(
          'GPS accuracy too low (${position.accuracy.toStringAsFixed(1)}m). Please move to an area with better GPS signal and try again.',
        );
      }

      print('✅ GPS accuracy acceptable: ${position.accuracy.toStringAsFixed(1)}m');

      // 6. Optional: Reverse geocoding to get address
      String? address;
      if (includeAddress) {
        try {
          print('📍 Fetching address from coordinates...');
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            address = [
              place.street,
              place.locality,
              place.administrativeArea,
              place.country,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
            
            print('📍 Address: $address');
          }
        } catch (e) {
          print('⚠️ Warning: Could not fetch address: $e');
          // Don't fail if reverse geocoding fails
          address = null;
        }
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        address: address,
        timestamp: DateTime.now(),
      );
    } on Exception {
      // Re-throw our custom exceptions
      rethrow;
    } catch (e) {
      // Wrap unexpected errors
      print('❌ Location error: $e');
      throw Exception(
        'Failed to get your location. Please ensure GPS is enabled and try again.',
      );
    }
  }

  /// Check if location permission is granted (helper method)
  Future<bool> isPermissionGranted() async {
    final permission = await checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
