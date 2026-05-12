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
import '../providers/meetings_provider.dart';
import '../../domain/entities/meeting.dart';
import '../../../../app/router/route_names.dart';

WidgetMeetingStatus _toWidgetStatus(MeetingStatus s) => switch (s) {
  MeetingStatus.draft => WidgetMeetingStatus.draft,
  MeetingStatus.processing => WidgetMeetingStatus.processing,
  MeetingStatus.completed => WidgetMeetingStatus.completed,
  MeetingStatus.failed => WidgetMeetingStatus.failed,
};

class MeetingsPage extends ConsumerStatefulWidget {
  const MeetingsPage({super.key});

  @override
  ConsumerState<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends ConsumerState<MeetingsPage> {
  MeetingStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final meetingsAsync = ref.watch(meetingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.meetings),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(RouteNames.importMeeting),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter chips
          _buildFilterRow(),

          // Meetings list
          Expanded(
            child: meetingsAsync.when(
              data: (meetings) {
                final filtered = _filterStatus == null
                    ? meetings
                    : meetings.where((m) => m.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.mic_none_rounded,
                    title: AppStrings.noMeetings,
                    description: AppStrings.noMeetingsDesc,
                    actionLabel: 'Import Meeting',
                    onAction: () => context.push(RouteNames.importMeeting),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => _MeetingListCard(meeting: filtered[index])
                      .animate(delay: (index * 40).ms)
                      .fadeIn()
                      .slideX(begin: 0.05, end: 0),
                );
              },
              loading: () => const ShimmerList(),
              error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.refresh(meetingsProvider)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = [null, MeetingStatus.completed, MeetingStatus.processing, MeetingStatus.failed];
    final labels = ['All', 'Completed', 'Processing', 'Failed'];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => FilterChip(
          label: Text(labels[i]),
          selected: _filterStatus == filters[i],
          onSelected: (_) => setState(() => _filterStatus = filters[i]),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _MeetingListCard extends StatelessWidget {
  final Meeting meeting;
  const _MeetingListCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final statusChip = StatusChip(status: _toWidgetStatus(meeting.status));

    return Card(
      child: InkWell(
        onTap: () => context.push('/meetings/${meeting.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  meeting.sourceType == MeetingSourceType.link
                      ? Icons.link_rounded
                      : Icons.audiotrack_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.title,
                      style: AppTextStyles.titleSmall(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(DateFormatter.formatRelative(meeting.createdAt),
                            style: AppTextStyles.bodySmall(context)),
                        const SizedBox(width: 8),
                        if (meeting.sourceName.isNotEmpty) ...[
                          const Icon(Icons.source_rounded, size: 12, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              meeting.sourceName,
                              style: AppTextStyles.bodySmall(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              statusChip,
            ],
          ),
        ),
      ),
    );
  }
}
