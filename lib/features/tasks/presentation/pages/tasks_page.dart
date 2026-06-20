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
import '../providers/tasks_provider.dart';
import '../../domain/entities/meeting_task.dart';

// --- Enum mapping helpers ---
WidgetTaskPriority _toWidgetPriority(TaskPriority p) => switch (p) {
      TaskPriority.low => WidgetTaskPriority.low,
      TaskPriority.medium => WidgetTaskPriority.medium,
      TaskPriority.high => WidgetTaskPriority.high,
    };

WidgetTaskStatus _toWidgetTaskStatus(TaskStatus s) => switch (s) {
      TaskStatus.pending => WidgetTaskStatus.pending,
      TaskStatus.inProgress => WidgetTaskStatus.inProgress,
      TaskStatus.completed => WidgetTaskStatus.completed,
    };

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.taskTitle)),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = tasks.where((t) {
                  if (_statusFilter != null && t.status != _statusFilter) {
                    return false;
                  }
                  if (_priorityFilter != null &&
                      t.priority != _priorityFilter) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: AppStrings.noTasks,
                    description: AppStrings.noTasksDesc,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => _TaskCard(task: filtered[index])
                      .animate(delay: (index * 40).ms)
                      .fadeIn()
                      .slideX(begin: 0.05, end: 0),
                );
              },
              loading: () => const ShimmerList(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.refresh(tasksProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip(
                label: 'All',
                selected: _statusFilter == null,
                onSelected: (_) => setState(() => _statusFilter = null),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Pending',
                selected: _statusFilter == TaskStatus.pending,
                selectedColor: AppColors.neutralForeground,
                onSelected: (_) =>
                    setState(() => _statusFilter = TaskStatus.pending),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'In Progress',
                selected: _statusFilter == TaskStatus.inProgress,
                selectedColor: AppColors.infoForeground,
                onSelected: (_) =>
                    setState(() => _statusFilter = TaskStatus.inProgress),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Completed',
                selected: _statusFilter == TaskStatus.completed,
                selectedColor: AppColors.successForeground,
                onSelected: (_) =>
                    setState(() => _statusFilter = TaskStatus.completed),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip(
                label: 'Any Priority',
                selected: _priorityFilter == null,
                onSelected: (_) => setState(() => _priorityFilter = null),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'High',
                selected: _priorityFilter == TaskPriority.high,
                selectedColor: AppColors.errorForeground,
                onSelected: (_) =>
                    setState(() => _priorityFilter = TaskPriority.high),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Medium',
                selected: _priorityFilter == TaskPriority.medium,
                selectedColor: AppColors.warningForeground,
                onSelected: (_) =>
                    setState(() => _priorityFilter = TaskPriority.medium),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: 'Low',
                selected: _priorityFilter == TaskPriority.low,
                selectedColor: AppColors.successForeground,
                onSelected: (_) =>
                    setState(() => _priorityFilter = TaskPriority.low),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Color? selectedColor,
  }) {
    final theme = Theme.of(context);
    final selectedBackground = selectedColor ?? AppColors.primary;
    final foreground =
        selected ? Colors.white : theme.colorScheme.onSurfaceVariant;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: selected,
      selectedColor: selectedBackground,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      checkmarkColor: foreground,
      labelStyle: AppTextStyles.labelMedium(context).copyWith(
        color: foreground,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        letterSpacing: 0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(
        color: selected ? selectedBackground : theme.colorScheme.outline,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final MeetingTask task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task.status == TaskStatus.completed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTextStyles.titleSmall(context).copyWith(
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5)
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                PriorityChip(priority: _toWidgetPriority(task.priority)),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(task.description,
                  style: AppTextStyles.bodySmall(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (task.assignee.isNotEmpty) ...[
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(task.assignee, style: AppTextStyles.labelSmall(context)),
                  const SizedBox(width: 12),
                ],
                if (task.dueDate.isNotEmpty) ...[
                  Icon(
                    Icons.event_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(DateFormatter.formatDueDate(task.dueDate),
                      style: AppTextStyles.labelSmall(context)),
                ],
                const Spacer(),
                TaskStatusChip(status: _toWidgetTaskStatus(task.status)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                if (task.meetingId.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.meeting_room_rounded, size: 14),
                    label:
                        const Text('Meeting', style: TextStyle(fontSize: 12)),
                    onPressed: () =>
                        context.push('/meetings/${task.meetingId}'),
                  ),
                const Spacer(),
                if (task.status == TaskStatus.pending)
                  TextButton(
                    onPressed: () => ref
                        .read(tasksNotifierProvider.notifier)
                        .updateStatus(task.id, TaskStatus.inProgress),
                    child: const Text('Start', style: TextStyle(fontSize: 12)),
                  ),
                if (task.status == TaskStatus.inProgress)
                  TextButton(
                    onPressed: () => ref
                        .read(tasksNotifierProvider.notifier)
                        .updateStatus(task.id, TaskStatus.completed),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.success),
                    child:
                        const Text('Complete', style: TextStyle(fontSize: 12)),
                  ),
                if (task.status == TaskStatus.completed)
                  TextButton(
                    onPressed: () => ref
                        .read(tasksNotifierProvider.notifier)
                        .updateStatus(task.id, TaskStatus.pending),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    child: const Text('Reopen', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
