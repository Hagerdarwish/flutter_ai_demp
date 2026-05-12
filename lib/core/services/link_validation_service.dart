import '../constants/app_constants.dart';

/// Validates URLs pasted by the user.
/// Detects invite links and rejects them for MVP.
class LinkValidationService {
  const LinkValidationService();

  /// Returns true if the link is a known unsupported invite link.
  bool isInviteLink(String url) {
    final lower = url.toLowerCase();
    return AppConstants.inviteLinkPatterns.any((pattern) => lower.contains(pattern));
  }

  /// Returns true if the URL appears to be a valid http/https URL.
  bool isValidUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  /// Infers source name from a URL (e.g., hostname).
  String getSourceName(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri?.host ?? url;
  }
}
