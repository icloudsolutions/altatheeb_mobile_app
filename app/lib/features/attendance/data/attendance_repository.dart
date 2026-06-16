import 'package:dio/dio.dart';

import '../domain/attendance_record.dart';

class AttendanceRepository {
  AttendanceRepository(this._dio);
  final Dio _dio;

  Future<AttendanceSummary> fetchFor(int studentId, {String? from, String? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final r = await _dio.get(
      '/v1/children/$studentId/attendance',
      queryParameters: params.isEmpty ? null : params,
    );
    return AttendanceSummary.fromJson(r.data as Map<String, dynamic>);
  }
}
