import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/header_background.dart';
import 'role_selection_page.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final captchaController = TextEditingController();

  bool submitted = false;
  bool isPasswordValid = false;
  bool isEmailValid = false;
  bool isCaptchaVerified = false;

  String randomString = "";

  StreamSubscription<AuthState>? _authSubscription;

  final supabase = Supabase.instance.client;

  bool get canProceed =>
      emailController.text.isNotEmpty &&
          isEmailValid &&
          isCaptchaVerified;

  // توليد الكابتشا
  void buildCaptcha() {
    const letters =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";

    const length = 6;

    final random = Random();

    randomString = String.fromCharCodes(
      List.generate(
        length,
            (index) => letters.codeUnitAt(
          random.nextInt(letters.length),
        ),
      ),
    );

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    buildCaptcha();

    _authSubscription =
        supabase.auth.onAuthStateChange.listen((data) {
          final session = data.session;

          if (session != null && mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const HomePage(),
              ),
                  (route) => false,
            );
          }
        });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();

    emailController.dispose();
    passwordController.dispose();
    captchaController.dispose();

    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => submitted = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    isCaptchaVerified =
        captchaController.text.trim() == randomString;

    // تحقق من الكابتشا
    if (!isCaptchaVerified) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء إدخال رمز التحقق بشكل صحيح',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      buildCaptcha();
      captchaController.clear();

      return;
    }

    if (email.isEmpty || password.isEmpty) {
      return;
    }

    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: Colors.white),

            const HeaderBackground(
              title: 'تسجيل دخول',
            ),

            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Column(
                      children: [
                      const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'هلا بالنخلاوي 🌴',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ),

                      const SizedBox(height: 50),

                      // الإيميل
                      CustomInput(
                        hint: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        controller: emailController,
                        showError: submitted,
                        onValidationChanged: (v) =>
                            setState(
                                  () => isEmailValid = v,
                            ),
                      ),

                      const SizedBox(height: 20),

                      // كلمة المرور
                      CustomInput(
                        hint: 'كلمة المرور',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: passwordController,
                        showError: submitted,
                      ),

                      const SizedBox(height: 24),

                      // Captcha UI
                      Row(
                        children: [
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(
                                color: AppColors.primary,
                              ),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Text(
                              randomString,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: buildCaptcha,
                            icon: const Icon(
                              Icons.refresh,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: captchaController,
                        decoration: const InputDecoration(
                          hintText:
                          "أدخل رمز التحقق",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      ForgotPasswordButton(),

                      const SizedBox(height: 30),

                      PrimaryButton(
                        title: 'تسجيل الدخول',
                        onPressed: _handleLogin,
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: SignUpLinkText(),
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

// زر نسيت كلمة المرور
class ForgotPasswordButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const ForgotPasswordPage(),
            ),
          );
        },
        child: const Text(
          'نسيت كلمة المرور؟',
          style: TextStyle(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// رابط إنشاء حساب
class SignUpLinkText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black,
        ),
        children: [
          const TextSpan(
            text: 'ليس لديك حساب؟ ',
          ),
          TextSpan(
            text: 'إنشاء حساب',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const RoleSelectionPage(),
                  ),
                );
              },
          ),
        ],
      ),
    );
  }
}