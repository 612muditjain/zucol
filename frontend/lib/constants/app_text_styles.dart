import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static final heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static final subtitle = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
  );

  static final body = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static final link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.link,
  );
}