import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import '../core/data/wiki_article_repo.dart';

class WikiArticleDetailsPage extends StatelessWidget {
  final WikiArticleItem article;

  const WikiArticleDetailsPage({
    super.key,
    required this.article,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    // YYYY-MM-DD
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Widget _buildImage(String image) {
    final isNetwork = image.trim().toLowerCase().startsWith('http');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: isNetwork
          ? Image.network(
              image,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image),
              ),
            )
          : Image.asset(
              image,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(article.createdAt);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: Colors.white),


            HeaderBackground(title: article.title),

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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImage(
                          article.imageUrl.isNotEmpty
                              ? article.imageUrl
                              : 'images/palm_growth.jpg',
                        ),

                        const SizedBox(height: 14),

                        // ✅ شارات صغيرة: category / author / date
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (article.category.trim().isNotEmpty)
                              _Chip(text: article.category),
                            if (article.authorName.trim().isNotEmpty)
                              _Chip(text: '✍️ ${article.authorName}'),
                            if (dateText.isNotEmpty) _Chip(text: '📅 $dateText'),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ✅ العنوان داخل الصفحة (اختياري)
                        Text(
                          article.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBrown,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ✅ المحتوى
                        Text(
                          article.content.trim().isNotEmpty
                              ? article.content
                              : article.description, // fallback لو content فاضي
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.8,
                            color: AppColors.darkBrown,
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
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.header,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.darkBrown,
        ),
      ),
    );
  }
}