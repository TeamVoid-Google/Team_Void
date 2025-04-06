// lib/services/news_ai_agent.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

class NewsAIAgent {
  // Replace with your actual API endpoint
  final String apiEndpoint = 'https://api.marketstack.com/v2';
  final String apiKey = '3b082b48ebb70c958db834679530c2f2';

  // Get personalized news recommendations
  Future<List<NewsArticle>> getPersonalizedRecommendations(List<String> userInterests, {int limit = 10}) async {
    try {
      final response = await http.post(
        Uri.parse('$apiEndpoint/personalize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'interests': userInterests,
          'limit': limit
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> articles = data['articles'] ?? [];

        return articles.map((article) {
          // Add the category based on the best matching interest
          String bestCategory = _findBestMatchingCategory(article['title'], userInterests);
          article['category'] = bestCategory;

          return NewsArticle.fromJson(article);
        }).toList();
      } else {
        throw Exception('Failed to get personalized news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in AI personalization: $e');
      return []; // Return empty list on error
    }
  }

  // Get sentiment analysis for a news article
  Future<Map<String, dynamic>> getArticleSentiment(String articleText) async {
    try {
      final response = await http.post(
        Uri.parse('$apiEndpoint/sentiment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': articleText,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze sentiment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in sentiment analysis: $e');
      return {
        'sentiment': 'neutral',
        'confidence': 0.5,
      };
    }
  }

  // Get news summary
  Future<String> getArticleSummary(String articleText) async {
    try {
      final response = await http.post(
        Uri.parse('$apiEndpoint/summarize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': articleText,
          'max_length': 100, // Customize as needed
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['summary'] ?? 'No summary available.';
      } else {
        throw Exception('Failed to summarize article: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in article summarization: $e');
      return 'Summary not available.';
    }
  }

  // Search for specific news with AI enhancement
  Future<List<NewsArticle>> aiEnhancedSearch(String query, List<String> userInterests) async {
    try {
      final response = await http.post(
        Uri.parse('$apiEndpoint/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'interests': userInterests,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> articles = data['articles'] ?? [];

        return articles.map((article) {
          String category = article['category'] ?? 'Uncategorized';
          article['category'] = category;

          return NewsArticle.fromJson(article);
        }).toList();
      } else {
        throw Exception('Failed in AI-enhanced search: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in AI-enhanced search: $e');
      return []; // Return empty list on error
    }
  }

  // Helper method to find the best matching category based on title text
  String _findBestMatchingCategory(String title, List<String> interests) {
    // This is a simplistic approach
    // A real implementation would use more sophisticated NLP matching

    title = title.toLowerCase();
    String bestMatch = 'Trending'; // Default

    for (String interest in interests) {
      if (title.contains(interest.toLowerCase())) {
        bestMatch = interest;
        break;
      }
    }

    // Map common finance terms to categories
    Map<String, String> termToCategory = {
      'stock': 'Investments',
      'invest': 'Investments',
      'market': 'Market & Economy',
      'economy': 'Market & Economy',
      'finance': 'Personal Finance',
      'saving': 'Personal Finance',
      'startup': 'Startups',
      'company': 'Business & Fintech',
      'business': 'Business & Fintech',
      'crypto': 'Investments',
      'bitcoin': 'Investments',
      'gold': 'Investments',
      'silver': 'Investments',
    };

    for (var entry in termToCategory.entries) {
      if (title.contains(entry.key)) {
        return entry.value;
      }
    }

    return bestMatch;
  }
}