import 'package:equatable/equatable.dart';

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.studentOdooId,
    required this.status,
    this.date,
    this.remarks,
  });

  final int id;
  final int studentOdooId;
  final String status; // present | absent | late | excused
  final DateTime? date;
  final String? remarks;

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'] as int,
        studentOdooId: j['student_odoo_id'] as int,
        status: (j['status'] as String?) ?? 'present',
        date: j['date'] != null ? DateTime.tryParse(j['date'] as String) : null,
        remarks: j['remarks'] as String?,
      );

  @override
  List<Object?> get props => [id, studentOdooId, status, date, remarks];
}

class AttendanceSummary extends Equatable {
  const AttendanceSummary({
    required this.records,
    this.total = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.excused = 0,
  });

  final List<AttendanceRecord> records;
  final int total;
  final int present;
  final int absent;
  final int late;
  final int excused;

  factory AttendanceSummary.fromJson(Map<String, dynamic> j) {
    final items = (j['attendance'] as List? ?? [])
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return AttendanceSummary(
      records: items,
      total: (j['total'] as int?) ?? items.length,
      present: (j['present'] as int?) ?? 0,
      absent: (j['absent'] as int?) ?? 0,
      late: (j['late'] as int?) ?? 0,
      excused: (j['excused'] as int?) ?? 0,
    );
  }

  @override
  List<Object?> get props => [records, total, present, absent, late, excused];
}
