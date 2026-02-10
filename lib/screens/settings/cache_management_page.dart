import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class CacheManagementPage extends ConsumerStatefulWidget {
  const CacheManagementPage({super.key});

  @override
  ConsumerState<CacheManagementPage> createState() =>
      _CacheManagementPageState();
}

class _CacheManagementPageState extends ConsumerState<CacheManagementPage> {
  // Keep in sync with ExploreNotifier keys.
  static const String _exploreCacheKey = 'explore_home_feed_cache';
  static const String _exploreCacheTsKey = 'explore_home_feed_ts';

  _CacheOverview? _overview;
  bool _isLoading = true;
  String? _busyAction;

  @override
  void initState() {
    super.initState();
    _refreshOverview();
  }

  bool get _isBusy => _busyAction != null;

  Future<void> _refreshOverview() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final overview = await _buildOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<_CacheOverview> _buildOverview() async {
    final appCacheDirFuture = getApplicationCacheDirectory();
    final tempDirFuture = getTemporaryDirectory();
    final appSupportDirFuture = getApplicationSupportDirectory();
    final coverStatsFuture = CoverCacheManager.getStats();
    final prefsFuture = SharedPreferences.getInstance();
    final trackCacheEntriesFuture = _getTrackCacheSizeSafe();

    final appCacheDir = await appCacheDirFuture;
    final tempDir = await tempDirFuture;
    final appCachePath = p.normalize(appCacheDir.path);
    final tempPath = p.normalize(tempDir.path);
    final tempIsSameAsAppCache = appCachePath == tempPath;

    final appCacheStatsFuture = _scanDirectory(Directory(appCachePath));
    final tempStatsFuture = tempIsSameAsAppCache
        ? Future<_DirectoryStats?>.value(null)
        : _scanDirectory(Directory(tempPath));

    final appSupportDir = await appSupportDirFuture;
    final libraryCoverStatsFuture = _scanDirectory(
      Directory('${appSupportDir.path}/library_covers'),
    );

    final prefs = await prefsFuture;
    final explorePayload = prefs.getString(_exploreCacheKey);
    final exploreTs = prefs.getInt(_exploreCacheTsKey);
    var exploreBytes = 0;
    if (explorePayload != null && explorePayload.isNotEmpty) {
      exploreBytes += utf8.encode(explorePayload).length;
    }
    if (exploreTs != null) {
      exploreBytes += 8;
    }
    final hasExploreCache = exploreBytes > 0;

    final appCacheStats = await appCacheStatsFuture;
    final tempStats = await tempStatsFuture;
    final coverStats = await coverStatsFuture;
    final libraryCoverStats = await libraryCoverStatsFuture;
    final trackCacheEntries = await trackCacheEntriesFuture;

    return _CacheOverview(
      appCachePath: appCachePath,
      appCacheStats: appCacheStats,
      tempPath: tempIsSameAsAppCache ? null : tempPath,
      tempStats: tempStats,
      tempIsSameAsAppCache: tempIsSameAsAppCache,
      coverStats: coverStats,
      libraryCoverStats: libraryCoverStats,
      exploreCacheBytes: exploreBytes,
      hasExploreCache: hasExploreCache,
      trackCacheEntries: trackCacheEntries,
    );
  }

  Future<_DirectoryStats> _scanDirectory(Directory directory) async {
    if (!await directory.exists()) {
      return const _DirectoryStats(fileCount: 0, totalSizeBytes: 0);
    }

    var fileCount = 0;
    var totalSize = 0;

    try {
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          fileCount++;
          totalSize += await entity.length();
        }
      }
    } catch (_) {}

    return _DirectoryStats(fileCount: fileCount, totalSizeBytes: totalSize);
  }

  Future<int> _getTrackCacheSizeSafe() async {
    try {
      return await PlatformBridge.getTrackCacheSize();
    } catch (_) {
      return 0;
    }
  }

  Future<void> _clearDirectoryContents(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) return;

    try {
      final entities = <FileSystemEntity>[];
      await for (final entity in directory.list(followLinks: false)) {
        entities.add(entity);
      }

      const deleteChunkSize = 24;
      for (var i = 0; i < entities.length; i += deleteChunkSize) {
        final end = (i + deleteChunkSize < entities.length)
            ? i + deleteChunkSize
            : entities.length;
        final chunk = entities.sublist(i, end);
        await Future.wait(
          chunk.map((entity) async {
            try {
              await entity.delete(recursive: true);
            } catch (_) {}
          }),
        );
      }
    } catch (_) {}

    try {
      await directory.create(recursive: true);
    } catch (_) {}
  }

  Future<void> _clearAppCache() async {
    final cacheDir = await getApplicationCacheDirectory();
    await _clearDirectoryContents(cacheDir.path);
  }

  Future<void> _clearTempCache() async {
    final tempDir = await getTemporaryDirectory();
    await _clearDirectoryContents(tempDir.path);
  }

  Future<void> _clearCoverCache() async {
    await CoverCacheManager.clearCache();
  }

  Future<void> _clearLibraryCoverCache() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final libraryCoverDir = Directory('${appSupportDir.path}/library_covers');
    await _clearDirectoryContents(libraryCoverDir.path);
  }

  Future<void> _clearExploreCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_exploreCacheKey);
    await prefs.remove(_exploreCacheTsKey);
  }

  Future<void> _clearTrackCache() async {
    await PlatformBridge.clearTrackCache();
  }

  Future<void> _clearAllCaches() async {
    final currentOverview = _overview;
    await _clearAppCache();
    if (currentOverview != null && !currentOverview.tempIsSameAsAppCache) {
      await _clearTempCache();
    }
    await _clearCoverCache();
    await _clearLibraryCoverCache();
    await _clearExploreCache();
    await _clearTrackCache();
  }

  Future<bool> _confirmClear(String target) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cacheClearConfirmTitle),
        content: Text(context.l10n.cacheClearConfirmMessage(target)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.dialogClear),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<bool> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cacheClearAllConfirmTitle),
        content: Text(context.l10n.cacheClearAllConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.dialogClear),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _runAction(
    String actionKey,
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    if (_isBusy || !mounted) return;
    setState(() => _busyAction = actionKey);

    try {
      await action();
      if (!mounted) return;
      if (successMessage != null && successMessage.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
        await _refreshOverview();
      }
    }
  }

  Future<void> _confirmAndRunAction({
    required String actionKey,
    required String targetLabel,
    required Future<void> Function() action,
  }) async {
    final confirmed = await _confirmClear(targetLabel);
    if (!confirmed) return;

    if (!mounted) return;
    await _runAction(
      actionKey,
      action,
      successMessage: context.l10n.cacheClearSuccess(targetLabel),
    );
  }

  Future<void> _cleanupUnusedData() async {
    await _runAction('cleanup_unused', () async {
      final orphanedDownloads = await ref
          .read(downloadHistoryProvider.notifier)
          .cleanupOrphanedDownloads();
      final missingLibraryEntries = await ref
          .read(localLibraryProvider.notifier)
          .cleanupMissingFiles();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.cacheCleanupResult(
              orphanedDownloads,
              missingLibraryEntries,
            ),
          ),
        ),
      );
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDirectorySize(_DirectoryStats stats) {
    if (stats.fileCount == 0 || stats.totalSizeBytes == 0) {
      return context.l10n.cacheNoData;
    }
    return context.l10n.cacheSizeWithFiles(
      _formatBytes(stats.totalSizeBytes),
      stats.fileCount,
    );
  }

  String _buildSubtitle(String description, String sizeInfo) {
    return '$description\n$sizeInfo';
  }

  Widget _buildClearTrailing(String actionKey, VoidCallback onPressed) {
    if (_busyAction == actionKey) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return TextButton(
      onPressed: _isBusy ? null : onPressed,
      child: Text(context.l10n.dialogClear),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);
    final overview = _overview;

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
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                onPressed: _isBusy ? null : _refreshOverview,
                icon: const Icon(Icons.refresh),
              ),
            ],
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
                    context.l10n.cacheTitle,
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

          if (_isLoading || overview == null)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.cacheSummaryTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.cacheEstimatedTotal(
                        _formatBytes(overview.totalKnownDiskCacheBytes),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.cacheSummarySubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _isBusy
                              ? null
                              : () async {
                                  final l10n = context.l10n;
                                  final confirmed = await _confirmClearAll();
                                  if (!confirmed) return;
                                  if (!mounted) return;
                                  await _runAction(
                                    'clear_all',
                                    _clearAllCaches,
                                    successMessage: l10n.cacheClearSuccess(
                                      l10n.cacheClearAll,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: Text(context.l10n.cacheClearAll),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isBusy ? null : _refreshOverview,
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.cacheRefreshStats),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.cacheSectionStorage,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.folder_outlined,
                    title: context.l10n.cacheAppDirectory,
                    subtitle: _buildSubtitle(
                      context.l10n.cacheAppDirectoryDesc,
                      _formatDirectorySize(overview.appCacheStats),
                    ),
                    trailing: _buildClearTrailing(
                      'clear_app_cache',
                      () => _confirmAndRunAction(
                        actionKey: 'clear_app_cache',
                        targetLabel: context.l10n.cacheAppDirectory,
                        action: _clearAppCache,
                      ),
                    ),
                  ),
                  if (!overview.tempIsSameAsAppCache &&
                      overview.tempStats != null)
                    SettingsItem(
                      icon: Icons.timer_outlined,
                      title: context.l10n.cacheTempDirectory,
                      subtitle: _buildSubtitle(
                        context.l10n.cacheTempDirectoryDesc,
                        _formatDirectorySize(overview.tempStats!),
                      ),
                      trailing: _buildClearTrailing(
                        'clear_temp_cache',
                        () => _confirmAndRunAction(
                          actionKey: 'clear_temp_cache',
                          targetLabel: context.l10n.cacheTempDirectory,
                          action: _clearTempCache,
                        ),
                      ),
                    ),
                  SettingsItem(
                    icon: Icons.image_outlined,
                    title: context.l10n.cacheCoverImage,
                    subtitle: _buildSubtitle(
                      context.l10n.cacheCoverImageDesc,
                      overview.coverStats.fileCount > 0 &&
                              overview.coverStats.totalSizeBytes > 0
                          ? context.l10n.cacheSizeWithFiles(
                              _formatBytes(overview.coverStats.totalSizeBytes),
                              overview.coverStats.fileCount,
                            )
                          : context.l10n.cacheNoData,
                    ),
                    trailing: _buildClearTrailing(
                      'clear_cover_cache',
                      () => _confirmAndRunAction(
                        actionKey: 'clear_cover_cache',
                        targetLabel: context.l10n.cacheCoverImage,
                        action: _clearCoverCache,
                      ),
                    ),
                  ),
                  SettingsItem(
                    icon: Icons.library_music_outlined,
                    title: context.l10n.cacheLibraryCover,
                    subtitle: _buildSubtitle(
                      context.l10n.cacheLibraryCoverDesc,
                      overview.libraryCoverStats.fileCount > 0 &&
                              overview.libraryCoverStats.totalSizeBytes > 0
                          ? context.l10n.cacheSizeWithFiles(
                              _formatBytes(
                                overview.libraryCoverStats.totalSizeBytes,
                              ),
                              overview.libraryCoverStats.fileCount,
                            )
                          : context.l10n.cacheNoData,
                    ),
                    trailing: _buildClearTrailing(
                      'clear_library_cover_cache',
                      () => _confirmAndRunAction(
                        actionKey: 'clear_library_cover_cache',
                        targetLabel: context.l10n.cacheLibraryCover,
                        action: _clearLibraryCoverCache,
                      ),
                    ),
                  ),
                  SettingsItem(
                    icon: Icons.explore_outlined,
                    title: context.l10n.cacheExploreFeed,
                    subtitle: _buildSubtitle(
                      context.l10n.cacheExploreFeedDesc,
                      overview.hasExploreCache
                          ? context.l10n.cacheSizeOnly(
                              _formatBytes(overview.exploreCacheBytes),
                            )
                          : context.l10n.cacheNoData,
                    ),
                    trailing: _buildClearTrailing(
                      'clear_explore_cache',
                      () => _confirmAndRunAction(
                        actionKey: 'clear_explore_cache',
                        targetLabel: context.l10n.cacheExploreFeed,
                        action: _clearExploreCache,
                      ),
                    ),
                  ),
                  SettingsItem(
                    icon: Icons.memory_outlined,
                    title: context.l10n.cacheTrackLookup,
                    subtitle: _buildSubtitle(
                      context.l10n.cacheTrackLookupDesc,
                      overview.trackCacheEntries > 0
                          ? context.l10n.cacheEntries(
                              overview.trackCacheEntries,
                            )
                          : context.l10n.cacheNoData,
                    ),
                    trailing: _buildClearTrailing(
                      'clear_track_cache',
                      () => _confirmAndRunAction(
                        actionKey: 'clear_track_cache',
                        targetLabel: context.l10n.cacheTrackLookup,
                        action: _clearTrackCache,
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.cacheSectionMaintenance,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.cleaning_services_outlined,
                    title: context.l10n.cacheCleanupUnused,
                    subtitle:
                        '${context.l10n.cacheCleanupUnusedDesc}\n${context.l10n.cacheCleanupUnusedSubtitle}',
                    trailing: _buildClearTrailing(
                      'cleanup_unused',
                      _cleanupUnusedData,
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }
}

class _CacheOverview {
  final String appCachePath;
  final _DirectoryStats appCacheStats;
  final String? tempPath;
  final _DirectoryStats? tempStats;
  final bool tempIsSameAsAppCache;
  final CacheStats coverStats;
  final _DirectoryStats libraryCoverStats;
  final int exploreCacheBytes;
  final bool hasExploreCache;
  final int trackCacheEntries;

  const _CacheOverview({
    required this.appCachePath,
    required this.appCacheStats,
    this.tempPath,
    this.tempStats,
    required this.tempIsSameAsAppCache,
    required this.coverStats,
    required this.libraryCoverStats,
    required this.exploreCacheBytes,
    required this.hasExploreCache,
    required this.trackCacheEntries,
  });

  int get totalKnownDiskCacheBytes {
    return appCacheStats.totalSizeBytes +
        (tempStats?.totalSizeBytes ?? 0) +
        coverStats.totalSizeBytes +
        libraryCoverStats.totalSizeBytes +
        exploreCacheBytes;
  }
}

class _DirectoryStats {
  final int fileCount;
  final int totalSizeBytes;

  const _DirectoryStats({
    required this.fileCount,
    required this.totalSizeBytes,
  });
}
