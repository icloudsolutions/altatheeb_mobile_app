import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../domain/auth_state.dart';
import 'auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _u = TextEditingController();
  final _p = TextEditingController();

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthUnauthenticated && state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_describeError(state.error!, l))),
                    );
                  }
                },
                builder: (context, state) {
                  final loading = state is AuthLoading;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.appTitle, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 32),
                      Text(l.loginTitle,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _u,
                        decoration: InputDecoration(labelText: l.loginUsername),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _p,
                        decoration: InputDecoration(labelText: l.loginPassword),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: loading
                            ? null
                            : () => context.read<AuthCubit>().login(
                                  username: _u.text.trim(),
                                  password: _p.text,
                                ),
                        child: loading
                            ? const SizedBox(
                                height: 18, width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(l.loginSubmit),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: loading ? null : () {},
                        child: Text(l.loginForgot),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _describeError(String code, AppLocalizations l) {
    switch (code) {
      case 'invalid_credentials':
        return 'Invalid credentials';
      case 'role_not_allowed':
        return 'This app is parent-only for now.';
      case 'network':
        return 'Network error';
      default:
        return 'Sign-in failed';
    }
  }
}
