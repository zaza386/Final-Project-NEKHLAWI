import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/consultation_card.dart';
import 'analysis_result_page.dart';


class ConsultationsPage2 extends StatefulWidget {
  const ConsultationsPage2({super.key});

  @override
  State<ConsultationsPage2> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage2> {
  int selectedTab = 0;
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final expertProfile = await supabase
          .from('ExpertProfile')
          .select('ExpertID')
          .eq('ExpertID', currentUser.id)
          .single();

      final realExpertId = expertProfile['ExpertID'];

      final response = await supabase
          .from('Review')
          .select('ReviewID, Rating, Comment, CreatedAt')
          .eq('ExpertID', realExpertId)
          .order('CreatedAt', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);

      double avg = 0.0;
      if (list.isNotEmpty) {
        final total = list.fold<int>(
          0,
              (sum, r) => sum + ((r['Rating'] as int?) ?? 0),
        );
        avg = total / list.length;
      }

      if (mounted) {
        setState(() {
          _reviews = list;
          _averageRating = avg;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Reviews error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: AppColors.background),
            const HeaderBackground(title: 'الاستشارات والتقييمات'),
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
                          _buildTab('التقييمات', 0),
                          _buildTab('استشارات AI', 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: selectedTab == 0
                          ? _buildExpertSection()
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

  // قسم عرض التقييمات الخاص بالخبير
  Widget _buildExpertSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_reviews.isEmpty) {
      return _buildEmpty();
    }
    return Column(
      children: [
        _buildSummaryCard(),
        Expanded(child: _buildReviewsList()),
      ],
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.reviews_outlined, size: 64, color: AppColors.grey),
          SizedBox(height: 16),
          Text(
            'لا توجد تقييمات بعد',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStars(_averageRating),
              Text(
                '(${_reviews.length} تقييم)',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          // Breakdown simplified for brevity
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [5, 4, 3, 2, 1].map((star) {
              final count = _reviews
                  .where((r) => (r['Rating'] as int?) == star)
                  .length;
              final percent = _reviews.isEmpty ? 0.0 : count / _reviews.length;
              return Row(
                children: [
                  Text('$star', style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 60,
                    height: 4,
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.white,
                      color: Colors.amber,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.builder(
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final rating = (review['Rating'] as int?) ?? 0;
        final comment = (review['Comment'] as String?) ?? '';
        final date = _formatDate(review['CreatedAt']?.toString());

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStars(rating.toDouble()),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(comment, style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
            (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        ),
      ),
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

            // session title retrieved from AISession Session Title col
            final String sessionTitle =
            (item['SessionTitle'] as String?)?.isNotEmpty == true
                ? item['Session Title'] as String
                : 'استشارة بدون عنوان';

            return FutureBuilder<Map<String, dynamic>?>(
              // confidence retrieved from AIDiagnosis Table
              future: supabase
                  .from('AIDiagnosis Table')
                  .select('Confidence')
                  .eq('AISessionID', item['AISessionID'])
                  .maybeSingle(),
              builder: (context, confSnap) {

                String? confidenceLabel;
                if (confSnap.hasData && confSnap.data != null) {
                  final raw =
                      confSnap.data!['Confidence']?.toString().replaceAll('%', '') ?? '';
                  final val = double.tryParse(raw);
                  if (val != null) {
                    confidenceLabel =
                    'الدقة: ${val.toStringAsFixed(1)}%';
                  }
                }

                return ConsultationCard(
                  title: sessionTitle,
                  subtitle: confidenceLabel != null
                      ? 'تحليل ذكي بواسطة نخلاوي\n$confidenceLabel'
                      : 'تحليل ذكي بواسطة نخلاوي',
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
      },
    );
  }
}