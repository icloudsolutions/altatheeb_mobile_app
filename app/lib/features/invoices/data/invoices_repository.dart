import 'package:dio/dio.dart';

import '../domain/invoice.dart';

class InvoicesRepository {
  InvoicesRepository(this._dio);
  final Dio _dio;

  Future<List<Invoice>> forChild(int studentId) async {
    final r = await _dio.get('/v1/children/$studentId/invoices');
    final list = (r.data['invoices'] as List).cast<Map<String, dynamic>>();
    return list.map(Invoice.fromJson).toList();
  }
}
