import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/smart_text.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/meetings_provider.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/decision.dart';
import '../../../../features/tasks/domain/entities/meeting_task.dart';

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
        title: Text(meeting.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Summary',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _buildMarkdownExport(meeting)));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
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
                  child: SmartText(meeting.shortSummary, style: AppTextStyles.bodyLarge(context)),
                ).animate().fadeIn(delay: 80.ms),
                const SizedBox(height: 12),

                if (meeting.detailedSummary.isNotEmpty)
                  _ExpandableSection(
                    title: AppStrings.detailedSummary,
                    icon: Icons.article_rounded,
                    child: SmartText(meeting.detailedSummary, style: AppTextStyles.bodyMedium(context)),
                  ).animate().fadeIn(delay: 120.ms),

                if (meeting.minutesOfMeeting.isNotEmpty)
                  _ExpandableSection(
                    title: AppStrings.minutesOfMeeting,
                    icon: Icons.format_list_bulleted_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: meeting.minutesOfMeeting.map((p) => SmartBulletPoint(p)).toList(),
                    ),
                  ).animate().fadeIn(delay: 160.ms),

                decisionsAsync.when(
                  data: (decisions) => decisions.isEmpty
                      ? const SizedBox.shrink()
                      : _ExpandableSection(
                          title: AppStrings.decisions,
                          icon: Icons.gavel_rounded,
                          child: Column(
                            children: decisions.map((d) => _DecisionTile(decision: d)).toList(),
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                  loading: () => const ShimmerCard(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                tasksAsync.when(
                  data: (tasks) => tasks.isEmpty
                      ? const SizedBox.shrink()
                      : _ExpandableSection(
                          title: AppStrings.tasks,
                          icon: Icons.task_alt_rounded,
                          child: Column(
                            children: tasks.map((t) => _TaskTile(task: t)).toList(),
                          ),
                        ).animate().fadeIn(delay: 240.ms),
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
                                label: Text(p),
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
                      children: meeting.followUps.map((f) => SmartBulletPoint(f)).toList(),
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
              const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Meeting Details',
                  style: AppTextStyles.labelMedium(context).copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          Text(meeting.title,
              style: AppTextStyles.titleLarge(context).copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(DateFormatter.formatDate(meeting.createdAt),
                  style: AppTextStyles.bodySmall(context).copyWith(color: Colors.white70)),
              const SizedBox(width: 16),
              const Icon(Icons.source_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                meeting.sourceName.isNotEmpty ? meeting.sourceName : meeting.fileType,
                style: AppTextStyles.bodySmall(context).copyWith(color: Colors.white70),
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
              Text('Processing meeting…', style: AppTextStyles.titleMedium(context)),
            ] else if (meeting.status == MeetingStatus.failed) ...[
              const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Processing Failed', style: AppTextStyles.headlineSmall(context)),
              const SizedBox(height: 8),
              Text('This meeting could not be processed by AI.',
                  style: AppTextStyles.bodyMedium(context)),
            ] else ...[
              const Icon(Icons.edit_note_rounded, size: 64, color: AppColors.statusDraft),
              const SizedBox(height: 16),
              Text('Draft Meeting', style: AppTextStyles.headlineSmall(context)),
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
      for (final p in meeting.minutesOfMeeting) buf.writeln('- $p');
      buf.writeln();
    }
    if (meeting.participants.isNotEmpty) {
      buf.writeln('## Participants');
      for (final p in meeting.participants) buf.writeln('- $p');
      buf.writeln();
    }
    if (meeting.followUps.isNotEmpty) {
      buf.writeln('## Follow-ups');
      for (final f in meeting.followUps) buf.writeln('- $f');
    }
    return buf.toString();
  }
}

// --- Reusable Section Widgets ---
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

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
                    style: AppTextStyles.titleSmall(context).copyWith(color: AppColors.primary)),
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
  const _ExpandableSection({required this.title, required this.icon, required this.child});

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
                        style: AppTextStyles.titleSmall(context).copyWith(color: AppColors.primary)),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
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

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7, right: 10),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium(context))),
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
            SmartText('Owner: ${decision.owner}', style: AppTextStyles.labelSmall(context)),
          ],
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final MeetingTask task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: SmartText(task.title, style: AppTextStyles.titleSmall(context))),
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
                const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                SmartText(task.assignee, style: AppTextStyles.labelSmall(context)),
                const SizedBox(width: 12),
              ],
              if (task.dueDate.isNotEmpty) ...[
                const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(DateFormatter.formatDueDate(task.dueDate), style: AppTextStyles.labelSmall(context)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
