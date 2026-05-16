import 'dart:io';
import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../utils/json_parser.dart';

/// Abstract Gemini service — swap impl for backend proxy later.
abstract class GeminiService {
  Future<Map<String, dynamic>> processMeetingFile(File file);
  Future<Map<String, dynamic>> processMeetingUrl(String url);
}

/// Firebase AI Logic implementation (replaces deprecated google_generative_ai).
class GeminiServiceImpl implements GeminiService {
  late final GenerativeModel _model;

  GeminiServiceImpl() {
    // Firebase AI handles the API key server-side — no key needed in code!
    final ai = FirebaseAI.googleAI();
    _model = ai.generativeModel(model: AppConstants.geminiModel);
  }

  static const String _systemPrompt = '''
You are an AI meeting documentation assistant.

Analyze the provided meeting audio, video, transcript, or meeting text and return ONLY valid JSON.

IMPORTANT LANGUAGE RULE:
- Detect the primary language spoken or written in the meeting.
- Write ALL output fields (title, summary, decisions, tasks, participants, follow-ups) in that SAME language.
- If the meeting is in Arabic, respond entirely in Arabic.
- If the meeting is in English, respond in English.
- Never translate; always match the meeting language.

Do not include markdown.
Do not include explanations outside JSON.

Return this exact structure:

{
  "title": "short meeting title",
  "shortSummary": "brief summary in 3-5 lines",
  "detailedSummary": "detailed meeting summary",
  "minutesOfMeeting": ["point 1", "point 2"],
  "decisions": [
    {"text": "decision text", "owner": "person or team if mentioned"}
  ],
  "tasks": [
    {
      "title": "task title",
      "description": "task details",
      "assignee": "person or team if mentioned",
      "dueDate": "YYYY-MM-DD or empty string",
      "priority": "low | medium | high",
      "status": "pending"
    }
  ],
  "participants": ["participant name if detected"],
  "followUps": ["follow up point"]
}

If any value is unknown, use an empty string or empty array.
''';

  @override
  Future<Map<String, dynamic>> processMeetingFile(File file) async {
    try {
      dev.log('[GeminiService] Processing file: ${file.path}', name: 'MeetFlow');
      final bytes = await file.readAsBytes();
      dev.log('[GeminiService] File size: ${bytes.length} bytes', name: 'MeetFlow');
      final mimeType = _getMimeType(file.path);
      dev.log('[GeminiService] MIME type: $mimeType', name: 'MeetFlow');

      final content = [
        Content.multi([
          TextPart(_systemPrompt),
          InlineDataPart(mimeType, bytes),
        ]),
      ];

      dev.log('[GeminiService] Sending to Gemini API...', name: 'MeetFlow');
      final response = await _model.generateContent(content);
      final text = response.text;
      dev.log('[GeminiService] Gemini response length: ${text?.length ?? 0}', name: 'MeetFlow');

      if (text == null || text.isEmpty) {
        throw AIException(message: 'Gemini returned an empty response. The file may be too large or unsupported.');
      }

      return JsonParser.parseMeetingResult(text);
    } on AIException {
      rethrow;
    } catch (e) {
      dev.log('[GeminiService] ERROR processing file: $e', name: 'MeetFlow', error: e);
      final msg = _humanizeError(e);
      throw AIException(message: msg, originalError: e);
    }
  }

  @override
  Future<Map<String, dynamic>> processMeetingUrl(String url) async {
    try {
      dev.log('[GeminiService] Processing URL: $url', name: 'MeetFlow');
      final response = await http.get(Uri.parse(url));
      dev.log('[GeminiService] HTTP status: ${response.statusCode}', name: 'MeetFlow');

      if (response.statusCode != 200) {
        throw AIException(message: 'Could not fetch content from URL (HTTP ${response.statusCode}).');
      }

      final contentType = response.headers['content-type'] ?? 'text/plain';
      final isTextContent = contentType.contains('text') || contentType.contains('json');

      if (isTextContent) {
        final content = [
          Content.text('$_systemPrompt\n\nMeeting transcript:\n${response.body}'),
        ];
        final aiResponse = await _model.generateContent(content);
        final text = aiResponse.text;
        if (text == null || text.isEmpty) throw AIException(message: 'Gemini returned empty response.');
        return JsonParser.parseMeetingResult(text);
      } else {
        final mimeType = _mimeFromContentType(contentType);
        final bytes = Uint8List.fromList(response.bodyBytes);
        final content = [
          Content.multi([
            TextPart(_systemPrompt),
            InlineDataPart(mimeType, bytes),
          ]),
        ];
        final aiResponse = await _model.generateContent(content);
        final text = aiResponse.text;
        if (text == null || text.isEmpty) throw AIException(message: 'Gemini returned empty response.');
        return JsonParser.parseMeetingResult(text);
      }
    } on AIException {
      rethrow;
    } catch (e) {
      dev.log('[GeminiService] ERROR processing URL: $e', name: 'MeetFlow', error: e);
      final msg = _humanizeError(e);
      throw AIException(message: msg, originalError: e);
    }
  }

  /// Converts raw exceptions into human-readable messages.
  String _humanizeError(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('api_key') || str.contains('api key') || str.contains('invalid_api_key')) {
      return 'Invalid Gemini API key. Check your Firebase AI Logic setup in the Firebase Console.';
    }
    if (str.contains('quota') || str.contains('resource_exhausted')) {
      return 'Gemini API quota exceeded. Try again later or check your billing.';
    }
    if (str.contains('unable to resolve host') || str.contains('socketexception') || str.contains('network')) {
      return 'No internet connection. Connect your device/emulator to the internet and try again.';
    }
    if (str.contains('timeout')) {
      return 'Request timed out. The file may be too large. Try a smaller file.';
    }
    if (str.contains('unsupported') || str.contains('invalid mime')) {
      return 'Unsupported file type. Please use MP3, WAV, M4A, MP4, or MOV.';
    }
    if (str.contains('too large') || str.contains('payload')) {
      return 'File is too large for direct processing. Please use a file under 20MB.';
    }
    return 'AI processing failed: $e';
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/m4a';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  String _mimeFromContentType(String contentType) {
    if (contentType.contains('audio/')) return contentType.split(';').first.trim();
    if (contentType.contains('video/')) return contentType.split(';').first.trim();
    return 'application/octet-stream';
  }
}
