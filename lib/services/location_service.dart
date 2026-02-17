import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as latlong2;

/// LocationService handles GPS location and geocoding operations.
/// 
/// Features:
/// - Get current device location
/// - Convert address to coordinates (geocoding)
/// - Convert coordinates to address (reverse geocoding)
/// - Handle location permissions
class LocationService {
  /// Singleton instance
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled and permissions granted
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current device location
  Future<latlong2.LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return latlong2.LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Convert address string to coordinates
  Future<latlong2.LatLng?> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return latlong2.LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
      }
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }

  /// Convert coordinates to address string
  Future<String?> getAddressFromLocation(latlong2.LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return [
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
      }
      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(latlong2.LatLng from, latlong2.LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convert meters to km
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

/// Predefined locations for quick selection
class PredefinedLocations {
  static final hyderabadHitechCity = latlong2.LatLng(17.4435, 78.3772);
  static final hyderabadMadhapur = latlong2.LatLng(17.4489, 78.3907);
  static final hyderabadGachibowli = latlong2.LatLng(17.4256, 78.3426);
  static final hyderabadKondapur = latlong2.LatLng(17.4622, 78.3568);
  static final hyderabadBanjaraHills = latlong2.LatLng(17.4156, 78.4082);
  
  static final bangaloreKoramangala = latlong2.LatLng(12.9352, 77.6245);
  static final bangaloreWhitefield = latlong2.LatLng(12.9698, 77.7500);
  static final bangaloreIndiranagar = latlong2.LatLng(12.9784, 77.6408);
  
  static final mumbaiAndheri = latlong2.LatLng(19.1136, 72.8697);
  static final mumbaiBandra = latlong2.LatLng(19.0596, 72.8295);

  static List<LocationOption> get popularLocations => [
    LocationOption('Hitech City, Hyderabad', hyderabadHitechCity),
    LocationOption('Madhapur, Hyderabad', hyderabadMadhapur),
    LocationOption('Gachibowli, Hyderabad', hyderabadGachibowli),
    LocationOption('Kondapur, Hyderabad', hyderabadKondapur),
    LocationOption('Banjara Hills, Hyderabad', hyderabadBanjaraHills),
    LocationOption('Koramangala, Bangalore', bangaloreKoramangala),
    LocationOption('Whitefield, Bangalore', bangaloreWhitefield),
    LocationOption('Indiranagar, Bangalore', bangaloreIndiranagar),
    LocationOption('Andheri, Mumbai', mumbaiAndheri),
    LocationOption('Bandra, Mumbai', mumbaiBandra),
  ];
}

class LocationOption {
  final String name;
  final latlong2.LatLng location;

  LocationOption(this.name, this.location);
}

