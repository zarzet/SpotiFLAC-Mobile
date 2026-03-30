import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class LibrarySettingsPage extends ConsumerStatefulWidget {
  const LibrarySettingsPage({super.key});

  @override
  ConsumerState<LibrarySettingsPage> createState() =>
      _LibrarySettingsPageState();
}

class _LibrarySettingsPageState extends ConsumerState<LibrarySettingsPage> {
  int _androidSdkVersion = 0;
  bool _hasStoragePermission = false;

  String _getDisplayPath(String path) {
    if (!path.startsWith('content://')) return path;
    try {
      final uri = Uri.parse(path);
      final treePath = uri.pathSegments.last;
      final decoded = Uri.decodeComponent(treePath);
      if (decoded.startsWith('primary:')) {
        return '/storage/emulated/0/${decoded.substring('primary:'.length)}';
      }
      return decoded;
    } catch (_) {
      return path;
    }
  }

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

      if (mounted) {
        setState(() {
          _androidSdkVersion = sdkVersion;
          // SAF doesn't need storage permission on Android 10+
          _hasStoragePermission = sdkVersion >= 29 ? true : false;
        });
        // For older Android, check legacy storage permission
        if (sdkVersion < 29) {
          final hasPermission = await Permission.storage.isGranted;
          if (mounted) {
            setState(() => _hasStoragePermission = hasPermission);
          }
        }
      }
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit storage permission for app documents
      setState(() => _hasStoragePermission = true);
    } else {
      setState(() => _hasStoragePermission = true);
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    // SAF on Android 10+ doesn't need MANAGE_EXTERNAL_STORAGE
    if (_androidSdkVersion >= 29) return true;

    final status = await Permission.storage.request();

    if (status.isGranted) {
      setState(() => _hasStoragePermission = true);
      return true;
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.libraryStorageAccessRequired),
            content: Text(context.l10n.libraryStorageAccessMessage),
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
    return false;
  }

  Future<void> _pickLibraryFolder() async {
    if (Platform.isAndroid && _androidSdkVersion >= 29) {
      // Use SAF tree picker - no MANAGE_EXTERNAL_STORAGE needed
      final result = await PlatformBridge.pickSafTree();
      if (result != null) {
        final treeUri = result['tree_uri'] as String? ?? '';
        if (treeUri.isNotEmpty) {
          ref.read(settingsProvider.notifier).setLocalLibraryPath(treeUri);
        }
      }
    } else {
      // Legacy: request permission and use file picker for older Android / iOS
      if (!_hasStoragePermission) {
        final granted = await _requestStoragePermission();
        if (!granted) return;
      }
      // Fallback for older devices
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        if (Platform.isIOS) {
          // On iOS, create a security-scoped bookmark so we can access
          // this folder across app restarts and from the Go backend.
          final bookmark = await PlatformBridge.createIosBookmarkFromPath(
            result,
          );
          if (bookmark != null && bookmark.isNotEmpty) {
            ref
                .read(settingsProvider.notifier)
                .setLocalLibraryPathAndBookmark(result, bookmark);
          } else {
            // Bookmark creation failed; save path anyway (works for
            // app-internal folders like Documents/).
            ref.read(settingsProvider.notifier).setLocalLibraryPath(result);
          }
        } else {
          ref.read(settingsProvider.notifier).setLocalLibraryPath(result);
        }
      }
    }
  }

  Future<void> _startScan({bool forceFullScan = false}) async {
    final settings = ref.read(settingsProvider);
    final libraryPath = settings.localLibraryPath;
    final iosBookmark = settings.localLibraryBookmark;

    if (libraryPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.libraryScanSelectFolderFirst)),
      );
      return;
    }

    // On iOS with a bookmark, try resolving the bookmark first to validate
    // access instead of checking the path directly (which may fail outside
    // the app sandbox).
    if (Platform.isIOS && iosBookmark.isNotEmpty) {
      // Bookmark will be resolved inside startScan; skip Directory.exists
      // check since security-scoped paths are not accessible without the
      // bookmark being activated.
    } else if (!libraryPath.startsWith('content://') &&
        !await Directory(libraryPath).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.libraryFolderNotExist)),
        );
      }
      return;
    }

    await ref
        .read(localLibraryProvider.notifier)
        .startScan(
          libraryPath,
          forceFullScan: forceFullScan,
          iosBookmark: iosBookmark.isNotEmpty ? iosBookmark : null,
        );
  }

  Future<void> _cancelScan() async {
    await ref.read(localLibraryProvider.notifier).cancelScan();
  }

  Future<void> _clearLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.libraryClearConfirmTitle),
        content: Text(context.l10n.libraryClearConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.dialogClear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(localLibraryProvider.notifier).clearLibrary();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.libraryCleared)));
      }
    }
  }

  Future<void> _cleanupMissingFiles() async {
    final iosBookmark = ref.read(settingsProvider).localLibraryBookmark;
    final removed = await ref
        .read(localLibraryProvider.notifier)
        .cleanupMissingFiles(
          iosBookmark: iosBookmark.isNotEmpty ? iosBookmark : null,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.libraryRemovedMissingFiles(removed)),
        ),
      );
    }
  }

  String _getAutoScanLabel(BuildContext context, String mode) {
    switch (mode) {
      case 'on_open':
        return context.l10n.libraryAutoScanOnOpen;
      case 'daily':
        return context.l10n.libraryAutoScanDaily;
      case 'weekly':
        return context.l10n.libraryAutoScanWeekly;
      default:
        return context.l10n.libraryAutoScanOff;
    }
  }

  void _showAutoScanPicker(BuildContext context, String current) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
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
                context.l10n.libraryAutoScan,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.libraryAutoScanSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _AutoScanOption(
              icon: Icons.block,
              title: context.l10n.libraryAutoScanOff,
              selected: current == 'off',
              colorScheme: colorScheme,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocalLibraryAutoScan('off');
                Navigator.pop(context);
              },
            ),
            _AutoScanOption(
              icon: Icons.open_in_new,
              title: context.l10n.libraryAutoScanOnOpen,
              selected: current == 'on_open',
              colorScheme: colorScheme,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocalLibraryAutoScan('on_open');
                Navigator.pop(context);
              },
            ),
            _AutoScanOption(
              icon: Icons.today,
              title: context.l10n.libraryAutoScanDaily,
              selected: current == 'daily',
              colorScheme: colorScheme,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocalLibraryAutoScan('daily');
                Navigator.pop(context);
              },
            ),
            _AutoScanOption(
              icon: Icons.date_range,
              title: context.l10n.libraryAutoScanWeekly,
              selected: current == 'weekly',
              colorScheme: colorScheme,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocalLibraryAutoScan('weekly');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final libraryState = ref.watch(localLibraryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);

    return Scaffold(
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
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                final leftPadding = 56 - (32 * expandRatio);
                return FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  titlePadding: EdgeInsets.only(left: leftPadding, bottom: 16),
                  title: Text(
                    context.l10n.libraryTitle,
                    style: TextStyle(
                      fontSize: 20 + (8 * expandRatio),
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: _LibraryHeroCard(
              itemCount: libraryState.items.length,
              excludedDownloadedCount: libraryState.excludedDownloadedCount,
              isScanning: libraryState.isScanning,
              scanIsFinalizing: libraryState.scanIsFinalizing,
              scanProgress: libraryState.scanProgress,
              scanCurrentFile: libraryState.scanCurrentFile,
              scanTotalFiles: libraryState.scanTotalFiles,
              scannedFiles: libraryState.scannedFiles,
              lastScannedAt: libraryState.lastScannedAt,
            ),
          ),

          SliverToBoxAdapter(
            child: SettingsSectionHeader(
              title: context.l10n.libraryScanSettings,
            ),
          ),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                SettingsSwitchItem(
                  icon: Icons.library_music_outlined,
                  title: context.l10n.libraryEnableLocalLibrary,
                  subtitle: settings.localLibraryEnabled
                      ? context.l10n.libraryEnableLocalLibrarySubtitle
                      : context.l10n.extensionsDisabled,
                  value: settings.localLibraryEnabled,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setLocalLibraryEnabled(value),
                ),
                Opacity(
                  opacity: settings.localLibraryEnabled ? 1.0 : 0.5,
                  child: SettingsItem(
                    icon: Icons.folder_outlined,
                    title: context.l10n.libraryFolder,
                    subtitle: settings.localLibraryPath.isEmpty
                        ? context.l10n.libraryFolderHint
                        : _getDisplayPath(settings.localLibraryPath),
                    onTap: settings.localLibraryEnabled
                        ? _pickLibraryFolder
                        : null,
                  ),
                ),
                SettingsSwitchItem(
                  icon: Icons.content_copy_outlined,
                  title: context.l10n.libraryShowDuplicateIndicator,
                  subtitle: settings.localLibraryShowDuplicates
                      ? context.l10n.libraryShowDuplicateIndicatorSubtitle
                      : context.l10n.extensionsDisabled,
                  value: settings.localLibraryShowDuplicates,
                  enabled: settings.localLibraryEnabled,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setLocalLibraryShowDuplicates(value),
                ),
                Opacity(
                  opacity: settings.localLibraryEnabled ? 1.0 : 0.5,
                  child: SettingsItem(
                    icon: Icons.autorenew_rounded,
                    title: context.l10n.libraryAutoScan,
                    subtitle: _getAutoScanLabel(
                      context,
                      settings.localLibraryAutoScan,
                    ),
                    onTap: settings.localLibraryEnabled
                        ? () => _showAutoScanPicker(
                            context,
                            settings.localLibraryAutoScan,
                          )
                        : null,
                    showDivider: false,
                  ),
                ),
              ],
            ),
          ),

          // Scan Actions Section
          if (settings.localLibraryEnabled) ...[
            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.libraryActions),
            ),
            if (libraryState.scanWasCancelled)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan cancelled',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You can retry the scan when ready.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onTertiaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _startScan,
                          child: Text(context.l10n.dialogRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  if (libraryState.isScanning)
                    _ScanProgressTile(
                      isFinalizing: libraryState.scanIsFinalizing,
                      progress: libraryState.scanProgress,
                      currentFile: libraryState.scanCurrentFile,
                      scannedFiles: libraryState.scannedFiles,
                      totalFiles: libraryState.scanTotalFiles,
                      onCancel: _cancelScan,
                    )
                  else ...[
                    Opacity(
                      opacity: settings.localLibraryPath.isNotEmpty ? 1.0 : 0.5,
                      child: SettingsItem(
                        icon: Icons.refresh,
                        title: context.l10n.libraryScan,
                        subtitle: settings.localLibraryPath.isEmpty
                            ? context.l10n.libraryScanSelectFolderFirst
                            : context.l10n.libraryScanSubtitle,
                        onTap: settings.localLibraryPath.isNotEmpty
                            ? _startScan
                            : null,
                      ),
                    ),
                    Opacity(
                      opacity: settings.localLibraryPath.isNotEmpty ? 1.0 : 0.5,
                      child: SettingsItem(
                        icon: Icons.sync,
                        title: context.l10n.libraryForceFullScan,
                        subtitle: context.l10n.libraryForceFullScanSubtitle,
                        onTap: settings.localLibraryPath.isNotEmpty
                            ? () => _startScan(forceFullScan: true)
                            : null,
                      ),
                    ),
                  ],
                  Opacity(
                    opacity: libraryState.items.isNotEmpty ? 1.0 : 0.5,
                    child: SettingsItem(
                      icon: Icons.cleaning_services_outlined,
                      title: context.l10n.libraryCleanupMissingFiles,
                      subtitle: context.l10n.libraryCleanupMissingFilesSubtitle,
                      onTap: libraryState.items.isNotEmpty
                          ? _cleanupMissingFiles
                          : null,
                    ),
                  ),
                  Opacity(
                    opacity: libraryState.items.isNotEmpty ? 1.0 : 0.5,
                    child: SettingsItem(
                      icon: Icons.delete_outline,
                      title: context.l10n.libraryClear,
                      subtitle: context.l10n.libraryClearSubtitle,
                      onTap: libraryState.items.isNotEmpty
                          ? _clearLibrary
                          : null,
                      showDivider: false,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.libraryAbout,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.libraryAboutDescription,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _LibraryHeroCard extends StatelessWidget {
  final int itemCount;
  final int excludedDownloadedCount;
  final bool isScanning;
  final bool scanIsFinalizing;
  final double scanProgress;
  final String? scanCurrentFile;
  final int scanTotalFiles;
  final int scannedFiles;
  final DateTime? lastScannedAt;

  const _LibraryHeroCard({
    required this.itemCount,
    required this.excludedDownloadedCount,
    required this.isScanning,
    required this.scanIsFinalizing,
    required this.scanProgress,
    this.scanCurrentFile,
    required this.scanTotalFiles,
    required this.scannedFiles,
    this.lastScannedAt,
  });

  String _formatLastScanned(BuildContext context) {
    if (lastScannedAt == null) return context.l10n.libraryLastScannedNever;
    final now = DateTime.now();
    final diff = now.difference(lastScannedAt!);

    if (diff.inMinutes < 1) return context.l10n.timeJustNow;
    if (diff.inHours < 1) return context.l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return context.l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return context.l10n.dateDaysAgo(diff.inDays);

    return '${lastScannedAt!.day}/${lastScannedAt!.month}/${lastScannedAt!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showIndeterminateProgress =
        isScanning &&
        (scanIsFinalizing ||
            scanTotalFiles <= 0 ||
            (scannedFiles <= 0 && scanProgress <= 0));
    final displayCount = isScanning
        ? scannedFiles
        : itemCount + excludedDownloadedCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.library_music,
              size: 200,
              color: colorScheme.primary.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isScanning ? Icons.sync : Icons.music_note,
                        color: colorScheme.onPrimaryContainer,
                        size: 32,
                      ),
                    ),
                    const Spacer(),
                    if (isScanning)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Scanning...',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayCount.toString(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isScanning
                      ? context.l10n.libraryFilesUnit(scannedFiles)
                      : context.l10n.libraryTracksUnit(displayCount),
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isScanning && excludedDownloadedCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$excludedDownloadedCount from Downloads history '
                    '(excluded from list)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
                if (isScanning) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: showIndeterminateProgress
                        ? null
                        : scanProgress / 100,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scanIsFinalizing
                        ? context.l10n.libraryScanFinalizing
                        : scanTotalFiles > 0
                        ? context.l10n.libraryScanProgress(
                            scanProgress.toStringAsFixed(0),
                            scanTotalFiles,
                          )
                        : context.l10n.libraryScanning,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  if (!scanIsFinalizing &&
                      scanCurrentFile != null &&
                      scanCurrentFile!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      scanCurrentFile!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.libraryLastScanned(
                          _formatLastScanned(context),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanProgressTile extends StatelessWidget {
  final bool isFinalizing;
  final double progress;
  final String? currentFile;
  final int scannedFiles;
  final int totalFiles;
  final VoidCallback onCancel;

  const _ScanProgressTile({
    required this.isFinalizing,
    required this.progress,
    this.currentFile,
    required this.scannedFiles,
    required this.totalFiles,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showIndeterminateProgress =
        isFinalizing || totalFiles <= 0 || (scannedFiles <= 0 && progress <= 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.scanner, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.libraryScanning,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isFinalizing
                          ? context.l10n.libraryScanFinalizing
                          : totalFiles > 0
                          ? context.l10n.libraryScanProgress(
                              progress.toStringAsFixed(0),
                              totalFiles,
                            )
                          : context.l10n.libraryScanning,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onCancel,
                child: Text(context.l10n.actionCancel),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: showIndeterminateProgress ? null : progress / 100,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          if (!isFinalizing &&
              currentFile != null &&
              currentFile!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              currentFile!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoScanOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _AutoScanOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selected ? Icon(Icons.check, color: colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
