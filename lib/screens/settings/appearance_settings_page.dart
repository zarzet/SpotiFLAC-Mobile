import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/theme_provider.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // Collapsing App Bar with back button
            SliverAppBar(
              expandedHeight: 120 + topPadding,
              collapsedHeight: kToolbarHeight,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: _AppBarTitle(
                title: 'Appearance',
                topPadding: topPadding,
              ),
            ),

            // Preview Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _ThemePreviewCard(),
              ),
            ),

            // Color section
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Color'),
            ),

            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.wallpaper,
                    title: 'Dynamic Color',
                    subtitle: 'Use colors from your wallpaper',
                    value: themeSettings.useDynamicColor,
                    onChanged: (value) => ref
                        .read(themeProvider.notifier)
                        .setUseDynamicColor(value),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            if (!themeSettings.useDynamicColor)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _ColorPalettePicker(
                    currentColor: themeSettings.seedColorValue,
                    onColorSelected: (color) =>
                        ref.read(themeProvider.notifier).setSeedColor(color),
                  ),
                ),
              ),

            // Theme section
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Theme'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _ThemeModeSelector(
                    currentMode: themeSettings.themeMode,
                    onChanged: (mode) =>
                        ref.read(themeProvider.notifier).setThemeMode(mode),
                  ),
                  if (Theme.of(context).brightness == Brightness.dark)
                    SettingsSwitchItem(
                      icon: Icons.brightness_2,
                      title: 'AMOLED Dark',
                      subtitle: 'Pure black background',
                      value: themeSettings.useAmoled,
                      onChanged: (value) =>
                          ref.read(themeProvider.notifier).setUseAmoled(value),
                      showDivider: false,
                    ),
                ],
              ),
            ),

            // Layout section
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Layout'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _HistoryViewSelector(
                    currentMode: settings.historyViewMode,
                    onChanged: (mode) => ref
                        .read(settingsProvider.notifier)
                        .setHistoryViewMode(mode),
                  ),
                ],
              ),
            ),

            // Fill remaining for scroll
            const SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simplified preview of how the app looks with current settings
class _ThemePreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme
              .surfaceContainerHighest, // Background similar to reference
          borderRadius: BorderRadius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative background blobs
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                ),
              ),
            ),

            // Foreground "fake UI"
            Center(
              child: Container(
                width: 260,
                height: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12, // Reduced from 20 for performance
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Fake Album Art
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: colorScheme.onPrimary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Fake Text Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 14,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.skip_previous,
                                size: 24,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.play_circle_fill,
                                size: 32,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.skip_next,
                                size: 24,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Label badge
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPalettePicker extends StatelessWidget {
  final int currentColor;
  final ValueChanged<Color> onColorSelected;
  const _ColorPalettePicker({
    required this.currentColor,
    required this.onColorSelected,
  });

  static const _colors = [
    Color(0xFF1DB954),
    Color(0xFF6750A4),
    Color(0xFF0061A4),
    Color(0xFF006E1C),
    Color(0xFFBA1A1A),
    Color(0xFF984061),
    Color(0xFF7D5260),
    Color(0xFF006874),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _colors.map((color) {
          final isSelected = color.toARGB32() == currentColor;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onColorSelected(color),
              child: _ColorPaletteItem(color: color, isSelected: isSelected),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ColorPaletteItem extends StatelessWidget {
  final Color color;
  final bool isSelected;

  const _ColorPaletteItem({required this.color, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: Theme.of(context).brightness,
    );
    final size = 64.0;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: Container(color: scheme.primaryContainer)),
                    Expanded(child: Container(color: scheme.tertiaryContainer)),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(color: scheme.secondaryContainer),
                    ),
                    Expanded(child: Container(color: scheme.surfaceContainer)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isSelected)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 16, color: scheme.primary),
              ),
            ),
          ),
      ],
    );
  }
}

/// Optimized app bar title with animation
class _AppBarTitle extends StatelessWidget {
  final String title;
  final double topPadding;

  const _AppBarTitle({required this.title, required this.topPadding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = 120 + topPadding;
        final minHeight = kToolbarHeight + topPadding;
        final expandRatio =
            ((constraints.maxHeight - minHeight) / (maxHeight - minHeight))
                .clamp(0.0, 1.0);
        final leftPadding = 56 - (32 * expandRatio); // 56 -> 24
        return FlexibleSpaceBar(
          expandedTitleScale: 1.0,
          titlePadding: EdgeInsets.only(left: leftPadding, bottom: 16),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20 + (8 * expandRatio), // 20 -> 28
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeModeSelector({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _ThemeModeChip(
            icon: Icons.brightness_auto,
            label: 'System',
            isSelected: currentMode == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
          ),
          const SizedBox(width: 8),
          _ThemeModeChip(
            icon: Icons.light_mode,
            label: 'Light',
            isSelected: currentMode == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
          const SizedBox(width: 8),
          _ThemeModeChip(
            icon: Icons.dark_mode,
            label: 'Dark',
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeModeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Unselected chips need contrast with card background
    // Card uses: dark = white 8% overlay, light = surfaceContainerHighest
    // So chips use: dark = white 5% overlay (darker), light = black 5% overlay (darker than card)
    final unselectedColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            colorScheme.surface,
          )
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.05),
            colorScheme.surfaceContainerHighest,
          );

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : unselectedColor,
          borderRadius: BorderRadius.circular(12),
          border: !isDark && !isSelected
              ? Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryViewSelector extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onChanged;
  const _HistoryViewSelector({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'History View',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Row(
            children: [
              _ViewModeChip(
                icon: Icons.view_list,
                label: 'List',
                isSelected: currentMode == 'list',
                onTap: () => onChanged('list'),
              ),
              const SizedBox(width: 8),
              _ViewModeChip(
                icon: Icons.grid_view,
                label: 'Grid',
                isSelected: currentMode == 'grid',
                onTap: () => onChanged('grid'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ViewModeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Unselected chips need contrast with card background
    final unselectedColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            colorScheme.surface,
          )
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.05),
            colorScheme.surfaceContainerHighest,
          );

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : unselectedColor,
          borderRadius: BorderRadius.circular(12),
          border: !isDark && !isSelected
              ? Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
