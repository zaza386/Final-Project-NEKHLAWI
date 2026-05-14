import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/widgets/custom_input.dart';
import 'terms_and_conditions_page.dart';
import 'login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isEditing = false;
  bool isLoading = true;

  String? avatarUrl;
  List<String> headerImages = [];

  final supabase = Supabase.instance.client;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final memberSinceCtrl = TextEditingController();
  final accountTypeCtrl = TextEditingController(text: 'مزارع');
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  // Validation error messages
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchHeaderImages();
    nameCtrl.addListener(_validateName);
    phoneCtrl.addListener(_validatePhone);
  }

  @override
  void dispose() {
    nameCtrl.removeListener(_validateName);
    phoneCtrl.removeListener(_validatePhone);
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    memberSinceCtrl.dispose();
    accountTypeCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Validators ──────────────────────────────

  void _validateName() {
    final value = nameCtrl.text.trim();
    setState(() {
      if (value.isEmpty) {
        _nameError = 'الاسم مطلوب';
      } else if (RegExp(r'[0-9]').hasMatch(value)) {
        _nameError = 'الاسم لا يجب أن يحتوي على أرقام';
      } else if (RegExp(r'[!@#\$%^&*()_+={}\[\]|\\:;"<>,.?/~`]')
          .hasMatch(value)) {
        _nameError = 'الاسم لا يجب أن يحتوي على رموز أو علامات خاصة';
      } else {
        _nameError = null;
      }
    });
  }

  void _validatePhone() {
    final value = phoneCtrl.text.trim();
    setState(() {
      if (value.isEmpty) {
        _phoneError = 'رقم الجوال مطلوب';
      } else if (!value.startsWith('05')) {
        _phoneError = 'رقم الجوال يجب أن يبدأ بـ 05';
      } else if (value.length != 10) {
        _phoneError = 'رقم الجوال يجب أن يتكون من 10 أرقام';
      } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        _phoneError = 'رقم الجوال يجب أن يحتوي على أرقام فقط';
      } else {
        _phoneError = null;
      }
    });
  }

  bool get _isFormValid =>
      _nameError == null &&
      _phoneError == null &&
      nameCtrl.text.trim().isNotEmpty &&
      phoneCtrl.text.trim().isNotEmpty;

  // ── Load user data from DB ──────────────────

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final userData = await supabase
          .from('User')
          .select('Name, Phone, Email, CreatedAt, ProfilePicturePath')
          .eq('UserID', userId)
          .maybeSingle();

      debugPrint('✅ userData: $userData');

      if (mounted) {
        setState(() {
          nameCtrl.text = userData?['Name'] ?? '';
          emailCtrl.text =
              userData?['Email'] ?? supabase.auth.currentUser?.email ?? '';
          phoneCtrl.text = userData?['Phone'] ?? '';
          avatarUrl = userData?['ProfilePicturePath'];

          final rawDate = userData?['CreatedAt'];
          if (rawDate != null) {
            final dt = DateTime.tryParse(rawDate.toString());
            if (dt != null) {
              memberSinceCtrl.text =
                  '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            }
          }
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _fetchHeaderImages() async {
    try {
      final response =
          await supabase.storage.from('pic').list(path: 'profile_headers');
      final urls = response.map((file) {
        return supabase.storage
            .from('pic')
            .getPublicUrl('profile_headers/${file.name}');
      }).toList();
      if (mounted) setState(() => headerImages = urls);
    } catch (e) {
      debugPrint('Error fetching header images: $e');
    }
  }

  // ── Save changes to DB ──────────────────────

  Future<void> _saveChanges() async {
    // Run validation before saving
    _validateName();
    _validatePhone();

    if (!_isFormValid) {
      final firstError = _nameError ?? _phoneError;
      if (firstError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(firstError),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('User').update({
        'Name': nameCtrl.text.trim(),
        'Phone': phoneCtrl.text.trim(),
      }).eq('UserID', userId);

      if (newPassCtrl.text.trim().isNotEmpty &&
          newPassCtrl.text == confirmPassCtrl.text) {
        await supabase.auth.updateUser(
          UserAttributes(password: newPassCtrl.text.trim()),
        );
        newPassCtrl.clear();
        confirmPassCtrl.clear();
      }

      if (mounted) {
        await _loadUserData();
        setState(() => isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ التعديلات بنجاح'),
            backgroundColor: Color(0xFF7B8646),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ حدث خطأ: $e')),
        );
      }
    }
  }

  // ── Change profile picture ──────────────────

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final bytes = await image.readAsBytes();
      final fileName = 'avatar_$userId.jpg';

      await supabase.storage.from('pic').uploadBinary(
        'avatars/$fileName',
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final url =
          supabase.storage.from('pic').getPublicUrl('avatars/$fileName');

      await supabase.from('User').update({
        'ProfilePicturePath': url,
      }).eq('UserID', userId);

      if (mounted) {
        setState(() => avatarUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تغيير الصورة بنجاح'),
            backgroundColor: Color(0xFF7B8646),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e')),
        );
      }
    }
  }

  // ── Support email ───────────────────────────

  Future<void> _launchSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@nekhlawi.com',
      queryParameters: {
        'subject': 'طلب دعم - تطبيق نخلاوي',
        'body': 'السلام عليكم،\n\nأحتاج مساعدة في:\n\n',
      },
    );
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'تعذّر فتح تطبيق البريد. يمكنك التواصل على: support@nekhlawi.com'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Navigation ──────────────────────────────

  void goHome() => Navigator.pop(context, true);

  Future<void> goLogin() async {
    // 1. إظهار نافذة التأكيد
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('تسجيل الخروج'),
          content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    // 2. التحقق مما إذا كان المستخدم اختار "نعم"
    if (shouldLogout != true) return;

    // 3. تنفيذ عملية تسجيل الخروج
    try {
      await supabase.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في تسجيل الخروج: $e')));
      }
    }

    if (!mounted) return;

    // 4. الانتقال لصفحة تسجيل الدخول
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  Future<void> confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد حذف الحساب'),
          content: const Text(
              'هل أنت متأكد من حذف الحساب؟ هذا الإجراء لا يمكن التراجع عنه.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        final userId = supabase.auth.currentUser!.id;
        await supabase.from('User').delete().eq('UserID', userId);
        await supabase.auth.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ── Build ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context, true);
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          body: isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary))
              : SafeArea(
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
                          onToggleEdit: () {
                            if (isEditing) {
                              _saveChanges();
                            } else {
                              setState(() => isEditing = true);
                            }
                          },
                          onChangeAvatar: _changeProfilePicture,
                          isEditing: isEditing,
                          avatarRadius: 58,
                          headerHeight:
                              MediaQuery.of(context).size.height * 0.30,
                        ),
                        const SizedBox(height: 16),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Name field ────────────────
                              CustomInput(
                                hint: 'الاسم',
                                icon: Icons.person_outline,
                                controller: nameCtrl,
                                enabled: isEditing,
                              ),
                              if (_nameError != null && isEditing)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 6, right: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.red, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        _nameError!,
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),

                              // ── Email (read-only) ─────────
                              CustomInput(
                                hint: 'الإيميل',
                                icon: Icons.email_outlined,
                                controller: emailCtrl,
                                enabled: false,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),

                              // ── Phone field ───────────────
                              CustomInput(
                                hint: 'رقم الجوال',
                                icon: Icons.phone_outlined,
                                controller: phoneCtrl,
                                enabled: isEditing,
                                keyboardType: TextInputType.phone,
                              ),
                              if (_phoneError != null && isEditing)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 6, right: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.red, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        _phoneError!,
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),

                              CustomInput(
                                hint: 'عضو منذ',
                                icon: Icons.calendar_month_outlined,
                                controller: memberSinceCtrl,
                                enabled: false,
                              ),
                              const SizedBox(height: 12),

                              CustomInput(
                                hint: 'نوع الحساب',
                                icon: Icons.badge_outlined,
                                controller: accountTypeCtrl,
                                enabled: false,
                              ),
                              const SizedBox(height: 12),

                              _NavTile(
                                title: 'الشروط والأحكام',
                                icon: Icons.description_outlined,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const TermsAndConditionsPage()),
                                ),
                              ),
                              const SizedBox(height: 12),

                              _SupportEmailTile(
                                  onTap: _launchSupportEmail),
                              const SizedBox(height: 16),

                              if (isEditing) ...[
                                const _SectionTitle(
                                    title: 'تعديل كلمة المرور'),
                                const SizedBox(height: 10),

                                CustomInput(
                                  hint: 'كلمة المرور الجديدة',
                                  icon: Icons.lock_outline,
                                  controller: newPassCtrl,
                                  isPassword: true,
                                  enabled: true,
                                  validateRules: true,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 10),

                                CustomInput(
                                  hint: 'تأكيد كلمة المرور',
                                  icon: Icons.lock_outline,
                                  controller: confirmPassCtrl,
                                  isPassword: true,
                                  matchWith: newPassCtrl,
                                  enabled: true,
                                  validateRules: false,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),

                                _DangerTile(
                                  title: 'حذف الحساب',
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      side: const BorderSide(
                                          color: Color(0xFFE9ECF3)),
                                    ),
                                  ),
                                  icon: const Icon(Icons.logout),
                                  label: const Text('تسجيل الخروج'),
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
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Header
// ══════════════════════════════════════════════

class _Header extends StatelessWidget {
  final List<String> headerImages;
  final String? avatarUrl;
  final String name;
  final String email;
  final VoidCallback onBack;
  final VoidCallback onToggleEdit;
  final VoidCallback onChangeAvatar;
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
    required this.onChangeAvatar,
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
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white),
                      ),
                    )
                  : PageView.builder(
                      itemCount: headerImages.length,
                      itemBuilder: (_, i) => Image.network(
                        headerImages[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.header,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: Colors.white, size: 42),
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
                _CircleIconButton(
                  icon: isEditing ? Icons.check : Icons.edit,
                  onTap: onToggleEdit,
                ),
              ],
            ),
          ),

          Positioned(
            top: headerHeight - avatarRadius,
            child: GestureDetector(
              onTap: isEditing ? onChangeAvatar : null,
              child: Stack(
                children: [
                  Container(
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
                      backgroundImage: avatarUrl == null
                          ? null
                          : NetworkImage(avatarUrl!),
                      child: avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 48, color: Color(0xFF8B95A5))
                          : null,
                    ),
                  ),
                  if (isEditing)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Positioned(
            top: headerHeight + avatarRadius + 10,
            child: Column(
              children: [
                Text(
                  name.isEmpty ? '—' : name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? '—' : email,
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

// ══════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════

class _NavTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _NavTile(
      {required this.title, required this.icon, required this.onTap});

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
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937))),
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
  const _DangerTile(
      {required this.title, required this.icon, required this.onTap});

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
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: Colors.red)),
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
  const _CircleIconButton({required this.icon, required this.onTap});

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
    path.quadraticBezierTo(
        size.width * 0.5, size.height, size.width, size.height - 70);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SupportEmailTile extends StatelessWidget {
  final VoidCallback onTap;
  const _SupportEmailTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4E8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.support_agent_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تواصل مع الدعم',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'support@nekhlawi.com',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left,
                color: AppColors.primary.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}