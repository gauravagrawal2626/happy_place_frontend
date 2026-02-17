/// Custom Map Marker Widget
/// 
/// Displays a rounded rectangle marker with:
/// - Progress bar at top (black, width based on match percentage)
/// - Percentage text below
/// - Triangular pointer at bottom

import 'package:flutter/material.dart';

class CustomMapMarker extends StatelessWidget {
  final int matchPercentage; // 0-100
  final Color backgroundColor; // Default: AppColors.background (cyan)

  const CustomMapMarker({
    super.key,
    required this.matchPercentage,
    this.backgroundColor = const Color(0xFF4DD0E1), // AppColors.background
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main marker body
        Container(
          width: 88, // Increased for better visibility
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white,
              width: 2.5, // White border for better visibility
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar - more visible with better contrast
              Container(
                height: 6, // Increased for better visibility
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3), // Light background for unfilled portion
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Stack(
                  children: [
                    // Unfilled portion (background)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // Filled portion (progress)
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: matchPercentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              // Percentage text
              Text(
                '$matchPercentage%',
                style: const TextStyle(
                  fontSize: 14, // Increased from 12
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Triangular pointer
        CustomPaint(
          size: const Size(16, 12), // Increased for better visibility
          painter: _TrianglePainter(color: backgroundColor),
        ),
      ],
    );
  }
}

/// Custom painter for triangle pointer
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height); // Bottom center (point)
    path.lineTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
