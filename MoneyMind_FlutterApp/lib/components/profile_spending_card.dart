import 'package:flutter/material.dart';

class ProfileSpendingCard extends StatelessWidget {
  final double spending;
  final String formattedSpending;

  const ProfileSpendingCard({
    Key? key,
    required this.spending,
    required this.formattedSpending,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending Analytics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Jul 2024',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '- $formattedSpending',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          // Simple chart placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 50,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Spending Chart",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryItem('Healthcare', '₹84,000', Colors.blue),
          const SizedBox(height: 8),
          _buildCategoryItem('Food', '₹52,700', Colors.orange),
          const SizedBox(height: 8),
          _buildCategoryItem('Utilities', '₹37,000', Colors.purple),
          const SizedBox(height: 8),
          _buildCategoryItem('Supplies', '₹17,100', Colors.teal),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category, String amount, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          category,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}