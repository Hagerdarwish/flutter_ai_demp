class AppConstants {
  AppConstants._();

  static const String appName = 'MeetFlow AI';
  static const String appVersion = '1.0.0';

  // Gemini — firebase_ai manages API key server-side
  // Model name: gemini-2.5-flash (2.0 shuts down June 1, 2026)
  static const String geminiModel = 'gemini-2.5-flash';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String meetingsCollection = 'meetings';
  static const String decisionsCollection = 'decisions';
  static const String tasksCollection = 'tasks';

  // Allowed file types
  static const List<String> allowedAudioExtensions = ['mp3', 'wav', 'm4a'];
  static const List<String> allowedVideoExtensions = ['mp4', 'mov'];
  static const List<String> allowedExtensions = ['mp3', 'wav', 'm4a', 'mp4', 'mov'];

  // Max file size: 50 MB
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  // Recent meetings count on home
  static const int recentMeetingsLimit = 5;

  // Known invite link patterns
  static const List<String> inviteLinkPatterns = [
    'meet.google.com',
    'zoom.us/j/',
    'zoom.us/my/',
    'teams.microsoft.com',
    'webex.com/meet/',
  ];
}
