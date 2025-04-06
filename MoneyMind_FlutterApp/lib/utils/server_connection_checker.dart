// Updated version of lib/utils/server_connection_checker.dart
import 'dart:io';
import 'package:http/http.dart' as http;

/// Utility function to check if the server is accessible
/// Returns true if the server is reachable, false otherwise
Future<bool> checkServerConnection(String baseUrl) async {
  try {
    print('Checking server connection to: $baseUrl/api/health');

    // First try the health endpoint
    final response = await http.get(
      Uri.parse('$baseUrl/api/health'),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('Health endpoint connection timed out');
        throw TimeoutException('Connection timed out');
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('Server connection successful: ${response.statusCode}');
      return true;
    }

    // If health endpoint fails, try the root endpoint as fallback
    print('Health endpoint failed, trying root endpoint');
    final rootResponse = await http.get(
      Uri.parse(baseUrl),
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('Root endpoint connection timed out');
        throw TimeoutException('Connection timed out');
      },
    );

    print('Root endpoint response: ${rootResponse.statusCode}');
    return rootResponse.statusCode >= 200 && rootResponse.statusCode < 300;
  } catch (e) {
    print('Server connection check failed: $e');
    return false;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Helper function to determine which URL to use based on platform
String getServerUrl() {
  // Use the production URL for the deployed backend
  const productionUrl = 'https://moneymind-dlnl.onrender.com';

  try {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      // If we're running tests, use localhost
      return 'http://localhost:5000';
    }

    // Check if running on Android emulator
    if (Platform.isAndroid) {
      return productionUrl;
      // For local development on emulator, use: 'http://10.0.2.2:5000'
    }
    // Check if running on iOS simulator
    else if (Platform.isIOS) {
      return productionUrl;
      // For local development on simulator, use: 'http://localhost:5000'
    }
    // Default case for physical devices or web
    else {
      return productionUrl;
    }
  } catch (e) {
    print('Error determining server URL: $e');
    // Default fallback to production
    return productionUrl;
  }
}