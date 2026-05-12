import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/meeting_import_provider.dart';

class ImportMeetingPage extends ConsumerStatefulWidget {
  const ImportMeetingPage({super.key});

  @override
  ConsumerState<ImportMeetingPage> createState() => _ImportMeetingPageState();
}

class _ImportMeetingPageState extends ConsumerState<ImportMeetingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  DateTime? _selectedDate;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  String? get _dateString =>
      _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(meetingImportProvider);

    ref.listen(meetingImportProvider, (_, next) {
      if (next.step == ImportStep.done && next.createdMeetingId != null) {
        ref.read(meetingImportProvider.notifier).reset();
        context.pushReplacement('/meetings/${next.createdMeetingId}');
      }
    });

    final isProcessing = importState.step != ImportStep.idle &&
        importState.step != ImportStep.done &&
        importState.step != ImportStep.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.importMeeting),
        leading: BackButton(onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file_rounded), text: 'Upload File'),
            Tab(icon: Icon(Icons.link_rounded), text: 'Paste Link'),
          ],
        ),
      ),
      body: isProcessing
          ? _buildProcessingView(importState.step)
          : importState.step == ImportStep.error
              ? _buildErrorView(importState.errorMessage)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _UploadFileTab(
                      titleCtrl: _titleCtrl,
                      selectedDate: _selectedDate,
                      dateString: _dateString,
                      onPickDate: _pickDate,
                      selectedFile: importState.selectedFile,
                    ),
                    _PasteLinkTab(
                      titleCtrl: _titleCtrl,
                      urlCtrl: _urlCtrl,
                      selectedDate: _selectedDate,
                      dateString: _dateString,
                      urlError: _urlError,
                      onPickDate: _pickDate,
                      onUrlChanged: (url) {
                        final notifier = ref.read(meetingImportProvider.notifier);
                        setState(() => _urlError = notifier.validateUrl(url));
                      },
                    ),
                  ],
                ),
      bottomNavigationBar: isProcessing || importState.step == ImportStep.error
          ? null
          : _buildBottomBar(importState.selectedFile),
    );
  }

  Widget _buildProcessingView(ImportStep step) {
    final messages = {
      ImportStep.pickingFile: 'Selecting file…',
      ImportStep.uploading: 'Preparing meeting…',
      ImportStep.processing: 'Analyzing with Gemini AI…',
      ImportStep.saving: 'Saving results…',
    };
    return Center(
      child: ProcessingCard(message: messages[step] ?? 'Processing…'),
    );
  }

  Widget _buildErrorView(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Processing Failed', style: AppTextStyles.headlineSmall(context)),
            const SizedBox(height: 8),
            Text(error ?? AppStrings.aiError,
                style: AppTextStyles.bodyMedium(context), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            AppButton(
              label: 'Try Again',
              onPressed: () => ref.read(meetingImportProvider.notifier).reset(),
              variant: AppButtonVariant.outlined,
              width: 180,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(File? selectedFile) {
    final isFileTab = _tabController.index == 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AppButton(
          label: AppStrings.generateSummary,
          leadingIcon: Icons.auto_awesome_rounded,
          onPressed: isFileTab
              ? (selectedFile == null ? null : _generateFromFile)
              : _generateFromUrl,
        ),
      ),
    );
  }

  Future<void> _generateFromFile() async {
    final file = ref.read(meetingImportProvider).selectedFile;
    if (file == null) return;
    await ref.read(meetingImportProvider.notifier).processFile(
          file: file,
          title: _titleCtrl.text,
          date: _dateString,
        );
  }

  Future<void> _generateFromUrl() async {
    final url = _urlCtrl.text.trim();
    final error = ref.read(meetingImportProvider.notifier).validateUrl(url);
    if (error != null) {
      setState(() => _urlError = error);
      return;
    }
    await ref.read(meetingImportProvider.notifier).processUrl(
          url: url,
          title: _titleCtrl.text,
          date: _dateString,
        );
  }
}

// --- Upload File Tab ---
class _UploadFileTab extends ConsumerWidget {
  final TextEditingController titleCtrl;
  final DateTime? selectedDate;
  final String? dateString;
  final VoidCallback onPickDate;
  final File? selectedFile;

  const _UploadFileTab({
    required this.titleCtrl,
    required this.selectedDate,
    required this.dateString,
    required this.onPickDate,
    required this.selectedFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // File picker card
          GestureDetector(
            onTap: () => ref.read(meetingImportProvider.notifier).pickFile(),
            child: AnimatedContainer(
              duration: 300.ms,
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: selectedFile != null
                    ? AppColors.success.withValues(alpha: 0.06)
                    : AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedFile != null ? AppColors.success : AppColors.primary,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    selectedFile != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                    size: 48,
                    color: selectedFile != null ? AppColors.success : AppColors.primary,
                  ).animate(key: ValueKey(selectedFile)).scale(duration: 300.ms),
                  const SizedBox(height: 16),
                  Text(
                    selectedFile != null
                        ? selectedFile!.path.split('/').last
                        : AppStrings.uploadFile,
                    style: AppTextStyles.titleSmall(context).copyWith(
                      color: selectedFile != null ? AppColors.success : AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedFile != null ? 'Tap to change file' : AppStrings.uploadFileDesc,
                    style: AppTextStyles.bodySmall(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          AppTextField(
            controller: titleCtrl,
            label: AppStrings.meetingTitle,
            hint: 'e.g. Q2 Planning Session',
            prefixIcon: const Icon(Icons.title_rounded, size: 20),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          AppTextField(
            label: AppStrings.meetingDate,
            readOnly: true,
            onTap: onPickDate,
            initialValue: selectedDate != null
                ? DateFormat('MMM d, yyyy').format(selectedDate!)
                : null,
            hint: 'Select date',
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// --- Paste Link Tab ---
class _PasteLinkTab extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController urlCtrl;
  final DateTime? selectedDate;
  final String? dateString;
  final String? urlError;
  final VoidCallback onPickDate;
  final void Function(String) onUrlChanged;

  const _PasteLinkTab({
    required this.titleCtrl,
    required this.urlCtrl,
    required this.selectedDate,
    required this.dateString,
    required this.urlError,
    required this.onPickDate,
    required this.onUrlChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Paste a public recording URL, direct audio/video link, or transcript URL.',
                    style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 20),
          TextFormField(
            controller: urlCtrl,
            onChanged: onUrlChanged,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: AppStrings.pasteMeetingLink,
              hintText: AppStrings.pasteUrl,
              prefixIcon: const Icon(Icons.link_rounded, size: 20),
              errorText: urlError,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          AppTextField(
            controller: titleCtrl,
            label: AppStrings.meetingTitle,
            hint: 'e.g. Team Standup',
            prefixIcon: const Icon(Icons.title_rounded, size: 20),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 16),
          AppTextField(
            label: AppStrings.meetingDate,
            readOnly: true,
            onTap: onPickDate,
            initialValue: selectedDate != null
                ? DateFormat('MMM d, yyyy').format(selectedDate!)
                : null,
            hint: 'Select date',
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
