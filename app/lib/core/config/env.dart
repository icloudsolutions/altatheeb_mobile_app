/// Compile-time configuration. Pass via:
///
///     flutter run --dart-define=BACKEND_BASE_URL=https://api.example.com
class Env {
  static const String backendBaseUrl =
      String.fromEnvironment('BACKEND_BASE_URL', defaultValue: 'http://10.0.2.2:8000');
}
