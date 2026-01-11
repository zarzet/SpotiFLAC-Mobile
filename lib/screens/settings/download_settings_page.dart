import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class DownloadSettingsPage extends ConsumerWidget {
  const DownloadSettingsPage({super.key});
  
  // Built-in services that support quality options
  static const _builtInServices = ['tidal', 'qobuz', 'amazon'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    
    // Check if current service is built-in (supports quality options)
    final isBuiltInService = _builtInServices.contains(settings.defaultService);

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
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = 120 + topPadding;
                  final minHeight = kToolbarHeight + topPadding;
                  final expandRatio =
                      ((constraints.maxHeight - minHeight) /
                              (maxHeight - minHeight))
                          .clamp(0.0, 1.0);
                  final leftPadding = 56 - (32 * expandRatio); // 56 -> 24
                  return FlexibleSpaceBar(
                    expandedTitleScale: 1.0,
                    titlePadding: EdgeInsets.only(
                      left: leftPadding,
                      bottom: 16,
                    ),
                    title: Text(
                      'Download',
                      style: TextStyle(
                        fontSize: 20 + (8 * expandRatio), // 20 -> 28
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Service section
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Service'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _ServiceSelector(
                    currentService: settings.defaultService,
                    onChanged: (service) => ref
                        .read(settingsProvider.notifier)
                        .setDefaultService(service),
                  ),
                ],
              ),
            ),

            // Quality section
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Audio Quality'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.tune,
                    title: 'Ask Before Download',
                    subtitle: isBuiltInService 
                        ? 'Choose quality for each download'
                        : 'Select a built-in service to enable',
                    value: settings.askQualityBeforeDownload,
                    // Not selected visually if extension is active
                    enabled: isBuiltInService,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setAskQualityBeforeDownload(value),
                  ),
                  if (!settings.askQualityBeforeDownload && isBuiltInService) ...[
                    _QualityOption(
                      title: 'FLAC Lossless',
                      subtitle: '16-bit / 44.1kHz',
                      isSelected: settings.audioQuality == 'LOSSLESS',
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAudioQuality('LOSSLESS'),
                    ),
                    _QualityOption(
                      title: 'Hi-Res FLAC',
                      subtitle: '24-bit / up to 96kHz',
                      isSelected: settings.audioQuality == 'HI_RES',
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAudioQuality('HI_RES'),
                    ),
                    _QualityOption(
                      title: 'Hi-Res FLAC Max',
                      subtitle: '24-bit / up to 192kHz',
                      isSelected: settings.audioQuality == 'HI_RES_LOSSLESS',
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAudioQuality('HI_RES_LOSSLESS'),
                      showDivider: false,
                    ),
                  ],
                  if (!isBuiltInService) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Select Tidal, Qobuz, or Amazon above to configure quality',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // File settings section
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'File Settings'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.text_fields,
                    title: 'Filename Format',
                    subtitle: settings.filenameFormat,
                    onTap: () => _showFormatEditor(
                      context,
                      ref,
                      settings.filenameFormat,
                    ),
                  ),
                  SettingsItem(
                    icon: Icons.folder_outlined,
                    title: 'Download Directory',
                    subtitle: settings.downloadDirectory.isEmpty
                        ? (Platform.isIOS
                              ? 'App Documents Folder'
                              : 'Music/SpotiFLAC')
                        : settings.downloadDirectory,
                    onTap: () => _pickDirectory(context, ref),
                  ),
                  SettingsItem(
                    icon: Icons.create_new_folder_outlined,
                    title: 'Folder Organization',
                    subtitle: _getFolderOrganizationLabel(
                      settings.folderOrganization,
                    ),
                    onTap: () => _showFolderOrganizationPicker(
                      context,
                      ref,
                      settings.folderOrganization,
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _showFormatEditor(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    final colorScheme = Theme.of(context).colorScheme;

    final tags = [
      '{artist}',
      '{title}',
      '{album}',
      '{track}',
      '{year}',
      '{disc}',
    ];

    void insertTag(String tag) {
      final text = controller.text;
      final selection = controller.selection;
      final start = selection.start >= 0 ? selection.start : text.length;
      final end = selection.end >= 0 ? selection.end : text.length;

      String insertion = tag;
      if (start > 0) {
        final before = text.substring(0, start);
        // Smart separator: if not starting a file and no hyphen separator exists, add " - "
        if (!before.trim().endsWith('-')) {
          insertion = ' - $tag';
        } else if (before.trim().endsWith('-') && !before.endsWith(' ')) {
          // If ends with '-' but no space, add space
          insertion = ' $tag';
        }
      }

      final newText = text.replaceRange(start, end, insertion);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + insertion.length),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Filename Format',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize how your files are named.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '{artist} - {title}',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Tap to insert tag:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return ActionChip(
                        label: Text(tag),
                        onPressed: () => insertTag(tag),
                        backgroundColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            ref
                                .read(settingsProvider.notifier)
                                .setFilenameFormat(controller.text);
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Save Format'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDirectory(BuildContext context, WidgetRef ref) async {
    if (Platform.isIOS) {
      // iOS: Show options dialog
      _showIOSDirectoryOptions(context, ref);
    } else {
      // Android: Use file picker
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        ref.read(settingsProvider.notifier).setDownloadDirectory(result);
      }
    }
  }

  void _showIOSDirectoryOptions(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Download Location',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'On iOS, downloads are saved to the app\'s Documents folder which is accessible via the Files app.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.folder_special, color: colorScheme.primary),
              title: const Text('App Documents Folder'),
              subtitle: const Text('Recommended - accessible via Files app'),
              trailing: Icon(Icons.check_circle, color: colorScheme.primary),
              onTap: () async {
                final dir = await getApplicationDocumentsDirectory();
                ref
                    .read(settingsProvider.notifier)
                    .setDownloadDirectory(dir.path);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud, color: colorScheme.onSurfaceVariant),
              title: const Text('Choose from Files'),
              subtitle: const Text('Select iCloud or other location'),
              onTap: () async {
                Navigator.pop(ctx);
                // Note: iOS requires folder to have at least one file to be selectable
                final result = await FilePicker.platform.getDirectoryPath();
                if (result != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .setDownloadDirectory(result);
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.tertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'iOS limitation: Empty folders cannot be selected. Create a file inside first or use App Documents.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getFolderOrganizationLabel(String value) {
    switch (value) {
      case 'artist':
        return 'By Artist';
      case 'album':
        return 'By Album';
      case 'artist_album':
        return 'By Artist & Album';
      default:
        return 'None';
    }
  }

  void _showFolderOrganizationPicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Folder Organization',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Organize downloaded files into folders',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _FolderOption(
              title: 'None',
              subtitle: 'All files in download folder',
              example: 'SpotiFLAC/Track.flac',
              isSelected: current == 'none',
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setFolderOrganization('none');
                Navigator.pop(context);
              },
            ),
            _FolderOption(
              title: 'By Artist',
              subtitle: 'Separate folder for each artist',
              example: 'SpotiFLAC/Artist Name/Track.flac',
              isSelected: current == 'artist',
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setFolderOrganization('artist');
                Navigator.pop(context);
              },
            ),
            _FolderOption(
              title: 'By Album',
              subtitle: 'Separate folder for each album',
              example: 'SpotiFLAC/Album Name/Track.flac',
              isSelected: current == 'album',
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setFolderOrganization('album');
                Navigator.pop(context);
              },
            ),
            _FolderOption(
              title: 'By Artist & Album',
              subtitle: 'Nested folders for artist and album',
              example: 'SpotiFLAC/Artist/Album/Track.flac',
              isSelected: current == 'artist_album',
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setFolderOrganization('artist_album');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ServiceSelector extends StatelessWidget {
  final String currentService;
  final ValueChanged<String> onChanged;
  const _ServiceSelector({
    required this.currentService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _ServiceChip(
            icon: Icons.music_note,
            label: 'Tidal',
            isSelected: currentService == 'tidal',
            onTap: () => onChanged('tidal'),
          ),
          const SizedBox(width: 8),
          _ServiceChip(
            icon: Icons.album,
            label: 'Qobuz',
            isSelected: currentService == 'qobuz',
            onTap: () => onChanged('qobuz'),
          ),
          const SizedBox(width: 8),
          _ServiceChip(
            icon: Icons.shopping_bag,
            label: 'Amazon',
            isSelected: currentService == 'amazon',
            onTap: () => onChanged('amazon'),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ServiceChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unselectedColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHigh;

    return Expanded(
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : unselectedColor,
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
    );
  }
}

class _QualityOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDivider;
  const _QualityOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                isSelected
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : Icon(Icons.circle_outlined, color: colorScheme.outline),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

class _FolderOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String example;
  final bool isSelected;
  final VoidCallback onTap;
  const _FolderOption({
    required this.title,
    required this.subtitle,
    required this.example,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 4),
          Text(
            example,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : Icon(Icons.circle_outlined, color: colorScheme.outline),
      onTap: onTap,
    );
  }
}
