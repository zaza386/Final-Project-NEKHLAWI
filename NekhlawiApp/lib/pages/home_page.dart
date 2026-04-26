import 'package:flutter/material.dart';
import 'package:nekhlawi_app/pages/booking_experts_page.dart';
import 'package:nekhlawi_app/pages/mini_wiki.dart';
import 'package:nekhlawi_app/pages/ai_consultation_details_page.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import 'package:nekhlawi_app/pages/History_page.dart';
import 'package:nekhlawi_app/pages/user_profile.dart';
import 'package:nekhlawi_app/pages/Expert_Account_Page.dart';
import 'package:nekhlawi_app/core/widgets/upcoming_sessions_carousel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  final String? userId;

  const HomePage({super.key, this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;
  String? userRole;
  String greeting = 'صباح الخير';

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _loadUserData();
    }
    _setGreeting();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      greeting = hour < 12 ? 'صباح الخير' : 'مساء الخير';
    });
  }

  Future<void> _loadUserData() async {
    if (widget.userId == null) return;

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('User')
          .select('Name, Role')
          .eq('UserID', widget.userId!)
          .single();

      if (mounted) {
        setState(() {
          userName = response['Name'] ?? 'المستخدم';
          userRole = response['Role'] ?? 'user';
        });
        print('DEBUG userRole = $userRole'); // ← remove after confirming
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = 'المستخدم';
          userRole = 'user';
        });
      }
    }
  }

  // ── Navigate to the correct profile page based on role ──
  void _goToProfile(BuildContext context) {
    // Guard: if role not loaded yet, show message
    if (userRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل البيانات، حاول مرة أخرى')),
      );
      return;
    }
    if (userRole!.toLowerCase() == 'expert') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExpertAccountPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserProfilePage()),
      );
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
            const HeaderBackground(title: 'حياك الله يا النخلاوي', showBack: false),
            Positioned(
              top: 140, left: 0, right: 0, bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              UserSessionsCarousel(
                                userId: widget.userId ?? 'default_user_id',
                                statuses: const ['لم تبدأ', 'بدأت'],
                                iconAssetPath: 'assets/images/home_brown_icon.png',
                              ),
                              const SizedBox(height: 24),
                              _buildWelcomeCard(context),
                              const SizedBox(height: 24),
                              _buildServiceGrid(context),
                              const SizedBox(height: 40),
                              const Center(
                                child: Text(
                                  '©️ 2025 - 2026 نخلاوي',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey, size: 22),
            SizedBox(width: 12),
            Text(
              'ابحث عن أمراض، خبراء، أو مقالات...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _HomeCard(
          icon: Icons.camera_alt_outlined,
          title: 'تشخيص النخل',
          onTap: () => _goToAiDiagnosis(context, 'تشخيص النخل'),
        ),
        _HomeCard(
          icon: Icons.menu_book_outlined,
          title: 'مقالات عن النخل',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MiniWiki()),
          ),
        ),
        _HomeCard(
          icon: Icons.chat_outlined,
          title: 'حجز مع خبير',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookingExpertsPage()),
          ),
        ),
        _HomeCard(
          icon: Icons.history,
          title: 'سجلك الزراعي',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConsultationsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final isExpert = userRole?.toLowerCase() == 'expert';
    final roleLabel = isExpert ? 'خبير نخيل' : 'مزارع';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _goToProfile(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.header.withOpacity(0.6),
              AppColors.header.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.header.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting يا ${userName ?? 'المستخدم'} 👋',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الدور: $roleLabel • اضغط لتعديل ملفك',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.darkBrown),
          ],
        ),
      ),
    );
  }

  void _goToAiDiagnosis(BuildContext context, String title) async {
    final supabase = Supabase.instance.client;

    await Future.delayed(Duration.zero);
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تسجيل الدخول أولاً لتتمكن من استخدام التشخيص'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: AppColors.darkBrown)),
    );

    try {
      final sessionResponse = await supabase.from('AISession').insert({
        'UserID': user.id,
        'CreatedAt': DateTime.now().toIso8601String(),
      }).select('AISessionID').single();

      final String sessionId = sessionResponse['AISessionID'];

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiConsultationDetailsPage(
              title: title,
              sessionId: sessionId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _HomeCard(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.header.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: AppColors.darkBrown),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}