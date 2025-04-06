// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';
import '../models/market_data.dart';

class ApiService {
  // Replace with your FastAPI server URL
  final String baseUrl;

  ApiService({this.baseUrl = 'https://moneymind-dlnl.onrender.com'});

  // Get trending news
  Future<List<NewsArticle>> getTrendingNews({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/trending?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          // Add 'Trending' category if not already present
          if (!item.containsKey('category')) {
            item['category'] = 'Trending';
          }
          return NewsArticle.fromJson(item);
        }).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load trending news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching trending news: $e');
      // Return placeholder data for development
      return _getPlaceholderArticles('Trending');
    }
  }

  // Get news by category
  Future<List<NewsArticle>> getNewsByCategory(String category, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/category/$category?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          // Ensure category is set
          if (!item.containsKey('category')) {
            item['category'] = category;
          }
          return NewsArticle.fromJson(item);
        }).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load $category news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching $category news: $e');
      // Return placeholder data for development
      return _getPlaceholderArticles(category);
    }
  }

  // Search news
  Future<List<NewsArticle>> searchNews(String query, {int limit = 10}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/news/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'country': 'in',
          'language': 'en',
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => NewsArticle.fromJson(item)).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching news: $e');
      // Return placeholder data with search query
      return _getSearchPlaceholderArticles(query);
    }
  }

  // Get market data
  Future<List<MarketTrend>> getMarketData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/markets'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => MarketTrend.fromJson(item)).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load market data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching market data: $e');
      // Return placeholder market data
      return _getPlaceholderMarketTrends();
    }
  }

  // Get personalized news based on user interests
  Future<List<NewsArticle>> getPersonalizedNews(List<String> interests, {int limit = 10}) async {
    try {
      // Simulate personalization by making separate requests and combining the results
      List<NewsArticle> personalizedArticles = [];

      for (String interest in interests.take(3)) { // Limit to top 3 interests
        final articles = await searchNews(interest, limit: 3);
        personalizedArticles.addAll(articles);
      }

      // Deduplicate by title
      final Map<String, NewsArticle> uniqueArticles = {};
      for (var article in personalizedArticles) {
        uniqueArticles[article.title] = article;
      }

      return uniqueArticles.values.toList();
    } catch (e) {
      print('Error fetching personalized news: $e');
      // Return placeholder data for "My Topics"
      return _getPlaceholderArticles('My Topics');
    }
  }

  // Placeholder data for development and testing
  List<NewsArticle> _getPlaceholderArticles(String category) {
    final List<Map<String, dynamic>> placeholderData = [];

    if (category == 'Trending' || category == 'My Topics') {
      placeholderData.addAll([
        {
          'title': 'Donald Trump plans to impose 4% tariff on India',
          'description': 'The new tariff policies could impact Indo-American trade relations.',
          'url': 'https://example.com/news1',
          'urlToImage': 'https://via.placeholder.com/500x300/333/fff?text=News+1',
          'publishedAt': '2025-03-30T10:00:00Z',
          'source': {'name': 'Financial Times'},
          'category': 'Trending',
        },
        {
          'title': 'Modi\'s Response to Tariff Proposal',
          'description': 'Indian Prime Minister addresses concerns about US trade policy.',
          'url': 'https://example.com/news2',
          'urlToImage': 'https://via.placeholder.com/500x300/333/fff?text=News+2',
          'publishedAt': '2025-03-30T11:30:00Z',
          'source': {'name': 'Economic Times'},
          'category': 'Trending',
        },
      ]);
    }

    if (category == 'Investments' || category == 'My Topics') {
      placeholderData.addAll([
        {
          'title': 'Gold Price Forecast: Fed Signals, Stronger Dollar Slow Rally',
          'description': 'Analysis of current gold price trends and future predictions.',
          'url': 'https://example.com/news3',
          'urlToImage': 'https://via.placeholder.com/500x300/DAA520/fff?text=Gold+News',
          'publishedAt': '2025-03-29T14:20:00Z',
          'source': {'name': 'Bloomberg'},
          'category': 'Investments',
        },
        {
          'title': 'Silver Pullback Overdue but Getting Started',
          'description': 'Market analysis suggests silver prices might see a correction soon.',
          'url': 'https://example.com/news4',
          'urlToImage': 'https://via.placeholder.com/500x300/C0C0C0/000?text=Silver+News',
          'publishedAt': '2025-03-29T16:15:00Z',
          'source': {'name': 'Forbes'},
          'category': 'Investments',
        },
      ]);
    }

    // If no specific category matched, provide generic content
    if (placeholderData.isEmpty) {
      placeholderData.addAll([
        {
          'title': 'Financial news for $category',
          'description': 'This is placeholder content for the $category category.',
          'url': 'https://example.com/placeholder',
          'urlToImage': 'https://via.placeholder.com/500x300/333/fff?text=$category',
          'publishedAt': '2025-03-30T12:00:00Z',
          'source': {'name': 'Financial Daily'},
          'category': category,
        },
      ]);
    }

    return placeholderData.map((item) => NewsArticle.fromJson(item)).toList();
  }

  // Placeholder search results
  List<NewsArticle> _getSearchPlaceholderArticles(String query) {
    return [
      {
        'title': 'Search results for: $query',
        'description': 'This is a placeholder search result for "$query".',
        'url': 'https://example.com/search',
        'urlToImage': 'https://via.placeholder.com/500x300/333/fff?text=Search:+$query',
        'publishedAt': DateTime.now().toIso8601String(),
        'source': {'name': 'Search Engine'},
        'category': 'Search',
      },
      {
        'title': 'More information about $query',
        'description': 'Additional details related to your search for "$query".',
        'url': 'https://example.com/search/details',
        'urlToImage': 'https://via.placeholder.com/500x300/333/fff?text=More+About:+$query',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'source': {'name': 'Knowledge Base'},
        'category': 'Search',
      },
    ].map((item) => NewsArticle.fromJson(item)).toList();
  }

  // Placeholder market data
  List<MarketTrend> _getPlaceholderMarketTrends() {
    return [
      MarketTrend(
        title: 'Market Indexes',
        results: [
          MarketResult(
            name: 'S&P 500',
            price: '5,234.18',
            stock: 'SPX',
            priceMovement: PriceMovement(
                movement: 'up',
                value: 12.45,
                percentage: 0.24,
                isPositive: true
            ),
          ),
          MarketResult(
            name: 'Dow Jones',
            price: '39,412.75',
            stock: 'DJI',
            priceMovement: PriceMovement(
                movement: 'up',
                value: 62.21,
                percentage: 0.16,
                isPositive: true
            ),
          ),
          MarketResult(
            name: 'Nasdaq',
            price: '16,384.47',
            stock: 'IXIC',
            priceMovement: PriceMovement(
                movement: 'down',
                value: -45.63,
                percentage: -0.28,
                isPositive: false
            ),
          ),
        ],
      ),
      MarketTrend(
        title: 'Popular Stocks',
        results: [
          MarketResult(
            name: 'Apple Inc.',
            price: '182.52',
            stock: 'AAPL',
            priceMovement: PriceMovement(
                movement: 'up',
                value: 1.23,
                percentage: 0.68,
                isPositive: true
            ),
          ),
          MarketResult(
            name: 'Microsoft',
            price: '416.78',
            stock: 'MSFT',
            priceMovement: PriceMovement(
                movement: 'up',
                value: 2.15,
                percentage: 0.52,
                isPositive: true
            ),
          ),
          MarketResult(
            name: 'Tesla',
            price: '175.33',
            stock: 'TSLA',
            priceMovement: PriceMovement(
                movement: 'down',
                value: -5.47,
                percentage: -3.02,
                isPositive: false
            ),
          ),
        ],
      ),
    ];
  }
}