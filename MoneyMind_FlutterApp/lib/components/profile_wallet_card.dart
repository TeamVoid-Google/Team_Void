import 'package:flutter/material.dart';

class ProfileWalletCard extends StatelessWidget {
  final String formattedBalance;

  const ProfileWalletCard({
    Key? key,
    required this.formattedBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
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
                'Wallet Balance',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.refresh,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formattedBalance,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWalletActionButton(Icons.send, 'Send'),
              _buildWalletActionButton(Icons.request_page, 'Request'),
              _buildWalletActionButton(Icons.qr_code_scanner, 'Scan'),
              _buildWalletActionButton(Icons.more_horiz, 'More'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletActionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          child: Icon(
            icon,
            size: 20,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}