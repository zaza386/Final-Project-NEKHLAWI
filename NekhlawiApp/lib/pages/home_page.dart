import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🔹 استيراد سوبابيس للجلب الآمن
import '../core/widgets/header_background.dart';
import '../core/widgets/upcoming_sessions_carousel.dart';

import '../core/widgets/home_search_bar.dart';
import '../core/widgets/home_welcome_card.dart';
import '../core/widgets/home_service_grid.dart';

class HomePage extends StatefulWidget {
  final String? userId;

  const HomePage({super.key, this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;
  String? userRole;
  String greeting = 'صباح الخير';
  final supabase = Supabase.instance.client;

  // 🔹 جلب الـ ID الحقيقي والآمن للمزارع الحالي من سوبابيس
  String get activeUserId {
    return widget.userId ?? supabase.auth.currentUser?.id ?? '';
  }

  @override
  void initState() {
    super.initState();
    _setGreeting();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      greeting = hour < 12 ? 'صباح الخير' : 'مساء الخير';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(color: Colors.white),

            const HeaderBackground(
              title: 'حياك الله يا النخلاوي',
              showBack: false,
            ),

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
                      HomeSearchBar(),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),

                              UserSessionsCarousel(
                                // 🔹 تم التعديل هنا: استخدام المعرف النشط لإنهاء مشكلة الـ UUID
                                userId: activeUserId,
                                statuses: const [
                                  'تحت المعاينة',
                                  'لم تبدأ',
                                  'بدأت',
                                  'مرفوضة',
                                  'أنتهت'
                                ],
                                iconAssetPath:
                                'assets/images/home_brown_icon.png',
                                userRole: 'user',
                              ),

                              const SizedBox(height: 24),

                              HomeWelcomeCard(
                                userId: activeUserId, // 🔹 استخدام المعرف النشط هنا أيضاً
                                greeting: greeting,
                              ),

                              const SizedBox(height: 24),

                              HomeServiceGrid(userId: activeUserId), // 🔹 وهنا أيضاً

                              const SizedBox(height: 40),

                              const Center(
                                child: Text(
                                  '©️ 2025 - 2026 نخلاوي',
                                  style: TextStyle(
                                    color: Colors.pink,
                                    fontSize: 12,
                                  ),
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
}