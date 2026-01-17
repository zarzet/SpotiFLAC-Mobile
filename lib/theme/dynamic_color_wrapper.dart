import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:spotiflac_android/providers/theme_provider.dart';
import 'package:spotiflac_android/theme/app_theme.dart';

/// Wrapper widget that provides dynamic color support from device wallpaper
class DynamicColorWrapper extends ConsumerWidget {
  final Widget Function(ThemeData light, ThemeData dark, ThemeMode mode) builder;

  const DynamicColorWrapper({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (themeSettings.useDynamicColor && lightDynamic != null && darkDynamic != null) {
          // Use dynamic colors from wallpaper (Android 12+)
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        } else {
          final seedColor = themeSettings.seedColor;
          lightScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          );
        }

        // Apply AMOLED mode if enabled (pure black background)
        if (themeSettings.useAmoled) {
          darkScheme = _applyAmoledColors(darkScheme);
        }

        final lightTheme = AppTheme.light(dynamicScheme: lightScheme);
        final darkTheme = AppTheme.dark(dynamicScheme: darkScheme, isAmoled: themeSettings.useAmoled);

        return builder(lightTheme, darkTheme, themeSettings.themeMode);
      },
    );
  }

  /// Apply AMOLED colors - pure black background with adjusted surface colors
  ColorScheme _applyAmoledColors(ColorScheme scheme) {
    return scheme.copyWith(
      surface: Colors.black,
      onSurface: Colors.white,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF121212),
      surfaceContainerHigh: const Color(0xFF1A1A1A),
      surfaceContainerHighest: const Color(0xFF222222),
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
    );
  }
}
