import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/secure_token_store.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/children/data/children_repository.dart';
import '../../features/children/presentation/children_cubit.dart';
import '../../features/children/presentation/home_shell.dart';
import '../../features/invoices/data/invoices_repository.dart';
import '../../features/invoices/presentation/invoices_cubit.dart';

class AppRouter {
  AppRouter({required this.authCubit});

  final AuthCubit authCubit;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(authCubit.stream),
    redirect: (context, state) {
      final s = authCubit.state;
      final loggingIn = state.matchedLocation == '/login';
      if (s is AuthInitial) return null;
      if (s is AuthUnauthenticated) {
        return loggingIn ? null : '/login';
      }
      if (s is AuthAuthenticated && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(
        path: '/',
        builder: (context, _) {
          final dio = buildDio(tokenStore: SecureTokenStore());
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => ChildrenCubit(ChildrenRepository(dio))),
              BlocProvider(create: (_) => InvoicesCubit(InvoicesRepository(dio))),
            ],
            child: const HomeShell(),
          );
        },
      ),
    ],
  );
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Stream<AuthState> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
