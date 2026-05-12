import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed }

class MeetingTask {
  final String id;
  final String meetingId;
  final String meetingTitle;
  final String title;
  final String description;
  final String assignee;
  final String dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MeetingTask({
    required this.id,
    required this.meetingId,
    this.meetingTitle = '',
    required this.title,
    this.description = '',
    this.assignee = '',
    this.dueDate = '',
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  MeetingTask copyWith({TaskStatus? status, TaskPriority? priority}) {
    return MeetingTask(
      id: id,
      meetingId: meetingId,
      meetingTitle: meetingTitle,
      title: title,
      description: description,
      assignee: assignee,
      dueDate: dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory MeetingTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingTask(
      id: doc.id,
      meetingId: data['meetingId'] as String? ?? '',
      meetingTitle: data['meetingTitle'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      assignee: data['assignee'] as String? ?? '',
      dueDate: data['dueDate'] as String? ?? '',
      priority: _priorityFromString(data['priority'] as String? ?? 'medium'),
      status: _statusFromString(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory MeetingTask.fromAiMap(Map<String, dynamic> map, {required String meetingId, String meetingTitle = ''}) {
    final now = DateTime.now();
    return MeetingTask(
      id: '',
      meetingId: meetingId,
      meetingTitle: meetingTitle,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      assignee: map['assignee'] as String? ?? '',
      dueDate: map['dueDate'] as String? ?? '',
      priority: _priorityFromString(map['priority'] as String? ?? 'medium'),
      status: TaskStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'meetingId': meetingId,
        'meetingTitle': meetingTitle,
        'title': title,
        'description': description,
        'assignee': assignee,
        'dueDate': dueDate,
        'priority': priority.name,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static TaskPriority _priorityFromString(String s) {
    return TaskPriority.values.firstWhere((e) => e.name == s.toLowerCase(), orElse: () => TaskPriority.medium);
  }

  static TaskStatus _statusFromString(String s) {
    if (s == 'inProgress') return TaskStatus.inProgress;
    return TaskStatus.values.firstWhere((e) => e.name == s.toLowerCase(), orElse: () => TaskStatus.pending);
  }
}
