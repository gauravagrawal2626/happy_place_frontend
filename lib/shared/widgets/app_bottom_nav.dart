/// App Bottom Navigation Bar
/// 
/// Shared bottom navigation bar used in both SEEKER and LISTER screens.
/// Contains 2 tabs: Search results, Account

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex; // 0: Search results, 1: Account
  final VoidCallback? onResultsTap;
  final VoidCallback? onAccountTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onResultsTap,
    this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.map_outlined,
                      color: currentIndex == 0 ? AppColors.textDark : Colors.grey[500],
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      label: 'Search results',
                      isSelected: currentIndex == 0,
                      onTap: onResultsTap ?? () {},
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildNavItem(
                      label: 'Account',
                      isSelected: currentIndex == 1,
                      onTap: onAccountTap ?? () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.background.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.circle,
                size: 8,
                color: AppColors.background,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.background : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
