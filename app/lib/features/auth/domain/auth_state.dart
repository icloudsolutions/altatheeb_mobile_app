import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.userId,
    required this.role,
    this.name,
    this.email,
    this.phone,
    this.odooUserId,
    this.emsParentId,
    this.schoolIds = const [],
  });

  final int userId;
  final String role;
  final String? name;
  final String? email;
  final String? phone;
  final int? odooUserId;
  final int? emsParentId;
  final List<int> schoolIds;

  AppUser copyWith({
    int? userId,
    String? role,
    String? name,
    String? email,
    String? phone,
    int? odooUserId,
    int? emsParentId,
    List<int>? schoolIds,
  }) => AppUser(
    userId: userId ?? this.userId,
    role: role ?? this.role,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    odooUserId: odooUserId ?? this.odooUserId,
    emsParentId: emsParentId ?? this.emsParentId,
    schoolIds: schoolIds ?? this.schoolIds,
  );

  @override
  List<Object?> get props => [userId, role, name, email, phone, odooUserId, emsParentId, schoolIds];
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
