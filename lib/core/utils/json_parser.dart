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
      final decoded = json.decode(cleaned) as Map<String, dynamic>;
      return _normalizeMeetingResult(decoded);
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
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  static Map<String, dynamic> _normalizeMeetingResult(
      Map<String, dynamic> input) {
    final participants = parseStringList(
      input['participants'] ?? input['attendees'] ?? input['people'],
    );

    final tasks = parseMapList(
      input['tasks'] ??
          input['actionItems'] ??
          input['action_items'] ??
          input['todo'] ??
          input['todos'],
    )
        .map((task) => _normalizeTask(task, participants))
        .where(_hasTaskContent)
        .toList();

    final decisions = parseMapList(
      input['decisions'] ?? input['decisionItems'] ?? input['decision_items'],
    )
        .map(_normalizeDecision)
        .where((item) => item['text'].toString().trim().isNotEmpty)
        .toList();

    return {
      'title': _asString(
          input['title'] ?? input['meetingTitle'] ?? input['subject']),
      'shortSummary': _asString(
        input['shortSummary'] ?? input['summary'] ?? input['short_summary'],
      ),
      'detailedSummary': _asString(
        input['detailedSummary'] ??
            input['details'] ??
            input['detailed_summary'],
      ),
      'minutesOfMeeting': parseStringList(
        input['minutesOfMeeting'] ??
            input['minutes'] ??
            input['minutes_of_meeting'],
      ),
      'decisions': decisions,
      'tasks': tasks,
      'participants': participants,
      'followUps': parseStringList(
        input['followUps'] ?? input['followups'] ?? input['follow_up'],
      ),
    };
  }

  static Map<String, dynamic> _normalizeTask(
    Map<String, dynamic> input,
    List<String> participants,
  ) {
    final title = _asString(
      input['title'] ?? input['task'] ?? input['name'] ?? input['action'],
    );
    final description = _asString(
      input['description'] ?? input['details'] ?? input['notes'],
    );
    final assignee = _asString(
      input['assignee'] ??
          input['owner'] ??
          input['assignedTo'] ??
          input['assigned_to'],
    );
    final inferredAssignee = assignee.isNotEmpty
        ? assignee
        : _inferAssigneeFromParticipants(
            participants: participants,
            title: title,
            description: description,
          );

    return {
      'title': title.isNotEmpty ? title : description,
      'description': description,
      'assignee': inferredAssignee,
      'dueDate': _asString(
        input['dueDate'] ?? input['deadline'] ?? input['due_date'],
      ),
      'priority': _normalizedPriority(
        _asString(input['priority'] ?? input['importance']),
      ),
      'status': _asString(input['status']).isNotEmpty
          ? _asString(input['status'])
          : 'pending',
    };
  }

  static Map<String, dynamic> _normalizeDecision(Map<String, dynamic> input) {
    return {
      'text': _asString(input['text'] ?? input['decision'] ?? input['summary']),
      'owner': _asString(input['owner'] ?? input['assignee']),
    };
  }

  static bool _hasTaskContent(Map<String, dynamic> task) {
    return task['title'].toString().trim().isNotEmpty ||
        task['description'].toString().trim().isNotEmpty;
  }

  static String _inferAssigneeFromParticipants({
    required List<String> participants,
    required String title,
    required String description,
  }) {
    final haystack = '$title\n$description'.toLowerCase();
    for (final participant in participants) {
      final normalizedParticipant = participant.trim().toLowerCase();
      if (normalizedParticipant.isEmpty) continue;
      if (haystack.contains(normalizedParticipant)) {
        return participant.trim();
      }
    }
    return '';
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _normalizedPriority(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'high' || normalized == 'low' || normalized == 'medium') {
      return normalized;
    }
    return 'medium';
  }
}
