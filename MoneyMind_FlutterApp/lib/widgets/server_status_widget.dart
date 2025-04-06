// lib/widgets/server_status_widget.dart
import 'package:flutter/material.dart';
import '../utils/server_connection_checker.dart';

class ServerStatusWidget extends StatefulWidget {
  final String serverUrl;
  final VoidCallback? onRetry;

  const ServerStatusWidget({
    Key? key,
    required this.serverUrl,
    this.onRetry,
  }) : super(key: key);

  @override
  State<ServerStatusWidget> createState() => _ServerStatusWidgetState();
}

class _ServerStatusWidgetState extends State<ServerStatusWidget> {
  bool _isChecking = true;
  bool _isConnected = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
      _errorMessage = '';
    });

    try {
      final isConnected = await checkServerConnection(widget.serverUrl);

      setState(() {
        _isConnected = isConnected;
        _isChecking = false;
        if (!isConnected) {
          _errorMessage = 'Unable to connect to the investment server';
        }
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isChecking = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.blue[50],
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Checking server connection...',
              style: TextStyle(color: Colors.blue[700]),
            ),
          ],
        ),
      );
    } else if (_isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.green[50],
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 18),
            const SizedBox(width: 12),
            Text(
              'Connected to investment server',
              style: TextStyle(color: Colors.green[700]),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.red[50],
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
            TextButton(
              onPressed: () {
                _checkConnection();
                widget.onRetry?.call();
              },
              child: Text(
                'Retry',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      );
    }
  }
}