import 'package:flutter/material.dart';
import 'package:nekhlawi_app/pages/welcome_page2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/widgets/primary_button.dart';


class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final hasSession = session != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ===== الصورة الخلفية =====
            Positioned.fill(
              child: Image(
                image: const AssetImage('images/welcome.png'),
                fit: BoxFit.cover,
              ),
            ),

            // ===== رسالة حالة الـ Session (للتصحيح) =====
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasSession ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasSession 
                    ? '✅ توجد جلسة نشطة (${session?.user?.email})'
                    : '❌ لا توجد جلسة - يرجى تسجيل الدخول',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ===== المحتوى =====
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'حيّا الله من جانا .\nنخلاوي يرحب فيك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: 160,
                      height: 48,
                      child: PrimaryButton(
                        title: 'يلا نبدأ',
                        onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OnboardingPage(),
                ),
              );
            },
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      '©️ 2025 - 2026',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}