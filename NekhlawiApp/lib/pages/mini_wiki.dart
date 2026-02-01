import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/widgets/article_card.dart';
import 'package:nekhlawi_app/pages/to_do_page.dart';
import '../core/widgets/header_background.dart';
import '../core/theme/app_colors.dart';

class MiniWiki extends StatelessWidget {
  const MiniWiki({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: Colors.white),

            HeaderBackground(
              title: 'اكتشف واملأ فضولك \nحتى القمة',
            ),

            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    const SizedBox(height: 40),

                    /// 🔍 البحث (ثابت)
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث عن مقال...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ⬇️ السكرول يبدأ من هنا
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          ArticleCard(
                            image: 'images/palm_growth.jpg',
                            title:
                            'هل تعرف سر ارتفاعها؟ خارطة الجذع والسعف',
                            description:
                            'تبدأ رحلة النخلة من الجذور العميقة التي تضمن الثبات والعطاء...',
                            onReadMore: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TodoPage(
                                    title:
                                    'هل تعرف سر ارتفاعها؟ خارطة الجذع والسعف',
                                  ),
                                ),
                              );
                            },
                          ),

                          ArticleCard(
                            image: 'images/seedling.jpg',
                            title:
                            'من "الفسيلة الصغيرة" إلى "عملاقة الصحراء"',
                            description:
                            'النخلة كائن حي مذهل، تمر بمراحل دقيقة حتى تصل لمرحلة الإنتاج...',
                            onReadMore: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TodoPage(
                                    title:
                                    'من "الفسيلة الصغيرة" إلى "عملاقة الصحراء"',
                                  ),
                                ),
                              );
                            },
                          ),

                          ArticleCard(
                            image: 'images/pests.png',
                            title: 'الأعداء تحت السطح!',
                            description:
                            'تعرف على أخطر الآفات التي تهدد النخيل وكيفية اكتشافها مبكرًا...',
                            onReadMore: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TodoPage(
                                    title: 'الأعداء تحت السطح!',
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),
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