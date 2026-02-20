import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/utils/lyrics_metadata_helper.dart';
import 'package:spotiflac_android/services/library_database.dart';
import 'package:spotiflac_android/services/ffmpeg_service.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/providers/playback_provider.dart';

/// Screen to display tracks from a local library album
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
      // Sort by disc number first, then by track number
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
          try {
            await deleteFile(item.filePath);
          } catch (_) {}
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

        // Go back if all tracks were deleted
        if (deletedCount == currentTracks.length) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _openFile(LocalLibraryItem track) async {
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

    // Show empty state if no tracks found
    if (tracks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.albumName)),
        body: const Center(child: Text('No tracks found for this album')),
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

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Full-screen cover background
                if (widget.coverPath != null)
                  Image.file(
                    File(widget.coverPath!),
                    fit: BoxFit.cover,
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
                // Bottom gradient for readability
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
                // Album info overlay at bottom
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
    // Info is now displayed in the full-screen cover overlay
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  String? _computeCommonQuality(List<LocalLibraryItem> tracks) {
    if (tracks.isEmpty) return null;
    final first = tracks.first;

    // For lossy formats, use bitrate
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

    // For lossless formats, use bit depth / sample rate
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
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _buildTrackItem(context, colorScheme, discTracks[index]),
            childCount: discTracks.length,
          ),
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
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: colorScheme.onPrimary,
                          size: 16,
                        )
                      : null,
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
    final isOpus =
        format == 'opus' ||
        format == 'ogg' ||
        lowerPath.endsWith('.opus') ||
        lowerPath.endsWith('.ogg');

    String? ffmpegResult;
    if (isMp3) {
      ffmpegResult = await FFmpegService.embedMetadataToMp3(
        mp3Path: ffmpegTarget,
        coverPath: effectiveCoverPath,
        metadata: metadata,
      );
    } else if (isOpus) {
      ffmpegResult = await FFmpegService.embedMetadataToOpus(
        opusPath: ffmpegTarget,
        coverPath: effectiveCoverPath,
        metadata: metadata,
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

  Future<bool> _reEnrichLocalTrack(LocalLibraryItem item) async {
    final durationMs = (item.duration ?? 0) * 1000;
    final request = <String, dynamic>{
      'file_path': item.filePath,
      'cover_url': '',
      'max_quality': true,
      'embed_lyrics': true,
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

  /// Batch re-enrich selected local tracks
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.trackReEnrich),
        content: Text(
          '${context.l10n.trackReEnrichOnlineSubtitle}\n\n'
          '${context.l10n.downloadedAlbumSelectedCount(selected.length)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.trackReEnrich),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    var successCount = 0;
    final total = selected.length;

    for (var i = 0; i < total; i++) {
      if (!mounted) break;
      final item = selected[i];

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.trackReEnrichProgress} (${i + 1}/$total)',
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      try {
        final ok = await _reEnrichLocalTrack(item);
        if (ok) {
          successCount++;
        }
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    final localLibraryPath = ref.read(settingsProvider).localLibraryPath.trim();
    try {
      if (localLibraryPath.isNotEmpty &&
          !ref.read(localLibraryProvider).isScanning) {
        await ref
            .read(localLibraryProvider.notifier)
            .startScan(localLibraryPath);
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

    ScaffoldMessenger.of(context).clearSnackBars();
    final failedCount = total - successCount;
    final summary = failedCount <= 0
        ? '${context.l10n.trackReEnrichSuccess} ($successCount/$total)'
        : '${context.l10n.trackReEnrichSuccess} ($successCount/$total) • Failed: $failedCount';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(summary)));
  }

  /// Show batch convert bottom sheet
  void _showBatchConvertSheet(
    BuildContext context,
    List<LocalLibraryItem> allTracks,
  ) {
    String selectedFormat = 'MP3';
    String selectedBitrate = '320k';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            final formats = ['MP3', 'Opus'];
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
                    Row(
                      children: formats.map((format) {
                        final isSelected = format == selectedFormat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(format),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() {
                                  selectedFormat = format;
                                  selectedBitrate = format == 'Opus'
                                      ? '128k'
                                      : '320k';
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
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
        } else if (lower.endsWith('.mp3')) {
          currentFormat = 'MP3';
        } else if (lower.endsWith('.opus') || lower.endsWith('.ogg')) {
          currentFormat = 'Opus';
        }
      }
      if (currentFormat != null && currentFormat != targetFormat) {
        selected.add(item);
      }
    }

    if (selected.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.selectionConvertNoConvertible)),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.selectionBatchConvertConfirmTitle),
        content: Text(
          context.l10n.selectionBatchConvertConfirmMessage(
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

    for (int i = 0; i < total; i++) {
      if (!mounted) break;
      final item = selected[i];

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.selectionBatchConvertProgress(i + 1, total),
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      try {
        final metadata = <String, String>{
          'TITLE': item.trackName,
          'ARTIST': item.artistName,
          'ALBUM': item.albumName,
        };
        try {
          final result = await PlatformBridge.readFileMetadata(item.filePath);
          if (result['error'] == null) {
            result.forEach((key, value) {
              if (key == 'error' || value == null) return;
              final v = value.toString().trim();
              if (v.isEmpty) return;
              metadata[key.toUpperCase()] = v;
            });
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
          // Copy SAF file to temp for conversion
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
          deleteOriginal: !isSaf, // Only delete original for regular files
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
          // For SAF: derive the parent tree URI and relative dir from the content URI,
          // then create new SAF file and delete old one
          //
          // Parse the SAF URI to get the tree document path:
          // content://...tree/...document/.../oldName.flac
          // We need tree URI and relative dir to create the new file
          final uri = Uri.parse(item.filePath);
          final pathSegments = uri.pathSegments;

          // Try to find 'tree' and 'document' segments
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
            final newExt = targetFormat.toLowerCase() == 'opus'
                ? '.opus'
                : '.mp3';
            final newFileName = '$baseName$newExt';
            final mimeType = targetFormat.toLowerCase() == 'opus'
                ? 'audio/opus'
                : 'audio/mpeg';

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

            // Delete old SAF file
            try {
              await PlatformBridge.safDelete(item.filePath);
            } catch (_) {}
            await localDb.deleteByPath(item.filePath);
          }

          // Clean up temp files
          try {
            await File(newPath).delete();
          } catch (_) {}
          if (safTempPath != null) {
            try {
              await File(safTempPath).delete();
            } catch (_) {}
          }
        } else {
          // Regular file: just remove old entry, rescan will find the new one
          await localDb.deleteByPath(item.filePath);
        }

        successCount++;
      } catch (_) {}
    }

    // Reload local library to pick up converted files
    ref.read(localLibraryProvider.notifier).reloadFromStorage();
    _exitSelectionMode();

    if (mounted) {
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

              // Action buttons row: Re-enrich, Convert
              Row(
                children: [
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
