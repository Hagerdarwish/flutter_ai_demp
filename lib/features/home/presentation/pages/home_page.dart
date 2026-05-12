import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../meetings/presentation/providers/meetings_provider.dart';
import '../../../meetings/domain/entities/meeting.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import '../../../tasks/domain/entities/meeting_task.dart';
import '../../../../app/router/route_names.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final meetingsAsync = ref.watch(meetingsProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context, user?.name ?? user?.email ?? 'User'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go(RouteNames.settings),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle(title: 'Overview'),
                const SizedBox(height: 12),
                statsAsync.when(
                  data: (stats) => _DashboardStats(stats: stats),
                  loading: () => const ShimmerCard(height: 100),
                  error: (_, __) => const SizedBox.shrink(),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 28),
                _SectionTitle(title: AppStrings.quickActions),
                const SizedBox(height: 12),
                _QuickActions().animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionTitle(title: AppStrings.recentMeetings),
                    TextButton(
                      onPressed: () => context.go(RouteNames.meetings),
                      child: const Text(AppStrings.viewAll),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                meetingsAsync.when(
                  data: (meetings) {
                    if (meetings.isEmpty) {
                      return EmptyState(
                        icon: Icons.mic_none_rounded,
                        title: AppStrings.noMeetings,
                        description: AppStrings.noMeetingsDesc,
                        actionLabel: 'Import Meeting',
                        onAction: () => context.push(RouteNames.importMeeting),
                      );
                    }
                    final recent = meetings.take(5).toList();
                    return Column(
                      children: recent
                          .asMap()
                          .entries
                          .map((e) => _MeetingHomeCard(meeting: e.value)
                              .animate(delay: (e.key * 60).ms)
                              .fadeIn()
                              .slideX(begin: 0.05, end: 0))
                          .toList(),
                    );
                  },
                  loading: () => const ShimmerList(count: 3, shrinkWrap: true),
                  error: (e, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionTitle(title: AppStrings.taskOverview),
                    TextButton(
                      onPressed: () => context.go(RouteNames.tasks),
                      child: const Text(AppStrings.viewAll),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                tasksAsync.when(
                  data: (tasks) => _TaskOverview(tasks: tasks),
                  loading: () => const ShimmerCard(height: 100),
                  error: (_, __) => const SizedBox.shrink(),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.importMeeting),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Import Meeting'),
      ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkHeaderGradient : null,
        color: isDark ? null : AppColors.surfaceLight,
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.appName,
                      style: AppTextStyles.labelMedium(context).copyWith(color: AppColors.primary)),
                  Text('${AppStrings.welcome}, $name!',
                      style: AppTextStyles.titleMedium(context)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) =>
      Text(title, style: AppTextStyles.titleMedium(context));
}

class _DashboardStats extends StatelessWidget {
  final Map<String, int> stats;
  const _DashboardStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (label: 'Meetings', value: stats['totalMeetings'] ?? 0, icon: Icons.meeting_room_rounded, color: AppColors.primary),
      (label: 'Completed', value: stats['completedSummaries'] ?? 0, icon: Icons.check_circle_rounded, color: AppColors.success),
      (label: 'Tasks', value: stats['pendingTasks'] ?? 0, icon: Icons.task_alt_rounded, color: AppColors.warning),
      (label: 'Decisions', value: stats['decisions'] ?? 0, icon: Icons.gavel_rounded, color: AppColors.info),
    ];
    return Row(
      children: items.map((item) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(item.icon, color: item.color, size: 22),
              const SizedBox(height: 8),
              Text('${item.value}',
                  style: AppTextStyles.headlineSmall(context).copyWith(color: item.color, fontSize: 22)),
              Text(item.label, style: AppTextStyles.labelSmall(context), textAlign: TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      (icon: Icons.upload_file_rounded, label: 'Upload\nRecording', color: AppColors.primary,
       action: () => context.push(RouteNames.importMeeting)),
      (icon: Icons.link_rounded, label: 'Paste\nLink', color: AppColors.secondary,
       action: () => context.push(RouteNames.importMeeting)),
      (icon: Icons.folder_rounded, label: 'All\nMeetings', color: AppColors.info,
       action: () => context.go(RouteNames.meetings)),
      (icon: Icons.task_alt_rounded, label: 'All\nTasks', color: AppColors.success,
       action: () => context.go(RouteNames.tasks)),
    ];
    return Row(
      children: actions.map((a) => Expanded(
        child: GestureDetector(
          onTap: a.action,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            decoration: BoxDecoration(
              color: a.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: a.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(a.icon, color: a.color, size: 26),
                const SizedBox(height: 8),
                Text(a.label,
                    style: AppTextStyles.labelSmall(context).copyWith(color: a.color),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}

WidgetMeetingStatus _toWidgetStatus(MeetingStatus s) => switch (s) {
      MeetingStatus.draft => WidgetMeetingStatus.draft,
      MeetingStatus.processing => WidgetMeetingStatus.processing,
      MeetingStatus.completed => WidgetMeetingStatus.completed,
      MeetingStatus.failed => WidgetMeetingStatus.failed,
    };

class _MeetingHomeCard extends StatelessWidget {
  final Meeting meeting;
  const _MeetingHomeCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            meeting.sourceType == MeetingSourceType.link
                ? Icons.link_rounded
                : Icons.audiotrack_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(meeting.title,
            style: AppTextStyles.titleSmall(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(DateFormatter.formatRelative(meeting.createdAt),
            style: AppTextStyles.bodySmall(context)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip(status: _toWidgetStatus(meeting.status)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
        onTap: () => context.push('/meetings/${meeting.id}'),
      ),
    );
  }
}

class _TaskOverview extends StatelessWidget {
  final List<MeetingTask> tasks;
  const _TaskOverview({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final high = tasks.where((t) => t.priority == TaskPriority.high && t.status != TaskStatus.completed).length;
    final done = tasks.where((t) => t.status == TaskStatus.completed).length;

    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.task_alt_rounded, color: AppColors.textSecondaryLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No tasks yet. They\'ll appear after your first meeting.',
                  style: AppTextStyles.bodySmall(context)),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        _TaskStat(label: 'Pending', value: pending, color: AppColors.warning),
        const SizedBox(width: 8),
        _TaskStat(label: 'High Priority', value: high, color: AppColors.error),
        const SizedBox(width: 8),
        _TaskStat(label: 'Done', value: done, color: AppColors.success),
      ],
    );
  }
}

class _TaskStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _TaskStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: AppTextStyles.headlineSmall(context).copyWith(color: color, fontSize: 22)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.labelSmall(context), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
