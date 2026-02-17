/// Match Models
/// 
/// Data models for GET /api/flats/matches response.
/// Supports both SEEKER (flats) and LISTER (seekers) flows.

import 'package:latlong2/latlong.dart' as latlong2;
import '../../../features/home/widgets/real_map_widget.dart';

/// Flat match for SEEKER view
class FlatMatch {
  final String id;
  final String title;
  final double matchScore; // 0-100
  final double distanceKm;
  final String? matchedLocation; // Which preferred location matched
  final latlong2.LatLng location; // Flat coordinates
  final double? rent;
  final String? address;
  final String? ownerName;
  final String? ownerId; // Owner user_id for public profile
  final String? imageUrl;
  final Map<String, dynamic>? additionalData; // Other flat fields

  FlatMatch({
    required this.id,
    required this.title,
    required this.matchScore,
    required this.distanceKm,
    this.matchedLocation,
    required this.location,
    this.rent,
    this.address,
    this.ownerName,
    this.ownerId,
    this.imageUrl,
    this.additionalData,
  });

  factory FlatMatch.fromJson(Map<String, dynamic> json) {
    // Parse location from various possible formats
    latlong2.LatLng location;
    
    print('[FlatMatch] Parsing location from JSON: ${json['location']}');
    print('[FlatMatch] JSON keys: ${json.keys.toList()}');
    
    if (json['location'] != null) {
      if (json['location'] is Map) {
        final loc = json['location'] as Map<String, dynamic>;
        print('[FlatMatch] Location is Map: $loc');
        if (loc['coordinates'] != null && loc['coordinates'] is List) {
          // GeoJSON format: { "type": "Point", "coordinates": [lng, lat] }
          final coords = loc['coordinates'] as List;
          print('[FlatMatch] GeoJSON coordinates: $coords');
          location = latlong2.LatLng(coords[1] as double, coords[0] as double);
          print('[FlatMatch] Parsed location: ${location.latitude}, ${location.longitude}');
        } else if (loc['latitude'] != null && loc['longitude'] != null) {
          location = latlong2.LatLng(
            loc['latitude'] as double,
            loc['longitude'] as double,
          );
          print('[FlatMatch] Parsed location from lat/lng: ${location.latitude}, ${location.longitude}');
        } else {
          print('[FlatMatch] ERROR: Invalid location format in Map');
          throw Exception('Invalid location format: missing coordinates or latitude/longitude');
        }
      } else {
        print('[FlatMatch] ERROR: Location is not a Map');
        throw Exception('Invalid location format: not a Map');
      }
    } else if (json['latitude'] != null && json['longitude'] != null) {
      location = latlong2.LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      );
      print('[FlatMatch] Parsed location from top-level lat/lng: ${location.latitude}, ${location.longitude}');
    } else {
      print('[FlatMatch] ERROR: No location data found');
      throw Exception('Location is required');
    }

    // Parse address - backend returns formatted_address if provided, otherwise constructs from locality/city/pincode
    final address = json['formatted_address'] as String? ?? json['address'] as String?;

    // user_id = lister/owner of flat; used for GET /api/users/{user_id}/public-profile (same field name as in seeker matches).
    final ownerIdRaw = json['user_id'] ?? json['owner_id'] ?? json['ownerId'];
    final ownerId = ownerIdRaw != null ? ownerIdRaw.toString().trim() : null;
    final ownerIdFinal = (ownerId != null && ownerId.isNotEmpty) ? ownerId : null;
    if (ownerIdFinal == null) {
      // ignore: avoid_print
      print('[FlatMatch] No user_id in match. Keys with owner/user: ${json.keys.where((k) => k.toString().toLowerCase().contains('owner') || k == 'user_id').toList()}');
    }

    return FlatMatch(
      id: json['_id'] as String,
      title: json['title'] as String? ?? '',
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      matchedLocation: json['matched_location'] as String?,
      location: location,
      rent: (json['rent'] as num?)?.toDouble(),
      address: address,
      ownerName: (json['owner_name'] ?? json['ownerName']) as String?,
      ownerId: ownerIdFinal,
      imageUrl: json['image_url'] as String?,
      additionalData: json,
    );
  }

  /// Convert to FlatListing for map display
  FlatListing toFlatListing() {
    return FlatListing(
      id: id,
      location: location,
      name: title,
      rent: rent ?? 0.0,
      address: address,
      matchPercentage: matchScore.round(),
      ownerName: ownerName,
      ownerId: ownerId,
      imageUrl: imageUrl,
    );
  }
}

/// Flatmate match for LISTER view
class FlatmateMatch {
  final String userId;
  final String fullName;
  final double matchScore; // 0-100
  final String flatId; // Always present for LISTER
  final int? age;
  final String? tagline;
  final String? imageUrl;
  final Map<String, dynamic>? additionalData; // Other user fields

  FlatmateMatch({
    required this.userId,
    required this.fullName,
    required this.matchScore,
    required this.flatId,
    this.age,
    this.tagline,
    this.imageUrl,
    this.additionalData,
  });

  factory FlatmateMatch.fromJson(Map<String, dynamic> json) {
    return FlatmateMatch(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      flatId: json['flat_id'] as String,
      age: json['age'] as int?,
      tagline: json['tagline'] as String?,
      imageUrl: json['image_url'] as String?,
      additionalData: json,
    );
  }
}

/// Match response wrapper
class MatchResponse {
  final List<dynamic> results; // List<FlatMatch> or List<FlatmateMatch>
  final int total;
  final int skip;
  final int limit;
  final String type; // "flats" or "seekers"
  final int? locationsSearched; // For SEEKER only

  MatchResponse({
    required this.results,
    required this.total,
    required this.skip,
    required this.limit,
    required this.type,
    this.locationsSearched,
  });

  /// Get results as FlatMatch list (for SEEKER)
  List<FlatMatch> get flats {
    if (type != 'flats') {
      throw Exception('Response type is not "flats"');
    }
    return results.map((r) => FlatMatch.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Get results as FlatmateMatch list (for LISTER)
  List<FlatmateMatch> get flatmates {
    if (type != 'seekers') {
      throw Exception('Response type is not "seekers"');
    }
    return results.map((r) => FlatmateMatch.fromJson(r as Map<String, dynamic>)).toList();
  }

  factory MatchResponse.fromJson(Map<String, dynamic> json) {
    return MatchResponse(
      results: json['results'] as List<dynamic>? ?? [],
      total: json['total'] as int? ?? 0,
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      type: json['type'] as String? ?? '',
      locationsSearched: json['locations_searched'] as int?,
    );
  }
}
