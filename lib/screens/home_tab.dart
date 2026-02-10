import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/providers/recent_access_provider.dart';
import 'package:spotiflac_android/providers/explore_provider.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';
import 'package:spotiflac_android/screens/album_screen.dart';
import 'package:spotiflac_android/screens/artist_screen.dart';
import 'package:spotiflac_android/services/csv_import_service.dart';
import 'package:spotiflac_android/services/downloaded_embedded_cover_resolver.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/screens/playlist_screen.dart';
import 'package:spotiflac_android/screens/downloaded_album_screen.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/widgets/download_service_picker.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});
  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _RecentAccessView {
  final List<RecentAccessItem> uniqueItems;
  final List<String> downloadIds;
  final Map<String, String> downloadFilePathByRecentKey;
  final bool hasHiddenDownloads;

  const _RecentAccessView({
    required this.uniqueItems,
    required this.downloadIds,
    required this.downloadFilePathByRecentKey,
    required this.hasHiddenDownloads,
  });
}

class _RecentAlbumAggregate {
  int count;
  DownloadHistoryItem mostRecent;

  _RecentAlbumAggregate({required this.count, required this.mostRecent});
}

class _CsvImportOptions {
  final bool confirmed;
  final bool skipDownloaded;

  const _CsvImportOptions({
    required this.confirmed,
    required this.skipDownloaded,
  });
}

class _HomeTabState extends ConsumerState<HomeTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _lastSearchQuery;
  late final ProviderSubscription<TrackState> _trackStateSub;
  late final ProviderSubscription<bool> _extensionInitSub;
  late final ProviderSubscription<bool> _homeFeedExtSub;

  Timer? _liveSearchDebounce;
  bool _isLiveSearchInProgress = false;
  String? _pendingLiveSearchQuery;
  static const int _minLiveSearchChars = 3;
  static const Duration _liveSearchDelay = Duration(milliseconds: 800);

  List<DownloadHistoryItem>? _recentAccessHistoryCache;
  List<RecentAccessItem>? _recentAccessItemsCache;
  Set<String>? _recentAccessHiddenIdsCache;
  _RecentAccessView? _recentAccessViewCache;
  bool _embeddedCoverRefreshScheduled = false;
  List<Extension>? _thumbnailSizesExtensionsCache;
  Map<String, (double, double)>? _thumbnailSizesCache;

  double _responsiveScale({
    required BuildContext context,
    double min = 0.82,
    double max = 1.08,
    double baseShortestSide = 390,
  }) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final scale = shortestSide / baseShortestSide;
    if (scale < min) return min;
    if (scale > max) return max;
    return scale;
  }

  double _effectiveTextScale(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    if (textScale < 1.0) return 1.0;
    if (textScale > 1.4) return 1.4;
    return textScale;
  }

  double _recentDownloadCoverSize(BuildContext context) {
    final scale = _responsiveScale(context: context, min: 0.82, max: 1.05);
    final textScale = _effectiveTextScale(context);
    return 100 * scale * (1 + (textScale - 1) * 0.15);
  }

  double _recentDownloadsRowHeight(BuildContext context) {
    final coverSize = _recentDownloadCoverSize(context);
    final textScale = _effectiveTextScale(context);
    return coverSize + 28 + ((textScale - 1) * 8);
  }

  double _exploreCardSize(BuildContext context) {
    final scale = _responsiveScale(context: context, min: 0.82, max: 1.08);
    final textScale = _effectiveTextScale(context);
    return 120 * scale * (1 + (textScale - 1) * 0.12);
  }

  double _exploreSectionHeight(BuildContext context) {
    final cardSize = _exploreCardSize(context);
    final textScale = _effectiveTextScale(context);
    return cardSize + 55 + ((textScale - 1) * 12);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);

    _trackStateSub = ref.listenManual<TrackState>(trackProvider, (
      previous,
      next,
    ) {
      _onTrackStateChanged(previous, next);
      if (previous != null &&
          previous.isLoading &&
          !next.isLoading &&
          next.error == null) {
        _navigateToDetailIfNeeded();
      }
    });

    _extensionInitSub = ref.listenManual<bool>(
      extensionProvider.select((s) => s.isInitialized),
      (previous, next) {
        if (next == true && previous != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fetchExploreIfNeeded();
          });
        }
      },
    );

    // Watch for new homeFeed extension being installed/enabled after init
    _homeFeedExtSub = ref.listenManual<bool>(
      extensionProvider.select(
        (s) => s.extensions.any((e) => e.enabled && e.hasHomeFeed),
      ),
      (previous, next) {
        if (next == true && previous != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref
                  .read(exploreProvider.notifier)
                  .fetchHomeFeed(forceRefresh: true);
            }
          });
        }
      },
    );
  }

  void _fetchExploreIfNeeded() {
    final extState = ref.read(extensionProvider);
    final exploreState = ref.read(exploreProvider);
    final hasHomeFeedExtension = extState.extensions.any(
      (e) => e.enabled && e.hasHomeFeed,
    );
    if (hasHomeFeedExtension &&
        !exploreState.hasContent &&
        !exploreState.isLoading) {
      ref.read(exploreProvider.notifier).fetchHomeFeed();
    }
  }

  @override
  void dispose() {
    _liveSearchDebounce?.cancel();
    _trackStateSub.close();
    _extensionInitSub.close();
    _homeFeedExtSub.close();
    _urlController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _urlController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Map<String, (double, double)> _getThumbnailSizesByExtensionId(
    List<Extension> extensions,
  ) {
    final cached = _thumbnailSizesCache;
    if (cached != null &&
        identical(extensions, _thumbnailSizesExtensionsCache)) {
      return cached;
    }

    final map = <String, (double, double)>{
      for (final extension in extensions)
        if (extension.searchBehavior != null)
          extension.id: extension.searchBehavior!.getThumbnailSize(
            defaultSize: 56,
          ),
    };
    _thumbnailSizesExtensionsCache = extensions;
    _thumbnailSizesCache = map;
    return map;
  }

  void _onSearchFocusChanged() {
    if (mounted) {
      setState(() {});
    }
    if (_searchFocusNode.hasFocus) {
      ref.read(trackProvider.notifier).setShowingRecentAccess(true);
    }
  }

  void _onTrackStateChanged(TrackState? previous, TrackState next) {
    if (previous != null &&
        !next.hasContent &&
        !next.hasSearchText &&
        !next.isLoading &&
        _urlController.text.isNotEmpty &&
        !_searchFocusNode.hasFocus) {
      _urlController.clear();
    }
  }

  /// Check if live search is available (extension is set as search provider)
  bool _isLiveSearchEnabled() {
    final settings = ref.read(settingsProvider);
    final extState = ref.read(extensionProvider);
    final searchProvider = settings.searchProvider;

    if (searchProvider == null || searchProvider.isEmpty) return false;

    final extension = extState.extensions
        .where((e) => e.id == searchProvider && e.enabled)
        .firstOrNull;
    return extension != null;
  }

  void _onSearchChanged() {
    final text = _urlController.text.trim();

    ref.read(trackProvider.notifier).setSearchText(text.isNotEmpty);

    if (text.isEmpty) {
      _liveSearchDebounce?.cancel();
      return;
    }

    if (_isLiveSearchEnabled() && text.length >= _minLiveSearchChars) {
      if (text.startsWith('http') || text.startsWith('spotify:')) return;

      _liveSearchDebounce?.cancel();
      _liveSearchDebounce = Timer(_liveSearchDelay, () {
        if (mounted && _urlController.text.trim() == text) {
          _executeLiveSearch(text);
        }
      });
    }
  }

  Future<void> _executeLiveSearch(String query) async {
    if (_isLiveSearchInProgress) {
      _pendingLiveSearchQuery = query;
      return;
    }

    _isLiveSearchInProgress = true;
    _pendingLiveSearchQuery = null;

    try {
      await _performSearch(query);
    } finally {
      _isLiveSearchInProgress = false;

      final pending = _pendingLiveSearchQuery;
      _pendingLiveSearchQuery = null;

      if (pending != null &&
          pending != query &&
          mounted &&
          _urlController.text.trim() == pending) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && _urlController.text.trim() == pending) {
          _executeLiveSearch(pending);
        }
      }
    }
  }

  Future<void> _performSearch(String query, {String? filterOverride}) async {
    final settings = ref.read(settingsProvider);
    final extState = ref.read(extensionProvider);
    final searchProvider = settings.searchProvider;
    // Use filterOverride if provided, otherwise read from state
    final selectedFilter =
        filterOverride ?? ref.read(trackProvider).selectedSearchFilter;

    final searchKey =
        '${searchProvider ?? 'default'}:$query:${selectedFilter ?? 'all'}';
    if (_lastSearchQuery == searchKey) return;
    _lastSearchQuery = searchKey;

    final isExtensionEnabled =
        searchProvider != null &&
        searchProvider.isNotEmpty &&
        extState.extensions.any((e) => e.id == searchProvider && e.enabled);

    if (isExtensionEnabled) {
      // Build options with filter if selected
      Map<String, dynamic>? options;
      if (selectedFilter != null) {
        options = {'filter': selectedFilter};
      }
      await ref
          .read(trackProvider.notifier)
          .customSearch(searchProvider, query, options: options);
    } else {
      if (searchProvider != null &&
          searchProvider.isNotEmpty &&
          !isExtensionEnabled) {
        ref.read(settingsProvider.notifier).setSearchProvider(null);
      }
      await ref
          .read(trackProvider.notifier)
          .search(
            query,
            metadataSource: settings.metadataSource,
            filterOverride: selectedFilter,
          );
    }
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
      final text = data.text!.trim();
      if (text.startsWith('http') || text.startsWith('spotify:')) {
        _fetchMetadata();
      }
    }
  }

  Future<void> _clearAndRefresh() async {
    _liveSearchDebounce?.cancel();
    _pendingLiveSearchQuery = null;
    _urlController.clear();
    _searchFocusNode.unfocus();
    _lastSearchQuery = null;
    ref.read(trackProvider.notifier).clear();
  }

  Future<void> _fetchMetadata() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (url.startsWith('http') || url.startsWith('spotify:')) {
      await ref.read(trackProvider.notifier).fetchFromUrl(url);
      _navigateToDetailIfNeeded();
    } else {
      final settings = ref.read(settingsProvider);
      await ref
          .read(trackProvider.notifier)
          .search(url, metadataSource: settings.metadataSource);
    }
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
  }

  void _navigateToDetailIfNeeded() {
    final trackState = ref.read(trackProvider);

    if (trackState.albumId != null &&
        trackState.albumName != null &&
        trackState.tracks.isNotEmpty) {
      final extensionId = trackState.searchExtensionId;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlbumScreen(
            albumId: trackState.albumId!,
            albumName: trackState.albumName!,
            coverUrl: trackState.coverUrl,
            tracks: trackState.tracks,
            extensionId: extensionId,
          ),
        ),
      );
      ref.read(trackProvider.notifier).clear();
      _urlController.clear();
      return;
    }

    if (trackState.playlistName != null && trackState.tracks.isNotEmpty) {
      ref
          .read(recentAccessProvider.notifier)
          .recordPlaylistAccess(
            id: trackState.playlistName!,
            name: trackState.playlistName!,
            imageUrl: trackState.coverUrl,
            providerId: trackState.searchExtensionId ?? 'spotify',
          );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistScreen(
            playlistName: trackState.playlistName!,
            coverUrl: trackState.coverUrl,
            tracks: trackState.tracks,
          ),
        ),
      );
      ref.read(trackProvider.notifier).clear();
      _urlController.clear();
      return;
    }

    if (trackState.artistId != null &&
        trackState.artistName != null &&
        trackState.artistAlbums != null) {
      final extensionId = trackState.searchExtensionId;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArtistScreen(
            artistId: trackState.artistId!,
            artistName: trackState.artistName!,
            coverUrl: trackState.coverUrl,
            albums: trackState.artistAlbums!,
            extensionId: extensionId,
          ),
        ),
      );
      ref.read(trackProvider.notifier).clear();
      _urlController.clear();
      return;
    }
  }

  void _downloadTrack(int index) {
    final trackState = ref.read(trackProvider);
    if (index >= 0 && index < trackState.tracks.length) {
      final track = trackState.tracks[index];
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
          SnackBar(
            content: Text(context.l10n.snackbarAddedToQueue(track.name)),
          ),
        );
      }
    }
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    int currentProgress = 0;
    int totalTracks = 0;

    bool dialogShown = false;
    StateSetter? setDialogState;

    void showProgressDialog() {
      if (dialogShown || !mounted) return;
      dialogShown = true;
      showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (dialogCtx, setState) {
            setDialogState = setState;
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    totalTracks > 0
                        ? context.l10n.progressFetchingMetadata(
                            currentProgress,
                            totalTracks,
                          )
                        : context.l10n.progressReadingCsv,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final tracks = await CsvImportService.pickAndParseCsv(
      onProgress: (current, total) {
        currentProgress = current;
        totalTracks = total;
        if (!dialogShown && total > 0) {
          showProgressDialog();
        }
        setDialogState?.call(() {});
      },
    );

    if (dialogShown && mounted) {
      Navigator.of(this.context).pop();
    }

    if (tracks.isNotEmpty) {
      final settings = ref.read(settingsProvider);

      if (!mounted) return;

      // ignore: use_build_context_synchronously
      final l10n = context.l10n;

      final options = await showDialog<_CsvImportOptions>(
        context: this.context,
        builder: (dialogCtx) {
          var skipDownloaded = true;
          return StatefulBuilder(
            builder: (dialogCtx, setDialogState) => AlertDialog(
              title: Text(l10n.dialogImportPlaylistTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.dialogImportPlaylistMessage(tracks.length)),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Skip already downloaded songs'),
                    value: skipDownloaded,
                    onChanged: (value) {
                      setDialogState(() {
                        skipDownloaded = value ?? true;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    dialogCtx,
                    const _CsvImportOptions(
                      confirmed: false,
                      skipDownloaded: true,
                    ),
                  ),
                  child: Text(l10n.dialogCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    dialogCtx,
                    _CsvImportOptions(
                      confirmed: true,
                      skipDownloaded: skipDownloaded,
                    ),
                  ),
                  child: Text(l10n.dialogImport),
                ),
              ],
            ),
          );
        },
      );

      if (options == null || !options.confirmed) return;

      var tracksToQueue = tracks;
      var skippedDownloadedCount = 0;

      if (options.skipDownloaded) {
        final historyState = ref.read(downloadHistoryProvider);
        tracksToQueue = [];
        for (final track in tracks) {
          final isDownloaded =
              historyState.isDownloaded(track.id) ||
              (track.isrc != null &&
                  historyState.getByIsrc(track.isrc!) != null);
          if (isDownloaded) {
            skippedDownloadedCount++;
            continue;
          }
          tracksToQueue.add(track);
        }
      }

      if (tracksToQueue.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.discographySkippedDownloaded(0, skippedDownloadedCount),
              ),
            ),
          );
        }
        return;
      }

      final queueSnackbarMessage = skippedDownloadedCount > 0
          ? l10n.discographySkippedDownloaded(
              tracksToQueue.length,
              skippedDownloadedCount,
            )
          : l10n.snackbarAddedTracksToQueue(tracksToQueue.length);

      if (!mounted) return;

      if (settings.askQualityBeforeDownload) {
        DownloadServicePicker.show(
          this.context,
          trackName: l10n.csvImportTracks(tracksToQueue.length),
          artistName: l10n.dialogImportPlaylistTitle,
          onSelect: (quality, service) {
            ref
                .read(downloadQueueProvider.notifier)
                .addMultipleToQueue(
                  tracksToQueue,
                  service,
                  qualityOverride: quality,
                );
            if (mounted) {
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(queueSnackbarMessage),
                  action: SnackBarAction(
                    label: l10n.snackbarViewQueue,
                    onPressed: () {},
                  ),
                ),
              );
            }
          },
        );
      } else {
        ref
            .read(downloadQueueProvider.notifier)
            .addMultipleToQueue(tracksToQueue, settings.defaultService);
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(queueSnackbarMessage),
              action: SnackBarAction(
                label: l10n.snackbarViewQueue,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final tracks = ref.watch(trackProvider.select((s) => s.tracks));
    final searchArtists = ref.watch(
      trackProvider.select((s) => s.searchArtists),
    );
    final searchAlbums = ref.watch(trackProvider.select((s) => s.searchAlbums));
    final searchPlaylists = ref.watch(
      trackProvider.select((s) => s.searchPlaylists),
    );
    final isLoading = ref.watch(trackProvider.select((s) => s.isLoading));
    final error = ref.watch(trackProvider.select((s) => s.error));
    final hasSearchedBefore = ref.watch(
      settingsProvider.select((s) => s.hasSearchedBefore),
    );

    final exploreSections = ref.watch(
      exploreProvider.select((s) => s.sections),
    );
    final exploreGreeting = ref.watch(
      exploreProvider.select((s) => s.greeting),
    );
    final exploreLoading = ref.watch(
      exploreProvider.select((s) => s.isLoading),
    );
    final hasHomeFeedExtension = ref.watch(
      extensionProvider.select(
        (s) => s.extensions.any((e) => e.enabled && e.hasHomeFeed),
      ),
    );

    final colorScheme = Theme.of(context).colorScheme;
    final hasActualResults =
        tracks.isNotEmpty ||
        (searchArtists != null && searchArtists.isNotEmpty) ||
        (searchAlbums != null && searchAlbums.isNotEmpty) ||
        (searchPlaylists != null && searchPlaylists.isNotEmpty);
    final searchText = _urlController.text.trim();
    final hasSearchInput = searchText.isNotEmpty;
    final isSearchFocused = _searchFocusNode.hasFocus;
    final hasShortSearchInput =
        hasSearchInput && searchText.length < _minLiveSearchChars;
    final isShowingRecentAccess = ref.watch(
      trackProvider.select((s) => s.isShowingRecentAccess),
    );
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = normalizedHeaderTopPadding(context);
    final historyItems = ref.watch(
      downloadHistoryProvider.select((s) => s.items),
    );
    final recentAccessItems = ref.watch(
      recentAccessProvider.select((s) => s.items),
    );
    final hiddenDownloadIds = ref.watch(
      recentAccessProvider.select((s) => s.hiddenDownloadIds),
    );

    final recentModeRequested = isShowingRecentAccess || isSearchFocused;
    final showRecentAccess =
        recentModeRequested &&
        (!hasSearchInput || hasShortSearchInput || !hasActualResults) &&
        !isLoading;
    final hasResults =
        hasSearchInput || hasActualResults || isLoading || showRecentAccess;
    final recentAccessView = showRecentAccess
        ? _getRecentAccessView(
            recentAccessItems,
            historyItems,
            hiddenDownloadIds,
          )
        : null;

    final hasExploreContent = exploreSections.isNotEmpty;
    final showExplore =
        !hasActualResults &&
        !isLoading &&
        !showRecentAccess &&
        (hasHomeFeedExtension || hasExploreContent) &&
        hasExploreContent;

    // Get current search extension and its filters
    final currentSearchProvider = ref.watch(
      settingsProvider.select((s) => s.searchProvider),
    );
    final extensions = ref.watch(extensionProvider.select((s) => s.extensions));
    final selectedSearchFilter = ref.watch(
      trackProvider.select((s) => s.selectedSearchFilter),
    );
    final searchExtensionId = ref.watch(
      trackProvider.select((s) => s.searchExtensionId),
    );
    final localLibrarySettings = ref.watch(
      settingsProvider.select(
        (s) => (s.localLibraryEnabled, s.localLibraryShowDuplicates),
      ),
    );
    final showLocalLibraryIndicator =
        localLibrarySettings.$1 && localLibrarySettings.$2;
    final thumbnailSizesByExtensionId = _getThumbnailSizesByExtensionId(
      extensions,
    );
    Extension? currentSearchExtension;
    List<SearchFilter> searchFilters = [];

    final isUsingExtensionSearch =
        currentSearchProvider != null &&
        currentSearchProvider.isNotEmpty &&
        extensions.any((e) => e.id == currentSearchProvider && e.enabled);

    if (isUsingExtensionSearch) {
      currentSearchExtension = extensions
          .where((e) => e.id == currentSearchProvider && e.enabled)
          .firstOrNull;
      if (currentSearchExtension?.searchBehavior?.filters.isNotEmpty == true) {
        searchFilters = currentSearchExtension!.searchBehavior!.filters;
      }
    } else {
      // Default Deezer filters
      searchFilters = const [
        SearchFilter(id: 'track', label: 'Tracks', icon: 'music'),
        SearchFilter(id: 'artist', label: 'Artists', icon: 'artist'),
        SearchFilter(id: 'album', label: 'Albums', icon: 'album'),
        SearchFilter(id: 'playlist', label: 'Playlists', icon: 'playlist'),
      ];
    }

    if (hasActualResults &&
        isShowingRecentAccess &&
        hasSearchInput &&
        !isSearchFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(trackProvider.notifier).setShowingRecentAccess(false);
        }
      });
    }

    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => ref.read(exploreProvider.notifier).refresh(),
          notificationPredicate: (notification) => showExplore,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverAppBar(
                expandedHeight: 120 + topPadding,
                collapsedHeight: kToolbarHeight,
                floating: false,
                pinned: true,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = 120 + topPadding;
                    final minHeight = kToolbarHeight + topPadding;
                    final expandRatio =
                        ((constraints.maxHeight - minHeight) /
                                (maxHeight - minHeight))
                            .clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      expandedTitleScale: 1.0,
                      titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                      title: Text(
                        context.l10n.homeTitle,
                        style: TextStyle(
                          fontSize: 20 + (14 * expandRatio), // 20 -> 34
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: (hasResults || showExplore)
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            SizedBox(height: screenHeight * 0.06),
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/images/logo-transparant.png',
                                color: colorScheme.onPrimary,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'SpotiFLAC',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.homeSubtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    (hasResults || showExplore) ? 8 : 32,
                    16,
                    (hasResults || showExplore) ? 8 : 16,
                  ),
                  child: _buildSearchBar(colorScheme),
                ),
              ),

              // Search filter bar (only shown when has search results)
              if (searchFilters.isNotEmpty &&
                  hasActualResults &&
                  !showRecentAccess)
                SliverToBoxAdapter(
                  child: _buildSearchFilterBar(
                    searchFilters,
                    selectedSearchFilter,
                    colorScheme,
                  ),
                ),

              if (showRecentAccess)
                SliverToBoxAdapter(
                  child: _buildRecentAccess(recentAccessView!, colorScheme),
                ),

              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: (hasResults || showRecentAccess || showExplore)
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            if (!hasSearchedBefore)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  context.l10n.homeSupports,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            if (historyItems.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  32,
                                  24,
                                  24,
                                ),
                                child: _buildRecentDownloads(
                                  historyItems,
                                  colorScheme,
                                ),
                              ),
                          ],
                        ),
                ),
              ),

              if (showExplore)
                ..._buildExploreSections(
                  exploreSections,
                  exploreGreeting,
                  colorScheme,
                ),

              if (hasHomeFeedExtension &&
                  !hasActualResults &&
                  !isLoading &&
                  exploreLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              ..._buildSearchResults(
                tracks: tracks,
                searchArtists: searchArtists,
                searchAlbums: searchAlbums,
                searchPlaylists: searchPlaylists,
                isLoading: isLoading,
                error: error,
                colorScheme: colorScheme,
                hasResults: hasActualResults || isLoading,
                searchExtensionId: searchExtensionId,
                showLocalLibraryIndicator: showLocalLibraryIndicator,
                thumbnailSizesByExtensionId: thumbnailSizesByExtensionId,
              ),
            ],
          ),
        ), // Close RefreshIndicator
      ), // Close GestureDetector
    );
  }

  void _onEmbeddedCoverChanged() {
    if (!mounted || _embeddedCoverRefreshScheduled) return;
    _embeddedCoverRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _embeddedCoverRefreshScheduled = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildRecentDownloads(
    List<DownloadHistoryItem> items,
    ColorScheme colorScheme,
  ) {
    final itemCount = items.length < 10 ? items.length : 10;
    final coverSize = _recentDownloadCoverSize(context);
    final rowHeight = _recentDownloadsRowHeight(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            context.l10n.homeRecent,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: rowHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final item = items[index];
              final embeddedCoverPath = DownloadedEmbeddedCoverResolver.resolve(
                item.filePath,
                onChanged: _onEmbeddedCoverChanged,
              );
              return KeyedSubtree(
                key: ValueKey(item.id),
                child: GestureDetector(
                  onTap: () => _navigateToMetadataScreen(item),
                  child: Container(
                    width: coverSize,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: embeddedCoverPath != null
                              ? Image.file(
                                  File(embeddedCoverPath),
                                  width: coverSize,
                                  height: coverSize,
                                  fit: BoxFit.cover,
                                  cacheWidth: (coverSize * 2).round(),
                                  cacheHeight: (coverSize * 2).round(),
                                  errorBuilder: (_, _, _) => Container(
                                    width: coverSize,
                                    height: coverSize,
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.music_note,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 32,
                                    ),
                                  ),
                                )
                              : item.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: item.coverUrl!,
                                  width: coverSize,
                                  height: coverSize,
                                  fit: BoxFit.cover,
                                  memCacheWidth: (coverSize * 2).round(),
                                  memCacheHeight: (coverSize * 2).round(),
                                  cacheManager: CoverCacheManager.instance,
                                )
                              : Container(
                                  width: coverSize,
                                  height: coverSize,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.music_note,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 32,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.trackName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  _RecentAccessView _getRecentAccessView(
    List<RecentAccessItem> items,
    List<DownloadHistoryItem> historyItems,
    Set<String> hiddenIds,
  ) {
    final cached = _recentAccessViewCache;
    if (cached != null &&
        identical(historyItems, _recentAccessHistoryCache) &&
        identical(items, _recentAccessItemsCache) &&
        identical(hiddenIds, _recentAccessHiddenIdsCache)) {
      return cached;
    }

    final albumGroups = <String, _RecentAlbumAggregate>{};
    for (final h in historyItems) {
      final artistForKey = (h.albumArtist != null && h.albumArtist!.isNotEmpty)
          ? h.albumArtist!
          : h.artistName;
      final albumKey = '${h.albumName}|$artistForKey';
      final existing = albumGroups[albumKey];
      if (existing == null) {
        albumGroups[albumKey] = _RecentAlbumAggregate(count: 1, mostRecent: h);
      } else {
        existing.count++;
        if (h.downloadedAt.isAfter(existing.mostRecent.downloadedAt)) {
          existing.mostRecent = h;
        }
      }
    }

    final downloadIds = <String>[];
    final visibleDownloads = <RecentAccessItem>[];
    final downloadFilePathByRecentKey = <String, String>{};
    for (final aggregate in albumGroups.values) {
      final mostRecent = aggregate.mostRecent;
      final artistForKey =
          (mostRecent.albumArtist != null && mostRecent.albumArtist!.isNotEmpty)
          ? mostRecent.albumArtist!
          : mostRecent.artistName;

      final isSingleTrack = aggregate.count == 1;
      final recentId = isSingleTrack
          ? (mostRecent.spotifyId ?? mostRecent.id)
          : '${mostRecent.albumName}|$artistForKey';
      final recent = RecentAccessItem(
        id: recentId,
        name: isSingleTrack ? mostRecent.trackName : mostRecent.albumName,
        subtitle: isSingleTrack ? mostRecent.artistName : artistForKey,
        imageUrl: mostRecent.coverUrl,
        type: isSingleTrack ? RecentAccessType.track : RecentAccessType.album,
        accessedAt: mostRecent.downloadedAt,
        providerId: 'download',
      );

      downloadIds.add(recentId);
      downloadFilePathByRecentKey['${recent.type.name}:${recent.id}'] =
          mostRecent.filePath;
      if (!hiddenIds.contains(recentId)) {
        visibleDownloads.add(recent);
      }
    }

    visibleDownloads.sort((a, b) => b.accessedAt.compareTo(a.accessedAt));
    if (visibleDownloads.length > 10) {
      visibleDownloads.removeRange(10, visibleDownloads.length);
    }

    final allItems = <RecentAccessItem>[...items, ...visibleDownloads];
    allItems.sort((a, b) => b.accessedAt.compareTo(a.accessedAt));

    final seen = <String>{};
    final uniqueItems = <RecentAccessItem>[];
    for (final item in allItems) {
      final key = '${item.type.name}:${item.id}';
      if (seen.add(key)) {
        uniqueItems.add(item);
        if (uniqueItems.length >= 10) {
          break;
        }
      }
    }

    final view = _RecentAccessView(
      uniqueItems: uniqueItems,
      downloadIds: downloadIds,
      downloadFilePathByRecentKey: downloadFilePathByRecentKey,
      hasHiddenDownloads: hiddenIds.isNotEmpty,
    );

    _recentAccessHistoryCache = historyItems;
    _recentAccessItemsCache = items;
    _recentAccessHiddenIdsCache = hiddenIds;
    _recentAccessViewCache = view;

    return view;
  }

  List<Widget> _buildExploreSections(
    List<ExploreSection> sections,
    String? greeting,
    ColorScheme colorScheme,
  ) {
    final hasGreeting = greeting != null && greeting.isNotEmpty;
    final sectionOffset = hasGreeting ? 1 : 0;
    final totalCount = sections.length + sectionOffset + 1; // + bottom padding

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (hasGreeting && index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                greeting,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final sectionIndex = index - sectionOffset;
          if (sectionIndex < sections.length) {
            return _buildExploreSection(sections[sectionIndex], colorScheme);
          }

          // Bottom padding
          return const SizedBox(height: 16);
        }, childCount: totalCount),
      ),
    ];
  }

  Widget _buildExploreSection(ExploreSection section, ColorScheme colorScheme) {
    final sectionHeight = _exploreSectionHeight(context);
    if (section.isYTMusicQuickPicks) {
      return _buildYTMusicQuickPicksSection(section, colorScheme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            section.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: sectionHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: section.items.length,
            itemBuilder: (context, index) {
              final item = section.items[index];
              return _buildExploreItem(item, colorScheme);
            },
          ),
        ),
      ],
    );
  }

  /// Build YT Music "Quick picks" style swipeable pages section
  Widget _buildYTMusicQuickPicksSection(
    ExploreSection section,
    ColorScheme colorScheme,
  ) {
    const itemsPerPage = 5;
    final totalPages = (section.items.length / itemsPerPage).ceil();

    return _QuickPicksPageView(
      section: section,
      colorScheme: colorScheme,
      itemsPerPage: itemsPerPage,
      totalPages: totalPages,
      onItemTap: _navigateToExploreItem,
      onItemMenu: _showTrackBottomSheet,
    );
  }

  Widget _buildExploreItem(ExploreItem item, ColorScheme colorScheme) {
    final isArtist = item.type == 'artist';
    final cardSize = _exploreCardSize(context);
    final iconSize = cardSize * 0.3;

    return GestureDetector(
      onTap: () => _navigateToExploreItem(item),
      child: SizedBox(
        width: cardSize,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: isArtist
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  isArtist ? cardSize / 2 : 8,
                ),
                child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.coverUrl!,
                        width: cardSize,
                        height: cardSize,
                        fit: BoxFit.cover,
                        memCacheWidth: (cardSize * 2).round(),
                        memCacheHeight: (cardSize * 2).round(),
                        cacheManager: CoverCacheManager.instance,
                        errorWidget: (context, url, error) => Container(
                          width: cardSize,
                          height: cardSize,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            _getIconForType(item.type),
                            color: colorScheme.onSurfaceVariant,
                            size: iconSize,
                          ),
                        ),
                      )
                    : Container(
                        width: cardSize,
                        height: cardSize,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          _getIconForType(item.type),
                          color: colorScheme.onSurfaceVariant,
                          size: iconSize,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: isArtist ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              if (item.artists.isNotEmpty && !isArtist)
                Text(
                  item.artists,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'track':
        return Icons.music_note;
      case 'album':
        return Icons.album;
      case 'playlist':
        return Icons.playlist_play;
      case 'artist':
        return Icons.person;
      case 'station':
        return Icons.radio;
      default:
        return Icons.music_note;
    }
  }

  void _navigateToExploreItem(ExploreItem item) async {
    final extensionId = item.providerId ?? 'spotify-web';

    switch (item.type) {
      case 'track':
        _showTrackBottomSheet(item);
        return;
      case 'album':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExtensionAlbumScreen(
              extensionId: extensionId,
              albumId: item.id,
              albumName: item.name,
              coverUrl: item.coverUrl,
            ),
          ),
        );
        return;
      case 'playlist':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExtensionPlaylistScreen(
              extensionId: extensionId,
              playlistId: item.id,
              playlistName: item.name,
              coverUrl: item.coverUrl,
            ),
          ),
        );
        return;
      case 'artist':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExtensionArtistScreen(
              extensionId: extensionId,
              artistId: item.id,
              artistName: item.name,
              coverUrl: item.coverUrl,
            ),
          ),
        );
        return;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${item.type}: ${item.name}')));
        return;
    }
  }

  void _showTrackBottomSheet(ExploreItem item) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.coverUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            memCacheWidth: 128,
                            cacheManager: CoverCacheManager.instance,
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.music_note,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.artists,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.download, color: colorScheme.primary),
              title: Text(context.l10n.downloadTitle),
              onTap: () {
                Navigator.pop(context);
                _downloadExploreTrack(item);
              },
            ),
            ListTile(
              leading: Icon(Icons.album, color: colorScheme.onSurfaceVariant),
              title: const Text('Go to Album'),
              onTap: () {
                Navigator.pop(context);
                _navigateToTrackAlbum(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadExploreTrack(ExploreItem item) async {
    final settings = ref.read(settingsProvider);

    final track = Track(
      id: item.id,
      name: item.name,
      artistName: item.artists,
      albumName: item.albumName ?? '',
      duration: item.durationMs ~/ 1000,
      trackNumber: 1,
      discNumber: 1,
      isrc: null,
      releaseDate: null,
      coverUrl: item.coverUrl,
      source: item.providerId ?? 'spotify-web',
    );

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

  Future<void> _navigateToTrackAlbum(ExploreItem item) async {
    if (item.albumId != null && item.albumId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExtensionAlbumScreen(
            extensionId: item.providerId ?? 'spotify-web',
            albumId: item.albumId!,
            albumName: item.albumName ?? 'Album',
            coverUrl: item.coverUrl,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Album info not available')));
    }
  }

  Widget _buildRecentAccess(_RecentAccessView view, ColorScheme colorScheme) {
    final uniqueItems = view.uniqueItems;
    final downloadIds = view.downloadIds;
    final hasHiddenDownloads = view.hasHiddenDownloads;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.homeRecent,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (uniqueItems.isNotEmpty)
                TextButton(
                  onPressed: () {
                    for (final id in downloadIds) {
                      ref
                          .read(recentAccessProvider.notifier)
                          .hideDownloadFromRecents(id);
                    }
                    ref.read(recentAccessProvider.notifier).clearHistory();
                  },
                  child: Text(
                    context.l10n.dialogClearAll,
                    style: TextStyle(color: colorScheme.primary, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (uniqueItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      hasHiddenDownloads ? Icons.visibility_off : Icons.history,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.recentEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (hasHiddenDownloads) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(recentAccessProvider.notifier)
                              .clearHiddenDownloads();
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: Text(context.l10n.recentShowAllDownloads),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ...uniqueItems.map(
              (item) => _buildRecentAccessItem(
                item,
                colorScheme,
                view.downloadFilePathByRecentKey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentAccessItem(
    RecentAccessItem item,
    ColorScheme colorScheme,
    Map<String, String> downloadFilePathByRecentKey,
  ) {
    IconData typeIcon;
    String typeLabel;
    final isDownloaded = item.providerId == 'download';
    final embeddedCoverPath = isDownloaded
        ? DownloadedEmbeddedCoverResolver.resolve(
            downloadFilePathByRecentKey['${item.type.name}:${item.id}'],
            onChanged: _onEmbeddedCoverChanged,
          )
        : null;

    switch (item.type) {
      case RecentAccessType.artist:
        typeIcon = Icons.person;
        typeLabel = context.l10n.recentTypeArtist;
      case RecentAccessType.album:
        typeIcon = Icons.album;
        typeLabel = context.l10n.recentTypeAlbum;
      case RecentAccessType.track:
        typeIcon = Icons.music_note;
        typeLabel = context.l10n.recentTypeSong;
      case RecentAccessType.playlist:
        typeIcon = Icons.playlist_play;
        typeLabel = context.l10n.recentTypePlaylist;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _navigateToRecentItem(item),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  item.type == RecentAccessType.artist ? 28 : 4,
                ),
                child: embeddedCoverPath != null
                    ? Image.file(
                        File(embeddedCoverPath),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        cacheWidth: 112,
                        cacheHeight: 112,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 56,
                          height: 56,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            typeIcon,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        memCacheWidth: 112,
                        cacheManager: CoverCacheManager.instance,
                        errorWidget: (context, url, error) => Container(
                          width: 56,
                          height: 56,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            typeIcon,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          typeIcon,
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
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDownloaded
                          ? (item.subtitle != null
                                ? '${context.l10n.recentTypeSong} • ${item.subtitle}'
                                : context.l10n.recentTypeSong)
                          : (item.subtitle != null
                                ? '$typeLabel • ${item.subtitle}'
                                : typeLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDownloaded
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  if (item.providerId == 'download') {
                    ref
                        .read(recentAccessProvider.notifier)
                        .hideDownloadFromRecents(item.id);
                  } else {
                    ref.read(recentAccessProvider.notifier).removeItem(item);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRecentItem(RecentAccessItem item) {
    _searchFocusNode.unfocus();

    switch (item.type) {
      case RecentAccessType.artist:
        if (item.providerId != null &&
            item.providerId!.isNotEmpty &&
            item.providerId != 'deezer' &&
            item.providerId != 'spotify') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExtensionArtistScreen(
                extensionId: item.providerId!,
                artistId: item.id,
                artistName: item.name,
                coverUrl: item.imageUrl,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistScreen(
                artistId: item.id,
                artistName: item.name,
                coverUrl: item.imageUrl,
              ),
            ),
          );
        }
      case RecentAccessType.album:
        if (item.providerId == 'download') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DownloadedAlbumScreen(
                albumName: item.name,
                artistName: item.subtitle ?? '',
                coverUrl: item.imageUrl,
              ),
            ),
          );
        } else if (item.providerId != null &&
            item.providerId!.isNotEmpty &&
            item.providerId != 'deezer' &&
            item.providerId != 'spotify') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExtensionAlbumScreen(
                extensionId: item.providerId!,
                albumId: item.id,
                albumName: item.name,
                coverUrl: item.imageUrl,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlbumScreen(
                albumId: item.id,
                albumName: item.name,
                coverUrl: item.imageUrl,
              ),
            ),
          );
        }
      case RecentAccessType.track:
        final historyItem = ref
            .read(downloadHistoryProvider.notifier)
            .getBySpotifyId(item.id);
        if (historyItem != null) {
          _navigateToMetadataScreen(historyItem);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(item.name)));
        }
      case RecentAccessType.playlist:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.recentPlaylistInfo(item.name))),
        );
    }
  }

  Future<void> _navigateToMetadataScreen(DownloadHistoryItem item) async {
    final navigator = Navigator.of(context);
    _precacheCover(item.coverUrl);
    final beforeModTime =
        await DownloadedEmbeddedCoverResolver.readFileModTimeMillis(
          item.filePath,
        );
    if (!mounted) return;
    final result = await navigator.push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            TrackMetadataScreen(item: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    await DownloadedEmbeddedCoverResolver.scheduleRefreshForPath(
      item.filePath,
      beforeModTime: beforeModTime,
      force: result == true,
      onChanged: _onEmbeddedCoverChanged,
    );
  }

  void _precacheCover(String? url) {
    if (url == null || url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return;
    }
    final dpr = MediaQuery.devicePixelRatioOf(
      context,
    ).clamp(1.0, 3.0).toDouble();
    final targetSize = (360 * dpr).round().clamp(512, 1024).toInt();
    precacheImage(
      ResizeImage(
        CachedNetworkImageProvider(
          url,
          cacheManager: CoverCacheManager.instance,
        ),
        width: targetSize,
        height: targetSize,
      ),
      context,
    );
  }

  Widget _buildErrorWidget(String error, ColorScheme colorScheme) {
    final isRateLimit =
        error.contains('429') ||
        error.toLowerCase().contains('rate limit') ||
        error.toLowerCase().contains('too many requests');

    if (isRateLimit) {
      return Card(
        elevation: 0,
        color: colorScheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.timer_off, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate Limited',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Too many requests. Please wait a moment before searching again.',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: colorScheme.errorContainer.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(error, style: TextStyle(color: colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSearchResults({
    required List<Track> tracks,
    required List<SearchArtist>? searchArtists,
    required List<SearchAlbum>? searchAlbums,
    required List<SearchPlaylist>? searchPlaylists,
    required bool isLoading,
    required String? error,
    required ColorScheme colorScheme,
    required bool hasResults,
    required String? searchExtensionId,
    required bool showLocalLibraryIndicator,
    required Map<String, (double, double)> thumbnailSizesByExtensionId,
  }) {
    if (!hasResults) {
      return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }

    final realTracks = <Track>[];
    final realTrackIndexes = <int>[];
    final albumItems = <Track>[];
    final playlistItems = <Track>[];
    final artistItems = <Track>[];

    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      if (!track.isCollection) {
        realTracks.add(track);
        realTrackIndexes.add(i);
      }
      if (track.isAlbumItem) {
        albumItems.add(track);
      }
      if (track.isPlaylistItem) {
        playlistItems.add(track);
      }
      if (track.isArtistItem) {
        artistItems.add(track);
      }
    }

    final slivers = <Widget>[
      if (error != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildErrorWidget(error, colorScheme),
          ),
        ),
      if (isLoading)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(),
          ),
        ),
    ];

    if (searchArtists != null && searchArtists.isNotEmpty) {
      slivers.addAll(
        _buildVirtualizedResultSection(
          title: context.l10n.searchArtists,
          itemCount: searchArtists.length,
          colorScheme: colorScheme,
          itemBuilder: (index, showDivider) => _SearchArtistItemWidget(
            key: ValueKey('search-artist-${searchArtists[index].id}'),
            artist: searchArtists[index],
            showDivider: showDivider,
            onTap: () => _navigateToArtist(
              searchArtists[index].id,
              searchArtists[index].name,
              searchArtists[index].imageUrl,
            ),
          ),
        ),
      );
    }

    if (artistItems.isNotEmpty) {
      slivers.addAll(
        _buildVirtualizedResultSection(
          title: context.l10n.searchArtists,
          itemCount: artistItems.length,
          colorScheme: colorScheme,
          itemBuilder: (index, showDivider) => _CollectionItemWidget(
            key: ValueKey('artist-${artistItems[index].id}'),
            item: artistItems[index],
            showDivider: showDivider,
            onTap: () => _navigateToExtensionArtist(artistItems[index]),
          ),
        ),
      );
    }

    if (searchAlbums != null && searchAlbums.isNotEmpty) {
      slivers.addAll(
        _buildVirtualizedResultSection(
          title: context.l10n.searchAlbums,
          itemCount: searchAlbums.length,
          colorScheme: colorScheme,
          itemBuilder: (index, showDivider) => _SearchAlbumItemWidget(
            key: ValueKey('search-album-${searchAlbums[index].id}'),
            album: searchAlbums[index],
            showDivider: showDivider,
            onTap: () => _navigateToSearchAlbum(searchAlbums[index]),
          ),
        ),
      );
    }

    if (albumItems.isNotEmpty) {
      slivers.addAll(
        _buildVirtualizedResultSection(
          title: context.l10n.searchAlbums,
          itemCount: albumItems.length,
          colorScheme: colorScheme,
          itemBuilder: (index, showDivider) => _CollectionItemWidget(
            key: ValueKey('album-${albumItems[index].id}'),
            item: albumItems[index],
            showDivider: showDivider,
            onTap: () => _navigateToExtensionAlbum(albumItems[index]),
          ),
        ),
      );
    }

    if (searchPlaylists != null && searchPlaylists.isNotEmpty) {
      slivers.addAll(
        _buildVirtualizedResultSection(
          title: context.l10n.searchPlaylists,
          itemCount: searchPlaylists.length,
          colorScheme: colorScheme,
          itemBuilder: (index, showDivider) => _SearchPlaylistItemWidget(
            key: ValueKey('search-playlist-${searchPlaylists[index].id}'),
            playlist: searchPlaylists[index],
            showDivider: showDivider,
            onTap: () => _navigateToSearchPlaylist(searchPlaylists[index]),
          ),
        ),
      );
    }

    if (playlistItems.isNotEmpty) {
      slivers.addAll(
        _buildVirtualizedResultSection(
          title: context.l10n.searchPlaylists,
          itemCount: playlistItems.length,
          colorScheme: colorScheme,
          itemBuilder: (index, showDivider) => _CollectionItemWidget(
            key: ValueKey('playlist-${playlistItems[index].id}'),
            item: playlistItems[index],
            showDivider: showDivider,
            onTap: () => _navigateToExtensionPlaylist(playlistItems[index]),
          ),
        ),
      );
    }

    if (realTracks.isNotEmpty) {
      slivers.addAll(
        _buildVirtualizedResultSection(
          title: context.l10n.searchSongs,
          itemCount: realTracks.length,
          colorScheme: colorScheme,
          itemBuilder: (index, showDivider) => _TrackItemWithStatus(
            key: ValueKey(realTracks[index].id),
            track: realTracks[index],
            index: realTrackIndexes[index],
            showDivider: showDivider,
            onDownload: () => _downloadTrack(realTrackIndexes[index]),
            searchExtensionId: searchExtensionId,
            showLocalLibraryIndicator: showLocalLibraryIndicator,
            thumbnailSizesByExtensionId: thumbnailSizesByExtensionId,
          ),
        ),
      );
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
    return slivers;
  }

  List<Widget> _buildVirtualizedResultSection({
    required String title,
    required int itemCount,
    required ColorScheme colorScheme,
    required Widget Function(int index, bool showDivider) itemBuilder,
  }) {
    final sectionColor = Theme.of(context).brightness == Brightness.dark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.08),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHighest;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final isFirst = index == 0;
          final isLast = index == itemCount - 1;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: sectionColor,
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(20) : Radius.zero,
                bottom: isLast ? const Radius.circular(20) : Radius.zero,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: itemBuilder(index, !isLast),
            ),
          );
        }, childCount: itemCount),
      ),
    ];
  }

  void _navigateToArtist(String artistId, String artistName, String? imageUrl) {
    ref.read(settingsProvider.notifier).setHasSearchedBefore();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistScreen(
          artistId: artistId,
          artistName: artistName,
          coverUrl: imageUrl,
        ),
      ),
    );
  }

  void _navigateToSearchAlbum(SearchAlbum album) {
    ref.read(settingsProvider.notifier).setHasSearchedBefore();

    ref
        .read(recentAccessProvider.notifier)
        .recordAlbumAccess(
          id: album.id,
          name: album.name,
          artistName: album.artists,
          imageUrl: album.imageUrl,
          providerId: 'deezer',
        );

    // Keep the full ID with prefix (e.g., "deezer:123") for AlbumScreen to detect source
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumScreen(
          albumId: album.id,
          albumName: album.name,
          coverUrl: album.imageUrl,
          tracks: const [], // Will be fetched by AlbumScreen
        ),
      ),
    );
  }

  void _navigateToSearchPlaylist(SearchPlaylist playlist) {
    ref.read(settingsProvider.notifier).setHasSearchedBefore();

    ref
        .read(recentAccessProvider.notifier)
        .recordPlaylistAccess(
          id: playlist.id,
          name: playlist.name,
          ownerName: playlist.owner,
          imageUrl: playlist.imageUrl,
          providerId: 'deezer',
        );

    // Keep the full ID with prefix (e.g., "deezer:123") for PlaylistScreen to detect source
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistScreen(
          playlistName: playlist.name,
          coverUrl: playlist.imageUrl,
          tracks: const [], // Will be fetched
          playlistId: playlist.id,
        ),
      ),
    );
  }

  void _navigateToExtensionAlbum(Track albumItem) async {
    final extensionId = albumItem.source;
    if (extensionId == null || extensionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorMissingExtensionSource('album')),
        ),
      );
      return;
    }

    ref.read(settingsProvider.notifier).setHasSearchedBefore();

    ref
        .read(recentAccessProvider.notifier)
        .recordAlbumAccess(
          id: albumItem.id,
          name: albumItem.name,
          artistName: albumItem.artistName,
          imageUrl: albumItem.coverUrl,
          providerId: extensionId,
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExtensionAlbumScreen(
          extensionId: extensionId,
          albumId: albumItem.id,
          albumName: albumItem.name,
          coverUrl: albumItem.coverUrl,
        ),
      ),
    );
  }

  void _navigateToExtensionPlaylist(Track playlistItem) async {
    final extensionId = playlistItem.source;
    if (extensionId == null || extensionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorMissingExtensionSource('playlist')),
        ),
      );
      return;
    }

    ref.read(settingsProvider.notifier).setHasSearchedBefore();

    ref
        .read(recentAccessProvider.notifier)
        .recordPlaylistAccess(
          id: playlistItem.id,
          name: playlistItem.name,
          ownerName: playlistItem.artistName,
          imageUrl: playlistItem.coverUrl,
          providerId: extensionId,
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExtensionPlaylistScreen(
          extensionId: extensionId,
          playlistId: playlistItem.id,
          playlistName: playlistItem.name,
          coverUrl: playlistItem.coverUrl,
        ),
      ),
    );
  }

  void _navigateToExtensionArtist(Track artistItem) {
    final extensionId = artistItem.source;
    if (extensionId == null || extensionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorMissingExtensionSource('artist')),
        ),
      );
      return;
    }

    ref.read(settingsProvider.notifier).setHasSearchedBefore();

    ref
        .read(recentAccessProvider.notifier)
        .recordArtistAccess(
          id: artistItem.id,
          name: artistItem.name,
          imageUrl: artistItem.coverUrl,
          providerId: extensionId,
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExtensionArtistScreen(
          extensionId: extensionId,
          artistId: artistItem.id,
          artistName: artistItem.name,
          coverUrl: artistItem.coverUrl,
        ),
      ),
    );
  }

  String _getSearchHint() {
    final settings = ref.read(settingsProvider);
    final searchProvider = settings.searchProvider;
    final extState = ref.read(extensionProvider);

    if (!extState.isInitialized) {
      return 'Paste Spotify URL or search...';
    }

    if (searchProvider != null && searchProvider.isNotEmpty) {
      final ext = extState.extensions
          .where((e) => e.id == searchProvider)
          .firstOrNull;
      if (ext != null && ext.enabled) {
        if (ext.searchBehavior?.placeholder != null) {
          return ext.searchBehavior!.placeholder!;
        }
        return 'Search with ${ext.displayName}...';
      }
    }
    return 'Paste Spotify URL or search...';
  }

  Widget _buildSearchFilterBar(
    List<SearchFilter> filters,
    String? selectedFilter,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "All" chip (no filter)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: selectedFilter == null,
                onSelected: (_) {
                  ref.read(trackProvider.notifier).setSearchFilter(null);
                  _triggerSearchWithFilter(null);
                },
                showCheckmark: false,
                selectedColor: colorScheme.primaryContainer,
                backgroundColor: colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: selectedFilter == null
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: selectedFilter == null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            // Filter chips from extension
            ...filters.map((filter) {
              final isSelected = selectedFilter == filter.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.label ?? filter.id),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(trackProvider.notifier).setSearchFilter(filter.id);
                    _triggerSearchWithFilter(filter.id);
                  },
                  showCheckmark: false,
                  selectedColor: colorScheme.primaryContainer,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  avatar: filter.icon != null
                      ? Icon(
                          _getFilterIcon(filter.icon!),
                          size: 18,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getFilterIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'music':
      case 'track':
      case 'song':
        return Icons.music_note;
      case 'album':
        return Icons.album;
      case 'artist':
        return Icons.person;
      case 'playlist':
        return Icons.playlist_play;
      case 'video':
        return Icons.video_library;
      case 'podcast':
        return Icons.podcasts;
      default:
        return Icons.search;
    }
  }

  void _triggerSearchWithFilter(String? filter) {
    final text = _urlController.text.trim();
    if (text.isEmpty || text.length < _minLiveSearchChars) return;
    if (text.startsWith('http') || text.startsWith('spotify:')) return;

    // Reset last search query to force new search
    _lastSearchQuery = null;
    _performSearch(text, filterOverride: filter);
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    final hasText = _urlController.text.isNotEmpty;

    return TextField(
      controller: _urlController,
      focusNode: _searchFocusNode,
      autofocus: false,
      decoration: InputDecoration(
        hintText: _getSearchHint(),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        prefixIcon: _SearchProviderDropdown(
          onProviderChanged: () {
            _lastSearchQuery = null;
            // Reset filter when provider changes
            ref.read(trackProvider.notifier).setSearchFilter(null);
            setState(() {});
            final text = _urlController.text.trim();
            if (text.isNotEmpty && text.length >= _minLiveSearchChars) {
              _performSearch(text);
            }
          },
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasText)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearAndRefresh,
                tooltip: 'Clear',
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.file_upload_outlined),
                onPressed: () => _importCsv(context, ref),
                tooltip: 'Import CSV',
              ),
              IconButton(
                icon: const Icon(Icons.paste),
                onPressed: _pasteFromClipboard,
                tooltip: 'Paste',
              ),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      onSubmitted: (_) => _onSearchSubmitted(),
    );
  }

  void _onSearchSubmitted() {
    _liveSearchDebounce?.cancel();
    _pendingLiveSearchQuery = null;

    final text = _urlController.text.trim();
    if (text.isEmpty) return;

    if (text.startsWith('http') || text.startsWith('spotify:')) {
      _fetchMetadata();
      _searchFocusNode.unfocus();
      return;
    }

    if (text.length >= 2) {
      _performSearch(text);
    }
    _searchFocusNode.unfocus();
  }
}

/// Dropdown widget for quick search provider switching
class _SearchProviderDropdown extends ConsumerWidget {
  final VoidCallback? onProviderChanged;

  const _SearchProviderDropdown({this.onProviderChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProvider = ref.watch(
      settingsProvider.select((s) => s.searchProvider),
    );
    final metadataSource = ref.watch(
      settingsProvider.select((s) => s.metadataSource),
    );
    final extensions = ref.watch(extensionProvider.select((s) => s.extensions));
    final colorScheme = Theme.of(context).colorScheme;

    final searchProviders = extensions
        .where((ext) => ext.enabled && ext.hasCustomSearch)
        .toList();

    Extension? currentExt;
    if (currentProvider != null && currentProvider.isNotEmpty) {
      currentExt = searchProviders
          .where((e) => e.id == currentProvider)
          .firstOrNull;
    }

    IconData displayIcon = Icons.search;
    String? iconPath;
    if (currentExt != null) {
      iconPath = currentExt.iconPath;
      if (currentExt.searchBehavior?.icon != null) {
        displayIcon = _getIconFromName(currentExt.searchBehavior!.icon!);
      }
    }

    if (searchProviders.isEmpty) {
      return const Icon(Icons.search);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: PopupMenuButton<String>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null && iconPath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(iconPath),
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => Icon(displayIcon, size: 20),
                ),
              )
            else
              Icon(displayIcon, size: 20),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        tooltip: 'Change search provider',
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (String providerId) {
          final provider = providerId.isEmpty ? null : providerId;
          ref.read(settingsProvider.notifier).setSearchProvider(provider);
          onProviderChanged?.call();
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: '',
            child: Row(
              children: [
                Icon(
                  Icons.music_note,
                  size: 20,
                  color: currentProvider == null || currentProvider.isEmpty
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    metadataSource == 'spotify' ? 'Spotify' : 'Deezer',
                    style: TextStyle(
                      fontWeight:
                          currentProvider == null || currentProvider.isEmpty
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (currentProvider == null || currentProvider.isEmpty)
                  Icon(Icons.check, size: 18, color: colorScheme.primary),
              ],
            ),
          ),
          if (searchProviders.isNotEmpty) const PopupMenuDivider(),
          ...searchProviders.map(
            (ext) => PopupMenuItem<String>(
              value: ext.id,
              child: Row(
                children: [
                  if (ext.iconPath != null && ext.iconPath!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(ext.iconPath!),
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) => Icon(
                          _getIconFromName(ext.searchBehavior?.icon),
                          size: 20,
                          color: currentProvider == ext.id
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Icon(
                      _getIconFromName(ext.searchBehavior?.icon),
                      size: 20,
                      color: currentProvider == ext.id
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ext.displayName,
                      style: TextStyle(
                        fontWeight: currentProvider == ext.id
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (currentProvider == ext.id)
                    Icon(Icons.check, size: 18, color: colorScheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromName(String? iconName) {
    switch (iconName) {
      case 'video':
      case 'movie':
        return Icons.video_library;
      case 'music':
        return Icons.music_note;
      case 'podcast':
        return Icons.podcasts;
      case 'book':
      case 'audiobook':
        return Icons.menu_book;
      case 'cloud':
        return Icons.cloud;
      case 'download':
        return Icons.download;
      default:
        return Icons.search;
    }
  }
}

class _TrackItemWithStatus extends ConsumerWidget {
  final Track track;
  final int index;
  final bool showDivider;
  final VoidCallback onDownload;
  final String? searchExtensionId;
  final bool showLocalLibraryIndicator;
  final Map<String, (double, double)> thumbnailSizesByExtensionId;

  const _TrackItemWithStatus({
    super.key,
    required this.track,
    required this.index,
    required this.showDivider,
    required this.onDownload,
    required this.searchExtensionId,
    required this.showLocalLibraryIndicator,
    required this.thumbnailSizesByExtensionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final queueItem = ref.watch(
      downloadQueueLookupProvider.select(
        (lookup) => lookup.byTrackId[track.id],
      ),
    );

    final isInHistory = ref.watch(
      downloadHistoryProvider.select((state) {
        return state.isDownloaded(track.id);
      }),
    );

    final isInLocalLibrary = showLocalLibraryIndicator
        ? ref.watch(
            localLibraryProvider.select(
              (state) => state.existsInLibrary(
                isrc: track.isrc,
                trackName: track.name,
                artistName: track.artistName,
              ),
            ),
          )
        : false;

    double thumbWidth = 56;
    double thumbHeight = 56;

    final extensionId = track.source ?? searchExtensionId;
    final thumbSize = extensionId == null
        ? null
        : thumbnailSizesByExtensionId[extensionId];
    if (thumbSize != null) {
      thumbWidth = thumbSize.$1;
      thumbHeight = thumbSize.$2;
    }

    final isQueued = queueItem != null;
    final isDownloading = queueItem?.status == DownloadStatus.downloading;
    final isFinalizing = queueItem?.status == DownloadStatus.finalizing;
    final isCompleted = queueItem?.status == DownloadStatus.completed;
    final progress = queueItem?.progress ?? 0.0;

    final showAsDownloaded =
        isCompleted || (!isQueued && isInHistory) || isInLocalLibrary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _handleTap(
            context,
            ref,
            isQueued: isQueued,
            isInHistory: isInHistory,
            isInLocalLibrary: isInLocalLibrary,
          ),
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: track.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: track.coverUrl!,
                          width: thumbWidth,
                          height: thumbHeight,
                          fit: BoxFit.cover,
                          memCacheWidth: (thumbWidth * 2).toInt(),
                          memCacheHeight: (thumbHeight * 2).toInt(),
                          cacheManager: CoverCacheManager.instance,
                        )
                      : Container(
                          width: thumbWidth,
                          height: thumbHeight,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              track.artistName,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isInLocalLibrary) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 10,
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    context.l10n.libraryInLibrary,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildDownloadButton(
                  context,
                  ref,
                  colorScheme,
                  isQueued: isQueued,
                  isDownloading: isDownloading,
                  isFinalizing: isFinalizing,
                  showAsDownloaded: showAsDownloaded,
                  isInHistory: isInHistory,
                  isInLocalLibrary: isInLocalLibrary,
                  progress: progress,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent:
                thumbWidth +
                24, // Adjust divider indent based on thumbnail width
            endIndent: 12,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref, {
    required bool isQueued,
    required bool isInHistory,
    required bool isInLocalLibrary,
  }) async {
    if (isQueued) return;

    if (isInLocalLibrary) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.snackbarAlreadyInLibrary(track.name)),
          ),
        );
      }
      return;
    }

    if (isInHistory) {
      final historyItem = ref
          .read(downloadHistoryProvider.notifier)
          .getBySpotifyId(track.id);
      if (historyItem != null) {
        final exists = await fileExists(historyItem.filePath);
        if (exists) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.snackbarAlreadyDownloaded(track.name),
                ),
              ),
            );
          }
          return;
        } else {
          ref
              .read(downloadHistoryProvider.notifier)
              .removeBySpotifyId(track.id);
        }
      }
    }

    onDownload();
  }

  Widget _buildDownloadButton(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme, {
    required bool isQueued,
    required bool isDownloading,
    required bool isFinalizing,
    required bool showAsDownloaded,
    required bool isInHistory,
    required bool isInLocalLibrary,
    required double progress,
  }) {
    const double size = 44.0;
    const double iconSize = 20.0;

    if (showAsDownloaded) {
      return GestureDetector(
        onTap: () => _handleTap(
          context,
          ref,
          isQueued: isQueued,
          isInHistory: isInHistory,
          isInLocalLibrary: isInLocalLibrary,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: colorScheme.onPrimaryContainer,
            size: iconSize,
          ),
        ),
      );
    } else if (isFinalizing) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.tertiary,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            Icon(Icons.edit_note, color: colorScheme.tertiary, size: 16),
          ],
        ),
      );
    } else if (isDownloading) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 3,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            if (progress > 0)
              Text(
                '${(progress * 100).toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
      );
    } else if (isQueued) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.hourglass_empty,
          color: colorScheme.onSurfaceVariant,
          size: iconSize,
        ),
      );
    } else {
      return GestureDetector(
        onTap: onDownload,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.download,
            color: colorScheme.onSecondaryContainer,
            size: iconSize,
          ),
        ),
      );
    }
  }
}

/// Widget for displaying album/playlist items in search results
class _CollectionItemWidget extends StatelessWidget {
  final Track item;
  final bool showDivider;
  final VoidCallback onTap;

  const _CollectionItemWidget({
    super.key,
    required this.item,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPlaylist = item.isPlaylistItem;
    final isArtist = item.isArtistItem;

    IconData placeholderIcon = Icons.album;
    if (isPlaylist) placeholderIcon = Icons.playlist_play;
    if (isArtist) placeholderIcon = Icons.person;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isArtist ? 28 : 10),
                  child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.coverUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          memCacheWidth: 112,
                          memCacheHeight: 112,
                          cacheManager: CoverCacheManager.instance,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            placeholderIcon,
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
                        item.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.artistName.isNotEmpty
                            ? item.artistName
                            : (isPlaylist
                                  ? 'Playlist'
                                  : (isArtist ? 'Artist' : 'Album')),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 80,
            endIndent: 12,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

/// Widget for displaying artist items from default search (Deezer/Spotify)
class _SearchArtistItemWidget extends StatelessWidget {
  final SearchArtist artist;
  final bool showDivider;
  final VoidCallback onTap;

  const _SearchArtistItemWidget({
    super.key,
    required this.artist,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValidImage =
        artist.imageUrl != null &&
        artist.imageUrl!.isNotEmpty &&
        Uri.tryParse(artist.imageUrl!)?.hasAuthority == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: hasValidImage
                      ? CachedNetworkImage(
                          imageUrl: artist.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          memCacheWidth: 112,
                          memCacheHeight: 112,
                          cacheManager: CoverCacheManager.instance,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
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
                        artist.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Artist',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 80,
            endIndent: 12,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

/// Widget for displaying album items from default search (Deezer/Spotify)
class _SearchAlbumItemWidget extends StatelessWidget {
  final SearchAlbum album;
  final bool showDivider;
  final VoidCallback onTap;

  const _SearchAlbumItemWidget({
    super.key,
    required this.album,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValidImage =
        album.imageUrl != null &&
        album.imageUrl!.isNotEmpty &&
        Uri.tryParse(album.imageUrl!)?.hasAuthority == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasValidImage
                      ? CachedNetworkImage(
                          imageUrl: album.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          memCacheWidth: 112,
                          memCacheHeight: 112,
                          cacheManager: CoverCacheManager.instance,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.album,
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
                        album.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        album.artists.isNotEmpty ? album.artists : 'Album',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 80,
            endIndent: 12,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

/// Widget for displaying playlist items from default search (Deezer/Spotify)
class _SearchPlaylistItemWidget extends StatelessWidget {
  final SearchPlaylist playlist;
  final bool showDivider;
  final VoidCallback onTap;

  const _SearchPlaylistItemWidget({
    super.key,
    required this.playlist,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValidImage =
        playlist.imageUrl != null &&
        playlist.imageUrl!.isNotEmpty &&
        Uri.tryParse(playlist.imageUrl!)?.hasAuthority == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasValidImage
                      ? CachedNetworkImage(
                          imageUrl: playlist.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          memCacheWidth: 112,
                          memCacheHeight: 112,
                          cacheManager: CoverCacheManager.instance,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.playlist_play,
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
                        playlist.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        playlist.owner.isNotEmpty ? playlist.owner : 'Playlist',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 80,
            endIndent: 12,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

class ExtensionAlbumScreen extends ConsumerStatefulWidget {
  final String extensionId;
  final String albumId;
  final String albumName;
  final String? coverUrl;

  const ExtensionAlbumScreen({
    super.key,
    required this.extensionId,
    required this.albumId,
    required this.albumName,
    this.coverUrl,
  });

  @override
  ConsumerState<ExtensionAlbumScreen> createState() =>
      _ExtensionAlbumScreenState();
}

class _ExtensionAlbumScreenState extends ConsumerState<ExtensionAlbumScreen> {
  List<Track>? _tracks;
  bool _isLoading = true;
  String? _error;
  String? _artistId;
  String? _artistName;

  @override
  void initState() {
    super.initState();
    _fetchTracks();
  }

  Future<void> _fetchTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await PlatformBridge.getAlbumWithExtension(
        widget.extensionId,
        widget.albumId,
      );
      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error = 'Failed to load album';
          _isLoading = false;
        });
        return;
      }

      final trackList = result['tracks'] as List<dynamic>?;
      if (trackList == null) {
        setState(() {
          _error = 'No tracks found';
          _isLoading = false;
        });
        return;
      }

      final tracks = trackList
          .map((t) => _parseTrack(t as Map<String, dynamic>))
          .toList();

      // Extract artist info from album response
      final artistId = result['artist_id'] as String?;
      final artistName = result['artists'] as String?;

      setState(() {
        _tracks = tracks;
        _artistId = artistId;
        _artistName = artistName;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Track _parseTrack(Map<String, dynamic> data) {
    int durationMs = 0;
    final durationValue = data['duration_ms'];
    if (durationValue is int) {
      durationMs = durationValue;
    } else if (durationValue is double) {
      durationMs = durationValue.toInt();
    }

    return Track(
      id: (data['id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      artistName: (data['artists'] ?? data['artist'] ?? '').toString(),
      albumName: (data['album_name'] ?? widget.albumName).toString(),
      coverUrl: _resolveCoverUrl(
        data['cover_url']?.toString(),
        widget.coverUrl,
      ),
      isrc: data['isrc']?.toString(),
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_number'] as int?,
      source: widget.extensionId,
    );
  }

  String? _resolveCoverUrl(String? trackCover, String? albumCover) {
    if (trackCover != null && trackCover.isNotEmpty) return trackCover;
    return albumCover;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.albumName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.albumName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTracks,
                child: Text(context.l10n.dialogRetry),
              ),
            ],
          ),
        ),
      );
    }

    return AlbumScreen(
      albumId: widget.albumId,
      albumName: widget.albumName,
      coverUrl: widget.coverUrl,
      tracks: _tracks,
      extensionId: widget.extensionId,
      artistId: _artistId,
      artistName: _artistName,
    );
  }
}

/// Screen for viewing extension playlist with track fetching
class ExtensionPlaylistScreen extends ConsumerStatefulWidget {
  final String extensionId;
  final String playlistId;
  final String playlistName;
  final String? coverUrl;

  const ExtensionPlaylistScreen({
    super.key,
    required this.extensionId,
    required this.playlistId,
    required this.playlistName,
    this.coverUrl,
  });

  @override
  ConsumerState<ExtensionPlaylistScreen> createState() =>
      _ExtensionPlaylistScreenState();
}

class _ExtensionPlaylistScreenState
    extends ConsumerState<ExtensionPlaylistScreen> {
  List<Track>? _tracks;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTracks();
  }

  Future<void> _fetchTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await PlatformBridge.getPlaylistWithExtension(
        widget.extensionId,
        widget.playlistId,
      );
      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error = 'Failed to load playlist';
          _isLoading = false;
        });
        return;
      }

      final trackList = result['tracks'] as List<dynamic>?;
      if (trackList == null) {
        setState(() {
          _error = 'No tracks found';
          _isLoading = false;
        });
        return;
      }

      final tracks = trackList
          .map((t) => _parseTrack(t as Map<String, dynamic>))
          .toList();

      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Track _parseTrack(Map<String, dynamic> data) {
    int durationMs = 0;
    final durationValue = data['duration_ms'];
    if (durationValue is int) {
      durationMs = durationValue;
    } else if (durationValue is double) {
      durationMs = durationValue.toInt();
    }

    return Track(
      id: (data['id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      artistName: (data['artists'] ?? data['artist'] ?? '').toString(),
      albumName: (data['album_name'] ?? '').toString(),
      coverUrl: _resolveCoverUrl(
        data['cover_url']?.toString(),
        widget.coverUrl,
      ),
      isrc: data['isrc']?.toString(),
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_number'] as int?,
      source: widget.extensionId,
    );
  }

  String? _resolveCoverUrl(String? trackCover, String? playlistCover) {
    if (trackCover != null && trackCover.isNotEmpty) return trackCover;
    return playlistCover;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.playlistName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.playlistName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTracks,
                child: Text(context.l10n.dialogRetry),
              ),
            ],
          ),
        ),
      );
    }

    return PlaylistScreen(
      playlistName: widget.playlistName,
      coverUrl: widget.coverUrl,
      tracks: _tracks!,
    );
  }
}

class ExtensionArtistScreen extends ConsumerStatefulWidget {
  final String extensionId;
  final String artistId;
  final String artistName;
  final String? coverUrl;

  const ExtensionArtistScreen({
    super.key,
    required this.extensionId,
    required this.artistId,
    required this.artistName,
    this.coverUrl,
  });

  @override
  ConsumerState<ExtensionArtistScreen> createState() =>
      _ExtensionArtistScreenState();
}

class _ExtensionArtistScreenState extends ConsumerState<ExtensionArtistScreen> {
  List<ArtistAlbum>? _albums;
  List<Track>? _topTracks;
  String? _headerImageUrl;
  int? _monthlyListeners;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchArtist();
  }

  Future<void> _fetchArtist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await PlatformBridge.getArtistWithExtension(
        widget.extensionId,
        widget.artistId,
      );
      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error = 'Failed to load artist';
          _isLoading = false;
        });
        return;
      }

      final albumList = result['albums'] as List<dynamic>?;
      final albums =
          albumList
              ?.map((a) => _parseAlbum(a as Map<String, dynamic>))
              .toList() ??
          [];

      final topTracksList = result['top_tracks'] as List<dynamic>?;
      List<Track>? topTracks;
      if (topTracksList != null && topTracksList.isNotEmpty) {
        topTracks = topTracksList
            .map((t) => _parseTrack(t as Map<String, dynamic>))
            .toList();
      }

      final headerImage = result['header_image'] as String?;
      final listeners = result['listeners'] as int?;

      setState(() {
        _albums = albums;
        _topTracks = topTracks;
        _headerImageUrl = headerImage;
        _monthlyListeners = listeners;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  ArtistAlbum _parseAlbum(Map<String, dynamic> data) {
    return ArtistAlbum(
      id: (data['id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      artists: (data['artists'] ?? '').toString(),
      releaseDate: (data['release_date'] ?? '').toString(),
      totalTracks: data['total_tracks'] as int? ?? 0,
      coverUrl: data['cover_url']?.toString(),
      albumType: (data['album_type'] ?? 'album').toString(),
      providerId: (data['provider_id'] ?? widget.extensionId).toString(),
    );
  }

  Track _parseTrack(Map<String, dynamic> data) {
    int durationMs = 0;
    final durationValue = data['duration_ms'];
    if (durationValue is int) {
      durationMs = durationValue;
    } else if (durationValue is double) {
      durationMs = durationValue.toInt();
    }

    return Track(
      id: (data['id'] ?? data['spotify_id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      artistName: (data['artists'] ?? data['artist'] ?? '').toString(),
      albumName: (data['album_name'] ?? data['album'] ?? '').toString(),
      albumArtist: data['album_artist']?.toString(),
      coverUrl: (data['cover_url'] ?? data['images'])?.toString(),
      isrc: data['isrc']?.toString(),
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      releaseDate: data['release_date']?.toString(),
      source: (data['provider_id'] ?? widget.extensionId).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.artistName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.artistName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchArtist,
                child: Text(context.l10n.dialogRetry),
              ),
            ],
          ),
        ),
      );
    }

    return ArtistScreen(
      artistId: widget.artistId,
      artistName: widget.artistName,
      coverUrl: widget.coverUrl,
      headerImageUrl: _headerImageUrl,
      monthlyListeners: _monthlyListeners,
      albums: _albums,
      topTracks: _topTracks,
      extensionId: widget.extensionId, // Skip Spotify/Deezer fetch
    );
  }
}

/// Swipeable Quick Picks widget with page indicator
class _QuickPicksPageView extends StatefulWidget {
  final ExploreSection section;
  final ColorScheme colorScheme;
  final int itemsPerPage;
  final int totalPages;
  final void Function(ExploreItem) onItemTap;
  final void Function(ExploreItem) onItemMenu;

  const _QuickPicksPageView({
    required this.section,
    required this.colorScheme,
    required this.itemsPerPage,
    required this.totalPages,
    required this.onItemTap,
    required this.onItemMenu,
  });

  @override
  State<_QuickPicksPageView> createState() => _QuickPicksPageViewState();
}

class _QuickPicksPageViewState extends State<_QuickPicksPageView> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            widget.section.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: widget.itemsPerPage * 64.0,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.totalPages,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * widget.itemsPerPage;
              final endIndex = (startIndex + widget.itemsPerPage).clamp(
                0,
                widget.section.items.length,
              );
              final pageItemCount = endIndex - startIndex;

              return Column(
                children: List.generate(pageItemCount, (index) {
                  final item = widget.section.items[startIndex + index];
                  return _buildQuickPickItem(item);
                }),
              );
            },
          ),
        ),
        if (widget.totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.totalPages, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 8 : 6,
                  height: isActive ? 8 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? widget.colorScheme.primary
                        : widget.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickPickItem(ExploreItem item) {
    return InkWell(
      onTap: () => widget.onItemTap(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.coverUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      memCacheWidth: 96,
                      memCacheHeight: 96,
                      cacheManager: CoverCacheManager.instance,
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        color: widget.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.music_note,
                          color: widget.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: widget.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.music_note,
                        color: widget.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.colorScheme.onSurface,
                    ),
                  ),
                  if (item.artists.isNotEmpty)
                    Text(
                      item.artists,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: widget.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () => widget.onItemMenu(item),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
