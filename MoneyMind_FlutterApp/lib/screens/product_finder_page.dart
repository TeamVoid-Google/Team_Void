// lib/screens/product_finder_page.dart
import 'package:flutter/material.dart';
import '../services/backend_investment_service.dart';
import '../utils/server_connection_checker.dart';
import '../widgets/server_status_widget.dart';
import '../widgets/connection_error_widget.dart';
import '../widgets/investment_product_card.dart';
import 'product_comparison_page.dart';
import 'investment_assistant_chat.dart';

class ProductFinderPage extends StatefulWidget {
  const ProductFinderPage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute(
      builder: (context) => const ProductFinderPage(),
    );
  }

  @override
  State<ProductFinderPage> createState() => _ProductFinderPageState();
}

class _ProductFinderPageState extends State<ProductFinderPage> {
  // Services - using BackendInvestmentService to connect to FastAPI
  late final BackendInvestmentService _investmentService;
  bool _isServerConnected = false;

  // Filter selections
  Set<String> selectedCategories = {'ETF', 'Gold', 'Silver', 'IPO\'s', 'Bonds'};
  String selectedRiskTolerance = 'Low';
  String selectedTimeHorizon = '1 year';
  double investmentAmount = 20000;
  String taxFreeGrowth = 'Yes';
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool isFilterExpanded = true;

  // UI state
  bool isCompareMode = false;
  List<Map<String, dynamic>> selectedProductsForComparison = [];
  bool isLoading = false;
  String? errorMessage;

  // Products data
  List<Map<String, dynamic>> _investmentProducts = [];

  // Categories for filtering
  final List<String> _categories = [
    'ETF', 'Stocks', 'Insurance', 'Crypto',
    'Gold', 'Silver', 'IPO\'s', 'Bonds',
    'Mutual Funds', 'Fixed Deposit'
  ];

  // Risk tolerance options
  final List<String> _riskTolerances = ['Low', 'Moderate', 'High'];

  // Time horizon options
  final List<String> _timeHorizons = ['1 year', '2-3 years', '5+ years'];

  @override
  void initState() {
    super.initState();
    // Get the appropriate server URL for the current platform
    final serverUrl = getServerUrl();
    _investmentService = BackendInvestmentService(baseUrl: serverUrl);

    // Initialize the compare mode to false and empty the selection list
    isCompareMode = false;
    selectedProductsForComparison = [];

    // Check if the server is reachable
    checkServerConnection(serverUrl).then((isConnected) {
      setState(() {
        _isServerConnected = isConnected;
      });
      if (isConnected) {
        _fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _goalController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkServerConnection() async {
    print('Checking server connection to: ${_investmentService.baseUrl}');
    try {
      final isConnected = await checkServerConnection(_investmentService.baseUrl);
      print('Server connection result: $isConnected');
      setState(() {
        _isServerConnected = isConnected;
      });
    } catch (e) {
      print('Error checking server connection: $e');
      setState(() {
        _isServerConnected = false;
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Check server connection first
      final isConnected = await checkServerConnection(_investmentService.baseUrl);

      setState(() {
        _isServerConnected = isConnected;
      });

      if (!isConnected) {
        setState(() {
          errorMessage = 'Cannot connect to the investment server. Check your network connection or try again later.';
          isLoading = false;
        });
        return;
      }

      // Clear previous products
      _investmentProducts.clear();

      // Use our backend service to fetch recommendations
      final products = await _investmentService.getRecommendedProducts(
        categories: selectedCategories.toList(),
        riskTolerance: selectedRiskTolerance,
        timeHorizon: selectedTimeHorizon,
        investmentAmount: investmentAmount,
        taxFreeGrowth: taxFreeGrowth == 'Yes',
        goal: _goalController.text.isNotEmpty ? _goalController.text : null,
      );

      setState(() {
        _investmentProducts = products;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        errorMessage = 'Failed to load investment products: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Filter products based on selected criteria and search text
  List<Map<String, dynamic>> get filteredProducts {
    return _investmentProducts.where((product) {
      // Filter by search query if provided
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final name = product['name'].toString().toLowerCase();
        final symbol = (product['symbol'] ?? '').toString().toLowerCase();
        final type = product['type'].toString().toLowerCase();

        if (!name.contains(query) && !symbol.contains(query) && !type.contains(query)) {
          return false;
        }
      }

      // Filter by selected categories
      if (!selectedCategories.contains(product['type'])) {
        return false;
      }

      // Filter by risk tolerance
      if (selectedRiskTolerance != product['risk']) {
        return false;
      }

      // Filter by time horizon
      if (selectedTimeHorizon != product['timeHorizon']) {
        return false;
      }

      return true;
    }).toList();
  }

  void _toggleCompareMode() {
    setState(() {
      isCompareMode = !isCompareMode;

      // Always clear selections when toggling mode to ensure clean state
      selectedProductsForComparison.clear();

      print('Toggled compare mode to: $isCompareMode');
      print('Selection list cleared. Count: ${selectedProductsForComparison.length}');
    });
  }

  // Helper method to check if a product is selected
  bool _isProductSelected(Map<String, dynamic> product) {
    // Get the unique identifier for this product
    final productSymbol = product['symbol'] ?? '';
    if (productSymbol.isEmpty) return false;

    // Check if this product is in the selected list
    return selectedProductsForComparison.any((p) => p['symbol'] == productSymbol);
  }

  // Debug method to print selected products
  void _debugPrintSelectedProducts() {
    print('====== SELECTED PRODUCTS ======');
    print('Total selected: ${selectedProductsForComparison.length}');

    for (int i = 0; i < selectedProductsForComparison.length; i++) {
      final product = selectedProductsForComparison[i];
      print('[$i] ${product['name']} (${product['symbol']})');
    }

    print('==============================');
  }

  void _toggleProductSelection(Map<String, dynamic> product) {
    // Print out the product we're trying to select for debugging
    print('Product selection triggered for:');
    product.forEach((key, value) {
      print('$key: $value');
    });

    // Force a unique identifier - use the product name if symbol is not available
    final String productId = product['symbol'] ?? product['name'] ?? '';

    if (productId.isEmpty) {
      print('Warning: Product has no identifier. Cannot toggle selection.');
      return;
    }

    setState(() {
      try {
        // Check if product is already selected by comparing with the EXACT identifiers
        final int existingIndex = selectedProductsForComparison.indexWhere((p) {
          final String pId = p['symbol'] ?? p['name'] ?? '';
          return pId == productId;
        });

        if (existingIndex >= 0) {
          // Product is already selected, remove it
          print('Removing product: $productId');
          selectedProductsForComparison.removeAt(existingIndex);
        } else {
          // Product is not selected, add it if not at limit
          if (selectedProductsForComparison.length < 3) {
            print('Adding product: $productId');
            // Create a deep copy of the product to avoid reference issues
            final Map<String, dynamic> productCopy = {};
            product.forEach((key, value) {
              productCopy[key] = value;
            });
            selectedProductsForComparison.add(productCopy);
          } else {
            // At selection limit
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You can compare up to 3 products at a time'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }

        // Print the current selection state for debugging
        print('Current selection (${selectedProductsForComparison.length} items):');
        for (var p in selectedProductsForComparison) {
          print('- ${p['symbol'] ?? p['name']}');
        }
      } catch (e) {
        print('Error in selection toggle: $e');
      }
    });
  }

  void _navigateToComparison() {
    if (selectedProductsForComparison.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product to compare'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      ProductComparisonPage.route(
        productsToCompare: selectedProductsForComparison,
      ),
    );
  }

  void _askAIAboutProducts() {
    Navigator.of(context).push(
      InvestmentAssistantChat.route(
        selectedProducts: selectedProductsForComparison.isEmpty
            ? null
            : selectedProductsForComparison,
      ),
    );
  }

  // Widget for category filter chips
  Widget _buildCategoryChip(String category) {
    final isSelected = selectedCategories.contains(category);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedCategories.remove(category);
          } else {
            selectedCategories.add(category);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check, color: Colors.white, size: 16),
              ),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for risk tolerance and time horizon options
  Widget _buildOptionChip(String option, String selectedOption, Function(String) onSelect) {
    final isSelected = option == selectedOption;
    return GestureDetector(
      onTap: () => onSelect(option),
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check, color: Colors.white, size: 16),
              ),
            Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExplanationDialog(Map<String, dynamic> product) {
    setState(() {
      isLoading = true;
    });

    // Use the backend service to get AI-generated explanation
    _investmentService.getAssistantProductExplanation(
      product: product,
    ).then((response) {
      setState(() {
        isLoading = false;
      });

      // Show dialog with the explanation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              _getIconForProductType(product['type']),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product basics
                _buildInfoRow('Symbol', product['symbol'] ?? ''),
                _buildInfoRow('Type', product['type']),
                _buildInfoRow('5Y Return', product['return']),
                _buildInfoRow('Expense Ratio', product['expenseRatio']),
                _buildInfoRow('Min Investment', product['minInvestment']),
                _buildInfoRow('Risk Level', product['risk']),
                _buildInfoRow('Time Horizon', product['timeHorizon']),

                const Divider(height: 24),

                // AI-generated explanation
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Investment Insights',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  response['summary'] ?? "No explanation available.",
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 16),

                // Benefits section
                if (response['benefits'] != null && (response['benefits'] as List).isNotEmpty)
                  Text(
                    'Benefits:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 4),
                ...(response['benefits'] as List? ?? []).map((benefit) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benefit as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                ).toList(),

                const SizedBox(height: 16),

                // Considerations section
                if (response['considerations'] != null && (response['considerations'] as List).isNotEmpty)
                  Text(
                    'Considerations:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 4),
                ...(response['considerations'] as List? ?? []).map((consideration) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              consideration as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                ).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _toggleProductSelection(product);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Compare'),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });

      // Show a simple explanation on error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(product['name']),
          content: Text('Unable to load detailed explanation. Basic information: ${product['type']} with ${product['return']} return and ${product['risk']} risk.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getIconForProductType(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'ETF':
        iconData = Icons.show_chart;
        iconColor = Colors.blue[700]!;
        break;
      case 'Gold':
        iconData = Icons.monetization_on;
        iconColor = Colors.amber[700]!;
        break;
      case 'Silver':
        iconData = Icons.monetization_on;
        iconColor = Colors.blueGrey[400]!;
        break;
      case 'Bonds':
        iconData = Icons.account_balance;
        iconColor = Colors.green[700]!;
        break;
      case 'Stocks':
        iconData = Icons.trending_up;
        iconColor = Colors.purple[700]!;
        break;
      case 'IPO\'s':
        iconData = Icons.rocket_launch;
        iconColor = Colors.red[700]!;
        break;
      case 'Mutual Funds':
        iconData = Icons.pie_chart;
        iconColor = Colors.indigo[700]!;
        break;
      case 'Fixed Deposit':
        iconData = Icons.lock_clock;
        iconColor = Colors.teal[700]!;
        break;
      case 'Crypto':
        iconData = Icons.currency_bitcoin;
        iconColor = Colors.orange[700]!;
        break;
      case 'Insurance':
        iconData = Icons.health_and_safety;
        iconColor = Colors.blue[700]!;
        break;
      default:
        iconData = Icons.attach_money;
        iconColor = Colors.grey[700]!;
    }

    return Icon(
      iconData,
      size: 20,
      color: iconColor,
    );
  }

  void _showActionOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Investment Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.compare_arrows, color: Colors.green),
                ),
                title: const Text('Compare Investments'),
                subtitle: const Text('Select and compare multiple products'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleCompareMode();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chat_bubble_outline, color: Colors.blue[700]),
                ),
                title: const Text('Ask Investment Assistant'),
                subtitle: const Text('Get personalized recommendations'),
                onTap: () {
                  Navigator.pop(context);
                  _askAIAboutProducts();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.refresh, color: Colors.orange[700]),
                ),
                title: const Text('Refresh Products'),
                subtitle: const Text('Get the latest investment data'),
                onTap: () {
                  Navigator.pop(context);
                  _fetchProducts();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Product Finder',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            // Compare mode toggle
            IconButton(
              icon: Icon(
                isCompareMode ? Icons.compare : Icons.compare_arrows,
                color: isCompareMode ? Colors.green : Colors.black,
              ),
              onPressed: _toggleCompareMode,
            ),
            // AI Assistant button
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: Colors.blue[700]),
              onPressed: _askAIAboutProducts,
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                // Focus on search field
                FocusScope.of(context).requestFocus(FocusNode());
                FocusScope.of(context).requestFocus(_searchFocusNode);
              },
            ),
          ],
        ),
        body: Column(
          children: [
          // Server connection status banner
          ServerStatusWidget(
          serverUrl: _investmentService.baseUrl,
          onRetry: () {
            // Retry fetching products when connection is restored
            if (_isServerConnected) {
              _fetchProducts();
            }
          },
        ),

        // Compare mode banner (when active)
            if (isCompareMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.green[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.compare_arrows, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Select up to 3 products to compare (${selectedProductsForComparison.length}/3)',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: selectedProductsForComparison.isEmpty
                            ? null
                            : _navigateToComparison,
                        child: const Text('Compare'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          disabledForegroundColor: Colors.grey[400],
                          disabledBackgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

    // Search bar with AI integration hint
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: TextField(
    controller: _searchController,
    focusNode: _searchFocusNode,
    decoration: InputDecoration(
    hintText: 'Search investment products...',
    hintStyle: TextStyle(color: Colors.grey[400]),
    filled: true,
    fillColor: Colors.grey[200],
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide.none,
    ),
    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
    suffixIcon: IconButton(
    icon: Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
    onPressed: () {
    // Open AI assistant with search query
    Navigator.of(context).push(
    InvestmentAssistantChat.route(
    selectedProducts: null,
    ),
    );
    },
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    ),
    onChanged: (value) {
    // Dynamically filter products based on search text
    setState(() {});
    },
    ),
    ),

    // Results count
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Align(
    alignment: Alignment.centerLeft,
    child: Text(
    '${filteredProducts.length} results matching your criteria',
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    ),
    ),
    ),
    ),

    // Main content - Filters and Products
    Expanded(
    child: isLoading
    ? Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    CircularProgressIndicator(color: Colors.green),
    SizedBox(height: 16),
    Text('Fetching investment products...'),
    ],
    ),
    )
        : errorMessage != null && _investmentProducts.isEmpty
    ? errorMessage!.contains('Cannot connect to the investment server')
    ? ConnectionErrorWidget(
    message: 'Unable to connect to the investment server. This can happen if the server is not running or your network connection is unstable.',
    onRetry: () {
    // First check connection
    checkServerConnection(_investmentService.baseUrl).then((isConnected) {
    setState(() {
    _isServerConnected = isConnected;
    });
    if (isConnected) {
    _fetchProducts();
    }
    });
    },
    )
        : Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
    const SizedBox(height: 16),
    Text(
    errorMessage!,
    style: const TextStyle(fontSize: 16),
    textAlign: TextAlign.center,
    ),
    const SizedBox(height: 24),
    ElevatedButton(
    onPressed: _fetchProducts,
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    ),
    ),
    child: const Text('Try Again'),
    ),
    ],
    ),
    )
        : RefreshIndicator(
    onRefresh: _fetchProducts,
    color: Colors.green,
    child: ListView(
    padding: const EdgeInsets.all(16),
    children: [
    // Filters Card
    Container(
    decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Filters header with toggle
    InkWell(
    onTap: () {
    setState(() {
    isFilterExpanded = !isFilterExpanded;
    });
    },
    child: Row(
    children: [
    Icon(Icons.filter_list, color: Colors.blue[800]),
    const SizedBox(width: 8),
    Text(
    'Filters',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.blue[800],
    ),
    ),
    const Spacer(),
    Icon(
    isFilterExpanded ? Icons.expand_less : Icons.expand_more,
    color: Colors.grey[600],
    ),
    ],
    ),
    ),

    // Expandable filter content
    if (isFilterExpanded) ...[
    const SizedBox(height: 16),

    // Categories
    const Text(
    'Categories',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    ),
    ),
    const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 0,
        children: _categories
            .map((category) => _buildCategoryChip(category))
            .toList(),
      ),
      const SizedBox(height: 16),

      // Risk Tolerance
      const Text(
        'Risk Tolerance',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: _riskTolerances
            .map((risk) => _buildOptionChip(
            risk,
            selectedRiskTolerance,
                (selected) => setState(() => selectedRiskTolerance = selected)))
            .toList(),
      ),
      const SizedBox(height: 16),

      // Time Horizon
      const Text(
        'Time Horizon',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: _timeHorizons
            .map((time) => _buildOptionChip(
            time,
            selectedTimeHorizon,
                (selected) => setState(() => selectedTimeHorizon = selected)))
            .toList(),
      ),
      const SizedBox(height: 16),

      // Investment Amount
      const Text(
        'Investment Amount',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 12),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: Colors.green,
          inactiveTrackColor: Colors.green.withOpacity(0.2),
          thumbColor: Colors.white,
          overlayColor: Colors.green.withOpacity(0.2),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        ),
        child: Column(
          children: [
            Slider(
              value: investmentAmount,
              min: 1000,
              max: 100000,
              divisions: 99,
              onChanged: (value) {
                setState(() {
                  investmentAmount = value;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '\${investmentAmount.round()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Tax free growth
      const Text(
        'Tax Free Growth',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: ['Yes', 'No'].map((option) => _buildOptionChip(
            option,
            taxFreeGrowth,
                (selected) => setState(() => taxFreeGrowth = selected)))
            .toList(),
      ),
      const SizedBox(height: 16),

      // Goal for Investment
      const Text(
        'Goal for Investment',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _goalController,
        decoration: InputDecoration(
          hintText: 'E.g. Retirement, Home, Education...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      const SizedBox(height: 16),

      // Search button
      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: () {
            // Apply filters and search for products
            _fetchProducts();
          },
          icon: const Icon(Icons.search, size: 18,color: Colors.white,),
          label: const Text('Apply Filters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    ],
    ],
    ),
    ),
    ),

      // Product list
      const SizedBox(height: 16),

      if (filteredProducts.isEmpty && !isLoading)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No matching products found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try adjusting your filters or search criteria',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        )
      else
        ...filteredProducts.map((product) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: InvestmentProductCard(
            product: product,
            // Use this improved selection check:
            isSelected: selectedProductsForComparison.any((p) {
              final String productId = product['symbol'] ?? product['name'] ?? '';
              final String pId = p['symbol'] ?? p['name'] ?? '';
              return pId == productId;
            }),
            onSelect: _toggleProductSelection,
            isCompareMode: isCompareMode,
          ),
        )).toList(),
    ],
    ),
    ),
    ),
          ],
        ),
      floatingActionButton: isCompareMode && selectedProductsForComparison.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _navigateToComparison,
        backgroundColor: Colors.green,
        label: const Text('Compare'),
        icon: const Icon(Icons.compare_arrows),
      )
          : FloatingActionButton(
        onPressed: () {
          // Show options menu
          _showActionOptions();
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.more_vert),
      ),
    );
  }
}