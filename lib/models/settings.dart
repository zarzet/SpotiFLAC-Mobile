import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable()
class AppSettings {
  final String defaultService;
  final String audioQuality;
  final String filenameFormat;
  final String downloadDirectory;
  final bool autoFallback;
  final bool embedLyrics;
  final bool maxQualityCover;
  final bool isFirstLaunch;
  final int concurrentDownloads; // 1 = sequential (default), max 3
  final bool checkForUpdates; // Check for updates on app start
  final bool hasSearchedBefore; // Hide helper text after first search
  final String folderOrganization; // none, artist, album, artist_album
  final String historyViewMode; // list, grid
  final bool askQualityBeforeDownload; // Show quality picker before each download
  final String spotifyClientId; // Custom Spotify client ID (empty = use default)
  final String spotifyClientSecret; // Custom Spotify client secret (empty = use default)
  final bool useCustomSpotifyCredentials; // Whether to use custom credentials (if set)

  const AppSettings({
    this.defaultService = 'tidal',
    this.audioQuality = 'LOSSLESS',
    this.filenameFormat = '{title} - {artist}',
    this.downloadDirectory = '',
    this.autoFallback = true,
    this.embedLyrics = true,
    this.maxQualityCover = true,
    this.isFirstLaunch = true,
    this.concurrentDownloads = 1, // Default: sequential (off)
    this.checkForUpdates = true, // Default: enabled
    this.hasSearchedBefore = false, // Default: show helper text
    this.folderOrganization = 'none', // Default: no folder organization
    this.historyViewMode = 'grid', // Default: grid view
    this.askQualityBeforeDownload = true, // Default: ask quality before download
    this.spotifyClientId = '', // Default: use built-in credentials
    this.spotifyClientSecret = '', // Default: use built-in credentials
    this.useCustomSpotifyCredentials = true, // Default: use custom if set
  });

  AppSettings copyWith({
    String? defaultService,
    String? audioQuality,
    String? filenameFormat,
    String? downloadDirectory,
    bool? autoFallback,
    bool? embedLyrics,
    bool? maxQualityCover,
    bool? isFirstLaunch,
    int? concurrentDownloads,
    bool? checkForUpdates,
    bool? hasSearchedBefore,
    String? folderOrganization,
    String? historyViewMode,
    bool? askQualityBeforeDownload,
    String? spotifyClientId,
    String? spotifyClientSecret,
    bool? useCustomSpotifyCredentials,
  }) {
    return AppSettings(
      defaultService: defaultService ?? this.defaultService,
      audioQuality: audioQuality ?? this.audioQuality,
      filenameFormat: filenameFormat ?? this.filenameFormat,
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      autoFallback: autoFallback ?? this.autoFallback,
      embedLyrics: embedLyrics ?? this.embedLyrics,
      maxQualityCover: maxQualityCover ?? this.maxQualityCover,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
      checkForUpdates: checkForUpdates ?? this.checkForUpdates,
      hasSearchedBefore: hasSearchedBefore ?? this.hasSearchedBefore,
      folderOrganization: folderOrganization ?? this.folderOrganization,
      historyViewMode: historyViewMode ?? this.historyViewMode,
      askQualityBeforeDownload: askQualityBeforeDownload ?? this.askQualityBeforeDownload,
      spotifyClientId: spotifyClientId ?? this.spotifyClientId,
      spotifyClientSecret: spotifyClientSecret ?? this.spotifyClientSecret,
      useCustomSpotifyCredentials: useCustomSpotifyCredentials ?? this.useCustomSpotifyCredentials,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);
}
