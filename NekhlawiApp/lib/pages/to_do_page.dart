import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';

class TodoPage extends StatelessWidget {
  final String title;

  const TodoPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // الخلفية
            Container(color: Colors.white),
            // الهيدر
            HeaderBackground(title: title),

            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: const Center(
                  child: Text(
                    '🚧 هذه الصفحة تحت التطوير (TODO)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}