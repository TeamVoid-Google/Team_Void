// lib/services/backend_investment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class BackendInvestmentService {
  final String baseUrl;
  static const int timeoutDuration = 15; // seconds

  // API endpoints
  static const String _recommendEndpoint = "/api/investments/recommend";
  static const String _explainEndpoint = "/api/investments/assistant/explain-product";
  static const String _compareEndpoint = "/api/investments/assistant/compare-products";
  static const String _assistantQueryEndpoint = "/api/investments/assistant/query";
  static const String _healthEndpoint = "/api/health";

  BackendInvestmentService({required this.baseUrl});

  /// Check if the server is available
  Future<bool> checkHealth() async {
    try {
      print('Checking health at: $baseUrl$_healthEndpoint');
      final response = await http.get(
        Uri.parse('$baseUrl$_healthEndpoint'),
      ).timeout(const Duration(seconds: 5));

      print('Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Get recommended investment products based on criteria
  /// Get recommended investment products based on criteria
  Future<List<Map<String, dynamic>>> getRecommendedProducts({
    List<String>? categories,
    String? riskTolerance,
    String? timeHorizon,
    double? investmentAmount,
    bool? taxFreeGrowth,
    String? goal,
    String? userId,
  }) async {
    print('Fetching recommended products from: $baseUrl$_recommendEndpoint');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_recommendEndpoint'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'categories': categories ?? [],
          'risk_tolerance': riskTolerance ?? 'Low',
          'time_horizon': timeHorizon ?? '1 year',
          'investment_amount': investmentAmount ?? 10000.0,
          'tax_free_growth': taxFreeGrowth ?? true,
          'goal': goal,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: timeoutDuration));

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        print('Successfully received ${jsonResponse.length} products');
        return jsonResponse.cast<Map<String, dynamic>>();
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recommended products: $e');
      // Return mock data if backend connection fails
      return _getMockProducts(categories?.isNotEmpty == true ? categories!.first : null);
    }
  }

  /// Get AI assistant explanation of a product
  Future<Map<String, dynamic>> getAssistantProductExplanation({
    required Map<String, dynamic> product,
    String? userId,
  }) async {
    print('Fetching product explanation from: $baseUrl$_explainEndpoint');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_explainEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product': product,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: timeoutDuration));

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get product explanation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting product explanation: $e');
      // Return fallback data
      return _generateLocalProductExplanation(product);
    }
  }

  /// Get AI assistant comparison of products
  Future<Map<String, dynamic>> getAssistantProductComparison({
    required List<Map<String, dynamic>> products,
  }) async {
    print('Fetching product comparison from: $baseUrl$_compareEndpoint');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_compareEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'products': products,
        }),
      ).timeout(const Duration(seconds: timeoutDuration));

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get product comparison: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting product comparison: $e');
      // Generate a basic comparison
      return _generateLocalProductComparison(products);
    }
  }

  /// Query the investment assistant
  Future<Map<String, dynamic>> queryAssistant({
    required String question,
    List<Map<String, dynamic>>? products,
    String? userId,
    List<Map<String, String>>? conversationHistory,
  }) async {
    print('Querying assistant at: $baseUrl$_assistantQueryEndpoint');
    try {
      final body = jsonEncode({
        'question': question,
        'products': products,
        'user_id': userId,
        'conversation_history': conversationHistory,
      });

      final response = await http.post(
        Uri.parse('$baseUrl$_assistantQueryEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30)); // Longer timeout for AI processing

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        return result;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to query assistant: ${response.statusCode}');
      }
    } catch (e) {
      print('Error querying assistant: $e');
      // Return fallback response
      return _generateLocalAssistantResponse(question, products);
    }
  }

  /// Generate local product explanation when backend fails
  Map<String, dynamic> _generateLocalProductExplanation(Map<String, dynamic> product) {
    final productType = product['type'] as String? ?? 'investment';
    final name = product['name'] as String? ?? 'This product';
    final returnValue = product['return'] as String? ?? '0%';
    final expenseRatio = product['expenseRatio'] as String? ?? '0%';
    final risk = product['risk'] as String? ?? 'moderate';
    final timeHorizon = product['timeHorizon'] as String? ?? 'medium-term';

    // Generate benefits based on product type
    List<String> benefits = [];
    List<String> considerations = [];

    switch (productType) {
      case 'ETF':
        benefits = [
          'Diversified exposure to a basket of securities',
          'Lower costs with $expenseRatio expense ratio',
          'Trades throughout the day like a stock',
          'Historical return of $returnValue'
        ];
        considerations = [
          'Subject to market volatility',
          'May not be suitable for very short-term investing'
        ];
        break;
      case 'Gold':
      case 'Silver':
        benefits = [
          'Hedge against inflation and market uncertainty',
          'Historical return of $returnValue',
          'Can help diversify your portfolio',
          'Physical asset backing'
        ];
        considerations = [
          'May underperform during strong economic growth',
          'Expense ratio of $expenseRatio'
        ];
        break;
      case 'Bonds':
        benefits = [
          'Generally lower volatility than stocks',
          'Income generation through regular interest payments',
          'Historical return of $returnValue',
          'Capital preservation focus'
        ];
        considerations = [
          'Interest rate risk - bond prices fall when rates rise',
          'May not keep pace with inflation over long periods'
        ];
        break;
      default:
        benefits = [
          'Historical return of $returnValue',
          '$risk risk profile suitable for $timeHorizon investing',
          'Competitive expense ratio of $expenseRatio'
        ];
        considerations = [
          'All investments carry some degree of risk',
          'Past performance does not guarantee future results'
        ];
    }

    String summary = '$name is a $productType investment with a historical return of $returnValue and an expense ratio of $expenseRatio. It has a $risk risk profile suitable for $timeHorizon investing.';

    return {
      'summary': summary,
      'benefits': benefits,
      'considerations': considerations,
      'ideal_for': _getIdealInvestorProfile(product)
    };
  }

  /// Generate local product comparison when backend fails
  Map<String, dynamic> _generateLocalProductComparison(List<Map<String, dynamic>> products) {
    List<String> keyDifferences = [];

    // Generate key differences
    if (products.length >= 2) {
      // Compare returns
      keyDifferences.add('Returns: ${products.map((p) => p['name'] + ': ' + (p['return'] ?? 'N/A')).join(' vs ')}');

      // Compare risk levels
      keyDifferences.add('Risk profiles: ${products.map((p) => p['name'] + ': ' + (p['risk'] ?? 'N/A')).join(' vs ')}');

      // Compare expense ratios
      keyDifferences.add('Fees: ${products.map((p) => p['name'] + ': ' + (p['expenseRatio'] ?? 'N/A')).join(' vs ')}');

      // Compare time horizons
      keyDifferences.add('Recommended time horizon: ${products.map((p) => p['name'] + ': ' + (p['timeHorizon'] ?? 'N/A')).join(' vs ')}');
    }

    // Generate overview
    String overview = 'Comparison of ${products.map((p) => p['name']).join(', ')}. ';
    overview += 'These products represent different ${products.map((p) => p['type']).toSet().join(', ')} options with varying risk levels and return potentials.';

    return {
      'overview': overview,
      'key_differences': keyDifferences,
      'recommendation': 'Consider your investment goals, risk tolerance, and time horizon when choosing between these options.',
      'considerations': [
        'Higher returns typically come with higher risk',
        'Lower expense ratios can significantly impact long-term returns',
        'Match your investment time horizon to the recommended holding period'
      ]
    };
  }

  /// Generate local AI assistant response when backend fails
  Map<String, dynamic> _generateLocalAssistantResponse(String question, List<Map<String, dynamic>>? products) {
    final questionLower = question.toLowerCase();

    // Determine context - comparing products or general question
    if (products != null && products.isNotEmpty) {
      if (questionLower.contains('difference') || questionLower.contains('compare')) {
        return {
          'answer': 'Based on my analysis, the key differences between these investments are in their risk levels, expected returns, and fee structures. ${products[0]['name'] ?? 'The first product'} offers ${products[0]['return'] ?? 'unknown'} return with ${products[0]['risk'] ?? 'unknown'} risk, while ${products.length > 1 ? (products[1]['name'] ?? 'the second product') + ' provides ' + (products[1]['return'] ?? 'unknown') + ' return with ' + (products[1]['risk'] ?? 'unknown') + ' risk.' : ''}',
          'follow_up_questions': [
            'Which is better for long-term growth?',
            'How do the fees compare?',
            'Which has better tax advantages?'
          ],
          'resources': ['Financial Advisor']
        };
      } else if (questionLower.contains('fee') || questionLower.contains('expense')) {
        return {
          'answer': 'Looking at the fee structures: ${products.map((p) => (p['name'] ?? 'Unknown') + ' has an expense ratio of ' + (p['expenseRatio'] ?? 'unknown')).join(', ')}. Lower fees can significantly impact your long-term returns, especially for passive investments held over many years.',
          'follow_up_questions': [
            'How much would fees impact returns over 10 years?',
            'Are these fees competitive for this type of investment?',
            'Are there any hidden fees I should know about?'
          ],
          'resources': ['Financial Advisor', 'Investment Fee Calculator']
        };
      } else if (questionLower.contains('retirement') || questionLower.contains('long term')) {
        return {
          'answer': 'For retirement planning, I\'d consider the time horizon and risk tolerance. ${products.firstWhere((p) => (p['timeHorizon'] ?? '') == '5+ years', orElse: () => products[0])['name'] ?? 'The longer-term product'} is designed for longer-term investing, which aligns well with retirement goals. It offers a good balance of growth potential and manageable risk for a retirement portfolio.',
          'follow_up_questions': [
            'How should I allocate between these investments for retirement?',
            'What percentage of my retirement portfolio should be in these investments?',
            'Are there tax advantages for retirement accounts with these investments?'
          ],
          'resources': ['Retirement Planner', 'Financial Advisor']
        };
      }
    }

    // Default responses for common topics
    if (questionLower.contains('etf') || questionLower.contains('mutual fund')) {
      return {
        'answer': 'ETFs (Exchange Traded Funds) and mutual funds are both investment vehicles that pool money from multiple investors to purchase a diversified portfolio of securities. Key differences:\n\n• Trading: ETFs trade like stocks throughout the day, while mutual funds trade once daily at market close.\n• Fees: ETFs typically have lower expense ratios than mutual funds.\n• Minimum investment: Many ETFs have no minimum investment beyond the share price, while mutual funds may require \$1,000+ to start.\n• Tax efficiency: ETFs are generally more tax-efficient than mutual funds.',
        'follow_up_questions': [
          'Which ETFs have the lowest fees?',
          'Are ETFs better than mutual funds for my taxes?',
          'How do I choose an ETF for my portfolio?'
        ],
        'resources': ['Investment Advisor', 'Tax Professional']
      };
    } else if (questionLower.contains('risk') && questionLower.contains('low')) {
      return {
        'answer': 'For low-risk investments, consider:\n\n• Treasury bonds and TIPS (Treasury Inflation-Protected Securities)\n• High-yield savings accounts\n• Short-term bond ETFs like VTIP or SHY\n• Blue-chip dividend stocks with stable histories\n• Investment-grade corporate bond funds\n\nThese options typically offer modest returns but with significantly less volatility than growth-oriented investments.',
        'follow_up_questions': [
          'How do I balance risk and return?',
          'What are the safest investments right now?',
          'How much risk should I take for retirement?'
        ],
        'resources': ['Financial Advisor']
      };
    } else if (questionLower.contains('retirement') || questionLower.contains('retire')) {
      return {
        'answer': 'For retirement savings, financial experts often recommend saving 15% of your pre-tax income, including any employer match. The exact amount you should save depends on your age, current savings, desired retirement lifestyle, and when you plan to retire. A common guideline is to have 1x your annual salary saved by 30, 3x by 40, 6x by 50, and 8x by 60. Would you like me to help you calculate a more specific target based on your situation?',
        'follow_up_questions': [
          'What\'s the 4% rule for retirement?',
          'Should I max out my 401(k) first?',
          'How do I catch up on retirement savings?'
        ],
        'resources': ['Retirement Planner', 'Financial Advisor']
      };
    }

    // Default response for other questions
    return {
      'answer': 'That\'s a great question about investing. Based on financial best practices, I\'d recommend focusing on a diversified approach that aligns with your risk tolerance and time horizon. Would you like me to provide more specific information or explain any particular aspect of investing in more detail?',
      'follow_up_questions': [
        'How should I diversify my portfolio?',
        'What\'s a good investment strategy for the current market?',
        'How much should I have in emergency savings?'
      ],
      'resources': ['Financial Advisor']
    };
  }

  /// Helper method to get ideal investor profile based on product
  String _getIdealInvestorProfile(Map<String, dynamic> product) {
    final risk = product['risk'] as String? ?? 'Moderate';
    final timeHorizon = product['timeHorizon'] as String? ?? '2-3 years';
    final type = product['type'] as String? ?? 'investment';

    if (risk == 'Low' && timeHorizon == '1 year') {
      return 'Conservative investors looking for short-term stability';
    } else if (risk == 'Low' && timeHorizon == '2-3 years') {
      return 'Income-focused investors who value capital preservation';
    } else if (risk == 'Moderate' && timeHorizon == '2-3 years') {
      return 'Balanced investors seeking moderate growth with reduced volatility';
    } else if (risk == 'Moderate' && timeHorizon == '5+ years') {
      return 'Growth investors with a longer time horizon';
    } else if (risk == 'High') {
      return 'Aggressive investors seeking maximum growth potential';
    }

    return 'General investors seeking exposure to $type';
  }

  // Mock data in case API fails or for testing
  // Add these methods to your BackendInvestmentService class

  List<Map<String, dynamic>> _getMockProducts(String? category) {
    switch (category?.toLowerCase()) {
      case 'silver':
        return _mockSilverProducts();
      case 'bonds':
        return _mockBondProducts();
      case 'ipos':
        return _mockIPOProducts();
      case 'etf':
        return _mockETFProducts();
      case 'gold':
        return _mockGoldProducts();
      case 'mixed':
        return _mockMixedProducts();
      default:
      // Return a mix as fallback
        return _mockMixedProducts();
    }
  }


  List<Map<String, dynamic>> _mockSilverProducts() {
    return [
      {
        'name': 'iShares Silver Trust',
        'symbol': 'SLV',
        'type': 'Silver',
        'return': '7.2%',
        'expenseRatio': '0.5%',
        'minInvestment': '\$20',
        'assets': '\$12.8B',
        'risk': 'Low',
        'timeHorizon': '1 year',
      },
      {
        'name': 'Aberdeen Standard Physical Silver Shares ETF',
        'symbol': 'SIVR',
        'type': 'Silver',
        'return': '7.3%',
        'expenseRatio': '0.30%',
        'minInvestment': '\$23',
        'assets': '\$1.1B',
        'risk': 'Low',
        'timeHorizon': '1 year',
      },
      {
        'name': 'ProShares Ultra Silver',
        'symbol': 'AGQ',
        'type': 'Silver',
        'return': '9.6%',
        'expenseRatio': '0.95%',
        'minInvestment': '\$30',
        'assets': '\$0.5B',
        'risk': 'High',
        'timeHorizon': '1 year',
      },
    ];
  }

  List<Map<String, dynamic>> _mockBondProducts() {
    return [
      {
        'name': 'Vanguard Total Bond Market ETF',
        'symbol': 'BND',
        'type': 'Bonds',
        'return': '3.5%',
        'expenseRatio': '0.035%',
        'minInvestment': '\$83',
        'assets': '\$96.8B',
        'risk': 'Low',
        'timeHorizon': '2-3 years',
      },
      {
        'name': 'iShares Core U.S. Aggregate Bond ETF',
        'symbol': 'AGG',
        'type': 'Bonds',
        'return': '3.6%',
        'expenseRatio': '0.03%',
        'minInvestment': '\$108',
        'assets': '\$90.1B',
        'risk': 'Low',
        'timeHorizon': '2-3 years',
      },
      {
        'name': 'Vanguard Long-Term Bond ETF',
        'symbol': 'BLV',
        'type': 'Bonds',
        'return': '5.1%',
        'expenseRatio': '0.04%',
        'minInvestment': '\$90',
        'assets': '\$5.2B',
        'risk': 'Low',
        'timeHorizon': '2-3 years',
      }
    ];
  }

  List<Map<String, dynamic>> _mockIPOProducts() {
    return [
      {
        'name': 'Renaissance IPO ETF',
        'symbol': 'IPO',
        'type': 'IPO\'s',
        'return': '12.8%',
        'expenseRatio': '0.6%',
        'minInvestment': '\$35',
        'assets': '\$320M',
        'risk': 'High',
        'timeHorizon': '5+ years',
      },
      {
        'name': 'First Trust US Equity Opportunities ETF',
        'symbol': 'FPX',
        'type': 'IPO\'s',
        'return': '11.5%',
        'expenseRatio': '0.58%',
        'minInvestment': '\$102',
        'assets': '\$1.2B',
        'risk': 'High',
        'timeHorizon': '5+ years',
      },
      {
        'name': 'Renaissance International IPO ETF',
        'symbol': 'IPOS',
        'type': 'IPO\'s',
        'return': '10.2%',
        'expenseRatio': '0.8%',
        'minInvestment': '\$24',
        'assets': '\$43M',
        'risk': 'High',
        'timeHorizon': '5+ years',
      },
    ];
  }

  List<Map<String, dynamic>> _mockETFProducts() {
    return [
      {
        'name': 'Vanguard Total Stock Market ETF',
        'symbol': 'VTI',
        'type': 'ETF',
        'return': '11.2%',
        'expenseRatio': '0.03%',
        'minInvestment': '\$1',
        'assets': '\$1.3T',
        'risk': 'Moderate',
        'timeHorizon': '5+ years',
      },
      {
        'name': 'iShares Core S&P 500 ETF',
        'symbol': 'IVV',
        'type': 'ETF',
        'return': '10.8%',
        'expenseRatio': '0.03%',
        'minInvestment': '\$1',
        'assets': '\$350B',
        'risk': 'Moderate',
        'timeHorizon': '5+ years',
      },
      // More mock products as previously defined...
    ];
  }

  // The rest of the mock data methods remain the same
  // (mockGoldProducts, mockSilverProducts, mockBondProducts, etc.)

  // For brevity, I'll include just one more example
  List<Map<String, dynamic>> _mockGoldProducts() {
    return [
      {
        'name': 'iShares Gold Trust',
        'symbol': 'IAU',
        'type': 'Gold',
        'return': '8.4%',
        'expenseRatio': '0.25%',
        'minInvestment': '\$15',
        'assets': '\$28.5B',
        'risk': 'Low',
        'timeHorizon': '1 year',
      },
      {
        'name': 'SPDR Gold Shares',
        'symbol': 'GLD',
        'type': 'Gold',
        'return': '8.2%',
        'expenseRatio': '0.40%',
        'minInvestment': '\$173',
        'assets': '\$57.3B',
        'risk': 'Low',
        'timeHorizon': '1 year',
      }
    ];
  }

  List<Map<String, dynamic>> _mockMixedProducts() {
    // Return a mix of different product types
    return [
      {
        'name': 'Vanguard Total Stock Market ETF',
        'symbol': 'VTI',
        'type': 'ETF',
        'return': '11.2%',
        'expenseRatio': '0.03%',
        'minInvestment': '\$1',
        'risk': 'Moderate',
        'timeHorizon': '5+ years',
      },
      {
        'name': 'iShares Gold Trust',
        'symbol': 'IAU',
        'type': 'Gold',
        'return': '8.4%',
        'expenseRatio': '0.25%',
        'minInvestment': '\$15',
        'risk': 'Low',
        'timeHorizon': '1 year',
      },
      {
        'name': 'Vanguard Total Bond Market ETF',
        'symbol': 'BND',
        'type': 'Bonds',
        'return': '3.5%',
        'expenseRatio': '0.035%',
        'minInvestment': '\$83',
        'risk': 'Low',
        'timeHorizon': '2-3 years',
      }
    ];
  }
}