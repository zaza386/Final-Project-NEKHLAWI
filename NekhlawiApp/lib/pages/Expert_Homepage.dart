import 'package:flutter/material.dart';
import 'package:nekhlawi_app/pages/mini_wiki.dart';
import 'package:nekhlawi_app/pages/ai_consultation_details_page.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import 'package:nekhlawi_app/pages/History_expert.dart';
import 'package:nekhlawi_app/pages/Expert_Account_Page.dart';   // ← Expert profile
import 'package:nekhlawi_app/core/widgets/upcoming_sessions_carousel.dart';
import 'package:nekhlawi_app/pages/wiki_article_details_page.dart';
import 'package:nekhlawi_app/core/data/wiki_article_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// import 'package:nekhlawi_app/pages/expert_sessions_page.dart';

class ExpertHomePage extends StatefulWidget {
  final String? userId;

  const ExpertHomePage({super.key, this.userId});

  @override
  State<ExpertHomePage> createState() => _ExpertHomePageState();
}

class _ExpertHomePageState extends State<ExpertHomePage> {
  String? userName;
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
          .select('Name')
          .eq('UserID', widget.userId!)
          .single();

      if (mounted) {
        setState(() {
          userName = response['Name'] ?? 'الخبير';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = 'الخبير';
        });
      }
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
            const HeaderBackground(title: 'حياك الله يا الخبير', showBack: false),
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
                                isExpert: true,
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
    child: SearchAnchor(
      builder: (context, controller) {
        return SearchBar(
          controller: controller,
          hintText:'ابحث عن أمراض، مقالات، أو جلسات...',
          leading: const Icon(Icons.search, color: Colors.grey),
          backgroundColor: WidgetStateProperty.all(Colors.grey.shade100),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onTap: () => controller.openView(),
          onChanged: (_) => controller.openView(),
        );
      },
      suggestionsBuilder: (context, controller) async {
        final query = controller.text.trim();
        if (query.isEmpty) return [];

        final List<Widget> suggestions = [];

       try{ 

          final _wikiRepo = WikiArticleRepo();
          final articleItems = await _wikiRepo.fetchArticles(query: query);

          if (articleItems != null && articleItems.isNotEmpty) {
            suggestions.add(
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('المقالات',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
              ),
            );

            for (final article in articleItems) {
              suggestions.add(
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.header,
                    child: Icon(Icons.article_outlined, color: AppColors.darkBrown),
                  ),
                  title: Text(article.title),
                  subtitle: Text(article.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_back_ios, size: 14, color: AppColors.darkBrown),
                  onTap: () {
                    controller.closeView('');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WikiArticleDetailsPage(article: article)),
                    );
                  },
                ),
              );
            }
          }

          if (suggestions.isEmpty) {
            suggestions.add(
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('لا توجد نتائج مطابقة لبحثك', style: TextStyle(color: Colors.grey))),
              ),
            );
          }

        } catch (e) {
          debugPrint('Search error: $e');
          suggestions.add(const ListTile(title: Text('حدث خطأ في البحث')));
        }

        return suggestions;
      },
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
          icon: Icons.calendar_month_outlined,
          title: 'إدارة الجلسات',
          onTap: () => _goToManageSessions(context),
        ),
        _HomeCard(
          icon: Icons.history,
          title: 'سجلك الزراعي',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConsultationsPage2()),
          ),
        ),
      ],
    );
  }

  /// ← بطاقة الترحيب تفتح صفحة حساب الخبير
  Widget _buildWelcomeCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpertAccountPage()),
        );
        // أعِد تحميل اسم المستخدم بعد العودة من صفحة التعديل
        _loadUserData();
      },
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
                    '$greeting يا ${userName ?? 'الخبير'} 👋',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'الدور: خبير • اضغط لتعديل ملفك',
                    style: TextStyle(fontSize: 14, color: AppColors.darkBrown),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.darkBrown),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  void _goToManageSessions(BuildContext context) {
    // TODO: replace with ExpertSessionsPage when ready
    // Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpertSessionsPage()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('صفحة إدارة الجلسات قيد التطوير'),
        backgroundColor: AppColors.darkBrown,
      ),
    );
  }
}

// ── Reusable card widget ──────────────────────────────────────────────────────

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

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