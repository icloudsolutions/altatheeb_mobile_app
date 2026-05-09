import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.userId,
    required this.role,
    this.name,
    this.odooUserId,
    this.emsParentId,
    this.schoolIds = const [],
  });

  final int userId;
  final String role;
  final String? name;
  final int? odooUserId;
  final int? emsParentId;
  final List<int> schoolIds;

  @override
  List<Object?> get props => [userId, role, name, odooUserId, emsParentId, schoolIds];
}

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AppUser user;
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.error});
  final String? error;
  @override
  List<Object?> get props => [error];
}

class AuthLoading extends AuthState {
  const AuthLoading();
}
