import 'package:flutter/material.dart';
import 'package:nekhlawi_app/pages/booking_experts_page.dart';
import 'package:nekhlawi_app/pages/mini_wiki.dart';
import 'package:nekhlawi_app/pages/to_do_page.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import 'package:nekhlawi_app/pages/consultations_page.dart';
import 'package:nekhlawi_app/pages/user_profile.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // الخلفية
            Container(color: Colors.white),
            /// الهيدر
            const HeaderBackground(
              title: 'حياك الله يا النخلاوي',
              showBack: false,
            ),

            /// المحتوى
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      /// شريط البحث (شكلي فقط)
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'ابحث...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// كرت الترحيب (زر)
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserProfilePage(),
                          ),
                        );
                      },
                      child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.header.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صباح الخير أحمد',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'الدور: مزارع\nعدل معلوماتك الشخصية',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.darkBrown,
          ),
        ),
      ],
    ),
  ),
),

                      const SizedBox(height: 24),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _HomeCard(
                            icon: Icons.camera_alt_outlined,
                            title: 'تشخيص النخل',
                            onTap: () => _goTodo(context, 'تشخيص النخل'),
                          ),
                          _HomeCard(
                            icon: Icons.menu_book_outlined,
                            title: 'مقالات عن النخل',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MiniWiki(),
                              ),
                            ),
                          ),
                          _HomeCard(
                            icon: Icons.chat_outlined,
                            title: 'بحجز مع خبير',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookingExpertsPage(),
                              ),
                            ),
                          ),
                          _HomeCard(
                            icon: Icons.history,
                            title: 'سجلك',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ConsultationsPage(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        '©️ 2025 - 2026',
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _goTodo(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodoPage(title: title),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.header.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.darkBrown),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}