// lib/widgets/connection_error_widget.dart
import 'package:flutter/material.dart';

class ConnectionErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ConnectionErrorWidget({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Show information dialog with common troubleshooting tips
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text('Troubleshooting Tips')
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Here are some steps you can try:'),
                        SizedBox(height: 16),
                        Text('1. Check your internet connection'),
                        SizedBox(height: 8),
                        Text('2. Try again in a few minutes'),
                        SizedBox(height: 8),
                        Text('3. If problem persists, the service might be temporarily down for maintenance'),
                        SizedBox(height: 8),
                        Text('4. You can still explore the app with limited functionality'),
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
              },
              child: Text(
                'Need Help?',
                style: TextStyle(color: Colors.blue[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}