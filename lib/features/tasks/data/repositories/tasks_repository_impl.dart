import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/meeting_task.dart';
import '../../../../core/constants/app_constants.dart';

class TasksRepository {
  final FirebaseFirestore _db;

  TasksRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksColl(String userId) => _db
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.tasksCollection);

  CollectionReference<Map<String, dynamic>> _meetingTasksColl(
          String userId, String meetingId) =>
      _db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.meetingsCollection)
          .doc(meetingId)
          .collection(AppConstants.tasksCollection);

  Stream<List<MeetingTask>> watchTasks(String userId) {
    return _tasksColl(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MeetingTask.fromFirestore(d)).toList());
  }

  Future<void> updateTaskStatus(
      String userId, String taskId, TaskStatus status) async {
    await _tasksColl(userId).doc(taskId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateTaskAssignee({
    required String userId,
    required String taskId,
    required String meetingId,
    required String assignee,
  }) async {
    final updatedAt = Timestamp.fromDate(DateTime.now());
    final batch = _db.batch();

    batch.update(_tasksColl(userId).doc(taskId), {
      'assignee': assignee.trim(),
      'updatedAt': updatedAt,
    });

    batch.update(_meetingTasksColl(userId, meetingId).doc(taskId), {
      'assignee': assignee.trim(),
      'updatedAt': updatedAt,
    });

    await batch.commit();
  }
}
