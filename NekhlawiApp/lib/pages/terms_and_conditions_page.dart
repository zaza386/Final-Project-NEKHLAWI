import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/primary_button.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            /// الخلفية الأساسية
            Container(color: Colors.white),

            /// الهيدر (ثابت في الخلف)
            const HeaderBackground(
              title: 'الشروط والأحكام',
            ),

            /// المحتوى الأبيض بإطار مدور ثابت
            Positioned(
              top: 140, // بداية ظهور الجزء الأبيض
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                // هنا التعديل: جعلنا الحواف مدورة وثابتة في هذا الحاوية
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  // إضافة ظل خفيف ليعطي شكل جمالي فوق الهيدر
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  // لضمان أن المحتوى لا يخرج عن الحواف المدورة أثناء السكرول
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),

                        /// بطاقة الترحيب
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: AppColors.header.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'هلا فيك 👋\nقبل نكمّل تسجيلك، خذ لحظة لقراءة الشروط والأحكام والموافقة عليها.',
                            style: TextStyle(
                              color: AppColors.darkBrown,
                              height: 1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Center(
                          child: Text(
                            'الشروط والأحكام',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Center(
                          child: Text(
                            'آخر تحديث: 2025-05-18',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// ===== البنود =====
                        _sectionTitle('1. قبول الشروط'),
                        _paragraph(
                          'باستخدامك لتطبيق نخلاوي، فإنك تقر بأنك قرأت هذه الشروط وفهمتها وتوافق على الالتزام بها بالكامل.',
                        ),

                        _sectionTitle('2. أهلية الاستخدام'),
                        _bullet('يجب أن يكون المستخدم 18 سنة أو أكبر.'),
                        _bullet(
                            'في حال كان المستخدم أصغر من ذلك، يجب وجود موافقة من ولي الأمر.'),
                        _bullet(
                            'يجب أن تكون جميع المعلومات المقدمة صحيحة ومحدثة.'),

                        _sectionTitle('3. إنشاء الحساب'),
                        _bullet('تقديم معلومات صحيحة ودقيقة.'),
                        _bullet(
                            'الحفاظ على سرية كلمة المرور وعدم مشاركتها.'),
                        _bullet(
                            'المستخدم مسؤول عن أي نشاط يتم من خلال حسابه.'),

                        _sectionTitle('4. استخدام التطبيق'),
                        _bullet(
                            'يُسمح باستخدام التطبيق للأغراض المشروعة فقط.'),
                        _bullet('طلب التشخيص والتواصل مع الخبراء.'),
                        _bullet('رفع صور النخيل للمساعدة في التشخيص.'),
                        _bullet('الاستفادة من المحتوى والمقالات التعليمية.'),

                        _sectionTitle('5. دور الخبراء'),
                        _paragraph(
                          'الخبراء داخل التطبيق يقدمون توصيات عامة أو تشخيص مبدئي بالاعتماد على الصور والمعلومات المرسلة، ولا يتحمل التطبيق مسؤولية أي نتائج ناتجة عن سوء التطبيق.',
                        ),

                        _sectionTitle('6. المحتوى وحقوق الملكية'),
                        _bullet(
                            'جميع النصوص, الصور, التصاميم والشعارات داخل التطبيق مملوكة لفريق نخلاوي ولا يجوز:'),
                        _bullet(
                            ' نسخها أو إعادة استخدامها دون إذن.'),
                        _bullet(
                            ' استخدامها لأغراض تجارية خارج التطبيق.'),

                        _sectionTitle('7. إيقاف الحساب'),
                        _paragraph('يحق لإدارة التطبيق :'),
                        _bullet(
                            'تعليق أو حذف أي حساب يسيء الاستخدام أو يخالف الشروط.'),
                        _bullet(
                            'إزالة أي محتوى مخالف دون الرجوع للمستخدم.'),

                        _sectionTitle('8. التعديلات على الشروط'),
                        _paragraph(
                          'قد نقوم بتحديث الشروط في أي وقت، وسيتم إشعار المستخدمين عند وجود تعديلات مهمة.',
                        ),

                        const SizedBox(height: 40),

                        /// زر التأكيد
                        PrimaryButton(
                          title: 'تأكيد',
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),

                        const SizedBox(height: 20),

                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              '©️ 2025 - 2026',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== Widgets مساعدة (لم تتغير) =====

  static Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.darkBrown,
        ),
      ),
    );
  }

  static Widget _paragraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Colors.black87,
      ),
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ',
              style: TextStyle(fontSize: 18, height: 1.3)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}