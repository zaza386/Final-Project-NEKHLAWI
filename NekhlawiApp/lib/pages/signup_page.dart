import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/header_background.dart';
import 'email_confirmation_page.dart';
import 'terms_and_conditions_page.dart';

class SignUpPage extends StatefulWidget {
  final String role; // يستقبل 'user' أو 'expert' من صفحة RoleSelection

  const SignUpPage({super.key, required this.role});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool isAccepted = false;
  bool submitted = false;
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isEmailValid = false;
  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // دالة التسجيل الأساسية (تم تعديل اللوجيك فقط)
  Future<void> _signUpWithPassword() async {
    if (isLoading) return;
    setState(() => submitted = true);

    // التحقق من المدخلات
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        !isEmailValid ||
        !passwordsMatch ||
        !isAccepted) {
      _showError('يرجى التأكد من تعبئة جميع الحقول والموافقة على الشروط');
      return;
    }

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      // 1. تسجيل الحساب في Supabase Auth فقط
      // حذفنا الـ insert من هنا لأن مكانه الصحيح في صفحة التأكيد لضمان نجاح العملية
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'role': widget.role},
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );

      if (!mounted) return;

      // 2. الانتقال لصفحة تأكيد الإيميل وتمرير البيانات
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailConfirmationPage(
            email: email,
            password: password,
            role: widget.role,
          ),
        ),
      );

    } catch (e) {
      _showError('❌ حدث خطأ أثناء إنشاء الحساب: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
            const HeaderBackground(title: 'إنشاء حساب جديد', showBack: true),
            Positioned(
              top: 140, left: 0, right: 0, bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        // حقل البريد
                        CustomInput(
                            hint: 'البريد الإلكتروني',
                            icon: Icons.email_outlined,
                            controller: emailController,
                            showError: submitted,
                            onValidationChanged: (v) => setState(() => isEmailValid = v)),
                        const SizedBox(height: 16),
                        // حقل كلمة المرور
                        CustomInput(
                            hint: 'كلمة المرور',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            controller: passwordController),
                        const SizedBox(height: 16),
                        // تأكيد كلمة المرور
                        CustomInput(
                            hint: 'تأكيد كلمة المرور',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            controller: confirmPasswordController,
                            matchWith: passwordController),
                        const SizedBox(height: 20),
                        // الموافقة على الشروط
                        Row(
                          children: [
                            Checkbox(
                                value: isAccepted,
                                activeColor: AppColors.primary,
                                onChanged: (v) => setState(() => isAccepted = v ?? false)),
                            Expanded(
                                child: RichText(
                                    text: TextSpan(children: [
                                      const TextSpan(
                                          text: 'أوافق على ',
                                          style: TextStyle(color: AppColors.primary, fontFamily: 'Tajawal')),
                                      TextSpan(
                                          text: 'الشروط والخصوصية',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              decoration: TextDecoration.underline),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) => const TermsAndConditionsPage()))),
                                    ]))),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // زر الإنشاء
                        PrimaryButton(
                          title: isLoading ? 'جاري إنشاء الحساب...' : 'إنشاء حساب',
                          onPressed: _signUpWithPassword,
                        ),
                        const SizedBox(height: 40),
                        const Center(
                            child: Text('©️ 2025 - 2026', style: TextStyle(color: Colors.grey))),
                        const SizedBox(height: 20),
                      ],
                    ),
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