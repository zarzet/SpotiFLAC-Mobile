import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/models/settings.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';

const _settingsKey = 'app_settings';
const _migrationVersionKey = 'settings_migration_version';
const _currentMigrationVersion = 1;

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_settingsKey);
    if (json != null) {
      state = AppSettings.fromJson(jsonDecode(json));
      
      // Run migrations if needed
      await _runMigrations(prefs);
      
      // Apply Spotify credentials to Go backend on load
      _applySpotifyCredentials();
      
      // Sync logging state
      LogBuffer.loggingEnabled = state.enableLogging;
    }
  }

  /// Run one-time migrations for settings
  Future<void> _runMigrations(SharedPreferences prefs) async {
    final lastMigration = prefs.getInt(_migrationVersionKey) ?? 0;
    
    if (lastMigration < 1) {
      // Migration 1: Set metadataSource to 'deezer' for existing users
      // Only apply if user hasn't enabled custom Spotify credentials
      // (users with custom credentials likely prefer Spotify)
      if (!state.useCustomSpotifyCredentials) {
        state = state.copyWith(metadataSource: 'deezer');
        await _saveSettings();
      }
    }
    
    // Save current migration version
    if (lastMigration < _currentMigrationVersion) {
      await prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(state.toJson()));
  }

  /// Apply current Spotify credentials to Go backend
  Future<void> _applySpotifyCredentials() async {
    // Only apply if both fields are set
    if (state.spotifyClientId.isNotEmpty && 
        state.spotifyClientSecret.isNotEmpty) {
      await PlatformBridge.setSpotifyCredentials(
        state.spotifyClientId,
        state.spotifyClientSecret,
      );
    }
    // Note: If credentials are empty, Spotify API will return error
    // User should use Deezer as metadata source instead
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

  void setAutoFallback(bool enabled) {
    state = state.copyWith(autoFallback: enabled);
    _saveSettings();
  }

  void setEmbedLyrics(bool enabled) {
    state = state.copyWith(embedLyrics: enabled);
    _saveSettings();
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
    // Clamp between 1 and 3
    final clamped = count.clamp(1, 3);
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

  void setHistoryViewMode(String mode) {
    state = state.copyWith(historyViewMode: mode);
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

  void setSpotifyClientSecret(String clientSecret) {
    state = state.copyWith(spotifyClientSecret: clientSecret);
    _saveSettings();
  }

  void setSpotifyCredentials(String clientId, String clientSecret) {
    state = state.copyWith(
      spotifyClientId: clientId,
      spotifyClientSecret: clientSecret,
    );
    _saveSettings();
    _applySpotifyCredentials();
  }

  void clearSpotifyCredentials() {
    state = state.copyWith(
      spotifyClientId: '',
      spotifyClientSecret: '',
    );
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
    state = state.copyWith(searchProvider: provider);
    _saveSettings();
  }

  void setEnableLogging(bool enabled) {
    state = state.copyWith(enableLogging: enabled);
    _saveSettings();
    // Sync logging state to LogBuffer
    LogBuffer.loggingEnabled = enabled;
  }

  void setUseExtensionProviders(bool enabled) {
    state = state.copyWith(useExtensionProviders: enabled);
    _saveSettings();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
