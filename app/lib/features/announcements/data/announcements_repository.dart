import 'package:dio/dio.dart';

import '../domain/announcement.dart';

class AnnouncementsRepository {
  AnnouncementsRepository(this._dio);
  final Dio _dio;

  Future<List<Announcement>> fetch({int? schoolId}) async {
    final params = <String, dynamic>{};
    if (schoolId != null) params['school_id'] = schoolId;
    final r = await _dio.get('/v1/announcements', queryParameters: params.isEmpty ? null : params);
    final data = r.data as Map<String, dynamic>;
    return (data['announcements'] as List? ?? [])
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
