import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/header_background.dart';

class SignUpPage extends StatelessWidget {
  final String role; // user | expert

  const SignUpPage({
    super.key,
    required this.role,
  });

  bool get isExpert => role == 'expert';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // الخلفية
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

                      /// الاسم
                      const CustomInput(
                        hint: 'الاسم الكريم',
                        icon: Icons.person_outline,
                      ),

                      const SizedBox(height: 16),

                      /// الإيميل
                      const CustomInput(
                        hint: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                      ),

                      const SizedBox(height: 16),

                      /// الجوال
                      const CustomInput(
                        hint: 'رقم الجوال',
                        icon: Icons.phone_outlined,
                      ),

                      /// حقول إضافية للخبير فقط
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

                      /// كلمة المرور
                      const CustomInput(
                        hint: 'كلمة المرور',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 16),

                      /// تأكيد كلمة المرور
                      const CustomInput(
                        hint: 'تأكيد كلمة المرور',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 20),

                      /// ملاحظة كلمة المرور
                      const Text(
                        '*يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل، رقم، وحرف كبير ورمز.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 40),

                      /// زر إنشاء الحساب
                      PrimaryButton(
                        title: 'إنشاء حساب',
                        onPressed: () {
                          // TODO: Firebase SignUp
                        },
                      ),

                      const SizedBox(height: 30),

                      /// الحقوق
                      const Center(
                        child: Text(
                          '© 2025 - 2026',
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