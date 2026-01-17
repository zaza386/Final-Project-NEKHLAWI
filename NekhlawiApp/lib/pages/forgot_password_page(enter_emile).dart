import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/verify_email_page(OTP).dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

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

            // الهيدر
            const HeaderBackground(
              title: 'نسيت كلمة المرور',
              showBack: true,
            ),

            // المحتوى
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0, // 🔥 مهم
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),

                              const Text(
                                'مو مشكلة 🌱',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'دخل بريدك الإلكتروني وبنساعدك تسترجع حسابك',
                                style: TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 30),

                              const CustomInput(
                                hint: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
                              ),

                              const SizedBox(height: 30),

                              PrimaryButton(
                                title: 'إعادة تعيين كلمة المرور',
                                onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                  builder: (context) => const EmailVerificationPage(),
                                  ),
                                );
                                },
                              ),

                              const Spacer(), // 🔑 تثبيت الحقوق

                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    '©️ 2025 - 2026',
                                    style: TextStyle(color: Colors.grey),
                                  ),
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