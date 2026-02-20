import 'dart:io';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/playback_item.dart';
import 'package:spotiflac_android/providers/playback_provider.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';

// ─── Mini Player Bar ─────────────────────────────────────────────────────────
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackProvider);
    final playbackError = _localizedPlaybackError(context, state);
    final item = state.currentItem;
    if (item == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final durationMs = state.duration.inMilliseconds;
    final positionMs = state.position.inMilliseconds.clamp(
      0,
      durationMs > 0 ? durationMs : 0,
    );
    final progress = durationMs > 0 ? positionMs / durationMs : 0.0;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => _showExpandedPlayer(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
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
                  if (state.isBuffering || state.isLoading)
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
                      state.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    onPressed: () =>
                        ref.read(playbackProvider.notifier).togglePlayPause(),
                  ),
                  // Next
                  if (state.hasNext || state.repeatMode == RepeatMode.all)
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 22),
                      onPressed: () =>
                          ref.read(playbackProvider.notifier).skipNext(),
                    ),
                  // Close
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => ref.read(playbackProvider.notifier).stop(),
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
    final playbackError = _localizedPlaybackError(context, state);
    final item = state.currentItem;
    if (item == null) {
      // Track stopped, close the player
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final duration = state.duration;
    final position = state.position;
    final maxSeconds = duration.inMilliseconds > 0
        ? duration.inSeconds.toDouble()
        : 0.0;
    final currentSeconds = position.inSeconds.toDouble().clamp(
      0.0,
      maxSeconds > 0 ? maxSeconds : 0.0,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar (close + title + lyrics toggle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 30,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                  const Spacer(),
                  // Queue info
                  if (state.queue.length > 1)
                    Text(
                      '${state.currentIndex + 1} / ${state.queue.length}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const Spacer(),
                  // Lyrics toggle button
                  IconButton(
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

            // ── Main content area (swipeable cover / lyrics)
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // Page 0: Cover art
                  _CoverArtPage(item: item, colorScheme: colorScheme),
                  // Page 1: Lyrics
                  _LyricsPage(
                    state: state,
                    colorScheme: colorScheme,
                    onRetry: () =>
                        ref.read(playbackProvider.notifier).refetchLyrics(),
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
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PageDot(active: _currentPage == 0, colorScheme: colorScheme),
                  const SizedBox(width: 6),
                  _PageDot(active: _currentPage == 1, colorScheme: colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Track info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (item.album.isNotEmpty) ...[
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
            const SizedBox(height: 4),

            // ── Quality + Service badge row
            _QualityServiceRow(item: item, colorScheme: colorScheme),
            const SizedBox(height: 4),

            // ── Error message
            if (playbackError != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  value: currentSeconds,
                  max: maxSeconds > 0 ? maxSeconds : 1,
                  onChanged: state.seekSupported
                      ? (value) {
                          ref
                              .read(playbackProvider.notifier)
                              .seek(Duration(seconds: value.round()));
                        }
                      : null,
                ),
              ),
            ),

            // ── Duration labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
            const SizedBox(height: 4),

            // ── Playback controls
            _PlaybackControls(state: state),
            const SizedBox(height: 16),
          ],
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
}

String? _localizedPlaybackError(BuildContext context, PlaybackState state) {
  final raw = (state.error ?? '').trim();
  if (raw.isEmpty) {
    return null;
  }
  if (state.errorType == 'seek_not_supported') {
    return context.l10n.errorSeekNotSupported;
  }
  if (state.errorType == 'not_found') {
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
                  fontSize: isCurrent ? 22 : 18,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? widget.colorScheme.onSurface
                      : isPast
                          ? widget.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.35)
                          : widget.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.55),
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
      fontSize: 22,
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
              fontSize: 18,
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

// ─── Playback Controls ───────────────────────────────────────────────────────
class _PlaybackControls extends ConsumerWidget {
  final PlaybackState state;

  const _PlaybackControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(playbackProvider.notifier);
    final hasPrev = state.hasPrevious || state.repeatMode == RepeatMode.all;
    final hasNext = state.hasNext || state.repeatMode == RepeatMode.all;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: state.shuffle
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 22,
          ),
          onPressed: notifier.toggleShuffle,
          tooltip: 'Shuffle',
        ),
        const SizedBox(width: 4),

        // Previous
        IconButton(
          iconSize: 32,
          onPressed: hasPrev ? notifier.skipPrevious : null,
          icon: Icon(
            Icons.skip_previous_rounded,
            color: hasPrev
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          tooltip: 'Previous',
        ),
        const SizedBox(width: 8),

        // Play / Pause (large)
        SizedBox(
          width: 64,
          height: 64,
          child: IconButton.filled(
            iconSize: 36,
            onPressed: notifier.togglePlayPause,
            icon: state.isBuffering || state.isLoading
                ? SizedBox(
                    width: 28,
                    height: 28,
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
        const SizedBox(width: 8),

        // Next
        IconButton(
          iconSize: 32,
          onPressed: hasNext ? notifier.skipNext : null,
          icon: Icon(
            Icons.skip_next_rounded,
            color: hasNext
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          tooltip: 'Next',
        ),
        const SizedBox(width: 4),

        // Repeat
        IconButton(
          icon: Icon(
            state.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: state.repeatMode != RepeatMode.off
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 22,
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
