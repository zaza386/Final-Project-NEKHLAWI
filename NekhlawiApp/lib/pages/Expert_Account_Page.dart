import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/widgets/custom_input.dart';
import 'terms_and_conditions_page.dart';
import 'login_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpertAccountPage extends StatefulWidget {
  const ExpertAccountPage({super.key});

  @override
  State<ExpertAccountPage> createState() => _ExpertAccountPageState();
}

class _ExpertAccountPageState extends State<ExpertAccountPage> {
  bool isEditing = false;
  bool isLoading = true;

  String? avatarUrl;
  List<String> headerImages = [];

  // ── Basic info controllers ──────────────────
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final memberSinceCtrl = TextEditingController();

  // ── Expert-only controllers ─────────────────
  final specializationCtrl = TextEditingController();
  final experienceYearsCtrl = TextEditingController();
  final bioCtrl = TextEditingController();

  // ── Password controllers ────────────────────
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  // ── Rating (read-only) ──────────────────────
  double ratingAvg = 0.0;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadExpertData();
    _fetchHeaderImages();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    memberSinceCtrl.dispose();
    specializationCtrl.dispose();
    experienceYearsCtrl.dispose();
    bioCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchSupportEmail() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'support@nekhlawi.com',
    queryParameters: {
      'subject': 'طلب دعم - تطبيق نخلاوي',
      'body': 'السلام عليكم،\n\nأحتاج مساعدة في:\n\n',
    },
  );

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح تطبيق البريد. يمكنك التواصل على: support@nekhlawi.com'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

  // ── Load all expert data from DB ────────────

Future<void> _loadExpertData() async {
  setState(() => isLoading = true);
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ No user logged in');
      setState(() => isLoading = false);
      return;
    }

    debugPrint('✅ Fetching data for user: $userId');

    final userData = await supabase
        .from('User')
        .select('Name, Phone, Email, CreatedAt')
        .eq('UserID', userId)
        .maybeSingle();

    debugPrint('✅ userData: $userData');

    final expertData = await supabase
        .from('ExpertProfile')
        .select('Specialization, ExperienceYears, Bio, RatingAvg')
        .eq('ExpertID', userId)
        .maybeSingle();

    debugPrint('✅ expertData: $expertData');

    if (mounted) {
      setState(() {
        nameCtrl.text = userData?['Name'] ?? '';
        emailCtrl.text =
            userData?['Email'] ?? supabase.auth.currentUser?.email ?? '';
        phoneCtrl.text = userData?['Phone'] ?? '';

        final rawDate = userData?['CreatedAt'];
        if (rawDate != null) {
          final dt = DateTime.tryParse(rawDate.toString());
          if (dt != null) {
            memberSinceCtrl.text =
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          }
        }

        specializationCtrl.text = expertData?['Specialization'] ?? '';
        experienceYearsCtrl.text =
            (expertData?['ExperienceYears'] ?? 0).toString();
        bioCtrl.text = expertData?['Bio'] ?? '';
        ratingAvg = (expertData?['RatingAvg'] ?? 0.0).toDouble();
        isLoading = false;
      });
    }
  } catch (e) {
    debugPrint('❌ Error loading expert data: $e');
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

  // ── Save all changes to DB ──────────────────

  Future<void> _saveChanges() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('User').update({
        'Name': nameCtrl.text.trim(),
        'Phone': phoneCtrl.text.trim(),
      }).eq('UserID', userId);

      await supabase.from('ExpertProfile').update({
        'Specialization': specializationCtrl.text.trim(),
        'ExperienceYears': int.tryParse(experienceYearsCtrl.text.trim()) ?? 0,
        'Bio': bioCtrl.text.trim(),
      }).eq('ExpertID', userId);

      if (newPassCtrl.text.trim().isNotEmpty &&
          newPassCtrl.text == confirmPassCtrl.text) {
        await supabase.auth.updateUser(
          UserAttributes(password: newPassCtrl.text.trim()),
        );
        newPassCtrl.clear();
        confirmPassCtrl.clear();
      }

      if (mounted) {
  await _loadExpertData(); 
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

  // ── Navigation ──────────────────────────────

  void goHome() => Navigator.pop(context, true);

  Future<void> goLogout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد حذف الحساب'),
          content: const Text(
              'هل أنت متأكد من حذف حسابك كخبير؟ هذا الإجراء لا يمكن التراجع عنه.'),
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
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم اختيار حذف الحساب (غير مربوط حالياً).')),
      );
    }
  }

  // ── Build ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          Navigator.pop(context, true);
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      _ExpertHeader(
                        headerImages: headerImages,
                        avatarUrl: avatarUrl,
                        name: nameCtrl.text,
                        specialization: specializationCtrl.text,
                        onBack: goHome,
                        isEditing: isEditing,
                        onToggleEdit: () {
                          if (isEditing) {
                            _saveChanges();
                          } else {
                            setState(() => isEditing = true);
                          }
                        },
                        headerHeight:
                            MediaQuery.of(context).size.height * 0.30,
                      ),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _SectionLabel(label: 'المعلومات الشخصية'),
                            const SizedBox(height: 10),

                            CustomInput(
                              hint: 'الاسم',
                              icon: Icons.person_outline,
                              controller: nameCtrl,
                              enabled: isEditing,
                            ),
                            const SizedBox(height: 12),

                            CustomInput(
                              hint: 'الإيميل',
                              icon: Icons.email_outlined,
                              controller: emailCtrl,
                              enabled: false,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),

                            CustomInput(
                              hint: 'رقم الجوال',
                              icon: Icons.phone_outlined,
                              controller: phoneCtrl,
                              enabled: isEditing,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),

                            CustomInput(
                              hint: 'عضو منذ',
                              icon: Icons.calendar_month_outlined,
                              controller: memberSinceCtrl,
                              enabled: false,
                            ),

                            const SizedBox(height: 24),

                            _SectionLabel(label: 'معلومات الخبير'),
                            const SizedBox(height: 10),

                            CustomInput(
                              hint: 'التخصص',
                              icon: Icons.agriculture_outlined,
                              controller: specializationCtrl,
                              enabled: isEditing,
                            ),
                            const SizedBox(height: 12),

                            CustomInput(
                              hint: 'سنوات الخبرة',
                              icon: Icons.timeline_outlined,
                              controller: experienceYearsCtrl,
                              enabled: isEditing,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),

                            // Bio multi-line
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: const Color(0xFFE9ECF3)),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Icon(Icons.info_outline,
                                        color: isEditing
                                            ? AppColors.primary
                                            : Colors.grey,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: bioCtrl,
                                      enabled: isEditing,
                                      maxLines: 4,
                                      minLines: 2,
                                      textDirection: TextDirection.rtl,
                                      decoration: const InputDecoration(
                                        hintText: 'نبذة عنك...',
                                        border: InputBorder.none,
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            _RatingBadge(ratingAvg: ratingAvg),

                            const SizedBox(height: 24),

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
                            _SupportEmailTile(onTap: _launchSupportEmail),

                            const SizedBox(height: 16),

                            if (isEditing) ...[
                              _SectionLabel(label: 'تعديل كلمة المرور'),
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
                                onTap: _confirmDeleteAccount,
                              ),
                              const SizedBox(height: 16),
                            ],

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: goLogout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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


// Expert Header


class _ExpertHeader extends StatelessWidget {
  final List<String> headerImages;
  final String? avatarUrl;
  final String name;
  final String specialization;
  final VoidCallback onBack;
  final VoidCallback onToggleEdit;
  final bool isEditing;
  final double headerHeight;
  static const double _avatarRadius = 58.0;

  const _ExpertHeader({
    required this.headerImages,
    required this.avatarUrl,
    required this.name,
    required this.specialization,
    required this.onBack,
    required this.onToggleEdit,
    required this.isEditing,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context) {
    const avatarDiameter = _avatarRadius * 2;

    return SizedBox(
      height: headerHeight + _avatarRadius + 70,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Curved banner
          ClipPath(
            clipper: _CurvedHeaderClipper(),
            child: SizedBox(
              height: headerHeight,
              width: double.infinity,
              child: headerImages.isEmpty
                  ? Container(color: AppColors.header)
                  : PageView.builder(
                      itemCount: headerImages.length,
                      itemBuilder: (_, i) => Image.network(
                        headerImages[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.header),
                      ),
                    ),
            ),
          ),

          // Back & edit buttons
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
                    onTap: onToggleEdit),
              ],
            ),
          ),

          // Avatar 
          Positioned(
            top: headerHeight - _avatarRadius,
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
                backgroundImage:
                    avatarUrl == null ? null : NetworkImage(avatarUrl!),
                child: avatarUrl == null
                    ? const Icon(Icons.person,
                        size: 48, color: Color(0xFF8B95A5))
                    : null,
              ),
            ),
          ),

          // Name + specialization
          Positioned(
            top: headerHeight + _avatarRadius + 8,
            left: 16,
            right: 16,
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
                if (specialization.isNotEmpty)
                  Text(
                    specialization,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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


// Rating badge (read-only)


class _RatingBadge extends StatelessWidget {
  final double ratingAvg;
  const _RatingBadge({required this.ratingAvg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECF3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFE4A01D), size: 22),
          const SizedBox(width: 10),
          Text(
            'متوسط التقييم: ${ratingAvg.toStringAsFixed(1)} / 5',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          ),
          const Spacer(),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < ratingAvg.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFE4A01D),
                size: 16,
              );
            }),
          ),
        ],
      ),
    );
  }
}


// Shared widgets


class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

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
                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'support@nekhlawi.com',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: AppColors.primary.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}