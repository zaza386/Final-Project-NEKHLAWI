import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:nekhlawi_app/pages/home_page.dart';
import 'package:nekhlawi_app/pages/forgot_password_page.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';
import 'role_selection_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

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




  bool get canProceed =>
      emailController.text.isNotEmpty &&
          isEmailValid &&
          passwordController.text.isNotEmpty &&
          isPasswordValid;



  Future<void> _signInWithFirebase(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
    on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'الحساب غير موجود';
          break;
        case 'wrong-password':
          message = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          message = 'صيغة البريد الإلكتروني غير صحيحة';
          break;
        case 'user-disabled':
          message = 'تم تعطيل هذا الحساب';
          break;
        case 'invalid-credential':
          message = 'بيانات الدخول غير صحيحة';
          break;
        default:
          message = e.message ?? 'حدث خطأ غير متوقع';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }


  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
              title: 'تسجيل دخول',
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
                                style: TextStyle(
                                  color: AppColors.darkBrown,
                                ),
                              ),

                              const SizedBox(height: 50),

                              /// البريد الإلكتروني
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

                              /// كلمة المرور
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

                              /// زر تسجيل الدخول
                              PrimaryButton(
                                title: 'تسجيل دخول',
                                onPressed: () {
                                  setState(() => submitted = true);

                                  if (!canProceed) return;

                                  _signInWithFirebase(context);
                                },
                              ),

                              const SizedBox(height: 16),

                              const Center(
                                child: SignUpLinkText(),
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
              style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 14,
              ),
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