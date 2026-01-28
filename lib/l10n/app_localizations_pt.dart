// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'SpotiFLAC';

  @override
  String get appDescription =>
      'Download Spotify tracks in lossless quality from Tidal, Qobuz, and Amazon Music.';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get navStore => 'Store';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeSearchHint => 'Paste Spotify URL or search...';

  @override
  String homeSearchHintExtension(String extensionName) {
    return 'Search with $extensionName...';
  }

  @override
  String get homeSubtitle => 'Paste a Spotify link or search by name';

  @override
  String get homeSupports => 'Supports: Track, Album, Playlist, Artist URLs';

  @override
  String get homeRecent => 'Recent';

  @override
  String get historyTitle => 'History';

  @override
  String historyDownloading(int count) {
    return 'Downloading ($count)';
  }

  @override
  String get historyDownloaded => 'Downloaded';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyFilterAlbums => 'Albums';

  @override
  String get historyFilterSingles => 'Singles';

  @override
  String historyTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String historyAlbumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String get historyNoDownloads => 'No download history';

  @override
  String get historyNoDownloadsSubtitle => 'Downloaded tracks will appear here';

  @override
  String get historyNoAlbums => 'No album downloads';

  @override
  String get historyNoAlbumsSubtitle =>
      'Download multiple tracks from an album to see them here';

  @override
  String get historyNoSingles => 'No single downloads';

  @override
  String get historyNoSinglesSubtitle =>
      'Single track downloads will appear here';

  @override
  String get historySearchHint => 'Search history...';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDownload => 'Download';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsOptions => 'Options';

  @override
  String get settingsExtensions => 'Extensions';

  @override
  String get settingsAbout => 'About';

  @override
  String get downloadTitle => 'Download';

  @override
  String get downloadLocation => 'Download Location';

  @override
  String get downloadLocationSubtitle => 'Choose where to save files';

  @override
  String get downloadLocationDefault => 'Default location';

  @override
  String get downloadDefaultService => 'Default Service';

  @override
  String get downloadDefaultServiceSubtitle => 'Service used for downloads';

  @override
  String get downloadDefaultQuality => 'Default Quality';

  @override
  String get downloadAskQuality => 'Ask Quality Before Download';

  @override
  String get downloadAskQualitySubtitle =>
      'Show quality picker for each download';

  @override
  String get downloadFilenameFormat => 'Filename Format';

  @override
  String get downloadFolderOrganization => 'Folder Organization';

  @override
  String get downloadSeparateSingles => 'Separate Singles';

  @override
  String get downloadSeparateSinglesSubtitle =>
      'Put single tracks in a separate folder';

  @override
  String get qualityBest => 'Best Available';

  @override
  String get qualityFlac => 'FLAC';

  @override
  String get quality320 => '320 kbps';

  @override
  String get quality128 => '128 kbps';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceTheme => 'Theme';

  @override
  String get appearanceThemeSystem => 'System';

  @override
  String get appearanceThemeLight => 'Light';

  @override
  String get appearanceThemeDark => 'Dark';

  @override
  String get appearanceDynamicColor => 'Dynamic Color';

  @override
  String get appearanceDynamicColorSubtitle => 'Use colors from your wallpaper';

  @override
  String get appearanceAccentColor => 'Accent Color';

  @override
  String get appearanceHistoryView => 'History View';

  @override
  String get appearanceHistoryViewList => 'List';

  @override
  String get appearanceHistoryViewGrid => 'Grid';

  @override
  String get optionsTitle => 'Options';

  @override
  String get optionsSearchSource => 'Search Source';

  @override
  String get optionsPrimaryProvider => 'Primary Provider';

  @override
  String get optionsPrimaryProviderSubtitle =>
      'Service used when searching by track name.';

  @override
  String optionsUsingExtension(String extensionName) {
    return 'Using extension: $extensionName';
  }

  @override
  String get optionsSwitchBack =>
      'Tap Deezer or Spotify to switch back from extension';

  @override
  String get optionsAutoFallback => 'Auto Fallback';

  @override
  String get optionsAutoFallbackSubtitle =>
      'Try other services if download fails';

  @override
  String get optionsUseExtensionProviders => 'Use Extension Providers';

  @override
  String get optionsUseExtensionProvidersOn => 'Extensions will be tried first';

  @override
  String get optionsUseExtensionProvidersOff => 'Using built-in providers only';

  @override
  String get optionsEmbedLyrics => 'Embed Lyrics';

  @override
  String get optionsEmbedLyricsSubtitle =>
      'Embed synced lyrics into FLAC files';

  @override
  String get optionsMaxQualityCover => 'Max Quality Cover';

  @override
  String get optionsMaxQualityCoverSubtitle =>
      'Download highest resolution cover art';

  @override
  String get optionsConcurrentDownloads => 'Concurrent Downloads';

  @override
  String get optionsConcurrentSequential => 'Sequential (1 at a time)';

  @override
  String optionsConcurrentParallel(int count) {
    return '$count parallel downloads';
  }

  @override
  String get optionsConcurrentWarning =>
      'Parallel downloads may trigger rate limiting';

  @override
  String get optionsExtensionStore => 'Extension Store';

  @override
  String get optionsExtensionStoreSubtitle => 'Show Store tab in navigation';

  @override
  String get optionsCheckUpdates => 'Check for Updates';

  @override
  String get optionsCheckUpdatesSubtitle =>
      'Notify when new version is available';

  @override
  String get optionsUpdateChannel => 'Update Channel';

  @override
  String get optionsUpdateChannelStable => 'Stable releases only';

  @override
  String get optionsUpdateChannelPreview => 'Get preview releases';

  @override
  String get optionsUpdateChannelWarning =>
      'Preview may contain bugs or incomplete features';

  @override
  String get optionsClearHistory => 'Clear Download History';

  @override
  String get optionsClearHistorySubtitle =>
      'Remove all downloaded tracks from history';

  @override
  String get optionsDetailedLogging => 'Detailed Logging';

  @override
  String get optionsDetailedLoggingOn => 'Detailed logs are being recorded';

  @override
  String get optionsDetailedLoggingOff => 'Enable for bug reports';

  @override
  String get optionsSpotifyCredentials => 'Spotify Credentials';

  @override
  String optionsSpotifyCredentialsConfigured(String clientId) {
    return 'Client ID: $clientId...';
  }

  @override
  String get optionsSpotifyCredentialsRequired => 'Required - tap to configure';

  @override
  String get optionsSpotifyWarning =>
      'Spotify requires your own API credentials. Get them free from developer.spotify.com';

  @override
  String get extensionsTitle => 'Extensions';

  @override
  String get extensionsInstalled => 'Installed Extensions';

  @override
  String get extensionsNone => 'No extensions installed';

  @override
  String get extensionsNoneSubtitle => 'Install extensions from the Store tab';

  @override
  String get extensionsEnabled => 'Enabled';

  @override
  String get extensionsDisabled => 'Disabled';

  @override
  String extensionsVersion(String version) {
    return 'Version $version';
  }

  @override
  String extensionsAuthor(String author) {
    return 'by $author';
  }

  @override
  String get extensionsUninstall => 'Uninstall';

  @override
  String get extensionsSetAsSearch => 'Set as Search Provider';

  @override
  String get storeTitle => 'Extension Store';

  @override
  String get storeSearch => 'Search extensions...';

  @override
  String get storeInstall => 'Install';

  @override
  String get storeInstalled => 'Installed';

  @override
  String get storeUpdate => 'Update';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutContributors => 'Contributors';

  @override
  String get aboutMobileDeveloper => 'Mobile version developer';

  @override
  String get aboutOriginalCreator => 'Creator of the original SpotiFLAC';

  @override
  String get aboutLogoArtist =>
      'The talented artist who created our beautiful app logo!';

  @override
  String get aboutTranslators => 'Translators';

  @override
  String get aboutSpecialThanks => 'Special Thanks';

  @override
  String get aboutLinks => 'Links';

  @override
  String get aboutMobileSource => 'Mobile source code';

  @override
  String get aboutPCSource => 'PC source code';

  @override
  String get aboutReportIssue => 'Report an issue';

  @override
  String get aboutReportIssueSubtitle => 'Report any problems you encounter';

  @override
  String get aboutFeatureRequest => 'Feature request';

  @override
  String get aboutFeatureRequestSubtitle => 'Suggest new features for the app';

  @override
  String get aboutTelegramChannel => 'Telegram Channel';

  @override
  String get aboutTelegramChannelSubtitle => 'Announcements and updates';

  @override
  String get aboutTelegramChat => 'Telegram Community';

  @override
  String get aboutTelegramChatSubtitle => 'Chat with other users';

  @override
  String get aboutSocial => 'Social';

  @override
  String get aboutSupport => 'Support';

  @override
  String get aboutBuyMeCoffee => 'Buy me a coffee';

  @override
  String get aboutBuyMeCoffeeSubtitle => 'Support development on Ko-fi';

  @override
  String get aboutApp => 'App';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBinimumDesc =>
      'The creator of QQDL & HiFi API. Without this API, Tidal downloads wouldn\'t exist!';

  @override
  String get aboutSachinsenalDesc =>
      'The original HiFi project creator. The foundation of Tidal integration!';

  @override
  String get aboutDoubleDouble => 'DoubleDouble';

  @override
  String get aboutDoubleDoubleDesc =>
      'Amazing API for Amazon Music downloads. Thank you for making it free!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'The best Qobuz streaming API. Hi-Res downloads wouldn\'t be possible without this!';

  @override
  String get aboutAppDescription =>
      'Download Spotify tracks in lossless quality from Tidal, Qobuz, and Amazon Music.';

  @override
  String get albumTitle => 'Album';

  @override
  String albumTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get albumDownloadAll => 'Download All';

  @override
  String get albumDownloadRemaining => 'Download Remaining';

  @override
  String get playlistTitle => 'Playlist';

  @override
  String get artistTitle => 'Artist';

  @override
  String get artistAlbums => 'Albums';

  @override
  String get artistSingles => 'Singles & EPs';

  @override
  String get artistCompilations => 'Compilations';

  @override
  String artistReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count releases',
      one: '1 release',
    );
    return '$_temp0';
  }

  @override
  String get artistPopular => 'Popular';

  @override
  String artistMonthlyListeners(String count) {
    return '$count monthly listeners';
  }

  @override
  String get trackMetadataTitle => 'Track Info';

  @override
  String get trackMetadataArtist => 'Artist';

  @override
  String get trackMetadataAlbum => 'Album';

  @override
  String get trackMetadataDuration => 'Duration';

  @override
  String get trackMetadataQuality => 'Quality';

  @override
  String get trackMetadataPath => 'File Path';

  @override
  String get trackMetadataDownloadedAt => 'Downloaded';

  @override
  String get trackMetadataService => 'Service';

  @override
  String get trackMetadataPlay => 'Play';

  @override
  String get trackMetadataShare => 'Share';

  @override
  String get trackMetadataDelete => 'Delete';

  @override
  String get trackMetadataRedownload => 'Re-download';

  @override
  String get trackMetadataOpenFolder => 'Open Folder';

  @override
  String get setupTitle => 'Welcome to SpotiFLAC';

  @override
  String get setupSubtitle => 'Let\'s get you started';

  @override
  String get setupStoragePermission => 'Storage Permission';

  @override
  String get setupStoragePermissionSubtitle =>
      'Required to save downloaded files';

  @override
  String get setupStoragePermissionGranted => 'Permission granted';

  @override
  String get setupStoragePermissionDenied => 'Permission denied';

  @override
  String get setupGrantPermission => 'Grant Permission';

  @override
  String get setupDownloadLocation => 'Download Location';

  @override
  String get setupChooseFolder => 'Choose Folder';

  @override
  String get setupContinue => 'Continue';

  @override
  String get setupSkip => 'Skip for now';

  @override
  String get setupStorageAccessRequired => 'Storage Access Required';

  @override
  String get setupStorageAccessMessage =>
      'SpotiFLAC needs \"All files access\" permission to save music files to your chosen folder.';

  @override
  String get setupStorageAccessMessageAndroid11 =>
      'Android 11+ requires \"All files access\" permission to save files to your chosen download folder.';

  @override
  String get setupOpenSettings => 'Open Settings';

  @override
  String get setupPermissionDeniedMessage =>
      'Permission denied. Please grant all permissions to continue.';

  @override
  String setupPermissionRequired(String permissionType) {
    return '$permissionType Permission Required';
  }

  @override
  String setupPermissionRequiredMessage(String permissionType) {
    return '$permissionType permission is required for the best experience. You can change this later in Settings.';
  }

  @override
  String get setupSelectDownloadFolder => 'Select Download Folder';

  @override
  String get setupUseDefaultFolder => 'Use Default Folder?';

  @override
  String get setupNoFolderSelected =>
      'No folder selected. Would you like to use the default Music folder?';

  @override
  String get setupUseDefault => 'Use Default';

  @override
  String get setupDownloadLocationTitle => 'Download Location';

  @override
  String get setupDownloadLocationIosMessage =>
      'On iOS, downloads are saved to the app\'s Documents folder. You can access them via the Files app.';

  @override
  String get setupAppDocumentsFolder => 'App Documents Folder';

  @override
  String get setupAppDocumentsFolderSubtitle =>
      'Recommended - accessible via Files app';

  @override
  String get setupChooseFromFiles => 'Choose from Files';

  @override
  String get setupChooseFromFilesSubtitle => 'Select iCloud or other location';

  @override
  String get setupIosEmptyFolderWarning =>
      'iOS limitation: Empty folders cannot be selected. Choose a folder with at least one file.';

  @override
  String get setupDownloadInFlac => 'Download Spotify tracks in FLAC';

  @override
  String get setupStepStorage => 'Storage';

  @override
  String get setupStepNotification => 'Notification';

  @override
  String get setupStepFolder => 'Folder';

  @override
  String get setupStepSpotify => 'Spotify';

  @override
  String get setupStepPermission => 'Permission';

  @override
  String get setupStorageGranted => 'Storage Permission Granted!';

  @override
  String get setupStorageRequired => 'Storage Permission Required';

  @override
  String get setupStorageDescription =>
      'SpotiFLAC needs storage permission to save your downloaded music files.';

  @override
  String get setupNotificationGranted => 'Notification Permission Granted!';

  @override
  String get setupNotificationEnable => 'Enable Notifications';

  @override
  String get setupNotificationDescription =>
      'Get notified when downloads complete or require attention.';

  @override
  String get setupFolderSelected => 'Download Folder Selected!';

  @override
  String get setupFolderChoose => 'Choose Download Folder';

  @override
  String get setupFolderDescription =>
      'Select a folder where your downloaded music will be saved.';

  @override
  String get setupChangeFolder => 'Change Folder';

  @override
  String get setupSelectFolder => 'Select Folder';

  @override
  String get setupSpotifyApiOptional => 'Spotify API (Optional)';

  @override
  String get setupSpotifyApiDescription =>
      'Add your Spotify API credentials for better search results and access to Spotify-exclusive content.';

  @override
  String get setupUseSpotifyApi => 'Use Spotify API';

  @override
  String get setupEnterCredentialsBelow => 'Enter your credentials below';

  @override
  String get setupUsingDeezer => 'Using Deezer (no account needed)';

  @override
  String get setupEnterClientId => 'Enter Spotify Client ID';

  @override
  String get setupEnterClientSecret => 'Enter Spotify Client Secret';

  @override
  String get setupGetFreeCredentials =>
      'Get your free API credentials from the Spotify Developer Dashboard.';

  @override
  String get setupEnableNotifications => 'Enable Notifications';

  @override
  String get setupProceedToNextStep => 'You can now proceed to the next step.';

  @override
  String get setupNotificationProgressDescription =>
      'You will receive download progress notifications.';

  @override
  String get setupNotificationBackgroundDescription =>
      'Get notified about download progress and completion. This helps you track downloads when the app is in background.';

  @override
  String get setupSkipForNow => 'Skip for now';

  @override
  String get setupBack => 'Back';

  @override
  String get setupNext => 'Next';

  @override
  String get setupGetStarted => 'Get Started';

  @override
  String get setupSkipAndStart => 'Skip & Start';

  @override
  String get setupAllowAccessToManageFiles =>
      'Please enable \"Allow access to manage all files\" in the next screen.';

  @override
  String get setupGetCredentialsFromSpotify =>
      'Get credentials from developer.spotify.com';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogOk => 'OK';

  @override
  String get dialogSave => 'Save';

  @override
  String get dialogDelete => 'Delete';

  @override
  String get dialogRetry => 'Retry';

  @override
  String get dialogClose => 'Close';

  @override
  String get dialogYes => 'Yes';

  @override
  String get dialogNo => 'No';

  @override
  String get dialogClear => 'Clear';

  @override
  String get dialogConfirm => 'Confirm';

  @override
  String get dialogDone => 'Done';

  @override
  String get dialogImport => 'Import';

  @override
  String get dialogDiscard => 'Discard';

  @override
  String get dialogRemove => 'Remove';

  @override
  String get dialogUninstall => 'Uninstall';

  @override
  String get dialogDiscardChanges => 'Discard Changes?';

  @override
  String get dialogUnsavedChanges =>
      'You have unsaved changes. Do you want to discard them?';

  @override
  String get dialogDownloadFailed => 'Download Failed';

  @override
  String get dialogTrackLabel => 'Track:';

  @override
  String get dialogArtistLabel => 'Artist:';

  @override
  String get dialogErrorLabel => 'Error:';

  @override
  String get dialogClearAll => 'Clear All';

  @override
  String get dialogClearAllDownloads =>
      'Are you sure you want to clear all downloads?';

  @override
  String get dialogRemoveFromDevice => 'Remove from device?';

  @override
  String get dialogRemoveExtension => 'Remove Extension';

  @override
  String get dialogRemoveExtensionMessage =>
      'Are you sure you want to remove this extension? This cannot be undone.';

  @override
  String get dialogUninstallExtension => 'Uninstall Extension?';

  @override
  String dialogUninstallExtensionMessage(String extensionName) {
    return 'Are you sure you want to remove $extensionName?';
  }

  @override
  String get dialogClearHistoryTitle => 'Clear History';

  @override
  String get dialogClearHistoryMessage =>
      'Are you sure you want to clear all download history? This cannot be undone.';

  @override
  String get dialogDeleteSelectedTitle => 'Delete Selected';

  @override
  String dialogDeleteSelectedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Delete $count $_temp0 from history?\n\nThis will also delete the files from storage.';
  }

  @override
  String get dialogImportPlaylistTitle => 'Import Playlist';

  @override
  String dialogImportPlaylistMessage(int count) {
    return 'Found $count tracks in CSV. Add them to download queue?';
  }

  @override
  String csvImportTracks(int count) {
    return '$count tracks from CSV';
  }

  @override
  String snackbarAddedToQueue(String trackName) {
    return 'Added \"$trackName\" to queue';
  }

  @override
  String snackbarAddedTracksToQueue(int count) {
    return 'Added $count tracks to queue';
  }

  @override
  String snackbarAlreadyDownloaded(String trackName) {
    return '\"$trackName\" already downloaded';
  }

  @override
  String get snackbarHistoryCleared => 'History cleared';

  @override
  String get snackbarCredentialsSaved => 'Credentials saved';

  @override
  String get snackbarCredentialsCleared => 'Credentials cleared';

  @override
  String snackbarDeletedTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Deleted $count $_temp0';
  }

  @override
  String snackbarCannotOpenFile(String error) {
    return 'Cannot open file: $error';
  }

  @override
  String get snackbarFillAllFields => 'Please fill all fields';

  @override
  String get snackbarViewQueue => 'View Queue';

  @override
  String snackbarFailedToLoad(String error) {
    return 'Failed to load: $error';
  }

  @override
  String snackbarUrlCopied(String platform) {
    return '$platform URL copied to clipboard';
  }

  @override
  String get snackbarFileNotFound => 'File not found';

  @override
  String get snackbarSelectExtFile => 'Please select a .spotiflac-ext file';

  @override
  String get snackbarProviderPrioritySaved => 'Provider priority saved';

  @override
  String get snackbarMetadataProviderSaved =>
      'Metadata provider priority saved';

  @override
  String snackbarExtensionInstalled(String extensionName) {
    return '$extensionName installed.';
  }

  @override
  String snackbarExtensionUpdated(String extensionName) {
    return '$extensionName updated.';
  }

  @override
  String get snackbarFailedToInstall => 'Failed to install extension';

  @override
  String get snackbarFailedToUpdate => 'Failed to update extension';

  @override
  String get errorRateLimited => 'Rate Limited';

  @override
  String get errorRateLimitedMessage =>
      'Too many requests. Please wait a moment before searching again.';

  @override
  String errorFailedToLoad(String item) {
    return 'Failed to load $item';
  }

  @override
  String get errorNoTracksFound => 'No tracks found';

  @override
  String errorMissingExtensionSource(String item) {
    return 'Cannot load $item: missing extension source';
  }

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusDownloading => 'Downloading';

  @override
  String get statusFinalizing => 'Finalizing';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusSkipped => 'Skipped';

  @override
  String get statusPaused => 'Paused';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionSelect => 'Select';

  @override
  String get actionSelectAll => 'Select All';

  @override
  String get actionDeselect => 'Deselect';

  @override
  String get actionPaste => 'Paste';

  @override
  String get actionImportCsv => 'Import CSV';

  @override
  String get actionRemoveCredentials => 'Remove Credentials';

  @override
  String get actionSaveCredentials => 'Save Credentials';

  @override
  String selectionSelected(int count) {
    return '$count selected';
  }

  @override
  String get selectionAllSelected => 'All tracks selected';

  @override
  String get selectionTapToSelect => 'Tap tracks to select';

  @override
  String selectionDeleteTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Delete $count $_temp0';
  }

  @override
  String get selectionSelectToDelete => 'Select tracks to delete';

  @override
  String progressFetchingMetadata(int current, int total) {
    return 'Fetching metadata... $current/$total';
  }

  @override
  String get progressReadingCsv => 'Reading CSV...';

  @override
  String get searchSongs => 'Songs';

  @override
  String get searchArtists => 'Artists';

  @override
  String get searchAlbums => 'Albums';

  @override
  String get searchPlaylists => 'Playlists';

  @override
  String get tooltipPlay => 'Play';

  @override
  String get tooltipCancel => 'Cancel';

  @override
  String get tooltipStop => 'Stop';

  @override
  String get tooltipRetry => 'Retry';

  @override
  String get tooltipRemove => 'Remove';

  @override
  String get tooltipClear => 'Clear';

  @override
  String get tooltipPaste => 'Paste';

  @override
  String get filenameFormat => 'Filename Format';

  @override
  String filenameFormatPreview(String preview) {
    return 'Preview: $preview';
  }

  @override
  String get filenameAvailablePlaceholders => 'Available placeholders:';

  @override
  String filenameHint(Object artist, Object title) {
    return '$artist - $title';
  }

  @override
  String get folderOrganization => 'Folder Organization';

  @override
  String get folderOrganizationNone => 'No organization';

  @override
  String get folderOrganizationByArtist => 'By Artist';

  @override
  String get folderOrganizationByAlbum => 'By Album';

  @override
  String get folderOrganizationByArtistAlbum => 'Artist/Album';

  @override
  String get folderOrganizationDescription =>
      'Organize downloaded files into folders';

  @override
  String get folderOrganizationNoneSubtitle => 'All files in download folder';

  @override
  String get folderOrganizationByArtistSubtitle =>
      'Separate folder for each artist';

  @override
  String get folderOrganizationByAlbumSubtitle =>
      'Separate folder for each album';

  @override
  String get folderOrganizationByArtistAlbumSubtitle =>
      'Nested folders for artist and album';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String updateNewVersion(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateDownload => 'Download';

  @override
  String get updateLater => 'Later';

  @override
  String get updateChangelog => 'Changelog';

  @override
  String get updateStartingDownload => 'Starting download...';

  @override
  String get updateDownloadFailed => 'Download failed';

  @override
  String get updateFailedMessage => 'Failed to download update';

  @override
  String get updateNewVersionReady => 'A new version is ready';

  @override
  String get updateCurrent => 'Current';

  @override
  String get updateNew => 'New';

  @override
  String get updateDownloading => 'Downloading...';

  @override
  String get updateWhatsNew => 'What\'s New';

  @override
  String get updateDownloadInstall => 'Download & Install';

  @override
  String get updateDontRemind => 'Don\'t remind';

  @override
  String get providerPriority => 'Provider Priority';

  @override
  String get providerPrioritySubtitle => 'Drag to reorder download providers';

  @override
  String get providerPriorityTitle => 'Provider Priority';

  @override
  String get providerPriorityDescription =>
      'Drag to reorder download providers. The app will try providers from top to bottom when downloading tracks.';

  @override
  String get providerPriorityInfo =>
      'If a track is not available on the first provider, the app will automatically try the next one.';

  @override
  String get providerBuiltIn => 'Built-in';

  @override
  String get providerExtension => 'Extension';

  @override
  String get metadataProviderPriority => 'Metadata Provider Priority';

  @override
  String get metadataProviderPrioritySubtitle =>
      'Order used when fetching track metadata';

  @override
  String get metadataProviderPriorityTitle => 'Metadata Priority';

  @override
  String get metadataProviderPriorityDescription =>
      'Drag to reorder metadata providers. The app will try providers from top to bottom when searching for tracks and fetching metadata.';

  @override
  String get metadataProviderPriorityInfo =>
      'Deezer has no rate limits and is recommended as primary. Spotify may rate limit after many requests.';

  @override
  String get metadataNoRateLimits => 'No rate limits';

  @override
  String get metadataMayRateLimit => 'May rate limit';

  @override
  String get logTitle => 'Logs';

  @override
  String get logCopy => 'Copy Logs';

  @override
  String get logClear => 'Clear Logs';

  @override
  String get logShare => 'Share Logs';

  @override
  String get logEmpty => 'No logs yet';

  @override
  String get logCopied => 'Logs copied to clipboard';

  @override
  String get logSearchHint => 'Search logs...';

  @override
  String get logFilterLevel => 'Level';

  @override
  String get logFilterSection => 'Filter';

  @override
  String get logShareLogs => 'Share logs';

  @override
  String get logClearLogs => 'Clear logs';

  @override
  String get logClearLogsTitle => 'Clear Logs';

  @override
  String get logClearLogsMessage => 'Are you sure you want to clear all logs?';

  @override
  String get logIspBlocking => 'ISP BLOCKING DETECTED';

  @override
  String get logRateLimited => 'RATE LIMITED';

  @override
  String get logNetworkError => 'NETWORK ERROR';

  @override
  String get logTrackNotFound => 'TRACK NOT FOUND';

  @override
  String get logFilterBySeverity => 'Filter logs by severity';

  @override
  String get logNoLogsYet => 'No logs yet';

  @override
  String get logNoLogsYetSubtitle => 'Logs will appear here as you use the app';

  @override
  String get logIssueSummary => 'Issue Summary';

  @override
  String get logIspBlockingDescription =>
      'Your ISP may be blocking access to download services';

  @override
  String get logIspBlockingSuggestion =>
      'Try using a VPN or change DNS to 1.1.1.1 or 8.8.8.8';

  @override
  String get logRateLimitedDescription => 'Too many requests to the service';

  @override
  String get logRateLimitedSuggestion =>
      'Wait a few minutes before trying again';

  @override
  String get logNetworkErrorDescription => 'Connection issues detected';

  @override
  String get logNetworkErrorSuggestion => 'Check your internet connection';

  @override
  String get logTrackNotFoundDescription =>
      'Some tracks could not be found on download services';

  @override
  String get logTrackNotFoundSuggestion =>
      'The track may not be available in lossless quality';

  @override
  String logTotalErrors(int count) {
    return 'Total errors: $count';
  }

  @override
  String logAffected(String domains) {
    return 'Affected: $domains';
  }

  @override
  String logEntriesFiltered(int count) {
    return 'Entries ($count filtered)';
  }

  @override
  String logEntries(int count) {
    return 'Entries ($count)';
  }

  @override
  String get credentialsTitle => 'Spotify Credentials';

  @override
  String get credentialsDescription =>
      'Enter your Client ID and Secret to use your own Spotify application quota.';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Paste Client ID';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => 'Paste Client Secret';

  @override
  String get channelStable => 'Stable';

  @override
  String get channelPreview => 'Preview';

  @override
  String get sectionSearchSource => 'Search Source';

  @override
  String get sectionDownload => 'Download';

  @override
  String get sectionPerformance => 'Performance';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionData => 'Data';

  @override
  String get sectionDebug => 'Debug';

  @override
  String get sectionService => 'Service';

  @override
  String get sectionAudioQuality => 'Audio Quality';

  @override
  String get sectionFileSettings => 'File Settings';

  @override
  String get sectionLyrics => 'Lyrics';

  @override
  String get lyricsMode => 'Lyrics Mode';

  @override
  String get lyricsModeDescription =>
      'Choose how lyrics are saved with your downloads';

  @override
  String get lyricsModeEmbed => 'Embed in file';

  @override
  String get lyricsModeEmbedSubtitle => 'Lyrics stored inside FLAC metadata';

  @override
  String get lyricsModeExternal => 'External .lrc file';

  @override
  String get lyricsModeExternalSubtitle =>
      'Separate .lrc file for players like Samsung Music';

  @override
  String get lyricsModeBoth => 'Both';

  @override
  String get lyricsModeBothSubtitle => 'Embed and save .lrc file';

  @override
  String get sectionColor => 'Color';

  @override
  String get sectionTheme => 'Theme';

  @override
  String get sectionLayout => 'Layout';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get appearanceLanguage => 'App Language';

  @override
  String get appearanceLanguageSubtitle => 'Choose your preferred language';

  @override
  String get settingsAppearanceSubtitle => 'Theme, colors, display';

  @override
  String get settingsDownloadSubtitle => 'Service, quality, filename format';

  @override
  String get settingsOptionsSubtitle => 'Fallback, lyrics, cover art, updates';

  @override
  String get settingsExtensionsSubtitle => 'Manage download providers';

  @override
  String get settingsLogsSubtitle => 'View app logs for debugging';

  @override
  String get loadingSharedLink => 'Loading shared link...';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get tracksHeader => 'Tracks';

  @override
  String downloadAllCount(int count) {
    return 'Download All ($count)';
  }

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get trackCopyFilePath => 'Copy file path';

  @override
  String get trackRemoveFromDevice => 'Remove from device';

  @override
  String get trackLoadLyrics => 'Load Lyrics';

  @override
  String get trackMetadata => 'Metadata';

  @override
  String get trackFileInfo => 'File Info';

  @override
  String get trackLyrics => 'Lyrics';

  @override
  String get trackFileNotFound => 'File not found';

  @override
  String get trackOpenInDeezer => 'Open in Deezer';

  @override
  String get trackOpenInSpotify => 'Open in Spotify';

  @override
  String get trackTrackName => 'Track name';

  @override
  String get trackArtist => 'Artist';

  @override
  String get trackAlbumArtist => 'Album artist';

  @override
  String get trackAlbum => 'Album';

  @override
  String get trackTrackNumber => 'Track number';

  @override
  String get trackDiscNumber => 'Disc number';

  @override
  String get trackDuration => 'Duration';

  @override
  String get trackAudioQuality => 'Audio quality';

  @override
  String get trackReleaseDate => 'Release date';

  @override
  String get trackGenre => 'Genre';

  @override
  String get trackLabel => 'Label';

  @override
  String get trackCopyright => 'Copyright';

  @override
  String get trackDownloaded => 'Downloaded';

  @override
  String get trackCopyLyrics => 'Copy lyrics';

  @override
  String get trackLyricsNotAvailable => 'Lyrics not available for this track';

  @override
  String get trackLyricsTimeout => 'Request timed out. Try again later.';

  @override
  String get trackLyricsLoadFailed => 'Failed to load lyrics';

  @override
  String get trackEmbedLyrics => 'Embed Lyrics';

  @override
  String get trackLyricsEmbedded => 'Lyrics embedded successfully';

  @override
  String get trackInstrumental => 'Instrumental track';

  @override
  String get trackCopiedToClipboard => 'Copied to clipboard';

  @override
  String get trackDeleteConfirmTitle => 'Remove from device?';

  @override
  String get trackDeleteConfirmMessage =>
      'This will permanently delete the downloaded file and remove it from your history.';

  @override
  String trackCannotOpen(String message) {
    return 'Cannot open: $message';
  }

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String dateWeeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String dateMonthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String get concurrentSequential => 'Sequential';

  @override
  String get concurrentParallel2 => '2 Parallel';

  @override
  String get concurrentParallel3 => '3 Parallel';

  @override
  String get tapToSeeError => 'Tap to see error details';

  @override
  String get storeFilterAll => 'All';

  @override
  String get storeFilterMetadata => 'Metadata';

  @override
  String get storeFilterDownload => 'Download';

  @override
  String get storeFilterUtility => 'Utility';

  @override
  String get storeFilterLyrics => 'Lyrics';

  @override
  String get storeFilterIntegration => 'Integration';

  @override
  String get storeClearFilters => 'Clear filters';

  @override
  String get storeNoResults => 'No extensions found';

  @override
  String get extensionProviderPriority => 'Provider Priority';

  @override
  String get extensionInstallButton => 'Install Extension';

  @override
  String get extensionDefaultProvider => 'Default (Deezer/Spotify)';

  @override
  String get extensionDefaultProviderSubtitle => 'Use built-in search';

  @override
  String get extensionAuthor => 'Author';

  @override
  String get extensionId => 'ID';

  @override
  String get extensionError => 'Error';

  @override
  String get extensionCapabilities => 'Capabilities';

  @override
  String get extensionMetadataProvider => 'Metadata Provider';

  @override
  String get extensionDownloadProvider => 'Download Provider';

  @override
  String get extensionLyricsProvider => 'Lyrics Provider';

  @override
  String get extensionUrlHandler => 'URL Handler';

  @override
  String get extensionQualityOptions => 'Quality Options';

  @override
  String get extensionPostProcessingHooks => 'Post-Processing Hooks';

  @override
  String get extensionPermissions => 'Permissions';

  @override
  String get extensionSettings => 'Settings';

  @override
  String get extensionRemoveButton => 'Remove Extension';

  @override
  String get extensionUpdated => 'Updated';

  @override
  String get extensionMinAppVersion => 'Min App Version';

  @override
  String get extensionCustomTrackMatching => 'Custom Track Matching';

  @override
  String get extensionPostProcessing => 'Post-Processing';

  @override
  String extensionHooksAvailable(int count) {
    return '$count hook(s) available';
  }

  @override
  String extensionPatternsCount(int count) {
    return '$count pattern(s)';
  }

  @override
  String extensionStrategy(String strategy) {
    return 'Strategy: $strategy';
  }

  @override
  String get extensionsProviderPrioritySection => 'Provider Priority';

  @override
  String get extensionsInstalledSection => 'Installed Extensions';

  @override
  String get extensionsNoExtensions => 'No extensions installed';

  @override
  String get extensionsNoExtensionsSubtitle =>
      'Install .spotiflac-ext files to add new providers';

  @override
  String get extensionsInstallButton => 'Install Extension';

  @override
  String get extensionsInfoTip =>
      'Extensions can add new metadata and download providers. Only install extensions from trusted sources.';

  @override
  String get extensionsInstalledSuccess => 'Extension installed successfully';

  @override
  String get extensionsDownloadPriority => 'Download Priority';

  @override
  String get extensionsDownloadPrioritySubtitle => 'Set download service order';

  @override
  String get extensionsNoDownloadProvider =>
      'No extensions with download provider';

  @override
  String get extensionsMetadataPriority => 'Metadata Priority';

  @override
  String get extensionsMetadataPrioritySubtitle =>
      'Set search & metadata source order';

  @override
  String get extensionsNoMetadataProvider =>
      'No extensions with metadata provider';

  @override
  String get extensionsSearchProvider => 'Search Provider';

  @override
  String get extensionsNoCustomSearch => 'No extensions with custom search';

  @override
  String get extensionsSearchProviderDescription =>
      'Choose which service to use for searching tracks';

  @override
  String get extensionsCustomSearch => 'Custom search';

  @override
  String get extensionsErrorLoading => 'Error loading extension';

  @override
  String get qualityFlacLossless => 'FLAC Lossless';

  @override
  String get qualityFlacLosslessSubtitle => '16-bit / 44.1kHz';

  @override
  String get qualityHiResFlac => 'Hi-Res FLAC';

  @override
  String get qualityHiResFlacSubtitle => '24-bit / up to 96kHz';

  @override
  String get qualityHiResFlacMax => 'Hi-Res FLAC Max';

  @override
  String get qualityHiResFlacMaxSubtitle => '24-bit / up to 192kHz';

  @override
  String get qualityMp3 => 'MP3';

  @override
  String get qualityMp3Subtitle => '320kbps (converted from FLAC)';

  @override
  String get enableMp3Option => 'Enable MP3 Option';

  @override
  String get enableMp3OptionSubtitleOn => 'MP3 quality option is available';

  @override
  String get enableMp3OptionSubtitleOff =>
      'Downloads FLAC then converts to 320kbps MP3';

  @override
  String get qualityNote =>
      'Actual quality depends on track availability from the service';

  @override
  String get downloadAskBeforeDownload => 'Ask Before Download';

  @override
  String get downloadDirectory => 'Download Directory';

  @override
  String get downloadSeparateSinglesFolder => 'Separate Singles Folder';

  @override
  String get downloadAlbumFolderStructure => 'Album Folder Structure';

  @override
  String get downloadSaveFormat => 'Save Format';

  @override
  String get downloadSelectService => 'Select Service';

  @override
  String get downloadSelectQuality => 'Select Quality';

  @override
  String get downloadFrom => 'Download From';

  @override
  String get downloadDefaultQualityLabel => 'Default Quality';

  @override
  String get downloadBestAvailable => 'Best available';

  @override
  String get folderNone => 'None';

  @override
  String get folderNoneSubtitle => 'Save all files directly to download folder';

  @override
  String get folderArtist => 'Artist';

  @override
  String get folderArtistSubtitle => 'Artist Name/filename';

  @override
  String get folderAlbum => 'Album';

  @override
  String get folderAlbumSubtitle => 'Album Name/filename';

  @override
  String get folderArtistAlbum => 'Artist/Album';

  @override
  String get folderArtistAlbumSubtitle => 'Artist Name/Album Name/filename';

  @override
  String get serviceTidal => 'Tidal';

  @override
  String get serviceQobuz => 'Qobuz';

  @override
  String get serviceAmazon => 'Amazon';

  @override
  String get serviceDeezer => 'Deezer';

  @override
  String get serviceSpotify => 'Spotify';

  @override
  String get appearanceAmoledDark => 'AMOLED Dark';

  @override
  String get appearanceAmoledDarkSubtitle => 'Pure black background';

  @override
  String get appearanceChooseAccentColor => 'Choose Accent Color';

  @override
  String get appearanceChooseTheme => 'Theme Mode';

  @override
  String get queueTitle => 'Download Queue';

  @override
  String get queueClearAll => 'Clear All';

  @override
  String get queueClearAllMessage =>
      'Are you sure you want to clear all downloads?';

  @override
  String get queueEmpty => 'No downloads in queue';

  @override
  String get queueEmptySubtitle => 'Add tracks from the home screen';

  @override
  String get queueClearCompleted => 'Clear completed';

  @override
  String get queueDownloadFailed => 'Download Failed';

  @override
  String get queueTrackLabel => 'Track:';

  @override
  String get queueArtistLabel => 'Artist:';

  @override
  String get queueErrorLabel => 'Error:';

  @override
  String get queueUnknownError => 'Unknown error';

  @override
  String get albumFolderArtistAlbum => 'Artist / Album';

  @override
  String get albumFolderArtistAlbumSubtitle => 'Albums/Artist Name/Album Name/';

  @override
  String get albumFolderArtistYearAlbum => 'Artist / [Year] Album';

  @override
  String get albumFolderArtistYearAlbumSubtitle =>
      'Albums/Artist Name/[2005] Album Name/';

  @override
  String get albumFolderAlbumOnly => 'Album Only';

  @override
  String get albumFolderAlbumOnlySubtitle => 'Albums/Album Name/';

  @override
  String get albumFolderYearAlbum => '[Year] Album';

  @override
  String get albumFolderYearAlbumSubtitle => 'Albums/[2005] Album Name/';

  @override
  String get albumFolderArtistAlbumSingles => 'Artist / Album + Singles';

  @override
  String get albumFolderArtistAlbumSinglesSubtitle =>
      'Artist/Album/ and Artist/Singles/';

  @override
  String get downloadedAlbumDeleteSelected => 'Delete Selected';

  @override
  String downloadedAlbumDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Delete $count $_temp0 from this album?\n\nThis will also delete the files from storage.';
  }

  @override
  String get downloadedAlbumTracksHeader => 'Tracks';

  @override
  String downloadedAlbumDownloadedCount(int count) {
    return '$count downloaded';
  }

  @override
  String downloadedAlbumSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get downloadedAlbumAllSelected => 'All tracks selected';

  @override
  String get downloadedAlbumTapToSelect => 'Tap tracks to select';

  @override
  String downloadedAlbumDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Delete $count $_temp0';
  }

  @override
  String get downloadedAlbumSelectToDelete => 'Select tracks to delete';

  @override
  String downloadedAlbumDiscHeader(int discNumber) {
    return 'Disc $discNumber';
  }

  @override
  String get utilityFunctions => 'Utility Functions';

  @override
  String get recentTypeArtist => 'Artist';

  @override
  String get recentTypeAlbum => 'Album';

  @override
  String get recentTypeSong => 'Song';

  @override
  String get recentTypePlaylist => 'Playlist';

  @override
  String recentPlaylistInfo(String name) {
    return 'Playlist: $name';
  }

  @override
  String errorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get discographyDownload => 'Download Discography';

  @override
  String get discographyDownloadAll => 'Download All';

  @override
  String discographyDownloadAllSubtitle(int count, int albumCount) {
    return '$count tracks from $albumCount releases';
  }

  @override
  String get discographyAlbumsOnly => 'Albums Only';

  @override
  String discographyAlbumsOnlySubtitle(int count, int albumCount) {
    return '$count tracks from $albumCount albums';
  }

  @override
  String get discographySinglesOnly => 'Singles & EPs Only';

  @override
  String discographySinglesOnlySubtitle(int count, int albumCount) {
    return '$count tracks from $albumCount singles';
  }

  @override
  String get discographySelectAlbums => 'Select Albums...';

  @override
  String get discographySelectAlbumsSubtitle =>
      'Choose specific albums or singles';

  @override
  String get discographyFetchingTracks => 'Fetching tracks...';

  @override
  String discographyFetchingAlbum(int current, int total) {
    return 'Fetching $current of $total...';
  }

  @override
  String discographySelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get discographyDownloadSelected => 'Download Selected';

  @override
  String discographyAddedToQueue(int count) {
    return 'Added $count tracks to queue';
  }

  @override
  String discographySkippedDownloaded(int added, int skipped) {
    return '$added added, $skipped already downloaded';
  }

  @override
  String get discographyNoAlbums => 'No albums available';

  @override
  String get discographyFailedToFetch => 'Failed to fetch some albums';

  @override
  String get webdavTitle => 'WebDAV Storage';

  @override
  String get webdavSubtitle => 'Upload files to WebDAV server';

  @override
  String get webdavSectionConfig => 'Configuration';

  @override
  String get webdavSectionServer => 'Server';

  @override
  String get webdavSectionOptions => 'Options';

  @override
  String get webdavSectionQueue => 'Upload Queue';

  @override
  String get webdavEnable => 'Enable WebDAV Upload';

  @override
  String get webdavEnableSubtitleConfigured =>
      'Upload downloaded files to WebDAV server';

  @override
  String get webdavEnableSubtitleNotConfigured =>
      'Configure server settings first';

  @override
  String get webdavServerUrl => 'Server URL';

  @override
  String get webdavUsername => 'Username';

  @override
  String get webdavUsernamePlaceholder => 'Enter username';

  @override
  String get webdavPassword => 'Password';

  @override
  String get webdavPasswordPlaceholder => 'Enter password';

  @override
  String get webdavRemotePath => 'Remote Path';

  @override
  String get webdavTestConnection => 'Test Connection';

  @override
  String get webdavTesting => 'Testing...';

  @override
  String get webdavConnectionSuccess => 'Connection successful!';

  @override
  String webdavConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get webdavDeleteLocal => 'Delete Local After Upload';

  @override
  String get webdavDeleteLocalSubtitle =>
      'Remove local file after successful WebDAV upload';

  @override
  String get webdavRetryOnFailure => 'Retry on Failure';

  @override
  String webdavRetrySubtitle(int count) {
    return 'Automatically retry up to $count times';
  }

  @override
  String get webdavActiveUploads => 'Active Uploads';

  @override
  String get webdavPending => 'Pending';

  @override
  String get webdavUploading => 'Uploading';

  @override
  String get webdavCompleted => 'Completed';

  @override
  String get webdavFailed => 'Failed';

  @override
  String get webdavRetry => 'Retry';

  @override
  String get webdavRetryAll => 'Retry All';

  @override
  String get webdavRemove => 'Remove';

  @override
  String get webdavClearCompleted => 'Clear Completed';
}

/// The translations for Portuguese, as used in Portugal (`pt_PT`).
class AppLocalizationsPtPt extends AppLocalizationsPt {
  AppLocalizationsPtPt() : super('pt_PT');

  @override
  String get appName => 'SpotiFLAC';

  @override
  String get appDescription =>
      'Baixe faixas do Spotify em qualidade sem perdas de Tidal, Qobuz e Amazon Music.';

  @override
  String get navHome => 'Início';

  @override
  String get navHistory => 'Histórico';

  @override
  String get navSettings => 'Configurações';

  @override
  String get navStore => 'Loja';

  @override
  String get homeTitle => 'Início';

  @override
  String get homeSearchHint => 'Pesquise ou cole a URL do Spotify...';

  @override
  String homeSearchHintExtension(String extensionName) {
    return 'Pesquisar com $extensionName...';
  }

  @override
  String get homeSubtitle => 'Cole um link do Spotify ou procure por nome';

  @override
  String get homeSupports =>
      'Suporte: Faixas, Álbuns, Playlists, URLs de Artista';

  @override
  String get homeRecent => 'Recentes';

  @override
  String get historyTitle => 'Histórico';

  @override
  String historyDownloading(int count) {
    return 'Baixando ($count)';
  }

  @override
  String get historyDownloaded => 'Baixados';

  @override
  String get historyFilterAll => 'Tudo';

  @override
  String get historyFilterAlbums => 'Álbuns';

  @override
  String get historyFilterSingles => 'Singles';

  @override
  String historyTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas',
      one: '1 faixa',
    );
    return '$_temp0';
  }

  @override
  String historyAlbumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbuns',
      one: '1 álbum',
    );
    return '$_temp0';
  }

  @override
  String get historyNoDownloads => 'Nenhum histórico de downloads';

  @override
  String get historyNoDownloadsSubtitle => 'As faixas baixadas aparecerão aqui';

  @override
  String get historyNoAlbums => 'Sem álbuns baixados';

  @override
  String get historyNoAlbumsSubtitle =>
      'Baixe várias faixas de um álbum para vê-las aqui';

  @override
  String get historyNoSingles => 'Sem singles baixados';

  @override
  String get historyNoSinglesSubtitle =>
      'Os downloads de faixa individuais aparecerão aqui';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsDownload => 'Download';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsOptions => 'Opções';

  @override
  String get settingsExtensions => 'Extensões';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get downloadTitle => 'Download';

  @override
  String get downloadLocation => 'Local dos Downloads';

  @override
  String get downloadLocationSubtitle => 'Escolha onde salvar os arquivos';

  @override
  String get downloadLocationDefault => 'Local padrão';

  @override
  String get downloadDefaultService => 'Serviço Padrão';

  @override
  String get downloadDefaultServiceSubtitle => 'Serviço usado para downloads';

  @override
  String get downloadDefaultQuality => 'Qualidade Predefinida';

  @override
  String get downloadAskQuality => 'Perguntar qualidade antes de baixar';

  @override
  String get downloadAskQualitySubtitle =>
      'Mostrar seletor de qualidade para cada download';

  @override
  String get downloadFilenameFormat => 'Formato do Nome do Arquivo';

  @override
  String get downloadFolderOrganization => 'Organização de Pastas';

  @override
  String get downloadSeparateSingles => 'Separar Singles';

  @override
  String get downloadSeparateSinglesSubtitle =>
      'Colocar singles numa pasta separada';

  @override
  String get qualityBest => 'Melhor Disponível';

  @override
  String get qualityFlac => 'FLAC';

  @override
  String get quality320 => '320 kbps';

  @override
  String get quality128 => '128 kbps';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceThemeSystem => 'Sistema';

  @override
  String get appearanceThemeLight => 'Claro';

  @override
  String get appearanceThemeDark => 'Escuro';

  @override
  String get appearanceDynamicColor => 'Cores Dinâmicas';

  @override
  String get appearanceDynamicColorSubtitle =>
      'Usar cores do seu papel de parede';

  @override
  String get appearanceAccentColor => 'Cor de Destaque';

  @override
  String get appearanceHistoryView => 'Visualização do Histórico';

  @override
  String get appearanceHistoryViewList => 'Lista';

  @override
  String get appearanceHistoryViewGrid => 'Grade';

  @override
  String get optionsTitle => 'Opções';

  @override
  String get optionsSearchSource => 'Origem da Pesquisa';

  @override
  String get optionsPrimaryProvider => 'Provedor Primário';

  @override
  String get optionsPrimaryProviderSubtitle =>
      'Serviço usado ao pesquisar por nome da faixa.';

  @override
  String optionsUsingExtension(String extensionName) {
    return 'Usando a extensão: $extensionName';
  }

  @override
  String get optionsSwitchBack =>
      'Toque no Deezer ou Spotify para alternar de volta da extensão';

  @override
  String get optionsAutoFallback => 'Fallback Automático';

  @override
  String get optionsAutoFallbackSubtitle =>
      'Tentar outros serviços se o download falhar';

  @override
  String get optionsUseExtensionProviders => 'Usar Provedores de Extensão';

  @override
  String get optionsUseExtensionProvidersOn =>
      'Extensões serão tentadas primeiro';

  @override
  String get optionsUseExtensionProvidersOff =>
      'Usando apenas provedores integrados';

  @override
  String get optionsEmbedLyrics => 'Incorporar Letras';

  @override
  String get optionsEmbedLyricsSubtitle =>
      'Incorporar letras sincronizadas aos arquivos FLAC';

  @override
  String get optionsMaxQualityCover => 'Capa de Qualidade Máxima';

  @override
  String get optionsMaxQualityCoverSubtitle =>
      'Baixar capa do álbum com a mais alta resolução';

  @override
  String get optionsConcurrentDownloads => 'Downloads Simultâneos';

  @override
  String get optionsConcurrentSequential => 'Sequencial (1 por vez)';

  @override
  String optionsConcurrentParallel(int count) {
    return '$count downloads paralelos';
  }

  @override
  String get optionsConcurrentWarning =>
      'Downloads simultâneos podem causar um limite da taxa (ratelimit)';

  @override
  String get optionsExtensionStore => 'Loja de Extensões';

  @override
  String get optionsExtensionStoreSubtitle =>
      'Mostrar aba da Loja na navegação';

  @override
  String get optionsCheckUpdates => 'Procurar Atualizações';

  @override
  String get optionsCheckUpdatesSubtitle =>
      'Notificar quando uma nova versão estiver disponível';

  @override
  String get optionsUpdateChannel => 'Canal de Atualização';

  @override
  String get optionsUpdateChannelStable => 'Somente versões estáveis';

  @override
  String get optionsUpdateChannelPreview => 'Obter versões de prévia';

  @override
  String get optionsUpdateChannelWarning =>
      'A prévia pode conter erros ou recursos incompletos';

  @override
  String get optionsClearHistory => 'Limpar Histórico de Download';

  @override
  String get optionsClearHistorySubtitle =>
      'Remover todas as faixas baixadas do histórico';

  @override
  String get optionsDetailedLogging => 'Registro detalhado';

  @override
  String get optionsDetailedLoggingOn =>
      'Registros detalhados estão sendo gravados';

  @override
  String get optionsDetailedLoggingOff => 'Habilitar para relatórios de erros';

  @override
  String get optionsSpotifyCredentials => 'Credenciais do Spotify';

  @override
  String optionsSpotifyCredentialsConfigured(String clientId) {
    return 'Client ID: $clientId...';
  }

  @override
  String get optionsSpotifyCredentialsRequired =>
      'Obrigatório - toque para configurar';

  @override
  String get optionsSpotifyWarning =>
      'O Spotify requer as suas próprias credenciais de API. Consiga gratuitamente em developer.spotify.com';

  @override
  String get extensionsTitle => 'Extensões';

  @override
  String get extensionsInstalled => 'Extensões Instaladas';

  @override
  String get extensionsNone => 'Nenhuma extensão instalada';

  @override
  String get extensionsNoneSubtitle =>
      'Instalar extensões a partir da aba Loja';

  @override
  String get extensionsEnabled => 'Habilitado';

  @override
  String get extensionsDisabled => 'Desabilitado';

  @override
  String extensionsVersion(String version) {
    return 'Versão $version';
  }

  @override
  String extensionsAuthor(String author) {
    return 'por $author';
  }

  @override
  String get extensionsUninstall => 'Desinstalar';

  @override
  String get extensionsSetAsSearch => 'Definir como Provedor de Pesquisa';

  @override
  String get storeTitle => 'Loja de Extensões';

  @override
  String get storeSearch => 'Pesquisar extensões...';

  @override
  String get storeInstall => 'Instalar';

  @override
  String get storeInstalled => 'Instalado';

  @override
  String get storeUpdate => 'Atualizar';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get aboutContributors => 'Colaboradores';

  @override
  String get aboutMobileDeveloper => 'Desenvolvedor da versão móvel';

  @override
  String get aboutOriginalCreator => 'Criador do SpotiFLAC original';

  @override
  String get aboutLogoArtist =>
      'O artista talentoso que criou o nosso lindo logotipo do aplicativo!';

  @override
  String get aboutSpecialThanks => 'Agradecimentos Especiais';

  @override
  String get aboutLinks => 'Links';

  @override
  String get aboutMobileSource => 'Código-fonte do app móvel';

  @override
  String get aboutPCSource => 'Código-fonte do app desktop';

  @override
  String get aboutReportIssue => 'Reportar um problema';

  @override
  String get aboutReportIssueSubtitle =>
      'Reporte qualquer problema que encontrar';

  @override
  String get aboutFeatureRequest => 'Solicitação de recurso';

  @override
  String get aboutFeatureRequestSubtitle =>
      'Sugira novos recursos para o aplicativo';

  @override
  String get aboutSupport => 'Apoiar';

  @override
  String get aboutBuyMeCoffee => 'Compre-me um café';

  @override
  String get aboutBuyMeCoffeeSubtitle => 'Apoie o desenvolvimento na Ko-fi';

  @override
  String get aboutApp => 'Aplicativo';

  @override
  String get aboutVersion => 'Versão';

  @override
  String get aboutBinimumDesc =>
      'O criador da API QQDL e HiFi. Sem esta API, os downloads Tidal não existiriam!';

  @override
  String get aboutSachinsenalDesc =>
      'O criador original do projeto HiFi. A base da integração do Tidal!';

  @override
  String get aboutDoubleDouble => 'DoubleDouble';

  @override
  String get aboutDoubleDoubleDesc =>
      'API incrível para downloads do Amazon Music. Obrigado por fazê-lo gratuitamente!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'A melhor API de streaming do Qobuz. Downloads de alta resolução não seriam possíveis sem isso!';

  @override
  String get aboutAppDescription =>
      'Baixe faixas do Spotify em qualidade sem perdas do Tidal, Qobuz e Amazon Music.';

  @override
  String get albumTitle => 'Álbum';

  @override
  String albumTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas',
      one: '1 faixa',
    );
    return '$_temp0';
  }

  @override
  String get albumDownloadAll => 'Baixar Tudo';

  @override
  String get albumDownloadRemaining => 'Downloads Restantes';

  @override
  String get playlistTitle => 'Playlist';

  @override
  String get artistTitle => 'Artista';

  @override
  String get artistAlbums => 'Álbuns';

  @override
  String get artistSingles => 'Singles e EPs';

  @override
  String get artistCompilations => 'Compilações';

  @override
  String artistReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lançamentos',
      one: '1 lançamento',
    );
    return '$_temp0';
  }

  @override
  String get artistPopular => 'Populares';

  @override
  String artistMonthlyListeners(String count) {
    return '$count ouvintes mensais';
  }

  @override
  String get trackMetadataTitle => 'Informações da Faixa';

  @override
  String get trackMetadataArtist => 'Artista';

  @override
  String get trackMetadataAlbum => 'Álbum';

  @override
  String get trackMetadataDuration => 'Duração';

  @override
  String get trackMetadataQuality => 'Qualidade';

  @override
  String get trackMetadataPath => 'Caminho do Arquivo';

  @override
  String get trackMetadataDownloadedAt => 'Baixado';

  @override
  String get trackMetadataService => 'Serviço';

  @override
  String get trackMetadataPlay => 'Reproduzir';

  @override
  String get trackMetadataShare => 'Compartilhar';

  @override
  String get trackMetadataDelete => 'Apagar';

  @override
  String get trackMetadataRedownload => 'Baixar Novamente';

  @override
  String get trackMetadataOpenFolder => 'Abrir Pasta';

  @override
  String get setupTitle => 'Bem-vindo ao SpotiFLAC';

  @override
  String get setupSubtitle => 'Vamos começar';

  @override
  String get setupStoragePermission => 'Permissão de Armazenamento';

  @override
  String get setupStoragePermissionSubtitle =>
      'Necessária para salvar arquivos baixados';

  @override
  String get setupStoragePermissionGranted => 'Permissão concedida';

  @override
  String get setupStoragePermissionDenied => 'Permissão negada';

  @override
  String get setupGrantPermission => 'Conceder Permissão';

  @override
  String get setupDownloadLocation => 'Local do Download';

  @override
  String get setupChooseFolder => 'Selecionar Pasta';

  @override
  String get setupContinue => 'Continuar';

  @override
  String get setupSkip => 'Ignorar por enquanto';

  @override
  String get setupStorageAccessRequired => 'Acesso ao Armazenamento Necessário';

  @override
  String get setupStorageAccessMessage =>
      'O SpotiFLAC precisa da permissão \"Acesso a todos os arquivos\" para salvar arquivos de música na sua pasta escolhida.';

  @override
  String get setupStorageAccessMessageAndroid11 =>
      'O Android 11+ requer a permissão \"Acesso a Todos os Arquivos\" para salvar arquivos na pasta de download escolhida.';

  @override
  String get setupOpenSettings => 'Abrir Configurações';

  @override
  String get setupPermissionDeniedMessage =>
      'Permissão negada. Por favor, conceda todas as permissões para continuar.';

  @override
  String setupPermissionRequired(String permissionType) {
    return 'Permissão $permissionType Necessária';
  }

  @override
  String setupPermissionRequiredMessage(String permissionType) {
    return 'A permissão $permissionType é necessária para a melhor experiência. Você pode alterar isso mais tarde em Configurações.';
  }

  @override
  String get setupSelectDownloadFolder => 'Escolher Pasta de Download';

  @override
  String get setupUseDefaultFolder => 'Usar Pasta Padrão?';

  @override
  String get setupNoFolderSelected =>
      'Nenhuma pasta selecionada. Você gostaria de usar a pasta padrão de música?';

  @override
  String get setupUseDefault => 'Usar Padrão';

  @override
  String get setupDownloadLocationTitle => 'Local do Download';

  @override
  String get setupDownloadLocationIosMessage =>
      'No iOS, downloads são salvos na pasta Documentos do aplicativo. Você pode acessá-los através do app Arquivos.';

  @override
  String get setupAppDocumentsFolder => 'Pasta Documentos do App';

  @override
  String get setupAppDocumentsFolderSubtitle =>
      'Recomendado - acessível através do aplicativo Arquivos';

  @override
  String get setupChooseFromFiles => 'Escolher dos Arquivos';

  @override
  String get setupChooseFromFilesSubtitle =>
      'Selecione o iCloud ou outro local';

  @override
  String get setupIosEmptyFolderWarning =>
      'Limitação do iOS: Pastas vazias não podem ser selecionadas. Escolha uma pasta com pelo menos um arquivo.';

  @override
  String get setupDownloadInFlac => 'Download Spotify tracks in FLAC';

  @override
  String get setupStepStorage => 'Storage';

  @override
  String get setupStepNotification => 'Notification';

  @override
  String get setupStepFolder => 'Folder';

  @override
  String get setupStepSpotify => 'Spotify';

  @override
  String get setupStepPermission => 'Permission';

  @override
  String get setupStorageGranted => 'Storage Permission Granted!';

  @override
  String get setupStorageRequired => 'Storage Permission Required';

  @override
  String get setupStorageDescription =>
      'SpotiFLAC needs storage permission to save your downloaded music files.';

  @override
  String get setupNotificationGranted => 'Permissão de Notificações Concedida!';

  @override
  String get setupNotificationEnable => 'Habilitar Notificações';

  @override
  String get setupNotificationDescription =>
      'Seja notificado quando os downloads completarem ou exigirem atenção.';

  @override
  String get setupFolderSelected => 'Pasta para Download Selecionada!';

  @override
  String get setupFolderChoose => 'Escolher Pasta de Download';

  @override
  String get setupFolderDescription =>
      'Selecione uma pasta onde as suas músicas baixadas serão salvas.';

  @override
  String get setupChangeFolder => 'Alterar Pasta';

  @override
  String get setupSelectFolder => 'Seleccionar Pasta';

  @override
  String get setupSpotifyApiOptional => 'API do Spotify (opcional)';

  @override
  String get setupSpotifyApiDescription =>
      'Adicione as suas credenciais da API do Spotify para obter melhores resultados de busca e acesso a conteúdo exclusivo do Spotify.';

  @override
  String get setupUseSpotifyApi => 'Usar API do Spotify';

  @override
  String get setupEnterCredentialsBelow => 'Insira as suas credenciais abaixo';

  @override
  String get setupUsingDeezer => 'Usando o Deezer (nenhuma conta necessária)';

  @override
  String get setupEnterClientId => 'Insira o Spotify Client ID';

  @override
  String get setupEnterClientSecret => 'Insira o Spotify Client Secret';

  @override
  String get setupGetFreeCredentials =>
      'Receba as suas credenciais de API gratuitas na Spotify Developer Dashboard.';

  @override
  String get setupEnableNotifications => 'Habilitar Notificações';

  @override
  String get setupProceedToNextStep =>
      'Você já pode prosseguir para o próximo passo.';

  @override
  String get setupNotificationProgressDescription =>
      'Você receberá notificações de progresso dos downloads.';

  @override
  String get setupNotificationBackgroundDescription =>
      'Seja notificado sobre o progresso e conclusão do download. Isso ajuda você a acompanhar os downloads quando o app estiver em segundo plano.';

  @override
  String get setupSkipForNow => 'Ignorar por enquanto';

  @override
  String get setupBack => 'Voltar';

  @override
  String get setupNext => 'Próximo';

  @override
  String get setupGetStarted => 'Começar';

  @override
  String get setupSkipAndStart => 'Ignorar e Iniciar';

  @override
  String get setupAllowAccessToManageFiles =>
      'Por favor, habilite \"Permitir acesso para gerenciar todos os arquivos\" na próxima tela.';

  @override
  String get setupGetCredentialsFromSpotify =>
      'Obter credenciais do developer.spotify.com';

  @override
  String get dialogCancel => 'Cancelar';

  @override
  String get dialogOk => 'OK';

  @override
  String get dialogSave => 'Salvar';

  @override
  String get dialogDelete => 'Apagar';

  @override
  String get dialogRetry => 'Tentar novamente';

  @override
  String get dialogClose => 'Fechar';

  @override
  String get dialogYes => 'Sim';

  @override
  String get dialogNo => 'Não';

  @override
  String get dialogClear => 'Limpar';

  @override
  String get dialogConfirm => 'Confirmar';

  @override
  String get dialogDone => 'Concluído';

  @override
  String get dialogImport => 'Importar';

  @override
  String get dialogDiscard => 'Descartar';

  @override
  String get dialogRemove => 'Remover';

  @override
  String get dialogUninstall => 'Desinstalar';

  @override
  String get dialogDiscardChanges => 'Descartar Alterações?';

  @override
  String get dialogUnsavedChanges =>
      'Você tem alterações não salvas. Deseja descartá-las?';

  @override
  String get dialogDownloadFailed => 'Download Falhou';

  @override
  String get dialogTrackLabel => 'Faixa:';

  @override
  String get dialogArtistLabel => 'Artista:';

  @override
  String get dialogErrorLabel => 'Erro:';

  @override
  String get dialogClearAll => 'Limpar Tudo';

  @override
  String get dialogClearAllDownloads =>
      'Você tem certeza que deseja limpar todos os downloads?';

  @override
  String get dialogRemoveFromDevice => 'Remove from device?';

  @override
  String get dialogRemoveExtension => 'Remove Extension';

  @override
  String get dialogRemoveExtensionMessage =>
      'Are you sure you want to remove this extension? This cannot be undone.';

  @override
  String get dialogUninstallExtension => 'Uninstall Extension?';

  @override
  String dialogUninstallExtensionMessage(String extensionName) {
    return 'Are you sure you want to remove $extensionName?';
  }

  @override
  String get dialogClearHistoryTitle => 'Clear History';

  @override
  String get dialogClearHistoryMessage =>
      'Are you sure you want to clear all download history? This cannot be undone.';

  @override
  String get dialogDeleteSelectedTitle => 'Delete Selected';

  @override
  String dialogDeleteSelectedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Delete $count $_temp0 from history?\n\nThis will also delete the files from storage.';
  }

  @override
  String get dialogImportPlaylistTitle => 'Import Playlist';

  @override
  String dialogImportPlaylistMessage(int count) {
    return 'Found $count tracks in CSV. Add them to download queue?';
  }

  @override
  String snackbarAddedToQueue(String trackName) {
    return 'Added \"$trackName\" to queue';
  }

  @override
  String snackbarAddedTracksToQueue(int count) {
    return 'Added $count tracks to queue';
  }

  @override
  String snackbarAlreadyDownloaded(String trackName) {
    return '\"$trackName\" already downloaded';
  }

  @override
  String get snackbarHistoryCleared => 'History cleared';

  @override
  String get snackbarCredentialsSaved => 'Credentials saved';

  @override
  String get snackbarCredentialsCleared => 'Credentials cleared';

  @override
  String snackbarDeletedTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Deleted $count $_temp0';
  }

  @override
  String snackbarCannotOpenFile(String error) {
    return 'Cannot open file: $error';
  }

  @override
  String get snackbarFillAllFields => 'Please fill all fields';

  @override
  String get snackbarViewQueue => 'View Queue';

  @override
  String snackbarFailedToLoad(String error) {
    return 'Failed to load: $error';
  }

  @override
  String snackbarUrlCopied(String platform) {
    return '$platform URL copied to clipboard';
  }

  @override
  String get snackbarFileNotFound => 'File not found';

  @override
  String get snackbarSelectExtFile => 'Please select a .spotiflac-ext file';

  @override
  String get snackbarProviderPrioritySaved => 'Provider priority saved';

  @override
  String get snackbarMetadataProviderSaved =>
      'Metadata provider priority saved';

  @override
  String snackbarExtensionInstalled(String extensionName) {
    return '$extensionName installed.';
  }

  @override
  String snackbarExtensionUpdated(String extensionName) {
    return '$extensionName updated.';
  }

  @override
  String get snackbarFailedToInstall => 'Failed to install extension';

  @override
  String get snackbarFailedToUpdate => 'Failed to update extension';

  @override
  String get errorRateLimited => 'Rate Limited';

  @override
  String get errorRateLimitedMessage =>
      'Too many requests. Please wait a moment before searching again.';

  @override
  String errorFailedToLoad(String item) {
    return 'Failed to load $item';
  }

  @override
  String get errorNoTracksFound => 'No tracks found';

  @override
  String errorMissingExtensionSource(String item) {
    return 'Cannot load $item: missing extension source';
  }

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusDownloading => 'Downloading';

  @override
  String get statusFinalizing => 'Finalizing';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusSkipped => 'Ignorado';

  @override
  String get statusPaused => 'Pausado';

  @override
  String get actionPause => 'Pausar';

  @override
  String get actionResume => 'Retomar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionStop => 'Parar';

  @override
  String get actionSelect => 'Selecionar';

  @override
  String get actionSelectAll => 'Selecionar Tudo';

  @override
  String get actionDeselect => 'Desselecionar';

  @override
  String get actionPaste => 'Colar';

  @override
  String get actionImportCsv => 'Importar CSV';

  @override
  String get actionRemoveCredentials => 'Remover Credenciais';

  @override
  String get actionSaveCredentials => 'Salvar Credenciais';

  @override
  String selectionSelected(int count) {
    return '$count selecionado(s)';
  }

  @override
  String get selectionAllSelected => 'Todas as faixas selecionadas';

  @override
  String get selectionTapToSelect => 'Toque nas faixas para selecionar';

  @override
  String selectionDeleteTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'faixas',
      one: 'faixa',
    );
    return 'Apagar $count $_temp0';
  }

  @override
  String get selectionSelectToDelete => 'Selecione as faixas para apagar';

  @override
  String progressFetchingMetadata(int current, int total) {
    return 'Buscando metadados... $current/$total';
  }

  @override
  String get progressReadingCsv => 'Lendo CSV...';

  @override
  String get searchSongs => 'Músicas';

  @override
  String get searchArtists => 'Artistas';

  @override
  String get searchAlbums => 'Álbuns';

  @override
  String get searchPlaylists => 'Playlists';

  @override
  String get tooltipPlay => 'Reproduzir';

  @override
  String get tooltipCancel => 'Cancelar';

  @override
  String get tooltipStop => 'Parar';

  @override
  String get tooltipRetry => 'Tentar Novamente';

  @override
  String get tooltipRemove => 'Remover';

  @override
  String get tooltipClear => 'Limpar';

  @override
  String get tooltipPaste => 'Colar';

  @override
  String get filenameFormat => 'Formato do Nome do Arquivo';

  @override
  String filenameFormatPreview(String preview) {
    return 'Prévia: $preview';
  }

  @override
  String get filenameAvailablePlaceholders => 'Substituições permitidas:';

  @override
  String filenameHint(Object artist, Object title) {
    return '$artist - $title';
  }

  @override
  String get folderOrganization => 'Organização de Pastas';

  @override
  String get folderOrganizationNone => 'Nenhuma organização';

  @override
  String get folderOrganizationByArtist => 'Por Artista';

  @override
  String get folderOrganizationByAlbum => 'Por Album';

  @override
  String get folderOrganizationByArtistAlbum => 'Artista/Álbum';

  @override
  String get folderOrganizationDescription =>
      'Organizar arquivos baixados em pastas';

  @override
  String get folderOrganizationNoneSubtitle =>
      'Todos os arquivos na pasta de download';

  @override
  String get folderOrganizationByArtistSubtitle =>
      'Pasta separada para cada artista';

  @override
  String get folderOrganizationByAlbumSubtitle =>
      'Pasta separada para cada álbum';

  @override
  String get folderOrganizationByArtistAlbumSubtitle =>
      'Pastas aninhadas para artista e álbum';

  @override
  String get updateAvailable => 'Atualização Disponível';

  @override
  String updateNewVersion(String version) {
    return 'A versão $version está disponível';
  }

  @override
  String get updateDownload => 'Baixar';

  @override
  String get updateLater => 'Depois';

  @override
  String get updateChangelog => 'Lista de alterações';

  @override
  String get updateStartingDownload => 'Iniciando download...';

  @override
  String get updateDownloadFailed => 'Download falhou';

  @override
  String get updateFailedMessage => 'Falha ao baixar a atualização';

  @override
  String get updateNewVersionReady => 'Uma nova versão está pronta';

  @override
  String get updateCurrent => 'Atual';

  @override
  String get updateNew => 'Novo';

  @override
  String get updateDownloading => 'Baixando...';

  @override
  String get updateWhatsNew => 'Novidades';

  @override
  String get updateDownloadInstall => 'Baixar e Instalar';

  @override
  String get updateDontRemind => 'Não lembrar';

  @override
  String get providerPriority => 'Prioridade de Provedor';

  @override
  String get providerPrioritySubtitle =>
      'Arraste para reordenar os provedores de download';

  @override
  String get providerPriorityTitle => 'Prioridade de Provedor';

  @override
  String get providerPriorityDescription =>
      'Arraste para reordenar provedores de download. O aplicativo irá tentar provedores de cima para baixo ao baixar as faixas.';

  @override
  String get providerPriorityInfo =>
      'Se uma faixa não estiver disponível no primeiro provedor, o aplicativo irá tentar automaticamente a próxima.';

  @override
  String get providerBuiltIn => 'Embutido';

  @override
  String get providerExtension => 'Extensão';

  @override
  String get metadataProviderPriority => 'Prioridade de Provedor de Metadados';

  @override
  String get metadataProviderPrioritySubtitle =>
      'Ordem usada para obter metadados de faixa';

  @override
  String get metadataProviderPriorityTitle => 'Prioridade de Metadados';

  @override
  String get metadataProviderPriorityDescription =>
      'Arraste para reordenar provedores de metadados. O aplicativo tentará provedores de cima para baixo ao procurar por faixas e buscar metadados.';

  @override
  String get metadataProviderPriorityInfo =>
      'O Deezer não tem limites de taxa e é recomendado como principal. O Spotify pode limitar a taxa após muitas solicitações.';

  @override
  String get metadataNoRateLimits => 'Sem limites de taxa';

  @override
  String get metadataMayRateLimit => 'Pode ter limites de taxa';

  @override
  String get logTitle => 'Registros';

  @override
  String get logCopy => 'Copiar Registros';

  @override
  String get logClear => 'Limpar Registros';

  @override
  String get logShare => 'Compartilhar Registros';

  @override
  String get logEmpty => 'Ainda não há registros';

  @override
  String get logCopied => 'Registros copiados para área de transferência';

  @override
  String get logSearchHint => 'Pesquisar registros...';

  @override
  String get logFilterLevel => 'Nível';

  @override
  String get logFilterSection => 'Filtro';

  @override
  String get logShareLogs => 'Compartilhar registros';

  @override
  String get logClearLogs => 'Limpar registros';

  @override
  String get logClearLogsTitle => 'Limpar Registros';

  @override
  String get logClearLogsMessage =>
      'Tem certeza de que deseja limpar todos os registros?';

  @override
  String get logIspBlocking => 'BLOQUEIO DE ISP DETECTADO';

  @override
  String get logRateLimited => 'TAXA LIMITADA (RATELIMITED)';

  @override
  String get logNetworkError => 'ERRO DE REDE';

  @override
  String get logTrackNotFound => 'FAIXA NÃO ENCONTRADA';

  @override
  String get logFilterBySeverity => 'Filtrar registros por gravidade';

  @override
  String get logNoLogsYet => 'Ainda não há registros';

  @override
  String get logNoLogsYetSubtitle =>
      'Os registros aparecerão aqui enquanto você usa o aplicativo';

  @override
  String get logIssueSummary => 'Resumo do Problemas';

  @override
  String get logIspBlockingDescription =>
      'O seu provedor pode estar bloqueando o acesso aos serviços de download';

  @override
  String get logIspBlockingSuggestion =>
      'Tente usar uma VPN ou altere o DNS para 1.1.1 ou 8.8.8.8';

  @override
  String get logRateLimitedDescription => 'Muitas solicitações ao serviço';

  @override
  String get logRateLimitedSuggestion =>
      'Aguarde alguns minutos antes de tentar novamente';

  @override
  String get logNetworkErrorDescription => 'Problemas de conexão detectados';

  @override
  String get logNetworkErrorSuggestion => 'Check your internet connection';

  @override
  String get logTrackNotFoundDescription =>
      'Some tracks could not be found on download services';

  @override
  String get logTrackNotFoundSuggestion =>
      'The track may not be available in lossless quality';

  @override
  String logTotalErrors(int count) {
    return 'Total errors: $count';
  }

  @override
  String logAffected(String domains) {
    return 'Affected: $domains';
  }

  @override
  String logEntriesFiltered(int count) {
    return 'Entries ($count filtered)';
  }

  @override
  String logEntries(int count) {
    return 'Entries ($count)';
  }

  @override
  String get credentialsTitle => 'Spotify Credentials';

  @override
  String get credentialsDescription =>
      'Enter your Client ID and Secret to use your own Spotify application quota.';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Colar Client ID';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => 'Colar Client Secret';

  @override
  String get channelStable => 'Estável';

  @override
  String get channelPreview => 'Prévia';

  @override
  String get sectionSearchSource => 'Origem da Pesquisa';

  @override
  String get sectionDownload => 'Download';

  @override
  String get sectionPerformance => 'Desempenho';

  @override
  String get sectionApp => 'Aplicativo';

  @override
  String get sectionData => 'Dados';

  @override
  String get sectionDebug => 'Depuração';

  @override
  String get sectionService => 'Serviço';

  @override
  String get sectionAudioQuality => 'Qualidade de Áudio';

  @override
  String get sectionFileSettings => 'Configurações de Arquivo';

  @override
  String get sectionColor => 'Cor';

  @override
  String get sectionTheme => 'Tema';

  @override
  String get sectionLayout => 'Layout';

  @override
  String get sectionLanguage => 'Idioma';

  @override
  String get appearanceLanguage => 'Idioma do aplicativo';

  @override
  String get appearanceLanguageSubtitle => 'Escolha o seu idioma preferido';

  @override
  String get settingsAppearanceSubtitle => 'Tema, cores, exibição';

  @override
  String get settingsDownloadSubtitle =>
      'Serviço, qualidade, formato de nome de arquivo';

  @override
  String get settingsOptionsSubtitle =>
      'Fallback, letras, arte de capa, atualizações';

  @override
  String get settingsExtensionsSubtitle => 'Gerenciar provedores de download';

  @override
  String get settingsLogsSubtitle => 'Ver logs do app para depuração';

  @override
  String get loadingSharedLink => 'Carregando link compartilhado...';

  @override
  String get pressBackAgainToExit => 'Pressione voltar novamente para sair';

  @override
  String get tracksHeader => 'Faixas';

  @override
  String downloadAllCount(int count) {
    return 'Baixar Todos ($count)';
  }

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas',
      one: '1 faixa',
    );
    return '$_temp0';
  }

  @override
  String get trackCopyFilePath => 'Copiar caminho do arquivo';

  @override
  String get trackRemoveFromDevice => 'Remover do dispositivo';

  @override
  String get trackLoadLyrics => 'Carregar Letras';

  @override
  String get trackMetadata => 'Metadados';

  @override
  String get trackFileInfo => 'Informações do Arquivo';

  @override
  String get trackLyrics => 'Letras';

  @override
  String get trackFileNotFound => 'Arquivo não encontrado';

  @override
  String get trackOpenInDeezer => 'Abrir no Deezer';

  @override
  String get trackOpenInSpotify => 'Abrir no Spotify';

  @override
  String get trackTrackName => 'Nome da faixa';

  @override
  String get trackArtist => 'Artista';

  @override
  String get trackAlbumArtist => 'Artista do álbum';

  @override
  String get trackAlbum => 'Álbum';

  @override
  String get trackTrackNumber => 'Número da faixa';

  @override
  String get trackDiscNumber => 'Número do disco';

  @override
  String get trackDuration => 'Duração';

  @override
  String get trackAudioQuality => 'Qualidade de Áudio';

  @override
  String get trackReleaseDate => 'Data de lançamento';

  @override
  String get trackDownloaded => 'Baixado';

  @override
  String get trackCopyLyrics => 'Copy lyrics';

  @override
  String get trackLyricsNotAvailable => 'Lyrics not available for this track';

  @override
  String get trackLyricsTimeout => 'Request timed out. Try again later.';

  @override
  String get trackLyricsLoadFailed => 'Failed to load lyrics';

  @override
  String get trackCopiedToClipboard => 'Copied to clipboard';

  @override
  String get trackDeleteConfirmTitle => 'Remove from device?';

  @override
  String get trackDeleteConfirmMessage =>
      'This will permanently delete the downloaded file and remove it from your history.';

  @override
  String trackCannotOpen(String message) {
    return 'Cannot open: $message';
  }

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String dateWeeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String dateMonthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String get concurrentSequential => 'Sequential';

  @override
  String get concurrentParallel2 => '2 Parallel';

  @override
  String get concurrentParallel3 => '3 Parallel';

  @override
  String get tapToSeeError => 'Tap to see error details';

  @override
  String get storeFilterAll => 'All';

  @override
  String get storeFilterMetadata => 'Metadata';

  @override
  String get storeFilterDownload => 'Download';

  @override
  String get storeFilterUtility => 'Utility';

  @override
  String get storeFilterLyrics => 'Lyrics';

  @override
  String get storeFilterIntegration => 'Integration';

  @override
  String get storeClearFilters => 'Clear filters';

  @override
  String get storeNoResults => 'No extensions found';

  @override
  String get extensionProviderPriority => 'Provider Priority';

  @override
  String get extensionInstallButton => 'Install Extension';

  @override
  String get extensionDefaultProvider => 'Default (Deezer/Spotify)';

  @override
  String get extensionDefaultProviderSubtitle => 'Use built-in search';

  @override
  String get extensionAuthor => 'Author';

  @override
  String get extensionId => 'ID';

  @override
  String get extensionError => 'Error';

  @override
  String get extensionCapabilities => 'Capabilities';

  @override
  String get extensionMetadataProvider => 'Metadata Provider';

  @override
  String get extensionDownloadProvider => 'Download Provider';

  @override
  String get extensionLyricsProvider => 'Lyrics Provider';

  @override
  String get extensionUrlHandler => 'URL Handler';

  @override
  String get extensionQualityOptions => 'Quality Options';

  @override
  String get extensionPostProcessingHooks => 'Post-Processing Hooks';

  @override
  String get extensionPermissions => 'Permissions';

  @override
  String get extensionSettings => 'Settings';

  @override
  String get extensionRemoveButton => 'Remover Extensão';

  @override
  String get extensionUpdated => 'Atualizado';

  @override
  String get extensionMinAppVersion => 'Versão Mínima do App';

  @override
  String get extensionCustomTrackMatching =>
      'Correspondência de Faixa Personalizada';

  @override
  String get extensionPostProcessing => 'Pós-Processamento';

  @override
  String extensionHooksAvailable(int count) {
    return '$count gancho(s) disponíveis';
  }

  @override
  String extensionPatternsCount(int count) {
    return '$count padrão(ões)';
  }

  @override
  String extensionStrategy(String strategy) {
    return 'Estratégia: $strategy';
  }

  @override
  String get extensionsProviderPrioritySection => 'Prioridade de Provedor';

  @override
  String get extensionsInstalledSection => 'Extensões Instaladas';

  @override
  String get extensionsNoExtensions => 'Nenhuma extensão instalada';

  @override
  String get extensionsNoExtensionsSubtitle =>
      'Instale arquivos .spotiflac-ext para adicionar novos provedores';

  @override
  String get extensionsInstallButton => 'Instalar Extensão';

  @override
  String get extensionsInfoTip =>
      'Extensões podem adicionar novos metadados e baixar provedores. Somente instale extensões a partir de fontes confiáveis.';

  @override
  String get extensionsInstalledSuccess => 'Extensão instalada com sucesso';

  @override
  String get extensionsDownloadPriority => 'Prioridade de Download';

  @override
  String get extensionsDownloadPrioritySubtitle =>
      'Definir ordem do serviço de download';

  @override
  String get extensionsNoDownloadProvider =>
      'Nenhuma extensão com provedor de download';

  @override
  String get extensionsMetadataPriority => 'Prioridade de Metadados';

  @override
  String get extensionsMetadataPrioritySubtitle =>
      'Definir ordem de origem de pesquisa e metadados';

  @override
  String get extensionsNoMetadataProvider =>
      'Nenhuma extensão com provedor de metadados';

  @override
  String get extensionsSearchProvider => 'Provedor de Pesquisa';

  @override
  String get extensionsNoCustomSearch =>
      'Nenhuma extensão com pesquisa personalizada';

  @override
  String get extensionsSearchProviderDescription =>
      'Escolha qual serviço utilizar para pesquisar faixas';

  @override
  String get extensionsCustomSearch => 'Busca personalizada';

  @override
  String get extensionsErrorLoading => 'Erro ao carregar extensão';

  @override
  String get qualityFlacLossless => 'FLAC Lossless';

  @override
  String get qualityFlacLosslessSubtitle => '16-bit / 44.1kHz';

  @override
  String get qualityHiResFlac => 'Hi-Res FLAC';

  @override
  String get qualityHiResFlacSubtitle => '24-bit / até 96kHz';

  @override
  String get qualityHiResFlacMax => 'Hi-Res FLAC Max';

  @override
  String get qualityHiResFlacMaxSubtitle => '24-bit / até 192kHz';

  @override
  String get qualityNote =>
      'A qualidade real depende da faixa que estiver disponível no serviço';

  @override
  String get downloadAskBeforeDownload => 'Perguntar qualidade antes de baixar';

  @override
  String get downloadDirectory => 'Pasta de Download';

  @override
  String get downloadSeparateSinglesFolder => 'Pasta de Singles Separada';

  @override
  String get downloadAlbumFolderStructure => 'Estrutura da Pasta de Álbum';

  @override
  String get downloadSaveFormat => 'Formato para Salvar';

  @override
  String get downloadSelectService => 'Selecionar Serviço';

  @override
  String get downloadSelectQuality => 'Selecionar Qualidade';

  @override
  String get downloadFrom => 'Baixar De';

  @override
  String get downloadDefaultQualityLabel => 'Qualidade Padrão';

  @override
  String get downloadBestAvailable => 'Melhor Disponível';

  @override
  String get folderNone => 'Nenhum';

  @override
  String get folderNoneSubtitle => 'Save all files directly to download folder';

  @override
  String get folderArtist => 'Artist';

  @override
  String get folderArtistSubtitle => 'Artist Name/filename';

  @override
  String get folderAlbum => 'Album';

  @override
  String get folderAlbumSubtitle => 'Album Name/filename';

  @override
  String get folderArtistAlbum => 'Artist/Album';

  @override
  String get folderArtistAlbumSubtitle => 'Artist Name/Album Name/filename';

  @override
  String get serviceTidal => 'Tidal';

  @override
  String get serviceQobuz => 'Qobuz';

  @override
  String get serviceAmazon => 'Amazon';

  @override
  String get serviceDeezer => 'Deezer';

  @override
  String get serviceSpotify => 'Spotify';

  @override
  String get appearanceAmoledDark => 'AMOLED Dark';

  @override
  String get appearanceAmoledDarkSubtitle => 'Pure black background';

  @override
  String get appearanceChooseAccentColor => 'Choose Accent Color';

  @override
  String get appearanceChooseTheme => 'Theme Mode';

  @override
  String get queueTitle => 'Download Queue';

  @override
  String get queueClearAll => 'Clear All';

  @override
  String get queueClearAllMessage =>
      'Are you sure you want to clear all downloads?';

  @override
  String get queueEmpty => 'No downloads in queue';

  @override
  String get queueEmptySubtitle => 'Add tracks from the home screen';

  @override
  String get queueClearCompleted => 'Clear completed';

  @override
  String get queueDownloadFailed => 'Download Failed';

  @override
  String get queueTrackLabel => 'Track:';

  @override
  String get queueArtistLabel => 'Artist:';

  @override
  String get queueErrorLabel => 'Error:';

  @override
  String get queueUnknownError => 'Unknown error';

  @override
  String get albumFolderArtistAlbum => 'Artist / Album';

  @override
  String get albumFolderArtistAlbumSubtitle => 'Albums/Artist Name/Album Name/';

  @override
  String get albumFolderArtistYearAlbum => 'Artist / [Year] Album';

  @override
  String get albumFolderArtistYearAlbumSubtitle =>
      'Albums/Artist Name/[2005] Album Name/';

  @override
  String get albumFolderAlbumOnly => 'Album Only';

  @override
  String get albumFolderAlbumOnlySubtitle => 'Albums/Album Name/';

  @override
  String get albumFolderYearAlbum => '[Year] Album';

  @override
  String get albumFolderYearAlbumSubtitle => 'Albums/[2005] Album Name/';

  @override
  String get downloadedAlbumDeleteSelected => 'Delete Selected';

  @override
  String downloadedAlbumDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Delete $count $_temp0 from this album?\n\nThis will also delete the files from storage.';
  }

  @override
  String get downloadedAlbumTracksHeader => 'Tracks';

  @override
  String downloadedAlbumDownloadedCount(int count) {
    return '$count downloaded';
  }

  @override
  String downloadedAlbumSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get downloadedAlbumAllSelected => 'All tracks selected';

  @override
  String get downloadedAlbumTapToSelect => 'Tap tracks to select';

  @override
  String downloadedAlbumDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Delete $count $_temp0';
  }

  @override
  String get downloadedAlbumSelectToDelete => 'Select tracks to delete';

  @override
  String get utilityFunctions => 'Utility Functions';

  @override
  String get recentTypeArtist => 'Artist';

  @override
  String get recentTypeAlbum => 'Album';

  @override
  String get recentTypeSong => 'Song';

  @override
  String get recentTypePlaylist => 'Playlist';

  @override
  String recentPlaylistInfo(String name) {
    return 'Playlist: $name';
  }

  @override
  String errorGeneric(String message) {
    return 'Error: $message';
  }
}
