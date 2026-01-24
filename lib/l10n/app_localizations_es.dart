// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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

/// The translations for Spanish Castilian, as used in Spain (`es_ES`).
class AppLocalizationsEsEs extends AppLocalizationsEs {
  AppLocalizationsEsEs() : super('es_ES');

  @override
  String get appName => 'SpotiFLAC';

  @override
  String get appDescription =>
      'Descargue pistas de Spotify con calidad sin pérdida de Tidal, Qobuz y Amazon Music.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navHistory => 'Historial';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navStore => 'Tienda';

  @override
  String get homeTitle => 'Inicio';

  @override
  String get homeSearchHint => 'Pegar URL Spotify o buscar...';

  @override
  String homeSearchHintExtension(String extensionName) {
    return 'Buscar con $extensionName...';
  }

  @override
  String get homeSubtitle => 'Pegar enlace de Spotify o buscar por nombre';

  @override
  String get homeSupports =>
      'Soportes: Pista, Álbum, Lista de reproducción, URLs de Artistas';

  @override
  String get homeRecent => 'Recientes';

  @override
  String get historyTitle => 'Historial';

  @override
  String historyDownloading(int count) {
    return 'Descargando ($count)';
  }

  @override
  String get historyDownloaded => 'Descargado';

  @override
  String get historyFilterAll => 'Todo';

  @override
  String get historyFilterAlbums => 'Álbumes';

  @override
  String get historyFilterSingles => 'Pistas';

  @override
  String historyTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistas',
      one: '1 pista',
    );
    return '$_temp0';
  }

  @override
  String historyAlbumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbumes',
      one: '1 álbum',
    );
    return '$_temp0';
  }

  @override
  String get historyNoDownloads => 'No hay historial de descargas';

  @override
  String get historyNoDownloadsSubtitle =>
      'Las pistas descargadas aparecerán aquí';

  @override
  String get historyNoAlbums => 'No hay descargas de álbum';

  @override
  String get historyNoAlbumsSubtitle =>
      'Descargar múltiples pistas de un álbum para verlas aquí';

  @override
  String get historyNoSingles => 'No hay descargas';

  @override
  String get historyNoSinglesSubtitle =>
      'Las descargas de una sola pista aparecerán aquí';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsDownload => 'Descargar';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsOptions => 'Opciones';

  @override
  String get settingsExtensions => 'Extensiones';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get downloadTitle => 'Descargar';

  @override
  String get downloadLocation => 'Ubicación de descarga';

  @override
  String get downloadLocationSubtitle => 'Elija dónde guardar los archivos';

  @override
  String get downloadLocationDefault => 'Ubicación predeterminada';

  @override
  String get downloadDefaultService => 'Servicio por defecto';

  @override
  String get downloadDefaultServiceSubtitle => 'Servicio usado para descargas';

  @override
  String get downloadDefaultQuality => 'Calidad por defecto';

  @override
  String get downloadAskQuality => 'Preguntar calidad antes de descargar';

  @override
  String get downloadAskQualitySubtitle =>
      'Mostrar selector de calidad para cada descarga';

  @override
  String get downloadFilenameFormat => 'Formato del nombre del archivo';

  @override
  String get downloadFolderOrganization => 'Organización de carpetas';

  @override
  String get downloadSeparateSingles => 'Separar Pistas';

  @override
  String get downloadSeparateSinglesSubtitle =>
      'Colocar pistas individuales en una carpeta separada';

  @override
  String get qualityBest => 'Mejor disponible';

  @override
  String get qualityFlac => 'FLAC';

  @override
  String get quality320 => '320 kbps';

  @override
  String get quality128 => '128 kbps';

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceThemeSystem => 'Sistema';

  @override
  String get appearanceThemeLight => 'Claro';

  @override
  String get appearanceThemeDark => 'Oscuro';

  @override
  String get appearanceDynamicColor => 'Color dinámico';

  @override
  String get appearanceDynamicColorSubtitle =>
      'Usar colores de tu fondo de pantalla';

  @override
  String get appearanceAccentColor => 'Color Secundario';

  @override
  String get appearanceHistoryView => 'Vista de Historial';

  @override
  String get appearanceHistoryViewList => 'Lista';

  @override
  String get appearanceHistoryViewGrid => 'Cuadrícula';

  @override
  String get optionsTitle => 'Opciones';

  @override
  String get optionsSearchSource => 'Buscar Fuente';

  @override
  String get optionsPrimaryProvider => 'Proveedor Principal';

  @override
  String get optionsPrimaryProviderSubtitle =>
      'Servicio usado al buscar por nombre de la pista.';

  @override
  String optionsUsingExtension(String extensionName) {
    return 'Usando la extensión: $extensionName';
  }

  @override
  String get optionsSwitchBack =>
      'Toque Deezer o Spotify para volver desde la extensión';

  @override
  String get optionsAutoFallback => 'Alternativa automática';

  @override
  String get optionsAutoFallbackSubtitle =>
      'Pruebe otros servicios si falla la descarga';

  @override
  String get optionsUseExtensionProviders => 'Usar proveedores de extensiones';

  @override
  String get optionsUseExtensionProvidersOn =>
      'Las extensiones serán probadas primero';

  @override
  String get optionsUseExtensionProvidersOff =>
      'Utilizando sólo proveedores integrados';

  @override
  String get optionsEmbedLyrics => 'Incrustar Letras';

  @override
  String get optionsEmbedLyricsSubtitle =>
      'Insertar letras sincronizadas en archivos FLAC';

  @override
  String get optionsMaxQualityCover => 'Carátula de calidad máxima';

  @override
  String get optionsMaxQualityCoverSubtitle =>
      'Descargar carátula de resolución máxima';

  @override
  String get optionsConcurrentDownloads => 'Descargas Simultáneas';

  @override
  String get optionsConcurrentSequential => 'Secuencial (1 a la vez)';

  @override
  String optionsConcurrentParallel(int count) {
    return '$count descargas paralelas';
  }

  @override
  String get optionsConcurrentWarning =>
      'Las descargas paralelas pueden activar la limitación de velocidad';

  @override
  String get optionsExtensionStore => 'Tienda de extensiones';

  @override
  String get optionsExtensionStoreSubtitle =>
      'Mostrar pestaña de tienda en la navegación';

  @override
  String get optionsCheckUpdates => 'Comprobar actualizaciones';

  @override
  String get optionsCheckUpdatesSubtitle =>
      'Notificar cuando una nueva versión esté disponible';

  @override
  String get optionsUpdateChannel => 'Tipo de actualizaciones';

  @override
  String get optionsUpdateChannelStable => 'Sólo versiones estables';

  @override
  String get optionsUpdateChannelPreview => 'Versión preliminar';

  @override
  String get optionsUpdateChannelWarning =>
      'La Versión preliminar puede contener errores o características incompletas';

  @override
  String get optionsClearHistory => 'Borrar el historial de descargas';

  @override
  String get optionsClearHistorySubtitle =>
      'Eliminar todas las pistas descargadas del historial';

  @override
  String get optionsDetailedLogging => 'Registro detallado';

  @override
  String get optionsDetailedLoggingOn =>
      'Registros detallados están siendo registrados';

  @override
  String get optionsDetailedLoggingOff => 'Habilitar para informes de errores';

  @override
  String get optionsSpotifyCredentials => 'Credenciales de Spotify';

  @override
  String optionsSpotifyCredentialsConfigured(String clientId) {
    return 'ID de cliente: $clientId...';
  }

  @override
  String get optionsSpotifyCredentialsRequired =>
      'Requerido - toque para configurar';

  @override
  String get optionsSpotifyWarning =>
      'Spotify requiere tus propias credenciales API. Obténgalas gratis de developer.spotify.com';

  @override
  String get extensionsTitle => 'Extensiones';

  @override
  String get extensionsInstalled => 'Extensiones instaladas';

  @override
  String get extensionsNone => 'No hay extensiones instaladas';

  @override
  String get extensionsNoneSubtitle =>
      'Instalar extensiones desde la pestaña Tienda';

  @override
  String get extensionsEnabled => 'Habilitado';

  @override
  String get extensionsDisabled => 'Deshabilitado';

  @override
  String extensionsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String extensionsAuthor(String author) {
    return 'por $author';
  }

  @override
  String get extensionsUninstall => 'Desinstalar';

  @override
  String get extensionsSetAsSearch => 'Establecer como proveedor de búsqueda';

  @override
  String get storeTitle => 'Tienda de extensiones';

  @override
  String get storeSearch => 'Buscar extensiones...';

  @override
  String get storeInstall => 'Instalar';

  @override
  String get storeInstalled => 'Instalada';

  @override
  String get storeUpdate => 'Actualizar';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutContributors => 'Colaboradores';

  @override
  String get aboutMobileDeveloper => 'Desarrollador de versiones móviles';

  @override
  String get aboutOriginalCreator => 'Creador original de SpotiFLAC';

  @override
  String get aboutLogoArtist =>
      '¡El talentoso artista que creó nuestro hermoso logo!';

  @override
  String get aboutSpecialThanks => 'Agradecimientos especiales';

  @override
  String get aboutLinks => 'Enlaces';

  @override
  String get aboutMobileSource => 'Código fuente móvil';

  @override
  String get aboutPCSource => 'Código fuente de PC';

  @override
  String get aboutReportIssue => 'Reportar un problema';

  @override
  String get aboutReportIssueSubtitle =>
      'Reporta cualquier problema que encuentres';

  @override
  String get aboutFeatureRequest => 'Sugerir una función';

  @override
  String get aboutFeatureRequestSubtitle =>
      'Sugerir nuevas funciones para la aplicación';

  @override
  String get aboutSupport => 'Soporte';

  @override
  String get aboutBuyMeCoffee => 'Invítame a un café';

  @override
  String get aboutBuyMeCoffeeSubtitle => 'Apoyar el desarrollo en Ko-fi';

  @override
  String get aboutApp => 'Aplicación';

  @override
  String get aboutVersion => 'Versión';

  @override
  String get aboutBinimumDesc =>
      'El creador de la API QQDL & Hi-Fi. ¡Sin esta API, las descargas de Tidal no existiría!';

  @override
  String get aboutSachinsenalDesc =>
      'El creador original del proyecto Hi-Fi. ¡La base de la integración de Tidal!';

  @override
  String get aboutDoubleDouble => 'DoubleDouble';

  @override
  String get aboutDoubleDoubleDesc =>
      'API increible para descargas de Amazon Music. ¡Gracias por hacerla gratis!';

  @override
  String get aboutDabMusic => 'Música DAB';

  @override
  String get aboutDabMusicDesc =>
      'La mejor API de streaming de Qobuz. ¡Las descargas de Hi-Res no serían posibles sin esto!';

  @override
  String get aboutAppDescription =>
      'Descarga pistas de Spotify con calidad sin pérdida de Tidal, Qobuz y Amazon Music.';

  @override
  String get albumTitle => 'Álbum';

  @override
  String albumTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistas',
      one: '1 pista',
    );
    return '$_temp0';
  }

  @override
  String get albumDownloadAll => 'Descargar Todo';

  @override
  String get albumDownloadRemaining => 'Descargas Restantes';

  @override
  String get playlistTitle => 'Lista de reproducción';

  @override
  String get artistTitle => 'Artista';

  @override
  String get artistAlbums => 'Álbumes';

  @override
  String get artistSingles => 'Pistas y EPs';

  @override
  String get artistCompilations => 'Compilaciones';

  @override
  String artistReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lanzamientos',
      one: '1 lanzamiento',
    );
    return '$_temp0';
  }

  @override
  String get artistPopular => 'Populares';

  @override
  String artistMonthlyListeners(String count) {
    return '$count oyentes mensuales';
  }

  @override
  String get trackMetadataTitle => 'Información de pista';

  @override
  String get trackMetadataArtist => 'Artista';

  @override
  String get trackMetadataAlbum => 'Álbum';

  @override
  String get trackMetadataDuration => 'Duración';

  @override
  String get trackMetadataQuality => 'Calidad';

  @override
  String get trackMetadataPath => 'Ruta del archivo';

  @override
  String get trackMetadataDownloadedAt => 'Descargado';

  @override
  String get trackMetadataService => 'Servicio';

  @override
  String get trackMetadataPlay => 'Reproducir';

  @override
  String get trackMetadataShare => 'Compartir';

  @override
  String get trackMetadataDelete => 'Eliminar';

  @override
  String get trackMetadataRedownload => 'Volver a descargar';

  @override
  String get trackMetadataOpenFolder => 'Abrir carpeta';

  @override
  String get setupTitle => 'Bienvenido a SpotiFLAC';

  @override
  String get setupSubtitle => 'Comencemos';

  @override
  String get setupStoragePermission => 'Permiso de almacenamiento';

  @override
  String get setupStoragePermissionSubtitle =>
      'Necesario para guardar los archivos descargados';

  @override
  String get setupStoragePermissionGranted => 'Permiso aprobado';

  @override
  String get setupStoragePermissionDenied => 'Permiso denegado';

  @override
  String get setupGrantPermission => 'Conceder permiso';

  @override
  String get setupDownloadLocation => 'Ubicación de descarga';

  @override
  String get setupChooseFolder => 'Seleccionar Carpeta';

  @override
  String get setupContinue => 'Continuar';

  @override
  String get setupSkip => 'Omitir por ahora';

  @override
  String get setupStorageAccessRequired => 'Acceso al almacenamiento requerido';

  @override
  String get setupStorageAccessMessage =>
      'SpotiFLAC necesita permiso de \"Todos los archivos de acceso\" para guardar los archivos de música en la carpeta elegida.';

  @override
  String get setupStorageAccessMessageAndroid11 =>
      'Android 11+ requiere permiso \"Todos los archivos de acceso\" para guardar los archivos en la carpeta de descargas elegida.';

  @override
  String get setupOpenSettings => 'Abrir ajustes';

  @override
  String get setupPermissionDeniedMessage =>
      'Permiso denegado. Por favor, conceda todos los permisos para continuar.';

  @override
  String setupPermissionRequired(String permissionType) {
    return 'Permiso de $permissionType requerido';
  }

  @override
  String setupPermissionRequiredMessage(String permissionType) {
    return 'Se requiere un permiso $permissionType para la mejor experiencia. Puedes cambiar esto más tarde en ajustes.';
  }

  @override
  String get setupSelectDownloadFolder => 'Seleccionar carpeta de descarga';

  @override
  String get setupUseDefaultFolder => '¿Usar carpeta por defecto?';

  @override
  String get setupNoFolderSelected =>
      'No se ha seleccionado ninguna carpeta. ¿Desea utilizar la carpeta por defecto?';

  @override
  String get setupUseDefault => 'Usar por defecto';

  @override
  String get setupDownloadLocationTitle => 'Ubicación de descarga';

  @override
  String get setupDownloadLocationIosMessage =>
      'En iOS, las descargas se guardan en la carpeta de documentos de la aplicación. Puede acceder a ellas desde la aplicación Archivos.';

  @override
  String get setupAppDocumentsFolder => 'Carpeta de documentos de App';

  @override
  String get setupAppDocumentsFolderSubtitle =>
      'Recomendado - accesible desde la aplicación Archivos';

  @override
  String get setupChooseFromFiles => 'Elegir de archivos';

  @override
  String get setupChooseFromFilesSubtitle =>
      'Seleccione iCloud u otra ubicación';

  @override
  String get setupIosEmptyFolderWarning =>
      'Limitación de iOS: No se pueden seleccionar carpetas vacías. Elige una carpeta con al menos un archivo.';

  @override
  String get setupDownloadInFlac => 'Descargar pistas de Spotify en FLAC';

  @override
  String get setupStepStorage => 'Almacenamiento';

  @override
  String get setupStepNotification => 'Notificación';

  @override
  String get setupStepFolder => 'Carpeta';

  @override
  String get setupStepSpotify => 'Spotify';

  @override
  String get setupStepPermission => 'Permiso';

  @override
  String get setupStorageGranted => '¡Permiso de almacenamiento concedido!';

  @override
  String get setupStorageRequired => 'Permiso de almacenamiento requerido';

  @override
  String get setupStorageDescription =>
      'SpotiFLAC necesita permiso de almacenamiento para guardar sus archivos de música descargados.';

  @override
  String get setupNotificationGranted =>
      '¡Acceso a las notificaciones permitido!';

  @override
  String get setupNotificationEnable => 'Activar notificaciones';

  @override
  String get setupNotificationDescription =>
      'Recibe notificaciones cuando las descargas completen o requieran atención.';

  @override
  String get setupFolderSelected => '¡Carpeta de descarga seleccionada!';

  @override
  String get setupFolderChoose => 'Cambiar carpeta de descargas';

  @override
  String get setupFolderDescription =>
      'Seleccione una carpeta donde se guardará la música descargada.';

  @override
  String get setupChangeFolder => 'Cambiar carpeta';

  @override
  String get setupSelectFolder => 'Seleccionar Carpeta';

  @override
  String get setupSpotifyApiOptional => 'API de Spotify (opcional)';

  @override
  String get setupSpotifyApiDescription =>
      'Añade tus credenciales de la API de Spotify para mejores resultados de búsqueda y acceso al contenido exclusivo de Spotify.';

  @override
  String get setupUseSpotifyApi => 'Usar API de Spotify';

  @override
  String get setupEnterCredentialsBelow =>
      'Ingresa tus credenciales a continuación';

  @override
  String get setupUsingDeezer => 'Usando Deezer (no se necesita cuenta)';

  @override
  String get setupEnterClientId => 'Introduzca el ID de cliente de Spotify';

  @override
  String get setupEnterClientSecret => 'Ingresa el Client Secret de Spotify';

  @override
  String get setupGetFreeCredentials =>
      'Obtén tus credenciales gratuitas de la API desde el Spotify Developer Dashboard.';

  @override
  String get setupEnableNotifications => 'Activar notificaciones';

  @override
  String get setupProceedToNextStep =>
      'Ahora puedes continuar con el siguiente paso.';

  @override
  String get setupNotificationProgressDescription =>
      'Recibirás notificaciones de progreso de descargas.';

  @override
  String get setupNotificationBackgroundDescription =>
      'Recibe notificaciones sobre el progreso de la descarga y la finalización. Esto te ayuda a rastrear las descargas cuando la aplicación está en segundo plano.';

  @override
  String get setupSkipForNow => 'Omitir por ahora';

  @override
  String get setupBack => 'Atrás';

  @override
  String get setupNext => 'Siguiente';

  @override
  String get setupGetStarted => 'Empezar';

  @override
  String get setupSkipAndStart => 'Saltar y empezar';

  @override
  String get setupAllowAccessToManageFiles =>
      'Por favor, activa \"Permitir el acceso para gestionar todos los archivos\" en la siguiente pantalla.';

  @override
  String get setupGetCredentialsFromSpotify =>
      'Obtener credenciales de developer.spotify.com';

  @override
  String get dialogCancel => 'Cancelar';

  @override
  String get dialogOk => 'Aceptar';

  @override
  String get dialogSave => 'Guardar';

  @override
  String get dialogDelete => 'Eliminar';

  @override
  String get dialogRetry => 'Volver a intentar';

  @override
  String get dialogClose => 'Cerrar';

  @override
  String get dialogYes => 'Sí';

  @override
  String get dialogNo => 'No';

  @override
  String get dialogClear => 'Borrar';

  @override
  String get dialogConfirm => 'Confirmar';

  @override
  String get dialogDone => 'Hecho';

  @override
  String get dialogImport => 'Importar';

  @override
  String get dialogDiscard => 'Descartar';

  @override
  String get dialogRemove => 'Eliminar';

  @override
  String get dialogUninstall => 'Desinstalar';

  @override
  String get dialogDiscardChanges => '¿Descartar cambios?';

  @override
  String get dialogUnsavedChanges =>
      'Tienes cambios sin guardar. ¿Quieres descartarlos?';

  @override
  String get dialogDownloadFailed => 'Descarga fallida';

  @override
  String get dialogTrackLabel => 'Pista:';

  @override
  String get dialogArtistLabel => 'Artista:';

  @override
  String get dialogErrorLabel => 'Error:';

  @override
  String get dialogClearAll => 'Eliminar todo';

  @override
  String get dialogClearAllDownloads =>
      '¿Estás seguro de que quieres borrar todas las descargas?';

  @override
  String get dialogRemoveFromDevice => '¿Eliminar del dispositivo?';

  @override
  String get dialogRemoveExtension => 'Eliminar extensión';

  @override
  String get dialogRemoveExtensionMessage =>
      '¿Estás seguro de que quieres eliminar esta extensión? Esto no se puede deshacer.';

  @override
  String get dialogUninstallExtension => '¿Desinstalar extensión?';

  @override
  String dialogUninstallExtensionMessage(String extensionName) {
    return '¿Estás seguro de que quieres eliminar $extensionName?';
  }

  @override
  String get dialogClearHistoryTitle => 'Borrar historial';

  @override
  String get dialogClearHistoryMessage =>
      '¿Estás seguro de que quieres borrar todo el historial de descargas? Esta acción no se puede deshacer.';

  @override
  String get dialogDeleteSelectedTitle => 'Borrar Seleccionados';

  @override
  String dialogDeleteSelectedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pistas',
      one: 'pista',
    );
    return '¿Eliminar $count $_temp0 del historial?\n\nEsto también eliminará los archivos del almacenamiento.';
  }

  @override
  String get dialogImportPlaylistTitle => 'Importar lista de reproducción';

  @override
  String dialogImportPlaylistMessage(int count) {
    return 'Se han encontrado pistas $count en CSV. ¿Añadirlas para descargar la cola?';
  }

  @override
  String snackbarAddedToQueue(String trackName) {
    return 'Añadido \"$trackName\" a la cola';
  }

  @override
  String snackbarAddedTracksToQueue(int count) {
    return 'Añadidas pistas $count a la cola';
  }

  @override
  String snackbarAlreadyDownloaded(String trackName) {
    return '\"$trackName\" ya descargado';
  }

  @override
  String get snackbarHistoryCleared => 'Historial borrado';

  @override
  String get snackbarCredentialsSaved => 'Credenciales guardadas';

  @override
  String get snackbarCredentialsCleared => 'Credenciales borradas';

  @override
  String snackbarDeletedTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pistas',
      one: 'pista',
    );
    return 'Eliminado $count $_temp0';
  }

  @override
  String snackbarCannotOpenFile(String error) {
    return 'No se puede abrir el archivo: $error';
  }

  @override
  String get snackbarFillAllFields => 'Por favor, completa todos los campos';

  @override
  String get snackbarViewQueue => 'Ver cola';

  @override
  String snackbarFailedToLoad(String error) {
    return 'Error al cargar: $error';
  }

  @override
  String snackbarUrlCopied(String platform) {
    return 'URL $platform copiada al portapapeles';
  }

  @override
  String get snackbarFileNotFound => 'Archivo no encontrado';

  @override
  String get snackbarSelectExtFile =>
      'Por favor, seleccione un archivo .spotiflac-ext';

  @override
  String get snackbarProviderPrioritySaved => 'Prioridad de proveedor guardada';

  @override
  String get snackbarMetadataProviderSaved =>
      'Prioridad de proveedor de metadatos guardada';

  @override
  String snackbarExtensionInstalled(String extensionName) {
    return '$extensionName instalado.';
  }

  @override
  String snackbarExtensionUpdated(String extensionName) {
    return '$extensionName actualizada.';
  }

  @override
  String get snackbarFailedToInstall => 'Fallo al instalar la extensión';

  @override
  String get snackbarFailedToUpdate => 'Error al actualizar la extensión';

  @override
  String get errorRateLimited => 'Límite Excedido';

  @override
  String get errorRateLimitedMessage =>
      'Demasiadas solicitudes. Por favor, espere un momento antes de buscar de nuevo.';

  @override
  String errorFailedToLoad(String item) {
    return 'Error al cargar $item';
  }

  @override
  String get errorNoTracksFound => 'No se encontraron pistas';

  @override
  String errorMissingExtensionSource(String item) {
    return 'No se puede cargar $item: falta una fuente de extensión';
  }

  @override
  String get statusQueued => 'En cola';

  @override
  String get statusDownloading => 'Descargando';

  @override
  String get statusFinalizing => 'Finalizando';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusFailed => 'Error';

  @override
  String get statusSkipped => 'Omitido';

  @override
  String get statusPaused => 'Pausado';

  @override
  String get actionPause => 'Pausar';

  @override
  String get actionResume => 'Reanudar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionStop => 'Detener';

  @override
  String get actionSelect => 'Seleccionar';

  @override
  String get actionSelectAll => 'Seleccionar Todo';

  @override
  String get actionDeselect => 'Deseleccionar';

  @override
  String get actionPaste => 'Pegar';

  @override
  String get actionImportCsv => 'Importar CSV';

  @override
  String get actionRemoveCredentials => 'Eliminar credenciales';

  @override
  String get actionSaveCredentials => 'Guardar credenciales';

  @override
  String selectionSelected(int count) {
    return '$count seleccionado';
  }

  @override
  String get selectionAllSelected => 'Todas las pistas seleccionadas';

  @override
  String get selectionTapToSelect => 'Toca las pistas para seleccionar';

  @override
  String selectionDeleteTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pistas',
      one: 'pista',
    );
    return '¡Eliminar $count $_temp0';
  }

  @override
  String get selectionSelectToDelete => 'Seleccionar pistas a eliminar';

  @override
  String progressFetchingMetadata(int current, int total) {
    return 'Obteniendo metadatos... $current/$total';
  }

  @override
  String get progressReadingCsv => 'Leyendo CSV...';

  @override
  String get searchSongs => 'Canciones';

  @override
  String get searchArtists => 'Artistas';

  @override
  String get searchAlbums => 'Álbumes';

  @override
  String get searchPlaylists => 'Listas de reproducción';

  @override
  String get tooltipPlay => 'Reproducir';

  @override
  String get tooltipCancel => 'Cancelar';

  @override
  String get tooltipStop => 'Detener';

  @override
  String get tooltipRetry => 'Volver a intentar';

  @override
  String get tooltipRemove => 'Eliminar';

  @override
  String get tooltipClear => 'Borrar';

  @override
  String get tooltipPaste => 'Pegar';

  @override
  String get filenameFormat => 'Formato del nombre del archivo';

  @override
  String filenameFormatPreview(String preview) {
    return 'Vista previa: $preview';
  }

  @override
  String get filenameAvailablePlaceholders => 'Marcadores disponibles:';

  @override
  String filenameHint(Object artist, Object title) {
    return '$artist - $title';
  }

  @override
  String get folderOrganization => 'Organización de carpetas';

  @override
  String get folderOrganizationNone => 'Ninguna organización';

  @override
  String get folderOrganizationByArtist => 'Por Artista';

  @override
  String get folderOrganizationByAlbum => 'Por Álbum';

  @override
  String get folderOrganizationByArtistAlbum => 'Artista/Álbum';

  @override
  String get folderOrganizationDescription =>
      'Organizar los archivos descargados en carpetas';

  @override
  String get folderOrganizationNoneSubtitle =>
      'Todos los archivos de la carpeta de descargas';

  @override
  String get folderOrganizationByArtistSubtitle =>
      'Carpeta separada para cada artista';

  @override
  String get folderOrganizationByAlbumSubtitle =>
      'Carpeta separada para cada artista';

  @override
  String get folderOrganizationByArtistAlbumSubtitle =>
      'Carpetas organizadas por artista y álbum';

  @override
  String get updateAvailable => 'Actualización Disponible';

  @override
  String updateNewVersion(String version) {
    return 'Versión $version está disponible';
  }

  @override
  String get updateDownload => 'Descargar';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateChangelog => 'Historial de cambios';

  @override
  String get updateStartingDownload => 'Iniciando descarga...';

  @override
  String get updateDownloadFailed => 'Descarga fallida';

  @override
  String get updateFailedMessage => 'Error al descargar la actualización';

  @override
  String get updateNewVersionReady => 'Una nueva versión está lista';

  @override
  String get updateCurrent => 'Actual';

  @override
  String get updateNew => 'Nuevo';

  @override
  String get updateDownloading => 'Descargando...';

  @override
  String get updateWhatsNew => 'Novedades';

  @override
  String get updateDownloadInstall => 'Descargar & Instalar';

  @override
  String get updateDontRemind => 'No recordar';

  @override
  String get providerPriority => 'Prioridad del proveedor';

  @override
  String get providerPrioritySubtitle =>
      'Arrastre para reordenar los proveedores de descarga';

  @override
  String get providerPriorityTitle => 'Prioridad del proveedor';

  @override
  String get providerPriorityDescription =>
      'Arrastra para reordenar los proveedores de descarga. La aplicación intentará usar los proveedores de arriba hacia abajo al descargar las pistas.';

  @override
  String get providerPriorityInfo =>
      'Si una pista no está disponible en el primer proveedor, la aplicación intentará automáticamente el siguiente.';

  @override
  String get providerBuiltIn => 'Integrado';

  @override
  String get providerExtension => 'Extensión';

  @override
  String get metadataProviderPriority => 'Prioridad del proveedor de metadatos';

  @override
  String get metadataProviderPrioritySubtitle =>
      'Orden usado al recuperar metadatos de la pista';

  @override
  String get metadataProviderPriorityTitle => 'Prioridad de los metadatos';

  @override
  String get metadataProviderPriorityDescription =>
      'Arrastra para reordenar los proveedores de metadatos. La aplicación probará los proveedores de arriba hacia abajo al buscar pistas y obtener los metadatos.';

  @override
  String get metadataProviderPriorityInfo =>
      'Deezer no tiene límites de tasa y se recomienda como principal. Spotify puede valorar el límite después de muchas solicitudes.';

  @override
  String get metadataNoRateLimits => 'Sin límites de tasa';

  @override
  String get metadataMayRateLimit => 'Sin límites de tasa';

  @override
  String get logTitle => 'Registros';

  @override
  String get logCopy => 'Copiar Registros';

  @override
  String get logClear => 'Limpiar registros';

  @override
  String get logShare => 'Compartir Registros';

  @override
  String get logEmpty => 'No hay registros aún';

  @override
  String get logCopied => 'Registros copiados al portapapeles';

  @override
  String get logSearchHint => 'Buscar registros...';

  @override
  String get logFilterLevel => 'Nivel';

  @override
  String get logFilterSection => 'Filtrar';

  @override
  String get logShareLogs => 'Compartir registros';

  @override
  String get logClearLogs => 'Borrar registros';

  @override
  String get logClearLogsTitle => 'Limpiar registros';

  @override
  String get logClearLogsMessage =>
      '¿Estás seguro que deseas limpiar todos los registros?';

  @override
  String get logIspBlocking => 'BLOQUEO POR EL ISP DETECTADO';

  @override
  String get logRateLimited => 'TASA LIMITADA';

  @override
  String get logNetworkError => 'ERROR DE RED';

  @override
  String get logTrackNotFound => 'PISTA NO ENCONTRADA';

  @override
  String get logFilterBySeverity => 'Filtrar los registros por gravedad';

  @override
  String get logNoLogsYet => 'No hay registros aún';

  @override
  String get logNoLogsYetSubtitle =>
      'Los registros aparecerán aquí mientras usas la aplicación';

  @override
  String get logIssueSummary => 'Resumen de Incidencias';

  @override
  String get logIspBlockingDescription =>
      'Tu ISP puede estar bloqueando el acceso a los servicios de descarga';

  @override
  String get logIspBlockingSuggestion =>
      'Intente usar una VPN o cambie el DNS a 1.1.1.1 o 8.8.8.8';

  @override
  String get logRateLimitedDescription => 'Demasiadas solicitudes al servicio';

  @override
  String get logRateLimitedSuggestion =>
      'Espere unos minutos antes de volver a intentarlo';

  @override
  String get logNetworkErrorDescription => 'Problemas de conexión detectados';

  @override
  String get logNetworkErrorSuggestion => 'Comprueba tu conexión a internet';

  @override
  String get logTrackNotFoundDescription =>
      'No se pudieron encontrar algunas pistas en los servicios de descarga';

  @override
  String get logTrackNotFoundSuggestion =>
      'La pista puede no estar disponible en calidad sin pérdida';

  @override
  String logTotalErrors(int count) {
    return 'Total de errores: $count';
  }

  @override
  String logAffected(String domains) {
    return 'Afectado: $domains';
  }

  @override
  String logEntriesFiltered(int count) {
    return 'Entradas ($count filtradas)';
  }

  @override
  String logEntries(int count) {
    return 'Entradas ($count)';
  }

  @override
  String get credentialsTitle => 'Credenciales de Spotify';

  @override
  String get credentialsDescription =>
      'Introduzca su ID de cliente y secreto para utilizar su propia cuota de aplicación de Spotify.';

  @override
  String get credentialsClientId => 'ID del cliente';

  @override
  String get credentialsClientIdHint => 'Pegar ID de cliente';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => 'Pegar Client Secret';

  @override
  String get channelStable => 'Estable';

  @override
  String get channelPreview => 'Vista previa';

  @override
  String get sectionSearchSource => 'Buscar Fuente';

  @override
  String get sectionDownload => 'Descargar';

  @override
  String get sectionPerformance => 'Alto rendimiento';

  @override
  String get sectionApp => 'Aplicación';

  @override
  String get sectionData => 'Datos';

  @override
  String get sectionDebug => 'Depuración';

  @override
  String get sectionService => 'Servicio';

  @override
  String get sectionAudioQuality => 'Calidad de Sonido';

  @override
  String get sectionFileSettings => 'Ajustes del archivo';

  @override
  String get sectionColor => 'Colores';

  @override
  String get sectionTheme => 'Tema';

  @override
  String get sectionLayout => 'Diseño';

  @override
  String get sectionLanguage => 'Idioma';

  @override
  String get appearanceLanguage => 'Idioma de la aplicación';

  @override
  String get appearanceLanguageSubtitle => 'Elija su idioma preferido';

  @override
  String get settingsAppearanceSubtitle => 'Tema, colores, pantalla';

  @override
  String get settingsDownloadSubtitle =>
      'Servicio, calidad, formato del nombre del archivo';

  @override
  String get settingsOptionsSubtitle =>
      'Alternativa, letras, carátula, actualizaciones';

  @override
  String get settingsExtensionsSubtitle =>
      'Administrar proveedores de descarga';

  @override
  String get settingsLogsSubtitle =>
      'Ver registros de aplicaciones para depuración';

  @override
  String get loadingSharedLink => 'Cargando enlace compartido...';

  @override
  String get pressBackAgainToExit => 'Presione de nuevo para salir';

  @override
  String get tracksHeader => 'Pistas';

  @override
  String downloadAllCount(int count) {
    return 'Descargar Todo ($count)';
  }

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pistas',
      one: '1 pista',
    );
    return '$_temp0';
  }

  @override
  String get trackCopyFilePath => 'Copiar ruta de archivo';

  @override
  String get trackRemoveFromDevice => 'Eliminar del dispositivo';

  @override
  String get trackLoadLyrics => 'Cargar letras';

  @override
  String get trackMetadata => 'Metadatos';

  @override
  String get trackFileInfo => 'Información de archivo';

  @override
  String get trackLyrics => 'Letras';

  @override
  String get trackFileNotFound => 'Archivo no encontrado';

  @override
  String get trackOpenInDeezer => 'Abrir en Deezer';

  @override
  String get trackOpenInSpotify => 'Abrir en Spotify';

  @override
  String get trackTrackName => 'Nombre de pista';

  @override
  String get trackArtist => 'Artista';

  @override
  String get trackAlbumArtist => 'Artista del álbum';

  @override
  String get trackAlbum => 'Álbum';

  @override
  String get trackTrackNumber => 'Número de pista';

  @override
  String get trackDiscNumber => 'Número de disco';

  @override
  String get trackDuration => 'Duración';

  @override
  String get trackAudioQuality => 'Calidad del sonido';

  @override
  String get trackReleaseDate => 'Fecha de lanzamiento';

  @override
  String get trackDownloaded => 'Descargado';

  @override
  String get trackCopyLyrics => 'Copiar letras';

  @override
  String get trackLyricsNotAvailable => 'Letras no disponibles para este tema';

  @override
  String get trackLyricsTimeout =>
      'Tiempo de espera agotado. Inténtalo de nuevo más tarde.';

  @override
  String get trackLyricsLoadFailed => 'Error al cargar la letra';

  @override
  String get trackCopiedToClipboard => 'Copiado al portapapeles';

  @override
  String get trackDeleteConfirmTitle => '¿Eliminar del dispositivo?';

  @override
  String get trackDeleteConfirmMessage =>
      'Esto eliminará permanentemente el archivo descargado y lo eliminará de tu historial.';

  @override
  String trackCannotOpen(String message) {
    return 'No se puede abrir: $message';
  }

  @override
  String get dateToday => 'Hoy';

  @override
  String get dateYesterday => 'Ayer';

  @override
  String dateDaysAgo(int count) {
    return 'Hace $count días';
  }

  @override
  String dateWeeksAgo(int count) {
    return '$count semanas antes';
  }

  @override
  String dateMonthsAgo(int count) {
    return '$count meses atrás';
  }

  @override
  String get concurrentSequential => 'Secuencial';

  @override
  String get concurrentParallel2 => '2 simultáneamente';

  @override
  String get concurrentParallel3 => '3 simultáneamente';

  @override
  String get tapToSeeError => 'Pulse para ver los detalles del error';

  @override
  String get storeFilterAll => 'Todo';

  @override
  String get storeFilterMetadata => 'Metadatos';

  @override
  String get storeFilterDownload => 'Descargar';

  @override
  String get storeFilterUtility => 'Utilidad';

  @override
  String get storeFilterLyrics => 'Letras';

  @override
  String get storeFilterIntegration => 'Integración';

  @override
  String get storeClearFilters => 'Limpiar filtros';

  @override
  String get storeNoResults => 'No se encontraron extensiones';

  @override
  String get extensionProviderPriority => 'Prioridad del proveedor';

  @override
  String get extensionInstallButton => 'Instalar extensión';

  @override
  String get extensionDefaultProvider => 'Por defecto (Deezer/Spotify)';

  @override
  String get extensionDefaultProviderSubtitle => 'Usar búsqueda integrada';

  @override
  String get extensionAuthor => 'Autor/a';

  @override
  String get extensionId => 'ID';

  @override
  String get extensionError => 'Error';

  @override
  String get extensionCapabilities => 'Recursos';

  @override
  String get extensionMetadataProvider => 'Proveedor de metadatos';

  @override
  String get extensionDownloadProvider => 'Proveedor de descargas';

  @override
  String get extensionLyricsProvider => 'Proveedor de letras';

  @override
  String get extensionUrlHandler => 'Gestor de URL';

  @override
  String get extensionQualityOptions => 'Opciones de calidad';

  @override
  String get extensionPostProcessingHooks => 'Hooks post-procesamiento';

  @override
  String get extensionPermissions => 'Permisos';

  @override
  String get extensionSettings => 'Ajustes';

  @override
  String get extensionRemoveButton => 'Eliminar extensión';

  @override
  String get extensionUpdated => 'Actualizado';

  @override
  String get extensionMinAppVersion => 'Versión Mínima de la aplicación';

  @override
  String get extensionCustomTrackMatching =>
      'Coincidencia de pista personalizada';

  @override
  String get extensionPostProcessing => 'Post-Procesamiento';

  @override
  String extensionHooksAvailable(int count) {
    return '$count hook(s) disponibles';
  }

  @override
  String extensionPatternsCount(int count) {
    return 'Patrón(es) $count';
  }

  @override
  String extensionStrategy(String strategy) {
    return 'Estrategia: $strategy';
  }

  @override
  String get extensionsProviderPrioritySection => 'Prioridad del proveedor';

  @override
  String get extensionsInstalledSection => 'Extensiones instaladas';

  @override
  String get extensionsNoExtensions => 'No hay extensiones instaladas';

  @override
  String get extensionsNoExtensionsSubtitle =>
      'Instalar archivos .spotiflac-ext para añadir nuevos proveedores';

  @override
  String get extensionsInstallButton => 'Instalar extensión';

  @override
  String get extensionsInfoTip =>
      'Las extensiones pueden añadir nuevos metadatos y proveedores de descargas. Sólo instalar extensiones desde fuentes confiables.';

  @override
  String get extensionsInstalledSuccess => 'Extensión instalada correctamente';

  @override
  String get extensionsDownloadPriority => 'Prioridad de descarga';

  @override
  String get extensionsDownloadPrioritySubtitle =>
      'Establecer orden de servicio de descarga';

  @override
  String get extensionsNoDownloadProvider =>
      'No hay extensiones con proveedor de descargas';

  @override
  String get extensionsMetadataPriority => 'Prioridad de los metadatos';

  @override
  String get extensionsMetadataPrioritySubtitle =>
      'Establecer orden de búsqueda y metadatos';

  @override
  String get extensionsNoMetadataProvider =>
      'No hay extensiones con el proveedor de metadatos';

  @override
  String get extensionsSearchProvider => 'Proveedor de búsqueda';

  @override
  String get extensionsNoCustomSearch =>
      'No hay extensiones con búsqueda personalizada';

  @override
  String get extensionsSearchProviderDescription =>
      'Elegir qué servicio usar para buscar pistas';

  @override
  String get extensionsCustomSearch => 'Búsqueda personalizada';

  @override
  String get extensionsErrorLoading => 'Error al cargar la extensión';

  @override
  String get qualityFlacLossless => 'FLAC Lossless';

  @override
  String get qualityFlacLosslessSubtitle => '16-bit / 44.1kHz';

  @override
  String get qualityHiResFlac => 'Hi-Res FLAC';

  @override
  String get qualityHiResFlacSubtitle => '24 bits/hasta 96kHz';

  @override
  String get qualityHiResFlacMax => 'Hi-Res FLAC Max';

  @override
  String get qualityHiResFlacMaxSubtitle => '24 bits / hasta 192kHz';

  @override
  String get qualityNote =>
      'La calidad real depende de la disponibilidad de la pista del servicio';

  @override
  String get downloadAskBeforeDownload => 'Preguntar antes de descargar';

  @override
  String get downloadDirectory => 'Carpeta de descarga';

  @override
  String get downloadSeparateSinglesFolder => 'Carpeta separada para pistas';

  @override
  String get downloadAlbumFolderStructure => 'Estructura de carpeta del álbum';

  @override
  String get downloadSaveFormat => 'Guardar Formato';

  @override
  String get downloadSelectService => 'Seleccionar Servicio';

  @override
  String get downloadSelectQuality => 'Seleccionar Calidad';

  @override
  String get downloadFrom => 'Descargar Desde';

  @override
  String get downloadDefaultQualityLabel => 'Calidad por Defecto';

  @override
  String get downloadBestAvailable => 'La mejor disponible';

  @override
  String get folderNone => 'Ninguna';

  @override
  String get folderNoneSubtitle =>
      'Guardar todos los archivos directamente para descargar la carpeta';

  @override
  String get folderArtist => 'Artista';

  @override
  String get folderArtistSubtitle => 'Nombre del Artista/nombre de archivo';

  @override
  String get folderAlbum => 'Álbum';

  @override
  String get folderAlbumSubtitle => 'Nombre del álbum/nombre de archivo';

  @override
  String get folderArtistAlbum => 'Artista/Álbum';

  @override
  String get folderArtistAlbumSubtitle =>
      'Nombre del Artista/Nombre del Álbum/Nombre del Archivo';

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
  String get appearanceAmoledDark => 'AMOLED Oscuro';

  @override
  String get appearanceAmoledDarkSubtitle => 'Fondo negro puro';

  @override
  String get appearanceChooseAccentColor => 'Elegir color principal';

  @override
  String get appearanceChooseTheme => 'Modo de tema';

  @override
  String get queueTitle => 'Descargas en proceso';

  @override
  String get queueClearAll => 'Eliminar todo';

  @override
  String get queueClearAllMessage =>
      '¿Estás seguro de que quieres borrar todas las descargas?';

  @override
  String get queueEmpty => 'No hay descargas en cola';

  @override
  String get queueEmptySubtitle => 'Añadir pistas desde la pantalla de inicio';

  @override
  String get queueClearCompleted => 'Limpiar tareas finalizadas';

  @override
  String get queueDownloadFailed => 'Descarga fallida';

  @override
  String get queueTrackLabel => 'Pista:';

  @override
  String get queueArtistLabel => 'Artista:';

  @override
  String get queueErrorLabel => 'Error:';

  @override
  String get queueUnknownError => 'Error desconocido';

  @override
  String get albumFolderArtistAlbum => 'Artista / Álbum';

  @override
  String get albumFolderArtistAlbumSubtitle =>
      'Álbumes/Nombre del Artista/Nombre del Álbum/';

  @override
  String get albumFolderArtistYearAlbum => 'Artista / [Año] Álbum';

  @override
  String get albumFolderArtistYearAlbumSubtitle =>
      'Álbumes/Nombre del Artista /[2005] Nombre del Álbum/';

  @override
  String get albumFolderAlbumOnly => 'Sólo álbum';

  @override
  String get albumFolderAlbumOnlySubtitle => 'Álbumes/Nombre del Álbum/';

  @override
  String get albumFolderYearAlbum => 'Álbum [Año]';

  @override
  String get albumFolderYearAlbumSubtitle => 'Álbumes/[2005] Nombre del Álbum/';

  @override
  String get downloadedAlbumDeleteSelected => 'Borrar Seleccionados';

  @override
  String downloadedAlbumDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pistas',
      one: 'pista',
    );
    return '¿Eliminar $count $_temp0 del historial?\n\nEsto también eliminará los archivos del almacenamiento.';
  }

  @override
  String get downloadedAlbumTracksHeader => 'Pistas';

  @override
  String downloadedAlbumDownloadedCount(int count) {
    return '$count descargado';
  }

  @override
  String downloadedAlbumSelectedCount(int count) {
    return '$count seleccionado';
  }

  @override
  String get downloadedAlbumAllSelected => 'Todas las pistas seleccionadas';

  @override
  String get downloadedAlbumTapToSelect => 'Toca las pistas para seleccionar';

  @override
  String downloadedAlbumDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pistas',
      one: 'pista',
    );
    return '¡Eliminar $count $_temp0';
  }

  @override
  String get downloadedAlbumSelectToDelete => 'Seleccionar pistas a eliminar';

  @override
  String get utilityFunctions => 'Funciones de utilidad';

  @override
  String get recentTypeArtist => 'Artista';

  @override
  String get recentTypeAlbum => 'Álbum';

  @override
  String get recentTypeSong => 'Canción';

  @override
  String get recentTypePlaylist => 'Lista de reproducción';

  @override
  String recentPlaylistInfo(String name) {
    return 'Lista de reproducción: $name';
  }

  @override
  String errorGeneric(String message) {
    return 'Error: $message';
  }
}
