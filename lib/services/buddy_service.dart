import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class BuddyService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> sendMessage(
    String message,
    List<Map<String, String>> history, {
    int? activeSeniorId,
  }) async {
    final token = await _api.getToken();
    if (token == null) return {'success': false, 'error': 'Not logged in'};

    try {
      final body = {
        'message': message,
        'history': history,
        if (activeSeniorId != null) 'active_senior_id': activeSeniorId,
      };

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/ai-chat/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'reply': data['reply'],
          'action_result': data['action_result'],
          'history': List<Map<String, String>>.from(
            (data['history'] as List).map((h) => {
              'role': h['role'].toString(),
              'content': h['content'].toString(),
            }),
          ),
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Unknown error'};
    } catch (e) {
      return {'success': false, 'error': 'Buddy is unavailable. Please try again.'};
    }
  }
}