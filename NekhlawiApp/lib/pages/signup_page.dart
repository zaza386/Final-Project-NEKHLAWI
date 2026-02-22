import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/header_background.dart';
import 'terms_and_conditions_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  final String role; // user | expert

  const SignUpPage({
    super.key,
    required this.role,
  });

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool isAccepted = false;
  bool submitted = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final yearsController = TextEditingController();
  final specialtyController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isEmailValid = false;
  bool isPasswordValid = false;
  bool isConfirmPasswordValid = false;

  bool get isExpert => widget.role == 'expert';

  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

  bool get canProceed {
    bool fieldsFilled =
        nameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty;

    if (isExpert) {
      fieldsFilled = fieldsFilled &&
          yearsController.text.isNotEmpty &&
          specialtyController.text.isNotEmpty;
    }

    return fieldsFilled &&
        isEmailValid &&
        isPasswordValid &&
        isConfirmPasswordValid &&
        passwordsMatch &&
        isAccepted;
  }

Future<void> _signUpWithSupabase(BuildContext context) async {
  try {
    final response =
        await Supabase.instance.client.auth.signUp(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (response.user != null) {
      // نجاح إنشاء الحساب
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء الحساب بنجاح، سجّل دخولك الآن'),
        ),
      );
    }
  } on AuthException catch (e) {
    String message = 'حدث خطأ غير متوقع';

    final error = e.message.toLowerCase();

    if (error.contains('already')) {
      message = 'البريد الإلكتروني مستخدم مسبقًا';
    } else if (error.contains('email')) {
      message = 'صيغة البريد الإلكتروني غير صحيحة';
    } else if (error.contains('password')) {
      message = 'كلمة المرور ضعيفة';
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
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    yearsController.dispose();
    specialtyController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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

            HeaderBackground(
              title: isExpert ? 'حساب خبير' : 'حساب جديد',
              showBack: true,
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

                              /// الاسم
                              CustomInput(
                                hint: 'الاسم الكريم',
                                icon: Icons.person_outline,
                                controller: nameController,
                                showError: submitted,
                                onChanged: (_) => setState(() {}),
                              ),

                              const SizedBox(height: 16),

                              /// البريد الإلكتروني (فالديشن)
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

                              /// الجوال
                              CustomInput(
                                hint: 'رقم الجوال',
                                icon: Icons.phone_outlined,
                                controller: phoneController,
                                showError: submitted,
                                onChanged: (_) => setState(() {}),
                              ),

                              if (isExpert) ...[
                                const SizedBox(height: 16),
                                CustomInput(
                                  hint: 'سنوات الخبرة',
                                  icon: Icons.timeline_outlined,
                                  controller: yearsController,
                                  showError: submitted,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                CustomInput(
                                  hint: 'التخصص',
                                  icon: Icons.agriculture_outlined,
                                  controller: specialtyController,
                                  showError: submitted,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],

                              const SizedBox(height: 16),

                              /// كلمة المرور
                              CustomInput(
                                hint: 'كلمة المرور',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                controller: passwordController,
                                enabled: true,
                                validateRules: true,
                                onChanged: (_) => setState(() {}),
                              ),

                              const SizedBox(height: 16),

                              /// تأكيد كلمة المرور
                              CustomInput(
                                hint: 'تأكيد كلمة المرور',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                controller: confirmPasswordController,
                                matchWith: passwordController,
                                validateRules: false, 
                                enabled: true,
                                onChanged: (_) => setState(() {}),
                              ),

                              const SizedBox(height: 20),

                              /// الشروط
                              Row(
                                children: [
                                  Checkbox(
                                    value: isAccepted,
                                    activeColor: AppColors.primary,
                                    onChanged: (v) {
                                      setState(
                                          () => isAccepted = v ?? false);
                                    },
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'أوافق على ',
                                            style: TextStyle(
                                                color: AppColors.primary),
                                          ),
                                          TextSpan(
                                            text: 'الشروط والخصوصية',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const TermsAndConditionsPage(),
                                                      ),
                                                    );
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              /// زر إنشاء حساب
                              PrimaryButton(
                                title: 'إنشاء حساب',
                                onPressed: () {
                                  setState(() => submitted = true);
                                  if (!canProceed) return;

                                  _signUpWithSupabase(context);
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