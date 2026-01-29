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
        backgroundColor: Colors.white,
        body: Column(
          children: [
            HeaderBackground(
              title: 'اكتشف واملأ فضولك حتى القمة',
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
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
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ArticleCard(
                    image: 'images/palm_growth.jpg',
                    title: 'هل تعرف سر ارتفاعها؟ خارطة الجذع والسعف',
                    description:
                        'تبدأ رحلة النخلة من الجذور العميقة التي تضمن الثبات والعطاء...',
                    onReadMore: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TodoPage(title: 'هل تعرف سر ارتفاعها؟ خارطة الجذع والسعف',),
                        ),
                      );
                    },
                  ),

                  ArticleCard(
                    image: 'assets/images/seedling.png',
                    title: 'من "الفسيلة الصغيرة" إلى "عملاقة الصحراء"',
                    description:
                        'النخلة كائن حي مذهل، تمر بمراحل دقيقة حتى تصل لمرحلة الإنتاج...',
                    onReadMore: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TodoPage(title: 'من "الفسيلة الصغيرة" إلى "عملاقة الصحراء"',),
                        ),
                      );
                    },
                  ),

                  ArticleCard(
                    image: 'assets/images/pests.png',
                    title: 'الأعداء تحت السطح!',
                    description:
                        'تعرف على أخطر الآفات التي تهدد النخيل وكيفية اكتشافها مبكرًا...',
                    onReadMore: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TodoPage(title: 'الأعداء تحت السطح!',),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}