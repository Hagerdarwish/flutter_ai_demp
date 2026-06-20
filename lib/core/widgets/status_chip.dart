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
        return AppColors.neutralForeground;
      case WidgetMeetingStatus.processing:
        return AppColors.warningForeground;
      case WidgetMeetingStatus.completed:
        return AppColors.successForeground;
      case WidgetMeetingStatus.failed:
        return AppColors.errorForeground;
    }
  }

  Color get _bgColor {
    switch (status) {
      case WidgetMeetingStatus.draft:
        return AppColors.dividerLight;
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
      WidgetTaskPriority.low => (
          'Low',
          AppColors.successForeground,
          AppColors.successLight
        ),
      WidgetTaskPriority.medium => (
          'Medium',
          AppColors.warningForeground,
          AppColors.warningLight
        ),
      WidgetTaskPriority.high => (
          'High',
          AppColors.errorForeground,
          AppColors.errorLight
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
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
      WidgetTaskStatus.pending => (
          'Pending',
          AppColors.neutralForeground,
          AppColors.dividerLight
        ),
      WidgetTaskStatus.inProgress => (
          'In Progress',
          AppColors.infoForeground,
          AppColors.infoLight
        ),
      WidgetTaskStatus.completed => (
          'Completed',
          AppColors.successForeground,
          AppColors.successLight
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
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
