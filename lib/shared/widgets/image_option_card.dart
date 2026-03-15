import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Image Option Card - Reusable Component
///
/// Used for image/icon grid options with:
/// - S3/CDN image URL support (PNG, JPEG)
/// - Local asset support (assets/images/...)
/// - Fallback icons when image missing or load fails
/// - Selection state
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

  static bool _isAssetPath(String url) {
    return url.startsWith('assets/') || url.startsWith('asset/');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.optionCardSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildContent(),
            ),
          ),
          const SizedBox(height: 10),
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
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackIcon();
    }
    final url = imageUrl!;

    if (_isAssetPath(url)) {
      return Image.asset(
        url,
        width: size * 0.75,
        height: size * 0.75,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
      );
    }

    return Image.network(
      url,
      headers: const {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
      },
      width: size * 0.75,
      height: size * 0.75,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[ImageOptionCard] "$text" load failed: $error');
        return _buildFallbackIcon();
      },
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
              color: isSelected ? AppColors.textDark : AppColors.textDark,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        fallbackIcon ?? Icons.image_outlined,
        size: size * 0.5,
        color: isSelected ? AppColors.textDark : AppColors.textDark,
      ),
    );
  }
}
