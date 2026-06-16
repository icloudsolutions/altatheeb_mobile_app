// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'التحضير';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginUsername => 'البريد الإلكتروني أو اسم المستخدم';

  @override
  String get loginPassword => 'كلمة المرور';

  @override
  String get loginSubmit => 'دخول';

  @override
  String get loginSubtitle => 'سجّل دخولك لمتابعة تعليم أبنائك.';

  @override
  String get loginUsernameRequired => 'يرجى إدخال اسم المستخدم.';

  @override
  String get loginPasswordRequired => 'يرجى إدخال كلمة المرور.';

  @override
  String get loginForgot => 'نسيت كلمة المرور؟';

  @override
  String get loginErrorInvalidCredentials =>
      'اسم المستخدم أو كلمة المرور غير صحيحة.';

  @override
  String get loginErrorRoleNotAllowed => 'الوصول مقتصر على أولياء الأمور.';

  @override
  String get loginErrorNetwork => 'تعذّر الاتصال بالخادم. تحقق من اتصالك.';

  @override
  String get loginErrorOdooUnavailable =>
      'النظام غير متاح حالياً. حاول مجدداً لاحقاً.';

  @override
  String get homeWelcome => 'الرئيسية';

  @override
  String get childrenTitle => 'أبنائي';

  @override
  String get invoicesTitle => 'الفواتير';

  @override
  String get invoicesEmpty => 'لا توجد فواتير بعد.';

  @override
  String get invoiceAmountTotal => 'الإجمالي';

  @override
  String get invoiceAmountResidual => 'المستحق';

  @override
  String get invoiceStatePosted => 'مُصدَرة';

  @override
  String get invoiceStatePaid => 'مدفوعة';

  @override
  String get invoiceStateCancelled => 'ملغاة';

  @override
  String get invoiceDateLabel => 'تاريخ الفاتورة';

  @override
  String get invoiceDueDateLabel => 'تاريخ الاستحقاق';

  @override
  String get attendanceTitle => 'الحضور';

  @override
  String get attendanceEmpty => 'لا توجد سجلات حضور بعد.';

  @override
  String get attendanceNoChild => 'اختر طالباً لعرض الحضور.';

  @override
  String get attendancePresent => 'حاضر';

  @override
  String get attendanceAbsent => 'غائب';

  @override
  String get attendanceLate => 'متأخر';

  @override
  String get attendanceExcused => 'بعذر';

  @override
  String get resultsTitle => 'النتائج';

  @override
  String get resultsEmpty => 'لا توجد نتائج بعد.';

  @override
  String get resultsNoChild => 'اختر طالباً لعرض النتائج.';

  @override
  String get announcementsTitle => 'الإعلانات';

  @override
  String get announcementsEmpty => 'لا توجد إعلانات بعد.';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeSystem => 'حسب النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'الإنجليزية';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get logout => 'تسجيل الخروج';
}
