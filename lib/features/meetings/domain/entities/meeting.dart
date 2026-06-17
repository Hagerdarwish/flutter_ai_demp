import 'package:cloud_firestore/cloud_firestore.dart';

enum MeetingStatus { draft, processing, completed, failed }

enum MeetingSourceType { file, link }

class Meeting {
  final String id;
  final String userId;
  final String title;
  final MeetingSourceType sourceType;
  final String sourceName;
  final String sourceUrl;
  final String fileType;
  final MeetingStatus status;
  final String shortSummary;
  final String detailedSummary;
  final List<String> minutesOfMeeting;
  final List<String> participants;
  final Map<String, String> participantEmails;
  final List<String> followUps;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;

  const Meeting({
    required this.id,
    required this.userId,
    required this.title,
    required this.sourceType,
    required this.sourceName,
    this.sourceUrl = '',
    this.fileType = '',
    required this.status,
    this.shortSummary = '',
    this.detailedSummary = '',
    this.minutesOfMeeting = const [],
    this.participants = const [],
    this.participantEmails = const {},
    this.followUps = const [],
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
  });

  Meeting copyWith({
    String? title,
    MeetingStatus? status,
    String? shortSummary,
    String? detailedSummary,
    List<String>? minutesOfMeeting,
    List<String>? participants,
    Map<String, String>? participantEmails,
    List<String>? followUps,
    DateTime? processedAt,
  }) {
    return Meeting(
      id: id,
      userId: userId,
      title: title ?? this.title,
      sourceType: sourceType,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      fileType: fileType,
      status: status ?? this.status,
      shortSummary: shortSummary ?? this.shortSummary,
      detailedSummary: detailedSummary ?? this.detailedSummary,
      minutesOfMeeting: minutesOfMeeting ?? this.minutesOfMeeting,
      participants: participants ?? this.participants,
      participantEmails: participantEmails ?? this.participantEmails,
      followUps: followUps ?? this.followUps,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      processedAt: processedAt ?? this.processedAt,
    );
  }

  factory Meeting.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meeting(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled Meeting',
      sourceType: data['sourceType'] == 'link'
          ? MeetingSourceType.link
          : MeetingSourceType.file,
      sourceName: data['sourceName'] as String? ?? '',
      sourceUrl: data['sourceUrl'] as String? ?? '',
      fileType: data['fileType'] as String? ?? '',
      status: _statusFromString(data['status'] as String? ?? 'draft'),
      shortSummary: data['shortSummary'] as String? ?? '',
      detailedSummary: data['detailedSummary'] as String? ?? '',
      minutesOfMeeting:
          List<String>.from(data['minutesOfMeeting'] as List? ?? []),
      participants: List<String>.from(data['participants'] as List? ?? []),
      participantEmails: Map<String, String>.from(
          data['participantEmails'] as Map? ?? const {}),
      followUps: List<String>.from(data['followUps'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'sourceType': sourceType == MeetingSourceType.link ? 'link' : 'file',
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,
        'fileType': fileType,
        'status': status.name,
        'shortSummary': shortSummary,
        'detailedSummary': detailedSummary,
        'minutesOfMeeting': minutesOfMeeting,
        'participants': participants,
        'participantEmails': participantEmails,
        'followUps': followUps,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        if (processedAt != null)
          'processedAt': Timestamp.fromDate(processedAt!),
      };

  static MeetingStatus _statusFromString(String s) {
    return MeetingStatus.values
        .firstWhere((e) => e.name == s, orElse: () => MeetingStatus.draft);
  }
}
