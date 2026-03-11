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
  String get navHome => 'Startseite';

  @override
  String get navLibrary => 'Bibliothek';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navStore => 'Store';

  @override
  String get homeTitle => 'Startseite';

  @override
  String get homeSubtitle => 'Spotify-Link einfügen oder nach Namen suchen';

  @override
  String get homeSupports =>
      'Unterstützt: Titel, Album, Playlist, Künstler-URLs';

  @override
  String get homeRecent => 'Zuletzt';

  @override
  String get historyFilterAll => 'Alle';

  @override
  String get historyFilterAlbums => 'Alben';

  @override
  String get historyFilterSingles => 'Singles';

  @override
  String get historySearchHint => 'Suchverlauf...';

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
  String get downloadAskQualitySubtitle =>
      'Qualitätsauswahl für jeden Download anzeigen';

  @override
  String get downloadFilenameFormat => 'Dateinamenformat';

  @override
  String get downloadFolderOrganization => 'Ordnerstruktur';

  @override
  String get appearanceTitle => 'Erscheinungsbild';

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
  String get appearanceHistoryView => 'Verlaufsansicht';

  @override
  String get appearanceHistoryViewList => 'Liste';

  @override
  String get appearanceHistoryViewGrid => 'Raster';

  @override
  String get optionsTitle => 'Optionen';

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
      'Tippe auf Deezer oder Spotify, um von der Erweiterung zurückzuwechseln';

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
      'Synchronisierte Lyrics in FLAC-Dateien einbetten';

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
  String get optionsSpotifyDeprecationWarning =>
      'Spotify-Suche wird am 3. März 2026 aufgrund von Änderungen der Spotify-API entfernt. Bitte wechsel vorher zu Deezer.';

  @override
  String get extensionsTitle => 'Erweiterungen';

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
  String get aboutTranslators => 'Übersetzer';

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
  String get aboutTelegramChannel => 'Telegram Kanal';

  @override
  String get aboutTelegramChannelSubtitle => 'Ankündigungen und Updates';

  @override
  String get aboutTelegramChat => 'Telegram Community';

  @override
  String get aboutTelegramChatSubtitle => 'Mit anderen Nutzern chatten';

  @override
  String get aboutSocial => 'Sozial';

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
  String get aboutSjdonadoDesc =>
      'Ersteller von I Don\'t Have Spotify (IDHS). Der Fallback-Link-Resolver, der den Tag rettete!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'Die beste Qobuz-Streaming-API. Hi-Res-Downloads wären ohne diese nicht möglich!';

  @override
  String get aboutSpotiSaver => 'SpotiSaver';

  @override
  String get aboutSpotiSaverDesc =>
      'Tidal Hi-Res FLAC Streaming-Endpunkte. Ein Schlüsselstück des verlustfreien Puzzle!';

  @override
  String get aboutAppDescription =>
      'Lade Spotify-Titel in verlustfreier Qualität von Tidal, Qobuz und Amazon Music herunter.';

  @override
  String get artistAlbums => 'Alben';

  @override
  String get artistSingles => 'Singles & EPs';

  @override
  String get artistCompilations => 'Zusammenstellungen';

  @override
  String get artistPopular => 'Beliebt';

  @override
  String artistMonthlyListeners(String count) {
    return '$count monatliche Hörer';
  }

  @override
  String get trackMetadataService => 'Anbieter';

  @override
  String get trackMetadataPlay => 'Abspielen';

  @override
  String get trackMetadataShare => 'Teilen';

  @override
  String get trackMetadataDelete => 'Löschen';

  @override
  String get setupGrantPermission => 'Berechtigung erlauben';

  @override
  String get setupSkip => 'Vorerst überspringen';

  @override
  String get setupStorageAccessRequired => 'Speicherzugriff erforderlich';

  @override
  String get setupStorageAccessMessageAndroid11 =>
      'Android 11+ benötigt die Berechtigung „Auf alle Dateien“, um Dateien im ausgewählten Download-Ordner zu speichern.';

  @override
  String get setupOpenSettings => 'Einstellungen öffnen';

  @override
  String get setupPermissionDeniedMessage =>
      'Berechtigung verweigert. Bitte erteile alle Berechtigungen um fortzufahren.';

  @override
  String setupPermissionRequired(String permissionType) {
    return '$permissionType Zugriff verweigert';
  }

  @override
  String setupPermissionRequiredMessage(String permissionType) {
    return '$permissionType Berechtigung ist erforderlich für\ndie beste Benutzererfahrung. Für kannst dies später in den Einstellungen ändern.';
  }

  @override
  String get setupUseDefaultFolder => 'Als Standardordner verwenden?';

  @override
  String get setupNoFolderSelected =>
      'Kein Ordner ausgewählt. Soll der Standard-Musikordner verwendet werden?';

  @override
  String get setupUseDefault => 'Standart benutzen';

  @override
  String get setupDownloadLocationTitle => 'Speicherort';

  @override
  String get setupDownloadLocationIosMessage =>
      'Auf iOS werden Downloads im Dokumentenverzeichnis der App gespeichert. Du kannst sie über die Datei-App aufrufen.';

  @override
  String get setupAppDocumentsFolder => 'App-Dokumentenordner';

  @override
  String get setupAppDocumentsFolderSubtitle =>
      'Empfohlen - zugänglich über die Datei-App';

  @override
  String get setupChooseFromFiles => 'Aus Dateien auswählen';

  @override
  String get setupChooseFromFilesSubtitle =>
      'Wähle iCloud oder einen anderen Speicherort';

  @override
  String get setupIosEmptyFolderWarning =>
      'iOS-Einschränkung: Leere Ordner können nicht ausgewählt werden. Wähle einen Ordner mit mindestens einer Datei.';

  @override
  String get setupIcloudNotSupported =>
      'iCloud Drive wird nicht unterstützt. Bitte verwende den \"Dokumente\" Ordner.';

  @override
  String get setupDownloadInFlac => 'Spotify Titel in FLAC herunterladen';

  @override
  String get setupStorageGranted => 'Speicherberechtigung erlaubt!';

  @override
  String get setupStorageRequired => 'Speicherzugriff erforderlich';

  @override
  String get setupStorageDescription =>
      'SpotiFLAC benötigt Speicherrechte, um die heruntergeladenen Musikdateien zu speichern.';

  @override
  String get setupNotificationGranted =>
      'Benachrichtigungs-Berechtigung erteilt';

  @override
  String get setupNotificationEnable => 'Benachrichtigungen aktivieren';

  @override
  String get setupFolderChoose => 'Speicherort auwählen';

  @override
  String get setupFolderDescription =>
      'Wähle einen Ordner, in dem die heruntergeladene Musik gespeichert wird.';

  @override
  String get setupSelectFolder => 'Ordner wählen';

  @override
  String get setupEnableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get setupNotificationBackgroundDescription =>
      'Erhalte Benachrichtigungen über den Fortschritt und die Fertigstellung deiner Downloads, selbst wenn die App im Hintergrund läuft.';

  @override
  String get setupSkipForNow => 'Vorerst überspringen';

  @override
  String get setupNext => 'Weiter';

  @override
  String get setupGetStarted => 'Los geht‘s';

  @override
  String get setupAllowAccessToManageFiles =>
      'Bitte aktiviere \"Zugriff auf alle Dateien erlauben\" auf dem nächsten Bildschirm.';

  @override
  String get dialogCancel => 'Abbrechen';

  @override
  String get dialogSave => 'Speichern';

  @override
  String get dialogDelete => 'Löschen';

  @override
  String get dialogRetry => 'Wiederholen';

  @override
  String get dialogClear => 'Leeren';

  @override
  String get dialogDone => 'Fertig';

  @override
  String get dialogImport => 'Importieren';

  @override
  String get dialogDiscard => 'Verwerfen';

  @override
  String get dialogRemove => 'Entfernen';

  @override
  String get dialogUninstall => 'Deinstallieren';

  @override
  String get dialogDiscardChanges => 'Änderungen verwerfen?';

  @override
  String get dialogUnsavedChanges =>
      'Hast du noch nicht alle Änderungen gespeichert. Möchtest du die Änderungen verwerfen?';

  @override
  String get dialogClearAll => 'Alles löschen';

  @override
  String get dialogRemoveExtension => 'Erweiterung entfernen';

  @override
  String get dialogRemoveExtensionMessage =>
      'Bist Du sicher, dass Du diese Erweiterung entfernen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get dialogUninstallExtension => 'Erweiterung deinstallieren?';

  @override
  String dialogUninstallExtensionMessage(String extensionName) {
    return 'Bist du dir sicher, dass du $extensionName entfernen möchtest?';
  }

  @override
  String get dialogClearHistoryTitle => 'Verlauf löschen';

  @override
  String get dialogClearHistoryMessage =>
      'Bist du dir sicher, dass du den gesamten Download verlauf löschen möchten? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get dialogDeleteSelectedTitle => 'Ausgewählte löschen';

  @override
  String dialogDeleteSelectedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tracks',
      one: 'Track',
    );
    return 'Lösche $count $_temp0 aus dem Verlauf?\n\nDies löscht auch die Dateien aus dem Speicher.';
  }

  @override
  String get dialogImportPlaylistTitle => 'Playlist importieren';

  @override
  String dialogImportPlaylistMessage(int count) {
    return '$count Titel gefunden hinzufügen?';
  }

  @override
  String csvImportTracks(int count) {
    return '$count Titel aus CSV';
  }

  @override
  String snackbarAddedToQueue(String trackName) {
    return '\"$trackName\" hinzugefügt';
  }

  @override
  String snackbarAddedTracksToQueue(int count) {
    return '$count Titel hinzugefügt';
  }

  @override
  String snackbarAlreadyDownloaded(String trackName) {
    return '\"$trackName\" bereits heruntergeladen';
  }

  @override
  String snackbarAlreadyInLibrary(String trackName) {
    return '\"$trackName\" existiert bereits in Ihrer Bibliothek';
  }

  @override
  String get snackbarHistoryCleared => 'Verlauf gelöscht';

  @override
  String get snackbarCredentialsSaved => 'Anmeldedaten gespeichert';

  @override
  String get snackbarCredentialsCleared => 'Anmeldedaten gelöscht';

  @override
  String snackbarDeletedTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Titel',
      one: 'Titel',
    );
    return '$count $_temp0';
  }

  @override
  String snackbarCannotOpenFile(String error) {
    return 'Datei kann nicht geöffnet werden: $error';
  }

  @override
  String get snackbarFillAllFields => 'Bitte fülle alle Felder aus';

  @override
  String get snackbarViewQueue => 'Warteschlange anzeigen';

  @override
  String snackbarUrlCopied(String platform) {
    return '$platform URL in die Zwischenablage kopiert';
  }

  @override
  String get snackbarFileNotFound => 'Datei nicht gefunden';

  @override
  String get snackbarSelectExtFile => 'Bitte wähle eine .spotiflac-ext Datei';

  @override
  String get snackbarProviderPrioritySaved => 'Anbieterpriorität gespeichert';

  @override
  String get snackbarMetadataProviderSaved =>
      'Priorität des Metadaten-Anbieters gespeichert';

  @override
  String snackbarExtensionInstalled(String extensionName) {
    return '$extensionName installiert.';
  }

  @override
  String snackbarExtensionUpdated(String extensionName) {
    return '$extensionName aktualisiert.';
  }

  @override
  String get snackbarFailedToInstall =>
      'Erweiterung konnte nicht installiert werden';

  @override
  String get snackbarFailedToUpdate =>
      'Erweiterung konnte nicht aktualisiert werden';

  @override
  String get errorRateLimited => 'Anfragelimit überschritten';

  @override
  String get errorRateLimitedMessage =>
      'Zu viele Anfragen. Bitte warte einen Moment, bevor du es erneut suchst.';

  @override
  String get errorNoTracksFound => 'Keine Titel gefunden';

  @override
  String get errorUrlNotRecognized => 'Link not recognized';

  @override
  String get errorUrlNotRecognizedMessage =>
      'This link is not supported. Make sure the URL is correct and a compatible extension is installed.';

  @override
  String get errorUrlFetchFailed =>
      'Failed to load content from this link. Please try again.';

  @override
  String errorMissingExtensionSource(String item) {
    return 'Kann $item nicht lade wegen fehlender Erweiterungsquelle';
  }

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Fortfahren';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionSelectAll => 'Alles Auswählen';

  @override
  String get actionDeselect => 'Alle abwählen';

  @override
  String get actionRemoveCredentials => 'Anmeldedaten entfernen';

  @override
  String get actionSaveCredentials => 'Anmeldedaten speichern';

  @override
  String selectionSelected(int count) {
    return '$count ausgewählt';
  }

  @override
  String get selectionAllSelected => 'Alle Titel sind ausgewählt';

  @override
  String get selectionSelectToDelete => 'Titel zum Löschen auswählen';

  @override
  String progressFetchingMetadata(int current, int total) {
    return 'Lade Metadaten... $current/$total';
  }

  @override
  String get progressReadingCsv => 'CSV wird gelesen...';

  @override
  String get searchSongs => 'Titel';

  @override
  String get searchArtists => 'Künstler';

  @override
  String get searchAlbums => 'Albums';

  @override
  String get searchPlaylists => 'Playlisten';

  @override
  String get tooltipPlay => 'Abspielen';

  @override
  String get filenameFormat => 'Dateinamenformat';

  @override
  String get filenameShowAdvancedTags => 'Erweiterte Tags anzeigen';

  @override
  String get filenameShowAdvancedTagsDescription =>
      'Formatierte Tags für Track-Padding und Datumsmuster aktivieren';

  @override
  String get folderOrganizationNone => 'Keine Organisation';

  @override
  String get folderOrganizationByPlaylist => 'By Playlist';

  @override
  String get folderOrganizationByPlaylistSubtitle =>
      'Separate folder for each playlist';

  @override
  String get folderOrganizationByArtist => 'Nach Künstler';

  @override
  String get folderOrganizationByAlbum => 'Nach Album';

  @override
  String get folderOrganizationByArtistAlbum => 'Künstler/Album';

  @override
  String get folderOrganizationDescription =>
      'Heruntergeladene Dateien in Ordner organisieren';

  @override
  String get folderOrganizationNoneSubtitle =>
      'Alle Dateien im Download-Verzeichnis';

  @override
  String get folderOrganizationByArtistSubtitle =>
      'Trenne Ordner nach Künstler';

  @override
  String get folderOrganizationByAlbumSubtitle => 'Trenne Ordner nach Album';

  @override
  String get folderOrganizationByArtistAlbumSubtitle =>
      'Verschachtelte Ordner für Künstler und Album';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get updateLater => 'Später';

  @override
  String get updateStartingDownload => 'Download wird gestartet...';

  @override
  String get updateDownloadFailed => 'Download fehlgeschlagen';

  @override
  String get updateFailedMessage =>
      'Das Update konnte nicht heruntergeladen werden';

  @override
  String get updateNewVersionReady => 'Eine neue Version ist verfügbar';

  @override
  String get updateCurrent => 'Aktuell';

  @override
  String get updateNew => 'Neu';

  @override
  String get updateDownloading => 'Wird heruntergeladen...';

  @override
  String get updateWhatsNew => 'Was ist neu';

  @override
  String get updateDownloadInstall => 'Herunterladen & Installieren';

  @override
  String get updateDontRemind => 'Nicht erinnern';

  @override
  String get providerPriorityTitle => 'Anbieterpriorität';

  @override
  String get providerPriorityDescription =>
      'Ziehen, um Download-Anbieter neu zu ordnen. Die App versucht Anbieter von oben nach unten, wenn Titel heruntergeladen werden.';

  @override
  String get providerPriorityInfo =>
      'Wenn kein Titel bei dem ersten Anbieter nicht verfügbar ist, wird die App automatisch den nächsten versuchen.';

  @override
  String get providerBuiltIn => 'Integriert';

  @override
  String get providerExtension => 'Erweiterung';

  @override
  String get metadataProviderPriorityTitle => 'Metadaten Priorität';

  @override
  String get metadataProviderPriorityDescription =>
      'Ziehe, um Metadatenanbieter neu zu ordnen. Die App versucht Anbieter von oben nach unten, wenn sie nach Tracks suchen und Metadaten abrufen.';

  @override
  String get metadataProviderPriorityInfo =>
      'Deezer hat keine Limits und wird als primäre empfohlen. Spotify kann nach vielen Anfragen begrenzen.';

  @override
  String get metadataNoRateLimits => 'Keine Limitierungen';

  @override
  String get metadataMayRateLimit => 'Hat vielleicht Limitierungen';

  @override
  String get logTitle => 'Protokolle';

  @override
  String get logCopied => 'Protokolle in Zwischenablage kopiert';

  @override
  String get logSearchHint => 'Protokolle durchsuchen...';

  @override
  String get logFilterLevel => 'Stufe';

  @override
  String get logFilterSection => 'Filter';

  @override
  String get logShareLogs => 'Protokolle teilen';

  @override
  String get logClearLogs => 'Protokolle löschen';

  @override
  String get logClearLogsTitle => 'Protokolle leeren';

  @override
  String get logClearLogsMessage =>
      'Bist du dir sicher, dass Sie alle Protokolle löschen möchtest?';

  @override
  String get logFilterBySeverity => 'Protokolle nach Schweregrad filtern';

  @override
  String get logNoLogsYet => 'Keine Protokolle bisher';

  @override
  String get logNoLogsYetSubtitle =>
      'Protokolle werden hier angezeigt, während du die App benutzt';

  @override
  String logEntriesFiltered(int count) {
    return 'Einträge ($count gefiltert)';
  }

  @override
  String logEntries(int count) {
    return '$count Einträge';
  }

  @override
  String get credentialsTitle => 'Spotify-Anmeldedaten';

  @override
  String get credentialsDescription =>
      'Gebe deine Client-ID und Secret ein, um dein eigenes Spotify Anwendungs Limit zu haben.';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Client ID einfügen';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => 'Client Secret einfügen';

  @override
  String get channelStable => 'Stabil';

  @override
  String get channelPreview => 'Vorschau';

  @override
  String get sectionSearchSource => 'Suchquelle';

  @override
  String get sectionDownload => 'Herunterladen';

  @override
  String get sectionPerformance => 'Performance';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionData => 'Daten';

  @override
  String get sectionDebug => 'Debug';

  @override
  String get sectionService => 'Anbieter';

  @override
  String get sectionAudioQuality => 'Audioqualität';

  @override
  String get sectionFileSettings => 'Datei-Einstellungen';

  @override
  String get sectionLyrics => 'Lyrics';

  @override
  String get lyricsMode => 'Lyrics-Modus';

  @override
  String get lyricsModeDescription =>
      'Wähle wie Songtexte mit deinen Downloads gespeichert werden';

  @override
  String get lyricsModeEmbed => 'In Datei einbetten';

  @override
  String get lyricsModeEmbedSubtitle => 'Lyrics in FLAC Metadaten gespeichert';

  @override
  String get lyricsModeExternal => 'Externe .lrc Datei';

  @override
  String get lyricsModeExternalSubtitle =>
      'Separate .lrc Datei für Player wie Samsung Music';

  @override
  String get lyricsModeBoth => 'Beides';

  @override
  String get lyricsModeBothSubtitle =>
      'Lyrics einbetten und als .lrc speichern';

  @override
  String get sectionColor => 'Farbe';

  @override
  String get sectionTheme => 'Design';

  @override
  String get sectionLayout => 'Layout';

  @override
  String get sectionLanguage => 'Sprache';

  @override
  String get appearanceLanguage => 'App Sprache';

  @override
  String get settingsAppearanceSubtitle => 'Design, Farben, Anzeige';

  @override
  String get settingsDownloadSubtitle => 'Dienst, Qualität, Dateinamen-Format';

  @override
  String get settingsOptionsSubtitle => 'Fallback, Lyrics, Covers, Updates';

  @override
  String get settingsExtensionsSubtitle => 'Download-Anbieter verwalten';

  @override
  String get settingsLogsSubtitle => 'App-Logs zum Debuggen anzeigen';

  @override
  String get loadingSharedLink => 'Link wird geladen...';

  @override
  String get pressBackAgainToExit =>
      'Drücke wieder \"zurück\" um die App zu beenden';

  @override
  String downloadAllCount(int count) {
    return 'Alle $count Titel herunterladen';
  }

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
    );
    return '$_temp0';
  }

  @override
  String get trackCopyFilePath => 'Dateipfad kopieren';

  @override
  String get trackRemoveFromDevice => 'Vom Gerät entfernen';

  @override
  String get trackLoadLyrics => 'Lade Lyrics';

  @override
  String get trackMetadata => 'Metadaten';

  @override
  String get trackFileInfo => 'Datei-Info';

  @override
  String get trackLyrics => 'Lyrics';

  @override
  String get trackFileNotFound => 'Datei nicht gefunden';

  @override
  String get trackOpenInDeezer => 'In Deezer öffnen';

  @override
  String get trackOpenInSpotify => 'In Spotify öffnen';

  @override
  String get trackTrackName => 'Name des Titels';

  @override
  String get trackArtist => 'Künstler';

  @override
  String get trackAlbumArtist => 'Album Künstler';

  @override
  String get trackAlbum => 'Album';

  @override
  String get trackTrackNumber => 'Titelnummer';

  @override
  String get trackDiscNumber => 'CD-Nummer';

  @override
  String get trackDuration => 'Länge';

  @override
  String get trackAudioQuality => 'Audioqualität';

  @override
  String get trackReleaseDate => 'Erscheinungsdatum';

  @override
  String get trackGenre => 'Genre';

  @override
  String get trackLabel => 'Label';

  @override
  String get trackCopyright => 'Urheberrecht';

  @override
  String get trackDownloaded => 'Heruntergeladen';

  @override
  String get trackCopyLyrics => 'Lyrics kopieren';

  @override
  String get trackLyricsNotAvailable =>
      'Lyrics sind für diesen Titel nicht verfügbar';

  @override
  String get trackLyricsTimeout =>
      'Anfrage Timeout. Versuche es später erneut.';

  @override
  String get trackLyricsLoadFailed => 'Fehler beim Laden der Lyrics';

  @override
  String get trackEmbedLyrics => 'Lyrics einbetten';

  @override
  String get trackLyricsEmbedded => 'Lyrics erfolgreich eingebettet';

  @override
  String get trackInstrumental => 'Instrumentalspur';

  @override
  String get trackCopiedToClipboard => 'In Zwischenablage kopiert';

  @override
  String get trackDeleteConfirmTitle => 'Vom Gerät entfernen?';

  @override
  String get trackDeleteConfirmMessage =>
      'Dies wird die heruntergeladene Datei dauerhaft löschen und sie aus deinem Verlauf entfernen.';

  @override
  String get dateToday => 'Heute';

  @override
  String get dateYesterday => 'Gestern';

  @override
  String dateDaysAgo(int count) {
    return 'Vor $count Tagen';
  }

  @override
  String dateWeeksAgo(int count) {
    return 'Vor $count Wochen';
  }

  @override
  String dateMonthsAgo(int count) {
    return 'Vor $count Monaten';
  }

  @override
  String get storeFilterAll => 'Alle';

  @override
  String get storeFilterMetadata => 'Metadaten';

  @override
  String get storeFilterDownload => 'Herunterladen';

  @override
  String get storeFilterUtility => 'Utility';

  @override
  String get storeFilterLyrics => 'Lyrics';

  @override
  String get storeFilterIntegration => 'Integration';

  @override
  String get storeClearFilters => 'Filter entfernen';

  @override
  String get extensionDefaultProvider => 'Standard (Deezer/Spotify)';

  @override
  String get extensionDefaultProviderSubtitle => 'Eingebaute Suche verwenden';

  @override
  String get extensionAuthor => 'Entwickler';

  @override
  String get extensionId => 'ID';

  @override
  String get extensionError => 'Fehler';

  @override
  String get extensionCapabilities => 'Eigenschaften';

  @override
  String get extensionMetadataProvider => 'Metadaten-Anbieter';

  @override
  String get extensionDownloadProvider => 'Download-Anbieter';

  @override
  String get extensionLyricsProvider => 'Lyrics-Anbieter';

  @override
  String get extensionUrlHandler => 'URL Handler';

  @override
  String get extensionQualityOptions => 'Qualitätsoptionen';

  @override
  String get extensionPostProcessingHooks => 'Post-Processing Hooks';

  @override
  String get extensionPermissions => 'Berechtigungen';

  @override
  String get extensionSettings => 'Einstellungen';

  @override
  String get extensionRemoveButton => 'Erweiterung entfernen';

  @override
  String get extensionUpdated => 'Aktualisiert';

  @override
  String get extensionMinAppVersion => 'Min App-Version';

  @override
  String get extensionCustomTrackMatching =>
      'Benutzerdefiniertes Track-Matching';

  @override
  String get extensionPostProcessing => 'Post-processing';

  @override
  String extensionHooksAvailable(int count) {
    return '$count Hook(s) verfügbar';
  }

  @override
  String extensionPatternsCount(int count) {
    return '$count Muster';
  }

  @override
  String extensionStrategy(String strategy) {
    return 'Strategie: $strategy';
  }

  @override
  String get extensionsProviderPrioritySection => 'Provider-Priorität';

  @override
  String get extensionsInstalledSection => 'Installierte Erweiterungen';

  @override
  String get extensionsNoExtensions => 'Keine Erweiterungen installiert';

  @override
  String get extensionsNoExtensionsSubtitle =>
      'Installiere .spotiflac-ext Dateien um neue Anbieter hinzuzufügen';

  @override
  String get extensionsInstallButton => 'Erweiterung installieren';

  @override
  String get extensionsInfoTip =>
      'Erweiterungen können neue Metadaten und Download-Anbieter hinzufügen. Installiere nur Erweiterungen von vertrauenswürdigen Quellen.';

  @override
  String get extensionsInstalledSuccess =>
      'Erweiterung erfolgreich installiert';

  @override
  String get extensionsDownloadPriority => 'Download-Priorität';

  @override
  String get extensionsDownloadPrioritySubtitle =>
      'Download-Service-Reihenfolge festlegen';

  @override
  String get extensionsNoDownloadProvider =>
      'Keine Erweiterungen mit Download-Provider';

  @override
  String get extensionsMetadataPriority => 'Metadaten Priorität';

  @override
  String get extensionsMetadataPrioritySubtitle =>
      'Reihenfolge der Such- und Metadaten quellen festlegen';

  @override
  String get extensionsNoMetadataProvider =>
      'Keine Erweiterungen mit Metadaten-Anbieter';

  @override
  String get extensionsSearchProvider => 'Such-Provider';

  @override
  String get extensionsNoCustomSearch =>
      'Keine Erweiterungen mit benutzerdefinierter Suche';

  @override
  String get extensionsSearchProviderDescription =>
      'Wähle den Dienst für die Suche von Titel';

  @override
  String get extensionsCustomSearch => 'Benutzerdefinierte Suche';

  @override
  String get extensionsErrorLoading => 'Fehler beim Laden der Erweiterung';

  @override
  String get qualityFlacLossless => 'FLAC Verlustfrei';

  @override
  String get qualityFlacLosslessSubtitle => '16-bit / 44.1kHz';

  @override
  String get qualityHiResFlac => 'Hi-Res FLAC';

  @override
  String get qualityHiResFlacSubtitle => '24-Bit / bis 96kHz';

  @override
  String get qualityHiResFlacMax => 'Hi-Res FLAC Max';

  @override
  String get qualityHiResFlacMaxSubtitle => '24-Bit / bis 192kHz';

  @override
  String get qualityNote =>
      'Die eigentliche Qualität hängt von der Verfügbarkeit des Dienstes ab';

  @override
  String get youtubeQualityNote =>
      'YouTube bietet nur verlustbehaftete Audioqualität. Deswegen ist es kein Teil des verlustfreien Fallbacks.';

  @override
  String get youtubeOpusBitrateTitle => 'YouTube Opus Bitrate';

  @override
  String get youtubeMp3BitrateTitle => 'YouTube MP3 Bitrate';

  @override
  String get downloadAskBeforeDownload => 'Qualität vor Download fragen';

  @override
  String get downloadDirectory => 'Downloadverzeichnis';

  @override
  String get downloadSeparateSinglesFolder => 'Singles Ordner trennen';

  @override
  String get downloadAlbumFolderStructure => 'Album Folder Structure';

  @override
  String get downloadUseAlbumArtistForFolders => 'Use Album Artist for folders';

  @override
  String get downloadUsePrimaryArtistOnly => 'Primary artist only for folders';

  @override
  String get downloadUsePrimaryArtistOnlyEnabled =>
      'Vorgestellte Künstler aus dem Ordnernamen entfernt (z.B. Justin Bieber, Quavo → Justin Bieber)';

  @override
  String get downloadUsePrimaryArtistOnlyDisabled =>
      'Full artist string used for folder name';

  @override
  String get downloadSelectQuality => 'Qualität wählen';

  @override
  String get downloadFrom => 'Herunterladen von';

  @override
  String get appearanceAmoledDark => 'AMOLED Schwarz';

  @override
  String get appearanceAmoledDarkSubtitle => 'AMOLED Hintergrund';

  @override
  String get queueClearAll => 'Alles löschen';

  @override
  String get queueClearAllMessage =>
      'Bist du dir sicher, dass du alle Downloads löschen möchten?';

  @override
  String get settingsAutoExportFailed => 'Auto-export failed downloads';

  @override
  String get settingsAutoExportFailedSubtitle =>
      'Fehlgeschlagene Downloads automatisch in eine TXT-Datei speichern';

  @override
  String get settingsDownloadNetwork => 'Download Netzwerk';

  @override
  String get settingsDownloadNetworkAny => 'WLAN + Mobile Daten';

  @override
  String get settingsDownloadNetworkWifiOnly => 'Nur WLAN';

  @override
  String get settingsDownloadNetworkSubtitle =>
      'Wähle aus, welches Netzwerk für Downloads verwendet werden soll. Wenn nur WLAN aktiviert wird, werden Downloads auf mobilen Daten angehalten.';

  @override
  String get albumFolderArtistAlbum => 'Künstler/Album';

  @override
  String get albumFolderArtistAlbumSubtitle => 'Albums/Artist Name/Album Name/';

  @override
  String get albumFolderArtistYearAlbum => 'Artist / [Year] Album';

  @override
  String get albumFolderArtistYearAlbumSubtitle =>
      'Albums/Künster Name/[2005] Album Name/';

  @override
  String get albumFolderAlbumOnly => 'Nur Alben';

  @override
  String get albumFolderAlbumOnlySubtitle => 'Alben/Album Name/';

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
  String get downloadedAlbumDeleteSelected => 'Ausgewählte löschen';

  @override
  String downloadedAlbumDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Titel',
      one: 'Titel',
    );
    return '$count $_temp0 aus diesem Album löschen?\n\nDadurch werden auch die Dateien aus dem Speicher gelöscht.';
  }

  @override
  String downloadedAlbumSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get downloadedAlbumAllSelected => 'Alle Titel sind ausgewählt';

  @override
  String get downloadedAlbumTapToSelect => 'Tippe auf Titel zum Auswählen';

  @override
  String downloadedAlbumDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Titel',
      one: 'Titel',
    );
    return 'Lösche $count $_temp0';
  }

  @override
  String get downloadedAlbumSelectToDelete => 'Select tracks to delete';

  @override
  String downloadedAlbumDiscHeader(int discNumber) {
    return 'Disc $discNumber';
  }

  @override
  String get recentTypeArtist => 'Künstler';

  @override
  String get recentTypeAlbum => 'Album';

  @override
  String get recentTypeSong => 'Titel';

  @override
  String get recentTypePlaylist => 'Playlist';

  @override
  String get recentEmpty => 'Noch keine aktuellen Einträge';

  @override
  String get recentShowAllDownloads => 'Alle Downloads anzeigen';

  @override
  String recentPlaylistInfo(String name) {
    return 'Playlist: $name';
  }

  @override
  String get discographyDownload => 'Diskographie herunterladen';

  @override
  String get discographyDownloadAll => 'Alle Herunterladen';

  @override
  String discographyDownloadAllSubtitle(int count, int albumCount) {
    return '$count Titel von $albumCount Releases';
  }

  @override
  String get discographyAlbumsOnly => 'Nur Alben';

  @override
  String discographyAlbumsOnlySubtitle(int count, int albumCount) {
    return '$count Titel von $albumCount Albums';
  }

  @override
  String get discographySinglesOnly => 'Nur Singles & EPs';

  @override
  String discographySinglesOnlySubtitle(int count, int albumCount) {
    return '$count Titel von $albumCount Singles';
  }

  @override
  String get discographySelectAlbums => 'Alben auswählen...';

  @override
  String get discographySelectAlbumsSubtitle =>
      'Choose specific albums or singles';

  @override
  String get discographyFetchingTracks => 'Lade Titel...';

  @override
  String discographyFetchingAlbum(int current, int total) {
    return 'Fetching $current of $total...';
  }

  @override
  String discographySelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get discographyDownloadSelected => 'Auswahl herunterladen';

  @override
  String discographyAddedToQueue(int count) {
    return 'Added $count tracks to queue';
  }

  @override
  String discographySkippedDownloaded(int added, int skipped) {
    return '$added hinzugefügt, $skipped bereits heruntergeladen';
  }

  @override
  String get discographyNoAlbums => 'Es sind keine Alben verfügbar';

  @override
  String get discographyFailedToFetch => 'Failed to fetch some albums';

  @override
  String get sectionStorageAccess => 'Speicherzugriff';

  @override
  String get allFilesAccess => 'Zugriff auf alle Dateien';

  @override
  String get allFilesAccessEnabledSubtitle => 'Can write to any folder';

  @override
  String get allFilesAccessDisabledSubtitle => 'Limited to media folders only';

  @override
  String get allFilesAccessDescription =>
      'Aktiviere die Option, wenn beim Speichern in benutzerdefinierten Ordnern Schreibfehler auftreten. Weil Android 13+ standardmäßig den Zugriff auf bestimmte Verzeichnisse einschränkt.';

  @override
  String get allFilesAccessDeniedMessage =>
      'Zugriff verweigert. Bitte aktiviere \"Zugriff auf alle Dateien\" manuell in den Systemeinstellungen.';

  @override
  String get allFilesAccessDisabledMessage =>
      'Zugriff auf alle Dateien ist deaktiviert. Die App verwendet nur begrenzten Zugriff auf den Speicher.';

  @override
  String get settingsLocalLibrary => 'Lokale Bibliothek';

  @override
  String get settingsLocalLibrarySubtitle => 'Scan music & detect duplicates';

  @override
  String get settingsCache => 'Speicher & Cache';

  @override
  String get settingsCacheSubtitle => 'View size and clear cached data';

  @override
  String get libraryTitle => 'Lokale Bibliothek';

  @override
  String get libraryScanSettings => 'Scan Einstellungen';

  @override
  String get libraryEnableLocalLibrary => 'Lokale Bibliothek aktivieren';

  @override
  String get libraryEnableLocalLibrarySubtitle =>
      'Scan and track your existing music';

  @override
  String get libraryFolder => 'Bibliotheksordner';

  @override
  String get libraryFolderHint => 'Tippe um Ordner auszuwählen';

  @override
  String get libraryShowDuplicateIndicator => 'Show Duplicate Indicator';

  @override
  String get libraryShowDuplicateIndicatorSubtitle =>
      'Bei der Suche nach vorhandenen Titeln anzeigen';

  @override
  String get libraryActions => 'Aktionen';

  @override
  String get libraryScan => 'Bibliothek scannen';

  @override
  String get libraryScanSubtitle => 'Suche nach Audiodateien';

  @override
  String get libraryScanSelectFolderFirst => 'Wähle zuerst einen Ordner';

  @override
  String get libraryCleanupMissingFiles => 'Fehlende Dateien bereinigen';

  @override
  String get libraryCleanupMissingFilesSubtitle =>
      'Verlaufseinträge für Dateien löschen, die nicht mehr existieren';

  @override
  String get libraryClear => 'Bibliothek löschen';

  @override
  String get libraryClearSubtitle => 'Alle gescannten Titel entfernen';

  @override
  String get libraryClearConfirmTitle => 'Bibliothek löschen';

  @override
  String get libraryClearConfirmMessage =>
      'Dadurch werden alle gescannten Titel aus Ihrer Bibliothek entfernt. Ihre eigentlichen Musikdateien werden nicht gelöscht.';

  @override
  String get libraryAbout => 'Über die lokale Bibliothek';

  @override
  String get libraryAboutDescription =>
      'Durchsucht deine bestehende Musiksammlung, um Duplikate beim Herunterladen zu erkennen. Unterstützt die Formate FLAC, M4A, MP3, Opus und OGG. Metadaten werden, sofern verfügbar, aus den Dateitags gelesen.';

  @override
  String libraryTracksUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
    );
    return '$_temp0';
  }

  @override
  String libraryLastScanned(String time) {
    return 'Zuletzt gescannt: $time';
  }

  @override
  String get libraryLastScannedNever => 'Nie';

  @override
  String get libraryScanning => 'Scannen...';

  @override
  String libraryScanProgress(String progress, int total) {
    return '$progress% von $total Dateien';
  }

  @override
  String get libraryInLibrary => 'In Bibliothek';

  @override
  String libraryRemovedMissingFiles(int count) {
    return 'Entfernte $count fehlende Dateien aus der Bibliothek';
  }

  @override
  String get libraryCleared => 'Bibliothek geleert';

  @override
  String get libraryStorageAccessRequired => 'Speicherzugriff erforderlich';

  @override
  String get libraryStorageAccessMessage =>
      'SpotiFLAC benötigt Speicherzugriff, um deine Musikbibliothek zu scannen. Bitte erteile die Berechtigung in den Einstellungen.';

  @override
  String get libraryFolderNotExist => 'Der ausgewählte Ordner existiert nicht';

  @override
  String get librarySourceDownloaded => 'Heruntergeladen';

  @override
  String get librarySourceLocal => 'Lokal';

  @override
  String get libraryFilterAll => 'Alle';

  @override
  String get libraryFilterDownloaded => 'Heruntergeladen';

  @override
  String get libraryFilterLocal => 'Lokal';

  @override
  String get libraryFilterTitle => 'Filter';

  @override
  String get libraryFilterReset => 'Zurücksetzen';

  @override
  String get libraryFilterApply => 'Anwenden';

  @override
  String get libraryFilterSource => 'Quelle';

  @override
  String get libraryFilterQuality => 'Qualität';

  @override
  String get libraryFilterQualityHiRes => 'Hi-Res (24bit)';

  @override
  String get libraryFilterQualityCD => 'CD (16bit)';

  @override
  String get libraryFilterQualityLossy => 'Verlustbehaftet';

  @override
  String get libraryFilterFormat => 'Format';

  @override
  String get libraryFilterSort => 'Sortieren';

  @override
  String get libraryFilterSortLatest => 'Neuste';

  @override
  String get libraryFilterSortOldest => 'Älteste';

  @override
  String get timeJustNow => 'Gerade eben';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor $count Minute',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor $count Stunde',
    );
    return '$_temp0';
  }

  @override
  String get tutorialWelcomeTitle => 'Willkommen bei SpotiFLAC!';

  @override
  String get tutorialWelcomeDesc =>
      'Lass uns lernen, wie du deine Lieblingsmusik in verlustfreier Qualität herunterlädst. Dieses schnelle Tutorial zeigt dir die Grundlagen.';

  @override
  String get tutorialWelcomeTip1 =>
      'Lade Musik von Spotify, Deezer herunter oder jeden unterstützten Link einfügen';

  @override
  String get tutorialWelcomeTip2 =>
      'Hole dir FLAC Audio von Tidal, Qobuz oder Amazon Musik';

  @override
  String get tutorialWelcomeTip3 =>
      'Automatische Metadaten, Cover und Lyrics einbetten';

  @override
  String get tutorialSearchTitle => 'Suche Musik';

  @override
  String get tutorialSearchDesc =>
      'Es gibt zwei einfache Möglichkeiten, Musik zu finden, die du herunterladen möchtest.';

  @override
  String get tutorialDownloadTitle => 'Musik wird heruntergeladen';

  @override
  String get tutorialDownloadDesc =>
      'Das Herunterladen von Musik ist einfach und schnell. So funktioniert es.';

  @override
  String get tutorialLibraryTitle => 'Deine Bibliothek';

  @override
  String get tutorialLibraryDesc =>
      'Die gesamte heruntergeladene Musik ist in der Bibliothek organisiert.';

  @override
  String get tutorialLibraryTip1 =>
      'Fortschritt und Warteschlange im Bibliothek‑Tab anzeigen';

  @override
  String get tutorialLibraryTip2 =>
      'Tippe auf einen Titel, um ihn mit deinem Musikplayer abzuspielen';

  @override
  String get tutorialLibraryTip3 =>
      'Wechsle zwischen Listen- und Gitteransicht für ein besseres Surfen';

  @override
  String get tutorialExtensionsTitle => 'Erweiterungen';

  @override
  String get tutorialExtensionsDesc =>
      'Erweitere die Fähigkeiten der App mit Community-Erweiterungen.';

  @override
  String get tutorialExtensionsTip1 =>
      'Im Store Tab findest du nützliche Erweiterungen';

  @override
  String get tutorialExtensionsTip2 =>
      'Neue Download- oder Suchanbieter hinzufügen';

  @override
  String get tutorialExtensionsTip3 =>
      'Lyrics, erweiterte Metadaten und mehr Funktionen erhalten';

  @override
  String get tutorialSettingsTitle => 'Passe deine Benutzererfahrung an';

  @override
  String get tutorialSettingsDesc =>
      'Personalisiere die App in den Einstellungen nach deiner Präferenz.';

  @override
  String get tutorialSettingsTip1 =>
      'Downloadverzeichnis und Ordnerorganisation ändern';

  @override
  String get tutorialSettingsTip2 =>
      'Standard Audioqualität und Formateinstellungen festlegen';

  @override
  String get tutorialSettingsTip3 => 'App-Design und Aussehen anpassen';

  @override
  String get tutorialReadyMessage =>
      'Das ist alles! Lade jetzt deine Lieblingsmusik herunter.';

  @override
  String get libraryForceFullScan => 'Vollen Neu-Scan erzwingen';

  @override
  String get libraryForceFullScanSubtitle =>
      'Alle Dateien erneut scannen und Cache ignorieren';

  @override
  String get cleanupOrphanedDownloads => 'Verwaiste Downloads bereinigen';

  @override
  String get cleanupOrphanedDownloadsSubtitle =>
      'Verlaufseinträge für Dateien löschen, die nicht mehr existieren';

  @override
  String cleanupOrphanedDownloadsResult(int count) {
    return 'Entfernte $count verwaiste Einträge aus dem Verlauf';
  }

  @override
  String get cleanupOrphanedDownloadsNone =>
      'Keine verwaisten Einträge gefunden';

  @override
  String get cacheTitle => 'Speicher & Cache';

  @override
  String get cacheSummaryTitle => 'Cache-Übersicht';

  @override
  String get cacheSummarySubtitle =>
      'Das Leeren des Caches entfernt nicht heruntergeladene Musikdateien.';

  @override
  String cacheEstimatedTotal(String size) {
    return 'Geschätzte Cache-Größe: $size';
  }

  @override
  String get cacheSectionStorage => 'Zwischengespeicherte Daten';

  @override
  String get cacheSectionMaintenance => 'Wartung';

  @override
  String get cacheAppDirectory => 'App-Cache Verzeichnis';

  @override
  String get cacheAppDirectoryDesc =>
      'HTTP-Antworten, WebView Daten und andere temporäre App-Daten.';

  @override
  String get cacheTempDirectory => 'Temporäres Verzeichnis';

  @override
  String get cacheTempDirectoryDesc =>
      'Temporäre Dateien von Downloads und Audio-Konvertierung.';

  @override
  String get cacheCoverImage => 'Cover-Cache';

  @override
  String get cacheCoverImageDesc =>
      'Album- und Titelcover heruntergeladen. Werden erneut heruntergeladen.';

  @override
  String get cacheLibraryCover => 'Bibliotheks-Cover-Cache';

  @override
  String get cacheLibraryCoverDesc =>
      'Cover aus lokalen Musikdateien extrahiert. Wird beim nächsten Scannen neu extrahiert.';

  @override
  String get cacheExploreFeed => 'Feed-Cache entdecken';

  @override
  String get cacheExploreFeedDesc =>
      'Startseiten-Inhalt (neue Releases, Trends). Wird bei einem Neustart aktualisiert.';

  @override
  String get cacheTrackLookup => 'Titel Such-Cache';

  @override
  String get cacheTrackLookupDesc =>
      'Spotify/Deezer Track-ID-Lookups. Das Löschen kann die nächsten Suchergebnisse verlangsamen.';

  @override
  String get cacheCleanupUnusedDesc =>
      'Verwaisten Downloadverlauf und Bibliothekseinträge für fehlende Dateien entfernen.';

  @override
  String get cacheNoData => 'Keine gecachten Daten';

  @override
  String cacheSizeWithFiles(String size, int count) {
    return '$size in $count Dateien';
  }

  @override
  String cacheSizeOnly(String size) {
    return '$size';
  }

  @override
  String cacheEntries(int count) {
    return '$count Einträge';
  }

  @override
  String cacheClearSuccess(String target) {
    return 'Entfernt: $target';
  }

  @override
  String get cacheClearConfirmTitle => 'Cache leeren?';

  @override
  String cacheClearConfirmMessage(String target) {
    return 'Dies löscht zwischengespeicherte Daten in $target. Die Musikdateien werden nicht gelöscht.';
  }

  @override
  String get cacheClearAllConfirmTitle => 'Gesamten Cache leeren?';

  @override
  String get cacheClearAllConfirmMessage =>
      'Dadurch werden alle Cache-Kategorien auf dieser Seite gelöscht. Heruntergeladene Musikdateien werden nicht gelöscht.';

  @override
  String get cacheClearAll => 'Gesamten Cache leeren';

  @override
  String get cacheCleanupUnused => 'Unbenutzte Daten bereinigen';

  @override
  String get cacheCleanupUnusedSubtitle =>
      'Verwaisten Downloadverlauf und fehlende Bibliothekseinträge löschen';

  @override
  String cacheCleanupResult(int downloadCount, int libraryCount) {
    return 'Bereinigung: $downloadCount verwaiste Downloads, $libraryCount fehlende Bibliothekseinträge';
  }

  @override
  String get cacheRefreshStats => 'Statistik aktualisieren';

  @override
  String get trackSaveCoverArt => 'Cover speichern';

  @override
  String get trackSaveCoverArtSubtitle => 'Albumcover als .jpg Datei speichern';

  @override
  String get trackSaveLyrics => 'Lyrics als .lrc speichern';

  @override
  String get trackSaveLyricsSubtitle => 'Lade Lyrics als .lrc Datei';

  @override
  String get trackSaveLyricsProgress => 'Speichere Lyrics...';

  @override
  String get trackReEnrich => 'Neu-anreichern';

  @override
  String get trackReEnrichOnlineSubtitle =>
      'Metadaten online suchen und in Datei einbinden';

  @override
  String get trackEditMetadata => 'Metadaten bearbeiten';

  @override
  String trackCoverSaved(String fileName) {
    return 'Cover art saved to $fileName';
  }

  @override
  String get trackCoverNoSource => 'No cover art source available';

  @override
  String trackLyricsSaved(String fileName) {
    return 'Lyrics in $fileName gespeichert';
  }

  @override
  String get trackReEnrichProgress => 'Metadaten neu anreichern...';

  @override
  String get trackReEnrichSearching => 'Suche Metadaten online...';

  @override
  String get trackReEnrichSuccess => 'Metadaten erfolgreich neu angereichert';

  @override
  String get trackReEnrichFfmpegFailed =>
      'FFmpeg Metadaten-Einbettung fehlgeschlagen';

  @override
  String trackSaveFailed(String error) {
    return 'Fehler: $error';
  }

  @override
  String get trackConvertFormat => 'Format konvertieren';

  @override
  String get trackConvertFormatSubtitle => 'In MP3 oder Opus konvertieren';

  @override
  String get trackConvertTitle => 'Audio konvertieren';

  @override
  String get trackConvertTargetFormat => 'Zielformat';

  @override
  String get trackConvertBitrate => 'Bitrate';

  @override
  String get trackConvertConfirmTitle => 'Konvertierung bestätigen';

  @override
  String trackConvertConfirmMessage(
    String sourceFormat,
    String targetFormat,
    String bitrate,
  ) {
    return 'Konvertieren von $sourceFormat in $targetFormat bei $bitrate?\n\nDie Originaldatei wird nach der Konvertierung gelöscht.';
  }

  @override
  String get trackConvertConverting => 'Konvertiere Audio...';

  @override
  String trackConvertSuccess(String format) {
    return 'Konvertiert in $format erfolgreich';
  }

  @override
  String get trackConvertFailed => 'Konvertierung fehlgeschlagen';

  @override
  String get cueSplitTitle => 'Split CUE Sheet';

  @override
  String get cueSplitSubtitle => 'Split CUE+FLAC into individual tracks';

  @override
  String cueSplitAlbum(String album) {
    return 'Album: $album';
  }

  @override
  String cueSplitArtist(String artist) {
    return 'Artist: $artist';
  }

  @override
  String cueSplitTrackCount(int count) {
    return '$count tracks';
  }

  @override
  String get cueSplitConfirmTitle => 'Split CUE Album';

  @override
  String cueSplitConfirmMessage(String album, int count) {
    return 'Split \"$album\" into $count individual FLAC files?\n\nFiles will be saved to the same directory.';
  }

  @override
  String cueSplitSplitting(int current, int total) {
    return 'Splitting CUE sheet... ($current/$total)';
  }

  @override
  String cueSplitSuccess(int count) {
    return 'Split into $count tracks successfully';
  }

  @override
  String get cueSplitFailed => 'CUE split failed';

  @override
  String get cueSplitNoAudioFile => 'Audio file not found for this CUE sheet';

  @override
  String get cueSplitButton => 'Split into Tracks';

  @override
  String get actionCreate => 'Erstellen';

  @override
  String get collectionFoldersTitle => 'Meine Ordner';

  @override
  String get collectionWishlist => 'Wunschliste';

  @override
  String get collectionLoved => 'Lieblingssongs';

  @override
  String get collectionPlaylists => 'Playlisten';

  @override
  String get collectionPlaylist => 'Playlist';

  @override
  String get collectionAddToPlaylist => 'Zur Playlist hinzufügen';

  @override
  String get collectionCreatePlaylist => 'Playlist erstellen';

  @override
  String get collectionNoPlaylistsYet => 'Noch keine Playlists';

  @override
  String get collectionNoPlaylistsSubtitle =>
      'Playlist erstellen, um Titel zu kategorisieren';

  @override
  String collectionPlaylistTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Titel',
      one: '1 Titel',
    );
    return '$_temp0';
  }

  @override
  String collectionAddedToPlaylist(String playlistName) {
    return 'Zu \"$playlistName \" hinzugefügt';
  }

  @override
  String collectionAlreadyInPlaylist(String playlistName) {
    return 'Bereits in \"$playlistName\"';
  }

  @override
  String get collectionPlaylistCreated => 'Playlist erstellt';

  @override
  String get collectionPlaylistNameHint => 'Playlist-Name';

  @override
  String get collectionPlaylistNameRequired => 'Playlist-Name ist erforderlich';

  @override
  String get collectionRenamePlaylist => 'Playlist umbenennen';

  @override
  String get collectionDeletePlaylist => 'Playlist löschen';

  @override
  String collectionDeletePlaylistMessage(String playlistName) {
    return 'Willst du \"$playlistName\" und alle darin enthaltenen Titel löschen?';
  }

  @override
  String get collectionPlaylistDeleted => 'Playlist gelöscht';

  @override
  String get collectionPlaylistRenamed => 'Playlist umbenannt';

  @override
  String get collectionWishlistEmptyTitle => 'Wunschliste ist leer';

  @override
  String get collectionWishlistEmptySubtitle =>
      'Tippe auf das + bei den Titeln, um sie zum späteren Herunterladen zu speichern';

  @override
  String get collectionLovedEmptyTitle => 'Lieblingssongs sind leer';

  @override
  String get collectionLovedEmptySubtitle =>
      'Tippe auf das Herz, um deine Favoriten zu behalten';

  @override
  String get collectionPlaylistEmptyTitle => 'Die Playlist ist leer';

  @override
  String get collectionPlaylistEmptySubtitle =>
      'Drücke lange + auf einem beliebigen Titel, um ihn hier hinzuzufügen';

  @override
  String get collectionRemoveFromPlaylist => 'Von Playlist entfernen';

  @override
  String get collectionRemoveFromFolder => 'Aus Ordner entfernen';

  @override
  String collectionRemoved(String trackName) {
    return '\"$trackName\" entfernt';
  }

  @override
  String collectionAddedToLoved(String trackName) {
    return '\"$trackName\" zu Lieblingssongs hinzugefügt';
  }

  @override
  String collectionRemovedFromLoved(String trackName) {
    return '\"$trackName\" aus Lieblingssongs entfernt';
  }

  @override
  String collectionAddedToWishlist(String trackName) {
    return '\"$trackName\" zur Wunschliste hinzugefügt';
  }

  @override
  String collectionRemovedFromWishlist(String trackName) {
    return '\"$trackName\" aus der Wunschliste entfernt';
  }

  @override
  String get trackOptionAddToLoved => 'Zu Lieblingssongs hinzufügen';

  @override
  String get trackOptionRemoveFromLoved => 'Aus Lieblingssongs entfernt';

  @override
  String get trackOptionAddToWishlist => 'Zur Wunschliste hinzufügen';

  @override
  String get trackOptionRemoveFromWishlist => 'Von der Wunschliste entfernen';

  @override
  String get collectionPlaylistChangeCover => 'Coverbild ändern';

  @override
  String get collectionPlaylistRemoveCover => 'Cover entfernen';

  @override
  String selectionShareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Titel',
      one: 'Titel',
    );
    return 'Teile $count $_temp0';
  }

  @override
  String get selectionShareNoFiles => 'Keine teilbare Dateien gefunden';

  @override
  String selectionConvertCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Titel',
      one: 'Titel',
    );
    return 'Konvertiere $count $_temp0';
  }

  @override
  String get selectionConvertNoConvertible =>
      'Keine konvertierbare Titel ausgewählt';

  @override
  String get selectionBatchConvertConfirmTitle => 'Batch-Konvertierung';

  @override
  String selectionBatchConvertConfirmMessage(
    int count,
    String format,
    String bitrate,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Titel',
      one: 'Titel',
    );
    return 'Konvertiere $count $format $_temp0 zu $bitrate?\n\nOriginaldateien werden nach der Konvertierung gelöscht.';
  }

  @override
  String selectionBatchConvertProgress(int current, int total) {
    return 'Konvertiere $current von $total...';
  }

  @override
  String selectionBatchConvertSuccess(int success, int total, String format) {
    return '$success von $total Titeln in $format konvertiert';
  }

  @override
  String downloadedAlbumDownloadedCount(int count) {
    return '$count heruntergeladen';
  }

  @override
  String get downloadUseAlbumArtistForFoldersAlbumSubtitle =>
      'Künstlerordner verwenden den Album-Interpreten, wenn verfügbar';

  @override
  String get downloadUseAlbumArtistForFoldersTrackSubtitle =>
      'Artist folders use Track Artist only';
}
