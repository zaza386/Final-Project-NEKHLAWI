import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:nekhlawi_app/pages/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  /// بيانات كل صفحة
  final List<Map<String, String>> onboardingData = [
    {
      'image': 'images/image1.png',
      'title': 'استشارة الخبراء',
      'desc':
          'احصل على إرشادات دقيقة من خبراء العناية بالنخيل.\nشارك مشكلتك أو صورة النخلة وسيتم توجيهك بخطوات واضحة.',
    },
    {
      'image': 'images/image2.png',
      'title': 'تشخيص ذكي',
      'desc':
          'اكتشف أمراض النخيل باستخدام الذكاء الاصطناعي بطريقة سهلة وسريعة.',
    },
    {
      'image': 'images/image3.png',
      'title': 'دليل النخيل',
      'desc': 'مكتبة معرفية تحتوي على مقالات وإرشادات لمساعدتك في العناية بالنخيل وتحسين صحته وإنتاجه',
    },
  ];

  /// المؤشر
  Widget _dot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: isActive ? 90 : 90,
      height: 4,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF343434) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  /// محتوى الصفحة
  Widget _onboardingItem({
    required String imagePath,
    required String title,
    required String description,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        /// الصورة
        Image.asset(
          imagePath,
          width: MediaQuery.of(context).size.width * 0.75,
          height: MediaQuery.of(context).size.height * 0.4,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 50),

        /// العنوان
        Padding(
          padding: const EdgeInsets.only(right: 32),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
          ),
        ),
        

        const SizedBox(height: 14),

        /// الوصف
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              description,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkBrown,
                height: 1.6,
              ),
            ),
          ),
        ), 
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            /// الصفحات
            PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final item = onboardingData[index];
                return _onboardingItem(
                  imagePath: item['image']!,
                  title: item['title']!,
                  description: item['desc']!,
                );
              },
            ),

            /// المؤشرات
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingData.length,
                  (index) => _dot(isActive: index == _currentPage),
                ),
              ),
            ),

            /// السهم (آخر صفحة فقط)
            if (_currentPage == onboardingData.length - 1)
              Positioned(
                bottom: 32,
                right: 24,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}