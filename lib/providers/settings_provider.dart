import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spotiflac_android/models/settings.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/artist_utils.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/utils/logger.dart';

const _settingsKey = 'app_settings';
const _migrationVersionKey = 'settings_migration_version';
const _currentMigrationVersion = 10;
const _spotifyClientSecretKey = 'spotify_client_secret';
final _log = AppLogger('SettingsProvider');

class SettingsNotifier extends Notifier<AppSettings> {
  static final RegExp _isoRegionPattern = RegExp(r'^[A-Z]{2}$');
  static const Set<String> _searchTabValues = {'all', 'track', 'album'};

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isSavingSettings = false;
  bool _saveQueued = false;
  String? _pendingSettingsJson;

  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefs;
    final json = prefs.getString(_settingsKey);
    if (json != null) {
      final loaded = AppSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(json) as Map),
      );
      final sanitizedDownloadFallbackExtensionIds =
          _sanitizeDownloadFallbackExtensionIds(
            loaded.downloadFallbackExtensionIds,
          );
      final sanitizedDefaultSearchTab = _normalizeDefaultSearchTab(
        loaded.defaultSearchTab,
      );
      state = loaded.copyWith(
        downloadFallbackExtensionIds: sanitizedDownloadFallbackExtensionIds,
        clearDownloadFallbackExtensionIds:
            loaded.downloadFallbackExtensionIds != null &&
            sanitizedDownloadFallbackExtensionIds == null,
        defaultSearchTab: sanitizedDefaultSearchTab,
      );

      await _runMigrations(prefs);
      await _normalizeIosDownloadDirectoryIfNeeded();
      await _normalizeSongLinkRegionIfNeeded();
    }

    await _cleanupRetiredSpotifySettings();

    LogBuffer.loggingEnabled = state.enableLogging;

    _syncLyricsSettingsToBackend();
    _syncNetworkCompatibilitySettingsToBackend();
    _syncExtensionFallbackSettingsToBackend();
  }

  void _syncLyricsSettingsToBackend() {
    if (!PlatformBridge.supportsCoreBackend) return;

    PlatformBridge.setLyricsProviders(state.lyricsProviders).catchError((
      Object e,
    ) {
      _log.w('Failed to sync lyrics providers to backend: $e');
    });

    PlatformBridge.setLyricsFetchOptions({
      'include_translation_netease': state.lyricsIncludeTranslationNetease,
      'include_romanization_netease': state.lyricsIncludeRomanizationNetease,
      'multi_person_word_by_word': state.lyricsMultiPersonWordByWord,
      'musixmatch_language': state.musixmatchLanguage,
    }).catchError((Object e) {
      _log.w('Failed to sync lyrics fetch options to backend: $e');
    });
  }

  void _syncNetworkCompatibilitySettingsToBackend() {
    if (!PlatformBridge.supportsCoreBackend) return;

    final compatibilityMode = state.networkCompatibilityMode;
    PlatformBridge.setNetworkCompatibilityOptions(
      allowHttp: compatibilityMode,
      insecureTls: compatibilityMode,
    ).catchError((Object e) {
      _log.w('Failed to sync network compatibility options to backend: $e');
    });
  }

  void _syncExtensionFallbackSettingsToBackend() {
    if (!PlatformBridge.supportsCoreBackend) return;

    PlatformBridge.setDownloadFallbackExtensionIds(
      state.downloadFallbackExtensionIds,
    ).catchError((Object e) {
      _log.w('Failed to sync extension fallback settings to backend: $e');
    });
  }

  Future<void> _runMigrations(SharedPreferences prefs) async {
    final lastMigration = prefs.getInt(_migrationVersionKey) ?? 0;

    if (lastMigration < _currentMigrationVersion) {
      if (state.downloadTreeUri.isNotEmpty && state.storageMode != 'saf') {
        state = state.copyWith(storageMode: 'saf');
      }
      // Migration 2: existing users who already completed setup should skip tutorial
      if (!state.isFirstLaunch && !state.hasCompletedTutorial) {
        state = state.copyWith(hasCompletedTutorial: true);
      }
      if (state.lyricsProviders.contains('spotify_api')) {
        final updatedProviders = state.lyricsProviders
            .where((provider) => provider != 'spotify_api')
            .toList();
        state = state.copyWith(
          lyricsProviders: updatedProviders.isEmpty
              ? const [
                  'lrclib',
                  'musixmatch',
                  'netease',
                  'apple_music',
                  'qqmusic',
                ]
              : updatedProviders,
        );
      }
      state = state.copyWith(lastSeenVersion: AppInfo.version);
      // Migration 7/10: retired built-in services reset back to Tidal
      if (state.defaultService == 'youtube' ||
          state.defaultService == 'deezer') {
        state = state.copyWith(defaultService: 'tidal');
      }
      await prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
      await _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    _pendingSettingsJson = jsonEncode(state.toJson());

    if (_isSavingSettings) {
      _saveQueued = true;
      return;
    }

    _isSavingSettings = true;
    try {
      final prefs = await _prefs;
      do {
        final jsonToWrite = _pendingSettingsJson;
        _saveQueued = false;
        if (jsonToWrite != null) {
          await prefs.setString(_settingsKey, jsonToWrite);
        }
      } while (_saveQueued);
    } catch (e) {
      _log.e('Failed to save settings: $e');
    } finally {
      _isSavingSettings = false;
    }
  }

  Future<void> _normalizeIosDownloadDirectoryIfNeeded() async {
    if (!Platform.isIOS) return;

    final currentDir = state.downloadDirectory.trim();
    if (currentDir.isEmpty) return;

    final normalizedDir = await validateOrFixIosPath(currentDir);
    if (normalizedDir == currentDir) return;

    _log.i('Normalized iOS download directory: $currentDir -> $normalizedDir');
    state = state.copyWith(downloadDirectory: normalizedDir);
    await _saveSettings();
  }

  String _normalizeSongLinkRegion(String region) {
    final normalized = region.trim().toUpperCase();
    if (_isoRegionPattern.hasMatch(normalized)) return normalized;
    return 'US';
  }

  String _normalizeDefaultSearchTab(String value) {
    final normalized = value.trim().toLowerCase();
    if (_searchTabValues.contains(normalized)) return normalized;
    return 'all';
  }

  Future<void> _normalizeSongLinkRegionIfNeeded() async {
    final normalized = _normalizeSongLinkRegion(state.songLinkRegion);
    if (normalized == state.songLinkRegion) return;
    state = state.copyWith(songLinkRegion: normalized);
    await _saveSettings();
  }

  List<String>? _sanitizeDownloadFallbackExtensionIds(List<String>? ids) {
    if (ids == null) {
      return null;
    }

    final result = <String>[];
    for (final id in ids) {
      final normalized = id.trim();
      if (normalized.isEmpty || result.contains(normalized)) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }

  Future<void> _cleanupRetiredSpotifySettings() async {
    final storedSecret = await _secureStorage.read(
      key: _spotifyClientSecretKey,
    );
    if (storedSecret != null && storedSecret.isNotEmpty) {
      await _secureStorage.delete(key: _spotifyClientSecretKey);
    }
  }

  void setDefaultService(String service) {
    state = state.copyWith(defaultService: service);
    _saveSettings();
  }

  void setAudioQuality(String quality) {
    state = state.copyWith(audioQuality: quality);
    _saveSettings();
  }

  void setFilenameFormat(String format) {
    state = state.copyWith(filenameFormat: format);
    _saveSettings();
  }

  void setSingleFilenameFormat(String format) {
    state = state.copyWith(singleFilenameFormat: format);
    _saveSettings();
  }

  void setDownloadDirectory(String directory) {
    state = state.copyWith(downloadDirectory: directory);
    _saveSettings();
  }

  void setStorageMode(String mode) {
    final normalized = mode == 'saf' ? 'saf' : 'app';
    state = state.copyWith(storageMode: normalized);
    _saveSettings();
  }

  void setDownloadTreeUri(String uri, {String? displayName}) {
    final nextDisplay = displayName ?? state.downloadDirectory;
    state = state.copyWith(
      downloadTreeUri: uri,
      storageMode: uri.isNotEmpty ? 'saf' : state.storageMode,
      downloadDirectory: nextDisplay,
    );
    _saveSettings();
  }

  void setAutoFallback(bool enabled) {
    state = state.copyWith(autoFallback: enabled);
    _saveSettings();
  }

  void setEmbedLyrics(bool enabled) {
    state = state.copyWith(embedLyrics: enabled);
    _saveSettings();
  }

  void setEmbedReplayGain(bool enabled) {
    state = state.copyWith(embedReplayGain: enabled);
    _saveSettings();
  }

  void setEmbedMetadata(bool enabled) {
    state = state.copyWith(embedMetadata: enabled);
    _saveSettings();
  }

  void setArtistTagMode(String mode) {
    if (mode == artistTagModeJoined || mode == artistTagModeSplitVorbis) {
      state = state.copyWith(artistTagMode: mode);
      _saveSettings();
    }
  }

  void setLyricsMode(String mode) {
    if (mode == 'embed' || mode == 'external' || mode == 'both') {
      state = state.copyWith(lyricsMode: mode);
      _saveSettings();
    }
  }

  void setLyricsProviders(List<String> providers) {
    state = state.copyWith(lyricsProviders: providers);
    _saveSettings();
    _syncLyricsSettingsToBackend();
  }

  void setLyricsIncludeTranslationNetease(bool enabled) {
    state = state.copyWith(lyricsIncludeTranslationNetease: enabled);
    _saveSettings();
    _syncLyricsSettingsToBackend();
  }

  void setLyricsIncludeRomanizationNetease(bool enabled) {
    state = state.copyWith(lyricsIncludeRomanizationNetease: enabled);
    _saveSettings();
    _syncLyricsSettingsToBackend();
  }

  void setLyricsMultiPersonWordByWord(bool enabled) {
    state = state.copyWith(lyricsMultiPersonWordByWord: enabled);
    _saveSettings();
    _syncLyricsSettingsToBackend();
  }

  void setMusixmatchLanguage(String languageCode) {
    state = state.copyWith(
      musixmatchLanguage: languageCode.trim().toLowerCase(),
    );
    _saveSettings();
    _syncLyricsSettingsToBackend();
  }

  void setMaxQualityCover(bool enabled) {
    state = state.copyWith(maxQualityCover: enabled);
    _saveSettings();
  }

  void setFirstLaunchComplete() {
    state = state.copyWith(isFirstLaunch: false);
    _saveSettings();
  }

  void setConcurrentDownloads(int count) {
    final clamped = count.clamp(1, 5);
    state = state.copyWith(concurrentDownloads: clamped);
    _saveSettings();
  }

  void setCheckForUpdates(bool enabled) {
    state = state.copyWith(checkForUpdates: enabled);
    _saveSettings();
  }

  void setUpdateChannel(String channel) {
    state = state.copyWith(updateChannel: channel);
    _saveSettings();
  }

  void setHasSearchedBefore() {
    if (!state.hasSearchedBefore) {
      state = state.copyWith(hasSearchedBefore: true);
      _saveSettings();
    }
  }

  void setFolderOrganization(String organization) {
    state = state.copyWith(folderOrganization: organization);
    _saveSettings();
  }

  void setCreatePlaylistFolder(bool enabled) {
    state = state.copyWith(createPlaylistFolder: enabled);
    _saveSettings();
  }

  void setUseAlbumArtistForFolders(bool enabled) {
    state = state.copyWith(useAlbumArtistForFolders: enabled);
    _saveSettings();
  }

  void setUsePrimaryArtistOnly(bool enabled) {
    state = state.copyWith(usePrimaryArtistOnly: enabled);
    _saveSettings();
  }

  void setFilterContributingArtistsInAlbumArtist(bool enabled) {
    state = state.copyWith(filterContributingArtistsInAlbumArtist: enabled);
    _saveSettings();
  }

  void setHistoryViewMode(String mode) {
    state = state.copyWith(historyViewMode: mode);
    _saveSettings();
  }

  void setHistoryFilterMode(String mode) {
    state = state.copyWith(historyFilterMode: mode);
    _saveSettings();
  }

  void setAskQualityBeforeDownload(bool enabled) {
    state = state.copyWith(askQualityBeforeDownload: enabled);
    _saveSettings();
  }

  void setSearchProvider(String? provider) {
    if (provider == null || provider.isEmpty) {
      state = state.copyWith(clearSearchProvider: true);
    } else {
      state = state.copyWith(searchProvider: provider);
    }
    _saveSettings();
  }

  void setDefaultSearchTab(String tab) {
    state = state.copyWith(defaultSearchTab: _normalizeDefaultSearchTab(tab));
    _saveSettings();
  }

  void setHomeFeedProvider(String? provider) {
    if (provider == null || provider.isEmpty) {
      state = state.copyWith(clearHomeFeedProvider: true);
    } else {
      state = state.copyWith(homeFeedProvider: provider);
    }
    _saveSettings();
  }

  void setEnableLogging(bool enabled) {
    state = state.copyWith(enableLogging: enabled);
    _saveSettings();
    LogBuffer.loggingEnabled = enabled;
  }

  void setUseExtensionProviders(bool enabled) {
    state = state.copyWith(useExtensionProviders: enabled);
    _saveSettings();
  }

  void setDownloadFallbackExtensionIds(List<String>? extensionIds) {
    final sanitized = _sanitizeDownloadFallbackExtensionIds(extensionIds);
    state = state.copyWith(
      downloadFallbackExtensionIds: sanitized,
      clearDownloadFallbackExtensionIds:
          extensionIds == null && state.downloadFallbackExtensionIds != null,
    );
    _saveSettings();
    _syncExtensionFallbackSettingsToBackend();
  }

  void setSeparateSingles(bool enabled) {
    state = state.copyWith(separateSingles: enabled);
    _saveSettings();
  }

  void setAlbumFolderStructure(String structure) {
    state = state.copyWith(albumFolderStructure: structure);
    _saveSettings();
  }

  void setShowExtensionStore(bool enabled) {
    state = state.copyWith(showExtensionStore: enabled);
    _saveSettings();
  }

  void setLocale(String locale) {
    state = state.copyWith(locale: locale);
    _saveSettings();
  }

  void setTidalHighFormat(String format) {
    state = state.copyWith(tidalHighFormat: format);
    _saveSettings();
  }

  void setUseAllFilesAccess(bool enabled) {
    state = state.copyWith(useAllFilesAccess: enabled);
    _saveSettings();
  }

  void setAutoExportFailedDownloads(bool enabled) {
    state = state.copyWith(autoExportFailedDownloads: enabled);
    _saveSettings();
  }

  void setDownloadNetworkMode(String mode) {
    state = state.copyWith(downloadNetworkMode: mode);
    _saveSettings();
  }

  void setNetworkCompatibilityMode(bool enabled) {
    state = state.copyWith(networkCompatibilityMode: enabled);
    _saveSettings();
    _syncNetworkCompatibilitySettingsToBackend();
  }

  void setSongLinkRegion(String region) {
    final normalized = _normalizeSongLinkRegion(region);
    state = state.copyWith(songLinkRegion: normalized);
    _saveSettings();
  }

  void setLocalLibraryEnabled(bool enabled) {
    state = state.copyWith(localLibraryEnabled: enabled);
    _saveSettings();
  }

  void setLocalLibraryPath(String path) {
    state = state.copyWith(localLibraryPath: path);
    _saveSettings();
  }

  void setLocalLibraryBookmark(String bookmark) {
    state = state.copyWith(localLibraryBookmark: bookmark);
    _saveSettings();
  }

  void setLocalLibraryPathAndBookmark(String path, String bookmark) {
    state = state.copyWith(
      localLibraryPath: path,
      localLibraryBookmark: bookmark,
    );
    _saveSettings();
  }

  void setLocalLibraryShowDuplicates(bool show) {
    state = state.copyWith(localLibraryShowDuplicates: show);
    _saveSettings();
  }

  void setLocalLibraryAutoScan(String mode) {
    state = state.copyWith(localLibraryAutoScan: mode);
    _saveSettings();
  }

  void setTutorialComplete() {
    state = state.copyWith(hasCompletedTutorial: true);
    _saveSettings();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
