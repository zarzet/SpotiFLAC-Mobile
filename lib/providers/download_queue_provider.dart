import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/models/settings.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/services/app_state_database.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/services/download_request_payload.dart';
import 'package:spotiflac_android/services/ffmpeg_service.dart';
import 'package:spotiflac_android/services/notification_service.dart';
import 'package:spotiflac_android/services/history_database.dart';
import 'package:spotiflac_android/utils/logger.dart' hide log;
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/utils/string_utils.dart';
import 'package:spotiflac_android/utils/artist_utils.dart';

final _log = AppLogger('DownloadQueue');
final _historyLog = AppLogger('DownloadHistory');

final _invalidFolderChars = RegExp(r'[<>:"/\\|?*]');
final _trailingDotsRegex = RegExp(r'\.+$');

/// log10 helper using dart:math's natural log.
double _log10(num x) => log(x) / ln10;
final _yearRegex = RegExp(r'^(\d{4})');
const _defaultOutputFolderName = 'SpotiFLAC';
const _defaultAndroidMusicSubpath = 'Music/$_defaultOutputFolderName';

class DownloadHistoryItem {
  final String id;
  final String trackName;
  final String artistName;
  final String albumName;
  final String? albumArtist;
  final String? coverUrl;
  final String filePath;
  final String? storageMode;
  final String? downloadTreeUri;
  final String? safRelativeDir;
  final String? safFileName;
  final bool safRepaired;
  final String service;
  final DateTime downloadedAt;
  final String? isrc;
  final String? spotifyId;
  final int? trackNumber;
  final int? discNumber;
  final int? duration;
  final String? releaseDate;
  final String? quality;
  final int? bitDepth;
  final int? sampleRate;
  final String? genre;
  final String? label;
  final String? copyright;

  const DownloadHistoryItem({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.albumArtist,
    this.coverUrl,
    required this.filePath,
    this.storageMode,
    this.downloadTreeUri,
    this.safRelativeDir,
    this.safFileName,
    this.safRepaired = false,
    required this.service,
    required this.downloadedAt,
    this.isrc,
    this.spotifyId,
    this.trackNumber,
    this.discNumber,
    this.duration,
    this.releaseDate,
    this.quality,
    this.bitDepth,
    this.sampleRate,
    this.genre,
    this.label,
    this.copyright,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'trackName': trackName,
    'artistName': artistName,
    'albumName': albumName,
    'albumArtist': albumArtist,
    'coverUrl': coverUrl,
    'filePath': filePath,
    'storageMode': storageMode,
    'downloadTreeUri': downloadTreeUri,
    'safRelativeDir': safRelativeDir,
    'safFileName': safFileName,
    'safRepaired': safRepaired,
    'service': service,
    'downloadedAt': downloadedAt.toIso8601String(),
    'isrc': isrc,
    'spotifyId': spotifyId,
    'trackNumber': trackNumber,
    'discNumber': discNumber,
    'duration': duration,
    'releaseDate': releaseDate,
    'quality': quality,
    'bitDepth': bitDepth,
    'sampleRate': sampleRate,
    'genre': genre,
    'label': label,
    'copyright': copyright,
  };

  factory DownloadHistoryItem.fromJson(Map<String, dynamic> json) =>
      DownloadHistoryItem(
        id: json['id'] as String,
        trackName: json['trackName'] as String,
        artistName: json['artistName'] as String,
        albumName: json['albumName'] as String,
        albumArtist: normalizeOptionalString(json['albumArtist'] as String?),
        coverUrl: normalizeCoverReference(json['coverUrl']?.toString()),
        filePath: json['filePath'] as String,
        storageMode: json['storageMode'] as String?,
        downloadTreeUri: json['downloadTreeUri'] as String?,
        safRelativeDir: json['safRelativeDir'] as String?,
        safFileName: json['safFileName'] as String?,
        safRepaired: json['safRepaired'] == true,
        service: json['service'] as String,
        downloadedAt: DateTime.parse(json['downloadedAt'] as String),
        isrc: json['isrc'] as String?,
        spotifyId: json['spotifyId'] as String?,
        trackNumber: json['trackNumber'] as int?,
        discNumber: json['discNumber'] as int?,
        duration: json['duration'] as int?,
        releaseDate: json['releaseDate'] as String?,
        quality: json['quality'] as String?,
        bitDepth: json['bitDepth'] as int?,
        sampleRate: json['sampleRate'] as int?,
        genre: json['genre'] as String?,
        label: json['label'] as String?,
        copyright: json['copyright'] as String?,
      );

  DownloadHistoryItem copyWith({
    String? trackName,
    String? artistName,
    String? albumName,
    String? albumArtist,
    String? coverUrl,
    String? filePath,
    String? storageMode,
    String? downloadTreeUri,
    String? safRelativeDir,
    String? safFileName,
    bool? safRepaired,
    String? isrc,
    String? spotifyId,
    int? trackNumber,
    int? discNumber,
    int? duration,
    String? releaseDate,
    String? quality,
    int? bitDepth,
    int? sampleRate,
    String? genre,
    String? label,
    String? copyright,
  }) {
    return DownloadHistoryItem(
      id: id,
      trackName: trackName ?? this.trackName,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      albumArtist: albumArtist ?? this.albumArtist,
      coverUrl: normalizeCoverReference(coverUrl ?? this.coverUrl),
      filePath: filePath ?? this.filePath,
      storageMode: storageMode ?? this.storageMode,
      downloadTreeUri: downloadTreeUri ?? this.downloadTreeUri,
      safRelativeDir: safRelativeDir ?? this.safRelativeDir,
      safFileName: safFileName ?? this.safFileName,
      safRepaired: safRepaired ?? this.safRepaired,
      service: service,
      downloadedAt: downloadedAt,
      isrc: isrc ?? this.isrc,
      spotifyId: spotifyId ?? this.spotifyId,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      duration: duration ?? this.duration,
      releaseDate: releaseDate ?? this.releaseDate,
      quality: quality ?? this.quality,
      bitDepth: bitDepth ?? this.bitDepth,
      sampleRate: sampleRate ?? this.sampleRate,
      genre: genre ?? this.genre,
      label: label ?? this.label,
      copyright: copyright ?? this.copyright,
    );
  }
}

class DownloadHistoryState {
  final List<DownloadHistoryItem> items;
  final Map<String, DownloadHistoryItem> _bySpotifyId;
  final Map<String, DownloadHistoryItem> _byIsrc;
  final Map<String, DownloadHistoryItem> _byTrackArtistKey;

  DownloadHistoryState({this.items = const []})
    : _bySpotifyId = Map.fromEntries(
        items
            .where(
              (item) => item.spotifyId != null && item.spotifyId!.isNotEmpty,
            )
            .map((item) => MapEntry(item.spotifyId!, item)),
      ),
      _byIsrc = Map.fromEntries(
        items
            .where((item) => item.isrc != null && item.isrc!.isNotEmpty)
            .map((item) => MapEntry(item.isrc!, item)),
      ),
      _byTrackArtistKey = Map.fromEntries(
        items
            .map(
              (item) => MapEntry(
                _trackArtistKey(item.trackName, item.artistName),
                item,
              ),
            )
            .where((entry) => entry.key.isNotEmpty),
      );

  static String _trackArtistKey(String trackName, String artistName) {
    final normalizedTrack = trackName.trim().toLowerCase();
    if (normalizedTrack.isEmpty) return '';
    final normalizedArtist = artistName.trim().toLowerCase();
    return '$normalizedTrack|$normalizedArtist';
  }

  bool isDownloaded(String spotifyId) => _bySpotifyId.containsKey(spotifyId);

  DownloadHistoryItem? getBySpotifyId(String spotifyId) =>
      _bySpotifyId[spotifyId];

  DownloadHistoryItem? getByIsrc(String isrc) => _byIsrc[isrc];

  DownloadHistoryItem? findByTrackAndArtist(
    String trackName,
    String artistName,
  ) {
    final key = _trackArtistKey(trackName, artistName);
    if (key.isEmpty) return null;
    return _byTrackArtistKey[key];
  }

  DownloadHistoryState copyWith({List<DownloadHistoryItem>? items}) {
    return DownloadHistoryState(items: items ?? this.items);
  }
}

class DownloadHistoryNotifier extends Notifier<DownloadHistoryState> {
  static const int _safRepairBatchSize = 20;
  static const int _safRepairMaxPerLaunch = 60;
  static const int _orphanCleanupMaxPerLaunch = 80;
  static const int _audioMetadataBackfillMaxPerLaunch = 24;
  static const _startupMaintenanceDelay = Duration(seconds: 4);
  static const _startupMaintenanceStepGap = Duration(milliseconds: 250);
  static const _startupSafRepairCursorKey =
      'history_startup_saf_repair_cursor_v1';
  static const _startupOrphanCursorKey = 'history_startup_orphan_cursor_v1';
  static const _startupAudioCursorKey = 'history_startup_audio_cursor_v1';
  final HistoryDatabase _db = HistoryDatabase.instance;
  bool _isLoaded = false;
  bool _isSafRepairInProgress = false;
  bool _isAudioMetadataBackfillInProgress = false;
  bool _startupMaintenanceScheduled = false;

  @override
  DownloadHistoryState build() {
    _loadFromDatabaseSync();
    return DownloadHistoryState();
  }

  void _loadFromDatabaseSync() {
    if (_isLoaded) return;
    _isLoaded = true;
    Future.microtask(() async {
      await _loadFromDatabase();
    });
  }

  Future<void> _loadFromDatabase() async {
    try {
      final migrated = await _db.migrateFromSharedPreferences();
      if (migrated) {
        _historyLog.i('Migrated history from SharedPreferences to SQLite');
      }

      if (Platform.isIOS) {
        final pathsMigrated = await _db.migrateIosContainerPaths();
        if (pathsMigrated) {
          _historyLog.i('Migrated iOS container paths after app update');
        }
      }

      final jsonList = await _db.getAll();
      final items = jsonList
          .map((e) => DownloadHistoryItem.fromJson(e))
          .toList();

      state = state.copyWith(items: items);
      _historyLog.i('Loaded ${items.length} items from SQLite database');
      _scheduleStartupMaintenance(items);
    } catch (e, stack) {
      _historyLog.e('Failed to load history from database: $e', e, stack);
    }
  }

  void _scheduleStartupMaintenance(List<DownloadHistoryItem> initialItems) {
    if (_startupMaintenanceScheduled) {
      return;
    }
    _startupMaintenanceScheduled = true;

    unawaited(
      Future<void>.delayed(_startupMaintenanceDelay, () async {
        try {
          final prefs = await SharedPreferences.getInstance();

          if (Platform.isAndroid) {
            await _repairMissingSafEntries(
              initialItems,
              maxItems: _safRepairMaxPerLaunch,
              prefs: prefs,
            );
            await Future<void>.delayed(_startupMaintenanceStepGap);
          }

          await _cleanupOrphanedDownloadsIncremental(
            maxItems: _orphanCleanupMaxPerLaunch,
            prefs: prefs,
          );
          await Future<void>.delayed(_startupMaintenanceStepGap);

          final currentItems = state.items;
          if (currentItems.isNotEmpty) {
            await _backfillAudioMetadata(
              currentItems,
              maxItems: _audioMetadataBackfillMaxPerLaunch,
              prefs: prefs,
            );
          }
        } catch (e, stack) {
          _historyLog.w('Startup history maintenance failed: $e');
          _historyLog.d('$stack');
        }
      }),
    );
  }

  int _readStartupCursor(SharedPreferences prefs, String key, int totalCount) {
    if (totalCount <= 0) {
      return 0;
    }
    final cursor = prefs.getInt(key) ?? 0;
    if (cursor < 0 || cursor >= totalCount) {
      return 0;
    }
    return cursor;
  }

  Future<void> _writeStartupCursor(
    SharedPreferences prefs,
    String key,
    int nextCursor,
    int totalCount,
  ) async {
    if (totalCount <= 0 || nextCursor <= 0 || nextCursor >= totalCount) {
      await prefs.remove(key);
      return;
    }
    await prefs.setInt(key, nextCursor);
  }

  String _fileNameFromUri(String uri) {
    try {
      final parsed = Uri.parse(uri);
      if (parsed.pathSegments.isNotEmpty) {
        return Uri.decodeComponent(parsed.pathSegments.last);
      }
    } catch (_) {}
    return '';
  }

  Future<void> _repairMissingSafEntries(
    List<DownloadHistoryItem> items, {
    required int maxItems,
    required SharedPreferences prefs,
  }) async {
    if (_isSafRepairInProgress || items.isEmpty) {
      return;
    }
    _isSafRepairInProgress = true;

    final candidateIndexes = <int>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.storageMode != 'saf') continue;
      if (item.safRepaired) continue;
      if (item.downloadTreeUri == null || item.downloadTreeUri!.isEmpty) {
        continue;
      }
      final hasFilePath = item.filePath.trim().isNotEmpty;
      final hasSafFileName =
          item.safFileName != null && item.safFileName!.trim().isNotEmpty;
      if (!hasFilePath && !hasSafFileName) {
        continue;
      }
      candidateIndexes.add(i);
    }

    if (candidateIndexes.isEmpty) {
      await prefs.remove(_startupSafRepairCursorKey);
      _isSafRepairInProgress = false;
      return;
    }

    final startCursor = _readStartupCursor(
      prefs,
      _startupSafRepairCursorKey,
      candidateIndexes.length,
    );
    final endCursor = (startCursor + maxItems).clamp(
      0,
      candidateIndexes.length,
    );
    final selectedIndexes = candidateIndexes.sublist(startCursor, endCursor);

    if (selectedIndexes.isEmpty) {
      await prefs.remove(_startupSafRepairCursorKey);
      _isSafRepairInProgress = false;
      return;
    }

    final updatedItems = [...items];
    final persistedUpdates = <Map<String, dynamic>>[];
    var changed = false;
    var repairedCount = 0;
    var verifiedCount = 0;

    try {
      for (var c = 0; c < selectedIndexes.length; c++) {
        final i = selectedIndexes[c];
        final item = items[i];
        final rawPath = item.filePath.trim();
        final isDirectSafUri = rawPath.isNotEmpty && isContentUri(rawPath);

        if (isDirectSafUri) {
          final exists = await fileExists(rawPath);
          if (exists) {
            final verified = item.copyWith(
              safRepaired: true,
              safFileName: item.safFileName ?? _fileNameFromUri(rawPath),
            );
            updatedItems[i] = verified;
            changed = true;
            verifiedCount++;
            persistedUpdates.add(verified.toJson());
            continue;
          }
        }

        var fallbackName = (item.safFileName ?? '').trim();
        if (fallbackName.isEmpty && isDirectSafUri) {
          fallbackName = _fileNameFromUri(rawPath);
        }
        if (fallbackName.isEmpty) {
          _historyLog.w('Missing SAF filename for history item: ${item.id}');
          continue;
        }

        try {
          final resolved = await PlatformBridge.resolveSafFile(
            treeUri: item.downloadTreeUri!,
            relativeDir: item.safRelativeDir ?? '',
            fileName: fallbackName,
          );
          final newUri = (resolved['uri'] as String? ?? '').trim();
          if (newUri.isEmpty) continue;

          final newRelativeDir = resolved['relative_dir'] as String?;
          final updated = item.copyWith(
            filePath: newUri,
            safRelativeDir:
                (newRelativeDir != null && newRelativeDir.isNotEmpty)
                ? newRelativeDir
                : item.safRelativeDir,
            safFileName: fallbackName,
            safRepaired: true,
          );

          updatedItems[i] = updated;
          changed = true;
          repairedCount++;
          persistedUpdates.add(updated.toJson());
        } catch (e) {
          _historyLog.w('Failed to repair SAF URI: $e');
        }

        if ((c + 1) % _safRepairBatchSize == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
      }

      if (changed) {
        await _db.upsertBatch(persistedUpdates);
        state = state.copyWith(items: updatedItems);
        _historyLog.i(
          'SAF repair pass: verified=$verifiedCount, repaired=$repairedCount, checked=${selectedIndexes.length}',
        );
      }
      await _writeStartupCursor(
        prefs,
        _startupSafRepairCursorKey,
        endCursor,
        candidateIndexes.length,
      );
    } finally {
      _isSafRepairInProgress = false;
    }
  }

  int? _readPositiveInt(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final asInt = value.toInt();
      return asInt > 0 ? asInt : null;
    }
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  bool _supportsAudioMetadataProbe(String filePath) {
    final trimmed = filePath.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('content://')) return true;
    return trimmed.endsWith('.flac') ||
        trimmed.endsWith('.m4a') ||
        trimmed.endsWith('.aac') ||
        trimmed.endsWith('.mp3') ||
        trimmed.endsWith('.opus') ||
        trimmed.endsWith('.ogg');
  }

  bool _shouldBackfillAudioMetadata(DownloadHistoryItem item) {
    if (!_supportsAudioMetadataProbe(item.filePath)) {
      return false;
    }

    final trimmedPath = item.filePath.trim().toLowerCase();
    final hasResolvedSpecs =
        item.bitDepth != null &&
        item.bitDepth! > 0 &&
        item.sampleRate != null &&
        item.sampleRate! > 0;
    final needsLosslessSpecProbe =
        !hasResolvedSpecs &&
        (trimmedPath.endsWith('.flac') ||
            trimmedPath.endsWith('.m4a') ||
            trimmedPath.endsWith('.aac') ||
            trimmedPath.startsWith('content://'));

    if (hasResolvedSpecs && !isPlaceholderQualityLabel(item.quality)) {
      return false;
    }

    return needsLosslessSpecProbe ||
        isPlaceholderQualityLabel(item.quality) ||
        normalizeOptionalString(item.quality) == null;
  }

  Future<Map<String, dynamic>?> _probeAudioMetadata(
    String filePath, {
    String? fallbackQuality,
  }) async {
    if (!_supportsAudioMetadataProbe(filePath)) {
      return null;
    }

    try {
      final result = await PlatformBridge.readFileMetadata(filePath);
      if (result['error'] != null) {
        return null;
      }

      final bitDepth = _readPositiveInt(result['bit_depth']);
      final sampleRate = _readPositiveInt(result['sample_rate']);
      final quality = buildDisplayAudioQuality(
        bitDepth: bitDepth,
        sampleRate: sampleRate,
        storedQuality: fallbackQuality,
      );

      if (quality == null && bitDepth == null && sampleRate == null) {
        return null;
      }

      return {
        'quality': quality,
        'bitDepth': bitDepth,
        'sampleRate': sampleRate,
      };
    } catch (e) {
      _historyLog.d('Audio metadata probe failed for $filePath: $e');
      return null;
    }
  }

  Future<void> _backfillAudioMetadata(
    List<DownloadHistoryItem> items, {
    required int maxItems,
    required SharedPreferences prefs,
  }) async {
    if (_isAudioMetadataBackfillInProgress || items.isEmpty) {
      return;
    }
    _isAudioMetadataBackfillInProgress = true;

    try {
      final candidateIndexes = <int>[];
      for (var i = 0; i < items.length; i++) {
        if (_shouldBackfillAudioMetadata(items[i])) {
          candidateIndexes.add(i);
        }
      }

      if (candidateIndexes.isEmpty) {
        await prefs.remove(_startupAudioCursorKey);
        return;
      }

      final startCursor = _readStartupCursor(
        prefs,
        _startupAudioCursorKey,
        candidateIndexes.length,
      );
      final endCursor = (startCursor + maxItems).clamp(
        0,
        candidateIndexes.length,
      );
      final selectedIndexes = candidateIndexes.sublist(startCursor, endCursor);

      if (selectedIndexes.isEmpty) {
        await prefs.remove(_startupAudioCursorKey);
        return;
      }

      List<DownloadHistoryItem>? updatedItems;
      final persistedUpdates = <Map<String, dynamic>>[];
      var refreshedCount = 0;

      for (final index in selectedIndexes) {
        final item = items[index];

        final probed = await _probeAudioMetadata(
          item.filePath,
          fallbackQuality: item.quality,
        );
        if (probed == null) {
          continue;
        }

        final resolvedQuality = normalizeOptionalString(
          probed['quality'] as String?,
        );
        final resolvedBitDepth = probed['bitDepth'] as int?;
        final resolvedSampleRate = probed['sampleRate'] as int?;

        final qualityChanged =
            resolvedQuality != null && resolvedQuality != item.quality;
        final bitDepthChanged =
            resolvedBitDepth != null && resolvedBitDepth != item.bitDepth;
        final sampleRateChanged =
            resolvedSampleRate != null && resolvedSampleRate != item.sampleRate;

        if (!qualityChanged && !bitDepthChanged && !sampleRateChanged) {
          continue;
        }

        final updated = item.copyWith(
          quality: resolvedQuality,
          bitDepth: resolvedBitDepth,
          sampleRate: resolvedSampleRate,
        );
        updatedItems ??= [...items];
        updatedItems[index] = updated;
        persistedUpdates.add(updated.toJson());
        refreshedCount++;
      }

      if (persistedUpdates.isNotEmpty && updatedItems != null) {
        await _db.upsertBatch(persistedUpdates);
        state = state.copyWith(items: updatedItems);
      }

      await _writeStartupCursor(
        prefs,
        _startupAudioCursorKey,
        endCursor,
        candidateIndexes.length,
      );

      if (refreshedCount > 0) {
        _historyLog.i(
          'Audio metadata backfill refreshed $refreshedCount items',
        );
      }
    } finally {
      _isAudioMetadataBackfillInProgress = false;
    }
  }

  Future<void> reloadFromStorage() async {
    await _loadFromDatabase();
  }

  void addToHistory(DownloadHistoryItem item) {
    DownloadHistoryItem? existing;
    if (item.spotifyId != null && item.spotifyId!.isNotEmpty) {
      existing = state.getBySpotifyId(item.spotifyId!);
    }
    if (existing == null && item.isrc != null && item.isrc!.isNotEmpty) {
      existing = state.getByIsrc(item.isrc!);
    }

    final mergedItem = existing == null
        ? item
        : item.copyWith(
            genre:
                normalizeOptionalString(item.genre) ??
                normalizeOptionalString(existing.genre),
            label:
                normalizeOptionalString(item.label) ??
                normalizeOptionalString(existing.label),
            copyright:
                normalizeOptionalString(item.copyright) ??
                normalizeOptionalString(existing.copyright),
          );

    if (existing != null) {
      final updatedItems = state.items
          .where((i) => i.id != existing!.id)
          .toList();
      updatedItems.insert(0, mergedItem);
      state = state.copyWith(items: updatedItems);
      _historyLog.d('Updated existing history entry: ${mergedItem.trackName}');
    } else {
      state = state.copyWith(items: [mergedItem, ...state.items]);
      _historyLog.d('Added new history entry: ${mergedItem.trackName}');
    }

    _db.upsert(mergedItem.toJson()).catchError((Object e) {
      _historyLog.e('Failed to save to database: $e');
    });
  }

  void removeFromHistory(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
    _db.deleteById(id).catchError((Object e) {
      _historyLog.e('Failed to delete from database: $e');
    });
  }

  void removeBySpotifyId(String spotifyId) {
    state = state.copyWith(
      items: state.items.where((item) => item.spotifyId != spotifyId).toList(),
    );
    _db.deleteBySpotifyId(spotifyId).catchError((Object e) {
      _historyLog.e('Failed to delete from database: $e');
    });
    _historyLog.d('Removed item with spotifyId: $spotifyId');
  }

  DownloadHistoryItem? getBySpotifyId(String spotifyId) {
    return state.getBySpotifyId(spotifyId);
  }

  DownloadHistoryItem? getByIsrc(String isrc) {
    return state.getByIsrc(isrc);
  }

  Future<DownloadHistoryItem?> getBySpotifyIdAsync(String spotifyId) async {
    final inMemory = state.getBySpotifyId(spotifyId);
    if (inMemory != null) return inMemory;

    final json = await _db.getBySpotifyId(spotifyId);
    if (json == null) return null;
    return DownloadHistoryItem.fromJson(json);
  }

  Future<void> updateAudioMetadataForItem({
    required String id,
    String? quality,
    int? bitDepth,
    int? sampleRate,
  }) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final current = state.items[index];
    final updated = current.copyWith(
      quality: quality,
      bitDepth: bitDepth,
      sampleRate: sampleRate,
    );

    if (updated.quality == current.quality &&
        updated.bitDepth == current.bitDepth &&
        updated.sampleRate == current.sampleRate) {
      return;
    }

    final updatedItems = [...state.items];
    updatedItems[index] = updated;
    state = state.copyWith(items: updatedItems);
    await _db.updateAudioMetadata(
      id,
      newQuality: quality,
      newBitDepth: bitDepth,
      newSampleRate: sampleRate,
    );
  }

  Future<void> updateMetadataForItem({
    required String id,
    required String trackName,
    required String artistName,
    required String albumName,
    String? albumArtist,
    String? isrc,
    int? trackNumber,
    int? discNumber,
    String? releaseDate,
    String? genre,
    String? label,
    String? copyright,
  }) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final current = state.items[index];
    final updated = current.copyWith(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      albumArtist: albumArtist,
      isrc: isrc,
      trackNumber: trackNumber,
      discNumber: discNumber,
      releaseDate: releaseDate,
      genre: genre,
      label: label,
      copyright: copyright,
    );

    final updatedItems = [...state.items];
    updatedItems[index] = updated;
    state = state.copyWith(items: updatedItems);
    await _db.upsert(updated.toJson());
  }

  static const _audioExtensions = [
    '.flac',
    '.m4a',
    '.mp3',
    '.opus',
    '.ogg',
    '.wav',
    '.aac',
  ];

  Future<String?> _findConvertedSibling(String originalPath) async {
    final dotIndex = originalPath.lastIndexOf('.');
    if (dotIndex < 0) return null;
    final basePath = originalPath.substring(0, dotIndex);
    final originalExt = originalPath.substring(dotIndex).toLowerCase();

    for (final ext in _audioExtensions) {
      if (ext == originalExt) continue;
      final candidatePath = '$basePath$ext';
      try {
        if (await fileExists(candidatePath)) return candidatePath;
      } catch (_) {}
    }
    return null;
  }

  Future<
    ({
      List<String> orphanedIds,
      Map<String, String> replacementPaths,
      Map<String, String> pathById,
    })
  >
  _inspectOrphanedEntries(List<Map<String, dynamic>> entries) async {
    final orphanedIds = <String>[];
    final replacementPaths = <String, String>{};
    final pathById = <String, String>{};
    const checkChunkSize = 16;

    for (var i = 0; i < entries.length; i += checkChunkSize) {
      final end = (i + checkChunkSize < entries.length)
          ? i + checkChunkSize
          : entries.length;
      final chunk = entries.sublist(i, end);

      final checks = await Future.wait<MapEntry<String, bool>?>(
        chunk.map((entry) async {
          final id = entry['id'] as String;
          final filePath = entry['file_path'] as String?;
          if (filePath == null || filePath.isEmpty) return null;
          pathById[id] = filePath;
          try {
            if (await fileExists(filePath)) return MapEntry(id, true);

            final sibling = await _findConvertedSibling(filePath);
            if (sibling != null) {
              _historyLog.i(
                'Found converted sibling for $id: $filePath -> $sibling',
              );
              replacementPaths[id] = sibling;
              pathById[id] = sibling;
              return MapEntry(id, true);
            }

            return MapEntry(id, false);
          } catch (e) {
            _historyLog.w('Error checking file existence for $id: $e');
            return MapEntry(id, false);
          }
        }),
      );

      for (final check in checks) {
        if (check == null || check.value) continue;
        orphanedIds.add(check.key);
        _historyLog.d(
          'Found orphaned entry: ${check.key} (${pathById[check.key] ?? ''})',
        );
      }
    }

    return (
      orphanedIds: orphanedIds,
      replacementPaths: replacementPaths,
      pathById: pathById,
    );
  }

  void _applyHistoryPathAndDeletionChanges({
    required List<String> deletedIds,
    required Map<String, String> replacementPaths,
  }) {
    if (deletedIds.isEmpty && replacementPaths.isEmpty) {
      return;
    }
    final deletedSet = deletedIds.toSet();
    final updatedItems = <DownloadHistoryItem>[];
    for (final item in state.items) {
      if (deletedSet.contains(item.id)) {
        continue;
      }
      final replacementPath = replacementPaths[item.id];
      if (replacementPath != null && replacementPath != item.filePath) {
        updatedItems.add(item.copyWith(filePath: replacementPath));
      } else {
        updatedItems.add(item);
      }
    }
    state = state.copyWith(items: updatedItems);
  }

  Future<int> _cleanupOrphanedDownloadsIncremental({
    required int maxItems,
    required SharedPreferences prefs,
  }) async {
    final cursor = prefs.getInt(_startupOrphanCursorKey) ?? 0;
    final safeCursor = cursor < 0 ? 0 : cursor;
    final entries = await _db.getEntriesWithPathsPage(
      limit: maxItems,
      offset: safeCursor,
    );
    if (entries.isEmpty) {
      await prefs.remove(_startupOrphanCursorKey);
      return 0;
    }

    final result = await _inspectOrphanedEntries(entries);
    for (final replacement in result.replacementPaths.entries) {
      await _db.updateFilePath(replacement.key, replacement.value);
    }

    final deletedCount = result.orphanedIds.isEmpty
        ? 0
        : await _db.deleteByIds(result.orphanedIds);

    _applyHistoryPathAndDeletionChanges(
      deletedIds: result.orphanedIds,
      replacementPaths: result.replacementPaths,
    );

    if (entries.length < maxItems) {
      await prefs.remove(_startupOrphanCursorKey);
    } else {
      final nextCursor =
          safeCursor + entries.length - result.orphanedIds.length;
      await prefs.setInt(_startupOrphanCursorKey, nextCursor);
    }

    if (deletedCount > 0 || result.replacementPaths.isNotEmpty) {
      _historyLog.i(
        'Startup orphan cleanup pass: removed=$deletedCount, repaired=${result.replacementPaths.length}, checked=${entries.length}',
      );
    }
    return deletedCount;
  }

  Future<int> cleanupOrphanedDownloads() async {
    _historyLog.i('Starting orphaned downloads cleanup...');
    final orphanedIds = <String>[];
    final replacementPaths = <String, String>{};
    const pageSize = 256;
    var offset = 0;

    while (true) {
      final entries = await _db.getEntriesWithPathsPage(
        limit: pageSize,
        offset: offset,
      );
      if (entries.isEmpty) {
        break;
      }

      final result = await _inspectOrphanedEntries(entries);
      orphanedIds.addAll(result.orphanedIds);
      replacementPaths.addAll(result.replacementPaths);

      if (entries.length < pageSize) {
        break;
      }
      offset += entries.length - result.orphanedIds.length;
    }

    for (final replacement in replacementPaths.entries) {
      await _db.updateFilePath(replacement.key, replacement.value);
    }

    if (orphanedIds.isEmpty && replacementPaths.isEmpty) {
      _historyLog.i('No orphaned entries found');
      return 0;
    }

    final deletedCount = orphanedIds.isEmpty
        ? 0
        : await _db.deleteByIds(orphanedIds);
    _applyHistoryPathAndDeletionChanges(
      deletedIds: orphanedIds,
      replacementPaths: replacementPaths,
    );

    _historyLog.i(
      'Cleaned up $deletedCount orphaned entries and repaired ${replacementPaths.length} paths',
    );
    return deletedCount;
  }

  void clearHistory() {
    state = DownloadHistoryState();
    _db.clearAll().catchError((Object e) {
      _historyLog.e('Failed to clear database: $e');
    });
  }

  Future<int> getDatabaseCount() async {
    return await _db.getCount();
  }
}

final downloadHistoryProvider =
    NotifierProvider<DownloadHistoryNotifier, DownloadHistoryState>(
      DownloadHistoryNotifier.new,
    );

class DownloadQueueState {
  static const Object _noChange = Object();
  final List<DownloadItem> items;
  final DownloadItem? currentDownload;
  final bool isProcessing;
  final bool isPaused;
  final String outputDir;
  final String filenameFormat;
  final String singleFilenameFormat;
  final String audioQuality;
  final bool autoFallback;
  final int concurrentDownloads;

  const DownloadQueueState({
    this.items = const [],
    this.currentDownload,
    this.isProcessing = false,
    this.isPaused = false,
    this.outputDir = '',
    this.filenameFormat = '{artist} - {title}',
    this.singleFilenameFormat = '{title} - {artist}',
    this.audioQuality = 'LOSSLESS',
    this.autoFallback = true,
    this.concurrentDownloads = 1,
  });

  DownloadQueueState copyWith({
    List<DownloadItem>? items,
    Object? currentDownload = _noChange,
    bool? isProcessing,
    bool? isPaused,
    String? outputDir,
    String? filenameFormat,
    String? singleFilenameFormat,
    String? audioQuality,
    bool? autoFallback,
    int? concurrentDownloads,
  }) {
    return DownloadQueueState(
      items: items ?? this.items,
      currentDownload: identical(currentDownload, _noChange)
          ? this.currentDownload
          : currentDownload as DownloadItem?,
      isProcessing: isProcessing ?? this.isProcessing,
      isPaused: isPaused ?? this.isPaused,
      outputDir: outputDir ?? this.outputDir,
      filenameFormat: filenameFormat ?? this.filenameFormat,
      singleFilenameFormat: singleFilenameFormat ?? this.singleFilenameFormat,
      audioQuality: audioQuality ?? this.audioQuality,
      autoFallback: autoFallback ?? this.autoFallback,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
    );
  }

  int get queuedCount => items
      .where(
        (i) =>
            i.status == DownloadStatus.queued ||
            i.status == DownloadStatus.downloading,
      )
      .length;
  int get completedCount =>
      items.where((i) => i.status == DownloadStatus.completed).length;
  int get failedCount =>
      items.where((i) => i.status == DownloadStatus.failed).length;
  int get activeDownloadsCount =>
      items.where((i) => i.status == DownloadStatus.downloading).length;
}

class _ProgressUpdate {
  final DownloadStatus status;
  final double progress;
  final double? speedMBps;
  final int? bytesReceived;
  final int? bytesTotal;

  const _ProgressUpdate({
    required this.status,
    required this.progress,
    this.speedMBps,
    this.bytesReceived,
    this.bytesTotal,
  });
}

class DownloadQueueNotifier extends Notifier<DownloadQueueState> {
  Timer? _progressTimer;
  Timer? _progressStreamBootstrapTimer;
  Timer? _queuePersistDebounce;
  StreamSubscription<Map<String, dynamic>>? _progressStreamSub;
  int _downloadCount = 0;
  static const _cleanupInterval = 50;
  static const _progressPollingInterval = Duration(milliseconds: 1200);
  static const _idleProgressPollEveryTicks = 3;
  static const _queueSchedulingInterval = Duration(milliseconds: 250);
  static const _queuePersistDebounceDuration = Duration(milliseconds: 350);
  static const _bytesUiStep = 104857; // ~0.1 MiB, matches one-decimal MB UI.
  static const _serviceProgressStepPercent = 2;
  final NotificationService _notificationService = NotificationService();
  final AppStateDatabase _appStateDb = AppStateDatabase.instance;
  int _totalQueuedAtStart = 0;
  int _completedInSession = 0;
  int _failedInSession = 0;
  int _queueItemSequence = 0;
  bool _isLoaded = false;
  final Set<String> _ensuredDirs = {};
  int _progressPollingErrorCount = 0;
  bool _isProgressPollingInFlight = false;
  int _idleProgressPollTick = 0;
  bool _hasReceivedProgressStreamEvent = false;
  bool _usingProgressStream = false;
  String? _lastServiceTrackName;
  String? _lastServiceArtistName;
  int _lastServicePercent = -1;
  int _lastServiceQueueCount = -1;
  DateTime _lastServiceUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastFinalizingTrackName;
  String? _lastFinalizingArtistName;
  String? _lastNotifTrackName;
  String? _lastNotifArtistName;
  int _lastNotifPercent = -1;
  int _lastNotifQueueCount = -1;
  final Set<String> _locallyCancelledItemIds = {};
  final Set<String> _pausePendingItemIds = {};

  // Album ReplayGain accumulator: keyed by album identifier.
  // Stores per-track loudness data until all album tracks are done,
  // then computes and writes album gain/peak to every track in the album.
  final Map<String, _AlbumRgAccumulator> _albumRgData = {};

  double _normalizeProgressForUi(double value) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    if (clamped <= 0) return 0;
    if (clamped >= 1) return 1;
    final rounded = double.parse(clamped.toStringAsFixed(2));
    return rounded == 0 ? 0.01 : rounded;
  }

  double _normalizeSpeedForUi(double value) {
    if (value <= 0) return 0;
    return double.parse(value.toStringAsFixed(1));
  }

  int _normalizeBytesForUi(int value) {
    if (value <= 0) return 0;
    return (value ~/ _bytesUiStep) * _bytesUiStep;
  }

  bool _shouldUpdateProgressNotification({
    required String trackName,
    required String artistName,
    required int progress,
    required int total,
    required int queueCount,
  }) {
    final safeTotal = total > 0 ? total : 1;
    final percent = ((progress * 100) / safeTotal).round().clamp(0, 100);
    final changed =
        trackName != _lastNotifTrackName ||
        artistName != _lastNotifArtistName ||
        percent != _lastNotifPercent ||
        queueCount != _lastNotifQueueCount;
    if (!changed) {
      return false;
    }

    _lastNotifTrackName = trackName;
    _lastNotifArtistName = artistName;
    _lastNotifPercent = percent;
    _lastNotifQueueCount = queueCount;
    return true;
  }

  @override
  DownloadQueueState build() {
    ref.listen<AppSettings>(settingsProvider, (previous, next) {
      final previousConcurrent =
          previous?.concurrentDownloads ?? state.concurrentDownloads;
      updateSettings(next);
      if (previousConcurrent != next.concurrentDownloads) {
        _log.i(
          'Concurrent downloads updated: $previousConcurrent -> ${next.concurrentDownloads}',
        );
      }
    });

    ref.onDispose(() {
      _progressTimer?.cancel();
      _progressStreamBootstrapTimer?.cancel();
      _progressStreamSub?.cancel();
      _progressTimer = null;
      _progressStreamBootstrapTimer = null;
      _progressStreamSub = null;
      if (_queuePersistDebounce?.isActive == true) {
        _queuePersistDebounce?.cancel();
        unawaited(_flushQueueToStorage());
      } else {
        _queuePersistDebounce?.cancel();
      }
      _queuePersistDebounce = null;
    });

    Future.microtask(() async {
      updateSettings(ref.read(settingsProvider));
      await _initOutputDir();
      await _loadQueueFromStorage();
    });
    return const DownloadQueueState();
  }

  Future<void> _loadQueueFromStorage() async {
    if (_isLoaded) return;
    _isLoaded = true;

    try {
      await _appStateDb.migrateQueueFromSharedPreferences();
      final rows = await _appStateDb.getPendingDownloadQueueRows();
      if (rows.isEmpty) {
        _log.d('No queue found in storage');
        return;
      }

      final pendingItems = <DownloadItem>[];
      for (final row in rows) {
        final itemJson = row['item_json'] as String?;
        if (itemJson == null || itemJson.isEmpty) continue;

        try {
          final decoded = jsonDecode(itemJson);
          if (decoded is! Map) continue;
          var item = DownloadItem.fromJson(Map<String, dynamic>.from(decoded));
          if (item.status == DownloadStatus.downloading) {
            item = item.copyWith(status: DownloadStatus.queued, progress: 0);
          }
          if (item.status == DownloadStatus.queued) {
            pendingItems.add(item);
          }
        } catch (_) {
          continue;
        }
      }

      if (pendingItems.isEmpty) {
        _log.d('No pending items to restore');
        await _appStateDb.replacePendingDownloadQueueRows(const []);
        return;
      }

      final normalizedPendingItems = _normalizeRestoredQueueIds(pendingItems);
      state = state.copyWith(items: normalizedPendingItems);
      _log.i(
        'Restored ${normalizedPendingItems.length} pending items from storage',
      );
      Future.microtask(() => _processQueue());
    } catch (e) {
      _log.e('Failed to load queue from storage: $e');
    }
  }

  void _saveQueueToStorage() {
    _queuePersistDebounce?.cancel();
    _queuePersistDebounce = Timer(_queuePersistDebounceDuration, () {
      _flushQueueToStorage();
    });
  }

  Future<void> _flushQueueToStorage() async {
    try {
      final pendingItems = state.items
          .where(
            (item) =>
                item.status == DownloadStatus.queued ||
                item.status == DownloadStatus.downloading,
          )
          .toList();

      if (pendingItems.isEmpty) {
        await _appStateDb.replacePendingDownloadQueueRows(const []);
        _log.d('Cleared queue storage (no pending items)');
      } else {
        final nowIso = DateTime.now().toIso8601String();
        final rows = pendingItems
            .map(
              (item) => <String, dynamic>{
                'id': item.id,
                'item_json': jsonEncode(item.toJson()),
                'status': item.status.name,
                'created_at': item.createdAt.toIso8601String(),
                'updated_at': nowIso,
              },
            )
            .toList(growable: false);
        await _appStateDb.replacePendingDownloadQueueRows(rows);
        _log.d('Saved ${pendingItems.length} pending items to storage');
      }
    } catch (e) {
      _log.e('Failed to save queue to storage: $e');
    }
  }

  void _startMultiProgressPolling() {
    _progressTimer?.cancel();
    _progressStreamBootstrapTimer?.cancel();
    _progressStreamBootstrapTimer = null;
    _progressStreamSub?.cancel();
    _progressStreamSub = null;
    _hasReceivedProgressStreamEvent = false;
    _usingProgressStream = false;
    _idleProgressPollTick = 0;

    if (Platform.isAndroid || Platform.isIOS) {
      _attachDownloadProgressStream();
      return;
    }

    _startMultiProgressPollingTimer();
  }

  void _attachDownloadProgressStream() {
    _progressStreamSub = PlatformBridge.downloadProgressStream().listen(
      (allProgress) {
        _hasReceivedProgressStreamEvent = true;
        _usingProgressStream = true;
        _progressStreamBootstrapTimer?.cancel();
        _progressStreamBootstrapTimer = null;
        if (_isProgressPollingInFlight) return;
        _isProgressPollingInFlight = true;
        try {
          _processAllDownloadProgress(allProgress);
          _progressPollingErrorCount = 0;
        } catch (e) {
          _progressPollingErrorCount++;
          if (_progressPollingErrorCount <= 3) {
            _log.w('Progress stream processing failed: $e');
          }
        } finally {
          _isProgressPollingInFlight = false;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_usingProgressStream) {
          _log.w(
            'Download progress stream failed, fallback to polling: $error',
          );
        }
        _progressStreamSub?.cancel();
        _progressStreamSub = null;
        _usingProgressStream = false;
        _progressStreamBootstrapTimer?.cancel();
        _progressStreamBootstrapTimer = null;
        _startMultiProgressPollingTimer();
      },
      cancelOnError: false,
    );

    _progressStreamBootstrapTimer = Timer(const Duration(seconds: 3), () {
      if (_hasReceivedProgressStreamEvent) {
        return;
      }
      _log.w('Download progress stream timeout, fallback to polling');
      _progressStreamSub?.cancel();
      _progressStreamSub = null;
      _usingProgressStream = false;
      _startMultiProgressPollingTimer();
    });
  }

  void _startMultiProgressPollingTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(_progressPollingInterval, (timer) async {
      if (_isProgressPollingInFlight) return;
      _isProgressPollingInFlight = true;
      try {
        final currentItems = state.items;
        final hasQueuedItems = currentItems.any(
          (item) => item.status == DownloadStatus.queued,
        );
        final hasActiveItems = currentItems.any(
          (item) =>
              item.status == DownloadStatus.downloading ||
              item.status == DownloadStatus.finalizing,
        );

        if (!hasActiveItems) {
          if (state.isPaused || !hasQueuedItems) {
            _idleProgressPollTick = 0;
            return;
          }

          _idleProgressPollTick =
              (_idleProgressPollTick + 1) % _idleProgressPollEveryTicks;
          if (_idleProgressPollTick != 0) {
            return;
          }
        } else {
          _idleProgressPollTick = 0;
        }

        final allProgress = await PlatformBridge.getAllDownloadProgress();
        _processAllDownloadProgress(allProgress);
        _progressPollingErrorCount = 0;
      } catch (e) {
        _progressPollingErrorCount++;
        if (_progressPollingErrorCount <= 3) {
          _log.w('Progress polling failed: $e');
        }
      } finally {
        _isProgressPollingInFlight = false;
      }
    });
  }

  void _processAllDownloadProgress(Map<String, dynamic> allProgress) {
    final rawItems = allProgress['items'];
    final items = rawItems is Map
        ? rawItems.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final currentItems = state.items;
    final itemsById = <String, DownloadItem>{};
    final itemIndexById = <String, int>{};
    int queuedCount = 0;
    int downloadingCount = 0;
    DownloadItem? firstDownloading;
    for (int i = 0; i < currentItems.length; i++) {
      final item = currentItems[i];
      itemsById[item.id] = item;
      itemIndexById[item.id] = i;
      if (item.status == DownloadStatus.downloading) {
        downloadingCount++;
        firstDownloading ??= item;
      }
      if (item.status == DownloadStatus.queued ||
          item.status == DownloadStatus.downloading) {
        queuedCount++;
      }
    }
    final progressUpdates = <String, _ProgressUpdate>{};

    bool hasFinalizingItem = false;
    String? finalizingTrackName;
    String? finalizingArtistName;

    for (final entry in items.entries) {
      final itemId = entry.key;
      final localItem = itemsById[itemId];
      if (localItem == null) {
        continue;
      }
      if (_isPausePending(itemId)) {
        PlatformBridge.clearItemProgress(itemId).catchError((_) {});
        continue;
      }
      if (localItem.status == DownloadStatus.skipped) {
        PlatformBridge.clearItemProgress(itemId).catchError((_) {});
        continue;
      }
      if (localItem.status == DownloadStatus.completed ||
          localItem.status == DownloadStatus.failed) {
        continue;
      }
      final rawItemProgress = entry.value;
      if (rawItemProgress is! Map) {
        continue;
      }
      final itemProgress = Map<String, dynamic>.from(rawItemProgress);
      final bytesReceived =
          (itemProgress['bytes_received'] as num?)?.toInt() ?? 0;
      final bytesTotal = (itemProgress['bytes_total'] as num?)?.toInt() ?? 0;
      final speedMBps = (itemProgress['speed_mbps'] as num?)?.toDouble() ?? 0.0;
      final isDownloading = itemProgress['is_downloading'] as bool? ?? false;
      final status = itemProgress['status'] as String? ?? 'downloading';

      if (status == 'finalizing') {
        progressUpdates[itemId] = const _ProgressUpdate(
          status: DownloadStatus.finalizing,
          progress: 1.0,
        );
        hasFinalizingItem = true;
        finalizingTrackName = localItem.track.name;
        finalizingArtistName = localItem.track.artistName;
        continue;
      }

      final progressFromBackend =
          (itemProgress['progress'] as num?)?.toDouble() ?? 0.0;

      if (isDownloading) {
        double percentage = 0.0;
        if (bytesTotal > 0) {
          percentage = bytesReceived / bytesTotal;
        } else {
          percentage = progressFromBackend;
        }
        final normalizedProgress = _normalizeProgressForUi(percentage);
        final normalizedSpeed = _normalizeSpeedForUi(speedMBps);
        final normalizedBytes = _normalizeBytesForUi(bytesReceived);

        progressUpdates[itemId] = _ProgressUpdate(
          status: DownloadStatus.downloading,
          progress: normalizedProgress,
          speedMBps: normalizedSpeed,
          bytesReceived: normalizedBytes,
          bytesTotal: bytesTotal,
        );

        if (LogBuffer.loggingEnabled) {
          final mbReceived = bytesReceived / (1024 * 1024);
          final mbTotal = bytesTotal / (1024 * 1024);
          if (bytesTotal > 0) {
            _log.d(
              'Progress [$itemId]: ${(percentage * 100).toStringAsFixed(1)}% (${mbReceived.toStringAsFixed(2)}/${mbTotal.toStringAsFixed(2)} MB) @ ${speedMBps.toStringAsFixed(2)} MB/s',
            );
          } else {
            _log.d(
              'Progress [$itemId]: ${(percentage * 100).toStringAsFixed(1)}% (DASH segments/unknown size) @ ${speedMBps.toStringAsFixed(2)} MB/s',
            );
          }
        }
      }
    }

    if (progressUpdates.isNotEmpty) {
      var updatedItems = currentItems;
      bool changed = false;

      for (final entry in progressUpdates.entries) {
        final index = itemIndexById[entry.key];
        if (index == null) continue;
        final current = updatedItems[index];
        if (current.status == DownloadStatus.skipped ||
            current.status == DownloadStatus.completed ||
            current.status == DownloadStatus.failed) {
          continue;
        }
        final update = entry.value;
        final next = current.copyWith(
          status: update.status,
          progress: update.progress,
          speedMBps: update.speedMBps ?? current.speedMBps,
          bytesReceived: update.bytesReceived ?? current.bytesReceived,
          bytesTotal: update.bytesTotal ?? current.bytesTotal,
        );
        if (current.status != next.status ||
            current.progress != next.progress ||
            current.speedMBps != next.speedMBps ||
            current.bytesReceived != next.bytesReceived ||
            current.bytesTotal != next.bytesTotal) {
          if (!changed) {
            updatedItems = List<DownloadItem>.from(updatedItems);
            changed = true;
          }
          updatedItems[index] = next;
        }
      }

      if (changed) {
        state = state.copyWith(items: updatedItems);
      }
    }

    if (hasFinalizingItem && finalizingTrackName != null) {
      final safeArtistName = finalizingArtistName ?? '';
      if (finalizingTrackName != _lastFinalizingTrackName ||
          safeArtistName != _lastFinalizingArtistName) {
        _notificationService.showDownloadFinalizing(
          trackName: finalizingTrackName,
          artistName: safeArtistName,
        );
        _lastFinalizingTrackName = finalizingTrackName;
        _lastFinalizingArtistName = safeArtistName;
      }
      return;
    }
    _lastFinalizingTrackName = null;
    _lastFinalizingArtistName = null;

    if (items.isNotEmpty) {
      final firstEntry = items.entries.first;
      final rawFirstProgress = firstEntry.value;
      if (rawFirstProgress is! Map) {
        return;
      }
      final firstProgress = Map<String, dynamic>.from(rawFirstProgress);
      final bytesReceived =
          (firstProgress['bytes_received'] as num?)?.toInt() ?? 0;
      final bytesTotal = (firstProgress['bytes_total'] as num?)?.toInt() ?? 0;

      if (downloadingCount > 0 && firstDownloading != null) {
        final trackName = downloadingCount == 1
            ? firstDownloading.track.name
            : '$downloadingCount downloads';
        final artistName = downloadingCount == 1
            ? firstDownloading.track.artistName
            : 'Downloading...';

        int notifProgress = bytesReceived;
        int notifTotal = bytesTotal;

        if (bytesTotal <= 0) {
          final progressPercent =
              (firstProgress['progress'] as num?)?.toDouble() ?? 0.0;
          notifProgress = (progressPercent * 100).toInt();
          notifTotal = 100;
        }

        final safeNotifTotal = notifTotal > 0 ? notifTotal : 1;
        if (_shouldUpdateProgressNotification(
          trackName: trackName,
          artistName: artistName,
          progress: notifProgress,
          total: safeNotifTotal,
          queueCount: queuedCount,
        )) {
          _notificationService.showDownloadProgress(
            trackName: trackName,
            artistName: artistName,
            progress: notifProgress,
            total: safeNotifTotal,
          );
        }

        if (Platform.isAndroid) {
          _maybeUpdateAndroidDownloadService(
            trackName: firstDownloading.track.name,
            artistName: firstDownloading.track.artistName,
            progress: notifProgress,
            total: safeNotifTotal,
            queueCount: queuedCount,
          );
        }
      }
    }
  }

  void _maybeUpdateAndroidDownloadService({
    required String trackName,
    required String artistName,
    required int progress,
    required int total,
    required int queueCount,
  }) {
    final now = DateTime.now();
    final safeTotal = total > 0 ? total : 1;
    final progressPercent = ((progress * 100) / safeTotal)
        .round()
        .clamp(0, 100)
        .toInt();
    final progressBucket = progressPercent == 100
        ? 100
        : ((progressPercent ~/ _serviceProgressStepPercent) *
                  _serviceProgressStepPercent)
              .clamp(0, 100);

    final didContentChange =
        trackName != _lastServiceTrackName ||
        artistName != _lastServiceArtistName ||
        queueCount != _lastServiceQueueCount ||
        progressBucket != _lastServicePercent;
    final allowHeartbeat =
        now.difference(_lastServiceUpdateAt) >= const Duration(seconds: 5);

    if (!didContentChange && !allowHeartbeat) {
      return;
    }

    _lastServiceTrackName = trackName;
    _lastServiceArtistName = artistName;
    _lastServicePercent = progressBucket;
    _lastServiceQueueCount = queueCount;
    _lastServiceUpdateAt = now;

    PlatformBridge.updateDownloadServiceProgress(
      trackName: trackName,
      artistName: artistName,
      progress: progress,
      total: safeTotal,
      queueCount: queueCount,
    ).catchError((_) {});
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    _progressStreamBootstrapTimer?.cancel();
    _progressStreamSub?.cancel();
    _progressTimer = null;
    _progressStreamBootstrapTimer = null;
    _progressStreamSub = null;
    _progressPollingErrorCount = 0;
    _isProgressPollingInFlight = false;
    _idleProgressPollTick = 0;
    _hasReceivedProgressStreamEvent = false;
    _usingProgressStream = false;
    _lastServiceTrackName = null;
    _lastServiceArtistName = null;
    _lastServicePercent = -1;
    _lastServiceQueueCount = -1;
    _lastServiceUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);
    _lastFinalizingTrackName = null;
    _lastFinalizingArtistName = null;
    _lastNotifTrackName = null;
    _lastNotifArtistName = null;
    _lastNotifPercent = -1;
    _lastNotifQueueCount = -1;
  }

  Directory _defaultDocumentsOutputDir(String documentsPath) {
    return Directory('$documentsPath/$_defaultOutputFolderName');
  }

  Directory _defaultAndroidMusicOutputDir(String storageRootPath) {
    return Directory('$storageRootPath/$_defaultAndroidMusicSubpath');
  }

  Future<Directory> _ensureDefaultDocumentsOutputDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = _defaultDocumentsOutputDir(dir.path);
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
  }

  Future<Directory?> _ensureDefaultAndroidMusicOutputDir() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) return null;

    final musicDir = _defaultAndroidMusicOutputDir(
      dir.parent.parent.parent.parent.path,
    );
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }
    return musicDir;
  }

  Future<void> _initOutputDir() async {
    if (state.outputDir.isEmpty) {
      try {
        if (Platform.isIOS) {
          final musicDir = await _ensureDefaultDocumentsOutputDir();
          state = state.copyWith(outputDir: musicDir.path);
        } else {
          final musicDir =
              await _ensureDefaultAndroidMusicOutputDir() ??
              await _ensureDefaultDocumentsOutputDir();
          state = state.copyWith(outputDir: musicDir.path);
        }
      } catch (e) {
        final musicDir = await _ensureDefaultDocumentsOutputDir();
        state = state.copyWith(outputDir: musicDir.path);
      }
    }
  }

  Future<void> _ensureDirExists(String path, {String? label}) async {
    if (_ensuredDirs.contains(path)) return;
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      if (label != null) {
        _log.d('Created $label: $path');
      } else {
        _log.d('Created folder: $path');
      }
    }
    _ensuredDirs.add(path);
  }

  void setOutputDir(String dir) {
    state = state.copyWith(outputDir: dir);
  }

  Future<String> _buildOutputDir(
    Track track,
    String folderOrganization, {
    bool separateSingles = false,
    String albumFolderStructure = 'artist_album',
    bool createPlaylistFolder = false,
    bool useAlbumArtistForFolders = true,
    bool usePrimaryArtistOnly = false,
    bool filterContributingArtistsInAlbumArtist = false,
    String? playlistName,
  }) async {
    String baseDir = state.outputDir;
    if (createPlaylistFolder &&
        folderOrganization != 'playlist' &&
        playlistName != null &&
        playlistName.isNotEmpty) {
      final playlistFolder = _sanitizeFolderName(playlistName);
      if (playlistFolder.isNotEmpty) {
        baseDir = '$baseDir${Platform.pathSeparator}$playlistFolder';
        await _ensureDirExists(baseDir, label: 'Playlist folder');
      }
    }
    final normalizedAlbumArtist = normalizeOptionalString(track.albumArtist);
    var folderArtist = useAlbumArtistForFolders
        ? normalizedAlbumArtist ?? track.artistName
        : track.artistName;
    if (useAlbumArtistForFolders &&
        filterContributingArtistsInAlbumArtist &&
        normalizedAlbumArtist != null) {
      folderArtist = _extractPrimaryArtist(folderArtist);
    }
    if (usePrimaryArtistOnly) {
      folderArtist = _extractPrimaryArtist(folderArtist);
    }

    if (separateSingles) {
      final isSingle = track.isSingle;
      final artistName = _sanitizeFolderName(folderArtist);

      if (albumFolderStructure == 'artist_album_singles') {
        if (isSingle) {
          final singlesPath =
              '$baseDir${Platform.pathSeparator}$artistName${Platform.pathSeparator}Singles';
          await _ensureDirExists(singlesPath, label: 'Artist Singles folder');
          return singlesPath;
        } else {
          final albumName = _sanitizeFolderName(track.albumName);
          final albumPath =
              '$baseDir${Platform.pathSeparator}$artistName${Platform.pathSeparator}$albumName';
          await _ensureDirExists(albumPath, label: 'Artist Album folder');
          return albumPath;
        }
      }

      if (albumFolderStructure == 'artist_album_flat') {
        if (isSingle) {
          final artistPath = '$baseDir${Platform.pathSeparator}$artistName';
          await _ensureDirExists(artistPath, label: 'Artist folder');
          return artistPath;
        } else {
          final albumName = _sanitizeFolderName(track.albumName);
          final albumPath =
              '$baseDir${Platform.pathSeparator}$artistName${Platform.pathSeparator}$albumName';
          await _ensureDirExists(albumPath, label: 'Artist Album folder');
          return albumPath;
        }
      }

      if (isSingle) {
        final singlesPath = '$baseDir${Platform.pathSeparator}Singles';
        await _ensureDirExists(singlesPath, label: 'Singles folder');
        return singlesPath;
      } else {
        final albumName = _sanitizeFolderName(track.albumName);
        final year = _extractYear(track.releaseDate);
        String albumPath;

        switch (albumFolderStructure) {
          case 'album_only':
            albumPath =
                '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$albumName';
            break;
          case 'artist_year_album':
            final yearAlbum = year != null ? '[$year] $albumName' : albumName;
            albumPath =
                '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$artistName${Platform.pathSeparator}$yearAlbum';
            break;
          case 'year_album':
            final yearAlbum = year != null ? '[$year] $albumName' : albumName;
            albumPath =
                '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$yearAlbum';
            break;
          default:
            albumPath =
                '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$artistName${Platform.pathSeparator}$albumName';
        }

        await _ensureDirExists(albumPath, label: 'Album folder');
        return albumPath;
      }
    }

    if (folderOrganization == 'none') {
      return baseDir;
    }

    String subPath = '';
    switch (folderOrganization) {
      case 'playlist':
        if (playlistName != null && playlistName.isNotEmpty) {
          subPath = _sanitizeFolderName(playlistName);
        }
        break;
      case 'artist':
        final artistName = _sanitizeFolderName(folderArtist);
        subPath = artistName;
        break;
      case 'album':
        final albumName = _sanitizeFolderName(track.albumName);
        subPath = albumName;
        break;
      case 'artist_album':
        final artistName = _sanitizeFolderName(folderArtist);
        final albumName = _sanitizeFolderName(track.albumName);
        subPath = '$artistName${Platform.pathSeparator}$albumName';
        break;
    }

    if (subPath.isNotEmpty) {
      final fullPath = '$baseDir${Platform.pathSeparator}$subPath';
      await _ensureDirExists(fullPath);
      return fullPath;
    }

    return baseDir;
  }

  String _sanitizeFolderName(String name) {
    return name
        .replaceAll(_invalidFolderChars, '_')
        .replaceAll(_trailingDotsRegex, '')
        .trim();
  }

  static final _featuredArtistPattern = RegExp(
    r'\s*[,;]\s*|\s+(?:feat\.?|ft\.?|featuring|with|x)\s+',
    caseSensitive: false,
  );

  String _extractPrimaryArtist(String artist) {
    final match = _featuredArtistPattern.firstMatch(artist);
    if (match != null && match.start > 0) {
      return artist.substring(0, match.start).trim();
    }
    return artist;
  }

  String _resolveAlbumArtistForMetadata(Track track, AppSettings settings) {
    var albumArtist =
        normalizeOptionalString(track.albumArtist) ?? track.artistName;
    if (settings.filterContributingArtistsInAlbumArtist) {
      albumArtist = _extractPrimaryArtist(albumArtist);
    }
    return albumArtist;
  }

  bool _isSafMode(AppSettings settings) {
    return Platform.isAndroid &&
        settings.storageMode == 'saf' &&
        settings.downloadTreeUri.isNotEmpty;
  }

  bool _isSafWriteFailure(Map<String, dynamic> result) {
    final error = (result['error'] ?? result['message'] ?? '')
        .toString()
        .toLowerCase();
    if (error.isEmpty) return false;
    return error.contains('saf') ||
        error.contains('content uri') ||
        error.contains('permission denied') ||
        error.contains('documentfile');
  }

  Future<String> _buildRelativeOutputDir(
    Track track,
    String folderOrganization, {
    bool separateSingles = false,
    String albumFolderStructure = 'artist_album',
    bool createPlaylistFolder = false,
    bool useAlbumArtistForFolders = true,
    bool usePrimaryArtistOnly = false,
    bool filterContributingArtistsInAlbumArtist = false,
    String? playlistName,
  }) async {
    final playlistPrefix =
        createPlaylistFolder &&
            folderOrganization != 'playlist' &&
            playlistName != null &&
            playlistName.isNotEmpty
        ? _sanitizeFolderName(playlistName)
        : '';
    final normalizedAlbumArtist = normalizeOptionalString(track.albumArtist);
    var folderArtist = useAlbumArtistForFolders
        ? normalizedAlbumArtist ?? track.artistName
        : track.artistName;
    if (useAlbumArtistForFolders &&
        filterContributingArtistsInAlbumArtist &&
        normalizedAlbumArtist != null) {
      folderArtist = _extractPrimaryArtist(folderArtist);
    }
    if (usePrimaryArtistOnly) {
      folderArtist = _extractPrimaryArtist(folderArtist);
    }

    if (separateSingles) {
      final isSingle = track.isSingle;
      final artistName = _sanitizeFolderName(folderArtist);

      if (albumFolderStructure == 'artist_album_singles') {
        if (isSingle) {
          return _joinRelativePath(playlistPrefix, '$artistName/Singles');
        }
        final albumName = _sanitizeFolderName(track.albumName);
        return _joinRelativePath(playlistPrefix, '$artistName/$albumName');
      }

      if (albumFolderStructure == 'artist_album_flat') {
        if (isSingle) {
          return _joinRelativePath(playlistPrefix, artistName);
        }
        final albumName = _sanitizeFolderName(track.albumName);
        return _joinRelativePath(playlistPrefix, '$artistName/$albumName');
      }

      if (isSingle) {
        return _joinRelativePath(playlistPrefix, 'Singles');
      }

      final albumName = _sanitizeFolderName(track.albumName);
      final year = _extractYear(track.releaseDate);
      switch (albumFolderStructure) {
        case 'album_only':
          return _joinRelativePath(playlistPrefix, 'Albums/$albumName');
        case 'artist_year_album':
          final yearAlbum = year != null ? '[$year] $albumName' : albumName;
          return _joinRelativePath(
            playlistPrefix,
            'Albums/$artistName/$yearAlbum',
          );
        case 'year_album':
          final yearAlbum = year != null ? '[$year] $albumName' : albumName;
          return _joinRelativePath(playlistPrefix, 'Albums/$yearAlbum');
        default:
          return _joinRelativePath(
            playlistPrefix,
            'Albums/$artistName/$albumName',
          );
      }
    }

    if (folderOrganization == 'none') {
      return playlistPrefix;
    }

    switch (folderOrganization) {
      case 'playlist':
        if (playlistName != null && playlistName.isNotEmpty) {
          return _sanitizeFolderName(playlistName);
        }
        return '';
      case 'artist':
        return _joinRelativePath(
          playlistPrefix,
          _sanitizeFolderName(folderArtist),
        );
      case 'album':
        return _joinRelativePath(
          playlistPrefix,
          _sanitizeFolderName(track.albumName),
        );
      case 'artist_album':
        final artistName = _sanitizeFolderName(folderArtist);
        final albumName = _sanitizeFolderName(track.albumName);
        return _joinRelativePath(playlistPrefix, '$artistName/$albumName');
      default:
        return playlistPrefix;
    }
  }

  String _joinRelativePath(String prefix, String suffix) {
    if (prefix.isEmpty) return suffix;
    if (suffix.isEmpty) return prefix;
    return '$prefix/$suffix';
  }

  String _determineOutputExt(String quality, String service) {
    if (service.toLowerCase() == 'tidal' && quality == 'HIGH') {
      return '.m4a';
    }
    final q = quality.toLowerCase();
    if (q.startsWith('opus')) return '.opus';
    if (q.startsWith('mp3')) return '.mp3';
    return '.flac';
  }

  String _mimeTypeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case '.m4a':
        return 'audio/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.opus':
        return 'audio/ogg';
      case '.flac':
        return 'audio/flac';
      case '.lrc':
        return 'application/octet-stream';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String?> _getSafMimeType(String uri) async {
    try {
      final stat = await PlatformBridge.safStat(uri);
      return stat['mime_type'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? _extractYear(String? releaseDate) {
    if (releaseDate == null || releaseDate.isEmpty) return null;
    final match = _yearRegex.firstMatch(releaseDate);
    return match?.group(1);
  }

  static final _isrcRegex = RegExp(r'^[A-Z]{2}[A-Z0-9]{3}\d{2}\d{5}$');

  bool _isValidISRC(String value) {
    return _isrcRegex.hasMatch(value.toUpperCase());
  }

  String _newQueueItemId(Track track, {Set<String>? takenIds}) {
    final trimmedIsrc = track.isrc?.trim();
    final trimmedTrackId = track.id.trim();
    final base = (trimmedIsrc != null && trimmedIsrc.isNotEmpty)
        ? trimmedIsrc
        : (trimmedTrackId.isNotEmpty ? trimmedTrackId : 'track');

    while (true) {
      _queueItemSequence++;
      final candidate =
          '$base-${DateTime.now().microsecondsSinceEpoch}-$_queueItemSequence';
      if (takenIds == null || !takenIds.contains(candidate)) {
        return candidate;
      }
    }
  }

  List<DownloadItem> _normalizeRestoredQueueIds(List<DownloadItem> items) {
    if (items.isEmpty) return items;

    final seen = <String>{};
    var regeneratedCount = 0;
    final normalized = <DownloadItem>[];

    for (final item in items) {
      final trimmedId = item.id.trim();
      final shouldRegenerate = trimmedId.isEmpty || seen.contains(trimmedId);
      if (shouldRegenerate) {
        final newId = _newQueueItemId(item.track, takenIds: seen);
        seen.add(newId);
        normalized.add(item.copyWith(id: newId));
        regeneratedCount++;
      } else {
        seen.add(trimmedId);
        normalized.add(item);
      }
    }

    if (regeneratedCount > 0) {
      _log.w(
        'Regenerated $regeneratedCount duplicate/empty queue item IDs during restore',
      );
    }

    return normalized;
  }

  void updateSettings(AppSettings settings) {
    final concurrentDownloads = settings.concurrentDownloads.clamp(1, 5);
    state = state.copyWith(
      outputDir: settings.downloadDirectory.isNotEmpty
          ? settings.downloadDirectory
          : state.outputDir,
      filenameFormat: settings.filenameFormat,
      singleFilenameFormat: settings.singleFilenameFormat,
      audioQuality: settings.audioQuality,
      autoFallback: settings.autoFallback,
      concurrentDownloads: concurrentDownloads,
    );
  }

  String addToQueue(
    Track track,
    String service, {
    String? qualityOverride,
    String? playlistName,
  }) {
    final settings = ref.read(settingsProvider);
    updateSettings(settings);

    final takenIds = state.items.map((item) => item.id).toSet();
    final id = _newQueueItemId(track, takenIds: takenIds);
    final item = DownloadItem(
      id: id,
      track: track,
      service: service,
      createdAt: DateTime.now(),
      qualityOverride: qualityOverride,
      playlistName: playlistName,
    );

    state = state.copyWith(items: [...state.items, item]);
    _saveQueueToStorage();

    if (!state.isProcessing) {
      Future.microtask(() => _processQueue());
    }

    return id;
  }

  void addMultipleToQueue(
    List<Track> tracks,
    String service, {
    String? qualityOverride,
    String? playlistName,
  }) {
    final settings = ref.read(settingsProvider);
    updateSettings(settings);

    final takenIds = state.items.map((item) => item.id).toSet();
    final newItems = tracks.map((track) {
      final id = _newQueueItemId(track, takenIds: takenIds);
      takenIds.add(id);
      return DownloadItem(
        id: id,
        track: track,
        service: service,
        createdAt: DateTime.now(),
        qualityOverride: qualityOverride,
        playlistName: playlistName,
      );
    }).toList();

    state = state.copyWith(items: [...state.items, ...newItems]);
    _saveQueueToStorage();

    if (!state.isProcessing) {
      Future.microtask(() => _processQueue());
    }
  }

  void updateItemStatus(
    String id,
    DownloadStatus status, {
    double? progress,
    double? speedMBps,
    String? filePath,
    String? error,
    DownloadErrorType? errorType,
  }) {
    final items = state.items;
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final current = items[index];
    final next = current.copyWith(
      status: status,
      progress: progress ?? current.progress,
      speedMBps: speedMBps ?? current.speedMBps,
      filePath: filePath,
      error: error,
      errorType: errorType,
    );

    if (current.status == next.status &&
        current.progress == next.progress &&
        current.speedMBps == next.speedMBps &&
        current.filePath == next.filePath &&
        current.error == next.error &&
        current.errorType == next.errorType) {
      return;
    }

    final updatedItems = List<DownloadItem>.from(items);
    updatedItems[index] = next;
    state = state.copyWith(items: updatedItems);

    if (status == DownloadStatus.completed ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.skipped) {
      _saveQueueToStorage();
    }
  }

  void updateProgress(String id, double progress, {double? speedMBps}) {
    final items = state.items;
    final index = items.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final item = items[index];
    if (item.status == DownloadStatus.skipped ||
        item.status == DownloadStatus.completed ||
        item.status == DownloadStatus.failed) {
      return;
    }
    updateItemStatus(
      id,
      DownloadStatus.downloading,
      progress: progress,
      speedMBps: speedMBps,
    );
  }

  DownloadItem? _findItemById(String id) {
    for (final item in state.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool _isLocallyCancelled(String id, {DownloadItem? item}) {
    if (_locallyCancelledItemIds.contains(id)) return true;
    final resolved = item ?? _findItemById(id);
    return resolved?.status == DownloadStatus.skipped;
  }

  bool _isPausePending(String id) => _pausePendingItemIds.contains(id);

  void _requeueItemForPause(String id) {
    final updatedItems = state.items
        .map((item) {
          if (item.id != id) return item;
          if (item.status == DownloadStatus.completed ||
              item.status == DownloadStatus.failed ||
              item.status == DownloadStatus.skipped) {
            return item;
          }
          return item.copyWith(
            status: DownloadStatus.queued,
            progress: 0,
            speedMBps: 0,
            bytesReceived: 0,
            bytesTotal: 0,
          );
        })
        .toList(growable: false);

    final currentDownload = state.currentDownload?.id == id
        ? null
        : state.currentDownload;
    state = state.copyWith(
      items: updatedItems,
      currentDownload: currentDownload,
    );
  }

  void _requestNativeCancel(String id) {
    PlatformBridge.cancelDownload(id).catchError((_) {});
    PlatformBridge.clearItemProgress(id).catchError((_) {});
  }

  void cancelItem(String id) {
    _pausePendingItemIds.remove(id);
    _locallyCancelledItemIds.add(id);
    updateItemStatus(id, DownloadStatus.skipped);
    _requestNativeCancel(id);
  }

  void dismissItem(String id) {
    final item = _findItemById(id);
    if (item == null) return;

    final isActive =
        item.status == DownloadStatus.queued ||
        item.status == DownloadStatus.downloading ||
        item.status == DownloadStatus.finalizing;
    final wasFailed =
        item.status == DownloadStatus.failed ||
        item.status == DownloadStatus.skipped;

    if (isActive) {
      _pausePendingItemIds.remove(id);
      _locallyCancelledItemIds.add(id);
      _requestNativeCancel(id);
    } else {
      _locallyCancelledItemIds.remove(id);
    }

    if (item.status != DownloadStatus.completed) {
      final key = _albumRgKey(item.track);
      final accumulator = _albumRgData[key];
      if (accumulator != null) {
        accumulator.entries.removeWhere((e) => e.trackId == item.track.id);
        if (accumulator.entries.isEmpty) {
          _albumRgData.remove(key);
        }
      }
    }

    final items = state.items.where((entry) => entry.id != id).toList();
    final currentDownload = state.currentDownload?.id == id
        ? null
        : state.currentDownload;
    state = state.copyWith(items: items, currentDownload: currentDownload);
    _saveQueueToStorage();

    // Dismissing a failed/skipped item may unblock album RG.
    if (wasFailed) {
      _retriggerAlbumRgChecks();
    }
  }

  void clearCompleted() {
    final removedItems = state.items.where(
      (item) =>
          item.status == DownloadStatus.completed ||
          item.status == DownloadStatus.failed ||
          item.status == DownloadStatus.skipped,
    );
    bool hadFailedOrSkipped = false;
    for (final item in removedItems) {
      if (item.status == DownloadStatus.failed ||
          item.status == DownloadStatus.skipped) {
        hadFailedOrSkipped = true;
        final key = _albumRgKey(item.track);
        final accumulator = _albumRgData[key];
        if (accumulator != null) {
          accumulator.entries.removeWhere((e) => e.trackId == item.track.id);
          if (accumulator.entries.isEmpty) {
            _albumRgData.remove(key);
          }
        }
      }
    }

    final items = state.items
        .where(
          (item) =>
              item.status != DownloadStatus.completed &&
              item.status != DownloadStatus.failed &&
              item.status != DownloadStatus.skipped,
        )
        .toList();

    state = state.copyWith(items: items);
    _saveQueueToStorage();

    if (hadFailedOrSkipped) {
      _retriggerAlbumRgChecks();
    }
  }

  void clearAll() {
    final wasProcessing = state.isProcessing;
    final activeIds = state.items
        .where(
          (item) =>
              item.status == DownloadStatus.queued ||
              item.status == DownloadStatus.downloading ||
              item.status == DownloadStatus.finalizing,
        )
        .map((item) => item.id)
        .toList(growable: false);

    if (activeIds.isNotEmpty) {
      _pausePendingItemIds.addAll(activeIds);
      _locallyCancelledItemIds.addAll(activeIds);
      for (final id in activeIds) {
        _requestNativeCancel(id);
      }
    }

    state = state.copyWith(items: [], isPaused: false, currentDownload: null);
    _notificationService.cancelDownloadNotification();
    _saveQueueToStorage();
    _albumRgData.clear();
    if (!wasProcessing) {
      _locallyCancelledItemIds.clear();
    }
    _pausePendingItemIds.clear();
  }

  void pauseQueue() {
    if (state.isProcessing && !state.isPaused) {
      final activeIds = state.items
          .where(
            (item) =>
                item.status == DownloadStatus.downloading ||
                item.status == DownloadStatus.finalizing,
          )
          .map((item) => item.id)
          .toSet();

      if (activeIds.isNotEmpty) {
        _pausePendingItemIds.addAll(activeIds);
        for (final id in activeIds) {
          _requestNativeCancel(id);
          _requeueItemForPause(id);
        }
      }

      state = state.copyWith(isPaused: true, currentDownload: null);
      _notificationService.cancelDownloadNotification();
      _log.i('Queue paused');
    }
  }

  void resumeQueue() {
    if (state.isPaused) {
      state = state.copyWith(isPaused: false);
      _log.i('Queue resumed');
      if (state.queuedCount > 0 && !state.isProcessing) {
        Future.microtask(() => _processQueue());
      }
    }
  }

  void togglePause() {
    if (state.isPaused) {
      resumeQueue();
    } else {
      pauseQueue();
    }
  }

  void retryItem(String id) {
    final item = state.items.where((i) => i.id == id).firstOrNull;
    if (item == null) {
      _log.w('retryItem: Item not found: $id');
      return;
    }

    if (item.status != DownloadStatus.failed &&
        item.status != DownloadStatus.skipped) {
      _log.w('retryItem: Item status is ${item.status}, not retrying');
      return;
    }

    _log.i('Retrying item: ${item.track.name} (id: $id)');
    _locallyCancelledItemIds.remove(id);

    // Purge stale ReplayGain entry for this track so a re-scan doesn't
    // produce duplicate entries that bias album gain.
    final rgKey = _albumRgKey(item.track);
    final rgAcc = _albumRgData[rgKey];
    if (rgAcc != null) {
      rgAcc.entries.removeWhere((e) => e.trackId == item.track.id);
      if (rgAcc.entries.isEmpty) {
        _albumRgData.remove(rgKey);
      }
    }

    final items = state.items.map((i) {
      if (i.id == id) {
        return i.copyWith(
          status: DownloadStatus.queued,
          progress: 0,
          error: null,
        );
      }
      return i;
    }).toList();
    state = state.copyWith(items: items);
    _saveQueueToStorage();

    if (!state.isProcessing) {
      _log.d('Starting queue processing for retry');
      Future.microtask(() => _processQueue());
    } else {
      _log.d('Queue already processing, item will be picked up');
    }
  }

  void removeItem(String id) {
    final removedItem = state.items.where((item) => item.id == id).firstOrNull;
    _locallyCancelledItemIds.remove(id);
    final items = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: items);
    _saveQueueToStorage();

    // Clean stale album RG entries when a track is removed from the queue.
    // Only purge for items that were NOT completed — completed items' RG data
    // must survive removal because album gain is computed after the last track
    // finishes, by which time earlier completed tracks have been removed.
    if (removedItem != null && removedItem.status != DownloadStatus.completed) {
      final key = _albumRgKey(removedItem.track);
      final accumulator = _albumRgData[key];
      if (accumulator != null) {
        accumulator.entries.removeWhere(
          (e) => e.trackId == removedItem.track.id,
        );
        if (accumulator.entries.isEmpty) {
          _albumRgData.remove(key);
        }
      }
      // Removing a failed/skipped item may unblock album RG for the album.
      _retriggerAlbumRgChecks();
    }
  }

  Future<String?> exportFailedDownloads() async {
    final failedItems = state.items
        .where((item) => item.status == DownloadStatus.failed)
        .toList();

    if (failedItems.isEmpty) {
      _log.d('No failed downloads to export');
      return null;
    }

    try {
      String baseDir = state.outputDir;
      if (baseDir.isEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        baseDir = dir.path;
      }

      final failedDownloadsDir = '$baseDir/failed_downloads';
      final failedDir = Directory(failedDownloadsDir);
      if (!await failedDir.exists()) {
        await failedDir.create(recursive: true);
      }

      // Use date-only format for daily grouping (YYYY-MM-DD)
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'failed_downloads_$dateStr.txt';
      final filePath = '$failedDownloadsDir/$fileName';

      final file = File(filePath);
      final bool fileExists = await file.exists();

      final buffer = StringBuffer();

      if (!fileExists) {
        buffer.writeln('# SpotiFLAC Failed Downloads');
        buffer.writeln('# Date: $dateStr');
        buffer.writeln('#');
        buffer.writeln('# Format: [Time] Track - Artist | URL | Error');
        buffer.writeln('');
      }

      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      for (final item in failedItems) {
        final track = item.track;
        final spotifyUrl = track.id.startsWith('deezer:')
            ? 'https://www.deezer.com/track/${track.id.substring(7)}'
            : 'https://open.spotify.com/track/${track.id}';
        final error = item.error ?? 'Unknown error';
        buffer.writeln(
          '[$timeStr] ${track.name} - ${track.artistName} | $spotifyUrl | $error',
        );
      }

      if (fileExists) {
        await file.writeAsString(buffer.toString(), mode: FileMode.append);
        _log.i('Appended ${failedItems.length} failed downloads to: $filePath');
      } else {
        await file.writeAsString(buffer.toString());
        _log.i('Created new failed downloads file: $filePath');
      }

      return filePath;
    } catch (e) {
      _log.e('Failed to export failed downloads: $e');
      return null;
    }
  }

  void clearFailedDownloads() {
    final failedItems = state.items
        .where((item) => item.status == DownloadStatus.failed)
        .toList();
    for (final item in failedItems) {
      final key = _albumRgKey(item.track);
      final accumulator = _albumRgData[key];
      if (accumulator != null) {
        accumulator.entries.removeWhere((e) => e.trackId == item.track.id);
        if (accumulator.entries.isEmpty) {
          _albumRgData.remove(key);
        }
      }
    }

    final items = state.items
        .where((item) => item.status != DownloadStatus.failed)
        .toList();
    state = state.copyWith(items: items);
    _saveQueueToStorage();
    _log.d('Cleared failed downloads from queue');

    // Removing failed items may unblock album RG for affected albums.
    if (failedItems.isNotEmpty) {
      _retriggerAlbumRgChecks();
    }
  }

  Future<void> _runPostProcessingHooks(String filePath, Track track) async {
    try {
      final settings = ref.read(settingsProvider);
      final extensionState = ref.read(extensionProvider);
      final resolvedAlbumArtist = _resolveAlbumArtistForMetadata(
        track,
        settings,
      );

      if (!settings.useExtensionProviders) return;

      final hasPostProcessing = extensionState.extensions.any(
        (e) => e.enabled && e.hasPostProcessing,
      );
      if (!hasPostProcessing) return;

      _log.d('Running post-processing hooks on: $filePath');

      final metadata = <String, dynamic>{
        'title': track.name,
        'artist': track.artistName,
        'album': track.albumName,
        'album_artist': resolvedAlbumArtist,
        'track_number': track.trackNumber ?? 0,
        'disc_number': track.discNumber ?? 0,
        'isrc': track.isrc ?? '',
        'release_date': track.releaseDate ?? '',
        'duration_ms': track.duration * 1000,
        'cover_url': track.coverUrl ?? '',
      };

      final result = await PlatformBridge.runPostProcessingV2(
        filePath,
        metadata: metadata,
      );

      if (result['success'] == true) {
        final hooksRun = result['hooks_run'] as int? ?? 0;
        final newPath = result['file_path'] as String?;
        _log.i('Post-processing completed: $hooksRun hook(s) executed');

        if (newPath != null && newPath != filePath) {
          _log.d('File path changed by post-processing: $newPath');
        }
      } else {
        final error = result['error'] as String? ?? 'Unknown error';
        _log.w('Post-processing failed: $error');
      }
    } catch (e) {
      _log.w('Post-processing error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Album ReplayGain: accumulate per-track data, compute & write album gain
  // ---------------------------------------------------------------------------

  /// Build a stable key for grouping tracks by album.
  String _albumRgKey(Track track) {
    if (track.albumId != null && track.albumId!.isNotEmpty) {
      return 'id:${track.albumId}';
    }
    return 'name:${track.albumName}|${track.albumArtist ?? ''}';
  }

  /// Store a track's ReplayGain scan result for later album gain computation.
  void _storeTrackReplayGainForAlbum(
    Track track,
    String filePath,
    ReplayGainResult rg,
  ) {
    final key = _albumRgKey(track);
    _albumRgData.putIfAbsent(key, () => _AlbumRgAccumulator());
    // Remove any stale entry for this track (e.g. from a previous failed
    // attempt that was retried).  Without this, the same track can accumulate
    // multiple entries and bias the album loudness calculation.
    _albumRgData[key]!.entries.removeWhere((e) => e.trackId == track.id);
    _albumRgData[key]!.entries.add(
      _AlbumRgTrackEntry(
        filePath: filePath,
        trackId: track.id,
        integratedLufs: rg.integratedLufs,
        truePeakLinear: rg.truePeakLinear,
        durationSecs: track.duration.toDouble(),
      ),
    );
  }

  /// Replace the temp path stored in the accumulator with the final output
  /// path.  For SAF downloads the embed happens on a temp file which is later
  /// deleted — this ensures the album-gain writer targets the real file.
  void _updateAlbumRgFilePath(Track track, String finalPath) {
    final key = _albumRgKey(track);
    final accumulator = _albumRgData[key];
    if (accumulator == null) return;
    for (final entry in accumulator.entries) {
      if (entry.trackId == track.id) {
        entry.filePath = finalPath;
        break;
      }
    }
  }

  /// After a track completes, check whether all tracks from the same album
  /// in the current queue are done.  If so, compute album gain and write it
  /// to every track's file.
  Future<void> _checkAndWriteAlbumReplayGain(Track track) async {
    final settings = ref.read(settingsProvider);
    if (!settings.embedReplayGain) return;

    final key = _albumRgKey(track);
    final accumulator = _albumRgData[key];
    if (accumulator == null || accumulator.entries.isEmpty) return;

    // Find queue items for this album that are STILL in the queue.
    // Completed tracks may have already been removed by removeItem(), so
    // their absence means they finished successfully (not that they're
    // still pending).
    final albumItemsInQueue = state.items
        .where((item) => _albumRgKey(item.track) == key)
        .toList();

    // If any item is still in-flight, the album isn't complete yet.
    final pending = albumItemsInQueue.where(
      (item) =>
          item.status == DownloadStatus.queued ||
          item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.finalizing,
    );
    if (pending.isNotEmpty) return; // still in progress

    // If any item is failed/skipped, the user might retry it later.
    // Don't finalize album RG with partial data — wait until all album
    // tracks are either completed (and possibly removed) or retried.
    final retryable = albumItemsInQueue.where(
      (item) =>
          item.status == DownloadStatus.failed ||
          item.status == DownloadStatus.skipped,
    );
    if (retryable.isNotEmpty) return; // still retryable

    // The accumulator entries represent successfully scanned tracks.  Entries
    // are only added after a successful ReplayGain scan, removed on retry or
    // when a non-completed item is removed from the queue, so every entry
    // here corresponds to a track that completed (or is about to complete)
    // its download.
    final validEntries = accumulator.entries.toList();

    // Single-track albums: album gain == track gain, no extra write needed.
    if (validEntries.length <= 1) {
      _albumRgData.remove(key);
      return;
    }

    // Compute album gain using duration-weighted power-mean of LUFS values.
    // album_loudness = 10 * log10( Σ(10^(Li/10) * di) / Σ(di) )
    // This weights longer tracks more, matching "whole program" loudness.
    double sumWeightedPower = 0;
    double sumDuration = 0;
    double maxPeak = 0;
    for (final entry in validEntries) {
      final weight = entry.durationSecs > 0 ? entry.durationSecs : 1.0;
      sumWeightedPower += pow(10, entry.integratedLufs / 10.0) * weight;
      sumDuration += weight;
      if (entry.truePeakLinear > maxPeak) {
        maxPeak = entry.truePeakLinear;
      }
    }
    final albumLufs = 10.0 * _log10(sumWeightedPower / sumDuration);
    const replayGainReferenceLufs = -18.0;
    final albumGainDb = replayGainReferenceLufs - albumLufs;

    final albumGain =
        '${albumGainDb >= 0 ? "+" : ""}${albumGainDb.toStringAsFixed(2)} dB';
    final albumPeak = maxPeak.toStringAsFixed(6);

    _log.i(
      'Album ReplayGain for "$key": gain=$albumGain, peak=$albumPeak (${validEntries.length} tracks, album LUFS=${albumLufs.toStringAsFixed(1)})',
    );

    for (final entry in validEntries) {
      try {
        await _writeAlbumReplayGain(entry.filePath, albumGain, albumPeak);
      } catch (e) {
        _log.w('Failed to write album ReplayGain to ${entry.filePath}: $e');
      }
    }

    _albumRgData.remove(key);
  }

  /// Write album ReplayGain tags to a single file.
  Future<void> _writeAlbumReplayGain(
    String filePath,
    String albumGain,
    String albumPeak,
  ) async {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.flac') ||
        lower.endsWith('.ape') ||
        lower.endsWith('.wv') ||
        lower.endsWith('.mpc')) {
      // Native writer — only touches the provided fields, preserves the rest.
      await PlatformBridge.editFileMetadata(filePath, {
        'replaygain_album_gain': albumGain,
        'replaygain_album_peak': albumPeak,
      });
    } else if (isContentUri(filePath)) {
      // SAF content:// URI — FFmpeg can read it but can't write back directly.
      // Get the temp output from FFmpeg, then copy it to the SAF URI.
      String? tempPath;
      final ok = await FFmpegService.writeAlbumReplayGainTags(
        filePath,
        albumGain,
        albumPeak,
        returnTempPath: true,
        onTempReady: (path) => tempPath = path,
      );
      if (ok && tempPath != null) {
        try {
          final safOk = await PlatformBridge.writeTempToSaf(
            tempPath!,
            filePath,
          );
          if (!safOk) {
            _log.w('SAF write-back failed for album RG: $filePath');
          }
        } finally {
          // Clean up temp file regardless of SAF result.
          try {
            final tmp = File(tempPath!);
            if (await tmp.exists()) await tmp.delete();
          } catch (_) {}
        }
      } else {
        _log.w('FFmpeg album ReplayGain write failed for SAF: $filePath');
      }
    } else {
      // Local MP3 / Opus — use FFmpeg copy-with-metadata approach.
      final ok = await FFmpegService.writeAlbumReplayGainTags(
        filePath,
        albumGain,
        albumPeak,
      );
      if (!ok) {
        _log.w('FFmpeg album ReplayGain write failed for: $filePath');
      }
    }
  }

  /// Re-check album ReplayGain for all albums that still have accumulator data.
  /// Called after removing/dismissing a failed or skipped item, which may
  /// unblock an album that was waiting for retryable items to be resolved.
  void _retriggerAlbumRgChecks() {
    if (_albumRgData.isEmpty) return;
    final settings = ref.read(settingsProvider);
    if (!settings.embedReplayGain) return;

    // Snapshot the keys — _checkAndWriteAlbumReplayGain may mutate the map.
    final keys = _albumRgData.keys.toList();
    for (final key in keys) {
      final acc = _albumRgData[key];
      if (acc == null || acc.entries.isEmpty) continue;
      // Use the first entry's trackId to find a representative track.
      // _checkAndWriteAlbumReplayGain only needs it for _albumRgKey(), so any
      // track from the album works.
      final albumItems = state.items
          .where((item) => _albumRgKey(item.track) == key)
          .toList();
      // If there are no items left in queue for this album but we have
      // accumulator data, all items were completed and removed.  Use a
      // synthetic call — we need a Track to call the check, but the items
      // are gone.  For this case, directly check conditions inline.
      if (albumItems.isEmpty) {
        // All items removed → no pending/retryable.  Trigger computation.
        if (acc.entries.length > 1) {
          _computeAndWriteAlbumRg(key, acc);
        }
        continue;
      }
      // If any representative item is available, use its track.
      final representative = albumItems.first;
      _checkAndWriteAlbumReplayGain(representative.track);
    }
  }

  /// Compute album RG and write it — extracted from _checkAndWriteAlbumReplayGain
  /// for use when no queue items remain (all completed and removed).
  Future<void> _computeAndWriteAlbumRg(
    String key,
    _AlbumRgAccumulator accumulator,
  ) async {
    final validEntries = accumulator.entries.toList();
    if (validEntries.length <= 1) {
      _albumRgData.remove(key);
      return;
    }

    double sumWeightedPower = 0;
    double sumDuration = 0;
    double maxPeak = 0;
    for (final entry in validEntries) {
      final weight = entry.durationSecs > 0 ? entry.durationSecs : 1.0;
      sumWeightedPower += pow(10, entry.integratedLufs / 10.0) * weight;
      sumDuration += weight;
      if (entry.truePeakLinear > maxPeak) {
        maxPeak = entry.truePeakLinear;
      }
    }
    final albumLufs = 10.0 * _log10(sumWeightedPower / sumDuration);
    const replayGainReferenceLufs = -18.0;
    final albumGainDb = replayGainReferenceLufs - albumLufs;

    final albumGain =
        '${albumGainDb >= 0 ? "+" : ""}${albumGainDb.toStringAsFixed(2)} dB';
    final albumPeak = maxPeak.toStringAsFixed(6);

    _log.i(
      'Album ReplayGain for "$key": gain=$albumGain, peak=$albumPeak (${validEntries.length} tracks, album LUFS=${albumLufs.toStringAsFixed(1)})',
    );

    for (final entry in validEntries) {
      try {
        await _writeAlbumReplayGain(entry.filePath, albumGain, albumPeak);
      } catch (e) {
        _log.w('Failed to write album ReplayGain to ${entry.filePath}: $e');
      }
    }

    _albumRgData.remove(key);
  }

  /// Deezer CDN cover size pattern: /WxH-0-0-0-0.jpg
  static final _deezerSizeRegex = RegExp(r'/(\d+)x(\d+)-\d+-\d+-\d+-\d+\.jpg$');

  String _upgradeToMaxQualityCover(String coverUrl) {
    const spotifySize300 = 'ab67616d00001e02';
    const spotifySize640 = 'ab67616d0000b273';
    const spotifySizeMax = 'ab67616d000082c1';

    var result = coverUrl;
    if (result.contains(spotifySize300)) {
      result = result.replaceFirst(spotifySize300, spotifySize640);
    }
    if (result.contains(spotifySize640)) {
      result = result.replaceFirst(spotifySize640, spotifySizeMax);
    }

    if (result.contains('cdn-images.dzcdn.net')) {
      final upgraded = result.replaceFirst(
        _deezerSizeRegex,
        '/1800x1800-000000-80-0-0.jpg',
      );
      if (upgraded != result) {
        _log.d('Cover URL upgraded (Deezer): 1800x1800');
        result = upgraded;
      }
    }

    // Tidal CDN upgrade (1280x1280 → origin)
    if (result.contains('resources.tidal.com') &&
        result.contains('/1280x1280.jpg')) {
      result = result.replaceFirst('/1280x1280.jpg', '/origin.jpg');
      _log.d('Cover URL upgraded (Tidal): origin');
    }

    return result;
  }

  int? _parsePositiveInt(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  Track _buildTrackForMetadataEmbedding(
    Track baseTrack,
    Map<String, dynamic> backendResult,
    String resolvedAlbumArtist,
  ) {
    final backendTrackNum = _parsePositiveInt(backendResult['track_number']);
    final backendDiscNum = _parsePositiveInt(backendResult['disc_number']);
    final backendYear = normalizeOptionalString(
      backendResult['release_date'] as String?,
    );
    final backendAlbum = normalizeOptionalString(
      backendResult['album'] as String?,
    );
    final backendIsrc = normalizeOptionalString(
      backendResult['isrc'] as String?,
    );
    final backendCoverUrl = normalizeCoverReference(
      backendResult['cover_url']?.toString(),
    );
    final backendAlbumArtist = normalizeOptionalString(
      backendResult['album_artist'] as String?,
    );

    final hasOverrides =
        backendTrackNum != null ||
        backendDiscNum != null ||
        backendYear != null ||
        backendAlbum != null ||
        backendIsrc != null ||
        backendCoverUrl != null ||
        backendAlbumArtist != null;

    if (!hasOverrides) {
      return baseTrack;
    }

    return Track(
      id: baseTrack.id,
      name: baseTrack.name,
      artistName: baseTrack.artistName,
      albumName: backendAlbum ?? baseTrack.albumName,
      albumArtist: backendAlbumArtist ?? resolvedAlbumArtist,
      artistId: baseTrack.artistId,
      albumId: baseTrack.albumId,
      coverUrl: backendCoverUrl ?? baseTrack.coverUrl,
      duration: baseTrack.duration,
      isrc: backendIsrc ?? baseTrack.isrc,
      trackNumber: backendTrackNum ?? baseTrack.trackNumber,
      discNumber: backendDiscNum ?? baseTrack.discNumber,
      releaseDate: backendYear ?? baseTrack.releaseDate,
      deezerId: baseTrack.deezerId,
      availability: baseTrack.availability,
      albumType: baseTrack.albumType,
      totalTracks: baseTrack.totalTracks,
      source: baseTrack.source,
    );
  }

  Future<void> _embedMetadataAndCover(
    String flacPath,
    Track track, {
    String? genre,
    String? label,
    String? copyright,
    bool writeExternalLrc = true,
  }) async {
    final settings = ref.read(settingsProvider);
    if (!settings.embedMetadata) {
      _log.d('Metadata embedding disabled, skipping FLAC metadata/cover embed');
      return;
    }

    String? coverPath;
    var coverUrl = normalizeRemoteHttpUrl(track.coverUrl);
    if (coverUrl != null && coverUrl.isNotEmpty) {
      try {
        if (settings.maxQualityCover) {
          coverUrl = _upgradeToMaxQualityCover(coverUrl);
          _log.d('Cover URL upgraded to max quality: $coverUrl');
        }

        final tempDir = await getTemporaryDirectory();
        final uniqueId =
            '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
        coverPath = '${tempDir.path}/cover_$uniqueId.jpg';

        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(coverUrl));
        final response = await request.close();
        if (response.statusCode == 200) {
          final file = File(coverPath);
          final sink = file.openWrite();
          await response.pipe(sink);
          await sink.close();
          _log.d('Cover downloaded to temp: $coverPath');
        } else {
          _log.w('Failed to download cover: HTTP ${response.statusCode}');
          coverPath = null;
        }
        httpClient.close();
      } catch (e) {
        _log.e('Failed to download cover: $e');
        coverPath = null;
      }
    }

    try {
      final metadata = <String, String>{
        'TITLE': track.name,
        'ARTIST': track.artistName,
        'ALBUM': track.albumName,
      };

      final albumArtist = _resolveAlbumArtistForMetadata(track, settings);
      metadata['ALBUMARTIST'] = albumArtist;

      if (track.trackNumber != null && track.trackNumber! > 0) {
        metadata['TRACKNUMBER'] = track.trackNumber.toString();
        metadata['TRACK'] = track.trackNumber.toString();
      }

      if (track.discNumber != null && track.discNumber! > 0) {
        metadata['DISCNUMBER'] = track.discNumber.toString();
        metadata['DISC'] = track.discNumber.toString();
      }

      if (track.releaseDate != null) {
        metadata['DATE'] = track.releaseDate!;
        metadata['YEAR'] = track.releaseDate!.split('-').first;
      }

      if (track.isrc != null) {
        metadata['ISRC'] = track.isrc!;
      }

      if (genre != null && genre.isNotEmpty) {
        metadata['GENRE'] = genre;
        _log.d('Adding GENRE: $genre');
      }
      if (label != null && label.isNotEmpty) {
        metadata['ORGANIZATION'] = label;
        _log.d('Adding ORGANIZATION (label): $label');
      }
      if (copyright != null && copyright.isNotEmpty) {
        metadata['COPYRIGHT'] = copyright;
        _log.d('Adding COPYRIGHT: $copyright');
      }

      _log.d('Metadata map content: $metadata');

      final lyricsMode = settings.lyricsMode;
      final shouldEmbedLyrics =
          settings.embedLyrics &&
          (lyricsMode == 'embed' || lyricsMode == 'both');
      final shouldSaveExternalLyrics =
          settings.embedLyrics &&
          (lyricsMode == 'external' || lyricsMode == 'both');
      final shouldFetchLyrics = shouldEmbedLyrics || shouldSaveExternalLyrics;
      String? lrcContent;

      if (shouldFetchLyrics) {
        try {
          final durationMs = track.duration * 1000;

          final fetchedLrc = await PlatformBridge.getLyricsLRC(
            track.id,
            track.name,
            track.artistName,
            filePath: '',
            durationMs: durationMs,
          );

          if (fetchedLrc.isNotEmpty && fetchedLrc != '[instrumental:true]') {
            lrcContent = fetchedLrc;
            _log.d('Lyrics fetched for FLAC (${fetchedLrc.length} chars)');
          } else if (fetchedLrc == '[instrumental:true]') {
            _log.d('Track is instrumental, skipping lyrics handling');
          } else {
            _log.d('No lyrics returned for FLAC download');
          }
        } catch (e) {
          _log.w('Failed to fetch lyrics for FLAC: $e');
        }
      }

      if (shouldEmbedLyrics) {
        if (lrcContent != null) {
          metadata['LYRICS'] = lrcContent;
          metadata['UNSYNCEDLYRICS'] = lrcContent;
          _log.d('Lyrics added to FLAC metadata');
        } else {
          _log.d('No lyrics available for FLAC embedding');
        }
      } else {
        metadata['LYRICS'] = '';
        metadata['UNSYNCEDLYRICS'] = '';
        _log.d(
          'Lyrics embedding disabled by settings, skipping lyric embedding',
        );
      }

      if (writeExternalLrc && shouldSaveExternalLyrics && lrcContent != null) {
        try {
          final replacedPath = flacPath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc');
          final lrcPath = replacedPath == flacPath
              ? '$flacPath.lrc'
              : replacedPath;
          await File(lrcPath).writeAsString(lrcContent);
          _log.d('External LRC file saved: $lrcPath');
        } catch (e) {
          _log.w('Failed to save external LRC file for FLAC: $e');
        }
      }

      _log.d('Generating tags for FLAC: $metadata');

      final result = await FFmpegService.embedMetadata(
        flacPath: flacPath,
        coverPath: coverPath != null && await File(coverPath).exists()
            ? coverPath
            : null,
        metadata: metadata,
        artistTagMode: settings.artistTagMode,
      );

      if (result != null) {
        _log.d('Metadata and cover embedded via FFmpeg');
      } else {
        _log.w('FFmpeg metadata/cover embed failed');
      }

      // After FFmpeg embed, fix split artist tags using native FLAC writer.
      // FFmpeg deduplicates repeated metadata keys, so multiple ARTIST entries
      // collapse into one. The Go FLAC writer rewrites them properly.
      if (settings.artistTagMode == artistTagModeSplitVorbis) {
        try {
          await PlatformBridge.rewriteSplitArtistTags(
            flacPath,
            track.artistName,
            albumArtist,
          );
          _log.d('Split artist tags rewritten via native FLAC writer');
        } catch (e) {
          _log.w('Failed to rewrite split artist tags: $e');
        }
      }

      // ReplayGain: scan loudness and embed tags via native FLAC writer.
      if (settings.embedReplayGain) {
        try {
          final rgResult = await FFmpegService.scanReplayGain(flacPath);
          if (rgResult != null) {
            await PlatformBridge.editFileMetadata(flacPath, {
              'replaygain_track_gain': rgResult.trackGain,
              'replaygain_track_peak': rgResult.trackPeak,
            });
            _log.d(
              'ReplayGain tags embedded: gain=${rgResult.trackGain}, peak=${rgResult.trackPeak}',
            );
            // Store for album gain computation after all album tracks complete.
            _storeTrackReplayGainForAlbum(track, flacPath, rgResult);
          } else {
            _log.w('ReplayGain scan returned no result');
          }
        } catch (e) {
          _log.w('Failed to scan/embed ReplayGain: $e');
        }
      }

      if (coverPath != null) {
        try {
          final coverFile = File(coverPath);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        } catch (e) {
          _log.w('Failed to cleanup cover file: $e');
        }
      }
    } catch (e) {
      _log.e('Failed to embed metadata: $e');
    }
  }

  Future<void> _embedMetadataToMp3(
    String mp3Path,
    Track track, {
    String? genre,
    String? label,
    String? copyright,
  }) async {
    final settings = ref.read(settingsProvider);
    if (!settings.embedMetadata) {
      _log.d('Metadata embedding disabled, skipping MP3 metadata/cover embed');
      return;
    }

    String? coverPath;
    var coverUrl = normalizeRemoteHttpUrl(track.coverUrl);
    if (coverUrl != null && coverUrl.isNotEmpty) {
      try {
        if (settings.maxQualityCover) {
          coverUrl = _upgradeToMaxQualityCover(coverUrl);
          _log.d('Cover URL upgraded to max quality for MP3: $coverUrl');
        }

        final tempDir = await getTemporaryDirectory();
        final uniqueId =
            '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
        coverPath = '${tempDir.path}/cover_mp3_$uniqueId.jpg';

        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(coverUrl));
        final response = await request.close();
        if (response.statusCode == 200) {
          final file = File(coverPath);
          final sink = file.openWrite();
          await response.pipe(sink);
          await sink.close();
          _log.d('Cover downloaded for MP3: $coverPath');
        } else {
          _log.w(
            'Failed to download cover for MP3: HTTP ${response.statusCode}',
          );
          coverPath = null;
        }
        httpClient.close();
      } catch (e) {
        _log.e('Failed to download cover for MP3: $e');
        coverPath = null;
      }
    }

    try {
      final metadata = <String, String>{
        'TITLE': track.name,
        'ARTIST': track.artistName,
        'ALBUM': track.albumName,
      };

      final albumArtist = _resolveAlbumArtistForMetadata(track, settings);
      metadata['ALBUMARTIST'] = albumArtist;

      if (track.trackNumber != null && track.trackNumber! > 0) {
        metadata['TRACKNUMBER'] = track.trackNumber.toString();
        metadata['TRACK'] = track.trackNumber.toString();
      }

      if (track.discNumber != null && track.discNumber! > 0) {
        metadata['DISCNUMBER'] = track.discNumber.toString();
        metadata['DISC'] = track.discNumber.toString();
      }

      if (track.releaseDate != null) {
        metadata['DATE'] = track.releaseDate!;
        metadata['YEAR'] = track.releaseDate!.split('-').first;
      }

      if (track.isrc != null) {
        metadata['ISRC'] = track.isrc!;
      }

      if (genre != null && genre.isNotEmpty) {
        metadata['GENRE'] = genre;
        _log.d('Adding GENRE to MP3: $genre');
      }
      if (label != null && label.isNotEmpty) {
        metadata['ORGANIZATION'] = label;
        _log.d('Adding ORGANIZATION (label) to MP3: $label');
      }
      if (copyright != null && copyright.isNotEmpty) {
        metadata['COPYRIGHT'] = copyright;
        _log.d('Adding COPYRIGHT to MP3: $copyright');
      }

      _log.d('MP3 Metadata map content: $metadata');

      final lyricsMode = settings.lyricsMode;
      final shouldEmbed = lyricsMode == 'embed' || lyricsMode == 'both';
      final shouldSaveExternal =
          lyricsMode == 'external' || lyricsMode == 'both';

      if (settings.embedLyrics && (shouldEmbed || shouldSaveExternal)) {
        try {
          final durationMs = track.duration * 1000;

          final lrcContent = await PlatformBridge.getLyricsLRC(
            track.id,
            track.name,
            track.artistName,
            filePath: '',
            durationMs: durationMs,
          );

          if (lrcContent.isNotEmpty) {
            if (shouldEmbed) {
              metadata['LYRICS'] = lrcContent;
              metadata['UNSYNCEDLYRICS'] = lrcContent;
              _log.d(
                'Lyrics fetched for MP3 embedding (${lrcContent.length} chars)',
              );
            }

            if (shouldSaveExternal) {
              try {
                final lrcPath = mp3Path.replaceAll(
                  RegExp(r'\.mp3$', caseSensitive: false),
                  '.lrc',
                );
                await File(lrcPath).writeAsString(lrcContent);
                _log.d('External LRC file saved: $lrcPath');
              } catch (e) {
                _log.w('Failed to save external LRC file: $e');
              }
            }
          }
        } catch (e) {
          _log.w('Failed to fetch lyrics for MP3: $e');
        }
      }

      _log.d('Embedding tags to MP3: $metadata');

      // ReplayGain: scan loudness and add to metadata before FFmpeg embed.
      if (settings.embedReplayGain) {
        try {
          final rgResult = await FFmpegService.scanReplayGain(mp3Path);
          if (rgResult != null) {
            metadata['REPLAYGAIN_TRACK_GAIN'] = rgResult.trackGain;
            metadata['REPLAYGAIN_TRACK_PEAK'] = rgResult.trackPeak;
            _log.d(
              'ReplayGain added to MP3 metadata: gain=${rgResult.trackGain}, peak=${rgResult.trackPeak}',
            );
            // Store for album gain computation after all album tracks complete.
            _storeTrackReplayGainForAlbum(track, mp3Path, rgResult);
          }
        } catch (e) {
          _log.w('Failed to scan ReplayGain for MP3: $e');
        }
      }

      final result = await FFmpegService.embedMetadataToMp3(
        mp3Path: mp3Path,
        coverPath: coverPath != null && await File(coverPath).exists()
            ? coverPath
            : null,
        metadata: metadata,
      );

      if (result != null) {
        _log.d('Metadata, lyrics, and cover embedded to MP3 via FFmpeg');
      } else {
        _log.w('FFmpeg MP3 metadata/cover embed failed');
      }

      if (coverPath != null) {
        try {
          final coverFile = File(coverPath);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        } catch (e) {
          _log.w('Failed to cleanup MP3 cover file: $e');
        }
      }
    } catch (e) {
      _log.e('Failed to embed metadata to MP3: $e');
    }
  }

  Future<void> _embedMetadataToOpus(
    String opusPath,
    Track track, {
    String? genre,
    String? label,
    String? copyright,
  }) async {
    final settings = ref.read(settingsProvider);
    if (!settings.embedMetadata) {
      _log.d('Metadata embedding disabled, skipping Opus metadata/cover embed');
      return;
    }

    String? coverPath;
    var coverUrl = normalizeRemoteHttpUrl(track.coverUrl);
    if (coverUrl != null && coverUrl.isNotEmpty) {
      try {
        if (settings.maxQualityCover) {
          coverUrl = _upgradeToMaxQualityCover(coverUrl);
          _log.d('Cover URL upgraded to max quality for Opus: $coverUrl');
        }

        final tempDir = await getTemporaryDirectory();
        final uniqueId =
            '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
        coverPath = '${tempDir.path}/cover_opus_$uniqueId.jpg';

        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(coverUrl));
        final response = await request.close();
        if (response.statusCode == 200) {
          final file = File(coverPath);
          final sink = file.openWrite();
          await response.pipe(sink);
          await sink.close();
          _log.d('Cover downloaded for Opus: $coverPath');
        } else {
          _log.w(
            'Failed to download cover for Opus: HTTP ${response.statusCode}',
          );
          coverPath = null;
        }
        httpClient.close();
      } catch (e) {
        _log.e('Failed to download cover for Opus: $e');
        coverPath = null;
      }
    }

    try {
      final metadata = <String, String>{
        'TITLE': track.name,
        'ARTIST': track.artistName,
        'ALBUM': track.albumName,
      };

      final albumArtist = _resolveAlbumArtistForMetadata(track, settings);
      metadata['ALBUMARTIST'] = albumArtist;

      if (track.trackNumber != null && track.trackNumber! > 0) {
        metadata['TRACKNUMBER'] = track.trackNumber.toString();
      }

      if (track.discNumber != null && track.discNumber! > 0) {
        metadata['DISCNUMBER'] = track.discNumber.toString();
      }

      if (track.releaseDate != null) {
        metadata['DATE'] = track.releaseDate!;
      }

      if (track.isrc != null) {
        metadata['ISRC'] = track.isrc!;
      }

      if (genre != null && genre.isNotEmpty) {
        metadata['GENRE'] = genre;
        _log.d('Adding GENRE to Opus: $genre');
      }
      if (label != null && label.isNotEmpty) {
        metadata['ORGANIZATION'] = label;
        _log.d('Adding ORGANIZATION (label) to Opus: $label');
      }
      if (copyright != null && copyright.isNotEmpty) {
        metadata['COPYRIGHT'] = copyright;
        _log.d('Adding COPYRIGHT to Opus: $copyright');
      }

      _log.d('Opus Metadata map content: $metadata');

      final lyricsMode = settings.lyricsMode;
      final shouldEmbed = lyricsMode == 'embed' || lyricsMode == 'both';
      final shouldSaveExternal =
          lyricsMode == 'external' || lyricsMode == 'both';

      if (settings.embedLyrics && (shouldEmbed || shouldSaveExternal)) {
        try {
          final durationMs = track.duration * 1000;

          final lrcContent = await PlatformBridge.getLyricsLRC(
            track.id,
            track.name,
            track.artistName,
            filePath: '',
            durationMs: durationMs,
          );

          if (lrcContent.isNotEmpty) {
            if (shouldEmbed) {
              metadata['LYRICS'] = lrcContent;
              _log.d(
                'Lyrics fetched for Opus embedding (${lrcContent.length} chars)',
              );
            }

            if (shouldSaveExternal) {
              try {
                final lrcPath = opusPath.replaceAll(
                  RegExp(r'\.opus$', caseSensitive: false),
                  '.lrc',
                );
                await File(lrcPath).writeAsString(lrcContent);
                _log.d('External LRC file saved: $lrcPath');
              } catch (e) {
                _log.w('Failed to save external LRC file: $e');
              }
            }
          }
        } catch (e) {
          _log.w('Failed to fetch lyrics for Opus: $e');
        }
      }

      _log.d('Embedding tags to Opus: $metadata');

      // ReplayGain: scan loudness and add to metadata before FFmpeg embed.
      if (settings.embedReplayGain) {
        try {
          final rgResult = await FFmpegService.scanReplayGain(opusPath);
          if (rgResult != null) {
            metadata['REPLAYGAIN_TRACK_GAIN'] = rgResult.trackGain;
            metadata['REPLAYGAIN_TRACK_PEAK'] = rgResult.trackPeak;
            _log.d(
              'ReplayGain added to Opus metadata: gain=${rgResult.trackGain}, peak=${rgResult.trackPeak}',
            );
            // Store for album gain computation after all album tracks complete.
            _storeTrackReplayGainForAlbum(track, opusPath, rgResult);
          }
        } catch (e) {
          _log.w('Failed to scan ReplayGain for Opus: $e');
        }
      }

      final result = await FFmpegService.embedMetadataToOpus(
        opusPath: opusPath,
        coverPath: coverPath != null && await File(coverPath).exists()
            ? coverPath
            : null,
        metadata: metadata,
        artistTagMode: settings.artistTagMode,
      );

      if (result != null) {
        _log.d('Metadata, lyrics, and cover embedded to Opus via FFmpeg');
      } else {
        _log.w('FFmpeg Opus metadata/cover embed failed');
      }

      if (coverPath != null) {
        try {
          final coverFile = File(coverPath);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        } catch (e) {
          _log.w('Failed to cleanup Opus cover file: $e');
        }
      }
    } catch (e) {
      _log.e('Failed to embed metadata to Opus: $e');
    }
  }

  Future<String?> _copySafToTemp(String uri) async {
    try {
      return await PlatformBridge.copyContentUriToTemp(uri);
    } catch (e) {
      _log.w('Failed to copy SAF uri to temp: $e');
      return null;
    }
  }

  Future<String?> _writeTempToSaf({
    required String treeUri,
    required String relativeDir,
    required String fileName,
    required String mimeType,
    required String srcPath,
  }) async {
    try {
      return await PlatformBridge.createSafFileFromPath(
        treeUri: treeUri,
        relativeDir: relativeDir,
        fileName: fileName,
        mimeType: mimeType,
        srcPath: srcPath,
      );
    } catch (e) {
      _log.w('Failed to write temp file to SAF: $e');
      return null;
    }
  }

  Future<void> _writeLrcToSaf({
    required String treeUri,
    required String relativeDir,
    required String baseName,
    required String lrcContent,
  }) async {
    try {
      if (lrcContent.isEmpty) return;
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$baseName.lrc';
      await File(tempPath).writeAsString(lrcContent);
      final lrcName = '$baseName.lrc';
      final uri = await _writeTempToSaf(
        treeUri: treeUri,
        relativeDir: relativeDir,
        fileName: lrcName,
        mimeType: _mimeTypeForExt('.lrc'),
        srcPath: tempPath,
      );
      if (uri != null) {
        _log.d('External LRC saved to SAF: $lrcName');
      } else {
        _log.w('Failed to write external LRC to SAF');
      }
      try {
        await File(tempPath).delete();
      } catch (_) {}
    } catch (e) {
      _log.w('Failed to create external LRC in SAF: $e');
    }
  }

  Future<void> _deleteSafFile(String uri) async {
    try {
      await PlatformBridge.safDelete(uri);
    } catch (e) {
      _log.w('Failed to delete SAF file: $e');
    }
  }

  Future<void> _processQueue() async {
    if (state.isProcessing) return;

    final settings = ref.read(settingsProvider);
    updateSettings(settings);
    final isSafMode = _isSafMode(settings);
    if (settings.downloadNetworkMode == 'wifi_only') {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasWifi = connectivityResult.contains(ConnectivityResult.wifi);
      if (!hasWifi) {
        _log.w('WiFi-only mode enabled but no WiFi connection. Queue paused.');
        state = state.copyWith(isProcessing: false, isPaused: true);
        return;
      }
    }

    state = state.copyWith(isProcessing: true);
    _log.i('Starting queue processing...');

    _totalQueuedAtStart = state.items
        .where((i) => i.status == DownloadStatus.queued)
        .length;
    _completedInSession = 0;
    _failedInSession = 0;

    if (Platform.isAndroid && _totalQueuedAtStart > 0) {
      final firstItem = state.items.firstWhere(
        (item) => item.status == DownloadStatus.queued,
        orElse: () => state.items.first,
      );
      try {
        await PlatformBridge.startDownloadService(
          trackName: firstItem.track.name,
          artistName: firstItem.track.artistName,
          queueCount: _totalQueuedAtStart,
        );
        _log.d('Foreground service started');
      } catch (e) {
        _log.e('Failed to start foreground service: $e');
      }
    }

    if (!isSafMode && state.outputDir.isEmpty) {
      _log.d('Output dir empty, initializing...');
      await _initOutputDir();
    }

    // iOS: Validate that outputDir is writable (not iCloud Drive which Go can't access)
    if (!isSafMode && Platform.isIOS && state.outputDir.isNotEmpty) {
      final isICloudPath =
          state.outputDir.contains('Mobile Documents') ||
          state.outputDir.contains('CloudDocs') ||
          state.outputDir.contains('com~apple~CloudDocs');
      if (isICloudPath) {
        _log.w(
          'iOS: iCloud Drive path detected, falling back to app Documents folder',
        );
        _log.w('Go backend cannot write to iCloud Drive due to iOS sandboxing');
        final musicDir = await _ensureDefaultDocumentsOutputDir();
        state = state.copyWith(outputDir: musicDir.path);
        ref.read(settingsProvider.notifier).setDownloadDirectory(musicDir.path);
      } else if (!isValidIosWritablePath(state.outputDir)) {
        _log.w(
          'iOS: Invalid output path detected (container root?), falling back to app Documents folder',
        );
        _log.w('Original path: ${state.outputDir}');
        final correctedPath = await validateOrFixIosPath(state.outputDir);
        _log.i('Corrected path: $correctedPath');
        state = state.copyWith(outputDir: correctedPath);
        ref.read(settingsProvider.notifier).setDownloadDirectory(correctedPath);
      }
    }

    if (!isSafMode && state.outputDir.isEmpty) {
      _log.d('Using fallback directory...');
      final musicDir = await _ensureDefaultDocumentsOutputDir();
      state = state.copyWith(outputDir: musicDir.path);
    }

    if (!isSafMode) {
      _log.d('Output directory: ${state.outputDir}');
    } else {
      _log.d('Output directory: SAF (tree_uri=${settings.downloadTreeUri})');
      try {
        final testResult = await PlatformBridge.createSafFileFromPath(
          treeUri: settings.downloadTreeUri,
          relativeDir: '',
          fileName: '.spotiflac_test',
          mimeType: 'application/octet-stream',
          srcPath: '',
        );
        if (testResult != null) {
          await PlatformBridge.safDelete(testResult);
        }
      } catch (e) {
        _log.e('SAF permission validation failed: $e');
        _log.w('SAF tree URI may be invalid or permission revoked');
        for (final item in state.items) {
          if (item.status == DownloadStatus.queued) {
            updateItemStatus(
              item.id,
              DownloadStatus.failed,
              error:
                  'SAF permission invalid or revoked. Please reconfigure download location in Settings.',
            );
          }
        }
        state = state.copyWith(isProcessing: false);
        return;
      }
    }
    _log.d('Concurrent downloads: ${state.concurrentDownloads}');
    await _processQueueParallel();
    final stoppedWhilePaused = state.isPaused;

    _stopProgressPolling();

    if (Platform.isAndroid) {
      try {
        await PlatformBridge.stopDownloadService();
        _log.d('Foreground service stopped');
      } catch (e) {
        _log.e('Failed to stop foreground service: $e');
      }
    }

    if (_downloadCount > 0) {
      _log.d('Final connection cleanup...');
      try {
        await PlatformBridge.cleanupConnections();
      } catch (e) {
        _log.e('Final cleanup failed: $e');
      }
      _downloadCount = 0;
    }

    _log.i(
      'Queue stats - completed: $_completedInSession, failed: $_failedInSession, totalAtStart: $_totalQueuedAtStart',
    );
    if (!stoppedWhilePaused && _totalQueuedAtStart > 0) {
      await _notificationService.showQueueComplete(
        completedCount: _completedInSession,
        failedCount: _failedInSession,
      );

      final settings = ref.read(settingsProvider);
      if (settings.autoExportFailedDownloads && _failedInSession > 0) {
        final exportPath = await exportFailedDownloads();
        if (exportPath != null) {
          _log.i('Auto-exported failed downloads to: $exportPath');
        }
      }
    }

    if (stoppedWhilePaused) {
      _log.i('Queue processing paused');
    } else {
      _log.i('Queue processing finished');
    }
    state = state.copyWith(isProcessing: false, currentDownload: null);

    final hasQueuedItems = state.items.any(
      (item) => item.status == DownloadStatus.queued,
    );
    if (hasQueuedItems && !state.isPaused) {
      _log.i(
        'Found queued items after processing finished, restarting queue...',
      );
      Future.microtask(() => _processQueue());
    }
  }

  Future<void> _processQueueParallel() async {
    final activeDownloads = <String, Future<void>>{};
    var lastLoggedMaxConcurrent = -1;

    _startMultiProgressPolling();

    while (true) {
      if (state.isPaused) {
        if (activeDownloads.isEmpty) {
          _log.d('Queue is paused and no active downloads remain');
          break;
        }
        _log.d('Queue is paused, waiting for active downloads...');
        await Future.any([
          Future.wait(activeDownloads.values),
          Future<void>.delayed(_queueSchedulingInterval),
        ]);
        continue;
      }

      final maxConcurrent = max(1, state.concurrentDownloads);
      if (lastLoggedMaxConcurrent != maxConcurrent) {
        _log.d('Parallel worker max concurrency now: $maxConcurrent');
        lastLoggedMaxConcurrent = maxConcurrent;
      }

      final queuedItems = state.items
          .where(
            (item) =>
                item.status == DownloadStatus.queued &&
                !_pausePendingItemIds.contains(item.id),
          )
          .toList();

      if (queuedItems.isEmpty && activeDownloads.isEmpty) {
        _log.d('No more items to process');
        break;
      }

      while (activeDownloads.length < maxConcurrent &&
          queuedItems.isNotEmpty &&
          !state.isPaused) {
        final item = queuedItems.removeAt(0);

        updateItemStatus(item.id, DownloadStatus.downloading);

        final future = _downloadSingleItem(item).whenComplete(() {
          activeDownloads.remove(item.id);
          PlatformBridge.clearItemProgress(item.id).catchError((_) {});
        });

        activeDownloads[item.id] = future;
        _log.d(
          'Started parallel download: ${item.track.name} (${activeDownloads.length}/$maxConcurrent active)',
        );
      }

      if (activeDownloads.isNotEmpty) {
        await Future.any([
          Future.any(activeDownloads.values),
          Future<void>.delayed(_queueSchedulingInterval),
        ]);
      } else {
        await Future<void>.delayed(_queueSchedulingInterval);
      }
    }

    if (activeDownloads.isNotEmpty) {
      await Future.wait(activeDownloads.values);
    }

    _stopProgressPolling();
    final remainingIds = state.items.map((item) => item.id).toSet();
    _locallyCancelledItemIds.removeWhere((id) => !remainingIds.contains(id));
    _pausePendingItemIds.removeWhere((id) => !remainingIds.contains(id));
  }

  Future<void> _downloadSingleItem(DownloadItem item) async {
    _log.d('Processing: ${item.track.name} by ${item.track.artistName}');
    _log.d('Cover URL: ${item.track.coverUrl}');
    var pausedDuringThisRun = false;

    final currentItem = _findItemById(item.id) ?? item;
    if (_isLocallyCancelled(item.id, item: currentItem)) {
      _log.i('Download was cancelled before start, skipping');
      return;
    }

    if (_isPausePending(item.id)) {
      pausedDuringThisRun = true;
      _requeueItemForPause(item.id);
      _log.i('Download is pause-pending before start, skipping');
      return;
    }

    state = state.copyWith(currentDownload: item);

    updateItemStatus(item.id, DownloadStatus.downloading);

    try {
      bool shouldAbortWork(String stage) {
        final current = _findItemById(item.id);
        if (_isLocallyCancelled(item.id, item: current)) {
          _log.i('Download was cancelled $stage, skipping');
          return true;
        }
        if (_isPausePending(item.id)) {
          pausedDuringThisRun = true;
          _requeueItemForPause(item.id);
          _log.i('Download pause requested $stage, re-queueing');
          return true;
        }
        return false;
      }

      final settings = ref.read(settingsProvider);
      final metadataEmbeddingEnabled = settings.embedMetadata;

      Track trackToDownload = item.track;
      final needsEnrichment =
          trackToDownload.id.startsWith('deezer:') &&
          (trackToDownload.isrc == null ||
              trackToDownload.isrc!.isEmpty ||
              trackToDownload.trackNumber == null ||
              trackToDownload.trackNumber == 0);

      if (needsEnrichment) {
        try {
          _log.d(
            'Enriching incomplete metadata for Deezer track: ${trackToDownload.name}',
          );
          _log.d(
            'Current ISRC: ${trackToDownload.isrc}, TrackNumber: ${trackToDownload.trackNumber}',
          );
          final rawId = trackToDownload.id.split(':')[1];
          _log.d('Fetching full metadata for Deezer ID: $rawId');
          final fullData = await PlatformBridge.getDeezerMetadata(
            'track',
            rawId,
          );
          _log.d('Got response keys: ${fullData.keys.toList()}');

          if (fullData.containsKey('track')) {
            final trackData = fullData['track'];
            _log.d('Track data type: ${trackData.runtimeType}');
            if (trackData is Map<String, dynamic>) {
              final data = trackData;
              _log.d('Track data keys: ${data.keys.toList()}');
              _log.d('ISRC from API: ${data['isrc']}');
              _log.d('album_type from API: ${data['album_type']}');
              trackToDownload = Track(
                id: (data['spotify_id'] as String?) ?? trackToDownload.id,
                name: (data['name'] as String?) ?? trackToDownload.name,
                artistName:
                    (data['artists'] as String?) ?? trackToDownload.artistName,
                albumName:
                    (data['album_name'] as String?) ??
                    trackToDownload.albumName,
                albumArtist: data['album_artist'] as String?,
                artistId:
                    (data['artist_id'] ?? data['artistId'])?.toString() ??
                    trackToDownload.artistId,
                albumId:
                    data['album_id']?.toString() ?? trackToDownload.albumId,
                coverUrl: data['images'] as String?,
                duration:
                    ((data['duration_ms'] as int?) ??
                        (trackToDownload.duration * 1000)) ~/
                    1000,
                isrc: (data['isrc'] as String?) ?? trackToDownload.isrc,
                trackNumber: data['track_number'] as int?,
                discNumber: data['disc_number'] as int?,
                releaseDate: data['release_date'] as String?,
                deezerId: rawId,
                availability: trackToDownload.availability,
                albumType:
                    (data['album_type'] as String?) ??
                    trackToDownload.albumType,
                totalTracks:
                    data['total_tracks'] as int? ?? trackToDownload.totalTracks,
                source: trackToDownload.source,
              );
              _log.d(
                'Metadata enriched: Track ${trackToDownload.trackNumber}, Disc ${trackToDownload.discNumber}, ISRC ${trackToDownload.isrc}, AlbumType ${trackToDownload.albumType}',
              );
            } else {
              _log.w('Unexpected track data type: ${trackData.runtimeType}');
            }
          } else {
            _log.w('Response does not contain track key');
          }
        } catch (e, stack) {
          _log.w('Failed to enrich metadata: $e');
          _log.w('Stack trace: $stack');
        }

        if (shouldAbortWork('during metadata enrichment')) {
          return;
        }
      }

      _log.d('Track coverUrl after enrichment: ${trackToDownload.coverUrl}');

      final resolvedAlbumArtist = _resolveAlbumArtistForMetadata(
        trackToDownload,
        settings,
      );

      var quality = item.qualityOverride ?? state.audioQuality;
      if (quality == 'DEFAULT') quality = state.audioQuality;
      final isSafMode = _isSafMode(settings);
      final relativeOutputDir = isSafMode
          ? await _buildRelativeOutputDir(
              trackToDownload,
              settings.folderOrganization,
              separateSingles: settings.separateSingles,
              albumFolderStructure: settings.albumFolderStructure,
              createPlaylistFolder: settings.createPlaylistFolder,
              useAlbumArtistForFolders: settings.useAlbumArtistForFolders,
              usePrimaryArtistOnly: settings.usePrimaryArtistOnly,
              filterContributingArtistsInAlbumArtist:
                  settings.filterContributingArtistsInAlbumArtist,
              playlistName: item.playlistName,
            )
          : '';
      String? appOutputDir;
      final initialOutputDir = isSafMode
          ? relativeOutputDir
          : await _buildOutputDir(
              trackToDownload,
              settings.folderOrganization,
              separateSingles: settings.separateSingles,
              albumFolderStructure: settings.albumFolderStructure,
              createPlaylistFolder: settings.createPlaylistFolder,
              useAlbumArtistForFolders: settings.useAlbumArtistForFolders,
              usePrimaryArtistOnly: settings.usePrimaryArtistOnly,
              filterContributingArtistsInAlbumArtist:
                  settings.filterContributingArtistsInAlbumArtist,
              playlistName: item.playlistName,
            );
      var effectiveOutputDir = initialOutputDir;
      var effectiveSafMode = isSafMode;

      String? safFileName;
      String? safBaseName;
      String safOutputExt = _determineOutputExt(quality, item.service);
      if (isSafMode) {
        final effectiveFormat = trackToDownload.isSingle
            ? state.singleFilenameFormat
            : state.filenameFormat;
        final baseName = await PlatformBridge.buildFilename(effectiveFormat, {
          'title': trackToDownload.name,
          'artist': trackToDownload.artistName,
          'album': trackToDownload.albumName,
          'track': trackToDownload.trackNumber ?? 0,
          'disc': trackToDownload.discNumber ?? 0,
          'year': _extractYear(trackToDownload.releaseDate) ?? '',
          'date': trackToDownload.releaseDate ?? '',
        });
        final sanitized = await PlatformBridge.sanitizeFilename(baseName);
        safBaseName = sanitized;
        safFileName = '$sanitized$safOutputExt';
      }
      String? finalSafFileName = safFileName;

      String? genre;
      String? label;
      String? copyright;
      final extensionState = ref.read(extensionProvider);
      final selectedExtensionDownloadProvider =
          settings.useExtensionProviders &&
          extensionState.extensions.any(
            (e) =>
                e.enabled &&
                e.hasDownloadProvider &&
                e.id.toLowerCase() == item.service.toLowerCase(),
          );
      final trackSource = (trackToDownload.source ?? '').trim().toLowerCase();
      final shouldSkipExtensionSongLinkPrelookup =
          trackSource.isNotEmpty &&
          extensionState.extensions.any(
            (e) =>
                e.enabled &&
                e.hasMetadataProvider &&
                e.id.toLowerCase() == trackSource,
          );

      String? deezerTrackId = trackToDownload.deezerId;
      if (deezerTrackId == null && trackToDownload.id.startsWith('deezer:')) {
        deezerTrackId = trackToDownload.id.split(':')[1];
      }
      if (deezerTrackId == null &&
          trackToDownload.availability?.deezerId != null) {
        deezerTrackId = trackToDownload.availability!.deezerId;
      }

      if (deezerTrackId == null &&
          trackToDownload.isrc != null &&
          trackToDownload.isrc!.isNotEmpty &&
          _isValidISRC(trackToDownload.isrc!)) {
        try {
          _log.d('No Deezer ID, searching by ISRC: ${trackToDownload.isrc}');
          final deezerResult = await PlatformBridge.searchDeezerByISRC(
            trackToDownload.isrc!,
          );
          if (deezerResult['success'] == true &&
              deezerResult['track_id'] != null) {
            deezerTrackId = deezerResult['track_id'].toString();
            _log.d('Found Deezer track ID via ISRC: $deezerTrackId');
          }
        } catch (e) {
          _log.w('Failed to search Deezer by ISRC: $e');
        }

        if (shouldAbortWork('during Deezer ISRC lookup')) {
          return;
        }
      }

      // For tidal:/qobuz: tracks without ISRC, resolve ISRC from provider
      // API directly (faster than SongLink and avoids rate limits).
      if (deezerTrackId == null &&
          (trackToDownload.isrc == null ||
              trackToDownload.isrc!.isEmpty ||
              !_isValidISRC(trackToDownload.isrc!)) &&
          (trackToDownload.id.startsWith('tidal:') ||
              trackToDownload.id.startsWith('qobuz:'))) {
        try {
          final colonIdx = trackToDownload.id.indexOf(':');
          final provider = trackToDownload.id.substring(0, colonIdx);
          final providerTrackId = trackToDownload.id.substring(colonIdx + 1);

          _log.d('No ISRC, fetching from $provider API: $providerTrackId');
          final providerData = provider == 'tidal'
              ? await PlatformBridge.getTidalMetadata('track', providerTrackId)
              : await PlatformBridge.getQobuzMetadata('track', providerTrackId);

          final trackData = providerData['track'] as Map<String, dynamic>?;
          if (trackData != null) {
            final resolvedIsrc = normalizeOptionalString(
              trackData['isrc'] as String?,
            );

            if (resolvedIsrc != null && _isValidISRC(resolvedIsrc)) {
              _log.d('Resolved ISRC from $provider: $resolvedIsrc');

              final provReleaseDate = normalizeOptionalString(
                trackData['release_date'] as String?,
              );
              final provTrackNum = trackData['track_number'] as int?;
              final provDiscNum = trackData['disc_number'] as int?;

              trackToDownload = Track(
                id: trackToDownload.id,
                name: trackToDownload.name,
                artistName: trackToDownload.artistName,
                albumName: trackToDownload.albumName,
                albumArtist: trackToDownload.albumArtist,
                artistId: trackToDownload.artistId,
                albumId: trackToDownload.albumId,
                coverUrl: normalizeCoverReference(trackToDownload.coverUrl),
                duration: trackToDownload.duration,
                isrc: resolvedIsrc,
                trackNumber:
                    (trackToDownload.trackNumber != null &&
                        trackToDownload.trackNumber! > 0)
                    ? trackToDownload.trackNumber
                    : provTrackNum,
                discNumber:
                    (trackToDownload.discNumber != null &&
                        trackToDownload.discNumber! > 0)
                    ? trackToDownload.discNumber
                    : provDiscNum,
                releaseDate: trackToDownload.releaseDate ?? provReleaseDate,
                deezerId: trackToDownload.deezerId,
                availability: trackToDownload.availability,
                albumType: trackToDownload.albumType,
                totalTracks: trackToDownload.totalTracks,
                source: trackToDownload.source,
              );

              try {
                final deezerResult = await PlatformBridge.searchDeezerByISRC(
                  resolvedIsrc,
                );
                if (deezerResult['success'] == true &&
                    deezerResult['track_id'] != null) {
                  deezerTrackId = deezerResult['track_id'].toString();
                  _log.d(
                    'Found Deezer track ID via $provider ISRC: $deezerTrackId',
                  );
                }
              } catch (e) {
                _log.w('Failed to search Deezer by $provider ISRC: $e');
              }
            }
          }
        } catch (e) {
          _log.w('Failed to resolve ISRC from provider: $e');
        }

        if (shouldAbortWork('during provider ISRC resolution')) {
          return;
        }
      }

      if (!selectedExtensionDownloadProvider &&
          deezerTrackId == null &&
          !shouldSkipExtensionSongLinkPrelookup &&
          trackToDownload.id.isNotEmpty &&
          !trackToDownload.id.startsWith('deezer:') &&
          !trackToDownload.id.startsWith('extension:') &&
          !trackToDownload.id.startsWith('tidal:') &&
          !trackToDownload.id.startsWith('qobuz:')) {
        try {
          String spotifyId = trackToDownload.id;
          if (spotifyId.startsWith('spotify:track:')) {
            spotifyId = spotifyId.split(':').last;
          }
          _log.d(
            'No Deezer ID, converting from Spotify via SongLink: $spotifyId',
          );
          final deezerData = await PlatformBridge.convertSpotifyToDeezer(
            'track',
            spotifyId,
          );
          final trackData = deezerData['track'];
          if (trackData is Map<String, dynamic>) {
            final rawId = trackData['spotify_id'] as String?;
            if (rawId != null && rawId.startsWith('deezer:')) {
              deezerTrackId = rawId.split(':')[1];
              _log.d('Found Deezer track ID via SongLink: $deezerTrackId');
            } else if (deezerData['id'] != null) {
              deezerTrackId = deezerData['id'].toString();
              _log.d(
                'Found Deezer track ID via SongLink (legacy): $deezerTrackId',
              );
            }

            // Enrich track metadata from Deezer response (release_date, isrc, etc.)
            final deezerReleaseDate = normalizeOptionalString(
              trackData['release_date'] as String?,
            );
            final deezerIsrc = normalizeOptionalString(
              trackData['isrc'] as String?,
            );
            final deezerTrackNum = trackData['track_number'] as int?;
            final deezerDiscNum = trackData['disc_number'] as int?;

            final needsEnrich =
                (trackToDownload.releaseDate == null &&
                    deezerReleaseDate != null) ||
                (trackToDownload.isrc == null && deezerIsrc != null) ||
                (!_isValidISRC(trackToDownload.isrc ?? '') &&
                    deezerIsrc != null) ||
                ((trackToDownload.trackNumber == null ||
                        trackToDownload.trackNumber! <= 0) &&
                    deezerTrackNum != null &&
                    deezerTrackNum > 0) ||
                ((trackToDownload.discNumber == null ||
                        trackToDownload.discNumber! <= 0) &&
                    deezerDiscNum != null &&
                    deezerDiscNum > 0);

            if (needsEnrich) {
              trackToDownload = Track(
                id: trackToDownload.id,
                name: trackToDownload.name,
                artistName: trackToDownload.artistName,
                albumName: trackToDownload.albumName,
                albumArtist: trackToDownload.albumArtist,
                artistId: trackToDownload.artistId,
                albumId: trackToDownload.albumId,
                coverUrl: normalizeCoverReference(trackToDownload.coverUrl),
                duration: trackToDownload.duration,
                isrc: (deezerIsrc != null && _isValidISRC(deezerIsrc))
                    ? deezerIsrc
                    : trackToDownload.isrc,
                trackNumber:
                    (trackToDownload.trackNumber != null &&
                        trackToDownload.trackNumber! > 0)
                    ? trackToDownload.trackNumber
                    : deezerTrackNum,
                discNumber:
                    (trackToDownload.discNumber != null &&
                        trackToDownload.discNumber! > 0)
                    ? trackToDownload.discNumber
                    : deezerDiscNum,
                releaseDate: trackToDownload.releaseDate ?? deezerReleaseDate,
                deezerId: deezerTrackId,
                availability: trackToDownload.availability,
                albumType: trackToDownload.albumType,
                totalTracks: trackToDownload.totalTracks,
                source: trackToDownload.source,
              );
              _log.d(
                'Enriched track from Deezer - date: ${trackToDownload.releaseDate}, ISRC: ${trackToDownload.isrc}, track: ${trackToDownload.trackNumber}, disc: ${trackToDownload.discNumber}',
              );
            }
          } else if (deezerData['id'] != null) {
            deezerTrackId = deezerData['id'].toString();
            _log.d('Found Deezer track ID via SongLink (flat): $deezerTrackId');
          }
        } catch (e) {
          _log.w('Failed to convert Spotify to Deezer via SongLink: $e');
        }

        if (shouldAbortWork('during SongLink availability lookup')) {
          return;
        }
      } else if (selectedExtensionDownloadProvider && deezerTrackId == null) {
        _log.d(
          'Skipping Flutter SongLink Deezer prelookup for extension provider: ${item.service}',
        );
      } else if (shouldSkipExtensionSongLinkPrelookup &&
          deezerTrackId == null) {
        _log.d(
          'Skipping Flutter SongLink Deezer prelookup for extension-sourced track; backend metadata enrichment will resolve identifiers first',
        );
      }

      if (deezerTrackId != null && deezerTrackId.isNotEmpty) {
        try {
          final extendedMetadata =
              await PlatformBridge.getDeezerExtendedMetadata(deezerTrackId);
          if (extendedMetadata != null) {
            genre = extendedMetadata['genre'];
            label = extendedMetadata['label'];
            copyright = extendedMetadata['copyright'];
            if (genre != null && genre.isNotEmpty) {
              _log.d(
                'Extended metadata - Genre: $genre, Label: $label, Copyright: $copyright',
              );
            }
          }
        } catch (e) {
          _log.w('Failed to fetch extended metadata from Deezer: $e');
        }

        if (shouldAbortWork('during extended metadata lookup')) {
          return;
        }
      }

      Map<String, dynamic> result;

      final hasActiveExtensions = extensionState.extensions.any(
        (e) => e.enabled,
      );
      final useExtensions =
          settings.useExtensionProviders && hasActiveExtensions;

      Future<Map<String, dynamic>> runDownload({
        required bool useSaf,
        required String outputDir,
      }) async {
        final storageMode = useSaf ? 'saf' : 'app';
        final treeUri = useSaf ? settings.downloadTreeUri : '';
        final relativeDir = useSaf ? outputDir : '';
        final fileName = useSaf ? (safFileName ?? '') : '';
        final outputExt = useSaf ? safOutputExt : '';
        final shouldUseExtensions = useExtensions;
        final shouldUseFallback = state.autoFallback;

        if (shouldUseExtensions) {
          _log.d('Using extension providers for download');
          _log.d(
            'Quality: $quality${item.qualityOverride != null ? ' (override)' : ''}',
          );
        } else if (shouldUseFallback) {
          _log.d('Using auto-fallback mode');
          _log.d(
            'Quality: $quality${item.qualityOverride != null ? ' (override)' : ''}',
          );
        }

        if (!useSaf) {
          await _ensureDirExists(outputDir, label: 'Output folder');
        }

        _log.d('Output dir: $outputDir');

        final normalizedTrackNumber =
            (trackToDownload.trackNumber != null &&
                trackToDownload.trackNumber! > 0)
            ? trackToDownload.trackNumber!
            : 0;
        final normalizedDiscNumber =
            (trackToDownload.discNumber != null &&
                trackToDownload.discNumber! > 0)
            ? trackToDownload.discNumber!
            : 0;

        String payloadSpotifyId = trackToDownload.id;
        String payloadQobuzId = '';
        String payloadTidalId = '';
        if (trackToDownload.id.startsWith('qobuz:')) {
          payloadQobuzId = trackToDownload.id.substring(6);
          if (item.service == 'qobuz') {
            payloadSpotifyId = '';
          }
        }
        if (trackToDownload.id.startsWith('tidal:')) {
          payloadTidalId = trackToDownload.id.substring(6);
          if (item.service == 'tidal') {
            payloadSpotifyId = '';
          }
        }

        final payload = DownloadRequestPayload(
          isrc: trackToDownload.isrc ?? '',
          service: item.service,
          spotifyId: payloadSpotifyId,
          trackName: trackToDownload.name,
          artistName: trackToDownload.artistName,
          albumName: trackToDownload.albumName,
          albumArtist: resolvedAlbumArtist,
          coverUrl: metadataEmbeddingEnabled
              ? (trackToDownload.coverUrl ?? '')
              : '',
          outputDir: outputDir,
          filenameFormat: trackToDownload.isSingle
              ? state.singleFilenameFormat
              : state.filenameFormat,
          quality: quality,
          embedMetadata: metadataEmbeddingEnabled,
          artistTagMode: settings.artistTagMode,
          embedLyrics: metadataEmbeddingEnabled && settings.embedLyrics,
          embedMaxQualityCover:
              metadataEmbeddingEnabled && settings.maxQualityCover,
          trackNumber: normalizedTrackNumber,
          discNumber: normalizedDiscNumber,
          releaseDate: trackToDownload.releaseDate ?? '',
          itemId: item.id,
          durationMs: trackToDownload.duration,
          source: trackToDownload.source ?? '',
          genre: genre ?? '',
          label: label ?? '',
          copyright: copyright ?? '',
          qobuzId: payloadQobuzId,
          tidalId: payloadTidalId,
          deezerId: deezerTrackId ?? '',
          lyricsMode: settings.lyricsMode,
          storageMode: storageMode,
          safTreeUri: treeUri,
          safRelativeDir: relativeDir,
          safFileName: fileName,
          safOutputExt: outputExt,
          songLinkRegion: settings.songLinkRegion,
        );

        return PlatformBridge.downloadByStrategy(
          payload: payload,
          useExtensions: shouldUseExtensions,
          useFallback: shouldUseFallback,
        );
      }

      if (shouldAbortWork('before native download start')) {
        return;
      }

      result = await runDownload(
        useSaf: effectiveSafMode,
        outputDir: effectiveOutputDir,
      );

      if (effectiveSafMode &&
          result['success'] != true &&
          _isSafWriteFailure(result)) {
        if (_isLocallyCancelled(item.id)) {
          _log.i('Download was cancelled before SAF fallback, skipping');
          return;
        }
        _log.w('SAF write failed, retrying with app-private storage');
        appOutputDir ??= await _buildOutputDir(
          trackToDownload,
          settings.folderOrganization,
          separateSingles: settings.separateSingles,
          albumFolderStructure: settings.albumFolderStructure,
          createPlaylistFolder: settings.createPlaylistFolder,
          useAlbumArtistForFolders: settings.useAlbumArtistForFolders,
          usePrimaryArtistOnly: settings.usePrimaryArtistOnly,
          filterContributingArtistsInAlbumArtist:
              settings.filterContributingArtistsInAlbumArtist,
          playlistName: item.playlistName,
        );
        final fallbackResult = await runDownload(
          useSaf: false,
          outputDir: appOutputDir,
        );
        if (fallbackResult['success'] == true) {
          effectiveSafMode = false;
          effectiveOutputDir = appOutputDir;
          finalSafFileName = null;
          result = fallbackResult;
        }
      }

      _log.d('Result: $result');

      final itemAfterResult = _findItemById(item.id);
      if (itemAfterResult == null ||
          _isLocallyCancelled(item.id, item: itemAfterResult)) {
        _log.i('Download was cancelled, skipping result processing');
        final filePath = result['file_path'] as String?;
        if (filePath != null && result['success'] == true) {
          await deleteFile(filePath);
          _log.d('Deleted cancelled download file: $filePath');
        }
        return;
      }

      if (_isPausePending(item.id)) {
        pausedDuringThisRun = true;
        final filePath = result['file_path'] as String?;
        if (filePath != null && result['success'] == true) {
          await deleteFile(filePath);
          _log.d('Deleted paused download file: $filePath');
        }
        _requeueItemForPause(item.id);
        _log.i('Download pause requested after result, re-queueing');
        return;
      }

      if (result['success'] == true) {
        var filePath = result['file_path'] as String?;
        final reportedFileName = result['file_name'] as String?;
        if (effectiveSafMode &&
            reportedFileName != null &&
            reportedFileName.isNotEmpty) {
          finalSafFileName = reportedFileName;
        }

        final wasExisting = result['already_exists'] == true;
        if (wasExisting) {
          _log.i('File already exists in library: $filePath');
        }

        _log.i('Download success, file: $filePath');

        final actualBitDepth = result['actual_bit_depth'] as int?;
        final actualSampleRate = result['actual_sample_rate'] as int?;
        String actualQuality = quality;

        if (actualBitDepth != null && actualBitDepth > 0) {
          final sampleRateKHz = actualSampleRate != null && actualSampleRate > 0
              ? (actualSampleRate / 1000).toStringAsFixed(
                  actualSampleRate % 1000 == 0 ? 0 : 1,
                )
              : '?';
          actualQuality = '$actualBitDepth-bit/${sampleRateKHz}kHz';
          _log.i('Actual quality: $actualQuality');
        }

        final actualService =
            ((result['service'] as String?)?.toLowerCase()) ??
            item.service.toLowerCase();
        final decryptionKey =
            (result['decryption_key'] as String?)?.trim() ?? '';
        trackToDownload = _buildTrackForMetadataEmbedding(
          trackToDownload,
          result,
          resolvedAlbumArtist,
        );
        _log.d(
          'Track coverUrl after download result: ${trackToDownload.coverUrl}',
        );

        if (!wasExisting && decryptionKey.isNotEmpty && filePath != null) {
          _log.i('Encrypted stream detected, decrypting via FFmpeg...');
          updateItemStatus(item.id, DownloadStatus.finalizing, progress: 0.9);

          if (effectiveSafMode && isContentUri(filePath)) {
            final currentFilePath = filePath;
            final tempPath = await _copySafToTemp(currentFilePath);
            if (tempPath == null) {
              _log.e('Failed to copy encrypted SAF file to temp for decrypt');
              updateItemStatus(
                item.id,
                DownloadStatus.failed,
                error: 'Failed to access encrypted SAF file',
                errorType: DownloadErrorType.unknown,
              );
              return;
            }

            String? decryptedTempPath;
            try {
              decryptedTempPath = await FFmpegService.decryptAudioFile(
                inputPath: tempPath,
                decryptionKey: decryptionKey,
                deleteOriginal: false,
              );
              if (decryptedTempPath == null) {
                _log.e('FFmpeg decrypt failed for SAF file');
                updateItemStatus(
                  item.id,
                  DownloadStatus.failed,
                  error: 'Failed to decrypt encrypted stream',
                  errorType: DownloadErrorType.unknown,
                );
                return;
              }

              final dotIndex = decryptedTempPath.lastIndexOf('.');
              final decryptedExt = dotIndex >= 0
                  ? decryptedTempPath.substring(dotIndex).toLowerCase()
                  : '.flac';
              final allowedExt = <String>{'.flac', '.m4a', '.mp3', '.opus'};
              final finalExt = allowedExt.contains(decryptedExt)
                  ? decryptedExt
                  : '.flac';

              final newFileName = '${safBaseName ?? 'track'}$finalExt';
              final newUri = await _writeTempToSaf(
                treeUri: settings.downloadTreeUri,
                relativeDir: effectiveOutputDir,
                fileName: newFileName,
                mimeType: _mimeTypeForExt(finalExt),
                srcPath: decryptedTempPath,
              );

              if (newUri == null) {
                _log.e('Failed to write decrypted stream back to SAF');
                updateItemStatus(
                  item.id,
                  DownloadStatus.failed,
                  error: 'Failed to write decrypted file to storage',
                  errorType: DownloadErrorType.unknown,
                );
                return;
              }

              if (newUri != currentFilePath) {
                await _deleteSafFile(currentFilePath);
              }
              filePath = newUri;
              finalSafFileName = newFileName;
              _log.i('SAF decryption completed');
            } finally {
              try {
                await File(tempPath).delete();
              } catch (_) {}
              if (decryptedTempPath != null && decryptedTempPath != tempPath) {
                try {
                  await File(decryptedTempPath).delete();
                } catch (_) {}
              }
            }
          } else {
            final decryptedPath = await FFmpegService.decryptAudioFile(
              inputPath: filePath,
              decryptionKey: decryptionKey,
              deleteOriginal: true,
            );
            if (decryptedPath == null) {
              _log.e('FFmpeg decrypt failed for local file');
              updateItemStatus(
                item.id,
                DownloadStatus.failed,
                error: 'Failed to decrypt encrypted stream',
                errorType: DownloadErrorType.unknown,
              );
              try {
                await deleteFile(filePath);
              } catch (_) {}
              return;
            }
            filePath = decryptedPath;
            _log.i('Local decryption completed');
          }
        }

        final isContentUriPath = filePath != null && isContentUri(filePath);
        final mimeType = isContentUriPath
            ? await _getSafMimeType(filePath)
            : null;
        final isM4aFile =
            filePath != null &&
            (filePath.endsWith('.m4a') ||
                (mimeType != null && mimeType.contains('mp4')));
        final isFlacFile =
            filePath != null &&
            (filePath.endsWith('.flac') ||
                (mimeType != null && mimeType.contains('flac')));
        final shouldForceTidalSafM4aHandling =
            !wasExisting &&
            isContentUriPath &&
            effectiveSafMode &&
            actualService == 'tidal' &&
            filePath.endsWith('.flac') &&
            (mimeType == null || mimeType.contains('flac'));

        if (shouldForceTidalSafM4aHandling) {
          _log.w(
            'Tidal SAF file is labeled FLAC but backend returned DASH/M4A stream; forcing FFmpeg conversion to FLAC.',
          );
        }

        if (isM4aFile || shouldForceTidalSafM4aHandling) {
          final currentFilePath = filePath;

          if (isContentUriPath && effectiveSafMode) {
            if (quality == 'HIGH') {
              final tidalHighFormat = settings.tidalHighFormat;
              _log.i(
                'Tidal HIGH quality (SAF), converting M4A to $tidalHighFormat...',
              );

              final tempPath = await _copySafToTemp(currentFilePath);
              if (tempPath != null) {
                String? convertedPath;
                try {
                  updateItemStatus(
                    item.id,
                    DownloadStatus.finalizing,
                    progress: 0.95,
                  );

                  final format = tidalHighFormat.startsWith('opus')
                      ? 'opus'
                      : 'mp3';
                  convertedPath = await FFmpegService.convertM4aToLossy(
                    tempPath,
                    format: format,
                    bitrate: tidalHighFormat,
                    deleteOriginal: false,
                  );

                  if (convertedPath != null) {
                    _log.i(
                      'Successfully converted M4A to $format (temp): $convertedPath',
                    );
                    _log.i('Embedding metadata to $format...');
                    updateItemStatus(
                      item.id,
                      DownloadStatus.finalizing,
                      progress: 0.99,
                    );

                    final backendGenre = result['genre'] as String?;
                    final backendLabel = result['label'] as String?;
                    final backendCopyright = result['copyright'] as String?;

                    if (format == 'mp3') {
                      await _embedMetadataToMp3(
                        convertedPath,
                        trackToDownload,
                        genre: backendGenre ?? genre,
                        label: backendLabel ?? label,
                        copyright: backendCopyright,
                      );
                    } else {
                      await _embedMetadataToOpus(
                        convertedPath,
                        trackToDownload,
                        genre: backendGenre ?? genre,
                        label: backendLabel ?? label,
                        copyright: backendCopyright,
                      );
                    }

                    final newExt = format == 'opus' ? '.opus' : '.mp3';
                    final newFileName = '${safBaseName ?? 'track'}$newExt';
                    final newUri = await _writeTempToSaf(
                      treeUri: settings.downloadTreeUri,
                      relativeDir: effectiveOutputDir,
                      fileName: newFileName,
                      mimeType: _mimeTypeForExt(newExt),
                      srcPath: convertedPath,
                    );

                    if (newUri != null) {
                      if (newUri != currentFilePath) {
                        await _deleteSafFile(currentFilePath);
                      }
                      filePath = newUri;
                      finalSafFileName = newFileName;
                      final bitrateDisplay = tidalHighFormat.contains('_')
                          ? '${tidalHighFormat.split('_').last}kbps'
                          : '320kbps';
                      actualQuality = '${format.toUpperCase()} $bitrateDisplay';
                    } else {
                      _log.w(
                        'Failed to write converted $format to SAF, keeping M4A',
                      );
                      actualQuality = 'AAC 320kbps';
                    }
                  } else {
                    _log.w(
                      'M4A to $format conversion failed, keeping M4A file',
                    );
                    actualQuality = 'AAC 320kbps';
                  }
                } catch (e) {
                  _log.w('SAF M4A conversion failed: $e');
                  actualQuality = 'AAC 320kbps';
                } finally {
                  try {
                    await File(tempPath).delete();
                  } catch (_) {}
                  if (convertedPath != null) {
                    try {
                      await File(convertedPath).delete();
                    } catch (_) {}
                  }
                }
              }
            } else {
              _log.d('M4A file detected (SAF), converting to FLAC...');
              final tempPath = await _copySafToTemp(currentFilePath);
              if (tempPath != null) {
                String? flacPath;
                try {
                  final length = await File(tempPath).length();
                  if (length < 1024) {
                    _log.w('Temp M4A is too small (<1KB), skipping conversion');
                  } else {
                    updateItemStatus(
                      item.id,
                      DownloadStatus.finalizing,
                      progress: 0.95,
                    );
                    flacPath = await FFmpegService.convertM4aToFlac(tempPath);
                    if (flacPath != null) {
                      _log.d('Converted to FLAC (temp): $flacPath');
                      _log.d(
                        'Embedding metadata and cover to converted FLAC...',
                      );
                      final finalTrack = _buildTrackForMetadataEmbedding(
                        trackToDownload,
                        result,
                        resolvedAlbumArtist,
                      );

                      final backendGenre = result['genre'] as String?;
                      final backendLabel = result['label'] as String?;
                      final backendCopyright = result['copyright'] as String?;

                      await _embedMetadataAndCover(
                        flacPath,
                        finalTrack,
                        genre: backendGenre ?? genre,
                        label: backendLabel ?? label,
                        copyright: backendCopyright,
                        writeExternalLrc: false,
                      );

                      final newFileName = '${safBaseName ?? 'track'}.flac';
                      final newUri = await _writeTempToSaf(
                        treeUri: settings.downloadTreeUri,
                        relativeDir: effectiveOutputDir,
                        fileName: newFileName,
                        mimeType: _mimeTypeForExt('.flac'),
                        srcPath: flacPath,
                      );

                      if (newUri != null) {
                        if (newUri != currentFilePath) {
                          await _deleteSafFile(currentFilePath);
                        }
                        filePath = newUri;
                        finalSafFileName = newFileName;
                      } else {
                        _log.w('Failed to write FLAC to SAF, keeping M4A');
                      }
                    } else {
                      _log.w(
                        'FFmpeg conversion returned null, keeping M4A file',
                      );
                    }
                  }
                } catch (e) {
                  _log.w('SAF M4A->FLAC conversion failed: $e');
                } finally {
                  try {
                    await File(tempPath).delete();
                  } catch (_) {}
                  if (flacPath != null) {
                    try {
                      await File(flacPath).delete();
                    } catch (_) {}
                  }
                }
              }
            }
          } else {
            if (quality == 'HIGH') {
              final tidalHighFormat = settings.tidalHighFormat;
              _log.i(
                'Tidal HIGH quality download, converting M4A to $tidalHighFormat...',
              );

              try {
                updateItemStatus(
                  item.id,
                  DownloadStatus.finalizing,
                  progress: 0.95,
                );

                final format = tidalHighFormat.startsWith('opus')
                    ? 'opus'
                    : 'mp3';
                final convertedPath = await FFmpegService.convertM4aToLossy(
                  currentFilePath,
                  format: format,
                  bitrate: tidalHighFormat,
                  deleteOriginal: true,
                );

                if (convertedPath != null) {
                  filePath = convertedPath;
                  final bitrateDisplay = tidalHighFormat.contains('_')
                      ? '${tidalHighFormat.split('_').last}kbps'
                      : '320kbps';
                  actualQuality = '${format.toUpperCase()} $bitrateDisplay';
                  _log.i(
                    'Successfully converted M4A to $format: $convertedPath',
                  );

                  _log.i('Embedding metadata to $format...');
                  updateItemStatus(
                    item.id,
                    DownloadStatus.finalizing,
                    progress: 0.99,
                  );

                  final backendGenre = result['genre'] as String?;
                  final backendLabel = result['label'] as String?;
                  final backendCopyright = result['copyright'] as String?;

                  if (format == 'mp3') {
                    await _embedMetadataToMp3(
                      convertedPath,
                      trackToDownload,
                      genre: backendGenre ?? genre,
                      label: backendLabel ?? label,
                      copyright: backendCopyright,
                    );
                  } else {
                    await _embedMetadataToOpus(
                      convertedPath,
                      trackToDownload,
                      genre: backendGenre ?? genre,
                      label: backendLabel ?? label,
                      copyright: backendCopyright,
                    );
                  }
                  _log.d('Metadata embedded successfully');
                } else {
                  _log.w('M4A to $format conversion failed, keeping M4A file');
                  actualQuality = 'AAC 320kbps';
                }
              } catch (e) {
                _log.w('M4A conversion process failed: $e, keeping M4A file');
                actualQuality = 'AAC 320kbps';
              }
            } else {
              _log.d(
                'M4A file detected (Hi-Res DASH stream), attempting conversion to FLAC...',
              );

              try {
                final file = File(currentFilePath);
                if (!await file.exists()) {
                  _log.e('File does not exist at path: $filePath');
                } else {
                  final length = await file.length();
                  _log.i('File size before conversion: ${length / 1024} KB');

                  if (length < 1024) {
                    _log.w(
                      'File is too small (<1KB), skipping conversion. Download might be corrupt.',
                    );
                  } else {
                    updateItemStatus(
                      item.id,
                      DownloadStatus.finalizing,
                      progress: 0.95,
                    );
                    final flacPath = await FFmpegService.convertM4aToFlac(
                      currentFilePath,
                    );

                    if (flacPath != null) {
                      filePath = flacPath;
                      _log.d('Converted to FLAC: $flacPath');

                      _log.d(
                        'Embedding metadata and cover to converted FLAC...',
                      );
                      try {
                        final finalTrack = _buildTrackForMetadataEmbedding(
                          trackToDownload,
                          result,
                          resolvedAlbumArtist,
                        );

                        final backendGenre = result['genre'] as String?;
                        final backendLabel = result['label'] as String?;
                        final backendCopyright = result['copyright'] as String?;

                        if (backendGenre != null ||
                            backendLabel != null ||
                            backendCopyright != null) {
                          _log.d(
                            'Extended metadata from backend - Genre: $backendGenre, Label: $backendLabel, Copyright: $backendCopyright',
                          );
                        }

                        await _embedMetadataAndCover(
                          flacPath,
                          finalTrack,
                          genre: backendGenre ?? genre,
                          label: backendLabel ?? label,
                          copyright: backendCopyright,
                        );
                        _log.d('Metadata and cover embedded successfully');
                      } catch (e) {
                        _log.w('Warning: Failed to embed metadata/cover: $e');
                      }
                    } else {
                      _log.w(
                        'FFmpeg conversion returned null, keeping M4A file',
                      );
                    }
                  }
                }
              } catch (e) {
                _log.w(
                  'FFmpeg conversion process failed: $e, keeping M4A file',
                );
              }
            }
          }
        } else if (metadataEmbeddingEnabled &&
            isContentUriPath &&
            effectiveSafMode &&
            !isM4aFile &&
            !wasExisting) {
          final currentFilePath = filePath;
          final isOpusFile = filePath.endsWith('.opus');
          final isMp3File = filePath.endsWith('.mp3');
          final ext = isOpusFile
              ? '.opus'
              : isMp3File
              ? '.mp3'
              : '.flac';
          final formatName = isOpusFile
              ? 'Opus'
              : isMp3File
              ? 'MP3'
              : 'FLAC';
          _log.d(
            'SAF $formatName detected, embedding metadata and cover via temp file...',
          );
          final tempPath = await _copySafToTemp(currentFilePath);
          if (tempPath != null) {
            try {
              updateItemStatus(
                item.id,
                DownloadStatus.finalizing,
                progress: 0.99,
              );

              final finalTrack = _buildTrackForMetadataEmbedding(
                trackToDownload,
                result,
                resolvedAlbumArtist,
              );
              final backendGenre = result['genre'] as String?;
              final backendLabel = result['label'] as String?;
              final backendCopyright = result['copyright'] as String?;

              if (isMp3File) {
                await _embedMetadataToMp3(
                  tempPath,
                  finalTrack,
                  genre: backendGenre ?? genre,
                  label: backendLabel ?? label,
                  copyright: backendCopyright,
                );
              } else if (isOpusFile) {
                await _embedMetadataToOpus(
                  tempPath,
                  finalTrack,
                  genre: backendGenre ?? genre,
                  label: backendLabel ?? label,
                  copyright: backendCopyright,
                );
              } else {
                await _embedMetadataAndCover(
                  tempPath,
                  finalTrack,
                  genre: backendGenre ?? genre,
                  label: backendLabel ?? label,
                  copyright: backendCopyright,
                  writeExternalLrc: false,
                );
              }

              final newFileName = '${safBaseName ?? 'track'}$ext';
              final newUri = await _writeTempToSaf(
                treeUri: settings.downloadTreeUri,
                relativeDir: effectiveOutputDir,
                fileName: newFileName,
                mimeType: _mimeTypeForExt(ext),
                srcPath: tempPath,
              );

              if (newUri != null) {
                if (newUri != currentFilePath) {
                  await _deleteSafFile(currentFilePath);
                }
                filePath = newUri;
                finalSafFileName = newFileName;
                _log.d('SAF $formatName metadata embedding completed');
              } else {
                _log.w(
                  'Failed to write metadata-updated $formatName back to SAF',
                );
              }
            } catch (e) {
              _log.w('SAF $formatName metadata embedding failed: $e');
            } finally {
              try {
                await File(tempPath).delete();
              } catch (_) {}
            }
          }
        } else if (metadataEmbeddingEnabled &&
            !isContentUriPath &&
            !effectiveSafMode &&
            isFlacFile &&
            !wasExisting &&
            decryptionKey.isNotEmpty) {
          _log.d(
            'Local FLAC after decrypt detected, embedding metadata and cover...',
          );
          try {
            updateItemStatus(
              item.id,
              DownloadStatus.finalizing,
              progress: 0.99,
            );

            final finalTrack = _buildTrackForMetadataEmbedding(
              trackToDownload,
              result,
              resolvedAlbumArtist,
            );
            final backendGenre = result['genre'] as String?;
            final backendLabel = result['label'] as String?;
            final backendCopyright = result['copyright'] as String?;

            await _embedMetadataAndCover(
              filePath,
              finalTrack,
              genre: backendGenre ?? genre,
              label: backendLabel ?? label,
              copyright: backendCopyright,
            );
            _log.d('Local FLAC metadata embedding completed');
          } catch (e) {
            _log.w('Local FLAC metadata embedding failed: $e');
          }
        }

        final itemAfterDownload = _findItemById(item.id);
        if (itemAfterDownload == null ||
            _isLocallyCancelled(item.id, item: itemAfterDownload)) {
          _log.i('Download was cancelled during finalization, cleaning up');
          if (filePath != null) {
            await deleteFile(filePath);
            _log.d('Deleted cancelled download file: $filePath');
          }
          return;
        }

        if (_isPausePending(item.id)) {
          pausedDuringThisRun = true;
          if (filePath != null) {
            await deleteFile(filePath);
            _log.d(
              'Deleted paused download file during finalization: $filePath',
            );
          }
          _requeueItemForPause(item.id);
          _log.i('Download pause requested during finalization, re-queueing');
          return;
        }

        if (effectiveSafMode &&
            filePath != null &&
            filePath.isNotEmpty &&
            !isContentUri(filePath) &&
            settings.downloadTreeUri.isNotEmpty) {
          final fallbackName = (finalSafFileName ?? safFileName ?? '').trim();
          if (fallbackName.isNotEmpty) {
            try {
              final resolved = await PlatformBridge.resolveSafFile(
                treeUri: settings.downloadTreeUri,
                relativeDir: effectiveOutputDir,
                fileName: fallbackName,
              );
              final resolvedUri = (resolved['uri'] as String? ?? '').trim();
              final resolvedRelativeDir =
                  (resolved['relative_dir'] as String? ?? '').trim();
              if (resolvedUri.isNotEmpty && isContentUri(resolvedUri)) {
                _log.w('Recovered SAF URI from transient path: $filePath');
                filePath = resolvedUri;
                finalSafFileName = fallbackName;
                if (resolvedRelativeDir.isNotEmpty) {
                  effectiveOutputDir = resolvedRelativeDir;
                }
              } else {
                _log.w(
                  'Failed to recover SAF URI (fileName=$fallbackName, dir=$effectiveOutputDir)',
                );
              }
            } catch (e) {
              _log.w('SAF URI recovery failed: $e');
            }
          } else {
            _log.w(
              'SAF download returned non-URI path without filename metadata: $filePath',
            );
          }
        }

        updateItemStatus(
          item.id,
          DownloadStatus.completed,
          progress: 1.0,
          filePath: filePath,
        );

        final lyricsMode = settings.lyricsMode;
        final shouldSaveExternalLrc =
            metadataEmbeddingEnabled &&
            settings.embedLyrics &&
            (lyricsMode == 'external' || lyricsMode == 'both');
        if (shouldSaveExternalLrc &&
            effectiveSafMode &&
            filePath != null &&
            isContentUri(filePath)) {
          String? lrcContent = result['lyrics_lrc'] as String?;
          if (lrcContent == null || lrcContent.isEmpty) {
            try {
              lrcContent = await PlatformBridge.getLyricsLRC(
                trackToDownload.id,
                trackToDownload.name,
                trackToDownload.artistName,
                durationMs: trackToDownload.duration * 1000,
              );
            } catch (e) {
              _log.w('Failed to fetch lyrics for external LRC: $e');
            }
          }

          if (lrcContent != null && lrcContent.isNotEmpty) {
            final baseName = finalSafFileName != null
                ? finalSafFileName.replaceFirst(RegExp(r'\.[^.]+$'), '')
                : safBaseName ??
                      await PlatformBridge.sanitizeFilename(
                        '${trackToDownload.artistName} - ${trackToDownload.name}',
                      );
            await _writeLrcToSaf(
              treeUri: settings.downloadTreeUri,
              relativeDir: effectiveOutputDir,
              baseName: baseName,
              lrcContent: lrcContent,
            );
          }
        }

        if (filePath != null) {
          await _runPostProcessingHooks(filePath, trackToDownload);
        }

        // Album ReplayGain: update the accumulator path to the final file
        // location.  For SAF downloads the metadata was embedded on a temp
        // copy, so the stored path still points there.  Replace it with the
        // actual output path (SAF content URI or local path) so the later
        // album-gain writer targets the correct file.
        if (filePath != null) {
          _updateAlbumRgFilePath(trackToDownload, filePath);
        }

        // Album ReplayGain: check if all album tracks are now complete and,
        // if so, compute and write album gain/peak to every track file.
        try {
          await _checkAndWriteAlbumReplayGain(trackToDownload);
        } catch (e) {
          _log.w('Album ReplayGain check failed: $e');
        }

        _completedInSession++;

        final historyNotifier = ref.read(downloadHistoryProvider.notifier);
        final existingInHistory =
            historyNotifier.getBySpotifyId(trackToDownload.id) ??
            (trackToDownload.isrc != null
                ? historyNotifier.getByIsrc(trackToDownload.isrc!)
                : null);

        if (wasExisting && existingInHistory != null) {
          _log.i('Track already in library, skipping history update');
          await _notificationService.showDownloadComplete(
            trackName: item.track.name,
            artistName: item.track.artistName,
            completedCount: _completedInSession,
            totalCount: _totalQueuedAtStart,
            alreadyInLibrary: true,
          );
          removeItem(item.id);
          return;
        }

        await _notificationService.showDownloadComplete(
          trackName: item.track.name,
          artistName: item.track.artistName,
          completedCount: _completedInSession,
          totalCount: _totalQueuedAtStart,
          alreadyInLibrary: wasExisting,
        );

        if (filePath != null) {
          final backendTitle = result['title'] as String?;
          final backendArtist = result['artist'] as String?;
          final backendAlbum = result['album'] as String?;
          final backendYear = result['release_date'] as String?;
          final backendTrackNum = result['track_number'] as int?;
          final backendDiscNum = result['disc_number'] as int?;
          final backendBitDepth = result['actual_bit_depth'] as int?;
          final backendSampleRate = result['actual_sample_rate'] as int?;
          final backendISRC = result['isrc'] as String?;
          final backendGenre = result['genre'] as String?;
          final backendLabel = result['label'] as String?;
          final backendCopyright = result['copyright'] as String?;
          final effectiveGenre =
              normalizeOptionalString(backendGenre) ??
              normalizeOptionalString(genre) ??
              normalizeOptionalString(existingInHistory?.genre);
          final effectiveLabel =
              normalizeOptionalString(backendLabel) ??
              normalizeOptionalString(label) ??
              normalizeOptionalString(existingInHistory?.label);
          final effectiveCopyright =
              normalizeOptionalString(backendCopyright) ??
              normalizeOptionalString(copyright) ??
              normalizeOptionalString(existingInHistory?.copyright);

          int? finalBitDepth = backendBitDepth;
          int? finalSampleRate = backendSampleRate;
          final lowerFilePath = filePath.toLowerCase();
          final canProbeFinalMetadata =
              filePath.startsWith('content://') ||
              lowerFilePath.endsWith('.flac') ||
              lowerFilePath.endsWith('.m4a') ||
              lowerFilePath.endsWith('.aac') ||
              lowerFilePath.endsWith('.mp3') ||
              lowerFilePath.endsWith('.opus') ||
              lowerFilePath.endsWith('.ogg');

          if (canProbeFinalMetadata) {
            try {
              final metadata = await PlatformBridge.readFileMetadata(filePath);
              if (metadata['error'] == null) {
                final probedBitDepth = metadata['bit_depth'] is num
                    ? (metadata['bit_depth'] as num).toInt()
                    : int.tryParse(metadata['bit_depth']?.toString() ?? '');
                final probedSampleRate = metadata['sample_rate'] is num
                    ? (metadata['sample_rate'] as num).toInt()
                    : int.tryParse(metadata['sample_rate']?.toString() ?? '');

                if (probedBitDepth != null && probedBitDepth > 0) {
                  finalBitDepth = probedBitDepth;
                }
                if (probedSampleRate != null && probedSampleRate > 0) {
                  finalSampleRate = probedSampleRate;
                }

                final resolvedQuality = buildDisplayAudioQuality(
                  bitDepth: finalBitDepth,
                  sampleRate: finalSampleRate,
                  storedQuality: actualQuality,
                );
                if (resolvedQuality != null) {
                  actualQuality = resolvedQuality;
                }
              }
            } catch (e) {
              _log.d('Final audio metadata probe failed for $filePath: $e');
            }
          }

          _log.d('Saving to history - coverUrl: ${trackToDownload.coverUrl}');

          final historyAlbumArtist =
              resolvedAlbumArtist != trackToDownload.artistName
              ? resolvedAlbumArtist
              : null;

          final isLossyOutput =
              lowerFilePath.endsWith('.mp3') ||
              lowerFilePath.endsWith('.opus') ||
              lowerFilePath.endsWith('.ogg');
          final historyBitDepth = isLossyOutput ? null : finalBitDepth;
          final historySampleRate = isLossyOutput ? null : finalSampleRate;

          ref
              .read(downloadHistoryProvider.notifier)
              .addToHistory(
                DownloadHistoryItem(
                  id: item.id,
                  trackName: (backendTitle != null && backendTitle.isNotEmpty)
                      ? backendTitle
                      : trackToDownload.name,
                  artistName:
                      (backendArtist != null && backendArtist.isNotEmpty)
                      ? backendArtist
                      : trackToDownload.artistName,
                  albumName: (backendAlbum != null && backendAlbum.isNotEmpty)
                      ? backendAlbum
                      : trackToDownload.albumName,
                  albumArtist: historyAlbumArtist,
                  coverUrl: normalizeCoverReference(trackToDownload.coverUrl),
                  filePath: filePath,
                  storageMode: effectiveSafMode ? 'saf' : 'app',
                  downloadTreeUri: effectiveSafMode
                      ? settings.downloadTreeUri
                      : null,
                  safRelativeDir: effectiveSafMode ? effectiveOutputDir : null,
                  safFileName: effectiveSafMode
                      ? (finalSafFileName ?? safFileName)
                      : null,
                  safRepaired: false,
                  service: result['service'] as String? ?? item.service,
                  downloadedAt: DateTime.now(),
                  isrc: (backendISRC != null && backendISRC.isNotEmpty)
                      ? backendISRC
                      : trackToDownload.isrc,
                  spotifyId: trackToDownload.id,
                  trackNumber: (backendTrackNum != null && backendTrackNum > 0)
                      ? backendTrackNum
                      : trackToDownload.trackNumber,
                  discNumber: (backendDiscNum != null && backendDiscNum > 0)
                      ? backendDiscNum
                      : trackToDownload.discNumber,
                  duration: trackToDownload.duration,
                  releaseDate: (backendYear != null && backendYear.isNotEmpty)
                      ? backendYear
                      : trackToDownload.releaseDate,
                  quality: actualQuality,
                  bitDepth: historyBitDepth,
                  sampleRate: historySampleRate,
                  genre: effectiveGenre,
                  label: effectiveLabel,
                  copyright: effectiveCopyright,
                ),
              );

          removeItem(item.id);
        }
      } else {
        final itemAfterFailure = _findItemById(item.id);
        if (itemAfterFailure == null ||
            _isLocallyCancelled(item.id, item: itemAfterFailure)) {
          _log.i('Download was cancelled, skipping error handling');
          return;
        }

        if (_isPausePending(item.id)) {
          pausedDuringThisRun = true;
          _requeueItemForPause(item.id);
          _log.i('Download pause requested after backend failure, re-queueing');
          return;
        }

        final errorMsg = result['error'] as String? ?? 'Download failed';
        final errorTypeStr = result['error_type'] as String? ?? 'unknown';
        if (errorTypeStr == 'cancelled') {
          if (_isPausePending(item.id)) {
            pausedDuringThisRun = true;
            _requeueItemForPause(item.id);
            _log.i('Download was paused by backend cancellation, re-queueing');
          } else {
            _log.i(
              'Download was cancelled by backend, skipping error handling',
            );
            updateItemStatus(item.id, DownloadStatus.skipped);
          }
          return;
        }

        DownloadErrorType errorType;
        switch (errorTypeStr) {
          case 'not_found':
            errorType = DownloadErrorType.notFound;
            break;
          case 'rate_limit':
            errorType = DownloadErrorType.rateLimit;
            break;
          case 'network':
            errorType = DownloadErrorType.network;
            break;
          case 'permission':
            errorType = DownloadErrorType.permission;
            break;
          default:
            errorType = DownloadErrorType.unknown;
        }

        _log.e('Download failed: $errorMsg (type: $errorTypeStr)');
        updateItemStatus(
          item.id,
          DownloadStatus.failed,
          error: errorMsg,
          errorType: errorType,
        );
        _failedInSession++;

        try {
          await PlatformBridge.cleanupConnections();
        } catch (e) {
          _log.e('Post-failure connection cleanup failed: $e');
        }
      }

      _downloadCount++;
      if (_downloadCount % _cleanupInterval == 0) {
        _log.d(
          'Cleaning up idle connections (after $_downloadCount downloads)...',
        );
        try {
          await PlatformBridge.cleanupConnections();
        } catch (e) {
          _log.e('Connection cleanup failed: $e');
        }
      }
    } catch (e, stackTrace) {
      final itemAfterError = _findItemById(item.id);
      if (itemAfterError == null ||
          _isLocallyCancelled(item.id, item: itemAfterError)) {
        _log.i('Download was cancelled, skipping error handling');
        return;
      }

      if (_isPausePending(item.id)) {
        pausedDuringThisRun = true;
        _requeueItemForPause(item.id);
        _log.i('Download pause requested after exception, re-queueing');
        return;
      }

      _log.e('Exception: $e', e, stackTrace);

      String errorMsg = e.toString();
      DownloadErrorType errorType = DownloadErrorType.unknown;

      if (errorMsg.contains('could not find Deezer equivalent') ||
          errorMsg.contains('track not found on Deezer')) {
        errorMsg = 'Track not found on Deezer (Metadata Unavailable)';
        errorType = DownloadErrorType.notFound;
      }

      updateItemStatus(
        item.id,
        DownloadStatus.failed,
        error: errorMsg,
        errorType: errorType,
      );
      _failedInSession++;

      try {
        await PlatformBridge.cleanupConnections();
      } catch (cleanupErr) {
        _log.e('Post-exception connection cleanup failed: $cleanupErr');
      }
    } finally {
      if (pausedDuringThisRun) {
        _pausePendingItemIds.remove(item.id);
      }
    }
  }
}

final downloadQueueProvider =
    NotifierProvider<DownloadQueueNotifier, DownloadQueueState>(
      DownloadQueueNotifier.new,
    );

class DownloadQueueLookup {
  final Map<String, DownloadItem> byTrackId;
  final Map<String, DownloadItem> byItemId;
  final List<String> itemIds;

  DownloadQueueLookup._({
    required this.byTrackId,
    required this.byItemId,
    required this.itemIds,
  });

  factory DownloadQueueLookup.fromItems(List<DownloadItem> items) {
    final byTrackId = <String, DownloadItem>{};
    final byItemId = <String, DownloadItem>{};
    final itemIds = <String>[];
    for (final item in items) {
      byTrackId.putIfAbsent(item.track.id, () => item);
      byItemId[item.id] = item;
      itemIds.add(item.id);
    }
    return DownloadQueueLookup._(
      byTrackId: byTrackId,
      byItemId: byItemId,
      itemIds: itemIds,
    );
  }
}

final downloadQueueLookupProvider = Provider<DownloadQueueLookup>((ref) {
  final items = ref.watch(downloadQueueProvider.select((s) => s.items));
  return DownloadQueueLookup.fromItems(items);
});

// ---------------------------------------------------------------------------
// Album ReplayGain helpers
// ---------------------------------------------------------------------------

class _AlbumRgTrackEntry {
  String filePath;
  final String trackId;
  final double integratedLufs;
  final double truePeakLinear;
  final double durationSecs;

  _AlbumRgTrackEntry({
    required this.filePath,
    required this.trackId,
    required this.integratedLufs,
    required this.truePeakLinear,
    required this.durationSecs,
  });
}

class _AlbumRgAccumulator {
  final List<_AlbumRgTrackEntry> entries = [];
}
