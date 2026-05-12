import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum WidgetMeetingStatus { draft, processing, completed, failed }

enum WidgetTaskPriority { low, medium, high }

enum WidgetTaskStatus { pending, inProgress, completed }

class StatusChip extends StatelessWidget {
  final WidgetMeetingStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return _buildChip(context, _label, _color, _bgColor);
  }

  String get _label {
    switch (status) {
      case WidgetMeetingStatus.draft:
        return 'Draft';
      case WidgetMeetingStatus.processing:
        return 'Processing';
      case WidgetMeetingStatus.completed:
        return 'Completed';
      case WidgetMeetingStatus.failed:
        return 'Failed';
    }
  }

  Color get _color {
    switch (status) {
      case WidgetMeetingStatus.draft:
        return AppColors.statusDraft;
      case WidgetMeetingStatus.processing:
        return AppColors.statusProcessing;
      case WidgetMeetingStatus.completed:
        return AppColors.statusCompleted;
      case WidgetMeetingStatus.failed:
        return AppColors.statusFailed;
    }
  }

  Color get _bgColor {
    switch (status) {
      case WidgetMeetingStatus.draft:
        return AppColors.statusDraft.withValues(alpha: 0.12);
      case WidgetMeetingStatus.processing:
        return AppColors.warningLight;
      case WidgetMeetingStatus.completed:
        return AppColors.successLight;
      case WidgetMeetingStatus.failed:
        return AppColors.errorLight;
    }
  }

  Widget _buildChip(BuildContext context, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class PriorityChip extends StatelessWidget {
  final WidgetTaskPriority priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (priority) {
      WidgetTaskPriority.low => ('Low', AppColors.priorityLow, AppColors.successLight),
      WidgetTaskPriority.medium => ('Medium', AppColors.priorityMedium, AppColors.warningLight),
      WidgetTaskPriority.high => ('High', AppColors.priorityHigh, AppColors.errorLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class TaskStatusChip extends StatelessWidget {
  final WidgetTaskStatus status;

  const TaskStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      WidgetTaskStatus.pending =>
        ('Pending', AppColors.statusDraft, AppColors.statusDraft.withValues(alpha: 0.12)),
      WidgetTaskStatus.inProgress => ('In Progress', AppColors.info, AppColors.infoLight),
      WidgetTaskStatus.completed => ('Completed', AppColors.success, AppColors.successLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
