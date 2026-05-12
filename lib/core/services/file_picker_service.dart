import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

class FilePickerService {
  const FilePickerService();

  /// Opens the native file picker and returns the selected file.
  /// Throws [FileException] on validation failure.
  Future<File?> pickMeetingFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedExtensions,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;

    final ext = picked.extension?.toLowerCase() ?? '';
    if (!AppConstants.allowedExtensions.contains(ext)) {
      throw FileException(message: 'Unsupported file format. Allowed: mp3, wav, m4a, mp4, mov.');
    }

    if (picked.size > AppConstants.maxFileSizeBytes) {
      throw FileException(message: 'File is too large. Maximum allowed size is 50 MB.');
    }

    return File(picked.path!);
  }

  String getFileName(File file) => file.path.split('/').last;
  String getFileExtension(File file) => file.path.split('.').last.toLowerCase();
}
