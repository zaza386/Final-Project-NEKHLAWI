
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HeaderBackground extends StatelessWidget {
  final String title;
  final bool showBack;

  const HeaderBackground({
    super.key,
    required this.title,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: AppColors.header,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                iconSize: 40,
                color: AppColors.darkBrown,
              ),
              Text(title, style: AppTextStyles.headerTitle),
          ],
        ),
      );
    }
  }