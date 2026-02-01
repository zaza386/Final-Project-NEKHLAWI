import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ConsultationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String time;
  final bool isAi;
  final VoidCallback? onTap; // ✅ لازم يكون موجود

  const ConsultationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
    required this.isAi,
    this.onTap, // ✅
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // ✅ مهم
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.header,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Icon(
                  isAi ? Icons.smart_toy : Icons.person,
                  color: AppColors.darkBrown,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.darkGrey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.darkGrey),
                const SizedBox(width: 6),
                Text(date, style: const TextStyle(color: AppColors.darkGrey)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time,
                    size: 16, color: AppColors.darkGrey),
                const SizedBox(width: 6),
                Text(time, style: const TextStyle(color: AppColors.darkGrey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}