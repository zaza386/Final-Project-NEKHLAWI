import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/primary_button.dart';
import 'complete_profile_page.dart';

class EmailConfirmationPage extends StatefulWidget {
  final String email;
  final String password;
  final String role;

  const EmailConfirmationPage({
    super.key,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  String statusMessage = 'تم إنشاء الحساب. افتح صندوق البريد واضغط على رابط التأكيد.';

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

  Future<void> _verifyEmailAndContinue() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      // 🔹 سجل دخول المستخدم
      final authResponse = await supabase.auth.signInWithPassword(
        email: widget.email,
        password: widget.password,
      );

      if (authResponse.session == null) {
        _showError('فشل تسجيل الدخول. تحقق من البيانات.');
        return;
      }

      final user = authResponse.user;
      if (user == null) {
        _showError('لم يتم العثور على المستخدم.');
        return;
      }

      // 🔹 تحقق من تأكيد البريد
      if (user.emailConfirmedAt == null) {
        _showError('البريد ما زال غير مؤكد. افتح رابط التأكيد في صندوق البريد ثم حاول مرة أخرى.');
        return;
      }

      if (!mounted) return;
      // 🔹 انتقل لصفحة استكمال البيانات
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteProfilePage(
            userId: user.id,
            email: widget.email,
            role: widget.role,
          ),
        ),
      );
    } catch (e) {
      _showError('❌ حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تأكيد البريد'),
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'لقد أرسلنا رابط تأكيد إلى:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                widget.email,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                statusMessage,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                title: isLoading ? 'جاري التحقق...' : 'لقد أكدت البريد، تابع',
                onPressed: _verifyEmailAndContinue,
              ),
              const SizedBox(height: 20),
              Text(
                'بعد الضغط على الرابط في البريد، اضغط زر "تابع" ليتم الانتقال لاستكمال بيانات حسابك.',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
