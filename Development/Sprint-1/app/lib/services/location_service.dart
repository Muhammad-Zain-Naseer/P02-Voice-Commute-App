import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/logger.dart';

class LocationService {
  static String? _cachedLocation;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(
    minutes: 2,
  ); // Reduced from 5 to 2 minutes for better accuracy

  /// Get current location and convert to address
  /// Returns formatted address string or null if failed
  static Future<String?> getCurrentLocationAddress() async {
    try {
      // Check cache first (valid for 5 minutes)
      if (_cachedLocation != null && _cacheTime != null) {
        final age = DateTime.now().difference(_cacheTime!);
        if (age < _cacheDuration) {
          Logger.log(
            '📍 LocationService: Using cached location: $_cachedLocation',
          );
          return _cachedLocation;
        }
      }

      Logger.log('📍 LocationService: Checking location permissions...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.error('📍 LocationService: Location services are disabled');
        return null;
      }

      // Check location permission (don't request again if already granted)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        Logger.log('📍 LocationService: Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.error('📍 LocationService: Location permissions denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Logger.error(
          '📍 LocationService: Location permissions permanently denied',
        );
        return null;
      }

      Logger.log('📍 LocationService: Permission granted, getting position...');

      // Get current position with improved accuracy handling
      Position position;
      try {
        // First attempt: Try with high accuracy (best for outdoors)
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(
            seconds: 30,
          ), // Increased from 10s to 30s for better GPS lock
        );
        Logger.log(
          '📍 LocationService: High accuracy position acquired: ${position.latitude}, ${position.longitude}',
        );
      } catch (e) {
        // Fallback: Try with medium accuracy (works better in urban areas)
        Logger.log(
          '📍 LocationService: High accuracy timeout, trying medium accuracy...',
        );
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );
          Logger.log(
            '📍 LocationService: Medium accuracy position acquired: ${position.latitude}, ${position.longitude}',
          );
        } catch (e) {
          // Last resort: Use last known position
          Logger.log(
            '📍 LocationService: Medium accuracy timeout, using last known position...',
          );
          position =
              await Geolocator.getLastKnownPosition() ??
              (throw Exception('Unable to get location: $e'));
          Logger.log(
            '📍 LocationService: Last known position: ${position.latitude}, ${position.longitude}',
          );
        }
      }

      Logger.log(
        '📍 LocationService: Final Position: ${position.latitude}, ${position.longitude}',
      );

      // Convert coordinates to address
      String address;
      if (kIsWeb) {
        // Use OpenStreetMap Nominatim API for web (geocoding package doesn't work on web)
        address = await _reverseGeocodeWeb(
          position.latitude,
          position.longitude,
        );
      } else {
        // Use geocoding package for mobile
        address = await _reverseGeocodeMobile(
          position.latitude,
          position.longitude,
        );
      }

      // Cache the location
      _cachedLocation = address;
      _cacheTime = DateTime.now();

      Logger.log('📍 LocationService: ✅ Current location: $address');
      return address;
    } catch (e) {
      Logger.error('📍 LocationService: ❌ Error getting location: $e');
      return null;
    }
  }

  /// Reverse geocode using OpenStreetMap Nominatim API (for web)
  static Future<String> _reverseGeocodeWeb(double lat, double lon) async {
    try {
      Logger.log('📍 LocationService: Reverse geocoding via Nominatim API...');
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'RideBookingApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        List<String> parts = [];

        // Add road/street
        if (address['road'] != null) {
          parts.add(address['road']);
        } else if (address['suburb'] != null) {
          parts.add(address['suburb']);
        }

        // Add city
        if (address['city'] != null) {
          parts.add(address['city']);
        } else if (address['town'] != null) {
          parts.add(address['town']);
        } else if (address['village'] != null) {
          parts.add(address['village']);
        }

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }

        // Fallback to display_name
        return data['display_name']?.toString().split(',').take(3).join(', ') ??
            'Current Location';
      }

      return 'Current Location';
    } catch (e) {
      Logger.error('📍 LocationService: Nominatim API error: $e');
      return 'Current Location';
    }
  }

  /// Reverse geocode using geocoding package (for mobile)
  static Future<String> _reverseGeocodeMobile(double lat, double lon) async {
    try {
      Logger.log(
        '📍 LocationService: Reverse geocoding via geocoding package...',
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);

      if (placemarks.isEmpty) {
        return 'Current Location';
      }

      Placemark place = placemarks[0];
      return _formatAddress(place);
    } catch (e) {
      Logger.error('📍 LocationService: Geocoding package error: $e');
      return 'Current Location';
    }
  }

  /// Format placemark into readable address
  static String _formatAddress(Placemark place) {
    List<String> parts = [];

    // Add street/sublocality
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }

    // Add locality/city
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    } else if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }

    // Add administrative area (state/province)
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      // Only add if not already in locality
      if (!parts.any((p) => p.contains(place.administrativeArea!))) {
        parts.add(place.administrativeArea!);
      }
    }

    // Join parts
    if (parts.isEmpty) {
      // Fallback to any available info
      if (place.name != null && place.name!.isNotEmpty) {
        return place.name!;
      }
      return 'Current Location';
    }

    return parts.join(', ');
  }
}
