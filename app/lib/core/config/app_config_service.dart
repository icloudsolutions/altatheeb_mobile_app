import 'package:dio/dio.dart';

class AppConfig {
  const AppConfig({
    this.minAndroid = '0.0.0',
    this.minIos = '0.0.0',
    this.maintenanceEnabled = false,
    this.maintenanceTitleAr,
    this.maintenanceTitleEn,
    this.maintenanceBodyAr,
    this.maintenanceBodyEn,
    this.featureFlags = const {},
  });

  final String minAndroid;
  final String minIos;
  final bool maintenanceEnabled;
  final String? maintenanceTitleAr;
  final String? maintenanceTitleEn;
  final String? maintenanceBodyAr;
  final String? maintenanceBodyEn;
  final Map<String, bool> featureFlags;

  bool isFeatureEnabled(String key) => featureFlags[key] ?? false;

  factory AppConfig.fromJson(Map<String, dynamic> j) {
    final ver = j['min_app_version'] as Map<String, dynamic>? ?? {};
    final banner = j['maintenance_banner'] as Map<String, dynamic>? ?? {};
    final flags = (j['feature_flags'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v as bool));
    return AppConfig(
      minAndroid: (ver['android'] as String?) ?? '0.0.0',
      minIos: (ver['ios'] as String?) ?? '0.0.0',
      maintenanceEnabled: (banner['enabled'] as bool?) ?? false,
      maintenanceTitleAr: banner['title_ar'] as String?,
      maintenanceTitleEn: banner['title_en'] as String?,
      maintenanceBodyAr: banner['body_ar'] as String?,
      maintenanceBodyEn: banner['body_en'] as String?,
      featureFlags: flags,
    );
  }
}

class AppConfigService {
  AppConfigService(this._dio);
  final Dio _dio;

  AppConfig _current = const AppConfig();
  AppConfig get current => _current;

  Future<void> fetch() async {
    try {
      final r = await _dio.get('/v1/config');
      _current = AppConfig.fromJson(r.data as Map<String, dynamic>);
    } catch (_) {
      // Keep previous / default config if fetch fails.
    }
  }
}
