import 'package:equatable/equatable.dart';

class Child extends Equatable {
  const Child({
    required this.id,
    required this.name,
    this.nameEn,
    this.studentNumber,
    this.grade,
    this.division,
    this.schoolId,
    this.state,
  });

  final int id;
  final String name;
  final String? nameEn;
  final String? studentNumber;
  final String? grade;
  final String? division;
  final int? schoolId;
  final String? state;

  factory Child.fromJson(Map<String, dynamic> j) => Child(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        nameEn: j['name_en'] as String?,
        studentNumber: j['student_number'] as String?,
        grade: (j['grade'] is Map ? j['grade']['name'] : j['grade']) as String?,
        division: (j['division'] is Map ? j['division']['name'] : j['division']) as String?,
        schoolId: (j['school'] is Map ? j['school']['id'] : j['school_id']) as int?,
        state: j['state'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, name, nameEn, studentNumber, grade, division, schoolId, state];
}
