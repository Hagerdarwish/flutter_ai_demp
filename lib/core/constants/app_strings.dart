/// All user-facing strings in one place.
/// Avoid hardcoding strings inside widgets.
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'MeetFlow AI';
  static const String appTagline = 'Turn meetings into structured actions';

  // Auth
  static const String login = 'Sign In';
  static const String register = 'Create Account';
  static const String logout = 'Sign Out';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String emailLabel = 'Email address';
  static const String passwordLabel = 'Password';
  static const String nameLabel = 'Full name';
  static const String confirmPassword = 'Confirm password';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signInHere = 'Sign in';
  static const String signUpHere = 'Sign up';
  static const String resetEmailSent = 'Password reset email sent. Check your inbox.';

  // Home
  static const String welcome = 'Welcome back';
  static const String homeTitle = 'Dashboard';
  static const String totalMeetings = 'Total Meetings';
  static const String completedSummaries = 'Completed';
  static const String pendingTasks = 'Pending Tasks';
  static const String decisionsCapured = 'Decisions';
  static const String recentMeetings = 'Recent Meetings';
  static const String taskOverview = 'Task Overview';
  static const String quickActions = 'Quick Actions';
  static const String viewAll = 'View All';

  // Quick actions
  static const String uploadAudio = 'Upload Recording';
  static const String pasteLink = 'Paste Link';
  static const String allMeetings = 'All Meetings';
  static const String allTasks = 'All Tasks';

  // Import
  static const String importMeeting = 'Import Meeting';
  static const String uploadFile = 'Upload Audio / Video';
  static const String uploadFileDesc = 'Select an mp3, wav, m4a, mp4, or mov file';
  static const String pasteMeetingLink = 'Paste Meeting Link';
  static const String pasteMeetingLinkDesc = 'Public recording, audio or transcript URL';
  static const String meetingTitle = 'Meeting title (optional)';
  static const String meetingDate = 'Meeting date (optional)';
  static const String generateSummary = 'Generate Summary';
  static const String processing = 'Analyzing with AI…';
  static const String browseFile = 'Browse File';
  static const String pasteUrl = 'Paste URL here';
  static const String inviteLinkWarning =
      'This looks like a meeting invite link. Please upload the meeting recording or paste a public recording/transcript link.';
  static const String fileTooLarge = 'File is too large. Maximum allowed size is 50 MB.';
  static const String unsupportedFormat = 'Unsupported file format. Allowed: mp3, wav, m4a, mp4, mov.';

  // Meetings
  static const String meetings = 'Meetings';
  static const String meetingDetails = 'Meeting Details';
  static const String summary = 'Summary';
  static const String detailedSummary = 'Detailed Summary';
  static const String minutesOfMeeting = 'Minutes of Meeting';
  static const String decisions = 'Decisions';
  static const String tasks = 'Tasks';
  static const String participants = 'Participants';
  static const String followUps = 'Follow-ups';
  static const String deleteMeeting = 'Delete Meeting';
  static const String copyText = 'Copy Text';
  static const String exportMarkdown = 'Export as Markdown';
  static const String confirmDelete = 'Are you sure you want to delete this meeting?';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';
  static const String noMeetings = 'No meetings yet';
  static const String noMeetingsDesc =
      'Upload your first meeting recording to generate AI-powered meeting documentation.';

  // Tasks
  static const String taskTitle = 'Tasks';
  static const String noTasks = 'No tasks yet';
  static const String noTasksDesc = 'Tasks extracted from your meetings will appear here.';
  static const String markCompleted = 'Mark as Completed';
  static const String markInProgress = 'Mark as In Progress';

  // Status labels
  static const String draft = 'Draft';
  static const String processingStatus = 'Processing';
  static const String completed = 'Completed';
  static const String failed = 'Failed';

  // Priority labels
  static const String low = 'Low';
  static const String medium = 'Medium';
  static const String high = 'High';

  // Task status labels
  static const String pending = 'Pending';
  static const String inProgress = 'In Progress';

  // Settings
  static const String settings = 'Settings';
  static const String profile = 'Profile';
  static const String themeMode = 'Theme';
  static const String lightTheme = 'Light';
  static const String darkTheme = 'Dark';
  static const String systemTheme = 'System';
  static const String aboutApp = 'About MeetFlow AI';
  static const String apiInfo = 'AI powered by Gemini — Google AI';
  static const String privacyNote = 'Your recordings are processed by AI and never stored on our servers.';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Check your connection.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String aiError = 'AI processing failed. Please try again.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String passwordTooShort = 'Password must be at least 8 characters.';
  static const String passwordsDoNotMatch = 'Passwords do not match.';
  static const String fieldRequired = 'This field is required.';
  static const String retry = 'Retry';
}
