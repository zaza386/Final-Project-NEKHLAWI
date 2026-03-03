import 'package:flutter/material.dart';
import 'package:nekhlawi_app/pages/to_do_page.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/consultation_card.dart';
import 'ai_consultation_details_page.dart';

class ConsultationsPage extends StatefulWidget {
  const ConsultationsPage({super.key});

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  int selectedTab = 0; // 0 = خبير | 1 = AI

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: AppColors.background),

            /// Header
            const HeaderBackground(title: 'الاستشارات'),

            /// Content
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

                    /// Tabs (خبير | AI)
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

                    const SizedBox(height: 16),

                    /// Search
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث عن استشارة...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Content
                    Expanded(
                      child: selectedTab == 0
                          ? _expertConsultations(context)
                          : _aiConsultations(context),
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

  /// Tab button
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

  /// Expert consultations
  Widget _expertConsultations(BuildContext context) {
    return ListView(
      children: [
        ConsultationCard(
          title: 'استشارة تسميد النخيل',
          subtitle: 'م. أحمد العتيبي',
          date: '25 يناير 2026',
          time: '11:15 - 11:30 ص',
          isAi: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TodoPage(
                  title: 'استشارة تسميد النخيل',
                ),
              ),
            );
          },
        ),
        ConsultationCard(
          title: 'مشاكل الري الحديثة',
          subtitle: 'م. خالد السبيعي',
          date: '18 نوفمبر 2025',
          time: '09:00 - 09:15 ص',
          isAi: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TodoPage(
                  title: 'مشاكل الري الحديثة',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// AI consultations
  Widget _aiConsultations(BuildContext context) {
    return ListView(
      children: [
        ConsultationCard(
          title: 'تشخيص اصفرار الأوراق',
          subtitle: 'تحليل ذكي',
          date: '06 نوفمبر 2025',
          time: '08:15 ص',
          isAi: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AiConsultationDetailsPage(
                  title: 'تشخيص اصفرار الأوراق',
                ),
              ),
            );
          },
        ),
        ConsultationCard(
          title: 'توقع مرض فطري',
          subtitle: 'تحليل ذكي',
          date: '02 نوفمبر 2025',
          time: '10:40 ص',
          isAi: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AiConsultationDetailsPage(
                  title: 'توقع مرض فطري',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}