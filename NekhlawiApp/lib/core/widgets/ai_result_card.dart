import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AiResultCard extends StatelessWidget {
  final String title;
  final String confidence;
  final String reason;
  final String percentage;

  const AiResultCard({
    super.key,
    required this.title,
    required this.confidence,
    required this.reason,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.header,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(confidence),
                const SizedBox(height: 4),
                Text(reason),
              ],
            ),
          ),
          Text(
            percentage,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}