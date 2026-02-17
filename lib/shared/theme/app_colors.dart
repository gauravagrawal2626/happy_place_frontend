import 'package:flutter/material.dart';

/// App Color Constants
/// 
/// Centralized color definitions for the entire app
/// Change colors here to update the entire app theme
class AppColors {
  // Background
  static const background = Color(0xFF4DD0E1); // Turquoise/Cyan (Figma)
  
  // Text
  static const textDark = Color(0xFF1A202C); // Dark text on light background
  static const textLight = Color(0xFFFFFFFF); // White text on dark background
  
  // Buttons
  static const primaryButton = Color(0xFF1A202C); // Dark button
  static const primaryButtonText = Color(0xFFFFFFFF); // White text on dark button
  
  // Chips/Tags
  static const chipSelected = Color(0xFF1A202C); // Dark when selected
  static const chipUnselected = Color(0xFFFFFFFF); // White when unselected
  static const chipBorder = Color(0xFF1A202C); // Border for unselected chips
  static const chipPink = Color(0xFFFFB6C1); // Special pink chip (e.g., "In a society")
  
  // Cards
  static const cardBackground = Color(0xFFFFFFFF);
  static const cardShadow = Color(0x1A000000); // 10% black for shadows
  
  // Status/Feedback
  static const success = Color(0xFF4CAF50); // Green
  static const warning = Color(0xFFFF9800); // Orange
  static const error = Color(0xFFE57373); // Light Red
  static const info = Color(0xFF2196F3); // Blue

  // Private constructor to prevent instantiation
  AppColors._();
}

