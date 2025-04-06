// lib/models/news_article.dart
class NewsArticle {
  final String title;
  final String? description;
  final String? url;
  final String? urlToImage;
  final String? publishedAt;
  final Map<String, dynamic>? source;
  final String category;

  NewsArticle({
    required this.title,
    this.description,
    this.url,
    this.urlToImage,
    this.publishedAt,
    this.source,
    required this.category,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? json['snippet'],
      url: json['url'],
      urlToImage: json['urlToImage'],
      publishedAt: json['publishedAt'],
      source: json['source'],
      category: json['category'] ?? 'Uncategorized',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt,
      'source': source,
      'category': category,
    };
  }
}