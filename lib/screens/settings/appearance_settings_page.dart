import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/theme_provider.dart';

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
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
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = 120 + topPadding;
                final minHeight = kToolbarHeight + topPadding;
                final expandRatio = ((constraints.maxHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);
                final animation = AlwaysStoppedAnimation(expandRatio);
                return FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  titlePadding: EdgeInsets.zero,
                  title: SafeArea(
                    child: Container(
                      alignment: Alignment.bottomLeft,
                      padding: EdgeInsets.only(
                        left: Tween<double>(begin: 56, end: 24).evaluate(animation),
                        bottom: Tween<double>(begin: 12, end: 16).evaluate(animation),
                      ),
                      child: Text('Appearance',
                        style: TextStyle(
                          fontSize: Tween<double>(begin: 20, end: 28).evaluate(animation),
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Theme section
          SliverToBoxAdapter(child: _SectionHeader(title: 'Theme')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ThemeModeSelector(
                currentMode: themeSettings.themeMode,
                onChanged: (mode) => ref.read(themeProvider.notifier).setThemeMode(mode),
              ),
            ),
          ),

          // Color section
          SliverToBoxAdapter(child: _SectionHeader(title: 'Color')),
          SliverToBoxAdapter(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: const Text('Dynamic Color'),
              subtitle: const Text('Use colors from your wallpaper'),
              value: themeSettings.useDynamicColor,
              onChanged: (value) => ref.read(themeProvider.notifier).setUseDynamicColor(value),
            ),
          ),

          if (!themeSettings.useDynamicColor)
            SliverToBoxAdapter(
              child: _ColorPicker(
                currentColor: themeSettings.seedColorValue,
                onColorSelected: (color) => ref.read(themeProvider.notifier).setSeedColor(color),
              ),
            ),

          // Layout section
          SliverToBoxAdapter(child: _SectionHeader(title: 'Layout')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HistoryViewSelector(
                currentMode: settings.historyViewMode,
                onChanged: (mode) => ref.read(settingsProvider.notifier).setHistoryViewMode(mode),
              ),
            ),
          ),

          // Fill remaining for scroll
          const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
  );
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeModeSelector({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          _ThemeModeChip(icon: Icons.brightness_auto, label: 'System', isSelected: currentMode == ThemeMode.system, onTap: () => onChanged(ThemeMode.system)),
          const SizedBox(width: 8),
          _ThemeModeChip(icon: Icons.light_mode, label: 'Light', isSelected: currentMode == ThemeMode.light, onTap: () => onChanged(ThemeMode.light)),
          const SizedBox(width: 8),
          _ThemeModeChip(icon: Icons.dark_mode, label: 'Dark', isSelected: currentMode == ThemeMode.dark, onTap: () => onChanged(ThemeMode.dark)),
        ]),
      ),
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeModeChip({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Icon(icon, color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int currentColor;
  final ValueChanged<Color> onColorSelected;
  const _ColorPicker({required this.currentColor, required this.onColorSelected});

  static const _colors = [
    Color(0xFF1DB954), Color(0xFF6750A4), Color(0xFF0061A4), Color(0xFF006E1C),
    Color(0xFFBA1A1A), Color(0xFF984061), Color(0xFF7D5260), Color(0xFF006874), Color(0xFFFF6F00),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Accent Color', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: _colors.map((color) {
          final isSelected = color.toARGB32() == currentColor;
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                border: isSelected ? Border.all(color: colorScheme.onSurface, width: 3) : null,
                boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)] : null,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
          );
        }).toList()),
      ]),
    );
  }
}

class _HistoryViewSelector extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onChanged;
  const _HistoryViewSelector({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Text('History View', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
            Row(children: [
              _ViewModeChip(icon: Icons.view_list, label: 'List', isSelected: currentMode == 'list', onTap: () => onChanged('list')),
              const SizedBox(width: 8),
              _ViewModeChip(icon: Icons.grid_view, label: 'Grid', isSelected: currentMode == 'grid', onTap: () => onChanged('grid')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ViewModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ViewModeChip({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Icon(icon, color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }
}
