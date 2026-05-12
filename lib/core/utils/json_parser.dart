import 'dart:convert';
import '../errors/app_exception.dart';

class JsonParser {
  JsonParser._();

  /// Extracts and parses the JSON object from a Gemini response string.
  /// Gemini may wrap JSON in markdown code fences — this handles that.
  static Map<String, dynamic> parseMeetingResult(String raw) {
    try {
      // Strip markdown code fences if present
      String cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```[a-z]*\n?'), '');
        cleaned = cleaned.replaceAll(RegExp(r'\n?```$'), '');
        cleaned = cleaned.trim();
      }
      return json.decode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw AIException(
        message: 'Failed to parse AI response as JSON.',
        originalError: e,
      );
    }
  }

  static List<String> parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static List<Map<String, dynamic>> parseMapList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
