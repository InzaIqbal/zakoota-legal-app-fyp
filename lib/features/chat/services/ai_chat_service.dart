import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatService {
  // CORRECT URL with /api
  static const String _baseUrl =
      'https://zakoota-backend-production.vercel.app';
  static const String _chatPath = '/api/chat';

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_chatPath'),
        headers: {
          'Content-Type': 'application/json',
          // Remove if not needed
          // if (ZingAIConfig.apiKey.isNotEmpty)
          //   'Authorization': 'Bearer ${ZingAIConfig.apiKey}',
        },
        body: jsonEncode({
          'message': message,
          'user_type': 'client',
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // YOUR BACKEND RETURNS: {"reply": "...", "status": "success"}
        if (data.containsKey('reply')) {
          return data['reply'].toString();
        } else if (data.containsKey('response')) {
          return data['response'].toString();
        } else {
          return 'Zing AI: Received unexpected response format';
        }
      } else {
        return 'Zing AI: Failed with status ${response.statusCode}';
      }
    } catch (e) {
      return 'Zing AI: Connection error - $e';
    }
  }
}
