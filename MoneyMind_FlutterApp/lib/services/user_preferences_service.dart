// lib/services/user_preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserPreferencesService {
  static const String _interestsKey = 'user_news_interests';
  static const String _favoriteArticlesKey = 'favorite_articles';

  // Default interests if none are set
  static final List<String> _defaultInterests = [
    'finance',
    'stocks',
    'market',
    'investment',
    'economy'
  ];

  // Get user interests
  Future<List<String>> getUserInterests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? interestsJson = prefs.getString(_interestsKey);

      if (interestsJson == null) {
        return _defaultInterests;
      }

      List<dynamic> interestsList = jsonDecode(interestsJson);
      return interestsList.map((e) => e.toString()).toList();
    } catch (e) {
      print('Error getting user interests: $e');
      return _defaultInterests;
    }
  }

  // Save user interests
  Future<bool> saveUserInterests(List<String> interests) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_interestsKey, jsonEncode(interests));
    } catch (e) {
      print('Error saving user interests: $e');
      return false;
    }
  }

  // Add a new interest
  Future<bool> addInterest(String interest) async {
    try {
      List<String> currentInterests = await getUserInterests();
      if (!currentInterests.contains(interest)) {
        currentInterests.add(interest);
        return await saveUserInterests(currentInterests);
      }
      return true; // Already exists
    } catch (e) {
      print('Error adding interest: $e');
      return false;
    }
  }

  // Remove an interest
  Future<bool> removeInterest(String interest) async {
    try {
      List<String> currentInterests = await getUserInterests();
      if (currentInterests.contains(interest)) {
        currentInterests.remove(interest);
        return await saveUserInterests(currentInterests);
      }
      return true; // Doesn't exist anyway
    } catch (e) {
      print('Error removing interest: $e');
      return false;
    }
  }

  // Save favorite article
  Future<bool> saveFavoriteArticle(Map<String, dynamic> article) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? favoritesJson = prefs.getString(_favoriteArticlesKey);

      List<dynamic> favorites = [];
      if (favoritesJson != null) {
        favorites = jsonDecode(favoritesJson);
      }

      // Check if article already exists (by URL or title)
      bool exists = favorites.any((element) =>
      (element['url'] != null && element['url'] == article['url']) ||
          element['title'] == article['title']
      );

      if (!exists) {
        favorites.add(article);
        return await prefs.setString(_favoriteArticlesKey, jsonEncode(favorites));
      }

      return true; // Already saved
    } catch (e) {
      print('Error saving favorite article: $e');
      return false;
    }
  }

  // Get favorite articles
  Future<List<Map<String, dynamic>>> getFavoriteArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? favoritesJson = prefs.getString(_favoriteArticlesKey);

      if (favoritesJson == null) {
        return [];
      }

      List<dynamic> favorites = jsonDecode(favoritesJson);
      return favorites.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error getting favorite articles: $e');
      return [];
    }
  }

  // Remove favorite article
  Future<bool> removeFavoriteArticle(String articleUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? favoritesJson = prefs.getString(_favoriteArticlesKey);

      if (favoritesJson == null) {
        return true; // Nothing to remove
      }

      List<dynamic> favorites = jsonDecode(favoritesJson);
      favorites.removeWhere((element) => element['url'] == articleUrl);

      return await prefs.setString(_favoriteArticlesKey, jsonEncode(favorites));
    } catch (e) {
      print('Error removing favorite article: $e');
      return false;
    }
  }
}