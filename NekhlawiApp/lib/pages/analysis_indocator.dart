import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'classifier.dart';
import 'analysis_result_page.dart';

class ProcessingPage extends StatefulWidget {
  final File imageFile;

  const ProcessingPage({super.key, required this.imageFile});

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  final Classifier _classifier = Classifier();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _runFullAnalysis();
  }

  Future<void> _runFullAnalysis() async {
    try {
      // 1. تشغيل الموديل
      Map<String, dynamic> result = await _classifier.predict(widget.imageFile);
      String label = result['label'].toString().trim();
      double confidence = result['confidence'];

      // 2. رفع الصورة إلى السيرفر (اسم الـ Bucket هو pic)
      final String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = fileName; // الرفع في المجلد الرئيسي للـ Bucket

      await supabase.storage.from('pic').upload(
        path,
        widget.imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // جلب الرابط العام
      final String uploadedUrl = supabase.storage.from('pic').getPublicUrl(path);

      // 3. إنشاء الجلسة
      final sessionResponse = await supabase.from('AISession').insert({
        'SessionTitle': 'تشخيص: $label',
        'CreatedAt': DateTime.now().toIso8601String(),
        'UserID': supabase.auth.currentUser?.id,
      }).select().single();

      String newSessionId = sessionResponse['AISessionID'].toString();

      // 4. جلب بيانات المرض
      final diseaseData = await supabase
          .from('Disease')
          .select()
          .ilike('ArabicName', '%$label%')
          .maybeSingle();

      Map<String, dynamic>? treatmentData;
      if (diseaseData != null) {
        treatmentData = await supabase
            .from('Treatment')
            .select()
            .eq('DiseaseID', diseaseData['DiseaseID'])
            .maybeSingle();
      }

      // 5. الانتقال لصفحة النتائج مع الرابط الصحيح
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultPage(
              imageFile: widget.imageFile,
              imageUrl: uploadedUrl, // الرابط اللي بيروح يتحفظ في الداتابيز
              aiLabel: label,
              confidence: confidence,
              diseaseInfo: diseaseData,
              treatmentInfo: treatmentData,
              sessionId: newSessionId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل الرفع للـ Bucket 'pic': $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.file(widget.imageFile, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF7B8646), strokeWidth: 6),
                SizedBox(height: 40),
                Text("جاري التحليل...", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF43321A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}