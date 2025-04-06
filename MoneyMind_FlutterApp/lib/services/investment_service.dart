// lib/services/investment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class InvestmentService {
  // Base URL for your API
  final String baseUrl;

  // API endpoints
  static const String _recommendEndpoint = "/api/investments/recommend";
  static const String _explainEndpoint = "/api/investments/products/explain";
  static const String _compareEndpoint = "/api/investments/compare";
  static const String _assistantQueryEndpoint = "/api/investments/assistant/query";
  static const String _assistantExplainEndpoint = "/api/investments/assistant/explain-product";
  static const String _assistantCompareEndpoint = "/api/investments/assistant/compare-products";

  InvestmentService({this.baseUrl = 'https://moneymind-dlnl.onrender.com'});

  /// Get recommended investment products based on criteria
  Future<List<Map<String, dynamic>>> getRecommendations({
    List<String>? categories,
    String? riskTolerance,
    String? timeHorizon,
    double? investmentAmount,
    bool? taxFreeGrowth,
    String? goal,
    String? userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$_recommendEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'categories': categories ?? [],
        'risk_tolerance': riskTolerance ?? 'Low',
        'time_horizon': timeHorizon ?? '1 year',
        'investment_amount': investmentAmount ?? 10000.0,
        'tax_free_growth': taxFreeGrowth ?? true,
        'goal': goal,
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get recommendations: ${response.body}');
    }
  }

  /// Get explanation of why a product is beneficial
  Future<String> getProductExplanation({
    required String productId,
    String? userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$_explainEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'product_id': productId,
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse['explanation'] as String;
    } else {
      throw Exception('Failed to get product explanation: ${response.body}');
    }
  }

  /// Compare multiple investment products
  Future<Map<String, dynamic>> compareProducts({
    required List<String> productIds,
    List<String>? factors,
    String? userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$_compareEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'product_ids': productIds,
        'factors': factors ?? ['return', 'risk', 'fees', 'liquidity', 'tax_efficiency'],
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to compare products: ${response.body}');
    }
  }

  /// Query the investment assistant
  Future<Map<String, dynamic>> queryAssistant({
    required String question,
    List<Map<String, dynamic>>? products,
    String? userId,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$_assistantQueryEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': question,
        'products': products,
        'user_id': userId,
        'conversation_history': conversationHistory,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to query assistant: ${response.body}');
    }
  }

  /// Get AI assistant explanation of a product
  Future<Map<String, dynamic>> getAssistantProductExplanation({
    required Map<String, dynamic> product,
    String? userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$_assistantExplainEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'product': product,
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get assistant product explanation: ${response.body}');
    }
  }

  /// Get AI assistant comparison of products
  Future<Map<String, dynamic>> getAssistantProductComparison({
    required List<Map<String, dynamic>> products,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$_assistantCompareEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'products': products,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get assistant product comparison: ${response.body}');
    }
  }
}