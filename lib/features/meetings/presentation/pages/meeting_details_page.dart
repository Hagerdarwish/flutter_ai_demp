import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/smart_text.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/task_email_service.dart';
import '../providers/meetings_provider.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/decision.dart';
import '../../../../features/tasks/domain/entities/meeting_task.dart';
import '../../../../features/tasks/presentation/providers/tasks_provider.dart';

// --- Enum mapping helpers ---
WidgetTaskPriority _toWidgetPriority(TaskPriority p) => switch (p) {
      TaskPriority.low => WidgetTaskPriority.low,
      TaskPriority.medium => WidgetTaskPriority.medium,
      TaskPriority.high => WidgetTaskPriority.high,
    };

class MeetingDetailsPage extends ConsumerWidget {
  final String meetingId;
  const MeetingDetailsPage({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingAsync = ref.watch(meetingDetailsProvider(meetingId));

    return meetingAsync.when(
      data: (meeting) => _MeetingDetailsView(meeting: meeting),
      loading: () => Scaffold(appBar: AppBar(), body: const AppLoader()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: 'Failed to load meeting.',
          onRetry: () => ref.refresh(meetingDetailsProvider(meetingId)),
        ),
      ),
    );
  }
}

class _MeetingDetailsView extends ConsumerWidget {
  final Meeting meeting;
  const _MeetingDetailsView({required this.meeting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decisionsAsync = ref.watch(meetingDecisionsProvider(meeting.id));
    final tasksAsync = ref.watch(meetingTasksProvider(meeting.id));

    return Scaffold(
      appBar: AppBar(
        title:
            Text(meeting.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Summary',
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: _buildMarkdownExport(meeting)));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            tooltip: 'Delete Meeting',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: meeting.status != MeetingStatus.completed
          ? _buildNonCompletedState(context, meeting)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeaderCard(context, meeting).animate().fadeIn(),
                const SizedBox(height: 16),
                _SectionCard(
                  title: AppStrings.summary,
                  icon: Icons.summarize_rounded,
                  child: SmartText(meeting.shortSummary,
                      style: AppTextStyles.bodyLarge(context)),
                ).animate().fadeIn(delay: 80.ms),
                const SizedBox(height: 12),
                if (meeting.detailedSummary.isNotEmpty)
                  _ExpandableSection(
                    title: AppStrings.detailedSummary,
                    icon: Icons.article_rounded,
                    child: SmartText(meeting.detailedSummary,
                        style: AppTextStyles.bodyMedium(context)),
                  ).animate().fadeIn(delay: 120.ms),
                if (meeting.minutesOfMeeting.isNotEmpty)
                  _ExpandableSection(
                    title: AppStrings.minutesOfMeeting,
                    icon: Icons.format_list_bulleted_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: meeting.minutesOfMeeting
                          .map((p) => SmartBulletPoint(p))
                          .toList(),
                    ),
                  ).animate().fadeIn(delay: 160.ms),
                decisionsAsync.when(
                  data: (decisions) => decisions.isEmpty
                      ? const SizedBox.shrink()
                      : _ExpandableSection(
                          title: AppStrings.decisions,
                          icon: Icons.gavel_rounded,
                          child: Column(
                            children: decisions
                                .map((d) => _DecisionTile(decision: d))
                                .toList(),
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                  loading: () => const ShimmerCard(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                tasksAsync.when(
                  data: (tasks) => Column(
                    children: [
                      if (tasks.isNotEmpty)
                        _ExpandableSection(
                          title: AppStrings.tasks,
                          icon: Icons.task_alt_rounded,
                          child: Column(
                            children: tasks
                                .map(
                                  (t) => _TaskTile(
                                    task: t,
                                    participantOptions: meeting.participants,
                                  ),
                                )
                                .toList(),
                          ),
                        ).animate().fadeIn(delay: 240.ms),
                      if (meeting.participants.isNotEmpty ||
                          tasks.isNotEmpty) ...[
                        if (tasks.isNotEmpty) const SizedBox(height: 12),
                        _ParticipantEmailSection(meeting: meeting, tasks: tasks)
                            .animate()
                            .fadeIn(delay: 260.ms),
                      ],
                    ],
                  ),
                  loading: () => const ShimmerCard(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                if (meeting.participants.isNotEmpty)
                  _SectionCard(
                    title: AppStrings.participants,
                    icon: Icons.people_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: meeting.participants
                          .map((p) => Chip(
                                label: Text(p, style: TextStyle(color: AppColors.primary)),
                                avatar: const Icon(Icons.person_rounded, size: 16),
                              ))
                          .toList(),
                    ),
                  ).animate().fadeIn(delay: 280.ms),
                if (meeting.followUps.isNotEmpty)
                  _ExpandableSection(
                    title: AppStrings.followUps,
                    icon: Icons.update_rounded,
                    child: Column(
                      children: meeting.followUps
                          .map((f) => SmartBulletPoint(f))
                          .toList(),
                    ),
                  ).animate().fadeIn(delay: 320.ms),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Meeting meeting) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.meeting_room_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Meeting Details',
                  style: AppTextStyles.labelMedium(context)
                      .copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          Text(meeting.title,
              style: AppTextStyles.titleLarge(context)
                  .copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(DateFormatter.formatDate(meeting.createdAt),
                  style: AppTextStyles.bodySmall(context)
                      .copyWith(color: Colors.white70)),
              const SizedBox(width: 16),
              const Icon(Icons.source_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  meeting.sourceName.isNotEmpty ? meeting.sourceName : meeting.fileType,
                  style: AppTextStyles.bodySmall(context).copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNonCompletedState(BuildContext context, Meeting meeting) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (meeting.status == MeetingStatus.processing) ...[
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Processing meeting…',
                  style: AppTextStyles.titleMedium(context)),
            ] else if (meeting.status == MeetingStatus.failed) ...[
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Processing Failed',
                  style: AppTextStyles.headlineSmall(context)),
              const SizedBox(height: 8),
              Text('This meeting could not be processed by AI.',
                  style: AppTextStyles.bodyMedium(context)),
            ] else ...[
              const Icon(Icons.edit_note_rounded,
                  size: 64, color: AppColors.statusDraft),
              const SizedBox(height: 16),
              Text('Draft Meeting',
                  style: AppTextStyles.headlineSmall(context)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteMeeting),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(meetingActionsProvider.notifier).deleteMeeting(meeting.id);
      if (context.mounted) context.pop();
    }
  }

  String _buildMarkdownExport(Meeting meeting) {
    final buf = StringBuffer();
    buf.writeln('# ${meeting.title}\n');
    buf.writeln('**Date:** ${DateFormatter.formatDate(meeting.createdAt)}\n');
    buf.writeln('## Summary\n${meeting.shortSummary}\n');
    if (meeting.detailedSummary.isNotEmpty) {
      buf.writeln('## Detailed Summary\n${meeting.detailedSummary}\n');
    }
    if (meeting.minutesOfMeeting.isNotEmpty) {
      buf.writeln('## Minutes of Meeting');
      for (final p in meeting.minutesOfMeeting) {
        buf.writeln('- $p');
      }
      buf.writeln();
    }
    if (meeting.participants.isNotEmpty) {
      buf.writeln('## Participants');
      for (final p in meeting.participants) {
        buf.writeln('- $p');
      }
      buf.writeln();
    }
    if (meeting.followUps.isNotEmpty) {
      buf.writeln('## Follow-ups');
      for (final f in meeting.followUps) {
        buf.writeln('- $f');
      }
    }
    return buf.toString();
  }
}

// --- Reusable Section Widgets ---
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: AppTextStyles.titleSmall(context)
                        .copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _ExpandableSection(
      {required this.title, required this.icon, required this.child});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.title,
                        style: AppTextStyles.titleSmall(context)
                            .copyWith(color: AppColors.primary)),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(16), child: widget.child),
          ],
        ],
      ),
    );
  }
}

class _DecisionTile extends StatelessWidget {
  final Decision decision;
  const _DecisionTile({required this.decision});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmartText(
            decision.text,
            style: AppTextStyles.bodyMedium(context)
                .copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          if (decision.owner.isNotEmpty) ...[
            const SizedBox(height: 4),
            SmartText('Owner: ${decision.owner}',
                style: AppTextStyles.labelSmall(context)),
          ],
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final MeetingTask task;
  final List<String> participantOptions;
  const _TaskTile({required this.task, required this.participantOptions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: SmartText(task.title,
                      style: AppTextStyles.titleSmall(context))),
              PriorityChip(priority: _toWidgetPriority(task.priority)),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            SmartText(
              task.description,
              style: AppTextStyles.bodySmall(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              if (task.assignee.isNotEmpty) ...[
                const Icon(Icons.person_outline_rounded,
                    size: 12, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                SmartText(task.assignee,
                    style: AppTextStyles.labelSmall(context)),
                const SizedBox(width: 12),
              ],
              TextButton.icon(
                onPressed: () => _showAssignDialog(context, ref),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                label: Text(
                  task.assignee.isEmpty ? 'Assign' : 'Change',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const Spacer(),
              if (task.dueDate.isNotEmpty) ...[
                const Icon(Icons.calendar_today_rounded,
                    size: 12, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(DateFormatter.formatDueDate(task.dueDate),
                    style: AppTextStyles.labelSmall(context)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: task.assignee);
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final suggestions = participantOptions
                .where((name) => name.trim().isNotEmpty)
                .toSet()
                .toList()
              ..sort();

            return AlertDialog(
              title: const Text('Assign Task'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: controller,
                      label: 'Assignee name',
                      hint: 'Write a name',
                      prefixIcon:
                          const Icon(Icons.person_outline_rounded, size: 20),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Detected names',
                        style: AppTextStyles.labelMedium(context),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: suggestions
                            .map(
                              (name) => ActionChip(
                                label: Text(name),
                                onPressed: () {
                                  controller.text = name;
                                  setState(() {});
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, ''),
                  child: const Text('Clear'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, controller.text.trim()),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (selected == null) return;

    await ref.read(tasksNotifierProvider.notifier).updateAssignee(
          taskId: task.id,
          meetingId: task.meetingId,
          assignee: selected,
        );
    ref.invalidate(meetingTasksProvider(task.meetingId));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selected.isEmpty
              ? 'Task assignment cleared.'
              : 'Task assigned to $selected.',
        ),
      ),
    );
  }
}

class _ParticipantEmailSection extends ConsumerStatefulWidget {
  final Meeting meeting;
  final List<MeetingTask> tasks;

  const _ParticipantEmailSection({
    required this.meeting,
    required this.tasks,
  });

  @override
  ConsumerState<_ParticipantEmailSection> createState() =>
      _ParticipantEmailSectionState();
}

class _ParticipantEmailSectionState
    extends ConsumerState<_ParticipantEmailSection> {
  final _emailService = const TaskEmailService();
  final Map<String, TextEditingController> _controllers = {};
  CorrespondenceLanguage _language = CorrespondenceLanguage.english;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _ParticipantEmailSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _detectedNames {
    final names = <String>{...widget.meeting.participants};
    for (final task in widget.tasks) {
      final assignee = task.assignee.trim();
      if (assignee.isNotEmpty) {
        names.add(assignee);
      }
    }
    return names.where((name) => name.trim().isNotEmpty).toList()..sort();
  }

  void _syncControllers() {
    final names = _detectedNames.toSet();

    for (final name in names) {
      final nextValue = widget.meeting.participantEmails[name] ?? '';
      final controller = _controllers[name];
      if (controller == null) {
        _controllers[name] = TextEditingController(text: nextValue);
      } else if (controller.text.trim() != nextValue.trim()) {
        controller.text = nextValue;
      }
    }

    final staleNames =
        _controllers.keys.where((name) => !names.contains(name)).toList();
    for (final name in staleNames) {
      _controllers.remove(name)?.dispose();
    }
  }

  Map<String, String> _collectParticipantEmails() {
    final emails = <String, String>{};
    for (final entry in _controllers.entries) {
      final name = entry.key.trim();
      final email = entry.value.text.trim();
      if (name.isNotEmpty && email.isNotEmpty) {
        emails[name] = email;
      }
    }
    return emails;
  }

  List<MeetingTask> _tasksFor(String assignee) {
    final normalized = assignee.trim().toLowerCase();
    return widget.tasks
        .where((task) => task.assignee.trim().toLowerCase() == normalized)
        .toList();
  }

  Future<void> _saveEmails() async {
    final emails = _collectParticipantEmails();

    for (final entry in emails.entries) {
      final error = Validators.email(entry.value);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid email for ${entry.key}: $error')),
        );
        return;
      }
    }

    await ref
        .read(meetingActionsProvider.notifier)
        .saveParticipantEmails(widget.meeting.id, emails);

    ref.invalidate(meetingDetailsProvider(widget.meeting.id));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Participant emails saved for future meetings.')),
    );
  }

  Future<void> _sendTasksEmail(String recipientName) async {
    final recipientEmail = _controllers[recipientName]?.text.trim() ?? '';
    final emailError = Validators.email(recipientEmail);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add a valid email for $recipientName first.')),
      );
      return;
    }

    final tasks = _tasksFor(recipientName);
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No detected tasks found for $recipientName.')),
      );
      return;
    }

    final launched = await _emailService.composeTaskEmail(
      meeting: widget.meeting,
      recipientName: recipientName,
      recipientEmail: recipientEmail,
      tasks: tasks,
      language: _language,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          launched
              ? _language == CorrespondenceLanguage.arabic
                  ? 'تم فتح مسودة البريد لـ $recipientName.'
                  : 'Email draft opened for $recipientName.'
              : 'Could not open the email app.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_detectedNames.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: _language == CorrespondenceLanguage.arabic
          ? 'الأشخاص والمهام والبريد'
          : 'People, Tasks & Emails',
      icon: Icons.alternate_email_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _language == CorrespondenceLanguage.arabic
                ? 'احفظ بريداً إلكترونياً لكل اسم تم اكتشافه. سيتم تجهيز رسالة لكل شخص تحتوي فقط على مهامه.'
                : 'Save an email for each detected name. MeetFlow will prepare one email per person with only that person\'s tasks.',
            style: AppTextStyles.bodySmall(context),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('English'),
                selected: _language == CorrespondenceLanguage.english,
                onSelected: (_) {
                  setState(() => _language = CorrespondenceLanguage.english);
                },
              ),
              ChoiceChip(
                label: const Text('العربية'),
                selected: _language == CorrespondenceLanguage.arabic,
                onSelected: (_) {
                  setState(() => _language = CorrespondenceLanguage.arabic);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final name in _detectedNames) ...[
            _ParticipantEmailRow(
              name: name,
              controller: _controllers[name]!,
              tasks: _tasksFor(name),
              language: _language,
              onSendEmail: () => _sendTasksEmail(name),
              emailPreview: _emailService.buildTaskEmailPreview(
                meeting: widget.meeting,
                recipientName: name,
                tasks: _tasksFor(name),
                language: _language,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saveEmails,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Emails'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantEmailRow extends StatelessWidget {
  final String name;
  final TextEditingController controller;
  final List<MeetingTask> tasks;
  final CorrespondenceLanguage language;
  final VoidCallback onSendEmail;
  final String emailPreview;

  const _ParticipantEmailRow({
    required this.name,
    required this.controller,
    required this.tasks,
    required this.language,
    required this.onSendEmail,
    required this.emailPreview,
  });

  @override
  Widget build(BuildContext context) {
    final hasTasks = tasks.isNotEmpty;
    final isArabic = language == CorrespondenceLanguage.arabic;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.titleSmall(context),
                ),
              ),
              if (hasTasks)
                Text(
                  isArabic
                      ? '${tasks.length} مهمة'
                      : '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                  style: AppTextStyles.labelSmall(context),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: controller,
            label: isArabic ? 'البريد الإلكتروني لـ $name' : 'Email for $name',
            hint: 'name@company.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
          ),
          const SizedBox(height: 10),
          _PersonTaskDigest(
            personName: name,
            tasks: tasks,
            language: language,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasTasks)
                OutlinedButton.icon(
                  onPressed: onSendEmail,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(isArabic ? 'إرسال المهام' : 'Email Tasks'),
                ),
            ],
          ),
          if (hasTasks) ...[
            const SizedBox(height: 10),
            Text(
              emailPreview,
              style: AppTextStyles.bodySmall(context),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _PersonTaskDigest extends StatelessWidget {
  final String personName;
  final List<MeetingTask> tasks;
  final CorrespondenceLanguage language;

  const _PersonTaskDigest({
    required this.personName,
    required this.tasks,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = language == CorrespondenceLanguage.arabic;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'المهام الخاصة بـ $personName' : 'Tasks for $personName',
            style: AppTextStyles.titleSmall(context),
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Text(
              isArabic
                  ? 'لا توجد مهام مرتبطة بهذا الشخص حالياً.'
                  : 'No tasks are currently assigned to this person.',
              style: AppTextStyles.bodySmall(context),
            ),
          for (final task in tasks) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 8, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SmartText(
                        task.title,
                        style: AppTextStyles.bodyMedium(context),
                      ),
                      if (task.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: SmartText(
                            task.description,
                            style: AppTextStyles.bodySmall(context),
                          ),
                        ),
                      if (task.dueDate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            isArabic
                                ? 'تاريخ الاستحقاق: ${DateFormatter.formatDueDate(task.dueDate)}'
                                : 'Due date: ${DateFormatter.formatDueDate(task.dueDate)}',
                            style: AppTextStyles.labelSmall(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
