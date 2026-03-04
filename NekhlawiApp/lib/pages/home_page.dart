import 'package:flutter/material.dart';
import 'package:nekhlawi_app/pages/booking_experts_page.dart';
import 'package:nekhlawi_app/pages/mini_wiki.dart';
import 'package:nekhlawi_app/pages/ai_consultation_details_page.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import 'package:nekhlawi_app/pages/History_page.dart';
import 'package:nekhlawi_app/pages/user_profile.dart';
import 'package:nekhlawi_app/core/widgets/upcoming_sessions_carousel.dart';

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
            // الخلفية البيضاء الأساسية
            Container(color: Colors.white),

            /// الهيدر الأخضر الثابت
            const HeaderBackground(
              title: 'حياك الله يا النخلاوي',
              showBack: false,
            ),

            /// الطبقة البيضاء التي تحتوي المحتوى
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
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      /// 1. شريط البحث الثابت
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey, size: 22),
                              SizedBox(width: 12),
                              Text(
                                'ابحث عن أمراض، خبراء، أو مقالات...',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// 2. الجزء القابل للتمرير
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),

                              /// قسم الجلسات القادمة
                              UserSessionsCarousel(
                                userId: '3f155ab7-60b2-4f12-9271-8881a128659b',
                                statuses: const ['لم تبدأ', 'بدأت'],
                                iconAssetPath: 'assets/images/home_brown_icon.png',
                              ),

                              const SizedBox(height: 24),

                              /// كرت الترحيب
                              _buildWelcomeCard(context),

                              const SizedBox(height: 24),

                              /// شبكة الخدمات (تم تحديث الأيقونات والروابط)
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.1,
                                children: [
                                  _HomeCard(
                                    icon: Icons.camera_alt_outlined,
                                    title: 'تشخيص النخل',
                                    onTap: () => _goToAiDiagnosis(context, 'تشخيص النخل'),
                                  ),
                                  _HomeCard(
                                    icon: Icons.menu_book_outlined,
                                    title: 'مقالات عن النخل',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const MiniWiki()),
                                    ),
                                  ),
                                  _HomeCard(
                                    icon: Icons.chat_outlined,
                                    title: 'حجز مع خبير',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const BookingExpertsPage()),
                                    ),
                                  ),
                                  _HomeCard(
                                    icon: Icons.history,
                                    title: 'سجلك الزراعي',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ConsultationsPage()),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 40),

                              /// التذييل
                              const Center(
                                child: Text(
                                  '©️ 2025 - 2026 نخلاوي',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
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

  /// ويدجت كرت الترحيب
  Widget _buildWelcomeCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfilePage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.header.withOpacity(0.6),
              AppColors.header.withOpacity(0.3),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.header.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'صباح الخير يا أحمد 👋',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الدور: مزارع • اضغط لتعديل ملفك',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkBrown.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.darkBrown),
          ],
        ),
      ),
    );
  }

  /// دالة التنقل لصفحة التشخيص
  void _goToAiDiagnosis(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiConsultationDetailsPage(title: title),
      ),
    );
  }
}

/// ويدجت كرت الخدمات (تم إزالة الدوائر وتكبير الأيقونات)
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.header.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.header.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الأيقونة مباشرة بدون Container دائري
              Icon(icon, size: 42, color: AppColors.darkBrown),

              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
