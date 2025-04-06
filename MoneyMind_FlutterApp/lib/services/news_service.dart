// lib/services/news_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';
import '../models/market_data.dart';

class NewsService {
  // Base URL for your API - already configured for your Render deployment
  final String baseUrl;

  NewsService({this.baseUrl = 'https://moneymind-dlnl.onrender.com'});

  // Get trending news
  Future<List<NewsArticle>> getTrendingNews({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/trending?limit=$limit'),
        headers: {'Accept': 'application/json'},
      );

      print('Trending news API response: ${response.statusCode}');
      print('Response body: ${response.body.substring(0, min(100, response.body.length))}...');

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
      // Return placeholder data when API fails
      return _getDummyArticles('Trending');
    }
  }

  // Get news by category
  Future<List<NewsArticle>> getNewsByCategory(String category, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/category/$category?limit=$limit'),
        headers: {'Accept': 'application/json'},
      );

      print('Category $category news API response: ${response.statusCode}');

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
      // Return placeholder data when API fails
      return _getDummyArticles(category);
    }
  }

  // Search for specific news
  Future<List<NewsArticle>> searchNews(String query, {int limit = 10}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/news/search'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          'query': query,
          'country': 'in',
          'language': 'en',
          'limit': limit,
        }),
      );

      print('Search news API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => NewsArticle.fromJson(item)).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching news: $e');
      // Return placeholder data when API fails
      return _getSearchPlaceholderArticles(query);
    }
  }

  // Get market data
  Future<List<MarketTrend>> getMarketData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/markets'),
        headers: {'Accept': 'application/json'},
      );

      print('Market data API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => MarketTrend.fromJson(item)).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load market data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching market data: $e');
      // Return placeholder market data when API fails
      return _getDummyMarketTrends();
    }
  }

  // Get personalized news based on user interests
  Future<List<NewsArticle>> getPersonalizedNews(List<String> interests, {int limit = 10}) async {
    try {
      // For now, we'll simulate personalization by combining search results
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
      // Return placeholder data when API fails
      return _getDummyArticles('My Topics');
    }
  }

  // Dummy data method for development/testing when API isn't available
  List<NewsArticle> _getDummyArticles(String category) {
    final List<Map<String, dynamic>> dummyData = [
      {
        'title': 'Donald Trump plans to impose 4% tariff on India',
        'urlToImage': 'https://via.placeholder.com/500x300/333/fff?text=News+1',
        'description': 'The new tariff policies could impact Indo-American trade relations.',
        'category': 'Trending',
        'publishedAt': '2025-03-30T10:00:00Z',
        'url': 'https://example.com/news1',
        'source': {'name': 'Financial Times'}
      },
      {
        'title': 'Modi\'s Response to Tariff Proposal',
        'urlToImage': 'https://via.placeholder.com/500x300/333/fff?text=News+2',
        'description': 'Indian Prime Minister addresses concerns about US trade policy.',
        'category': 'Trending',
        'publishedAt': '2025-03-30T11:30:00Z',
        'url': 'https://example.com/news2',
        'source': {'name': 'Economic Times'}
      },
      {
        'title': 'Gold Price Forecast: Fed Signals, Stronger Dollar Slow Rally',
        'urlToImage': 'https://via.placeholder.com/500x300/DAA520/fff?text=Gold+News',
        'description': 'Analysis of current gold price trends and future predictions.',
        'category': 'Investments',
        'publishedAt': '2025-03-29T14:20:00Z',
        'url': 'https://example.com/news3',
        'source': {'name': 'Bloomberg'}
      },
      {
        'title': 'Silver Pullback Overdue but Getting Started',
        'urlToImage': 'https://via.placeholder.com/500x300/C0C0C0/000?text=Silver+News',
        'description': 'Market analysis suggests silver prices might see a correction soon.',
        'category': 'Investments',
        'publishedAt': '2025-03-29T16:15:00Z',
        'url': 'https://example.com/news4',
        'source': {'name': 'Forbes'}
      },
      {
        'title': 'New Fintech Startup Raises 50M in Series A',
        'urlToImage': 'https://via.placeholder.com/500x300/333/fff?text=Startup+News',
        'description': 'Promising financial technology startup secures major funding round.',
        'category': 'Startups',
        'publishedAt': '2025-03-28T09:45:00Z',
        'url': 'https://example.com/news5',
        'source': {'name': 'TechCrunch'}
      },
      {
        'title': 'Local Economy Shows Signs of Recovery',
        'urlToImage': 'https://via.placeholder.com/500x300/333/fff?text=Local+News',
        'description': 'Regional economic indicators point to post-pandemic recovery.',
        'category': 'Local News',
        'publishedAt': '2025-03-28T08:30:00Z',
        'url': 'https://example.com/news6',
        'source': {'name': 'Local Herald'}
      },
      {
        'title': 'Fact Check: Are Cryptocurrency Investments Really Safe?',
        'urlToImage': 'https://via.placeholder.com/500x300/333/fff?text=Fact+Check',
        'description': 'Examining the reality behind cryptocurrency investment safety claims.',
        'category': 'Fact Check',
        'publishedAt': '2025-03-27T13:10:00Z',
        'url': 'https://example.com/news7',
        'source': {'name': 'Reuters'}
      },
    ];

    return dummyData
        .where((article) => category == 'Trending' || category == 'My Topics'
        ? true  // Return all articles for 'Trending' or 'My Topics'
        : article['category'] == category)
        .map((article) => NewsArticle.fromJson(article))
        .toList();
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

  // Dummy market data
  List<MarketTrend> _getDummyMarketTrends() {
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

// Helper function to get the minimum of two integers
int min(int a, int b) {
  return a < b ? a : b;
}