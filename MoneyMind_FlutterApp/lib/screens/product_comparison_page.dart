// lib/screens/product_comparison_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProductComparisonPage extends StatefulWidget {
  final List<Map<String, dynamic>> productsToCompare;

  const ProductComparisonPage({
    Key? key,
    required this.productsToCompare,
  }) : super(key: key);

  static Route route({required List<Map<String, dynamic>> productsToCompare}) {
    return MaterialPageRoute(
      builder: (context) => ProductComparisonPage(productsToCompare: productsToCompare),
    );
  }

  @override
  State<ProductComparisonPage> createState() => _ProductComparisonPageState();
}

class _ProductComparisonPageState extends State<ProductComparisonPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  Map<String, dynamic>? comparisonData;

  // Comparison categories
  final List<String> _comparisonCategories = [
    'Overview',
    'Performance',
    'Risk',
    'Fees',
    'AI Analysis'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _comparisonCategories.length, vsync: this);
    _fetchComparisonData();
  }

  Future<void> _fetchComparisonData() async {
    // In a real app, this would call your backend API
    await Future.delayed(const Duration(seconds: 1));

    // Simulate API response with comparison data
    setState(() {
      comparisonData = {
        'performance': {
          'historical_returns': widget.productsToCompare.map((product) {
            // Convert percentage strings to doubles for chart
            final returnStr = product['return'] as String;
            final returnValue = double.tryParse(returnStr.replaceAll('%', '')) ?? 0.0;
            return {
              'name': product['name'],
              'value': returnValue,
              'color': _getProductColor(widget.productsToCompare.indexOf(product)),
            };
          }).toList(),
        },
        'risk_metrics': {
          'volatility': widget.productsToCompare.map((product) {
            final riskLevel = product['risk'] as String;
            double volatility = 0.0;
            if (riskLevel == 'Low') volatility = 5.0;
            else if (riskLevel == 'Moderate') volatility = 12.0;
            else if (riskLevel == 'High') volatility = 18.0;

            return {
              'name': product['name'],
              'value': volatility,
              'color': _getProductColor(widget.productsToCompare.indexOf(product)),
            };
          }).toList(),
        },
        'fees': {
          'expense_ratios': widget.productsToCompare.map((product) {
            final expenseStr = product['expenseRatio'] as String;
            final expenseValue = double.tryParse(expenseStr.replaceAll('%', '')) ?? 0.0;
            return {
              'name': product['name'],
              'value': expenseValue,
              'color': _getProductColor(widget.productsToCompare.indexOf(product)),
            };
          }).toList(),
        },
        'ai_analysis': {
          'recommendations': widget.productsToCompare.map((product) {
            return {
              'name': product['name'],
              'strengths': [
                '${product['return']} historical return',
                'Suitable for ${product['timeHorizon']} investment',
                '${product['risk']} risk profile',
              ],
              'weaknesses': [
                '${product['expenseRatio']} expense ratio',
                'Minimum investment of ${product['minInvestment']}',
              ],
              'ideal_for': _getIdealInvestorProfile(product),
            };
          }).toList(),
        }
      };
      isLoading = false;
    });
  }

  String _getIdealInvestorProfile(Map<String, dynamic> product) {
    final risk = product['risk'] as String;
    final timeHorizon = product['timeHorizon'] as String;
    final type = product['type'] as String;

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

  Color _getProductColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Compare Products',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.green,
          tabs: _comparisonCategories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPerformanceTab(),
          _buildRiskTab(),
          _buildFeesTab(),
          _buildAIAnalysisTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show a dialog with sharing options or add to portfolio
          _showActionDialog();
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Overview tab - side-by-side comparison of key metrics
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Metrics Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Product cards in a horizontal row
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.productsToCompare.length,
              itemBuilder: (context, index) {
                final product = widget.productsToCompare[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getProductColor(index).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getProductColor(index).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product['type'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Return: ${product['return']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Comparison table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildComparisonTableRow(
                  'Type',
                  widget.productsToCompare.map((p) => p['type'] as String).toList(),
                  isHeader: true,
                ),
                _buildComparisonTableRow(
                  'Risk Level',
                  widget.productsToCompare.map((p) => p['risk'] as String).toList(),
                ),
                _buildComparisonTableRow(
                  'Time Horizon',
                  widget.productsToCompare.map((p) => p['timeHorizon'] as String).toList(),
                ),
                _buildComparisonTableRow(
                  'Return',
                  widget.productsToCompare.map((p) => p['return'] as String).toList(),
                ),
                _buildComparisonTableRow(
                  'Expense Ratio',
                  widget.productsToCompare.map((p) => p['expenseRatio'] as String).toList(),
                ),
                _buildComparisonTableRow(
                  'Min Investment',
                  widget.productsToCompare.map((p) => p['minInvestment'] as String).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI-Powered Recommendation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'AI-Powered Recommendation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _generateAIRecommendation(),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    _tabController.animateTo(4); // Navigate to AI Analysis tab
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                    side: BorderSide(color: Colors.blue[700]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('See Detailed Analysis'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Performance tab with charts
  Widget _buildPerformanceTab() {
    final performanceData = comparisonData!['performance']['historical_returns'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historical Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Expected annual returns based on historical data',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Bar chart for historical returns
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxReturn(performanceData) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = performanceData[groupIndex];
                      return BarTooltipItem(
                        '${data['name']}\n${data['value']}%',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < performanceData.length) {
                          final name = performanceData[index]['name'] as String;
                          // Return shortened name to fit
                          final displayName = name.length > 10 ? name.substring(0, 10) + '...' : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  performanceData.length,
                      (index) {
                    final data = performanceData[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['value'],
                          color: data['color'],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Performance explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Understanding Performance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Historical performance is not a guarantee of future returns. The chart above shows the expected annual return based on historical data. Higher returns typically come with higher risk.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Top Performer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTopPerformerCard(_getTopPerformer(performanceData)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Risk tab with risk metrics visualization
  Widget _buildRiskTab() {
    final riskData = comparisonData!['risk_metrics']['volatility'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Assessment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Volatility and risk characteristics of each investment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Horizontal bar chart for risk visualization
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxVolatility(riskData) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = riskData[groupIndex];
                      return BarTooltipItem(
                        '${data['name']}\nVolatility: ${data['value']}%',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < riskData.length) {
                          final name = riskData[index]['name'] as String;
                          final displayName = name.length > 10 ? name.substring(0, 10) + '...' : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  riskData.length,
                      (index) {
                    final data = riskData[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['value'],
                          color: data['color'],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Risk level cards
          const Text(
            'Risk Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildRiskLevelCard(
                  'Low Risk',
                  'Minimal volatility with modest returns. Suitable for conservative investors.',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRiskLevelCard(
                  'Moderate Risk',
                  'Balanced approach with moderate volatility and better growth potential.',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRiskLevelCard(
                  'High Risk',
                  'Higher volatility with potential for greater returns. For growth-focused investors.',
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Risk explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Understanding Risk',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Volatility measures how much an investments value fluctuates over time. Higher volatility generally indicates higher risk, but also potential for higher returns. Your risk tolerance and time horizon should guide your investment choices.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fees tab with expense ratio comparison
  Widget _buildFeesTab() {
    final feesData = comparisonData!['fees']['expense_ratios'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Annual expense ratios and cost analysis',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Bar chart for expense ratios
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxFee(feesData) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = feesData[groupIndex];
                      return BarTooltipItem(
                        '${data['name']}\n${data['value']}%',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < feesData.length) {
                          final name = feesData[index]['name'] as String;
                          final displayName = name.length > 10 ? name.substring(0, 10) + '...' : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 45,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  feesData.length,
                      (index) {
                    final data = feesData[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['value'],
                          color: data['color'],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Fee impact calculator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fee Impact Calculator',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'See how fees impact your investment over time. The table below shows the cost of fees on a \$10,000 investment over different time periods.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Fee impact table
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildFeeImpactRow(['Product', '1 Year', '5 Years', '10 Years'], isHeader: true),
                      ...feesData.map((data) {
                        final feePercentage = data['value'] as double;
                        return _buildFeeImpactRow([
                          data['name'] as String,
                          '\$${(10000 * feePercentage / 100).toStringAsFixed(0)}',
                          '\$${(10000 * feePercentage / 100 * 5).toStringAsFixed(0)}',
                          '\$${(10000 * feePercentage / 100 * 10).toStringAsFixed(0)}',
                        ]);
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Note: This is a simplified calculation that doesnt account for compounding or changes in investment value. Actual fee impact may be higher.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // AI Analysis tab
  Widget _buildAIAnalysisTab() {
    final analysisData = comparisonData!['ai_analysis']['recommendations'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'AI-Powered Investment Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Text(
            'Comprehensive analysis based on your investment profile',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // AI recommendation cards
          ...analysisData.asMap().entries.map((entry) {
            final index = entry.key;
            final analysis = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getProductColor(index).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getProductColor(index).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Strengths',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...(analysis['strengths'] as List).map((strength) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                strength as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ).toList(),

                  const SizedBox(height: 12),
                  const Text(
                    'Considerations',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...(analysis['weaknesses'] as List).map((weakness) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info, size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                weakness as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ).toList(),

                  const SizedBox(height: 12),
                  const Text(
                    'Ideal For',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysis['ideal_for'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Financial advisor note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.support_agent, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Financial Advisor Consultation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'For personalized investment advice based on your specific financial situation, consider scheduling a consultation with a financial advisor.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Open financial advisor booking screen
                  },
                  icon: Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                  label: Text(
                    'Schedule Consultation',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue[700]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build comparison table rows
  Widget _buildComparisonTableRow(String label, List<String> values, {bool isHeader = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey[100] : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          ...values.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            return Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey[300]!),
                  ),
                  color: isHeader
                      ? _getProductColor(index).withOpacity(0.1)
                      : Colors.white,
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                    color: isHeader ? _getProductColor(index) : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Helper method to build fee impact table rows
  Widget _buildFeeImpactRow(List<String> values, {bool isHeader = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey[100] : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: values.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          return Expanded(
            flex: index == 0 ? 2 : 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: index > 0
                    ? Border(left: BorderSide(color: Colors.grey[300]!))
                    : null,
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper method to build risk level cards
  Widget _buildRiskLevelCard(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to build top performer card
  Widget _buildTopPerformerCard(Map<String, dynamic> performer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performer['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Return: ${performer['value']}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get max return value for chart
  double _getMaxReturn(List performanceData) {
    double max = 0;
    for (var data in performanceData) {
      final value = data['value'] as double;
      if (value > max) max = value;
    }
    return max;
  }

  // Helper method to get max volatility value for chart
  double _getMaxVolatility(List riskData) {
    double max = 0;
    for (var data in riskData) {
      final value = data['value'] as double;
      if (value > max) max = value;
    }
    return max;
  }

  // Helper method to get max fee value for chart
  double _getMaxFee(List feesData) {
    double max = 0;
    for (var data in feesData) {
      final value = data['value'] as double;
      if (value > max) max = value;
    }
    return max;
  }

  // Helper method to get top performing product
  Map<String, dynamic> _getTopPerformer(List performanceData) {
    if (performanceData.isEmpty) {
      return {'name': 'None', 'value': 0.0};
    }

    var topPerformer = performanceData[0];
    double maxValue = topPerformer['value'];

    for (var data in performanceData) {
      final value = data['value'] as double;
      if (value > maxValue) {
        maxValue = value;
        topPerformer = data;
      }
    }

    return topPerformer;
  }

  // Helper method to generate AI recommendation text
  String _generateAIRecommendation() {
    if (widget.productsToCompare.isEmpty) {
      return 'No products to compare.';
    }

    // Sort products by return (descending)
    final sortedProducts = List<Map<String, dynamic>>.from(widget.productsToCompare)
      ..sort((a, b) {
        final aReturn = double.tryParse(a['return'].toString().replaceAll('%', '')) ?? 0.0;
        final bReturn = double.tryParse(b['return'].toString().replaceAll('%', '')) ?? 0.0;
        return bReturn.compareTo(aReturn);
      });

    final topProduct = sortedProducts.first;
    final secondProduct = sortedProducts.length > 1 ? sortedProducts[1] : null;

    String recommendation = 'Based on your investment criteria, ';

    if (topProduct['risk'] == 'Low') {
      recommendation += '${topProduct['name']} stands out as a conservative option with a steady ${topProduct['return']} return and lower volatility. ';
    } else if (topProduct['risk'] == 'Moderate') {
      recommendation += '${topProduct['name']} offers a balanced approach with a ${topProduct['return']} return and moderate risk. ';
    } else {
      recommendation += '${topProduct['name']} provides higher growth potential at ${topProduct['return']} but comes with increased volatility. ';
    }

    if (secondProduct != null) {
      recommendation += 'Consider ${secondProduct['name']} as an alternative option that ';

      if (secondProduct['risk'] != topProduct['risk']) {
        recommendation += 'offers a different risk profile (${secondProduct['risk']}) ';
      } else {
        recommendation += 'provides similar risk characteristics ';
      }

      recommendation += 'with a ${secondProduct['return']} expected return.';
    }

    return recommendation;
  }

  // Show action dialog for the floating action button
  void _showActionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Investment Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_chart, color: Colors.green),
              title: const Text('Add to Portfolio'),
              subtitle: const Text('Save these investments to your portfolio'),
              onTap: () {
                Navigator.pop(context);
                // Add logic to save to portfolio
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to portfolio')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share Comparison'),
              subtitle: const Text('Share this comparison with others'),
              onTap: () {
                Navigator.pop(context);
                // Add sharing logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing comparison...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Colors.purple),
              title: const Text('Ask AI Assistant'),
              subtitle: const Text('Get AI-powered advice on these options'),
              onTap: () {
                Navigator.pop(context);
                // Open AI assistant dialog
                _showAIAssistantDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show AI assistant dialog
  void _showAIAssistantDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.assistant, color: Colors.purple[700]),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Investment AI Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(
                        'How can I help with your investment decision?',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'You can ask me:',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text('• Which investment is best for my risk profile?'),
                      SizedBox(height: 4),
                      Text('• What are the tax implications of these investments?'),
                      SizedBox(height: 4),
                      Text('• How should I allocate my portfolio between these options?'),
                      SizedBox(height: 4),
                      Text('• What are the pros and cons of each investment?'),
                    ],
                  ),
                ),
              ),
              const Divider(),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.purple),
                    onPressed: () {
                      // Send question to AI
                      Navigator.pop(context);
                      // Show response in snackbar for demo
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AI is analyzing your investment options...'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}