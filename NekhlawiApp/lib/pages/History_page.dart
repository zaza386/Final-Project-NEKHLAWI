import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/consultation_card.dart';
import 'analysis_result_page.dart';
import 'package:nekhlawi_app/pages/to_do_page.dart';

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
                    /// Tabs (خبير / AI)
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

  /// قائمة استشارات الخبراء
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

  /// قائمة استشارات AI (الهيستوري)
  Widget _buildAiList() {
    final user = supabase.auth.currentUser;

    return FutureBuilder(
      future: supabase
          .from('AISession')
          .select()
          .eq('UserID', user?.id ?? '')
          .order('CreatedAt', ascending: false),
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
            DateTime createdAt = DateTime.parse(item['CreatedAt']);
            String formattedDate =
                "${createdAt.day}/${createdAt.month}/${createdAt.year}";

            return ConsultationCard(
              title:
                  item['Title'] ??
                  'تحليل نخلة #${item['AISessionID'].toString().substring(0, 5)}',
              subtitle: 'تحليل ذكي بواسطة نخلاوي',
              date: formattedDate,
              time: "${createdAt.hour}:${createdAt.minute}",
              isAi: true,
              onTap: () async {
                try {
                  // 1. جلب بيانات التشخيص مع ربط الجداول (المرض والعلاج)
                  final diagnosisData = await supabase
                      .from('AIDiagnosis Table')
                      .select('*, Disease(*, Treatment(*))')
                      .eq('AISessionID', item['AISessionID'])
                      .maybeSingle();

                  // 2. جلب رابط الصورة من جدول AISessionPicture (باستخدام عمود FileURL)
                  final pictureData = await supabase
                      .from('AISessionPicture')
                      .select('FileURL')
                      .eq('AISessionID', item['AISessionID'])
                      .maybeSingle();

                  if (diagnosisData != null && context.mounted) {
                    // معالجة بيانات المرض (تحويل القائمة لماب)
                    final diseaseSource =
                        diagnosisData['Disease'] ?? diagnosisData['disease'];
                    final Map<String, dynamic>? diseaseMap =
                        (diseaseSource is List && diseaseSource.isNotEmpty)
                        ? diseaseSource[0]
                        : (diseaseSource is Map<String, dynamic>
                              ? diseaseSource
                              : null);

                    // معالجة بيانات العلاج (تحويل القائمة لماب)
                    final treatmentSource =
                        diseaseMap?['Treatment'] ?? diseaseMap?['treatment'];
                    final Map<String, dynamic>? treatmentMap =
                        (treatmentSource is List && treatmentSource.isNotEmpty)
                        ? treatmentSource[0]
                        : (treatmentSource is Map<String, dynamic>
                              ? treatmentSource
                              : null);

                    // تنظيف النسبة المئوية للتحليل
                    String confStr =
                        diagnosisData['Confidence']?.toString().replaceAll(
                          '%',
                          '',
                        ) ??
                        "0";
                    double confVal = double.tryParse(confStr) ?? 0.0;

                    // 3. الانتقال لصفحة النتائج وتمرير الرابط المجلوب FileURL
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnalysisResultPage(
                          imageFile:
                              null, // نرسل null لأننا نستخدم الرابطimageUrl
                          imageUrl: pictureData != null
                              ? pictureData['FileURL']
                              : null,
                          aiLabel: diseaseMap?['ArabicName'] ?? 'غير معروف',
                          confidence: confVal,
                          sessionId: item['AISessionID'].toString(),
                          diseaseInfo: diseaseMap,
                          treatmentInfo: treatmentMap,
                        ),
                      ),
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "عذراً، تفاصيل هذا التشخيص غير متوفرة في السجلات",
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint("Error fetching details: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("حدث خطأ أثناء تحميل البيانات: $e"),
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}
