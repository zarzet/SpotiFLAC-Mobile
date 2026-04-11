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
  String get downloadSingleFilenameFormat => 'Single Filename Format';

  @override
  String get downloadSingleFilenameFormatDescription =>
      'Filename pattern for singles and EPs. Uses the same tags as the album format.';

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
  String get optionsDefaultSearchTab => 'Default Search Tab';

  @override
  String get optionsDefaultSearchTabSubtitle =>
      'Choose which tab opens first for new search results.';

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
  String get optionsReplayGain => 'ReplayGain';

  @override
  String get optionsReplayGainSubtitleOn =>
      'Scan loudness and embed ReplayGain tags (EBU R128)';

  @override
  String get optionsReplayGainSubtitleOff =>
      'Disabled: no loudness normalization tags';

  @override
  String get optionsArtistTagMode => 'Artist Tag Mode';

  @override
  String get optionsArtistTagModeDescription =>
      'Choose how multiple artists are written into embedded tags.';

  @override
  String get optionsArtistTagModeJoined => 'Single joined value';

  @override
  String get optionsArtistTagModeJoinedSubtitle =>
      'Write one ARTIST value like \"Artist A, Artist B\" for maximum player compatibility.';

  @override
  String get optionsArtistTagModeSplitVorbis => 'Split tags for FLAC/Opus';

  @override
  String get optionsArtistTagModeSplitVorbisSubtitle =>
      'Write one artist tag per artist for FLAC and Opus; MP3 and M4A stay joined.';

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
  String get aboutKeepAndroidOpen => 'Keep Android Open';

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
      'Lade Spotify-Titel in verlustfreier Qualität von Tidal und Qobuz herunter.';

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
      'Auf iOS werden Downloads im Dokumentenordner der App gespeichert. Du kannst sie über die Datei-App aufrufen.';

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
  String get dialogDownload => 'Download';

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
  String get errorUrlNotRecognized => 'Link wurde nicht erkannt';

  @override
  String get errorUrlNotRecognizedMessage =>
      'Dieser Link ist inkompatibel. Prüfe die URL und stelle sicher, dass eine kompatible Erweiterung installiert ist.';

  @override
  String get errorUrlFetchFailed =>
      'Laden fehlgeschlagen. Bitte erneut versuchen.';

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
  String get selectionSelectToDelete => 'Titel zum Löschen wählen';

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
  String get searchAlbums => 'Alben';

  @override
  String get searchPlaylists => 'Playlisten';

  @override
  String get searchSortTitle => 'Sort Results';

  @override
  String get searchSortDefault => 'Default';

  @override
  String get searchSortTitleAZ => 'Title (A-Z)';

  @override
  String get searchSortTitleZA => 'Title (Z-A)';

  @override
  String get searchSortArtistAZ => 'Artist (A-Z)';

  @override
  String get searchSortArtistZA => 'Artist (Z-A)';

  @override
  String get searchSortDurationShort => 'Duration (Shortest)';

  @override
  String get searchSortDurationLong => 'Duration (Longest)';

  @override
  String get searchSortDateOldest => 'Release Date (Oldest)';

  @override
  String get searchSortDateNewest => 'Release Date (Newest)';

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
  String get folderOrganizationByPlaylist => 'Nach Playlist';

  @override
  String get folderOrganizationByPlaylistSubtitle =>
      'Ordner für jede Playlist trennen';

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
      'Alle Dateien im Download-Ordner';

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
  String get providerPriorityFallbackExtensionsTitle => 'Extension Fallback';

  @override
  String get providerPriorityFallbackExtensionsDescription =>
      'Choose which installed download extensions can be used during automatic fallback. Built-in providers still follow the priority order above.';

  @override
  String get providerPriorityFallbackExtensionsHint =>
      'Only enabled extensions with download-provider capability are listed here.';

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
  String get trackLyricsNotInFile => 'No lyrics found in this file';

  @override
  String get trackFetchOnlineLyrics => 'Fetch from Online';

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
  String get storeAddRepoTitle => 'Add Extension Repository';

  @override
  String get storeAddRepoDescription =>
      'Enter a GitHub repository URL that contains a registry.json file to browse and install extensions.';

  @override
  String get storeRepoUrlLabel => 'Repository URL';

  @override
  String get storeRepoUrlHint => 'https://github.com/user/repo';

  @override
  String get storeRepoUrlHelper =>
      'e.g. https://github.com/user/extensions-repo';

  @override
  String get storeAddRepoButton => 'Add Repository';

  @override
  String get storeChangeRepoTooltip => 'Change repository';

  @override
  String get storeRepoDialogTitle => 'Extension Repository';

  @override
  String get storeRepoDialogCurrent => 'Current repository:';

  @override
  String get storeNewRepoUrlLabel => 'New Repository URL';

  @override
  String get storeLoadError => 'Failed to load repository';

  @override
  String get storeEmptyNoExtensions => 'No extensions available';

  @override
  String get storeEmptyNoResults => 'No extensions found';

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
  String get extensionsFallbackTitle => 'Fallback Extensions';

  @override
  String get extensionsFallbackSubtitle =>
      'Choose which installed download extensions can be used as fallback';

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
  String get downloadLossy320 => 'Lossy 320kbps';

  @override
  String get downloadLossyFormat => 'Lossy Format';

  @override
  String get downloadLossy320Format => 'Lossy 320kbps Format';

  @override
  String get downloadLossy320FormatDesc =>
      'Choose the output format for Tidal 320kbps lossy downloads. The original AAC stream will be converted to your selected format.';

  @override
  String get downloadLossyMp3 => 'MP3 320kbps';

  @override
  String get downloadLossyMp3Subtitle => 'Best compatibility, ~10MB per track';

  @override
  String get downloadLossyOpus256 => 'Opus 256kbps';

  @override
  String get downloadLossyOpus256Subtitle =>
      'Best quality Opus, ~8MB per track';

  @override
  String get downloadLossyOpus128 => 'Opus 128kbps';

  @override
  String get downloadLossyOpus128Subtitle => 'Smallest size, ~4MB per track';

  @override
  String get qualityNote =>
      'Die eigentliche Qualität hängt von der Verfügbarkeit des Dienstes ab';

  @override
  String get downloadAskBeforeDownload => 'Qualität vor Download fragen';

  @override
  String get downloadDirectory => 'Download-Ordner';

  @override
  String get downloadSeparateSinglesFolder => 'Singles Ordner trennen';

  @override
  String get downloadAlbumFolderStructure => 'Album-Ordnerstruktur';

  @override
  String get downloadUseAlbumArtistForFolders =>
      'Album-Künstler für Ordner verwenden';

  @override
  String get downloadUsePrimaryArtistOnly => 'Primärer Künstler nur für Ordner';

  @override
  String get downloadUsePrimaryArtistOnlyEnabled =>
      'Vorgestellte Künstler aus dem Ordnernamen entfernt (z.B. Justin Bieber, Quavo → Justin Bieber)';

  @override
  String get downloadUsePrimaryArtistOnlyDisabled =>
      'Vollständiger Künstler für Ordnername';

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
  String get settingsAutoExportFailed =>
      'Auto-Export fehlgeschlagener Downloads';

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
  String get albumFolderArtistAlbumSubtitle => 'Alben/Künster Name/Album Name/';

  @override
  String get albumFolderArtistYearAlbum => 'Künstler / [Year] Album';

  @override
  String get albumFolderArtistYearAlbumSubtitle =>
      'Alben/Künster Name/[2005] Album Name/';

  @override
  String get albumFolderAlbumOnly => 'Nur Alben';

  @override
  String get albumFolderAlbumOnlySubtitle => 'Alben/Album Name/';

  @override
  String get albumFolderYearAlbum => '[Year] Album';

  @override
  String get albumFolderYearAlbumSubtitle => 'Alben/[2005] Album Name/';

  @override
  String get albumFolderArtistAlbumSingles => 'Künstler / Album + Singles';

  @override
  String get albumFolderArtistAlbumSinglesSubtitle =>
      'Künstler/Album/ und Künstler/Singles/';

  @override
  String get albumFolderArtistAlbumFlat => 'Artist / Album (Singles flat)';

  @override
  String get albumFolderArtistAlbumFlatSubtitle =>
      'Artist/Album/ and Artist/song.flac';

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
  String get downloadedAlbumSelectToDelete => 'Titel zum Löschen wählen';

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
    return '$count Titel aus $albumCount Alben';
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
      'Wähle bestimmte Alben oder Singles';

  @override
  String get discographyFetchingTracks => 'Lade Titel...';

  @override
  String discographyFetchingAlbum(int current, int total) {
    return 'Lade $current von $total...';
  }

  @override
  String discographySelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get discographyDownloadSelected => 'Auswahl herunterladen';

  @override
  String discographyAddedToQueue(int count) {
    return '$count Titel zur Warteschlange hinzugefügt';
  }

  @override
  String discographySkippedDownloaded(int added, int skipped) {
    return '$added hinzugefügt, $skipped bereits heruntergeladen';
  }

  @override
  String get discographyNoAlbums => 'Es sind keine Alben verfügbar';

  @override
  String get discographyFailedToFetch => 'Fehler beim Abrufen einiger Alben';

  @override
  String get sectionStorageAccess => 'Speicherzugriff';

  @override
  String get allFilesAccess => 'Zugriff auf alle Dateien';

  @override
  String get allFilesAccessEnabledSubtitle => 'Darf in jeden Ordner schreiben';

  @override
  String get allFilesAccessDisabledSubtitle => 'Nur auf Medienordner begrenzt';

  @override
  String get allFilesAccessDescription =>
      'Option bei Schreibfehlern bitte aktivieren (erforderlich ab Android 13).';

  @override
  String get allFilesAccessDeniedMessage =>
      'Zugriff verweigert. Bitte aktiviere \"Zugriff auf alle Dateien\" manuell in den Systemeinstellungen.';

  @override
  String get allFilesAccessDisabledMessage =>
      'Zugriff auf alle Dateien ist deaktiviert. Die App verwendet nur begrenzten Zugriff auf den Speicher.';

  @override
  String get settingsLocalLibrary => 'Lokale Bibliothek';

  @override
  String get settingsLocalLibrarySubtitle =>
      'Musik scannen & Duplikate erkennen';

  @override
  String get settingsCache => 'Speicher & Cache';

  @override
  String get settingsCacheSubtitle =>
      'Größe anzeigen und Daten im Cache leeren';

  @override
  String get libraryTitle => 'Lokale Bibliothek';

  @override
  String get libraryScanSettings => 'Scan Einstellungen';

  @override
  String get libraryEnableLocalLibrary => 'Lokale Bibliothek aktivieren';

  @override
  String get libraryEnableLocalLibrarySubtitle =>
      'Scan und verfolge deine bestehende Musik';

  @override
  String get libraryFolder => 'Bibliotheksordner';

  @override
  String get libraryFolderHint => 'Tippe um Ordner auszuwählen';

  @override
  String get libraryShowDuplicateIndicator => 'Duplikat Indikator anzeigen';

  @override
  String get libraryShowDuplicateIndicatorSubtitle =>
      'Bei der Suche nach vorhandenen Titeln anzeigen';

  @override
  String get libraryAutoScan => 'Auto Scan';

  @override
  String get libraryAutoScanSubtitle =>
      'Automatically scan your library for new files';

  @override
  String get libraryAutoScanOff => 'Off';

  @override
  String get libraryAutoScanOnOpen => 'Every app open';

  @override
  String get libraryAutoScanDaily => 'Daily';

  @override
  String get libraryAutoScanWeekly => 'Weekly';

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
  String libraryFilesUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'files',
      one: 'file',
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
  String get libraryScanFinalizing => 'Finalizing library...';

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
  String get libraryFilterMetadata => 'Metadata';

  @override
  String get libraryFilterMetadataComplete => 'Complete metadata';

  @override
  String get libraryFilterMetadataMissingAny => 'Missing any metadata';

  @override
  String get libraryFilterMetadataMissingYear => 'Missing year';

  @override
  String get libraryFilterMetadataMissingGenre => 'Missing genre';

  @override
  String get libraryFilterMetadataMissingAlbumArtist => 'Missing album artist';

  @override
  String get libraryFilterSort => 'Sortieren';

  @override
  String get libraryFilterSortLatest => 'Neuste';

  @override
  String get libraryFilterSortOldest => 'Älteste';

  @override
  String get libraryFilterSortAlbumAsc => 'Album (A-Z)';

  @override
  String get libraryFilterSortAlbumDesc => 'Album (Z-A)';

  @override
  String get libraryFilterSortGenreAsc => 'Genre (A-Z)';

  @override
  String get libraryFilterSortGenreDesc => 'Genre (Z-A)';

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
      'Hole dir FLAC Audio von Tidal, Qobuz oder Deezer';

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
      'Download-Ordner und Ordner-Organisation ändern';

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
  String get cacheAppDirectory => 'App-Cache Ordner';

  @override
  String get cacheAppDirectoryDesc =>
      'HTTP-Antworten, WebView Daten und andere temporäre App-Daten.';

  @override
  String get cacheTempDirectory => 'Temporärer Ordner';

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
  String get trackReEnrichFieldsTitle => 'Fields to update';

  @override
  String get trackReEnrichFieldCover => 'Cover Art';

  @override
  String get trackReEnrichFieldLyrics => 'Lyrics';

  @override
  String get trackReEnrichFieldBasicTags => 'Album, Album Artist';

  @override
  String get trackReEnrichFieldTrackInfo => 'Track & Disc Number';

  @override
  String get trackReEnrichFieldReleaseInfo => 'Date & ISRC';

  @override
  String get trackReEnrichFieldExtra => 'Genre, Label, Copyright';

  @override
  String get trackReEnrichSelectAll => 'Select All';

  @override
  String get trackEditMetadata => 'Metadaten bearbeiten';

  @override
  String trackCoverSaved(String fileName) {
    return 'Cover in $fileName gespeichert';
  }

  @override
  String get trackCoverNoSource => 'Keine Cover Quelle vorhanden';

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
  String get queueFlacAction => 'Queue FLAC';

  @override
  String queueFlacConfirmMessage(int count) {
    return 'Search online matches for the selected tracks and queue FLAC downloads.\n\nExisting files will not be modified or deleted.\n\nOnly high-confidence matches are queued automatically.\n\n$count selected';
  }

  @override
  String queueFlacFindingProgress(int current, int total) {
    return 'Finding FLAC matches... ($current/$total)';
  }

  @override
  String get queueFlacNoReliableMatches =>
      'No reliable online matches found for the selection';

  @override
  String queueFlacQueuedWithSkipped(int addedCount, int skippedCount) {
    return 'Added $addedCount tracks to queue, skipped $skippedCount';
  }

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
  String trackConvertConfirmMessageLossless(
    String sourceFormat,
    String targetFormat,
  ) {
    return 'Convert from $sourceFormat to $targetFormat? (Lossless — no quality loss)\n\nThe original file will be deleted after conversion.';
  }

  @override
  String get trackConvertLosslessHint =>
      'Lossless conversion — no quality loss';

  @override
  String get trackConvertConverting => 'Konvertiere Audio...';

  @override
  String trackConvertSuccess(String format) {
    return 'Konvertiert in $format erfolgreich';
  }

  @override
  String get trackConvertFailed => 'Konvertierung fehlgeschlagen';

  @override
  String get cueSplitTitle => 'CUE-Sheet aufteilen';

  @override
  String get cueSplitSubtitle => 'CUE+FLAC in einzelne Titel aufteilen';

  @override
  String cueSplitAlbum(String album) {
    return 'Album: $album';
  }

  @override
  String cueSplitArtist(String artist) {
    return 'Künstler: $artist';
  }

  @override
  String cueSplitTrackCount(int count) {
    return '$count Titel';
  }

  @override
  String get cueSplitConfirmTitle => 'CUE-Album aufteilen';

  @override
  String cueSplitConfirmMessage(String album, int count) {
    return 'Soll „$album“ in $count einzelne FLAC-Dateien aufgeteilt werden?\n\nDie Dateien werden im selben Ordner gespeichert.';
  }

  @override
  String cueSplitSplitting(int current, int total) {
    return 'CUE-Sheet wird geteilt... ($current/$total)';
  }

  @override
  String cueSplitSuccess(int count) {
    return '$count Titel erfolgreich aufgeteilt';
  }

  @override
  String get cueSplitFailed => 'CUE-Aufteilung fehlgeschlagen';

  @override
  String get cueSplitNoAudioFile =>
      'Audiodatei für dieses CUE-Sheet nicht gefunden';

  @override
  String get cueSplitButton => 'In Titel aufteilen';

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
  String selectionBatchConvertConfirmMessageLossless(int count, String format) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Convert $count $_temp0 to $format? (Lossless — no quality loss)\n\nOriginal files will be deleted after conversion.';
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
      'Interpret-Ordner verwenden Album-Interpret, sofern vorhanden';

  @override
  String get downloadUseAlbumArtistForFoldersTrackSubtitle =>
      'Künstler-Ordner nur für Titel-Künstler';

  @override
  String get lyricsProvidersTitle => 'Lyrics Providers';

  @override
  String get lyricsProvidersDescription =>
      'Enable, disable and reorder lyrics sources. Providers are tried top-to-bottom until lyrics are found.';

  @override
  String get lyricsProvidersInfoText =>
      'Extension lyrics providers always run before built-in providers. At least one provider must remain enabled.';

  @override
  String lyricsProvidersEnabledSection(int count) {
    return 'Enabled ($count)';
  }

  @override
  String lyricsProvidersDisabledSection(int count) {
    return 'Disabled ($count)';
  }

  @override
  String get lyricsProvidersAtLeastOne =>
      'At least one provider must remain enabled';

  @override
  String get lyricsProvidersSaved => 'Lyrics provider priority saved';

  @override
  String get lyricsProvidersDiscardContent =>
      'You have unsaved changes that will be lost.';

  @override
  String get lyricsProviderLrclibDesc => 'Open-source synced lyrics database';

  @override
  String get lyricsProviderNeteaseDesc =>
      'NetEase Cloud Music (good for Asian songs)';

  @override
  String get lyricsProviderMusixmatchDesc =>
      'Largest lyrics database (multi-language)';

  @override
  String get lyricsProviderAppleMusicDesc =>
      'Word-by-word synced lyrics (via proxy)';

  @override
  String get lyricsProviderQqMusicDesc =>
      'QQ Music (good for Chinese songs, via proxy)';

  @override
  String get lyricsProviderExtensionDesc => 'Extension provider';

  @override
  String get safMigrationTitle => 'Storage Update Required';

  @override
  String get safMigrationMessage1 =>
      'SpotiFLAC now uses Android Storage Access Framework (SAF) for downloads. This fixes \"permission denied\" errors on Android 10+.';

  @override
  String get safMigrationMessage2 =>
      'Please select your download folder again to switch to the new storage system.';

  @override
  String get safMigrationSuccess => 'Download folder updated to SAF mode';

  @override
  String get settingsDonate => 'Donate';

  @override
  String get settingsDonateSubtitle => 'Support SpotiFLAC-Mobile development';

  @override
  String get tooltipLoveAll => 'Love All';

  @override
  String get tooltipAddToPlaylist => 'Add to Playlist';

  @override
  String snackbarRemovedTracksFromLoved(int count) {
    return 'Removed $count tracks from Loved';
  }

  @override
  String snackbarAddedTracksToLoved(int count) {
    return 'Added $count tracks to Loved';
  }

  @override
  String get dialogDownloadAllTitle => 'Download All';

  @override
  String dialogDownloadAllMessage(int count) {
    return 'Download $count tracks?';
  }

  @override
  String get homeSkipAlreadyDownloaded => 'Skip already downloaded songs';

  @override
  String get homeGoToAlbum => 'Go to Album';

  @override
  String get homeAlbumInfoUnavailable => 'Album info not available';

  @override
  String get snackbarLoadingCueSheet => 'Loading CUE sheet...';

  @override
  String get snackbarMetadataSaved => 'Metadata saved successfully';

  @override
  String get snackbarFailedToEmbedLyrics => 'Failed to embed lyrics';

  @override
  String get snackbarFailedToWriteStorage => 'Failed to write back to storage';

  @override
  String snackbarError(String error) {
    return 'Error: $error';
  }

  @override
  String get snackbarNoActionDefined => 'No action defined for this button';

  @override
  String get noTracksFoundForAlbum => 'No tracks found for this album';

  @override
  String get downloadLocationSubtitle =>
      'Choose storage mode for downloaded files.';

  @override
  String get storageModeAppFolder => 'App folder (non-SAF)';

  @override
  String get storageModeAppFolderSubtitle => 'Use default Music/SpotiFLAC path';

  @override
  String get storageModeSaf => 'SAF folder';

  @override
  String get storageModeSafSubtitle =>
      'Pick folder via Android Storage Access Framework';

  @override
  String get downloadFilenameDescription =>
      'Customize how your files are named.';

  @override
  String get downloadFilenameInsertTag => 'Tap to insert tag:';

  @override
  String get downloadSeparateSinglesEnabled => 'Albums/ and Singles/ folders';

  @override
  String get downloadSeparateSinglesDisabled => 'All files in same structure';

  @override
  String get downloadArtistNameFilters => 'Artist Name Filters';

  @override
  String get downloadCreatePlaylistSourceFolder =>
      'Create playlist source folder';

  @override
  String get downloadCreatePlaylistSourceFolderEnabled =>
      'Playlist downloads use Playlist/ plus your normal folder structure.';

  @override
  String get downloadCreatePlaylistSourceFolderDisabled =>
      'Playlist downloads use the normal folder structure only.';

  @override
  String get downloadCreatePlaylistSourceFolderRedundant =>
      'By Playlist already places downloads inside a playlist folder.';

  @override
  String get downloadSongLinkRegion => 'SongLink Region';

  @override
  String get downloadNetworkCompatibilityMode => 'Network compatibility mode';

  @override
  String get downloadNetworkCompatibilityModeEnabled =>
      'Enabled: try HTTP + accept invalid TLS certificates (unsafe)';

  @override
  String get downloadNetworkCompatibilityModeDisabled =>
      'Off: strict HTTPS certificate validation (recommended)';

  @override
  String get downloadSelectServiceToEnable =>
      'Select a built-in service to enable';

  @override
  String get downloadSelectTidalQobuz =>
      'Select Tidal or Qobuz above to configure quality';

  @override
  String get downloadEmbedLyricsDisabled =>
      'Disabled while Embed Metadata is turned off';

  @override
  String get downloadNeteaseIncludeTranslation =>
      'Netease: Include Translation';

  @override
  String get downloadNeteaseIncludeTranslationEnabled =>
      'Append translated lyrics when available';

  @override
  String get downloadNeteaseIncludeTranslationDisabled =>
      'Use original lyrics only';

  @override
  String get downloadNeteaseIncludeRomanization =>
      'Netease: Include Romanization';

  @override
  String get downloadNeteaseIncludeRomanizationEnabled =>
      'Append romanized lyrics when available';

  @override
  String get downloadNeteaseIncludeRomanizationDisabled => 'Disabled';

  @override
  String get downloadAppleQqMultiPerson => 'Apple/QQ Multi-Person Word-by-Word';

  @override
  String get downloadAppleQqMultiPersonEnabled =>
      'Enable v1/v2 speaker and [bg:] tags';

  @override
  String get downloadAppleQqMultiPersonDisabled =>
      'Simplified word-by-word formatting';

  @override
  String get downloadMusixmatchLanguage => 'Musixmatch Language';

  @override
  String get downloadMusixmatchLanguageAuto => 'Auto (original)';

  @override
  String get downloadFilterContributing =>
      'Filter contributing artists in Album Artist';

  @override
  String get downloadFilterContributingEnabled =>
      'Album Artist metadata uses primary artist only';

  @override
  String get downloadFilterContributingDisabled =>
      'Keep full Album Artist metadata value';

  @override
  String get downloadProvidersNoneEnabled => 'None enabled';

  @override
  String get downloadMusixmatchLanguageCode => 'Language code';

  @override
  String get downloadMusixmatchLanguageHint => 'auto / en / es / ja';

  @override
  String get downloadMusixmatchLanguageDesc =>
      'Set preferred language code (example: en, es, ja). Leave empty for auto.';

  @override
  String get downloadMusixmatchAuto => 'Auto';

  @override
  String get downloadNetworkAnySubtitle => 'WiFi + Mobile Data';

  @override
  String get downloadNetworkWifiOnlySubtitle =>
      'Pause downloads on mobile data';

  @override
  String get downloadSongLinkRegionDesc =>
      'Used as userCountry for SongLink API lookup.';

  @override
  String get snackbarUnsupportedAudioFormat => 'Unsupported audio format';

  @override
  String get cacheRefresh => 'Refresh';

  @override
  String dialogDownloadPlaylistsMessage(int trackCount, int playlistCount) {
    String _temp0 = intl.Intl.pluralLogic(
      trackCount,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    String _temp1 = intl.Intl.pluralLogic(
      playlistCount,
      locale: localeName,
      other: 'playlists',
      one: 'playlist',
    );
    return 'Download $trackCount $_temp0 from $playlistCount $_temp1?';
  }

  @override
  String bulkDownloadPlaylistsButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'playlists',
      one: 'playlist',
    );
    return 'Download $count $_temp0';
  }

  @override
  String get bulkDownloadSelectPlaylists => 'Select playlists to download';

  @override
  String get snackbarSelectedPlaylistsEmpty =>
      'Selected playlists have no tracks';

  @override
  String playlistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists',
      one: '1 playlist',
    );
    return '$_temp0';
  }

  @override
  String get editMetadataAutoFill => 'Auto-fill from online';

  @override
  String get editMetadataAutoFillDesc =>
      'Select fields to fill automatically from online metadata';

  @override
  String get editMetadataAutoFillFetch => 'Fetch & Fill';

  @override
  String get editMetadataAutoFillSearching => 'Searching online...';

  @override
  String get editMetadataAutoFillNoResults =>
      'No matching metadata found online';

  @override
  String editMetadataAutoFillDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fields',
      one: 'field',
    );
    return 'Filled $count $_temp0 from online metadata';
  }

  @override
  String get editMetadataAutoFillNoneSelected =>
      'Select at least one field to auto-fill';

  @override
  String get editMetadataFieldTitle => 'Title';

  @override
  String get editMetadataFieldArtist => 'Artist';

  @override
  String get editMetadataFieldAlbum => 'Album';

  @override
  String get editMetadataFieldAlbumArtist => 'Album Artist';

  @override
  String get editMetadataFieldDate => 'Date';

  @override
  String get editMetadataFieldTrackNum => 'Track #';

  @override
  String get editMetadataFieldDiscNum => 'Disc #';

  @override
  String get editMetadataFieldGenre => 'Genre';

  @override
  String get editMetadataFieldIsrc => 'ISRC';

  @override
  String get editMetadataFieldLabel => 'Label';

  @override
  String get editMetadataFieldCopyright => 'Copyright';

  @override
  String get editMetadataFieldCover => 'Cover Art';

  @override
  String get editMetadataSelectAll => 'All';

  @override
  String get editMetadataSelectEmpty => 'Empty only';

  @override
  String queueDownloadingCount(int count) {
    return 'Downloading ($count)';
  }

  @override
  String get queueDownloadedHeader => 'Downloaded';

  @override
  String get queueFilteringIndicator => 'Filtering...';

  @override
  String queueTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String queueAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String get queueEmptyAlbums => 'No album downloads';

  @override
  String get queueEmptyAlbumsSubtitle =>
      'Download multiple tracks from an album to see them here';

  @override
  String get queueEmptySingles => 'No single downloads';

  @override
  String get queueEmptySinglesSubtitle =>
      'Single track downloads will appear here';

  @override
  String get queueEmptyHistory => 'No download history';

  @override
  String get queueEmptyHistorySubtitle => 'Downloaded tracks will appear here';

  @override
  String get selectionAllPlaylistsSelected => 'All playlists selected';

  @override
  String get selectionTapPlaylistsToSelect => 'Tap playlists to select';

  @override
  String get selectionSelectPlaylistsToDelete => 'Select playlists to delete';

  @override
  String get audioAnalysisTitle => 'Audio Quality Analysis';

  @override
  String get audioAnalysisDescription =>
      'Verify lossless quality with spectrum analysis';

  @override
  String get audioAnalysisAnalyzing => 'Analyzing audio...';

  @override
  String get audioAnalysisSampleRate => 'Sample Rate';

  @override
  String get audioAnalysisBitDepth => 'Bit Depth';

  @override
  String get audioAnalysisChannels => 'Channels';

  @override
  String get audioAnalysisDuration => 'Duration';

  @override
  String get audioAnalysisNyquist => 'Nyquist';

  @override
  String get audioAnalysisFileSize => 'Size';

  @override
  String get audioAnalysisDynamicRange => 'Dynamic Range';

  @override
  String get audioAnalysisPeak => 'Peak';

  @override
  String get audioAnalysisRms => 'RMS';

  @override
  String get audioAnalysisSamples => 'Samples';

  @override
  String extensionsSearchWith(String providerName) {
    return 'Search with $providerName';
  }

  @override
  String get extensionsHomeFeedProvider => 'Home Feed Provider';

  @override
  String get extensionsHomeFeedDescription =>
      'Choose which extension provides the home feed on the main screen';

  @override
  String get extensionsHomeFeedAuto => 'Auto';

  @override
  String get extensionsHomeFeedAutoSubtitle =>
      'Automatically select the best available';

  @override
  String extensionsHomeFeedUse(String extensionName) {
    return 'Use $extensionName home feed';
  }

  @override
  String get extensionsNoHomeFeedExtensions => 'No extensions with home feed';

  @override
  String get sortAlphaAsc => 'A-Z';

  @override
  String get sortAlphaDesc => 'Z-A';

  @override
  String get cancelDownloadTitle => 'Cancel download?';

  @override
  String cancelDownloadContent(String trackName) {
    return 'This will cancel the active download for \"$trackName\".';
  }

  @override
  String get cancelDownloadKeep => 'Keep';

  @override
  String get metadataSaveFailedFfmpeg => 'Failed to save metadata via FFmpeg';

  @override
  String get metadataSaveFailedStorage =>
      'Failed to write metadata back to storage';

  @override
  String snackbarFolderPickerFailed(String error) {
    return 'Failed to open folder picker: $error';
  }

  @override
  String get errorLoadAlbum => 'Failed to load album';

  @override
  String get errorLoadPlaylist => 'Failed to load playlist';

  @override
  String get errorLoadArtist => 'Failed to load artist';

  @override
  String get notifChannelDownloadName => 'Download Progress';

  @override
  String get notifChannelDownloadDesc => 'Shows download progress for tracks';

  @override
  String get notifChannelLibraryScanName => 'Library Scan';

  @override
  String get notifChannelLibraryScanDesc => 'Shows local library scan progress';

  @override
  String notifDownloadingTrack(String trackName) {
    return 'Downloading $trackName';
  }

  @override
  String notifFinalizingTrack(String trackName) {
    return 'Finalizing $trackName';
  }

  @override
  String get notifEmbeddingMetadata => 'Embedding metadata...';

  @override
  String notifAlreadyInLibraryCount(int completed, int total) {
    return 'Already in Library ($completed/$total)';
  }

  @override
  String get notifAlreadyInLibrary => 'Already in Library';

  @override
  String notifDownloadCompleteCount(int completed, int total) {
    return 'Download Complete ($completed/$total)';
  }

  @override
  String get notifDownloadComplete => 'Download Complete';

  @override
  String notifDownloadsFinished(int completed, int failed) {
    return 'Downloads Finished ($completed done, $failed failed)';
  }

  @override
  String get notifAllDownloadsComplete => 'All Downloads Complete';

  @override
  String notifTracksDownloadedSuccess(int count) {
    return '$count tracks downloaded successfully';
  }

  @override
  String get notifScanningLibrary => 'Scanning local library';

  @override
  String notifLibraryScanProgressWithTotal(
    int scanned,
    int total,
    int percentage,
  ) {
    return '$scanned/$total files • $percentage%';
  }

  @override
  String notifLibraryScanProgressNoTotal(int scanned, int percentage) {
    return '$scanned files scanned • $percentage%';
  }

  @override
  String get notifLibraryScanComplete => 'Library scan complete';

  @override
  String notifLibraryScanCompleteBody(int count) {
    return '$count tracks indexed';
  }

  @override
  String notifLibraryScanExcluded(int count) {
    return '$count excluded';
  }

  @override
  String notifLibraryScanErrors(int count) {
    return '$count errors';
  }

  @override
  String get notifLibraryScanFailed => 'Library scan failed';

  @override
  String get notifLibraryScanCancelled => 'Library scan cancelled';

  @override
  String get notifLibraryScanStopped => 'Scan stopped before completion.';

  @override
  String notifDownloadingUpdate(String version) {
    return 'Downloading SpotiFLAC v$version';
  }

  @override
  String notifUpdateProgress(String received, String total, int percentage) {
    return '$received / $total MB • $percentage%';
  }

  @override
  String get notifUpdateReady => 'Update Ready';

  @override
  String notifUpdateReadyBody(String version) {
    return 'SpotiFLAC v$version downloaded. Tap to install.';
  }

  @override
  String get notifUpdateFailed => 'Update Failed';

  @override
  String get notifUpdateFailedBody =>
      'Could not download update. Try again later.';
}
