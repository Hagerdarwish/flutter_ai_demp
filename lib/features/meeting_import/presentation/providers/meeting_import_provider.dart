import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../../../core/services/link_validation_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../meetings/data/repositories/meetings_repository_impl.dart';
import '../../../meetings/domain/entities/meeting.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../meetings/presentation/providers/meetings_provider.dart';

enum ImportStep { idle, pickingFile, uploading, processing, saving, done, error }

class ImportState {
  final ImportStep step;
  final String? errorMessage;
  final String? createdMeetingId;
  final File? selectedFile;
  final String? selectedUrl;

  const ImportState({
    this.step = ImportStep.idle,
    this.errorMessage,
    this.createdMeetingId,
    this.selectedFile,
    this.selectedUrl,
  });

  ImportState copyWith({
    ImportStep? step,
    String? errorMessage,
    String? createdMeetingId,
    File? selectedFile,
    String? selectedUrl,
  }) {
    return ImportState(
      step: step ?? this.step,
      errorMessage: errorMessage,
      createdMeetingId: createdMeetingId ?? this.createdMeetingId,
      selectedFile: selectedFile ?? this.selectedFile,
      selectedUrl: selectedUrl ?? this.selectedUrl,
    );
  }
}

class MeetingImportNotifier extends StateNotifier<ImportState> {
  final GeminiService _gemini;
  final FilePickerService _filePicker;
  final LinkValidationService _linkValidator;
  final MeetingsRepository _meetings;
  final String _userId;
  MeetingImportNotifier({
    required GeminiService gemini,
    required FilePickerService filePicker,
    required LinkValidationService linkValidator,
    required MeetingsRepository meetings,
    required String userId,
  })  : _gemini = gemini,
        _filePicker = filePicker,
        _linkValidator = linkValidator,
        _meetings = meetings,
        _userId = userId,
        super(const ImportState());

  Future<File?> pickFile() async {
    state = state.copyWith(step: ImportStep.pickingFile);
    try {
      final file = await _filePicker.pickMeetingFile();
      if (file == null) {
        state = state.copyWith(step: ImportStep.idle);
        return null;
      }
      state = state.copyWith(step: ImportStep.idle, selectedFile: file);
      return file;
    } on FileException catch (e) {
      state = ImportState(step: ImportStep.error, errorMessage: e.message);
      return null;
    }
  }

  void setUrl(String url) {
    state = state.copyWith(selectedUrl: url);
  }

  String? validateUrl(String url) {
    if (!_linkValidator.isValidUrl(url)) return 'Please enter a valid URL.';
    if (_linkValidator.isInviteLink(url)) return AppStrings.inviteLinkWarning;
    return null;
  }

  Future<void> processFile({
    required File file,
    required String title,
    required String? date,
  }) async {
    if (_userId.isEmpty) {
      state = ImportState(step: ImportStep.error, errorMessage: 'Not logged in.');
      return;
    }

    final fileName = file.path.split('/').last;
    final fileExt = file.path.split('.').last.toLowerCase();
    final meetingTitle = title.trim().isNotEmpty ? title.trim() : fileName;
    String? meetingId;

    try {
      // 1. Create draft meeting in Firestore
      state = state.copyWith(step: ImportStep.uploading);
      final draft = Meeting(
        id: '',
        userId: _userId,
        title: meetingTitle,
        sourceType: MeetingSourceType.file,
        sourceName: fileName,
        fileType: fileExt,
        status: MeetingStatus.processing,
        createdAt: date != null ? DateTime.tryParse(date) ?? DateTime.now() : DateTime.now(),
        updatedAt: DateTime.now(),
      );
      meetingId = await _meetings.createDraftMeeting(draft);

      // 2. Send to Gemini
      state = state.copyWith(step: ImportStep.processing);
      final aiResult = await _gemini.processMeetingFile(file);

      // 3. Save result to Firestore
      state = state.copyWith(step: ImportStep.saving);
      await _meetings.saveMeetingResult(
        userId: _userId,
        meetingId: meetingId,
        aiResult: aiResult,
        meetingTitle: meetingTitle,
      );

      state = ImportState(step: ImportStep.done, createdMeetingId: meetingId);
    } on AIException catch (e) {
      // Mark meeting as failed only if we have a valid ID
      if (meetingId != null && meetingId.isNotEmpty) {
        try {
          await _meetings.markMeetingFailed(userId: _userId, meetingId: meetingId);
        } catch (_) {}
      }
      state = ImportState(step: ImportStep.error, errorMessage: e.message);
    } catch (e) {
      if (meetingId != null && meetingId.isNotEmpty) {
        try {
          await _meetings.markMeetingFailed(userId: _userId, meetingId: meetingId);
        } catch (_) {}
      }
      state = ImportState(
        step: ImportStep.error,
        errorMessage: e.toString().contains('Unable to resolve host')
            ? 'No internet connection. Please check your network and try again.'
            : 'Import failed: ${e.toString()}',
      );
    }
  }

  Future<void> processUrl({
    required String url,
    required String title,
    required String? date,
  }) async {
    if (_userId.isEmpty) {
      state = ImportState(step: ImportStep.error, errorMessage: 'Not logged in.');
      return;
    }

    final sourceName = _linkValidator.getSourceName(url);
    final meetingTitle = title.trim().isNotEmpty ? title.trim() : 'Meeting from $sourceName';
    String? meetingId;

    try {
      state = state.copyWith(step: ImportStep.uploading);
      final draft = Meeting(
        id: '',
        userId: _userId,
        title: meetingTitle,
        sourceType: MeetingSourceType.link,
        sourceName: sourceName,
        sourceUrl: url,
        status: MeetingStatus.processing,
        createdAt: date != null ? DateTime.tryParse(date) ?? DateTime.now() : DateTime.now(),
        updatedAt: DateTime.now(),
      );
      meetingId = await _meetings.createDraftMeeting(draft);

      state = state.copyWith(step: ImportStep.processing);
      final aiResult = await _gemini.processMeetingUrl(url);

      state = state.copyWith(step: ImportStep.saving);
      await _meetings.saveMeetingResult(
        userId: _userId,
        meetingId: meetingId,
        aiResult: aiResult,
        meetingTitle: meetingTitle,
      );
      state = ImportState(step: ImportStep.done, createdMeetingId: meetingId);
    } on AIException catch (e) {
      if (meetingId != null && meetingId.isNotEmpty) {
        try { await _meetings.markMeetingFailed(userId: _userId, meetingId: meetingId); } catch (_) {}
      }
      state = ImportState(step: ImportStep.error, errorMessage: e.message);
    } catch (e) {
      if (meetingId != null && meetingId.isNotEmpty) {
        try { await _meetings.markMeetingFailed(userId: _userId, meetingId: meetingId); } catch (_) {}
      }
      state = ImportState(
        step: ImportStep.error,
        errorMessage: e.toString().contains('Unable to resolve host')
            ? 'No internet connection. Please check your network and try again.'
            : 'Import failed: ${e.toString()}',
      );
    }
  }

  void reset() => state = const ImportState();
}

final meetingImportProvider = StateNotifierProvider<MeetingImportNotifier, ImportState>((ref) {
  final user = ref.watch(currentUserProvider);
  return MeetingImportNotifier(
    gemini: GeminiServiceImpl(),
    filePicker: const FilePickerService(),
    linkValidator: const LinkValidationService(),
    meetings: ref.watch(meetingsRepositoryProvider),
    userId: user?.id ?? '',
  );
});
