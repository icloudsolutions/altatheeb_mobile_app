import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class PreferencesState {
  const PreferencesState({this.themeMode = ThemeMode.system, this.locale});

  final ThemeMode themeMode;
  final Locale? locale;

  PreferencesState copyWith({ThemeMode? themeMode, Locale? locale}) =>
      PreferencesState(themeMode: themeMode ?? this.themeMode, locale: locale ?? this.locale);
}

class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit() : super(const PreferencesState());

  static const _kThemeMode = 'theme_mode'; // 'system'|'light'|'dark'
  static const _kLocale = 'locale'; // 'ar'|'en'

  Box<dynamic> get _box => Hive.box<dynamic>('preferences');

  Future<void> load() async {
    final tm = _box.get(_kThemeMode, defaultValue: 'system') as String;
    final loc = _box.get(_kLocale, defaultValue: 'ar') as String;
    emit(PreferencesState(
      themeMode: _parseThemeMode(tm),
      locale: Locale(loc),
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.put(_kThemeMode, _stringifyThemeMode(mode));
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLocale(Locale locale) async {
    await _box.put(_kLocale, locale.languageCode);
    emit(state.copyWith(locale: locale));
  }

  ThemeMode _parseThemeMode(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _stringifyThemeMode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
