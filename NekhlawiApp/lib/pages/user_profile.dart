import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/widgets/custom_input.dart';
import 'terms_and_conditions_page.dart';
import 'login_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isEditing = false;

  String? avatarUrl;

  List<String> headerImages = [];

  final nameCtrl = TextEditingController(text: "هاشم");
  final emailCtrl = TextEditingController(text: "hashim@example.com");
  final phoneCtrl = TextEditingController(text: "05xxxxxxxx");
  final memberSinceCtrl = TextEditingController(text: "2025-09-01");
  final accountTypeCtrl = TextEditingController(text: "مستخدم");

  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchHeaderImages();
  }

  Future<void> fetchHeaderImages() async {
    final client = Supabase.instance.client;

    final response = await client.storage.from('pic').list(path: 'profile_headers');

    final urls = response.map((file) {
      return client.storage.from('pic').getPublicUrl('profile_headers/${file.name}');
    }).toList();

    setState(() => headerImages = urls);

    // debug
    // ignore: avoid_print
    print(response);
    // ignore: avoid_print
    print(urls);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    memberSinceCtrl.dispose();
    accountTypeCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  void goHome() => Navigator.pop(context);

  void goTerms() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()));
  }

  Future<void> goLogin() async {
    // إنهاء الـ session
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تسجيل الخروج: $e')),
        );
      }
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("تأكيد حذف الحساب"),
            content: const Text("هل أنت متأكد من حذف الحساب؟ هذا الإجراء لا يمكن التراجع عنه."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("إلغاء")),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("حذف"),
              ),
            ],
          ),
        );
      },
    );

    if (ok == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم اختيار حذف الحساب (غير مربوط حالياً).")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                _Header(
                  headerImages: headerImages,
                  avatarUrl: avatarUrl,
                  name: nameCtrl.text,
                  email: emailCtrl.text,
                  onBack: goHome,
                  onToggleEdit: () => setState(() => isEditing = !isEditing),
                  isEditing: isEditing,
                  avatarRadius: 58,
                  headerHeight: MediaQuery.of(context).size.height * 0.30,
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      CustomInput(
                        hint: "الاسم",
                        icon: Icons.person_outline,
                        controller: nameCtrl,
                        enabled: isEditing,
                      ),
                      const SizedBox(height: 12),

                      CustomInput(
                        hint: "الإيميل",
                        icon: Icons.email_outlined,
                        controller: emailCtrl,
                        enabled: isEditing,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      CustomInput(
                        hint: "رقم التلفون",
                        icon: Icons.phone_outlined,
                        controller: phoneCtrl,
                        enabled: isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      CustomInput(
                        hint: "عضو منذ",
                        icon: Icons.calendar_month_outlined,
                        controller: memberSinceCtrl,
                        enabled: false,
                      ),
                      const SizedBox(height: 12),

                      CustomInput(
                        hint: "نوع الحساب",
                        icon: Icons.badge_outlined,
                        controller: accountTypeCtrl,
                        enabled: false,
                      ),
                      const SizedBox(height: 12),

                      _NavTile(
                        title: "الشروط والأحكام",
                        icon: Icons.description_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      if (isEditing) ...[
                        const _SectionTitle(title: "تعديل كلمة المرور"),
                        const SizedBox(height: 10),

                        CustomInput(
                          hint: "كلمة المرور الجديدة",
                          icon: Icons.lock_outline,
                          controller: newPassCtrl,
                          isPassword: true,
                          enabled: true,
                          validateRules: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),

                        CustomInput(
                          hint: "تأكيد كلمة المرور",
                          icon: Icons.lock_outline,
                          controller: confirmPassCtrl,
                          isPassword: true,
                          matchWith: newPassCtrl, // ✅ هنا التطابق
                          enabled: true,
                          validateRules: false,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        _DangerTile(
                          title: "حذف الحساب",
                          icon: Icons.delete_outline,
                          onTap: confirmDeleteAccount,
                        ),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: goLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFE9ECF3)),
                            ),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text("تسجيل الخروج"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =================== WIDGETS ===================

class _Header extends StatelessWidget {
  final List<String> headerImages;
  final String? avatarUrl;
  final String name;
  final String email;
  final VoidCallback onBack;
  final VoidCallback onToggleEdit;
  final bool isEditing;

  final double avatarRadius;
  final double headerHeight;

  const _Header({
    required this.headerImages,
    required this.avatarUrl,
    required this.name,
    required this.email,
    required this.onBack,
    required this.onToggleEdit,
    required this.isEditing,
    required this.avatarRadius,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context) {
    final avatarDiameter = avatarRadius * 2;

    return SizedBox(
      height: headerHeight + avatarRadius + 60,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ClipPath(
            clipper: _CurvedHeaderClipper(),
            child: SizedBox(
              height: headerHeight,
              width: double.infinity,
              child: headerImages.isEmpty
                  ? Container(
                      color: AppColors.header,
                      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                    )
                  : PageView.builder(
                      itemCount: headerImages.length,
                      itemBuilder: (_, i) => Image.network(
                        headerImages[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.header,
                          child: const Center(
                            child: Icon(Icons.image_outlined, color: Colors.white, size: 42),
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          Positioned(
            top: 6,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
                _CircleIconButton(icon: isEditing ? Icons.check : Icons.edit, onTap: onToggleEdit),
              ],
            ),
          ),

          Positioned(
            top: headerHeight - avatarRadius,
            child: Container(
              width: avatarDiameter,
              height: avatarDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    color: Colors.black.withOpacity(0.12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFEFF2F8),
                backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 48, color: Color(0xFF8B95A5))
                    : null,
              ),
            ),
          ),

          Positioned(
            top: headerHeight + avatarRadius + 10,
            child: Column(
              children: [
                Text(
                  name.isEmpty ? "—" : name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? "—" : email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _NavTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9ECF3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
              ),
            ),
            const Icon(Icons.chevron_left, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DangerTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD4D4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red),
              ),
            ),
            const Icon(Icons.chevron_left, color: Colors.red),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1F2937)),
      ),
    );
  }
}

class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 70);
    path.quadraticBezierTo(size.width * 0.5, size.height, size.width, size.height - 70);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
