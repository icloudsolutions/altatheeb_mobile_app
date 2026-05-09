import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthInitial());

  final AuthRepository _repo;

  Future<void> bootstrap() async {
    final has = await _repo.hasSavedSession();
    if (has) {
      // Trust saved tokens; the API layer will refresh on 401.
      emit(const AuthAuthenticated(AppUser(userId: 0, role: 'parent')));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({required String username, required String password}) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.login(username: username, password: password);
      if (user.role != 'parent') {
        emit(const AuthUnauthenticated(error: 'role_not_allowed'));
        return;
      }
      emit(AuthAuthenticated(user));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      emit(AuthUnauthenticated(
        error: code == 401 ? 'invalid_credentials'
             : code == 403 ? 'role_not_allowed'
             : 'network',
      ));
    } catch (_) {
      emit(const AuthUnauthenticated(error: 'unknown'));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    emit(const AuthUnauthenticated());
  }
}
