import 'dart:math'; // ضروري لتوليد الكابتشا العشوائية
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

  // Controller للكابتشا
  final captchaController = TextEditingController();

  bool isEmailValid = false;
  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

  // حالة التحقق من الكابتشا والنص العشوائي
  bool isCaptchaVerified = false;
  String randomString = "";

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // توليد الكابتشا عند تحميل الصفحة
    buildCaptcha();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    captchaController.dispose();
    super.dispose();
  }

  // دالة توليد الكابتشا
  void buildCaptcha() {
    const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
    const length = 6;
    final random = Random();
    randomString = String.fromCharCodes(
      List.generate(
        length,
            (index) => letters.codeUnitAt(random.nextInt(letters.length)),
      ),
    );
    setState(() {});
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

    // 1. التحقق من الكابتشا أولاً
    isCaptchaVerified = captchaController.text.trim() == randomString;
    if (!isCaptchaVerified) {
      _showError('الرجاء إدخال رمز التحقق بشكل صحيح');
      buildCaptcha();
      captchaController.clear();
      return;
    }

    // 2. التحقق من الحقول الفارغة
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showError('يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    // 3. التحقق من صحة صيغة الإيميل (المحلي)
    if (!isEmailValid) {
      _showError('صيغة البريد الإلكتروني غير صحيحة');
      return;
    }

    // 4. التحقق من تطابق كلمات المرور
    if (!passwordsMatch) {
      _showError('كلمات المرور غير متطابقة');
      return;
    }

    // 5. التحقق من الموافقة على الشروط
    if (!isAccepted) {
      _showError('يجب الموافقة على الشروط والأحكام للمتابعة');
      return;
    }

    // إذا اجتاز كل الفحوصات المحلية، نبدأ عملية التسجيل الفعلي
    setState(() {
      submitted = true;
      isLoading = true;
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'role': widget.role},
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );

      // فحص إضافي: إذا نجح الطلب ولكن لم يتم إنشاء هوية (Identity) فهذا يعني أن الإيميل مستخدم مسبقاً
      if (res.user != null && (res.user?.identities?.isEmpty ?? true)) {
        _showError('يوجد حساب مسجل بهذا البريد الإلكتروني مسبقاً');
        setState(() => isLoading = false);
        return;
      }

      if (!mounted) return;

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

    } on AuthException catch (error) {
      // فحص رسائل الخطأ من السيرفر
      if (error.message.contains('already registered') ||
          error.message.contains('already exists') ||
          error.statusCode == '422' ||
          error.statusCode == '400') {
        _showError('يوجد حساب مسجل بهذا البريد الإلكتروني مسبقاً');
      } else {
        _showError('خطأ: ${error.message}');
      }
    } catch (e) {
      _showError('❌ حدث خطأ غير متوقع: $e');
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                        const SizedBox(height: 24),
                        // قسم الكابتشا
                        const Text("رمز التحقق", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.5))
                              ),
                              child: Text(
                                randomString,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                              ),
                            ),
                            IconButton(
                              onPressed: buildCaptcha,
                              icon: const Icon(Icons.refresh, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: captchaController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'أدخل الرمز الظاهر أعلاه',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),

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