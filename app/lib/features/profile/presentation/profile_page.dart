import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../children/presentation/children_cubit.dart';
import '../../settings/presentation/preferences_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthCubit>().state;
    final user = (authState is AuthAuthenticated) ? authState.user : null;
    final childrenState = context.watch<ChildrenCubit>().state;
    final children =
        (childrenState is ChildrenLoaded) ? childrenState.children : <dynamic>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.logout,
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(
                    user?.name?.isNotEmpty == true
                        ? user!.name![0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 12),
                if (user?.name != null)
                  Text(user!.name!,
                      style: Theme.of(context).textTheme.titleLarge),
                if (user?.email != null)
                  Text(user!.email!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(.6))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Children section
          if (children.isNotEmpty) ...[
            Text(l.childrenTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children.map((c) => ListTile(
                  leading: CircleAvatar(
                      child: Text(c.name.isNotEmpty ? c.name[0] : '?')),
                  title: Text(c.name),
                  subtitle: Text([
                    if (c.grade != null) c.grade!,
                    if (c.division != null) c.division!,
                  ].join(' · ')),
                  dense: true,
                )),
            const SizedBox(height: 16),
          ],

          const Divider(),
          const SizedBox(height: 8),

          // Settings section embedded
          Text(l.settingsTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const _ThemePicker(),
          const SizedBox(height: 8),
          const _LanguagePicker(),
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final prefs = context.watch<PreferencesCubit>().state;
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(l.settingsTheme),
      trailing: DropdownButton<ThemeMode>(
        value: prefs.themeMode,
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem(
              value: ThemeMode.system, child: Text(l.settingsThemeSystem)),
          DropdownMenuItem(
              value: ThemeMode.light, child: Text(l.settingsThemeLight)),
          DropdownMenuItem(
              value: ThemeMode.dark, child: Text(l.settingsThemeDark)),
        ],
        onChanged: (m) {
          if (m != null) context.read<PreferencesCubit>().setThemeMode(m);
        },
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final prefs = context.watch<PreferencesCubit>().state;
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l.settingsLanguage),
      trailing: DropdownButton<String>(
        value: prefs.locale?.languageCode ?? 'en',
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem(value: 'ar', child: Text(l.settingsLanguageArabic)),
          DropdownMenuItem(
              value: 'en', child: Text(l.settingsLanguageEnglish)),
        ],
        onChanged: (code) {
          if (code != null) {
            context
                .read<PreferencesCubit>()
                .setLocale(Locale(code));
          }
        },
      ),
    );
  }
}
