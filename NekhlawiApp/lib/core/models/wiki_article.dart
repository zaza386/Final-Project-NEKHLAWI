class WikiArticle {
  final String title;
  final String imagePath;
  final String description;

  WikiArticle({
    required this.title,
    required this.imagePath,
    required this.description,
  });

  factory WikiArticle.fromMap(Map<String, dynamic> map) {
    return WikiArticle(
      title: (map['Title'] ?? '') as String,
      imagePath: (map['ImagePath'] ?? '') as String,
      description: (map['Description'] ?? '') as String,
    );
  }
}
