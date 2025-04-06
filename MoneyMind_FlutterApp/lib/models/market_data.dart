// lib/models/market_data.dart

class MarketTrend {
  final String title;
  final List<MarketResult> results;

  MarketTrend({
    required this.title,
    required this.results,
  });

  factory MarketTrend.fromJson(Map<String, dynamic> json) {
    final List<dynamic> resultsJson = json['results'] ?? [];

    return MarketTrend(
      title: json['title'] ?? 'Unknown',
      results: resultsJson.map((result) => MarketResult.fromJson(result)).toList(),
    );
  }
}

class MarketResult {
  final String name;
  final String price;
  final String stock;
  final PriceMovement priceMovement;

  MarketResult({
    required this.name,
    required this.price,
    required this.stock,
    required this.priceMovement,
  });

  factory MarketResult.fromJson(Map<String, dynamic> json) {
    return MarketResult(
      name: json['name'] ?? 'Unknown',
      price: json['price'] ?? '0.00',
      stock: json['stock'] ?? '',
      priceMovement: PriceMovement.fromJson(json['price_movement'] ?? {}),
    );
  }
}

class PriceMovement {
  final String? movement; // 'up', 'down', or null
  final double? value;
  final double? percentage;
  final bool isPositive;

  PriceMovement({
    this.movement,
    this.value,
    this.percentage,
    required this.isPositive,
  });

  factory PriceMovement.fromJson(Map<String, dynamic> json) {
    // Handle numeric values that might come as strings
    double? parseDoubleValue(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    final double? valueNumber = parseDoubleValue(json['value']);
    final double? percentageNumber = parseDoubleValue(json['percentage']);

    // Determine if movement is positive
    final String? movementStr = json['movement']?.toString().toLowerCase();
    final bool isPositiveMovement = movementStr == 'up' ||
        (valueNumber != null && valueNumber > 0) ||
        (percentageNumber != null && percentageNumber > 0);

    return PriceMovement(
      movement: movementStr,
      value: valueNumber,
      percentage: percentageNumber,
      isPositive: json['is_positive'] ?? isPositiveMovement,
    );
  }
}