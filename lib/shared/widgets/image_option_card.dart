import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Image Option Card - Reusable Component
/// 
/// Used for image/icon grid options with:
/// - S3 image URL support
/// - Fallback icons
/// - Selection state
/// - Configurable size
class ImageOptionCard extends StatelessWidget {
  final String text;
  final String? imageUrl;
  final IconData? fallbackIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;
  final double fontSize;

  const ImageOptionCard({
    super.key,
    required this.text,
    this.imageUrl,
    this.fallbackIcon,
    required this.isSelected,
    required this.onTap,
    this.size = 80,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image/Icon container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildContent(),
            ),
          ),
          const SizedBox(height: 10),
          
          // Label
          SizedBox(
            width: size + 20,
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? AppColors.textDark
                    : AppColors.textDark.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: size * 0.75,
        height: size * 0.75,
        fit: BoxFit.contain,
        color: isSelected ? Colors.white : null,
        colorBlendMode: isSelected ? BlendMode.srcIn : null,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          );
        },
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Icon(
      fallbackIcon ?? Icons.image_outlined,
      size: size * 0.5,
      color: isSelected ? Colors.white : AppColors.textDark,
    );
  }
}

