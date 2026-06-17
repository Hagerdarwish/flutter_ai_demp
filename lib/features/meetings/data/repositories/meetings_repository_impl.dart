import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/decision.dart';
import '../../../../features/tasks/domain/entities/meeting_task.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';

class MeetingsRepository {
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  MeetingsRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _meetingsColl(String userId) => _db
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.meetingsCollection);

  CollectionReference<Map<String, dynamic>> _decisionsColl(
          String userId, String meetingId) =>
      _meetingsColl(userId)
          .doc(meetingId)
          .collection(AppConstants.decisionsCollection);

  CollectionReference<Map<String, dynamic>> _meetingTasksColl(
          String userId, String meetingId) =>
      _meetingsColl(userId)
          .doc(meetingId)
          .collection(AppConstants.tasksCollection);

  CollectionReference<Map<String, dynamic>> _userTasksColl(String userId) => _db
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.tasksCollection);

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _db.collection(AppConstants.usersCollection).doc(userId);

  // --- Meetings CRUD ---

  Stream<List<Meeting>> watchMeetings(String userId) {
    return _meetingsColl(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Meeting.fromFirestore(d)).toList());
  }

  Future<Meeting> getMeeting(String userId, String meetingId) async {
    final doc = await _meetingsColl(userId).doc(meetingId).get();
    if (!doc.exists) throw StorageException(message: 'Meeting not found.');
    return Meeting.fromFirestore(doc);
  }

  Future<String> createDraftMeeting(Meeting meeting) async {
    final id = _uuid.v4();
    await _meetingsColl(meeting.userId).doc(id).set(meeting.toFirestore());
    return id;
  }

  Future<void> updateMeeting(Meeting meeting) async {
    if (meeting.id.isEmpty) {
      throw StorageException(message: 'Cannot update meeting: ID is empty.');
    }
    await _meetingsColl(meeting.userId)
        .doc(meeting.id)
        .update(meeting.toFirestore());
  }

  /// Marks an existing meeting document as failed using its known ID.
  /// Safe to call even when the Meeting object was never updated with the generated ID.
  Future<void> markMeetingFailed(
      {required String userId, required String meetingId}) async {
    if (meetingId.isEmpty) return;
    await _meetingsColl(userId).doc(meetingId).update({
      'status': 'failed',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteMeeting(String userId, String meetingId) async {
    // Delete sub-collections first
    final batch = _db.batch();

    final decisionsSnap = await _decisionsColl(userId, meetingId).get();
    for (final d in decisionsSnap.docs) {
      batch.delete(d.reference);
    }

    final tasksSnap = await _meetingTasksColl(userId, meetingId).get();
    for (final t in tasksSnap.docs) {
      batch.delete(t.reference);
    }

    batch.delete(_meetingsColl(userId).doc(meetingId));
    await batch.commit();
  }

  // --- Save AI Result ---

  Future<void> saveMeetingResult({
    required String userId,
    required String meetingId,
    required Map<String, dynamic> aiResult,
    required String meetingTitle,
    String defaultTaskAssignee = '',
  }) async {
    final batch = _db.batch();
    final now = DateTime.now();
    final participantEmails = await _matchedParticipantEmails(userId, aiResult);

    final updatedData = {
      'title': (aiResult['title'] as String?)?.isNotEmpty == true
          ? aiResult['title']
          : meetingTitle,
      'shortSummary': aiResult['shortSummary'] ?? '',
      'detailedSummary': aiResult['detailedSummary'] ?? '',
      'minutesOfMeeting': aiResult['minutesOfMeeting'] ?? [],
      'participants': aiResult['participants'] ?? [],
      'participantEmails': participantEmails,
      'followUps': aiResult['followUps'] ?? [],
      'status': 'completed',
      'updatedAt': Timestamp.fromDate(now),
      'processedAt': Timestamp.fromDate(now),
    };

    batch.update(_meetingsColl(userId).doc(meetingId), updatedData);

    // Save decisions
    final decisions = aiResult['decisions'] as List? ?? [];
    for (final d in decisions) {
      if (d is Map<String, dynamic>) {
        final id = _uuid.v4();
        final decision = Decision.fromMap(id, d);
        batch.set(
            _decisionsColl(userId, meetingId).doc(id), decision.toFirestore());
      }
    }

    // Save tasks (under meeting and user-level)
    final finalTitle = updatedData['title'] as String;
    final tasks = aiResult['tasks'] as List? ?? [];
    for (final t in tasks) {
      if (t is Map<String, dynamic>) {
        final id = _uuid.v4();
        final task = MeetingTask.fromAiMap(t,
            meetingId: meetingId,
            meetingTitle: finalTitle,
            defaultAssignee: defaultTaskAssignee);
        final taskMap = task.toFirestore();
        batch.set(_meetingTasksColl(userId, meetingId).doc(id), taskMap);
        batch.set(_userTasksColl(userId).doc(id), taskMap);
      }
    }

    await batch.commit();
  }

  Future<void> saveParticipantEmails({
    required String userId,
    required String meetingId,
    required Map<String, String> participantEmails,
  }) async {
    final sanitized = _sanitizeEmailMap(participantEmails);
    final mergedDirectory = {
      ...await _participantEmailDirectory(userId),
      ...sanitized,
    };
    final batch = _db.batch();
    batch.update(_meetingsColl(userId).doc(meetingId), {
      'participantEmails': sanitized,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    batch.set(
      _userDoc(userId),
      {
        'participantEmailDirectory': mergedDirectory,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  // --- Decisions ---

  Future<List<Decision>> getDecisions(String userId, String meetingId) async {
    final snap =
        await _decisionsColl(userId, meetingId).orderBy('createdAt').get();
    return snap.docs.map((d) => Decision.fromFirestore(d)).toList();
  }

  // --- Meeting Tasks ---

  Future<List<MeetingTask>> getMeetingTasks(
      String userId, String meetingId) async {
    final snap =
        await _meetingTasksColl(userId, meetingId).orderBy('createdAt').get();
    return snap.docs.map((d) => MeetingTask.fromFirestore(d)).toList();
  }

  // --- Stats ---

  Future<Map<String, int>> getDashboardStats(String userId) async {
    final meetingsSnap = await _meetingsColl(userId).get();
    final meetings =
        meetingsSnap.docs.map((d) => Meeting.fromFirestore(d)).toList();

    final tasksSnap = await _userTasksColl(userId).get();
    final tasks =
        tasksSnap.docs.map((d) => MeetingTask.fromFirestore(d)).toList();

    int decisions = 0;
    for (final m
        in meetings.where((m) => m.status == MeetingStatus.completed)) {
      final dSnap = await _decisionsColl(userId, m.id).count().get();
      decisions += dSnap.count ?? 0;
    }

    return {
      'totalMeetings': meetings.length,
      'completedSummaries':
          meetings.where((m) => m.status == MeetingStatus.completed).length,
      'pendingTasks': tasks.where((t) => t.status == TaskStatus.pending).length,
      'decisions': decisions,
    };
  }

  Future<Map<String, String>> _matchedParticipantEmails(
    String userId,
    Map<String, dynamic> aiResult,
  ) async {
    final directory = await _participantEmailDirectory(userId);
    if (directory.isEmpty) return const {};

    final names = <String>{};
    names.addAll(_extractNames(aiResult['participants']));

    final tasks = aiResult['tasks'] as List? ?? const [];
    for (final task in tasks) {
      if (task is Map<String, dynamic>) {
        final assignee = (task['assignee'] as String? ?? '').trim();
        if (assignee.isNotEmpty) {
          names.add(assignee);
        }
      }
    }

    final matched = <String, String>{};
    for (final name in names) {
      final email = directory[name];
      if (email != null && email.isNotEmpty) {
        matched[name] = email;
      }
    }
    return matched;
  }

  Future<Map<String, String>> _participantEmailDirectory(String userId) async {
    final doc = await _userDoc(userId).get();
    final data = doc.data();
    if (data == null) return const {};
    return _sanitizeEmailMap(
      Map<String, String>.from(
          data['participantEmailDirectory'] as Map? ?? const {}),
    );
  }

  Map<String, String> _sanitizeEmailMap(Map<String, String> source) {
    final cleaned = <String, String>{};
    for (final entry in source.entries) {
      final name = entry.key.trim();
      final email = entry.value.trim();
      if (name.isNotEmpty && email.isNotEmpty) {
        cleaned[name] = email;
      }
    }
    return cleaned;
  }

  List<String> _extractNames(Object? rawNames) {
    if (rawNames is! List) return const [];
    return rawNames
        .whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
