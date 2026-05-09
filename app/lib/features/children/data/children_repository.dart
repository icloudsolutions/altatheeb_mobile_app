import 'package:dio/dio.dart';

import '../domain/child.dart';

class ChildrenRepository {
  ChildrenRepository(this._dio);

  final Dio _dio;

  Future<List<Child>> list() async {
    final r = await _dio.get('/v1/children');
    final list = (r.data['students'] as List).cast<Map<String, dynamic>>();
    return list.map(Child.fromJson).toList();
  }
}
