import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

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
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SpotiFLAC'**
  String get appName;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Download Spotify tracks in lossless quality from Tidal, Qobuz, and Amazon Music.'**
  String get appDescription;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get navStore;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Paste Spotify URL or search...'**
  String get homeSearchHint;

  /// No description provided for @homeSearchHintExtension.
  ///
  /// In en, this message translates to:
  /// **'Search with {extensionName}...'**
  String homeSearchHintExtension(String extensionName);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a Spotify link or search by name'**
  String get homeSubtitle;

  /// No description provided for @homeSupports.
  ///
  /// In en, this message translates to:
  /// **'Supports: Track, Album, Playlist, Artist URLs'**
  String get homeSupports;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading ({count})'**
  String historyDownloading(int count);

  /// No description provided for @historyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get historyDownloaded;

  /// No description provided for @historyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// No description provided for @historyFilterAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get historyFilterAlbums;

  /// No description provided for @historyFilterSingles.
  ///
  /// In en, this message translates to:
  /// **'Singles'**
  String get historyFilterSingles;

  /// No description provided for @historyTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String historyTracksCount(int count);

  /// No description provided for @historyAlbumsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 album} other{{count} albums}}'**
  String historyAlbumsCount(int count);

  /// No description provided for @historyNoDownloads.
  ///
  /// In en, this message translates to:
  /// **'No download history'**
  String get historyNoDownloads;

  /// No description provided for @historyNoDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded tracks will appear here'**
  String get historyNoDownloadsSubtitle;

  /// No description provided for @historyNoAlbums.
  ///
  /// In en, this message translates to:
  /// **'No album downloads'**
  String get historyNoAlbums;

  /// No description provided for @historyNoAlbumsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download multiple tracks from an album to see them here'**
  String get historyNoAlbumsSubtitle;

  /// No description provided for @historyNoSingles.
  ///
  /// In en, this message translates to:
  /// **'No single downloads'**
  String get historyNoSingles;

  /// No description provided for @historyNoSinglesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Single track downloads will appear here'**
  String get historyNoSinglesSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get settingsDownload;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get settingsOptions;

  /// No description provided for @settingsExtensions.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get settingsExtensions;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @downloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadTitle;

  /// No description provided for @downloadLocation.
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get downloadLocation;

  /// No description provided for @downloadLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose where to save files'**
  String get downloadLocationSubtitle;

  /// No description provided for @downloadLocationDefault.
  ///
  /// In en, this message translates to:
  /// **'Default location'**
  String get downloadLocationDefault;

  /// No description provided for @downloadDefaultService.
  ///
  /// In en, this message translates to:
  /// **'Default Service'**
  String get downloadDefaultService;

  /// No description provided for @downloadDefaultServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Service used for downloads'**
  String get downloadDefaultServiceSubtitle;

  /// No description provided for @downloadDefaultQuality.
  ///
  /// In en, this message translates to:
  /// **'Default Quality'**
  String get downloadDefaultQuality;

  /// No description provided for @downloadAskQuality.
  ///
  /// In en, this message translates to:
  /// **'Ask Quality Before Download'**
  String get downloadAskQuality;

  /// No description provided for @downloadAskQualitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show quality picker for each download'**
  String get downloadAskQualitySubtitle;

  /// No description provided for @downloadFilenameFormat.
  ///
  /// In en, this message translates to:
  /// **'Filename Format'**
  String get downloadFilenameFormat;

  /// No description provided for @downloadFolderOrganization.
  ///
  /// In en, this message translates to:
  /// **'Folder Organization'**
  String get downloadFolderOrganization;

  /// No description provided for @downloadSeparateSingles.
  ///
  /// In en, this message translates to:
  /// **'Separate Singles'**
  String get downloadSeparateSingles;

  /// No description provided for @downloadSeparateSinglesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Put single tracks in a separate folder'**
  String get downloadSeparateSinglesSubtitle;

  /// No description provided for @qualityBest.
  ///
  /// In en, this message translates to:
  /// **'Best Available'**
  String get qualityBest;

  /// No description provided for @qualityFlac.
  ///
  /// In en, this message translates to:
  /// **'FLAC'**
  String get qualityFlac;

  /// No description provided for @quality320.
  ///
  /// In en, this message translates to:
  /// **'320 kbps'**
  String get quality320;

  /// No description provided for @quality128.
  ///
  /// In en, this message translates to:
  /// **'128 kbps'**
  String get quality128;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appearanceTheme;

  /// No description provided for @appearanceThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceThemeSystem;

  /// No description provided for @appearanceThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceThemeLight;

  /// No description provided for @appearanceThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceThemeDark;

  /// No description provided for @appearanceDynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Color'**
  String get appearanceDynamicColor;

  /// No description provided for @appearanceDynamicColorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use colors from your wallpaper'**
  String get appearanceDynamicColorSubtitle;

  /// No description provided for @appearanceAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get appearanceAccentColor;

  /// No description provided for @appearanceHistoryView.
  ///
  /// In en, this message translates to:
  /// **'History View'**
  String get appearanceHistoryView;

  /// No description provided for @appearanceHistoryViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get appearanceHistoryViewList;

  /// No description provided for @appearanceHistoryViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get appearanceHistoryViewGrid;

  /// No description provided for @optionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsTitle;

  /// No description provided for @optionsSearchSource.
  ///
  /// In en, this message translates to:
  /// **'Search Source'**
  String get optionsSearchSource;

  /// No description provided for @optionsPrimaryProvider.
  ///
  /// In en, this message translates to:
  /// **'Primary Provider'**
  String get optionsPrimaryProvider;

  /// No description provided for @optionsPrimaryProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Service used when searching by track name.'**
  String get optionsPrimaryProviderSubtitle;

  /// No description provided for @optionsUsingExtension.
  ///
  /// In en, this message translates to:
  /// **'Using extension: {extensionName}'**
  String optionsUsingExtension(String extensionName);

  /// No description provided for @optionsSwitchBack.
  ///
  /// In en, this message translates to:
  /// **'Tap Deezer or Spotify to switch back from extension'**
  String get optionsSwitchBack;

  /// No description provided for @optionsAutoFallback.
  ///
  /// In en, this message translates to:
  /// **'Auto Fallback'**
  String get optionsAutoFallback;

  /// No description provided for @optionsAutoFallbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try other services if download fails'**
  String get optionsAutoFallbackSubtitle;

  /// No description provided for @optionsUseExtensionProviders.
  ///
  /// In en, this message translates to:
  /// **'Use Extension Providers'**
  String get optionsUseExtensionProviders;

  /// No description provided for @optionsUseExtensionProvidersOn.
  ///
  /// In en, this message translates to:
  /// **'Extensions will be tried first'**
  String get optionsUseExtensionProvidersOn;

  /// No description provided for @optionsUseExtensionProvidersOff.
  ///
  /// In en, this message translates to:
  /// **'Using built-in providers only'**
  String get optionsUseExtensionProvidersOff;

  /// No description provided for @optionsEmbedLyrics.
  ///
  /// In en, this message translates to:
  /// **'Embed Lyrics'**
  String get optionsEmbedLyrics;

  /// No description provided for @optionsEmbedLyricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Embed synced lyrics into FLAC files'**
  String get optionsEmbedLyricsSubtitle;

  /// No description provided for @optionsMaxQualityCover.
  ///
  /// In en, this message translates to:
  /// **'Max Quality Cover'**
  String get optionsMaxQualityCover;

  /// No description provided for @optionsMaxQualityCoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download highest resolution cover art'**
  String get optionsMaxQualityCoverSubtitle;

  /// No description provided for @optionsConcurrentDownloads.
  ///
  /// In en, this message translates to:
  /// **'Concurrent Downloads'**
  String get optionsConcurrentDownloads;

  /// No description provided for @optionsConcurrentSequential.
  ///
  /// In en, this message translates to:
  /// **'Sequential (1 at a time)'**
  String get optionsConcurrentSequential;

  /// No description provided for @optionsConcurrentParallel.
  ///
  /// In en, this message translates to:
  /// **'{count} parallel downloads'**
  String optionsConcurrentParallel(int count);

  /// No description provided for @optionsConcurrentWarning.
  ///
  /// In en, this message translates to:
  /// **'Parallel downloads may trigger rate limiting'**
  String get optionsConcurrentWarning;

  /// No description provided for @optionsExtensionStore.
  ///
  /// In en, this message translates to:
  /// **'Extension Store'**
  String get optionsExtensionStore;

  /// No description provided for @optionsExtensionStoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show Store tab in navigation'**
  String get optionsExtensionStoreSubtitle;

  /// No description provided for @optionsCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get optionsCheckUpdates;

  /// No description provided for @optionsCheckUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when new version is available'**
  String get optionsCheckUpdatesSubtitle;

  /// No description provided for @optionsUpdateChannel.
  ///
  /// In en, this message translates to:
  /// **'Update Channel'**
  String get optionsUpdateChannel;

  /// No description provided for @optionsUpdateChannelStable.
  ///
  /// In en, this message translates to:
  /// **'Stable releases only'**
  String get optionsUpdateChannelStable;

  /// No description provided for @optionsUpdateChannelPreview.
  ///
  /// In en, this message translates to:
  /// **'Get preview releases'**
  String get optionsUpdateChannelPreview;

  /// No description provided for @optionsUpdateChannelWarning.
  ///
  /// In en, this message translates to:
  /// **'Preview may contain bugs or incomplete features'**
  String get optionsUpdateChannelWarning;

  /// No description provided for @optionsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Download History'**
  String get optionsClearHistory;

  /// No description provided for @optionsClearHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all downloaded tracks from history'**
  String get optionsClearHistorySubtitle;

  /// No description provided for @optionsDetailedLogging.
  ///
  /// In en, this message translates to:
  /// **'Detailed Logging'**
  String get optionsDetailedLogging;

  /// No description provided for @optionsDetailedLoggingOn.
  ///
  /// In en, this message translates to:
  /// **'Detailed logs are being recorded'**
  String get optionsDetailedLoggingOn;

  /// No description provided for @optionsDetailedLoggingOff.
  ///
  /// In en, this message translates to:
  /// **'Enable for bug reports'**
  String get optionsDetailedLoggingOff;

  /// No description provided for @optionsSpotifyCredentials.
  ///
  /// In en, this message translates to:
  /// **'Spotify Credentials'**
  String get optionsSpotifyCredentials;

  /// No description provided for @optionsSpotifyCredentialsConfigured.
  ///
  /// In en, this message translates to:
  /// **'Client ID: {clientId}...'**
  String optionsSpotifyCredentialsConfigured(String clientId);

  /// No description provided for @optionsSpotifyCredentialsRequired.
  ///
  /// In en, this message translates to:
  /// **'Required - tap to configure'**
  String get optionsSpotifyCredentialsRequired;

  /// No description provided for @optionsSpotifyWarning.
  ///
  /// In en, this message translates to:
  /// **'Spotify requires your own API credentials. Get them free from developer.spotify.com'**
  String get optionsSpotifyWarning;

  /// No description provided for @extensionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get extensionsTitle;

  /// No description provided for @extensionsInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed Extensions'**
  String get extensionsInstalled;

  /// No description provided for @extensionsNone.
  ///
  /// In en, this message translates to:
  /// **'No extensions installed'**
  String get extensionsNone;

  /// No description provided for @extensionsNoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Install extensions from the Store tab'**
  String get extensionsNoneSubtitle;

  /// No description provided for @extensionsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get extensionsEnabled;

  /// No description provided for @extensionsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get extensionsDisabled;

  /// No description provided for @extensionsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String extensionsVersion(String version);

  /// No description provided for @extensionsAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String extensionsAuthor(String author);

  /// No description provided for @extensionsUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get extensionsUninstall;

  /// No description provided for @extensionsSetAsSearch.
  ///
  /// In en, this message translates to:
  /// **'Set as Search Provider'**
  String get extensionsSetAsSearch;

  /// No description provided for @storeTitle.
  ///
  /// In en, this message translates to:
  /// **'Extension Store'**
  String get storeTitle;

  /// No description provided for @storeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search extensions...'**
  String get storeSearch;

  /// No description provided for @storeInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get storeInstall;

  /// No description provided for @storeInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get storeInstalled;

  /// No description provided for @storeUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get storeUpdate;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutContributors.
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get aboutContributors;

  /// No description provided for @aboutMobileDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Mobile version developer'**
  String get aboutMobileDeveloper;

  /// No description provided for @aboutOriginalCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator of the original SpotiFLAC'**
  String get aboutOriginalCreator;

  /// No description provided for @aboutLogoArtist.
  ///
  /// In en, this message translates to:
  /// **'The talented artist who created our beautiful app logo!'**
  String get aboutLogoArtist;

  /// No description provided for @aboutSpecialThanks.
  ///
  /// In en, this message translates to:
  /// **'Special Thanks'**
  String get aboutSpecialThanks;

  /// No description provided for @aboutLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get aboutLinks;

  /// No description provided for @aboutMobileSource.
  ///
  /// In en, this message translates to:
  /// **'Mobile source code'**
  String get aboutMobileSource;

  /// No description provided for @aboutPCSource.
  ///
  /// In en, this message translates to:
  /// **'PC source code'**
  String get aboutPCSource;

  /// No description provided for @aboutReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get aboutReportIssue;

  /// No description provided for @aboutReportIssueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report any problems you encounter'**
  String get aboutReportIssueSubtitle;

  /// No description provided for @aboutFeatureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature request'**
  String get aboutFeatureRequest;

  /// No description provided for @aboutFeatureRequestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest new features for the app'**
  String get aboutFeatureRequestSubtitle;

  /// No description provided for @aboutSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get aboutSupport;

  /// No description provided for @aboutBuyMeCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get aboutBuyMeCoffee;

  /// No description provided for @aboutBuyMeCoffeeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Support development on Ko-fi'**
  String get aboutBuyMeCoffeeSubtitle;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get aboutApp;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @albumTitle.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get albumTitle;

  /// No description provided for @albumTracks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String albumTracks(int count);

  /// No description provided for @albumDownloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get albumDownloadAll;

  /// No description provided for @albumDownloadRemaining.
  ///
  /// In en, this message translates to:
  /// **'Download Remaining'**
  String get albumDownloadRemaining;

  /// No description provided for @playlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlistTitle;

  /// No description provided for @artistTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artistTitle;

  /// No description provided for @artistAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get artistAlbums;

  /// No description provided for @artistSingles.
  ///
  /// In en, this message translates to:
  /// **'Singles & EPs'**
  String get artistSingles;

  /// No description provided for @trackMetadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Info'**
  String get trackMetadataTitle;

  /// No description provided for @trackMetadataArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get trackMetadataArtist;

  /// No description provided for @trackMetadataAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get trackMetadataAlbum;

  /// No description provided for @trackMetadataDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get trackMetadataDuration;

  /// No description provided for @trackMetadataQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get trackMetadataQuality;

  /// No description provided for @trackMetadataPath.
  ///
  /// In en, this message translates to:
  /// **'File Path'**
  String get trackMetadataPath;

  /// No description provided for @trackMetadataDownloadedAt.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get trackMetadataDownloadedAt;

  /// No description provided for @trackMetadataService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get trackMetadataService;

  /// No description provided for @trackMetadataPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get trackMetadataPlay;

  /// No description provided for @trackMetadataShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get trackMetadataShare;

  /// No description provided for @trackMetadataDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get trackMetadataDelete;

  /// No description provided for @trackMetadataRedownload.
  ///
  /// In en, this message translates to:
  /// **'Re-download'**
  String get trackMetadataRedownload;

  /// No description provided for @trackMetadataOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get trackMetadataOpenFolder;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SpotiFLAC'**
  String get setupTitle;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you started'**
  String get setupSubtitle;

  /// No description provided for @setupStoragePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get setupStoragePermission;

  /// No description provided for @setupStoragePermissionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required to save downloaded files'**
  String get setupStoragePermissionSubtitle;

  /// No description provided for @setupStoragePermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Permission granted'**
  String get setupStoragePermissionGranted;

  /// No description provided for @setupStoragePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get setupStoragePermissionDenied;

  /// No description provided for @setupGrantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get setupGrantPermission;

  /// No description provided for @setupDownloadLocation.
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get setupDownloadLocation;

  /// No description provided for @setupChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get setupChooseFolder;

  /// No description provided for @setupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get setupContinue;

  /// No description provided for @setupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get setupSkip;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @dialogOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogOk;

  /// No description provided for @dialogSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dialogSave;

  /// No description provided for @dialogDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialogDelete;

  /// No description provided for @dialogRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get dialogRetry;

  /// No description provided for @dialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// No description provided for @dialogYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get dialogYes;

  /// No description provided for @dialogNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get dialogNo;

  /// No description provided for @dialogClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get dialogClear;

  /// No description provided for @dialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialogConfirm;

  /// No description provided for @dialogDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dialogDone;

  /// No description provided for @dialogClearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get dialogClearHistoryTitle;

  /// No description provided for @dialogClearHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all download history? This cannot be undone.'**
  String get dialogClearHistoryMessage;

  /// No description provided for @dialogDeleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get dialogDeleteSelectedTitle;

  /// No description provided for @dialogDeleteSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}} from history?\n\nThis will also delete the files from storage.'**
  String dialogDeleteSelectedMessage(int count);

  /// No description provided for @dialogImportPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Playlist'**
  String get dialogImportPlaylistTitle;

  /// No description provided for @dialogImportPlaylistMessage.
  ///
  /// In en, this message translates to:
  /// **'Found {count} tracks in CSV. Add them to download queue?'**
  String dialogImportPlaylistMessage(int count);

  /// No description provided for @snackbarAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added \"{trackName}\" to queue'**
  String snackbarAddedToQueue(String trackName);

  /// No description provided for @snackbarAddedTracksToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks to queue'**
  String snackbarAddedTracksToQueue(int count);

  /// No description provided for @snackbarAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'\"{trackName}\" already downloaded'**
  String snackbarAlreadyDownloaded(String trackName);

  /// No description provided for @snackbarHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get snackbarHistoryCleared;

  /// No description provided for @snackbarCredentialsSaved.
  ///
  /// In en, this message translates to:
  /// **'Credentials saved'**
  String get snackbarCredentialsSaved;

  /// No description provided for @snackbarCredentialsCleared.
  ///
  /// In en, this message translates to:
  /// **'Credentials cleared'**
  String get snackbarCredentialsCleared;

  /// No description provided for @snackbarDeletedTracks.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} {count, plural, =1{track} other{tracks}}'**
  String snackbarDeletedTracks(int count);

  /// No description provided for @snackbarCannotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot open file: {error}'**
  String snackbarCannotOpenFile(String error);

  /// No description provided for @snackbarFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get snackbarFillAllFields;

  /// No description provided for @snackbarViewQueue.
  ///
  /// In en, this message translates to:
  /// **'View Queue'**
  String get snackbarViewQueue;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Rate Limited'**
  String get errorRateLimited;

  /// No description provided for @errorRateLimitedMessage.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment before searching again.'**
  String get errorRateLimitedMessage;

  /// No description provided for @errorFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load {item}'**
  String errorFailedToLoad(String item);

  /// No description provided for @errorNoTracksFound.
  ///
  /// In en, this message translates to:
  /// **'No tracks found'**
  String get errorNoTracksFound;

  /// No description provided for @errorMissingExtensionSource.
  ///
  /// In en, this message translates to:
  /// **'Cannot load {item}: missing extension source'**
  String errorMissingExtensionSource(String item);

  /// No description provided for @statusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// No description provided for @statusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get statusDownloading;

  /// No description provided for @statusFinalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing'**
  String get statusFinalizing;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get statusSkipped;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @actionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// No description provided for @actionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get actionSelect;

  /// No description provided for @actionSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get actionSelectAll;

  /// No description provided for @actionDeselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get actionDeselect;

  /// No description provided for @actionPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get actionPaste;

  /// No description provided for @actionImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get actionImportCsv;

  /// No description provided for @actionRemoveCredentials.
  ///
  /// In en, this message translates to:
  /// **'Remove Credentials'**
  String get actionRemoveCredentials;

  /// No description provided for @actionSaveCredentials.
  ///
  /// In en, this message translates to:
  /// **'Save Credentials'**
  String get actionSaveCredentials;

  /// No description provided for @selectionSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectionSelected(int count);

  /// No description provided for @selectionAllSelected.
  ///
  /// In en, this message translates to:
  /// **'All tracks selected'**
  String get selectionAllSelected;

  /// No description provided for @selectionTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap tracks to select'**
  String get selectionTapToSelect;

  /// No description provided for @selectionDeleteTracks.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}}'**
  String selectionDeleteTracks(int count);

  /// No description provided for @selectionSelectToDelete.
  ///
  /// In en, this message translates to:
  /// **'Select tracks to delete'**
  String get selectionSelectToDelete;

  /// No description provided for @progressFetchingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Fetching metadata... {current}/{total}'**
  String progressFetchingMetadata(int current, int total);

  /// No description provided for @progressReadingCsv.
  ///
  /// In en, this message translates to:
  /// **'Reading CSV...'**
  String get progressReadingCsv;

  /// No description provided for @searchSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get searchSongs;

  /// No description provided for @searchArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get searchArtists;

  /// No description provided for @searchAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get searchAlbums;

  /// No description provided for @searchPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get searchPlaylists;

  /// No description provided for @tooltipPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get tooltipPlay;

  /// No description provided for @tooltipCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tooltipCancel;

  /// No description provided for @tooltipStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get tooltipStop;

  /// No description provided for @tooltipRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get tooltipRetry;

  /// No description provided for @tooltipRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get tooltipRemove;

  /// No description provided for @tooltipClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get tooltipClear;

  /// No description provided for @tooltipPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get tooltipPaste;

  /// No description provided for @filenameFormat.
  ///
  /// In en, this message translates to:
  /// **'Filename Format'**
  String get filenameFormat;

  /// No description provided for @filenameFormatPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview: {preview}'**
  String filenameFormatPreview(String preview);

  /// No description provided for @folderOrganization.
  ///
  /// In en, this message translates to:
  /// **'Folder Organization'**
  String get folderOrganization;

  /// No description provided for @folderOrganizationNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get folderOrganizationNone;

  /// No description provided for @folderOrganizationByArtist.
  ///
  /// In en, this message translates to:
  /// **'By Artist'**
  String get folderOrganizationByArtist;

  /// No description provided for @folderOrganizationByAlbum.
  ///
  /// In en, this message translates to:
  /// **'By Album'**
  String get folderOrganizationByAlbum;

  /// No description provided for @folderOrganizationByArtistAlbum.
  ///
  /// In en, this message translates to:
  /// **'By Artist & Album'**
  String get folderOrganizationByArtistAlbum;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @updateNewVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateNewVersion(String version);

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateChangelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get updateChangelog;

  /// No description provided for @providerPriority.
  ///
  /// In en, this message translates to:
  /// **'Provider Priority'**
  String get providerPriority;

  /// No description provided for @providerPrioritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder download providers'**
  String get providerPrioritySubtitle;

  /// No description provided for @metadataProviderPriority.
  ///
  /// In en, this message translates to:
  /// **'Metadata Provider Priority'**
  String get metadataProviderPriority;

  /// No description provided for @metadataProviderPrioritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order used when fetching track metadata'**
  String get metadataProviderPrioritySubtitle;

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logTitle;

  /// No description provided for @logCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy Logs'**
  String get logCopy;

  /// No description provided for @logClear.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get logClear;

  /// No description provided for @logShare.
  ///
  /// In en, this message translates to:
  /// **'Share Logs'**
  String get logShare;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logEmpty;

  /// No description provided for @logCopied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get logCopied;

  /// No description provided for @credentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spotify Credentials'**
  String get credentialsTitle;

  /// No description provided for @credentialsDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your Client ID and Secret to use your own Spotify application quota.'**
  String get credentialsDescription;

  /// No description provided for @credentialsClientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get credentialsClientId;

  /// No description provided for @credentialsClientIdHint.
  ///
  /// In en, this message translates to:
  /// **'Paste Client ID'**
  String get credentialsClientIdHint;

  /// No description provided for @credentialsClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Client Secret'**
  String get credentialsClientSecret;

  /// No description provided for @credentialsClientSecretHint.
  ///
  /// In en, this message translates to:
  /// **'Paste Client Secret'**
  String get credentialsClientSecretHint;

  /// No description provided for @channelStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get channelStable;

  /// No description provided for @channelPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get channelPreview;

  /// No description provided for @sectionSearchSource.
  ///
  /// In en, this message translates to:
  /// **'Search Source'**
  String get sectionSearchSource;

  /// No description provided for @sectionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get sectionDownload;

  /// No description provided for @sectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get sectionPerformance;

  /// No description provided for @sectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sectionApp;

  /// No description provided for @sectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get sectionData;

  /// No description provided for @sectionDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get sectionDebug;

  /// No description provided for @sectionService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get sectionService;

  /// No description provided for @sectionAudioQuality.
  ///
  /// In en, this message translates to:
  /// **'Audio Quality'**
  String get sectionAudioQuality;

  /// No description provided for @sectionFileSettings.
  ///
  /// In en, this message translates to:
  /// **'File Settings'**
  String get sectionFileSettings;

  /// No description provided for @sectionColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get sectionColor;

  /// No description provided for @sectionTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get sectionTheme;

  /// No description provided for @sectionLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get sectionLayout;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, colors, display'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsDownloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Service, quality, filename format'**
  String get settingsDownloadSubtitle;

  /// No description provided for @settingsOptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fallback, lyrics, cover art, updates'**
  String get settingsOptionsSubtitle;

  /// No description provided for @settingsExtensionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage download providers'**
  String get settingsExtensionsSubtitle;

  /// No description provided for @settingsLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View app logs for debugging'**
  String get settingsLogsSubtitle;

  /// No description provided for @loadingSharedLink.
  ///
  /// In en, this message translates to:
  /// **'Loading shared link...'**
  String get loadingSharedLink;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @artistReleases.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 release} other{{count} releases}}'**
  String artistReleases(int count);

  /// No description provided for @artistCompilations.
  ///
  /// In en, this message translates to:
  /// **'Compilations'**
  String get artistCompilations;

  /// No description provided for @tracksHeader.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracksHeader;

  /// No description provided for @downloadAllCount.
  ///
  /// In en, this message translates to:
  /// **'Download All ({count})'**
  String downloadAllCount(int count);

  /// No description provided for @tracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String tracksCount(int count);

  /// No description provided for @setupStorageAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage Access Required'**
  String get setupStorageAccessRequired;

  /// No description provided for @setupStorageAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'SpotiFLAC needs \"All files access\" permission to save music files to your chosen folder.'**
  String get setupStorageAccessMessage;

  /// No description provided for @setupStorageAccessMessageAndroid11.
  ///
  /// In en, this message translates to:
  /// **'Android 11+ requires \"All files access\" permission to save files to your chosen download folder.'**
  String get setupStorageAccessMessageAndroid11;

  /// No description provided for @setupOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get setupOpenSettings;

  /// No description provided for @setupPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please grant all permissions to continue.'**
  String get setupPermissionDeniedMessage;

  /// No description provided for @setupPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'{permissionType} Permission Required'**
  String setupPermissionRequired(String permissionType);

  /// No description provided for @setupPermissionRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'{permissionType} permission is required for the best experience. You can change this later in Settings.'**
  String setupPermissionRequiredMessage(String permissionType);

  /// No description provided for @setupSelectDownloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Download Folder'**
  String get setupSelectDownloadFolder;

  /// No description provided for @setupUseDefaultFolder.
  ///
  /// In en, this message translates to:
  /// **'Use Default Folder?'**
  String get setupUseDefaultFolder;

  /// No description provided for @setupNoFolderSelected.
  ///
  /// In en, this message translates to:
  /// **'No folder selected. Would you like to use the default Music folder?'**
  String get setupNoFolderSelected;

  /// No description provided for @setupUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use Default'**
  String get setupUseDefault;

  /// No description provided for @setupDownloadLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get setupDownloadLocationTitle;

  /// No description provided for @setupDownloadLocationIosMessage.
  ///
  /// In en, this message translates to:
  /// **'On iOS, downloads are saved to the app\'s Documents folder. You can access them via the Files app.'**
  String get setupDownloadLocationIosMessage;

  /// No description provided for @setupAppDocumentsFolder.
  ///
  /// In en, this message translates to:
  /// **'App Documents Folder'**
  String get setupAppDocumentsFolder;

  /// No description provided for @setupAppDocumentsFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended - accessible via Files app'**
  String get setupAppDocumentsFolderSubtitle;

  /// No description provided for @setupChooseFromFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose from Files'**
  String get setupChooseFromFiles;

  /// No description provided for @setupChooseFromFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select iCloud or other location'**
  String get setupChooseFromFilesSubtitle;

  /// No description provided for @setupIosEmptyFolderWarning.
  ///
  /// In en, this message translates to:
  /// **'iOS limitation: Empty folders cannot be selected. Choose a folder with at least one file.'**
  String get setupIosEmptyFolderWarning;

  /// No description provided for @setupDownloadInFlac.
  ///
  /// In en, this message translates to:
  /// **'Download Spotify tracks in FLAC'**
  String get setupDownloadInFlac;

  /// No description provided for @setupStepStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get setupStepStorage;

  /// No description provided for @setupStepNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get setupStepNotification;

  /// No description provided for @setupStepFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get setupStepFolder;

  /// No description provided for @setupStepSpotify.
  ///
  /// In en, this message translates to:
  /// **'Spotify'**
  String get setupStepSpotify;

  /// No description provided for @setupStepPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get setupStepPermission;

  /// No description provided for @setupStorageGranted.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Granted!'**
  String get setupStorageGranted;

  /// No description provided for @setupStorageRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission Required'**
  String get setupStorageRequired;

  /// No description provided for @setupStorageDescription.
  ///
  /// In en, this message translates to:
  /// **'SpotiFLAC needs storage permission to save your downloaded music files.'**
  String get setupStorageDescription;

  /// No description provided for @setupNotificationGranted.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Granted!'**
  String get setupNotificationGranted;

  /// No description provided for @setupNotificationEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get setupNotificationEnable;

  /// No description provided for @setupNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified when downloads complete or require attention.'**
  String get setupNotificationDescription;

  /// No description provided for @setupFolderSelected.
  ///
  /// In en, this message translates to:
  /// **'Download Folder Selected!'**
  String get setupFolderSelected;

  /// No description provided for @setupFolderChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose Download Folder'**
  String get setupFolderChoose;

  /// No description provided for @setupFolderDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a folder where your downloaded music will be saved.'**
  String get setupFolderDescription;

  /// No description provided for @setupChangeFolder.
  ///
  /// In en, this message translates to:
  /// **'Change Folder'**
  String get setupChangeFolder;

  /// No description provided for @setupSelectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get setupSelectFolder;

  /// No description provided for @setupSpotifyApiOptional.
  ///
  /// In en, this message translates to:
  /// **'Spotify API (Optional)'**
  String get setupSpotifyApiOptional;

  /// No description provided for @setupSpotifyApiDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your Spotify API credentials for better search results and access to Spotify-exclusive content.'**
  String get setupSpotifyApiDescription;

  /// No description provided for @setupUseSpotifyApi.
  ///
  /// In en, this message translates to:
  /// **'Use Spotify API'**
  String get setupUseSpotifyApi;

  /// No description provided for @setupEnterCredentialsBelow.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials below'**
  String get setupEnterCredentialsBelow;

  /// No description provided for @setupUsingDeezer.
  ///
  /// In en, this message translates to:
  /// **'Using Deezer (no account needed)'**
  String get setupUsingDeezer;

  /// No description provided for @setupEnterClientId.
  ///
  /// In en, this message translates to:
  /// **'Enter Spotify Client ID'**
  String get setupEnterClientId;

  /// No description provided for @setupEnterClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Enter Spotify Client Secret'**
  String get setupEnterClientSecret;

  /// No description provided for @setupGetFreeCredentials.
  ///
  /// In en, this message translates to:
  /// **'Get your free API credentials from the Spotify Developer Dashboard.'**
  String get setupGetFreeCredentials;

  /// No description provided for @setupEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get setupEnableNotifications;

  /// No description provided for @dialogImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get dialogImport;

  /// No description provided for @dialogDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get dialogDiscard;

  /// No description provided for @dialogRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dialogRemove;

  /// No description provided for @dialogUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get dialogUninstall;

  /// No description provided for @dialogDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get dialogDiscardChanges;

  /// No description provided for @dialogUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get dialogUnsavedChanges;

  /// No description provided for @dialogDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get dialogDownloadFailed;

  /// No description provided for @dialogTrackLabel.
  ///
  /// In en, this message translates to:
  /// **'Track:'**
  String get dialogTrackLabel;

  /// No description provided for @dialogArtistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist:'**
  String get dialogArtistLabel;

  /// No description provided for @dialogErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get dialogErrorLabel;

  /// No description provided for @dialogClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get dialogClearAll;

  /// No description provided for @dialogClearAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all downloads?'**
  String get dialogClearAllDownloads;

  /// No description provided for @dialogRemoveFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove from device?'**
  String get dialogRemoveFromDevice;

  /// No description provided for @dialogRemoveExtension.
  ///
  /// In en, this message translates to:
  /// **'Remove Extension'**
  String get dialogRemoveExtension;

  /// No description provided for @dialogRemoveExtensionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this extension? This cannot be undone.'**
  String get dialogRemoveExtensionMessage;

  /// No description provided for @dialogUninstallExtension.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Extension?'**
  String get dialogUninstallExtension;

  /// No description provided for @dialogUninstallExtensionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {extensionName}?'**
  String dialogUninstallExtensionMessage(String extensionName);

  /// No description provided for @snackbarFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String snackbarFailedToLoad(String error);

  /// No description provided for @snackbarUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'{platform} URL copied to clipboard'**
  String snackbarUrlCopied(String platform);

  /// No description provided for @snackbarFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get snackbarFileNotFound;

  /// No description provided for @snackbarSelectExtFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a .spotiflac-ext file'**
  String get snackbarSelectExtFile;

  /// No description provided for @snackbarProviderPrioritySaved.
  ///
  /// In en, this message translates to:
  /// **'Provider priority saved'**
  String get snackbarProviderPrioritySaved;

  /// No description provided for @snackbarMetadataProviderSaved.
  ///
  /// In en, this message translates to:
  /// **'Metadata provider priority saved'**
  String get snackbarMetadataProviderSaved;

  /// No description provided for @snackbarExtensionInstalled.
  ///
  /// In en, this message translates to:
  /// **'{extensionName} installed.'**
  String snackbarExtensionInstalled(String extensionName);

  /// No description provided for @snackbarExtensionUpdated.
  ///
  /// In en, this message translates to:
  /// **'{extensionName} updated.'**
  String snackbarExtensionUpdated(String extensionName);

  /// No description provided for @snackbarFailedToInstall.
  ///
  /// In en, this message translates to:
  /// **'Failed to install extension'**
  String get snackbarFailedToInstall;

  /// No description provided for @snackbarFailedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update extension'**
  String get snackbarFailedToUpdate;

  /// No description provided for @storeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get storeFilterAll;

  /// No description provided for @storeFilterMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get storeFilterMetadata;

  /// No description provided for @storeFilterDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get storeFilterDownload;

  /// No description provided for @storeFilterUtility.
  ///
  /// In en, this message translates to:
  /// **'Utility'**
  String get storeFilterUtility;

  /// No description provided for @storeFilterLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get storeFilterLyrics;

  /// No description provided for @storeFilterIntegration.
  ///
  /// In en, this message translates to:
  /// **'Integration'**
  String get storeFilterIntegration;

  /// No description provided for @storeClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get storeClearFilters;

  /// No description provided for @storeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No extensions found'**
  String get storeNoResults;

  /// No description provided for @extensionProviderPriority.
  ///
  /// In en, this message translates to:
  /// **'Provider Priority'**
  String get extensionProviderPriority;

  /// No description provided for @extensionInstallButton.
  ///
  /// In en, this message translates to:
  /// **'Install Extension'**
  String get extensionInstallButton;

  /// No description provided for @extensionDefaultProvider.
  ///
  /// In en, this message translates to:
  /// **'Default (Deezer/Spotify)'**
  String get extensionDefaultProvider;

  /// No description provided for @extensionDefaultProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use built-in search'**
  String get extensionDefaultProviderSubtitle;

  /// No description provided for @extensionAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get extensionAuthor;

  /// No description provided for @extensionId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get extensionId;

  /// No description provided for @extensionError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get extensionError;

  /// No description provided for @extensionCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get extensionCapabilities;

  /// No description provided for @extensionMetadataProvider.
  ///
  /// In en, this message translates to:
  /// **'Metadata Provider'**
  String get extensionMetadataProvider;

  /// No description provided for @extensionDownloadProvider.
  ///
  /// In en, this message translates to:
  /// **'Download Provider'**
  String get extensionDownloadProvider;

  /// No description provided for @extensionLyricsProvider.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Provider'**
  String get extensionLyricsProvider;

  /// No description provided for @extensionUrlHandler.
  ///
  /// In en, this message translates to:
  /// **'URL Handler'**
  String get extensionUrlHandler;

  /// No description provided for @extensionQualityOptions.
  ///
  /// In en, this message translates to:
  /// **'Quality Options'**
  String get extensionQualityOptions;

  /// No description provided for @extensionPostProcessingHooks.
  ///
  /// In en, this message translates to:
  /// **'Post-Processing Hooks'**
  String get extensionPostProcessingHooks;

  /// No description provided for @extensionPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get extensionPermissions;

  /// No description provided for @extensionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get extensionSettings;

  /// No description provided for @extensionRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove Extension'**
  String get extensionRemoveButton;

  /// No description provided for @extensionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get extensionUpdated;

  /// No description provided for @extensionMinAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Min App Version'**
  String get extensionMinAppVersion;

  /// No description provided for @qualityFlacLossless.
  ///
  /// In en, this message translates to:
  /// **'FLAC Lossless'**
  String get qualityFlacLossless;

  /// No description provided for @qualityFlacLosslessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'16-bit / 44.1kHz'**
  String get qualityFlacLosslessSubtitle;

  /// No description provided for @qualityHiResFlac.
  ///
  /// In en, this message translates to:
  /// **'Hi-Res FLAC'**
  String get qualityHiResFlac;

  /// No description provided for @qualityHiResFlacSubtitle.
  ///
  /// In en, this message translates to:
  /// **'24-bit / up to 96kHz'**
  String get qualityHiResFlacSubtitle;

  /// No description provided for @qualityHiResFlacMax.
  ///
  /// In en, this message translates to:
  /// **'Hi-Res FLAC Max'**
  String get qualityHiResFlacMax;

  /// No description provided for @qualityHiResFlacMaxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'24-bit / up to 192kHz'**
  String get qualityHiResFlacMaxSubtitle;

  /// No description provided for @qualityNote.
  ///
  /// In en, this message translates to:
  /// **'Actual quality depends on track availability from the service'**
  String get qualityNote;

  /// No description provided for @downloadAskBeforeDownload.
  ///
  /// In en, this message translates to:
  /// **'Ask Before Download'**
  String get downloadAskBeforeDownload;

  /// No description provided for @downloadDirectory.
  ///
  /// In en, this message translates to:
  /// **'Download Directory'**
  String get downloadDirectory;

  /// No description provided for @downloadSeparateSinglesFolder.
  ///
  /// In en, this message translates to:
  /// **'Separate Singles Folder'**
  String get downloadSeparateSinglesFolder;

  /// No description provided for @downloadAlbumFolderStructure.
  ///
  /// In en, this message translates to:
  /// **'Album Folder Structure'**
  String get downloadAlbumFolderStructure;

  /// No description provided for @downloadSaveFormat.
  ///
  /// In en, this message translates to:
  /// **'Save Format'**
  String get downloadSaveFormat;

  /// No description provided for @downloadSelectService.
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get downloadSelectService;

  /// No description provided for @downloadSelectQuality.
  ///
  /// In en, this message translates to:
  /// **'Select Quality'**
  String get downloadSelectQuality;

  /// No description provided for @downloadFrom.
  ///
  /// In en, this message translates to:
  /// **'Download From'**
  String get downloadFrom;

  /// No description provided for @downloadDefaultQualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Quality'**
  String get downloadDefaultQualityLabel;

  /// No description provided for @downloadBestAvailable.
  ///
  /// In en, this message translates to:
  /// **'Best available'**
  String get downloadBestAvailable;

  /// No description provided for @folderNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get folderNone;

  /// No description provided for @folderNoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save all files directly to download folder'**
  String get folderNoneSubtitle;

  /// No description provided for @folderArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get folderArtist;

  /// No description provided for @folderArtistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Artist Name/filename'**
  String get folderArtistSubtitle;

  /// No description provided for @folderAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get folderAlbum;

  /// No description provided for @folderAlbumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Album Name/filename'**
  String get folderAlbumSubtitle;

  /// No description provided for @folderArtistAlbum.
  ///
  /// In en, this message translates to:
  /// **'Artist/Album'**
  String get folderArtistAlbum;

  /// No description provided for @folderArtistAlbumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Artist Name/Album Name/filename'**
  String get folderArtistAlbumSubtitle;

  /// No description provided for @serviceTidal.
  ///
  /// In en, this message translates to:
  /// **'Tidal'**
  String get serviceTidal;

  /// No description provided for @serviceQobuz.
  ///
  /// In en, this message translates to:
  /// **'Qobuz'**
  String get serviceQobuz;

  /// No description provided for @serviceAmazon.
  ///
  /// In en, this message translates to:
  /// **'Amazon'**
  String get serviceAmazon;

  /// No description provided for @serviceDeezer.
  ///
  /// In en, this message translates to:
  /// **'Deezer'**
  String get serviceDeezer;

  /// No description provided for @serviceSpotify.
  ///
  /// In en, this message translates to:
  /// **'Spotify'**
  String get serviceSpotify;

  /// No description provided for @logSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search logs...'**
  String get logSearchHint;

  /// No description provided for @logFilterLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get logFilterLevel;

  /// No description provided for @logFilterSection.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get logFilterSection;

  /// No description provided for @logShareLogs.
  ///
  /// In en, this message translates to:
  /// **'Share logs'**
  String get logShareLogs;

  /// No description provided for @logClearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get logClearLogs;

  /// No description provided for @logClearLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get logClearLogsTitle;

  /// No description provided for @logClearLogsMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all logs?'**
  String get logClearLogsMessage;

  /// No description provided for @logIspBlocking.
  ///
  /// In en, this message translates to:
  /// **'ISP BLOCKING DETECTED'**
  String get logIspBlocking;

  /// No description provided for @logRateLimited.
  ///
  /// In en, this message translates to:
  /// **'RATE LIMITED'**
  String get logRateLimited;

  /// No description provided for @logNetworkError.
  ///
  /// In en, this message translates to:
  /// **'NETWORK ERROR'**
  String get logNetworkError;

  /// No description provided for @logTrackNotFound.
  ///
  /// In en, this message translates to:
  /// **'TRACK NOT FOUND'**
  String get logTrackNotFound;

  /// No description provided for @appearanceAmoledDark.
  ///
  /// In en, this message translates to:
  /// **'AMOLED Dark'**
  String get appearanceAmoledDark;

  /// No description provided for @appearanceAmoledDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pure black background'**
  String get appearanceAmoledDarkSubtitle;

  /// No description provided for @appearanceChooseAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Choose Accent Color'**
  String get appearanceChooseAccentColor;

  /// No description provided for @appearanceChooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get appearanceChooseTheme;

  /// No description provided for @updateStartingDownload.
  ///
  /// In en, this message translates to:
  /// **'Starting download...'**
  String get updateStartingDownload;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get updateDownloadFailed;

  /// No description provided for @updateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to download update'**
  String get updateFailedMessage;

  /// No description provided for @updateNewVersionReady.
  ///
  /// In en, this message translates to:
  /// **'A new version is ready'**
  String get updateNewVersionReady;

  /// No description provided for @updateCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get updateCurrent;

  /// No description provided for @updateNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get updateNew;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get updateDownloading;

  /// No description provided for @updateWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get updateWhatsNew;

  /// No description provided for @updateDownloadInstall.
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get updateDownloadInstall;

  /// No description provided for @updateDontRemind.
  ///
  /// In en, this message translates to:
  /// **'Don\'t remind'**
  String get updateDontRemind;

  /// No description provided for @trackCopyFilePath.
  ///
  /// In en, this message translates to:
  /// **'Copy file path'**
  String get trackCopyFilePath;

  /// No description provided for @trackRemoveFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove from device'**
  String get trackRemoveFromDevice;

  /// No description provided for @trackLoadLyrics.
  ///
  /// In en, this message translates to:
  /// **'Load Lyrics'**
  String get trackLoadLyrics;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String dateDaysAgo(int count);

  /// No description provided for @dateWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String dateWeeksAgo(int count);

  /// No description provided for @dateMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String dateMonthsAgo(int count);

  /// No description provided for @concurrentSequential.
  ///
  /// In en, this message translates to:
  /// **'Sequential'**
  String get concurrentSequential;

  /// No description provided for @concurrentParallel2.
  ///
  /// In en, this message translates to:
  /// **'2 Parallel'**
  String get concurrentParallel2;

  /// No description provided for @concurrentParallel3.
  ///
  /// In en, this message translates to:
  /// **'3 Parallel'**
  String get concurrentParallel3;

  /// No description provided for @filenameAvailablePlaceholders.
  ///
  /// In en, this message translates to:
  /// **'Available placeholders:'**
  String get filenameAvailablePlaceholders;

  /// No description provided for @filenameHint.
  ///
  /// In en, this message translates to:
  /// **'{artist} - {title}'**
  String filenameHint(Object artist, Object title);

  /// No description provided for @tapToSeeError.
  ///
  /// In en, this message translates to:
  /// **'Tap to see error details'**
  String get tapToSeeError;

  /// No description provided for @setupProceedToNextStep.
  ///
  /// In en, this message translates to:
  /// **'You can now proceed to the next step.'**
  String get setupProceedToNextStep;

  /// No description provided for @setupNotificationProgressDescription.
  ///
  /// In en, this message translates to:
  /// **'You will receive download progress notifications.'**
  String get setupNotificationProgressDescription;

  /// No description provided for @setupNotificationBackgroundDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified about download progress and completion. This helps you track downloads when the app is in background.'**
  String get setupNotificationBackgroundDescription;

  /// No description provided for @setupSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get setupSkipForNow;

  /// No description provided for @setupBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get setupBack;

  /// No description provided for @setupNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get setupNext;

  /// No description provided for @setupGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get setupGetStarted;

  /// No description provided for @setupSkipAndStart.
  ///
  /// In en, this message translates to:
  /// **'Skip & Start'**
  String get setupSkipAndStart;

  /// No description provided for @setupAllowAccessToManageFiles.
  ///
  /// In en, this message translates to:
  /// **'Please enable \"Allow access to manage all files\" in the next screen.'**
  String get setupAllowAccessToManageFiles;

  /// No description provided for @setupGetCredentialsFromSpotify.
  ///
  /// In en, this message translates to:
  /// **'Get credentials from developer.spotify.com'**
  String get setupGetCredentialsFromSpotify;

  /// No description provided for @trackMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get trackMetadata;

  /// No description provided for @trackFileInfo.
  ///
  /// In en, this message translates to:
  /// **'File Info'**
  String get trackFileInfo;

  /// No description provided for @trackLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get trackLyrics;

  /// No description provided for @trackFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get trackFileNotFound;

  /// No description provided for @trackOpenInDeezer.
  ///
  /// In en, this message translates to:
  /// **'Open in Deezer'**
  String get trackOpenInDeezer;

  /// No description provided for @trackOpenInSpotify.
  ///
  /// In en, this message translates to:
  /// **'Open in Spotify'**
  String get trackOpenInSpotify;

  /// No description provided for @trackTrackName.
  ///
  /// In en, this message translates to:
  /// **'Track name'**
  String get trackTrackName;

  /// No description provided for @trackArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get trackArtist;

  /// No description provided for @trackAlbumArtist.
  ///
  /// In en, this message translates to:
  /// **'Album artist'**
  String get trackAlbumArtist;

  /// No description provided for @trackAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get trackAlbum;

  /// No description provided for @trackTrackNumber.
  ///
  /// In en, this message translates to:
  /// **'Track number'**
  String get trackTrackNumber;

  /// No description provided for @trackDiscNumber.
  ///
  /// In en, this message translates to:
  /// **'Disc number'**
  String get trackDiscNumber;

  /// No description provided for @trackDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get trackDuration;

  /// No description provided for @trackAudioQuality.
  ///
  /// In en, this message translates to:
  /// **'Audio quality'**
  String get trackAudioQuality;

  /// No description provided for @trackReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release date'**
  String get trackReleaseDate;

  /// No description provided for @trackDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get trackDownloaded;

  /// No description provided for @trackCopyLyrics.
  ///
  /// In en, this message translates to:
  /// **'Copy lyrics'**
  String get trackCopyLyrics;

  /// No description provided for @trackLyricsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Lyrics not available for this track'**
  String get trackLyricsNotAvailable;

  /// No description provided for @trackLyricsTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Try again later.'**
  String get trackLyricsTimeout;

  /// No description provided for @trackLyricsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load lyrics'**
  String get trackLyricsLoadFailed;

  /// No description provided for @trackCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get trackCopiedToClipboard;

  /// No description provided for @trackDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from device?'**
  String get trackDeleteConfirmTitle;

  /// No description provided for @trackDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the downloaded file and remove it from your history.'**
  String get trackDeleteConfirmMessage;

  /// No description provided for @trackCannotOpen.
  ///
  /// In en, this message translates to:
  /// **'Cannot open: {message}'**
  String trackCannotOpen(String message);

  /// No description provided for @logFilterBySeverity.
  ///
  /// In en, this message translates to:
  /// **'Filter logs by severity'**
  String get logFilterBySeverity;

  /// No description provided for @logNoLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logNoLogsYet;

  /// No description provided for @logNoLogsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Logs will appear here as you use the app'**
  String get logNoLogsYetSubtitle;

  /// No description provided for @logIssueSummary.
  ///
  /// In en, this message translates to:
  /// **'Issue Summary'**
  String get logIssueSummary;

  /// No description provided for @logIspBlockingDescription.
  ///
  /// In en, this message translates to:
  /// **'Your ISP may be blocking access to download services'**
  String get logIspBlockingDescription;

  /// No description provided for @logIspBlockingSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Try using a VPN or change DNS to 1.1.1.1 or 8.8.8.8'**
  String get logIspBlockingSuggestion;

  /// No description provided for @logRateLimitedDescription.
  ///
  /// In en, this message translates to:
  /// **'Too many requests to the service'**
  String get logRateLimitedDescription;

  /// No description provided for @logRateLimitedSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Wait a few minutes before trying again'**
  String get logRateLimitedSuggestion;

  /// No description provided for @logNetworkErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Connection issues detected'**
  String get logNetworkErrorDescription;

  /// No description provided for @logNetworkErrorSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get logNetworkErrorSuggestion;

  /// No description provided for @logTrackNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Some tracks could not be found on download services'**
  String get logTrackNotFoundDescription;

  /// No description provided for @logTrackNotFoundSuggestion.
  ///
  /// In en, this message translates to:
  /// **'The track may not be available in lossless quality'**
  String get logTrackNotFoundSuggestion;

  /// No description provided for @logTotalErrors.
  ///
  /// In en, this message translates to:
  /// **'Total errors: {count}'**
  String logTotalErrors(int count);

  /// No description provided for @logAffected.
  ///
  /// In en, this message translates to:
  /// **'Affected: {domains}'**
  String logAffected(String domains);

  /// No description provided for @logEntriesFiltered.
  ///
  /// In en, this message translates to:
  /// **'Entries ({count} filtered)'**
  String logEntriesFiltered(int count);

  /// No description provided for @logEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries ({count})'**
  String logEntries(int count);

  /// No description provided for @extensionsProviderPrioritySection.
  ///
  /// In en, this message translates to:
  /// **'Provider Priority'**
  String get extensionsProviderPrioritySection;

  /// No description provided for @extensionsInstalledSection.
  ///
  /// In en, this message translates to:
  /// **'Installed Extensions'**
  String get extensionsInstalledSection;

  /// No description provided for @extensionsNoExtensions.
  ///
  /// In en, this message translates to:
  /// **'No extensions installed'**
  String get extensionsNoExtensions;

  /// No description provided for @extensionsNoExtensionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Install .spotiflac-ext files to add new providers'**
  String get extensionsNoExtensionsSubtitle;

  /// No description provided for @extensionsInstallButton.
  ///
  /// In en, this message translates to:
  /// **'Install Extension'**
  String get extensionsInstallButton;

  /// No description provided for @extensionsInfoTip.
  ///
  /// In en, this message translates to:
  /// **'Extensions can add new metadata and download providers. Only install extensions from trusted sources.'**
  String get extensionsInfoTip;

  /// No description provided for @extensionsInstalledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Extension installed successfully'**
  String get extensionsInstalledSuccess;

  /// No description provided for @extensionsDownloadPriority.
  ///
  /// In en, this message translates to:
  /// **'Download Priority'**
  String get extensionsDownloadPriority;

  /// No description provided for @extensionsDownloadPrioritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set download service order'**
  String get extensionsDownloadPrioritySubtitle;

  /// No description provided for @extensionsNoDownloadProvider.
  ///
  /// In en, this message translates to:
  /// **'No extensions with download provider'**
  String get extensionsNoDownloadProvider;

  /// No description provided for @extensionsMetadataPriority.
  ///
  /// In en, this message translates to:
  /// **'Metadata Priority'**
  String get extensionsMetadataPriority;

  /// No description provided for @extensionsMetadataPrioritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set search & metadata source order'**
  String get extensionsMetadataPrioritySubtitle;

  /// No description provided for @extensionsNoMetadataProvider.
  ///
  /// In en, this message translates to:
  /// **'No extensions with metadata provider'**
  String get extensionsNoMetadataProvider;

  /// No description provided for @extensionsSearchProvider.
  ///
  /// In en, this message translates to:
  /// **'Search Provider'**
  String get extensionsSearchProvider;

  /// No description provided for @extensionsNoCustomSearch.
  ///
  /// In en, this message translates to:
  /// **'No extensions with custom search'**
  String get extensionsNoCustomSearch;

  /// No description provided for @extensionsSearchProviderDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which service to use for searching tracks'**
  String get extensionsSearchProviderDescription;

  /// No description provided for @extensionsCustomSearch.
  ///
  /// In en, this message translates to:
  /// **'Custom search'**
  String get extensionsCustomSearch;

  /// No description provided for @extensionsErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading extension'**
  String get extensionsErrorLoading;

  /// No description provided for @extensionCustomTrackMatching.
  ///
  /// In en, this message translates to:
  /// **'Custom Track Matching'**
  String get extensionCustomTrackMatching;

  /// No description provided for @extensionPostProcessing.
  ///
  /// In en, this message translates to:
  /// **'Post-Processing'**
  String get extensionPostProcessing;

  /// No description provided for @extensionHooksAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} hook(s) available'**
  String extensionHooksAvailable(int count);

  /// No description provided for @extensionPatternsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pattern(s)'**
  String extensionPatternsCount(int count);

  /// No description provided for @extensionStrategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy: {strategy}'**
  String extensionStrategy(String strategy);

  /// No description provided for @aboutDoubleDouble.
  ///
  /// In en, this message translates to:
  /// **'DoubleDouble'**
  String get aboutDoubleDouble;

  /// No description provided for @aboutDoubleDoubleDesc.
  ///
  /// In en, this message translates to:
  /// **'Amazing API for Amazon Music downloads. Thank you for making it free!'**
  String get aboutDoubleDoubleDesc;

  /// No description provided for @aboutDabMusic.
  ///
  /// In en, this message translates to:
  /// **'DAB Music'**
  String get aboutDabMusic;

  /// No description provided for @aboutDabMusicDesc.
  ///
  /// In en, this message translates to:
  /// **'The best Qobuz streaming API. Hi-Res downloads wouldn\'t be possible without this!'**
  String get aboutDabMusicDesc;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Queue'**
  String get queueTitle;

  /// No description provided for @queueClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get queueClearAll;

  /// No description provided for @queueClearAllMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all downloads?'**
  String get queueClearAllMessage;

  /// No description provided for @albumFolderArtistAlbum.
  ///
  /// In en, this message translates to:
  /// **'Artist / Album'**
  String get albumFolderArtistAlbum;

  /// No description provided for @albumFolderArtistAlbumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Albums/Artist Name/Album Name/'**
  String get albumFolderArtistAlbumSubtitle;

  /// No description provided for @albumFolderArtistYearAlbum.
  ///
  /// In en, this message translates to:
  /// **'Artist / [Year] Album'**
  String get albumFolderArtistYearAlbum;

  /// No description provided for @albumFolderArtistYearAlbumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Albums/Artist Name/[2005] Album Name/'**
  String get albumFolderArtistYearAlbumSubtitle;

  /// No description provided for @albumFolderAlbumOnly.
  ///
  /// In en, this message translates to:
  /// **'Album Only'**
  String get albumFolderAlbumOnly;

  /// No description provided for @albumFolderAlbumOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Albums/Album Name/'**
  String get albumFolderAlbumOnlySubtitle;

  /// No description provided for @albumFolderYearAlbum.
  ///
  /// In en, this message translates to:
  /// **'[Year] Album'**
  String get albumFolderYearAlbum;

  /// No description provided for @albumFolderYearAlbumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Albums/[2005] Album Name/'**
  String get albumFolderYearAlbumSubtitle;

  /// No description provided for @downloadedAlbumDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get downloadedAlbumDeleteSelected;

  /// No description provided for @downloadedAlbumDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}} from this album?\n\nThis will also delete the files from storage.'**
  String downloadedAlbumDeleteMessage(int count);

  /// No description provided for @utilityFunctions.
  ///
  /// In en, this message translates to:
  /// **'Utility Functions'**
  String get utilityFunctions;

  /// No description provided for @aboutBinimumDesc.
  ///
  /// In en, this message translates to:
  /// **'The creator of QQDL & HiFi API. Without this API, Tidal downloads wouldn\'t exist!'**
  String get aboutBinimumDesc;

  /// No description provided for @aboutSachinsenalDesc.
  ///
  /// In en, this message translates to:
  /// **'The original HiFi project creator. The foundation of Tidal integration!'**
  String get aboutSachinsenalDesc;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Download Spotify tracks in lossless quality from Tidal, Qobuz, and Amazon Music.'**
  String get aboutAppDescription;

  /// No description provided for @providerPriorityTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider Priority'**
  String get providerPriorityTitle;

  /// No description provided for @providerPriorityDescription.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder download providers. The app will try providers from top to bottom when downloading tracks.'**
  String get providerPriorityDescription;

  /// No description provided for @providerPriorityInfo.
  ///
  /// In en, this message translates to:
  /// **'If a track is not available on the first provider, the app will automatically try the next one.'**
  String get providerPriorityInfo;

  /// No description provided for @providerBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get providerBuiltIn;

  /// No description provided for @providerExtension.
  ///
  /// In en, this message translates to:
  /// **'Extension'**
  String get providerExtension;

  /// No description provided for @metadataProviderPriorityTitle.
  ///
  /// In en, this message translates to:
  /// **'Metadata Priority'**
  String get metadataProviderPriorityTitle;

  /// No description provided for @metadataProviderPriorityDescription.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder metadata providers. The app will try providers from top to bottom when searching for tracks and fetching metadata.'**
  String get metadataProviderPriorityDescription;

  /// No description provided for @metadataProviderPriorityInfo.
  ///
  /// In en, this message translates to:
  /// **'Deezer has no rate limits and is recommended as primary. Spotify may rate limit after many requests.'**
  String get metadataProviderPriorityInfo;

  /// No description provided for @metadataNoRateLimits.
  ///
  /// In en, this message translates to:
  /// **'No rate limits'**
  String get metadataNoRateLimits;

  /// No description provided for @metadataMayRateLimit.
  ///
  /// In en, this message translates to:
  /// **'May rate limit'**
  String get metadataMayRateLimit;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No downloads in queue'**
  String get queueEmpty;

  /// No description provided for @queueEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add tracks from the home screen'**
  String get queueEmptySubtitle;

  /// No description provided for @queueClearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clear completed'**
  String get queueClearCompleted;

  /// No description provided for @queueDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get queueDownloadFailed;

  /// No description provided for @queueTrackLabel.
  ///
  /// In en, this message translates to:
  /// **'Track:'**
  String get queueTrackLabel;

  /// No description provided for @queueArtistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist:'**
  String get queueArtistLabel;

  /// No description provided for @queueErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get queueErrorLabel;

  /// No description provided for @queueUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get queueUnknownError;

  /// No description provided for @downloadedAlbumTracksHeader.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get downloadedAlbumTracksHeader;

  /// No description provided for @downloadedAlbumDownloadedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} downloaded'**
  String downloadedAlbumDownloadedCount(int count);

  /// No description provided for @downloadedAlbumSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String downloadedAlbumSelectedCount(int count);

  /// No description provided for @downloadedAlbumAllSelected.
  ///
  /// In en, this message translates to:
  /// **'All tracks selected'**
  String get downloadedAlbumAllSelected;

  /// No description provided for @downloadedAlbumTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap tracks to select'**
  String get downloadedAlbumTapToSelect;

  /// No description provided for @downloadedAlbumDeleteCount.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} {count, plural, =1{track} other{tracks}}'**
  String downloadedAlbumDeleteCount(int count);

  /// No description provided for @downloadedAlbumSelectToDelete.
  ///
  /// In en, this message translates to:
  /// **'Select tracks to delete'**
  String get downloadedAlbumSelectToDelete;

  /// No description provided for @folderOrganizationDescription.
  ///
  /// In en, this message translates to:
  /// **'Organize downloaded files into folders'**
  String get folderOrganizationDescription;

  /// No description provided for @folderOrganizationNoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All files in download folder'**
  String get folderOrganizationNoneSubtitle;

  /// No description provided for @folderOrganizationByArtistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Separate folder for each artist'**
  String get folderOrganizationByArtistSubtitle;

  /// No description provided for @folderOrganizationByAlbumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Separate folder for each album'**
  String get folderOrganizationByAlbumSubtitle;

  /// No description provided for @folderOrganizationByArtistAlbumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nested folders for artist and album'**
  String get folderOrganizationByArtistAlbumSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
