import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env.dart';
import '../storage/secure_token_store.dart';

Dio buildDio({required SecureTokenStore tokenStore}) {
  final dio = Dio(BaseOptions(
    baseUrl: Env.backendBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    contentType: 'application/json',
    responseType: ResponseType.json,
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final access = await tokenStore.readAccess();
      if (access != null && access.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      // 401 -> try refresh once.
      if (e.response?.statusCode == 401 &&
          e.requestOptions.extra['retried'] != true) {
        final refresh = await tokenStore.readRefresh();
        if (refresh != null && refresh.isNotEmpty) {
          try {
            final r = await Dio(BaseOptions(baseUrl: Env.backendBaseUrl)).post(
              '/v1/auth/refresh',
              data: {'refresh': refresh},
            );
            await tokenStore.save(
              access: r.data['access'] as String,
              refresh: r.data['refresh'] as String,
            );
            final opts = e.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${r.data['access']}';
            opts.extra['retried'] = true;
            final retry = await Dio().fetch(opts);
            return handler.resolve(retry);
          } catch (_) {
            // fallthrough to default error
          }
        }
      }
      handler.next(e);
    },
  ));

  if (kDebugMode) {
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseBody: false,
      responseHeader: false,
    ));
  }
  return dio;
}
