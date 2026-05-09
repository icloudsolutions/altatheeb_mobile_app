import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/localization/generated/app_localizations.dart';
import 'preferences_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final prefs = context.watch<PreferencesCubit>();
    final state = prefs.state;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          ListTile(title: Text(l.settingsTheme)),
          RadioListTile<ThemeMode>(
            title: Text(l.settingsThemeSystem),
            value: ThemeMode.system,
            groupValue: state.themeMode,
            onChanged: (v) => v == null ? null : prefs.setThemeMode(v),
          ),
          RadioListTile<ThemeMode>(
            title: Text(l.settingsThemeLight),
            value: ThemeMode.light,
            groupValue: state.themeMode,
            onChanged: (v) => v == null ? null : prefs.setThemeMode(v),
          ),
          RadioListTile<ThemeMode>(
            title: Text(l.settingsThemeDark),
            value: ThemeMode.dark,
            groupValue: state.themeMode,
            onChanged: (v) => v == null ? null : prefs.setThemeMode(v),
          ),
          const Divider(),
          ListTile(title: Text(l.settingsLanguage)),
          RadioListTile<String>(
            title: Text(l.settingsLanguageArabic),
            value: 'ar',
            groupValue: state.locale?.languageCode,
            onChanged: (v) => v == null ? null : prefs.setLocale(Locale(v)),
          ),
          RadioListTile<String>(
            title: Text(l.settingsLanguageEnglish),
            value: 'en',
            groupValue: state.locale?.languageCode,
            onChanged: (v) => v == null ? null : prefs.setLocale(Locale(v)),
          ),
        ],
      ),
    );
  }
}
