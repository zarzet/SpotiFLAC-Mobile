import 'dart:io';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/playback_item.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/playback_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/widgets/download_service_picker.dart';

// ─── Mini Player Bar ─────────────────────────────────────────────────────────
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateSnapshot = ref.watch(
      playbackProvider.select(
        (s) => (
          currentItem: s.currentItem,
          isPlaying: s.isPlaying,
          isBuffering: s.isBuffering,
          isLoading: s.isLoading,
          hasNext: s.hasNext,
          repeatMode: s.repeatMode,
          error: s.error,
          errorType: s.errorType,
        ),
      ),
    );
    final playbackError = _localizedPlaybackErrorFromRaw(
      context,
      stateSnapshot.error,
      stateSnapshot.errorType,
    );
    final item = stateSnapshot.currentItem;
    if (item == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => _showExpandedPlayer(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _MiniPlayerProgressBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Cover art
                  _CoverArt(
                    url: item.coverUrl,
                    isLocal: item.hasLocalCover,
                    size: 40,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 10),
                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          item.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  // Error indicator
                  if (playbackError != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 20,
                        color: colorScheme.error,
                      ),
                    ),
                  // Loading indicator
                  if (stateSnapshot.isBuffering || stateSnapshot.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  // Play / Pause
                  IconButton(
                    icon: Icon(
                      stateSnapshot.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    onPressed: () =>
                        ref.read(playbackProvider.notifier).togglePlayPause(),
                  ),
                  // Next
                  if (stateSnapshot.hasNext ||
                      stateSnapshot.repeatMode == RepeatMode.all)
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 22),
                      onPressed: () =>
                          ref.read(playbackProvider.notifier).skipNext(),
                    ),
                  // Close
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () =>
                        ref.read(playbackProvider.notifier).dismissPlayer(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpandedPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const _FullScreenPlayer(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _MiniPlayerProgressBar extends ConsumerWidget {
  const _MiniPlayerProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(
      playbackProvider.select(
        (s) => (position: s.position, duration: s.duration),
      ),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final durationMs = progressState.duration.inMilliseconds;
    final positionMs = progressState.position.inMilliseconds.clamp(
      0,
      durationMs > 0 ? durationMs : 0,
    );
    final progress = durationMs > 0 ? positionMs / durationMs : 0.0;

    return LinearProgressIndicator(
      value: progress,
      minHeight: 2,
      backgroundColor: colorScheme.surfaceContainerHighest,
    );
  }
}

// ─── Full-Screen Player ──────────────────────────────────────────────────────
class _FullScreenPlayer extends ConsumerStatefulWidget {
  const _FullScreenPlayer();

  @override
  ConsumerState<_FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends ConsumerState<_FullScreenPlayer> {
  // 0 = cover art view, 1 = lyrics view
  int _currentPage = 0;
  late final PageController _pageController;
  bool _isScrubbing = false;
  double _scrubSeconds = 0;
  String? _lastLyricsPrefetchKey;
  AppLifecycleListener? _appLifecycleListener;
  bool _isAppResumed = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final initialState = WidgetsBinding.instance.lifecycleState;
    _isAppResumed =
        initialState == null || initialState == AppLifecycleState.resumed;
    _appLifecycleListener = AppLifecycleListener(
      onResume: () {
        _isAppResumed = true;
        if (!mounted) return;
        final state = ref.read(playbackProvider);
        _prefetchLyricsForCurrentTrack(state);
      },
      onPause: () => _isAppResumed = false,
      onHide: () => _isAppResumed = false,
      onDetach: () => _isAppResumed = false,
      onInactive: () => _isAppResumed = false,
    );
  }

  @override
  void dispose() {
    _appLifecycleListener?.dispose();
    _appLifecycleListener = null;
    _pageController.dispose();
    super.dispose();
  }

  String _lyricsPrefetchKey(PlaybackItem item) {
    return '${item.id}|${item.title}|${item.artist}';
  }

  void _prefetchLyricsForCurrentTrack(PlaybackState state) {
    if (!_isAppResumed) return;
    final item = state.currentItem;
    if (item == null) return;

    final key = _lyricsPrefetchKey(item);
    if (_lastLyricsPrefetchKey == key) return;
    _lastLyricsPrefetchKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(playbackProvider.notifier).ensureLyricsLoaded());
    });
  }

  void _switchToLyrics() {
    setState(() => _currentPage = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _switchToCover() {
    setState(() => _currentPage = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);
    final displayOrder = playbackNotifier.getQueueDisplayOrder();
    final displayPosition = playbackNotifier.getCurrentDisplayQueuePosition(
      displayOrder: displayOrder,
    );
    final queuePositionLabel = displayPosition >= 0
        ? displayPosition + 1
        : state.currentIndex + 1;
    final playbackError = _localizedPlaybackError(context, state);
    final item = state.currentItem;
    if (item == null) {
      _lastLyricsPrefetchKey = null;
      // Track stopped, close the player
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }
    _prefetchLyricsForCurrentTrack(state);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.sizeOf(context);
    final isLandscape = screenSize.width > screenSize.height;

    final duration = state.duration;
    final position = state.position;
    final maxSeconds = duration.inMilliseconds > 0
        ? duration.inSeconds.toDouble()
        : 0.0;
    final currentSeconds = position.inSeconds.toDouble().clamp(
      0.0,
      maxSeconds > 0 ? maxSeconds : 0.0,
    );
    final sliderSeconds = _isScrubbing
        ? _scrubSeconds.clamp(0.0, maxSeconds > 0 ? maxSeconds : 0.0)
        : currentSeconds;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactLayout = isLandscape || constraints.maxHeight < 620;
            final mediaSectionHeight =
                (constraints.maxHeight * (isCompactLayout ? 0.32 : 0.50)).clamp(
                  isCompactLayout ? 140.0 : 260.0,
                  isCompactLayout ? 280.0 : 560.0,
                );
            final horizontalPadding = isCompactLayout ? 16.0 : 24.0;
            final verticalGap = isCompactLayout ? 2.0 : 4.0;
            final showAlbum = item.album.isNotEmpty && !isCompactLayout;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    // ── Top bar (close + title + lyrics toggle)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: isCompactLayout ? 2 : 4,
                      ),
                      child: Row(
                        children: [
                          // ── Left side
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 30,
                                ),
                                visualDensity: isCompactLayout
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                                onPressed: () => Navigator.of(context).pop(),
                                tooltip: 'Close',
                              ),
                            ),
                          ),
                          // ── Center: Queue info
                          if (state.queue.length > 1)
                            GestureDetector(
                              onTap: () => _showQueueSheet(context, ref),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.queue_music_rounded,
                                      size: 16,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$queuePositionLabel / ${state.queue.length}',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // ── Right side
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!item.isLocal && item.track != null)
                                  _DownloadButton(
                                    item: item,
                                    compact: isCompactLayout,
                                  ),
                                IconButton(
                                  visualDensity: isCompactLayout
                                      ? VisualDensity.compact
                                      : VisualDensity.standard,
                                  icon: Icon(
                                    Icons.lyrics_outlined,
                                    color: _currentPage == 1
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    if (_currentPage == 0) {
                                      _switchToLyrics();
                                    } else {
                                      _switchToCover();
                                    }
                                  },
                                  tooltip: 'Lyrics',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Main content area (swipeable cover / lyrics)
                    SizedBox(
                      height: mediaSectionHeight,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (page) =>
                            setState(() => _currentPage = page),
                        children: [
                          // Page 0: Cover art
                          _CoverArtPage(item: item, colorScheme: colorScheme),
                          // Page 1: Lyrics
                          _LyricsPage(
                            state: state,
                            colorScheme: colorScheme,
                            onRetry: () => ref
                                .read(playbackProvider.notifier)
                                .refetchLyrics(),
                            onSeek: state.seekSupported
                                ? (ms) => ref
                                      .read(playbackProvider.notifier)
                                      .seek(Duration(milliseconds: ms))
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // ── Page indicator dots
                    Padding(
                      padding: EdgeInsets.only(top: isCompactLayout ? 4 : 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PageDot(
                            active: _currentPage == 0,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(width: 6),
                          _PageDot(
                            active: _currentPage == 1,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isCompactLayout ? 4 : 8),

                    // ── Track info
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style:
                                (isCompactLayout
                                        ? textTheme.titleMedium
                                        : textTheme.titleLarge)
                                    ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: verticalGap),
                          Text(
                            item.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (isCompactLayout
                                        ? textTheme.bodySmall
                                        : textTheme.bodyMedium)
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                          if (showAlbum) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.album,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: verticalGap),

                    // ── Quality + Service badge row
                    _QualityServiceRow(item: item, colorScheme: colorScheme),
                    SizedBox(height: verticalGap),

                    // ── Error message
                    if (playbackError != null)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalGap,
                        ),
                        child: Text(
                          playbackError,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),

                    // ── Seek slider
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompactLayout ? 12 : 16,
                      ),
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor: colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                        ),
                        child: Slider(
                          value: sliderSeconds,
                          max: maxSeconds > 0 ? maxSeconds : 1,
                          onChangeStart: state.seekSupported && maxSeconds > 0
                              ? (value) {
                                  setState(() {
                                    _isScrubbing = true;
                                    _scrubSeconds = value;
                                  });
                                }
                              : null,
                          onChanged: state.seekSupported
                              ? (value) {
                                  if (!_isScrubbing) {
                                    setState(() {
                                      _isScrubbing = true;
                                    });
                                  }
                                  setState(() {
                                    _scrubSeconds = value;
                                  });
                                }
                              : null,
                          onChangeEnd: state.seekSupported
                              ? (value) async {
                                  setState(() {
                                    _scrubSeconds = value;
                                    _isScrubbing = false;
                                  });
                                  await ref
                                      .read(playbackProvider.notifier)
                                      .seek(
                                        Duration(
                                          milliseconds: (value * 1000).round(),
                                        ),
                                      );
                                }
                              : null,
                        ),
                      ),
                    ),

                    // ── Duration labels
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: verticalGap),

                    // ── Playback controls
                    _PlaybackControls(state: state, compact: isCompactLayout),
                    SizedBox(height: verticalGap),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showQueueSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QueueBottomSheet(ref: ref),
    );
  }
}

String? _localizedPlaybackError(BuildContext context, PlaybackState state) {
  return _localizedPlaybackErrorFromRaw(context, state.error, state.errorType);
}

String? _localizedPlaybackErrorFromRaw(
  BuildContext context,
  String? error,
  String? errorType,
) {
  final raw = (error ?? '').trim();
  if (raw.isEmpty) {
    return null;
  }
  if (errorType == 'seek_not_supported') {
    return context.l10n.errorSeekNotSupported;
  }
  if (errorType == 'not_found') {
    return context.l10n.errorNoTracksFound;
  }
  return raw;
}

// ─── Page dot indicator ──────────────────────────────────────────────────────
class _PageDot extends StatelessWidget {
  final bool active;
  final ColorScheme colorScheme;

  const _PageDot({required this.active, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 16 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? colorScheme.primary : colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ─── Cover Art Page ──────────────────────────────────────────────────────────
class _CoverArtPage extends StatelessWidget {
  final PlaybackItem item;
  final ColorScheme colorScheme;

  const _CoverArtPage({required this.item, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: AspectRatio(
          aspectRatio: 1,
          child: _CoverArt(
            url: item.coverUrl,
            isLocal: item.hasLocalCover,
            size: double.infinity,
            borderRadius: 20,
          ),
        ),
      ),
    );
  }
}

// ─── Lyrics Page ─────────────────────────────────────────────────────────────
class _LyricsPage extends StatelessWidget {
  final PlaybackState state;
  final ColorScheme colorScheme;
  final VoidCallback onRetry;
  final ValueChanged<int>? onSeek;

  const _LyricsPage({
    required this.state,
    required this.colorScheme,
    required this.onRetry,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    if (state.lyricsLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading lyrics...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final lyrics = state.lyrics;
    if (lyrics == null || lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No lyrics available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (lyrics.instrumental) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 48,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Instrumental',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (lyrics.isSynced) {
      return _SyncedLyricsView(
        lyrics: lyrics,
        positionMs: state.position.inMilliseconds,
        colorScheme: colorScheme,
        onSeek: onSeek,
      );
    }

    // Unsynced lyrics: simple scrollable text
    return _UnsyncedLyricsView(lyrics: lyrics, colorScheme: colorScheme);
  }
}

// ─── Synced Lyrics View (line + word-by-word) ────────────────────────────────
class _SyncedLyricsView extends StatefulWidget {
  final LyricsData lyrics;
  final int positionMs;
  final ColorScheme colorScheme;
  final ValueChanged<int>? onSeek;

  const _SyncedLyricsView({
    required this.lyrics,
    required this.positionMs,
    required this.colorScheme,
    required this.onSeek,
  });

  @override
  State<_SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<_SyncedLyricsView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentLineKey = GlobalKey();
  int _lastScrolledLine = -1;
  int _lastQueuedScrollLine = -1;
  int? _pendingAutoScrollLine;
  bool _userScrolling = false;
  bool _isAutoScrolling = false;
  Timer? _userScrollTimer;
  double _viewHeight = 400;

  @override
  void dispose() {
    _scrollController.dispose();
    _userScrollTimer?.cancel();
    super.dispose();
  }

  int _findCurrentLineIndex() {
    final pos = widget.positionMs;
    final lines = widget.lyrics.lines;
    if (lines.isEmpty) return -1;

    // Binary search: find the last line whose startMs <= current position.
    var left = 0;
    var right = lines.length - 1;
    var result = -1;
    while (left <= right) {
      final mid = left + ((right - left) >> 1);
      if (lines[mid].startMs <= pos) {
        result = mid;
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }
    return result;
  }

  double? _targetOffsetFromCurrentLineKey() {
    if (!_scrollController.hasClients) return null;
    final keyContext = _currentLineKey.currentContext;
    if (keyContext == null) return null;
    final renderObject = keyContext.findRenderObject();
    if (renderObject == null) return null;
    final viewport = RenderAbstractViewport.of(renderObject);
    final target = viewport.getOffsetToReveal(renderObject, 0.4).offset;
    return target
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();
  }

  Duration _autoScrollDuration(double distancePx) {
    final clampedDistance = distancePx.clamp(80.0, 900.0);
    var ms = (160 + (clampedDistance / 2.4)).round();
    if (ms < 180) ms = 180;
    if (ms > 560) ms = 560;
    return Duration(milliseconds: ms);
  }

  Future<void> _scrollToLine(int index) async {
    if (_userScrolling || !_scrollController.hasClients) return;
    if (_isAutoScrolling) {
      _pendingAutoScrollLine = index;
      return;
    }
    if (index == _lastScrolledLine) return;
    _lastScrolledLine = index;

    double targetOffset;
    final fromKey = _targetOffsetFromCurrentLineKey();
    if (fromKey != null) {
      targetOffset = fromKey;
    } else {
      // Fallback: estimate-based scroll for off-screen items
      const lineHeight = 44.0;
      final topPad = _viewHeight * 0.4;
      targetOffset = topPad + (index * lineHeight) - (_viewHeight * 0.4);
      targetOffset = targetOffset
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();
    }

    final distance = (targetOffset - _scrollController.offset).abs();
    if (distance < 1.0) return;

    _isAutoScrolling = true;
    try {
      await _scrollController.animateTo(
        targetOffset,
        duration: _autoScrollDuration(distance),
        curve: Curves.easeInOutCubicEmphasized,
      );
    } catch (_) {
      // Ignore interrupted scroll animations; latest queued target will run next.
    } finally {
      _isAutoScrolling = false;
      final pending = _pendingAutoScrollLine;
      _pendingAutoScrollLine = null;
      if (pending != null && pending != index && mounted) {
        unawaited(_scrollToLine(pending));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLine = _findCurrentLineIndex();

    // Auto-scroll only when the target line changes.
    if (currentLine >= 0 && currentLine != _lastQueuedScrollLine) {
      _lastQueuedScrollLine = currentLine;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_scrollToLine(currentLine));
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewHeight = constraints.maxHeight;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _userScrolling = true;
              _userScrollTimer?.cancel();
              _pendingAutoScrollLine = null;
            }
            if (notification is ScrollEndNotification && _userScrolling) {
              _userScrollTimer = Timer(const Duration(seconds: 4), () {
                _userScrolling = false;
                _isAutoScrolling = false;
                _lastScrolledLine = -1; // Force re-scroll
                _lastQueuedScrollLine = -1;
                _pendingAutoScrollLine = null;
              });
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: _viewHeight * 0.4,
              bottom: _viewHeight * 0.4,
            ),
            itemCount: widget.lyrics.lines.length,
            itemBuilder: (context, index) {
              final line = widget.lyrics.lines[index];
              final isCurrent = index == currentLine;
              final isPast = index < currentLine;

              Widget lineWidget;

              if (line.text.isEmpty) {
                // Empty line = interlude gap
                lineWidget = const SizedBox(height: 32);
              } else {
                // Target style — AnimatedDefaultTextStyle will
                // smoothly tween fontSize / fontWeight / color.
                final targetStyle = TextStyle(
                  fontSize: isCurrent ? 24 : 19,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? widget.colorScheme.onSurface
                      : isPast
                      ? widget.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.35,
                        )
                      : widget.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.55,
                        ),
                  height: 1.4,
                );

                lineWidget = GestureDetector(
                  onTap: widget.onSeek == null
                      ? null
                      : () => widget.onSeek!(line.startMs),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      style: targetStyle,
                      child: line.hasWordSync
                          ? _WordByWordLine(
                              line: line,
                              positionMs: widget.positionMs,
                              colorScheme: widget.colorScheme,
                              isCurrent: isCurrent,
                            )
                          : Text(line.text),
                    ),
                  ),
                );
              }

              // Attach key to the current line for scroll targeting.
              if (isCurrent && line.text.isNotEmpty) {
                return KeyedSubtree(key: _currentLineKey, child: lineWidget);
              }
              return lineWidget;
            },
          ),
        );
      },
    );
  }
}

// ─── Word-by-Word Highlighted Line ───────────────────────────────────────────
class _WordByWordLine extends StatelessWidget {
  final LyricsLine line;
  final int positionMs;
  final ColorScheme colorScheme;
  final bool isCurrent;

  const _WordByWordLine({
    required this.line,
    required this.positionMs,
    required this.colorScheme,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    // When not the current line, render plain text that inherits the
    // animated style from the parent AnimatedDefaultTextStyle.
    if (!isCurrent) {
      return Text(line.text);
    }

    // Current line: word-by-word gradient sweep
    final baseStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.4,
    );
    final inactiveColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.35);
    final sungColor = colorScheme.onSurface;
    final activeColor = colorScheme.primary;

    return Wrap(
      children: line.words.map((word) {
        final isCurrentWord =
            positionMs >= word.startMs && positionMs < word.endMs;
        final isSung = positionMs >= word.endMs;
        final wordProgress = isSung
            ? 1.0
            : isCurrentWord && word.endMs > word.startMs
            ? ((positionMs - word.startMs) / (word.endMs - word.startMs)).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return _AnimatedWordToken(
          text: word.text,
          progress: wordProgress,
          isCurrentWord: isCurrentWord,
          baseStyle: baseStyle,
          inactiveColor: inactiveColor,
          sungColor: sungColor,
          activeColor: activeColor,
        );
      }).toList(),
    );
  }
}

class _AnimatedWordToken extends StatelessWidget {
  final String text;
  final double progress;
  final bool isCurrentWord;
  final TextStyle baseStyle;
  final Color inactiveColor;
  final Color sungColor;
  final Color activeColor;

  const _AnimatedWordToken({
    required this.text,
    required this.progress,
    required this.isCurrentWord,
    required this.baseStyle,
    required this.inactiveColor,
    required this.sungColor,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final hasSweep = p > 0.0 && p < 1.0;
    final settledColor = p >= 1.0 ? sungColor : inactiveColor;

    return AnimatedScale(
      scale: isCurrentWord ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Stack(
        children: [
          Text(text, style: baseStyle.copyWith(color: settledColor)),
          if (hasSweep)
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: p,
                child: Text(
                  text,
                  style: baseStyle.copyWith(color: activeColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Unsynced Lyrics View ────────────────────────────────────────────────────
class _UnsyncedLyricsView extends StatelessWidget {
  final LyricsData lyrics;
  final ColorScheme colorScheme;

  const _UnsyncedLyricsView({required this.lyrics, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      itemCount: lyrics.lines.length,
      itemBuilder: (context, index) {
        final line = lyrics.lines[index];
        if (line.text.isEmpty) return const SizedBox(height: 24);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            line.text,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        );
      },
    );
  }
}

// ─── Quality + Service Row ───────────────────────────────────────────────────
class _QualityServiceRow extends StatelessWidget {
  final PlaybackItem item;
  final ColorScheme colorScheme;

  const _QualityServiceRow({required this.item, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final qualityLabel = item.qualityLabel;
    final serviceLabel = _serviceDisplayName(item.service);

    if (qualityLabel.isEmpty && serviceLabel.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          if (serviceLabel.isNotEmpty)
            _Chip(
              icon: Icons.cloud_outlined,
              label: serviceLabel,
              colorScheme: colorScheme,
            ),
          if (qualityLabel.isNotEmpty)
            _Chip(
              icon: Icons.graphic_eq_rounded,
              label: qualityLabel,
              colorScheme: colorScheme,
            ),
        ],
      ),
    );
  }

  String _serviceDisplayName(String service) {
    if (service.isEmpty) return '';
    switch (service.toLowerCase()) {
      case 'tidal':
        return 'Tidal';
      case 'qobuz':
        return 'Qobuz';
      case 'amazon':
        return 'Amazon Music';
      case 'youtube':
        return 'YouTube';
      case 'offline':
        return 'Local file';
      default:
        if (service.isNotEmpty) {
          return service[0].toUpperCase() + service.substring(1);
        }
        return service;
    }
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _Chip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Download Button ─────────────────────────────────────────────────────────
class _DownloadButton extends ConsumerWidget {
  final PlaybackItem item;
  final bool compact;

  const _DownloadButton({required this.item, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = item.track;
    if (track == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final iconSize = compact ? 18.0 : 22.0;

    return IconButton(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      icon: Icon(
        Icons.download_rounded,
        color: colorScheme.onSurfaceVariant,
        size: iconSize,
      ),
      onPressed: () => _onDownloadTap(context, ref, track),
      tooltip: context.l10n.downloadTitle,
    );
  }

  void _onDownloadTap(BuildContext context, WidgetRef ref, Track track) {
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
        SnackBar(
          content: Text(context.l10n.snackbarAddedToQueue(track.name)),
        ),
      );
    }
  }
}

// ─── Playback Controls ───────────────────────────────────────────────────────
class _PlaybackControls extends ConsumerWidget {
  final PlaybackState state;
  final bool compact;

  const _PlaybackControls({required this.state, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(playbackProvider.notifier);
    final hasPrev = state.hasPrevious || state.repeatMode == RepeatMode.all;
    final hasNext = state.hasNext || state.repeatMode == RepeatMode.all;
    final sideIconSize = compact ? 18.0 : 22.0;
    final skipIconSize = compact ? 28.0 : 32.0;
    final mainButtonSize = compact ? 54.0 : 64.0;
    final mainIconSize = compact ? 30.0 : 36.0;
    final loadingSize = compact ? 24.0 : 28.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle
        IconButton(
          visualDensity: compact
              ? VisualDensity.compact
              : VisualDensity.standard,
          icon: Icon(
            Icons.shuffle_rounded,
            color: state.shuffle
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: sideIconSize,
          ),
          onPressed: notifier.toggleShuffle,
          tooltip: 'Shuffle',
        ),
        SizedBox(width: compact ? 2 : 4),

        // Previous
        IconButton(
          iconSize: skipIconSize,
          visualDensity: compact
              ? VisualDensity.compact
              : VisualDensity.standard,
          onPressed: hasPrev ? notifier.skipPrevious : null,
          icon: Icon(
            Icons.skip_previous_rounded,
            color: hasPrev
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          tooltip: 'Previous',
        ),
        SizedBox(width: compact ? 4 : 8),

        // Play / Pause (large)
        SizedBox(
          width: mainButtonSize,
          height: mainButtonSize,
          child: IconButton.filled(
            iconSize: mainIconSize,
            onPressed: notifier.togglePlayPause,
            icon: state.isBuffering || state.isLoading
                ? SizedBox(
                    width: loadingSize,
                    height: loadingSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            tooltip: state.isPlaying ? 'Pause' : 'Play',
          ),
        ),
        SizedBox(width: compact ? 4 : 8),

        // Next
        IconButton(
          iconSize: skipIconSize,
          visualDensity: compact
              ? VisualDensity.compact
              : VisualDensity.standard,
          onPressed: hasNext ? notifier.skipNext : null,
          icon: Icon(
            Icons.skip_next_rounded,
            color: hasNext
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          tooltip: 'Next',
        ),
        SizedBox(width: compact ? 2 : 4),

        // Repeat
        IconButton(
          visualDensity: compact
              ? VisualDensity.compact
              : VisualDensity.standard,
          icon: Icon(
            state.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: state.repeatMode != RepeatMode.off
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: sideIconSize,
          ),
          onPressed: notifier.cycleRepeatMode,
          tooltip: _repeatTooltip(state.repeatMode),
        ),
      ],
    );
  }

  String _repeatTooltip(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return 'Repeat: Off';
      case RepeatMode.all:
        return 'Repeat: All';
      case RepeatMode.one:
        return 'Repeat: One';
    }
  }
}

// ─── Cover Art Widget (supports both network and local) ──────────────────────
class _CoverArt extends StatelessWidget {
  final String url;
  final bool isLocal;
  final double size;
  final double borderRadius;

  const _CoverArt({
    required this.url,
    required this.isLocal,
    required this.size,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (url.trim().isEmpty) {
      return _placeholder(colorScheme);
    }

    if (isLocal) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(url),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: size.isFinite ? (size * 3).toInt() : null,
          cacheHeight: size.isFinite ? (size * 3).toInt() : null,
          errorBuilder: (_, _, _) => _placeholder(colorScheme),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: size.isFinite ? (size * 3).toInt() : null,
        memCacheHeight: size.isFinite ? (size * 3).toInt() : null,
        cacheManager: CoverCacheManager.instance,
        errorWidget: (_, _, _) => _placeholder(colorScheme),
      ),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    final iconSize = size.isFinite ? size * 0.4 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: iconSize,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ─── Queue Bottom Sheet ──────────────────────────────────────────────────────
class _QueueBottomSheet extends ConsumerWidget {
  final WidgetRef ref;

  const _QueueBottomSheet({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final queue = state.queue;
    final displayOrder = playbackNotifier.getQueueDisplayOrder();
    final currentDisplayIndex = playbackNotifier.getCurrentDisplayQueuePosition(
      displayOrder: displayOrder,
    );
    if (queue.isEmpty || displayOrder.isEmpty || currentDisplayIndex < 0) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Queue',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${queue.length} tracks',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Queue list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount:
                    queue.length +
                    _sectionHeaderCount(currentDisplayIndex, queue.length),
                itemBuilder: (context, index) {
                  // Calculate real item index accounting for section headers
                  return _buildQueueListItem(
                    context,
                    ref,
                    index,
                    queue,
                    displayOrder,
                    currentDisplayIndex,
                    colorScheme,
                    textTheme,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  int _sectionHeaderCount(int currentIndex, int queueLength) {
    int count = 0;
    if (currentIndex > 0) count++; // "Already Played" header
    count++; // "Now Playing" header
    if (currentIndex < queueLength - 1) count++; // "Up Next" header
    return count;
  }

  Widget _buildQueueListItem(
    BuildContext context,
    WidgetRef ref,
    int listIndex,
    List<PlaybackItem> queue,
    List<int> displayOrder,
    int currentDisplayIndex,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Build a flat list: [played header?, played items, now playing header,
    //                     now playing item, up next header?, up next items]
    int offset = 0;

    // Section: Already Played
    if (currentDisplayIndex > 0) {
      if (listIndex == offset) {
        return _sectionHeader(
          'Played',
          Icons.history_rounded,
          colorScheme,
          textTheme,
        );
      }
      offset++;
      if (listIndex < offset + currentDisplayIndex) {
        final displayIdx = listIndex - offset;
        final queueIdx = displayOrder[displayIdx];
        return _queueTrackTile(
          context,
          ref,
          queue[queueIdx],
          queueIdx,
          displayIdx,
          colorScheme,
          textTheme,
          isPlayed: true,
        );
      }
      offset += currentDisplayIndex;
    }

    // Section: Now Playing
    if (listIndex == offset) {
      return _sectionHeader(
        'Now Playing',
        Icons.play_circle_filled_rounded,
        colorScheme,
        textTheme,
        isPrimary: true,
      );
    }
    offset++;
    if (listIndex == offset) {
      final queueIdx = displayOrder[currentDisplayIndex];
      return _queueTrackTile(
        context,
        ref,
        queue[queueIdx],
        queueIdx,
        currentDisplayIndex,
        colorScheme,
        textTheme,
        isCurrent: true,
      );
    }
    offset++;

    // Section: Up Next
    if (currentDisplayIndex < queue.length - 1) {
      if (listIndex == offset) {
        final upNextCount = queue.length - currentDisplayIndex - 1;
        return _sectionHeader(
          'Up Next ($upNextCount)',
          Icons.skip_next_rounded,
          colorScheme,
          textTheme,
        );
      }
      offset++;
      final displayIdx = currentDisplayIndex + 1 + (listIndex - offset);
      if (displayIdx < queue.length) {
        final queueIdx = displayOrder[displayIdx];
        return _queueTrackTile(
          context,
          ref,
          queue[queueIdx],
          queueIdx,
          displayIdx,
          colorScheme,
          textTheme,
        );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _sectionHeader(
    String title,
    IconData icon,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isPrimary
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isPrimary
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueTrackTile(
    BuildContext context,
    WidgetRef ref,
    PlaybackItem item,
    int queueIndex,
    int displayIndex,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isCurrent = false,
    bool isPlayed = false,
  }) {
    final opacity = isPlayed ? 0.5 : 1.0;

    return Material(
      color: isCurrent
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: isCurrent
            ? null
            : () {
                ref.read(playbackProvider.notifier).playQueueIndex(queueIndex);
                Navigator.of(context).pop();
              },
        child: Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Track number in queue
                SizedBox(
                  width: 28,
                  child: Text(
                    '${displayIndex + 1}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: isCurrent
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Cover art
                _CoverArt(
                  url: item.coverUrl,
                  isLocal: item.hasLocalCover,
                  size: 44,
                  borderRadius: 8,
                ),
                const SizedBox(width: 12),
                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isCurrent
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Now playing indicator
                if (isCurrent)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.equalizer_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                // Remove from queue button (for up next items only)
                if (!isCurrent && !isPlayed)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(playbackProvider.notifier)
                          .removeFromQueue(queueIndex);
                    },
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
