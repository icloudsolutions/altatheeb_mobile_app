import 'package:equatable/equatable.dart';

class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    this.body,
    this.schoolId,
    this.audience,
    this.publishedAt,
  });

  final int id;
  final String title;
  final String? body;
  final int? schoolId;
  final String? audience;
  final DateTime? publishedAt;

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'] as int,
        title: (j['title'] as String?) ?? '',
        body: j['body'] as String?,
        schoolId: j['school_id'] as int?,
        audience: j['audience'] as String?,
        publishedAt: j['published_at'] != null
            ? DateTime.tryParse(j['published_at'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, title, body, schoolId, audience, publishedAt];
}
