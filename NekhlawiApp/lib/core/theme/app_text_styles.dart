import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class AppTextStyles {
  static const TextStyle headerTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBrown,
  );

  static const TextStyle title = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    color: Colors.grey,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    color: Colors.white,
  );
}