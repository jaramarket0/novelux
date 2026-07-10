import 'package:flutter/material.dart';

// Theme-aware helper functions
class ThemeUtils {
  // Get input border based on current theme
  static OutlineInputBorder getInputBorder(BuildContext context, {bool isFocused = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double kBorderRadius = 12.0;
    
    if (isFocused) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFFB0FFC1) : const Color.fromARGB(255, 58, 71, 183),
          width: 2,
        ),
      );
    }
    
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(kBorderRadius),
      borderSide: BorderSide(
        color: isDark ? const Color(0xff878787) : const Color(0xffEAEAEA),
      ),
    );
  }
  
  // Get primary color based on theme
  static Color getPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xff878787) : const Color.fromARGB(240, 252, 251, 251);
  }
  
  // Get secondary color based on theme
  static Color getSecondaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFB3C2FF) : const Color(0xff347EFB);
  }
  
  // Get surface color based on theme
  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xff292526) : const Color.fromARGB(240, 252, 251, 251);
  }
  
  // Get background color based on theme
  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xff1b2028) : const Color(0xffffffff);
  }

    // Get background color based on theme
  static Color getBackgroundColor1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xff1b2028) :Colors.grey.shade200;
  }
  
  // Get text color based on theme
  static Color getTextColor(BuildContext context, {bool isSecondary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isSecondary) {
      return isDark ? const Color(0xff878787) : const Color.fromARGB(255, 100, 105, 108);
    }
    
    return isDark ? const Color(0xffffffff) : const Color(0xff111111);
  }
}