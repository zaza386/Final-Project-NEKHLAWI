import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/pages/forgot_password_page(enter_emile).dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';
import 'role_selection_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
            const HeaderBackground(title: 'تسجيل دخول',
            ),

            // المحتوى
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),

                              const Text(
                                'هلا بالنخلاوي 🌴',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkBrown
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'سجل دخولك وخلك قريب من نخلك',
                                style: TextStyle(color: AppColors.darkBrown),
                              ),

                              const SizedBox(height: 50),

                              const CustomInput(
                                hint: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
                              ),

                              const SizedBox(height: 16),

                              const CustomInput(
                                hint: 'كلمة المرور',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),

                              const SizedBox(height: 12),

                              const _ForgotPasswordButton(),

                              const SizedBox(height: 30),

                              PrimaryButton(
                                title: 'تسجيل دخول',
                                onPressed: () {},
                              ),
                            
                              const SizedBox(height: 16),

                              Center(
                                child: RichText(
                                  textDirection: TextDirection.rtl,
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'لا أملك حساب، ',
                                        style: TextStyle(
                                          color: AppColors.darkBrown,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'إنشاء حساب جديد',
                                        style: const TextStyle(
                                          color: AppColors.darkBrown,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline, // اختياري
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const RoleSelectionPage(),
                                              ),
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),
                              
                              const Spacer(), // 🔑 هذا يدفّ الحقوق تحت

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




class _ForgotPasswordButton extends StatelessWidget {
  const _ForgotPasswordButton();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 150,
          height: 45,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForgotPasswordPage(),
                ),
              );
            },
            child: const Text('نسيت كلمة المرور؟'),
          ),
        ),
      ),
    );
  }
}