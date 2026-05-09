// =============================================================================
// PLACEHOLDER — replace by running:
//
//     flutter gen-l10n --arb-dir l10n --template-arb-file app_en.arb \
//                      --output-dir lib/app/localization/generated \
//                      --output-class AppLocalizations \
//                      --output-localization-file app_localizations.dart \
//                      --no-synthetic-package
//
// (or simply `flutter pub run intl_utils:generate` if you adopt the
// `flutter_intl` plugin in your IDE).
//
// Keep this file in source control so static analysis works before the first
// codegen pass; it will be overwritten by the tool above.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _Delegate();

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      const [
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];

  bool get isAr => locale.languageCode == 'ar';

  String get appTitle => isAr ? 'التحضير' : 'Altatheeb';
  String get loginTitle => isAr ? 'تسجيل الدخول' : 'Sign in';
  String get loginUsername => isAr ? 'البريد أو اسم المستخدم' : 'Email or username';
  String get loginPassword => isAr ? 'كلمة المرور' : 'Password';
  String get loginSubmit => isAr ? 'دخول' : 'Sign in';
  String get loginForgot => isAr ? 'نسيت كلمة المرور؟' : 'Forgot password?';
  String get homeWelcome => isAr ? 'الرئيسية' : 'Home';
  String get childrenTitle => isAr ? 'أبنائي' : 'My children';
  String get invoicesTitle => isAr ? 'الفواتير' : 'Invoices';
  String get invoicesEmpty => isAr ? 'لا توجد فواتير بعد.' : 'No invoices yet.';
  String get invoiceAmountTotal => isAr ? 'الإجمالي' : 'Total';
  String get invoiceAmountResidual => isAr ? 'المستحق' : 'Balance';
  String get invoiceStatePosted => isAr ? 'مُصدَرة' : 'Posted';
  String get invoiceStatePaid => isAr ? 'مدفوعة' : 'Paid';
  String get invoiceStateCancelled => isAr ? 'ملغاة' : 'Cancelled';
  String get settingsTitle => isAr ? 'الإعدادات' : 'Settings';
  String get settingsTheme => isAr ? 'المظهر' : 'Theme';
  String get settingsThemeSystem => isAr ? 'حسب النظام' : 'Follow system';
  String get settingsThemeLight => isAr ? 'فاتح' : 'Light';
  String get settingsThemeDark => isAr ? 'داكن' : 'Dark';
  String get settingsLanguage => isAr ? 'اللغة' : 'Language';
  String get settingsLanguageArabic => 'العربية';
  String get settingsLanguageEnglish => isAr ? 'الإنجليزية' : 'English';
  String get logout => isAr ? 'تسجيل الخروج' : 'Sign out';
}

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(_Delegate old) => false;
}
