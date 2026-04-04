import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/custom_input.dart';
import '../core/widgets/primary_button.dart';
import 'home_page.dart';

class CompleteProfilePage extends StatefulWidget {
  final String userId;
  final String email;
  final String role;

  const CompleteProfilePage({
    super.key,
    required this.userId,
    required this.email,
    required this.role,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  bool submitted = false;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final yearsController = TextEditingController();
  final specialtyController = TextEditingController();

  bool get isExpert => widget.role == 'expert';

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    yearsController.dispose();
    specialtyController.dispose();
    super.dispose();
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

  List<String> _missingFields() {
    final missing = <String>[];
    if (nameController.text.trim().isEmpty) missing.add('الاسم');
    if (phoneController.text.trim().isEmpty) missing.add('رقم الجوال');
    if (isExpert && yearsController.text.trim().isEmpty) missing.add('سنوات الخبرة');
    if (isExpert && specialtyController.text.trim().isEmpty) missing.add('التخصص');
    return missing;
  }

  Future<void> _saveProfileData() async {
    if (isLoading) return;
    setState(() => submitted = true);

    final missing = _missingFields();
    if (missing.isNotEmpty) {
      _showError('الحقول مطلوبة: ${missing.join(', ')}');
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔹 إدراج بيانات المستخدم في جدول User
      await supabase.from('User').insert({
        'UserID': widget.userId,
        'Name': nameController.text.trim(),
        'Email': widget.email,
        'Phone': phoneController.text.trim(),
        'Role': widget.role,
      });

      // 🔹 إذا كان خبير، أدرج البيانات الإضافية
      if (isExpert) {
        await supabase.from('ExpertProfile').insert({
          'ExpertID': widget.userId,
          'Specialization': specialtyController.text.trim(),
          'ExperienceYears': int.tryParse(yearsController.text.trim()) ?? 0,
          'Bio': '',
          'RatingAvg': 0,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ بيانات حسابك بنجاح!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // توجيه للهوم
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
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
          title: const Text('استكمال البيانات'),
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'استكمل بيانات حسابك',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomInput(
                  hint: 'الاسم الكريم',
                  icon: Icons.person_outline,
                  controller: nameController,
                  showError: submitted,
                ),
                const SizedBox(height: 16),
                CustomInput(
                  hint: 'رقم الجوال',
                  icon: Icons.phone_outlined,
                  controller: phoneController,
                  showError: submitted,
                ),
                if (isExpert) ...[
                  const SizedBox(height: 16),
                  CustomInput(
                    hint: 'سنوات الخبرة',
                    icon: Icons.timeline_outlined,
                    controller: yearsController,
                    showError: submitted,
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    hint: 'التخصص',
                    icon: Icons.agriculture_outlined,
                    controller: specialtyController,
                    showError: submitted,
                  ),
                ],
                const SizedBox(height: 40),
                PrimaryButton(
                  title: isLoading ? 'جاري الحفظ...' : 'استكمال',
                  onPressed: _saveProfileData,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
