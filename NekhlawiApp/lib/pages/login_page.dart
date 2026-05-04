import 'dart:async'; // ضروري للمستمع
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:nekhlawi_app/pages/wrapper.dart';
import 'package:nekhlawi_app/pages/role_selection_page.dart';
import 'package:nekhlawi_app/pages/forgot_password_page.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool submitted = false;
  bool isPasswordValid = false;
  bool isEmailValid = false;

  // 1. تعريف متغير المستمع لمراقبة حالة الدخول
  StreamSubscription<AuthState>? _authSubscription;

  bool get canProceed => emailController.text.isNotEmpty && isEmailValid;

  @override
  void initState() {
    super.initState();

    // 2. تفعيل المستمع: هذا الجزء هو المسؤول عن "لقط" الجلسة فور العودة من الرابط السحري
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        // إذا تم العثور على جلسة، ننتقل فوراً للـ Wrapper
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Wrapper()),
              (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    // 3. تنظيف المستمع عند إغلاق الصفحة
    _authSubscription?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  final supabase = Supabase.instance.client;

  Future<void> signInWithMagicLink(TextEditingController emailAddress) async {
    String emailAddress2 = emailAddress.text.trim();
    if (emailAddress2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال البريد الإلكتروني'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // تعديل الرابط ليتوافق مع الـ Host في المانيفست
      await supabase.auth.signInWithOtp(
        email: emailAddress2,
        shouldCreateUser: false,
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال الرابط السحري إلى بريدك!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signInWithPassword() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال البريد الإلكتروني وكلمة المرور'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => submitted = true);

    if (!isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال بريد إلكتروني صحيح'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الدخول بنجاح!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Wrapper()),
              (route) => false,
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ غير متوقع: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => submitted = false);
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
            const HeaderBackground(title: 'تسجيل دخول'),
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
                                  color: AppColors.darkBrown,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'سجل دخولك وخلك قريب من نخلك',
                                style: TextStyle(color: AppColors.darkBrown),
                              ),
                              const SizedBox(height: 50),

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

                              const SizedBox(height: 16),

                              CustomInput(
                                hint: 'كلمة المرور',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                controller: passwordController,
                                showError: submitted,
                                onValidationChanged: (v) {
                                  setState(() => isPasswordValid = v);
                                },
                                onChanged: (_) => setState(() {}),
                              ),

                              const SizedBox(height: 12),
                              const ForgotPasswordButton(),

                              const SizedBox(height: 30),

                              PrimaryButton(
                                title: 'تسجيل دخول',
                                onPressed: _signInWithPassword,
                              ),

                              const SizedBox(height: 12),

                              // PrimaryButton(
                              //   title: 'تسجيل الدخول باستخدام البريد',
                              //   onPressed: () => signInWithMagicLink(emailController),
                              // ),
                              // const SizedBox(height: 16),
                              // const Center(child: SignUpLinkText()),

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



/// باقي الكلاسات بدون تغيير
class SignUpLinkText extends StatefulWidget {
  const SignUpLinkText({super.key});

  @override
  State<SignUpLinkText> createState() => _SignUpLinkTextState();
}

class _SignUpLinkTextState extends State<SignUpLinkText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: RichText(
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'لا أملك حساب، ',
              style: TextStyle(color: AppColors.darkBrown, fontSize: 14),
            ),
            TextSpan(
              text: 'إنشاء حساب جديد',
              style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: _isHovered
                    ? TextDecoration.underline
                    : TextDecoration.none,
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
    );
  }
}

class ForgotPasswordButton extends StatelessWidget {
  const ForgotPasswordButton({super.key});

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