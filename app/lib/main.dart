import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/localization/generated/app_localizations.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/network/dio_client.dart';
import 'core/storage/secure_token_store.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/settings/presentation/preferences_cubit.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>('preferences');

  // Initialise Firebase (gracefully skipped if google-services files are missing in dev).
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase init skipped: $e');
  }

  final tokenStore = SecureTokenStore();
  final dio = buildDio(tokenStore: tokenStore);
  final authRepo = AuthRepository(dio: dio, tokenStore: tokenStore);

  runApp(AltatheebApp(authRepository: authRepo, dio: dio));
}

class AltatheebApp extends StatelessWidget {
  const AltatheebApp({super.key, required this.authRepository, required this.dio});

  final AuthRepository authRepository;
  final Dio dio;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PreferencesCubit()..load()),
        BlocProvider(create: (_) => AuthCubit(authRepository)..bootstrap()),
      ],
      child: BlocBuilder<PreferencesCubit, PreferencesState>(
        builder: (context, prefs) {
          final router = AppRouter(
            authCubit: context.read<AuthCubit>(),
            dio: dio,
          ).router;
          return MaterialApp.router(
            title: 'Altatheeb',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: prefs.themeMode,
            locale: prefs.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: router,
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              return Directionality(
                textDirection: prefs.locale?.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}

