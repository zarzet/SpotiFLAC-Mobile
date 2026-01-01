import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotiflac_android/screens/main_shell.dart';
import 'package:spotiflac_android/screens/setup_screen.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/theme/dynamic_color_wrapper.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  // Only watch isFirstLaunch to prevent router rebuild on other settings changes
  final isFirstLaunch = ref.watch(settingsProvider.select((s) => s.isFirstLaunch));
  
  return GoRouter(
    initialLocation: isFirstLaunch ? '/setup' : '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
    ],
  );
});

class SpotiFLACApp extends ConsumerWidget {
  const SpotiFLACApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    
    return DynamicColorWrapper(
      builder: (lightTheme, darkTheme, themeMode) {
        return MaterialApp.router(
          title: 'SpotiFLAC',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeInOut,
          routerConfig: router,
        );
      },
    );
  }
}
