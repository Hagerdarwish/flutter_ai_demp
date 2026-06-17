import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/tasks_repository_impl.dart';
import '../../domain/entities/meeting_task.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final tasksRepositoryProvider =
    Provider<TasksRepository>((_) => TasksRepository());

final tasksProvider = StreamProvider<List<MeetingTask>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(tasksRepositoryProvider).watchTasks(user.id);
});

class TasksNotifier extends StateNotifier<AsyncValue<void>> {
  final TasksRepository _repo;
  final String _userId;

  TasksNotifier(this._repo, this._userId) : super(const AsyncValue.data(null));

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateTaskStatus(_userId, taskId, status);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateAssignee({
    required String taskId,
    required String meetingId,
    required String assignee,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateTaskAssignee(
        userId: _userId,
        taskId: taskId,
        meetingId: meetingId,
        assignee: assignee,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final tasksNotifierProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return TasksNotifier(ref.watch(tasksRepositoryProvider), user?.id ?? '');
});
