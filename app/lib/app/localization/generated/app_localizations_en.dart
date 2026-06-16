// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Altatheeb';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginUsername => 'Email or username';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginSubtitle => 'Sign in to manage your children\'s education.';

  @override
  String get loginUsernameRequired => 'Please enter your username.';

  @override
  String get loginPasswordRequired => 'Please enter your password.';

  @override
  String get loginForgot => 'Forgot password?';

  @override
  String get loginErrorInvalidCredentials => 'Invalid username or password.';

  @override
  String get loginErrorRoleNotAllowed => 'Access is restricted to parents.';

  @override
  String get loginErrorNetwork =>
      'Cannot reach the server. Check your connection.';

  @override
  String get loginErrorOdooUnavailable => 'System is offline. Try again later.';

  @override
  String get homeWelcome => 'Home';

  @override
  String get childrenTitle => 'My Children';

  @override
  String get invoicesTitle => 'Invoices';

  @override
  String get invoicesEmpty => 'No invoices yet.';

  @override
  String get invoiceAmountTotal => 'Total';

  @override
  String get invoiceAmountResidual => 'Balance';

  @override
  String get invoiceStatePosted => 'Issued';

  @override
  String get invoiceStatePaid => 'Paid';

  @override
  String get invoiceStateCancelled => 'Cancelled';

  @override
  String get invoiceDateLabel => 'Invoice date';

  @override
  String get invoiceDueDateLabel => 'Due date';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendanceEmpty => 'No attendance records yet.';

  @override
  String get attendanceNoChild => 'Select a child to view attendance.';

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceExcused => 'Excused';

  @override
  String get resultsTitle => 'Results';

  @override
  String get resultsEmpty => 'No results yet.';

  @override
  String get resultsNoChild => 'Select a child to view results.';

  @override
  String get announcementsTitle => 'Announcements';

  @override
  String get announcementsEmpty => 'No announcements yet.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'Follow system';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get seeAll => 'See all';

  @override
  String get retry => 'Retry';

  @override
  String get logout => 'Sign out';
}
