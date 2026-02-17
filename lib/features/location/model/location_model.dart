/// Location Models - Phase 4
/// 
/// Models for location selection based on user role:
/// - SEEKER: Multiple preferred areas
/// - LISTER: Single exact flat location

/// Area model (for SEEKER - popular areas)
class Area {
  final String id;
  final String name;
  final String city;
  final double? latitude;
  final double? longitude;

  Area({
    required this.id,
    required this.name,
    required this.city,
    this.latitude,
    this.longitude,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    // API returns _id, but we use id
    final id = json['_id'] as String? ?? json['id'] as String? ?? '';
    
    // Extract coordinates from location GeoJSON: {"type": "Point", "coordinates": [longitude, latitude]}
    double? latitude;
    double? longitude;
    if (json['location'] != null && json['location'] is Map) {
      final location = json['location'] as Map<String, dynamic>;
      final coordinates = location['coordinates'] as List<dynamic>?;
      if (coordinates != null && coordinates.length >= 2) {
        longitude = (coordinates[0] as num).toDouble();
        latitude = (coordinates[1] as num).toDouble();
      }
    }
    
    // Fallback to direct latitude/longitude if location object not present
    if (latitude == null) {
      latitude = (json['latitude'] as num?)?.toDouble();
    }
    if (longitude == null) {
      longitude = (json['longitude'] as num?)?.toDouble();
    }
    
    return Area(
      id: id,
      name: json['name'] as String,
      city: json['city'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

/// Location with GeoJSON coordinates
class GeoLocation {
  final String type; // "Point"
  final List<double> coordinates; // [longitude, latitude]

  GeoLocation({
    this.type = 'Point',
    required this.coordinates,
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      type: json['type'] as String? ?? 'Point',
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((c) => (c as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }

  /// Create from latitude and longitude
  factory GeoLocation.fromLatLng(double latitude, double longitude) {
    return GeoLocation(
      coordinates: [longitude, latitude],
    );
  }

  double get longitude => coordinates[0];
  double get latitude => coordinates[1];
}

/// Preferred location for SEEKER
class PreferredLocation {
  final String id;
  final String name;
  final String city;
  final GeoLocation location;

  PreferredLocation({
    required this.id,
    required this.name,
    required this.city,
    required this.location,
  });

  factory PreferredLocation.fromArea(Area area) {
    if (area.latitude == null || area.longitude == null) {
      throw ArgumentError('Area must have coordinates to create PreferredLocation');
    }
    return PreferredLocation(
      id: area.id,
      name: area.name,
      city: area.city,
      location: GeoLocation.fromLatLng(area.latitude!, area.longitude!),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'location': location.toJson(),
    };
  }
}

/// Preferred locations request (SEEKER)
class PreferredLocationsRequest {
  final List<PreferredLocation> locations;
  final double searchRadiusKm;

  PreferredLocationsRequest({
    required this.locations,
    this.searchRadiusKm = 3.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'locations': locations.map((l) => l.toJson()).toList(),
      'search_radius_km': searchRadiusKm,
    };
  }
}

/// Flat location for LISTER
class FlatLocation {
  final GeoLocation location;
  final String locality;
  final String city;
  final String pincode;
  final String? formattedAddress; // Full formatted address (backend field name: formatted_address)

  FlatLocation({
    required this.location,
    required this.locality,
    required this.city,
    required this.pincode,
    this.formattedAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'location': location.toJson(),
      'locality': locality,
      'city': city,
      'pincode': pincode,
      if (formattedAddress != null) 'formatted_address': formattedAddress,
    };
  }
}

/// Create draft flat request (LISTER)
class CreateDraftFlatRequest {
  final FlatLocation location;
  final bool isDraft;

  CreateDraftFlatRequest({
    required this.location,
    this.isDraft = true,
  });

  Map<String, dynamic> toJson() {
    return {
      ...location.toJson(),
      'is_draft': isDraft,
    };
  }
}

/// Areas response from API
class AreasResponse {
  final List<Area> areas;
  final String city;

  AreasResponse({
    required this.areas,
    required this.city,
  });

  factory AreasResponse.fromJson(Map<String, dynamic> json) {
    return AreasResponse(
      areas: (json['areas'] as List<dynamic>?)
              ?.map((a) => Area.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      city: json['city'] as String? ?? '',
    );
  }
}

/// Draft flat creation response
class DraftFlatResponse {
  final String message;
  final String flatId;
  final String status;
  final bool isActive;
  final String? nextStep;

  DraftFlatResponse({
    required this.message,
    required this.flatId,
    required this.status,
    required this.isActive,
    this.nextStep,
  });

  factory DraftFlatResponse.fromJson(Map<String, dynamic> json) {
    return DraftFlatResponse(
      message: json['message'] as String,
      flatId: json['flat_id'] as String,
      status: json['status'] as String,
      isActive: json['is_active'] as bool,
      nextStep: json['next_step'] as String?,
    );
  }
}
