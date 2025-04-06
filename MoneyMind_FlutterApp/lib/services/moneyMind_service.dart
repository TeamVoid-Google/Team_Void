import 'dart:convert';
import 'package:http/http.dart' as http;

class MoneyMindService {
  final String baseUrl;
  final String userId;

  MoneyMindService({
    required this.baseUrl,
    required this.userId
  });

  Future<bool> verifyServerConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Server connection error: $e');
      return false;
    }
  }

  Future<String> generateResponse(String message) async {
    try {
      print('Attempting to call API at: $baseUrl/api/chat');
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'message': message
        }),
      ).timeout(const Duration(seconds: 30));

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? 'No response received';
      } else {
        Map<String, dynamic> error;
        try {
          error = json.decode(response.body);
          print('Error response: $error');
        } catch (e) {
          error = {'detail': 'Unknown error occurred'};
          print('Failed to parse error: $e');
        }
        return 'Error: ${error['detail'] ?? 'Unknown error occurred'}';
      }
    } catch (e) {
      print('Generate response error (detailed): $e');
      return 'Connection error: $e';
    }
  }
}