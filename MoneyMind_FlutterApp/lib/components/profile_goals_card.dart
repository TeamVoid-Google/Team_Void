import 'package:flutter/material.dart';

class ProfileGoalsCard extends StatelessWidget {
  const ProfileGoalsCard({Key? key}) : super(key: key);

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
                'Financial Goals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                onPressed: () {
                  // Add new goal
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGoalItem(
            'Emergency Fund',
            500000.0,
            350000.0,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildGoalItem(
            'Vacation',
            200000.0,
            120000.0,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildGoalItem(
            'New Laptop',
            100000.0,
            75000.0,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(
      String title,
      double target,
      double current,
      Color color,
      ) {
    final percentage = (current / target * 100).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: color,
                  minHeight: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '₹${current.toInt()} of ₹${target.toInt()}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}