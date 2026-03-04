import 'dart:convert';

class BackupSerializer {
  static String encode(Map<String, List<Map<String, dynamic>>> data) {
    final payload = {
      'schemaVersion': 3,
      'lastExported': DateTime.now().millisecondsSinceEpoch,
      ...data
    };
    return jsonEncode(payload);
  }

  static Map<String, dynamic>? decode(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
