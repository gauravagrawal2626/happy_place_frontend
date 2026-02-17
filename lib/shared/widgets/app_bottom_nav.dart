/// App Bottom Navigation Bar
/// 
/// Shared bottom navigation bar used in both SEEKER and LISTER screens.
/// Contains 2 tabs: Search results, Account

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        // Remove box shadow for floating effect
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Search results tab
            Expanded(
              child: _buildNavItem(
                icon: Icons.search,
                label: 'Search results',
                isSelected: currentIndex == 0,
                onTap: onResultsTap ?? () {},
              ),
            ),
            // Account tab
            Expanded(
              child: _buildNavItem(
                icon: Icons.person_outline,
                label: 'Account',
                isSelected: currentIndex == 1,
                onTap: onAccountTap ?? () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.textDark : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.textDark : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
