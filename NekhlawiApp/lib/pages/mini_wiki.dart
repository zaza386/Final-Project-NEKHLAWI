import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/widgets/article_card.dart';
import '../core/widgets/header_background.dart';
import '../core/theme/app_colors.dart';
import 'wiki_article_details_page.dart';
import '../core/data/wiki_article_repo.dart';

class MiniWiki extends StatefulWidget {
  const MiniWiki({super.key});

  @override
  State<MiniWiki> createState() => _MiniWikiState();
}

class _MiniWikiState extends State<MiniWiki> {
  final _repo = WikiArticleRepo();
  final _searchController = TextEditingController();

  Future<List<WikiArticleItem>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchArticles();
  }

  void _runSearch(String value) {
    setState(() {
      _future = _repo.fetchArticles(query: value);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: Colors.white),

            const HeaderBackground(
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

                    /// 🔍 البحث
                    TextField(                     controller: _searchController,
                      onChanged: _runSearch,
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

                    Expanded(
                      child: FutureBuilder<List<WikiArticleItem>>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'صار خطأ في تحميل المقالات:\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          final articles = snapshot.data ?? [];

                          if (articles.isEmpty) {
                            return const Center(child: Text('ما فيه مقالات حالياً'));
                          }

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: articles.length + 1,
                            itemBuilder: (context, index) {
                              if (index == articles.length) {
                                return const SizedBox(height: 24);
                              }

                              final a = articles[index];

                              return ArticleCard(
                                image: a.imageUrl.isNotEmpty
                                    ? a.imageUrl
                                    : 'images/nekhlawi_icon2.png',
                                title: a.title,
                                description: a.description,
                                onReadMore: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WikiArticleDetailsPage(article: a),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
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