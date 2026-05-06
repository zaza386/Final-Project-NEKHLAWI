import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:nekhlawi_app/pages/ai_consultation_details_page.dart';
import 'package:nekhlawi_app/pages/booking_experts_page.dart';
import 'package:nekhlawi_app/pages/booking_page.dart';
import 'package:nekhlawi_app/pages/History_page.dart';
import 'package:nekhlawi_app/pages/mini_wiki.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeServiceGrid extends StatelessWidget {
  final String? userId;

  const HomeServiceGrid({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingExpertsPage()),
            );
          },
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
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.darkBrown),
      ),
    );

    try {
      final sessionResponse = await supabase
          .from('AISession')
          .insert({
            'UserID': user.id,
            'CreatedAt': DateTime.now().toIso8601String(),
          })
          .select('AISessionID')
          .single();

      final String sessionId = sessionResponse['AISessionID'];

      if (context.mounted) {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AiConsultationDetailsPage(title: title, sessionId: sessionId),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }
}

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
