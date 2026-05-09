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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>('preferences');

  final tokenStore = SecureTokenStore();
  final dio = buildDio(tokenStore: tokenStore);
  final authRepo = AuthRepository(dio: dio, tokenStore: tokenStore);

  runApp(AltatheebApp(
    authRepository: authRepo,
  ));
}

class AltatheebApp extends StatelessWidget {
  const AltatheebApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PreferencesCubit()..load()),
        BlocProvider(create: (_) => AuthCubit(authRepository)..bootstrap()),
      ],
      child: BlocBuilder<PreferencesCubit, PreferencesState>(
        builder: (context, prefs) {
          final router = AppRouter(authCubit: context.read<AuthCubit>()).router;
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
              // Force RTL for Arabic; flutter_localizations already does this when
              // a Locale ar is selected, but we keep an explicit Directionality
              // wrapper so any custom widgets in tests behave consistently.
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

