import 'package:supabase_flutter/supabase_flutter.dart';

class WikiArticleItem {
  final String title;
  final String description;
  final String imageUrl;

  final String content;
  final String category;
  final String authorName;
  final DateTime? createdAt;

  WikiArticleItem({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.content,
    required this.category,
    required this.authorName,
    required this.createdAt,
  });

  factory WikiArticleItem.fromMap(
    Map<String, dynamic> map, {
    required String bucketName,
  }) {
    final client = Supabase.instance.client;

    final title = (map['Title'] ?? '') as String;
    final description = (map['Description'] ?? '') as String;

    final path = (map['ImagePath'] ?? '') as String;
    final imageUrl =
        path.trim().isEmpty ? '' : client.storage.from(bucketName).getPublicUrl(path);

    final content = (map['Content'] ?? '') as String;
    final category = (map['Category'] ?? '') as String;
    final authorName = (map['AuthorName'] ?? '') as String;

    DateTime? createdAt;
    final raw = map['CreatedAt'];
    if (raw != null) {
      try {
        createdAt = DateTime.parse(raw.toString());
      } catch (_) {
        createdAt = null;
      }
    }

    return WikiArticleItem(
      title: title,
      description: description,
      imageUrl: imageUrl,
      content: content,
      category: category,
      authorName: authorName,
      createdAt: createdAt,
    );
  }
}

class WikiArticleRepo {
  final SupabaseClient _client = Supabase.instance.client;

 
  final String bucketName = 'pic';

  Future<List<WikiArticleItem>> fetchArticles({String? query}) async {
    final q = (query ?? '').trim();

    final base = _client.from('WikiArticle').select(
          'Title, ImagePath, Description, Content, Category, AuthorName, CreatedAt',
        );

    final res = q.isEmpty
        ? await base.order('CreatedAt', ascending: false)
        : await base
            .or('Title.ilike.%$q%,Description.ilike.%$q%,Category.ilike.%$q%')
            .order('CreatedAt', ascending: false);

    return (res as List)
        .map((e) => WikiArticleItem.fromMap(e as Map<String, dynamic>, bucketName: bucketName))
        .toList();
  }

  Future<WikiArticleItem?> fetchByTitle(String title) async {
    final res = await _client
        .from('WikiArticle')
        .select('Title, ImagePath, Description, Content, Category, AuthorName, CreatedAt')
        .eq('Title', title)
        .limit(1);

    final list = (res as List);
    if (list.isEmpty) return null;

    return WikiArticleItem.fromMap(list.first as Map<String, dynamic>, bucketName: bucketName);
  }
}