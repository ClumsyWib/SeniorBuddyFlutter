import 'dart:convert';

class JsonConverter {
  static String encode(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  static Map<String, dynamic> decode(String data) {
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
