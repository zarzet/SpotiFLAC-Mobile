import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/library_collections_provider.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/providers/playback_provider.dart';
import 'package:spotiflac_android/services/library_database.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';
import 'package:spotiflac_android/widgets/download_service_picker.dart';
import 'package:spotiflac_android/widgets/playlist_picker_sheet.dart';

class LibraryTracksFolderScreen extends ConsumerStatefulWidget {
  final LibraryTracksFolderMode mode;
  final String? playlistId;

  const LibraryTracksFolderScreen({
    super.key,
    required this.mode,
    this.playlistId,
  });

  @override
  ConsumerState<LibraryTracksFolderScreen> createState() =>
      _LibraryTracksFolderScreenState();
}

class _LibraryTracksFolderScreenState
    extends ConsumerState<LibraryTracksFolderScreen> {
  bool _showTitleInAppBar = false;
  final ScrollController _scrollController = ScrollController();

  // ── Multi-select state ──
  bool _isSelectionMode = false;
  final Set<String> _selectedKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    return (mediaSize.height * 0.45).clamp(300.0, 420.0);
  }

  IconData _modeIcon() {
    return switch (widget.mode) {
      LibraryTracksFolderMode.wishlist => Icons.bookmark,
      LibraryTracksFolderMode.loved => Icons.favorite,
      LibraryTracksFolderMode.playlist => Icons.queue_music,
    };
  }

  String? _resolveEntryCoverUrl(
    CollectionTrackEntry entry,
    LocalLibraryState localState,
  ) {
    final rawCover = entry.track.coverUrl?.trim();
    if (rawCover != null &&
        rawCover.isNotEmpty &&
        !rawCover.startsWith('content://')) {
      return rawCover;
    }

    final isrc = entry.track.isrc?.trim();
    if (isrc != null && isrc.isNotEmpty) {
      final byIsrc = localState.getByIsrc(isrc);
      final localCover = byIsrc?.coverPath?.trim();
      if (localCover != null && localCover.isNotEmpty) {
        return localCover;
      }
    }

    final byTrack = localState.findByTrackAndArtist(
      entry.track.name,
      entry.track.artistName,
    );
    final localCover = byTrack?.coverPath?.trim();
    if (localCover != null && localCover.isNotEmpty) {
      return localCover;
    }

    return null;
  }

  /// Find the first available cover URL from entries.
  String? _firstCoverUrl(
    List<CollectionTrackEntry> entries,
    LocalLibraryState localState,
  ) {
    for (final entry in entries) {
      final cover = _resolveEntryCoverUrl(entry, localState);
      if (cover != null && cover.isNotEmpty) {
        return cover;
      }
    }
    return null;
  }

  /// Returns true if [url] is a local file path rather than a network URL.
  bool _isCoverLocalPath(String url) {
    return !url.startsWith('http://') && !url.startsWith('https://');
  }

  /// Upgrade cover URL to higher resolution for full-screen display.
  String? _highResCoverUrl(String? url) {
    if (url == null) return null;
    // Spotify CDN: upgrade 300 → 640
    if (url.contains('ab67616d00001e02')) {
      return url.replaceAll('ab67616d00001e02', 'ab67616d0000b273');
    }
    // Deezer CDN: upgrade to 1000x1000
    final deezerRegex = RegExp(r'/(\d+)x(\d+)-(\d+)-(\d+)-(\d+)-(\d+)\.jpg$');
    if (url.contains('cdn-images.dzcdn.net') && deezerRegex.hasMatch(url)) {
      return url.replaceAllMapped(
        deezerRegex,
        (m) => '/1000x1000-${m[3]}-${m[4]}-${m[5]}-${m[6]}.jpg',
      );
    }
    return url;
  }

  // ── Selection helpers ──

  void _enterSelectionMode(String key) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedKeys.add(key);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedKeys.clear();
    });
  }

  void _toggleSelection(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
        if (_selectedKeys.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  void _selectAll(List<CollectionTrackEntry> entries) {
    setState(() {
      _selectedKeys.addAll(entries.map((e) => e.key));
    });
  }

  // ── Batch actions ──

  Future<void> _removeSelected(List<CollectionTrackEntry> entries) async {
    final keysToRemove = _selectedKeys.toSet();
    if (keysToRemove.isEmpty) return;

    final count = keysToRemove.length;
    final notifier = ref.read(libraryCollectionsProvider.notifier);

    for (final key in keysToRemove) {
      switch (widget.mode) {
        case LibraryTracksFolderMode.wishlist:
          await notifier.removeFromWishlist(key);
          break;
        case LibraryTracksFolderMode.loved:
          await notifier.removeFromLoved(key);
          break;
        case LibraryTracksFolderMode.playlist:
          if (widget.playlistId != null) {
            await notifier.removeTrackFromPlaylist(widget.playlistId!, key);
          }
          break;
      }
    }

    _exitSelectionMode();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.selectionSelected(count))),
    );
  }

  void _downloadSelected(List<CollectionTrackEntry> entries) {
    final settings = ref.read(settingsProvider);
    final queueNotifier = ref.read(downloadQueueProvider.notifier);
    var count = 0;

    for (final entry in entries) {
      if (!_selectedKeys.contains(entry.key)) continue;
      queueNotifier.addToQueue(entry.track, settings.defaultService);
      count++;
    }

    _exitSelectionMode();

    if (!mounted || count == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.selectionSelected(count))),
    );
  }

  void _addSelectedToPlaylist(List<CollectionTrackEntry> entries) {
    final selectedTracks = entries
        .where((e) => _selectedKeys.contains(e.key))
        .map((e) => e.track)
        .toList(growable: false);
    if (selectedTracks.isEmpty) return;

    showAddTracksToPlaylistSheet(context, ref, selectedTracks);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    ref.watch(localLibraryProvider.select((s) => s.items));
    final localState = ref.read(localLibraryProvider);
    final UserPlaylistCollection? playlist;
    final List<CollectionTrackEntry> entries;

    switch (widget.mode) {
      case LibraryTracksFolderMode.wishlist:
        playlist = null;
        entries = ref.watch(
          libraryCollectionsProvider.select((state) => state.wishlist),
        );
        break;
      case LibraryTracksFolderMode.loved:
        playlist = null;
        entries = ref.watch(
          libraryCollectionsProvider.select((state) => state.loved),
        );
        break;
      case LibraryTracksFolderMode.playlist:
        final playlistId = widget.playlistId;
        playlist = playlistId == null
            ? null
            : ref.watch(
                libraryCollectionsProvider.select(
                  (state) => state.playlistById(playlistId),
                ),
              );
        entries = playlist?.tracks ?? const <CollectionTrackEntry>[];
        break;
    }

    // Stale selection cleanup
    if (_isSelectionMode) {
      final validKeys = entries.map((e) => e.key).toSet();
      _selectedKeys.removeWhere((key) => !validKeys.contains(key));
      if (_selectedKeys.isEmpty && _isSelectionMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isSelectionMode = false);
        });
      }
    }

    final title = switch (widget.mode) {
      LibraryTracksFolderMode.wishlist => context.l10n.collectionWishlist,
      LibraryTracksFolderMode.loved => context.l10n.collectionLoved,
      LibraryTracksFolderMode.playlist =>
        playlist?.name ?? context.l10n.collectionPlaylist,
    };

    final emptyTitle = switch (widget.mode) {
      LibraryTracksFolderMode.wishlist =>
        context.l10n.collectionWishlistEmptyTitle,
      LibraryTracksFolderMode.loved => context.l10n.collectionLovedEmptyTitle,
      LibraryTracksFolderMode.playlist =>
        context.l10n.collectionPlaylistEmptyTitle,
    };

    final emptySubtitle = switch (widget.mode) {
      LibraryTracksFolderMode.wishlist =>
        context.l10n.collectionWishlistEmptySubtitle,
      LibraryTracksFolderMode.loved =>
        context.l10n.collectionLovedEmptySubtitle,
      LibraryTracksFolderMode.playlist =>
        context.l10n.collectionPlaylistEmptySubtitle,
    };
    final folderTracks = entries
        .map((entry) => entry.track)
        .toList(growable: false);

    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                _buildAppBar(
                  context,
                  colorScheme,
                  title,
                  entries,
                  playlist,
                  localState,
                ),
                if (entries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyFolderState(
                      title: emptyTitle,
                      subtitle: emptySubtitle,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = entries[index];
                      final isSelected = _selectedKeys.contains(entry.key);
                      return KeyedSubtree(
                        key: ValueKey(entry.key),
                        child: _CollectionTrackTile(
                          entry: entry,
                          mode: widget.mode,
                          playlistId: widget.playlistId,
                          localLibraryState: localState,
                          folderTracks: folderTracks,
                          isSelectionMode: _isSelectionMode,
                          isSelected: isSelected,
                          onTap: _isSelectionMode
                              ? () => _toggleSelection(entry.key)
                              : null,
                          onLongPress: _isSelectionMode
                              ? null
                              : () => _enterSelectionMode(entry.key),
                        ),
                      );
                    }, childCount: entries.length),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: _isSelectionMode ? 200 : 32),
                ),
              ],
            ),

            // Selection bottom bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: _isSelectionMode ? 0 : -(280 + bottomPadding),
              child: _buildSelectionBottomBar(
                context,
                colorScheme,
                entries,
                bottomPadding,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBottomBar(
    BuildContext context,
    ColorScheme colorScheme,
    List<CollectionTrackEntry> entries,
    double bottomPadding,
  ) {
    final selectedCount = _selectedKeys.length;
    final allSelected = selectedCount == entries.length && entries.isNotEmpty;
    final isWishlist = widget.mode == LibraryTracksFolderMode.wishlist;

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
              // Drag handle
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header: [X close] [count] [Select All / Deselect]
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
                          context.l10n.selectionSelected(selectedCount),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          allSelected
                              ? context.l10n.selectionAllSelected
                              : context.l10n.selectionSelectToDelete,
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
                        _selectAll(entries);
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

              // Action buttons row
              Row(
                children: [
                  if (isWishlist)
                    Expanded(
                      child: _SelectionActionButton(
                        icon: Icons.download,
                        label:
                            '${context.l10n.settingsDownload} ($selectedCount)',
                        onPressed: selectedCount > 0
                            ? () => _downloadSelected(entries)
                            : null,
                        colorScheme: colorScheme,
                      ),
                    ),
                  if (isWishlist) const SizedBox(width: 8),
                  Expanded(
                    child: _SelectionActionButton(
                      icon: Icons.playlist_add,
                      label:
                          '${context.l10n.collectionAddToPlaylist} ($selectedCount)',
                      onPressed: selectedCount > 0
                          ? () => _addSelectedToPlaylist(entries)
                          : null,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Remove button (full width, red)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: selectedCount > 0
                      ? () => _removeSelected(entries)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: Text(
                    selectedCount > 0
                        ? '${widget.mode == LibraryTracksFolderMode.playlist ? context.l10n.collectionRemoveFromPlaylist : context.l10n.collectionRemoveFromFolder} ($selectedCount)'
                        : widget.mode == LibraryTracksFolderMode.playlist
                        ? context.l10n.collectionRemoveFromPlaylist
                        : context.l10n.collectionRemoveFromFolder,
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

  Future<void> _pickCoverImage() async {
    final playlistId = widget.playlistId;
    if (playlistId == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null || path.isEmpty) return;

    await ref
        .read(libraryCollectionsProvider.notifier)
        .setPlaylistCover(playlistId, path);
  }

  Future<void> _removeCoverImage() async {
    final playlistId = widget.playlistId;
    if (playlistId == null) return;

    await ref
        .read(libraryCollectionsProvider.notifier)
        .removePlaylistCover(playlistId);
  }

  Widget _buildAppBar(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    List<CollectionTrackEntry> entries,
    UserPlaylistCollection? playlist,
    LocalLibraryState localState,
  ) {
    final expandedHeight = _calculateExpandedHeight(context);
    final customCoverPath = playlist?.coverImagePath;
    final isLovedMode = widget.mode == LibraryTracksFolderMode.loved;
    final isPlaylistMode = widget.mode == LibraryTracksFolderMode.playlist;
    // Loved always shows the heart icon (like Spotify's Liked Songs)
    final coverUrl = isLovedMode ? null : _firstCoverUrl(entries, localState);
    final hasCustomCover =
        customCoverPath != null && customCoverPath.isNotEmpty;
    final hasCoverUrl = coverUrl != null;

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
          _isSelectionMode
              ? context.l10n.selectionSelected(_selectedKeys.length)
              : title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        if (isPlaylistMode && !_isSelectionMode)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => _showCoverOptionsSheet(context, hasCustomCover),
          ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapseRatio =
              (constraints.maxHeight - kToolbarHeight) /
              (expandedHeight - kToolbarHeight);
          final showContent = collapseRatio > 0.3;
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final cacheWidth = (MediaQuery.sizeOf(context).width * dpr)
              .round()
              .clamp(320, 2048);
          final coverFallback = Container(
            color: colorScheme.surfaceContainerHighest,
            child: Icon(
              _modeIcon(),
              size: 80,
              color: colorScheme.onSurfaceVariant,
            ),
          );

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Cover background: custom > first track URL > icon
                if (hasCustomCover)
                  Image.file(
                    File(customCoverPath),
                    fit: BoxFit.cover,
                    cacheWidth: cacheWidth,
                    filterQuality: FilterQuality.low,
                    gaplessPlayback: true,
                    frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded || frame != null) return child;
                      return coverFallback;
                    },
                    errorBuilder: (_, _, _) => coverFallback,
                  )
                else if (hasCoverUrl)
                  _isCoverLocalPath(coverUrl)
                      ? Image.file(
                          File(coverUrl),
                          fit: BoxFit.cover,
                          cacheWidth: cacheWidth,
                          filterQuality: FilterQuality.low,
                          gaplessPlayback: true,
                          frameBuilder:
                              (_, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded || frame != null) {
                                  return child;
                                }
                                return Container(color: colorScheme.surface);
                              },
                          errorBuilder: (_, _, _) =>
                              Container(color: colorScheme.surface),
                        )
                      : CachedNetworkImage(
                          imageUrl: _highResCoverUrl(coverUrl) ?? coverUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: cacheWidth,
                          cacheManager: CoverCacheManager.instance,
                          placeholder: (_, _) =>
                              Container(color: colorScheme.surface),
                          errorWidget: (_, _, _) =>
                              Container(color: colorScheme.surface),
                        )
                else
                  coverFallback,
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
                // Title and track count overlay
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
                          title,
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
                        if (entries.isNotEmpty) ...[
                          const SizedBox(height: 12),
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
                                Icon(
                                  _modeIcon(),
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.tracksCount(entries.length),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.mode !=
                                  LibraryTracksFolderMode.wishlist) ...[
                                _buildShuffleButton(entries),
                                const SizedBox(width: 12),
                              ],
                              _buildDownloadAllCenterButton(context, entries),
                            ],
                          ),
                        ],
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
          child: Icon(
            _isSelectionMode ? Icons.close : Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        onPressed: _isSelectionMode
            ? _exitSelectionMode
            : () => Navigator.pop(context),
      ),
    );
  }

  // ── Shuffle / Download buttons ──

  Widget _buildShuffleButton(List<CollectionTrackEntry> entries) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: entries.isEmpty ? null : () => _shufflePlay(entries),
        icon: const Icon(Icons.shuffle_rounded, size: 22, color: Colors.white),
        tooltip: 'Shuffle Play',
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDownloadAllCenterButton(
    BuildContext context,
    List<CollectionTrackEntry> entries,
  ) {
    final tracks = entries.map((e) => e.track).toList(growable: false);
    return FilledButton.icon(
      onPressed: tracks.isEmpty ? null : () => _downloadAll(context, tracks),
      icon: const Icon(Icons.download_rounded, size: 18),
      label: Text(context.l10n.downloadAllCount(tracks.length)),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  void _shufflePlay(List<CollectionTrackEntry> entries) {
    final tracks = entries.map((e) => e.track).toList(growable: false);
    if (tracks.isEmpty) return;
    final shuffled = [...tracks]..shuffle();
    final messenger = ScaffoldMessenger.of(context);
    ref.read(playbackProvider.notifier).playTrackList(shuffled).catchError((e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Cannot shuffle play local tracks: $e')),
      );
    });
  }

  void _downloadAll(BuildContext context, List<Track> tracks) {
    if (tracks.isEmpty) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainerHigh,
          title: const Text('Download All'),
          content: Text('Download ${tracks.length} tracks?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _executeDownloadAll(context, tracks);
              },
              child: const Text('Download'),
            ),
          ],
        );
      },
    );
  }

  void _executeDownloadAll(BuildContext context, List<Track> tracks) {
    final settings = ref.read(settingsProvider);
    if (settings.askQualityBeforeDownload) {
      DownloadServicePicker.show(
        context,
        trackName: '${tracks.length} tracks',
        artistName: '',
        onSelect: (quality, service) {
          ref
              .read(downloadQueueProvider.notifier)
              .addMultipleToQueue(tracks, service, qualityOverride: quality);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.snackbarAddedTracksToQueue(tracks.length),
              ),
            ),
          );
        },
      );
    } else {
      ref
          .read(downloadQueueProvider.notifier)
          .addMultipleToQueue(tracks, settings.defaultService);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.snackbarAddedTracksToQueue(tracks.length)),
        ),
      );
    }
  }

  void _showCoverOptionsSheet(BuildContext context, bool hasCustomCover) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(context.l10n.collectionPlaylistChangeCover),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickCoverImage();
              },
            ),
            if (hasCustomCover)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                title: Text(context.l10n.collectionPlaylistRemoveCover),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeCoverImage();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CollectionTrackTile extends ConsumerWidget {
  final CollectionTrackEntry entry;
  final LibraryTracksFolderMode mode;
  final String? playlistId;
  final LocalLibraryState localLibraryState;
  final List<Track> folderTracks;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _CollectionTrackTile({
    required this.entry,
    required this.mode,
    required this.playlistId,
    required this.localLibraryState,
    required this.folderTracks,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = entry.track;
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveCoverUrl = _resolveCoverUrl(track);

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
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelectionMode) ...[
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: effectiveCoverUrl != null && effectiveCoverUrl.isNotEmpty
                    ? _buildTrackCover(context, effectiveCoverUrl, 52)
                    : Container(
                        width: 52,
                        height: 52,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.music_note,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ],
          ),
          title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            track.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isSelectionMode
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => _showTrackOptionsSheet(context, ref),
                ),
          onTap: isSelectionMode
              ? onTap
              : () {
                  if (mode == LibraryTracksFolderMode.wishlist) {
                    _downloadTrack(context, ref);
                    return;
                  }

                  _navigateToMetadata(context, ref);
                },
          onLongPress: isSelectionMode ? onTap : onLongPress,
        ),
      ),
    );
  }

  String? _resolveCoverUrl(Track track) {
    final rawCover = track.coverUrl?.trim();
    if (rawCover != null &&
        rawCover.isNotEmpty &&
        !rawCover.startsWith('content://')) {
      return rawCover;
    }

    final isrc = track.isrc?.trim();
    if (isrc != null && isrc.isNotEmpty) {
      final byIsrc = localLibraryState.getByIsrc(isrc);
      final localCover = byIsrc?.coverPath?.trim();
      if (localCover != null && localCover.isNotEmpty) return localCover;
    }

    final byTrack = localLibraryState.findByTrackAndArtist(
      track.name,
      track.artistName,
    );
    final localCover = byTrack?.coverPath?.trim();
    if (localCover != null && localCover.isNotEmpty) return localCover;

    return null;
  }

  /// Builds a cover image widget that handles both network URLs and local file paths.
  Widget _buildTrackCover(BuildContext context, String coverUrl, double size) {
    final isLocal =
        !coverUrl.startsWith('http://') && !coverUrl.startsWith('https://');
    final colorScheme = Theme.of(context).colorScheme;

    if (isLocal) {
      return Image.file(
        File(coverUrl),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          color: colorScheme.surfaceContainerHighest,
          child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: coverUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: (size * 2).toInt(),
      cacheManager: CoverCacheManager.instance,
      errorWidget: (_, _, _) => Container(
        width: size,
        height: size,
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  void _showTrackOptionsSheet(BuildContext context, WidgetRef ref) {
    final track = entry.track;
    final effectiveCoverUrl = _resolveCoverUrl(track);
    final colorScheme = Theme.of(context).colorScheme;
    final historyState = ref.read(downloadHistoryProvider);
    final isDownloaded =
        historyState.isDownloaded(track.id) ||
        (track.isrc != null &&
            track.isrc!.isNotEmpty &&
            historyState.getByIsrc(track.isrc!) != null) ||
        historyState.findByTrackAndArtist(track.name, track.artistName) != null;
    // Wishlist: only show "Add to Playlist" if track is already downloaded
    final showAddToPlaylist =
        mode != LibraryTracksFolderMode.wishlist || isDownloaded;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: drag handle + cover + track info
            Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            effectiveCoverUrl != null &&
                                effectiveCoverUrl.isNotEmpty
                            ? _buildTrackCover(context, effectiveCoverUrl, 56)
                            : Container(
                                width: 56,
                                height: 56,
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.music_note,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artistName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),

            // Add to playlist (hidden in wishlist unless already downloaded)
            if (showAddToPlaylist)
              _CollectionOptionTile(
                icon: Icons.playlist_add,
                title: context.l10n.collectionAddToPlaylist,
                onTap: () {
                  Navigator.pop(sheetContext);
                  showAddTrackToPlaylistSheet(context, ref, track);
                },
              ),

            // Remove from folder / playlist
            _CollectionOptionTile(
              icon: Icons.remove_circle_outline,
              iconColor: colorScheme.error,
              title: mode == LibraryTracksFolderMode.playlist
                  ? context.l10n.collectionRemoveFromPlaylist
                  : context.l10n.collectionRemoveFromFolder,
              onTap: () {
                Navigator.pop(sheetContext);
                _removeFromCurrentFolder(context, ref);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFromCurrentFolder(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(libraryCollectionsProvider.notifier);
    final key = entry.key;

    switch (mode) {
      case LibraryTracksFolderMode.wishlist:
        await notifier.removeFromWishlist(key);
        break;
      case LibraryTracksFolderMode.loved:
        await notifier.removeFromLoved(key);
        break;
      case LibraryTracksFolderMode.playlist:
        if (playlistId != null) {
          await notifier.removeTrackFromPlaylist(playlistId!, key);
        }
        break;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.collectionRemoved(entry.track.name))),
    );
  }

  void _downloadTrack(BuildContext context, WidgetRef ref) {
    final track = entry.track;
    final settings = ref.read(settingsProvider);

    if (settings.askQualityBeforeDownload) {
      DownloadServicePicker.show(
        context,
        trackName: track.name,
        artistName: track.artistName,
        coverUrl: track.coverUrl,
        onSelect: (quality, service) {
          ref
              .read(downloadQueueProvider.notifier)
              .addToQueue(track, service, qualityOverride: quality);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.snackbarAddedToQueue(track.name)),
            ),
          );
        },
      );
    } else {
      ref
          .read(downloadQueueProvider.notifier)
          .addToQueue(track, settings.defaultService);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.snackbarAddedToQueue(track.name))),
      );
    }
  }

  Future<void> _navigateToMetadata(BuildContext context, WidgetRef ref) async {
    final track = entry.track;
    final historyState = ref.read(downloadHistoryProvider);

    // 1. Download history by Spotify ID
    var historyItem = historyState.getBySpotifyId(track.id);

    // 2. Download history by ISRC
    if (historyItem == null && track.isrc != null && track.isrc!.isNotEmpty) {
      historyItem = historyState.getByIsrc(track.isrc!);
    }

    // 3. Download history by track name + artist (handles ID/ISRC mismatch)
    historyItem ??= historyState.findByTrackAndArtist(
      track.name,
      track.artistName,
    );

    if (historyItem != null) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) =>
              TrackMetadataScreen(item: historyItem),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      return;
    }

    // 4. Local library by ISRC
    final localState = ref.read(localLibraryProvider);
    LocalLibraryItem? localItem;
    if (track.isrc != null && track.isrc!.isNotEmpty) {
      localItem = localState.getByIsrc(track.isrc!);
    }

    // 5. Local library by track name + artist
    localItem ??= localState.findByTrackAndArtist(track.name, track.artistName);

    if (localItem != null) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) =>
              TrackMetadataScreen(localItem: localItem),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      return;
    }

    // 6. Not found anywhere — offer to download
    _downloadTrack(context, ref);
  }
}

/// Styled like _OptionTile in track_collection_quick_actions.dart
class _CollectionOptionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final VoidCallback onTap;

  const _CollectionOptionTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  const _SelectionActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        backgroundColor: onPressed != null
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        foregroundColor: onPressed != null
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _EmptyFolderState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyFolderState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 60,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum LibraryTracksFolderMode { wishlist, loved, playlist }
