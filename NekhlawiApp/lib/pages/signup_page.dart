import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  bool get isExpert => widget.role == 'expert';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(color: Colors.white),

            /// الهيدر
            HeaderBackground(
              title: isExpert ? 'حساب خبير' : 'حساب جديد',
              showBack: true,
            ),

            /// المحتوى
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
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

                      /// العنوان
                      Text(
                        isExpert
                            ? 'مرحبًا خبيرنا 🌴'
                            : 'يا هلا فيك بنخلاوي 🌴',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        isExpert
                            ? 'أنشئ حسابك وشارك خبرتك مع مزارعي النخل'
                            : 'أنشئ حسابك وخلك قريب من نخلك',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 40),

                      const CustomInput(
                        hint: 'الاسم الكريم',
                        icon: Icons.person_outline,
                      ),

                      const SizedBox(height: 16),

                      const CustomInput(
                        hint: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                      ),

                      const SizedBox(height: 16),

                      const CustomInput(
                        hint: 'رقم الجوال',
                        icon: Icons.phone_outlined,
                      ),

                      if (isExpert) ...[
                        const SizedBox(height: 16),
                        const CustomInput(
                          hint: 'سنوات الخبرة',
                          icon: Icons.timeline_outlined,
                        ),
                        const SizedBox(height: 16),
                        const CustomInput(
                          hint: 'التخصص (نخيل، آفات، ري...)',
                          icon: Icons.agriculture_outlined,
                        ),
                      ],

                      const SizedBox(height: 16),

                      const CustomInput(
                        hint: 'كلمة المرور',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 16),

                      const CustomInput(
                        hint: 'تأكيد كلمة المرور',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        '*يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل، رقم، وحرف كبير ورمز.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const SizedBox(height: 40),

                      /// ✅ المربع + الشروط
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: isAccepted,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                isAccepted = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: RichText(
                              textDirection: TextDirection.rtl,
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text:
                                        'بتسجيلك في التطبيق، أنت توافق على ',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'الشروط والخصوصية',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const TermsAndConditionsPage(),
                                          ),
                                        );
                                      },
                                  ),
                                  const TextSpan(
                                    text:
                                        ' الخاصة بتطبيق نخلاوي.',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      /// زر إنشاء الحساب (يتفعل فقط عند الموافقة)
                      PrimaryButton(
                        title: 'إنشاء حساب',
                        onPressed: () {
                          if (!isAccepted) return;
                          // TODO: Firebase SignUp
                        },
                      ),

                      const SizedBox(height: 30),

                      const Center(
                        child: Text(
                          '©️ 2025 - 2026',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),

                      const SizedBox(height: 20),
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