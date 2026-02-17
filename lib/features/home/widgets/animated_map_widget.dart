import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Geographic coordinate model
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

/// Defines the geographic bounding box for the map
class MapBounds {
  final double minLat; // South
  final double maxLat; // North
  final double minLng; // West
  final double maxLng; // East

  const MapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  /// Converts lat/long to normalized coordinates (0-1 range)
  Offset toNormalized(LatLng point) {
    final x = (point.longitude - minLng) / (maxLng - minLng);
    // Y is inverted because screen coordinates go down, lat goes up
    final y = (maxLat - point.latitude) / (maxLat - minLat);
    return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }

  /// Default bounds for Hyderabad, India
  static const hyderabad = MapBounds(
    minLat: 17.35,
    maxLat: 17.50,
    minLng: 78.40,
    maxLng: 78.55,
  );

  /// Default bounds for Bangalore, India
  static const bangalore = MapBounds(
    minLat: 12.90,
    maxLat: 13.05,
    minLng: 77.50,
    maxLng: 77.70,
  );

  /// Default bounds for Mumbai, India
  static const mumbai = MapBounds(
    minLat: 18.90,
    maxLat: 19.15,
    minLng: 72.80,
    maxLng: 72.95,
  );
}

/// Represents a match pin on the map with location and match percentage
class MatchPin {
  final LatLng location;
  final int percentage;
  final String? name;
  final String? avatarUrl;

  const MatchPin({
    required this.location,
    required this.percentage,
    this.name,
    this.avatarUrl,
  });

  /// Create from raw lat/lng values
  factory MatchPin.fromCoords({
    required double lat,
    required double lng,
    required int percentage,
    String? name,
    String? avatarUrl,
  }) {
    return MatchPin(
      location: LatLng(lat, lng),
      percentage: percentage,
      name: name,
      avatarUrl: avatarUrl,
    );
  }
}

/// AnimatedMapWidget displays a stylized map UI with animated match bubbles.
/// 
/// Features:
/// - Grid-based road network background
/// - Animated center location pin with pulse effect
/// - Match pins positioned using real lat/long coordinates
/// - Filter pills at the top (city + preference)
/// - Action buttons for modifying preferences and adding flat details
class AnimatedMapWidget extends StatefulWidget {
  final String city;
  final String preference;
  final MapBounds mapBounds;
  final List<MatchPin> matches;
  final LatLng? userLocation;
  final VoidCallback? onModifyPreferences;
  final VoidCallback? onAddFlatDetails;
  final Function(MatchPin)? onPinTapped;

  const AnimatedMapWidget({
    super.key,
    this.city = 'Hyderabad',
    this.preference = 'Vegetarian',
    this.mapBounds = MapBounds.hyderabad,
    this.matches = const [],
    this.userLocation,
    this.onModifyPreferences,
    this.onAddFlatDetails,
    this.onPinTapped,
  });

  /// Convenience constructor with default sample data
  factory AnimatedMapWidget.sample({
    String city = 'Hyderabad',
    String preference = 'Vegetarian',
    VoidCallback? onModifyPreferences,
    VoidCallback? onAddFlatDetails,
  }) {
    return AnimatedMapWidget(
      city: city,
      preference: preference,
      mapBounds: MapBounds.hyderabad,
      userLocation: const LatLng(17.425, 78.475),
      matches: const [
        MatchPin(
          location: LatLng(17.40, 78.42),
          percentage: 50,
          name: 'Rahul',
        ),
        MatchPin(
          location: LatLng(17.46, 78.50),
          percentage: 90,
          name: 'Priya',
        ),
        MatchPin(
          location: LatLng(17.38, 78.48),
          percentage: 40,
          name: 'Amit',
        ),
        MatchPin(
          location: LatLng(17.44, 78.52),
          percentage: 10,
          name: 'Sara',
        ),
      ],
      onModifyPreferences: onModifyPreferences,
      onAddFlatDetails: onAddFlatDetails,
    );
  }

  @override
  State<AnimatedMapWidget> createState() => _AnimatedMapWidgetState();
}

class _AnimatedMapWidgetState extends State<AnimatedMapWidget>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _bubbleController;
  late AnimationController _roadAnimationController;

  // Animations
  late Animation<double> _pulseAnimation;
  late List<Animation<double>> _bubbleFadeAnimations;
  late List<Animation<double>> _bubbleScaleAnimations;

  // Map display area (excluding padding for buttons/pills)
  static const double _mapPadding = 20.0;
  static const double _topOffset = 70.0;    // Space for filter pills
  static const double _bottomOffset = 120.0; // Space for buttons
  static const double _bubbleSize = 70.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void didUpdateWidget(AnimatedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize animations if matches changed
    if (oldWidget.matches.length != widget.matches.length) {
      _bubbleController.dispose();
      _initBubbleAnimations();
      _bubbleController.forward();
    }
  }

  void _initAnimations() {
    // Pulse animation for center pin (continuous)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Road animation (subtle movement)
    _roadAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _initBubbleAnimations();
    _bubbleController.forward();
  }

  void _initBubbleAnimations() {
    // Bubble animations (sequential fade-in and scale)
    _bubbleController = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.matches.length * 400)),
      vsync: this,
    );

    _bubbleFadeAnimations = [];
    _bubbleScaleAnimations = [];

    final matchCount = widget.matches.isEmpty ? 4 : widget.matches.length;
    
    // Create staggered animations for each bubble
    for (int i = 0; i < matchCount; i++) {
      final startInterval = (i * 0.15).clamp(0.0, 0.7);
      final endInterval = (startInterval + 0.3).clamp(0.0, 1.0);

      _bubbleFadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _bubbleController,
            curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
          ),
        ),
      );

      _bubbleScaleAnimations.add(
        Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(
            parent: _bubbleController,
            curve: Interval(startInterval, endInterval, curve: Curves.elasticOut),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bubbleController.dispose();
    _roadAnimationController.dispose();
    super.dispose();
  }

  /// Converts a LatLng to pixel position within the map widget
  Offset _latLngToPixel(LatLng point, Size mapSize) {
    final normalized = widget.mapBounds.toNormalized(point);
    
    // Calculate the usable map area (excluding UI elements)
    final usableWidth = mapSize.width - (2 * _mapPadding) - _bubbleSize;
    final usableHeight = mapSize.height - _topOffset - _bottomOffset - _bubbleSize;
    
    return Offset(
      _mapPadding + (normalized.dx * usableWidth),
      _topOffset + (normalized.dy * usableHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main map container
        Container(
          height: 420,
          decoration: BoxDecoration(
            color: const Color(0xFFB8B8B8),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mapSize = Size(constraints.maxWidth, 420);
                return Stack(
                  children: [
                    // Animated road grid background
                    AnimatedBuilder(
                      animation: _roadAnimationController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: mapSize,
                          painter: MapGridPainter(
                            animationValue: _roadAnimationController.value,
                          ),
                        );
                      },
                    ),

                    // Filter pills at top
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          _buildFilterPill(widget.city, isPrimary: true),
                          const SizedBox(width: 12),
                          _buildFilterPill(widget.preference, isPrimary: false),
                        ],
                      ),
                    ),

                    // Match bubbles positioned by lat/long
                    ..._buildMatchBubbles(mapSize),

                    // Center location pin with pulse (user's location)
                    if (widget.userLocation != null)
                      _buildUserLocationPin(mapSize),

                    // Action buttons at bottom
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 70,
                      child: Column(
                        children: [
                          _buildActionButton(
                            'Modify Preferences',
                            onTap: widget.onModifyPreferences,
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'Add Flat Details',
                            onTap: widget.onAddFlatDetails,
                          ),
                        ],
                      ),
                    ),

                    // Decorative black circle
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Subtitle
        const SizedBox(height: 16),
        const Text(
          'Profile matching based on user profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Georgia',
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildUserLocationPin(Size mapSize) {
    final position = _latLngToPixel(widget.userLocation!, mapSize);
    
    return Positioned(
      left: position.dx + (_bubbleSize / 2) - 18, // Center the pin
      top: position.dy + (_bubbleSize / 2) - 18,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: _buildLocationPin(),
          );
        },
      ),
    );
  }

  Widget _buildFilterPill(String text, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  List<Widget> _buildMatchBubbles(Size mapSize) {
    if (widget.matches.isEmpty) {
      return _buildDefaultBubbles(mapSize);
    }

    return List.generate(widget.matches.length, (index) {
      final match = widget.matches[index];
      final position = _latLngToPixel(match.location, mapSize);

      return Positioned(
        left: position.dx,
        top: position.dy,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _bubbleFadeAnimations[index],
            _bubbleScaleAnimations[index],
          ]),
          builder: (context, child) {
            return Opacity(
              opacity: _bubbleFadeAnimations[index].value,
              child: Transform.scale(
                scale: _bubbleScaleAnimations[index].value,
                child: GestureDetector(
                  onTap: () => widget.onPinTapped?.call(match),
                  child: _buildMatchBubble(
                    match.percentage,
                    name: match.name,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  /// Fallback bubbles when no matches provided (uses hardcoded positions)
  List<Widget> _buildDefaultBubbles(Size mapSize) {
    final defaultPositions = [
      const Offset(40, 120),
      const Offset(280, 100),
      const Offset(50, 280),
      const Offset(290, 260),
    ];
    final defaultPercentages = [50, 90, 40, 10];

    return List.generate(4, (index) {
      return Positioned(
        left: defaultPositions[index].dx,
        top: defaultPositions[index].dy,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _bubbleFadeAnimations[index],
            _bubbleScaleAnimations[index],
          ]),
          builder: (context, child) {
            return Opacity(
              opacity: _bubbleFadeAnimations[index].value,
              child: Transform.scale(
                scale: _bubbleScaleAnimations[index].value,
                child: _buildMatchBubble(defaultPercentages[index]),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildMatchBubble(int percentage, {String? name}) {
    // Color based on match quality
    Color getBubbleColor() {
      if (percentage >= 80) return const Color(0xFFE8F5E9); // Light green
      if (percentage >= 50) return const Color(0xFFFFF8E1); // Light amber
      return const Color(0xFFFFEBEE); // Light red
    }

    return CustomPaint(
      painter: SpeechBubblePainter(fillColor: getBubbleColor()),
      child: Container(
        width: _bubbleSize,
        height: _bubbleSize,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            if (name != null)
              Text(
                name,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPin() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.my_location,
          size: 18,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the map grid/road network background
class MapGridPainter extends CustomPainter {
  final double animationValue;

  MapGridPainter({this.animationValue = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF9A9A9A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final thinRoadPaint = Paint()
      ..color = const Color(0xFFA5A5A5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Main horizontal roads
    _drawHorizontalRoad(canvas, size, 80, roadPaint);
    _drawHorizontalRoad(canvas, size, 200, roadPaint);
    _drawHorizontalRoad(canvas, size, 320, roadPaint);

    // Main vertical roads
    _drawVerticalRoad(canvas, size, 100, roadPaint);
    _drawVerticalRoad(canvas, size, 250, roadPaint);

    // Diagonal roads
    _drawDiagonalRoad(canvas, size, thinRoadPaint);

    // Curved roads
    _drawCurvedRoads(canvas, size, thinRoadPaint);
  }

  void _drawHorizontalRoad(Canvas canvas, Size size, double y, Paint paint) {
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  void _drawVerticalRoad(Canvas canvas, Size size, double x, Paint paint) {
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  void _drawDiagonalRoad(Canvas canvas, Size size, Paint paint) {
    // Top-left to center diagonal
    final path1 = Path()
      ..moveTo(0, 150)
      ..lineTo(150, 220);
    canvas.drawPath(path1, paint);

    // Bottom diagonal
    final path2 = Path()
      ..moveTo(200, 280)
      ..lineTo(size.width, 350);
    canvas.drawPath(path2, paint);
  }

  void _drawCurvedRoads(Canvas canvas, Size size, Paint paint) {
    // Curved road top-left
    final curvePath1 = Path()
      ..moveTo(30, 0)
      ..quadraticBezierTo(60, 100, 30, 180);
    canvas.drawPath(curvePath1, paint);

    // Curved road right side
    final curvePath2 = Path()
      ..moveTo(size.width - 50, 80)
      ..quadraticBezierTo(size.width - 100, 180, size.width - 30, 280);
    canvas.drawPath(curvePath2, paint);

    // Additional curved paths for depth
    final curvePath3 = Path()
      ..moveTo(150, 0)
      ..quadraticBezierTo(200, 80, 180, 150);
    canvas.drawPath(curvePath3, paint);
  }

  @override
  bool shouldRepaint(covariant MapGridPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Custom painter for speech bubble shape
class SpeechBubblePainter extends CustomPainter {
  final Color fillColor;

  SpeechBubblePainter({this.fillColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final bubbleWidth = size.width;
    final bubbleHeight = size.height - 15;
    final tailHeight = 15.0;
    final radius = 20.0;

    // Create bubble path
    final path = Path();

    // Start from top-left corner
    path.moveTo(radius, 0);

    // Top edge
    path.lineTo(bubbleWidth - radius, 0);

    // Top-right corner
    path.arcToPoint(
      Offset(bubbleWidth, radius),
      radius: Radius.circular(radius),
    );

    // Right edge
    path.lineTo(bubbleWidth, bubbleHeight - radius);

    // Bottom-right corner
    path.arcToPoint(
      Offset(bubbleWidth - radius, bubbleHeight),
      radius: Radius.circular(radius),
    );

    // Bottom edge with tail
    path.lineTo(bubbleWidth * 0.55, bubbleHeight);
    path.lineTo(bubbleWidth * 0.45, bubbleHeight + tailHeight);
    path.lineTo(bubbleWidth * 0.35, bubbleHeight);
    path.lineTo(radius, bubbleHeight);

    // Bottom-left corner
    path.arcToPoint(
      Offset(0, bubbleHeight - radius),
      radius: Radius.circular(radius),
    );

    // Left edge
    path.lineTo(0, radius);

    // Top-left corner
    path.arcToPoint(
      Offset(radius, 0),
      radius: Radius.circular(radius),
    );

    path.close();

    // Draw shadow
    canvas.save();
    canvas.translate(2, 3);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw fill
    canvas.drawPath(path, paint);

    // Draw border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant SpeechBubblePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor;
  }
}
