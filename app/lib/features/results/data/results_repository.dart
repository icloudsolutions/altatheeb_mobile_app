import 'package:dio/dio.dart';

import '../domain/exam_result.dart';

class ResultsRepository {
  ResultsRepository(this._dio);
  final Dio _dio;

  Future<List<ExamResult>> fetchFor(int studentId) async {
    final r = await _dio.get('/v1/children/$studentId/results');
    final data = r.data as Map<String, dynamic>;
    return (data['results'] as List? ?? [])
        .map((e) => ExamResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
