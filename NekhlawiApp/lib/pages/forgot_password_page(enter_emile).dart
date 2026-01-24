import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/pages/verify_email_page(OTP).dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  bool submitted = false;
  bool isEmailValid = false;

  bool get canProceed =>
      emailController.text.isNotEmpty && isEmailValid;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
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
              title: 'نسيت كلمة المرور',
            ),

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
                                'مو مشكلة 🌱',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkBrown,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'دخل بريدك الإلكتروني وبنساعدك تسترجع حسابك',
                                style: TextStyle(
                                  color: AppColors.darkBrown,
                                ),
                              ),

                              const SizedBox(height: 50),

                              /// البريد الإلكتروني (مع فالديشن)
                              CustomInput(
                                hint: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
                                controller: emailController,
                                showError: submitted,
                                onValidationChanged: (v) {
                                  setState(() => isEmailValid = v);
                                },
                                onChanged: (_) => setState(() {}),
                              ),

                              const SizedBox(height: 30),

                              PrimaryButton(
                                title: 'إعادة تعيين كلمة المرور',
                                onPressed: () {
                                  setState(() => submitted = true);

                                  if (!canProceed) return;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EmailVerificationPage(),
                                    ),
                                  );
                                },
                              ),

                              const Spacer(),

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