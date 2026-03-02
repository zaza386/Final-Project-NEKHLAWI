import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:nekhlawi_app/pages/to_do_page.dart';

class ExpertCard extends StatelessWidget {
  final String name;
  final String specialization;
  final int pricePerHour;
  final VoidCallback onOpenProfile;
  

  const ExpertCard({
    super.key,
    required this.name,
    required this.specialization,
    required this.pricePerHour,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // light grey background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ الصورة في يمين الكارد قبل الاسم (أكبر)
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.header,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundImage: AssetImage('images/nekhlawi_icon.png'),
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(width: 10),

          // ✅ النصوص بالوسط
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  specialization.trim().isEmpty ? '—' : specialization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.darkBrown.withOpacity(.75),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 22, color: AppColors.darkBrown.withOpacity(.9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سعر الاستشارة تبدأ من: $pricePerHour ريال',
                        style: TextStyle(
                          color: AppColors.darkBrown.withOpacity(.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TodoPage(title: 'حجز موعد'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Text(
                      'حجز موعد',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ✅ السهم بعد الصورة
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TodoPage(title: 'حجز موعد'),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 26,
                color: AppColors.darkBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}