import 'package:flutter/material.dart';

class AiConsultationDetailsPage extends StatefulWidget {
  final String title;
  const AiConsultationDetailsPage({super.key, required this.title});

  @override
  State<AiConsultationDetailsPage> createState() => _AiConsultationDetailsPageState();
}

class _AiConsultationDetailsPageState extends State<AiConsultationDetailsPage> {
  
  @override
  void initState() {
    super.initState();
    // تظهر نافذة التعليمات تلقائياً بعد بناء الصفحة بـ 500 ملي ثانية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: Colors.white),
            // HeaderBackground(title: widget.title), // تأكد من تفعيلها في مشروعك

            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'images/image5.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  Container(height: 200, color: Colors.grey[300], child: Icon(Icons.image_not_supported)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // كارت النتيجة (AiResultCard)
                          _buildAiResultPlaceholder(), 

                          const SizedBox(height: 16),
                          const Text(
                            '''الأدلة البصرية قاطعة: جميع السعف جاف تماماً (بني اللون)، والقمة النامية (القلب) منهارة...''',
                            style: TextStyle(height: 1.8, fontSize: 15),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'الإجراءات المقترحة:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildActionBtn(Icons.local_fire_department, 'التخلص الآمن')),
                              const SizedBox(width: 12),
                              Expanded(child: _buildActionBtn(Icons.hardware, 'الإزالة الفورية')),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
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

  // دالة إظهار نافذة التعليمات (التي طلبتها في السؤال السابق)
  void _showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // لا يغلق عند الضغط خارج النافذة
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ),
                const Text(
                  "تعليمات الصورة",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.error, color: Colors.red, size: 70),
                const SizedBox(height: 20),
                const Text(
                  "قبل ما ترفع الصورة.. تأكد إنها منورة وواضحة، وحجمها أقل من 10 ميجابايت. وتذكر أننا نستقبل صور فقط.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E8449),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("فهمت", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // أجزاء تجريبية لتعويض الكلاسات المفقودة لديك
  Widget _buildActionBtn(IconData icon, String label) => Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [Icon(icon, color: Colors.orange), Text(label)]),
  );

  Widget _buildAiResultPlaceholder() => Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
    child: Text("نتيجة الذكاء الاصطناعي: إصابة متقدمة", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
  );
}
