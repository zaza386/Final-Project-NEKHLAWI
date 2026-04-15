import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_experts_page.dart';

class AnalysisResultPage extends StatefulWidget {
  final File? imageFile;
  final String? imageUrl;     // هذا الرابط القادم من السيرفر
  final String aiLabel;
  final double confidence;
  final Map<String, dynamic>? diseaseInfo;
  final Map<String, dynamic>? treatmentInfo;
  final String sessionId;

  const AnalysisResultPage({
    super.key,
    this.imageFile,
    this.imageUrl,
    required this.aiLabel,
    required this.confidence,
    required this.sessionId,
    this.diseaseInfo,
    this.treatmentInfo,
  });

  @override
  State<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends State<AnalysisResultPage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // إذا كانت هناك صورة جديدة ورابط، نقوم بالحفظ
    if (widget.imageFile != null && widget.imageUrl != null) {
      _saveAllDataToDatabase();
    }
  }

  Future<void> _saveAllDataToDatabase() async {
    try {
      // 1. حفظ بيانات التشخيص
      if (widget.diseaseInfo != null) {
        await supabase.from('AIDiagnosis Table').insert({
          'AISessionID': widget.sessionId,
          'DiseaseID': widget.diseaseInfo!['DiseaseID'],
          'Confidence': "${widget.confidence.toStringAsFixed(0)}%",
        });
      }

      // 2. حفظ رابط الصورة في جدول AISessionPicture
      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        await supabase.from('AISessionPicture').insert({
          'AISessionID': widget.sessionId,
          'FileURL': widget.imageUrl, // العمود كما في قاعدة بياناتك
        });
        print("✅ تم حفظ الصورة في الداتابيز بنجاح");
      }
    } catch (e) {
      debugPrint("❌ خطأ أثناء الحفظ: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBrown = Color(0xFF43321A);
    const Color lightBeige = Color(0xFFD9E0B3);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightBeige,
        appBar: AppBar(
          title: const Text("نتائج التحليل", style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: widget.imageFile != null
                    ? Image.file(widget.imageFile!, height: 180, width: double.infinity, fit: BoxFit.cover)
                    : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    ? Image.network(widget.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 180, color: Colors.grey[300], child: const Icon(Icons.image)),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      _buildResultCard(widget.aiLabel, widget.confidence),
                      const SizedBox(height: 30),
                      _buildSection("الأعراض:", widget.diseaseInfo?['Symptoms'] ?? "لا توجد تفاصيل."),
                      _buildSection("العلاج:", widget.treatmentInfo?['Steps'] ?? "لا يتوفر علاج حالياً."),
                      const SizedBox(height: 30),
                      // الهيبرلينك لصفحة الخبراء
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingExpertsPage())),
                        child: Column(
                          children: [
                            const Text("بستشير خبيراً", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBrown)),
                            Container(margin: const EdgeInsets.only(top: 2), height: 1.5, width: 100, color: darkBrown),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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

  // ميثود مساعدة لبناء الأقسام
  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF43321A))),
        const SizedBox(height: 10),
        Text(content, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87)),
        const Divider(height: 35),
      ],
    );
  }

  Widget _buildResultCard(String label, double conf) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFD9E0B3).withOpacity(0.3), borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          CircularProgressIndicator(value: conf / 100, color: const Color(0xFF7B8646), strokeWidth: 6),
          const SizedBox(width: 25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF43321A))),
              Text("الدقة: ${conf.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }
}