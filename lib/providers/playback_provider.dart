import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotiflac_android/models/playback_item.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/providers/library_collections_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/services/ffmpeg_service.dart';
import 'package:spotiflac_android/services/library_database.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/artist_utils.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:spotiflac_android/services/download_request_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = AppLogger('PlaybackProvider');

// ─── Repeat mode ─────────────────────────────────────────────────────────────
enum RepeatMode { off, all, one }

// ─── Lyrics types ────────────────────────────────────────────────────────────

/// A single word/syllable within a lyrics line, with its own timing.
class LyricsWord {
  final String text;
  final int startMs;
  final int endMs;

  const LyricsWord({
    required this.text,
    required this.startMs,
    required this.endMs,
  });
}

/// A single lyrics line, optionally with per-word timing.
class LyricsLine {
  final int startMs;
  final int endMs;
  final String text;
  final List<LyricsWord> words;

  const LyricsLine({
    required this.startMs,
    required this.endMs,
    required this.text,
    this.words = const [],
  });

  bool get hasWordSync => words.isNotEmpty;
}

/// Parsed lyrics data ready for display.
class LyricsData {
  final List<LyricsLine> lines;
  final String syncType; // LINE_SYNCED, UNSYNCED
  final String source; // LRCLIB, Apple Music, etc.
  final bool instrumental;
  final bool isWordSynced; // true if any line has word-level timing

  const LyricsData({
    this.lines = const [],
    this.syncType = '',
    this.source = '',
    this.instrumental = false,
    this.isWordSynced = false,
  });

  bool get isSynced => syncType == 'LINE_SYNCED';
  bool get isEmpty => lines.isEmpty && !instrumental;
}

// ─── State ───────────────────────────────────────────────────────────────────
class PlaybackState {
  final PlaybackItem? currentItem;
  final bool isPlaying;
  final bool isBuffering;
  final bool isLoading;
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  final String? error;
  final String? errorType;
  final bool seekSupported;

  // Queue
  final List<PlaybackItem> queue;
  final int currentIndex;
  final bool shuffle;
  final RepeatMode repeatMode;

  // Lyrics
  final LyricsData? lyrics;
  final bool lyricsLoading;

  const PlaybackState({
    this.currentItem,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration = Duration.zero,
    this.error,
    this.errorType,
    this.seekSupported = true,
    this.queue = const [],
    this.currentIndex = -1,
    this.shuffle = false,
    this.repeatMode = RepeatMode.off,
    this.lyrics,
    this.lyricsLoading = false,
  });

  bool get hasNext => queue.isNotEmpty && currentIndex < queue.length - 1;
  bool get hasPrevious => queue.isNotEmpty && currentIndex > 0;

  PlaybackState copyWith({
    PlaybackItem? currentItem,
    bool clearCurrentItem = false,
    bool? isPlaying,
    bool? isBuffering,
    bool? isLoading,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    String? error,
    String? errorType,
    bool? seekSupported,
    bool clearError = false,
    List<PlaybackItem>? queue,
    int? currentIndex,
    bool? shuffle,
    RepeatMode? repeatMode,
    LyricsData? lyrics,
    bool clearLyrics = false,
    bool? lyricsLoading,
  }) {
    return PlaybackState(
      currentItem: clearCurrentItem ? null : (currentItem ?? this.currentItem),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
      errorType: clearError ? null : (errorType ?? this.errorType),
      seekSupported: seekSupported ?? this.seekSupported,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffle: shuffle ?? this.shuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      lyrics: clearLyrics ? null : (lyrics ?? this.lyrics),
      lyricsLoading: lyricsLoading ?? this.lyricsLoading,
    );
  }
}

// ─── Audio Handler (audio_service bridge) ────────────────────────────────────
class _SpotiFLACAudioHandler extends audio_service.BaseAudioHandler
    with audio_service.SeekHandler {
  final Future<void> Function() _onPlay;
  final Future<void> Function() _onPause;
  final Future<void> Function() _onSkipNext;
  final Future<void> Function() _onSkipPrevious;
  final Future<void> Function() _onStop;
  final Future<void> Function(Duration position) _onSeek;
  final Future<void> Function() _onToggleLove;

  _SpotiFLACAudioHandler({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function() onSkipNext,
    required Future<void> Function() onSkipPrevious,
    required Future<void> Function() onStop,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onToggleLove,
  }) : _onPlay = onPlay,
       _onPause = onPause,
       _onSkipNext = onSkipNext,
       _onSkipPrevious = onSkipPrevious,
       _onStop = onStop,
       _onSeek = onSeek,
       _onToggleLove = onToggleLove;

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'toggle_love') {
      try {
        await _onToggleLove();
      } catch (e) {
        _log.e('Notification toggle love failed: $e');
      }
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> play() async {
    try {
      await _onPlay();
    } catch (e) {
      _log.e('Notification play failed: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _onPause();
    } catch (e) {
      _log.e('Notification pause failed: $e');
    }
  }

  @override
  Future<void> seek(Duration position) => _onSeek(position);

  @override
  Future<void> stop() async {
    try {
      await _onStop();
    } catch (e) {
      _log.e('Notification stop failed: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      await _onSkipNext();
    } catch (e) {
      _log.e('Notification next failed: $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      await _onSkipPrevious();
    } catch (e) {
      _log.e('Notification previous failed: $e');
    }
  }
}

// ─── Controller ──────────────────────────────────────────────────────────────
class PlaybackController extends Notifier<PlaybackState> {
  static const String _playbackSnapshotKey = 'playback_snapshot_v1';
  static const String _smartQueueModelKey = 'smart_queue_model_v1';
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _snapshotSaveTimer;
  Timer? _smartQueueModelSaveTimer;
  _SpotiFLACAudioHandler? _audioHandler;
  var _initialized = false;
  static const Duration _prefetchThresholdFloor = Duration(seconds: 12);
  static const Duration _prefetchThresholdCeiling = Duration(seconds: 40);
  static const Duration _prefetchEarlyKickoffPosition = Duration(seconds: 6);
  static const Duration _prefetchRetryCooldown = Duration(seconds: 3);
  static const int _maxPrefetchAttemptsPerTrack = 2;
  static const int _smartQueueTriggerRemainingTracks = 2;
  static const int _smartQueueTargetRemainingTracks = 6;
  static const int _smartQueueMaxAutoAddsPerSession = 40;
  static const int _smartQueueRecentPlayedWindow = 40;
  static const int _smartQueueCandidatePoolLimit = 28;
  static const int _smartQueueRelatedArtistsLimit = 3;
  static const int _smartQueueMaxAffinityKeys = 160;
  static const int _smartQueueSessionWindowSize = 10;
  static const int _smartQueueMaxArtistRepeats = 2;
  static const int _smartQueueMaxDecadeDriftYears = 20;
  static const int _smartQueueMaxTempoJumpBpm = 42;
  static const int _smartQueueMaxTempoHints = 720;
  static const int _smartQueueMaxSkipStreak = 6;
  static const double _smartQueuePrimarySourceRatio = 0.68;
  static const String _smartQueueSpotifyExtensionId = 'spotify-web';
  static const Duration _smartQueueRefillCooldown = Duration(seconds: 18);
  static const Duration _smartQueueSearchCacheTtl = Duration(minutes: 3);
  static const Duration _smartQueueFeedbackMaxAge = Duration(hours: 6);
  static const double _smartQueueLearningRate = 0.2;
  int? _prefetchingQueueIndex;
  int? _lastPrefetchAttemptIndex;
  final Map<int, int> _prefetchAttemptCounts = <int, int>{};
  final Map<int, DateTime> _prefetchLastAttemptAt = <int, DateTime>{};
  final Map<String, List<int>> _prefetchLatencyByServiceMs =
      <String, List<int>>{};
  final Random _smartQueueRandom = Random();
  final List<String> _recentPlayedTrackKeys = <String>[];
  final Map<String, _SmartQueueLearningContext>
  _smartQueuePendingFeedbackByTrack = <String, _SmartQueueLearningContext>{};
  final Map<String, _SmartQueueCachedResult> _smartQueueSearchCache =
      <String, _SmartQueueCachedResult>{};
  final Map<String, _SmartQueueRelatedArtistsCache>
  _smartQueueRelatedArtistsCache = <String, _SmartQueueRelatedArtistsCache>{};
  final Map<String, double> _smartQueueWeights = <String, double>{
    'bias': -0.15,
    'same_artist': 0.06,
    'same_album': 0.04,
    'duration_similarity': 0.8,
    'source_match': 0.18,
    'release_year_similarity': 0.32,
    'artist_affinity': 0.55,
    'source_affinity': 0.3,
    'novelty': 0.65,
    'session_alignment': 0.42,
    'hour_affinity': 0.21,
    'skip_context': 0.29,
    'tempo_continuity': 0.26,
    'year_cohesion': 0.22,
  };
  final Map<String, double> _smartQueueArtistAffinity = <String, double>{};
  final Map<String, double> _smartQueueSourceAffinity = <String, double>{};
  final Map<String, double> _smartQueueHourAffinity = <String, double>{};
  final Map<String, double> _smartQueueTempoHintByTrackKey = <String, double>{};
  final List<_SmartQueueSessionSignal> _smartQueueSessionSignals =
      <_SmartQueueSessionSignal>[];
  bool _smartQueueRefillInFlight = false;
  DateTime? _lastSmartQueueRefillAt;
  int _smartQueueAutoAddedCount = 0;
  int _smartQueueSkipStreak = 0;
  _SmartQueueSessionProfile _smartQueueSessionProfile =
      const _SmartQueueSessionProfile(
        mode: _SmartQueueSessionMode.balanced,
        targetDurationSec: 215,
        preferredSourceKey: '',
      );

  // Shuffle order: indices into queue
  List<int> _shuffleOrder = [];
  int _shufflePosition = -1;
  int _playRequestEpoch = 0;
  Duration? _pendingResumePosition;
  int? _pendingResumeIndex;
  int _lastProgressSnapshotMs = -1;
  int _lyricsGeneration = 0;
  AppLifecycleListener? _appLifecycleListener;

  @override
  PlaybackState build() {
    if (!_initialized) {
      _initialized = true;
      _init();
      ref.onDispose(_disposeInternal);
    }
    return const PlaybackState();
  }

  void _init() {
    unawaited(_configureAudioSession());
    unawaited(_initAudioService());
    unawaited(_restorePlaybackSnapshot());
    unawaited(_restoreSmartQueueModel());
    _appLifecycleListener ??= AppLifecycleListener(
      onInactive: () => unawaited(_savePlaybackSnapshot()),
      onPause: () => unawaited(_savePlaybackSnapshot()),
      onDetach: () => unawaited(_savePlaybackSnapshot()),
      onHide: () => unawaited(_savePlaybackSnapshot()),
    );

    ref.listen(libraryCollectionsProvider, (previous, next) {
      final track = state.currentItem?.track;
      if (track != null) {
        final wasLoved = previous?.isLoved(track) ?? false;
        final isLoved = next.isLoved(track);
        if (wasLoved != isLoved) {
          _syncServicePlaybackState(_player.processingState, _player.playing);
        }
      }
    });

    _subscriptions.add(
      _player.playerStateStream.listen((playerState) {
        final playing = playerState.playing;
        final processingState = playerState.processingState;

        state = state.copyWith(
          isPlaying: playing,
          isBuffering:
              processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering,
          isLoading: false,
        );

        // Update audio_service playback state
        _syncServicePlaybackState(processingState, playing);

        // Handle track completion
        if (processingState == ProcessingState.completed) {
          // Guard against premature completion (e.g. on stream connection reset during seek)
          final posMs = state.position.inMilliseconds;
          final durMs = state.duration.inMilliseconds;
          final remainingMs = durMs - posMs;

          // Only transition if we are actually near the end (within 1 second)
          // or if duration is unknown (0)
          if (durMs <= 0 || remainingMs.abs() < 1000) {
            _onTrackCompleted();
          } else {
            _log.w(
              'Premature ProcessingState.completed detected. Position: $posMs, Duration: $durMs. Ignoring completion transition.',
            );
            // Optionally try to recover if we were playing, but usually it means the stream broke.
            // For now, ignoring ensures we don't skip to the next track or restart if repeat is on.
          }
        }
      }),
    );

    _subscriptions.add(
      _player
          .createPositionStream(
            minPeriod: const Duration(milliseconds: 16),
            maxPeriod: const Duration(milliseconds: 33),
          )
          .listen((position) {
            final hasPendingResume =
                state.currentIndex >= 0 &&
                _pendingResumePositionForIndex(state.currentIndex) != null;
            final shouldKeepRestoredPosition =
                _player.processingState == ProcessingState.idle &&
                hasPendingResume &&
                position == Duration.zero &&
                state.position > Duration.zero;
            if (shouldKeepRestoredPosition) {
              return;
            }
            state = state.copyWith(position: position);
            _maybePrefetchNext(position);
            _maybeTriggerSmartQueueRefill(position);
            _scheduleSnapshotSaveForProgress(position);
          }),
    );

    _subscriptions.add(
      _player.bufferedPositionStream.listen((bufferedPosition) {
        state = state.copyWith(bufferedPosition: bufferedPosition);
      }),
    );

    _subscriptions.add(
      _player.durationStream.listen((duration) {
        final hasPendingResume =
            state.currentIndex >= 0 &&
            _pendingResumePositionForIndex(state.currentIndex) != null;
        final shouldKeepRestoredDuration =
            _player.processingState == ProcessingState.idle &&
            hasPendingResume &&
            duration == null &&
            state.duration > Duration.zero;
        if (shouldKeepRestoredDuration) {
          return;
        }
        final fallbackDuration = _fallbackDurationForItem(state.currentItem);
        final resolvedDuration = duration != null && duration > Duration.zero
            ? duration
            : fallbackDuration;
        if (state.duration != resolvedDuration) {
          state = state.copyWith(duration: resolvedDuration);
        }

        if (duration != null &&
            duration > Duration.zero &&
            state.currentIndex >= 0 &&
            state.currentIndex < state.queue.length) {
          final durationMs = duration.inMilliseconds;
          final currentItem = state.currentItem;
          final updatedCurrentItem =
              currentItem != null && currentItem.durationMs != durationMs
              ? PlaybackItem(
                  id: currentItem.id,
                  title: currentItem.title,
                  artist: currentItem.artist,
                  album: currentItem.album,
                  coverUrl: currentItem.coverUrl,
                  sourceUri: currentItem.sourceUri,
                  isLocal: currentItem.isLocal,
                  service: currentItem.service,
                  durationMs: durationMs,
                  fileSize: currentItem.fileSize,
                  format: currentItem.format,
                  bitDepth: currentItem.bitDepth,
                  sampleRate: currentItem.sampleRate,
                  bitrate: currentItem.bitrate,
                  track: currentItem.track,
                )
              : currentItem;

          final queueItem = state.queue[state.currentIndex];
          final shouldUpdateQueueItem = queueItem.durationMs != durationMs;

          if (updatedCurrentItem != currentItem || shouldUpdateQueueItem) {
            final updatedQueue = [...state.queue];
            if (shouldUpdateQueueItem) {
              updatedQueue[state.currentIndex] = PlaybackItem(
                id: queueItem.id,
                title: queueItem.title,
                artist: queueItem.artist,
                album: queueItem.album,
                coverUrl: queueItem.coverUrl,
                sourceUri: queueItem.sourceUri,
                isLocal: queueItem.isLocal,
                service: queueItem.service,
                durationMs: durationMs,
                fileSize: queueItem.fileSize,
                format: queueItem.format,
                bitDepth: queueItem.bitDepth,
                sampleRate: queueItem.sampleRate,
                bitrate: queueItem.bitrate,
                track: queueItem.track,
              );
            }

            state = state.copyWith(
              currentItem: updatedCurrentItem,
              queue: updatedQueue,
            );
            unawaited(_savePlaybackSnapshot());
          }
        }

        // Update notification duration when known
        if (state.currentItem != null && duration != null) {
          _updateMediaItemNotification(state.currentItem!);
        }
      }),
    );

    _subscriptions.add(
      _player.playbackEventStream.listen(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          _log.e('Playback error: $error');
          state = state.copyWith(
            isLoading: false,
            isPlaying: false,
            isBuffering: false,
            error: error.toString(),
            errorType: 'playback_failed',
          );
        },
      ),
    );
  }

  Future<void> _initAudioService() async {
    try {
      _audioHandler =
          await audio_service.AudioService.init<_SpotiFLACAudioHandler>(
            builder: () => _SpotiFLACAudioHandler(
              onPlay: _handleNotificationPlay,
              onPause: _handleNotificationPause,
              onSkipNext: _handleNotificationNext,
              onSkipPrevious: _handleNotificationPrevious,
              onStop: _handleNotificationStop,
              onSeek: seek,
              onToggleLove: _handleNotificationToggleLove,
            ),
            config: const audio_service.AudioServiceConfig(
              androidNotificationChannelId: 'com.zarz.spotiflac.playback',
              androidNotificationChannelName: 'Music Playback',
              androidNotificationOngoing: true,
              androidShowNotificationBadge: true,
              androidStopForegroundOnPause: true,
            ),
          );
    } catch (e) {
      _log.w('AudioService init failed: $e');
    }
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      _log.w('Audio session configuration failed: $e');
    }
  }

  Future<void> _handleNotificationPlay() async {
    if (_player.processingState == ProcessingState.idle &&
        state.queue.isNotEmpty) {
      final resumeIndex = state.currentIndex < 0 ? 0 : state.currentIndex;
      await _playQueueIndex(resumeIndex);
      return;
    }
    await _player.play();
  }

  Future<void> _handleNotificationPause() async {
    await _player.pause();
  }

  Future<void> _handleNotificationNext() async {
    await skipNext();
  }

  Future<void> _handleNotificationPrevious() async {
    await skipPrevious();
  }

  Future<void> _handleNotificationStop() async {
    await stop();
  }

  Future<void> _handleNotificationToggleLove() async {
    final track = state.currentItem?.track;
    if (track != null) {
      await ref.read(libraryCollectionsProvider.notifier).toggleLoved(track);
    }
  }

  void _syncServicePlaybackState(
    ProcessingState processingState,
    bool playing,
  ) {
    final handler = _audioHandler;
    if (handler == null) return;

    audio_service.AudioProcessingState serviceState;
    switch (processingState) {
      case ProcessingState.idle:
        serviceState = audio_service.AudioProcessingState.idle;
      case ProcessingState.loading:
        serviceState = audio_service.AudioProcessingState.loading;
      case ProcessingState.buffering:
        serviceState = audio_service.AudioProcessingState.buffering;
      case ProcessingState.ready:
        serviceState = audio_service.AudioProcessingState.ready;
      case ProcessingState.completed:
        serviceState = audio_service.AudioProcessingState.completed;
    }

    final track = state.currentItem?.track;
    final isLoved =
        track != null && ref.read(libraryCollectionsProvider).isLoved(track);

    final controls = <audio_service.MediaControl>[
      audio_service.MediaControl.custom(
        androidIcon: isLoved
            ? 'drawable/ic_stat_favorite'
            : 'drawable/ic_stat_favorite_border',
        label: isLoved ? 'Unlove' : 'Love',
        name: 'toggle_love',
      ),
      audio_service.MediaControl.skipToPrevious,
      if (playing)
        audio_service.MediaControl.pause
      else
        audio_service.MediaControl.play,
      audio_service.MediaControl.skipToNext,
    ];

    final systemActions = <audio_service.MediaAction>{};
    if (state.seekSupported) {
      systemActions.addAll(const {
        audio_service.MediaAction.seek,
        audio_service.MediaAction.seekForward,
        audio_service.MediaAction.seekBackward,
      });
    }

    handler.playbackState.add(
      audio_service.PlaybackState(
        controls: controls,
        systemActions: systemActions,
        androidCompactActionIndices: _compactIndices(controls),
        processingState: serviceState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  List<int> _compactIndices(List<audio_service.MediaControl> controls) {
    // Always show prev(0), play/pause(1), next(2) in compact notification
    final count = controls.length;
    if (count >= 3) return const [0, 1, 2];
    return List.generate(count, (i) => i);
  }

  Uri? _resolveMediaArtUri(String coverUrl) {
    final raw = coverUrl.trim();
    if (raw.isEmpty) return null;

    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('file://') ||
        raw.startsWith('content://')) {
      return Uri.tryParse(raw);
    }

    // Treat bare local paths as file URIs so notification can load local art.
    return Uri.file(raw);
  }

  void _updateMediaItemNotification(PlaybackItem item) {
    final handler = _audioHandler;
    if (handler == null) return;

    handler.mediaItem.add(
      audio_service.MediaItem(
        id: item.id,
        album: item.album,
        title: item.title,
        artist: item.artist,
        duration: state.duration,
        artUri: _resolveMediaArtUri(item.coverUrl),
        extras: {
          if ((item.track?.isrc ?? '').trim().isNotEmpty)
            'isrc': item.track!.isrc!.trim(),
          'trackName': item.title,
          'artistName': item.artist,
          if (item.album.isNotEmpty) 'albumName': item.album,
          if (item.coverUrl.isNotEmpty) 'coverUrl': item.coverUrl,
          if (item.sourceUri.isNotEmpty) 'sourceUri': item.sourceUri,
          'isLocal': item.isLocal,
          if (item.service.isNotEmpty) 'service': item.service,
          if (item.format.isNotEmpty) 'format': item.format,
        },
      ),
    );
  }

  // ─── Track completion ────────────────────────────────────────────────────
  void _onTrackCompleted() {
    _learnFromCurrentTrackOutcome(completedNaturally: true);
    final completedItem = state.currentItem;
    if (completedItem != null) {
      _rememberRecentPlayed(completedItem);
    }

    if (state.repeatMode == RepeatMode.one) {
      // Replay current track
      unawaited(_restartCurrentTrack(playAfterSeek: true));
      return;
    }

    final nextIndex = _resolveNextIndex();
    if (nextIndex != null) {
      unawaited(_playQueueIndex(nextIndex));
    } else {
      unawaited(_handleQueueExhausted());
    }
  }

  Future<void> _handleQueueExhausted() async {
    final added = await _autoRefillSmartQueue(force: true);
    if (added > 0) {
      final nextIndex = _resolveNextIndex();
      if (nextIndex != null) {
        await _playQueueIndex(nextIndex);
        return;
      }
    }

    // Queue exhausted
    state = state.copyWith(isPlaying: false, position: Duration.zero);
    _syncServicePlaybackState(ProcessingState.completed, false);
  }

  Future<void> _restartCurrentTrack({bool playAfterSeek = false}) async {
    try {
      if (state.seekSupported) {
        await _player.seek(Duration.zero);
        if (playAfterSeek) {
          await _player.play();
        }
        return;
      }

      final index = state.currentIndex;
      if (index >= 0 && index < state.queue.length) {
        await _playQueueIndex(index);
        return;
      }

      _setPlaybackError(
        'Failed to restart track from the beginning.',
        type: 'playback_failed',
      );
    } catch (e) {
      _log.e('Failed to restart current track: $e');
      _setPlaybackError('Failed to restart track: $e', type: 'playback_failed');
    }
  }

  int? _resolveNextIndex() {
    if (state.queue.isEmpty) return null;

    if (state.shuffle) {
      _shufflePosition++;
      if (_shufflePosition < _shuffleOrder.length) {
        return _shuffleOrder[_shufflePosition];
      }
      // Shuffle exhausted
      if (state.repeatMode == RepeatMode.all) {
        _regenerateShuffleOrder();
        _shufflePosition = 0;
        return _shuffleOrder.isNotEmpty ? _shuffleOrder[0] : null;
      }
      return null;
    }

    final next = state.currentIndex + 1;
    if (next < state.queue.length) return next;
    if (state.repeatMode == RepeatMode.all) return 0;
    return null;
  }

  int? _resolvePreviousIndex() {
    if (state.queue.isEmpty) return null;

    if (state.shuffle) {
      if (_shufflePosition > 0) {
        _shufflePosition--;
        return _shuffleOrder[_shufflePosition];
      }
      return null;
    }

    final prev = state.currentIndex - 1;
    if (prev >= 0) return prev;
    if (state.repeatMode == RepeatMode.all) return state.queue.length - 1;
    return null;
  }

  void _regenerateShuffleOrder() {
    final rng = Random();
    _shuffleOrder = List.generate(state.queue.length, (i) => i)..shuffle(rng);
  }

  void _regenerateShuffleOrderPreservingCurrentProgress() {
    final queueLength = state.queue.length;
    if (queueLength == 0) {
      _shuffleOrder = [];
      _shufflePosition = -1;
      return;
    }

    final currentIndex = state.currentIndex;
    if (currentIndex < 0 || currentIndex >= queueLength) {
      _regenerateShuffleOrder();
      _shufflePosition = -1;
      return;
    }

    final rng = Random();
    final playedAndCurrent = List<int>.generate(currentIndex + 1, (i) => i);
    final upcoming = List<int>.generate(
      queueLength - currentIndex - 1,
      (i) => currentIndex + i + 1,
    )..shuffle(rng);

    _shuffleOrder = <int>[...playedAndCurrent, ...upcoming];
    _shufflePosition = currentIndex;
  }

  List<int> getQueueDisplayOrder() {
    if (state.queue.isEmpty) return const [];

    if (!state.shuffle) {
      return List<int>.generate(state.queue.length, (i) => i);
    }

    final seen = <int>{};
    final normalized = <int>[];
    for (final idx in _shuffleOrder) {
      if (idx >= 0 && idx < state.queue.length && seen.add(idx)) {
        normalized.add(idx);
      }
    }
    for (var i = 0; i < state.queue.length; i++) {
      if (seen.add(i)) {
        normalized.add(i);
      }
    }
    return normalized;
  }

  int getCurrentDisplayQueuePosition({List<int>? displayOrder}) {
    final order = displayOrder ?? getQueueDisplayOrder();
    if (order.isEmpty) return -1;

    if (!state.shuffle) {
      if (state.currentIndex < 0 || state.currentIndex >= order.length) {
        return 0;
      }
      return state.currentIndex;
    }

    final position = order.indexOf(state.currentIndex);
    if (position >= 0) return position;
    return 0;
  }

  int _startNewPlayRequest() {
    _playRequestEpoch++;
    return _playRequestEpoch;
  }

  void _resetPrefetchCycleState() {
    _prefetchingQueueIndex = null;
    _lastPrefetchAttemptIndex = null;
    _prefetchAttemptCounts.clear();
    _prefetchLastAttemptAt.clear();
  }

  bool _isPlayRequestCurrent(int epoch) => epoch == _playRequestEpoch;

  void _clearLyricsForTrackChange({PlaybackItem? upcomingItem}) {
    // Invalidate any in-flight lyrics fetch from previous track.
    _lyricsGeneration++;
    state = state.copyWith(
      currentItem: upcomingItem ?? state.currentItem,
      lyricsLoading: false,
      clearLyrics: true,
    );
  }

  Map<String, dynamic> _serializePlaybackItem(PlaybackItem item) => {
    'id': item.id,
    'title': item.title,
    'artist': item.artist,
    'album': item.album,
    'coverUrl': item.coverUrl,
    'sourceUri': item.sourceUri,
    'isLocal': item.isLocal,
    'service': item.service,
    'durationMs': item.durationMs,
    'format': item.format,
    'bitDepth': item.bitDepth,
    'sampleRate': item.sampleRate,
    'bitrate': item.bitrate,
    if (item.track != null) 'track': item.track!.toJson(),
  };

  PlaybackItem? _deserializePlaybackItem(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = (json['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) return null;

    Track? track;
    try {
      final trackJson = json['track'];
      if (trackJson is Map) {
        track = Track.fromJson(Map<String, dynamic>.from(trackJson));
      }
    } catch (_) {}

    return PlaybackItem(
      id: id,
      title: (json['title'] as String?) ?? '',
      artist: (json['artist'] as String?) ?? '',
      album: (json['album'] as String?) ?? '',
      coverUrl: (json['coverUrl'] as String?) ?? '',
      sourceUri: (json['sourceUri'] as String?) ?? '',
      isLocal: json['isLocal'] == true,
      service: (json['service'] as String?) ?? '',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      format: (json['format'] as String?) ?? '',
      bitDepth: (json['bitDepth'] as num?)?.toInt() ?? 0,
      sampleRate: (json['sampleRate'] as num?)?.toInt() ?? 0,
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 0,
      track: track,
    );
  }

  Future<void> _savePlaybackSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'queue': state.queue
            .map(_serializePlaybackItem)
            .toList(growable: false),
        'currentIndex': state.currentIndex,
        'positionMs': state.position.inMilliseconds,
        'durationMs': state.duration > Duration.zero
            ? state.duration.inMilliseconds
            : (state.currentItem?.durationMs ?? 0),
        'shuffle': state.shuffle,
        'repeatMode': state.repeatMode.index,
      };
      await prefs.setString(_playbackSnapshotKey, jsonEncode(payload));
    } catch (e) {
      _log.w('Failed to save playback snapshot: $e');
    }
  }

  Future<void> _restorePlaybackSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_playbackSnapshotKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final payload = Map<String, dynamic>.from(decoded);

      final queueRaw = payload['queue'];
      final restoredQueue = <PlaybackItem>[];
      if (queueRaw is List) {
        for (final entry in queueRaw) {
          if (entry is! Map) continue;
          final item = _deserializePlaybackItem(
            Map<String, dynamic>.from(entry),
          );
          if (item != null) restoredQueue.add(item);
        }
      }
      if (restoredQueue.isEmpty) return;

      var restoredIndex = (payload['currentIndex'] as num?)?.toInt() ?? 0;
      restoredIndex = restoredIndex.clamp(0, restoredQueue.length - 1).toInt();
      final restoredPositionMs = (payload['positionMs'] as num?)?.toInt() ?? 0;
      final restoredDurationMs = (payload['durationMs'] as num?)?.toInt() ?? 0;
      final restoredRepeatIndex = (payload['repeatMode'] as num?)?.toInt() ?? 0;
      final restoredRepeatMode =
          restoredRepeatIndex >= 0 &&
              restoredRepeatIndex < RepeatMode.values.length
          ? RepeatMode.values[restoredRepeatIndex]
          : RepeatMode.off;

      state = state.copyWith(
        queue: restoredQueue,
        currentIndex: restoredIndex,
        currentItem: restoredQueue[restoredIndex],
        isPlaying: false,
        isBuffering: false,
        isLoading: false,
        position: Duration(milliseconds: restoredPositionMs),
        bufferedPosition: Duration.zero,
        duration: restoredDurationMs > 0
            ? Duration(milliseconds: restoredDurationMs)
            : (restoredQueue[restoredIndex].durationMs > 0
                  ? Duration(
                      milliseconds: restoredQueue[restoredIndex].durationMs,
                    )
                  : Duration.zero),
        shuffle: payload['shuffle'] == true,
        repeatMode: restoredRepeatMode,
        clearError: true,
      );
      _pendingResumePosition = restoredPositionMs > 0
          ? Duration(milliseconds: restoredPositionMs)
          : null;
      _pendingResumeIndex = restoredPositionMs > 0 ? restoredIndex : null;
      _lastProgressSnapshotMs = restoredPositionMs;

      if (state.shuffle) {
        _regenerateShuffleOrder();
        _shufflePosition = _shuffleOrder.indexOf(state.currentIndex);
        if (_shufflePosition < 0) _shufflePosition = 0;
      } else {
        _shuffleOrder = [];
        _shufflePosition = -1;
      }
    } catch (e) {
      _log.w('Failed to restore playback snapshot: $e');
    }
  }

  Future<void> _restoreSmartQueueModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_smartQueueModelKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final payload = Map<String, dynamic>.from(decoded);

      final weightsRaw = payload['weights'];
      if (weightsRaw is Map) {
        for (final entry in weightsRaw.entries) {
          final key = entry.key.toString();
          final value = (entry.value as num?)?.toDouble();
          if (value == null) continue;
          _smartQueueWeights[key] = value;
        }
      }

      _smartQueueArtistAffinity.clear();
      final artistRaw = payload['artistAffinity'];
      if (artistRaw is Map) {
        for (final entry in artistRaw.entries) {
          final key = entry.key.toString().trim().toLowerCase();
          if (key.isEmpty) continue;
          final value = (entry.value as num?)?.toDouble();
          if (value == null) continue;
          _smartQueueArtistAffinity[key] = value.clamp(-1.0, 1.0);
        }
      }

      _smartQueueSourceAffinity.clear();
      final sourceRaw = payload['sourceAffinity'];
      if (sourceRaw is Map) {
        for (final entry in sourceRaw.entries) {
          final key = entry.key.toString().trim().toLowerCase();
          if (key.isEmpty) continue;
          final value = (entry.value as num?)?.toDouble();
          if (value == null) continue;
          _smartQueueSourceAffinity[key] = value.clamp(-1.0, 1.0);
        }
      }

      _smartQueueHourAffinity.clear();
      final hourRaw = payload['hourAffinity'];
      if (hourRaw is Map) {
        for (final entry in hourRaw.entries) {
          final key = entry.key.toString().trim().toLowerCase();
          if (key.isEmpty) continue;
          final value = (entry.value as num?)?.toDouble();
          if (value == null) continue;
          _smartQueueHourAffinity[key] = value.clamp(-1.0, 1.0);
        }
      }
    } catch (e) {
      _log.w('Failed to restore smart queue model: $e');
    }
  }

  void _scheduleSmartQueueModelSave() {
    _smartQueueModelSaveTimer?.cancel();
    _smartQueueModelSaveTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_persistSmartQueueModel());
    });
  }

  Future<void> _persistSmartQueueModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'weights': _smartQueueWeights,
        'artistAffinity': _smartQueueArtistAffinity,
        'sourceAffinity': _smartQueueSourceAffinity,
        'hourAffinity': _smartQueueHourAffinity,
      };
      await prefs.setString(_smartQueueModelKey, jsonEncode(payload));
    } catch (e) {
      _log.w('Failed to save smart queue model: $e');
    }
  }

  PlaybackItem _buildQueueItemFromTrack(Track track) {
    final localState = ref.read(localLibraryProvider);
    final isLocalSource = (track.source ?? '').toLowerCase() == 'local';

    LocalLibraryItem? localItem;
    if (isLocalSource) {
      for (final item in localState.items) {
        if (item.id == track.id) {
          localItem = item;
          break;
        }
      }
    }

    if (localItem == null) {
      final isrc = track.isrc?.trim();
      if (isrc != null && isrc.isNotEmpty) {
        localItem = localState.getByIsrc(isrc);
      }
    }

    localItem ??= localState.findByTrackAndArtist(track.name, track.artistName);

    if (localItem != null && localItem.filePath.isNotEmpty) {
      final localUri = _uriFromPath(localItem.filePath);
      final localDurationMs =
          localItem.duration != null && localItem.duration! > 0
          ? localItem.duration! * 1000
          : _trackDurationMs(track);
      return PlaybackItem(
        id: localItem.id,
        title: localItem.trackName,
        artist: localItem.artistName,
        album: localItem.albumName,
        coverUrl: localItem.coverPath ?? track.coverUrl ?? '',
        sourceUri: localUri.toString(),
        isLocal: true,
        service: 'offline',
        durationMs: localDurationMs,
        format: localItem.format ?? '',
        bitDepth: localItem.bitDepth ?? 0,
        sampleRate: localItem.sampleRate ?? 0,
        bitrate: localItem.bitrate ?? 0,
        fileSize: localItem.fileSize ?? 0,
        track: track,
      );
    }

    final historyState = ref.read(downloadHistoryProvider);
    DownloadHistoryItem? historyItem;
    if (isLocalSource) {
      for (final item in historyState.items) {
        if (item.id == track.id) {
          historyItem = item;
          break;
        }
      }
    }

    if (historyItem == null) {
      final isrc = track.isrc?.trim();
      if (isrc != null && isrc.isNotEmpty) {
        historyItem = historyState.getByIsrc(isrc);
      }
    }

    historyItem ??= historyState.findByTrackAndArtist(
      track.name,
      track.artistName,
    );

    if (historyItem != null && historyItem.filePath.isNotEmpty) {
      final localUri = _uriFromPath(historyItem.filePath);
      final localDurationMs =
          historyItem.duration != null && historyItem.duration! > 0
          ? historyItem.duration!
          : _trackDurationMs(track);
      return PlaybackItem(
        id: historyItem.id,
        title: historyItem.trackName,
        artist: historyItem.artistName,
        album: historyItem.albumName,
        coverUrl: historyItem.coverUrl ?? track.coverUrl ?? '',
        sourceUri: localUri.toString(),
        isLocal: true,
        service: 'offline',
        durationMs: localDurationMs,
        format: historyItem.quality?.split(' ').first ?? '',
        bitDepth: historyItem.bitDepth ?? 0,
        sampleRate: historyItem.sampleRate ?? 0,
        bitrate: 0, // bitrate is usually not stored separately for lossless
        fileSize: historyItem.fileSize,
        track: track,
      );
    }

    return PlaybackItem(
      id: track.id,
      title: track.name,
      artist: track.artistName,
      album: track.albumName,
      coverUrl: track.coverUrl ?? '',
      sourceUri: '',
      durationMs: _trackDurationMs(track),
      track: track,
    );
  }

  int _trackDurationMs(Track track) {
    if (track.duration <= 0) return 0;
    return track.duration * 1000;
  }

  Duration _fallbackDurationForItem(PlaybackItem? item) {
    final ms = item?.durationMs ?? 0;
    if (ms <= 0) return Duration.zero;
    return Duration(milliseconds: ms);
  }

  // ─── Public: play local file ─────────────────────────────────────────────
  Future<void> playLocalPath({
    required String path,
    required String title,
    required String artist,
    String album = '',
    String coverUrl = '',
  }) async {
    final requestEpoch = _startNewPlayRequest();
    _resetPrefetchCycleState();
    _resetSmartQueueSessionState(clearRecent: true);
    _pendingResumePosition = null;
    _pendingResumeIndex = null;
    final uri = _uriFromPath(path);
    final item = PlaybackItem(
      id: path,
      title: title,
      artist: artist,
      album: album,
      coverUrl: coverUrl,
      sourceUri: uri.toString(),
      isLocal: true,
      service: 'offline',
    );

    _clearLyricsForTrackChange(upcomingItem: item);

    // Replacing single-track playback should also replace queue to avoid stale UI.
    state = state.copyWith(
      seekSupported: true,
      clearError: true,
      queue: [item],
      currentIndex: 0,
    );
    unawaited(_savePlaybackSnapshot());

    if (state.shuffle) {
      _regenerateShuffleOrder();
      _shufflePosition = _shuffleOrder.indexOf(0);
      if (_shufflePosition < 0) _shufflePosition = 0;
    } else {
      _shuffleOrder = [];
      _shufflePosition = -1;
    }

    await _setSourceAndPlay(uri, item, expectedRequestEpoch: requestEpoch);
  }

  // ─── Public: play a list of tracks (set queue) ───────────────────────────
  Future<void> playTrackList(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    _resetPrefetchCycleState();
    _resetSmartQueueSessionState(clearRecent: true);

    final items = tracks.map(_buildQueueItemFromTrack).toList(growable: false);
    _pendingResumePosition = null;
    _pendingResumeIndex = null;

    state = state.copyWith(
      queue: items,
      currentIndex: startIndex.clamp(0, items.length - 1),
    );
    unawaited(_savePlaybackSnapshot());

    if (state.shuffle) {
      _regenerateShuffleOrder();
      // Place the starting track at the front of the shuffle order
      // so playback begins from it, then continues in random order.
      final pos = _shuffleOrder.indexOf(state.currentIndex);
      if (pos > 0) {
        _shuffleOrder.removeAt(pos);
        _shuffleOrder.insert(0, state.currentIndex);
      }
      _shufflePosition = 0;
    }

    await _playQueueIndex(state.currentIndex);
  }

  // ─── Public: add track to queue ──────────────────────────────────────────
  void addToQueue(Track track) {
    final item = _buildQueueItemFromTrack(track);

    final newQueue = [...state.queue, item];
    state = state.copyWith(queue: newQueue);
    unawaited(_savePlaybackSnapshot());

    if (state.shuffle) {
      _shuffleOrder.add(newQueue.length - 1);
    }
  }

  // ─── Public: remove from queue ───────────────────────────────────────────
  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;

    final newQueue = [...state.queue]..removeAt(index);
    var newIndex = state.currentIndex;
    if (index < newIndex) {
      newIndex--;
    } else if (index == newIndex) {
      newIndex = newIndex.clamp(0, newQueue.length - 1);
    }

    state = state.copyWith(queue: newQueue, currentIndex: newIndex);
    unawaited(_savePlaybackSnapshot());
    if (state.shuffle) _regenerateShuffleOrder();
  }

  // ─── Public: clear queue ─────────────────────────────────────────────────
  void clearQueue() {
    _resetPrefetchCycleState();
    _resetSmartQueueSessionState(clearRecent: false);
    _lastProgressSnapshotMs = -1;
    state = state.copyWith(queue: [], currentIndex: -1);
    unawaited(_savePlaybackSnapshot());
    _shuffleOrder = [];
    _shufflePosition = -1;
    _pendingResumePosition = null;
    _pendingResumeIndex = null;
  }

  // ─── Public: jump to specific queue index ────────────────────────────────
  Future<void> playQueueIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    if (index == state.currentIndex) return;
    await _playQueueIndex(index);
  }

  // ─── Public: skip next / previous ────────────────────────────────────────
  Future<void> skipNext() async {
    _learnFromCurrentTrackOutcome(completedNaturally: false);
    final nextIndex = _resolveNextIndex();
    if (nextIndex != null) {
      await _playQueueIndex(nextIndex);
    }
  }

  Future<void> skipPrevious() async {
    // If > 3 seconds into track, restart instead of going previous
    if (_player.position.inSeconds > 3) {
      await _restartCurrentTrack();
      return;
    }

    final prevIndex = _resolvePreviousIndex();
    if (prevIndex != null) {
      await _playQueueIndex(prevIndex);
    } else {
      await _restartCurrentTrack();
    }
  }

  // ─── Public: toggle shuffle ──────────────────────────────────────────────
  void toggleShuffle() {
    setShuffle(!state.shuffle);
  }

  void setShuffle(bool enabled) {
    if (state.shuffle == enabled) return;
    state = state.copyWith(shuffle: enabled);

    if (enabled) {
      _regenerateShuffleOrderPreservingCurrentProgress();
    } else {
      _shuffleOrder = [];
      _shufflePosition = -1;
    }
    unawaited(_savePlaybackSnapshot());
  }

  // ─── Public: cycle repeat mode ───────────────────────────────────────────
  void cycleRepeatMode() {
    final modes = RepeatMode.values;
    final next = (state.repeatMode.index + 1) % modes.length;
    state = state.copyWith(repeatMode: modes[next]);
  }

  // ─── Public: toggle play/pause ───────────────────────────────────────────
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        final hasCurrentTrack =
            state.currentIndex >= 0 || state.currentItem != null;
        if (hasCurrentTrack) {
          await _restartCurrentTrack(playAfterSeek: true);
          return;
        }
      }

      if (_player.processingState == ProcessingState.idle &&
          state.queue.isNotEmpty) {
        final resumeIndex = state.currentIndex < 0 ? 0 : state.currentIndex;
        await _playQueueIndex(resumeIndex);
        return;
      }
      await _player.play();
    }
  }

  // ─── Public: seek ────────────────────────────────────────────────────────
  Future<void> seek(Duration position) async {
    if (!state.seekSupported) {
      _setPlaybackError(
        'Seeking is not supported for this stream.',
        type: 'seek_not_supported',
      );
      return;
    }
    await _player.seek(position);
  }

  // ─── Public: stop ────────────────────────────────────────────────────────
  Future<void> stop() async {
    _startNewPlayRequest();
    _lyricsGeneration++;
    final lastKnownPosition = state.position;
    final lastKnownDuration = state.duration;
    await FFmpegService.stopLiveDecryptedStream();
    await FFmpegService.stopNativeDashManifestPlayback();
    await FFmpegService.cleanupInactivePreparedNativeDashManifests();
    await _player.stop();
    _resetPrefetchCycleState();
    _lastProgressSnapshotMs = lastKnownPosition.inMilliseconds;
    _audioHandler?.playbackState.add(
      audio_service.PlaybackState(
        processingState: audio_service.AudioProcessingState.idle,
        playing: false,
      ),
    );
    _audioHandler?.mediaItem.add(null);

    state = state.copyWith(
      isPlaying: false,
      isBuffering: false,
      isLoading: false,
      seekSupported: true,
      position: lastKnownPosition,
      bufferedPosition: Duration.zero,
      duration: lastKnownDuration,
      clearError: true,
      clearLyrics: true,
    );
    unawaited(_savePlaybackSnapshot());
  }

  /// Stops playback and dismisses the mini player UI entirely.
  Future<void> dismissPlayer() async {
    await stop();
    _pendingResumePosition = null;
    _pendingResumeIndex = null;
    _lastProgressSnapshotMs = -1;

    state = state.copyWith(
      clearCurrentItem: true,
      queue: const [],
      currentIndex: -1,
      position: Duration.zero,
      bufferedPosition: Duration.zero,
      duration: Duration.zero,
      clearError: true,
      clearLyrics: true,
      lyricsLoading: false,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_playbackSnapshotKey);
    } catch (e) {
      _log.w('Failed to clear playback snapshot on dismiss: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  Future<void> _playQueueIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    // Stop current playback to prevent old audio bleeding into loading states
    // Calling this first ensures _playRequestEpoch is incremented before we capture requestEpoch
    await stop();

    final previousItem = state.currentItem;
    final requestEpoch = _startNewPlayRequest();
    _resetPrefetchCycleState();
    final pendingResumePosition = _pendingResumePositionForIndex(index);
    var item = state.queue[index];
    if (previousItem != null &&
        _trackKeyFromPlaybackItem(previousItem) !=
            _trackKeyFromPlaybackItem(item)) {
      _rememberRecentPlayed(previousItem);
    }
    _clearLyricsForTrackChange(upcomingItem: item);

    // Fetch missing file size natively before starting playback
    if (item.isLocal && item.fileSize <= 0 && item.sourceUri.isNotEmpty) {
      String localPath = item.sourceUri;
      if (localPath.startsWith('file://')) {
        try {
          localPath = Uri.parse(localPath).toFilePath();
        } catch (_) {}
      }
      try {
        final stat = await fileStat(localPath);
        if (stat != null && stat.size != null && stat.size! > 0) {
          item = item.copyWith(fileSize: stat.size!);
          final updatedQueue = List<PlaybackItem>.from(state.queue);
          updatedQueue[index] = item;
          state = state.copyWith(queue: updatedQueue);
        }
      } catch (e) {
        _log.w('Failed to fetch fileStat for local track: $e');
      }
    }
    state = state.copyWith(
      currentIndex: index,
      currentItem: item,
      isLoading: true,
      isBuffering: true,
      isPlaying: false,
      seekSupported: _inferSeekSupportedForQueueItem(item),
      position:
          pendingResumePosition != null && pendingResumePosition > Duration.zero
          ? pendingResumePosition
          : Duration.zero,
      bufferedPosition: Duration.zero,
      duration: _fallbackDurationForItem(item),
      clearError: true,
    );
    await _savePlaybackSnapshot();

    if (item.sourceUri.isEmpty) {
      if (item.track != null && !item.isLocal) {
        _log.i('No sourceUri for ${item.track!.name}. Resolving stream...');
        try {
          final settings = ref.read(settingsProvider);
          final defaultService = _resolveService(settings.defaultService);
          final tempDir = await getTemporaryDirectory();
          final streamCacheDir = Directory(
            p.join(tempDir.path, 'stream_cache'),
          );
          if (!await streamCacheDir.exists()) {
            await streamCacheDir.create(recursive: true);
          }
          final tempId = DateTime.now().millisecondsSinceEpoch.toString();

          final payload = DownloadRequestPayload(
            trackName: item.track!.name,
            artistName: item.track!.artistName,
            albumName: item.track!.albumName,
            spotifyId:
                item.track!.source == 'spotify-web' ||
                    item.track!.id.length == 22
                ? item.track!.id
                : '',
            deezerId: item.track!.deezerId ?? '',
            isrc: item.track!.isrc ?? '',
            service: defaultService,
            quality: 'HI_RES_LOSSLESS',
            outputDir: streamCacheDir.path,
            filenameFormat: 'stream_$tempId.flac',
            itemId: tempId,
            embedMetadata: false,
            embedLyrics: false,
            embedMaxQualityCover: false,
            coverUrl: item.track!.coverUrl ?? '',
          );

          final response = await PlatformBridge.downloadByStrategy(
            payload: payload,
            useExtensions: true,
            useFallback: true,
          );

          if (response['success'] == true && response['file_path'] != null) {
            final String filePath = response['file_path'];
            int resolvedFileSize = response['file_size'] ?? 0;

            // If fileSize is missing or zero, try fetching it from the local file
            if (resolvedFileSize <= 0) {
              try {
                final stat = await fileStat(filePath);
                if (stat != null && stat.size != null) {
                  resolvedFileSize = stat.size!;
                }
              } catch (_) {}
            }

            int parseSafeInt(dynamic val) {
              if (val == null) return 0;
              if (val is int) return val;
              if (val is String) return int.tryParse(val) ?? 0;
              if (val is double) return val.toInt();
              return 0;
            }

            item = item.copyWith(
              sourceUri: filePath,
              format: response['format'] ?? 'flac',
              bitrate: parseSafeInt(
                response['bitrate'] ??
                    response['bit_rate'] ??
                    response['actual_bitrate'] ??
                    0,
              ),
              sampleRate: parseSafeInt(
                response['sample_rate'] ??
                    response['actual_sample_rate'] ??
                    response['sample_frequency'] ??
                    0,
              ),
              bitDepth: parseSafeInt(
                response['bit_depth'] ??
                    response['actual_bit_depth'] ??
                    response['bits_per_sample'] ??
                    0,
              ),
              fileSize: resolvedFileSize,
              service: payload.service,
            );
            final updatedQueue = List<PlaybackItem>.from(state.queue);
            updatedQueue[index] = item;
            state = state.copyWith(queue: updatedQueue);
          } else {
            throw Exception(
              response['error'] ?? 'Unknown streaming resolution error.',
            );
          }
        } catch (e) {
          final skipped = await _handleQueueItemPlaybackFailure(
            failedIndex: index,
            expectedRequestEpoch: requestEpoch,
            error: Exception('Stream resolution failed: $e'),
            fallbackType: 'resolve_failed',
          );
          if (skipped) return;
          return;
        }
      } else {
        final skipped = await _handleQueueItemPlaybackFailure(
          failedIndex: index,
          expectedRequestEpoch: requestEpoch,
          error: Exception(
            'Track is not available locally. Download it first.',
          ),
          fallbackType: 'source_missing',
        );
        if (skipped) return;
        return;
      }
    }

    // Already have a URI
    if (item.sourceUri.isNotEmpty) {
      final uri = _uriFromPath(item.sourceUri);
      try {
        await _setSourceAndPlay(
          uri,
          item,
          initialPosition: pendingResumePosition,
          expectedRequestEpoch: requestEpoch,
        );
        if (!_isPlayRequestCurrent(requestEpoch) ||
            state.currentIndex != index) {
          return;
        }
        _clearPendingResumeForIndex(index);
      } catch (e) {
        if (!_isPlayRequestCurrent(requestEpoch)) return;
        final skipped = await _handleQueueItemPlaybackFailure(
          failedIndex: index,
          expectedRequestEpoch: requestEpoch,
          error: e,
          fallbackType: 'playback_failed',
        );
        if (skipped) {
          return;
        }
      }
    }
  }

  Future<void> _setSourceAndPlay(
    Uri uri,
    PlaybackItem item, {
    Duration? initialPosition,
    int? expectedRequestEpoch,
  }) async {
    if (expectedRequestEpoch != null &&
        !_isPlayRequestCurrent(expectedRequestEpoch)) {
      return;
    }
    final sourceUrl = uri.toString();
    await FFmpegService.activatePreparedNativeDashManifest(sourceUrl);
    if (!FFmpegService.isActiveLiveDecryptedUrl(sourceUrl)) {
      await FFmpegService.stopLiveDecryptedStream();
    }
    if (!FFmpegService.isActiveNativeDashManifestUrl(sourceUrl)) {
      await FFmpegService.stopNativeDashManifestPlayback();
    }

    final startPosition =
        initialPosition != null && initialPosition > Duration.zero
        ? initialPosition
        : Duration.zero;
    state = state.copyWith(
      currentItem: item,
      isLoading: true,
      isBuffering: true,
      isPlaying: false,
      position: startPosition,
      bufferedPosition: Duration.zero,
      duration: _fallbackDurationForItem(item),
      clearError: true,
    );
    unawaited(_savePlaybackSnapshot());

    _updateMediaItemNotification(item);

    try {
      if (expectedRequestEpoch != null &&
          !_isPlayRequestCurrent(expectedRequestEpoch)) {
        return;
      }
      final isDirectLocalFile = uri.scheme == 'file';
      if (isDirectLocalFile) {
        final filePath = uri.toFilePath();
        if (startPosition > Duration.zero) {
          await _player.setFilePath(filePath, initialPosition: startPosition);
        } else {
          await _player.setFilePath(filePath);
        }
      } else {
        // Use LockCachingAudioSource for external remote URIs to improve seeking stability.
        // It caches the stream to a local temporary file as it plays.
        // We skip this for localhost (FFmpeg tunnels) as they handle their own data flow.

        // Note: LockCachingAudioSource is disabled for remote streams
        // because it breaks seeking (returning to 0 instead of resuming).
        // Using AudioSource.uri directly avoids this problem for dynamically proxied HTTP streams.
        final audioSource = AudioSource.uri(uri);

        if (startPosition > Duration.zero) {
          await _player.setAudioSource(
            audioSource,
            initialPosition: startPosition,
          );
        } else {
          await _player.setAudioSource(audioSource);
        }
      }
      if (expectedRequestEpoch != null &&
          !_isPlayRequestCurrent(expectedRequestEpoch)) {
        return;
      }
      await _player.play();
    } catch (e) {
      if (expectedRequestEpoch != null &&
          !_isPlayRequestCurrent(expectedRequestEpoch)) {
        return;
      }
      if (FFmpegService.isActiveLiveDecryptedUrl(sourceUrl)) {
        await FFmpegService.stopLiveDecryptedStream();
      }
      if (FFmpegService.isActiveNativeDashManifestUrl(sourceUrl)) {
        await FFmpegService.stopNativeDashManifestPlayback();
      }
      _log.e('Failed to play source: $e');
      _setPlaybackError(e.toString(), type: 'playback_failed');
      rethrow;
    }
  }

  // ─── Lyrics fetching + parsing ───────────────────────────────────────────

  Future<void> _fetchLyricsForItem(PlaybackItem item) async {
    final generation = ++_lyricsGeneration;
    _log.d('Lyrics fetch start: ${item.artist} - ${item.title} (${item.id})');
    state = state.copyWith(lyricsLoading: true, clearLyrics: true);

    try {
      final result = await PlatformBridge.fetchLyrics(
        item.id,
        item.title,
        item.artist,
        durationMs: item.durationMs,
      );

      // Discard if a newer track has started since
      if (generation != _lyricsGeneration) return;

      final success = result['success'] == true;
      final instrumental = result['instrumental'] == true;
      final syncType = (result['sync_type'] as String?) ?? '';
      final source = (result['source'] as String?) ?? '';

      if (!success && !instrumental) {
        _log.d('Lyrics fetch returned no usable lyrics for ${item.id}');
        state = state.copyWith(
          lyricsLoading: false,
          lyrics: const LyricsData(),
        );
        return;
      }

      if (instrumental) {
        _log.d('Lyrics fetch result is instrumental from: $source');
        state = state.copyWith(
          lyricsLoading: false,
          lyrics: LyricsData(
            instrumental: true,
            source: source,
            syncType: syncType,
          ),
        );
        return;
      }

      final rawLines = result['lines'] as List<dynamic>? ?? [];
      final parsed = _parseLyricsLines(rawLines, syncType);
      _log.d(
        'Lyrics fetch success from $source (sync=$syncType, lines=${parsed.lines.length}, wordSync=${parsed.hasWordSync})',
      );

      state = state.copyWith(
        lyricsLoading: false,
        lyrics: LyricsData(
          lines: parsed.lines,
          syncType: syncType,
          source: source,
          isWordSynced: parsed.hasWordSync,
        ),
      );
    } catch (e) {
      if (generation != _lyricsGeneration) return;
      _log.w('Lyrics fetch failed for ${item.id}: $e');
      state = state.copyWith(lyricsLoading: false, lyrics: const LyricsData());
    }
  }

  /// Public method to manually refetch lyrics (e.g. retry button).
  Future<void> refetchLyrics() async {
    await ensureLyricsLoaded(force: true);
  }

  /// Load lyrics only when needed (e.g. when lyrics page is visible).
  Future<void> ensureLyricsLoaded({bool force = false}) async {
    final item = state.currentItem;
    if (item == null) return;
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (!force &&
        lifecycleState != null &&
        lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    if (!force) {
      if (state.lyricsLoading) return;
      if (state.lyrics != null) return;
    }
    await _fetchLyricsForItem(item);
  }

  /// Parse raw lines from Go backend into [LyricsLine] list.
  static ({List<LyricsLine> lines, bool hasWordSync}) _parseLyricsLines(
    List<dynamic> rawLines,
    String syncType,
  ) {
    final lines = <LyricsLine>[];
    var hasAnyWordSync = false;

    for (var i = 0; i < rawLines.length; i++) {
      final raw = rawLines[i] as Map<String, dynamic>;
      final startMs = (raw['startTimeMs'] as num?)?.toInt() ?? 0;
      final endMs = (raw['endTimeMs'] as num?)?.toInt() ?? 0;
      final wordsRaw = (raw['words'] as String?) ?? '';

      // Strip voice tags (v1:, v2:) from the beginning
      var cleanedText = wordsRaw;
      if (cleanedText.startsWith('v1:') || cleanedText.startsWith('v2:')) {
        cleanedText = cleanedText.substring(3);
      }

      // Parse word-by-word inline timestamps: <mm:ss.cs>word<mm:ss.cs>
      final words = _parseInlineWordTimestamps(cleanedText, startMs);
      if (words.isNotEmpty) hasAnyWordSync = true;

      // Clean text for display (remove inline timestamps)
      final displayText = _stripInlineTimestamps(cleanedText);

      // Calculate end time: use provided endMs, or next line's start, or +5s
      var effectiveEnd = endMs;
      if (effectiveEnd <= startMs && i + 1 < rawLines.length) {
        final nextStart =
            (rawLines[i + 1] as Map<String, dynamic>)['startTimeMs'] as num?;
        effectiveEnd = nextStart?.toInt() ?? (startMs + 5000);
      }
      if (effectiveEnd <= startMs) effectiveEnd = startMs + 5000;

      lines.add(
        LyricsLine(
          startMs: startMs,
          endMs: effectiveEnd,
          text: displayText.trim(),
          words: words,
        ),
      );
    }

    return (lines: lines, hasWordSync: hasAnyWordSync);
  }

  /// Parse inline `<mm:ss.cs>` timestamps in enhanced LRC word-by-word format.
  static List<LyricsWord> _parseInlineWordTimestamps(
    String text,
    int lineStartMs,
  ) {
    // Pattern: <mm:ss.cs> or <mm:ss.cc>
    final pattern = RegExp(r'<(\d{2}):(\d{2})\.(\d{2,3})>');
    final matches = pattern.allMatches(text).toList();
    if (matches.isEmpty) return [];

    final words = <LyricsWord>[];

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final startMs = _lrcInlineToMs(
        match.group(1)!,
        match.group(2)!,
        match.group(3)!,
      );

      // Text runs from after this timestamp to the next timestamp (or end)
      final textStart = match.end;
      final textEnd = i + 1 < matches.length
          ? matches[i + 1].start
          : text.length;
      final wordText = text.substring(textStart, textEnd);

      if (wordText.trim().isEmpty) continue;

      // End time is the start of the next word, or line end + buffer
      final endMs = i + 1 < matches.length
          ? _lrcInlineToMs(
              matches[i + 1].group(1)!,
              matches[i + 1].group(2)!,
              matches[i + 1].group(3)!,
            )
          : startMs + 2000;

      words.add(LyricsWord(text: wordText, startMs: startMs, endMs: endMs));
    }

    return words;
  }

  static int _lrcInlineToMs(String min, String sec, String cs) {
    final m = int.tryParse(min) ?? 0;
    final s = int.tryParse(sec) ?? 0;
    var c = int.tryParse(cs) ?? 0;
    if (cs.length == 2) c *= 10;
    return m * 60000 + s * 1000 + c;
  }

  /// Remove inline timestamps like <mm:ss.cs> for clean display text.
  static String _stripInlineTimestamps(String text) {
    return text
        .replaceAll(RegExp(r'<\d{2}:\d{2}\.\d{2,3}>'), '')
        .replaceAll(RegExp(r'\[bg:.*?\]'), '')
        .trim();
  }

  void _resetSmartQueueSessionState({required bool clearRecent}) {
    _smartQueueRefillInFlight = false;
    _lastSmartQueueRefillAt = null;
    _smartQueueAutoAddedCount = 0;
    _smartQueueSkipStreak = 0;
    _smartQueueSessionProfile = const _SmartQueueSessionProfile(
      mode: _SmartQueueSessionMode.balanced,
      targetDurationSec: 215,
      preferredSourceKey: '',
    );
    _smartQueuePendingFeedbackByTrack.clear();
    _smartQueueSearchCache.clear();
    _smartQueueRelatedArtistsCache.clear();
    if (clearRecent) {
      _recentPlayedTrackKeys.clear();
      _smartQueueSessionSignals.clear();
      _smartQueueTempoHintByTrackKey.clear();
    }
  }

  bool _isSmartQueueEnabled() {
    final settings = ref.read(settingsProvider);
    if (!settings.smartQueueEnabled) return false;
    if (state.repeatMode == RepeatMode.all ||
        state.repeatMode == RepeatMode.one) {
      return false;
    }
    if (state.isLoading || state.currentIndex < 0 || state.queue.isEmpty) {
      return false;
    }
    if (state.currentItem?.track == null) return false;
    if (_smartQueueAutoAddedCount >= _smartQueueMaxAutoAddsPerSession) {
      return false;
    }
    return true;
  }

  String _normalizeSmartQueueKey(String value) => value.trim().toLowerCase();

  String _trackKeyFromTrack(Track track) {
    final isrc = _normalizeSmartQueueKey(track.isrc ?? '');
    if (isrc.isNotEmpty) return 'isrc:$isrc';

    final source = _normalizeSmartQueueKey(track.source ?? '');
    final id = _normalizeSmartQueueKey(track.id);
    if (source.isNotEmpty && id.isNotEmpty) return 'src:$source:$id';
    if (id.isNotEmpty) return 'id:$id';

    final title = _normalizeSmartQueueKey(track.name);
    final artist = _normalizeSmartQueueKey(track.artistName);
    if (title.isNotEmpty || artist.isNotEmpty) {
      return 'name:$title|$artist';
    }
    return '';
  }

  String _trackKeyFromPlaybackItem(PlaybackItem item) {
    final fromTrack = item.track;
    if (fromTrack != null) {
      final key = _trackKeyFromTrack(fromTrack);
      if (key.isNotEmpty) return key;
    }

    final id = _normalizeSmartQueueKey(item.id);
    if (id.isNotEmpty) return 'id:$id';

    final title = _normalizeSmartQueueKey(item.title);
    final artist = _normalizeSmartQueueKey(item.artist);
    if (title.isNotEmpty || artist.isNotEmpty) {
      return 'name:$title|$artist';
    }
    return '';
  }

  void _rememberRecentPlayed(PlaybackItem item) {
    final key = _trackKeyFromPlaybackItem(item);
    if (key.isEmpty) return;
    _recentPlayedTrackKeys.remove(key);
    _recentPlayedTrackKeys.insert(0, key);
    if (_recentPlayedTrackKeys.length > _smartQueueRecentPlayedWindow) {
      _recentPlayedTrackKeys.removeRange(
        _smartQueueRecentPlayedWindow,
        _recentPlayedTrackKeys.length,
      );
    }
  }

  void _learnFromCurrentTrackOutcome({required bool completedNaturally}) {
    final current = state.currentItem;
    if (current == null) return;
    final key = _trackKeyFromPlaybackItem(current);
    if (key.isEmpty) return;

    final durationMs = max(
      1,
      state.duration.inMilliseconds > 0
          ? state.duration.inMilliseconds
          : current.durationMs,
    );
    final positionMs = state.position.inMilliseconds.clamp(0, durationMs);
    final listenRatio = completedNaturally ? 1.0 : (positionMs / durationMs);
    final skipStreakBefore = _smartQueueSkipStreak;
    if (current.track != null) {
      _recordSmartQueueSessionSignal(
        track: current.track!,
        listenRatio: listenRatio,
        completedNaturally: completedNaturally,
      );
    }
    _updateSmartQueueSkipStreak(
      listenRatio: listenRatio,
      completedNaturally: completedNaturally,
    );

    final context = _smartQueuePendingFeedbackByTrack.remove(key);
    if (context == null) return;
    if (DateTime.now().difference(context.addedAt) >
        _smartQueueFeedbackMaxAge) {
      return;
    }

    final hourBucket = _currentSmartQueueHourBucket();
    final reward = _smartQueueRewardFromListenRatio(
      listenRatio: listenRatio,
      completedNaturally: completedNaturally,
      currentSkipStreak: skipStreakBefore,
      hourAffinityRaw: _smartQueueHourAffinity[hourBucket] ?? 0.0,
    );
    _updateSmartQueueModel(
      features: context.features,
      reward: reward,
      track: current.track,
      hourBucket: hourBucket,
    );
  }

  double _smartQueueRewardFromListenRatio({
    required double listenRatio,
    required bool completedNaturally,
    required int currentSkipStreak,
    required double hourAffinityRaw,
  }) {
    double reward;
    if (completedNaturally || listenRatio >= 0.98) {
      reward = 1.0;
    } else if (listenRatio >= 0.75) {
      reward = 0.85;
    } else if (listenRatio >= 0.50) {
      reward = 0.65;
    } else if (listenRatio >= 0.25) {
      reward = 0.35;
    } else if (listenRatio >= 0.12) {
      reward = 0.15;
    } else {
      reward = 0.0;
    }

    // Contextual bandit shaping: adjust reward based on current context.
    final hourAffinity = ((hourAffinityRaw + 1.0) / 2.0).clamp(0.0, 1.0);
    reward += (hourAffinity - 0.5) * 0.10;
    if (!completedNaturally && listenRatio < 0.25 && currentSkipStreak >= 2) {
      reward -= 0.08;
    }
    if (completedNaturally && currentSkipStreak >= 2) {
      reward += 0.05;
    }
    return reward.clamp(0.0, 1.0);
  }

  void _updateSmartQueueSkipStreak({
    required double listenRatio,
    required bool completedNaturally,
  }) {
    if (completedNaturally || listenRatio >= 0.70) {
      _smartQueueSkipStreak = 0;
      return;
    }
    if (listenRatio < 0.35) {
      _smartQueueSkipStreak = min(
        _smartQueueMaxSkipStreak,
        _smartQueueSkipStreak + 1,
      );
      return;
    }
    _smartQueueSkipStreak = max(0, _smartQueueSkipStreak - 1);
  }

  String _currentSmartQueueHourBucket() {
    final hour = DateTime.now().hour;
    return 'h${hour.toString().padLeft(2, '0')}';
  }

  void _recordSmartQueueSessionSignal({
    required Track track,
    required double listenRatio,
    required bool completedNaturally,
  }) {
    _smartQueueSessionSignals.add(
      _SmartQueueSessionSignal(
        artistKey: _normalizeSmartQueueKey(track.artistName),
        sourceKey: _sourceKey(track.source ?? ''),
        durationSec: max(1, track.duration),
        releaseYear: _parseYear(track.releaseDate),
        listenRatio: listenRatio.clamp(0.0, 1.0),
        skipped: !completedNaturally && listenRatio < 0.70,
      ),
    );
    final maxSignals = _smartQueueSessionWindowSize * 6;
    if (_smartQueueSessionSignals.length > maxSignals) {
      _smartQueueSessionSignals.removeRange(
        0,
        _smartQueueSessionSignals.length - maxSignals,
      );
    }
  }

  void _refreshSmartQueueSessionProfile({required Track seed}) {
    final recent =
        _smartQueueSessionSignals.length <= _smartQueueSessionWindowSize
        ? List<_SmartQueueSessionSignal>.from(_smartQueueSessionSignals)
        : _smartQueueSessionSignals.sublist(
            _smartQueueSessionSignals.length - _smartQueueSessionWindowSize,
          );
    if (recent.isEmpty) {
      _smartQueueSessionProfile = _SmartQueueSessionProfile(
        mode: _SmartQueueSessionMode.balanced,
        targetDurationSec: max(140, seed.duration),
        targetYear: _parseYear(seed.releaseDate),
        preferredSourceKey: _sourceKey(seed.source ?? ''),
      );
      return;
    }

    final avgDuration =
        recent.map((s) => s.durationSec.toDouble()).reduce((a, b) => a + b) /
        recent.length;
    final avgListen =
        recent.map((s) => s.listenRatio).reduce((a, b) => a + b) /
        recent.length;
    final skipRate = recent.where((s) => s.skipped).length / recent.length;
    final variance =
        recent
            .map((s) => pow((s.durationSec - avgDuration).toDouble(), 2))
            .reduce((a, b) => a + b) /
        recent.length;
    final durationStdDev = sqrt(variance);

    _SmartQueueSessionMode mode = _SmartQueueSessionMode.balanced;
    if (skipRate > 0.45 || avgDuration < 190) {
      mode = _SmartQueueSessionMode.energetic;
    } else if (avgDuration > 280 && skipRate < 0.28) {
      mode = _SmartQueueSessionMode.chill;
    } else if (durationStdDev < 45 && avgListen >= 0.58) {
      mode = _SmartQueueSessionMode.focus;
    }

    final years =
        recent
            .map((s) => s.releaseYear)
            .whereType<int>()
            .toList(growable: false)
          ..sort();
    final targetYear = years.isEmpty
        ? _parseYear(seed.releaseDate)
        : years[years.length ~/ 2];
    final sourceCounts = <String, int>{};
    for (final signal in recent) {
      if (signal.sourceKey.isEmpty) continue;
      sourceCounts[signal.sourceKey] =
          (sourceCounts[signal.sourceKey] ?? 0) + 1;
    }
    var preferredSourceKey = _sourceKey(seed.source ?? '');
    if (sourceCounts.isNotEmpty) {
      preferredSourceKey =
          (sourceCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
    }
    final targetDurationSec = switch (mode) {
      _SmartQueueSessionMode.chill => max(240, avgDuration.round()),
      _SmartQueueSessionMode.focus => avgDuration.round().clamp(170, 320),
      _SmartQueueSessionMode.energetic => avgDuration.round().clamp(120, 220),
      _SmartQueueSessionMode.balanced => avgDuration.round().clamp(145, 280),
    };

    _smartQueueSessionProfile = _SmartQueueSessionProfile(
      mode: mode,
      targetDurationSec: targetDurationSec,
      targetYear: targetYear,
      preferredSourceKey: preferredSourceKey,
    );
  }

  void _updateAffinity(Map<String, double> map, String key, double reward) {
    final normalizedKey = _normalizeSmartQueueKey(key);
    if (normalizedKey.isEmpty) return;

    final current = map[normalizedKey] ?? 0.0;
    final target = (reward * 2.0) - 1.0; // [0,1] -> [-1,1]
    final updated = (current * 0.85) + (target * 0.15);
    map[normalizedKey] = updated.clamp(-1.0, 1.0);

    while (map.length > _smartQueueMaxAffinityKeys) {
      map.remove(map.keys.first);
    }
  }

  void _updateSmartQueueModel({
    required Map<String, double> features,
    required double reward,
    Track? track,
    required String hourBucket,
  }) {
    final clippedReward = reward.clamp(0.0, 1.0);
    final prediction = _smartQueuePredict(features);
    final error = clippedReward - prediction;

    final nextBias =
        (_smartQueueWeights['bias'] ?? 0.0) + (_smartQueueLearningRate * error);
    _smartQueueWeights['bias'] = nextBias.clamp(-3.0, 3.0);

    for (final entry in features.entries) {
      final currentWeight = _smartQueueWeights[entry.key] ?? 0.0;
      final updatedWeight =
          currentWeight + (_smartQueueLearningRate * error * entry.value);
      _smartQueueWeights[entry.key] = updatedWeight.clamp(-3.0, 3.0);
    }

    if (track != null) {
      _updateAffinity(
        _smartQueueArtistAffinity,
        track.artistName,
        clippedReward,
      );
      _updateAffinity(
        _smartQueueSourceAffinity,
        _sourceKey(track.source ?? ''),
        clippedReward,
      );
      _updateAffinity(_smartQueueHourAffinity, hourBucket, clippedReward);
    }

    _scheduleSmartQueueModelSave();
  }

  double _smartQueuePredict(Map<String, double> features) {
    var logit = _smartQueueWeights['bias'] ?? 0.0;
    for (final entry in features.entries) {
      logit += (_smartQueueWeights[entry.key] ?? 0.0) * entry.value;
    }
    return _sigmoid(logit);
  }

  double _sigmoid(double x) => 1.0 / (1.0 + exp(-x));

  void _maybeTriggerSmartQueueRefill(Duration position) {
    if (!_isSmartQueueEnabled()) return;
    if (_smartQueueRefillInFlight) return;

    final remaining = state.queue.length - state.currentIndex - 1;
    if (remaining > _smartQueueTriggerRemainingTracks) return;
    if (position < const Duration(seconds: 8)) return;

    final lastRefill = _lastSmartQueueRefillAt;
    if (lastRefill != null &&
        DateTime.now().difference(lastRefill) < _smartQueueRefillCooldown) {
      return;
    }

    unawaited(_autoRefillSmartQueue(force: false));
  }

  Future<int> _autoRefillSmartQueue({required bool force}) async {
    if (!_isSmartQueueEnabled()) return 0;
    if (_smartQueueRefillInFlight) return 0;

    final remaining = max(0, state.queue.length - state.currentIndex - 1);
    final needed = _smartQueueTargetRemainingTracks - remaining;
    if (!force && needed <= 0) return 0;

    final lastRefill = _lastSmartQueueRefillAt;
    if (!force &&
        lastRefill != null &&
        DateTime.now().difference(lastRefill) < _smartQueueRefillCooldown) {
      return 0;
    }

    final seed = state.currentItem?.track;
    if (seed == null) return 0;
    _refreshSmartQueueSessionProfile(seed: seed);

    final epoch = _playRequestEpoch;
    _smartQueueRefillInFlight = true;
    try {
      _pruneSmartQueueCaches();

      final candidates = await _fetchSmartQueueCandidates(
        seed,
        limit: _smartQueueCandidatePoolLimit,
      );
      if (_playRequestEpoch != epoch) return 0;
      if (candidates.isEmpty) return 0;

      final existingTrackKeys = <String>{};
      for (final item in state.queue) {
        final key = _trackKeyFromPlaybackItem(item);
        if (key.isNotEmpty) existingTrackKeys.add(key);
      }
      existingTrackKeys.addAll(_recentPlayedTrackKeys);

      final scored = <_SmartQueueCandidate>[];
      for (final candidate in candidates) {
        final candidateEntry = _buildSmartQueueCandidate(
          seed: seed,
          candidate: candidate,
          existingTrackKeys: existingTrackKeys,
        );
        if (candidateEntry == null) continue;
        scored.add(candidateEntry);
      }
      if (scored.isEmpty) return 0;

      scored.sort((a, b) => b.score.compareTo(a.score));
      final targetCount = force ? max(1, needed) : max(0, needed);
      if (targetCount <= 0) return 0;
      final selected = _selectSmartQueueCandidates(
        seed: seed,
        sessionProfile: _smartQueueSessionProfile,
        scored: scored,
        targetCount: targetCount,
      );
      if (selected.isEmpty) return 0;
      if (_playRequestEpoch != epoch) return 0;

      final queueBefore = state.queue.length;
      final updatedQueue = [...state.queue];
      for (final selection in selected) {
        final item = _buildQueueItemFromTrack(selection.track);
        updatedQueue.add(item);
        final itemKey = _trackKeyFromPlaybackItem(item);
        if (itemKey.isNotEmpty) {
          _smartQueuePendingFeedbackByTrack[itemKey] =
              _SmartQueueLearningContext(
                features: selection.features,
                addedAt: DateTime.now(),
              );
        }
      }

      state = state.copyWith(queue: updatedQueue);
      if (state.shuffle) {
        for (var idx = queueBefore; idx < updatedQueue.length; idx++) {
          _shuffleOrder.add(idx);
        }
      }

      _smartQueueAutoAddedCount += selected.length;
      _lastSmartQueueRefillAt = DateTime.now();
      unawaited(_savePlaybackSnapshot());
      final sourceSummary = <String, int>{};
      for (final selection in selected) {
        final source = _resolveSmartQueueSourceLabel(selection.track);
        sourceSummary[source] = (sourceSummary[source] ?? 0) + 1;
      }
      final summaryText = sourceSummary.entries
          .map((entry) => '${entry.key}:${entry.value}')
          .join(', ');
      _log.d(
        'Smart queue appended ${selected.length} tracks (remaining=$remaining, session=${_smartQueueSessionProfile.mode.name}, sources=[$summaryText])',
      );
      return selected.length;
    } catch (e) {
      _log.d('Smart queue refill skipped: $e');
      return 0;
    } finally {
      _smartQueueRefillInFlight = false;
    }
  }

  Future<List<Track>> _fetchSmartQueueCandidates(
    Track seed, {
    required int limit,
  }) async {
    final queries = <String>{
      '${seed.artistName} ${seed.name}'.trim(),
      seed.artistName.trim(),
      '${seed.artistName} ${seed.albumName}'.trim(),
    }.where((q) => q.isNotEmpty).take(3).toList(growable: false);

    if (queries.isEmpty) return const <Track>[];

    final perQueryLimit = max(10, (limit / queries.length).ceil() + 4);
    final results = await Future.wait(
      queries.map(
        (q) => _searchTracksForSmartQueue(q, trackLimit: perQueryLimit),
      ),
    );

    final merged = <Track>[];
    for (final list in results) {
      merged.addAll(list);
      if (merged.length >= limit * 2) break;
    }

    final relatedArtistTracks = await _fetchRelatedArtistTracksForSmartQueue(
      seed,
      fallbackTracks: merged,
      limit: limit,
    );
    if (relatedArtistTracks.isNotEmpty) {
      merged.addAll(relatedArtistTracks);
    }
    return merged;
  }

  Future<List<Track>> _fetchRelatedArtistTracksForSmartQueue(
    Track seed, {
    required List<Track> fallbackTracks,
    required int limit,
  }) async {
    final seedArtist = _normalizeSmartQueueKey(seed.artistName);
    if (seedArtist.isEmpty) return const [];

    final relatedArtists = await _discoverRelatedArtistsForSmartQueue(
      seed,
      fallbackTracks: fallbackTracks,
      limit: _smartQueueRelatedArtistsLimit,
    );
    if (relatedArtists.isEmpty) return const [];

    final perArtistLimit = max(
      6,
      (limit / max(1, relatedArtists.length)).ceil(),
    );
    final results = await Future.wait(
      relatedArtists.map(
        (artist) =>
            _searchTracksForSmartQueue(artist.name, trackLimit: perArtistLimit),
      ),
    );

    final merged = <Track>[];
    for (final tracks in results) {
      for (final track in tracks) {
        final artist = _normalizeSmartQueueKey(track.artistName);
        if (artist.isEmpty || artist == seedArtist) continue;
        merged.add(track);
      }
      if (merged.length >= limit) break;
    }
    return merged;
  }

  Future<List<_SmartQueueRelatedArtist>> _discoverRelatedArtistsForSmartQueue(
    Track seed, {
    required List<Track> fallbackTracks,
    required int limit,
  }) async {
    final seedArtist = _normalizeSmartQueueKey(seed.artistName);
    if (seedArtist.isEmpty || limit <= 0) return const [];

    final cacheKey = 'seed:$seedArtist';
    final cached = _smartQueueRelatedArtistsCache[cacheKey];
    final now = DateTime.now();
    if (cached != null &&
        now.difference(cached.fetchedAt) < _smartQueueSearchCacheTtl) {
      return cached.artists.take(limit).toList(growable: false);
    }

    final relatedByName = <String, _SmartQueueRelatedArtist>{};
    void addCandidate(_SmartQueueRelatedArtist candidate) {
      final key = _normalizeSmartQueueKey(candidate.name);
      if (key.isEmpty || key == seedArtist) return;
      final existing = relatedByName[key];
      if (existing == null || candidate.score > existing.score) {
        relatedByName[key] = candidate;
      }
    }

    final spotifySeed = await _findArtistSeedBySearch(
      queryArtistName: seed.artistName,
      provider: 'spotify',
    );
    if (spotifySeed != null) {
      final related = await _fetchRelatedArtistsFromProviderSeed(spotifySeed);
      for (final item in related) {
        addCandidate(item);
      }
    }

    final deezerSeed = await _findArtistSeedBySearch(
      queryArtistName: seed.artistName,
      provider: 'deezer',
    );
    if (deezerSeed != null) {
      final related = await _fetchRelatedArtistsFromProviderSeed(deezerSeed);
      for (final item in related) {
        addCandidate(item);
      }
    }

    // Fallback heuristic from current track candidates if provider APIs don't return enough.
    if (relatedByName.length < limit) {
      final counts = <String, int>{};
      for (final track in fallbackTracks.take(80)) {
        final artistName = track.artistName.trim();
        final key = _normalizeSmartQueueKey(artistName);
        if (key.isEmpty || key == seedArtist) continue;
        counts[key] = (counts[key] ?? 0) + 1;
      }
      for (final entry in counts.entries) {
        addCandidate(
          _SmartQueueRelatedArtist(
            name: entry.key,
            provider: 'fallback',
            score: min(1.0, 0.25 + (entry.value * 0.14)),
          ),
        );
      }
    }

    final sorted = relatedByName.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    _smartQueueRelatedArtistsCache[cacheKey] = _SmartQueueRelatedArtistsCache(
      artists: sorted,
      fetchedAt: now,
    );
    return sorted.take(limit).toList(growable: false);
  }

  Future<_SmartQueueArtistSeed?> _findArtistSeedBySearch({
    required String queryArtistName,
    required String provider,
  }) async {
    final normalizedProvider = provider.trim().toLowerCase();
    final query = queryArtistName.trim();
    if (query.isEmpty) return null;

    final artists = await _searchArtistsForSmartQueue(
      query: query,
      provider: normalizedProvider,
      limit: 8,
    );
    if (artists.isEmpty) return null;

    artists.sort((a, b) => b.score.compareTo(a.score));
    return artists.first;
  }

  Future<List<_SmartQueueRelatedArtist>> _fetchRelatedArtistsFromProviderSeed(
    _SmartQueueArtistSeed seed,
  ) async {
    try {
      if (seed.provider == 'spotify') {
        return await _fetchSpotifyRelatedArtistsForSmartQueue(seed);
      } else if (seed.provider == 'deezer') {
        final response = await PlatformBridge.getDeezerRelatedArtists(
          seed.id,
          limit: 10,
        );
        final rawList = response['artists'] as List<dynamic>? ?? const [];
        final result = <_SmartQueueRelatedArtist>[];
        for (final entry in rawList) {
          if (entry is! Map) continue;
          final map = Map<String, dynamic>.from(entry);
          final name = (map['name'] as String?)?.trim() ?? '';
          if (name.isEmpty) continue;
          final popularity = (map['popularity'] as num?)?.toDouble() ?? 0.0;
          final followers = (map['followers'] as num?)?.toDouble() ?? 0.0;
          final score =
              ((popularity / 100.0) * 0.65) +
              (min(followers, 2000000) / 2000000.0) * 0.35;
          result.add(
            _SmartQueueRelatedArtist(
              name: name,
              provider: seed.provider,
              score: score.clamp(0.05, 1.0),
            ),
          );
        }
        return result;
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<_SmartQueueRelatedArtist>>
  _fetchSpotifyRelatedArtistsForSmartQueue(_SmartQueueArtistSeed seed) async {
    final seedArtistKey = _normalizeSmartQueueKey(seed.name);
    if (seedArtistKey.isEmpty) return const [];

    final relatedScores = <String, double>{};
    final relatedNames = <String, String>{};

    void addRelatedName(String rawName, double score) {
      final name = rawName.trim();
      final key = _normalizeSmartQueueKey(name);
      if (key.isEmpty || key == seedArtistKey || score <= 0) return;
      relatedNames[key] = name;
      relatedScores[key] = (relatedScores[key] ?? 0.0) + score;
    }

    try {
      final artist = await PlatformBridge.getArtistWithExtension(
        _smartQueueSpotifyExtensionId,
        seed.id,
      );
      if (artist != null) {
        final topTracks = artist['top_tracks'] as List<dynamic>? ?? const [];
        for (var index = 0; index < topTracks.length && index < 20; index++) {
          final entry = topTracks[index];
          if (entry is! Map) continue;
          final map = Map<String, dynamic>.from(entry);
          final artistsText = (map['artists'] ?? map['artist'] ?? '')
              .toString()
              .trim();
          if (artistsText.isEmpty) continue;
          final rankWeight = (1.0 - (index / 18.0)).clamp(0.18, 1.0);
          for (final artistName in _extractArtistNamesForSmartQueue(
            artistsText,
          )) {
            addRelatedName(artistName, 0.42 * rankWeight);
          }
        }
      }
    } catch (_) {}

    try {
      final searchResults = await PlatformBridge.customSearchWithExtension(
        _smartQueueSpotifyExtensionId,
        seed.name,
        options: <String, dynamic>{
          'filter': 'artists',
          'limit': 12,
          'offset': 0,
        },
      );
      for (var index = 0; index < searchResults.length; index++) {
        final map = searchResults[index];
        final itemType = (map['item_type'] ?? '').toString().toLowerCase();
        if (itemType.isNotEmpty && itemType != 'artist') continue;
        final id = (map['id'] ?? '').toString().trim();
        final name = (map['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final normalizedName = _normalizeSmartQueueKey(name);
        if (normalizedName == seedArtistKey || id == seed.id) continue;

        final similarity = _artistNameSimilarity(seed.name, name);
        final rankWeight = (1.0 - (index / 12.0)).clamp(0.1, 1.0);
        addRelatedName(name, (rankWeight * 0.24) + (similarity * 0.12));
      }
    } catch (_) {}

    if (relatedScores.isEmpty) return const [];

    final related = <_SmartQueueRelatedArtist>[];
    for (final entry in relatedScores.entries) {
      related.add(
        _SmartQueueRelatedArtist(
          name: relatedNames[entry.key] ?? entry.key,
          provider: _smartQueueSpotifyExtensionId,
          score: entry.value.clamp(0.05, 1.0),
        ),
      );
    }
    related.sort((a, b) => b.score.compareTo(a.score));
    return related.take(10).toList(growable: false);
  }

  List<String> _extractArtistNamesForSmartQueue(String rawArtists) {
    final tokens = splitArtistNames(rawArtists);
    if (tokens.isEmpty) return const [];

    final names = <String>[];
    final seen = <String>{};
    for (final token in tokens) {
      final name = token.trim();
      if (name.isEmpty) continue;
      final key = _normalizeSmartQueueKey(name);
      if (key.isEmpty || !seen.add(key)) continue;
      names.add(name);
    }
    return names;
  }

  Future<List<_SmartQueueArtistSeed>> _searchArtistsForSmartQueue({
    required String query,
    required String provider,
    int limit = 8,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const [];

    final normalizedProvider = provider.trim().toLowerCase();
    if (normalizedProvider != 'spotify' && normalizedProvider != 'deezer') {
      return const [];
    }

    try {
      final List<Map<String, dynamic>> artistsRaw;
      if (normalizedProvider == 'spotify') {
        final response = await PlatformBridge.customSearchWithExtension(
          _smartQueueSpotifyExtensionId,
          normalizedQuery,
          options: <String, dynamic>{
            'filter': 'artists',
            'limit': min(30, max(4, limit)),
            'offset': 0,
          },
        );
        artistsRaw = response
            .where(
              (item) =>
                  (item['item_type'] ?? 'artist').toString().toLowerCase() ==
                  'artist',
            )
            .toList(growable: false);
      } else {
        final result = await PlatformBridge.searchDeezerAll(
          normalizedQuery,
          trackLimit: 1,
          artistLimit: limit,
          filter: 'artist',
        );
        final raw = result['artists'] as List<dynamic>? ?? const [];
        artistsRaw = raw
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false);
      }

      final seeds = <_SmartQueueArtistSeed>[];
      final seen = <String>{};
      for (var index = 0; index < artistsRaw.length; index++) {
        final map = artistsRaw[index];
        final id = (map['id'] ?? '').toString().trim();
        final name = (map['name'] ?? '').toString().trim();
        if (id.isEmpty || name.isEmpty) continue;
        final key = '$normalizedProvider:${_normalizeSmartQueueKey(id)}';
        if (!seen.add(key)) continue;

        final popularity = (map['popularity'] as num?)?.toDouble() ?? 0.0;
        final similarity = _artistNameSimilarity(query, name);
        final rankScore = (1.0 - (index / max(1, artistsRaw.length))).clamp(
          0.05,
          1.0,
        );
        final score = normalizedProvider == 'spotify'
            ? (similarity * 0.82) + (rankScore * 0.18)
            : (similarity * 0.72) + ((popularity / 100.0) * 0.28);
        seeds.add(
          _SmartQueueArtistSeed(
            id: id,
            name: name,
            provider: normalizedProvider,
            score: score.clamp(0.0, 1.0),
          ),
        );
      }
      return seeds;
    } catch (_) {
      return const [];
    }
  }

  double _artistNameSimilarity(String a, String b) {
    final na = _normalizeSmartQueueKey(a);
    final nb = _normalizeSmartQueueKey(b);
    if (na.isEmpty || nb.isEmpty) return 0.0;
    if (na == nb) return 1.0;
    if (na.contains(nb) || nb.contains(na)) return 0.88;

    final tokensA = na
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toSet();
    final tokensB = nb
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toSet();
    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;

    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }

  Future<List<Track>> _searchTracksForSmartQueue(
    String query, {
    int trackLimit = 20,
  }) async {
    final normalizedQuery = _normalizeSmartQueueKey(query);
    if (normalizedQuery.isEmpty) return const <Track>[];

    final now = DateTime.now();
    final cached = _smartQueueSearchCache[normalizedQuery];
    if (cached != null &&
        now.difference(cached.fetchedAt) < _smartQueueSearchCacheTtl) {
      return cached.tracks;
    }

    final settings = ref.read(settingsProvider);
    final preferSpotify =
        settings.metadataSource.trim().toLowerCase() == 'spotify';
    final primaryLimit = max(
      trackLimit,
      (trackLimit * _smartQueuePrimarySourceRatio).round() + 5,
    );
    final secondaryLimit = max(trackLimit ~/ 2, trackLimit - 2);

    final primaryResults = await (preferSpotify
        ? _safeSmartQueueTrackSearch(
            () => _searchSpotifyTracksForSmartQueue(
              normalizedQuery,
              trackLimit: primaryLimit,
            ),
          )
        : _safeSmartQueueTrackSearch(
            () => _searchDeezerTracksForSmartQueue(
              normalizedQuery,
              trackLimit: primaryLimit,
            ),
          ));
    final shouldQuerySecondary =
        primaryResults.length <
        max(8, (trackLimit * _smartQueuePrimarySourceRatio).round());
    final secondaryResults = shouldQuerySecondary
        ? (preferSpotify
              ? await _safeSmartQueueTrackSearch(
                  () => _searchDeezerTracksForSmartQueue(
                    normalizedQuery,
                    trackLimit: secondaryLimit,
                  ),
                )
              : await _safeSmartQueueTrackSearch(
                  () => _searchSpotifyTracksForSmartQueue(
                    normalizedQuery,
                    trackLimit: secondaryLimit,
                  ),
                ))
        : const <Map<String, dynamic>>[];

    final blended = _blendSmartQueueTrackCandidates(
      primary: primaryResults,
      secondary: secondaryResults,
      targetCount: max(10, trackLimit + 6),
      primaryRatio: _smartQueuePrimarySourceRatio,
    );

    final parsedTracks = <Track>[];
    final seenTrackKeys = <String>{};
    for (final entry in blended) {
      final track = _parseSearchTrackForSmartQueue(entry);
      if (track.id.trim().isEmpty || track.name.trim().isEmpty) continue;
      if (track.isCollection) continue;
      final key = _trackKeyFromTrack(track);
      if (key.isNotEmpty && !seenTrackKeys.add(key)) continue;
      _registerSmartQueueTrackHints(track: track, raw: entry);
      parsedTracks.add(track);
    }

    _smartQueueSearchCache[normalizedQuery] = _SmartQueueCachedResult(
      tracks: parsedTracks,
      fetchedAt: now,
    );
    return parsedTracks;
  }

  Future<List<Map<String, dynamic>>> _safeSmartQueueTrackSearch(
    Future<List<Map<String, dynamic>>> Function() resolver,
  ) async {
    try {
      return await resolver();
    } catch (e) {
      _log.d('Smart queue source search failed: $e');
      return const <Map<String, dynamic>>[];
    }
  }

  List<Map<String, dynamic>> _blendSmartQueueTrackCandidates({
    required List<Map<String, dynamic>> primary,
    required List<Map<String, dynamic>> secondary,
    required int targetCount,
    required double primaryRatio,
  }) {
    final merged = <Map<String, dynamic>>[];
    final seen = <String>{};
    var primaryIndex = 0;
    var secondaryIndex = 0;
    var primaryTaken = 0;
    var secondaryTaken = 0;
    final maxTarget = max(1, targetCount);

    void tryTakeFrom(List<Map<String, dynamic>> source, bool isPrimary) {
      while (true) {
        final index = isPrimary ? primaryIndex : secondaryIndex;
        if (index >= source.length) return;
        final item = source[index];
        if (isPrimary) {
          primaryIndex++;
        } else {
          secondaryIndex++;
        }
        final dedupKey = _smartQueueRawTrackDedupKey(item);
        if (dedupKey.isEmpty || !seen.add(dedupKey)) {
          continue;
        }
        merged.add(item);
        if (isPrimary) {
          primaryTaken++;
        } else {
          secondaryTaken++;
        }
        return;
      }
    }

    while (merged.length < maxTarget &&
        (primaryIndex < primary.length || secondaryIndex < secondary.length)) {
      final expectedPrimary = ((merged.length + 1) * primaryRatio).round();
      final shouldTakePrimary =
          secondaryIndex >= secondary.length ||
          (primaryIndex < primary.length && primaryTaken < expectedPrimary);
      if (shouldTakePrimary) {
        tryTakeFrom(primary, true);
      } else {
        tryTakeFrom(secondary, false);
      }
      if (merged.length >= maxTarget) break;
      if (primaryIndex >= primary.length && secondaryIndex < secondary.length) {
        tryTakeFrom(secondary, false);
      } else if (secondaryIndex >= secondary.length &&
          primaryIndex < primary.length) {
        tryTakeFrom(primary, true);
      }
      if (primaryTaken + secondaryTaken == 0) {
        break;
      }
    }
    return merged;
  }

  String _smartQueueRawTrackDedupKey(Map<String, dynamic> raw) {
    final id = (raw['spotify_id'] ?? raw['id'] ?? '').toString().trim();
    final source = (raw['source'] ?? raw['provider_id'] ?? '')
        .toString()
        .trim();
    if (id.isNotEmpty && source.isNotEmpty) {
      return 'src:${_normalizeSmartQueueKey(source)}:${_normalizeSmartQueueKey(id)}';
    }
    if (id.isNotEmpty) {
      return 'id:${_normalizeSmartQueueKey(id)}';
    }
    final title = (raw['name'] ?? '').toString().trim();
    final artist = (raw['artists'] ?? raw['artist'] ?? '').toString().trim();
    if (title.isEmpty && artist.isEmpty) return '';
    return 'name:${_normalizeSmartQueueKey(title)}|${_normalizeSmartQueueKey(artist)}';
  }

  Future<List<Map<String, dynamic>>> _searchSpotifyTracksForSmartQueue(
    String query, {
    required int trackLimit,
  }) async {
    final response = await PlatformBridge.customSearchWithExtension(
      _smartQueueSpotifyExtensionId,
      query,
      options: <String, dynamic>{
        'filter': 'tracks',
        'limit': min(50, max(1, trackLimit)),
        'offset': 0,
      },
    );
    return response
        .where(
          (item) =>
              (item['item_type'] ?? 'track').toString().toLowerCase() ==
              'track',
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _searchDeezerTracksForSmartQueue(
    String query, {
    required int trackLimit,
  }) async {
    final result = await PlatformBridge.searchDeezerAll(
      query,
      trackLimit: trackLimit,
      artistLimit: 0,
      filter: 'track',
    );
    final tracks = result['tracks'] as List<dynamic>? ?? const [];
    return tracks
        .whereType<Map>()
        .map((entry) {
          final map = Map<String, dynamic>.from(entry);
          map.putIfAbsent('provider_id', () => 'deezer');
          map.putIfAbsent('source', () => 'deezer');
          return map;
        })
        .toList(growable: false);
  }

  String _resolveSmartQueueSourceLabel(Track track) {
    final raw = (track.source ?? '').trim().toLowerCase();
    if (raw.isNotEmpty) return raw;
    final id = track.id.trim().toLowerCase();
    if (id.startsWith('deezer:')) return 'deezer';
    if (id.startsWith('spotify:')) return 'spotify';
    return 'unknown';
  }

  Track _parseSearchTrackForSmartQueue(
    Map<String, dynamic> data, {
    String? source,
  }) {
    final durationMs = _extractDurationMsForSmartQueue(data);
    final itemType = data['item_type']?.toString();
    return Track(
      id: (data['spotify_id'] ?? data['id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      artistName: (data['artists'] ?? data['artist'] ?? '').toString(),
      albumName: (data['album_name'] ?? data['album'] ?? '').toString(),
      albumArtist: data['album_artist']?.toString(),
      artistId: (data['artist_id'] ?? data['artistId'])?.toString(),
      albumId: data['album_id']?.toString(),
      coverUrl: (data['cover_url'] ?? data['images'])?.toString(),
      isrc: data['isrc']?.toString(),
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      releaseDate: data['release_date']?.toString(),
      source:
          source ??
          data['source']?.toString() ??
          data['provider_id']?.toString(),
      albumType: data['album_type']?.toString(),
      itemType: itemType,
      deezerId: data['deezer_id']?.toString(),
    );
  }

  int _extractDurationMsForSmartQueue(Map<String, dynamic> data) {
    final durationMsRaw = data['duration_ms'];
    if (durationMsRaw is num && durationMsRaw > 0) {
      return durationMsRaw.toInt();
    }
    if (durationMsRaw is String) {
      final parsed = num.tryParse(durationMsRaw.trim());
      if (parsed != null && parsed > 0) {
        return parsed.toInt();
      }
    }

    final durationSecRaw = data['duration'];
    if (durationSecRaw is num && durationSecRaw > 0) {
      return (durationSecRaw * 1000).toInt();
    }
    if (durationSecRaw is String) {
      final parsed = num.tryParse(durationSecRaw.trim());
      if (parsed != null && parsed > 0) {
        return (parsed * 1000).toInt();
      }
    }
    return 0;
  }

  void _registerSmartQueueTrackHints({
    required Track track,
    required Map<String, dynamic> raw,
  }) {
    final tempo = _extractTempoBpmForSmartQueue(raw);
    if (tempo == null || tempo <= 0) return;
    final key = _trackKeyFromTrack(track);
    if (key.isEmpty) return;
    _smartQueueTempoHintByTrackKey[key] = tempo;
    if (_smartQueueTempoHintByTrackKey.length > _smartQueueMaxTempoHints) {
      final removeCount =
          _smartQueueTempoHintByTrackKey.length - _smartQueueMaxTempoHints;
      final keys = _smartQueueTempoHintByTrackKey.keys
          .take(removeCount)
          .toList(growable: false);
      for (final k in keys) {
        _smartQueueTempoHintByTrackKey.remove(k);
      }
    }
  }

  double? _extractTempoBpmForSmartQueue(Map<String, dynamic> raw) {
    const keys = <String>['tempo', 'bpm', 'audio_tempo', 'track_bpm'];
    for (final key in keys) {
      final value = raw[key];
      if (value is num) {
        final bpm = value.toDouble();
        if (bpm > 30 && bpm < 260) return bpm;
      } else if (value is String) {
        final bpm = double.tryParse(value.trim());
        if (bpm != null && bpm > 30 && bpm < 260) return bpm;
      }
    }
    return null;
  }

  _SmartQueueCandidate? _buildSmartQueueCandidate({
    required Track seed,
    required Track candidate,
    required Set<String> existingTrackKeys,
  }) {
    final candidateKey = _trackKeyFromTrack(candidate);
    if (candidateKey.isEmpty || existingTrackKeys.contains(candidateKey)) {
      return null;
    }

    final features = _buildSmartQueueFeatures(
      seed: seed,
      candidate: candidate,
      existingTrackKeys: existingTrackKeys,
    );
    final prediction = _smartQueuePredict(features);
    final exploration =
        _smartQueueRandom.nextDouble() * _sessionExplorationCeiling();
    final score = prediction + exploration;
    return _SmartQueueCandidate(
      track: candidate,
      key: candidateKey,
      features: features,
      score: score,
    );
  }

  Map<String, double> _buildSmartQueueFeatures({
    required Track seed,
    required Track candidate,
    required Set<String> existingTrackKeys,
  }) {
    final sameArtist =
        _normalizeSmartQueueKey(seed.artistName) ==
            _normalizeSmartQueueKey(candidate.artistName)
        ? 1.0
        : 0.0;
    final sameAlbum =
        _normalizeSmartQueueKey(seed.albumName) ==
            _normalizeSmartQueueKey(candidate.albumName)
        ? 1.0
        : 0.0;
    final durationSimilarity = _durationSimilarity(
      seed.duration,
      candidate.duration,
    );
    final sourceMatch =
        _sourceKey(seed.source ?? '') == _sourceKey(candidate.source ?? '')
        ? 1.0
        : 0.0;
    final releaseYearSimilarity = _releaseYearSimilarity(
      seed.releaseDate,
      candidate.releaseDate,
    );
    final artistAffinityRaw =
        _smartQueueArtistAffinity[_normalizeSmartQueueKey(
          candidate.artistName,
        )] ??
        0.0;
    final sourceAffinityRaw =
        _smartQueueSourceAffinity[_sourceKey(candidate.source ?? '')] ?? 0.0;
    final artistAffinity = ((artistAffinityRaw + 1.0) / 2.0).clamp(0.0, 1.0);
    final sourceAffinity = ((sourceAffinityRaw + 1.0) / 2.0).clamp(0.0, 1.0);
    final sessionAlignment = _smartQueueSessionAlignment(
      profile: _smartQueueSessionProfile,
      candidate: candidate,
    );
    final hourAffinityRaw =
        _smartQueueHourAffinity[_currentSmartQueueHourBucket()] ?? 0.0;
    final hourAffinity = ((hourAffinityRaw + 1.0) / 2.0).clamp(0.0, 1.0);
    final tempoContinuity = _smartQueueTempoContinuity(
      seed: seed,
      candidate: candidate,
    );
    final yearCohesion = _smartQueueYearCohesion(
      profile: _smartQueueSessionProfile,
      candidate: candidate,
    );

    var artistRepetition = 0;
    final candidateArtist = _normalizeSmartQueueKey(candidate.artistName);
    if (candidateArtist.isNotEmpty) {
      for (final key in _recentPlayedTrackKeys.take(10)) {
        if (key.contains('|$candidateArtist')) {
          artistRepetition++;
        }
      }
      for (final queueItem in state.queue.reversed.take(6)) {
        final artist = _normalizeSmartQueueKey(queueItem.artist);
        if (artist.isNotEmpty && artist == candidateArtist) {
          artistRepetition++;
        }
      }
    }
    final novelty = (1.0 - (artistRepetition / 3.0)).clamp(0.15, 1.0);

    final alreadySeen = existingTrackKeys.contains(
      _trackKeyFromTrack(candidate),
    );
    final noveltyAfterDuplicateCheck = alreadySeen ? 0.0 : novelty;
    final skipPressure = (_smartQueueSkipStreak / _smartQueueMaxSkipStreak)
        .clamp(0.0, 1.0);
    final skipContext = (1.0 - (sameArtist * skipPressure)).clamp(0.05, 1.0);

    return <String, double>{
      'same_artist': sameArtist,
      'same_album': sameAlbum,
      'duration_similarity': durationSimilarity,
      'source_match': sourceMatch,
      'release_year_similarity': releaseYearSimilarity,
      'artist_affinity': artistAffinity,
      'source_affinity': sourceAffinity,
      'novelty': noveltyAfterDuplicateCheck,
      'session_alignment': sessionAlignment,
      'hour_affinity': hourAffinity,
      'skip_context': skipContext,
      'tempo_continuity': tempoContinuity,
      'year_cohesion': yearCohesion,
    };
  }

  double _durationSimilarity(int aSec, int bSec) {
    if (aSec <= 0 || bSec <= 0) return 0.5;
    final maxSec = max(aSec, bSec).toDouble();
    final diff = (aSec - bSec).abs().toDouble();
    final normalized = (1.0 - (diff / maxSec)).clamp(0.0, 1.0);
    return normalized;
  }

  double _releaseYearSimilarity(String? a, String? b) {
    final yearA = _parseYear(a);
    final yearB = _parseYear(b);
    if (yearA == null || yearB == null) return 0.5;
    final diff = (yearA - yearB).abs();
    if (diff == 0) return 1.0;
    if (diff <= 1) return 0.85;
    if (diff <= 3) return 0.65;
    if (diff <= 6) return 0.45;
    return 0.2;
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final match = RegExp(r'(\d{4})').firstMatch(raw);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  double _sessionExplorationCeiling() {
    return switch (_smartQueueSessionProfile.mode) {
      _SmartQueueSessionMode.focus => 0.03,
      _SmartQueueSessionMode.chill => 0.045,
      _SmartQueueSessionMode.energetic => 0.08,
      _SmartQueueSessionMode.balanced => 0.06,
    };
  }

  double _smartQueueSessionAlignment({
    required _SmartQueueSessionProfile profile,
    required Track candidate,
  }) {
    final targetDuration = max(1, profile.targetDurationSec);
    final durationDiff = (candidate.duration - targetDuration).abs().toDouble();
    final durationMatch =
        (1.0 - (durationDiff / max(90.0, targetDuration.toDouble()))).clamp(
          0.0,
          1.0,
        );
    final yearMatch = _smartQueueYearCohesion(
      profile: profile,
      candidate: candidate,
    );
    final preferredSource = _normalizeSmartQueueKey(profile.preferredSourceKey);
    final candidateSource = _sourceKey(candidate.source ?? '');
    final sourceMatch =
        preferredSource.isEmpty || candidateSource == preferredSource
        ? 1.0
        : 0.45;
    return ((durationMatch * 0.55) + (yearMatch * 0.25) + (sourceMatch * 0.20))
        .clamp(0.0, 1.0);
  }

  double _smartQueueYearCohesion({
    required _SmartQueueSessionProfile profile,
    required Track candidate,
  }) {
    final targetYear = profile.targetYear;
    final candidateYear = _parseYear(candidate.releaseDate);
    if (targetYear == null || candidateYear == null) return 0.55;
    final diff = (targetYear - candidateYear).abs();
    if (diff == 0) return 1.0;
    if (diff <= 2) return 0.88;
    if (diff <= 5) return 0.72;
    if (diff <= 10) return 0.5;
    if (diff <= 15) return 0.3;
    return 0.1;
  }

  double _smartQueueTempoContinuity({
    required Track seed,
    required Track candidate,
  }) {
    final seedTempo = _smartQueueTempoHintForTrack(seed);
    final candidateTempo = _smartQueueTempoHintForTrack(candidate);
    if (seedTempo == null || candidateTempo == null) {
      return _durationSimilarity(
        seed.duration,
        candidate.duration,
      ).clamp(0.2, 1.0);
    }
    final diff = (seedTempo - candidateTempo).abs();
    if (diff <= 8) return 1.0;
    if (diff <= 16) return 0.82;
    if (diff <= 26) return 0.62;
    if (diff <= _smartQueueMaxTempoJumpBpm) return 0.38;
    return 0.12;
  }

  double? _smartQueueTempoHintForTrack(Track track) {
    final key = _trackKeyFromTrack(track);
    if (key.isEmpty) return null;
    final raw = _smartQueueTempoHintByTrackKey[key];
    if (raw == null || raw <= 0) return null;
    return raw;
  }

  String _sourceKey(String sourceRaw) {
    final normalized = _normalizeSmartQueueKey(sourceRaw);
    if (normalized.isNotEmpty) return normalized;
    return _resolveService(
      ref.read(settingsProvider).defaultService,
    ).toLowerCase();
  }

  List<_SmartQueueCandidate> _selectSmartQueueCandidates({
    required Track seed,
    required _SmartQueueSessionProfile sessionProfile,
    required List<_SmartQueueCandidate> scored,
    required int targetCount,
  }) {
    if (targetCount <= 0 || scored.isEmpty) return const [];

    final poolSize = min(scored.length, max(14, targetCount * 3));
    final pool = scored.take(poolSize).toList(growable: true);
    final selected = <_SmartQueueCandidate>[];
    final artistCounts = _buildSmartQueueArtistBaselineCounts();
    final selectedKeys = <String>{};

    while (pool.isNotEmpty && selected.length < targetCount) {
      final picked = _pickWeightedCandidate(pool);
      pool.remove(picked);
      if (selectedKeys.contains(picked.key)) {
        continue;
      }

      final artistKey = _normalizeSmartQueueKey(picked.track.artistName);
      final repeats = artistCounts[artistKey] ?? 0;
      if (artistKey.isNotEmpty && repeats >= _smartQueueMaxArtistRepeats) {
        continue;
      }

      if (!_passesSmartQueueConstraints(
        seed: seed,
        candidate: picked.track,
        profile: sessionProfile,
      )) {
        continue;
      }

      selected.add(picked);
      selectedKeys.add(picked.key);
      if (artistKey.isNotEmpty) {
        artistCounts[artistKey] = repeats + 1;
      }
    }

    if (selected.isEmpty) {
      final relaxedArtistLimit = _smartQueueMaxArtistRepeats + 1;
      for (final candidate in scored) {
        if (selected.length >= targetCount) break;
        if (selectedKeys.contains(candidate.key)) continue;

        final artistKey = _normalizeSmartQueueKey(candidate.track.artistName);
        final repeats = artistCounts[artistKey] ?? 0;
        if (artistKey.isNotEmpty && repeats >= relaxedArtistLimit) {
          continue;
        }

        selected.add(candidate);
        selectedKeys.add(candidate.key);
        if (artistKey.isNotEmpty) {
          artistCounts[artistKey] = repeats + 1;
        }
      }
    }

    return selected;
  }

  Map<String, int> _buildSmartQueueArtistBaselineCounts() {
    final counts = <String, int>{};
    for (final item in state.queue.reversed.take(8)) {
      final artistKey = _normalizeSmartQueueKey(item.artist);
      if (artistKey.isEmpty) continue;
      counts[artistKey] = (counts[artistKey] ?? 0) + 1;
    }
    for (final signal in _smartQueueSessionSignals.reversed.take(8)) {
      final artistKey = signal.artistKey;
      if (artistKey.isEmpty) continue;
      counts[artistKey] = (counts[artistKey] ?? 0) + 1;
    }
    return counts;
  }

  bool _passesSmartQueueConstraints({
    required Track seed,
    required Track candidate,
    required _SmartQueueSessionProfile profile,
  }) {
    final seedYear = _parseYear(seed.releaseDate);
    final candidateYear = _parseYear(candidate.releaseDate);
    if (seedYear != null &&
        candidateYear != null &&
        (seedYear - candidateYear).abs() > _smartQueueMaxDecadeDriftYears) {
      return false;
    }

    if (profile.targetYear != null &&
        candidateYear != null &&
        (profile.targetYear! - candidateYear).abs() >
            _smartQueueMaxDecadeDriftYears) {
      return false;
    }

    final seedTempo = _smartQueueTempoHintForTrack(seed);
    final candidateTempo = _smartQueueTempoHintForTrack(candidate);
    if (seedTempo != null &&
        candidateTempo != null &&
        (seedTempo - candidateTempo).abs() > _smartQueueMaxTempoJumpBpm) {
      return false;
    }

    final seedDuration = max(1, seed.duration);
    final candidateDuration = max(1, candidate.duration);
    final durationRatio = candidateDuration / seedDuration;
    if (durationRatio > 2.25 || durationRatio < 0.45) {
      return false;
    }
    return true;
  }

  _SmartQueueCandidate _pickWeightedCandidate(List<_SmartQueueCandidate> pool) {
    if (pool.length == 1) return pool.first;

    var total = 0.0;
    for (final item in pool) {
      total += max(0.0001, item.score);
    }
    var cursor = _smartQueueRandom.nextDouble() * total;
    for (final item in pool) {
      cursor -= max(0.0001, item.score);
      if (cursor <= 0) return item;
    }
    return pool.last;
  }

  void _pruneSmartQueueCaches() {
    final now = DateTime.now();
    _smartQueueSearchCache.removeWhere(
      (_, value) => now.difference(value.fetchedAt) > _smartQueueSearchCacheTtl,
    );
    _smartQueueRelatedArtistsCache.removeWhere(
      (_, value) => now.difference(value.fetchedAt) > _smartQueueSearchCacheTtl,
    );
    _smartQueuePendingFeedbackByTrack.removeWhere(
      (_, value) => now.difference(value.addedAt) > _smartQueueFeedbackMaxAge,
    );
  }

  Uri _uriFromPath(String path) {
    final input = path.trim();
    if (input.startsWith('http://') ||
        input.startsWith('https://') ||
        input.startsWith('content://') ||
        input.startsWith('file://')) {
      return Uri.parse(input);
    }
    return Uri.file(input);
  }

  String _resolvePrefetchServiceBucket(PlaybackItem item) {
    final itemService = item.service.trim().toLowerCase();
    if (_isBuiltInStreamingService(itemService)) {
      return itemService;
    }

    final trackSource = (item.track?.source ?? '').trim().toLowerCase();
    if (_isBuiltInStreamingService(trackSource)) {
      return trackSource;
    }

    final defaultService = _resolveService(
      ref.read(settingsProvider).defaultService,
    ).toLowerCase();
    if (_isBuiltInStreamingService(defaultService)) {
      return defaultService;
    }
    return 'other';
  }

  int _defaultPrefetchResolveLatencyMs(String serviceBucket) {
    switch (serviceBucket) {
      case 'tidal':
        return 16000;
      case 'amazon':
        return 15000;
      case 'qobuz':
        return 10000;
      case 'youtube':
        return 12000;
      default:
        return 10000;
    }
  }

  int _prefetchSafetyMarginMs(String serviceBucket) {
    switch (serviceBucket) {
      case 'tidal':
        return 9000;
      case 'amazon':
        return 7000;
      case 'qobuz':
        return 5000;
      case 'youtube':
        return 6000;
      default:
        return 5000;
    }
  }

  int _estimatePrefetchResolveLatencyMs(String serviceBucket) {
    final samples = _prefetchLatencyByServiceMs[serviceBucket];
    if (samples == null || samples.isEmpty) {
      return _defaultPrefetchResolveLatencyMs(serviceBucket);
    }

    final sorted = [...samples]..sort();
    final percentileIndex = (((sorted.length - 1) * 0.95).round()).clamp(
      0,
      sorted.length - 1,
    );
    return sorted[percentileIndex];
  }

  Duration _adaptivePrefetchThresholdFor(PlaybackItem nextItem) {
    final serviceBucket = _resolvePrefetchServiceBucket(nextItem);
    var triggerMs =
        _estimatePrefetchResolveLatencyMs(serviceBucket) +
        _prefetchSafetyMarginMs(serviceBucket);
    if (serviceBucket == 'tidal') {
      // DASH manifest flow typically needs earlier warmup than direct URLs.
      triggerMs = max(triggerMs, 22000);
    }
    final clamped = triggerMs.clamp(
      _prefetchThresholdFloor.inMilliseconds,
      _prefetchThresholdCeiling.inMilliseconds,
    );
    return Duration(milliseconds: clamped.toInt());
  }

  bool _shouldTriggerPrefetchAttempt({
    required int attempts,
    required Duration position,
    required Duration remaining,
    required Duration threshold,
  }) {
    if (attempts >= _maxPrefetchAttemptsPerTrack) {
      return false;
    }
    if (position < const Duration(seconds: 1) || remaining.isNegative) {
      return false;
    }

    final inLateWindow = remaining <= threshold;
    if (attempts == 0) {
      return inLateWindow || position >= _prefetchEarlyKickoffPosition;
    }

    // Retry only close to track end to avoid repeated resolver load.
    return inLateWindow;
  }

  void _maybePrefetchNext(Duration position) {
    if (state.isLoading || state.currentIndex < 0 || state.queue.isEmpty) {
      return;
    }
    final duration = state.duration;
    if (duration <= Duration.zero) return;

    final nextIndex = _peekNextIndexForPrefetch();
    if (nextIndex == null) return;
    if (nextIndex < 0 || nextIndex >= state.queue.length) return;
    if (_prefetchingQueueIndex == nextIndex &&
        _lastPrefetchAttemptIndex == nextIndex) {
      return;
    }

    final nextItem = state.queue[nextIndex];
    if (nextItem.sourceUri.isNotEmpty ||
        nextItem.track == null ||
        nextItem.isLocal) {
      return;
    }

    final remaining = duration - position;
    final adaptiveThreshold = _adaptivePrefetchThresholdFor(nextItem);
    final attempts = _prefetchAttemptCounts[nextIndex] ?? 0;
    if (!_shouldTriggerPrefetchAttempt(
      attempts: attempts,
      position: position,
      remaining: remaining,
      threshold: adaptiveThreshold,
    )) {
      return;
    }

    final lastAttemptAt = _prefetchLastAttemptAt[nextIndex];
    if (lastAttemptAt != null &&
        DateTime.now().difference(lastAttemptAt) < _prefetchRetryCooldown) {
      return;
    }

    _prefetchAttemptCounts[nextIndex] = attempts + 1;
    _prefetchLastAttemptAt[nextIndex] = DateTime.now();
    _lastPrefetchAttemptIndex = nextIndex;
    unawaited(_prefetchQueueIndex(nextIndex));
  }

  int? _peekNextIndexForPrefetch() {
    if (state.queue.isEmpty) return null;

    if (state.shuffle) {
      final nextPos = _shufflePosition + 1;
      if (nextPos < _shuffleOrder.length) {
        return _shuffleOrder[nextPos];
      }
      if (state.repeatMode == RepeatMode.all && _shuffleOrder.isNotEmpty) {
        return _shuffleOrder.first;
      }
      return null;
    }

    final next = state.currentIndex + 1;
    if (next < state.queue.length) return next;
    if (state.repeatMode == RepeatMode.all) return 0;
    return null;
  }

  Future<void> _prefetchQueueIndex(int index) async {
    if (index < 0) return;
  }

  String _resolveService(String defaultService) {
    final selected = defaultService.trim();
    if (selected.isEmpty) {
      return 'tidal';
    }
    final normalized = selected.toLowerCase();
    if (_isBuiltInStreamingService(normalized)) {
      return normalized;
    }
    return selected;
  }

  bool _isBuiltInStreamingService(String service) {
    switch (service) {
      case 'tidal':
      case 'qobuz':
      case 'amazon':
      case 'youtube':
        return true;
      default:
        return false;
    }
  }

  void _setPlaybackError(String message, {String type = 'resolve_failed'}) {
    final trimmed = message.trim();
    state = state.copyWith(
      isLoading: false,
      isPlaying: false,
      isBuffering: false,
      error: trimmed.isEmpty ? 'Playback error' : trimmed,
      errorType: type,
    );
  }

  bool _shouldAutoSkipQueueItemOnFailure(String? failureType) {
    final settings = ref.read(settingsProvider);
    if (!settings.autoSkipUnavailableTracks) {
      return false;
    }
    final normalized = (failureType ?? '').trim().toLowerCase();
    return normalized == 'not_found' || normalized == 'resolve_failed';
  }

  int? _resolveNextQueueIndexWithoutWrapAfterFailure(int failedIndex) {
    if (failedIndex < 0 || failedIndex >= state.queue.length) return null;

    if (state.shuffle) {
      final failedShufflePos = _shuffleOrder.indexOf(failedIndex);
      if (failedShufflePos < 0) return null;
      final nextShufflePos = failedShufflePos + 1;
      if (nextShufflePos >= _shuffleOrder.length) return null;
      return _shuffleOrder[nextShufflePos];
    }

    final nextIndex = failedIndex + 1;
    if (nextIndex >= state.queue.length) return null;
    return nextIndex;
  }

  Future<bool> _handleQueueItemPlaybackFailure({
    required int failedIndex,
    required int expectedRequestEpoch,
    required Object error,
    String fallbackType = 'resolve_failed',
  }) async {
    if (!_isPlayRequestCurrent(expectedRequestEpoch)) {
      return false;
    }

    final hasExistingError = (state.error ?? '').trim().isNotEmpty;
    if (hasExistingError) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        isBuffering: false,
      );
    } else {
      _setPlaybackError('Failed to play: $error', type: fallbackType);
    }

    if (!_isPlayRequestCurrent(expectedRequestEpoch) ||
        state.currentIndex != failedIndex ||
        !_shouldAutoSkipQueueItemOnFailure(state.errorType)) {
      return false;
    }

    final nextIndex = _resolveNextQueueIndexWithoutWrapAfterFailure(
      failedIndex,
    );
    if (nextIndex == null || nextIndex == failedIndex) {
      return false;
    }

    final failureMessage = (state.error ?? '').trim();
    _log.w(
      'Auto-skip queue item $failedIndex -> $nextIndex '
      'after ${state.errorType ?? fallbackType}: '
      '${failureMessage.isNotEmpty ? failureMessage : error}',
    );
    await _playQueueIndex(nextIndex);
    return true;
  }

  bool _inferSeekSupportedForQueueItem(PlaybackItem item) {
    // Local files always support seeking
    if (item.isLocal) return true;

    // If sourceUri points to a local file (resolved stream cached), it supports seeking
    if (item.sourceUri.startsWith('/') ||
        item.sourceUri.startsWith('file://')) {
      return true;
    }

    final service = item.service.trim().toLowerCase();
    final trackSource = (item.track?.source ?? '').trim().toLowerCase();
    final resolvedService = service.isNotEmpty ? service : trackSource;

    // YouTube HLS/DASH streams often have issues with direct seeking via just_audio
    if (resolvedService == 'youtube') return false;

    final sourceUri = item.sourceUri.trim();
    // Live tunnels (ffmpeg -listen) do not support random access seeking
    if (sourceUri.isNotEmpty &&
        FFmpegService.isActiveLiveDecryptedUrl(sourceUri)) {
      return false;
    }

    return true;
  }

  Duration? _pendingResumePositionForIndex(int index) {
    final pendingPosition = _pendingResumePosition;
    final pendingIndex = _pendingResumeIndex;
    if (pendingPosition == null ||
        pendingPosition <= Duration.zero ||
        pendingIndex != index) {
      return null;
    }
    return pendingPosition;
  }

  void _clearPendingResumeForIndex(int index) {
    if (_pendingResumeIndex != index) return;
    _pendingResumePosition = null;
    _pendingResumeIndex = null;
  }

  void _scheduleSnapshotSaveForProgress(Duration position) {
    if (state.queue.isEmpty || state.currentIndex < 0) return;
    if (_player.processingState == ProcessingState.idle) return;

    final ms = position.inMilliseconds;
    if (_lastProgressSnapshotMs >= 0 &&
        (ms - _lastProgressSnapshotMs).abs() < 1500) {
      return;
    }
    _lastProgressSnapshotMs = ms;

    _snapshotSaveTimer?.cancel();
    _snapshotSaveTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_savePlaybackSnapshot());
    });
  }

  void _disposeInternal() {
    _appLifecycleListener?.dispose();
    _appLifecycleListener = null;
    _snapshotSaveTimer?.cancel();
    _smartQueueModelSaveTimer?.cancel();
    unawaited(_savePlaybackSnapshot());
    unawaited(_persistSmartQueueModel());
    unawaited(FFmpegService.stopLiveDecryptedStream());
    unawaited(FFmpegService.stopNativeDashManifestPlayback());
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
  }
}

class _SmartQueueLearningContext {
  final Map<String, double> features;
  final DateTime addedAt;

  const _SmartQueueLearningContext({
    required this.features,
    required this.addedAt,
  });
}

enum _SmartQueueSessionMode { balanced, focus, chill, energetic }

class _SmartQueueSessionProfile {
  final _SmartQueueSessionMode mode;
  final int targetDurationSec;
  final int? targetYear;
  final String preferredSourceKey;

  const _SmartQueueSessionProfile({
    required this.mode,
    required this.targetDurationSec,
    this.targetYear,
    this.preferredSourceKey = '',
  });
}

class _SmartQueueSessionSignal {
  final String artistKey;
  final String sourceKey;
  final int durationSec;
  final int? releaseYear;
  final double listenRatio;
  final bool skipped;

  const _SmartQueueSessionSignal({
    required this.artistKey,
    required this.sourceKey,
    required this.durationSec,
    required this.releaseYear,
    required this.listenRatio,
    required this.skipped,
  });
}

class _SmartQueueCachedResult {
  final List<Track> tracks;
  final DateTime fetchedAt;

  const _SmartQueueCachedResult({
    required this.tracks,
    required this.fetchedAt,
  });
}

class _SmartQueueRelatedArtistsCache {
  final List<_SmartQueueRelatedArtist> artists;
  final DateTime fetchedAt;

  const _SmartQueueRelatedArtistsCache({
    required this.artists,
    required this.fetchedAt,
  });
}

class _SmartQueueRelatedArtist {
  final String name;
  final String provider;
  final double score;

  const _SmartQueueRelatedArtist({
    required this.name,
    required this.provider,
    required this.score,
  });
}

class _SmartQueueArtistSeed {
  final String id;
  final String name;
  final String provider;
  final double score;

  const _SmartQueueArtistSeed({
    required this.id,
    required this.name,
    required this.provider,
    required this.score,
  });
}

class _SmartQueueCandidate {
  final Track track;
  final String key;
  final Map<String, double> features;
  final double score;

  const _SmartQueueCandidate({
    required this.track,
    required this.key,
    required this.features,
    required this.score,
  });
}

final playbackProvider = NotifierProvider<PlaybackController, PlaybackState>(
  PlaybackController.new,
);
