import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/meetings_repository_impl.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/decision.dart';
import '../../../../features/tasks/domain/entities/meeting_task.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final meetingsRepositoryProvider =
    Provider<MeetingsRepository>((_) => MeetingsRepository());

// Stream of all meetings for current user
final meetingsProvider = StreamProvider<List<Meeting>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(meetingsRepositoryProvider).watchMeetings(user.id);
});

// Single meeting details
final meetingDetailsProvider =
    FutureProvider.family<Meeting, String>((ref, meetingId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not logged in');
  return ref.watch(meetingsRepositoryProvider).getMeeting(user.id, meetingId);
});

// Decisions for a specific meeting
final meetingDecisionsProvider =
    FutureProvider.family<List<Decision>, String>((ref, meetingId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(meetingsRepositoryProvider).getDecisions(user.id, meetingId);
});

// Tasks for a specific meeting
final meetingTasksProvider =
    FutureProvider.family<List<MeetingTask>, String>((ref, meetingId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref
      .watch(meetingsRepositoryProvider)
      .getMeetingTasks(user.id, meetingId);
});

// Dashboard stats
final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  return ref.watch(meetingsRepositoryProvider).getDashboardStats(user.id);
});

// Meetings deletion notifier
class MeetingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final MeetingsRepository _repo;
  final String _userId;

  MeetingActionsNotifier(this._repo, this._userId)
      : super(const AsyncValue.data(null));

  Future<void> deleteMeeting(String meetingId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteMeeting(_userId, meetingId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveParticipantEmails(
      String meetingId, Map<String, String> participantEmails) async {
    state = const AsyncValue.loading();
    try {
      await _repo.saveParticipantEmails(
        userId: _userId,
        meetingId: meetingId,
        participantEmails: participantEmails,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final meetingActionsProvider =
    StateNotifierProvider<MeetingActionsNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return MeetingActionsNotifier(
      ref.watch(meetingsRepositoryProvider), user?.id ?? '');
});
