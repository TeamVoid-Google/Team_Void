import 'package:flutter/material.dart';

class ProfileInvestmentsCard extends StatelessWidget {
  const ProfileInvestmentsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPortfolioSummaryCard(),
        const SizedBox(height: 24),
        _buildInvestmentsList(),
      ],
    );
  }

  Widget _buildPortfolioSummaryCard() {
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
          const Text(
            'Investment Portfolio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '₹5,72,211',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                '+12.4% this month',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Asset Allocation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 45,
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 30,
                child: Container(
                  height: 8,
                  color: Colors.green,
                ),
              ),
              Expanded(
                flex: 15,
                child: Container(
                  height: 8,
                  color: Colors.amber,
                ),
              ),
              Expanded(
                flex: 10,
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAllocationItem('Stocks', '45%', Colors.blue),
          const SizedBox(height: 8),
          _buildAllocationItem('Mutual Funds', '30%', Colors.green),
          const SizedBox(height: 8),
          _buildAllocationItem('Gold', '15%', Colors.amber),
          const SizedBox(height: 8),
          _buildAllocationItem('Crypto', '10%', Colors.red),
        ],
      ),
    );
  }

  Widget _buildAllocationItem(String title, String percentage, Color color) {
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
          title,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentsList() {
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
                'Your Investments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Add new investment
                },
                icon: const Icon(Icons.add, color: Colors.green, size: 16),
                label: const Text(
                  'Add New',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInvestmentItem(
            'HDFC Bank',
            'HDFCBANK',
            '₹1,682.50',
            '+3.45%',
            Icons.trending_up,
            Colors.green,
          ),
          const Divider(),
          _buildInvestmentItem(
            'Reliance Industries',
            'RELIANCE',
            '₹2,750.75',
            '-1.24%',
            Icons.trending_down,
            Colors.red,
          ),
          const Divider(),
          _buildInvestmentItem(
            'Tata Consultancy',
            'TCS',
            '₹3,550.20',
            '+2.15%',
            Icons.trending_up,
            Colors.green,
          ),
          const Divider(),
          _buildInvestmentItem(
            'SBI Bluechip Fund',
            'Mutual Fund',
            '₹45.85',
            '+0.75%',
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildViewAllButton(),
        ],
      ),
    );
  }

  Widget _buildInvestmentItem(
      String name,
      String ticker,
      String price,
      String change,
      IconData trendIcon,
      Color changeColor,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade100,
            child: Text(
              name.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticker,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    trendIcon,
                    color: changeColor,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    change,
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'View All Investments',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}