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

  void _showInvalidImageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تنبيه من نخلاوي 🌴", textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF43321A))),
        content: const Text(
            "يبدو أن الصورة الملتقطة ليست لورقة نخل واضحة. فضلاً تأكد من تصوير الورقة مباشرة في مكان مضاء جيداً لضمان دقة التشخيص.",
            textAlign: TextAlign.center, style: TextStyle(height: 1.5)),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B8646)),
              onPressed: () {
                Navigator.pop(context); // إغلاق التنبيه
                Navigator.pop(context); // الرجوع للكاميرا
              },
              child: const Text("حاول مرة أخرى", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runFullAnalysis() async {
    try {
      Map<String, dynamic> result = await _classifier.predict(widget.imageFile);
      String label = result['label'].toString().trim();
      double confidence = result['confidence'];

      // 💡 بوابة الفحص النهائية: إذا كانت الثقة أقل من 85% أو الألوان غير مطابقة
      if (label == "غير قادر على التحديد بدقة" || confidence < 68) {
        if (mounted) _showInvalidImageDialog();
        return;
      }

      final String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('pic').upload(fileName, widget.imageFile);
      final String uploadedUrl = supabase.storage.from('pic').getPublicUrl(fileName);

      final sessionResponse = await supabase.from('AISession').insert({
        'SessionTitle': 'تشخيص: $label',
        'CreatedAt': DateTime.now().toIso8601String(),
        'UserID': supabase.auth.currentUser?.id,
      }).select().single();

      final diseaseData = await supabase.from('Disease').select().ilike('ArabicName', '%$label%').maybeSingle();
      Map<String, dynamic>? treatmentData;
      if (diseaseData != null) {
        treatmentData = await supabase.from('Treatment').select().eq('DiseaseID', diseaseData['DiseaseID']).maybeSingle();
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AnalysisResultPage(
          imageFile: widget.imageFile, imageUrl: uploadedUrl, aiLabel: label,
          confidence: confidence, diseaseInfo: diseaseData, treatmentInfo: treatmentData, sessionId: sessionResponse['AISessionID'].toString(),
        )));
      }
    } catch (e) {
      if (mounted) _showInvalidImageDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.file(widget.imageFile, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Container(color: Colors.white.withOpacity(0.5)))),
          const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: Color(0xFF7B8646), strokeWidth: 6),
            SizedBox(height: 40),
            Text("جاري التحليل...", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF43321A))),
          ])),
        ],
      ),
    );
  }
}