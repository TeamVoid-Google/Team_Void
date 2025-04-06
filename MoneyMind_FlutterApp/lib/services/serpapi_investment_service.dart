// lib/services/serpapi_investment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class SerpApiInvestmentService {
  final String apiKey;
  final String baseUrl = 'https://serpapi.com/search.json';

  SerpApiInvestmentService({required this.apiKey});

  Future<List<Map<String, dynamic>>> getInvestmentProducts({
    List<String>? categories,
    String? riskTolerance,
    String? timeHorizon,
  }) async {
    // Determine search query based on selected categories and criteria
    String searchQuery = _buildSearchQuery(categories, riskTolerance, timeHorizon);

    try {
      final response = await http.get(
          Uri.parse('$baseUrl?engine=google_finance&q=${Uri.encodeComponent(searchQuery)}&api_key=$apiKey')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Process SerpAPI response and convert to investment products
        return _processFinanceResponse(data, categories?.firstOrNull);
      } else {
        throw Exception('Failed to load from SerpAPI: ${response.statusCode}');
      }
    } catch (e) {
      // Fall back to mock data for demonstration
      return _getMockProducts(categories?.firstOrNull);
    }
  }

  // Alternative method using Google Shopping for more product-centric info
  Future<List<Map<String, dynamic>>> getInvestmentProductsFromShopping({
    List<String>? categories,
    String? riskTolerance,
    String? timeHorizon,
  }) async {
    // Determine search query based on selected categories and criteria
    String searchQuery = _buildSearchQuery(categories, riskTolerance, timeHorizon);

    try {
      final response = await http.get(
          Uri.parse('$baseUrl?engine=google_shopping&q=${Uri.encodeComponent(searchQuery)}&api_key=$apiKey')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['shopping_results'] != null) {
          return _processShoppingResults(data['shopping_results'], categories?.firstOrNull);
        }

        return _getMockProducts(categories?.firstOrNull);
      } else {
        throw Exception('Failed to load from SerpAPI: ${response.statusCode}');
      }
    } catch (e) {
      // Fall back to mock data for demonstration
      return _getMockProducts(categories?.firstOrNull);
    }
  }

  String _buildSearchQuery(List<String>? categories, String? riskTolerance, String? timeHorizon) {
    // Create a search query based on categories and criteria
    String query = 'investment';

    if (categories != null && categories.isNotEmpty) {
      // Map category to appropriate search term
      String categoryTerm = _getCategorySearchTerm(categories.first);
      query = '$categoryTerm investment';
    }

    // Enhance query with risk tolerance if provided
    if (riskTolerance != null) {
      if (riskTolerance == 'Low') {
        query += ' low risk';
      } else if (riskTolerance == 'Moderate') {
        query += ' moderate risk';
      } else if (riskTolerance == 'High') {
        query += ' high growth';
      }
    }

    // Add time horizon context if provided
    if (timeHorizon != null) {
      if (timeHorizon == '1 year') {
        query += ' short term';
      } else if (timeHorizon == '2-3 years') {
        query += ' medium term';
      } else if (timeHorizon == '5+ years') {
        query += ' long term';
      }
    }

    return query;
  }

  String _getCategorySearchTerm(String category) {
    switch (category) {
      case 'ETF': return 'ETF';
      case 'Gold': return 'Gold ETF';
      case 'Silver': return 'Silver ETF';
      case 'Bonds': return 'Bond ETF';
      case 'Stocks': return 'Stock';
      case 'IPO\'s': return 'IPO fund';
      case 'Mutual Funds': return 'Mutual fund';
      case 'Fixed Deposit': return 'Fixed deposit';
      case 'Crypto': return 'Cryptocurrency';
      case 'Insurance': return 'Insurance investment';
      default: return category;
    }
  }

  List<Map<String, dynamic>> _processFinanceResponse(Map<String, dynamic> data, String? category) {
    try {
      List<Map<String, dynamic>> products = [];

      // Process markets data (stocks, indices, currencies)
      if (data['markets'] != null) {
        // Process US markets
        if (data['markets']['us'] != null) {
          for (var item in data['markets']['us']) {
            products.add(_mapFinanceItemToProduct(item, 'ETF', category));
          }
        }

        // Process other market types based on category
        if (category == 'Crypto' && data['markets']['crypto'] != null) {
          for (var item in data['markets']['crypto']) {
            products.add(_mapFinanceItemToProduct(item, 'Crypto', category));
          }
        }

        if ((category == 'Gold' || category == 'Silver') && data['markets']['futures'] != null) {
          for (var item in data['markets']['futures']) {
            if (item['name'].toString().toLowerCase().contains('gold') && category == 'Gold') {
              products.add(_mapFinanceItemToProduct(item, 'Gold', category));
            } else if (item['name'].toString().toLowerCase().contains('silver') && category == 'Silver') {
              products.add(_mapFinanceItemToProduct(item, 'Silver', category));
            }
          }
        }
      }

      // If no results, return mock data
      if (products.isEmpty) {
        return _getMockProducts(category);
      }

      return products;
    } catch (e) {
      // Fall back to mock data on error
      return _getMockProducts(category);
    }
  }

  Map<String, dynamic> _mapFinanceItemToProduct(Map<String, dynamic> item, String defaultType, String? category) {
    // Extract stock symbol
    String symbol = item['stock'] ?? '';
    if (symbol.contains(':')) {
      symbol = symbol.split(':')[0];
    }

    // Determine product type
    String type = defaultType;
    if (category != null) {
      type = category;
    } else {
      String name = (item['name'] ?? '').toLowerCase();
      if (name.contains('etf')) type = 'ETF';
      else if (name.contains('gold')) type = 'Gold';
      else if (name.contains('silver')) type = 'Silver';
      else if (name.contains('bond')) type = 'Bonds';
      else if (name.contains('mutual')) type = 'Mutual Funds';
      else if (name.contains('ipo')) type = 'IPO\'s';
    }

    // Generate product return percentage based on price movement
    String returnValue = '0.0%';
    String riskLevel = 'Moderate';
    String timeHorizon = '2-3 years';

    if (item['price_movement'] != null) {
      double? movement = 0.0;
      if (item['price_movement']['percentage'] != null) {
        movement = _parseDouble(item['price_movement']['percentage'].toString());
      }

      // Set return based on movement (or random if not available)
      if (movement != null) {
        // Annualize the movement (assuming it's daily) with some randomization
        double annualReturn = movement * 252 * (0.8 + (0.4 * (DateTime.now().millisecondsSinceEpoch % 100) / 100));
        returnValue = '${annualReturn.toStringAsFixed(1)}%';

        // Determine risk level based on return volatility
        if (annualReturn.abs() > 15) {
          riskLevel = 'High';
          timeHorizon = '5+ years';
        } else if (annualReturn.abs() > 8) {
          riskLevel = 'Moderate';
          timeHorizon = '2-3 years';
        } else {
          riskLevel = 'Low';
          timeHorizon = '1 year';
        }
      } else {
        // Fallback with random return
        double randomReturn = 5.0 + (DateTime.now().millisecondsSinceEpoch % 100) / 10;
        returnValue = '${randomReturn.toStringAsFixed(1)}%';
      }
    }

    // Create expense ratio based on product type
    String expenseRatio = _getExpenseRatioForType(type);

    // Create minimum investment amount
    String minInvestment = '\$${(10 + (DateTime.now().millisecondsSinceEpoch % 1000) / 10).round()}';
    if (item['price'] != null && item['price'] is num) {
      minInvestment = '\$${item['price']}';
    }

    return {
      'name': item['name'] ?? 'Unknown Investment',
      'symbol': symbol,
      'type': type,
      'return': returnValue,
      'expenseRatio': expenseRatio,
      'minInvestment': minInvestment,
      'assets': '\$${((1 + (DateTime.now().millisecondsSinceEpoch % 1000)) * 10).round()}B',
      'risk': riskLevel,
      'timeHorizon': timeHorizon,
    };
  }

  List<Map<String, dynamic>> _processShoppingResults(List<dynamic> items, String? category) {
    try {
      List<Map<String, dynamic>> products = [];

      for (var item in items) {
        String title = item['title'] ?? '';
        // Filter out non-investment products
        if (_isLikelyInvestmentProduct(title)) {
          products.add(_mapShoppingItemToProduct(item, category));
        }
      }

      // If no valid investment products found, return mock data
      if (products.isEmpty) {
        return _getMockProducts(category);
      }

      return products;
    } catch (e) {
      // Fall back to mock data on error
      return _getMockProducts(category);
    }
  }

  bool _isLikelyInvestmentProduct(String title) {
    title = title.toLowerCase();
    return title.contains('etf') ||
        title.contains('fund') ||
        title.contains('invest') ||
        title.contains('gold') ||
        title.contains('silver') ||
        title.contains('bond') ||
        title.contains('share') ||
        title.contains('stock');
  }

  Map<String, dynamic> _mapShoppingItemToProduct(Map<String, dynamic> item, String? category) {
    String title = item['title'] ?? 'Unknown Investment';

    // Extract symbol if possible
    String symbol = _extractSymbol(title);

    // Determine product type
    String type = _determineType(title, category);

    // Generate product return
    String returnValue = _generateReturnForType(type);

    // Set risk level and time horizon based on type
    Map<String, String> riskAndHorizon = _getRiskAndHorizonForType(type);

    // Create expense ratio based on product type
    String expenseRatio = _getExpenseRatioForType(type);

    // Parse price for minimum investment
    String minInvestment = '\$100';
    if (item['price'] != null) {
      String price = item['price'].toString();
      if (price.startsWith('\$')) {
        minInvestment = price;
      } else {
        minInvestment = '\$$price';
      }
    }

    return {
      'name': title,
      'symbol': symbol,
      'type': type,
      'return': returnValue,
      'expenseRatio': expenseRatio,
      'minInvestment': minInvestment,
      'assets': '\$${((1 + (DateTime.now().millisecondsSinceEpoch % 1000)) * 10).round()}B',
      'risk': riskAndHorizon['risk'] ?? 'Moderate',
      'timeHorizon': riskAndHorizon['timeHorizon'] ?? '2-3 years',
    };
  }

  String _extractSymbol(String title) {
    // Try to extract stock symbol from title
    // Check for pattern like "XYZ" or (XYZ) or [XYZ]
    RegExp symbolRegex = RegExp(r'[(\[]([A-Z]{1,5})[)\]]|(\b[A-Z]{2,5}\b)');
    Match? match = symbolRegex.firstMatch(title);

    if (match != null) {
      return match.group(1) ?? match.group(2) ?? '';
    }

    // Generate random 3-4 letter symbol if none found
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    int len = 3 + (DateTime.now().millisecondsSinceEpoch % 2);
    String randomSymbol = '';
    for (int i = 0; i < len; i++) {
      randomSymbol += chars[DateTime.now().millisecondsSinceEpoch % chars.length];
    }

    return randomSymbol;
  }

  String _determineType(String title, String? category) {
    if (category != null) return category;

    title = title.toLowerCase();

    if (title.contains('etf')) return 'ETF';
    if (title.contains('gold')) return 'Gold';
    if (title.contains('silver')) return 'Silver';
    if (title.contains('bond')) return 'Bonds';
    if (title.contains('mutual fund')) return 'Mutual Funds';
    if (title.contains('ipo')) return 'IPO\'s';
    if (title.contains('crypto') || title.contains('bitcoin')) return 'Crypto';
    if (title.contains('deposit')) return 'Fixed Deposit';
    if (title.contains('insurance')) return 'Insurance';

    return 'Stocks';
  }

  String _generateReturnForType(String type) {
    double baseReturn;
    double randomFactor = (DateTime.now().millisecondsSinceEpoch % 100) / 100 * 4;

    switch (type) {
      case 'ETF': baseReturn = 9.0 + randomFactor; break;
      case 'Gold': baseReturn = 7.0 + randomFactor; break;
      case 'Silver': baseReturn = 6.5 + randomFactor; break;
      case 'Bonds': baseReturn = 4.0 + randomFactor; break;
      case 'Stocks': baseReturn = 10.0 + randomFactor; break;
      case 'IPO\'s': baseReturn = 12.0 + randomFactor; break;
      case 'Mutual Funds': baseReturn = 8.5 + randomFactor; break;
      case 'Fixed Deposit': baseReturn = 3.5 + randomFactor; break;
      case 'Crypto': baseReturn = 15.0 + randomFactor; break;
      case 'Insurance': baseReturn = 5.0 + randomFactor; break;
      default: baseReturn = 8.0 + randomFactor;
    }

    return '${baseReturn.toStringAsFixed(1)}%';
  }

  Map<String, String> _getRiskAndHorizonForType(String type) {
    switch (type) {
      case 'ETF':
        return {'risk': 'Moderate', 'timeHorizon': '5+ years'};
      case 'Gold':
      case 'Silver':
        return {'risk': 'Low', 'timeHorizon': '1 year'};
      case 'Bonds':
        return {'risk': 'Low', 'timeHorizon': '2-3 years'};
      case 'Stocks':
        return {'risk': 'Moderate', 'timeHorizon': '5+ years'};
      case 'IPO\'s':
        return {'risk': 'High', 'timeHorizon': '5+ years'};
      case 'Mutual Funds':
        return {'risk': 'Moderate', 'timeHorizon': '2-3 years'};
      case 'Fixed Deposit':
        return {'risk': 'Low', 'timeHorizon': '1 year'};
      case 'Crypto':
        return {'risk': 'High', 'timeHorizon': '5+ years'};
      case 'Insurance':
        return {'risk': 'Low', 'timeHorizon': '5+ years'};
      default:
        return {'risk': 'Moderate', 'timeHorizon': '2-3 years'};
    }
  }

  String _getExpenseRatioForType(String type) {
    switch (type) {
      case 'ETF': return '0.0${3 + (DateTime.now().millisecondsSinceEpoch % 7)}%';
      case 'Gold': return '0.${20 + (DateTime.now().millisecondsSinceEpoch % 10)}%';
      case 'Silver': return '0.${40 + (DateTime.now().millisecondsSinceEpoch % 15)}%';
      case 'Bonds': return '0.0${4 + (DateTime.now().millisecondsSinceEpoch % 6)}%';
      case 'Stocks': return '0.00%';
      case 'IPO\'s': return '0.${50 + (DateTime.now().millisecondsSinceEpoch % 20)}%';
      case 'Mutual Funds': return '0.${70 + (DateTime.now().millisecondsSinceEpoch % 30)}%';
      case 'Fixed Deposit': return '0.00%';
      case 'Crypto': return '0.${80 + (DateTime.now().millisecondsSinceEpoch % 40)}%';
      case 'Insurance': return '1.${20 + (DateTime.now().millisecondsSinceEpoch % 30)}%';
      default: return '0.25%';
    }
  }

  double? _parseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }

  // Mock data in case API fails or for testing
  List<Map<String, dynamic>> _getMockProducts(String? category) {
    switch (category) {
      case 'ETF':
        return _mockETFProducts();
      case 'Gold':
        return _mockGoldProducts();
      case 'Silver':
        return _mockSilverProducts();
      case 'Bonds':
        return _mockBondProducts();
      case 'IPO\'s':
        return _mockIPOProducts();
      default:
        return _mockMixedProducts();
    }
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
      {
        'name': 'Vanguard Growth ETF',
        'symbol': 'VUG',
        'type': 'ETF',
        'return': '13.5%',
        'expenseRatio': '0.04%',
        'minInvestment': '\$1',
        'assets': '\$180B',
        'risk': 'High',
        'timeHorizon': '5+ years',
      },
      {
        'name': 'Invesco QQQ Trust',
        'symbol': 'QQQ',
        'type': 'ETF',
        'return': '15.2%',
        'expenseRatio': '0.20%',
        'minInvestment': '\$386',
        'assets': '\$222B',
        'risk': 'High',
        'timeHorizon': '5+ years',
      },
      {
        'name': 'Vanguard Dividend Appreciation ETF',
        'symbol': 'VIG',
        'type': 'ETF',
        'return': '9.5%',
        'expenseRatio': '0.06%',
        'minInvestment': '\$172',
        'assets': '\$85B',
        'risk': 'Moderate',
        'timeHorizon': '5+ years',
      },
    ];
  }

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
      },
      {
        'name': 'Aberdeen Standard Physical Gold Shares ETF',
        'symbol': 'SGOL',
        'type': 'Gold',
        'return': '8.3%',
        'expenseRatio': '0.17%',
        'minInvestment': '\$18',
        'assets': '\$2.8B',
        'risk': 'Low',
        'timeHorizon': '1 year',
      },
      {
        'name': 'VanEck Merk Gold Trust',
        'symbol': 'OUNZ',
        'type': 'Gold',
        'return': '8.1%',
        'expenseRatio': '0.25%',
        'minInvestment': '\$18',
        'assets': '\$0.6B',
        'risk': 'Low',
        'timeHorizon': '1 year',
      },
    ];
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
        'name': 'Vanguard Long-Term Bond ETF',
        'symbol': 'BLV',
        'type': 'Bonds',
        'return': '5.1%',
        'expenseRatio': '0.04%',
        'minInvestment': '\$90',
        'assets': '\$5.2B',
        'risk': 'Low',
        'timeHorizon': '2-3 years',
      },
      {
        'name': 'iShares 20+ Year Treasury Bond ETF',
        'symbol': 'TLT',
        'type': 'Bonds',
        'return': '4.8%',
        'expenseRatio': '0.15%',
        'minInvestment': '\$102',
        'assets': '\$37.4B',
        'risk': 'Low',
        'timeHorizon': '2-3 years',
      },
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

  List<Map<String, dynamic>> _mockMixedProducts() {
    return [
      ..._mockETFProducts().take(2).toList(),
      ..._mockGoldProducts().take(2).toList(),
      ..._mockBondProducts().take(2).toList(),
      ..._mockIPOProducts().take(1).toList(),
    ];
  }
}