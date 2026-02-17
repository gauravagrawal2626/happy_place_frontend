import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import '../../../shared/widgets/custom_map_marker.dart';

/// Model for flat listings on the map
class FlatListing {
  final String id;
  final latlong2.LatLng location;
  final String name;
  final double rent;
  final String? address;
  final int matchPercentage;
  final String? ownerName;
  final String? ownerId; // Owner user_id for public profile
  final String? imageUrl;

  const FlatListing({
    required this.id,
    required this.location,
    required this.name,
    required this.rent,
    this.address,
    required this.matchPercentage,
    this.ownerName,
    this.ownerId,
    this.imageUrl,
  });

  /// Calculate distance from a point in kilometers using Haversine formula
  double distanceFrom(latlong2.LatLng point) {
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(location.latitude - point.latitude);
    final dLng = _toRadians(location.longitude - point.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(point.latitude)) *
            math.cos(_toRadians(location.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}

/// RealMapWidget displays an actual OpenStreetMap with flat listings.
/// 
/// Features:
/// - Real OpenStreetMap tiles showing actual roads and landmarks
/// - Flat listing markers positioned at exact lat/long
/// - User location marker with optional 5km radius circle
/// - Interactive: pan, zoom, tap markers
/// - Filter pills and action buttons overlay
class RealMapWidget extends StatefulWidget {
  final String city;
  final String preference;
  final latlong2.LatLng? userLocation;
  final List<FlatListing> flats;
  final double radiusKm;
  final bool showRadiusCircle;
  final VoidCallback? onModifyPreferences;
  final VoidCallback? onAddFlatDetails;
  final Function(FlatListing)? onFlatTapped;
  final Function(VoidCallback)? onRecenterReady; // Callback to provide recenter function

  const RealMapWidget({
    super.key,
    this.city = 'Hyderabad',
    this.preference = 'Vegetarian',
    this.userLocation,
    this.flats = const [],
    this.radiusKm = 5.0,
    this.showRadiusCircle = true,
    this.onModifyPreferences,
    this.onAddFlatDetails,
    this.onFlatTapped,
    this.onRecenterReady,
  });

  /// Sample data for testing
  factory RealMapWidget.sample({
    String city = 'Hyderabad',
    String preference = 'Vegetarian',
    VoidCallback? onModifyPreferences,
    VoidCallback? onAddFlatDetails,
  }) {
    // Hitech City, Hyderabad coordinates
    final userLoc = latlong2.LatLng(17.4435, 78.3772);

    return RealMapWidget(
      city: city,
      preference: preference,
      userLocation: userLoc,
      radiusKm: 5.0,
      showRadiusCircle: true,
      flats: [
        FlatListing(
          id: '1',
          location: latlong2.LatLng(17.4489, 78.3907), // Madhapur
          name: '2BHK in Madhapur',
          rent: 18000,
          address: 'Madhapur, Hyderabad',
          matchPercentage: 90,
          ownerName: 'Priya',
        ),
        FlatListing(
          id: '2',
          location: latlong2.LatLng(17.4256, 78.3426), // Gachibowli
          name: '3BHK in Gachibowli',
          rent: 25000,
          address: 'Gachibowli, Hyderabad',
          matchPercentage: 75,
          ownerName: 'Rahul',
        ),
        FlatListing(
          id: '3',
          location: latlong2.LatLng(17.4622, 78.3568), // Kondapur
          name: '1BHK in Kondapur',
          rent: 12000,
          address: 'Kondapur, Hyderabad',
          matchPercentage: 60,
          ownerName: 'Amit',
        ),
        FlatListing(
          id: '4',
          location: latlong2.LatLng(17.4375, 78.4482), // Jubilee Hills
          name: '2BHK in Jubilee Hills',
          rent: 30000,
          address: 'Jubilee Hills, Hyderabad',
          matchPercentage: 45,
          ownerName: 'Sara',
        ),
        FlatListing(
          id: '5',
          location: latlong2.LatLng(17.4156, 78.4082), // Banjara Hills
          name: '3BHK in Banjara Hills',
          rent: 35000,
          address: 'Banjara Hills, Hyderabad',
          matchPercentage: 85,
          ownerName: 'Kiran',
        ),
      ],
      onModifyPreferences: onModifyPreferences,
      onAddFlatDetails: onAddFlatDetails,
    );
  }

  @override
  State<RealMapWidget> createState() => _RealMapWidgetState();
}

class _RealMapWidgetState extends State<RealMapWidget>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  double _currentZoom = 13.0;
  latlong2.LatLng? _mapCenter;
  
  // Store initial values for recenter functionality
  double? _initialZoom;
  latlong2.LatLng? _initialCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Pulse animation for user location marker
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Initialize map center - use userLocation if provided, otherwise center on flats
    _mapCenter = widget.userLocation ?? _calculateFlatsCenter();
    
    // Store initial center for recenter functionality
    _initialCenter = _mapCenter;
    
    // Provide recenter function to parent via callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onRecenterReady != null) {
        widget.onRecenterReady!(recenterMap);
      }
      
      // If flats are already available when widget initializes, fit to them
      // This handles the case where flats are loaded before the widget is built
      if (widget.userLocation == null && widget.flats.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && widget.flats.isNotEmpty) {
            _fitMapToFlats();
          }
        });
      }
    });
  }
  
  /// Recenter map to initial position and zoom
  void recenterMap() {
    if (widget.flats.isEmpty) return;
    
    // Always fit to bounds to ensure all flats are visible
    // This recalculates the optimal zoom and center
    _fitMapToFlats();
  }

  /// Calculate center point from flats locations
  latlong2.LatLng? _calculateFlatsCenter() {
    if (widget.flats.isEmpty) {
      return null; // Will use default in build
    }
    
    double sumLat = 0;
    double sumLng = 0;
    for (final flat in widget.flats) {
      sumLat += flat.location.latitude;
      sumLng += flat.location.longitude;
    }
    
    return latlong2.LatLng(
      sumLat / widget.flats.length,
      sumLng / widget.flats.length,
    );
  }

  /// Fit map bounds to show all flats
  /// This dynamically calculates zoom based on the spread of flats:
  /// - If flats are close together (clustered), zoom will be higher
  /// - If flats are spread out (farther apart), zoom will be lower to show all
  void _fitMapToFlats() {
    if (widget.flats.isEmpty) return;
    
    final bounds = _calculateBounds();
    if (bounds != null) {
      // Use fitCamera to automatically calculate zoom and center to show all flats
      // This dynamically adjusts zoom based on the actual distribution of flats
      // Increased padding to zoom out more and ensure all flats are visible
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(
            horizontal: 150, // More horizontal padding
            vertical: 200,  // More vertical padding (top and bottom)
          ),
        ),
      );
      
      // Update state after fitting to reflect new zoom and center
      // Use a longer delay to ensure the camera movement is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _currentZoom = _mapController.camera.zoom;
            _mapCenter = _mapController.camera.center;
            // Store initial values if not already set
            if (_initialZoom == null) {
              _initialZoom = _currentZoom;
            }
            if (_initialCenter == null) {
              _initialCenter = _mapCenter;
            }
          });
        }
      });
    }
  }
  
  /// Calculate initial zoom level to show all flats
  /// This provides a conservative (more zoomed out) initial estimate
  /// fitCamera will do the exact calculation, but this helps start zoomed out
  double? _calculateInitialZoom() {
    if (widget.flats.isEmpty) return null;
    
    // Calculate bounds manually to get lat/lng differences
    double minLat = widget.flats.first.location.latitude;
    double maxLat = widget.flats.first.location.latitude;
    double minLng = widget.flats.first.location.longitude;
    double maxLng = widget.flats.first.location.longitude;
    
    for (final flat in widget.flats) {
      minLat = math.min(minLat, flat.location.latitude);
      maxLat = math.max(maxLat, flat.location.latitude);
      minLng = math.min(minLng, flat.location.longitude);
      maxLng = math.max(maxLng, flat.location.longitude);
    }
    
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = math.max(latDiff, lngDiff);
    
    // More conservative zoom calculation (lower zoom = more zoomed out)
    // Reduced zoom levels by 1-2 to ensure all flats are visible initially
    if (maxDiff > 0.1) return 9.0;  // Very spread out - zoom out more
    if (maxDiff > 0.05) return 10.0; // Spread out - zoom out more
    if (maxDiff > 0.02) return 11.0; // Medium spread
    if (maxDiff > 0.01) return 12.0; // Close together
    return 13.0; // Very close together - but still zoomed out more
  }

  /// Calculate bounds that contain all flats
  /// This creates a bounding box that encompasses all flat locations
  /// The fitCamera will use this to calculate the optimal zoom level
  LatLngBounds? _calculateBounds() {
    if (widget.flats.isEmpty) return null;
    
    // Start with first flat's coordinates
    double minLat = widget.flats.first.location.latitude;
    double maxLat = widget.flats.first.location.latitude;
    double minLng = widget.flats.first.location.longitude;
    double maxLng = widget.flats.first.location.longitude;
    
    // Expand bounds to include all flats
    for (final flat in widget.flats) {
      minLat = math.min(minLat, flat.location.latitude);
      maxLat = math.max(maxLat, flat.location.latitude);
      minLng = math.min(minLng, flat.location.longitude);
      maxLng = math.max(maxLng, flat.location.longitude);
    }
    
    // Add a larger buffer to ensure markers aren't at the very edge and zoom out more
    // Increased buffer percentage to zoom out more in all scenarios
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    
    // Use a larger buffer (20% instead of 10%) and ensure minimum buffer size
    final latBuffer = math.max(latDiff * 0.2, 0.01); // 20% buffer, minimum 0.01 degrees
    final lngBuffer = math.max(lngDiff * 0.2, 0.01); // 20% buffer, minimum 0.01 degrees
    
    return LatLngBounds(
      latlong2.LatLng(minLat - latBuffer, minLng - lngBuffer),
      latlong2.LatLng(maxLat + latBuffer, maxLng + lngBuffer),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Calculate dynamic radius based on zoom level
  /// Zoomed out (10-12): Show flats within 5km
  /// Medium zoom (12-14): Show flats within 3km
  /// Zoomed in (14-16): Show flats within 1.5km
  /// Very zoomed in (16+): Show flats within 0.5km
  double get _dynamicRadiusKm {
    if (_currentZoom <= 12) return widget.radiusKm; // 5km when zoomed out
    if (_currentZoom <= 14) return 3.0; // 3km at medium zoom
    if (_currentZoom <= 16) return 1.5; // 1.5km when zoomed in
    return 0.5; // 0.5km when very zoomed in
  }

  /// Filter flats based on zoom level and distance
  List<FlatListing> get _flatsToShow {
    final center = _mapCenter ?? widget.userLocation ?? latlong2.LatLng(17.4435, 78.3772);
    final radius = _dynamicRadiusKm;
    
    // Filter by distance from map center (or user location)
    final filtered = widget.flats.where((flat) {
      final distance = flat.distanceFrom(center);
      return distance <= radius;
    }).toList();
    
    // Sort by distance (closest first)
    filtered.sort((a, b) {
      final distA = a.distanceFrom(center);
      final distB = b.distanceFrom(center);
      return distA.compareTo(distB);
    });
    
    // Limit number of flats shown based on zoom level
    // More zoom = show more flats (but in smaller area)
    int maxFlats;
    if (_currentZoom <= 12) {
      maxFlats = 10; // Show top 10 when zoomed out
    } else if (_currentZoom <= 14) {
      maxFlats = 15; // Show top 15 at medium zoom
    } else if (_currentZoom <= 16) {
      maxFlats = 20; // Show top 20 when zoomed in
    } else {
      maxFlats = 30; // Show top 30 when very zoomed in
    }
    
    return filtered.take(maxFlats).toList();
  }

  /// Get color based on match percentage
  Color _getMatchColor(int percentage) {
    if (percentage >= 80) return const Color(0xFF4CAF50); // Green
    if (percentage >= 50) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFE57373); // Light red
  }

  @override
  void didUpdateWidget(RealMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If flats changed and we don't have a userLocation, recalculate center and fit bounds
    // This handles the case when flats are loaded after the widget is built
    if (widget.flats != oldWidget.flats && widget.userLocation == null) {
      final newCenter = _calculateFlatsCenter();
      if (newCenter != null && widget.flats.isNotEmpty) {
        _mapCenter = newCenter;
        // Fit map to show all flats - use longer delay to ensure map is fully ready
        // This ensures dynamic zoom calculation based on actual flat distribution
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && widget.flats.isNotEmpty) {
            _fitMapToFlats();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate center: userLocation if provided, otherwise center of flats, otherwise default
    final center = widget.userLocation ?? 
        _calculateFlatsCenter() ?? 
        latlong2.LatLng(17.4435, 78.3772);
    
    // Calculate initial zoom dynamically based on flat locations
    final initialZoom = widget.userLocation == null && widget.flats.isNotEmpty
        ? _calculateInitialZoom() ?? 11.0  // Dynamic zoom for seeker
        : 12.0; // Default for lister
    
    // For seeker (no userLocation), show all flats (they're already matched by API)
    // For lister (with userLocation), use filtered flats based on zoom
    final flatsToShow = widget.userLocation == null 
        ? widget.flats  // Show all flats for seeker
        : _flatsToShow; // Filtered flats for lister

    // Full screen map (no fixed height, no Column wrapper)
    return SizedBox.expand(
      child: Stack(
        children: [
                // OpenStreetMap
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: initialZoom,
                    minZoom: 10,
                    maxZoom: 18,
                    onMapReady: () {
                      // Fit map to show all flats when map is ready (for seeker)
                      // This ensures all flats are visible with dynamic zoom based on their spread
                      if (widget.userLocation == null && widget.flats.isNotEmpty) {
                        // Use a longer delay to ensure map is fully rendered and flats are loaded
                        // The fitCamera will automatically calculate the optimal zoom:
                        // - Higher zoom if flats are clustered together
                        // - Lower zoom if flats are spread out
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted && widget.flats.isNotEmpty) {
                            _fitMapToFlats();
                          }
                        });
                      }
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMove || 
                          event is MapEventScrollWheelZoom || 
                          event is MapEventFlingAnimation ||
                          event is MapEventMoveEnd) {
                        setState(() {
                          _currentZoom = _mapController.camera.zoom;
                          _mapCenter = _mapController.camera.center;
                        });
                      }
                    },
                  ),
                  children: [
                    // Map tiles from CartoDB Positron (light theme)
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.happyplace.app',
                      maxZoom: 19,
                    ),

                    // Dynamic radius circle based on zoom
                    if (widget.showRadiusCircle && (_mapCenter ?? widget.userLocation) != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _mapCenter ?? widget.userLocation!,
                            radius: _dynamicRadiusKm * 1000, // Convert to meters
                            useRadiusInMeter: true,
                            color: const Color(0xFF667eea).withOpacity(0.1),
                            borderColor: const Color(0xFF667eea),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),

                    // Flat markers
                    MarkerLayer(
                      markers: [
                        // User location marker
                        if (widget.userLocation != null)
                          Marker(
                            point: widget.userLocation!,
                            width: 50,
                            height: 50,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: _buildUserMarker(),
                                );
                              },
                            ),
                          ),

                        // Flat listing markers
                        ...flatsToShow.map((flat) => Marker(
                              point: flat.location,
                              width: 110, // Increased for larger, more visible markers
                              height: 110,
                              alignment: Alignment.topCenter, // Align marker point at bottom
                              child: GestureDetector(
                                onTap: () => widget.onFlatTapped?.call(flat),
                                child: _buildFlatMarker(flat),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),

                // Filter pills at top
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      _buildFilterPill(widget.city, isPrimary: true),
                      const SizedBox(width: 10),
                      _buildFilterPill(widget.preference, isPrimary: false),
                    ],
                  ),
                ),

                // Zoom buttons on the right side - centered vertically in available space
                Positioned(
                  top: 160, // Below header and filter chips
                  bottom: 100, // Above floating buttons
                  right: 8,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildZoomButton(Icons.add, () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom + 1,
                          );
                        }),
                        const SizedBox(height: 8),
                        _buildZoomButton(Icons.remove, () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom - 1,
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                  // Flats count badge with dynamic radius
                  Positioned(
                    top: 70,
                    left: 16,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${flatsToShow.length} flats within ${_dynamicRadiusKm.toStringAsFixed(1)}km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Action buttons at bottom (only show if callbacks are provided)
                if (widget.onModifyPreferences != null || widget.onAddFlatDetails != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 70,
                    child: Column(
                      children: [
                        if (widget.onModifyPreferences != null)
                          _buildActionButton(
                            'Modify Preferences',
                            onTap: widget.onModifyPreferences,
                          ),
                        if (widget.onModifyPreferences != null && widget.onAddFlatDetails != null)
                          const SizedBox(height: 10),
                        if (widget.onAddFlatDetails != null)
                          _buildActionButton(
                            'Add Flat Details',
                            onTap: widget.onAddFlatDetails,
                          ),
                      ],
                    ),
                  ),

        ],
      ),
    );
  }

  Widget _buildUserMarker() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF667eea),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildFlatMarker(FlatListing flat) {
    // Use the new custom marker widget with progress bar
    return CustomMapMarker(
      matchPercentage: flat.matchPercentage,
      backgroundColor: const Color(0xFF4DD0E1), // AppColors.background
    );
  }

  Widget _buildFilterPill(String text, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black87, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }

  Widget _buildActionButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for triangle pointer under markers
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

