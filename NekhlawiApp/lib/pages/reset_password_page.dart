import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/password_updated_page.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  bool submitted = false;
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

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

            // الهيدر (السهم على اليمين تلقائيًا مع RTL)
            const HeaderBackground(
              title: 'إعادة تعيين كلمة المرور',
              showBack: true,
            ),

            // المحتوى
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0, // 🔑 لتثبيت الحقوق
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
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'وصلنا لآخر خطوة، دخل كلمة مرور جديدة',
                                style: TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 30),

                              CustomInput(
                                hint: 'كلمة المرور',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                controller: passwordController,
                                showError: submitted,
                              ),

                              const SizedBox(height: 16),

                              CustomInput(
                                hint: 'تأكيد كلمة المرور',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                controller: confirmPasswordController,
                                showError: submitted || !passwordsMatch,
                              ),

                              const SizedBox(height: 15),

                              const Text(
                                'يجب أن تتكون كلمة المرور من 8 خانات و أن تحتوي على 5 أحرف على الأقل*\n'
                                'ورقم، وحرف كبير، ورمز',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 30),

                              PrimaryButton(
                                title: 'إعادة التعيين',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PasswordUpdatedPage(),
                                    ),
                                  );
                                },
                              ),

                              const Spacer(), // 🔥 يدفّ الحقوق تحت

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