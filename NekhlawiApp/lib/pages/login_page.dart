import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
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
  bool isEmailValid = false;
  bool isLoading = false; // لإظهار مؤشر تحميل عند الضغط

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  final supabase = Supabase.instance.client;

  // 🪄 دالة الرابط السحري: الحل الأساسي لتسجيل الدخول في "نخلاتي"
  Future<void> signInWithMagicLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال بريد إلكتروني صحيح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // لا نريد إنشاء حساب جديد من هنا، فقط تسجيل دخول
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال رابط الدخول السريع إلى بريدك!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
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
            const HeaderBackground(title: 'تسجيل دخول'),
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
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
                        'أدخل بريدك ليصلك رابط دخول مباشر وسريع',
                        style: TextStyle(color: AppColors.darkBrown),
                      ),
                      const SizedBox(height: 50),

                      /// البريد الإلكتروني
                      CustomInput(
                        hint: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        controller: emailController,
                        showError: submitted,
                        onValidationChanged: (v) => setState(() => isEmailValid = v),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 30),

                      /// زر تسجيل الدخول السحري
                      PrimaryButton(
                        title: isLoading ? 'جاري إرسال الرابط...' : 'تسجيل دخول سريع 🪄',
                        onPressed: signInWithMagicLink,
                      ),

                      const SizedBox(height: 24),
                      const Center(child: SignUpLinkText()),

                      const SizedBox(height: 100), // مساحة إضافية للتمرير

                      const Center(
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
          ],
        ),
      ),
    );
  }
}

// الكلاسات المساعدة كما هي
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
        text: TextSpan(
          children: [
            const TextSpan(text: 'لا أملك حساب، ', style: TextStyle(color: AppColors.darkBrown, fontSize: 14)),
            TextSpan(
              text: 'إنشاء حساب جديد',
              style: TextStyle(
                color: AppColors.darkBrown, fontSize: 14, fontWeight: FontWeight.w600,
                decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RoleSelectionPage())),
            ),
          ],
        ),
      ),
    );
  }
}