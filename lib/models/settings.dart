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
  final int concurrentDownloads;
  final bool checkForUpdates;
  final String updateChannel;
  final bool hasSearchedBefore;
  final String folderOrganization;
  final String historyViewMode;
  final String historyFilterMode;
  final bool askQualityBeforeDownload;
  final String spotifyClientId;
  final String spotifyClientSecret;
  final bool useCustomSpotifyCredentials;
  final String metadataSource;
  final bool enableLogging;
  final bool useExtensionProviders;
  final String? searchProvider;
  final bool separateSingles;
  final String albumFolderStructure;
  final bool showExtensionStore;
  final String locale;
  final bool enableLossyOption;
  final String lossyFormat;
  final String lyricsMode;

  const AppSettings({
    this.defaultService = 'tidal',
    this.audioQuality = 'LOSSLESS',
    this.filenameFormat = '{title} - {artist}',
    this.downloadDirectory = '',
    this.autoFallback = true,
    this.embedLyrics = true,
    this.maxQualityCover = true,
    this.isFirstLaunch = true,
    this.concurrentDownloads = 1,
    this.checkForUpdates = true,
    this.updateChannel = 'stable',
    this.hasSearchedBefore = false,
    this.folderOrganization = 'none',
    this.historyViewMode = 'grid',
    this.historyFilterMode = 'all',
    this.askQualityBeforeDownload = true,
    this.spotifyClientId = '',
    this.spotifyClientSecret = '',
    this.useCustomSpotifyCredentials = true,
    this.metadataSource = 'deezer',
    this.enableLogging = false,
    this.useExtensionProviders = true,
    this.searchProvider,
    this.separateSingles = false,
    this.albumFolderStructure = 'artist_album',
    this.showExtensionStore = true,
    this.locale = 'system',
    this.enableLossyOption = false,
    this.lossyFormat = 'mp3',
    this.lyricsMode = 'embed',
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
    bool clearSearchProvider = false,
    bool? separateSingles,
    String? albumFolderStructure,
    bool? showExtensionStore,
    String? locale,
    bool? enableLossyOption,
    String? lossyFormat,
    String? lyricsMode,
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
      enableLossyOption: enableLossyOption ?? this.enableLossyOption,
      lossyFormat: lossyFormat ?? this.lossyFormat,
      lyricsMode: lyricsMode ?? this.lyricsMode,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);
}
