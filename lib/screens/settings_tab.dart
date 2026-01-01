import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/theme_provider.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = ref.watch(settingsProvider);
    final themeSettings = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        // Theme Section
        _buildSectionHeader(context, 'Appearance', colorScheme),
        
        // Theme Mode
        ListTile(
          leading: Icon(Icons.brightness_6, color: colorScheme.primary),
          title: const Text('Theme Mode'),
          subtitle: Text(_getThemeModeName(themeSettings.themeMode)),
          onTap: () => _showThemeModePicker(context, ref, themeSettings.themeMode),
        ),
        
        // Dynamic Color Toggle
        SwitchListTile(
          secondary: Icon(Icons.palette, color: colorScheme.primary),
          title: const Text('Dynamic Color'),
          subtitle: const Text('Use colors from your wallpaper'),
          value: themeSettings.useDynamicColor,
          onChanged: (value) => ref.read(themeProvider.notifier).setUseDynamicColor(value),
        ),
        
        // Seed Color Picker (only when dynamic color is disabled)
        if (!themeSettings.useDynamicColor)
          ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(themeSettings.seedColorValue),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline),
              ),
            ),
            title: const Text('Accent Color'),
            subtitle: const Text('Choose your preferred color'),
            onTap: () => _showColorPicker(context, ref, themeSettings.seedColorValue),
          ),
        
        // Theme Preview
        _buildThemePreview(context, colorScheme),
        
        const Divider(),
        
        // Download Section
        _buildSectionHeader(context, 'Download', colorScheme),

        // Download Service
        ListTile(
          leading: Icon(Icons.cloud_download, color: colorScheme.primary),
          title: const Text('Default Service'),
          subtitle: Text(_getServiceName(settings.defaultService)),
          onTap: () => _showServicePicker(context, ref, settings.defaultService),
        ),

        // Audio Quality
        ListTile(
          leading: Icon(Icons.high_quality, color: colorScheme.primary),
          title: const Text('Audio Quality'),
          subtitle: Text(_getQualityName(settings.audioQuality)),
          onTap: () => _showQualityPicker(context, ref, settings.audioQuality),
        ),

        // Filename Format
        ListTile(
          leading: Icon(Icons.text_fields, color: colorScheme.primary),
          title: const Text('Filename Format'),
          subtitle: Text(settings.filenameFormat),
          onTap: () => _showFormatEditor(context, ref, settings.filenameFormat),
        ),

        // Download Directory
        ListTile(
          leading: Icon(Icons.folder, color: colorScheme.primary),
          title: const Text('Download Directory'),
          subtitle: Text(settings.downloadDirectory.isEmpty ? 'Music/SpotiFLAC' : settings.downloadDirectory),
          onTap: () => _pickDirectory(context, ref),
        ),
        
        const Divider(),
        
        // Options Section
        _buildSectionHeader(context, 'Options', colorScheme),

        // Auto Fallback
        SwitchListTile(
          secondary: Icon(Icons.sync, color: colorScheme.primary),
          title: const Text('Auto Fallback'),
          subtitle: const Text('Try other services if download fails'),
          value: settings.autoFallback,
          onChanged: (value) => ref.read(settingsProvider.notifier).setAutoFallback(value),
        ),

        // Embed Lyrics
        SwitchListTile(
          secondary: Icon(Icons.lyrics, color: colorScheme.primary),
          title: const Text('Embed Lyrics'),
          subtitle: const Text('Embed synced lyrics into FLAC files'),
          value: settings.embedLyrics,
          onChanged: (value) => ref.read(settingsProvider.notifier).setEmbedLyrics(value),
        ),

        // Max Quality Cover
        SwitchListTile(
          secondary: Icon(Icons.image, color: colorScheme.primary),
          title: const Text('Max Quality Cover'),
          subtitle: const Text('Download highest resolution cover art'),
          value: settings.maxQualityCover,
          onChanged: (value) => ref.read(settingsProvider.notifier).setMaxQualityCover(value),
        ),
        
        const Divider(),

        // About
        ListTile(
          leading: Icon(Icons.info, color: colorScheme.primary),
          title: const Text('About'),
          subtitle: const Text('SpotiFLAC v1.0.1'),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'SpotiFLAC',
            applicationVersion: '1.0.1',
            applicationLegalese: '© 2024 SpotiFLAC',
          ),
        ),
        
        // Bottom padding for navigation bar
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemePreview(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme Preview', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildColorChip('Primary', colorScheme.primary, colorScheme.onPrimary),
                  _buildColorChip('Secondary', colorScheme.secondary, colorScheme.onSecondary),
                  _buildColorChip('Tertiary', colorScheme.tertiary, colorScheme.onTertiary),
                  _buildColorChip('Surface', colorScheme.surface, colorScheme.onSurface),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorChip(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(color: foreground, fontSize: 12)),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'System';
    }
  }

  String _getServiceName(String service) {
    switch (service) {
      case 'tidal': return 'Tidal';
      case 'qobuz': return 'Qobuz';
      case 'amazon': return 'Amazon Music';
      default: return service;
    }
  }

  String _getQualityName(String quality) {
    switch (quality) {
      case 'LOSSLESS': return 'FLAC (Lossless)';
      case 'HI_RES': return 'Hi-Res FLAC (24-bit)';
      default: return quality;
    }
  }

  void _showThemeModePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeModeOption(context, ref, ThemeMode.system, 'System', Icons.brightness_auto, current, colorScheme),
            _buildThemeModeOption(context, ref, ThemeMode.light, 'Light', Icons.light_mode, current, colorScheme),
            _buildThemeModeOption(context, ref, ThemeMode.dark, 'Dark', Icons.dark_mode, current, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeOption(BuildContext context, WidgetRef ref, ThemeMode mode, String label, IconData icon, ThemeMode current, ColorScheme colorScheme) {
    final isSelected = mode == current;
    return ListTile(
      leading: Icon(icon, color: isSelected ? colorScheme.primary : null),
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
      onTap: () {
        ref.read(themeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, int currentColor) {
    final colors = [
      const Color(0xFF1DB954), const Color(0xFF6750A4), const Color(0xFF0061A4),
      const Color(0xFF006E1C), const Color(0xFFBA1A1A), const Color(0xFF984061),
      const Color(0xFF7D5260), const Color(0xFF006874), const Color(0xFFFF6F00),
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Accent Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = color.toARGB32() == currentColor;
            return GestureDetector(
              onTap: () {
                ref.read(themeProvider.notifier).setSeedColor(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showServicePicker(BuildContext context, WidgetRef ref, String current) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildServiceOption(context, ref, 'tidal', 'Tidal', current, colorScheme),
            _buildServiceOption(context, ref, 'qobuz', 'Qobuz', current, colorScheme),
            _buildServiceOption(context, ref, 'amazon', 'Amazon Music', current, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOption(BuildContext context, WidgetRef ref, String value, String label, String current, ColorScheme colorScheme) {
    final isSelected = value == current;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
      onTap: () {
        ref.read(settingsProvider.notifier).setDefaultService(value);
        Navigator.pop(context);
      },
    );
  }

  void _showQualityPicker(BuildContext context, WidgetRef ref, String current) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityOption(context, ref, 'LOSSLESS', 'FLAC (Lossless)', '16-bit / 44.1kHz', current, colorScheme),
            _buildQualityOption(context, ref, 'HI_RES', 'Hi-Res FLAC', '24-bit / up to 192kHz', current, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption(BuildContext context, WidgetRef ref, String value, String title, String subtitle, String current, ColorScheme colorScheme) {
    final isSelected = value == current;
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
      onTap: () {
        ref.read(settingsProvider.notifier).setAudioQuality(value);
        Navigator.pop(context);
      },
    );
  }

  void _showFormatEditor(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filename Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(hintText: '{artist} - {title}')),
            const SizedBox(height: 16),
            Text('Available placeholders:', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('{title}, {artist}, {album}, {track}, {year}, {disc}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setFilenameFormat(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDirectory(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      ref.read(settingsProvider.notifier).setDownloadDirectory(result);
    }
  }
}
