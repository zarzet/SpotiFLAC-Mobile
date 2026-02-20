import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotiflac_android/models/playback_item.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/services/ffmpeg_service.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/services/stream_request_payload.dart';
import 'package:spotiflac_android/utils/logger.dart';

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
  final AudioPlayer _player;
  final void Function() _onSkipNext;
  final void Function() _onSkipPrevious;
  final void Function() _onStop;
  final Future<void> Function(Duration position) _onSeek;

  _SpotiFLACAudioHandler({
    required AudioPlayer player,
    required void Function() onSkipNext,
    required void Function() onSkipPrevious,
    required void Function() onStop,
    required Future<void> Function(Duration position) onSeek,
  }) : _player = player,
       _onSkipNext = onSkipNext,
       _onSkipPrevious = onSkipPrevious,
       _onStop = onStop,
       _onSeek = onSeek;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _onSeek(position);

  @override
  Future<void> stop() async {
    _onStop();
  }

  @override
  Future<void> skipToNext() async => _onSkipNext();

  @override
  Future<void> skipToPrevious() async => _onSkipPrevious();
}

// ─── Controller ──────────────────────────────────────────────────────────────
class PlaybackController extends Notifier<PlaybackState> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  _SpotiFLACAudioHandler? _audioHandler;
  var _initialized = false;

  // Shuffle order: indices into queue
  List<int> _shuffleOrder = [];
  int _shufflePosition = -1;

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
          _onTrackCompleted();
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
            state = state.copyWith(position: position);
          }),
    );

    _subscriptions.add(
      _player.bufferedPositionStream.listen((bufferedPosition) {
        state = state.copyWith(bufferedPosition: bufferedPosition);
      }),
    );

    _subscriptions.add(
      _player.durationStream.listen((duration) {
        state = state.copyWith(duration: duration ?? Duration.zero);

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
              player: _player,
              onSkipNext: () => unawaited(skipNext()),
              onSkipPrevious: () => unawaited(skipPrevious()),
              onStop: () => unawaited(stop()),
              onSeek: seek,
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

    final controls = <audio_service.MediaControl>[
      audio_service.MediaControl.skipToPrevious,
      if (playing)
        audio_service.MediaControl.pause
      else
        audio_service.MediaControl.play,
      audio_service.MediaControl.skipToNext,
      audio_service.MediaControl.stop,
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
        artUri:
            item.coverUrl.isNotEmpty &&
                (item.coverUrl.startsWith('http://') ||
                    item.coverUrl.startsWith('https://'))
            ? Uri.tryParse(item.coverUrl)
            : null,
        extras: {
          if (item.service.isNotEmpty) 'service': item.service,
          if (item.format.isNotEmpty) 'format': item.format,
        },
      ),
    );
  }

  // ─── Track completion ────────────────────────────────────────────────────
  void _onTrackCompleted() {
    if (state.repeatMode == RepeatMode.one) {
      // Replay current track
      unawaited(_restartCurrentTrack(playAfterSeek: true));
      return;
    }

    final nextIndex = _resolveNextIndex();
    if (nextIndex != null) {
      unawaited(_playQueueIndex(nextIndex));
    } else {
      // Queue exhausted
      state = state.copyWith(isPlaying: false, position: Duration.zero);
    }
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

      final track = state.currentItem?.track;
      if (track != null) {
        await playTrackStream(track);
        return;
      }

      _setPlaybackError(
        'Failed to restart this stream from the beginning.',
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

  // ─── Public: play a Track (streaming) ────────────────────────────────────
  Future<void> playTrackStream(Track track) async {
    await FFmpegService.stopLiveDecryptedStream();

    final settings = ref.read(settingsProvider);
    final extensionState = ref.read(extensionProvider);
    final hasActiveExtensions = extensionState.extensions.any((e) => e.enabled);
    final selectedService = _resolveService(settings.defaultService);
    final sourceForResolver = _resolveStreamSource(track, extensionState);
    final quality = _resolveStreamQuality(
      selectedService,
      settings.audioQuality,
    );

    final resolvingItem = PlaybackItem(
      id: track.id,
      title: track.name,
      artist: track.artistName,
      album: track.albumName,
      coverUrl: track.coverUrl ?? '',
      sourceUri: '',
      isLocal: false,
      service: selectedService,
      durationMs: track.duration,
      track: track,
    );

    state = state.copyWith(
      currentItem: resolvingItem,
      isLoading: true,
      isBuffering: true,
      isPlaying: false,
      seekSupported: true,
      position: Duration.zero,
      bufferedPosition: Duration.zero,
      duration: Duration.zero,
      clearError: true,
    );
    _updateMediaItemNotification(resolvingItem);

    final payload = StreamRequestPayload(
      service: selectedService,
      spotifyId: track.id,
      isrc: track.isrc ?? '',
      trackName: track.name,
      artistName: track.artistName,
      albumName: track.albumName,
      quality: quality,
      source: sourceForResolver,
      deezerId: track.deezerId ?? '',
      durationMs: track.duration,
      useExtensions: settings.useExtensionProviders && hasActiveExtensions,
      useFallback: settings.autoFallback,
      songLinkRegion: settings.songLinkRegion,
    );

    final result = await PlatformBridge.resolveStreamByStrategy(payload);
    final requiresDecryption = result['requires_decryption'] == true;
    if (result['success'] != true && !requiresDecryption) {
      final failure = _buildStreamResolveFailure(result);
      _setPlaybackError(failure.message, type: failure.type);
      throw Exception(failure.message);
    }

    final rawStreamUrl = (result['stream_url'] as String?)?.trim() ?? '';
    if (rawStreamUrl.isEmpty) {
      _setPlaybackError(
        'Resolved stream URL is empty.',
        type: 'resolve_failed',
      );
      throw Exception('Resolved stream URL is empty.');
    }

    var playbackUrl = rawStreamUrl;
    var playbackFormat = (result['format'] as String?) ?? '';
    var persistResolvedUrl = true;

    if (requiresDecryption) {
      final decryptionKey = (result['decryption_key'] as String?)?.trim() ?? '';
      if (decryptionKey.isEmpty) {
        final message = (result['error'] as String?)?.trim().isNotEmpty == true
            ? (result['error'] as String).trim()
            : 'Stream requires decryption key but key is empty.';
        _setPlaybackError(message, type: 'resolve_failed');
        throw Exception(message);
      }

      final decrypted = await FFmpegService.startAmazonLiveDecryptedStream(
        encryptedStreamUrl: rawStreamUrl,
        decryptionKey: decryptionKey,
        preferredFormat: 'flac',
      );
      if (decrypted == null) {
        final message = (result['error'] as String?)?.trim().isNotEmpty == true
            ? (result['error'] as String).trim()
            : 'Failed to start live decryption stream.';
        _setPlaybackError(message, type: 'resolve_failed');
        throw Exception(message);
      }

      playbackUrl = decrypted.localUrl;
      playbackFormat = decrypted.format;
      persistResolvedUrl = false;
    }

    final item = PlaybackItem(
      id: track.id,
      title: track.name,
      artist: track.artistName,
      album: track.albumName,
      coverUrl: track.coverUrl ?? '',
      sourceUri: persistResolvedUrl ? playbackUrl : '',
      isLocal: false,
      service: (result['service'] as String?) ?? selectedService,
      durationMs: track.duration,
      format: playbackFormat,
      bitDepth: (result['bit_depth'] as int?) ?? 0,
      sampleRate: (result['sample_rate'] as int?) ?? 0,
      bitrate: (result['bitrate'] as int?) ?? 0,
      track: track,
    );

    state = state.copyWith(seekSupported: !requiresDecryption);
    await _setSourceAndPlay(Uri.parse(playbackUrl), item);
  }

  // ─── Public: play local file ─────────────────────────────────────────────
  Future<void> playLocalPath({
    required String path,
    required String title,
    required String artist,
    String album = '',
    String coverUrl = '',
  }) async {
    await FFmpegService.stopLiveDecryptedStream();
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
    state = state.copyWith(seekSupported: true, clearError: true);
    await _setSourceAndPlay(uri, item);
  }

  // ─── Public: play a list of tracks (set queue) ───────────────────────────
  Future<void> playTrackList(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;

    final items = tracks
        .map(
          (t) => PlaybackItem(
            id: t.id,
            title: t.name,
            artist: t.artistName,
            album: t.albumName,
            coverUrl: t.coverUrl ?? '',
            sourceUri: '', // resolved lazily
            durationMs: t.duration,
            track: t,
          ),
        )
        .toList();

    state = state.copyWith(
      queue: items,
      currentIndex: startIndex.clamp(0, items.length - 1),
    );

    if (state.shuffle) {
      _regenerateShuffleOrder();
      // Start shuffle at the chosen index
      _shufflePosition = _shuffleOrder.indexOf(state.currentIndex);
      if (_shufflePosition < 0) _shufflePosition = 0;
    }

    await _playQueueIndex(state.currentIndex);
  }

  // ─── Public: play single track and set as queue of 1 ─────────────────────
  Future<void> playTrackStreamAndSetQueue(
    Track track,
    List<Track> albumTracks,
  ) async {
    final items = albumTracks
        .map(
          (t) => PlaybackItem(
            id: t.id,
            title: t.name,
            artist: t.artistName,
            album: t.albumName,
            coverUrl: t.coverUrl ?? '',
            sourceUri: '',
            durationMs: t.duration,
            track: t,
          ),
        )
        .toList();

    final startIndex = albumTracks.indexWhere((t) => t.id == track.id);
    state = state.copyWith(
      queue: items,
      currentIndex: startIndex >= 0 ? startIndex : 0,
    );

    if (state.shuffle) {
      _regenerateShuffleOrder();
      _shufflePosition = _shuffleOrder.indexOf(state.currentIndex);
      if (_shufflePosition < 0) _shufflePosition = 0;
    }

    await playTrackStream(track);

    // Update the queue item with resolved data
    if (startIndex >= 0 &&
        startIndex < state.queue.length &&
        state.currentItem != null) {
      final updatedQueue = [...state.queue];
      updatedQueue[startIndex] = state.currentItem!;
      state = state.copyWith(queue: updatedQueue);
    }
  }

  // ─── Public: add track to queue ──────────────────────────────────────────
  void addToQueue(Track track) {
    final item = PlaybackItem(
      id: track.id,
      title: track.name,
      artist: track.artistName,
      album: track.albumName,
      coverUrl: track.coverUrl ?? '',
      sourceUri: '',
      durationMs: track.duration,
      track: track,
    );

    final newQueue = [...state.queue, item];
    state = state.copyWith(queue: newQueue);

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
    if (state.shuffle) _regenerateShuffleOrder();
  }

  // ─── Public: clear queue ─────────────────────────────────────────────────
  void clearQueue() {
    state = state.copyWith(queue: [], currentIndex: -1);
    _shuffleOrder = [];
    _shufflePosition = -1;
  }

  // ─── Public: skip next / previous ────────────────────────────────────────
  Future<void> skipNext() async {
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
    final newShuffle = !state.shuffle;
    state = state.copyWith(shuffle: newShuffle);

    if (newShuffle) {
      _regenerateShuffleOrder();
      _shufflePosition = _shuffleOrder.indexOf(state.currentIndex);
      if (_shufflePosition < 0) _shufflePosition = 0;
    } else {
      _shuffleOrder = [];
      _shufflePosition = -1;
    }
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
      await _player.play();
    }
  }

  // ─── Public: seek ────────────────────────────────────────────────────────
  Future<void> seek(Duration position) async {
    if (!state.seekSupported) {
      _setPlaybackError(
        'Seeking is not supported for this live decrypted stream.',
        type: 'seek_not_supported',
      );
      return;
    }
    await _player.seek(position);
  }

  // ─── Public: stop ────────────────────────────────────────────────────────
  Future<void> stop() async {
    await FFmpegService.stopLiveDecryptedStream();
    await _player.stop();
    _audioHandler?.playbackState.add(
      audio_service.PlaybackState(
        processingState: audio_service.AudioProcessingState.idle,
        playing: false,
      ),
    );
    _audioHandler?.mediaItem.add(null);

    state = state.copyWith(
      clearCurrentItem: true,
      isPlaying: false,
      isBuffering: false,
      isLoading: false,
      seekSupported: true,
      position: Duration.zero,
      bufferedPosition: Duration.zero,
      duration: Duration.zero,
      clearError: true,
      clearLyrics: true,
      queue: [],
      currentIndex: -1,
    );
    _shuffleOrder = [];
    _shufflePosition = -1;
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  Future<void> _playQueueIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    final item = state.queue[index];
    state = state.copyWith(currentIndex: index);

    // If the item has a Track but no resolved sourceUri, resolve stream
    if (item.sourceUri.isEmpty && item.track != null) {
      try {
        await playTrackStream(item.track!);
        // Update the queue item with resolved data
        final updatedQueue = [...state.queue];
        if (index < updatedQueue.length && state.currentItem != null) {
          updatedQueue[index] = state.currentItem!;
          state = state.copyWith(queue: updatedQueue);
        }
      } catch (e) {
        _log.e('Failed to resolve queue item $index: $e');
        final hasExistingError = (state.error ?? '').trim().isNotEmpty;
        if (hasExistingError) {
          state = state.copyWith(
            isLoading: false,
            isPlaying: false,
            isBuffering: false,
          );
        } else {
          _setPlaybackError('Failed to play: $e', type: 'resolve_failed');
        }
      }
      return;
    }

    // Already have a URI
    if (item.sourceUri.isNotEmpty) {
      final uri = _uriFromPath(item.sourceUri);
      await _setSourceAndPlay(uri, item);
    }
  }

  Future<void> _setSourceAndPlay(Uri uri, PlaybackItem item) async {
    if (!FFmpegService.isActiveLiveDecryptedUrl(uri.toString())) {
      await FFmpegService.stopLiveDecryptedStream();
    }

    state = state.copyWith(
      currentItem: item,
      isLoading: true,
      isBuffering: true,
      isPlaying: false,
      position: Duration.zero,
      bufferedPosition: Duration.zero,
      duration: Duration.zero,
      clearError: true,
      clearLyrics: true,
    );

    _updateMediaItemNotification(item);

    // Fetch lyrics in background
    unawaited(_fetchLyricsForItem(item));

    try {
      await _player.setAudioSource(AudioSource.uri(uri));
      await _player.play();
    } catch (e) {
      if (FFmpegService.isActiveLiveDecryptedUrl(uri.toString())) {
        await FFmpegService.stopLiveDecryptedStream();
      }
      _log.e('Failed to play source: $e');
      _setPlaybackError(e.toString(), type: 'playback_failed');
      rethrow;
    }
  }

  // ─── Lyrics fetching + parsing ───────────────────────────────────────────

  /// A generation counter to discard stale lyrics results.
  int _lyricsGeneration = 0;

  Future<void> _fetchLyricsForItem(PlaybackItem item) async {
    final generation = ++_lyricsGeneration;
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
        state = state.copyWith(
          lyricsLoading: false,
          lyrics: const LyricsData(),
        );
        return;
      }

      if (instrumental) {
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
      _log.w('Lyrics fetch failed: $e');
      state = state.copyWith(lyricsLoading: false, lyrics: const LyricsData());
    }
  }

  /// Public method to manually refetch lyrics (e.g. retry button).
  Future<void> refetchLyrics() async {
    final item = state.currentItem;
    if (item == null) return;
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

  String _resolveStreamSource(Track track, ExtensionState extensionState) {
    final source = (track.source ?? '').trim();
    if (source.isEmpty) {
      return '';
    }

    final normalizedSource = source.toLowerCase();
    if (_isBuiltInStreamingService(normalizedSource)) {
      return normalizedSource;
    }

    for (final ext in extensionState.extensions) {
      if (ext.enabled && ext.hasDownloadProvider && ext.id == source) {
        return source;
      }
    }

    return '';
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

  String _resolveStreamQuality(String service, String defaultQuality) {
    final normalizedService = service.toLowerCase();
    if (normalizedService == 'youtube') {
      if (defaultQuality.toLowerCase().startsWith('mp3_') ||
          defaultQuality.toLowerCase().startsWith('opus_')) {
        return defaultQuality;
      }
      return 'mp3_320';
    }
    return defaultQuality;
  }

  ({String message, String type}) _buildStreamResolveFailure(
    Map<String, dynamic> result,
  ) {
    final errorTypeRaw = (result['error_type'] as String?)?.trim() ?? '';
    final errorType = errorTypeRaw.isEmpty ? 'resolve_failed' : errorTypeRaw;
    final rawMessage = (result['error'] as String?)?.trim() ?? '';
    final message = rawMessage.isEmpty
        ? 'Failed to resolve stream.'
        : rawMessage;
    return (message: message, type: errorType);
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

  void _disposeInternal() {
    unawaited(FFmpegService.stopLiveDecryptedStream());
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
  }
}

final playbackProvider = NotifierProvider<PlaybackController, PlaybackState>(
  PlaybackController.new,
);
