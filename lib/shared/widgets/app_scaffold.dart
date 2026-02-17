import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// AppScaffold - Base Wrapper for All Screens
/// 
/// This is the FIRST component that wraps all screens in the app.
/// It provides:
/// - Consistent turquoise background color
/// - SafeArea wrapper
/// - Optional AppBar
/// - Consistent padding
/// 
/// **Benefits:**
/// - Change background color in ONE place (AppColors.background)
/// - Consistent look across all screens
/// - Automatic SafeArea handling
/// 
/// **Usage:**
/// ```dart
/// AppScaffold(
///   child: YourScreenContent(),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  /// The main content of the screen
  final Widget child;
  
  /// Optional app bar
  final PreferredSizeWidget? appBar;
  
  /// Whether to apply SafeArea (default: true)
  final bool useSafeArea;
  
  /// Whether to make the content scrollable (default: false)
  final bool scrollable;
  
  /// Padding around the content (default: EdgeInsets.zero)
  final EdgeInsetsGeometry padding;

  const AppScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.useSafeArea = true,
    this.scrollable = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Add padding if specified
    if (padding != EdgeInsets.zero) {
      content = Padding(
        padding: padding,
        child: content,
      );
    }

    // Make scrollable if needed
    if (scrollable) {
      content = SingleChildScrollView(
        child: content,
      );
    }

    // Wrap in SafeArea if needed
    if (useSafeArea) {
      content = SafeArea(
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background, // Turquoise background
      appBar: appBar,
      body: content,
    );
  }
}

