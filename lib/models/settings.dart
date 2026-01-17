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
  final String updateChannel; // stable, preview
  final bool hasSearchedBefore; // Hide helper text after first search
  final String folderOrganization; // none, artist, album, artist_album
  final String historyViewMode; // list, grid
  final String historyFilterMode; // all, albums, singles
  final bool askQualityBeforeDownload; // Show quality picker before each download
  final String spotifyClientId; // Custom Spotify client ID (empty = use default)
  final String spotifyClientSecret; // Custom Spotify client secret (empty = use default)
  final bool useCustomSpotifyCredentials; // Whether to use custom credentials (if set)
  final String metadataSource; // spotify, deezer - source for search and metadata
  final bool enableLogging; // Enable detailed logging for debugging
  final bool useExtensionProviders; // Use extension providers for downloads when available
  final String? searchProvider; // null/empty = default (Deezer/Spotify), otherwise extension ID
  final bool separateSingles; // Separate singles/EPs into their own folder
  final String albumFolderStructure; // artist_album, album_only, artist_year_album, year_album
  final bool showExtensionStore; // Show Extension Store tab in navigation
  final String locale; // App language: 'system', 'en', 'id', etc.

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
    this.updateChannel = 'stable', // Default: stable releases only
    this.hasSearchedBefore = false, // Default: show helper text
    this.folderOrganization = 'none', // Default: no folder organization
    this.historyViewMode = 'grid', // Default: grid view
    this.historyFilterMode = 'all', // Default: show all
    this.askQualityBeforeDownload = true, // Default: ask quality before download
    this.spotifyClientId = '', // Default: use built-in credentials
    this.spotifyClientSecret = '', // Default: use built-in credentials
    this.useCustomSpotifyCredentials = true, // Default: use custom if set
    this.metadataSource = 'deezer', // Default: Deezer (no rate limit)
    this.enableLogging = false, // Default: disabled for performance
    this.useExtensionProviders = true, // Default: use extensions when available
    this.searchProvider, // Default: null (use Deezer/Spotify)
    this.separateSingles = false, // Default: disabled
    this.albumFolderStructure = 'artist_album', // Default: Albums/Artist/Album
    this.showExtensionStore = true, // Default: show store
    this.locale = 'system', // Default: follow system language
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
    String? updateChannel,
    bool? hasSearchedBefore,
    String? folderOrganization,
    String? historyViewMode,
    String? historyFilterMode,
    bool? askQualityBeforeDownload,
    String? spotifyClientId,
    String? spotifyClientSecret,
    bool? useCustomSpotifyCredentials,
    String? metadataSource,
    bool? enableLogging,
    bool? useExtensionProviders,
    String? searchProvider,
    bool clearSearchProvider = false, // Set to true to clear searchProvider to null
    bool? separateSingles,
    String? albumFolderStructure,
    bool? showExtensionStore,
    String? locale,
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
      updateChannel: updateChannel ?? this.updateChannel,
      hasSearchedBefore: hasSearchedBefore ?? this.hasSearchedBefore,
      folderOrganization: folderOrganization ?? this.folderOrganization,
      historyViewMode: historyViewMode ?? this.historyViewMode,
      historyFilterMode: historyFilterMode ?? this.historyFilterMode,
      askQualityBeforeDownload: askQualityBeforeDownload ?? this.askQualityBeforeDownload,
      spotifyClientId: spotifyClientId ?? this.spotifyClientId,
      spotifyClientSecret: spotifyClientSecret ?? this.spotifyClientSecret,
      useCustomSpotifyCredentials: useCustomSpotifyCredentials ?? this.useCustomSpotifyCredentials,
      metadataSource: metadataSource ?? this.metadataSource,
      enableLogging: enableLogging ?? this.enableLogging,
      useExtensionProviders: useExtensionProviders ?? this.useExtensionProviders,
      searchProvider: clearSearchProvider ? null : (searchProvider ?? this.searchProvider),
      separateSingles: separateSingles ?? this.separateSingles,
      albumFolderStructure: albumFolderStructure ?? this.albumFolderStructure,
      showExtensionStore: showExtensionStore ?? this.showExtensionStore,
      locale: locale ?? this.locale,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);
}
