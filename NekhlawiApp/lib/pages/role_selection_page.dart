import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_application_1/pages/role_card.dart';
import '../core/theme/app_colors.dart';
import 'signup_page.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String selectedRole = 'user'; // user | expert

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                /// العنوان
                const Text(
                  'إختر نوع حسابك',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),

                const SizedBox(height: 8),

                /// الوصف
                const Text(
                  'علشان نعرف شلون نخدمك، حدّد إذا كنت مستخدم عادي ولا خبير نخل.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 40),

                /// كرت مستخدم عادي
                RoleCard(
                  title: 'مستخدم عادي',
                  subtitle: 'للمزارعين والمهتمين بالعناية بالنخل',
                  icon: Icons.person_outline,
                  isSelected: selectedRole == 'user',
                  onTap: () {
                    setState(() {
                      selectedRole = 'user';
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// كرت خبير نخل
                RoleCard(
                  title: 'خبير نخل',
                  subtitle: 'لأهل الخبرة، شخص مختص يقدم نصيحة',
                  icon: Icons.psychology_outlined,
                  isSelected: selectedRole == 'expert',
                  onTap: () {
                    setState(() {
                      selectedRole = 'expert';
                    });
                  },
                ),

                const Spacer(),

                /// زر المتابعة
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SignUpPage(role: selectedRole),
                        ),
                      );
                    },
                    child: const Text(
                      'متابعة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// تسجيل الدخول
                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'هل لديك حساب؟ ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextSpan(
                          text: 'سجل دخول',
                          style: const TextStyle(
                            color: AppColors.darkBrown,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const LoginPage(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}