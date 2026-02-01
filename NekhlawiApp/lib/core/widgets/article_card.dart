import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ArticleCard extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final VoidCallback onReadMore;

  const ArticleCard({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.onReadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.header,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              image,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Stack(
            clipBehavior: Clip.none, // ⭐ مهم عشان تطلع فوق الكارد
            children: [
              /// الخط
              const Divider(
                thickness: 3,
                color: AppColors.primary,
              ),

              /// أيقونة نخلاوي (نص فوق + يمين شوي)
              Positioned(
                top: -18, // 👈 يطلع نصها فوق المربع
                left: 35,  // 👈 تحريك لليمين (عدّل الرقم على مزاجك)
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.header,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage(
                      'images/nekhlawi_icon.png',
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBrown,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkBrown,
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onReadMore,
                    child: const Text(
                      'اقرأ المزيد',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}