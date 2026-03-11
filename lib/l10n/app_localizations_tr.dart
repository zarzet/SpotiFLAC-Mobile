// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'SpotiFLAC';

  @override
  String get navHome => 'Ara';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get navStore => 'Dükkan';

  @override
  String get homeTitle => 'Ara';

  @override
  String get homeSubtitle => 'Spotify linki yapıştır veya isimle arat';

  @override
  String get homeSupports =>
      'Desteklenen linkler: Şarkı, Albüm, Çalma Listesi, Sanatçı linkleri';

  @override
  String get homeRecent => 'En son';

  @override
  String get historyFilterAll => 'Tümü';

  @override
  String get historyFilterAlbums => 'Albümler';

  @override
  String get historyFilterSingles => 'Single\'lar';

  @override
  String get historySearchHint => 'Arama geçmişi...';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsDownload => 'İndirme';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsOptions => 'Seçenekler';

  @override
  String get settingsExtensions => 'Eklentiler';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String get downloadTitle => 'İndirme';

  @override
  String get downloadAskQualitySubtitle =>
      'Her indirmeden önce kalite seçim ekranını göster';

  @override
  String get downloadFilenameFormat => 'Dosya adı formatı';

  @override
  String get downloadFolderOrganization => 'Dosya Organizasyonu';

  @override
  String get appearanceTitle => 'Görünüm';

  @override
  String get appearanceThemeSystem => 'Sistem';

  @override
  String get appearanceThemeLight => 'Açık';

  @override
  String get appearanceThemeDark => 'Koyu';

  @override
  String get appearanceDynamicColor => 'Dinamik Renk';

  @override
  String get appearanceDynamicColorSubtitle =>
      'Duvar kağıdının renklerini kullan';

  @override
  String get appearanceHistoryView => 'Geçmiş Düzeni';

  @override
  String get appearanceHistoryViewList => 'Liste';

  @override
  String get appearanceHistoryViewGrid => 'Izgara';

  @override
  String get optionsTitle => 'Seçenekler';

  @override
  String get optionsPrimaryProvider => 'Ana Kaynek';

  @override
  String get optionsPrimaryProviderSubtitle =>
      'Şarkı ismi aratılırken kullanılan kaynak.';

  @override
  String optionsUsingExtension(String extensionName) {
    return 'Kullanılan eklenti: $extensionName';
  }

  @override
  String get optionsSwitchBack =>
      'Dahili kaynaklara dönmek için Deezer veya Spotify\'a tıkla';

  @override
  String get optionsAutoFallback => 'Diğerlerini dene';

  @override
  String get optionsAutoFallbackSubtitle =>
      'İndirme başarısız olursa diğer hizmetleri dene';

  @override
  String get optionsUseExtensionProviders => 'Eklenti sağlayıcılarını kullan';

  @override
  String get optionsUseExtensionProvidersOn => 'Eklentiler ilk denenecek';

  @override
  String get optionsUseExtensionProvidersOff =>
      'Sadece dahili sağlayıcıları kullan';

  @override
  String get optionsEmbedLyrics => 'Şarkı Sözlerini Göm';

  @override
  String get optionsEmbedLyricsSubtitle =>
      'Senkronize şarkı sözlerini FLAC dosyalarına göm';

  @override
  String get optionsMaxQualityCover => 'En Yüksek Kapak Kalitesi';

  @override
  String get optionsMaxQualityCoverSubtitle =>
      'En yüksek kalitedeki albüm kapaklarını indir';

  @override
  String get optionsConcurrentDownloads => 'Eş Zamanlı İndirmeler';

  @override
  String get optionsConcurrentSequential => 'Sıralı (Birer birer)';

  @override
  String optionsConcurrentParallel(int count) {
    return 'Aynı anda $count indirme';
  }

  @override
  String get optionsConcurrentWarning =>
      'Aynı anda birden fazla indirme sınırlamaya takılabilir';

  @override
  String get optionsExtensionStore => 'Eklenti Dükkanı';

  @override
  String get optionsExtensionStoreSubtitle => 'Dükkan sekmesini altta göster';

  @override
  String get optionsCheckUpdates => 'Güncelleştirmeleri Denetle';

  @override
  String get optionsCheckUpdatesSubtitle => 'Yeni sürüm çıktığında bildir';

  @override
  String get optionsUpdateChannel => 'Güncelleme Kanalı';

  @override
  String get optionsUpdateChannelStable => 'Sadece stabil sürümler';

  @override
  String get optionsUpdateChannelPreview => 'Önizleme sürümlerini al';

  @override
  String get optionsUpdateChannelWarning =>
      'Önizleme sürümleri hatalar veya tamamlanmamış özellikler içerebilir';

  @override
  String get optionsClearHistory => 'İndirme Geçmişini Temizle';

  @override
  String get optionsClearHistorySubtitle =>
      'İndirilen bütün şarkıları geçmişten temizle';

  @override
  String get optionsDetailedLogging => 'Detaylı Günlükleme';

  @override
  String get optionsDetailedLoggingOn => 'Detaylı günlük kayıt ediliyor';

  @override
  String get optionsDetailedLoggingOff => 'Hata bildirmek için aç';

  @override
  String get optionsSpotifyCredentials => 'Spotify Kimlik Bilgileri';

  @override
  String optionsSpotifyCredentialsConfigured(String clientId) {
    return 'Client ID: $clientId...';
  }

  @override
  String get optionsSpotifyCredentialsRequired =>
      'Zorunlu - değiştirmek için tıkla';

  @override
  String get optionsSpotifyWarning =>
      'Spotify\'ın senin API kimlik bilgilerine ihtiyacı var. Onları developer.spotify.com\'dan alabilirsin';

  @override
  String get optionsSpotifyDeprecationWarning =>
      'Spotify search will be deprecated on March 3, 2026 due to Spotify API changes. Please switch to Deezer.';

  @override
  String get extensionsTitle => 'Eklentiler';

  @override
  String get extensionsDisabled => 'Devre Dışı';

  @override
  String extensionsVersion(String version) {
    return 'Versiyon $version';
  }

  @override
  String extensionsAuthor(String author) {
    return '$author tarafından';
  }

  @override
  String get extensionsUninstall => 'Kaldır';

  @override
  String get storeTitle => 'Eklenti Dükkanı';

  @override
  String get storeSearch => 'Eklenti ara...';

  @override
  String get storeInstall => 'Kur';

  @override
  String get storeInstalled => 'Kuruldu';

  @override
  String get storeUpdate => 'Güncelle';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String get aboutContributors => 'Katkıda Bulunanlar';

  @override
  String get aboutMobileDeveloper => 'Mobil versiyon geliştiricisi';

  @override
  String get aboutOriginalCreator => 'Orijinal SpotiFLAC\'ın kurucusu';

  @override
  String get aboutLogoArtist =>
      'Uygulama logomuzu yaratmış yetenekli sanatçımız!';

  @override
  String get aboutTranslators => 'Çevirmenler';

  @override
  String get aboutSpecialThanks => 'Özel teşekkür';

  @override
  String get aboutLinks => 'Linkler';

  @override
  String get aboutMobileSource => 'Mobil kaynak kodu';

  @override
  String get aboutPCSource => 'PC kaynak kodu';

  @override
  String get aboutReportIssue => 'Sorun bildir';

  @override
  String get aboutReportIssueSubtitle =>
      'Karşılaştığın herhangi bir problemi bildir';

  @override
  String get aboutFeatureRequest => 'Özellik isteği';

  @override
  String get aboutFeatureRequestSubtitle =>
      'Uygulama için yeni özellikler isteyin';

  @override
  String get aboutTelegramChannel => 'Telegram Kanalı';

  @override
  String get aboutTelegramChannelSubtitle => 'Duyurular ve güncellemeler';

  @override
  String get aboutTelegramChat => 'Telegram Grubu';

  @override
  String get aboutTelegramChatSubtitle => 'Diğer kullanıcılarla sohbet et';

  @override
  String get aboutSocial => 'Sosyal ağlar';

  @override
  String get aboutApp => 'Uygulama';

  @override
  String get aboutVersion => 'Versiyon';

  @override
  String get aboutBinimumDesc =>
      'QQDL ve HiFi API\'ın kurucusu. Bu API olmadan, Tidal indirmeleri olmazdı!';

  @override
  String get aboutSachinsenalDesc =>
      'Orijinal HiFi projesi kurucusu. Tidal entegrasyonun temeli!';

  @override
  String get aboutSjdonadoDesc =>
      'Creator of I Don\'t Have Spotify (IDHS). The fallback link resolver that saves the day!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'En iyi Qobuz streaming API\'ı. Yüksek kalite indirmeler bunun sayesinde!';

  @override
  String get aboutSpotiSaver => 'SpotiSaver';

  @override
  String get aboutSpotiSaverDesc =>
      'Tidal Hi-Res FLAC streaming endpoints. A key piece of the lossless puzzle!';

  @override
  String get aboutAppDescription =>
      'Spotify şarkılarını Tidal ve Qobuz\'den yüksek kalitede indir.';

  @override
  String get artistAlbums => 'Albümler';

  @override
  String get artistSingles => 'Single\'lar ve EP\'ler';

  @override
  String get artistCompilations => 'Derlemeler';

  @override
  String get artistPopular => 'Popüler';

  @override
  String artistMonthlyListeners(String count) {
    return 'Aylık $count dinleyici';
  }

  @override
  String get trackMetadataService => 'Hizmet';

  @override
  String get trackMetadataPlay => 'Oynat';

  @override
  String get trackMetadataShare => 'Paylaş';

  @override
  String get trackMetadataDelete => 'Sil';

  @override
  String get setupGrantPermission => 'İzin Ver';

  @override
  String get setupSkip => 'Şimdilik atla';

  @override
  String get setupStorageAccessRequired => 'Depolama Erişimi Gerekli';

  @override
  String get setupStorageAccessMessageAndroid11 =>
      'Android 11 ve sonrasında şarkıların seçili klasörünüze kaydedilebilmesi için \"Bütün dosyalara eriş\" iznine ihtiyaç var.';

  @override
  String get setupOpenSettings => 'Ayarları Aç';

  @override
  String get setupPermissionDeniedMessage =>
      'İzin reddedildi. Devam etmek için lütfen bütün izinleri verin.';

  @override
  String setupPermissionRequired(String permissionType) {
    return '$permissionType İzni Zorunlu';
  }

  @override
  String setupPermissionRequiredMessage(String permissionType) {
    return 'En iyi deneyim için $permissionType izni zorunludur. Bunu ayarlardan daha sonra değiştirebilirsiniz.';
  }

  @override
  String get setupUseDefaultFolder => 'Varsayılan Klasörü Kullan?';

  @override
  String get setupNoFolderSelected =>
      'Klasör seçilmedi. Varsayılan \"Music\" klasörünü kullanmak ister misiniz?';

  @override
  String get setupUseDefault => 'Varsayılanı Kullan';

  @override
  String get setupDownloadLocationTitle => 'İndirme Konumu';

  @override
  String get setupDownloadLocationIosMessage =>
      'iOS\'ta indirilenler uygulamanın \"Documents\" dosyasına kaydedilir. Onlara Dosyalar uygulamasından erişebilirsiniz.';

  @override
  String get setupAppDocumentsFolder => 'App Documents Folder';

  @override
  String get setupAppDocumentsFolderSubtitle =>
      'Tavsiye edilen - Dosyalar uygulamasından erişilebilir';

  @override
  String get setupChooseFromFiles => 'Dosyalar\'dan Seç';

  @override
  String get setupChooseFromFilesSubtitle => 'iCloud veya başka konum seç';

  @override
  String get setupIosEmptyFolderWarning =>
      'iOS\'un sınırlaması: Boş klasörler seçilemiyor. İçinde en az bir dosya bulunan bir klasör seçin.';

  @override
  String get setupIcloudNotSupported =>
      'iCloud Drive is not supported. Please use the app Documents folder.';

  @override
  String get setupDownloadInFlac => 'Spotify şarkılarını FLAC olarak indirin';

  @override
  String get setupStorageGranted => 'Depolama İzni Verildi!';

  @override
  String get setupStorageRequired => 'Depolama İzni Gerekli';

  @override
  String get setupStorageDescription =>
      'SpotiFLAC\'ın şarkılarınızı kaydetmek için depolama iznine ihtiyacı var.';

  @override
  String get setupNotificationGranted => 'Bildirim İzni Verildi!';

  @override
  String get setupNotificationEnable => 'Bildirimleri Etkinleştir';

  @override
  String get setupFolderChoose => 'İndirilecek Klasörü Seç';

  @override
  String get setupFolderDescription =>
      'İndirdiğin şarkıların kaydedileceği klasörü seç.';

  @override
  String get setupSelectFolder => 'Klasör Seç';

  @override
  String get setupEnableNotifications => 'Bildirimleri Etkinleştir';

  @override
  String get setupNotificationBackgroundDescription =>
      'İndirmelerin durumu hakkında bildirim al. Bunu açmak uygulama arka plandayken indirmelerinizi takip etmenizi sağlar.';

  @override
  String get setupSkipForNow => 'Şimdilik atla';

  @override
  String get setupNext => 'Sıradaki';

  @override
  String get setupGetStarted => 'Başla';

  @override
  String get setupAllowAccessToManageFiles =>
      'Lütfen bir sonraki ekranda \"Bütün dosyalara eriş\" iznini sağlayın.';

  @override
  String get dialogCancel => 'İptal';

  @override
  String get dialogSave => 'Kaydet';

  @override
  String get dialogDelete => 'Sil';

  @override
  String get dialogRetry => 'Yeniden dene';

  @override
  String get dialogClear => 'Temizle';

  @override
  String get dialogDone => 'Tamamlandı';

  @override
  String get dialogImport => 'İçe aktar';

  @override
  String get dialogDiscard => 'Vazgeç';

  @override
  String get dialogRemove => 'Kaldır';

  @override
  String get dialogUninstall => 'Kaldır';

  @override
  String get dialogDiscardChanges => 'Değişiklikleri İptal Et?';

  @override
  String get dialogUnsavedChanges =>
      'Kaydedilmeyen değişiklikler mevcut. Bu değişiklikleri iptal etmek istiyor musunuz?';

  @override
  String get dialogClearAll => 'Tümünü Temizle';

  @override
  String get dialogRemoveExtension => 'Eklentiyi Kaldır';

  @override
  String get dialogRemoveExtensionMessage =>
      'Bu eklentiyi kaldırmak istediğine emin misin? Bu işlem geri alınamaz.';

  @override
  String get dialogUninstallExtension => 'Eklentiyi Kaldır?';

  @override
  String dialogUninstallExtensionMessage(String extensionName) {
    return '$extensionName eklentisini kaldırmak istediğine emin misin?';
  }

  @override
  String get dialogClearHistoryTitle => 'Geçmişi Temizle';

  @override
  String get dialogClearHistoryMessage =>
      'Tüm indirme geçmişini temizlemek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get dialogDeleteSelectedTitle => 'Seçileni Sil';

  @override
  String dialogDeleteSelectedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şarkıyı',
      one: 'şarkıyı',
    );
    return '$count $_temp0 geçmişten silmeye emin misiniz?\n\nBu işlem seçilenleri cihazınızdan da silecektir.';
  }

  @override
  String get dialogImportPlaylistTitle => 'Çalma listesini içe aktar';

  @override
  String dialogImportPlaylistMessage(int count) {
    return 'CSV\'de $count şarkı bulundu. İndirme kuyruğuna ekle?';
  }

  @override
  String csvImportTracks(int count) {
    return 'CSV\'den $count şarkı';
  }

  @override
  String snackbarAddedToQueue(String trackName) {
    return '\"$trackName\" kuyruğa eklendi';
  }

  @override
  String snackbarAddedTracksToQueue(int count) {
    return '$count şarkı kuyruğa eklendi';
  }

  @override
  String snackbarAlreadyDownloaded(String trackName) {
    return '\"$trackName\" zaten indirilmiş';
  }

  @override
  String snackbarAlreadyInLibrary(String trackName) {
    return '\"$trackName\" already exists in your library';
  }

  @override
  String get snackbarHistoryCleared => 'Geçmiş temizlendi';

  @override
  String get snackbarCredentialsSaved => 'Kimlik bilgileri kaydedildi';

  @override
  String get snackbarCredentialsCleared => 'Kimlik bilgileri temizlendi';

  @override
  String snackbarDeletedTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şarkı',
      one: 'şarkı',
    );
    return '$count $_temp0 silindi';
  }

  @override
  String snackbarCannotOpenFile(String error) {
    return 'Dosya açılamadı: $error';
  }

  @override
  String get snackbarFillAllFields => 'Lütfen tüm alanları doldurun';

  @override
  String get snackbarViewQueue => 'Kuyruğu Görüntüle';

  @override
  String snackbarUrlCopied(String platform) {
    return '$platform Bağlantı panoya kopyalandı';
  }

  @override
  String get snackbarFileNotFound => 'Dosya bulunamadı';

  @override
  String get snackbarSelectExtFile => 'Lütfen .spotiflac-ext dosyasını seçin';

  @override
  String get snackbarProviderPrioritySaved => 'Sağlayıcı önceliği kaydedildi';

  @override
  String get snackbarMetadataProviderSaved =>
      'Metadata sağlayıcı önceliği kaydedildi';

  @override
  String snackbarExtensionInstalled(String extensionName) {
    return '$extensionName yüklendi.';
  }

  @override
  String snackbarExtensionUpdated(String extensionName) {
    return '$extensionName güncellendi.';
  }

  @override
  String get snackbarFailedToInstall => 'Eklenti yüklenirken hata oluştu';

  @override
  String get snackbarFailedToUpdate => 'Eklenti güncellenirken hata oluştu';

  @override
  String get errorRateLimited => 'Aşırı istek gönderildi';

  @override
  String get errorRateLimitedMessage =>
      'Çok fazla istek. Lütfen arama yapmadan önce biraz bekleyin.';

  @override
  String get errorNoTracksFound => 'Parça bulunamadı';

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
    return '$item yüklenemedi: Eksik eklenti kaynağı';
  }

  @override
  String get actionPause => 'Duraklat';

  @override
  String get actionResume => 'Devam et';

  @override
  String get actionCancel => 'Vazgeç';

  @override
  String get actionSelectAll => 'Tümünü Seç';

  @override
  String get actionDeselect => 'Seçimi kaldır';

  @override
  String get actionRemoveCredentials => 'Özellikleri kaldır';

  @override
  String get actionSaveCredentials => 'Özellikleri kaydet';

  @override
  String selectionSelected(int count) {
    return '$count seçildi';
  }

  @override
  String get selectionAllSelected => 'Tüm parçalar seçildi';

  @override
  String get selectionSelectToDelete => 'Silinecek parçaları seçin';

  @override
  String progressFetchingMetadata(int current, int total) {
    return 'Meta verileri alınıyor... $current/$total';
  }

  @override
  String get progressReadingCsv => 'CSV okunuyor...';

  @override
  String get searchSongs => 'Şarkılar';

  @override
  String get searchArtists => 'Sanatçılar';

  @override
  String get searchAlbums => 'Albümler';

  @override
  String get searchPlaylists => 'Çalma Listeleri';

  @override
  String get tooltipPlay => 'Oynat';

  @override
  String get filenameFormat => 'Dosya adı formatı';

  @override
  String get filenameShowAdvancedTags => 'Show advanced tags';

  @override
  String get filenameShowAdvancedTagsDescription =>
      'Enable formatted tags for track padding and date patterns';

  @override
  String get folderOrganizationNone => 'Organizasyon yok';

  @override
  String get folderOrganizationByPlaylist => 'By Playlist';

  @override
  String get folderOrganizationByPlaylistSubtitle =>
      'Separate folder for each playlist';

  @override
  String get folderOrganizationByArtist => 'Sanatçıya Göre';

  @override
  String get folderOrganizationByAlbum => 'Albüme Göre';

  @override
  String get folderOrganizationByArtistAlbum => 'Sanatçı/Albüm';

  @override
  String get folderOrganizationDescription =>
      'İndirilenleri klasörlerle organize et';

  @override
  String get folderOrganizationNoneSubtitle =>
      'Her şey indirilen dosyasına kaydedilecek';

  @override
  String get folderOrganizationByArtistSubtitle =>
      'Her sanatçı için ayrı klasör';

  @override
  String get folderOrganizationByAlbumSubtitle => 'Her albüm için ayrı klasör';

  @override
  String get folderOrganizationByArtistAlbumSubtitle =>
      'Sanatçı klasörlerinin içinde Albüm klasörleri';

  @override
  String get updateAvailable => 'Güncelleme Mevcut';

  @override
  String get updateLater => 'Daha Sonra';

  @override
  String get updateStartingDownload => 'İndirme başlıyor...';

  @override
  String get updateDownloadFailed => 'İndirme başarısız';

  @override
  String get updateFailedMessage => 'Güncelleme indirilemedi';

  @override
  String get updateNewVersionReady => 'Yeni bir sürüm hazır';

  @override
  String get updateCurrent => 'Şimdiki';

  @override
  String get updateNew => 'Yeni';

  @override
  String get updateDownloading => 'İndiriliyor...';

  @override
  String get updateWhatsNew => 'Yenilikler';

  @override
  String get updateDownloadInstall => 'İndir & Yükle';

  @override
  String get updateDontRemind => 'Bir daha sorma';

  @override
  String get providerPriorityTitle => 'İndirme hizmetleri öncelik sırası';

  @override
  String get providerPriorityDescription =>
      'İndirme hizmetlerini sıralamak için kaydır. Uygulama şarkı indirirken hizmetleri yukarıdan aşağıya doğru deneyecektir.';

  @override
  String get providerPriorityInfo =>
      'Eğer bir şarkı ilk hizmette mevcut değilse uygulama otomatik olarak bir sonrakini deneyecektir.';

  @override
  String get providerBuiltIn => 'Dahili';

  @override
  String get providerExtension => 'Eklenti';

  @override
  String get metadataProviderPriorityTitle => 'Metadata Önceliği';

  @override
  String get metadataProviderPriorityDescription =>
      'Metadata sağlayıcılarını sıralamak için kaydır. Uygulama şarkı ararken ve metadata alırken sağlayıcıları yukarıdan aşağıya doğru deneyecektir.';

  @override
  String get metadataProviderPriorityInfo =>
      'Deezer\'ın istek sınırı yok ve birincil olarak önerilir. Spotify çok fazla istekten sonra sınırlama yapabilir.';

  @override
  String get metadataNoRateLimits => 'İstek sınırı yok';

  @override
  String get metadataMayRateLimit => 'Sınırlama yapabilir';

  @override
  String get logTitle => 'Kayıtlar';

  @override
  String get logCopied => 'Kayıtlar panoya kopyalandı';

  @override
  String get logSearchHint => 'Kayıtları Ara...';

  @override
  String get logFilterLevel => 'Seviye';

  @override
  String get logFilterSection => 'Filtre';

  @override
  String get logShareLogs => 'Kayıtları paylaş';

  @override
  String get logClearLogs => 'Kayıtları temizle';

  @override
  String get logClearLogsTitle => 'Kayıtları temizle';

  @override
  String get logClearLogsMessage =>
      'Tüm kayıtları temizlemek istediğinize emin misiniz?';

  @override
  String get logFilterBySeverity => 'Kayıtları önem derecesine göre filtrele';

  @override
  String get logNoLogsYet => 'Henüz kayıt yok';

  @override
  String get logNoLogsYetSubtitle =>
      'Uygulamayı kullandıkça kayıtlar burada görünecek';

  @override
  String logEntriesFiltered(int count) {
    return 'Entries ($count filtered)';
  }

  @override
  String logEntries(int count) {
    return 'Entries ($count)';
  }

  @override
  String get credentialsTitle => 'Spotify Kimlik Bilgileri';

  @override
  String get credentialsDescription =>
      'Kendi Spotify uygulama kotanızı kullanmak için Client ID ve Secret girin.';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Client ID yapıştır';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => 'Client Secret yapıştır';

  @override
  String get channelStable => 'Kararlı';

  @override
  String get channelPreview => 'Önizleme';

  @override
  String get sectionSearchSource => 'Arama Kaynağı';

  @override
  String get sectionDownload => 'İndirme';

  @override
  String get sectionPerformance => 'Performans';

  @override
  String get sectionApp => 'Uygulama';

  @override
  String get sectionData => 'Veri';

  @override
  String get sectionDebug => 'Hata Ayıklama';

  @override
  String get sectionService => 'Hizmet';

  @override
  String get sectionAudioQuality => 'Ses Kalitesi';

  @override
  String get sectionFileSettings => 'Dosya Ayarları';

  @override
  String get sectionLyrics => 'Şarkı Sözleri';

  @override
  String get lyricsMode => 'Şarkı Sözü Modu';

  @override
  String get lyricsModeDescription =>
      'Şarkı sözlerinin indirmelerle nasıl kaydedileceğini seçin';

  @override
  String get lyricsModeEmbed => 'Dosyaya göm';

  @override
  String get lyricsModeEmbedSubtitle =>
      'Şarkı sözleri FLAC metadata içinde saklanır';

  @override
  String get lyricsModeExternal => 'Harici .lrc dosyası';

  @override
  String get lyricsModeExternalSubtitle =>
      'Samsung Music gibi oynatıcılar için ayrı .lrc dosyası';

  @override
  String get lyricsModeBoth => 'Her ikisi';

  @override
  String get lyricsModeBothSubtitle => 'Göm ve .lrc dosyası kaydet';

  @override
  String get sectionColor => 'Renk';

  @override
  String get sectionTheme => 'Tema';

  @override
  String get sectionLayout => 'Düzen';

  @override
  String get sectionLanguage => 'Dil';

  @override
  String get appearanceLanguage => 'Uygulama Dili';

  @override
  String get settingsAppearanceSubtitle => 'Tema, renkler, görünüm';

  @override
  String get settingsDownloadSubtitle => 'Hizmet, kalite, dosya adı formatı';

  @override
  String get settingsOptionsSubtitle =>
      'Yedek, şarkı sözleri, kapak resmi, güncellemeler';

  @override
  String get settingsExtensionsSubtitle => 'İndirme sağlayıcılarını yönet';

  @override
  String get settingsLogsSubtitle =>
      'Hata ayıklama için uygulama kayıtlarını görüntüle';

  @override
  String get loadingSharedLink => 'Paylaşılan bağlantı yükleniyor...';

  @override
  String get pressBackAgainToExit => 'Çıkmak için tekrar geri basın';

  @override
  String downloadAllCount(int count) {
    return 'Tümünü İndir ($count)';
  }

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şarkı',
      one: '1 şarkı',
    );
    return '$_temp0';
  }

  @override
  String get trackCopyFilePath => 'Dosya yolunu kopyala';

  @override
  String get trackRemoveFromDevice => 'Cihazdan kaldır';

  @override
  String get trackLoadLyrics => 'Şarkı Sözlerini Yükle';

  @override
  String get trackMetadata => 'Metadata';

  @override
  String get trackFileInfo => 'Dosya Bilgisi';

  @override
  String get trackLyrics => 'Şarkı Sözleri';

  @override
  String get trackFileNotFound => 'Dosya bulunamadı';

  @override
  String get trackOpenInDeezer => 'Deezer\'da aç';

  @override
  String get trackOpenInSpotify => 'Spotify\'da aç';

  @override
  String get trackTrackName => 'Şarkı adı';

  @override
  String get trackArtist => 'Sanatçı';

  @override
  String get trackAlbumArtist => 'Albüm sanatçısı';

  @override
  String get trackAlbum => 'Albüm';

  @override
  String get trackTrackNumber => 'Şarkı numarası';

  @override
  String get trackDiscNumber => 'Disk numarası';

  @override
  String get trackDuration => 'Süre';

  @override
  String get trackAudioQuality => 'Ses kalitesi';

  @override
  String get trackReleaseDate => 'Yayın tarihi';

  @override
  String get trackGenre => 'Tür';

  @override
  String get trackLabel => 'Plak şirketi';

  @override
  String get trackCopyright => 'Telif hakkı';

  @override
  String get trackDownloaded => 'İndirildi';

  @override
  String get trackCopyLyrics => 'Şarkı sözlerini kopyala';

  @override
  String get trackLyricsNotAvailable => 'Bu şarkı için şarkı sözü mevcut değil';

  @override
  String get trackLyricsTimeout =>
      'İstek zaman aşımına uğradı. Daha sonra tekrar deneyin.';

  @override
  String get trackLyricsLoadFailed => 'Şarkı sözleri yüklenemedi';

  @override
  String get trackEmbedLyrics => 'Şarkı Sözlerini Göm';

  @override
  String get trackLyricsEmbedded => 'Şarkı sözleri başarıyla gömüldü';

  @override
  String get trackInstrumental => 'Enstrümantal şarkı';

  @override
  String get trackCopiedToClipboard => 'Panoya kopyalandı';

  @override
  String get trackDeleteConfirmTitle => 'Cihazdan kaldırılsın mı?';

  @override
  String get trackDeleteConfirmMessage =>
      'Bu işlem indirilen dosyayı kalıcı olarak silecek ve geçmişten kaldıracaktır.';

  @override
  String get dateToday => 'Bugün';

  @override
  String get dateYesterday => 'Dün';

  @override
  String dateDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String dateWeeksAgo(int count) {
    return '$count hafta önce';
  }

  @override
  String dateMonthsAgo(int count) {
    return '$count ay önce';
  }

  @override
  String get storeFilterAll => 'Tümü';

  @override
  String get storeFilterMetadata => 'Metadata';

  @override
  String get storeFilterDownload => 'İndirme';

  @override
  String get storeFilterUtility => 'Araç';

  @override
  String get storeFilterLyrics => 'Şarkı Sözleri';

  @override
  String get storeFilterIntegration => 'Entegrasyon';

  @override
  String get storeClearFilters => 'Filtreleri temizle';

  @override
  String get extensionDefaultProvider => 'Varsayılan (Deezer/Spotify)';

  @override
  String get extensionDefaultProviderSubtitle => 'Dahili aramayı kullan';

  @override
  String get extensionAuthor => 'Yazar';

  @override
  String get extensionId => 'ID';

  @override
  String get extensionError => 'Hata';

  @override
  String get extensionCapabilities => 'Yetenekler';

  @override
  String get extensionMetadataProvider => 'Metadata Sağlayıcı';

  @override
  String get extensionDownloadProvider => 'İndirme Sağlayıcı';

  @override
  String get extensionLyricsProvider => 'Şarkı Sözü Sağlayıcı';

  @override
  String get extensionUrlHandler => 'URL İşleyici';

  @override
  String get extensionQualityOptions => 'Kalite Seçenekleri';

  @override
  String get extensionPostProcessingHooks => 'İşlem Sonrası Kancalar';

  @override
  String get extensionPermissions => 'İzinler';

  @override
  String get extensionSettings => 'Ayarlar';

  @override
  String get extensionRemoveButton => 'Eklentiyi Kaldır';

  @override
  String get extensionUpdated => 'Güncellendi';

  @override
  String get extensionMinAppVersion => 'Min Uygulama Sürümü';

  @override
  String get extensionCustomTrackMatching => 'Özel Şarkı Eşleştirme';

  @override
  String get extensionPostProcessing => 'İşlem Sonrası';

  @override
  String extensionHooksAvailable(int count) {
    return '$count kanca mevcut';
  }

  @override
  String extensionPatternsCount(int count) {
    return '$count desen';
  }

  @override
  String extensionStrategy(String strategy) {
    return 'Strateji: $strategy';
  }

  @override
  String get extensionsProviderPrioritySection => 'Sağlayıcı Önceliği';

  @override
  String get extensionsInstalledSection => 'Yüklü Eklentiler';

  @override
  String get extensionsNoExtensions => 'Yüklü eklenti yok';

  @override
  String get extensionsNoExtensionsSubtitle =>
      'Yeni sağlayıcılar eklemek için .spotiflac-ext dosyalarını yükleyin';

  @override
  String get extensionsInstallButton => 'Eklenti Yükle';

  @override
  String get extensionsInfoTip =>
      'Eklentiler yeni metadata ve indirme sağlayıcıları ekleyebilir. Sadece güvenilir kaynaklardan eklenti yükleyin.';

  @override
  String get extensionsInstalledSuccess => 'Eklenti başarıyla yüklendi';

  @override
  String get extensionsDownloadPriority => 'İndirme Önceliği';

  @override
  String get extensionsDownloadPrioritySubtitle =>
      'İndirme hizmeti sırasını ayarla';

  @override
  String get extensionsNoDownloadProvider =>
      'İndirme sağlayıcısı olan eklenti yok';

  @override
  String get extensionsMetadataPriority => 'Metadata Önceliği';

  @override
  String get extensionsMetadataPrioritySubtitle =>
      'Arama ve metadata kaynağı sırasını ayarla';

  @override
  String get extensionsNoMetadataProvider =>
      'Metadata sağlayıcısı olan eklenti yok';

  @override
  String get extensionsSearchProvider => 'Arama Sağlayıcı';

  @override
  String get extensionsNoCustomSearch => 'Özel arama olan eklenti yok';

  @override
  String get extensionsSearchProviderDescription =>
      'Şarkı aramak için hangi hizmetin kullanılacağını seçin';

  @override
  String get extensionsCustomSearch => 'Özel arama';

  @override
  String get extensionsErrorLoading => 'Eklenti yüklenirken hata oluştu';

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
  String get downloadUsePrimaryArtistOnly => 'Primary artist only for folders';

  @override
  String get downloadUsePrimaryArtistOnlyEnabled =>
      'Featured artists removed from folder name (e.g. Justin Bieber, Quavo → Justin Bieber)';

  @override
  String get downloadUsePrimaryArtistOnlyDisabled =>
      'Full artist string used for folder name';

  @override
  String get downloadSelectQuality => 'Select Quality';

  @override
  String get downloadFrom => 'Download From';

  @override
  String get appearanceAmoledDark => 'AMOLED Dark';

  @override
  String get appearanceAmoledDarkSubtitle => 'Pure black background';

  @override
  String get queueClearAll => 'Clear All';

  @override
  String get queueClearAllMessage =>
      'Are you sure you want to clear all downloads?';

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
    return '$count şarkı kuyruğa eklendi';
  }

  @override
  String discographySkippedDownloaded(int added, int skipped) {
    return '$added eklendi, $skipped zaten indirilmiş';
  }

  @override
  String get discographyNoAlbums => 'Albüm mevcut değil';

  @override
  String get discographyFailedToFetch => 'Bazı albümler alınamadı';

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
  String libraryTracksUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return '$_temp0';
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
  String get libraryFilterSort => 'Sort';

  @override
  String get libraryFilterSortLatest => 'Latest';

  @override
  String get libraryFilterSortOldest => 'Oldest';

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
  String get tutorialWelcomeTitle => 'Welcome to SpotiFLAC!';

  @override
  String get tutorialWelcomeDesc =>
      'Let\'s learn how to download your favorite music in lossless quality. This quick tutorial will show you the basics.';

  @override
  String get tutorialWelcomeTip1 =>
      'Download music from Spotify, Deezer, or paste any supported URL';

  @override
  String get tutorialWelcomeTip2 =>
      'Tidal, Qobuz veya Deezer\'den FLAC kalitesinde ses alın';

  @override
  String get tutorialWelcomeTip3 =>
      'Automatic metadata, cover art, and lyrics embedding';

  @override
  String get tutorialSearchTitle => 'Finding Music';

  @override
  String get tutorialSearchDesc =>
      'There are two easy ways to find music you want to download.';

  @override
  String get tutorialDownloadTitle => 'Downloading Music';

  @override
  String get tutorialDownloadDesc =>
      'Downloading music is simple and fast. Here\'s how it works.';

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
  String get trackReEnrich => 'Re-enrich';

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
  String get actionCreate => 'Create';

  @override
  String get collectionFoldersTitle => 'My folders';

  @override
  String get collectionWishlist => 'Wishlist';

  @override
  String get collectionLoved => 'Loved';

  @override
  String get collectionPlaylists => 'Playlists';

  @override
  String get collectionPlaylist => 'Playlist';

  @override
  String get collectionAddToPlaylist => 'Add to playlist';

  @override
  String get collectionCreatePlaylist => 'Create playlist';

  @override
  String get collectionNoPlaylistsYet => 'No playlists yet';

  @override
  String get collectionNoPlaylistsSubtitle =>
      'Create a playlist to start categorizing tracks';

  @override
  String collectionPlaylistTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String collectionAddedToPlaylist(String playlistName) {
    return 'Added to \"$playlistName\"';
  }

  @override
  String collectionAlreadyInPlaylist(String playlistName) {
    return 'Already in \"$playlistName\"';
  }

  @override
  String get collectionPlaylistCreated => 'Playlist created';

  @override
  String get collectionPlaylistNameHint => 'Playlist name';

  @override
  String get collectionPlaylistNameRequired => 'Playlist name is required';

  @override
  String get collectionRenamePlaylist => 'Rename playlist';

  @override
  String get collectionDeletePlaylist => 'Delete playlist';

  @override
  String collectionDeletePlaylistMessage(String playlistName) {
    return 'Delete \"$playlistName\" and all tracks inside it?';
  }

  @override
  String get collectionPlaylistDeleted => 'Playlist deleted';

  @override
  String get collectionPlaylistRenamed => 'Playlist renamed';

  @override
  String get collectionWishlistEmptyTitle => 'Wishlist is empty';

  @override
  String get collectionWishlistEmptySubtitle =>
      'Tap + on tracks to save what you want to download later';

  @override
  String get collectionLovedEmptyTitle => 'Loved folder is empty';

  @override
  String get collectionLovedEmptySubtitle =>
      'Tap love on tracks to keep your favorites';

  @override
  String get collectionPlaylistEmptyTitle => 'Playlist is empty';

  @override
  String get collectionPlaylistEmptySubtitle =>
      'Long-press + on any track to add it here';

  @override
  String get collectionRemoveFromPlaylist => 'Remove from playlist';

  @override
  String get collectionRemoveFromFolder => 'Remove from folder';

  @override
  String collectionRemoved(String trackName) {
    return '\"$trackName\" removed';
  }

  @override
  String collectionAddedToLoved(String trackName) {
    return '\"$trackName\" added to Loved';
  }

  @override
  String collectionRemovedFromLoved(String trackName) {
    return '\"$trackName\" removed from Loved';
  }

  @override
  String collectionAddedToWishlist(String trackName) {
    return '\"$trackName\" added to Wishlist';
  }

  @override
  String collectionRemovedFromWishlist(String trackName) {
    return '\"$trackName\" removed from Wishlist';
  }

  @override
  String get trackOptionAddToLoved => 'Add to Loved';

  @override
  String get trackOptionRemoveFromLoved => 'Remove from Loved';

  @override
  String get trackOptionAddToWishlist => 'Add to Wishlist';

  @override
  String get trackOptionRemoveFromWishlist => 'Remove from Wishlist';

  @override
  String get collectionPlaylistChangeCover => 'Change cover image';

  @override
  String get collectionPlaylistRemoveCover => 'Remove cover image';

  @override
  String selectionShareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Share $count $_temp0';
  }

  @override
  String get selectionShareNoFiles => 'No shareable files found';

  @override
  String selectionConvertCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Convert $count $_temp0';
  }

  @override
  String get selectionConvertNoConvertible => 'No convertible tracks selected';

  @override
  String get selectionBatchConvertConfirmTitle => 'Batch Convert';

  @override
  String selectionBatchConvertConfirmMessage(
    int count,
    String format,
    String bitrate,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tracks',
      one: 'track',
    );
    return 'Convert $count $_temp0 to $format at $bitrate?\n\nOriginal files will be deleted after conversion.';
  }

  @override
  String selectionBatchConvertProgress(int current, int total) {
    return 'Converting $current of $total...';
  }

  @override
  String selectionBatchConvertSuccess(int success, int total, String format) {
    return 'Converted $success of $total tracks to $format';
  }

  @override
  String downloadedAlbumDownloadedCount(int count) {
    return '$count downloaded';
  }

  @override
  String get downloadUseAlbumArtistForFoldersAlbumSubtitle =>
      'Artist folders use Album Artist when available';

  @override
  String get downloadUseAlbumArtistForFoldersTrackSubtitle =>
      'Artist folders use Track Artist only';
}
