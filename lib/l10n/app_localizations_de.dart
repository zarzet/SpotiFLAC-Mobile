// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'SpotiFLAC';

  @override
  String get appDescription =>
      'Laden Sie Spotify-Titel in verlustfreier Qualität von Tidal, Qobuz und Amazon Music herunter.';

  @override
  String get navHome => 'Startseite';

  @override
  String get navHistory => 'Verlauf';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navStore => 'Store';

  @override
  String get homeTitle => 'Startseite';

  @override
  String get homeSearchHint => 'Spotify-URL einfügen oder suchen...';

  @override
  String homeSearchHintExtension(String extensionName) {
    return 'Mit $extensionName suchen...';
  }

  @override
  String get homeSubtitle => 'Spotify-Link einfügen oder nach Namen suchen';

  @override
  String get homeSupports =>
      'Unterstützt: Titel, Album, Playlist, Künstler-URLs';

  @override
  String get homeRecent => 'Zuletzt';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String historyDownloading(int count) {
    return 'Wird heruntergeladen ($count)';
  }

  @override
  String get historyDownloaded => 'Heruntergeladen';

  @override
  String get historyFilterAll => 'Alle';

  @override
  String get historyFilterAlbums => 'Alben';

  @override
  String get historyFilterSingles => 'Singles';

  @override
  String historyTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
    );
    return '$_temp0';
  }

  @override
  String historyAlbumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Alben',
      one: '1 Album',
    );
    return '$_temp0';
  }

  @override
  String get historyNoDownloads => 'Kein Download-Verlauf';

  @override
  String get historyNoDownloadsSubtitle =>
      'Heruntergeladene Titel werden hier angezeigt';

  @override
  String get historyNoAlbums => 'Keine Album-Downloads';

  @override
  String get historyNoAlbumsSubtitle =>
      'Laden Sie mehrere Titel eines Albums herunter, um sie hier zu sehen';

  @override
  String get historyNoSingles => 'Keine Einzel-Downloads';

  @override
  String get historyNoSinglesSubtitle =>
      'Einzelne Titel-Downloads werden hier angezeigt';

  @override
  String get historySearchHint => 'Search history...';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsDownload => 'Herunterladen';

  @override
  String get settingsAppearance => 'Erscheinungsbild';

  @override
  String get settingsOptions => 'Optionen';

  @override
  String get settingsExtensions => 'Erweiterungen';

  @override
  String get settingsAbout => 'Über';

  @override
  String get downloadTitle => 'Herunterladen';

  @override
  String get downloadLocation => 'Download-Speicherort';

  @override
  String get downloadLocationSubtitle =>
      'Wählen Sie den Speicherort für Dateien';

  @override
  String get downloadLocationDefault => 'Standard-Speicherort';

  @override
  String get downloadDefaultService => 'Standard-Dienst';

  @override
  String get downloadDefaultServiceSubtitle => 'Dienst für Downloads';

  @override
  String get downloadDefaultQuality => 'Standard-Qualität';

  @override
  String get downloadAskQuality => 'Qualität vor Download abfragen';

  @override
  String get downloadAskQualitySubtitle =>
      'Qualitätsauswahl für jeden Download anzeigen';

  @override
  String get downloadFilenameFormat => 'Dateinamenformat';

  @override
  String get downloadFolderOrganization => 'Ordnerstruktur';

  @override
  String get downloadSeparateSingles => 'Singles trennen';

  @override
  String get downloadSeparateSinglesSubtitle =>
      'Einzelne Titel in separatem Ordner speichern';

  @override
  String get qualityBest => 'Beste Qualität';

  @override
  String get qualityFlac => 'FLAC';

  @override
  String get quality320 => '320 kbps';

  @override
  String get quality128 => '128 kbps';

  @override
  String get appearanceTitle => 'Erscheinungsbild';

  @override
  String get appearanceTheme => 'Design';

  @override
  String get appearanceThemeSystem => 'System';

  @override
  String get appearanceThemeLight => 'Hell';

  @override
  String get appearanceThemeDark => 'Dunkel';

  @override
  String get appearanceDynamicColor => 'Dynamische Farben';

  @override
  String get appearanceDynamicColorSubtitle =>
      'Farben von Ihrem Hintergrundbild verwenden';

  @override
  String get appearanceAccentColor => 'Akzentfarbe';

  @override
  String get appearanceHistoryView => 'Verlaufsansicht';

  @override
  String get appearanceHistoryViewList => 'Liste';

  @override
  String get appearanceHistoryViewGrid => 'Raster';

  @override
  String get optionsTitle => 'Optionen';

  @override
  String get optionsSearchSource => 'Suchquelle';

  @override
  String get optionsPrimaryProvider => 'Primärer Anbieter';

  @override
  String get optionsPrimaryProviderSubtitle =>
      'Dienst für die Suche nach Titelnamen.';

  @override
  String optionsUsingExtension(String extensionName) {
    return 'Erweiterung verwenden: $extensionName';
  }

  @override
  String get optionsSwitchBack =>
      'Tippen Sie auf Deezer oder Spotify, um von der Erweiterung zurückzuwechseln';

  @override
  String get optionsAutoFallback => 'Automatischer Fallback';

  @override
  String get optionsAutoFallbackSubtitle =>
      'Andere Dienste versuchen, wenn Download fehlschlägt';

  @override
  String get optionsUseExtensionProviders => 'Erweiterungs-Anbieter verwenden';

  @override
  String get optionsUseExtensionProvidersOn =>
      'Erweiterungen werden zuerst versucht';

  @override
  String get optionsUseExtensionProvidersOff =>
      'Nur integrierte Anbieter verwenden';

  @override
  String get optionsEmbedLyrics => 'Liedtexte einbetten';

  @override
  String get optionsEmbedLyricsSubtitle =>
      'Synchronisierte Liedtexte in FLAC-Dateien einbetten';

  @override
  String get optionsMaxQualityCover => 'Maximale Cover-Qualität';

  @override
  String get optionsMaxQualityCoverSubtitle =>
      'Cover in höchster Auflösung herunterladen';

  @override
  String get optionsConcurrentDownloads => 'Parallele Downloads';

  @override
  String get optionsConcurrentSequential => 'Sequentiell (1 gleichzeitig)';

  @override
  String optionsConcurrentParallel(int count) {
    return '$count parallele Downloads';
  }

  @override
  String get optionsConcurrentWarning =>
      'Parallele Downloads können Ratenlimitierung auslösen';

  @override
  String get optionsExtensionStore => 'Erweiterungs-Store';

  @override
  String get optionsExtensionStoreSubtitle =>
      'Store-Tab in Navigation anzeigen';

  @override
  String get optionsCheckUpdates => 'Nach Updates suchen';

  @override
  String get optionsCheckUpdatesSubtitle =>
      'Benachrichtigen, wenn neue Version verfügbar';

  @override
  String get optionsUpdateChannel => 'Update-Kanal';

  @override
  String get optionsUpdateChannelStable => 'Nur stabile Versionen';

  @override
  String get optionsUpdateChannelPreview => 'Vorschau-Versionen erhalten';

  @override
  String get optionsUpdateChannelWarning =>
      'Vorschau kann Fehler oder unvollständige Funktionen enthalten';

  @override
  String get optionsClearHistory => 'Download-Verlauf löschen';

  @override
  String get optionsClearHistorySubtitle =>
      'Alle heruntergeladenen Titel aus dem Verlauf entfernen';

  @override
  String get optionsDetailedLogging => 'Detaillierte Protokollierung';

  @override
  String get optionsDetailedLoggingOn =>
      'Detaillierte Protokolle werden aufgezeichnet';

  @override
  String get optionsDetailedLoggingOff => 'Für Fehlerberichte aktivieren';

  @override
  String get optionsSpotifyCredentials => 'Spotify-Anmeldedaten';

  @override
  String optionsSpotifyCredentialsConfigured(String clientId) {
    return 'Client-ID: $clientId...';
  }

  @override
  String get optionsSpotifyCredentialsRequired =>
      'Erforderlich - zum Konfigurieren tippen';

  @override
  String get optionsSpotifyWarning =>
      'Spotify erfordert eigene API-Anmeldedaten. Kostenlos erhältlich auf developer.spotify.com';

  @override
  String get extensionsTitle => 'Erweiterungen';

  @override
  String get extensionsInstalled => 'Installierte Erweiterungen';

  @override
  String get extensionsNone => 'Keine Erweiterungen installiert';

  @override
  String get extensionsNoneSubtitle =>
      'Erweiterungen aus dem Store-Tab installieren';

  @override
  String get extensionsEnabled => 'Aktiviert';

  @override
  String get extensionsDisabled => 'Deaktiviert';

  @override
  String extensionsVersion(String version) {
    return 'Version $version';
  }

  @override
  String extensionsAuthor(String author) {
    return 'von $author';
  }

  @override
  String get extensionsUninstall => 'Deinstallieren';

  @override
  String get extensionsSetAsSearch => 'Als Suchanbieter festlegen';

  @override
  String get storeTitle => 'Erweiterungs-Store';

  @override
  String get storeSearch => 'Erweiterungen suchen...';

  @override
  String get storeInstall => 'Installieren';

  @override
  String get storeInstalled => 'Installiert';

  @override
  String get storeUpdate => 'Aktualisieren';

  @override
  String get aboutTitle => 'Über';

  @override
  String get aboutContributors => 'Mitwirkende';

  @override
  String get aboutMobileDeveloper => 'Mobile-Version Entwickler';

  @override
  String get aboutOriginalCreator => 'Schöpfer des ursprünglichen SpotiFLAC';

  @override
  String get aboutLogoArtist =>
      'Der talentierte Künstler, der unser wunderschönes App-Logo entworfen hat!';

  @override
  String get aboutTranslators => 'Translators';

  @override
  String get aboutSpecialThanks => 'Besonderer Dank';

  @override
  String get aboutLinks => 'Links';

  @override
  String get aboutMobileSource => 'Mobiler Quellcode';

  @override
  String get aboutPCSource => 'PC Quellcode';

  @override
  String get aboutReportIssue => 'Problem melden';

  @override
  String get aboutReportIssueSubtitle =>
      'Melde jedes Problem, die dir auftreten';

  @override
  String get aboutFeatureRequest => 'Feature vorschlagen';

  @override
  String get aboutFeatureRequestSubtitle =>
      'Schlage neue Funktionen für die App vor';

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
  String get aboutBuyMeCoffee => 'Spendiere mir einen Kaffee';

  @override
  String get aboutBuyMeCoffeeSubtitle =>
      'Unterstütze die Entwicklung auf Ko-fi';

  @override
  String get aboutApp => 'App';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBinimumDesc =>
      'Der Schöpfer der QQDL & HiFi API. Ohne diese API gäbe es keine Tidal-Downloads!';

  @override
  String get aboutSachinsenalDesc =>
      'Der ursprüngliche Entwickler des HiFi-Projekts. Die Grundlage der Tidal-Integration!';

  @override
  String get aboutDoubleDouble => 'DoubleDouble';

  @override
  String get aboutDoubleDoubleDesc =>
      'Wundervolle API für Amazon Music Downloads.\nVielen Dank, dass Sie sie kostenlos zur Verfügung stellen!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'Die beste Qobuz-Streaming-API. Hi-Res-Downloads wären ohne diese nicht möglich!';

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
