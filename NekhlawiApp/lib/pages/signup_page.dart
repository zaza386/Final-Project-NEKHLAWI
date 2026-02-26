import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/header_background.dart';
import 'terms_and_conditions_page.dart';

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

  // ✅ فقط نتحقق من الحقول المطلوبة (وإيميل صحيح + مطابقة كلمة المرور + الشروط)
  List<String> _missingFields() {
    final missing = <String>[];

    if (nameController.text.trim().isEmpty) missing.add('الاسم');
    if (emailController.text.trim().isEmpty) missing.add('البريد الإلكتروني');
    if (phoneController.text.trim().isEmpty) missing.add('رقم الجوال');
    if (passwordController.text.isEmpty) missing.add('كلمة المرور');
    if (confirmPasswordController.text.isEmpty) missing.add('تأكيد كلمة المرور');

    if (isExpert) {
      if (yearsController.text.trim().isEmpty) missing.add('سنوات الخبرة');
      if (specialtyController.text.trim().isEmpty) missing.add('التخصص');
    }

    return missing;
  }

  void _showMissingFieldsMessage(List<String> missing) {
    final msg = 'الحقول التالية مطلوبة:\n- ${missing.join('\n- ')}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
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

Future<void> _signUpWithSupabase() async {
  if (isLoading) return;

  setState(() => submitted = true);

  final missing = _missingFields();
  if (missing.isNotEmpty) {
    _showMissingFieldsMessage(missing);
    return;
  }

  if (!isEmailValid) {
    _showError('البريد الإلكتروني غير صحيح');
    return;
  }

  if (!passwordsMatch) {
    _showError('كلمة المرور وتأكيد كلمة المرور غير متطابقين');
    return;
  }

  if (!isAccepted) {
    _showError('لازم توافق على الشروط والخصوصية');
    return;
  }

  int? years;
  if (isExpert) {
    years = int.tryParse(yearsController.text.trim());
    if (years == null) {
      _showError('سنوات الخبرة لازم تكون رقم');
      return;
    }
  }

  setState(() => isLoading = true);

  try {
    final supabase = Supabase.instance.client;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final res = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) throw const AuthException('لم يتم إنشاء المستخدم.');

    final userId = user.id;

    // ✅ بما إن عندك Trigger: الصف في جدول User انخلق تلقائي
    // ✅ إذًا هنا نسوي UPDATE فقط ونعبّي باقي الحقول
    await supabase.from('User').update({
      'Name': nameController.text.trim(),
      'Email': email,
      'Phone': phoneController.text.trim(),
      'Role': widget.role,
      // 'ProfilePicturePath': null, // إذا تبين تتركينه مثل ما هو في التريغر
      // لا نحدّث CreatedAt عادة
    }).eq('UserID', userId);

    // ✅ إذا خبير: ندخل بياناته في ExpertProfile
    if (isExpert) {
      await supabase.from('ExpertProfile').insert({
        'ExpertID': userId,
        'Specialization': specialtyController.text.trim(),
        'ExperienceYears': years,
        'Bio': '',
        'RatingAvg': 0,
      });
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إنشاء الحساب بنجاح، سجّل دخولك الآن')),
    );
  } on AuthException catch (e) {
    _showError(e.message);
  } on PostgrestException catch (e) {
    _showError('Database error: ${e.message}');
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
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
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

                              // الاسم
                              CustomInput(
                                hint: 'الاسم الكريم',
                                icon: Icons.person_outline,
                                controller: nameController,
                                showError: submitted,
                                onChanged: (_) => setState(() {}),
                              ),

                              const SizedBox(height: 16),

                              // البريد الإلكتروني (فالديشن داخل CustomInput)
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

                              // الجوال
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

                              // كلمة المرور (فالديشن داخل CustomInput)
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

                              // تأكيد كلمة المرور
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

                              // الشروط
                              Row(
                                children: [
                                  Checkbox(
                                    value: isAccepted,
                                    activeColor: AppColors.primary,
                                    onChanged: (v) {
                                      setState(() => isAccepted = v ?? false);
                                    },
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'أوافق على ',
                                            style: TextStyle(color: AppColors.primary),
                                          ),
                                          TextSpan(
                                            text: 'الشروط والخصوصية',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const TermsAndConditionsPage(),
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

                              // زر إنشاء حساب
                              PrimaryButton(
                                title: isLoading ? 'جاري إنشاء الحساب...' : 'إنشاء حساب',
                                onPressed: () {
                                  if (!isLoading) {
                                    _signUpWithSupabase();
                                  }
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