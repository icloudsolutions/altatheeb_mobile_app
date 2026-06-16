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
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthCubit>().login(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: cs.surface,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated && state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorText(state.error!, l))),
                    ],
                  ),
                  backgroundColor: cs.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 600;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: wide
                          ? _WideLayout(
                              formKey: _formKey,
                              usernameCtrl: _usernameCtrl,
                              passwordCtrl: _passwordCtrl,
                              obscurePassword: _obscurePassword,
                              onToggleObscure: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              onSubmit: _submit,
                              loading: loading,
                              l: l,
                              isAr: isAr,
                            )
                          : _NarrowLayout(
                              formKey: _formKey,
                              usernameCtrl: _usernameCtrl,
                              passwordCtrl: _passwordCtrl,
                              obscurePassword: _obscurePassword,
                              onToggleObscure: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              onSubmit: _submit,
                              loading: loading,
                              l: l,
                              isAr: isAr,
                            ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _errorText(String code, AppLocalizations l) {
    return switch (code) {
      'invalid_credentials' => l.loginErrorInvalidCredentials,
      'role_not_allowed' => l.loginErrorRoleNotAllowed,
      'network' => l.loginErrorNetwork,
      'odoo_unavailable_no_local_credentials' => l.loginErrorOdooUnavailable,
      _ => l.loginErrorNetwork,
    };
  }
}

// ---------------------------------------------------------------------------
// Narrow (phone) layout
// ---------------------------------------------------------------------------

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.formKey,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.loading,
    required this.l,
    required this.isAr,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final bool loading;
  final AppLocalizations l;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Top brand header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1B6B3A),
                const Color(0xFF2E8B57),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogoMark(),
              const SizedBox(height: 24),
              Text(
                isAr ? 'مدارس التحضير' : 'Al Tahtheeb Schools',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'نظام إدارة أولياء الأمور'
                    : 'Parent Management System',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
        ),

        // Form card
        Expanded(
          child: Container(
            color: cs.surface,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _LoginForm(
                formKey: formKey,
                usernameCtrl: usernameCtrl,
                passwordCtrl: passwordCtrl,
                obscurePassword: obscurePassword,
                onToggleObscure: onToggleObscure,
                onSubmit: onSubmit,
                loading: loading,
                l: l,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Wide (tablet/desktop) layout
// ---------------------------------------------------------------------------

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.formKey,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.loading,
    required this.l,
    required this.isAr,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final bool loading;
  final AppLocalizations l;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Brand panel
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B6B3A), Color(0xFF2E8B57)],
              ),
            ),
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LogoMark(size: 72),
                const SizedBox(height: 32),
                Text(
                  isAr ? 'مدارس التحضير' : 'Al Tahtheeb Schools',
                  style:
                      Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'نظام إدارة أولياء الأمور'
                      : 'Parent Management System',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
        ),
        // Form panel
        Expanded(
          child: Container(
            color: cs.surface,
            padding: const EdgeInsets.all(48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: _LoginForm(
                  formKey: formKey,
                  usernameCtrl: usernameCtrl,
                  passwordCtrl: passwordCtrl,
                  obscurePassword: obscurePassword,
                  onToggleObscure: onToggleObscure,
                  onSubmit: onSubmit,
                  loading: loading,
                  l: l,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared form
// ---------------------------------------------------------------------------

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.loading,
    required this.l,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final bool loading;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.loginTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l.loginSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: usernameCtrl,
            decoration: InputDecoration(
              labelText: l.loginUsername,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.loginUsernameRequired : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordCtrl,
            decoration: InputDecoration(
              labelText: l.loginPassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            validator: (v) =>
                (v == null || v.isEmpty) ? l.loginPasswordRequired : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: loading ? null : () {},
              child: Text(l.loginForgot),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(l.loginSubmit),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo mark widget
// ---------------------------------------------------------------------------

class _LogoMark extends StatelessWidget {
  const _LogoMark({this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          'ت',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
