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
      'Lade Spotify-Titel in verlustfreier Qualität von Tidal, Qobuz und Amazon Music herunter.';

  @override
  String get navHome => 'Startseite';

  @override
  String get navLibrary => 'Archiv';

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
      'Lade mehrere Titel eines Albums herunter, um sie hier zu sehen';

  @override
  String get historyNoSingles => 'Keine Einzel-Downloads';

  @override
  String get historyNoSinglesSubtitle =>
      'Einzelne Titel-Downloads werden hier angezeigt';

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
  String get downloadLocation => 'Download-Speicherort';

  @override
  String get downloadLocationSubtitle => 'Wähle den Speicherort der Dateien';

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
  String get aboutSupport => 'Support';

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
  String get aboutDoubleDouble => 'DoubleDouble';

  @override
  String get aboutDoubleDoubleDesc =>
      'Wundervolle API für Amazon Musik-Downloads.';

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
  String get albumTitle => 'Album';

  @override
  String albumTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs',
      one: '1 Song',
    );
    return '$_temp0';
  }

  @override
  String get albumDownloadAll => 'Alle Herunterladen';

  @override
  String get albumDownloadRemaining => 'Downloads verbleibend';

  @override
  String get playlistTitle => 'Playlist';

  @override
  String get artistTitle => 'Künstler';

  @override
  String get artistAlbums => 'Alben';

  @override
  String get artistSingles => 'Singles & EPs';

  @override
  String get artistCompilations => 'Zusammenstellungen';

  @override
  String artistReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Veröffentlichungen',
      one: '1 Veröffentlichung',
    );
    return '$_temp0';
  }

  @override
  String get artistPopular => 'Beliebt';

  @override
  String artistMonthlyListeners(String count) {
    return '$count monatliche Hörer';
  }

  @override
  String get trackMetadataTitle => 'Titel Info';

  @override
  String get trackMetadataArtist => 'Künstler';

  @override
  String get trackMetadataAlbum => 'Album';

  @override
  String get trackMetadataDuration => 'Länge';

  @override
  String get trackMetadataQuality => 'Qualität';

  @override
  String get trackMetadataPath => 'Dateipfad';

  @override
  String get trackMetadataDownloadedAt => 'Heruntergeladen';

  @override
  String get trackMetadataService => 'Anbieter';

  @override
  String get trackMetadataPlay => 'Abspielen';

  @override
  String get trackMetadataShare => 'Teilen';

  @override
  String get trackMetadataDelete => 'Löschen';

  @override
  String get trackMetadataRedownload => 'Erneut herunterladen';

  @override
  String get trackMetadataOpenFolder => 'Ordner öffnen';

  @override
  String get setupTitle => 'Willkommen bei SpotiFLAC';

  @override
  String get setupSubtitle => 'Los geht\'s';

  @override
  String get setupStoragePermission => 'Speicherberechtigung';

  @override
  String get setupStoragePermissionSubtitle =>
      'Benötigt um heruntergeladene Dateien zu Speichern';

  @override
  String get setupStoragePermissionGranted => 'Berechtigung erteilt';

  @override
  String get setupStoragePermissionDenied => 'Berechtigung verweigert';

  @override
  String get setupGrantPermission => 'Berechtigung erlauben';

  @override
  String get setupDownloadLocation => 'Speicherort';

  @override
  String get setupChooseFolder => 'Ordner wählen';

  @override
  String get setupContinue => 'Fortfahren';

  @override
  String get setupSkip => 'Vorerst überspringen';

  @override
  String get setupStorageAccessRequired => 'Speicherzugriff erforderlich';

  @override
  String get setupStorageAccessMessage =>
      'SpotiFLAC benötigt die Berechtigung \"Auf alle Dateien zugreifen\", um Musikdateien in deinen gewählten Ordner zu speichern.';

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
  String get setupSelectDownloadFolder => 'Wähle Download-Ordner aus';

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
  String get setupStepStorage => 'Speicherort';

  @override
  String get setupStepNotification => 'Benachrichtigung';

  @override
  String get setupStepFolder => 'Ordner';

  @override
  String get setupStepSpotify => 'Spotify';

  @override
  String get setupStepPermission => 'Berechtigung';

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
  String get setupNotificationDescription =>
      'Benachrichtigt werden, wenn Downloads abgeschlossen sind.';

  @override
  String get setupFolderSelected => 'Download Ordner ausgewählt!';

  @override
  String get setupFolderChoose => 'Speicherort auwählen';

  @override
  String get setupFolderDescription =>
      'Wähle einen Ordner, in dem die heruntergeladene Musik gespeichert wird.';

  @override
  String get setupChangeFolder => 'Ordner ändern';

  @override
  String get setupSelectFolder => 'Ordner wählen';

  @override
  String get setupSpotifyApiOptional => 'Spotify-API (optional)';

  @override
  String get setupSpotifyApiDescription =>
      'Füge deine Spotify-API-Zugangsdaten für bessere Suchergebnisse und den Zugriff auf Spotify-exklusive Inhalte hinzu.';

  @override
  String get setupUseSpotifyApi => 'Spotify-API verwenden';

  @override
  String get setupEnterCredentialsBelow => 'Gib deine Anmeldedaten unten ein';

  @override
  String get setupUsingDeezer => 'Deezer verwenden (kein Konto erforderlich)';

  @override
  String get setupEnterClientId => 'Spotify-Client-ID eingeben';

  @override
  String get setupEnterClientSecret => 'Spotify Client-Secret eingeben';

  @override
  String get setupGetFreeCredentials =>
      'Hole dir kostenlose API-Anmeldeinformationen aus dem Spotify-Entwickler-Dashboard.';

  @override
  String get setupEnableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get setupProceedToNextStep =>
      'Du kannst mit dem nächsten Schritt fortfahren.';

  @override
  String get setupNotificationProgressDescription =>
      'Du erhältst Benachrichtigungen über den Download-Fortschritt.';

  @override
  String get setupNotificationBackgroundDescription =>
      'Werde benachrichtigt über Download-Fortschritt und -Fertigstellung. Dies hilft Ihnen, Downloads zu verfolgen, wenn die App im Hintergrund ist.';

  @override
  String get setupSkipForNow => 'Vorerst überspringen';

  @override
  String get setupBack => 'Zurück';

  @override
  String get setupNext => 'Weiter';

  @override
  String get setupGetStarted => 'Los geht‘s';

  @override
  String get setupSkipAndStart => 'Überspringen & Starten';

  @override
  String get setupAllowAccessToManageFiles =>
      'Bitte aktiviere \"Zugriff auf alle Dateien erlauben\" auf dem nächsten Bildschirm.';

  @override
  String get setupGetCredentialsFromSpotify =>
      'Zugangsdaten von developer.spotify.com erhalten';

  @override
  String get dialogCancel => 'Abbrechen';

  @override
  String get dialogOk => 'OK';

  @override
  String get dialogSave => 'Speichern';

  @override
  String get dialogDelete => 'Löschen';

  @override
  String get dialogRetry => 'Wiederholen';

  @override
  String get dialogClose => 'Schließen';

  @override
  String get dialogYes => 'Ja';

  @override
  String get dialogNo => 'Nein';

  @override
  String get dialogClear => 'Leeren';

  @override
  String get dialogConfirm => 'Bestätigen';

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
  String get dialogDownloadFailed => 'Download fehlgeschlagen';

  @override
  String get dialogTrackLabel => 'Titel:';

  @override
  String get dialogArtistLabel => 'Künstler:';

  @override
  String get dialogErrorLabel => 'Fehler:';

  @override
  String get dialogClearAll => 'Alles löschen';

  @override
  String get dialogClearAllDownloads =>
      'Bist du dir sicher, dass du alle Downloads löschen möchten?';

  @override
  String get dialogRemoveFromDevice => 'Vom Gerät entfernen?';

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
  String get dialogImportPlaylistTitle => 'Wiedergabeliste importieren';

  @override
  String dialogImportPlaylistMessage(int count) {
    return '$count Titel in CSV gefunden. Zur Warteschlange hinzufügen?';
  }

  @override
  String csvImportTracks(int count) {
    return '$count Titel aus CSV';
  }

  @override
  String snackbarAddedToQueue(String trackName) {
    return '\"$trackName\" zur Warteschlange hinzugefügt';
  }

  @override
  String snackbarAddedTracksToQueue(int count) {
    return '$count Titel zur Warteschlange hinzugefügt';
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
  String snackbarFailedToLoad(String error) {
    return 'Fehler beim Laden: $error';
  }

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
  String errorFailedToLoad(String item) {
    return 'Fehler beim Laden von: $item';
  }

  @override
  String get errorNoTracksFound => 'Keine Titel gefunden';

  @override
  String errorMissingExtensionSource(String item) {
    return 'Kann $item nicht lade wegen fehlender Erweiterungsquelle';
  }

  @override
  String get statusQueued => 'In der Warteschlange';

  @override
  String get statusDownloading => 'Wird heruntergeladen';

  @override
  String get statusFinalizing => 'Wird fertiggestellt';

  @override
  String get statusCompleted => 'Beendet';

  @override
  String get statusFailed => 'Fehlgeschlagen';

  @override
  String get statusSkipped => 'Übersprungen';

  @override
  String get statusPaused => 'Pausiert';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Fortfahren';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionStop => 'Beenden';

  @override
  String get actionSelect => 'Wähle';

  @override
  String get actionSelectAll => 'Alles Auswählen';

  @override
  String get actionDeselect => 'Alle abwählen';

  @override
  String get actionPaste => 'Einfügen';

  @override
  String get actionImportCsv => 'CSV-Datei importieren';

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
  String get selectionTapToSelect => 'Tippe auf Titel zum Auswählen';

  @override
  String selectionDeleteTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Titel',
      one: 'Titel',
    );
    return 'Lösche $count $_temp0';
  }

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
  String get tooltipCancel => 'Abbrechen';

  @override
  String get tooltipStop => 'Beenden';

  @override
  String get tooltipRetry => 'Wiederholen';

  @override
  String get tooltipRemove => 'Entfernen';

  @override
  String get tooltipClear => 'Leeren';

  @override
  String get tooltipPaste => 'Einfügen';

  @override
  String get filenameFormat => 'Dateinamenformat';

  @override
  String filenameFormatPreview(String preview) {
    return 'Vorschau: $preview';
  }

  @override
  String get filenameAvailablePlaceholders => 'Verfügbare Platzhalter:';

  @override
  String filenameHint(Object artist, Object title) {
    return '$artist - $title';
  }

  @override
  String get filenameShowAdvancedTags => 'Show advanced tags';

  @override
  String get filenameShowAdvancedTagsDescription =>
      'Enable formatted tags for track padding and date patterns';

  @override
  String get folderOrganization => 'Ordnerstruktur';

  @override
  String get folderOrganizationNone => 'Keine Organisation';

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
  String updateNewVersion(String version) {
    return 'Version $version ist verfügbar';
  }

  @override
  String get updateDownload => 'Herunterladen';

  @override
  String get updateLater => 'Später';

  @override
  String get updateChangelog => 'Änderungsverlauf';

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
  String get providerPriority => 'Anbieterpriorität';

  @override
  String get providerPrioritySubtitle =>
      'Ziehen, um Download-Anbieter neu anzuordnen';

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
  String get metadataProviderPriority => 'Priorität des Metadaten-Anbieters';

  @override
  String get metadataProviderPrioritySubtitle =>
      'Reihenfolge beim Abrufen von Titelmetadaten';

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
  String get logCopy => 'Protokolle kopieren';

  @override
  String get logClear => 'Protokolle löschen';

  @override
  String get logShare => 'Protokolle teilen';

  @override
  String get logEmpty => 'Keine Protokolle bisher';

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
  String get logIspBlocking => 'ISP BLOCKIERUNG ERKANNT';

  @override
  String get logRateLimited => 'LIMIT ERKANNT';

  @override
  String get logNetworkError => 'NETZWERKFEHLER';

  @override
  String get logTrackNotFound => 'TITEL NICHT GEFUNDEN';

  @override
  String get logFilterBySeverity => 'Protokolle nach Schweregrad filtern';

  @override
  String get logNoLogsYet => 'Keine Protokolle bisher';

  @override
  String get logNoLogsYetSubtitle =>
      'Protokolle werden hier angezeigt, während du die App benutzt';

  @override
  String get logIssueSummary => 'Problemübersicht';

  @override
  String get logIspBlockingDescription =>
      'Ihr ISP blockiert möglicherweise den Zugriff auf den Download Dienst';

  @override
  String get logIspBlockingSuggestion =>
      'Versuche es einem VPN oder ändere DNS auf 1.1.1.1 oder 8.8.8.8';

  @override
  String get logRateLimitedDescription => 'Zu viele Anfragen an den Dienst';

  @override
  String get logRateLimitedSuggestion =>
      'Warte ein paar Minuten, bevor du es erneut versuchst';

  @override
  String get logNetworkErrorDescription => 'Verbindungsprobleme erkannt';

  @override
  String get logNetworkErrorSuggestion => 'Überprüfe deine Internetverbindung';

  @override
  String get logTrackNotFoundDescription =>
      'Einige Titel konnten auf Download-Diensten nicht gefunden werden';

  @override
  String get logTrackNotFoundSuggestion =>
      'Der Titel ist möglicherweise nicht in verlustfreier Qualität verfügbar';

  @override
  String logTotalErrors(int count) {
    return 'Gesamte Fehler: $count';
  }

  @override
  String logAffected(String domains) {
    return 'Betroffen: $domains';
  }

  @override
  String logEntriesFiltered(int count) {
    return 'Einträge ($count gefiltert)';
  }

  @override
  String logEntries(int count) {
    return 'Entries ($count)';
  }

  @override
  String get credentialsTitle => 'Spotify Credentials';

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
  String get lyricsModeEmbed => 'In Datei einbinden';

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
      'Lyrics einbinden und als .lrc speichern';

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
  String get qualityLossy => 'Lossy';

  @override
  String get qualityLossyMp3Subtitle => 'MP3 320kbps (converted from FLAC)';

  @override
  String get qualityLossyOpusSubtitle => 'Opus 128kbps (converted from FLAC)';

  @override
  String get enableLossyOption => 'Enable Lossy Option';

  @override
  String get enableLossyOptionSubtitleOn => 'Lossy quality option is available';

  @override
  String get enableLossyOptionSubtitleOff =>
      'Downloads FLAC then converts to lossy format';

  @override
  String get lossyFormat => 'Lossy Format';

  @override
  String get lossyFormatDescription => 'Choose the lossy format for conversion';

  @override
  String get lossyFormatMp3Subtitle => '320kbps, best compatibility';

  @override
  String get lossyFormatOpusSubtitle =>
      '128kbps, better quality at smaller size';

  @override
  String get qualityNote =>
      'Actual quality depends on track availability from the service';

  @override
  String get youtubeQualityNote =>
      'YouTube provides lossy audio only. Not part of lossless fallback.';

  @override
  String get youtubeOpusBitrateTitle => 'YouTube Opus Bitrate';

  @override
  String get youtubeMp3BitrateTitle => 'YouTube MP3 Bitrate';

  @override
  String youtubeBitrateSubtitle(int bitrate, int min, int max) {
    return '${bitrate}kbps ($min-$max)';
  }

  @override
  String youtubeBitrateInputHelp(int min, int max) {
    return 'Enter custom bitrate ($min-$max kbps)';
  }

  @override
  String get youtubeBitrateFieldLabel => 'Bitrate (kbps)';

  @override
  String youtubeBitrateValidationError(int min, int max) {
    return 'Bitrate must be between $min and $max kbps';
  }

  @override
  String get downloadAskBeforeDownload => 'Ask Before Download';

  @override
  String get downloadDirectory => 'Download Directory';

  @override
  String get downloadSeparateSinglesFolder => 'Separate Singles Folder';

  @override
  String get downloadAlbumFolderStructure => 'Album Folder Structure';

  @override
  String get downloadUseAlbumArtistForFolders => 'Use Album Artist for folders';

  @override
  String get downloadUseAlbumArtistForFoldersAlbumSubtitle =>
      'Artist folders use Album Artist when available';

  @override
  String get downloadUseAlbumArtistForFoldersTrackSubtitle =>
      'Artist folders use Track Artist only';

  @override
  String get downloadUsePrimaryArtistOnly => 'Primary artist only for folders';

  @override
  String get downloadUsePrimaryArtistOnlyEnabled =>
      'Featured artists removed from folder name (e.g. Justin Bieber, Quavo → Justin Bieber)';

  @override
  String get downloadUsePrimaryArtistOnlyDisabled =>
      'Full artist string used for folder name';

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
  String get queueExportFailed => 'Export';

  @override
  String get queueExportFailedSuccess =>
      'Failed downloads exported to TXT file';

  @override
  String get queueExportFailedClear => 'Clear Failed';

  @override
  String get queueExportFailedError => 'Failed to export downloads';

  @override
  String get settingsAutoExportFailed => 'Auto-export failed downloads';

  @override
  String get settingsAutoExportFailedSubtitle =>
      'Save failed downloads to TXT file automatically';

  @override
  String get settingsDownloadNetwork => 'Download Network';

  @override
  String get settingsDownloadNetworkAny => 'WiFi + Mobile Data';

  @override
  String get settingsDownloadNetworkWifiOnly => 'WiFi Only';

  @override
  String get settingsDownloadNetworkSubtitle =>
      'Choose which network to use for downloads. When set to WiFi Only, downloads will pause on mobile data.';

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
  String get recentEmpty => 'No recent items yet';

  @override
  String get recentShowAllDownloads => 'Show All Downloads';

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
  String get sectionStorageAccess => 'Storage Access';

  @override
  String get allFilesAccess => 'All Files Access';

  @override
  String get allFilesAccessEnabledSubtitle => 'Can write to any folder';

  @override
  String get allFilesAccessDisabledSubtitle => 'Limited to media folders only';

  @override
  String get allFilesAccessDescription =>
      'Enable this if you encounter write errors when saving to custom folders. Android 13+ restricts access to certain directories by default.';

  @override
  String get allFilesAccessDeniedMessage =>
      'Permission was denied. Please enable \'All files access\' manually in system settings.';

  @override
  String get allFilesAccessDisabledMessage =>
      'All Files Access disabled. The app will use limited storage access.';

  @override
  String get settingsLocalLibrary => 'Local Library';

  @override
  String get settingsLocalLibrarySubtitle => 'Scan music & detect duplicates';

  @override
  String get settingsCache => 'Storage & Cache';

  @override
  String get settingsCacheSubtitle => 'View size and clear cached data';

  @override
  String get libraryTitle => 'Local Library';

  @override
  String get libraryStatus => 'Library Status';

  @override
  String get libraryScanSettings => 'Scan Settings';

  @override
  String get libraryEnableLocalLibrary => 'Enable Local Library';

  @override
  String get libraryEnableLocalLibrarySubtitle =>
      'Scan and track your existing music';

  @override
  String get libraryFolder => 'Library Folder';

  @override
  String get libraryFolderHint => 'Tap to select folder';

  @override
  String get libraryShowDuplicateIndicator => 'Show Duplicate Indicator';

  @override
  String get libraryShowDuplicateIndicatorSubtitle =>
      'Show when searching for existing tracks';

  @override
  String get libraryActions => 'Actions';

  @override
  String get libraryScan => 'Scan Library';

  @override
  String get libraryScanSubtitle => 'Scan for audio files';

  @override
  String get libraryScanSelectFolderFirst => 'Select a folder first';

  @override
  String get libraryCleanupMissingFiles => 'Cleanup Missing Files';

  @override
  String get libraryCleanupMissingFilesSubtitle =>
      'Remove entries for files that no longer exist';

  @override
  String get libraryClear => 'Clear Library';

  @override
  String get libraryClearSubtitle => 'Remove all scanned tracks';

  @override
  String get libraryClearConfirmTitle => 'Clear Library';

  @override
  String get libraryClearConfirmMessage =>
      'This will remove all scanned tracks from your library. Your actual music files will not be deleted.';

  @override
  String get libraryAbout => 'About Local Library';

  @override
  String get libraryAboutDescription =>
      'Scans your existing music collection to detect duplicates when downloading. Supports FLAC, M4A, MP3, Opus, and OGG formats. Metadata is read from file tags when available.';

  @override
  String libraryTracksCount(int count) {
    return '$count tracks';
  }

  @override
  String libraryLastScanned(String time) {
    return 'Last scanned: $time';
  }

  @override
  String get libraryLastScannedNever => 'Never';

  @override
  String get libraryScanning => 'Scanning...';

  @override
  String libraryScanProgress(String progress, int total) {
    return '$progress% of $total files';
  }

  @override
  String get libraryInLibrary => 'In Library';

  @override
  String libraryRemovedMissingFiles(int count) {
    return 'Removed $count missing files from library';
  }

  @override
  String get libraryCleared => 'Library cleared';

  @override
  String get libraryStorageAccessRequired => 'Storage Access Required';

  @override
  String get libraryStorageAccessMessage =>
      'SpotiFLAC needs storage access to scan your music library. Please grant permission in settings.';

  @override
  String get libraryFolderNotExist => 'Selected folder does not exist';

  @override
  String get librarySourceDownloaded => 'Downloaded';

  @override
  String get librarySourceLocal => 'Local';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryFilterDownloaded => 'Downloaded';

  @override
  String get libraryFilterLocal => 'Local';

  @override
  String get libraryFilterTitle => 'Filters';

  @override
  String get libraryFilterReset => 'Reset';

  @override
  String get libraryFilterApply => 'Apply';

  @override
  String get libraryFilterSource => 'Source';

  @override
  String get libraryFilterQuality => 'Quality';

  @override
  String get libraryFilterQualityHiRes => 'Hi-Res (24bit)';

  @override
  String get libraryFilterQualityCD => 'CD (16bit)';

  @override
  String get libraryFilterQualityLossy => 'Lossy';

  @override
  String get libraryFilterFormat => 'Format';

  @override
  String get libraryFilterDate => 'Date Added';

  @override
  String get libraryFilterDateToday => 'Today';

  @override
  String get libraryFilterDateWeek => 'This Week';

  @override
  String get libraryFilterDateMonth => 'This Month';

  @override
  String get libraryFilterDateYear => 'This Year';

  @override
  String get libraryFilterSort => 'Sort';

  @override
  String get libraryFilterSortLatest => 'Latest';

  @override
  String get libraryFilterSortOldest => 'Oldest';

  @override
  String libraryFilterActive(int count) {
    return '$count filter(s) active';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get storageSwitchTitle => 'Switch Storage Mode';

  @override
  String get storageSwitchToSafTitle => 'Switch to SAF Storage?';

  @override
  String get storageSwitchToAppTitle => 'Switch to App Storage?';

  @override
  String get storageSwitchToSafMessage =>
      'Your existing downloads will remain in the current location and stay accessible.\n\nNew downloads will be saved to your selected SAF folder.';

  @override
  String get storageSwitchToAppMessage =>
      'Your existing downloads will remain in the current SAF location and stay accessible.\n\nNew downloads will be saved to Music/SpotiFLAC folder.';

  @override
  String get storageSwitchExistingDownloads => 'Existing Downloads';

  @override
  String storageSwitchExistingDownloadsInfo(int count, String mode) {
    return '$count tracks in $mode storage';
  }

  @override
  String get storageSwitchNewDownloads => 'New Downloads';

  @override
  String storageSwitchNewDownloadsLocation(String location) {
    return 'Will be saved to: $location';
  }

  @override
  String get storageSwitchContinue => 'Continue';

  @override
  String get storageSwitchSelectFolder => 'Select SAF Folder';

  @override
  String get storageAppStorage => 'App Storage';

  @override
  String get storageSafStorage => 'SAF Storage';

  @override
  String storageModeBadge(String mode) {
    return 'Storage: $mode';
  }

  @override
  String get storageStatsTitle => 'Storage Statistics';

  @override
  String storageStatsAppCount(int count) {
    return '$count tracks in App Storage';
  }

  @override
  String storageStatsSafCount(int count) {
    return '$count tracks in SAF Storage';
  }

  @override
  String get storageModeInfo => 'Your files are stored in multiple locations';

  @override
  String get tutorialWelcomeTitle => 'Welcome to SpotiFLAC!';

  @override
  String get tutorialWelcomeDesc =>
      'Let\'s learn how to download your favorite music in lossless quality. This quick tutorial will show you the basics.';

  @override
  String get tutorialWelcomeTip1 =>
      'Download music from Spotify, Deezer, or paste any supported URL';

  @override
  String get tutorialWelcomeTip2 =>
      'Get FLAC quality audio from Tidal, Qobuz, or Amazon Music';

  @override
  String get tutorialWelcomeTip3 =>
      'Automatic metadata, cover art, and lyrics embedding';

  @override
  String get tutorialSearchTitle => 'Finding Music';

  @override
  String get tutorialSearchDesc =>
      'There are two easy ways to find music you want to download.';

  @override
  String get tutorialSearchTip1 =>
      'Paste a Spotify or Deezer URL directly in the search box';

  @override
  String get tutorialSearchTip2 =>
      'Or type the song name, artist, or album to search';

  @override
  String get tutorialSearchTip3 =>
      'Supports tracks, albums, playlists, and artist pages';

  @override
  String get tutorialDownloadTitle => 'Downloading Music';

  @override
  String get tutorialDownloadDesc =>
      'Downloading music is simple and fast. Here\'s how it works.';

  @override
  String get tutorialDownloadTip1 =>
      'Tap the download button next to any track to start downloading';

  @override
  String get tutorialDownloadTip2 =>
      'Choose your preferred quality (FLAC, Hi-Res, or MP3)';

  @override
  String get tutorialDownloadTip3 =>
      'Download entire albums or playlists with one tap';

  @override
  String get tutorialLibraryTitle => 'Your Library';

  @override
  String get tutorialLibraryDesc =>
      'All your downloaded music is organized in the Library tab.';

  @override
  String get tutorialLibraryTip1 =>
      'View download progress and queue in the Library tab';

  @override
  String get tutorialLibraryTip2 =>
      'Tap any track to play it with your music player';

  @override
  String get tutorialLibraryTip3 =>
      'Switch between list and grid view for better browsing';

  @override
  String get tutorialExtensionsTitle => 'Extensions';

  @override
  String get tutorialExtensionsDesc =>
      'Extend the app\'s capabilities with community extensions.';

  @override
  String get tutorialExtensionsTip1 =>
      'Browse the Store tab to discover useful extensions';

  @override
  String get tutorialExtensionsTip2 =>
      'Add new download providers or search sources';

  @override
  String get tutorialExtensionsTip3 =>
      'Get lyrics, enhanced metadata, and more features';

  @override
  String get tutorialSettingsTitle => 'Customize Your Experience';

  @override
  String get tutorialSettingsDesc =>
      'Personalize the app in Settings to match your preferences.';

  @override
  String get tutorialSettingsTip1 =>
      'Change download location and folder organization';

  @override
  String get tutorialSettingsTip2 =>
      'Set default audio quality and format preferences';

  @override
  String get tutorialSettingsTip3 => 'Customize app theme and appearance';

  @override
  String get tutorialReadyMessage =>
      'You\'re all set! Start downloading your favorite music now.';

  @override
  String get tutorialExample => 'EXAMPLE';

  @override
  String get libraryForceFullScan => 'Force Full Scan';

  @override
  String get libraryForceFullScanSubtitle => 'Rescan all files, ignoring cache';

  @override
  String get cleanupOrphanedDownloads => 'Cleanup Orphaned Downloads';

  @override
  String get cleanupOrphanedDownloadsSubtitle =>
      'Remove history entries for files that no longer exist';

  @override
  String cleanupOrphanedDownloadsResult(int count) {
    return 'Removed $count orphaned entries from history';
  }

  @override
  String get cleanupOrphanedDownloadsNone => 'No orphaned entries found';

  @override
  String get cacheTitle => 'Storage & Cache';

  @override
  String get cacheSummaryTitle => 'Cache overview';

  @override
  String get cacheSummarySubtitle =>
      'Clearing cache will not remove downloaded music files.';

  @override
  String cacheEstimatedTotal(String size) {
    return 'Estimated cache usage: $size';
  }

  @override
  String get cacheSectionStorage => 'Cached Data';

  @override
  String get cacheSectionMaintenance => 'Maintenance';

  @override
  String get cacheAppDirectory => 'App cache directory';

  @override
  String get cacheAppDirectoryDesc =>
      'HTTP responses, WebView data, and other temporary app data.';

  @override
  String get cacheTempDirectory => 'Temporary directory';

  @override
  String get cacheTempDirectoryDesc =>
      'Temporary files from downloads and audio conversion.';

  @override
  String get cacheCoverImage => 'Cover image cache';

  @override
  String get cacheCoverImageDesc =>
      'Downloaded album and track cover art. Will re-download when viewed.';

  @override
  String get cacheLibraryCover => 'Library cover cache';

  @override
  String get cacheLibraryCoverDesc =>
      'Cover art extracted from local music files. Will re-extract on next scan.';

  @override
  String get cacheExploreFeed => 'Explore feed cache';

  @override
  String get cacheExploreFeedDesc =>
      'Explore tab content (new releases, trending). Will refresh on next visit.';

  @override
  String get cacheTrackLookup => 'Track lookup cache';

  @override
  String get cacheTrackLookupDesc =>
      'Spotify/Deezer track ID lookups. Clearing may slow next few searches.';

  @override
  String get cacheCleanupUnusedDesc =>
      'Remove orphaned download history and library entries for missing files.';

  @override
  String get cacheNoData => 'No cached data';

  @override
  String cacheSizeWithFiles(String size, int count) {
    return '$size in $count files';
  }

  @override
  String cacheSizeOnly(String size) {
    return '$size';
  }

  @override
  String cacheEntries(int count) {
    return '$count entries';
  }

  @override
  String cacheClearSuccess(String target) {
    return 'Cleared: $target';
  }

  @override
  String get cacheClearConfirmTitle => 'Clear cache?';

  @override
  String cacheClearConfirmMessage(String target) {
    return 'This will clear cached data for $target. Downloaded music files will not be deleted.';
  }

  @override
  String get cacheClearAllConfirmTitle => 'Clear all cache?';

  @override
  String get cacheClearAllConfirmMessage =>
      'This will clear all cache categories on this page. Downloaded music files will not be deleted.';

  @override
  String get cacheClearAll => 'Clear all cache';

  @override
  String get cacheCleanupUnused => 'Cleanup unused data';

  @override
  String get cacheCleanupUnusedSubtitle =>
      'Remove orphaned download history and missing library entries';

  @override
  String cacheCleanupResult(int downloadCount, int libraryCount) {
    return 'Cleanup completed: $downloadCount orphaned downloads, $libraryCount missing library entries';
  }

  @override
  String get cacheRefreshStats => 'Refresh stats';

  @override
  String get trackSaveCoverArt => 'Save Cover Art';

  @override
  String get trackSaveCoverArtSubtitle => 'Save album art as .jpg file';

  @override
  String get trackSaveLyrics => 'Save Lyrics (.lrc)';

  @override
  String get trackSaveLyricsSubtitle => 'Fetch and save lyrics as .lrc file';

  @override
  String get trackSaveLyricsProgress => 'Saving lyrics...';

  @override
  String get trackReEnrich => 'Re-enrich Metadata';

  @override
  String get trackReEnrichSubtitle =>
      'Re-embed metadata without re-downloading';

  @override
  String get trackReEnrichOnlineSubtitle =>
      'Search metadata online and embed into file';

  @override
  String get trackEditMetadata => 'Edit Metadata';

  @override
  String trackCoverSaved(String fileName) {
    return 'Cover art saved to $fileName';
  }

  @override
  String get trackCoverNoSource => 'No cover art source available';

  @override
  String trackLyricsSaved(String fileName) {
    return 'Lyrics saved to $fileName';
  }

  @override
  String get trackReEnrichProgress => 'Re-enriching metadata...';

  @override
  String get trackReEnrichSearching => 'Searching metadata online...';

  @override
  String get trackReEnrichSuccess => 'Metadata re-enriched successfully';

  @override
  String get trackReEnrichFfmpegFailed => 'FFmpeg metadata embed failed';

  @override
  String trackSaveFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get trackConvertFormat => 'Convert Format';

  @override
  String get trackConvertFormatSubtitle => 'Convert to MP3 or Opus';

  @override
  String get trackConvertTitle => 'Convert Audio';

  @override
  String get trackConvertTargetFormat => 'Target Format';

  @override
  String get trackConvertBitrate => 'Bitrate';

  @override
  String get trackConvertConfirmTitle => 'Confirm Conversion';

  @override
  String trackConvertConfirmMessage(
    String sourceFormat,
    String targetFormat,
    String bitrate,
  ) {
    return 'Convert from $sourceFormat to $targetFormat at $bitrate?\n\nThe original file will be deleted after conversion.';
  }

  @override
  String get trackConvertConverting => 'Converting audio...';

  @override
  String trackConvertSuccess(String format) {
    return 'Converted to $format successfully';
  }

  @override
  String get trackConvertFailed => 'Conversion failed';
}
