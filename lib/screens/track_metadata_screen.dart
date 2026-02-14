import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/services/history_database.dart';
import 'package:spotiflac_android/services/library_database.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/services/ffmpeg_service.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('TrackMetadata');

class _EmbeddedCoverPreviewCacheEntry {
  final String previewPath;
  final int? fileModTime;

  const _EmbeddedCoverPreviewCacheEntry({
    required this.previewPath,
    this.fileModTime,
  });
}

class TrackMetadataScreen extends ConsumerStatefulWidget {
  final DownloadHistoryItem? item;
  final LocalLibraryItem? localItem;

  const TrackMetadataScreen({super.key, this.item, this.localItem})
    : assert(
        item != null || localItem != null,
        'Either item or localItem must be provided',
      );

  @override
  ConsumerState<TrackMetadataScreen> createState() =>
      _TrackMetadataScreenState();
}

class _TrackMetadataScreenState extends ConsumerState<TrackMetadataScreen> {
  static const int _maxCoverPreviewCacheEntries = 96;
  static final Map<String, _EmbeddedCoverPreviewCacheEntry>
  _embeddedCoverPreviewCache = {};

  bool _fileExists = false;
  int? _fileSize;
  String? _lyrics; // Cleaned lyrics for display (no timestamps)
  String? _rawLyrics; // Raw LRC with timestamps for embedding
  bool _lyricsLoading = false;
  String? _lyricsError;
  String? _lyricsSource;
  bool _showTitleInAppBar = false;
  bool _lyricsEmbedded = false; // Track if lyrics are embedded in file
  bool _isEmbedding = false; // Track embed operation in progress
  bool _isInstrumental = false; // Track if detected as instrumental
  bool _isConverting = false; // Track convert operation in progress
  bool _hasMetadataChanges = false;
  Map<String, dynamic>? _editedMetadata; // Overrides after metadata edit
  String? _embeddedCoverPreviewPath;
  final ScrollController _scrollController = ScrollController();
  static final RegExp _lrcTimestampPattern = RegExp(
    r'^\[\d{2}:\d{2}\.\d{2,3}\]',
  );
  static final RegExp _lrcMetadataPattern = RegExp(r'^\[[a-zA-Z]+:.*\]$');
  static final RegExp _lrcInlineTimestampPattern = RegExp(
    r'<\d{2}:\d{2}\.\d{2,3}>',
  );
  static final RegExp _lrcSpeakerPrefixPattern = RegExp(r'^(v1|v2):\s*');
  static final RegExp _lrcBackgroundLinePattern = RegExp(r'^\[bg:(.*)\]$');
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _coverCacheKey => _itemId;

  bool _isCacheTrackedPath(String? path) {
    if (!_hasPath(path)) return false;
    return _embeddedCoverPreviewCache.values.any(
      (entry) => entry.previewPath == path,
    );
  }

  bool _isVolatileSafTempPath(String path) {
    if (path.isEmpty) return false;
    return path.contains(
      '${Platform.pathSeparator}cache${Platform.pathSeparator}saf_',
    );
  }

  int? _readLocalFileModTimeMsSync(String path) {
    if (path.isEmpty || isContentUri(path) || _isVolatileSafTempPath(path)) {
      return null;
    }
    try {
      return File(path).statSync().modified.millisecondsSinceEpoch;
    } catch (_) {
      return null;
    }
  }

  void _cacheEmbeddedCoverPreview(
    String cacheKey,
    String sourcePath,
    String previewPath,
  ) {
    final fileModTime = _readLocalFileModTimeMsSync(sourcePath);
    final existing = _embeddedCoverPreviewCache[cacheKey];
    _embeddedCoverPreviewCache[cacheKey] = _EmbeddedCoverPreviewCacheEntry(
      previewPath: previewPath,
      fileModTime: fileModTime,
    );
    if (existing != null && existing.previewPath != previewPath) {
      _cleanupTempFileAndParentSyncIfNotCached(existing.previewPath);
    }

    while (_embeddedCoverPreviewCache.length > _maxCoverPreviewCacheEntries) {
      final oldestKey = _embeddedCoverPreviewCache.keys.first;
      final removed = _embeddedCoverPreviewCache.remove(oldestKey);
      if (removed != null) {
        _cleanupTempFileAndParentSyncIfNotCached(removed.previewPath);
      }
    }
  }

  void _invalidateEmbeddedCoverPreviewCacheForPath(String cacheKey) {
    if (cacheKey.isEmpty) return;
    final removed = _embeddedCoverPreviewCache.remove(cacheKey);
    if (removed != null) {
      _cleanupTempFileAndParentSyncIfNotCached(removed.previewPath);
    }
  }

  String? _getCachedEmbeddedCoverPreviewPathIfValid(
    String cacheKey,
    String sourcePath,
  ) {
    if (cacheKey.isEmpty) return null;
    final cached = _embeddedCoverPreviewCache[cacheKey];
    if (cached == null) return null;

    final previewFile = File(cached.previewPath);
    if (!previewFile.existsSync()) {
      _embeddedCoverPreviewCache.remove(cacheKey);
      return null;
    }

    if (!isContentUri(sourcePath) && !_isVolatileSafTempPath(sourcePath)) {
      final currentModTime = _readLocalFileModTimeMsSync(sourcePath);
      if (currentModTime != null &&
          cached.fileModTime != null &&
          currentModTime != cached.fileModTime) {
        _embeddedCoverPreviewCache.remove(cacheKey);
        _cleanupTempFileAndParentSyncIfNotCached(cached.previewPath);
        return null;
      }
    }

    return cached.previewPath;
  }

  String? _normalizeOptionalString(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase() == 'null') return null;
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkFile();
  }

  @override
  void dispose() {
    _cleanupTempFileAndParentSyncIfNotCached(_embeddedCoverPreviewPath);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 280;
    if (shouldShow != _showTitleInAppBar) {
      setState(() => _showTitleInAppBar = shouldShow);
    }
  }

  Future<void> _checkFile() async {
    var filePath = _filePath;
    if (filePath.startsWith('EXISTS:')) {
      filePath = filePath.substring(7);
    }

    bool exists = false;
    int? size;
    try {
      final stat = await fileStat(filePath);
      if (stat != null) {
        exists = true;
        size = stat.size;
      }
    } catch (_) {}

    if (mounted && (exists != _fileExists || size != _fileSize)) {
      setState(() {
        _fileExists = exists;
        _fileSize = size;
      });
    }

    if (mounted && exists && _lyrics == null && !_lyricsLoading) {
      _fetchLyrics();
    }
    if (mounted && exists && !_hasPath(_embeddedCoverPreviewPath)) {
      final cachedPath = _getCachedEmbeddedCoverPreviewPathIfValid(
        _coverCacheKey,
        cleanFilePath,
      );
      if (_hasPath(cachedPath)) {
        setState(() => _embeddedCoverPreviewPath = cachedPath);
      }
    }
  }

  bool _hasPath(String? path) => path != null && path.trim().isNotEmpty;

  Future<void> _cleanupTempFileAndParent(String? path) async {
    if (!_hasPath(path)) return;
    final file = File(path!);
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    try {
      final dir = file.parent;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> _cleanupTempFileAndParentIfNotCached(String? path) async {
    if (_isCacheTrackedPath(path)) return;
    await _cleanupTempFileAndParent(path);
  }

  void _cleanupTempFileAndParentSync(String? path) {
    if (!_hasPath(path)) return;
    final file = File(path!);
    try {
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
    try {
      final dir = file.parent;
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {}
  }

  void _cleanupTempFileAndParentSyncIfNotCached(String? path) {
    if (_isCacheTrackedPath(path)) return;
    _cleanupTempFileAndParentSync(path);
  }

  Future<void> _refreshEmbeddedCoverPreview({bool force = false}) async {
    final cacheKey = _coverCacheKey;
    final sourcePath = cleanFilePath;
    if (!force) {
      final cachedPath = _getCachedEmbeddedCoverPreviewPathIfValid(
        cacheKey,
        sourcePath,
      );
      if (_hasPath(cachedPath)) {
        if (mounted && _embeddedCoverPreviewPath != cachedPath) {
          setState(() => _embeddedCoverPreviewPath = cachedPath);
        }
        return;
      }
    }

    String? newPreviewPath;
    try {
      if (!_fileExists) {
        _invalidateEmbeddedCoverPreviewCacheForPath(cacheKey);
        await _cleanupTempFileAndParentIfNotCached(_embeddedCoverPreviewPath);
        if (mounted) {
          setState(() => _embeddedCoverPreviewPath = null);
        }
        return;
      }
      if (force) {
        _invalidateEmbeddedCoverPreviewCacheForPath(cacheKey);
      }
      final tempDir = await Directory.systemTemp.createTemp(
        'track_cover_preview_',
      );
      final outputPath =
          '${tempDir.path}${Platform.pathSeparator}cover_preview.jpg';
      final result = await PlatformBridge.extractCoverToFile(
        sourcePath,
        outputPath,
      );
      if (result['error'] == null && await File(outputPath).exists()) {
        newPreviewPath = outputPath;
        _cacheEmbeddedCoverPreview(cacheKey, sourcePath, outputPath);
      } else {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}

    final oldPreviewPath = _embeddedCoverPreviewPath;
    if (!mounted) {
      if (newPreviewPath != null) {
        await _cleanupTempFileAndParentIfNotCached(newPreviewPath);
      }
      return;
    }

    setState(() => _embeddedCoverPreviewPath = newPreviewPath);
    if (oldPreviewPath != null && oldPreviewPath != newPreviewPath) {
      await _cleanupTempFileAndParentIfNotCached(oldPreviewPath);
    }
  }

  bool get _isLocalItem => widget.localItem != null;
  DownloadHistoryItem? get _downloadItem => widget.item;
  LocalLibraryItem? get _localLibraryItem => widget.localItem;

  String get _itemId =>
      _isLocalItem ? _localLibraryItem!.id : _downloadItem!.id;
  String get trackName =>
      _editedMetadata?['title']?.toString() ??
      (_isLocalItem ? _localLibraryItem!.trackName : _downloadItem!.trackName);
  String get artistName =>
      _editedMetadata?['artist']?.toString() ??
      (_isLocalItem
          ? _localLibraryItem!.artistName
          : _downloadItem!.artistName);
  String get albumName =>
      _editedMetadata?['album']?.toString() ??
      (_isLocalItem ? _localLibraryItem!.albumName : _downloadItem!.albumName);
  String? get albumArtist {
    final edited = _editedMetadata?['album_artist']?.toString();
    if (edited != null && edited.isNotEmpty) return edited;
    return _normalizeOptionalString(
      _isLocalItem
          ? _localLibraryItem!.albumArtist
          : _downloadItem!.albumArtist,
    );
  }

  int? get trackNumber {
    final edited = _editedMetadata?['track_number'];
    if (edited != null) {
      final v = int.tryParse(edited.toString());
      if (v != null && v > 0) return v;
    }
    return _isLocalItem
        ? _localLibraryItem!.trackNumber
        : _downloadItem!.trackNumber;
  }

  int? get discNumber {
    final edited = _editedMetadata?['disc_number'];
    if (edited != null) {
      final v = int.tryParse(edited.toString());
      if (v != null && v > 0) return v;
    }
    return _isLocalItem
        ? _localLibraryItem!.discNumber
        : _downloadItem!.discNumber;
  }

  String? get releaseDate =>
      _editedMetadata?['date']?.toString() ??
      (_isLocalItem
          ? _localLibraryItem!.releaseDate
          : _downloadItem!.releaseDate);
  String? get isrc =>
      _editedMetadata?['isrc']?.toString() ??
      (_isLocalItem ? _localLibraryItem!.isrc : _downloadItem!.isrc);
  String? get genre =>
      _editedMetadata?['genre']?.toString() ??
      (_isLocalItem ? _localLibraryItem!.genre : _downloadItem!.genre);
  String? get label =>
      _editedMetadata?['label']?.toString() ??
      (_isLocalItem ? null : _downloadItem!.label);
  String? get copyright =>
      _editedMetadata?['copyright']?.toString() ??
      (_isLocalItem ? null : _downloadItem!.copyright);
  int? get duration =>
      _isLocalItem ? _localLibraryItem!.duration : _downloadItem!.duration;
  int? get bitDepth =>
      _isLocalItem ? _localLibraryItem!.bitDepth : _downloadItem!.bitDepth;
  int? get sampleRate =>
      _isLocalItem ? _localLibraryItem!.sampleRate : _downloadItem!.sampleRate;
  int? get _localBitrate => _isLocalItem ? _localLibraryItem!.bitrate : null;

  String get _filePath =>
      _isLocalItem ? _localLibraryItem!.filePath : _downloadItem!.filePath;
  String? get _coverUrl => _isLocalItem ? null : _downloadItem!.coverUrl;
  String? get _localCoverPath =>
      _isLocalItem ? _localLibraryItem!.coverPath : null;
  String? get _spotifyId => _isLocalItem ? null : _downloadItem!.spotifyId;
  String get _service => _isLocalItem ? 'local' : _downloadItem!.service;
  DateTime get _addedAt {
    if (_isLocalItem) {
      // Use file modification time if available, otherwise fall back to scannedAt
      final modTime = _localLibraryItem!.fileModTime;
      if (modTime != null && modTime > 0) {
        return DateTime.fromMillisecondsSinceEpoch(modTime);
      }
      return _localLibraryItem!.scannedAt;
    }
    return _downloadItem!.downloadedAt;
  }

  String? get _quality => _isLocalItem ? null : _downloadItem!.quality;

  String get cleanFilePath {
    final path = _filePath;
    return path.startsWith('EXISTS:') ? path.substring(7) : path;
  }

  String _formatPathForDisplay(String pathOrUri) {
    if (pathOrUri.isEmpty || !pathOrUri.startsWith('content://')) {
      return pathOrUri;
    }

    try {
      final uri = Uri.parse(pathOrUri);
      final segments = uri.pathSegments;
      String? documentId;

      final documentIndex = segments.indexOf('document');
      if (documentIndex != -1 && documentIndex + 1 < segments.length) {
        documentId = Uri.decodeComponent(segments[documentIndex + 1]);
      }

      if (documentId == null || documentId.isEmpty) {
        final treeIndex = segments.indexOf('tree');
        if (treeIndex != -1 && treeIndex + 1 < segments.length) {
          documentId = Uri.decodeComponent(segments[treeIndex + 1]);
        }
      }

      if (documentId == null || documentId.isEmpty) return pathOrUri;

      final separatorIndex = documentId.indexOf(':');
      if (separatorIndex <= 0) return documentId;

      final volumeId = documentId.substring(0, separatorIndex);
      final relativePath = documentId
          .substring(separatorIndex + 1)
          .replaceAll('\\', '/');

      if (volumeId.toLowerCase() == 'primary') {
        if (relativePath.isEmpty) return '/storage/emulated/0';
        return '/storage/emulated/0/$relativePath';
      }

      if (relativePath.isEmpty) return volumeId;
      return 'SD Card/$relativePath';
    } catch (_) {
      return pathOrUri;
    }
  }

  void _markMetadataChanged() {
    _hasMetadataChanges = true;
  }

  void _popWithMetadataResult() {
    Navigator.pop(context, _hasMetadataChanges ? true : null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final coverSize = screenWidth * 0.5;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor:
                colorScheme.surface, // Use theme color for collapsed state
            surfaceTintColor: Colors.transparent,
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showTitleInAppBar ? 1.0 : 0.0,
              child: Text(
                trackName,
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
                    (320 - kToolbarHeight);
                final showContent = collapseRatio > 0.3;

                return FlexibleSpaceBar(
                  collapseMode: CollapseMode.none,
                  background: _buildHeaderBackground(
                    context,
                    colorScheme,
                    coverSize,
                    showContent,
                  ),
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                );
              },
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              ),
              onPressed: _popWithMetadataResult,
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.more_vert, color: colorScheme.onSurface),
                ),
                onPressed: () => _showOptionsMenu(context, ref, colorScheme),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTrackInfoCard(context, colorScheme, _fileExists),

                  const SizedBox(height: 16),

                  _buildMetadataCard(context, colorScheme, _fileSize),

                  const SizedBox(height: 16),

                  _buildFileInfoCard(
                    context,
                    colorScheme,
                    _fileExists,
                    _fileSize,
                  ),

                  const SizedBox(height: 16),

                  _buildLyricsCard(context, colorScheme),

                  const SizedBox(height: 24),

                  _buildActionButtons(context, ref, colorScheme, _fileExists),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(
    BuildContext context,
    ColorScheme colorScheme,
    double coverSize,
    bool showContent,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final backgroundCacheWidth = (screenSize.width * pixelRatio).round();
    final backgroundCacheHeight = (screenSize.height * 0.65 * pixelRatio)
        .round();
    final coverCacheSize = (coverSize * pixelRatio).round();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred cover art background
        if (_hasPath(_embeddedCoverPreviewPath))
          Image.file(
            File(_embeddedCoverPreviewPath!),
            fit: BoxFit.cover,
            cacheWidth: backgroundCacheWidth,
            cacheHeight: backgroundCacheHeight,
            errorBuilder: (_, _, _) => Container(color: colorScheme.surface),
          )
        else if (_coverUrl != null)
          CachedNetworkImage(
            imageUrl: _coverUrl!,
            fit: BoxFit.cover,
            memCacheWidth: backgroundCacheWidth,
            memCacheHeight: backgroundCacheHeight,
            cacheManager: CoverCacheManager.instance,
            placeholder: (_, _) => Container(color: colorScheme.surface),
            errorWidget: (_, _, _) => Container(color: colorScheme.surface),
          )
        else if (_localCoverPath != null && _localCoverPath!.isNotEmpty)
          Image.file(
            File(_localCoverPath!),
            fit: BoxFit.cover,
            cacheWidth: backgroundCacheWidth,
            cacheHeight: backgroundCacheHeight,
            errorBuilder: (_, _, _) => Container(color: colorScheme.surface),
          )
        else
          Container(color: colorScheme.surface),

        // Blur filter
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: colorScheme.surface.withValues(alpha: 0.4)),
          ),
        ),

        // Bottom fade to surface
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface.withValues(alpha: 0.0),
                  colorScheme.surface,
                ],
              ),
            ),
          ),
        ),

        // Cover art
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: showContent ? 1.0 : 0.0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Hero(
                tag: 'cover_$_itemId',
                child: Container(
                  width: coverSize,
                  height: coverSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _hasPath(_embeddedCoverPreviewPath)
                        ? Image.file(
                            File(_embeddedCoverPreviewPath!),
                            fit: BoxFit.cover,
                            cacheWidth: coverCacheSize,
                            cacheHeight: coverCacheSize,
                            errorBuilder: (_, _, _) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : _coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _coverUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: (coverSize * 2).toInt(),
                            cacheManager: CoverCacheManager.instance,
                            placeholder: (_, _) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : _localCoverPath != null && _localCoverPath!.isNotEmpty
                        ? Image.file(
                            File(_localCoverPath!),
                            fit: BoxFit.cover,
                            cacheWidth: coverCacheSize,
                            cacheHeight: coverCacheSize,
                          )
                        : Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.music_note,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackInfoCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool fileExists,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trackName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              artistName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.album,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    albumName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            if (!fileExists) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      size: 16,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.trackFileNotFound,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(
    BuildContext context,
    ColorScheme colorScheme,
    int? fileSize,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  context.l10n.trackMetadata,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildMetadataGrid(context, colorScheme),

            if (_spotifyId != null && _spotifyId!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final isDeezer = _spotifyId!.contains('deezer');
                  return OutlinedButton.icon(
                    onPressed: () => _openServiceUrl(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      isDeezer
                          ? context.l10n.trackOpenInDeezer
                          : context.l10n.trackOpenInSpotify,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openServiceUrl(BuildContext context) async {
    if (_spotifyId == null) return;

    final isDeezer = _spotifyId!.contains('deezer');
    final rawId = _spotifyId!.replaceAll('deezer:', '');

    final webUrl = isDeezer
        ? 'https://www.deezer.com/track/$rawId'
        : 'https://open.spotify.com/track/$rawId';

    final appUri = isDeezer
        ? Uri.parse('deezer://www.deezer.com/track/$rawId')
        : Uri.parse('spotify:track:$rawId');

    try {
      final launched = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      try {
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        if (context.mounted) {
          _copyToClipboard(context, webUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.snackbarUrlCopied(isDeezer ? 'Deezer' : 'Spotify'),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildMetadataGrid(BuildContext context, ColorScheme colorScheme) {
    // Determine audio quality string - prefer stored quality from download
    String? audioQualityStr;
    final fileName = _extractFileNameFromPathOrUri(cleanFilePath);
    final fileExt = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : '';

    // Use stored quality from download history if available
    if (_quality != null && _quality!.isNotEmpty) {
      audioQualityStr = _quality;
    } else if (_isLocalItem && _localBitrate != null && _localBitrate! > 0) {
      // Lossy local file with bitrate info
      final fmt = _localLibraryItem!.format?.toUpperCase() ?? fileExt;
      audioQualityStr = '$fmt ${_localBitrate}kbps';
    } else if (bitDepth != null && bitDepth! > 0 && sampleRate != null) {
      // Lossless file with actual bit depth (FLAC, ALAC)
      final sampleRateKHz = (sampleRate! / 1000).toStringAsFixed(1);
      audioQualityStr = '$bitDepth-bit/${sampleRateKHz}kHz';
    } else {
      // Fallback based on file extension for legacy items
      if (fileExt == 'MP3') {
        audioQualityStr = 'MP3';
      } else if (fileExt == 'OPUS' || fileExt == 'OGG') {
        audioQualityStr = 'Opus';
      } else if (fileExt == 'M4A' || fileExt == 'AAC') {
        audioQualityStr = 'AAC';
      }
    }

    final items = <_MetadataItem>[
      _MetadataItem(context.l10n.trackTrackName, trackName),
      _MetadataItem(context.l10n.trackArtist, artistName),
      if (albumArtist != null && albumArtist != artistName)
        _MetadataItem(context.l10n.trackAlbumArtist, albumArtist!),
      _MetadataItem(context.l10n.trackAlbum, albumName),
      if (trackNumber != null && trackNumber! > 0)
        _MetadataItem(context.l10n.trackTrackNumber, trackNumber.toString()),
      if (discNumber != null && discNumber! > 0)
        _MetadataItem(context.l10n.trackDiscNumber, discNumber.toString()),
      if (duration != null)
        _MetadataItem(context.l10n.trackDuration, _formatDuration(duration!)),
      if (audioQualityStr != null)
        _MetadataItem(context.l10n.trackAudioQuality, audioQualityStr),
      if (releaseDate != null && releaseDate!.isNotEmpty)
        _MetadataItem(context.l10n.trackReleaseDate, releaseDate!),
      if (genre != null && genre!.isNotEmpty)
        _MetadataItem(context.l10n.trackGenre, genre!),
      if (label != null && label!.isNotEmpty)
        _MetadataItem(context.l10n.trackLabel, label!),
      if (copyright != null && copyright!.isNotEmpty)
        _MetadataItem(context.l10n.trackCopyright, copyright!),
      if (isrc != null && isrc!.isNotEmpty) _MetadataItem('ISRC', isrc!),
    ];

    if (!_isLocalItem && _spotifyId != null && _spotifyId!.isNotEmpty) {
      final isDeezer = _spotifyId!.contains('deezer');
      final cleanId = _spotifyId!.replaceAll('deezer:', '');
      items.add(_MetadataItem(isDeezer ? 'Deezer ID' : 'Spotify ID', cleanId));
    }

    items.add(
      _MetadataItem(context.l10n.trackMetadataService, _service.toUpperCase()),
    );
    items.add(
      _MetadataItem(context.l10n.trackDownloaded, _formatFullDate(_addedAt)),
    );

    return Column(
      children: items.map((metadata) {
        final isCopyable =
            metadata.label == 'ISRC' || metadata.label == 'Spotify ID';
        return InkWell(
          onTap: isCopyable
              ? () => _copyToClipboard(context, metadata.value)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    metadata.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    metadata.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isCopyable)
                  Icon(
                    Icons.copy,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildFileInfoCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool fileExists,
    int? fileSize,
  ) {
    final displayFilePath = _formatPathForDisplay(cleanFilePath);
    final fileName = _extractFileNameFromPathOrUri(cleanFilePath);
    final fileExtension = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : 'Unknown';
    final lossyBitrateLabel = _extractLossyBitrateLabel(_quality);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.trackFileInfo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fileExtension,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (fileSize != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatFileSize(fileSize),
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if ((fileExtension == 'MP3' ||
                        fileExtension == 'OPUS' ||
                        fileExtension == 'OGG') &&
                    lossyBitrateLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lossyBitrateLabel,
                      style: TextStyle(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (_isLocalItem &&
                    _localBitrate != null &&
                    _localBitrate! > 0 &&
                    (fileExtension == 'MP3' ||
                        fileExtension == 'OPUS' ||
                        fileExtension == 'OGG'))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_localBitrate}kbps',
                      style: TextStyle(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (bitDepth != null &&
                    bitDepth! > 0 &&
                    sampleRate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$bitDepth-bit/${(sampleRate! / 1000).toStringAsFixed(1)}kHz',
                      style: TextStyle(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getServiceColor(_service, colorScheme),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getServiceIcon(_service),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _service.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            InkWell(
              onTap: () => _copyToClipboard(context, cleanFilePath),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayFilePath,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.copy,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lyrics_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.trackLyrics,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (_lyrics != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyToClipboard(context, _lyrics!),
                    tooltip: context.l10n.trackCopyLyrics,
                  ),
              ],
            ),
            if (_lyricsSource != null && _lyricsSource!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Source: ${_lyricsSource!}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            if (_lyricsLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_lyricsError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _lyricsError!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchLyrics,
                      child: Text(context.l10n.dialogRetry),
                    ),
                  ],
                ),
              )
            else if (_isInstrumental)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note,
                      color: colorScheme.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.trackInstrumental,
                      style: TextStyle(
                        color: colorScheme.onTertiaryContainer,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else if (_lyrics != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Text(
                        _lyrics!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  // Show "Embed Lyrics" button if lyrics are from online (not already embedded)
                  if (!_lyricsEmbedded && _fileExists) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: FilledButton.tonalIcon(
                        onPressed: _isEmbedding ? null : _embedLyrics,
                        icon: _isEmbedding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_alt),
                        label: Text(context.l10n.trackEmbedLyrics),
                      ),
                    ),
                  ],
                ],
              )
            else
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: _fetchLyrics,
                  icon: const Icon(Icons.download),
                  label: Text(context.l10n.trackLoadLyrics),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchLyrics() async {
    if (_lyricsLoading) return;

    setState(() {
      _lyricsLoading = true;
      _lyricsError = null;
      _isInstrumental = false;
      _lyricsSource = null;
    });

    try {
      // Convert duration from seconds to milliseconds
      final durationMs = (duration ?? 0) * 1000;

      // First, check if lyrics are embedded in the file
      if (_fileExists) {
        final embeddedResult =
            await PlatformBridge.getLyricsLRCWithSource(
              '',
              trackName,
              artistName,
              filePath: cleanFilePath,
              durationMs: 0,
            ).timeout(
              const Duration(seconds: 5),
              onTimeout: () => <String, dynamic>{'lyrics': '', 'source': ''},
            );

        final embeddedLyrics = embeddedResult['lyrics']?.toString() ?? '';
        final embeddedSource = embeddedResult['source']?.toString() ?? '';

        if (embeddedLyrics.isNotEmpty) {
          // Lyrics found in file
          if (mounted) {
            final cleanLyrics = _cleanLrcForDisplay(embeddedLyrics);
            setState(() {
              _lyrics = cleanLyrics;
              _rawLyrics = embeddedLyrics;
              _lyricsSource = embeddedSource.isNotEmpty
                  ? embeddedSource
                  : 'Embedded';
              _lyricsEmbedded = true;
              _lyricsLoading = false;
            });
          }
          return;
        }
      }

      // No embedded lyrics, fetch from online
      final result = await PlatformBridge.getLyricsLRCWithSource(
        _spotifyId ?? '',
        trackName,
        artistName,
        filePath: null, // Don't check file again
        durationMs: durationMs,
      ).timeout(const Duration(seconds: 20));

      final lrcText = result['lyrics']?.toString() ?? '';
      final source = result['source']?.toString() ?? '';
      final instrumental =
          (result['instrumental'] as bool? ?? false) ||
          lrcText == '[instrumental:true]';

      if (mounted) {
        // Check for instrumental marker
        if (instrumental) {
          setState(() {
            _isInstrumental = true;
            _lyricsSource = source.isNotEmpty ? source : null;
            _lyricsLoading = false;
          });
        } else if (lrcText.isEmpty) {
          setState(() {
            _lyricsError = context.l10n.trackLyricsNotAvailable;
            _lyricsLoading = false;
          });
        } else {
          final cleanLyrics = _cleanLrcForDisplay(lrcText);
          setState(() {
            _lyrics = cleanLyrics;
            _rawLyrics = lrcText; // Keep raw LRC with timestamps for embedding
            _lyricsSource = source.isNotEmpty ? source : null;
            _lyricsEmbedded = false; // Lyrics from online, not embedded
            _lyricsLoading = false;
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _lyricsError = context.l10n.trackLyricsTimeout;
          _lyricsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lyricsError = context.l10n.trackLyricsLoadFailed;
          _lyricsLoading = false;
        });
      }
    }
  }

  Future<void> _embedLyrics() async {
    if (_isEmbedding || _rawLyrics == null || !_fileExists) return;

    setState(() => _isEmbedding = true);

    String? safTempPath;
    String? coverPath;

    try {
      final rawLyrics = _rawLyrics!;
      var workingPath = cleanFilePath;

      if (_isSafFile) {
        safTempPath = await PlatformBridge.copyContentUriToTemp(cleanFilePath);
        if (safTempPath == null || safTempPath.isEmpty) {
          throw Exception('Failed to access SAF file');
        }
        workingPath = safTempPath;
      }

      final lower = workingPath.toLowerCase();
      final isFlac = lower.endsWith('.flac');
      final isMp3 = lower.endsWith('.mp3');
      final isOpus = lower.endsWith('.opus') || lower.endsWith('.ogg');

      bool success = false;
      String? error;

      if (isFlac) {
        final result = await PlatformBridge.embedLyricsToFile(
          workingPath,
          rawLyrics,
        );
        if (result['success'] == true) {
          if (_isSafFile) {
            final ok = await PlatformBridge.writeTempToSaf(
              workingPath,
              cleanFilePath,
            );
            success = ok;
            if (!ok) {
              error = 'Failed to write back to storage';
            }
          } else {
            success = true;
          }
        } else {
          error = result['error']?.toString() ?? 'Failed to embed lyrics';
        }
      } else if (isMp3 || isOpus) {
        final metadata = _buildFallbackMetadata();
        try {
          final result = await PlatformBridge.readFileMetadata(workingPath);
          if (result['error'] == null) {
            final mapped = _mapMetadataForTagEmbed(result);
            metadata.addAll(mapped);
          }
        } catch (e) {
          _log.w('Failed reading file metadata before lyrics embed: $e');
        }

        metadata['LYRICS'] = rawLyrics;
        metadata['UNSYNCEDLYRICS'] = rawLyrics;

        try {
          final tempDir = await getTemporaryDirectory();
          final coverOutput =
              '${tempDir.path}${Platform.pathSeparator}lyrics_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final coverResult = await PlatformBridge.extractCoverToFile(
            workingPath,
            coverOutput,
          );
          if (coverResult['error'] == null) {
            coverPath = coverOutput;
          }
        } catch (_) {}

        String? ffmpegResult;
        if (isMp3) {
          ffmpegResult = await FFmpegService.embedMetadataToMp3(
            mp3Path: workingPath,
            coverPath: coverPath,
            metadata: metadata,
          );
        } else {
          ffmpegResult = await FFmpegService.embedMetadataToOpus(
            opusPath: workingPath,
            coverPath: coverPath,
            metadata: metadata,
          );
        }

        if (ffmpegResult == null) {
          error = 'Failed to embed lyrics';
        } else if (_isSafFile) {
          final ok = await PlatformBridge.writeTempToSaf(
            ffmpegResult,
            cleanFilePath,
          );
          success = ok;
          if (!ok) {
            error = 'Failed to write back to storage';
          }
        } else {
          success = true;
        }
      } else {
        error = 'Unsupported audio format';
      }

      if (mounted) {
        if (success) {
          setState(() {
            _lyricsEmbedded = true;
            _isEmbedding = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.trackLyricsEmbedded)),
          );
        } else {
          setState(() => _isEmbedding = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Failed to embed lyrics')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEmbedding = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (coverPath != null) {
        try {
          await File(coverPath).delete();
        } catch (_) {}
      }
      if (safTempPath != null) {
        try {
          await File(safTempPath).delete();
        } catch (_) {}
      }
    }
  }

  String _buildSaveBaseName() {
    final artist = artistName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final track = trackName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '$artist - $track';
  }

  String _getFileDirectory() {
    if (isContentUri(cleanFilePath)) {
      // SAF URIs don't have a filesystem parent directory
      return '';
    }
    final file = File(cleanFilePath);
    return file.parent.path;
  }

  bool get _isSafFile => isContentUri(cleanFilePath);

  Future<void> _saveCoverArt() async {
    try {
      final baseName = _buildSaveBaseName();

      if (_isSafFile) {
        // SAF file: save to temp, then copy to SAF tree
        final tempDir = await Directory.systemTemp.createTemp('cover_');
        final tempOutput =
            '${tempDir.path}${Platform.pathSeparator}$baseName.jpg';

        Map<String, dynamic> result;
        if (_coverUrl != null && _coverUrl!.isNotEmpty) {
          result = await PlatformBridge.downloadCoverToFile(
            _coverUrl!,
            tempOutput,
            maxQuality: true,
          );
        } else if (_fileExists) {
          result = await PlatformBridge.extractCoverToFile(
            cleanFilePath,
            tempOutput,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.trackCoverNoSource)),
            );
          }
          return;
        }

        if (result['error'] != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.trackSaveFailed(result['error'].toString()),
                ),
              ),
            );
          }
          try {
            await Directory(tempDir.path).delete(recursive: true);
          } catch (_) {}
          return;
        }

        // Write temp file to SAF tree
        final treeUri = _downloadItem?.downloadTreeUri;
        final relativeDir = _downloadItem?.safRelativeDir ?? '';
        if (treeUri != null && treeUri.isNotEmpty) {
          final safUri = await PlatformBridge.createSafFileFromPath(
            treeUri: treeUri,
            relativeDir: relativeDir,
            fileName: '$baseName.jpg',
            mimeType: 'image/jpeg',
            srcPath: tempOutput,
          );
          try {
            await Directory(tempDir.path).delete(recursive: true);
          } catch (_) {}
          if (mounted) {
            if (safUri != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.trackCoverSaved(baseName))),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.l10n.trackSaveFailed('Failed to write to storage'),
                  ),
                ),
              );
            }
          }
        } else {
          // No SAF tree info, keep in temp
          try {
            await Directory(tempDir.path).delete(recursive: true);
          } catch (_) {}
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.trackSaveFailed('No storage access'),
                ),
              ),
            );
          }
        }
        return;
      }

      // Regular file path
      final dir = _getFileDirectory();
      final outputPath = '$dir${Platform.pathSeparator}$baseName.jpg';

      Map<String, dynamic> result;
      if (_coverUrl != null && _coverUrl!.isNotEmpty) {
        result = await PlatformBridge.downloadCoverToFile(
          _coverUrl!,
          outputPath,
          maxQuality: true,
        );
      } else if (_fileExists) {
        result = await PlatformBridge.extractCoverToFile(
          cleanFilePath,
          outputPath,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.trackCoverNoSource)),
          );
        }
        return;
      }

      if (mounted) {
        if (result['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.trackSaveFailed(result['error'].toString()),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.trackCoverSaved(baseName))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.trackSaveFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _saveLyrics() async {
    try {
      final baseName = _buildSaveBaseName();
      final durationMs = (duration ?? 0) * 1000;
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.trackSaveLyricsProgress)),
          );
      }

      if (_isSafFile) {
        // SAF file: save to temp, then copy to SAF tree
        final tempDir = await Directory.systemTemp.createTemp('lyrics_');
        final tempOutput =
            '${tempDir.path}${Platform.pathSeparator}$baseName.lrc';

        final result = await PlatformBridge.fetchAndSaveLyrics(
          trackName: trackName,
          artistName: artistName,
          spotifyId: _spotifyId ?? '',
          durationMs: durationMs,
          outputPath: tempOutput,
        );

        if (result['error'] != null) {
          if (mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    context.l10n.trackSaveFailed(result['error'].toString()),
                  ),
                ),
              );
          }
          try {
            await Directory(tempDir.path).delete(recursive: true);
          } catch (_) {}
          return;
        }

        // Write temp file to SAF tree
        final treeUri = _downloadItem?.downloadTreeUri;
        final relativeDir = _downloadItem?.safRelativeDir ?? '';
        if (treeUri != null && treeUri.isNotEmpty) {
          final safUri = await PlatformBridge.createSafFileFromPath(
            treeUri: treeUri,
            relativeDir: relativeDir,
            fileName: '$baseName.lrc',
            mimeType: 'text/plain',
            srcPath: tempOutput,
          );
          try {
            await Directory(tempDir.path).delete(recursive: true);
          } catch (_) {}
          if (mounted) {
            if (safUri != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.trackLyricsSaved(baseName)),
                  ),
                );
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      context.l10n.trackSaveFailed(
                        'Failed to write to storage',
                      ),
                    ),
                  ),
                );
            }
          }
        } else {
          try {
            await Directory(tempDir.path).delete(recursive: true);
          } catch (_) {}
          if (mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    context.l10n.trackSaveFailed('No storage access'),
                  ),
                ),
              );
          }
        }
        return;
      }

      // Regular file path
      final dir = _getFileDirectory();
      final outputPath = '$dir${Platform.pathSeparator}$baseName.lrc';

      final result = await PlatformBridge.fetchAndSaveLyrics(
        trackName: trackName,
        artistName: artistName,
        spotifyId: _spotifyId ?? '',
        durationMs: durationMs,
        outputPath: outputPath,
      );

      if (mounted) {
        if (result['error'] != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.trackSaveFailed(result['error'].toString()),
                ),
              ),
            );
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(context.l10n.trackLyricsSaved(baseName))),
            );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.trackSaveFailed(e.toString()))),
          );
      }
    }
  }

  Future<void> _reEnrichMetadata() async {
    if (!_fileExists) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.trackReEnrichSearching)),
      );

      final durationMs = (duration ?? 0) * 1000;
      final request = <String, dynamic>{
        'file_path': cleanFilePath,
        'cover_url': _coverUrl ?? '',
        'max_quality': true,
        'embed_lyrics': true,
        'spotify_id': _spotifyId ?? '',
        'track_name': trackName,
        'artist_name': artistName,
        'album_name': albumName,
        'album_artist': albumArtist ?? artistName,
        'track_number': trackNumber ?? 0,
        'disc_number': discNumber ?? 0,
        'release_date': releaseDate ?? '',
        'isrc': isrc ?? '',
        'genre': genre ?? '',
        'label': label ?? '',
        'copyright': copyright ?? '',
        'duration_ms': durationMs,
        'search_online': true,
      };

      final result = await PlatformBridge.reEnrichFile(request);
      final method = result['method'] as String?;

      // Update local UI state with enriched metadata from online search
      final enriched = result['enriched_metadata'] as Map<String, dynamic>?;
      if (enriched != null && mounted) {
        setState(() {
          _editedMetadata = {
            'title': enriched['track_name'] ?? trackName,
            'artist': enriched['artist_name'] ?? artistName,
            'album': enriched['album_name'] ?? albumName,
            'album_artist': enriched['album_artist'] ?? albumArtist,
            'date': enriched['release_date'] ?? releaseDate,
            'track_number': enriched['track_number'] ?? trackNumber,
            'disc_number': enriched['disc_number'] ?? discNumber,
            'isrc': enriched['isrc'] ?? isrc,
            'genre': enriched['genre'] ?? genre,
            'label': enriched['label'] ?? label,
            'copyright': enriched['copyright'] ?? copyright,
          };
        });
      }

      if (method == 'native') {
        // FLAC - handled natively by Go (SAF write-back handled in Kotlin)
        await _refreshEmbeddedCoverPreview(force: true);
        _markMetadataChanged();
        await _syncDownloadHistoryMetadata();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.trackReEnrichSuccess)),
          );
        }
      } else if (method == 'ffmpeg') {
        // MP3/Opus - need FFmpeg from Dart side
        // For SAF files, Kotlin returns temp_path + saf_uri
        final tempPath = result['temp_path'] as String?;
        final safUri = result['saf_uri'] as String?;
        final ffmpegTarget = tempPath ?? cleanFilePath;

        final downloadedCoverPath = result['cover_path'] as String?;
        String? effectiveCoverPath = downloadedCoverPath;
        String? extractedCoverPath;
        if (!_hasPath(effectiveCoverPath)) {
          try {
            final tempDir = await Directory.systemTemp.createTemp(
              'reenrich_cover_',
            );
            final coverOutput =
                '${tempDir.path}${Platform.pathSeparator}cover.jpg';
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
        final lower = cleanFilePath.toLowerCase();

        String? ffmpegResult;
        if (lower.endsWith('.mp3')) {
          ffmpegResult = await FFmpegService.embedMetadataToMp3(
            mp3Path: ffmpegTarget,
            coverPath: effectiveCoverPath,
            metadata: metadata,
          );
        } else if (lower.endsWith('.opus') || lower.endsWith('.ogg')) {
          ffmpegResult = await FFmpegService.embedMetadataToOpus(
            opusPath: ffmpegTarget,
            coverPath: effectiveCoverPath,
            metadata: metadata,
          );
        }

        // For SAF files, copy processed temp file back
        if (ffmpegResult != null && tempPath != null && safUri != null) {
          final ok = await PlatformBridge.writeTempToSaf(ffmpegResult, safUri);
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.trackSaveFailed(
                    'Failed to write back to storage',
                  ),
                ),
              ),
            );
            // Cleanup temp files
            if (_hasPath(downloadedCoverPath)) {
              try {
                await File(downloadedCoverPath!).delete();
              } catch (_) {}
            }
            if (_hasPath(extractedCoverPath)) {
              await _cleanupTempFileAndParent(extractedCoverPath);
            }
            if (tempPath.isNotEmpty) {
              try {
                await File(tempPath).delete();
              } catch (_) {}
            }
            return;
          }
        }

        // Cleanup temp files
        if (tempPath != null && tempPath.isNotEmpty) {
          try {
            await File(tempPath).delete();
          } catch (_) {}
        }

        if (ffmpegResult != null) {
          await _refreshEmbeddedCoverPreview(force: true);
          _markMetadataChanged();
          await _syncDownloadHistoryMetadata();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.trackReEnrichSuccess)),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.trackReEnrichFfmpegFailed)),
          );
        }

        // Cleanup temp cover from Go backend
        if (_hasPath(downloadedCoverPath)) {
          try {
            await File(downloadedCoverPath!).delete();
          } catch (_) {}
        }
        if (_hasPath(extractedCoverPath)) {
          await _cleanupTempFileAndParent(extractedCoverPath);
        }
      } else {
        if (mounted) {
          final error = result['error']?.toString() ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.trackSaveFailed(error))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.trackSaveFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _syncDownloadHistoryMetadata() async {
    if (_isLocalItem || _downloadItem == null) return;

    String? normalizedOrNull(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return trimmed;
    }

    try {
      await ref
          .read(downloadHistoryProvider.notifier)
          .updateMetadataForItem(
            id: _downloadItem!.id,
            trackName: trackName,
            artistName: artistName,
            albumName: albumName,
            albumArtist: normalizedOrNull(albumArtist),
            isrc: normalizedOrNull(isrc),
            trackNumber: trackNumber,
            discNumber: discNumber,
            releaseDate: normalizedOrNull(releaseDate),
            genre: normalizedOrNull(genre),
            label: normalizedOrNull(label),
            copyright: normalizedOrNull(copyright),
          );
    } catch (e) {
      _log.w('Failed to sync download history metadata: $e');
    }
  }

  String _cleanLrcForDisplay(String lrc) {
    final lines = lrc.split('\n');
    final cleanLines = <String>[];

    for (final line in lines) {
      var cleaned = line.trim();

      // Skip metadata tags
      if (_lrcMetadataPattern.hasMatch(cleaned) &&
          !_lrcBackgroundLinePattern.hasMatch(cleaned)) {
        continue;
      }

      // Convert [bg:...] wrapper to a plain secondary vocal line.
      final bgMatch = _lrcBackgroundLinePattern.firstMatch(cleaned);
      if (bgMatch != null) {
        cleaned = bgMatch.group(1)?.trim() ?? '';
      }

      // Remove line timestamp, inline word-by-word timestamps, and speaker prefix.
      cleaned = cleaned.replaceAll(_lrcTimestampPattern, '').trim();
      cleaned = cleaned.replaceAll(_lrcInlineTimestampPattern, '');
      cleaned = cleaned.replaceFirst(_lrcSpeakerPrefixPattern, '');
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (cleaned.isNotEmpty) {
        cleanLines.add(cleaned);
      }
    }

    return cleanLines.join('\n');
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    bool fileExists,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: fileExists
                ? () => _openFile(context, cleanFilePath)
                : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(context.l10n.trackMetadataPlay),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, ref, colorScheme),
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            label: Text(
              context.l10n.trackMetadataDelete,
              style: TextStyle(color: colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(context.l10n.trackCopyFilePath),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(context, cleanFilePath);
                },
              ),
              if (_fileExists)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(context.l10n.trackEditMetadata),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditMetadataSheet(context, ref, colorScheme);
                  },
                ),
              if (!_isLocalItem && (_coverUrl != null || _fileExists))
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: Text(context.l10n.trackSaveCoverArt),
                  subtitle: Text(context.l10n.trackSaveCoverArtSubtitle),
                  onTap: () {
                    Navigator.pop(context);
                    _saveCoverArt();
                  },
                ),
              if (!_isLocalItem)
                ListTile(
                  leading: const Icon(Icons.lyrics_outlined),
                  title: Text(context.l10n.trackSaveLyrics),
                  subtitle: Text(context.l10n.trackSaveLyricsSubtitle),
                  onTap: () {
                    Navigator.pop(context);
                    _saveLyrics();
                  },
                ),
              if (_fileExists)
                ListTile(
                  leading: const Icon(Icons.travel_explore),
                  title: Text(context.l10n.trackReEnrich),
                  subtitle: Text(context.l10n.trackReEnrichOnlineSubtitle),
                  onTap: () {
                    Navigator.pop(context);
                    _reEnrichMetadata();
                  },
                ),
              if (_fileExists && _isConvertibleFormat)
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text(context.l10n.trackConvertFormat),
                  subtitle: Text(context.l10n.trackConvertFormatSubtitle),
                  onTap: () {
                    Navigator.pop(context);
                    _showConvertSheet(context);
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(context.l10n.trackMetadataShare),
                onTap: () {
                  Navigator.pop(context);
                  _shareFile(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: colorScheme.error),
                title: Text(
                  context.l10n.trackRemoveFromDevice,
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, colorScheme);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether the current file format supports conversion
  bool get _isConvertibleFormat {
    final lower = cleanFilePath.toLowerCase();
    return lower.endsWith('.flac') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.opus') ||
        lower.endsWith('.ogg');
  }

  String get _currentFileFormat {
    final lower = cleanFilePath.toLowerCase();
    if (lower.endsWith('.flac')) return 'FLAC';
    if (lower.endsWith('.mp3')) return 'MP3';
    if (lower.endsWith('.opus') || lower.endsWith('.ogg')) return 'Opus';
    return 'Unknown';
  }

  Map<String, String> _buildFallbackMetadata() {
    return {
      'TITLE': trackName,
      'ARTIST': artistName,
      'ALBUM': albumName,
      if (albumArtist != null && albumArtist!.isNotEmpty)
        'ALBUMARTIST': albumArtist!,
      if (trackNumber != null) 'TRACKNUMBER': trackNumber.toString(),
      if (discNumber != null) 'DISCNUMBER': discNumber.toString(),
      if (releaseDate != null && releaseDate!.isNotEmpty) 'DATE': releaseDate!,
      if (isrc != null && isrc!.isNotEmpty) 'ISRC': isrc!,
      if (genre != null && genre!.isNotEmpty) 'GENRE': genre!,
      if (label != null && label!.isNotEmpty) 'LABEL': label!,
      if (copyright != null && copyright!.isNotEmpty) 'COPYRIGHT': copyright!,
    };
  }

  Map<String, String> _mapMetadataForTagEmbed(Map<String, dynamic> source) {
    final mapped = <String, String>{};

    void put(String key, dynamic value) {
      final normalized = value?.toString().trim();
      if (normalized == null || normalized.isEmpty) return;
      mapped[key] = normalized;
    }

    put('TITLE', source['title']);
    put('ARTIST', source['artist']);
    put('ALBUM', source['album']);
    put('ALBUMARTIST', source['album_artist']);
    put('DATE', source['date']);
    put('ISRC', source['isrc']);
    put('GENRE', source['genre']);
    put('ORGANIZATION', source['label']);
    put('COPYRIGHT', source['copyright']);
    put('COMPOSER', source['composer']);
    put('COMMENT', source['comment']);

    final trackNumber = source['track_number'];
    if (trackNumber != null && trackNumber.toString() != '0') {
      put('TRACKNUMBER', trackNumber);
    }
    final discNumber = source['disc_number'];
    if (discNumber != null && discNumber.toString() != '0') {
      put('DISCNUMBER', discNumber);
    }

    return mapped;
  }

  String _buildConvertedQualityLabel(String targetFormat, String bitrate) {
    final normalizedBitrate = bitrate.trim().toLowerCase();
    return '${targetFormat.toUpperCase()} $normalizedBitrate';
  }

  String? _extractLossyBitrateLabel(String? quality) {
    if (quality == null || quality.isEmpty) return null;
    final match = RegExp(
      r'(\d+)\s*k(?:bps)?',
      caseSensitive: false,
    ).firstMatch(quality);
    if (match == null) return null;
    return '${match.group(1)}kbps';
  }

  String _extractFileNameFromPathOrUri(String pathOrUri) {
    if (pathOrUri.isEmpty) return '';
    try {
      if (pathOrUri.startsWith('content://')) {
        final uri = Uri.parse(pathOrUri);
        if (uri.pathSegments.isNotEmpty) {
          var last = Uri.decodeComponent(uri.pathSegments.last);
          if (last.contains('/')) {
            last = last.split('/').last;
          }
          if (last.contains(':')) {
            last = last.split(':').last;
          }
          if (last.isNotEmpty) return last;
        }
      }
    } catch (_) {}

    final normalized = pathOrUri.replaceAll('\\', '/');
    if (normalized.contains('/')) {
      return normalized.split('/').last;
    }
    return normalized;
  }

  void _showConvertSheet(BuildContext context) {
    final currentFormat = _currentFileFormat;
    // Available target formats (exclude current)
    final formats = <String>[
      'MP3',
      'Opus',
    ].where((f) => f != currentFormat).toList();
    if (currentFormat == 'FLAC') {
      // FLAC can convert to both
    }

    String selectedFormat = formats.first;
    String selectedBitrate = selectedFormat == 'Opus' ? '128k' : '320k';

    showModalBottomSheet(
      context: context,
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
                      context.l10n.trackConvertTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Target format
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
                                  // Reset bitrate to default for format
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

                    // Bitrate
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

                    // Convert button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmAndConvert(
                            context: this.context,
                            sourceFormat: currentFormat,
                            targetFormat: selectedFormat,
                            bitrate: selectedBitrate,
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '$currentFormat  ->  $selectedFormat @ $selectedBitrate',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmAndConvert({
    required BuildContext context,
    required String sourceFormat,
    required String targetFormat,
    required String bitrate,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.l10n.trackConvertConfirmTitle),
          content: Text(
            dialogContext.l10n.trackConvertConfirmMessage(
              sourceFormat,
              targetFormat,
              bitrate,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performConversion(
                  targetFormat: targetFormat,
                  bitrate: bitrate,
                );
              },
              child: Text(dialogContext.l10n.trackConvertFormat),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performConversion({
    required String targetFormat,
    required String bitrate,
  }) async {
    if (_isConverting) return;
    setState(() => _isConverting = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.trackConvertConverting)),
      );

      // Step 1: Read metadata from file (fallback to known item metadata).
      final metadata = _buildFallbackMetadata();
      try {
        final result = await PlatformBridge.readFileMetadata(cleanFilePath);
        if (result['error'] == null) {
          result.forEach((key, value) {
            if (key == 'error' || value == null) return;
            final normalizedValue = value.toString().trim();
            if (normalizedValue.isEmpty) return;
            metadata[key.toUpperCase()] = normalizedValue;
          });
        } else {
          _log.w('readFileMetadata returned error, using fallback metadata');
        }
      } catch (e) {
        _log.w('readFileMetadata threw, using fallback metadata: $e');
      }

      // Step 2: Extract cover art to temp file
      String? coverPath;
      try {
        final tempDir = await getTemporaryDirectory();
        final coverOutput =
            '${tempDir.path}${Platform.pathSeparator}convert_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final coverResult = await PlatformBridge.extractCoverToFile(
          cleanFilePath,
          coverOutput,
        );
        if (coverResult['error'] == null) {
          coverPath = coverOutput;
        }
      } catch (_) {}

      // Step 3: Handle SAF vs regular file
      String workingPath = cleanFilePath;
      final isSaf = _isSafFile;
      String? safTempPath;

      if (isSaf) {
        // Copy SAF file to temp for processing
        safTempPath = await PlatformBridge.copyContentUriToTemp(cleanFilePath);
        if (safTempPath == null) {
          if (mounted) {
            setState(() => _isConverting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.trackConvertFailed)),
            );
          }
          return;
        }
        workingPath = safTempPath;
      }

      // Step 4: Convert
      final newPath = await FFmpegService.convertAudioFormat(
        inputPath: workingPath,
        targetFormat: targetFormat.toLowerCase(),
        bitrate: bitrate,
        metadata: metadata,
        coverPath: coverPath,
        deleteOriginal: !isSaf, // Don't delete temp copy for SAF, we handle it
      );

      // Cleanup cover temp
      if (coverPath != null) {
        try {
          await File(coverPath).delete();
        } catch (_) {}
      }

      if (newPath == null) {
        // Cleanup SAF temp if needed
        if (safTempPath != null) {
          try {
            await File(safTempPath).delete();
          } catch (_) {}
        }
        if (mounted) {
          setState(() => _isConverting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.trackConvertFailed)),
          );
        }
        return;
      }

      final newQuality = _buildConvertedQualityLabel(targetFormat, bitrate);

      // Step 5: Handle SAF write-back
      if (isSaf) {
        final treeUri = _downloadItem?.downloadTreeUri;
        final relativeDir = _downloadItem?.safRelativeDir ?? '';
        if (treeUri == null || treeUri.isEmpty) {
          try {
            await File(newPath).delete();
          } catch (_) {}
          if (safTempPath != null) {
            try {
              await File(safTempPath).delete();
            } catch (_) {}
          }
          if (mounted) {
            setState(() => _isConverting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.trackConvertFailed)),
            );
          }
          return;
        }

        final oldFileName =
            (_downloadItem?.safFileName != null &&
                _downloadItem!.safFileName!.isNotEmpty)
            ? _downloadItem!.safFileName!
            : _extractFileNameFromPathOrUri(cleanFilePath);
        final dotIdx = oldFileName.lastIndexOf('.');
        final baseName = dotIdx > 0
            ? oldFileName.substring(0, dotIdx)
            : oldFileName;
        final newExt = targetFormat.toLowerCase() == 'opus' ? '.opus' : '.mp3';
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
          if (mounted) {
            setState(() => _isConverting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.trackConvertFailed)),
            );
          }
          return;
        }

        final deletedOriginal = await PlatformBridge.safDelete(
          cleanFilePath,
        ).catchError((_) => false);
        if (deletedOriginal != true) {
          _log.w('Converted SAF file created but failed deleting original URI');
        }

        // Update history with new SAF info
        if (!_isLocalItem) {
          await HistoryDatabase.instance.updateFilePath(
            _downloadItem!.id,
            safUri,
            newSafFileName: newFileName,
            newQuality: newQuality,
            clearAudioSpecs: true,
          );
          await ref.read(downloadHistoryProvider.notifier).reloadFromStorage();
        }

        // Cleanup temp files
        try {
          await File(newPath).delete();
        } catch (_) {}
        if (safTempPath != null) {
          try {
            await File(safTempPath).delete();
          } catch (_) {}
        }
      } else {
        // Regular file: update history with new path
        if (!_isLocalItem) {
          await HistoryDatabase.instance.updateFilePath(
            _downloadItem!.id,
            newPath,
            newQuality: newQuality,
            clearAudioSpecs: true,
          );
          await ref.read(downloadHistoryProvider.notifier).reloadFromStorage();
        }
      }

      if (mounted) {
        setState(() => _isConverting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.trackConvertSuccess(targetFormat)),
          ),
        );
        // Pop and let the caller refresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConverting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.trackSaveFailed(e.toString()))),
        );
      }
    }
  }

  void _showEditMetadataSheet(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) async {
    // Read current metadata from file, fall back to item data on failure
    Map<String, dynamic>? fileMetadata;
    try {
      final result = await PlatformBridge.readFileMetadata(cleanFilePath);
      if (result['error'] == null) {
        fileMetadata = result;
      }
    } catch (e) {
      debugPrint('readFileMetadata failed, using item data: $e');
    }

    // Build initial values map — prefer file metadata, fall back to item data
    String val(String key, String? fallback) {
      final v = fileMetadata?[key]?.toString();
      return (v != null && v.isNotEmpty) ? v : (fallback ?? '');
    }

    final initialValues = <String, String>{
      'title': val('title', trackName),
      'artist': val('artist', artistName),
      'album': val('album', albumName),
      'album_artist': val('album_artist', albumArtist),
      'date': val('date', releaseDate),
      'track_number': (fileMetadata?['track_number'] ?? trackNumber ?? '')
          .toString(),
      'disc_number': (fileMetadata?['disc_number'] ?? discNumber ?? '')
          .toString(),
      'genre': val('genre', genre),
      'isrc': val('isrc', isrc),
      'label': val('label', label),
      'copyright': val('copyright', copyright),
      'composer': fileMetadata?['composer']?.toString() ?? '',
      'comment': fileMetadata?['comment']?.toString() ?? '',
    };

    if (!context.mounted) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _EditMetadataSheet(
        colorScheme: colorScheme,
        initialValues: initialValues,
        filePath: cleanFilePath,
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Metadata saved successfully')),
      );
      // Re-read metadata from file to refresh the display
      try {
        final refreshed = await PlatformBridge.readFileMetadata(cleanFilePath);
        setState(() => _editedMetadata = refreshed);
      } catch (_) {
        setState(() {});
      }
      await _refreshEmbeddedCoverPreview(force: true);
      _markMetadataChanged();
      await _syncDownloadHistoryMetadata();
    }
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.trackDeleteConfirmTitle),
        content: Text(context.l10n.trackDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.dialogCancel),
          ),
          TextButton(
            onPressed: () async {
              if (_isLocalItem) {
                // For local items, just delete the file
                try {
                  await deleteFile(cleanFilePath);
                } catch (e) {
                  debugPrint('Failed to delete file: $e');
                }
                // Also remove from local library database
                // ref.read(localLibraryProvider.notifier).removeItem(_localLibraryItem!.id);
              } else {
                // Existing download history deletion logic
                try {
                  await deleteFile(cleanFilePath);
                } catch (e) {
                  debugPrint('Failed to delete file: $e');
                }

                ref
                    .read(downloadHistoryProvider.notifier)
                    .removeFromHistory(_downloadItem!.id);
              }

              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text(
              context.l10n.dialogDelete,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String filePath) async {
    try {
      await openFile(filePath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.snackbarCannotOpenFile(e.toString())),
          ),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.trackCopiedToClipboard),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareFile(BuildContext context) async {
    String sharePath = cleanFilePath;
    if (!await fileExists(sharePath)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.snackbarFileNotFound)),
        );
      }
      return;
    }

    final shareTitle = '$trackName - $artistName';

    // For SAF content URIs, use native share intent directly (zero-copy)
    if (isContentUri(sharePath)) {
      try {
        await PlatformBridge.shareContentUri(sharePath, title: shareTitle);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.snackbarCannotOpenFile('Failed to share file'),
              ),
            ),
          );
        }
      }
      return;
    }

    await SharePlus.instance.share(
      ShareParams(files: [XFile(sharePath)], text: shareTitle),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  IconData _getServiceIcon(String service) {
    switch (service.toLowerCase()) {
      case 'tidal':
        return Icons.waves;
      case 'qobuz':
        return Icons.album;
      case 'amazon':
        return Icons.shopping_cart;
      default:
        return Icons.cloud_download;
    }
  }

  Color _getServiceColor(String service, ColorScheme colorScheme) {
    switch (service.toLowerCase()) {
      case 'tidal':
        return const Color(0xFF0077B5);
      case 'qobuz':
        return const Color(0xFF0052CC);
      case 'amazon':
        return const Color(0xFFFF9900);
      default:
        return colorScheme.primary;
    }
  }
}

class _EditMetadataSheet extends StatefulWidget {
  final ColorScheme colorScheme;
  final Map<String, String> initialValues;
  final String filePath;

  const _EditMetadataSheet({
    required this.colorScheme,
    required this.initialValues,
    required this.filePath,
  });

  @override
  State<_EditMetadataSheet> createState() => _EditMetadataSheetState();
}

class _EditMetadataSheetState extends State<_EditMetadataSheet> {
  bool _saving = false;
  bool _showAdvanced = false;
  String? _selectedCoverPath;
  String? _selectedCoverTempDir;
  String? _selectedCoverName;
  String? _currentCoverPath;
  String? _currentCoverTempDir;
  bool _loadingCurrentCover = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _artistCtrl;
  late final TextEditingController _albumCtrl;
  late final TextEditingController _albumArtistCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _trackNumCtrl;
  late final TextEditingController _discNumCtrl;
  late final TextEditingController _genreCtrl;
  late final TextEditingController _isrcCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _copyrightCtrl;
  late final TextEditingController _composerCtrl;
  late final TextEditingController _commentCtrl;

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  String _resolveImageExtension(String? ext, Uint8List? bytes) {
    final normalized = (ext ?? '').toLowerCase();
    if (normalized == 'png' ||
        normalized == 'jpg' ||
        normalized == 'jpeg' ||
        normalized == 'webp') {
      return normalized == 'jpeg' ? 'jpg' : normalized;
    }
    if (bytes != null && bytes.length >= 8) {
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'png';
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return 'jpg';
      }
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'webp';
      }
    }
    return 'jpg';
  }

  Future<void> _cleanupSelectedCoverTemp() async {
    final dirPath = _selectedCoverTempDir;
    _selectedCoverPath = null;
    _selectedCoverTempDir = null;
    _selectedCoverName = null;
    if (dirPath == null || dirPath.isEmpty) return;
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  void _cleanupSelectedCoverTempSync() {
    final dirPath = _selectedCoverTempDir;
    _selectedCoverPath = null;
    _selectedCoverTempDir = null;
    _selectedCoverName = null;
    if (dirPath == null || dirPath.isEmpty) return;
    try {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {}
  }

  void _cleanupCurrentCoverTempSync() {
    final dirPath = _currentCoverTempDir;
    _currentCoverPath = null;
    _currentCoverTempDir = null;
    if (dirPath == null || dirPath.isEmpty) return;
    try {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> _loadCurrentCoverPreview() async {
    if (_loadingCurrentCover) return;
    setState(() => _loadingCurrentCover = true);
    String? newCoverPath;
    String? newCoverDir;
    try {
      final tempDir = await Directory.systemTemp.createTemp(
        'edit_existing_cover_',
      );
      final coverOutput =
          '${tempDir.path}${Platform.pathSeparator}existing_cover.jpg';
      final coverResult = await PlatformBridge.extractCoverToFile(
        widget.filePath,
        coverOutput,
      );
      if (coverResult['error'] == null && await File(coverOutput).exists()) {
        newCoverPath = coverOutput;
        newCoverDir = tempDir.path;
      } else {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}

    if (!mounted) {
      if (newCoverDir != null) {
        try {
          final dir = Directory(newCoverDir);
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
        } catch (_) {}
      }
      return;
    }

    final oldDir = _currentCoverTempDir;
    setState(() {
      _currentCoverPath = newCoverPath;
      _currentCoverTempDir = newCoverDir;
      _loadingCurrentCover = false;
    });
    if (oldDir != null && oldDir.isNotEmpty && oldDir != newCoverDir) {
      try {
        final dir = Directory(oldDir);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final bytes = picked.bytes;
      final sourcePath = picked.path;
      final extension = _resolveImageExtension(picked.extension, bytes);

      final tempDir = await Directory.systemTemp.createTemp('edit_cover_');
      final tempPath =
          '${tempDir.path}${Platform.pathSeparator}cover.$extension';

      if (bytes != null && bytes.isNotEmpty) {
        await File(tempPath).writeAsBytes(bytes, flush: true);
      } else if (sourcePath != null && sourcePath.isNotEmpty) {
        final sourceFile = File(sourcePath);
        if (!await sourceFile.exists()) {
          throw Exception('Selected image is not accessible');
        }
        await sourceFile.copy(tempPath);
      } else {
        throw Exception('Unable to read selected image');
      }

      await _cleanupSelectedCoverTemp();
      if (!mounted) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
        return;
      }
      setState(() {
        _selectedCoverPath = tempPath;
        _selectedCoverTempDir = tempDir.path;
        _selectedCoverName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick cover: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    final v = widget.initialValues;
    _titleCtrl = TextEditingController(text: v['title'] ?? '');
    _artistCtrl = TextEditingController(text: v['artist'] ?? '');
    _albumCtrl = TextEditingController(text: v['album'] ?? '');
    _albumArtistCtrl = TextEditingController(text: v['album_artist'] ?? '');
    _dateCtrl = TextEditingController(text: v['date'] ?? '');
    _trackNumCtrl = TextEditingController(text: v['track_number'] ?? '');
    _discNumCtrl = TextEditingController(text: v['disc_number'] ?? '');
    _genreCtrl = TextEditingController(text: v['genre'] ?? '');
    _isrcCtrl = TextEditingController(text: v['isrc'] ?? '');
    _labelCtrl = TextEditingController(text: v['label'] ?? '');
    _copyrightCtrl = TextEditingController(text: v['copyright'] ?? '');
    _composerCtrl = TextEditingController(text: v['composer'] ?? '');
    _commentCtrl = TextEditingController(text: v['comment'] ?? '');
    _loadCurrentCoverPreview();
  }

  @override
  void dispose() {
    _cleanupSelectedCoverTempSync();
    _cleanupCurrentCoverTempSync();
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    _albumArtistCtrl.dispose();
    _dateCtrl.dispose();
    _trackNumCtrl.dispose();
    _discNumCtrl.dispose();
    _genreCtrl.dispose();
    _isrcCtrl.dispose();
    _labelCtrl.dispose();
    _copyrightCtrl.dispose();
    _composerCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final metadata = <String, String>{
      'title': _titleCtrl.text,
      'artist': _artistCtrl.text,
      'album': _albumCtrl.text,
      'album_artist': _albumArtistCtrl.text,
      'date': _dateCtrl.text,
      'track_number': _trackNumCtrl.text,
      'disc_number': _discNumCtrl.text,
      'genre': _genreCtrl.text,
      'isrc': _isrcCtrl.text,
      'label': _labelCtrl.text,
      'copyright': _copyrightCtrl.text,
      'composer': _composerCtrl.text,
      'comment': _commentCtrl.text,
      'cover_path': _selectedCoverPath ?? '',
    };

    try {
      final result = await PlatformBridge.editFileMetadata(
        widget.filePath,
        metadata,
      );

      if (result['error'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${result['error']}')));
        }
        setState(() => _saving = false);
        return;
      }

      final method = result['method'] as String?;

      if (method == 'ffmpeg') {
        // MP3/Opus: use FFmpeg to write metadata
        // For SAF files, Kotlin returns temp_path + saf_uri
        final tempPath = result['temp_path'] as String?;
        final safUri = result['saf_uri'] as String?;
        final ffmpegTarget = tempPath ?? widget.filePath;

        final lower = widget.filePath.toLowerCase();
        final isMp3 = lower.endsWith('.mp3');
        final isOpus = lower.endsWith('.opus') || lower.endsWith('.ogg');

        final vorbisMap = <String, String>{};
        if (metadata['title']?.isNotEmpty == true) {
          vorbisMap['TITLE'] = metadata['title']!;
        }
        if (metadata['artist']?.isNotEmpty == true) {
          vorbisMap['ARTIST'] = metadata['artist']!;
        }
        if (metadata['album']?.isNotEmpty == true) {
          vorbisMap['ALBUM'] = metadata['album']!;
        }
        if (metadata['album_artist']?.isNotEmpty == true) {
          vorbisMap['ALBUMARTIST'] = metadata['album_artist']!;
        }
        if (metadata['date']?.isNotEmpty == true) {
          vorbisMap['DATE'] = metadata['date']!;
        }
        if (metadata['track_number']?.isNotEmpty == true &&
            metadata['track_number'] != '0') {
          vorbisMap['TRACKNUMBER'] = metadata['track_number']!;
        }
        if (metadata['disc_number']?.isNotEmpty == true &&
            metadata['disc_number'] != '0') {
          vorbisMap['DISCNUMBER'] = metadata['disc_number']!;
        }
        if (metadata['genre']?.isNotEmpty == true) {
          vorbisMap['GENRE'] = metadata['genre']!;
        }
        if (metadata['isrc']?.isNotEmpty == true) {
          vorbisMap['ISRC'] = metadata['isrc']!;
        }
        if (metadata['label']?.isNotEmpty == true) {
          vorbisMap['ORGANIZATION'] = metadata['label']!;
        }
        if (metadata['copyright']?.isNotEmpty == true) {
          vorbisMap['COPYRIGHT'] = metadata['copyright']!;
        }
        if (metadata['composer']?.isNotEmpty == true) {
          vorbisMap['COMPOSER'] = metadata['composer']!;
        }
        if (metadata['comment']?.isNotEmpty == true) {
          vorbisMap['COMMENT'] = metadata['comment']!;
        }

        String? existingCoverPath = _selectedCoverPath ?? _currentCoverPath;
        String? extractedCoverPath;
        if (existingCoverPath == null || existingCoverPath.isEmpty) {
          // Preserve current embedded cover when user does not pick a new one.
          try {
            final tempDir = await Directory.systemTemp.createTemp('cover_');
            final coverOutput =
                '${tempDir.path}${Platform.pathSeparator}cover.jpg';
            final coverResult = await PlatformBridge.extractCoverToFile(
              ffmpegTarget,
              coverOutput,
            );
            if (coverResult['error'] == null) {
              existingCoverPath = coverOutput;
              extractedCoverPath = coverOutput;
            } else {
              try {
                await tempDir.delete(recursive: true);
              } catch (_) {}
            }
          } catch (_) {
            // No cover to preserve, continue without
          }
        }

        String? ffmpegResult;
        if (isMp3) {
          ffmpegResult = await FFmpegService.embedMetadataToMp3(
            mp3Path: ffmpegTarget,
            coverPath: existingCoverPath,
            metadata: vorbisMap,
          );
        } else if (isOpus) {
          ffmpegResult = await FFmpegService.embedMetadataToOpus(
            opusPath: ffmpegTarget,
            coverPath: existingCoverPath,
            metadata: vorbisMap,
          );
        }

        // Cleanup extracted temp cover (manual selected cover is cleaned on dispose)
        if (extractedCoverPath != null && extractedCoverPath.isNotEmpty) {
          final extractedFile = File(extractedCoverPath);
          try {
            await extractedFile.delete();
          } catch (_) {}
          try {
            final dir = extractedFile.parent;
            if (await dir.exists()) {
              await dir.delete(recursive: true);
            }
          } catch (_) {}
        }

        if (ffmpegResult == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save metadata via FFmpeg'),
              ),
            );
          }
          setState(() => _saving = false);
          return;
        }

        // For SAF files, copy the processed temp file back
        if (tempPath != null && safUri != null) {
          final ok = await PlatformBridge.writeTempToSaf(ffmpegResult, safUri);
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to write metadata back to storage'),
              ),
            );
            setState(() => _saving = false);
            return;
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save metadata: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Metadata',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_saving)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Fields
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 6),
                  _buildCoverEditor(cs),
                  _field('Title', _titleCtrl),
                  _field('Artist', _artistCtrl),
                  _field('Album', _albumCtrl),
                  _field('Album Artist', _albumArtistCtrl),
                  _field('Date', _dateCtrl, hint: 'YYYY-MM-DD or YYYY'),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'Track #',
                          _trackNumCtrl,
                          keyboard: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          'Disc #',
                          _discNumCtrl,
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _field('Genre', _genreCtrl),
                  _field('ISRC', _isrcCtrl),
                  // Advanced fields toggle
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: InkWell(
                      onTap: () =>
                          setState(() => _showAdvanced = !_showAdvanced),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _showAdvanced
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Advanced',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_showAdvanced) ...[
                    _field('Label', _labelCtrl),
                    _field('Copyright', _copyrightCtrl),
                    _field('Composer', _composerCtrl),
                    _field('Comment', _commentCtrl, maxLines: 3),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverEditor(ColorScheme cs) {
    final hasSelectedCover = _hasValue(_selectedCoverPath);
    final hasCurrentCover = _hasValue(_currentCoverPath);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cover Art',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 6),
            if (_loadingCurrentCover)
              const LinearProgressIndicator(minHeight: 2)
            else if (!hasCurrentCover)
              Text(
                'No embedded album art found',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _pickCoverImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      hasSelectedCover ? 'Replace Cover' : 'Pick Cover',
                    ),
                  ),
                ),
                if (hasSelectedCover) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Clear selected cover',
                    onPressed: _saving
                        ? null
                        : () async {
                            await _cleanupSelectedCoverTemp();
                            if (!mounted) return;
                            setState(() {});
                          },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            if (hasCurrentCover || hasSelectedCover) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (hasCurrentCover)
                    Expanded(
                      child: _buildCoverPreviewTile(
                        cs: cs,
                        path: _currentCoverPath!,
                        label: 'Current cover',
                      ),
                    ),
                  if (hasCurrentCover && hasSelectedCover)
                    const SizedBox(width: 12),
                  if (hasSelectedCover)
                    Expanded(
                      child: _buildCoverPreviewTile(
                        cs: cs,
                        path: _selectedCoverPath!,
                        label: _selectedCoverName ?? 'Selected cover',
                      ),
                    ),
                ],
              ),
              if (hasSelectedCover) ...[
                const SizedBox(height: 8),
                Text(
                  'The selected cover will replace the current embedded cover when you tap Save.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPreviewTile({
    required ColorScheme cs,
    required String path,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              height: 160,
              width: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.broken_image,
                  color: cs.onSurfaceVariant,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    final cs = widget.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _MetadataItem {
  final String label;
  final String value;

  _MetadataItem(this.label, this.value);
}
