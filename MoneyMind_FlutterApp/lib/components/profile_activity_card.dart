import 'package:flutter/material.dart';

class ProfileActivityCard extends StatelessWidget {
  const ProfileActivityCard({Key? key}) : super(key: key);

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
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to details
                },
                child: const Text(
                  'See Details',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'Dribbble',
            '-₹9,100',
            'Design Tools, 10:45 AM',
            Colors.pink,
            Icons.design_services,
          ),
          const Divider(),
          _buildActivityItem(
            'Wilson Mango',
            '-₹2,400',
            'Money Transfer, Yesterday',
            Colors.purple,
            Icons.person,
          ),
          const Divider(),
          _buildActivityItem(
            'Abram Botosh',
            '+₹4,500',
            'Payment Received, 07/24',
            Colors.green,
            Icons.account_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String amount, String subtitle, Color iconColor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: amount.startsWith('+') ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}