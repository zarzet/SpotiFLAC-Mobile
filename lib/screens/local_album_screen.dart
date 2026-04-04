import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/utils/image_cache_utils.dart';
import 'package:spotiflac_android/utils/lyrics_metadata_helper.dart';
import 'package:spotiflac_android/services/library_database.dart';
import 'package:spotiflac_android/services/ffmpeg_service.dart';
import 'package:spotiflac_android/services/local_track_redownload_service.dart';
import 'package:spotiflac_android/widgets/batch_progress_dialog.dart';
import 'package:spotiflac_android/widgets/re_enrich_field_dialog.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/providers/playback_provider.dart';
import 'package:spotiflac_android/widgets/animation_utils.dart';

class LocalAlbumScreen extends ConsumerStatefulWidget {
  final String albumName;
  final String artistName;
  final String? coverPath;
  final List<LocalLibraryItem> tracks;

  const LocalAlbumScreen({
    super.key,
    required this.albumName,
    required this.artistName,
    this.coverPath,
    required this.tracks,
  });

  @override
  ConsumerState<LocalAlbumScreen> createState() => _LocalAlbumScreenState();
}

class _LocalAlbumScreenState extends ConsumerState<LocalAlbumScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _showTitleInAppBar = false;
  final ScrollController _scrollController = ScrollController();
  late List<LocalLibraryItem> _sortedTracksCache;
  late Map<int, List<LocalLibraryItem>> _discGroupsCache;

  void _showCueVirtualTrackSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(cueVirtualTrackRequiresSplitMessage)),
    );
  }

  late List<int> _sortedDiscNumbersCache;
  late bool _hasMultipleDiscsCache;
  String? _commonQualityCache;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _rebuildTrackCaches();
  }

  @override
  void didUpdateWidget(covariant LocalAlbumScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.tracks, widget.tracks) ||
        oldWidget.tracks.length != widget.tracks.length) {
      _rebuildTrackCaches();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final expandedHeight = _calculateExpandedHeight(context);
    final shouldShow =
        _scrollController.offset > (expandedHeight - kToolbarHeight - 20);
    if (shouldShow != _showTitleInAppBar) {
      setState(() => _showTitleInAppBar = shouldShow);
    }
  }

  double _calculateExpandedHeight(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    return (mediaSize.height * 0.55).clamp(360.0, 520.0);
  }

  List<LocalLibraryItem> _buildSortedTracks() {
    final tracks = List<LocalLibraryItem>.from(widget.tracks);
    tracks.sort((a, b) {
      final aDisc = a.discNumber ?? 1;
      final bDisc = b.discNumber ?? 1;
      if (aDisc != bDisc) return aDisc.compareTo(bDisc);
      final aNum = a.trackNumber ?? 999;
      final bNum = b.trackNumber ?? 999;
      if (aNum != bNum) return aNum.compareTo(bNum);
      return a.trackName.compareTo(b.trackName);
    });
    return tracks;
  }

  void _rebuildTrackCaches() {
    _sortedTracksCache = _buildSortedTracks();
    _discGroupsCache = _groupTracksByDisc(_sortedTracksCache);
    _sortedDiscNumbersCache = _discGroupsCache.keys.toList()..sort();
    _hasMultipleDiscsCache = _discGroupsCache.length > 1;
    _commonQualityCache = _computeCommonQuality(_sortedTracksCache);
  }

  Map<int, List<LocalLibraryItem>> _groupTracksByDisc(
    List<LocalLibraryItem> tracks,
  ) {
    final discMap = <int, List<LocalLibraryItem>>{};
    for (final track in tracks) {
      final discNumber = track.discNumber ?? 1;
      discMap.putIfAbsent(discNumber, () => []).add(track);
    }
    return discMap;
  }

  void _enterSelectionMode(String itemId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(itemId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedIds.contains(itemId)) {
        _selectedIds.remove(itemId);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(itemId);
      }
    });
  }

  void _selectAll(List<LocalLibraryItem> tracks) {
    setState(() {
      _selectedIds.addAll(tracks.map((e) => e.id));
    });
  }

  Future<void> _deleteSelected(List<LocalLibraryItem> currentTracks) async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.downloadedAlbumDeleteSelected),
        content: Text(context.l10n.downloadedAlbumDeleteMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.dialogDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final libraryNotifier = ref.read(localLibraryProvider.notifier);
      final idsToDelete = _selectedIds.toList();
      final tracksById = {for (final track in currentTracks) track.id: track};

      int deletedCount = 0;
      for (final id in idsToDelete) {
        final item = tracksById[id];
        if (item != null) {
          if (!isCueVirtualPath(item.filePath)) {
            try {
              await deleteFile(item.filePath);
            } catch (_) {}
          }
          await libraryNotifier.removeItem(id);
          deletedCount++;
        }
      }

      _exitSelectionMode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.snackbarDeletedTracks(deletedCount)),
          ),
        );

        if (deletedCount == currentTracks.length) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _openFile(LocalLibraryItem track) async {
    if (isCueVirtualPath(track.filePath)) {
      _showCueVirtualTrackSnackBar();
      return;
    }
    try {
      await ref
          .read(playbackProvider.notifier)
          .playLocalPath(
            path: track.filePath,
            title: track.trackName,
            artist: track.artistName,
            album: track.albumName,
            coverUrl: track.coverPath ?? '',
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.snackbarCannotOpenFile(e.toString())),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final tracks = _sortedTracksCache;

    if (tracks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.albumName)),
        body: Center(child: Text(context.l10n.noTracksFoundForAlbum)),
      );
    }

    final validIds = tracks.map((t) => t.id).toSet();
    _selectedIds.removeWhere((id) => !validIds.contains(id));
    if (_selectedIds.isEmpty && _isSelectionMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isSelectionMode = false);
      });
    }

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(context, colorScheme),
                _buildInfoCard(context, colorScheme, tracks),
                _buildTrackList(context, colorScheme, tracks),
                SliverToBoxAdapter(
                  child: SizedBox(height: _isSelectionMode ? 120 : 32),
                ),
              ],
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: _isSelectionMode ? 0 : -(200 + bottomPadding),
              child: _buildSelectionBottomBar(
                context,
                colorScheme,
                tracks,
                bottomPadding,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    final expandedHeight = _calculateExpandedHeight(context);
    final commonQuality = _commonQualityCache;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showTitleInAppBar ? 1.0 : 0.0,
        child: Text(
          widget.albumName,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapseRatio =
              (constraints.maxHeight - kToolbarHeight) /
              (expandedHeight - kToolbarHeight);
          final showContent = collapseRatio > 0.3;
          final cacheWidth = coverCacheWidthForViewport(context);

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.coverPath != null)
                  Image.file(
                    File(widget.coverPath!),
                    fit: BoxFit.cover,
                    cacheWidth: cacheWidth,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, _, _) =>
                        Container(color: colorScheme.surface),
                  )
                else
                  Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.album,
                      size: 80,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: expandedHeight * 0.65,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 40,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: showContent ? 1.0 : 0.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.albumName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.artistName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.folder,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Local',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.music_note,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_sortedTracksCache.length} tracks',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (commonQuality != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  commonQuality,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            stretchModes: const [StretchMode.zoomBackground],
          );
        },
      ),
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    ColorScheme colorScheme,
    List<LocalLibraryItem> tracks,
  ) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  String? _computeCommonQuality(List<LocalLibraryItem> tracks) {
    if (tracks.isEmpty) return null;
    final first = tracks.first;

    if (first.bitrate != null && first.bitrate! > 0) {
      final fmt = first.format?.toUpperCase() ?? '';
      final firstBitrate = first.bitrate;
      for (final track in tracks) {
        if (track.bitrate != firstBitrate) {
          return null;
        }
      }
      return '$fmt ${firstBitrate}kbps'.trim();
    }

    if (first.bitDepth == null ||
        first.bitDepth == 0 ||
        first.sampleRate == null) {
      return null;
    }

    final firstQuality =
        '${first.bitDepth}/${(first.sampleRate! / 1000).round()}kHz';
    for (final track in tracks) {
      if (track.bitDepth != first.bitDepth ||
          track.sampleRate != first.sampleRate) {
        return null;
      }
    }
    return firstQuality;
  }

  Widget _buildTrackList(
    BuildContext context,
    ColorScheme colorScheme,
    List<LocalLibraryItem> tracks,
  ) {
    final discGroups = _discGroupsCache;
    final hasMultipleDiscs = _hasMultipleDiscsCache;

    final slivers = <Widget>[];

    for (final discNumber in _sortedDiscNumbersCache) {
      final discTracks = discGroups[discNumber]!;

      if (hasMultipleDiscs) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.album,
                          size: 16,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.downloadedAlbumDiscHeader(discNumber),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final track = discTracks[index];
            return KeyedSubtree(
              key: ValueKey(track.id),
              child: StaggeredListItem(
                index: index,
                child: _buildTrackItem(context, colorScheme, track),
              ),
            );
          }, childCount: discTracks.length),
        ),
      );
    }

    return SliverMainAxisGroup(slivers: slivers);
  }

  Widget _buildTrackItem(
    BuildContext context,
    ColorScheme colorScheme,
    LocalLibraryItem track,
  ) {
    final isSelected = _selectedIds.contains(track.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 0,
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: _isSelectionMode
              ? () => _toggleSelection(track.id)
              : () => _openFile(track),
          onLongPress: _isSelectionMode
              ? null
              : () => _enterSelectionMode(track.id),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSelectionMode) ...[
                AnimatedSelectionCheckbox(
                  visible: true,
                  selected: isSelected,
                  colorScheme: colorScheme,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              SizedBox(
                width: 24,
                child: Text(
                  track.trackNumber?.toString() ?? '-',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          title: Text(
            track.trackName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: Row(
            children: [
              Flexible(
                child: Text(
                  track.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              if (track.format != null) ...[
                Text(
                  ' • ',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                Text(
                  track.format!.toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          trailing: _isSelectionMode
              ? null
              : IconButton(
                  tooltip: 'Play track',
                  onPressed: () => _openFile(track),
                  icon: Icon(Icons.play_arrow, color: colorScheme.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  Future<void> _safeDeleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _cleanupTempFileAndParent(String path) async {
    await _safeDeleteFile(path);
    try {
      final parent = File(path).parent;
      if (await parent.exists()) {
        await parent.delete();
      }
    } catch (_) {}
  }

  Future<bool> _applyFfmpegReEnrichResult(
    LocalLibraryItem item,
    Map<String, dynamic> result,
  ) async {
    final tempPath = result['temp_path'] as String?;
    final safUri = result['saf_uri'] as String?;
    final ffmpegTarget = _hasValue(tempPath) ? tempPath! : item.filePath;
    final downloadedCoverPath = result['cover_path'] as String?;
    String? effectiveCoverPath = downloadedCoverPath;
    String? extractedCoverPath;

    if (!_hasValue(effectiveCoverPath)) {
      try {
        final tempDir = await Directory.systemTemp.createTemp(
          'reenrich_cover_',
        );
        final coverOutput = '${tempDir.path}${Platform.pathSeparator}cover.jpg';
        final extracted = await PlatformBridge.extractCoverToFile(
          ffmpegTarget,
          coverOutput,
        );
        if (extracted['error'] == null) {
          effectiveCoverPath = coverOutput;
          extractedCoverPath = coverOutput;
        } else {
          try {
            await tempDir.delete(recursive: true);
          } catch (_) {}
        }
      } catch (_) {}
    }

    final metadata = (result['metadata'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, v.toString()),
    );

    final format = item.format?.toLowerCase();
    final lowerPath = item.filePath.toLowerCase();
    final isMp3 = format == 'mp3' || lowerPath.endsWith('.mp3');
    final isM4A =
        format == 'm4a' ||
        format == 'aac' ||
        lowerPath.endsWith('.m4a') ||
        lowerPath.endsWith('.aac');
    final isOpus =
        format == 'opus' ||
        format == 'ogg' ||
        lowerPath.endsWith('.opus') ||
        lowerPath.endsWith('.ogg');

    final artistTagMode = ref.read(settingsProvider).artistTagMode;
    String? ffmpegResult;
    if (isMp3) {
      ffmpegResult = await FFmpegService.embedMetadataToMp3(
        mp3Path: ffmpegTarget,
        coverPath: effectiveCoverPath,
        metadata: metadata,
        preserveMetadata: true,
      );
    } else if (isM4A) {
      ffmpegResult = await FFmpegService.embedMetadataToM4a(
        m4aPath: ffmpegTarget,
        coverPath: effectiveCoverPath,
        metadata: metadata,
        preserveMetadata: true,
      );
    } else if (isOpus) {
      ffmpegResult = await FFmpegService.embedMetadataToOpus(
        opusPath: ffmpegTarget,
        coverPath: effectiveCoverPath,
        metadata: metadata,
        artistTagMode: artistTagMode,
        preserveMetadata: true,
      );
    }

    if (ffmpegResult != null && _hasValue(tempPath) && _hasValue(safUri)) {
      final ok = await PlatformBridge.writeTempToSaf(ffmpegResult, safUri!);
      if (!ok) {
        if (_hasValue(downloadedCoverPath)) {
          await _safeDeleteFile(downloadedCoverPath!);
        }
        if (_hasValue(extractedCoverPath)) {
          await _cleanupTempFileAndParent(extractedCoverPath!);
        }
        await _safeDeleteFile(tempPath!);
        return false;
      }
    }

    if (_hasValue(downloadedCoverPath)) {
      await _safeDeleteFile(downloadedCoverPath!);
    }
    if (_hasValue(extractedCoverPath)) {
      await _cleanupTempFileAndParent(extractedCoverPath!);
    }
    if (_hasValue(tempPath)) {
      await _safeDeleteFile(tempPath!);
    }

    return ffmpegResult != null;
  }

  Future<bool> _reEnrichLocalTrack(
    LocalLibraryItem item, {
    List<String>? updateFields,
  }) async {
    final durationMs = (item.duration ?? 0) * 1000;
    final artistTagMode = ref.read(settingsProvider).artistTagMode;
    final request = <String, dynamic>{
      'file_path': item.filePath,
      'cover_url': '',
      'max_quality': true,
      'embed_lyrics': true,
      'artist_tag_mode': artistTagMode,
      'spotify_id': '',
      'track_name': item.trackName,
      'artist_name': item.artistName,
      'album_name': item.albumName,
      'album_artist': item.albumArtist ?? item.artistName,
      'track_number': item.trackNumber ?? 0,
      'disc_number': item.discNumber ?? 0,
      'release_date': item.releaseDate ?? '',
      'isrc': item.isrc ?? '',
      'genre': item.genre ?? '',
      'label': '',
      'copyright': '',
      'duration_ms': durationMs,
      'search_online': true,
      // ignore: use_null_aware_elements
      if (updateFields != null) 'update_fields': updateFields,
    };

    final result = await PlatformBridge.reEnrichFile(request);
    final method = result['method'] as String?;
    if (method == 'native') {
      return true;
    }
    if (method == 'ffmpeg') {
      return _applyFfmpegReEnrichResult(item, result);
    }
    return false;
  }

  List<LocalLibraryItem> _selectedFlacEligibleItems(
    List<LocalLibraryItem> allTracks,
  ) {
    final tracksById = {for (final t in allTracks) t.id: t};
    return _selectedIds
        .map((id) => tracksById[id])
        .whereType<LocalLibraryItem>()
        .where(LocalTrackRedownloadService.isFlacUpgradeEligible)
        .toList(growable: false);
  }

  Future<void> _queueSelectedAsFlac(List<LocalLibraryItem> allTracks) async {
    final selected = _selectedFlacEligibleItems(allTracks);

    if (selected.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.queueFlacAction),
        content: Text(context.l10n.queueFlacConfirmMessage(selected.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.queueFlacAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final settings = ref.read(settingsProvider);
    final extensionState = ref.read(extensionProvider);
    final includeExtensions =
        settings.useExtensionProviders &&
        extensionState.extensions.any(
          (ext) => ext.enabled && ext.hasMetadataProvider,
        );
    final targetService = LocalTrackRedownloadService.preferredFlacService(
      settings,
    );
    final targetQuality =
        LocalTrackRedownloadService.preferredFlacQualityForService(
          targetService,
        );

    final matchedTracks = <Track>[];
    var skippedCount = 0;
    final total = selected.length;

    var cancelled = false;
    BatchProgressDialog.show(
      context: context,
      title: context.l10n.queueFlacAction,
      total: total,
      icon: Icons.queue_music,
      onCancel: () {
        cancelled = true;
        BatchProgressDialog.dismiss(context);
      },
    );

    for (var i = 0; i < total; i++) {
      if (!mounted || cancelled) break;

      BatchProgressDialog.update(current: i + 1, detail: selected[i].trackName);

      try {
        final resolution = await LocalTrackRedownloadService.resolveBestMatch(
          selected[i],
          includeExtensions: includeExtensions,
        );
        if (resolution.canQueue && resolution.match != null) {
          matchedTracks.add(resolution.match!);
        } else {
          skippedCount++;
        }
      } catch (_) {
        skippedCount++;
      }
    }

    if (!mounted) {
      return;
    }

    if (!cancelled) {
      BatchProgressDialog.dismiss(context);
    }

    if (matchedTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.queueFlacNoReliableMatches)),
      );
      return;
    }

    ref
        .read(downloadQueueProvider.notifier)
        .addMultipleToQueue(
          matchedTracks,
          targetService,
          qualityOverride: targetQuality,
        );

    final summary = skippedCount == 0
        ? context.l10n.snackbarAddedTracksToQueue(matchedTracks.length)
        : context.l10n.queueFlacQueuedWithSkipped(
            matchedTracks.length,
            skippedCount,
          );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(summary)));
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _reEnrichSelected(List<LocalLibraryItem> allTracks) async {
    final tracksById = {for (final t in allTracks) t.id: t};
    final selected = <LocalLibraryItem>[];

    for (final id in _selectedIds) {
      final item = tracksById[id];
      if (item != null) {
        selected.add(item);
      }
    }

    if (selected.isEmpty) {
      return;
    }

    // The bar uses AnimatedPositioned (250ms), so wait for the slide-out.
    setState(() => _isSelectionMode = false);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final selection = await showReEnrichFieldDialog(
      context,
      selectedCount: selected.length,
    );

    if (selection == null || !mounted) {
      // Cancelled — restore selection mode (IDs are still intact).
      if (mounted) setState(() => _isSelectionMode = true);
      return;
    }

    final updateFields = selection.isAll ? null : selection.fields;

    var successCount = 0;
    final total = selected.length;

    var cancelled = false;
    BatchProgressDialog.show(
      context: context,
      title: context.l10n.trackReEnrichProgress,
      total: total,
      icon: Icons.auto_fix_high,
      onCancel: () {
        cancelled = true;
        BatchProgressDialog.dismiss(context);
      },
    );

    for (var i = 0; i < total; i++) {
      if (!mounted || cancelled) break;
      final item = selected[i];

      BatchProgressDialog.update(
        current: i + 1,
        detail: '${item.trackName} - ${item.artistName}',
      );

      try {
        final ok = await _reEnrichLocalTrack(item, updateFields: updateFields);
        if (ok) {
          successCount++;
        }
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    final settings = ref.read(settingsProvider);
    final localLibraryPath = settings.localLibraryPath.trim();
    final iosBookmark = settings.localLibraryBookmark;
    try {
      if (localLibraryPath.isNotEmpty &&
          !ref.read(localLibraryProvider).isScanning) {
        await ref
            .read(localLibraryProvider.notifier)
            .startScan(
              localLibraryPath,
              iosBookmark: iosBookmark.isNotEmpty ? iosBookmark : null,
            );
      } else {
        await ref.read(localLibraryProvider.notifier).reloadFromStorage();
      }
    } catch (_) {
      await ref.read(localLibraryProvider.notifier).reloadFromStorage();
    }

    _exitSelectionMode();

    if (!mounted) {
      return;
    }

    if (!cancelled) {
      BatchProgressDialog.dismiss(context);
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    final failedCount = total - successCount;
    final summary = failedCount <= 0
        ? '${context.l10n.trackReEnrichSuccess} ($successCount/$total)'
        : '${context.l10n.trackReEnrichSuccess} ($successCount/$total) • Failed: $failedCount';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(summary)));
  }

  void _showBatchConvertSheet(
    BuildContext context,
    List<LocalLibraryItem> allTracks,
  ) {
    final tracksById = {for (final t in allTracks) t.id: t};
    final sourceFormats = <String>{};
    for (final id in _selectedIds) {
      final item = tracksById[id];
      if (item == null) continue;
      String? ext;
      if (item.format != null && item.format!.isNotEmpty) {
        final fmt = item.format!.toLowerCase();
        if (fmt == 'flac') {
          ext = 'FLAC';
        } else if (fmt == 'm4a') {
          ext = 'M4A';
        } else if (fmt == 'mp3') {
          ext = 'MP3';
        } else if (fmt == 'opus' || fmt == 'ogg') {
          ext = 'Opus';
        }
      }
      if (ext == null) {
        final lower = item.filePath.toLowerCase();
        if (lower.endsWith('.flac')) {
          ext = 'FLAC';
        } else if (lower.endsWith('.m4a')) {
          ext = 'M4A';
        } else if (lower.endsWith('.mp3')) {
          ext = 'MP3';
        } else if (lower.endsWith('.opus') || lower.endsWith('.ogg')) {
          ext = 'Opus';
        }
      }
      if (ext != null) sourceFormats.add(ext);
    }

    final formats = ['ALAC', 'FLAC', 'MP3', 'Opus'].where((target) {
      return sourceFormats.any((src) {
        if (src == target) return false;
        final isLosslessTarget = target == 'ALAC' || target == 'FLAC';
        final isLosslessSource = src == 'FLAC' || src == 'M4A';
        if (isLosslessTarget && !isLosslessSource) return false;
        return true;
      });
    }).toList();

    if (formats.isEmpty) return;

    String selectedFormat = formats.first;
    bool isLosslessTarget =
        selectedFormat == 'ALAC' || selectedFormat == 'FLAC';
    String selectedBitrate = isLosslessTarget
        ? '320k'
        : (selectedFormat == 'Opus' ? '128k' : '320k');

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            final bitrates = ['128k', '192k', '256k', '320k'];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.selectionBatchConvertConfirmTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.trackConvertTargetFormat,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: formats.map((format) {
                        final isSelected = format == selectedFormat;
                        return ChoiceChip(
                          label: Text(format),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() {
                                selectedFormat = format;
                                isLosslessTarget =
                                    format == 'ALAC' || format == 'FLAC';
                                if (!isLosslessTarget) {
                                  selectedBitrate = format == 'Opus'
                                      ? '128k'
                                      : '320k';
                                }
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    if (!isLosslessTarget) ...[
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.trackConvertBitrate,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: bitrates.map((br) {
                          final isSelected = br == selectedBitrate;
                          return ChoiceChip(
                            label: Text(br),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() => selectedBitrate = br);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    if (isLosslessTarget) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.trackConvertLosslessHint,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.primary),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performBatchConversion(
                            allTracks: allTracks,
                            targetFormat: selectedFormat,
                            bitrate: selectedBitrate,
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          context.l10n.selectionConvertCount(
                            _selectedIds.length,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performBatchConversion({
    required List<LocalLibraryItem> allTracks,
    required String targetFormat,
    required String bitrate,
  }) async {
    final tracksById = {for (final t in allTracks) t.id: t};
    final selected = <LocalLibraryItem>[];
    for (final id in _selectedIds) {
      final item = tracksById[id];
      if (item == null) continue;
      // Detect current format: prefer item.format field (works for SAF too),
      // fall back to file extension for regular paths
      String? currentFormat;
      if (item.format != null && item.format!.isNotEmpty) {
        final fmt = item.format!.toLowerCase();
        if (fmt == 'flac') {
          currentFormat = 'FLAC';
        } else if (fmt == 'm4a') {
          currentFormat = 'M4A';
        } else if (fmt == 'mp3') {
          currentFormat = 'MP3';
        } else if (fmt == 'opus' || fmt == 'ogg') {
          currentFormat = 'Opus';
        }
      }
      if (currentFormat == null) {
        // Fallback: try file extension (works for regular paths)
        final lower = item.filePath.toLowerCase();
        if (lower.endsWith('.flac')) {
          currentFormat = 'FLAC';
        } else if (lower.endsWith('.m4a')) {
          currentFormat = 'M4A';
        } else if (lower.endsWith('.mp3')) {
          currentFormat = 'MP3';
        } else if (lower.endsWith('.opus') || lower.endsWith('.ogg')) {
          currentFormat = 'Opus';
        }
      }
      if (currentFormat == null || currentFormat == targetFormat) continue;
      final isLosslessTarget = targetFormat == 'ALAC' || targetFormat == 'FLAC';
      final isLosslessSource =
          currentFormat == 'FLAC' || currentFormat == 'M4A';
      if (isLosslessTarget && !isLosslessSource) continue;
      selected.add(item);
    }

    if (selected.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.selectionConvertNoConvertible)),
        );
      }
      return;
    }

    final isLossless = targetFormat == 'ALAC' || targetFormat == 'FLAC';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.selectionBatchConvertConfirmTitle),
        content: Text(
          isLossless
              ? context.l10n.selectionBatchConvertConfirmMessageLossless(
                  selected.length,
                  targetFormat,
                )
              : context.l10n.selectionBatchConvertConfirmMessage(
                  selected.length,
                  targetFormat,
                  bitrate,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.trackConvertFormat),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    int successCount = 0;
    final total = selected.length;
    final localDb = LibraryDatabase.instance;
    final settings = ref.read(settingsProvider);
    final shouldEmbedLyrics =
        settings.embedLyrics && settings.lyricsMode != 'external';

    var cancelled = false;
    BatchProgressDialog.show(
      context: context,
      title: context.l10n.trackConvertConverting,
      total: total,
      icon: Icons.transform,
      onCancel: () {
        cancelled = true;
        BatchProgressDialog.dismiss(context);
      },
    );

    for (int i = 0; i < total; i++) {
      if (!mounted || cancelled) break;
      final item = selected[i];

      BatchProgressDialog.update(current: i + 1, detail: item.trackName);

      try {
        final metadata = <String, String>{
          'TITLE': item.trackName,
          'ARTIST': item.artistName,
          'ALBUM': item.albumName,
        };
        try {
          final result = await PlatformBridge.readFileMetadata(item.filePath);
          if (result['error'] == null) {
            mergePlatformMetadataForTagEmbed(target: metadata, source: result);
          }
        } catch (_) {}
        await ensureLyricsMetadataForConversion(
          metadata: metadata,
          sourcePath: item.filePath,
          shouldEmbedLyrics: shouldEmbedLyrics,
          trackName: item.trackName,
          artistName: item.artistName,
          durationMs: (item.duration ?? 0) * 1000,
        );

        String? coverPath;
        try {
          final tempDir = await getTemporaryDirectory();
          final coverOutput =
              '${tempDir.path}${Platform.pathSeparator}batch_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final coverResult = await PlatformBridge.extractCoverToFile(
            item.filePath,
            coverOutput,
          );
          if (coverResult['error'] == null) coverPath = coverOutput;
        } catch (_) {}

        final isSaf = isContentUri(item.filePath);
        String workingPath = item.filePath;
        String? safTempPath;

        if (isSaf) {
          safTempPath = await PlatformBridge.copyContentUriToTemp(
            item.filePath,
          );
          if (safTempPath == null) continue;
          workingPath = safTempPath;
        }

        final newPath = await FFmpegService.convertAudioFormat(
          inputPath: workingPath,
          targetFormat: targetFormat.toLowerCase(),
          bitrate: bitrate,
          metadata: metadata,
          coverPath: coverPath,
          artistTagMode: settings.artistTagMode,
          deleteOriginal: !isSaf,
        );

        if (coverPath != null) {
          try {
            await File(coverPath).delete();
          } catch (_) {}
        }

        if (newPath == null) {
          if (safTempPath != null) {
            try {
              await File(safTempPath).delete();
            } catch (_) {}
          }
          continue;
        }

        if (isSaf) {
          final uri = Uri.parse(item.filePath);
          final pathSegments = uri.pathSegments;

          String? treeUri;
          String relativeDir = '';
          String oldFileName = '';

          // Typical SAF document URI pattern:
          // content://authority/tree/<tree-id>/document/<doc-path>
          final treeIdx = pathSegments.indexOf('tree');
          final docIdx = pathSegments.indexOf('document');
          if (treeIdx >= 0 && treeIdx + 1 < pathSegments.length) {
            final treeId = pathSegments[treeIdx + 1];
            treeUri =
                'content://${uri.authority}/tree/${Uri.encodeComponent(treeId)}';
          }

          if (docIdx >= 0 && docIdx + 1 < pathSegments.length) {
            final docPath = Uri.decodeFull(pathSegments[docIdx + 1]);
            final slashIdx = docPath.lastIndexOf('/');
            if (slashIdx >= 0) {
              oldFileName = docPath.substring(slashIdx + 1);
              // Relative dir is everything after the tree id's directory base
              final treeId = treeIdx >= 0 && treeIdx + 1 < pathSegments.length
                  ? Uri.decodeFull(pathSegments[treeIdx + 1])
                  : '';
              if (treeId.isNotEmpty && docPath.startsWith(treeId)) {
                final afterTree = docPath.substring(treeId.length);
                final trimmed = afterTree.startsWith('/')
                    ? afterTree.substring(1)
                    : afterTree;
                final lastSlash = trimmed.lastIndexOf('/');
                relativeDir = lastSlash >= 0
                    ? trimmed.substring(0, lastSlash)
                    : '';
              }
            } else {
              oldFileName = docPath;
            }
          }

          if (treeUri != null && oldFileName.isNotEmpty) {
            final dotIdx = oldFileName.lastIndexOf('.');
            final baseName = dotIdx > 0
                ? oldFileName.substring(0, dotIdx)
                : oldFileName;
            String newExt;
            String mimeType;
            switch (targetFormat.toLowerCase()) {
              case 'opus':
                newExt = '.opus';
                mimeType = 'audio/opus';
                break;
              case 'alac':
                newExt = '.m4a';
                mimeType = 'audio/mp4';
                break;
              case 'flac':
                newExt = '.flac';
                mimeType = 'audio/flac';
                break;
              default:
                newExt = '.mp3';
                mimeType = 'audio/mpeg';
                break;
            }
            final newFileName = '$baseName$newExt';

            final safUri = await PlatformBridge.createSafFileFromPath(
              treeUri: treeUri,
              relativeDir: relativeDir,
              fileName: newFileName,
              mimeType: mimeType,
              srcPath: newPath,
            );

            if (safUri == null || safUri.isEmpty) {
              try {
                await File(newPath).delete();
              } catch (_) {}
              if (safTempPath != null) {
                try {
                  await File(safTempPath).delete();
                } catch (_) {}
              }
              continue;
            }

            try {
              await PlatformBridge.safDelete(item.filePath);
            } catch (_) {}
            await localDb.replaceWithConvertedItem(
              item: item,
              newFilePath: safUri,
              targetFormat: targetFormat,
              bitrate: bitrate,
            );
          }

          try {
            await File(newPath).delete();
          } catch (_) {}
          if (safTempPath != null) {
            try {
              await File(safTempPath).delete();
            } catch (_) {}
          }
        } else {
          await localDb.replaceWithConvertedItem(
            item: item,
            newFilePath: newPath,
            targetFormat: targetFormat,
            bitrate: bitrate,
          );
        }

        successCount++;
      } catch (_) {}
    }

    ref.read(localLibraryProvider.notifier).reloadFromStorage();
    _exitSelectionMode();

    if (mounted) {
      if (!cancelled) {
        BatchProgressDialog.dismiss(context);
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.selectionBatchConvertSuccess(
              successCount,
              total,
              targetFormat,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSelectionBottomBar(
    BuildContext context,
    ColorScheme colorScheme,
    List<LocalLibraryItem> tracks,
    double bottomPadding,
  ) {
    final selectedCount = _selectedIds.length;
    final flacEligibleCount = _selectedFlacEligibleItems(tracks).length;
    final allSelected = selectedCount == tracks.length && tracks.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding > 0 ? 8 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _exitSelectionMode,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.downloadedAlbumSelectedCount(
                            selectedCount,
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          allSelected
                              ? context.l10n.downloadedAlbumAllSelected
                              : context.l10n.downloadedAlbumTapToSelect,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      if (allSelected) {
                        _exitSelectionMode();
                      } else {
                        _selectAll(tracks);
                      }
                    },
                    icon: Icon(
                      allSelected ? Icons.deselect : Icons.select_all,
                      size: 20,
                    ),
                    label: Text(
                      allSelected
                          ? context.l10n.actionDeselect
                          : context.l10n.actionSelectAll,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  if (flacEligibleCount > 0) ...[
                    Expanded(
                      child: _LocalAlbumSelectionActionButton(
                        icon: Icons.download_for_offline_outlined,
                        label:
                            '${context.l10n.queueFlacAction} ($flacEligibleCount)',
                        onPressed: () => _queueSelectedAsFlac(tracks),
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _LocalAlbumSelectionActionButton(
                      icon: Icons.auto_fix_high_outlined,
                      label: '${context.l10n.trackReEnrich} ($selectedCount)',
                      onPressed: selectedCount > 0
                          ? () => _reEnrichSelected(tracks)
                          : null,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LocalAlbumSelectionActionButton(
                      icon: Icons.swap_horiz,
                      label: context.l10n.selectionConvertCount(selectedCount),
                      onPressed: selectedCount > 0
                          ? () => _showBatchConvertSheet(context, tracks)
                          : null,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: selectedCount > 0
                      ? () => _deleteSelected(tracks)
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    selectedCount > 0
                        ? context.l10n.downloadedAlbumDeleteCount(selectedCount)
                        : context.l10n.downloadedAlbumSelectToDelete,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedCount > 0
                        ? colorScheme.error
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor: selectedCount > 0
                        ? colorScheme.onError
                        : colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalAlbumSelectionActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  const _LocalAlbumSelectionActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return Material(
      color: isDisabled
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isDisabled
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                    : colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
