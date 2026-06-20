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

IMPORTANT TASK ASSIGNMENT RULE:
- Detect every person mentioned in the meeting and include them in "participants".
- For every action item or task, assign it to exactly one person or team in the "assignee" field whenever the meeting gives enough evidence.
- If the meeting says that a person will do something, that person must be the assignee for that task.
- Do not leave "assignee" empty if a responsible person is mentioned anywhere near the task.
- Keep tasks separated by owner. If Ahmed has 2 tasks and Sara has 1 task, return 3 task objects with the correct assignee on each one.
- Only leave "assignee" empty when the responsible person is truly unknown.

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
      dev.log('[GeminiService] Processing file: ${file.path}',
          name: 'MeetFlow');
      final bytes = await file.readAsBytes();
      dev.log('[GeminiService] File size: ${bytes.length} bytes',
          name: 'MeetFlow');
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
      dev.log('[GeminiService] Gemini response length: ${text?.length ?? 0}',
          name: 'MeetFlow');

      if (text == null || text.isEmpty) {
        throw AIException(
            message:
                'Gemini returned an empty response. The file may be too large or unsupported.');
      }

      return JsonParser.parseMeetingResult(text);
    } on AIException {
      rethrow;
    } catch (e) {
      dev.log('[GeminiService] ERROR processing file: $e',
          name: 'MeetFlow', error: e);
      final msg = _humanizeError(e);
      throw AIException(message: msg, originalError: e);
    }
  }

  @override
  Future<Map<String, dynamic>> processMeetingUrl(String url) async {
    try {
      final transformedUrl = _transformUrl(url);
      dev.log('[GeminiService] Processing URL: $url (Transformed: $transformedUrl)', name: 'MeetFlow');
      final response = await http.get(Uri.parse(transformedUrl));
      dev.log('[GeminiService] HTTP status: ${response.statusCode}',
          name: 'MeetFlow');

      if (response.statusCode != 200) {
        throw AIException(
            message:
                'Could not fetch content from URL (HTTP ${response.statusCode}).');
      }

      final contentType = response.headers['content-type'] ?? 'text/plain';
      final isTextContent =
          contentType.contains('text') || contentType.contains('json');

      if (isTextContent) {
        final cleanedBody = _stripHtml(response.body);
        final content = [
          Content.text(
              '$_systemPrompt\n\nMeeting transcript:\n$cleanedBody'),
        ];
        final aiResponse = await _model.generateContent(content);
        final text = aiResponse.text;
        if (text == null || text.isEmpty) {
          throw AIException(message: 'Gemini returned empty response.');
        }
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
        if (text == null || text.isEmpty) {
          throw AIException(message: 'Gemini returned empty response.');
        }
        return JsonParser.parseMeetingResult(text);
      }
    } on AIException {
      rethrow;
    } catch (e) {
      dev.log('[GeminiService] ERROR processing URL: $e',
          name: 'MeetFlow', error: e);
      final msg = _humanizeError(e);
      throw AIException(message: msg, originalError: e);
    }
  }

  /// Converts raw exceptions into human-readable messages.
  String _humanizeError(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('api_key') ||
        str.contains('api key') ||
        str.contains('invalid_api_key')) {
      return 'Invalid Gemini API key. Check your Firebase AI Logic setup in the Firebase Console.';
    }
    if (str.contains('quota') || str.contains('resource_exhausted')) {
      return 'Gemini API quota exceeded. Try again later or check your billing.';
    }
    if (str.contains('unable to resolve host') ||
        str.contains('socketexception') ||
        str.contains('network')) {
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
    if (contentType.contains('audio/')) {
      return contentType.split(';').first.trim();
    }
    if (contentType.contains('video/')) {
      return contentType.split(';').first.trim();
    }
    return 'application/octet-stream';
  }

  String _transformUrl(String url) {
    var targetUrl = url.trim();
    
    // Google Drive
    final driveRegExp1 = RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
    final driveRegExp2 = RegExp(r'drive\.google\.com/open\?id=([a-zA-Z0-9_-]+)');
    
    final match1 = driveRegExp1.firstMatch(targetUrl);
    if (match1 != null) {
      final fileId = match1.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    
    final match2 = driveRegExp2.firstMatch(targetUrl);
    if (match2 != null) {
      final fileId = match2.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    
    // Dropbox
    if (targetUrl.contains('dropbox.com')) {
      if (targetUrl.endsWith('dl=0')) {
        return targetUrl.substring(0, targetUrl.length - 4) + 'dl=1';
      } else if (!targetUrl.contains('dl=1')) {
        if (targetUrl.contains('?')) {
          return '$targetUrl&dl=1';
        } else {
          return '$targetUrl?dl=1';
        }
      }
    }
    
    return targetUrl;
  }

  String _stripHtml(String html) {
    var text = html;
    text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    text = text.replaceAll('&nbsp;', ' ')
               .replaceAll('&amp;', '&')
               .replaceAll('&lt;', '<')
               .replaceAll('&gt;', '>')
               .replaceAll('&quot;', '"')
               .replaceAll('&#39;', "'");
    return text.trim();
  }
}
