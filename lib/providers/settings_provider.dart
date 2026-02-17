import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spotiflac_android/models/settings.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';

const _settingsKey = 'app_settings';
const _migrationVersionKey = 'settings_migration_version';
const _currentMigrationVersion = 2;
const _spotifyClientSecretKey = 'spotify_client_secret';
final _log = AppLogger('SettingsProvider');

class SettingsNotifier extends Notifier<AppSettings> {
  static const List<int> _youtubeOpusSupportedBitrates = [128, 256];
  static const List<int> _youtubeMp3SupportedBitrates = [128, 256, 320];

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
      state = AppSettings.fromJson(jsonDecode(json));

      await _runMigrations(prefs);
      await _normalizeYouTubeBitratesIfNeeded();
    }

    await _loadSpotifyClientSecret(prefs);

    _applySpotifyCredentials();

    LogBuffer.loggingEnabled = state.enableLogging;

    _syncLyricsSettingsToBackend();
  }

  void _syncLyricsSettingsToBackend() {
    PlatformBridge.setLyricsProviders(state.lyricsProviders).catchError((e) {
      _log.w('Failed to sync lyrics providers to backend: $e');
    });

    PlatformBridge.setLyricsFetchOptions({
      'include_translation_netease': state.lyricsIncludeTranslationNetease,
      'include_romanization_netease': state.lyricsIncludeRomanizationNetease,
      'multi_person_word_by_word': state.lyricsMultiPersonWordByWord,
      'musixmatch_language': state.musixmatchLanguage,
    }).catchError((e) {
      _log.w('Failed to sync lyrics fetch options to backend: $e');
    });
  }

  Future<void> _runMigrations(SharedPreferences prefs) async {
    final lastMigration = prefs.getInt(_migrationVersionKey) ?? 0;

    if (lastMigration < 1) {
      if (!state.useCustomSpotifyCredentials) {
        state = state.copyWith(metadataSource: 'deezer');
        await _saveSettings();
      }
    }

    if (lastMigration < _currentMigrationVersion) {
      if (state.downloadTreeUri.isNotEmpty && state.storageMode != 'saf') {
        state = state.copyWith(storageMode: 'saf');
      }
      // Migration 2: existing users who already completed setup should skip tutorial
      if (!state.isFirstLaunch && !state.hasCompletedTutorial) {
        state = state.copyWith(hasCompletedTutorial: true);
      }
      await prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
      await _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    final settingsToSave = state.copyWith(spotifyClientSecret: '');
    _pendingSettingsJson = jsonEncode(settingsToSave.toJson());

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

  int _nearestSupportedBitrate(int value, List<int> supported) {
    var nearest = supported.first;
    var nearestDistance = (value - nearest).abs();

    for (final option in supported.skip(1)) {
      final distance = (value - option).abs();
      // On tie, prefer higher quality bitrate.
      if (distance < nearestDistance ||
          (distance == nearestDistance && option > nearest)) {
        nearest = option;
        nearestDistance = distance;
      }
    }

    return nearest;
  }

  int _normalizeYouTubeOpusBitrate(int bitrate) {
    return _nearestSupportedBitrate(bitrate, _youtubeOpusSupportedBitrates);
  }

  int _normalizeYouTubeMp3Bitrate(int bitrate) {
    return _nearestSupportedBitrate(bitrate, _youtubeMp3SupportedBitrates);
  }

  Future<void> _normalizeYouTubeBitratesIfNeeded() async {
    final normalizedOpus = _normalizeYouTubeOpusBitrate(
      state.youtubeOpusBitrate,
    );
    final normalizedMp3 = _normalizeYouTubeMp3Bitrate(state.youtubeMp3Bitrate);

    if (normalizedOpus == state.youtubeOpusBitrate &&
        normalizedMp3 == state.youtubeMp3Bitrate) {
      return;
    }

    state = state.copyWith(
      youtubeOpusBitrate: normalizedOpus,
      youtubeMp3Bitrate: normalizedMp3,
    );
    await _saveSettings();
  }

  Future<void> _loadSpotifyClientSecret(SharedPreferences prefs) async {
    final storedSecret = await _secureStorage.read(
      key: _spotifyClientSecretKey,
    );
    final prefsSecret = state.spotifyClientSecret;

    if ((storedSecret == null || storedSecret.isEmpty) &&
        prefsSecret.isNotEmpty) {
      await _secureStorage.write(
        key: _spotifyClientSecretKey,
        value: prefsSecret,
      );
    }

    final effectiveSecret = (storedSecret != null && storedSecret.isNotEmpty)
        ? storedSecret
        : (prefsSecret.isNotEmpty ? prefsSecret : '');

    if (effectiveSecret != state.spotifyClientSecret) {
      state = state.copyWith(spotifyClientSecret: effectiveSecret);
    }

    if (prefsSecret.isNotEmpty) {
      await _saveSettings();
    }
  }

  Future<void> _storeSpotifyClientSecret(String secret) async {
    if (secret.isEmpty) {
      await _secureStorage.delete(key: _spotifyClientSecretKey);
    } else {
      await _secureStorage.write(key: _spotifyClientSecretKey, value: secret);
    }
  }

  Future<void> _applySpotifyCredentials() async {
    if (state.spotifyClientId.isNotEmpty &&
        state.spotifyClientSecret.isNotEmpty) {
      await PlatformBridge.setSpotifyCredentials(
        state.spotifyClientId,
        state.spotifyClientSecret,
      );
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

  void setSpotifyClientId(String clientId) {
    state = state.copyWith(spotifyClientId: clientId);
    _saveSettings();
  }

  Future<void> setSpotifyClientSecret(String clientSecret) async {
    state = state.copyWith(spotifyClientSecret: clientSecret);
    await _storeSpotifyClientSecret(clientSecret);
    _saveSettings();
  }

  Future<void> setSpotifyCredentials(
    String clientId,
    String clientSecret,
  ) async {
    state = state.copyWith(
      spotifyClientId: clientId,
      spotifyClientSecret: clientSecret,
    );
    await _storeSpotifyClientSecret(clientSecret);
    _saveSettings();
    _applySpotifyCredentials();
  }

  Future<void> clearSpotifyCredentials() async {
    state = state.copyWith(spotifyClientId: '', spotifyClientSecret: '');
    await _storeSpotifyClientSecret('');
    _saveSettings();
    _applySpotifyCredentials();
  }

  void setUseCustomSpotifyCredentials(bool enabled) {
    state = state.copyWith(useCustomSpotifyCredentials: enabled);
    _saveSettings();
    _applySpotifyCredentials();
  }

  void setMetadataSource(String source) {
    state = state.copyWith(metadataSource: source);
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

  void setEnableLogging(bool enabled) {
    state = state.copyWith(enableLogging: enabled);
    _saveSettings();
    LogBuffer.loggingEnabled = enabled;
  }

  void setUseExtensionProviders(bool enabled) {
    state = state.copyWith(useExtensionProviders: enabled);
    _saveSettings();
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

  void setYoutubeOpusBitrate(int bitrate) {
    final normalized = _normalizeYouTubeOpusBitrate(bitrate);
    state = state.copyWith(youtubeOpusBitrate: normalized);
    _saveSettings();
  }

  void setYoutubeMp3Bitrate(int bitrate) {
    final normalized = _normalizeYouTubeMp3Bitrate(bitrate);
    state = state.copyWith(youtubeMp3Bitrate: normalized);
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

  void setLocalLibraryEnabled(bool enabled) {
    state = state.copyWith(localLibraryEnabled: enabled);
    _saveSettings();
  }

  void setLocalLibraryPath(String path) {
    state = state.copyWith(localLibraryPath: path);
    _saveSettings();
  }

  void setLocalLibraryShowDuplicates(bool show) {
    state = state.copyWith(localLibraryShowDuplicates: show);
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
