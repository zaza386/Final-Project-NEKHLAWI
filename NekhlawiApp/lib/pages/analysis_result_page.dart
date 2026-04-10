import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'classifier.dart'; // 1. استيراد ملف المحلل

class AnalysisResultPage extends StatefulWidget {
  final File imageFile;
  final String sessionId;

  const AnalysisResultPage({
    super.key,
    required this.imageFile,
    required this.sessionId,
  });

  @override
  State<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends State<AnalysisResultPage> {
  final supabase = Supabase.instance.client;
  final Classifier _classifier = Classifier(); // 2. تعريف نسخة من المحلل

  bool _isProcessing = true;
  String _statusMessage = 'جاري التحليل...'; // المتغير الذي سيتغير لاحقاً

  @override
  void initState() {
    super.initState();
    _startFullProcess();
  }

  Future<void> _startFullProcess() async {
    try {
      // الخطوة الأولى: رفع الصورة لـ Supabase (لحفظ السجل)
      final String fileName = 'palm_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('pic').upload(fileName, widget.imageFile);
      final String publicUrl = supabase.storage.from('pic').getPublicUrl(fileName);

      final decodedImage = await decodeImageFromList(widget.imageFile.readAsBytesSync());

      // الخطوة الثانية: تشغيل الذكاء الاصطناعي (الموديل)
      // ننتظر قليلاً لضمان تحميل الموديل ثم نقوم بالتنبؤ
      String aiResult = await _classifier.predict(widget.imageFile);

      // الخطوة الثالثة: حفظ البيانات والنتيجة في جدول AISessionPicture
      await supabase.from('AISessionPicture').insert({
        'AISessionID': widget.sessionId,
        'FileURL': publicUrl,
        'Width': decodedImage.width,
        'Height': decodedImage.height,
        'EXIFJson': {'ai_label': aiResult}, // حفظ النتيجة هنا أيضاً
      });

      // الخطوة الرابعة: تحديث الواجهة بالنتيجة
      if (mounted) {
        setState(() {
          _statusMessage = aiResult; // تغيير النص من "جاري التحليل" إلى النتيجة الفعلية
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        setState(() {
          _statusMessage = "حدث خطأ أثناء المعالجة";
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // عرض الصورة الملتقطة
          Image.file(widget.imageFile, fit: BoxFit.cover),

          // طبقة تعتيم
          Container(color: Colors.black.withOpacity(0.5)),

          // محتوى التحليل
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing)
                  const CircularProgressIndicator(color: Color(0xFFC7C7A3)),

                const SizedBox(height: 30),

                // مستطيل النتيجة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF43321A), width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _statusMessage, // هنا تظهر النتيجة (سليمة، مصابة...)
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF43321A),
                        ),
                      ),
                      if (!_isProcessing) ...[
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43321A),
                          ),
                          child: const Text("العودة للكاميرا", style: TextStyle(color: Colors.white)),
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}