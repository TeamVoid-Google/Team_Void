// lib/widgets/investment_product_card.dart
import 'package:flutter/material.dart';

class InvestmentProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isSelected;
  final Function(Map<String, dynamic>) onSelect;
  final bool isCompareMode;

  const InvestmentProductCard({
    Key? key,
    required this.product,
    required this.isSelected,
    required this.onSelect,
    this.isCompareMode = false,
  }) : super(key: key);

  @override
  State<InvestmentProductCard> createState() => _InvestmentProductCardState();
}

class _InvestmentProductCardState extends State<InvestmentProductCard> {
  bool isExplaining = false;
  String? explanation;

  // Add these methods to your _InvestmentProductCardState class

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

  Widget _buildMetricColumn({required String label, required String value, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Color _getReturnColor(String returnValue) {
    final returnPercent = double.tryParse(returnValue.replaceAll('%', '')) ?? 0.0;

    if (returnPercent >= 10.0) {
      return Colors.green[700]!;
    } else if (returnPercent >= 7.0) {
      return Colors.green[500]!;
    } else if (returnPercent >= 4.0) {
      return Colors.amber[700]!;
    } else if (returnPercent >= 0.0) {
      return Colors.orange[700]!;
    } else {
      return Colors.red[700]!;
    }
  }

  Widget _buildRiskBadge(String risk) {
    Color backgroundColor;
    Color textColor;

    switch (risk) {
      case 'Low':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        break;
      case 'Moderate':
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        break;
      case 'High':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        break;
      default:
        backgroundColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        risk,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  void _showExplanationDialog() {
    // Safe access to product values
    final productType = widget.product['type']?.toString() ?? 'Other';
    final name = widget.product['name']?.toString() ?? 'This product';
    final returnValue = widget.product['return']?.toString() ?? 'N/A';
    final expenseRatio = widget.product['expenseRatio']?.toString() ?? 'N/A';
    final risk = widget.product['risk']?.toString() ?? 'moderate';
    final timeHorizon = widget.product['timeHorizon']?.toString() ?? 'medium-term';

    // Generate explanation
    String _generateExplanation({
      required String productType,
      required String name,
      required String returnValue,
      required String expenseRatio,
      required String risk,
      required String timeHorizon,
    }) {
      switch (productType) {
        case 'ETF':
          return '$name is an Exchange-Traded Fund with a historical return of $returnValue and an expense ratio of $expenseRatio. ETFs trade like stocks but offer diversification similar to mutual funds. With a $risk risk profile, this investment is suitable for a $timeHorizon time horizon. ETFs typically offer better tax efficiency and lower fees than mutual funds.';

        case 'Gold':
          return '$name is a Gold ETF that provides exposure to gold prices with a $returnValue historical return. It has an expense ratio of $expenseRatio and is considered a $risk risk investment suitable for a $timeHorizon horizon. Gold often serves as a hedge against inflation and market volatility, making it a popular choice for portfolio diversification.';

        case 'Silver':
          return '$name is a Silver ETF that offers exposure to silver prices with a $returnValue historical return. With an expense ratio of $expenseRatio, it presents a $risk risk profile suitable for a $timeHorizon investment timeline. Silver investments can provide portfolio diversification and potential inflation protection, though they may be more volatile than gold.';

        case 'Bonds':
          return '$name is a Bond investment with a $returnValue historical return and an expense ratio of $expenseRatio. With a $risk risk profile, this is suitable for a $timeHorizon investment horizon. Bonds typically provide regular income through interest payments and are generally less volatile than stocks, making them a cornerstone of income-focused portfolios.';

        case 'Stocks':
          return '$name represents equity ownership in a company, with a historical return of $returnValue. It carries a $risk risk profile and is recommended for a $timeHorizon investment horizon. Stocks offer growth potential through price appreciation and possibly dividends, though they come with higher volatility than bonds or fixed-income investments.';

        case 'IPO\'s':
          return '$name focuses on newly public companies with a historical return of $returnValue and an expense ratio of $expenseRatio. With a $risk risk profile, this investment is suited for a $timeHorizon horizon. IPO investments can offer significant growth potential but also come with higher volatility and uncertainty compared to established companies.';

        case 'Mutual Funds':
          return '$name is a Mutual Fund with a $returnValue historical return and an expense ratio of $expenseRatio. It has a $risk risk profile suitable for a $timeHorizon investment timeline. Mutual funds pool money from many investors to purchase a diversified portfolio of securities, professionally managed to meet specified investment objectives.';

        case 'Fixed Deposit':
          return '$name is a Fixed Deposit investment with a $returnValue return and minimal fees ($expenseRatio). With a $risk risk profile, its ideal for a $timeHorizon investment timeline. Fixed deposits offer guaranteed returns and principal protection, making them suitable for conservative investors prioritizing capital preservation over growth.';

        case 'Crypto':
          return '$name is a Cryptocurrency investment with a historical return of $returnValue and fees of $expenseRatio. This $risk risk investment is suitable for a $timeHorizon horizon. Cryptocurrencies offer significant growth potential but come with high volatility and regulatory uncertainty, making them appropriate only for those comfortable with substantial risk.';

        case 'Insurance':
          return '$name is an Insurance-based investment with a $returnValue historical return and fees of $expenseRatio. This $risk risk product is designed for a $timeHorizon investment timeline. Insurance investments typically combine protection benefits with investment components, offering tax advantages but sometimes higher fees compared to direct investments.';

        default:
          return '$name offers a historical return of $returnValue with an expense ratio of $expenseRatio. With a $risk risk profile, its suitable for investors with a $timeHorizon time horizon. Consider how this investment fits within your overall portfolio strategy and financial goals.';
      }
    }
    String productExplanation = _generateExplanation(
        productType: productType,
        name: name,
        returnValue: returnValue,
        expenseRatio: expenseRatio,
        risk: risk,
        timeHorizon: timeHorizon
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _getIconForProductType(productType),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
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
              _buildInfoRow('Symbol', widget.product['symbol']?.toString() ?? ''),
              _buildInfoRow('Type', productType),
              _buildInfoRow('5Y Return', returnValue),
              _buildInfoRow('Expense Ratio', expenseRatio),
              _buildInfoRow('Min Investment', widget.product['minInvestment']?.toString() ?? 'N/A'),
              _buildInfoRow('Risk Level', risk),
              _buildInfoRow('Time Horizon', timeHorizon),

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
                productExplanation,
                style: const TextStyle(fontSize: 14),
              ),
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
              // Add this specific product to the comparison list
              widget.onSelect(widget.product);
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

  @override
  Widget build(BuildContext context) {
    // Add null checks for all string properties
    final name = widget.product['name']?.toString() ?? 'Unknown Product';
    final symbol = widget.product['symbol']?.toString() ?? '';
    final type = widget.product['type']?.toString() ?? 'Other';
    final returnVal = widget.product['return']?.toString() ?? 'N/A';
    final expenseRatio = widget.product['expenseRatio']?.toString() ?? 'N/A';
    final minInvestment = widget.product['minInvestment']?.toString() ?? 'N/A';
    final risk = widget.product['risk']?.toString() ?? 'Moderate';
    final timeHorizon = widget.product['timeHorizon']?.toString() ?? 'N/A';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: widget.isSelected
              ? Border.all(color: Colors.green, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with selection checkbox and name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isCompareMode)
                    GestureDetector(
                      onTap: () {
                        // Add explicit debug logs
                        print('Checkbox clicked for ${widget.product['name']}');

                        // Call the onSelect callback with this specific product
                        widget.onSelect(widget.product);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12, top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isSelected ? Colors.green : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: widget.isSelected
                              ? const Icon(Icons.check, color: Colors.green, size: 16)
                              : const SizedBox(width: 16, height: 16),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getIconForProductType(type),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          symbol,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Key metrics row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricColumn(
                    label: '5Y Return',
                    value: returnVal,
                    valueColor: _getReturnColor(returnVal),
                  ),
                  _buildMetricColumn(
                    label: 'Expense Ratio',
                    value: expenseRatio,
                  ),
                  _buildMetricColumn(
                    label: 'Min',
                    value: minInvestment,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Risk badge and time horizon
              Row(
                children: [
                  _buildRiskBadge(risk),
                  const SizedBox(width: 8),
                  Text(
                    timeHorizon,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showExplanationDialog();
                      },
                      icon: const Icon(Icons.lightbulb_outline, size: 16),
                      label: const Text('Explain'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[200]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: widget.isCompareMode
                        ? ElevatedButton.icon(
                      onPressed: () {
                        // Add explicit debug logs to see if this button is pressed
                        print('SELECT button pressed for ${widget.product['name']}');

                        // Call the onSelect callback with this specific product
                        widget.onSelect(widget.product);
                      },
                      icon: widget.isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : const Icon(Icons.add, size: 16, color: Colors.white),
                      label: Text(
                        widget.isSelected ? 'Selected' : 'Select',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isSelected ? Colors.green : Colors.grey[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                        : OutlinedButton.icon(
                      onPressed: () {
                        // Add explicit debug logs
                        print('COMPARE button pressed for ${widget.product['name']}');

                        // Call the onSelect callback with this specific product
                        widget.onSelect(widget.product);
                      },
                      icon: const Icon(Icons.compare_arrows, size: 16),
                      label: const Text('Compare'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}