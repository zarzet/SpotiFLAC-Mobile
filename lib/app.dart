import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:spotiflac_android/screens/main_shell.dart';
import 'package:spotiflac_android/screens/setup_screen.dart';
import 'package:spotiflac_android/screens/tutorial_screen.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/theme/dynamic_color_wrapper.dart';
import 'package:spotiflac_android/l10n/app_localizations.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final isFirstLaunch = ref.watch(
    settingsProvider.select((s) => s.isFirstLaunch),
  );
  final hasCompletedTutorial = ref.watch(
    settingsProvider.select((s) => s.hasCompletedTutorial),
  );

  // Determine initial location based on app state
  String initialLocation;
  if (isFirstLaunch) {
    initialLocation = '/setup';
  } else if (!hasCompletedTutorial) {
    initialLocation = '/tutorial';
  } else {
    initialLocation = '/';
  }

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MainShell()),
      GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
      GoRoute(
        path: '/tutorial',
        builder: (context, state) => const TutorialScreen(),
      ),
    ],
    // Safety net: if a deep link URL (e.g. Spotify/Deezer) somehow reaches
    // GoRouter, redirect to home instead of showing "Page Not Found".
    errorBuilder: (context, state) => const MainShell(),
  );
});

class SpotiFLACApp extends ConsumerWidget {
  final bool disableOverscrollEffects;

  const SpotiFLACApp({super.key, this.disableOverscrollEffects = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    final localeString = ref.watch(settingsProvider.select((s) => s.locale));
    final scrollBehavior = disableOverscrollEffects
        ? const MaterialScrollBehavior().copyWith(overscroll: false)
        : null;

    Locale? locale;
    if (localeString != 'system' && localeString.isNotEmpty) {
      if (localeString.contains('_')) {
        final parts = localeString.split('_');
        if (parts.length == 2) {
          locale = Locale(parts[0], parts[1]);
        } else {
          locale = Locale(parts[0]);
        }
      } else {
        locale = Locale(localeString);
      }
    }

    return DynamicColorWrapper(
      builder: (lightTheme, darkTheme, themeMode) {
        return MaterialApp.router(
          title: 'SpotiFLAC',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          scrollBehavior: scrollBehavior,
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeInOut,
          routerConfig: router,
          locale: locale,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (locale != null) return locale;
            if (deviceLocale == null) return supportedLocales.first;

            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == deviceLocale.languageCode &&
                  supportedLocale.countryCode == deviceLocale.countryCode) {
                return supportedLocale;
              }
            }

            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == deviceLocale.languageCode) {
                return supportedLocale;
              }
            }

            return supportedLocales.first;
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}
