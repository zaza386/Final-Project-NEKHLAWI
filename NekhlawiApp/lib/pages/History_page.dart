import 'package:flutter/material.dart';
import 'package:nekhlawi_app/pages/to_do_page.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/consultation_card.dart';
import 'ai_consultation_details_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultationsPage extends StatefulWidget {
  const ConsultationsPage({super.key});

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  int selectedTab = 0; // 0 = خبير | 1 = AI
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: AppColors.background),
            const HeaderBackground(title: 'الاستشارات'),
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    /// Tabs
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _buildTab('استشارات الخبير', 0),
                          _buildTab('استشارات AI', 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Content (سحب البيانات بناءً على التاب المختار)
                    Expanded(
                      child: selectedTab == 0
                          ? _buildExpertList()
                          : _buildAiList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// جلب استشارات الخبراء من جدول (مثلاً: ExpertConsultations)
  Widget _buildExpertList() {
    return FutureBuilder(
      future: supabase.from('ExpertConsultations').select().order('created_at'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("لا توجد استشارات خبراء حالياً"));
        }

        final data = snapshot.data as List<dynamic>;

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            return ConsultationCard(
              title: item['Title'] ?? 'استشارة خبير',
              subtitle: item['ExpertName'] ?? 'مختص زراعي',
              date: item['Date'] ?? '',
              time: item['Time'] ?? '',
              isAi: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TodoPage(title: item['Title']),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// جلب استشارات AI من جدول (AISession)
  Widget _buildAiList() {
    final user = supabase.auth.currentUser;

    return FutureBuilder(
      // نجلب فقط الجلسات الخاصة بالمستخدم الحالي
      future: supabase
          .from('AISession')
          .select()
          .eq('UserID', user?.id ?? '')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("حدث خطأ: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("لا توجد استشارات ذكاء اصطناعي"));
        }

        final data = snapshot.data as List<dynamic>;

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            // تحويل الوقت من format قاعدة البيانات لشكل مقروء
            DateTime createdAt = DateTime.parse(item['created_at']);
            String formattedDate = "${createdAt.day}/${createdAt.month}/${createdAt.year}";

            return ConsultationCard(
              title: 'تحليل نخلة #${item['AISessionID'].toString().substring(0, 5)}',
              subtitle: 'تحليل ذكي',
              date: formattedDate,
              time: "${createdAt.hour}:${createdAt.minute}",
              isAi: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AiConsultationDetailsPage(
                      title: 'تفاصيل التشخيص',
                      sessionId: item['AISessionID'].toString(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}