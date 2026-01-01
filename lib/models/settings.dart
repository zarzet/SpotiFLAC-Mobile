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
  final bool convertLyricsToRomaji; // Convert Japanese lyrics to romaji
  final String historyViewMode; // list, grid

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
    this.convertLyricsToRomaji = false, // Default: keep original Japanese
    this.historyViewMode = 'grid', // Default: grid view
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
    bool? convertLyricsToRomaji,
    String? historyViewMode,
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
      convertLyricsToRomaji: convertLyricsToRomaji ?? this.convertLyricsToRomaji,
      historyViewMode: historyViewMode ?? this.historyViewMode,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);
}
