import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:nekhlawi_app/pages/login_page.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/primary_button.dart';

class PasswordUpdatedPage extends StatelessWidget {
  const PasswordUpdatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            /// الخلفية
            Container(color: Colors.white),

            /// الهيدر
            const HeaderBackground(
              title: 'يمكنك الان تحديث كلمة المرور'
            ),

            /// المحتوى
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
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
                              const SizedBox(height: 40),

                              /// العنوان
                              const Text(
                                'هلا بالنخلاوي مرة ثانية 🌴',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkBrown,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 40),

                              /// علامة الصح
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// النص
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.\n يرجى التحقق من بريدك واتبع التعليمات لتحديث كلمة المرور الخاصة بك\n بعد التغيير، سجّل دخولك مرة أخرى.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                    height: 1.6,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              /// زر تسجيل الدخول
                              PrimaryButton(
                                title: 'تسجيل دخول',
                                onPressed: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),

                              const Spacer(),

                              /// الحقوق
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text(
                                  '©️ 2025 - 2026',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}