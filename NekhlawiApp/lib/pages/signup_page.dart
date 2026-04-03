import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/header_background.dart';
import 'terms_and_conditions_page.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  final String role;

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
  bool isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final yearsController = TextEditingController();
  final specialtyController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isEmailValid = false;

  bool get isExpert => widget.role == 'expert';
  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

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

  List<String> _missingFields() {
    final missing = <String>[];
    if (nameController.text.trim().isEmpty) missing.add('الاسم');
    if (emailController.text.trim().isEmpty) missing.add('البريد الإلكتروني');
    if (phoneController.text.trim().isEmpty) missing.add('رقم الجوال');
    // في الـ Magic Link لا نحتاج للتحقق من الباسوورد، لكن سأبقيها للـ Sign Up العادي
    return missing;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  final supabase = Supabase.instance.client;

  // 🔹 تطبيق "فكرة هبة": إنشاء الحساب وحفظ البيانات في الـ Metadata 🔹
  Future<void> signUpWithMagicLink(TextEditingController emailAddress) async {
    final email = emailAddress.text.trim();

    if (email.isEmpty) {
      _showError('الرجاء إدخال البريد الإلكتروني أولاً');
      return;
    }

    // التحقق من الحقول الأساسية لضمان حفظها
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      _showError('الرجاء إكمال الاسم ورقم الجوال قبل إرسال الرابط');
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
        emailRedirectTo: 'io.supabase.flutter://signup-callback/',
        // 👈 هنا بنحط بياناتك عشان ترجع لنا لما يفتح الإيميل
        data: {
          'full_name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'role': widget.role,
          if (isExpert) 'specialization': specialtyController.text.trim(),
          if (isExpert) 'experience_years': yearsController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال رابط التفعيل! افتح بريدك لتسجيل الدخول مباشرة'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (error) {
      _showError('❌ حدث خطأ: $error');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signUpWithSupabase() async {
    if (isLoading) return;
    setState(() => submitted = true);

    final missing = _missingFields();
    if (missing.isNotEmpty || !isEmailValid || !passwordsMatch || !isAccepted) {
      if (missing.isNotEmpty) _showError('الحقول مطلوبة: ${missing.join(', ')}');
      else if (!isEmailValid) _showError('البريد غير صحيح');
      else if (!passwordsMatch) _showError('الباسوورد غير متطابق');
      else _showError('يجب الموافقة على الشروط');
      return;
    }

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final res = await supabase.auth.signUp(email: email, password: password);
      final user = res.user;

      if (user != null) {
        await supabase.from('User').insert({
          'UserID': user.id,
          'Name': nameController.text.trim(),
          'Email': email,
          'Phone': phoneController.text.trim(),
          'Role': widget.role,
        });

        if (isExpert) {
          await supabase.from('ExpertProfile').insert({
            'ExpertID': user.id,
            'Specialization': specialtyController.text.trim(),
            'ExperienceYears': int.tryParse(yearsController.text.trim()) ?? 0,
            'Bio': '',
            'RatingAvg': 0,
          });
        }

        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } catch (e) {
      _showError('Error: $e');
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
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Container(color: Colors.white),
            HeaderBackground(title: isExpert ? 'حساب خبير' : 'حساب جديد', showBack: true),
            Positioned(
              top: 140, left: 0, right: 0, bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        CustomInput(hint: 'الاسم الكريم', icon: Icons.person_outline, controller: nameController, showError: submitted),
                        const SizedBox(height: 16),
                        CustomInput(hint: 'البريد الإلكتروني', icon: Icons.email_outlined, controller: emailController, showError: submitted, onValidationChanged: (v) => setState(() => isEmailValid = v)),
                        const SizedBox(height: 16),
                        CustomInput(hint: 'رقم الجوال', icon: Icons.phone_outlined, controller: phoneController, showError: submitted),
                        if (isExpert) ...[
                          const SizedBox(height: 16),
                          CustomInput(hint: 'سنوات الخبرة', icon: Icons.timeline_outlined, controller: yearsController, showError: submitted),
                          const SizedBox(height: 16),
                          CustomInput(hint: 'التخصص', icon: Icons.agriculture_outlined, controller: specialtyController, showError: submitted),
                        ],
                        const SizedBox(height: 16),
                        CustomInput(hint: 'كلمة المرور', icon: Icons.lock_outline, isPassword: true, controller: passwordController),
                        const SizedBox(height: 16),
                        CustomInput(hint: 'تأكيد كلمة المرور', icon: Icons.lock_outline, isPassword: true, controller: confirmPasswordController, matchWith: passwordController),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Checkbox(value: isAccepted, activeColor: AppColors.primary, onChanged: (v) => setState(() => isAccepted = v ?? false)),
                            Expanded(child: RichText(text: TextSpan(children: [
                              const TextSpan(text: 'أوافق على ', style: TextStyle(color: AppColors.primary, fontFamily: 'Tajawal')),
                              TextSpan(text: 'الشروط والخصوصية', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()))),
                            ]))),
                          ],
                        ),
                        const SizedBox(height: 30),
                        PrimaryButton(
                          title: isLoading ? 'جاري العمل...' : 'إنشاء حساب (باسوورد)',
                          onPressed: _signUpWithSupabase,
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          title: 'إنشاء حساب بالرابط السحري 🪄',
                          onPressed: () => signUpWithMagicLink(emailController),
                        ),
                        const SizedBox(height: 40),
                        const Center(child: Text('©️ 2025 - 2026', style: TextStyle(color: Colors.grey))),
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