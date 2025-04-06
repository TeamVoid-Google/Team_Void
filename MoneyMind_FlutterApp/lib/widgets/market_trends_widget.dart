// lib/widgets/market_trends_widget.dart
import 'package:flutter/material.dart';
import '../models/market_data.dart';
import '../services/api_service.dart';

class MarketTrendsWidget extends StatefulWidget {
  const MarketTrendsWidget({Key? key}) : super(key: key);

  @override
  State<MarketTrendsWidget> createState() => _MarketTrendsWidgetState();
}

class _MarketTrendsWidgetState extends State<MarketTrendsWidget> {
  final ApiService _apiService = ApiService();
  List<MarketTrend> _marketTrends = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
  }

  Future<void> _fetchMarketData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final marketTrends = await _apiService.getMarketData();
      setState(() {
        _marketTrends = marketTrends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load market data: $e';
        _isLoading = false;
      });
      print('Error fetching market data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMarketData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_marketTrends.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No market data available'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Market Trends',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchMarketData,
                tooltip: 'Refresh data',
              ),
            ],
          ),
        ),
        for (final marketTrend in _marketTrends)
          _buildMarketTrendSection(marketTrend),
      ],
    );
  }

  Widget _buildMarketTrendSection(MarketTrend marketTrend) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            marketTrend.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: marketTrend.results.length,
            itemBuilder: (context, index) {
              final result = marketTrend.results[index];
              return _buildMarketResultCard(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMarketResultCard(MarketResult result) {
    final isPositive = result.priceMovement.isPositive;
    final isNegative = result.priceMovement.movement?.toLowerCase() == 'down';
    final changeColor = isPositive ? Colors.green : (isNegative ? Colors.red : Colors.grey);
    final changeIcon = isPositive
        ? Icons.arrow_upward
        : (isNegative ? Icons.arrow_downward : Icons.remove);

    return GestureDetector(
      onTap: () {
        // Optional: handle tapping on a market card
        // Could open a detailed view or navigate to a stock page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected ${result.name}')),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    result.price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          changeIcon,
                          color: changeColor,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${(result.priceMovement.percentage ?? 0).toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: changeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (result.priceMovement.value != null)
                Text(
                  'Change: ${result.priceMovement.value!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    result.stock,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}