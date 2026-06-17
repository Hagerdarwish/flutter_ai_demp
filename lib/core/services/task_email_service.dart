import 'package:url_launcher/url_launcher_string.dart';

import '../../features/meetings/domain/entities/meeting.dart';
import '../../features/tasks/domain/entities/meeting_task.dart';
import '../utils/date_formatter.dart';

enum CorrespondenceLanguage { english, arabic }

class TaskEmailService {
  const TaskEmailService();

  Future<bool> composeTaskEmail({
    required Meeting meeting,
    required String recipientName,
    required String recipientEmail,
    required List<MeetingTask> tasks,
    required CorrespondenceLanguage language,
  }) async {
    if (recipientEmail.trim().isEmpty || tasks.isEmpty) return false;
    return launchUrlString(
      _buildMailtoUrl(
        recipientEmail: recipientEmail,
        subject: _buildTaskEmailSubject(meeting, language),
        body: _buildTaskEmailBody(
          meeting: meeting,
          recipientName: recipientName,
          tasks: tasks,
          language: language,
        ),
      ),
    );
  }

  String buildTaskEmailPreview({
    required Meeting meeting,
    required String recipientName,
    required List<MeetingTask> tasks,
    required CorrespondenceLanguage language,
  }) {
    return _buildTaskEmailBody(
      meeting: meeting,
      recipientName: recipientName,
      tasks: tasks,
      language: language,
    );
  }

  String _buildTaskEmailSubject(
    Meeting meeting,
    CorrespondenceLanguage language,
  ) {
    return switch (language) {
      CorrespondenceLanguage.arabic =>
        'المهام الخاصة بك من اجتماع ${meeting.title}',
      CorrespondenceLanguage.english => 'Your tasks from ${meeting.title}',
    };
  }

  String _buildTaskEmailBody({
    required Meeting meeting,
    required String recipientName,
    required List<MeetingTask> tasks,
    required CorrespondenceLanguage language,
  }) {
    final isArabic = language == CorrespondenceLanguage.arabic;
    final buffer = StringBuffer()
      ..writeln(isArabic ? 'مرحباً $recipientName،' : 'Hello $recipientName,')
      ..writeln()
      ..writeln(
        isArabic
            ? 'فيما يلي المهام الخاصة بك من اجتماع "${meeting.title}".'
            : 'Please find below your assigned tasks from "${meeting.title}".',
      )
      ..writeln(
        isArabic
            ? 'تاريخ الاجتماع: ${DateFormatter.formatDate(meeting.createdAt)}'
            : 'Meeting date: ${DateFormatter.formatDate(meeting.createdAt)}',
      )
      ..writeln();

    if (meeting.shortSummary.isNotEmpty) {
      buffer
        ..writeln(isArabic ? 'ملخص موجز:' : 'Brief summary:')
        ..writeln(meeting.shortSummary)
        ..writeln();
    }

    buffer.writeln(isArabic ? 'المهام المطلوبة:' : 'Assigned tasks:');
    for (final task in tasks) {
      buffer.writeln('- ${task.title}');
      if (task.description.isNotEmpty) {
        buffer.writeln(
          isArabic
              ? '  التفاصيل: ${task.description}'
              : '  Details: ${task.description}',
        );
      }
      if (task.dueDate.isNotEmpty) {
        buffer.writeln(
          isArabic
              ? '  تاريخ الاستحقاق: ${DateFormatter.formatDueDate(task.dueDate)}'
              : '  Due date: ${DateFormatter.formatDueDate(task.dueDate)}',
        );
      }
      buffer.writeln();
    }

    if (meeting.followUps.isNotEmpty) {
      buffer.writeln(isArabic ? 'متابعات:' : 'Follow-ups:');
      for (final followUp in meeting.followUps) {
        buffer.writeln('- $followUp');
      }
      buffer.writeln();
    }

    buffer.writeln(
      isArabic ? 'تم الإرسال من MeetFlow AI.' : 'Sent from MeetFlow AI.',
    );
    return buffer.toString().trim();
  }

  String _buildMailtoUrl({
    required String recipientEmail,
    required String subject,
    required String body,
  }) {
    final email = Uri.encodeComponent(recipientEmail.trim());
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    return 'mailto:$email?subject=$encodedSubject&body=$encodedBody';
  }
}
