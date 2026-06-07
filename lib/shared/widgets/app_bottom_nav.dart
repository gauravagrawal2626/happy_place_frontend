/// App Bottom Navigation Bar
///
/// Shared bottom navigation used on SEEKER and LISTER main screens.
/// Tabs: Search (0), Chat (1), Account (2).

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  /// 0: Search, 1: Chat, 2: Account
  final int currentIndex;
  final VoidCallback? onResultsTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onAccountTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onResultsTap,
    this.onChatTap,
    this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                  if (currentIndex == 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Icon(
                        Icons.map_outlined,
                        color: AppColors.textDark,
                        size: 22,
                      ),
                    ),
                  Expanded(
                    child: _buildNavItem(
                      label: 'Search',
                      isSelected: currentIndex == 0,
                      onTap: onResultsTap ?? () {},
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: _buildNavItem(
                      label: 'Chat',
                      isSelected: currentIndex == 1,
                      onTap: onChatTap ?? () {},
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: _buildNavItem(
                      label: 'Account',
                      isSelected: currentIndex == 2,
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
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
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.background : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
