import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('es', 'ES'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pt'),
    Locale('pt', 'PT'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];

  /// App name - DO NOT TRANSLATE
  ///
  /// In en, this message translates to:
  /// **'SpotiFLAC'**
  String get appName;

  /// App description shown in about page
  ///
  /// In en, this message translates to:
  /// **'Download Spotify tracks in lossless quality from Tidal, Qobuz, and Amazon Music.'**
  String get appDescription;

  /// Bottom navigation - Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation - History tab
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// Bottom navigation - Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Bottom navigation - Extension store tab
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get navStore;

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Placeholder text in search box
  ///
  /// In en, this message translates to:
  /// **'Paste Spotify URL or search...'**
  String get homeSearchHint;

  /// Placeholder when extension search is active
  ///
  /// In en, this message translates to:
  /// **'Search with {extensionName}...'**
  String homeSearchHintExtension(String extensionName);

  /// Subtitle shown below search box
  ///
  /// In en, this message translates to:
  /// **'Paste a Spotify link or search by name'**
  String get homeSubtitle;

  /// Info text about supported URL types
  ///
  /// In en, this message translates to:
  /// **'Supports: Track, Album, Playlist, Artist URLs'**
  String get homeSupports;

  /// Section header for recent searches
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// History screen title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// Tab showing active downloads count
  ///
  /// In en, this message translates to:
  /// **'Downloading ({count})'**
  String historyDownloading(int count);

  /// Tab showing completed downloads
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get historyDownloaded;

  /// Filter chip - show all items
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// Filter chip - show albums only
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get historyFilterAlbums;

  /// Filter chip - show singles only
  ///
  /// In en, this message translates to:
  /// **'Singles'**
  String get historyFilterSingles;

  /// Track count with plural form
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String historyTracksCount(int count);

  /// Album count with plural form
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 album} other{{count} albums}}'**
  String historyAlbumsCount(int count);

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No download history'**
  String get historyNoDownloads;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Downloaded tracks will appear here'**
  String get historyNoDownloadsSubtitle;

  /// Empty state when filtering albums
  ///
  /// In en, this message translates to:
  /// **'No album downloads'**
  String get historyNoAlbums;

  /// Empty state subtitle for albums filter
  ///
  /// In en, this message translates to:
  /// **'Download multiple tracks from an album to see them here'**
  String get historyNoAlbumsSubtitle;

  /// Empty state when filtering singles
  ///
  /// In en, this message translates to:
  /// **'No single downloads'**
  String get historyNoSingles;

  /// Empty state subtitle for singles filter
  ///
  /// In en, this message translates to:
  /// **'Single track downloads will appear here'**
  String get historyNoSinglesSubtitle;

  /// Search bar placeholder in history
  ///
  /// In en, this message translates to:
  /// **'Search history...'**
  String get historySearchHint;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section - download options
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get settingsDownload;

  /// Settings section - visual customization
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Settings section - app options
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get settingsOptions;

  /// Settings section - extension management
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get settingsExtensions;

  /// Settings section - app info
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Download settings page title
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadTitle;

  /// Setting for download folder
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get downloadLocation;

  /// Subtitle for download location
  ///
  /// In en, this message translates to:
  /// **'Choose where to save files'**
  String get downloadLocationSubtitle;

  /// Shown when using default folder
  ///
  /// In en, this message translates to:
  /// **'Default location'**
  String get downloadLocationDefault;

  /// Setting for preferred download service (Tidal/Qobuz/Amazon)
  ///
  /// In en, this message translates to:
  /// **'Default Service'**
  String get downloadDefaultService;

  /// Subtitle for default service
  ///
  /// In en, this message translates to:
  /// **'Service used for downloads'**
  String get downloadDefaultServiceSubtitle;

  /// Setting for audio quality
  ///
  /// In en, this message translates to:
  /// **'Default Quality'**
  String get downloadDefaultQuality;

  /// Toggle to show quality picker
  ///
  /// In en, this message translates to:
  /// **'Ask Quality Before Download'**
  String get downloadAskQuality;

  /// Subtitle for ask quality toggle
  ///
  /// In en, this message translates to:
  /// **'Show quality picker for each download'**
  String get downloadAskQualitySubtitle;

  /// Setting for output filename pattern
  ///
  /// In en, this message translates to:
  /// **'Filename Format'**
  String get downloadFilenameFormat;

  /// Setting for folder structure
  ///
  /// In en, this message translates to:
  /// **'Folder Organization'**
  String get downloadFolderOrganization;

  /// Toggle to separate single tracks
  ///
  /// In en, this message translates to:
  /// **'Separate Singles'**
  String get downloadSeparateSingles;

  /// Subtitle for separate singles toggle
  ///
  /// In en, this message translates to:
  /// **'Put single tracks in a separate folder'**
  String get downloadSeparateSinglesSubtitle;

  /// Audio quality option - highest available
  ///
  /// In en, this message translates to:
  /// **'Best Available'**
  String get qualityBest;

  /// Audio quality option - FLAC lossless
  ///
  /// In en, this message translates to:
  /// **'FLAC'**
  String get qualityFlac;

  /// Audio quality option - 320kbps MP3
  ///
  /// In en, this message translates to:
  /// **'320 kbps'**
  String get quality320;

  /// Audio quality option - 128kbps MP3
  ///
  /// In en, this message translates to:
  /// **'128 kbps'**
  String get quality128;

  /// Appearance settings page title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// Theme mode setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appearanceTheme;

  /// Follow system theme
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceThemeSystem;

  /// Light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceThemeLight;

  /// Dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceThemeDark;

  /// Material You dynamic colors
  ///
  /// In en, this message translates to:
  /// **'Dynamic Color'**
  String get appearanceDynamicColor;

  /// Subtitle for dynamic color
  ///
  /// In en, this message translates to:
  /// **'Use colors from your wallpaper'**
  String get appearanceDynamicColorSubtitle;

  /// Custom accent color picker
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get appearanceAccentColor;

  /// Layout style for history
  ///
  /// In en, this message translates to:
  /// **'History View'**
  String get appearanceHistoryView;

  /// List layout option
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get appearanceHistoryViewList;

  /// Grid layout option
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get appearanceHistoryViewGrid;

  /// Options settings page title
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsTitle;

  /// Section for search provider settings
  ///
  /// In en, this message translates to:
  /// **'Search Source'**
  String get optionsSearchSource;

  /// Main search provider setting
  ///
  /// In en, this message translates to:
  /// **'Primary Provider'**
  String get optionsPrimaryProvider;

  /// Subtitle for primary provider
  ///
  /// In en, this message translates to:
  /// **'Service used when searching by track name.'**
  String get optionsPrimaryProviderSubtitle;

  /// Shows active extension name
  ///
  /// In en, this message translates to:
  /// **'Using extension: {extensionName}'**
  String optionsUsingExtension(String extensionName);

  /// Hint to switch back to built-in providers
  ///
  /// In en, this message translates to:
  /// **'Tap Deezer or Spotify to switch back from extension'**
  String get optionsSwitchBack;

  /// Auto-retry with other services
  ///
  /// In en, this message translates to:
  /// **'Auto Fallback'**
  String get optionsAutoFallback;

  /// Subtitle for auto fallback
  ///
  /// In en, this message translates to:
  /// **'Try other services if download fails'**
  String get optionsAutoFallbackSubtitle;

  /// Enable extension download providers
  ///
  /// In en, this message translates to:
  /// **'Use Extension Providers'**
  String get optionsUseExtensionProviders;

  /// Status when extension providers enabled
  ///
  /// In en, this message translates to:
  /// **'Extensions will be tried first'**
  String get optionsUseExtensionProvidersOn;

  /// Status when extension providers disabled
  ///
  /// In en, this message translates to:
  /// **'Using built-in providers only'**
  String get optionsUseExtensionProvidersOff;

  /// Embed lyrics in audio files
  ///
  /// In en, this message translates to:
  /// **'Embed Lyrics'**
  String get optionsEmbedLyrics;

  /// Subtitle for embed lyrics
  ///
  /// In en, this message translates to:
  /// **'Embed synced lyrics into FLAC files'**
  String get optionsEmbedLyricsSubtitle;

  /// Download highest quality album art
  ///
  /// In en, this message translates to:
  /// **'Max Quality Cover'**
  String get optionsMaxQualityCover;

  /// Subtitle for max quality cover
  ///
  /// In en, this message translates to:
  /// **'Download highest resolution cover art'**
  String get optionsMaxQualityCoverSubtitle;

  /// Number of parallel downloads
  ///
  /// In en, this message translates to:
  /// **'Concurrent Downloads'**
  String get optionsConcurrentDownloads;

  /// Download one at a time
  ///
  /// In en, this message translates to:
  /// **'Sequential (1 at a time)'**
  String get optionsConcurrentSequential;

  /// Multiple parallel downloads
  ///
  /// In en, this message translates to:
  /// **'{count} parallel downloads'**
  String optionsConcurrentParallel(int count);

  /// Warning about rate limits
  ///
  /// In en, this message translates to:
  /// **'Parallel downloads may trigger rate limiting'**
  String get optionsConcurrentWarning;

  /// Show/hide store tab
  ///
  /// In en, this message translates to:
  /// **'Extension Store'**
  String get optionsExtensionStore;

  /// Subtitle for extension store toggle
  ///
  /// In en, this message translates to:
  /// **'Show Store tab in navigation'**
  String get optionsExtensionStoreSubtitle;

  /// Auto update check toggle
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get optionsCheckUpdates;

  /// Subtitle for update check
  ///
  /// In en, this message translates to:
  /// **'Notify when new version is available'**
  String get optionsCheckUpdatesSubtitle;

  /// Stable vs preview releases
  ///
  /// In en, this message translates to:
  /// **'Update Channel'**
  String get optionsUpdateChannel;

  /// Only stable updates
  ///
  /// In en, this message translates to:
  /// **'Stable releases only'**
  String get optionsUpdateChannelStable;

  /// Include beta/preview updates
  ///
  /// In en, this message translates to:
  /// **'Get preview releases'**
  String get optionsUpdateChannelPreview;

  /// Warning about preview channel
  ///
  /// In en, this message translates to:
  /// **'Preview may contain bugs or incomplete features'**
  String get optionsUpdateChannelWarning;

  /// Delete all download history
  ///
  /// In en, this message translates to:
  /// **'Clear Download History'**
  String get optionsClearHistory;

  /// Subtitle for clear history
  ///
  /// In en, this message translates to:
  /// **'Remove all downloaded tracks from history'**
  String get optionsClearHistorySubtitle;

  /// Enable verbose logs for debugging
  ///
  /// In en, this message translates to:
  /// **'Detailed Logging'**
  String get optionsDetailedLogging;

  /// Status when logging enabled
  ///
  /// In en, this message translates to:
  /// **'Detailed logs are being recorded'**
  String get optionsDetailedLoggingOn;

  /// Status when logging disabled
  ///
  /// In en, this message translates to:
  /// **'Enable for bug reports'**
  String get optionsDetailedLoggingOff;

  /// Spotify API credentials setting
  ///
  /// In en, this message translates to:
  /// **'Spotify Credentials'**
  String get optionsSpotifyCredentials;

  /// Shows configured client ID preview
  ///
  /// In en, this message translates to:
  /// **'Client ID: {clientId}...'**
  String optionsSpotifyCredentialsConfigured(String clientId);

  /// Prompt to set up credentials
  ///
  /// In en, this message translates to:
  /// **'Required - tap to configure'**
  String get optionsSpotifyCredentialsRequired;

  /// Info about Spotify API requirement
  ///
  /// In en, this message translates to:
  /// **'Spotify requires your own API credentials. Get them free from developer.spotify.com'**
  String get optionsSpotifyWarning;

  /// Extensions page title
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get extensionsTitle;

  /// Section header for installed extensions
  ///
  /// In en, this message translates to:
  /// **'Installed Extensions'**
  String get extensionsInstalled;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No extensions installed'**
  String get extensionsNone;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Install extensions from the Store tab'**
  String get extensionsNoneSubtitle;

  /// Extension status - active
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get extensionsEnabled;

  /// Extension status - inactive
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get extensionsDisabled;

  /// Extension version display
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String extensionsVersion(String version);

  /// Extension author credit
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String extensionsAuthor(String author);

  /// Uninstall extension button
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get extensionsUninstall;

  /// Use extension for search
  ///
  /// In en, this message translates to:
  /// **'Set as Search Provider'**
  String get extensionsSetAsSearch;

  /// Store screen title
  ///
  /// In en, this message translates to:
  /// **'Extension Store'**
  String get storeTitle;

  /// Store search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search extensions...'**
  String get storeSearch;

  /// Install extension button
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get storeInstall;

  /// Already installed badge
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get storeInstalled;

  /// Update available button
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get storeUpdate;

  /// About page title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// Section for contributors
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get aboutContributors;

  /// Role description for mobile dev
  ///
  /// In en, this message translates to:
  /// **'Mobile version developer'**
  String get aboutMobileDeveloper;

  /// Role description for original creator
  ///
  /// In en, this message translates to:
  /// **'Creator of the original SpotiFLAC'**
  String get aboutOriginalCreator;

  /// Role description for logo artist
  ///
  /// In en, this message translates to:
  /// **'The talented artist who created our beautiful app logo!'**
  String get aboutLogoArtist;

  /// Section for translators
  ///
  /// In en, this message translates to:
  /// **'Translators'**
  String get aboutTranslators;

  /// Section for special thanks
  ///
  /// In en, this message translates to:
  /// **'Special Thanks'**
  String get aboutSpecialThanks;

  /// Section for external links
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get aboutLinks;

  /// Link to mobile GitHub repo
  ///
  /// In en, this message translates to:
  /// **'Mobile source code'**
  String get aboutMobileSource;

  /// Link to PC GitHub repo
  ///
  /// In en, this message translates to:
  /// **'PC source code'**
  String get aboutPCSource;

  /// Link to report bugs
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get aboutReportIssue;

  /// Subtitle for report issue
  ///
  /// In en, this message translates to:
  /// **'Report any problems you encounter'**
  String get aboutReportIssueSubtitle;

  /// Link to suggest features
  ///
  /// In en, this message translates to:
  /// **'Feature request'**
  String get aboutFeatureRequest;

  /// Subtitle for feature request
  ///
  /// In en, this message translates to:
  /// **'Suggest new features for the app'**
  String get aboutFeatureRequestSubtitle;

  /// Link to Telegram channel
  ///
  /// In en, this message translates to:
  /// **'Telegram Channel'**
  String get aboutTelegramChannel;

  /// Subtitle for Telegram channel
  ///
  /// In en, this message translates to:
  /// **'Announcements and updates'**
  String get aboutTelegramChannelSubtitle;

  /// Link to Telegram chat group
  ///
  /// In en, this message translates to:
  /// **'Telegram Community'**
  String get aboutTelegramChat;

  /// Subtitle for Telegram chat
  ///
  /// In en, this message translates to:
  /// **'Chat with other users'**
  String get aboutTelegramChatSubtitle;

  /// Section for social links
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get aboutSocial;

  /// Section for support/donation links
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get aboutSupport;

  /// Donation link
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get aboutBuyMeCoffee;

  /// Subtitle for donation
  ///
  /// In en, this message translates to:
  /// **'Support development on Ko-fi'**
  String get aboutBuyMeCoffeeSubtitle;

  /// Section for app info
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get aboutApp;

  /// Version info label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// Credit description for binimum
  ///
  /// In en, this message translates to:
  /// **'The creator of QQDL & HiFi API. Without this API, Tidal downloads wouldn\'t exist!'**
  String get aboutBinimumDesc;

  /// Credit description for sachinsenal0x64
  ///
  /// In en, this message translates to:
  /// **'The original HiFi project creator. The foundation of Tidal integration!'**
  String get aboutSachinsenalDesc;

  /// Name of Amazon API service - DO NOT TRANSLATE
  ///
  /// In en, this message translates to:
  /// **'DoubleDouble'**
  String get aboutDoubleDouble;

  /// Credit for DoubleDouble API
  ///
  /// In en, this message translates to:
  /// **'Amazing API for Amazon Music downloads. Thank you for making it free!'**
  String get aboutDoubleDoubleDesc;

  /// Name of Qobuz API service - DO NOT TRANSLATE
  ///
  /// In en, this message translates to:
  /// **'DAB Music'**
  String get aboutDabMusic;

  /// Credit for DAB Music API
  ///
  /// In en, this message translates to:
  /// **'The best Qobuz streaming API. Hi-Res downloads wouldn\'t be possible without this!'**
  String get aboutDabMusicDesc;

  /// App description in header card
  ///
  /// In en, this message translates to:
  /// **'Download Spotify tracks in lossless quality from Tidal, Qobuz, and Amazon Music.'**
  String get aboutAppDescription;

  /// Album screen title
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get albumTitle;

  /// Album track count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String albumTracks(int count);

  /// Button to download all tracks
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get albumDownloadAll;

  /// Button to download remaining tracks
  ///
  /// In en, this message translates to:
  /// **'Download Remaining'**
  String get albumDownloadRemaining;

  /// Playlist screen title
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlistTitle;

  /// Artist screen title
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artistTitle;

  /// Section header for artist albums
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get artistAlbums;

  /// Section header for singles/EPs
  ///
  /// In en, this message translates to:
  /// **'Singles & EPs'**
  String get artistSingles;

  /// Section header for compilations
  ///
  /// In en, this message translates to:
  /// **'Compilations'**
  String get artistCompilations;

  /// Artist release count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 release} other{{count} releases}}'**
  String artistReleases(int count);

  /// Section header for popular/top tracks
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get artistPopular;

  /// Monthly listener count display
  ///
  /// In en, this message translates to:
  /// **'{count} monthly listeners'**
  String artistMonthlyListeners(String count);

  /// Track metadata screen title
  ///
  /// In en, this message translates to:
  /// **'Track Info'**
  String get trackMetadataTitle;

  /// Metadata field - artist name
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get trackMetadataArtist;

  /// Metadata field - album name
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get trackMetadataAlbum;

  /// Metadata field - track length
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get trackMetadataDuration;

  /// Metadata field - audio quality
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get trackMetadataQuality;

  /// Metadata field - file location
  ///
  /// In en, this message translates to:
  /// **'File Path'**
  String get trackMetadataPath;

  /// Metadata field - download date
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get trackMetadataDownloadedAt;

  /// Metadata field - download service used
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get trackMetadataService;

  /// Action button - play track
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get trackMetadataPlay;

  /// Action button - share track
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get trackMetadataShare;

  /// Action button - delete track
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get trackMetadataDelete;

  /// Action button - download again
  ///
  /// In en, this message translates to:
  /// **'Re-download'**
  String get trackMetadataRedownload;

  /// Action button - open containing folder
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get trackMetadataOpenFolder;

  /// Setup wizard title
  ///
  /// In en, this message translates to:
  /// **'Welcome to SpotiFLAC'**
  String get setupTitle;

  /// Setup wizard subtitle
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you started'**
  String get setupSubtitle;

  /// Storage permission step title
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get setupStoragePermission;

  /// Explanation for storage permission
  ///
  /// In en, this message translates to:
  /// **'Required to save downloaded files'**
  String get setupStoragePermissionSubtitle;

  /// Status when permission granted
  ///
  /// In en, this message translates to:
  /// **'Permission granted'**
  String get setupStoragePermissionGranted;

  /// Status when permission denied
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get setupStoragePermissionDenied;

  /// Button to request permission
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get setupGrantPermission;

  /// Download folder step title
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get setupDownloadLocation;

  /// Button to pick folder
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get setupChooseFolder;

  /// Continue to next step button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get setupContinue;

  /// Skip current step button
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get setupSkip;

  /// Title when storage access needed
  ///
  /// In en, this message translates to:
  /// **'Storage Access Required'**
  String get setupStorageAccessRequired;

  /// Explanation for storage access
  ///
  /// In en, this message translates to:
  /// **'SpotiFLAC needs \"All files access\" permission to save music files to your chosen folder.'**
  String get setupStorageAccessMessage;

  /// Android 11+ specific explanation
  ///
  /// In en, this message translates to:
  /// **'Android 11+ requires \"All files access\" permission to save files to your chosen download folder.'**
  String get setupStorageAccessMessageAndroid11;

  /// Button to open system settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get setupOpenSettings;

  /// Error when permission denied
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please grant all permissions to continue.'**
  String get setupPermissionDeniedMessage;

  /// Generic permission required title
  ///
  /// In en, this message translates to:
  /// **'{permissionType} Permission Required'**
  String setupPermissionRequired(String permissionType);

  /// Generic permission required message
  ///
  /// In en, this message translates to:
  /// **'{permissionType} permission is required for the best experience. You can change this later in Settings.'**
  String setupPermissionRequiredMessage(String permissionType);

  /// Folder selection step title
  ///
  /// In en, this message translates to:
  /// **'Select Download Folder'**
  String get setupSelectDownloadFolder;

  /// Dialog title for default folder
  ///
  /// In en, this message translates to:
  /// **'Use Default Folder?'**
  String get setupUseDefaultFolder;

  /// Prompt when no folder selected
  ///
  /// In en, this message translates to:
  /// **'No folder selected. Would you like to use the default Music folder?'**
  String get setupNoFolderSelected;

  /// Button to use default folder
  ///
  /// In en, this message translates to:
  /// **'Use Default'**
  String get setupUseDefault;

  /// Download location dialog title
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get setupDownloadLocationTitle;

  /// iOS-specific folder info
  ///
  /// In en, this message translates to:
  /// **'On iOS, downloads are saved to the app\'s Documents folder. You can access them via the Files app.'**
  String get setupDownloadLocationIosMessage;

  /// iOS documents folder option
  ///
  /// In en, this message translates to:
  /// **'App Documents Folder'**
  String get setupAppDocumentsFolder;

  /// Subtitle for documents folder
  ///
  /// In en, this message translates to:
  /// **'Recommended - accessible via Files app'**
  String get setupAppDocumentsFolderSubtitle;

  /// iOS file picker option
  ///
  /// In en, this message translates to:
  /// **'Choose from Files'**
  String get setupChooseFromFiles;

  /// Subtitle for file picker
  ///
  /// In en, this message translates to:
  /// **'Select iCloud or other location'**
  String get setupChooseFromFilesSubtitle;

  /// iOS folder selection warning
  ///
  /// In en, this message translates to:
  /// **'iOS limitation: Empty folders cannot be selected. Choose a folder with at least one file.'**
  String get setupIosEmptyFolderWarning;

  /// App tagline in setup
  ///
  /// In en, this message translates to:
  /// **'Download Spotify tracks in FLAC'**
  String get setupDownloadInFlac;

  /// Setup step indicator - storage
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get setupStepStorage;

  /// Setup step indicator - notification
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get setupStepNotification;

  /// Setup step indicator - folder
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get setupStepFolder;

  /// Setup step indicator - Spotify API
  ///
  /// In en, this message translates to:
  /// **'Spotify'**
  String get setupStepSpotify;

  /// Setup step indicator - permission
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get setupStepPermission;

  /// Success message for storage permission
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Granted!'**
  String get setupStorageGranted;

  /// Title when storage permission needed
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Required'**
  String get setupStorageRequired;

  /// Explanation for storage permission
  ///
  /// In en, this message translates to:
  /// **'SpotiFLAC needs storage permission to save your downloaded music files.'**
  String get setupStorageDescription;

  /// Success message for notification permission
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Granted!'**
  String get setupNotificationGranted;

  /// Button to enable notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get setupNotificationEnable;

  /// Explanation for notifications
  ///
  /// In en, this message translates to:
  /// **'Get notified when downloads complete or require attention.'**
  String get setupNotificationDescription;

  /// Success message for folder selection
  ///
  /// In en, this message translates to:
  /// **'Download Folder Selected!'**
  String get setupFolderSelected;

  /// Button to choose folder
  ///
  /// In en, this message translates to:
  /// **'Choose Download Folder'**
  String get setupFolderChoose;

  /// Explanation for folder selection
  ///
  /// In en, this message translates to:
  /// **'Select a folder where your downloaded music will be saved.'**
  String get setupFolderDescription;

  /// Button to change selected folder
  ///
  /// In en, this message translates to:
  /// **'Change Folder'**
  String get setupChangeFolder;

  /// Button to select folder
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get setupSelectFolder;

  /// Spotify API step title
  ///
  /// In en, this message translates to:
  /// **'Spotify API (Optional)'**
  String get setupSpotifyApiOptional;

  /// Explanation for Spotify API
  ///
  /// In en, this message translates to:
  /// **'Add your Spotify API credentials for better search results and access to Spotify-exclusive content.'**
  String get setupSpotifyApiDescription;

  /// Toggle to enable Spotify API
  ///
  /// In en, this message translates to:
  /// **'Use Spotify API'**
  String get setupUseSpotifyApi;

  /// Prompt to enter credentials
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials below'**
  String get setupEnterCredentialsBelow;

  /// Status when using Deezer
  ///
  /// In en, this message translates to:
  /// **'Using Deezer (no account needed)'**
  String get setupUsingDeezer;

  /// Placeholder for client ID field
  ///
  /// In en, this message translates to:
  /// **'Enter Spotify Client ID'**
  String get setupEnterClientId;

  /// Placeholder for client secret field
  ///
  /// In en, this message translates to:
  /// **'Enter Spotify Client Secret'**
  String get setupEnterClientSecret;

  /// Info about getting Spotify credentials
  ///
  /// In en, this message translates to:
  /// **'Get your free API credentials from the Spotify Developer Dashboard.'**
  String get setupGetFreeCredentials;

  /// Button to enable notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get setupEnableNotifications;

  /// Message after completing a step
  ///
  /// In en, this message translates to:
  /// **'You can now proceed to the next step.'**
  String get setupProceedToNextStep;

  /// Info about notification usage
  ///
  /// In en, this message translates to:
  /// **'You will receive download progress notifications.'**
  String get setupNotificationProgressDescription;

  /// Detailed notification explanation
  ///
  /// In en, this message translates to:
  /// **'Get notified about download progress and completion. This helps you track downloads when the app is in background.'**
  String get setupNotificationBackgroundDescription;

  /// Skip button text
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get setupSkipForNow;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get setupBack;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get setupNext;

  /// Final setup button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get setupGetStarted;

  /// Skip setup and start app
  ///
  /// In en, this message translates to:
  /// **'Skip & Start'**
  String get setupSkipAndStart;

  /// Instruction for file access permission
  ///
  /// In en, this message translates to:
  /// **'Please enable \"Allow access to manage all files\" in the next screen.'**
  String get setupAllowAccessToManageFiles;

  /// Link text for Spotify developer portal
  ///
  /// In en, this message translates to:
  /// **'Get credentials from developer.spotify.com'**
  String get setupGetCredentialsFromSpotify;

  /// Dialog button - cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// Dialog button - confirm/acknowledge
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogOk;

  /// Dialog button - save changes
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dialogSave;

  /// Dialog button - delete item
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialogDelete;

  /// Dialog button - retry action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get dialogRetry;

  /// Dialog button - close dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// Dialog button - confirm yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get dialogYes;

  /// Dialog button - confirm no
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get dialogNo;

  /// Dialog button - clear items
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get dialogClear;

  /// Dialog button - confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialogConfirm;

  /// Dialog button - action completed
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dialogDone;

  /// Dialog button - import data
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get dialogImport;

  /// Dialog button - discard changes
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get dialogDiscard;

  /// Dialog button - remove item
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dialogRemove;

  /// Dialog button - uninstall extension
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get dialogUninstall;

  /// Dialog title - unsaved changes warning
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get dialogDiscardChanges;

  /// Dialog message - unsaved changes
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get dialogUnsavedChanges;

  /// Dialog title - download error
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get dialogDownloadFailed;

  /// Label for track name in error dialog
  ///
  /// In en, this message translates to:
  /// **'Track:'**
  String get dialogTrackLabel;

  /// Label for artist name in error dialog
  ///
  /// In en, this message translates to:
  /// **'Artist:'**
  String get dialogArtistLabel;

  /// Label for error message
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get dialogErrorLabel;

  /// Dialog title - clear all items
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get dialogClearAll;

  /// Dialog message - clear downloads confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all downloads?'**
  String get dialogClearAllDownloads;

  /// Dialog title - delete file confirmation
  ///
  /// In en, this message translates to:
  /// **'Remove from device?'**
  String get dialogRemoveFromDevice;

  /// Dialog title - uninstall extension
  ///
  /// In en, this message translates to:
  /// **'Remove Extension'**
  String get dialogRemoveExtension;

  /// Dialog message - uninstall confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this extension? This cannot be undone.'**
  String get dialogRemoveExtensionMessage;

  /// Dialog title - uninstall extension
  ///
  /// In en, this message translates to:
  /// **'Uninstall Extension?'**
  String get dialogUninstallExtension;

  /// Dialog message - uninstall specific extension
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {extensionName}?'**
  String dialogUninstallExtensionMessage(String extensionName);

  /// Dialog title - clear download history
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get dialogClearHistoryTitle;

  /// Dialog message - clear history confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all download history? This cannot be undone.'**
  String get dialogClearHistoryMessage;

  /// Dialog title - delete selected items
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get dialogDeleteSelectedTitle;

  /// Dialog message - delete selected tracks
  ///
  /// In en, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}} from history?\n\nThis will also delete the files from storage.'**
  String dialogDeleteSelectedMessage(int count);

  /// Dialog title - import CSV playlist
  ///
  /// In en, this message translates to:
  /// **'Import Playlist'**
  String get dialogImportPlaylistTitle;

  /// Dialog message - import playlist confirmation
  ///
  /// In en, this message translates to:
  /// **'Found {count} tracks in CSV. Add them to download queue?'**
  String dialogImportPlaylistMessage(int count);

  /// Label shown in quality picker for CSV import
  ///
  /// In en, this message translates to:
  /// **'{count} tracks from CSV'**
  String csvImportTracks(int count);

  /// Snackbar - track added to download queue
  ///
  /// In en, this message translates to:
  /// **'Added \"{trackName}\" to queue'**
  String snackbarAddedToQueue(String trackName);

  /// Snackbar - multiple tracks added to queue
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks to queue'**
  String snackbarAddedTracksToQueue(int count);

  /// Snackbar - track already exists
  ///
  /// In en, this message translates to:
  /// **'\"{trackName}\" already downloaded'**
  String snackbarAlreadyDownloaded(String trackName);

  /// Snackbar - history deleted
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get snackbarHistoryCleared;

  /// Snackbar - Spotify credentials saved
  ///
  /// In en, this message translates to:
  /// **'Credentials saved'**
  String get snackbarCredentialsSaved;

  /// Snackbar - Spotify credentials removed
  ///
  /// In en, this message translates to:
  /// **'Credentials cleared'**
  String get snackbarCredentialsCleared;

  /// Snackbar - tracks deleted
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} {count, plural, =1{track} other{tracks}}'**
  String snackbarDeletedTracks(int count);

  /// Snackbar - file open error
  ///
  /// In en, this message translates to:
  /// **'Cannot open file: {error}'**
  String snackbarCannotOpenFile(String error);

  /// Snackbar - validation error
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get snackbarFillAllFields;

  /// Snackbar action - view download queue
  ///
  /// In en, this message translates to:
  /// **'View Queue'**
  String get snackbarViewQueue;

  /// Snackbar - loading error
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String snackbarFailedToLoad(String error);

  /// Snackbar - URL copied
  ///
  /// In en, this message translates to:
  /// **'{platform} URL copied to clipboard'**
  String snackbarUrlCopied(String platform);

  /// Snackbar - file doesn't exist
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get snackbarFileNotFound;

  /// Snackbar - wrong file type selected
  ///
  /// In en, this message translates to:
  /// **'Please select a .spotiflac-ext file'**
  String get snackbarSelectExtFile;

  /// Snackbar - provider order saved
  ///
  /// In en, this message translates to:
  /// **'Provider priority saved'**
  String get snackbarProviderPrioritySaved;

  /// Snackbar - metadata provider order saved
  ///
  /// In en, this message translates to:
  /// **'Metadata provider priority saved'**
  String get snackbarMetadataProviderSaved;

  /// Snackbar - extension installed successfully
  ///
  /// In en, this message translates to:
  /// **'{extensionName} installed.'**
  String snackbarExtensionInstalled(String extensionName);

  /// Snackbar - extension updated successfully
  ///
  /// In en, this message translates to:
  /// **'{extensionName} updated.'**
  String snackbarExtensionUpdated(String extensionName);

  /// Snackbar - extension install error
  ///
  /// In en, this message translates to:
  /// **'Failed to install extension'**
  String get snackbarFailedToInstall;

  /// Snackbar - extension update error
  ///
  /// In en, this message translates to:
  /// **'Failed to update extension'**
  String get snackbarFailedToUpdate;

  /// Error title - too many requests
  ///
  /// In en, this message translates to:
  /// **'Rate Limited'**
  String get errorRateLimited;

  /// Error message - rate limit explanation
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment before searching again.'**
  String get errorRateLimitedMessage;

  /// Error message - loading failed
  ///
  /// In en, this message translates to:
  /// **'Failed to load {item}'**
  String errorFailedToLoad(String item);

  /// Error - search returned no results
  ///
  /// In en, this message translates to:
  /// **'No tracks found'**
  String get errorNoTracksFound;

  /// Error - extension source not available
  ///
  /// In en, this message translates to:
  /// **'Cannot load {item}: missing extension source'**
  String errorMissingExtensionSource(String item);

  /// Download status - waiting in queue
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// Download status - in progress
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get statusDownloading;

  /// Download status - writing metadata
  ///
  /// In en, this message translates to:
  /// **'Finalizing'**
  String get statusFinalizing;

  /// Download status - finished
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Download status - error occurred
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// Download status - already exists
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get statusSkipped;

  /// Download status - paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// Action button - pause download
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// Action button - resume download
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// Action button - cancel operation
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Action button - stop operation
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// Action button - enter selection mode
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get actionSelect;

  /// Action button - select all items
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get actionSelectAll;

  /// Action button - deselect all
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get actionDeselect;

  /// Action button - paste from clipboard
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get actionPaste;

  /// Action button - import CSV file
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get actionImportCsv;

  /// Action button - delete Spotify credentials
  ///
  /// In en, this message translates to:
  /// **'Remove Credentials'**
  String get actionRemoveCredentials;

  /// Action button - save Spotify credentials
  ///
  /// In en, this message translates to:
  /// **'Save Credentials'**
  String get actionSaveCredentials;

  /// Selection count indicator
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectionSelected(int count);

  /// Status - all items selected
  ///
  /// In en, this message translates to:
  /// **'All tracks selected'**
  String get selectionAllSelected;

  /// Hint - how to select items
  ///
  /// In en, this message translates to:
  /// **'Tap tracks to select'**
  String get selectionTapToSelect;

  /// Delete button with count
  ///
  /// In en, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}}'**
  String selectionDeleteTracks(int count);

  /// Placeholder when nothing selected
  ///
  /// In en, this message translates to:
  /// **'Select tracks to delete'**
  String get selectionSelectToDelete;

  /// Progress indicator - loading track info
  ///
  /// In en, this message translates to:
  /// **'Fetching metadata... {current}/{total}'**
  String progressFetchingMetadata(int current, int total);

  /// Progress indicator - parsing CSV file
  ///
  /// In en, this message translates to:
  /// **'Reading CSV...'**
  String get progressReadingCsv;

  /// Search result category - songs
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get searchSongs;

  /// Search result category - artists
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get searchArtists;

  /// Search result category - albums
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get searchAlbums;

  /// Search result category - playlists
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get searchPlaylists;

  /// Tooltip - play button
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get tooltipPlay;

  /// Tooltip - cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tooltipCancel;

  /// Tooltip - stop button
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get tooltipStop;

  /// Tooltip - retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get tooltipRetry;

  /// Tooltip - remove button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get tooltipRemove;

  /// Tooltip - clear button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get tooltipClear;

  /// Tooltip - paste button
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get tooltipPaste;

  /// Setting title - filename pattern
  ///
  /// In en, this message translates to:
  /// **'Filename Format'**
  String get filenameFormat;

  /// Preview of filename pattern
  ///
  /// In en, this message translates to:
  /// **'Preview: {preview}'**
  String filenameFormatPreview(String preview);

  /// Label for placeholder list
  ///
  /// In en, this message translates to:
  /// **'Available placeholders:'**
  String get filenameAvailablePlaceholders;

  /// Default filename format hint
  ///
  /// In en, this message translates to:
  /// **'{artist} - {title}'**
  String filenameHint(Object artist, Object title);

  /// Setting title - folder structure
  ///
  /// In en, this message translates to:
  /// **'Folder Organization'**
  String get folderOrganization;

  /// Folder option - flat structure
  ///
  /// In en, this message translates to:
  /// **'No organization'**
  String get folderOrganizationNone;

  /// Folder option - artist folders
  ///
  /// In en, this message translates to:
  /// **'By Artist'**
  String get folderOrganizationByArtist;

  /// Folder option - album folders
  ///
  /// In en, this message translates to:
  /// **'By Album'**
  String get folderOrganizationByAlbum;

  /// Folder option - nested folders
  ///
  /// In en, this message translates to:
  /// **'Artist/Album'**
  String get folderOrganizationByArtistAlbum;

  /// Folder organization sheet description
  ///
  /// In en, this message translates to:
  /// **'Organize downloaded files into folders'**
  String get folderOrganizationDescription;

  /// Subtitle for no organization option
  ///
  /// In en, this message translates to:
  /// **'All files in download folder'**
  String get folderOrganizationNoneSubtitle;

  /// Subtitle for artist folder option
  ///
  /// In en, this message translates to:
  /// **'Separate folder for each artist'**
  String get folderOrganizationByArtistSubtitle;

  /// Subtitle for album folder option
  ///
  /// In en, this message translates to:
  /// **'Separate folder for each album'**
  String get folderOrganizationByAlbumSubtitle;

  /// Subtitle for nested folder option
  ///
  /// In en, this message translates to:
  /// **'Nested folders for artist and album'**
  String get folderOrganizationByArtistAlbumSubtitle;

  /// Update dialog title
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// Update available message
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateNewVersion(String version);

  /// Update button - download update
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;

  /// Update button - dismiss
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// Link to changelog
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get updateChangelog;

  /// Update status - initializing
  ///
  /// In en, this message translates to:
  /// **'Starting download...'**
  String get updateStartingDownload;

  /// Update error title
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get updateDownloadFailed;

  /// Update error message
  ///
  /// In en, this message translates to:
  /// **'Failed to download update'**
  String get updateFailedMessage;

  /// Update subtitle
  ///
  /// In en, this message translates to:
  /// **'A new version is ready'**
  String get updateNewVersionReady;

  /// Label for current version
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get updateCurrent;

  /// Label for new version
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get updateNew;

  /// Update status - downloading
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get updateDownloading;

  /// Changelog section title
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get updateWhatsNew;

  /// Update button - download and install
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get updateDownloadInstall;

  /// Update button - skip this version
  ///
  /// In en, this message translates to:
  /// **'Don\'t remind'**
  String get updateDontRemind;

  /// Setting title - download provider order
  ///
  /// In en, this message translates to:
  /// **'Provider Priority'**
  String get providerPriority;

  /// Subtitle for provider priority
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder download providers'**
  String get providerPrioritySubtitle;

  /// Provider priority page title
  ///
  /// In en, this message translates to:
  /// **'Provider Priority'**
  String get providerPriorityTitle;

  /// Provider priority page description
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder download providers. The app will try providers from top to bottom when downloading tracks.'**
  String get providerPriorityDescription;

  /// Info tip about fallback behavior
  ///
  /// In en, this message translates to:
  /// **'If a track is not available on the first provider, the app will automatically try the next one.'**
  String get providerPriorityInfo;

  /// Label for built-in providers (Tidal/Qobuz/Amazon)
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get providerBuiltIn;

  /// Label for extension-provided providers
  ///
  /// In en, this message translates to:
  /// **'Extension'**
  String get providerExtension;

  /// Setting title - metadata provider order
  ///
  /// In en, this message translates to:
  /// **'Metadata Provider Priority'**
  String get metadataProviderPriority;

  /// Subtitle for metadata priority
  ///
  /// In en, this message translates to:
  /// **'Order used when fetching track metadata'**
  String get metadataProviderPrioritySubtitle;

  /// Metadata priority page title
  ///
  /// In en, this message translates to:
  /// **'Metadata Priority'**
  String get metadataProviderPriorityTitle;

  /// Metadata priority page description
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder metadata providers. The app will try providers from top to bottom when searching for tracks and fetching metadata.'**
  String get metadataProviderPriorityDescription;

  /// Info tip about rate limits
  ///
  /// In en, this message translates to:
  /// **'Deezer has no rate limits and is recommended as primary. Spotify may rate limit after many requests.'**
  String get metadataProviderPriorityInfo;

  /// Deezer provider description
  ///
  /// In en, this message translates to:
  /// **'No rate limits'**
  String get metadataNoRateLimits;

  /// Spotify provider description
  ///
  /// In en, this message translates to:
  /// **'May rate limit'**
  String get metadataMayRateLimit;

  /// Logs screen title
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logTitle;

  /// Action - copy logs to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy Logs'**
  String get logCopy;

  /// Action - delete all logs
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get logClear;

  /// Action - share logs file
  ///
  /// In en, this message translates to:
  /// **'Share Logs'**
  String get logShare;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logEmpty;

  /// Snackbar - logs copied
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get logCopied;

  /// Log search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search logs...'**
  String get logSearchHint;

  /// Filter by log level
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get logFilterLevel;

  /// Filter section title
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get logFilterSection;

  /// Share button tooltip
  ///
  /// In en, this message translates to:
  /// **'Share logs'**
  String get logShareLogs;

  /// Clear button tooltip
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get logClearLogs;

  /// Clear logs dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get logClearLogsTitle;

  /// Clear logs confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all logs?'**
  String get logClearLogsMessage;

  /// Error category - ISP blocking
  ///
  /// In en, this message translates to:
  /// **'ISP BLOCKING DETECTED'**
  String get logIspBlocking;

  /// Error category - rate limiting
  ///
  /// In en, this message translates to:
  /// **'RATE LIMITED'**
  String get logRateLimited;

  /// Error category - network issues
  ///
  /// In en, this message translates to:
  /// **'NETWORK ERROR'**
  String get logNetworkError;

  /// Error category - missing tracks
  ///
  /// In en, this message translates to:
  /// **'TRACK NOT FOUND'**
  String get logTrackNotFound;

  /// Filter dialog title
  ///
  /// In en, this message translates to:
  /// **'Filter logs by severity'**
  String get logFilterBySeverity;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logNoLogsYet;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Logs will appear here as you use the app'**
  String get logNoLogsYetSubtitle;

  /// Section header for error summary
  ///
  /// In en, this message translates to:
  /// **'Issue Summary'**
  String get logIssueSummary;

  /// ISP blocking explanation
  ///
  /// In en, this message translates to:
  /// **'Your ISP may be blocking access to download services'**
  String get logIspBlockingDescription;

  /// ISP blocking fix suggestion
  ///
  /// In en, this message translates to:
  /// **'Try using a VPN or change DNS to 1.1.1.1 or 8.8.8.8'**
  String get logIspBlockingSuggestion;

  /// Rate limit explanation
  ///
  /// In en, this message translates to:
  /// **'Too many requests to the service'**
  String get logRateLimitedDescription;

  /// Rate limit fix suggestion
  ///
  /// In en, this message translates to:
  /// **'Wait a few minutes before trying again'**
  String get logRateLimitedSuggestion;

  /// Network error explanation
  ///
  /// In en, this message translates to:
  /// **'Connection issues detected'**
  String get logNetworkErrorDescription;

  /// Network error fix suggestion
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get logNetworkErrorSuggestion;

  /// Track not found explanation
  ///
  /// In en, this message translates to:
  /// **'Some tracks could not be found on download services'**
  String get logTrackNotFoundDescription;

  /// Track not found explanation
  ///
  /// In en, this message translates to:
  /// **'The track may not be available in lossless quality'**
  String get logTrackNotFoundSuggestion;

  /// Error count display
  ///
  /// In en, this message translates to:
  /// **'Total errors: {count}'**
  String logTotalErrors(int count);

  /// Affected domains display
  ///
  /// In en, this message translates to:
  /// **'Affected: {domains}'**
  String logAffected(String domains);

  /// Log count with filter active
  ///
  /// In en, this message translates to:
  /// **'Entries ({count} filtered)'**
  String logEntriesFiltered(int count);

  /// Total log count
  ///
  /// In en, this message translates to:
  /// **'Entries ({count})'**
  String logEntries(int count);

  /// Credentials dialog title
  ///
  /// In en, this message translates to:
  /// **'Spotify Credentials'**
  String get credentialsTitle;

  /// Credentials dialog explanation
  ///
  /// In en, this message translates to:
  /// **'Enter your Client ID and Secret to use your own Spotify application quota.'**
  String get credentialsDescription;

  /// Client ID field label - DO NOT TRANSLATE
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get credentialsClientId;

  /// Client ID placeholder
  ///
  /// In en, this message translates to:
  /// **'Paste Client ID'**
  String get credentialsClientIdHint;

  /// Client Secret field label - DO NOT TRANSLATE
  ///
  /// In en, this message translates to:
  /// **'Client Secret'**
  String get credentialsClientSecret;

  /// Client Secret placeholder
  ///
  /// In en, this message translates to:
  /// **'Paste Client Secret'**
  String get credentialsClientSecretHint;

  /// Update channel - stable releases
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get channelStable;

  /// Update channel - beta/preview releases
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get channelPreview;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Search Source'**
  String get sectionSearchSource;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get sectionDownload;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get sectionPerformance;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sectionApp;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get sectionData;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get sectionDebug;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get sectionService;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Audio Quality'**
  String get sectionAudioQuality;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'File Settings'**
  String get sectionFileSettings;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get sectionLyrics;

  /// Setting - how to save lyrics
  ///
  /// In en, this message translates to:
  /// **'Lyrics Mode'**
  String get lyricsMode;

  /// Lyrics mode picker description
  ///
  /// In en, this message translates to:
  /// **'Choose how lyrics are saved with your downloads'**
  String get lyricsModeDescription;

  /// Lyrics mode option - embed in audio file
  ///
  /// In en, this message translates to:
  /// **'Embed in file'**
  String get lyricsModeEmbed;

  /// Subtitle for embed option
  ///
  /// In en, this message translates to:
  /// **'Lyrics stored inside FLAC metadata'**
  String get lyricsModeEmbedSubtitle;

  /// Lyrics mode option - separate LRC file
  ///
  /// In en, this message translates to:
  /// **'External .lrc file'**
  String get lyricsModeExternal;

  /// Subtitle for external option
  ///
  /// In en, this message translates to:
  /// **'Separate .lrc file for players like Samsung Music'**
  String get lyricsModeExternalSubtitle;

  /// Lyrics mode option - embed and external
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get lyricsModeBoth;

  /// Subtitle for both option
  ///
  /// In en, this message translates to:
  /// **'Embed and save .lrc file'**
  String get lyricsModeBothSubtitle;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get sectionColor;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get sectionTheme;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get sectionLayout;

  /// Settings section header for language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// Language setting title
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appearanceLanguage;

  /// Language setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get appearanceLanguageSubtitle;

  /// Appearance settings description
  ///
  /// In en, this message translates to:
  /// **'Theme, colors, display'**
  String get settingsAppearanceSubtitle;

  /// Download settings description
  ///
  /// In en, this message translates to:
  /// **'Service, quality, filename format'**
  String get settingsDownloadSubtitle;

  /// Options settings description
  ///
  /// In en, this message translates to:
  /// **'Fallback, lyrics, cover art, updates'**
  String get settingsOptionsSubtitle;

  /// Extensions settings description
  ///
  /// In en, this message translates to:
  /// **'Manage download providers'**
  String get settingsExtensionsSubtitle;

  /// Logs settings description
  ///
  /// In en, this message translates to:
  /// **'View app logs for debugging'**
  String get settingsLogsSubtitle;

  /// Status when opening shared URL
  ///
  /// In en, this message translates to:
  /// **'Loading shared link...'**
  String get loadingSharedLink;

  /// Exit confirmation message
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// Section header for track list
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracksHeader;

  /// Download all button with count
  ///
  /// In en, this message translates to:
  /// **'Download All ({count})'**
  String downloadAllCount(int count);

  /// Track count display
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String tracksCount(int count);

  /// Action - copy file path
  ///
  /// In en, this message translates to:
  /// **'Copy file path'**
  String get trackCopyFilePath;

  /// Action - delete downloaded file
  ///
  /// In en, this message translates to:
  /// **'Remove from device'**
  String get trackRemoveFromDevice;

  /// Action - fetch lyrics
  ///
  /// In en, this message translates to:
  /// **'Load Lyrics'**
  String get trackLoadLyrics;

  /// Tab title - track metadata
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get trackMetadata;

  /// Tab title - file information
  ///
  /// In en, this message translates to:
  /// **'File Info'**
  String get trackFileInfo;

  /// Tab title - lyrics
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get trackLyrics;

  /// Error - file doesn't exist
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get trackFileNotFound;

  /// Action - open track in Deezer app
  ///
  /// In en, this message translates to:
  /// **'Open in Deezer'**
  String get trackOpenInDeezer;

  /// Action - open track in Spotify app
  ///
  /// In en, this message translates to:
  /// **'Open in Spotify'**
  String get trackOpenInSpotify;

  /// Metadata label - track title
  ///
  /// In en, this message translates to:
  /// **'Track name'**
  String get trackTrackName;

  /// Metadata label - artist name
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get trackArtist;

  /// Metadata label - album artist
  ///
  /// In en, this message translates to:
  /// **'Album artist'**
  String get trackAlbumArtist;

  /// Metadata label - album name
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get trackAlbum;

  /// Metadata label - track number
  ///
  /// In en, this message translates to:
  /// **'Track number'**
  String get trackTrackNumber;

  /// Metadata label - disc number
  ///
  /// In en, this message translates to:
  /// **'Disc number'**
  String get trackDiscNumber;

  /// Metadata label - track length
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get trackDuration;

  /// Metadata label - audio quality
  ///
  /// In en, this message translates to:
  /// **'Audio quality'**
  String get trackAudioQuality;

  /// Metadata label - release date
  ///
  /// In en, this message translates to:
  /// **'Release date'**
  String get trackReleaseDate;

  /// Metadata label - music genre
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get trackGenre;

  /// Metadata label - record label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get trackLabel;

  /// Metadata label - copyright information
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get trackCopyright;

  /// Metadata label - download date
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get trackDownloaded;

  /// Action - copy lyrics to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy lyrics'**
  String get trackCopyLyrics;

  /// Message when lyrics not found
  ///
  /// In en, this message translates to:
  /// **'Lyrics not available for this track'**
  String get trackLyricsNotAvailable;

  /// Message when lyrics request times out
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Try again later.'**
  String get trackLyricsTimeout;

  /// Message when lyrics loading fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load lyrics'**
  String get trackLyricsLoadFailed;

  /// Action - embed lyrics into audio file
  ///
  /// In en, this message translates to:
  /// **'Embed Lyrics'**
  String get trackEmbedLyrics;

  /// Snackbar - lyrics saved to file
  ///
  /// In en, this message translates to:
  /// **'Lyrics embedded successfully'**
  String get trackLyricsEmbedded;

  /// Message when track is instrumental (no lyrics)
  ///
  /// In en, this message translates to:
  /// **'Instrumental track'**
  String get trackInstrumental;

  /// Snackbar - content copied
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get trackCopiedToClipboard;

  /// Delete confirmation title
  ///
  /// In en, this message translates to:
  /// **'Remove from device?'**
  String get trackDeleteConfirmTitle;

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the downloaded file and remove it from your history.'**
  String get trackDeleteConfirmMessage;

  /// Error opening file
  ///
  /// In en, this message translates to:
  /// **'Cannot open: {message}'**
  String trackCannotOpen(String message);

  /// Relative date - today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// Relative date - yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// Relative date - days ago
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String dateDaysAgo(int count);

  /// Relative date - weeks ago
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String dateWeeksAgo(int count);

  /// Relative date - months ago
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String dateMonthsAgo(int count);

  /// Download mode - one at a time
  ///
  /// In en, this message translates to:
  /// **'Sequential'**
  String get concurrentSequential;

  /// Download mode - 2 simultaneous
  ///
  /// In en, this message translates to:
  /// **'2 Parallel'**
  String get concurrentParallel2;

  /// Download mode - 3 simultaneous
  ///
  /// In en, this message translates to:
  /// **'3 Parallel'**
  String get concurrentParallel3;

  /// Tooltip for failed download
  ///
  /// In en, this message translates to:
  /// **'Tap to see error details'**
  String get tapToSeeError;

  /// Store filter - all extensions
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get storeFilterAll;

  /// Store filter - metadata providers
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get storeFilterMetadata;

  /// Store filter - download providers
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get storeFilterDownload;

  /// Store filter - utility extensions
  ///
  /// In en, this message translates to:
  /// **'Utility'**
  String get storeFilterUtility;

  /// Store filter - lyrics providers
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get storeFilterLyrics;

  /// Store filter - integrations
  ///
  /// In en, this message translates to:
  /// **'Integration'**
  String get storeFilterIntegration;

  /// Button to clear all filters
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get storeClearFilters;

  /// Empty state when no extensions match filters
  ///
  /// In en, this message translates to:
  /// **'No extensions found'**
  String get storeNoResults;

  /// Extension capability - provider priority
  ///
  /// In en, this message translates to:
  /// **'Provider Priority'**
  String get extensionProviderPriority;

  /// Button to install extension
  ///
  /// In en, this message translates to:
  /// **'Install Extension'**
  String get extensionInstallButton;

  /// Default search provider option
  ///
  /// In en, this message translates to:
  /// **'Default (Deezer/Spotify)'**
  String get extensionDefaultProvider;

  /// Subtitle for default provider
  ///
  /// In en, this message translates to:
  /// **'Use built-in search'**
  String get extensionDefaultProviderSubtitle;

  /// Extension detail - author
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get extensionAuthor;

  /// Extension detail - unique ID
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get extensionId;

  /// Extension detail - error message
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get extensionError;

  /// Section header - extension features
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get extensionCapabilities;

  /// Capability - provides metadata
  ///
  /// In en, this message translates to:
  /// **'Metadata Provider'**
  String get extensionMetadataProvider;

  /// Capability - provides downloads
  ///
  /// In en, this message translates to:
  /// **'Download Provider'**
  String get extensionDownloadProvider;

  /// Capability - provides lyrics
  ///
  /// In en, this message translates to:
  /// **'Lyrics Provider'**
  String get extensionLyricsProvider;

  /// Capability - handles URLs
  ///
  /// In en, this message translates to:
  /// **'URL Handler'**
  String get extensionUrlHandler;

  /// Capability - quality selection
  ///
  /// In en, this message translates to:
  /// **'Quality Options'**
  String get extensionQualityOptions;

  /// Capability - post-processing
  ///
  /// In en, this message translates to:
  /// **'Post-Processing Hooks'**
  String get extensionPostProcessingHooks;

  /// Section header - required permissions
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get extensionPermissions;

  /// Section header - extension settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get extensionSettings;

  /// Button to uninstall extension
  ///
  /// In en, this message translates to:
  /// **'Remove Extension'**
  String get extensionRemoveButton;

  /// Extension detail - last update
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get extensionUpdated;

  /// Extension detail - minimum app version
  ///
  /// In en, this message translates to:
  /// **'Min App Version'**
  String get extensionMinAppVersion;

  /// Capability - custom track matching algorithm
  ///
  /// In en, this message translates to:
  /// **'Custom Track Matching'**
  String get extensionCustomTrackMatching;

  /// Capability - post-download processing
  ///
  /// In en, this message translates to:
  /// **'Post-Processing'**
  String get extensionPostProcessing;

  /// Post-processing hooks count
  ///
  /// In en, this message translates to:
  /// **'{count} hook(s) available'**
  String extensionHooksAvailable(int count);

  /// URL patterns count
  ///
  /// In en, this message translates to:
  /// **'{count} pattern(s)'**
  String extensionPatternsCount(int count);

  /// Track matching strategy name
  ///
  /// In en, this message translates to:
  /// **'Strategy: {strategy}'**
  String extensionStrategy(String strategy);

  /// Section header - provider priority
  ///
  /// In en, this message translates to:
  /// **'Provider Priority'**
  String get extensionsProviderPrioritySection;

  /// Section header - installed extensions
  ///
  /// In en, this message translates to:
  /// **'Installed Extensions'**
  String get extensionsInstalledSection;

  /// Empty state - no extensions
  ///
  /// In en, this message translates to:
  /// **'No extensions installed'**
  String get extensionsNoExtensions;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Install .spotiflac-ext files to add new providers'**
  String get extensionsNoExtensionsSubtitle;

  /// Button to install extension from file
  ///
  /// In en, this message translates to:
  /// **'Install Extension'**
  String get extensionsInstallButton;

  /// Security warning about extensions
  ///
  /// In en, this message translates to:
  /// **'Extensions can add new metadata and download providers. Only install extensions from trusted sources.'**
  String get extensionsInfoTip;

  /// Success message after install
  ///
  /// In en, this message translates to:
  /// **'Extension installed successfully'**
  String get extensionsInstalledSuccess;

  /// Setting - download provider order
  ///
  /// In en, this message translates to:
  /// **'Download Priority'**
  String get extensionsDownloadPriority;

  /// Subtitle for download priority
  ///
  /// In en, this message translates to:
  /// **'Set download service order'**
  String get extensionsDownloadPrioritySubtitle;

  /// Empty state - no download providers
  ///
  /// In en, this message translates to:
  /// **'No extensions with download provider'**
  String get extensionsNoDownloadProvider;

  /// Setting - metadata provider order
  ///
  /// In en, this message translates to:
  /// **'Metadata Priority'**
  String get extensionsMetadataPriority;

  /// Subtitle for metadata priority
  ///
  /// In en, this message translates to:
  /// **'Set search & metadata source order'**
  String get extensionsMetadataPrioritySubtitle;

  /// Empty state - no metadata providers
  ///
  /// In en, this message translates to:
  /// **'No extensions with metadata provider'**
  String get extensionsNoMetadataProvider;

  /// Setting - search provider selection
  ///
  /// In en, this message translates to:
  /// **'Search Provider'**
  String get extensionsSearchProvider;

  /// Empty state - no search providers
  ///
  /// In en, this message translates to:
  /// **'No extensions with custom search'**
  String get extensionsNoCustomSearch;

  /// Search provider setting description
  ///
  /// In en, this message translates to:
  /// **'Choose which service to use for searching tracks'**
  String get extensionsSearchProviderDescription;

  /// Label for custom search provider
  ///
  /// In en, this message translates to:
  /// **'Custom search'**
  String get extensionsCustomSearch;

  /// Error message when extension fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading extension'**
  String get extensionsErrorLoading;

  /// Quality option - CD quality FLAC
  ///
  /// In en, this message translates to:
  /// **'FLAC Lossless'**
  String get qualityFlacLossless;

  /// Technical spec for lossless
  ///
  /// In en, this message translates to:
  /// **'16-bit / 44.1kHz'**
  String get qualityFlacLosslessSubtitle;

  /// Quality option - high resolution FLAC
  ///
  /// In en, this message translates to:
  /// **'Hi-Res FLAC'**
  String get qualityHiResFlac;

  /// Technical spec for hi-res
  ///
  /// In en, this message translates to:
  /// **'24-bit / up to 96kHz'**
  String get qualityHiResFlacSubtitle;

  /// Quality option - maximum resolution FLAC
  ///
  /// In en, this message translates to:
  /// **'Hi-Res FLAC Max'**
  String get qualityHiResFlacMax;

  /// Technical spec for hi-res max
  ///
  /// In en, this message translates to:
  /// **'24-bit / up to 192kHz'**
  String get qualityHiResFlacMaxSubtitle;

  /// Quality option - lossy format (MP3/Opus)
  ///
  /// In en, this message translates to:
  /// **'Lossy'**
  String get qualityLossy;

  /// Technical spec for lossy MP3
  ///
  /// In en, this message translates to:
  /// **'MP3 320kbps (converted from FLAC)'**
  String get qualityLossyMp3Subtitle;

  /// Technical spec for lossy Opus
  ///
  /// In en, this message translates to:
  /// **'Opus 128kbps (converted from FLAC)'**
  String get qualityLossyOpusSubtitle;

  /// Setting - enable lossy quality option
  ///
  /// In en, this message translates to:
  /// **'Enable Lossy Option'**
  String get enableLossyOption;

  /// Subtitle when lossy is enabled
  ///
  /// In en, this message translates to:
  /// **'Lossy quality option is available'**
  String get enableLossyOptionSubtitleOn;

  /// Subtitle when lossy is disabled
  ///
  /// In en, this message translates to:
  /// **'Downloads FLAC then converts to lossy format'**
  String get enableLossyOptionSubtitleOff;

  /// Setting - choose lossy format
  ///
  /// In en, this message translates to:
  /// **'Lossy Format'**
  String get lossyFormat;

  /// Description for lossy format picker
  ///
  /// In en, this message translates to:
  /// **'Choose the lossy format for conversion'**
  String get lossyFormatDescription;

  /// MP3 format description
  ///
  /// In en, this message translates to:
  /// **'320kbps, best compatibility'**
  String get lossyFormatMp3Subtitle;

  /// Opus format description
  ///
  /// In en, this message translates to:
  /// **'128kbps, better quality at smaller size'**
  String get lossyFormatOpusSubtitle;

  /// Note about quality availability
  ///
  /// In en, this message translates to:
  /// **'Actual quality depends on track availability from the service'**
  String get qualityNote;

  /// Setting - show quality picker
  ///
  /// In en, this message translates to:
  /// **'Ask Before Download'**
  String get downloadAskBeforeDownload;

  /// Setting - download folder
  ///
  /// In en, this message translates to:
  /// **'Download Directory'**
  String get downloadDirectory;

  /// Setting - separate folder for singles
  ///
  /// In en, this message translates to:
  /// **'Separate Singles Folder'**
  String get downloadSeparateSinglesFolder;

  /// Setting - album folder organization
  ///
  /// In en, this message translates to:
  /// **'Album Folder Structure'**
  String get downloadAlbumFolderStructure;

  /// Setting - output file format
  ///
  /// In en, this message translates to:
  /// **'Save Format'**
  String get downloadSaveFormat;

  /// Dialog title - choose download service
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get downloadSelectService;

  /// Dialog title - choose audio quality
  ///
  /// In en, this message translates to:
  /// **'Select Quality'**
  String get downloadSelectQuality;

  /// Label - download source
  ///
  /// In en, this message translates to:
  /// **'Download From'**
  String get downloadFrom;

  /// Label - default quality setting
  ///
  /// In en, this message translates to:
  /// **'Default Quality'**
  String get downloadDefaultQualityLabel;

  /// Quality option - highest available
  ///
  /// In en, this message translates to:
  /// **'Best available'**
  String get downloadBestAvailable;

  /// Folder option - no organization
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get folderNone;

  /// Subtitle for no folder organization
  ///
  /// In en, this message translates to:
  /// **'Save all files directly to download folder'**
  String get folderNoneSubtitle;

  /// Folder option - by artist
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get folderArtist;

  /// Folder structure example
  ///
  /// In en, this message translates to:
  /// **'Artist Name/filename'**
  String get folderArtistSubtitle;

  /// Folder option - by album
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get folderAlbum;

  /// Folder structure example
  ///
  /// In en, this message translates to:
  /// **'Album Name/filename'**
  String get folderAlbumSubtitle;

  /// Folder option - nested
  ///
  /// In en, this message translates to:
  /// **'Artist/Album'**
  String get folderArtistAlbum;

  /// Folder structure example
  ///
  /// In en, this message translates to:
  /// **'Artist Name/Album Name/filename'**
  String get folderArtistAlbumSubtitle;

  /// Service name - DO NOT TRANSLATE
  ///
  /// In en, this message translates to:
  /// **'Tidal'**
  String get serviceTidal;

  /// Service name - DO NOT TRANSLATE
  ///
  /// In en, this message translates to:
  /// **'Qobuz'**
  String get serviceQobuz;

  /// Service name - DO NOT TRANSLATE
  ///
  /// In en, this message translates to:
  /// **'Amazon'**
  String get serviceAmazon;

  /// Service name - DO NOT TRANSLATE
  ///
  /// In en, this message translates to:
  /// **'Deezer'**
  String get serviceDeezer;

  /// Service name - DO NOT TRANSLATE
  ///
  /// In en, this message translates to:
  /// **'Spotify'**
  String get serviceSpotify;

  /// Theme option - pure black
  ///
  /// In en, this message translates to:
  /// **'AMOLED Dark'**
  String get appearanceAmoledDark;

  /// Subtitle for AMOLED dark
  ///
  /// In en, this message translates to:
  /// **'Pure black background'**
  String get appearanceAmoledDarkSubtitle;

  /// Color picker dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Accent Color'**
  String get appearanceChooseAccentColor;

  /// Theme picker dialog title
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get appearanceChooseTheme;

  /// Queue screen title
  ///
  /// In en, this message translates to:
  /// **'Download Queue'**
  String get queueTitle;

  /// Button - clear all queue items
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get queueClearAll;

  /// Clear queue confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all downloads?'**
  String get queueClearAllMessage;

  /// Empty queue state title
  ///
  /// In en, this message translates to:
  /// **'No downloads in queue'**
  String get queueEmpty;

  /// Empty queue state subtitle
  ///
  /// In en, this message translates to:
  /// **'Add tracks from the home screen'**
  String get queueEmptySubtitle;

  /// Button - clear finished downloads
  ///
  /// In en, this message translates to:
  /// **'Clear completed'**
  String get queueClearCompleted;

  /// Error dialog title
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get queueDownloadFailed;

  /// Label in error dialog
  ///
  /// In en, this message translates to:
  /// **'Track:'**
  String get queueTrackLabel;

  /// Label in error dialog
  ///
  /// In en, this message translates to:
  /// **'Artist:'**
  String get queueArtistLabel;

  /// Label in error dialog
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get queueErrorLabel;

  /// Fallback error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get queueUnknownError;

  /// Album folder option
  ///
  /// In en, this message translates to:
  /// **'Artist / Album'**
  String get albumFolderArtistAlbum;

  /// Folder structure example
  ///
  /// In en, this message translates to:
  /// **'Albums/Artist Name/Album Name/'**
  String get albumFolderArtistAlbumSubtitle;

  /// Album folder option with year
  ///
  /// In en, this message translates to:
  /// **'Artist / [Year] Album'**
  String get albumFolderArtistYearAlbum;

  /// Folder structure example
  ///
  /// In en, this message translates to:
  /// **'Albums/Artist Name/[2005] Album Name/'**
  String get albumFolderArtistYearAlbumSubtitle;

  /// Album folder option
  ///
  /// In en, this message translates to:
  /// **'Album Only'**
  String get albumFolderAlbumOnly;

  /// Folder structure example
  ///
  /// In en, this message translates to:
  /// **'Albums/Album Name/'**
  String get albumFolderAlbumOnlySubtitle;

  /// Album folder option with year
  ///
  /// In en, this message translates to:
  /// **'[Year] Album'**
  String get albumFolderYearAlbum;

  /// Folder structure example
  ///
  /// In en, this message translates to:
  /// **'Albums/[2005] Album Name/'**
  String get albumFolderYearAlbumSubtitle;

  /// Album folder option with singles inside artist
  ///
  /// In en, this message translates to:
  /// **'Artist / Album + Singles'**
  String get albumFolderArtistAlbumSingles;

  /// Folder structure example
  ///
  /// In en, this message translates to:
  /// **'Artist/Album/ and Artist/Singles/'**
  String get albumFolderArtistAlbumSinglesSubtitle;

  /// Button - delete selected tracks
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get downloadedAlbumDeleteSelected;

  /// Delete confirmation with count
  ///
  /// In en, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}} from this album?\n\nThis will also delete the files from storage.'**
  String downloadedAlbumDeleteMessage(int count);

  /// Section header for tracks
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get downloadedAlbumTracksHeader;

  /// Downloaded tracks count badge
  ///
  /// In en, this message translates to:
  /// **'{count} downloaded'**
  String downloadedAlbumDownloadedCount(int count);

  /// Selection count indicator
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String downloadedAlbumSelectedCount(int count);

  /// Status - all items selected
  ///
  /// In en, this message translates to:
  /// **'All tracks selected'**
  String get downloadedAlbumAllSelected;

  /// Selection hint
  ///
  /// In en, this message translates to:
  /// **'Tap tracks to select'**
  String get downloadedAlbumTapToSelect;

  /// Delete button text with count
  ///
  /// In en, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}}'**
  String downloadedAlbumDeleteCount(int count);

  /// Placeholder when nothing selected
  ///
  /// In en, this message translates to:
  /// **'Select tracks to delete'**
  String get downloadedAlbumSelectToDelete;

  /// Header for disc separator in multi-disc albums
  ///
  /// In en, this message translates to:
  /// **'Disc {discNumber}'**
  String downloadedAlbumDiscHeader(int discNumber);

  /// Extension capability - utility functions
  ///
  /// In en, this message translates to:
  /// **'Utility Functions'**
  String get utilityFunctions;

  /// Recent access item type - artist
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get recentTypeArtist;

  /// Recent access item type - album
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get recentTypeAlbum;

  /// Recent access item type - song/track
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get recentTypeSong;

  /// Recent access item type - playlist
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get recentTypePlaylist;

  /// Snackbar message when tapping playlist in recent access
  ///
  /// In en, this message translates to:
  /// **'Playlist: {name}'**
  String recentPlaylistInfo(String name);

  /// Generic error message format
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorGeneric(String message);

  /// Button - download artist discography
  ///
  /// In en, this message translates to:
  /// **'Download Discography'**
  String get discographyDownload;

  /// Option - download entire discography
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get discographyDownloadAll;

  /// Subtitle showing total tracks and albums
  ///
  /// In en, this message translates to:
  /// **'{count} tracks from {albumCount} releases'**
  String discographyDownloadAllSubtitle(int count, int albumCount);

  /// Option - download only albums
  ///
  /// In en, this message translates to:
  /// **'Albums Only'**
  String get discographyAlbumsOnly;

  /// Subtitle showing album tracks count
  ///
  /// In en, this message translates to:
  /// **'{count} tracks from {albumCount} albums'**
  String discographyAlbumsOnlySubtitle(int count, int albumCount);

  /// Option - download only singles
  ///
  /// In en, this message translates to:
  /// **'Singles & EPs Only'**
  String get discographySinglesOnly;

  /// Subtitle showing singles tracks count
  ///
  /// In en, this message translates to:
  /// **'{count} tracks from {albumCount} singles'**
  String discographySinglesOnlySubtitle(int count, int albumCount);

  /// Option - manually select albums to download
  ///
  /// In en, this message translates to:
  /// **'Select Albums...'**
  String get discographySelectAlbums;

  /// Subtitle for select albums option
  ///
  /// In en, this message translates to:
  /// **'Choose specific albums or singles'**
  String get discographySelectAlbumsSubtitle;

  /// Progress - fetching album tracks
  ///
  /// In en, this message translates to:
  /// **'Fetching tracks...'**
  String get discographyFetchingTracks;

  /// Progress - fetching specific album
  ///
  /// In en, this message translates to:
  /// **'Fetching {current} of {total}...'**
  String discographyFetchingAlbum(int current, int total);

  /// Selection count badge
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String discographySelectedCount(int count);

  /// Button - download selected albums
  ///
  /// In en, this message translates to:
  /// **'Download Selected'**
  String get discographyDownloadSelected;

  /// Snackbar - tracks added from discography
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks to queue'**
  String discographyAddedToQueue(int count);

  /// Snackbar - with skipped tracks count
  ///
  /// In en, this message translates to:
  /// **'{added} added, {skipped} already downloaded'**
  String discographySkippedDownloaded(int added, int skipped);

  /// Error - no albums found for artist
  ///
  /// In en, this message translates to:
  /// **'No albums available'**
  String get discographyNoAlbums;

  /// Error - some albums failed to load
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch some albums'**
  String get discographyFailedToFetch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'ja',
    'ko',
    'nl',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case 'ES':
            return AppLocalizationsEsEs();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'PT':
            return AppLocalizationsPtPt();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
