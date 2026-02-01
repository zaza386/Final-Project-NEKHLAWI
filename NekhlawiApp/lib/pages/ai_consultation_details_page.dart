import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/action_card.dart';
import '../core/widgets/ai_result_card.dart';

class AiConsultationDetailsPage extends StatelessWidget {
  final String title;

  const AiConsultationDetailsPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: Colors.white),
            HeaderBackground(title: title),

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

                    /// المحتوى المتحرك
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [

                          /// 🖼️ الصورة (تتحرك مع السكرول)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'images/image5.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// 🤖 نتيجة الذكاء الاصطناعي
                          const AiResultCard(
                            title: 'تلف لا رجعة فيه / موت',
                            confidence: 'نسبة ثقة الذكاء الاصطناعي: مرتفعة',
                            reason: 'السبب المحتمل: إصابة بسوسة النخيل',
                            percentage: '98%',
                          ),

                          const SizedBox(height: 16),

                          /// 📄 الوصف
                          const Text(
                            '''
الأدلة البصرية قاطعة: جميع السعف جاف تماماً (بني اللون)،
والقمة النامية (القلب) منهارة. عملية التمثيل الضوئي متوقفة تماماً،
مما يعني أن النخلة قد ماتت سريرياً.

كما أن مظهر "المظلة المفتوحة" وانهيار التاج هو عرض كلاسيكي
للإصابة المتقدمة بسوسة النخيل.

ولكن لا يمكن تأكيد ذلك بنسبة 100% من الصورة فقط دون فحص الجذع.
                            ''',
                            style: TextStyle(height: 1.8),
                          ),

                          const SizedBox(height: 24),

                          /// ⚠️ الإجراءات
                          const Text(
                            'الإجراءات المقترحة:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// 🧯 الكروت (بدون Overflow)
                          Row(
                            children: [
                              Flexible(
                                child: ActionCard(
                                  icon: Icons.local_fire_department,
                                  label: 'التخلص الآمن',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: ActionCard(
                                  icon: Icons.hardware,
                                  label: 'الإزالة الفورية',
                                ),
                              ),
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
}