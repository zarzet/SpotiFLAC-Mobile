import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class DownloadSettingsPage extends ConsumerStatefulWidget {
  const DownloadSettingsPage({super.key});

  @override
  ConsumerState<DownloadSettingsPage> createState() => _DownloadSettingsPageState();
}

class _DownloadSettingsPageState extends ConsumerState<DownloadSettingsPage> {
  static const _builtInServices = ['tidal', 'qobuz', 'amazon'];
  int _androidSdkVersion = 0;
  bool _hasAllFilesAccess = false;

  @override
  void initState() {
    super.initState();
    _initDeviceInfo();
  }

  Future<void> _initDeviceInfo() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;
      final hasAccess = await Permission.manageExternalStorage.isGranted;
      if (mounted) {
        setState(() {
          _androidSdkVersion = sdkVersion;
          _hasAllFilesAccess = hasAccess;
        });
      }
    }
  }

  Future<void> _requestAllFilesAccess() async {
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      ref.read(settingsProvider.notifier).setUseAllFilesAccess(true);
      if (mounted) {
        setState(() => _hasAllFilesAccess = true);
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.setupStorageAccessRequired),
            content: Text(context.l10n.allFilesAccessDeniedMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.dialogCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.setupOpenSettings),
              ),
            ],
          ),
        );
        if (shouldOpen == true) {
          await openAppSettings();
        }
      }
    }
  }

  Future<void> _disableAllFilesAccess() async {
    ref.read(settingsProvider.notifier).setUseAllFilesAccess(false);
    // Note: We can't revoke the permission programmatically,
    // but we can stop using it in the app
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.allFilesAccessDisabledMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    
    final isBuiltInService = _builtInServices.contains(settings.defaultService);
    final isTidalService = settings.defaultService == 'tidal';

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
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
                    context.l10n.downloadTitle,
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

            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionService),
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

            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionAudioQuality),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.tune,
                    title: context.l10n.downloadAskBeforeDownload,
                    subtitle: isBuiltInService 
                        ? context.l10n.downloadAskQualitySubtitle
                        : 'Select a built-in service to enable',
                    value: settings.askQualityBeforeDownload,
                    enabled: isBuiltInService,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setAskQualityBeforeDownload(value),
                  ),
                  SettingsSwitchItem(
                    icon: Icons.audiotrack,
                    title: context.l10n.enableLossyOption,
                    subtitle: settings.enableLossyOption
                        ? context.l10n.enableLossyOptionSubtitleOn
                        : context.l10n.enableLossyOptionSubtitleOff,
                    value: settings.enableLossyOption,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setEnableLossyOption(value),
                  ),
                  if (settings.enableLossyOption)
                    SettingsItem(
                      icon: Icons.tune,
                      title: context.l10n.lossyFormat,
                      subtitle: _getLossyBitrateLabel(settings.lossyBitrate),
                      onTap: () => _showLossyBitratePicker(context, ref, settings.lossyBitrate),
                    ),
                  if (!settings.askQualityBeforeDownload && isBuiltInService) ...[
                    _QualityOption(
                      title: context.l10n.qualityFlacLossless,
                      subtitle: context.l10n.qualityFlacLosslessSubtitle,
                      isSelected: settings.audioQuality == 'LOSSLESS',
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAudioQuality('LOSSLESS'),
                    ),
                    _QualityOption(
                      title: context.l10n.qualityHiResFlac,
                      subtitle: context.l10n.qualityHiResFlacSubtitle,
                      isSelected: settings.audioQuality == 'HI_RES',
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAudioQuality('HI_RES'),
                    ),
                    _QualityOption(
                      title: context.l10n.qualityHiResFlacMax,
                      subtitle: context.l10n.qualityHiResFlacMaxSubtitle,
                      isSelected: settings.audioQuality == 'HI_RES_LOSSLESS',
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAudioQuality('HI_RES_LOSSLESS'),
                      showDivider: isTidalService || settings.enableLossyOption,
                    ),
                    // Native AAC 320kbps option (Tidal only)
                    if (isTidalService)
                      _QualityOption(
                        title: 'AAC 320kbps',
                        subtitle: 'Native AAC (no conversion)',
                        isSelected: settings.audioQuality == 'HIGH',
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setAudioQuality('HIGH'),
                        showDivider: settings.enableLossyOption,
                      ),
                    if (settings.enableLossyOption)
                      _QualityOption(
                        title: context.l10n.qualityLossy,
                        subtitle: settings.lossyFormat == 'opus' 
                            ? context.l10n.qualityLossyOpusSubtitle
                            : context.l10n.qualityLossyMp3Subtitle,
                        isSelected: settings.audioQuality == 'LOSSY',
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setAudioQuality('LOSSY'),
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

          SliverToBoxAdapter(
            child: SettingsSectionHeader(title: context.l10n.sectionLyrics),
          ),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                SettingsItem(
                  icon: Icons.lyrics_outlined,
                  title: context.l10n.lyricsMode,
                  subtitle: _getLyricsModeLabel(context, settings.lyricsMode),
                  onTap: () => _showLyricsModePicker(
                    context,
                    ref,
                    settings.lyricsMode,
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: SettingsSectionHeader(title: context.l10n.sectionFileSettings),
          ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.text_fields,
                    title: context.l10n.downloadFilenameFormat,
                    subtitle: settings.filenameFormat,
                    onTap: () => _showFormatEditor(
                      context,
                      ref,
                      settings.filenameFormat,
                    ),
                  ),
                  SettingsItem(
                    icon: Icons.folder_outlined,
                    title: context.l10n.downloadDirectory,
                    subtitle: settings.downloadDirectory.isEmpty
                        ? (Platform.isIOS
                              ? context.l10n.setupAppDocumentsFolder
                              : 'Music/SpotiFLAC')
                        : settings.downloadDirectory,
                    onTap: () => _pickDirectory(context, ref),
                  ),
                  SettingsSwitchItem(
                    icon: Icons.library_music_outlined,
                    title: context.l10n.downloadSeparateSinglesFolder,
                    subtitle: settings.separateSingles
                        ? 'Albums/ and Singles/ folders'
                        : 'All files in same structure',
                    value: settings.separateSingles,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setSeparateSingles(value),
                  ),
                  if (settings.separateSingles)
                    SettingsItem(
                      icon: Icons.folder_outlined,
                      title: context.l10n.downloadAlbumFolderStructure,
                      subtitle: _getAlbumFolderStructureLabel(settings.albumFolderStructure),
                      onTap: () => _showAlbumFolderStructurePicker(
                        context,
                        ref,
                        settings.albumFolderStructure,
                      ),
                    ),
                  if (!settings.separateSingles)
                    SettingsItem(
                      icon: Icons.create_new_folder_outlined,
                      title: context.l10n.downloadFolderOrganization,
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

            // All Files Access section (Android 13+ only)
            if (Platform.isAndroid && _androidSdkVersion >= 33) ...[
              SliverToBoxAdapter(
                child: SettingsSectionHeader(title: context.l10n.sectionStorageAccess),
              ),
              SliverToBoxAdapter(
                child: SettingsGroup(
                  children: [
                    SettingsSwitchItem(
                      icon: Icons.folder_special_outlined,
                      title: context.l10n.allFilesAccess,
                      subtitle: _hasAllFilesAccess
                          ? context.l10n.allFilesAccessEnabledSubtitle
                          : context.l10n.allFilesAccessDisabledSubtitle,
                      value: _hasAllFilesAccess && settings.useAllFilesAccess,
                      onChanged: (value) {
                        if (value) {
                          _requestAllFilesAccess();
                        } else {
                          _disableAllFilesAccess();
                        }
                      },
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.allFilesAccessDescription,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _getAlbumFolderStructureLabel(String structure) {
    switch (structure) {
      case 'album_only':
        return 'Albums/Album Name/';
      case 'artist_year_album':
        return 'Albums/Artist/[Year] Album/';
      case 'year_album':
        return 'Albums/[Year] Album/';
      case 'artist_album_singles':
        return 'Artist/Album/ + Artist/Singles/';
      default:
        return 'Albums/Artist/Album Name/';
    }
  }

  void _showAlbumFolderStructurePicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(context.l10n.albumFolderArtistAlbum),
              subtitle: Text(context.l10n.albumFolderArtistAlbumSubtitle),
              trailing: current == 'artist_album' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setAlbumFolderStructure('artist_album');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(context.l10n.albumFolderArtistYearAlbum),
              subtitle: Text(context.l10n.albumFolderArtistYearAlbumSubtitle),
              trailing: current == 'artist_year_album' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setAlbumFolderStructure('artist_year_album');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.album_outlined),
              title: Text(context.l10n.albumFolderAlbumOnly),
              subtitle: Text(context.l10n.albumFolderAlbumOnlySubtitle),
              trailing: current == 'album_only' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setAlbumFolderStructure('album_only');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(context.l10n.albumFolderYearAlbum),
              subtitle: Text(context.l10n.albumFolderYearAlbumSubtitle),
              trailing: current == 'year_album' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setAlbumFolderStructure('year_album');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outlined),
              title: Text(context.l10n.albumFolderArtistAlbumSingles),
              subtitle: Text(context.l10n.albumFolderArtistAlbumSinglesSubtitle),
              trailing: current == 'artist_album_singles' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setAlbumFolderStructure('artist_album_singles');
                Navigator.pop(context);
              },
            ),
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
        if (!before.trim().endsWith('-')) {
          insertion = ' - $tag';
        } else if (before.trim().endsWith('-') && !before.endsWith(' ')) {
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
                    context.l10n.filenameFormat,
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
                          child: Text(context.l10n.dialogCancel),
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
                          child: Text(context.l10n.dialogSave),
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
      _showIOSDirectoryOptions(context, ref);
    } else {
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
                context.l10n.setupDownloadLocationTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.setupDownloadLocationIosMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.folder_special, color: colorScheme.primary),
              title: Text(context.l10n.setupAppDocumentsFolder),
              subtitle: Text(context.l10n.setupAppDocumentsFolderSubtitle),
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
              title: Text(context.l10n.setupChooseFromFiles),
              subtitle: Text(context.l10n.setupChooseFromFilesSubtitle),
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
                        context.l10n.setupIosEmptyFolderWarning,
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
        return 'Artist/Album';
      default:
        return 'None';
    }
  }

  String _getLyricsModeLabel(BuildContext context, String mode) {
    switch (mode) {
      case 'external':
        return context.l10n.lyricsModeExternal;
      case 'both':
        return context.l10n.lyricsModeBoth;
      default:
        return context.l10n.lyricsModeEmbed;
    }
  }

  void _showLyricsModePicker(
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
                context.l10n.lyricsMode,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.lyricsModeDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: Text(context.l10n.lyricsModeEmbed),
              subtitle: Text(context.l10n.lyricsModeEmbedSubtitle),
              trailing: current == 'embed' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLyricsMode('embed');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(context.l10n.lyricsModeExternal),
              subtitle: Text(context.l10n.lyricsModeExternalSubtitle),
              trailing: current == 'external' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLyricsMode('external');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_music_outlined),
              title: Text(context.l10n.lyricsModeBoth),
              subtitle: Text(context.l10n.lyricsModeBothSubtitle),
              trailing: current == 'both' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLyricsMode('both');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getLossyBitrateLabel(String bitrate) {
    switch (bitrate) {
      case 'mp3_320':
        return 'MP3 320kbps (Best)';
      case 'mp3_256':
        return 'MP3 256kbps';
      case 'mp3_192':
        return 'MP3 192kbps';
      case 'mp3_128':
        return 'MP3 128kbps';
      case 'opus_128':
        return 'Opus 128kbps (Best)';
      case 'opus_96':
        return 'Opus 96kbps';
      case 'opus_64':
        return 'Opus 64kbps';
      default:
        return 'MP3 320kbps';
    }
  }

  void _showLossyBitratePicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  context.l10n.lossyFormat,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  context.l10n.lossyFormatDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              // MP3 Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Text(
                  'MP3',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack),
                title: const Text('320kbps'),
                subtitle: const Text('Best quality, larger files'),
                trailing: current == 'mp3_320' ? Icon(Icons.check, color: colorScheme.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLossyBitrate('mp3_320');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack),
                title: const Text('256kbps'),
                subtitle: const Text('High quality'),
                trailing: current == 'mp3_256' ? Icon(Icons.check, color: colorScheme.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLossyBitrate('mp3_256');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack),
                title: const Text('192kbps'),
                subtitle: const Text('Good quality'),
                trailing: current == 'mp3_192' ? Icon(Icons.check, color: colorScheme.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLossyBitrate('mp3_192');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack),
                title: const Text('128kbps'),
                subtitle: const Text('Smaller files'),
                trailing: current == 'mp3_128' ? Icon(Icons.check, color: colorScheme.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLossyBitrate('mp3_128');
                  Navigator.pop(context);
                },
              ),
              const Divider(indent: 24, endIndent: 24),
              // Opus Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Text(
                  'Opus',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.graphic_eq),
                title: const Text('128kbps'),
                subtitle: const Text('Best quality, efficient codec'),
                trailing: current == 'opus_128' ? Icon(Icons.check, color: colorScheme.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLossyBitrate('opus_128');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.graphic_eq),
                title: const Text('96kbps'),
                subtitle: const Text('Good quality'),
                trailing: current == 'opus_96' ? Icon(Icons.check, color: colorScheme.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLossyBitrate('opus_96');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.graphic_eq),
                title: const Text('64kbps'),
                subtitle: const Text('Smallest files'),
                trailing: current == 'opus_64' ? Icon(Icons.check, color: colorScheme.primary) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLossyBitrate('opus_64');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
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
                  context.l10n.folderOrganizationDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _FolderOption(
                title: context.l10n.folderOrganizationNone,
                subtitle: context.l10n.folderOrganizationNoneSubtitle,
                example: 'SpotiFLAC/Track.flac',
                isSelected: current == 'none',
                onTap: () {
                  ref.read(settingsProvider.notifier).setFolderOrganization('none');
                  Navigator.pop(context);
                },
              ),
              _FolderOption(
                title: context.l10n.folderOrganizationByArtist,
                subtitle: context.l10n.folderOrganizationByArtistSubtitle,
                example: 'SpotiFLAC/Artist Name/Track.flac',
                isSelected: current == 'artist',
                onTap: () {
                  ref.read(settingsProvider.notifier).setFolderOrganization('artist');
                  Navigator.pop(context);
                },
              ),
              _FolderOption(
                title: context.l10n.folderOrganizationByAlbum,
                subtitle: context.l10n.folderOrganizationByAlbumSubtitle,
                example: 'SpotiFLAC/Album Name/Track.flac',
                isSelected: current == 'album',
                onTap: () {
                  ref.read(settingsProvider.notifier).setFolderOrganization('album');
                  Navigator.pop(context);
                },
              ),
              _FolderOption(
                title: context.l10n.folderOrganizationByArtistAlbum,
                subtitle: context.l10n.folderOrganizationByArtistAlbumSubtitle,
                example: 'SpotiFLAC/Artist/Album/Track.flac',
                isSelected: current == 'artist_album',
                onTap: () {
                  ref.read(settingsProvider.notifier).setFolderOrganization('artist_album');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceSelector extends ConsumerWidget {
  final String currentService;
  final ValueChanged<String> onChanged;
  const _ServiceSelector({
    required this.currentService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extState = ref.watch(extensionProvider);
    
    final extensionProviders = extState.extensions
        .where((e) => e.enabled && e.hasDownloadProvider)
        .toList();
    
    final isExtensionService = !['tidal', 'qobuz', 'amazon'].contains(currentService);
    final isCurrentExtensionEnabled = isExtensionService 
        ? extensionProviders.any((e) => e.id == currentService)
        : true;
    
    final effectiveService = isCurrentExtensionEnabled ? currentService : '';
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              _ServiceChip(
                icon: Icons.music_note,
                label: 'Tidal',
                isSelected: effectiveService == 'tidal',
                onTap: () => onChanged('tidal'),
              ),
              const SizedBox(width: 8),
              _ServiceChip(
                icon: Icons.album,
                label: 'Qobuz',
                isSelected: effectiveService == 'qobuz',
                onTap: () => onChanged('qobuz'),
              ),
              const SizedBox(width: 8),
              _ServiceChip(
                icon: Icons.shopping_bag,
                label: 'Amazon',
                isSelected: effectiveService == 'amazon',
                onTap: () => onChanged('amazon'),
              ),
            ],
          ),
          if (extensionProviders.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 0; i < extensionProviders.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _ServiceChip(
                      icon: Icons.extension,
                      label: extensionProviders[i].displayName,
                      isSelected: effectiveService == extensionProviders[i].id,
                      onTap: () => onChanged(extensionProviders[i].id),
                    ),
                  ),
                ],
                for (int i = extensionProviders.length; i < 3; i++) ...[
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ],
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
