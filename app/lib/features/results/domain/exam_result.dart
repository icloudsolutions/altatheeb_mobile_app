import 'package:equatable/equatable.dart';

class ExamResult extends Equatable {
  const ExamResult({
    required this.id,
    required this.studentOdooId,
    required this.examId,
    required this.examName,
    this.subject,
    this.date,
    this.marksObtained = 0,
    this.totalMarks = 0,
    this.percentage = 0,
    this.grade,
  });

  final int id;
  final int studentOdooId;
  final int examId;
  final String examName;
  final String? subject;
  final DateTime? date;
  final double marksObtained;
  final double totalMarks;
  final double percentage;
  final String? grade;

  factory ExamResult.fromJson(Map<String, dynamic> j) => ExamResult(
        id: j['id'] as int,
        studentOdooId: j['student_odoo_id'] as int,
        examId: j['exam_id'] as int,
        examName: (j['exam_name'] as String?) ?? '',
        subject: j['subject'] as String?,
        date: j['date'] != null ? DateTime.tryParse(j['date'] as String) : null,
        marksObtained: ((j['marks_obtained'] as num?) ?? 0).toDouble(),
        totalMarks: ((j['total_marks'] as num?) ?? 0).toDouble(),
        percentage: ((j['percentage'] as num?) ?? 0).toDouble(),
        grade: j['grade'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, studentOdooId, examId, examName, subject, date, marksObtained, totalMarks, percentage, grade];
}
