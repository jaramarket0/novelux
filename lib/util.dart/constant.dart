import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF9800); // Orange
  static const Color secondary = Colors.black;
  static const Color background = Colors.white;
  static const Color error = Colors.red;
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.grey;
  static const Color statusBarGreen = Color(0xFF4CD964);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'Mont'
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'Mont'
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    fontFamily: 'Mont'
  );

  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.error,
    fontFamily: 'Mont'
  );
}

