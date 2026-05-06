import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:nekhlawi_app/pages/booking_page.dart';
import 'package:nekhlawi_app/pages/wiki_article_details_page.dart';
import 'package:nekhlawi_app/core/data/wiki_article_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({super.key});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: SearchAnchor(
        builder: (context, controller) {
          return SearchBar(
            controller: controller,
            hintText: 'ابحث عن أمراض، خبراء، أو مقالات...',
            leading: const Icon(Icons.search, color: Colors.grey),
            backgroundColor: WidgetStateProperty.all(Colors.grey.shade100),
            elevation: WidgetStateProperty.all(0),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onTap: () => controller.openView(),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) {
                _debounce!.cancel();
              }

              _debounce = Timer(const Duration(milliseconds: 400), () {
                if (value.trim().length >= 3) {
                  controller.openView();
                }
              });
            },
          );
        },

        suggestionsBuilder: (context, controller) async {
          final query = controller.text.trim();

          if (query.isEmpty || query.length < 2) {
            return [];
          }

          final List<Widget> suggestions = [];

          try {
            final bySpec = await supabase
                .from('ExpertProfile')
                .select(
                  'ExpertID, Specialization, User ( Name, ProfilePicturePath )',
                )
                .ilike('Specialization', '%$query%');

            final byName = await supabase
                .from('ExpertProfile')
                .select(
                  'ExpertID, Specialization, User!inner ( Name, ProfilePicturePath )',
                )
                .ilike('User.Name', '%$query%');

            final seenIds = <String>{};
            final mergedExperts = <Map<String, dynamic>>[];

            for (final e in [...bySpec, ...byName]) {
              final id = e['ExpertID'].toString();

              if (seenIds.add(id)) {
                mergedExperts.add(e);
              }
            }

            final wikiRepo = WikiArticleRepo();

            final articleItems = await wikiRepo.fetchArticles(query: query);

            if (mergedExperts.isNotEmpty) {
              suggestions.add(
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'الخبراء',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
              );

              for (final expert in mergedExperts) {
                final userData = expert['User'];
                final userMap = (userData is List) ? userData.first : userData;

                suggestions.add(
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.header,
                      backgroundImage:
                          userMap['ProfilePicturePath'] != null &&
                              userMap['ProfilePicturePath']!.isNotEmpty
                          ? ResizeImage(
                              NetworkImage(
                                supabase.storage
                                    .from('pic')
                                    .getPublicUrl(
                                      userMap['ProfilePicturePath']!,
                                    ),
                              ),
                              width: 80,
                              height: 80,
                            )
                          : const AssetImage('images/nekhlawi_icon.png'),

                      child: userMap['ProfilePicturePath'] == null
                          ? const Icon(Icons.person, color: AppColors.darkBrown)
                          : null,
                    ),

                    title: Text(userMap['Name'] ?? 'خبير'),

                    subtitle: Text(expert['Specialization'] ?? ''),

                    trailing: const Icon(
                      Icons.arrow_back_ios,
                      size: 14,
                      color: AppColors.darkBrown,
                    ),

                    onTap: () {
                      controller.closeView('');

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingPage(
                            expertId: expert['ExpertID'].toString(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            }

            if (articleItems.isNotEmpty) {
              suggestions.add(
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'المقالات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
              );

              for (final article in articleItems) {
                suggestions.add(
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.header,
                      child: Icon(
                        Icons.article_outlined,
                        color: AppColors.darkBrown,
                      ),
                    ),

                    title: Text(article.title),

                    subtitle: Text(
                      article.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    trailing: const Icon(
                      Icons.arrow_back_ios,
                      size: 14,
                      color: AppColors.darkBrown,
                    ),

                    onTap: () {
                      controller.closeView('');

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WikiArticleDetailsPage(article: article),
                        ),
                      );
                    },
                  ),
                );
              }
            }

            if (suggestions.isEmpty) {
              suggestions.add(
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'لا توجد نتائج مطابقة لبحثك',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('Search error: $e');

            suggestions.add(const ListTile(title: Text('حدث خطأ في البحث')));
          }

          return suggestions;
        },
      ),
    );
  }
}
