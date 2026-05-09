import 'package:dio/dio.dart';

import '../../../core/storage/secure_token_store.dart';
import '../domain/auth_state.dart';

class AuthRepository {
  AuthRepository({required this.dio, required this.tokenStore});

  final Dio dio;
  final SecureTokenStore tokenStore;

  Future<AppUser> login({required String username, required String password}) async {
    final r = await dio.post('/v1/auth/login', data: {
      'username': username,
      'password': password,
    });
    final data = r.data as Map<String, dynamic>;
    await tokenStore.save(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return AppUser(
      userId: data['user_id'] as int,
      role: data['app_role'] as String,
      name: data['name'] as String?,
      odooUserId: data['odoo_user_id'] as int?,
      emsParentId: data['ems_parent_id'] as int?,
      schoolIds: (data['school_ids'] as List?)?.cast<int>() ?? const [],
    );
  }

  Future<void> logout() async {
    try {
      await dio.post('/v1/auth/logout');
    } catch (_) {
      // ignore: stateless logout, drop tokens regardless
    }
    await tokenStore.clear();
  }

  Future<bool> hasSavedSession() async {
    return (await tokenStore.readAccess()) != null;
  }
}
