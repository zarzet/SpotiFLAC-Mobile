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
  String get navHome => 'Ana Sayfa';

  @override
  String get navLibrary => 'Kitaplık';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get navStore => 'Mağaza';

  @override
  String get homeTitle => 'Ana Sayfa';

  @override
  String get homeSubtitle =>
      'Bir Spotify bağlantısı yapıştırın veya şarkı arayın';

  @override
  String get homeSupports =>
      'Desteklenenler: Şarkı, Albüm, Çalma Listesi, Sanatçı bağlantıları';

  @override
  String get homeRecent => 'Son Arananlar';

  @override
  String get historyFilterAll => 'Tümü';

  @override
  String get historyFilterAlbums => 'Albümler';

  @override
  String get historyFilterSingles => 'Single\'lar';

  @override
  String get historySearchHint => 'Geçmişte ara...';

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
      'Her indirmede kalite seçme ekranını göster';

  @override
  String get downloadFilenameFormat => 'Dosya Adı Formatı';

  @override
  String get downloadSingleFilenameFormat => 'Single Filename Format';

  @override
  String get downloadSingleFilenameFormatDescription =>
      'Filename pattern for singles and EPs. Uses the same tags as the album format.';

  @override
  String get downloadFolderOrganization => 'Klasör Düzeni Seçimi';

  @override
  String get appearanceTitle => 'Görünüm';

  @override
  String get appearanceThemeSystem => 'Sistem';

  @override
  String get appearanceThemeLight => 'Açık';

  @override
  String get appearanceThemeDark => 'Koyu';

  @override
  String get appearanceDynamicColor => 'Dinamik Renkler';

  @override
  String get appearanceDynamicColorSubtitle =>
      'Uygulama renklerini duvar kağıdınızdan alır';

  @override
  String get appearanceHistoryView => 'Geçmiş Görünümü';

  @override
  String get appearanceHistoryViewList => 'Liste';

  @override
  String get appearanceHistoryViewGrid => 'Izgara';

  @override
  String get optionsTitle => 'Seçenekler';

  @override
  String get optionsPrimaryProvider => 'Ana Sağlayıcı';

  @override
  String get optionsPrimaryProviderSubtitle =>
      'Şarkı adıyla arama yaparken kullanılacak servis.';

  @override
  String optionsUsingExtension(String extensionName) {
    return 'Şu anki eklenti: $extensionName';
  }

  @override
  String get optionsDefaultSearchTab => 'Default Search Tab';

  @override
  String get optionsDefaultSearchTabSubtitle =>
      'Choose which tab opens first for new search results.';

  @override
  String get optionsSwitchBack =>
      'Eklentiden çıkıp varsayılana dönmek için Deezer veya Spotify\'a dokunun';

  @override
  String get optionsAutoFallback => 'Otomatik Geçiş';

  @override
  String get optionsAutoFallbackSubtitle =>
      'İndirme başarısız olursa otomatik olarak diğer servisleri dener';

  @override
  String get optionsUseExtensionProviders => 'Eklenti Sağlayıcılarını Kullan';

  @override
  String get optionsUseExtensionProvidersOn =>
      'İndirme için önce eklentiler denenecek';

  @override
  String get optionsUseExtensionProvidersOff =>
      'Sadece yerleşik sağlayıcılar kullanılıyor';

  @override
  String get optionsEmbedLyrics => 'Şarkı Sözlerini Gömer';

  @override
  String get optionsEmbedLyricsSubtitle =>
      'Senkronize şarkı sözlerini FLAC dosyalarının içine gömer';

  @override
  String get optionsMaxQualityCover => 'En Yüksek Kalite Albüm Kapağı';

  @override
  String get optionsMaxQualityCoverSubtitle =>
      'Albüm kapağını bulunabilen en yüksek çözünürlükte indirir';

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
  String get optionsConcurrentDownloads => 'Eşzamanlı İndirmeler';

  @override
  String get optionsConcurrentSequential => 'Sırayla (Tek tek)';

  @override
  String optionsConcurrentParallel(int count) {
    return 'Aynı anda $count indirme';
  }

  @override
  String get optionsConcurrentWarning =>
      'Aynı anda çok fazla indirme yapmak kısıtlamaya takılmanıza neden olabilir';

  @override
  String get optionsExtensionStore => 'Eklenti Mağazası';

  @override
  String get optionsExtensionStoreSubtitle =>
      'Gezinme çubuğunda Mağaza sekmesini göster';

  @override
  String get optionsCheckUpdates => 'Güncellemeleri Kontrol Et';

  @override
  String get optionsCheckUpdatesSubtitle =>
      'Yeni bir sürüm çıktığında haber ver';

  @override
  String get optionsUpdateChannel => 'Güncelleme Kanalı';

  @override
  String get optionsUpdateChannelStable => 'Sadece kararlı sürümler';

  @override
  String get optionsUpdateChannelPreview =>
      'Ön izleme (Beta) sürümlerini de al';

  @override
  String get optionsUpdateChannelWarning =>
      'Beta sürümler hatalar içerebilir veya tamamlanmamış özellikler barındırabilir';

  @override
  String get optionsClearHistory => 'İndirme Geçmişini Temizle';

  @override
  String get optionsClearHistorySubtitle =>
      'İndirilen tüm şarkıları geçmişten siler';

  @override
  String get optionsDetailedLogging => 'Detaylı Hata Ayıklama (Log)';

  @override
  String get optionsDetailedLoggingOn => 'Arka planda detaylı kayıt tutuluyor';

  @override
  String get optionsDetailedLoggingOff => 'Hata bildirimi yapacaksanız açın';

  @override
  String get optionsSpotifyCredentials => 'Spotify API Kimlik Bilgileri';

  @override
  String optionsSpotifyCredentialsConfigured(String clientId) {
    return 'İstemci Kimliği (Client ID): $clientId...';
  }

  @override
  String get optionsSpotifyCredentialsRequired =>
      'Gerekli - ayarlamak için dokunun';

  @override
  String get optionsSpotifyWarning =>
      'Spotify, kendi API kimlik bilgilerinizi kullanmanızı gerektirir. developer.spotify.com adresinden ücretsiz alabilirsiniz.';

  @override
  String get optionsSpotifyDeprecationWarning =>
      'Spotify API\'sindeki değişiklikler nedeniyle Spotify araması 3 Mart 2026\'da kullanımdan kaldırılacak. Lütfen Deezer\'a geçin.';

  @override
  String get extensionsTitle => 'Eklentiler';

  @override
  String get extensionsDisabled => 'Devre dışı';

  @override
  String extensionsVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String extensionsAuthor(String author) {
    return '$author tarafından';
  }

  @override
  String get extensionsUninstall => 'Kaldır';

  @override
  String get storeTitle => 'Eklenti Mağazası';

  @override
  String get storeSearch => 'Eklentilerde ara...';

  @override
  String get storeInstall => 'Yükle';

  @override
  String get storeInstalled => 'Yüklü';

  @override
  String get storeUpdate => 'Güncelle';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String get aboutContributors => 'Katkıda Bulunanlar';

  @override
  String get aboutMobileDeveloper => 'Mobil sürüm geliştiricisi';

  @override
  String get aboutOriginalCreator => 'Orijinal SpotiFLAC\'ın yaratıcısı';

  @override
  String get aboutLogoArtist =>
      'Uygulamanın harika logosunu tasarlayan yetenekli sanatçı!';

  @override
  String get aboutTranslators => 'Çevirmenler';

  @override
  String get aboutSpecialThanks => 'Özel Teşekkürler';

  @override
  String get aboutLinks => 'Bağlantılar';

  @override
  String get aboutMobileSource => 'Mobil kaynak kodu';

  @override
  String get aboutPCSource => 'PC kaynak kodu';

  @override
  String get aboutKeepAndroidOpen => 'Keep Android Open';

  @override
  String get aboutReportIssue => 'Sorun bildir';

  @override
  String get aboutReportIssueSubtitle =>
      'Karşılaştığınız sorunları bize iletin';

  @override
  String get aboutFeatureRequest => 'Özellik isteği';

  @override
  String get aboutFeatureRequestSubtitle =>
      'Uygulama için yeni özellikler önerin';

  @override
  String get aboutTelegramChannel => 'Telegram Kanalı';

  @override
  String get aboutTelegramChannelSubtitle => 'Duyurular ve güncellemeler';

  @override
  String get aboutTelegramChat => 'Telegram Topluluğu';

  @override
  String get aboutTelegramChatSubtitle => 'Diğer kullanıcılarla sohbet edin';

  @override
  String get aboutSocial => 'Sosyal Medya';

  @override
  String get aboutApp => 'Uygulama Bilgisi';

  @override
  String get aboutVersion => 'Sürüm';

  @override
  String get aboutBinimumDesc =>
      'QQDL ve HiFi API\'nin yaratıcısı. Bu API olmasaydı Tidal indirmeleri var olamazdı!';

  @override
  String get aboutSachinsenalDesc =>
      'Orijinal HiFi projesinin kurucusu. Tidal entegrasyonunun temel taşı!';

  @override
  String get aboutSjdonadoDesc =>
      'I Don\'t Have Spotify (IDHS) projesinin yaratıcısı. Günü kurtaran bağlantı çözümleyicimiz!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'En iyi Qobuz yayın API\'si. Hi-Res indirmeler onlar olmadan mümkün olamazdı!';

  @override
  String get aboutSpotiSaver => 'SpotiSaver';

  @override
  String get aboutSpotiSaverDesc =>
      'Tidal Hi-Res FLAC altyapısı. Kayıpsız ses deneyiminin kilit parçası!';

  @override
  String get aboutAppDescription =>
      'Spotify şarkılarını Tidal ve Qobuz üzerinden kayıpsız kalitede indirin.';

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
  String get trackMetadataService => 'Sağlayıcı';

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
  String get setupStorageAccessRequired => 'Depolama İzni Gerekli';

  @override
  String get setupStorageAccessMessageAndroid11 =>
      'Android 11 ve üzeri, müzikleri seçtiğiniz klasöre kaydedebilmek için \'Tüm dosyalara erişim\' izni gerektirir.';

  @override
  String get setupOpenSettings => 'Ayarları Aç';

  @override
  String get setupPermissionDeniedMessage =>
      'İzin reddedildi. Devam etmek için lütfen gerekli izinleri verin.';

  @override
  String setupPermissionRequired(String permissionType) {
    return '$permissionType İzni Gerekli';
  }

  @override
  String setupPermissionRequiredMessage(String permissionType) {
    return 'En iyi deneyim için $permissionType iznine ihtiyacımız var. Bunu daha sonra Ayarlar\'dan değiştirebilirsiniz.';
  }

  @override
  String get setupUseDefaultFolder => 'Varsayılan Klasör Kullanılsın mı?';

  @override
  String get setupNoFolderSelected =>
      'Hiçbir klasör seçilmedi. İndirilenler için cihazınızdaki varsayılan Müzik klasörü kullanılsın mı?';

  @override
  String get setupUseDefault => 'Varsayılanı Kullan';

  @override
  String get setupDownloadLocationTitle => 'İndirme Konumu';

  @override
  String get setupDownloadLocationIosMessage =>
      'iOS\'te indirilen dosyalar uygulamanın Belgeler klasörüne kaydedilir. Bunlara Dosyalar uygulaması üzerinden erişebilirsiniz.';

  @override
  String get setupAppDocumentsFolder => 'Uygulama Belgeleri Klasörü';

  @override
  String get setupAppDocumentsFolderSubtitle =>
      'Önerilen - Dosyalar uygulamasıyla erişilebilir';

  @override
  String get setupChooseFromFiles => 'Dosyalar\'dan Seç';

  @override
  String get setupChooseFromFilesSubtitle =>
      'iCloud veya başka bir konum seçin';

  @override
  String get setupIosEmptyFolderWarning =>
      'iOS Kısıtlaması: Boş klasörler seçilemez. Lütfen içinde en az bir dosya olan bir klasör seçin.';

  @override
  String get setupIcloudNotSupported =>
      'iCloud Drive desteklenmiyor. Lütfen uygulamanın Belgeler klasörünü kullanın.';

  @override
  String get setupDownloadInFlac =>
      'Spotify müziklerini FLAC formatında indirin';

  @override
  String get setupStorageGranted => 'Depolama İzni Verildi!';

  @override
  String get setupStorageRequired => 'Depolama İzni Gerekli';

  @override
  String get setupStorageDescription =>
      'İndirdiğiniz şarkıları kaydedebilmemiz için SpotiFLAC\'ın depolama iznine ihtiyacı var.';

  @override
  String get setupNotificationGranted => 'Bildirim İzni Verildi!';

  @override
  String get setupNotificationEnable => 'Bildirimleri Aç';

  @override
  String get setupFolderChoose => 'İndirme Klasörü Seç';

  @override
  String get setupFolderDescription =>
      'İndirilen şarkıların nereye kaydedileceğini seçin.';

  @override
  String get setupSelectFolder => 'Klasör Seç';

  @override
  String get setupEnableNotifications => 'Bildirimleri Aç';

  @override
  String get setupNotificationBackgroundDescription =>
      'İndirme durumları ve tamamlanan şarkılar hakkında anında bildirim alın. Bu, uygulama arka plandayken süreci takip etmenizi kolaylaştırır.';

  @override
  String get setupSkipForNow => 'Şimdilik atla';

  @override
  String get setupNext => 'İleri';

  @override
  String get setupGetStarted => 'Hadi Başlayalım';

  @override
  String get setupAllowAccessToManageFiles =>
      'Lütfen sonraki ekranda \"Tüm dosyaları yönetme erişimine izin ver\" seçeneğini açın.';

  @override
  String get dialogCancel => 'İptal';

  @override
  String get dialogSave => 'Kaydet';

  @override
  String get dialogDelete => 'Sil';

  @override
  String get dialogRetry => 'Yeniden Dene';

  @override
  String get dialogClear => 'Temizle';

  @override
  String get dialogDone => 'Bitti';

  @override
  String get dialogImport => 'İçe Aktar';

  @override
  String get dialogDownload => 'İndir';

  @override
  String get dialogDiscard => 'Değişiklikleri Sil';

  @override
  String get dialogRemove => 'Kaldır';

  @override
  String get dialogUninstall => 'Sil';

  @override
  String get dialogDiscardChanges => 'Değişiklikler İptal Edilsin mi?';

  @override
  String get dialogUnsavedChanges =>
      'Kaydedilmemiş değişiklikleriniz var. Çıkmak istediğinize emin misiniz?';

  @override
  String get dialogClearAll => 'Tümünü Temizle';

  @override
  String get dialogRemoveExtension => 'Eklentiyi Kaldır';

  @override
  String get dialogRemoveExtensionMessage =>
      'Bu eklentiyi kaldırmak istediğinize emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get dialogUninstallExtension => 'Eklentiyi Sil?';

  @override
  String dialogUninstallExtensionMessage(String extensionName) {
    return '$extensionName eklentisini silmek istediğinize emin misiniz?';
  }

  @override
  String get dialogClearHistoryTitle => 'Geçmişi Temizle';

  @override
  String get dialogClearHistoryMessage =>
      'Tüm indirme geçmişinizi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get dialogDeleteSelectedTitle => 'Seçilenleri Sil';

  @override
  String dialogDeleteSelectedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şarkı',
      one: 'şarkı',
    );
    return 'Geçmişten $count $_temp0 silinsin mi?\n\nBu işlem, indirilen dosyaları cihazınızdan da tamamen silecek.';
  }

  @override
  String get dialogImportPlaylistTitle => 'Çalma Listesi İçe Aktar';

  @override
  String dialogImportPlaylistMessage(int count) {
    return 'CSV dosyasında $count şarkı bulundu. İndirme sırasına eklensin mi?';
  }

  @override
  String csvImportTracks(int count) {
    return 'CSV\'den $count şarkı';
  }

  @override
  String snackbarAddedToQueue(String trackName) {
    return '\"$trackName\" indirme sırasına eklendi';
  }

  @override
  String snackbarAddedTracksToQueue(int count) {
    return '$count şarkı indirme sırasına eklendi';
  }

  @override
  String snackbarAlreadyDownloaded(String trackName) {
    return '\"$trackName\" zaten inmiş durumda';
  }

  @override
  String snackbarAlreadyInLibrary(String trackName) {
    return '\"$trackName\" kitaplığınızda zaten mevcut';
  }

  @override
  String get snackbarHistoryCleared => 'Geçmiş temizlendi';

  @override
  String get snackbarCredentialsSaved => 'API bilgileri kaydedildi';

  @override
  String get snackbarCredentialsCleared => 'API bilgileri silindi';

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
    return 'Dosya açılamıyor: $error';
  }

  @override
  String get snackbarFillAllFields => 'Lütfen tüm alanları doldurun';

  @override
  String get snackbarViewQueue => 'Sırayı Gör';

  @override
  String snackbarUrlCopied(String platform) {
    return '$platform bağlantısı panoya kopyalandı';
  }

  @override
  String get snackbarFileNotFound => 'Dosya bulunamadı';

  @override
  String get snackbarSelectExtFile => 'Lütfen bir .spotiflac-ext dosyası seçin';

  @override
  String get snackbarProviderPrioritySaved => 'Sağlayıcı önceliği kaydedildi';

  @override
  String get snackbarMetadataProviderSaved =>
      'Veri sağlayıcı önceliği kaydedildi';

  @override
  String snackbarExtensionInstalled(String extensionName) {
    return '$extensionName başarıyla yüklendi.';
  }

  @override
  String snackbarExtensionUpdated(String extensionName) {
    return '$extensionName başarıyla güncellendi.';
  }

  @override
  String get snackbarFailedToInstall => 'Eklenti yüklenemedi';

  @override
  String get snackbarFailedToUpdate => 'Eklenti güncellenemedi';

  @override
  String get errorRateLimited => 'Hız Sınırına Takıldınız';

  @override
  String get errorRateLimitedMessage =>
      'Çok fazla istek gönderdiniz. Yeniden arama yapmadan önce lütfen biraz bekleyin.';

  @override
  String get errorNoTracksFound => 'Şarkı bulunamadı';

  @override
  String get errorUrlNotRecognized => 'Bağlantı algılanamadı';

  @override
  String get errorUrlNotRecognizedMessage =>
      'Bu bağlantı desteklenmiyor. Bağlantının doğru olduğundan ve gerekli eklentinin yüklü olduğundan emin olun.';

  @override
  String get errorUrlFetchFailed =>
      'Bu bağlantıdan içerik yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String errorMissingExtensionSource(String item) {
    return '$item yüklenemiyor: Eklenti kaynağı eksik';
  }

  @override
  String get actionPause => 'Duraklat';

  @override
  String get actionResume => 'Devam Et';

  @override
  String get actionCancel => 'İptal';

  @override
  String get actionSelectAll => 'Tümünü Seç';

  @override
  String get actionDeselect => 'Seçimi Kaldır';

  @override
  String get actionRemoveCredentials => 'API Bilgilerini Sil';

  @override
  String get actionSaveCredentials => 'API Bilgilerini Kaydet';

  @override
  String selectionSelected(int count) {
    return '$count seçildi';
  }

  @override
  String get selectionAllSelected => 'Tüm şarkılar seçildi';

  @override
  String get selectionSelectToDelete => 'Silinecek şarkıları seçin';

  @override
  String progressFetchingMetadata(int current, int total) {
    return 'Veriler alınıyor... $current/$total';
  }

  @override
  String get progressReadingCsv => 'CSV dosyası okunuyor...';

  @override
  String get searchSongs => 'Şarkılar';

  @override
  String get searchArtists => 'Sanatçılar';

  @override
  String get searchAlbums => 'Albümler';

  @override
  String get searchPlaylists => 'Çalma Listeleri';

  @override
  String get searchSortTitle => 'Sonuçları Sırala';

  @override
  String get searchSortDefault => 'Varsayılan';

  @override
  String get searchSortTitleAZ => 'Şarkı Adı (A-Z)';

  @override
  String get searchSortTitleZA => 'Şarkı Adı (Z-A)';

  @override
  String get searchSortArtistAZ => 'Sanatçı (A-Z)';

  @override
  String get searchSortArtistZA => 'Sanatçı (Z-A)';

  @override
  String get searchSortDurationShort => 'Süre (Önce kısalar)';

  @override
  String get searchSortDurationLong => 'Süre (Önce uzunlar)';

  @override
  String get searchSortDateOldest => 'Çıkış Tarihi (Önce eskiler)';

  @override
  String get searchSortDateNewest => 'Çıkış Tarihi (Önce yeniler)';

  @override
  String get tooltipPlay => 'Oynat';

  @override
  String get filenameFormat => 'Dosya Adı Formatı';

  @override
  String get filenameShowAdvancedTags => 'Gelişmiş etiketleri göster';

  @override
  String get filenameShowAdvancedTagsDescription =>
      'Boşluk doldurma ve tarih formatları için gelişmiş dosya adı etiketlerini açar';

  @override
  String get folderOrganizationNone => 'Düzen yok';

  @override
  String get folderOrganizationByPlaylist => 'Çalma Listesine Göre';

  @override
  String get folderOrganizationByPlaylistSubtitle =>
      'Her çalma listesi için ayrı bir klasör oluşturur';

  @override
  String get folderOrganizationByArtist => 'Sanatçıya Göre';

  @override
  String get folderOrganizationByAlbum => 'Albüme Göre';

  @override
  String get folderOrganizationByArtistAlbum => 'Sanatçı / Albüm';

  @override
  String get folderOrganizationDescription =>
      'İndirilen dosyaları klasörlere düzenler';

  @override
  String get folderOrganizationNoneSubtitle =>
      'Tüm dosyalar tek bir klasöre atılır';

  @override
  String get folderOrganizationByArtistSubtitle =>
      'Her sanatçı için ayrı klasör oluşturur';

  @override
  String get folderOrganizationByAlbumSubtitle =>
      'Her albüm için ayrı klasör oluşturur';

  @override
  String get folderOrganizationByArtistAlbumSubtitle =>
      'İç içe Sanatçı ve Albüm klasörleri oluşturur';

  @override
  String get updateAvailable => 'Güncelleme Var';

  @override
  String get updateLater => 'Daha Sonra';

  @override
  String get updateStartingDownload => 'İndirme başlatılıyor...';

  @override
  String get updateDownloadFailed => 'İndirme başarısız';

  @override
  String get updateFailedMessage => 'Güncelleme dosyası indirilemedi';

  @override
  String get updateNewVersionReady => 'Uygulamanın yeni bir sürümü hazır';

  @override
  String get updateCurrent => 'Mevcut';

  @override
  String get updateNew => 'Yeni';

  @override
  String get updateDownloading => 'İndiriliyor...';

  @override
  String get updateWhatsNew => 'Neler Yeni?';

  @override
  String get updateDownloadInstall => 'İndir ve Yükle';

  @override
  String get updateDontRemind => 'Bir daha hatırlatma';

  @override
  String get providerPriorityTitle => 'Sağlayıcı Önceliği';

  @override
  String get providerPriorityDescription =>
      'İndirme sağlayıcılarını sürükleyip sıralayın. Uygulama, şarkıları indirirken sağlayıcıları yukarıdan aşağıya doğru dener.';

  @override
  String get providerPriorityInfo =>
      'Bir şarkı ilk sağlayıcıda bulunamazsa, uygulama otomatik olarak listedeki bir sonrakini dener.';

  @override
  String get providerPriorityFallbackExtensionsTitle => 'Extension Fallback';

  @override
  String get providerPriorityFallbackExtensionsDescription =>
      'Choose which installed download extensions can be used during automatic fallback. Built-in providers still follow the priority order above.';

  @override
  String get providerPriorityFallbackExtensionsHint =>
      'Only enabled extensions with download-provider capability are listed here.';

  @override
  String get providerBuiltIn => 'Yerleşik';

  @override
  String get providerExtension => 'Eklenti';

  @override
  String get metadataProviderPriorityTitle => 'Arama Kaynağı Önceliği';

  @override
  String get metadataProviderPriorityDescription =>
      'Arama kaynaklarını sürükleyip sıralayın. Uygulama, şarkı ararken ve veri çekerken kaynakları yukarıdan aşağıya doğru dener.';

  @override
  String get metadataProviderPriorityInfo =>
      'Deezer\'da hız sınırı yoktur, bu yüzden ana kaynak olarak kullanılması tavsiye edilir. Spotify, çok fazla istekte bulunduğunuzda kısıtlama yapabilir.';

  @override
  String get metadataNoRateLimits => 'Hız sınırı yok';

  @override
  String get metadataMayRateLimit => 'Hız sınırı yapabilir';

  @override
  String get logTitle => 'Hata Kayıtları (Log)';

  @override
  String get logCopied => 'Kayıtlar panoya kopyalandı';

  @override
  String get logSearchHint => 'Kayıtlarda ara...';

  @override
  String get logFilterLevel => 'Seviye';

  @override
  String get logFilterSection => 'Filtrele';

  @override
  String get logShareLogs => 'Kayıtları paylaş';

  @override
  String get logClearLogs => 'Kayıtları temizle';

  @override
  String get logClearLogsTitle => 'Kayıtları Temizle';

  @override
  String get logClearLogsMessage =>
      'Tüm hata kayıtlarını silmek istediğinize emin misiniz?';

  @override
  String get logFilterBySeverity => 'Önem derecesine göre filtrele';

  @override
  String get logNoLogsYet => 'Henüz kayıt yok';

  @override
  String get logNoLogsYetSubtitle =>
      'Uygulamayı kullandıkça teknik kayıtlar burada görünecek';

  @override
  String logEntriesFiltered(int count) {
    return 'Kayıtlar ($count filtrelendi)';
  }

  @override
  String logEntries(int count) {
    return 'Kayıtlar ($count)';
  }

  @override
  String get credentialsTitle => 'Spotify API Bilgileri';

  @override
  String get credentialsDescription =>
      'Kendi Spotify uygulamanızın kota limitlerini kullanmak için İstemci Kimliği (Client ID) ve Gizli Anahtarınızı (Client Secret) girin.';

  @override
  String get credentialsClientId => 'Client ID (İstemci Kimliği)';

  @override
  String get credentialsClientIdHint => 'Client ID yapıştır';

  @override
  String get credentialsClientSecret => 'Client Secret (Gizli Anahtar)';

  @override
  String get credentialsClientSecretHint => 'Client Secret yapıştır';

  @override
  String get channelStable => 'Kararlı';

  @override
  String get channelPreview => 'Beta (Ön İzleme)';

  @override
  String get sectionSearchSource => 'Arama Kaynağı';

  @override
  String get sectionDownload => 'İndirme';

  @override
  String get sectionPerformance => 'Performans';

  @override
  String get sectionApp => 'Uygulama';

  @override
  String get sectionData => 'Veri Yönetimi';

  @override
  String get sectionDebug => 'Hata Ayıklama';

  @override
  String get sectionService => 'Servisler';

  @override
  String get sectionAudioQuality => 'Ses Kalitesi';

  @override
  String get sectionFileSettings => 'Dosya Ayarları';

  @override
  String get sectionLyrics => 'Şarkı Sözleri';

  @override
  String get lyricsMode => 'Şarkı Sözü Formatı';

  @override
  String get lyricsModeDescription =>
      'Şarkı sözlerinin nasıl kaydedileceğini seçin';

  @override
  String get lyricsModeEmbed => 'Dosyaya göm';

  @override
  String get lyricsModeEmbedSubtitle =>
      'Şarkı sözleri FLAC dosyasının içine işlenir';

  @override
  String get lyricsModeExternal => 'Harici .lrc dosyası';

  @override
  String get lyricsModeExternalSubtitle =>
      'Bazı müzik çalarlar için şarkının yanına ayrı bir .lrc dosyası açar';

  @override
  String get lyricsModeBoth => 'Her ikisi de';

  @override
  String get lyricsModeBothSubtitle =>
      'Hem dosyaya gömer hem de .lrc dosyası olarak kaydeder';

  @override
  String get sectionColor => 'Renkler';

  @override
  String get sectionTheme => 'Tema';

  @override
  String get sectionLayout => 'Tasarım';

  @override
  String get sectionLanguage => 'Dil';

  @override
  String get appearanceLanguage => 'Uygulama Dili';

  @override
  String get settingsAppearanceSubtitle => 'Temalar, renkler, görünümler';

  @override
  String get settingsDownloadSubtitle =>
      'İndirme servisi, ses kalitesi, dosya adı düzeni';

  @override
  String get settingsOptionsSubtitle =>
      'İndirme limitleri, şarkı sözleri, güncellemeler';

  @override
  String get settingsExtensionsSubtitle =>
      'Yeni müzik kaynakları ve eklentileri yönetin';

  @override
  String get settingsLogsSubtitle =>
      'Sorun tespiti için uygulama kayıtlarına göz atın';

  @override
  String get loadingSharedLink => 'Paylaşılan bağlantı yükleniyor...';

  @override
  String get pressBackAgainToExit => 'Çıkmak için tekrar geri dokunun';

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
  String get trackRemoveFromDevice => 'Cihazdan sil';

  @override
  String get trackLoadLyrics => 'Sözleri Yükle';

  @override
  String get trackMetadata => 'Şarkı Künyesi';

  @override
  String get trackFileInfo => 'Dosya Bilgisi';

  @override
  String get trackLyrics => 'Sözler';

  @override
  String get trackFileNotFound => 'Dosya bulunamadı';

  @override
  String get trackOpenInDeezer => 'Deezer\'da Aç';

  @override
  String get trackOpenInSpotify => 'Spotify\'da Aç';

  @override
  String get trackTrackName => 'Şarkı Adı';

  @override
  String get trackArtist => 'Sanatçı';

  @override
  String get trackAlbumArtist => 'Albüm Sanatçısı';

  @override
  String get trackAlbum => 'Albüm';

  @override
  String get trackTrackNumber => 'Parça numarası';

  @override
  String get trackDiscNumber => 'Disk numarası';

  @override
  String get trackDuration => 'Süre';

  @override
  String get trackAudioQuality => 'Ses kalitesi';

  @override
  String get trackReleaseDate => 'Çıkış tarihi';

  @override
  String get trackGenre => 'Tür';

  @override
  String get trackLabel => 'Plak Şirketi';

  @override
  String get trackCopyright => 'Telif Hakkı';

  @override
  String get trackDownloaded => 'İndirilme tarihi';

  @override
  String get trackCopyLyrics => 'Sözleri kopyala';

  @override
  String get trackLyricsNotAvailable => 'Bu şarkının sözleri bulunamadı';

  @override
  String get trackLyricsNotInFile => 'No lyrics found in this file';

  @override
  String get trackFetchOnlineLyrics => 'Fetch from Online';

  @override
  String get trackLyricsTimeout =>
      'Zaman aşımına uğradı. Lütfen daha sonra tekrar deneyin.';

  @override
  String get trackLyricsLoadFailed => 'Şarkı sözleri yüklenemedi';

  @override
  String get trackEmbedLyrics => 'Şarkı Sözlerini Gömer';

  @override
  String get trackLyricsEmbedded => 'Şarkı sözleri dosyaya başarıyla eklendi';

  @override
  String get trackInstrumental => 'Enstrümantal parça (Sözsüz)';

  @override
  String get trackCopiedToClipboard => 'Panoya kopyalandı';

  @override
  String get trackDeleteConfirmTitle => 'Cihazdan silinsin mi?';

  @override
  String get trackDeleteConfirmMessage =>
      'Bu işlem indirdiğiniz dosyayı tamamen silecek ve geçmişinizden kaldıracak.';

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
  String get storeFilterMetadata => 'Şarkı Verisi';

  @override
  String get storeFilterDownload => 'İndirme';

  @override
  String get storeFilterUtility => 'Araçlar';

  @override
  String get storeFilterLyrics => 'Şarkı Sözü';

  @override
  String get storeFilterIntegration => 'Entegrasyon';

  @override
  String get storeClearFilters => 'Filtreleri temizle';

  @override
  String get storeAddRepoTitle => 'Eklenti Deposu (Repository) Ekle';

  @override
  String get storeAddRepoDescription =>
      'Eklentilere göz atmak ve yüklemek için içinde registry.json dosyası olan bir GitHub depo bağlantısı girin.';

  @override
  String get storeRepoUrlLabel => 'Depo Bağlantısı (URL)';

  @override
  String get storeRepoUrlHint => 'https://github.com/kullaniciadi/depo';

  @override
  String get storeRepoUrlHelper =>
      'Örn: https://github.com/spoti/extensions-repo';

  @override
  String get storeAddRepoButton => 'Depoyu Ekle';

  @override
  String get storeChangeRepoTooltip => 'Depoyu değiştir';

  @override
  String get storeRepoDialogTitle => 'Eklenti Deposu';

  @override
  String get storeRepoDialogCurrent => 'Mevcut depo:';

  @override
  String get storeNewRepoUrlLabel => 'Yeni Depo Bağlantısı';

  @override
  String get storeLoadError => 'Mağaza yüklenemedi';

  @override
  String get storeEmptyNoExtensions => 'Kullanılabilir eklenti yok';

  @override
  String get storeEmptyNoResults => 'Aramanıza uygun eklenti bulunamadı';

  @override
  String get extensionDefaultProvider => 'Varsayılan (Deezer)';

  @override
  String get extensionDefaultProviderSubtitle =>
      'Uygulamanın kendi aramasını kullan';

  @override
  String get extensionAuthor => 'Geliştirici';

  @override
  String get extensionId => 'Kimlik (ID)';

  @override
  String get extensionError => 'Hata';

  @override
  String get extensionCapabilities => 'Yetenekler';

  @override
  String get extensionMetadataProvider => 'Şarkı Verisi (Metadata) Kaynağı';

  @override
  String get extensionDownloadProvider => 'İndirme Sağlayıcısı';

  @override
  String get extensionLyricsProvider => 'Şarkı Sözü Sağlayıcısı';

  @override
  String get extensionUrlHandler => 'Bağlantı Okuyucu';

  @override
  String get extensionQualityOptions => 'Kalite Seçenekleri';

  @override
  String get extensionPostProcessingHooks => 'İndirme Sonrası İşlemler';

  @override
  String get extensionPermissions => 'İzinler';

  @override
  String get extensionSettings => 'Ayarlar';

  @override
  String get extensionRemoveButton => 'Eklentiyi Kaldır';

  @override
  String get extensionUpdated => 'Son Güncelleme';

  @override
  String get extensionMinAppVersion => 'Minimum Uygulama Sürümü';

  @override
  String get extensionCustomTrackMatching => 'Özel Eşleştirme Algoritması';

  @override
  String get extensionPostProcessing => 'İşlem Sonrası Özellikleri';

  @override
  String extensionHooksAvailable(int count) {
    return '$count özel kanca (hook) mevcut';
  }

  @override
  String extensionPatternsCount(int count) {
    return '$count bağlantı kalıbı';
  }

  @override
  String extensionStrategy(String strategy) {
    return 'Eşleştirme Stratejisi: $strategy';
  }

  @override
  String get extensionsProviderPrioritySection => 'Sağlayıcı Önceliği';

  @override
  String get extensionsInstalledSection => 'Yüklü Eklentiler';

  @override
  String get extensionsNoExtensions => 'Henüz eklenti yüklenmemiş';

  @override
  String get extensionsNoExtensionsSubtitle =>
      'Yeni müzik kaynakları eklemek için .spotiflac-ext dosyalarını yükleyin';

  @override
  String get extensionsInstallButton => 'Eklenti Yükle';

  @override
  String get extensionsInfoTip =>
      'Eklentiler yeni veri ve indirme kaynakları ekleyebilir. Lütfen eklentileri sadece güvendiğiniz kaynaklardan yükleyin.';

  @override
  String get extensionsInstalledSuccess => 'Eklenti başarıyla yüklendi';

  @override
  String get extensionsDownloadPriority => 'İndirme Önceliği';

  @override
  String get extensionsDownloadPrioritySubtitle =>
      'İndirme servislerinin deneneceği sırayı belirleyin';

  @override
  String get extensionsFallbackTitle => 'Fallback Extensions';

  @override
  String get extensionsFallbackSubtitle =>
      'Choose which installed download extensions can be used as fallback';

  @override
  String get extensionsNoDownloadProvider =>
      'İndirme sağlayıcısı barındıran bir eklenti yok';

  @override
  String get extensionsMetadataPriority => 'Arama Kaynağı Önceliği';

  @override
  String get extensionsMetadataPrioritySubtitle =>
      'Arama ve veri kaynaklarının sırasını belirleyin';

  @override
  String get extensionsNoMetadataProvider =>
      'Şarkı verisi (metadata) barındıran bir eklenti yok';

  @override
  String get extensionsSearchProvider => 'Arama Servisi';

  @override
  String get extensionsNoCustomSearch =>
      'Özel arama özelliği olan bir eklenti yok';

  @override
  String get extensionsSearchProviderDescription =>
      'Şarkı aramak için kullanılacak servisi seçin';

  @override
  String get extensionsCustomSearch => 'Özel arama';

  @override
  String get extensionsErrorLoading => 'Eklenti yüklenirken hata oluştu';

  @override
  String get qualityFlacLossless => 'FLAC Kayıpsız';

  @override
  String get qualityFlacLosslessSubtitle => '16-bit / 44.1kHz';

  @override
  String get qualityHiResFlac => 'Hi-Res FLAC (Yüksek Çözünürlüklü)';

  @override
  String get qualityHiResFlacSubtitle => '24-bit / 96kHz\'e kadar';

  @override
  String get qualityHiResFlacMax => 'Hi-Res FLAC Maksimum';

  @override
  String get qualityHiResFlacMaxSubtitle => '24-bit / 192kHz\'e kadar';

  @override
  String get downloadLossy320 => 'Kayıplı (Lossy) 320kbps';

  @override
  String get downloadLossyFormat => 'Kayıplı Formatı';

  @override
  String get downloadLossy320Format => 'Kayıplı (Lossy) 320kbps Formatı';

  @override
  String get downloadLossy320FormatDesc =>
      'Tidal\'dan 320kbps kalitesinde indirirken kullanılacak formatı seçin. Orijinal AAC yayını seçtiğiniz formata dönüştürülecektir.';

  @override
  String get downloadLossyMp3 => 'MP3 320kbps';

  @override
  String get downloadLossyMp3Subtitle => 'En iyi uyumluluk, şarkı başı ~10MB';

  @override
  String get downloadLossyOpus256 => 'Opus 256kbps';

  @override
  String get downloadLossyOpus256Subtitle =>
      'En iyi Opus kalitesi, şarkı başı ~8MB';

  @override
  String get downloadLossyOpus128 => 'Opus 128kbps';

  @override
  String get downloadLossyOpus128Subtitle => 'En küçük boyut, şarkı başı ~4MB';

  @override
  String get qualityNote =>
      'Gerçek kalite, şarkının serviste hangi kalitede bulunduğuna bağlıdır.';

  @override
  String get downloadAskBeforeDownload => 'İndirmeden Önce Sor';

  @override
  String get downloadDirectory => 'İndirme Klasörü';

  @override
  String get downloadSeparateSinglesFolder => 'Single\'ları Ayrı Klasöre Koy';

  @override
  String get downloadAlbumFolderStructure => 'Albüm Klasörü Düzeni';

  @override
  String get downloadUseAlbumArtistForFolders =>
      'Klasörler için Albüm Sanatçısını Kullan';

  @override
  String get downloadUsePrimaryArtistOnly =>
      'Klasörlerde Sadece Ana Sanatçı (Düetleri Gizle)';

  @override
  String get downloadUsePrimaryArtistOnlyEnabled =>
      'Konuk sanatçılar klasör adından silinir (Örn: Justin Bieber, Quavo → Justin Bieber)';

  @override
  String get downloadUsePrimaryArtistOnlyDisabled =>
      'Klasör adına tüm sanatçılar yazılır';

  @override
  String get downloadSelectQuality => 'Kaliteyi Seçin';

  @override
  String get downloadFrom => 'İndirme Kaynağı:';

  @override
  String get appearanceAmoledDark => 'AMOLED Koyu (Tam Siyah)';

  @override
  String get appearanceAmoledDarkSubtitle =>
      'Tamamen siyah arka plan (OLED ekranlar için)';

  @override
  String get queueClearAll => 'Tümünü Temizle';

  @override
  String get queueClearAllMessage =>
      'Tüm indirme sırasını temizlemek istediğinize emin misiniz?';

  @override
  String get settingsAutoExportFailed =>
      'Başarısız İndirmeleri Otomatik Dışa Aktar';

  @override
  String get settingsAutoExportFailedSubtitle =>
      'İndirilemeyen şarkıların listesini TXT dosyası olarak kaydeder';

  @override
  String get settingsDownloadNetwork => 'İndirme İçin Kullanılacak Ağ';

  @override
  String get settingsDownloadNetworkAny => 'Wi-Fi + Mobil Veri';

  @override
  String get settingsDownloadNetworkWifiOnly => 'Sadece Wi-Fi';

  @override
  String get settingsDownloadNetworkSubtitle =>
      'Sadece Wi-Fi seçildiğinde, mobil verideyken indirmeler otomatik duraklatılır.';

  @override
  String get albumFolderArtistAlbum => 'Sanatçı / Albüm';

  @override
  String get albumFolderArtistAlbumSubtitle =>
      'Albümler/Sanatçı Adı/Albüm Adı/';

  @override
  String get albumFolderArtistYearAlbum => 'Sanatçı / [Yıl] Albüm';

  @override
  String get albumFolderArtistYearAlbumSubtitle =>
      'Albümler/Sanatçı Adı/[2005] Albüm Adı/';

  @override
  String get albumFolderAlbumOnly => 'Sadece Albüm';

  @override
  String get albumFolderAlbumOnlySubtitle => 'Albümler/Albüm Adı/';

  @override
  String get albumFolderYearAlbum => '[Yıl] Albüm';

  @override
  String get albumFolderYearAlbumSubtitle => 'Albümler/[2005] Albüm Adı/';

  @override
  String get albumFolderArtistAlbumSingles => 'Sanatçı / Albüm + Single\'lar';

  @override
  String get albumFolderArtistAlbumSinglesSubtitle =>
      'Sanatçı/Albüm/ ve Sanatçı/Single\'lar/';

  @override
  String get albumFolderArtistAlbumFlat =>
      'Sanatçı / Albüm (Single\'lar ayrı klasörsüz)';

  @override
  String get albumFolderArtistAlbumFlatSubtitle =>
      'Sanatçı/Albüm/ ve Sanatçı/sarki.flac';

  @override
  String get downloadedAlbumDeleteSelected => 'Seçilenleri Sil';

  @override
  String downloadedAlbumDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şarkı',
      one: 'şarkı',
    );
    return 'Bu albümden $count $_temp0 silinsin mi?\n\nBu işlem, dosyaları cihazınızdan da tamamen silecek.';
  }

  @override
  String downloadedAlbumSelectedCount(int count) {
    return '$count seçildi';
  }

  @override
  String get downloadedAlbumAllSelected => 'Tüm şarkılar seçildi';

  @override
  String get downloadedAlbumTapToSelect => 'Seçmek için şarkılara dokunun';

  @override
  String downloadedAlbumDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Şarkıyı',
      one: 'Şarkıyı',
    );
    return '$count $_temp0 Sil';
  }

  @override
  String get downloadedAlbumSelectToDelete => 'Silinecek şarkıları seçin';

  @override
  String downloadedAlbumDiscHeader(int discNumber) {
    return 'Disk $discNumber';
  }

  @override
  String get recentTypeArtist => 'Sanatçı';

  @override
  String get recentTypeAlbum => 'Albüm';

  @override
  String get recentTypeSong => 'Şarkı';

  @override
  String get recentTypePlaylist => 'Çalma Listesi';

  @override
  String get recentEmpty => 'Henüz yeni bir arama yok';

  @override
  String get recentShowAllDownloads => 'Tüm İndirmeleri Göster';

  @override
  String recentPlaylistInfo(String name) {
    return 'Çalma Listesi: $name';
  }

  @override
  String get discographyDownload => 'Tüm Diskografiyi İndir';

  @override
  String get discographyDownloadAll => 'Tümünü İndir';

  @override
  String discographyDownloadAllSubtitle(int count, int albumCount) {
    return '$albumCount albüm/single üzerinden toplam $count şarkı';
  }

  @override
  String get discographyAlbumsOnly => 'Sadece Albümler';

  @override
  String discographyAlbumsOnlySubtitle(int count, int albumCount) {
    return '$albumCount albümden toplam $count şarkı';
  }

  @override
  String get discographySinglesOnly => 'Sadece Single\'lar ve EP\'ler';

  @override
  String discographySinglesOnlySubtitle(int count, int albumCount) {
    return '$albumCount single üzerinden toplam $count şarkı';
  }

  @override
  String get discographySelectAlbums => 'Albümleri Seç...';

  @override
  String get discographySelectAlbumsSubtitle =>
      'İstediğiniz albümleri veya single\'ları kendiniz seçin';

  @override
  String get discographyFetchingTracks => 'Şarkılar alınıyor...';

  @override
  String discographyFetchingAlbum(int current, int total) {
    return 'Alınıyor: $current / $total...';
  }

  @override
  String discographySelectedCount(int count) {
    return '$count seçildi';
  }

  @override
  String get discographyDownloadSelected => 'Seçilenleri İndir';

  @override
  String discographyAddedToQueue(int count) {
    return '$count şarkı indirme sırasına eklendi';
  }

  @override
  String discographySkippedDownloaded(int added, int skipped) {
    return '$added şarkı eklendi, zaten inmiş olan $skipped şarkı atlandı';
  }

  @override
  String get discographyNoAlbums => 'Bu sanatçıya ait albüm bulunamadı';

  @override
  String get discographyFailedToFetch => 'Bazı albümler yüklenemedi';

  @override
  String get sectionStorageAccess => 'Depolama Erişimi';

  @override
  String get allFilesAccess => 'Tüm Dosyalara Erişim';

  @override
  String get allFilesAccessEnabledSubtitle =>
      'Cihazdaki herhangi bir klasöre yazabilir';

  @override
  String get allFilesAccessDisabledSubtitle =>
      'Sadece medya klasörleriyle sınırlı';

  @override
  String get allFilesAccessDescription =>
      'Özel klasörlere kaydederken yazma hatası alıyorsanız bunu açın. Android 13 ve sonrasında bazı klasörlere erişim varsayılan olarak kısıtlanmıştır.';

  @override
  String get allFilesAccessDeniedMessage =>
      'İzin reddedildi. Lütfen sistem ayarlarından \'Tüm dosyalara erişim\' iznini manuel olarak verin.';

  @override
  String get allFilesAccessDisabledMessage =>
      'Tüm Dosyalara Erişim devre dışı. Uygulama sınırlı depolama izniyle çalışacak.';

  @override
  String get settingsLocalLibrary => 'Yerel Kitaplık';

  @override
  String get settingsLocalLibrarySubtitle =>
      'Telefonunuzdaki müzikleri tarayıp kopyaları bulun';

  @override
  String get settingsCache => 'Önbellek ve Depolama';

  @override
  String get settingsCacheSubtitle =>
      'Boyutu görüntüleyin ve gereksiz dosyaları temizleyin';

  @override
  String get libraryTitle => 'Yerel Kitaplık';

  @override
  String get libraryScanSettings => 'Tarama Ayarları';

  @override
  String get libraryEnableLocalLibrary => 'Yerel Kitaplık Taramasını Aç';

  @override
  String get libraryEnableLocalLibrarySubtitle =>
      'İndirme yaparken elinizde olan şarkıları takip eder';

  @override
  String get libraryFolder => 'Taranacak Klasör';

  @override
  String get libraryFolderHint => 'Klasör seçmek için dokunun';

  @override
  String get libraryShowDuplicateIndicator => 'Kopya İndikatörünü Göster';

  @override
  String get libraryShowDuplicateIndicatorSubtitle =>
      'Zaten indirmiş olduğunuz şarkıların yanında belirteç gösterir';

  @override
  String get libraryAutoScan => 'Otomatik Tarama';

  @override
  String get libraryAutoScanSubtitle =>
      'Cihazınıza yeni eklenen müzikleri otomatik olarak bulur';

  @override
  String get libraryAutoScanOff => 'Kapalı';

  @override
  String get libraryAutoScanOnOpen => 'Uygulama her açıldığında';

  @override
  String get libraryAutoScanDaily => 'Günde bir';

  @override
  String get libraryAutoScanWeekly => 'Haftada bir';

  @override
  String get libraryActions => 'İşlemler';

  @override
  String get libraryScan => 'Kitaplığı Tara';

  @override
  String get libraryScanSubtitle => 'Klasördeki müzik dosyalarını tarar';

  @override
  String get libraryScanSelectFolderFirst =>
      'Lütfen önce taranacak bir klasör seçin';

  @override
  String get libraryCleanupMissingFiles => 'Eksik Dosyaları Temizle';

  @override
  String get libraryCleanupMissingFilesSubtitle =>
      'Artık cihazınızda olmayan dosyaların kayıtlarını kaldırır';

  @override
  String get libraryClear => 'Kitaplığı Temizle';

  @override
  String get libraryClearSubtitle => 'Taranmış tüm şarkı kayıtlarını sıfırlar';

  @override
  String get libraryClearConfirmTitle => 'Kitaplık Temizlensin mi?';

  @override
  String get libraryClearConfirmMessage =>
      'Uygulamanın kaydettiği tüm taranmış şarkı verileri silinecek. (Gerçek müzik dosyalarınız SİLİNMEYECEK).';

  @override
  String get libraryAbout => 'Yerel Kitaplık Hakkında';

  @override
  String get libraryAboutDescription =>
      'İndirme yaparken kopyaları (zaten inmiş olanları) tespit etmek için mevcut müzik arşivinizi tarar. FLAC, M4A, MP3, Opus ve OGG formatlarını destekler. Bilgiler şarkı dosyalarının kendi etiketlerinden (ID3 tag vb.) okunur.';

  @override
  String libraryTracksUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şarkı',
      one: 'şarkı',
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
    return 'Son tarama: $time';
  }

  @override
  String get libraryLastScannedNever => 'Hiç taranmadı';

  @override
  String get libraryScanning => 'Taranıyor...';

  @override
  String get libraryScanFinalizing => 'Finalizing library...';

  @override
  String libraryScanProgress(String progress, int total) {
    return '%$progress (Toplam $total dosya)';
  }

  @override
  String get libraryInLibrary => 'Cihazda Var';

  @override
  String libraryRemovedMissingFiles(int count) {
    return 'Cihazda olmayan $count dosyanın kaydı temizlendi';
  }

  @override
  String get libraryCleared => 'Kitaplık kayıtları temizlendi';

  @override
  String get libraryStorageAccessRequired => 'Depolama İzni Gerekli';

  @override
  String get libraryStorageAccessMessage =>
      'Müzik kitaplığınızı taramak için SpotiFLAC\'ın depolama iznine ihtiyacı var. Lütfen ayarlardan izin verin.';

  @override
  String get libraryFolderNotExist => 'Seçilen klasör artık mevcut değil';

  @override
  String get librarySourceDownloaded => 'İndirildi';

  @override
  String get librarySourceLocal => 'Cihazdan';

  @override
  String get libraryFilterAll => 'Tümü';

  @override
  String get libraryFilterDownloaded => 'Uygulama İle İndirilenler';

  @override
  String get libraryFilterLocal => 'Yerel Dosyalar';

  @override
  String get libraryFilterTitle => 'Filtreler';

  @override
  String get libraryFilterReset => 'Sıfırla';

  @override
  String get libraryFilterApply => 'Uygula';

  @override
  String get libraryFilterSource => 'Kaynak';

  @override
  String get libraryFilterQuality => 'Kalite';

  @override
  String get libraryFilterQualityHiRes => 'Hi-Res (24-bit)';

  @override
  String get libraryFilterQualityCD => 'CD Kalitesi (16-bit)';

  @override
  String get libraryFilterQualityLossy => 'Kayıplı (Lossy)';

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
  String get libraryFilterSort => 'Sıralama';

  @override
  String get libraryFilterSortLatest => 'En Yeniler';

  @override
  String get libraryFilterSortOldest => 'En Eskiler';

  @override
  String get libraryFilterSortAlbumAsc => 'Album (A-Z)';

  @override
  String get libraryFilterSortAlbumDesc => 'Album (Z-A)';

  @override
  String get libraryFilterSortGenreAsc => 'Genre (A-Z)';

  @override
  String get libraryFilterSortGenreDesc => 'Genre (Z-A)';

  @override
  String get timeJustNow => 'Az önce';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika önce',
      one: '1 dakika önce',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat önce',
      one: '1 saat önce',
    );
    return '$_temp0';
  }

  @override
  String get tutorialWelcomeTitle => 'SpotiFLAC\'a Hoş Geldiniz!';

  @override
  String get tutorialWelcomeDesc =>
      'En sevdiğiniz müzikleri kayıpsız kalitede nasıl indireceğinizi öğrenelim. Bu kısa rehber size temelleri gösterecek.';

  @override
  String get tutorialWelcomeTip1 =>
      'Müzikleri bulmak için bir Spotify ya da Deezer bağlantısı yapıştırabilir veya adıyla arayabilirsiniz';

  @override
  String get tutorialWelcomeTip2 =>
      'Şarkıları Tidal, Qobuz veya Deezer altyapısıyla en yüksek kalitede (FLAC) indirin';

  @override
  String get tutorialWelcomeTip3 =>
      'Albüm kapağı, şarkı sözleri ve tüm şarkı verileri dosyanın içine otomatik olarak gömülür';

  @override
  String get tutorialSearchTitle => 'Müzik Bulmak Çok Kolay';

  @override
  String get tutorialSearchDesc =>
      'İstediğiniz müzikleri bulmanın iki basit yolu var.';

  @override
  String get tutorialDownloadTitle => 'Müzikleri İndirme';

  @override
  String get tutorialDownloadDesc =>
      'Şarkıları indirmek hızlı ve pürüzsüzdür. İşte süreç böyle işliyor:';

  @override
  String get tutorialLibraryTitle => 'Kişisel Kitaplığınız';

  @override
  String get tutorialLibraryDesc =>
      'İndirdiğiniz tüm müzikler Kitaplık sekmesinde düzenli bir şekilde tutulur.';

  @override
  String get tutorialLibraryTip1 =>
      'İndirme ilerlemenizi ve sırayı Kitaplık sekmesinden takip edin';

  @override
  String get tutorialLibraryTip2 =>
      'İndirdiğiniz şarkıyı favori müzik çalarınızda açmak için üzerine dokunun';

  @override
  String get tutorialLibraryTip3 =>
      'Daha rahat göz atmak için liste ve ızgara görünümleri arasında geçiş yapın';

  @override
  String get tutorialExtensionsTitle => 'Eklentilerle Güçlendirin';

  @override
  String get tutorialExtensionsDesc =>
      'Topluluğun geliştirdiği eklentilerle uygulamanın sınırlarını aşın.';

  @override
  String get tutorialExtensionsTip1 =>
      'İlginizi çekebilecek eklentileri keşfetmek için Mağaza sekmesine göz atın';

  @override
  String get tutorialExtensionsTip2 =>
      'Uygulamaya yepyeni indirme ve arama kaynakları ekleyin';

  @override
  String get tutorialExtensionsTip3 =>
      'Farklı şarkı sözü sağlayıcıları ve yepyeni özellikler kazanın';

  @override
  String get tutorialSettingsTitle => 'Deneyiminizi Kişiselleştirin';

  @override
  String get tutorialSettingsDesc =>
      'Uygulamanın nasıl davranacağını Ayarlar menüsünden zevkinize göre özelleştirin.';

  @override
  String get tutorialSettingsTip1 =>
      'İndirme konumunu ve klasörleme biçimini değiştirin';

  @override
  String get tutorialSettingsTip2 =>
      'Varsayılan ses kalitesini ve indirme formatınızı belirleyin';

  @override
  String get tutorialSettingsTip3 =>
      'Temayı, renkleri ve uygulamanın görünümünü ayarlayın';

  @override
  String get tutorialReadyMessage =>
      'İşte bu kadar! Artık favori müziklerinizi indirmeye hazırsınız.';

  @override
  String get libraryForceFullScan => 'Tam Taramaya Zorla';

  @override
  String get libraryForceFullScanSubtitle =>
      'Önbelleği yoksayarak klasördeki tüm dosyaları baştan tarar';

  @override
  String get cleanupOrphanedDownloads => 'Geçersiz İndirmeleri Temizle';

  @override
  String get cleanupOrphanedDownloadsSubtitle =>
      'Cihazdan silinmiş dosyalara ait eski geçmiş kayıtlarını kaldırır';

  @override
  String cleanupOrphanedDownloadsResult(int count) {
    return 'Geçmişten $count geçersiz kayıt kaldırıldı';
  }

  @override
  String get cleanupOrphanedDownloadsNone =>
      'Temizlenecek geçersiz kayıt bulunamadı';

  @override
  String get cacheTitle => 'Önbellek ve Depolama';

  @override
  String get cacheSummaryTitle => 'Önbellek Özeti';

  @override
  String get cacheSummarySubtitle =>
      'Önbelleği temizlemek indirdiğiniz müzik dosyalarını SİLMEZ.';

  @override
  String cacheEstimatedTotal(String size) {
    return 'Tahmini önbellek kullanımı: $size';
  }

  @override
  String get cacheSectionStorage => 'Önbelleğe Alınan Veriler';

  @override
  String get cacheSectionMaintenance => 'Bakım ve Temizlik';

  @override
  String get cacheAppDirectory => 'Uygulama Önbelleği';

  @override
  String get cacheAppDirectoryDesc =>
      'İnternet yanıtları, küçük resimler ve uygulamanın tuttuğu geçici dosyalar.';

  @override
  String get cacheTempDirectory => 'Geçici Klasör';

  @override
  String get cacheTempDirectoryDesc =>
      'İndirme ve ses dönüştürme işlemleri sırasında oluşan artık dosyalar.';

  @override
  String get cacheCoverImage => 'Kapak Resmi Önbelleği';

  @override
  String get cacheCoverImageDesc =>
      'Önceden yüklenmiş albüm kapakları. Silinirse tekrar görüntülediğinizde yeniden indirilir.';

  @override
  String get cacheLibraryCover => 'Kitaplık Kapağı Önbelleği';

  @override
  String get cacheLibraryCoverDesc =>
      'Yerel müzik dosyalarınızdan çıkarılmış kapaklar. Silinirse sonraki taramada yeniden oluşturulur.';

  @override
  String get cacheExploreFeed => 'Keşfet Akışı Önbelleği';

  @override
  String get cacheExploreFeedDesc =>
      'Keşfet sekmesindeki (yeni çıkanlar vb.) içerikler. Silerseniz sayfayı açtığınızda yenilenir.';

  @override
  String get cacheTrackLookup => 'Şarkı Kimliği Önbelleği';

  @override
  String get cacheTrackLookupDesc =>
      'Spotify/Deezer ID eşleşmeleri. Temizlerseniz ilk birkaç aramanız biraz yavaşlayabilir.';

  @override
  String get cacheCleanupUnusedDesc =>
      'Artık cihazınızda var olmayan dosyaların geçmiş kayıtlarını ve kitaplık verilerini temizler.';

  @override
  String get cacheNoData => 'Veri yok';

  @override
  String cacheSizeWithFiles(String size, int count) {
    return '$size ($count dosya)';
  }

  @override
  String cacheSizeOnly(String size) {
    return '$size';
  }

  @override
  String cacheEntries(int count) {
    return '$count kayıt';
  }

  @override
  String cacheClearSuccess(String target) {
    return 'Temizlendi: $target';
  }

  @override
  String get cacheClearConfirmTitle => 'Önbelleği Temizle?';

  @override
  String cacheClearConfirmMessage(String target) {
    return 'Sadece \"$target\" için olan önbellek silinecek. İndirdiğiniz hiçbir müzik dosyasına dokunulmayacak.';
  }

  @override
  String get cacheClearAllConfirmTitle => 'Tüm Önbelleği Temizle?';

  @override
  String get cacheClearAllConfirmMessage =>
      'Bu sayfadaki tüm önbellek kategorileri temizlenecek. İndirdiğiniz müzik dosyaları kesinlikle SİLİNMEYECEK.';

  @override
  String get cacheClearAll => 'Tüm Önbelleği Temizle';

  @override
  String get cacheCleanupUnused => 'Gereksiz Dosyaları Temizle';

  @override
  String get cacheCleanupUnusedSubtitle =>
      'Cihazda olmayan dosyalara ait geçmiş ve kitaplık kayıtlarını kaldırır';

  @override
  String cacheCleanupResult(int downloadCount, int libraryCount) {
    return 'Temizlik Bitti: $downloadCount geçersiz geçmiş, $libraryCount eksik kitaplık kaydı kaldırıldı';
  }

  @override
  String get cacheRefreshStats => 'Boyutları Yenile';

  @override
  String get trackSaveCoverArt => 'Albüm Kapağını Kaydet';

  @override
  String get trackSaveCoverArtSubtitle =>
      'Albüm kapağını resim (.jpg) dosyası olarak dışa aktar';

  @override
  String get trackSaveLyrics => 'Şarkı Sözlerini Kaydet (.lrc)';

  @override
  String get trackSaveLyricsSubtitle =>
      'Şarkı sözlerini çekip .lrc dosyası olarak kaydeder';

  @override
  String get trackSaveLyricsProgress => 'Şarkı sözleri kaydediliyor...';

  @override
  String get trackReEnrich => 'Bilgileri İnternetten Güncelle (Re-enrich)';

  @override
  String get trackReEnrichOnlineSubtitle =>
      'İnternetten şarkı verilerini (metadata) bulup dosyaya yeniden işler';

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
  String get trackEditMetadata => 'Şarkı Bilgilerini Düzenle';

  @override
  String trackCoverSaved(String fileName) {
    return 'Kapak resmi \"$fileName\" adıyla kaydedildi';
  }

  @override
  String get trackCoverNoSource => 'Geçerli bir kapak resmi kaynağı bulunamadı';

  @override
  String trackLyricsSaved(String fileName) {
    return 'Sözler \"$fileName\" adıyla kaydedildi';
  }

  @override
  String get trackReEnrichProgress =>
      'Şarkı bilgileri (metadata) güncelleniyor...';

  @override
  String get trackReEnrichSearching =>
      'İnternette şarkı bilgisi (metadata) aranıyor...';

  @override
  String get trackReEnrichSuccess =>
      'Şarkı bilgileri dosyaya başarıyla işlendi';

  @override
  String get trackReEnrichFfmpegFailed =>
      'Sözleri (veya verileri) dosyaya yazarken hata oluştu';

  @override
  String get queueFlacAction => 'Bunu FLAC Olarak İndir';

  @override
  String queueFlacConfirmMessage(int count) {
    return 'Seçilen şarkılar için internette FLAC eşleşmesi aranacak ve indirme sırasına eklenecek.\n\nMevcut dosyalarınıza dokunulmayacak veya silinmeyecek.\n\nSadece yüksek oranda eşleşenler otomatik olarak sıraya eklenir.\n\n$count şarkı seçildi';
  }

  @override
  String queueFlacFindingProgress(int current, int total) {
    return 'FLAC eşleşmeleri aranıyor... ($current/$total)';
  }

  @override
  String get queueFlacNoReliableMatches =>
      'Seçiminiz için internette güvenilir bir eşleşme bulunamadı';

  @override
  String queueFlacQueuedWithSkipped(int addedCount, int skippedCount) {
    return '$addedCount şarkı sıraya eklendi, $skippedCount şarkı eşleşmediği için atlandı';
  }

  @override
  String trackSaveFailed(String error) {
    return 'İşlem başarısız: $error';
  }

  @override
  String get trackConvertFormat => 'Ses Formatını Dönüştür';

  @override
  String get trackConvertFormatSubtitle =>
      'Dosyayı MP3, Opus, ALAC veya FLAC formatına çevirin';

  @override
  String get trackConvertTitle => 'Sesi Dönüştür';

  @override
  String get trackConvertTargetFormat => 'Hedef Format';

  @override
  String get trackConvertBitrate => 'Bit Hızı (Kalite)';

  @override
  String get trackConvertConfirmTitle => 'Dönüşümü Onayla';

  @override
  String trackConvertConfirmMessage(
    String sourceFormat,
    String targetFormat,
    String bitrate,
  ) {
    return '$sourceFormat formatından $targetFormat formatına ($bitrate) dönüştürülsün mü?\n\nDönüşüm bittikten sonra orijinal dosya tamamen silinecektir.';
  }

  @override
  String trackConvertConfirmMessageLossless(
    String sourceFormat,
    String targetFormat,
  ) {
    return '$sourceFormat formatından $targetFormat formatına dönüştürülsün mü? (Kayıpsız format, kalite kaybı yaşanmaz)\n\nDönüşüm bittikten sonra orijinal dosya tamamen silinecektir.';
  }

  @override
  String get trackConvertLosslessHint =>
      'Kayıpsız bir formata dönüştürülüyor (Kalite düşüşü olmaz)';

  @override
  String get trackConvertConverting => 'Ses dönüştürülüyor...';

  @override
  String trackConvertSuccess(String format) {
    return 'Dosya başarıyla $format formatına çevrildi';
  }

  @override
  String get trackConvertFailed => 'Dönüşüm işlemi başarısız oldu';

  @override
  String get cueSplitTitle => 'CUE Dosyasını Parçalara Böl';

  @override
  String get cueSplitSubtitle =>
      'Tek parça olan CUE+FLAC dosyasını ayrı şarkılara böler';

  @override
  String cueSplitAlbum(String album) {
    return 'Albüm: $album';
  }

  @override
  String cueSplitArtist(String artist) {
    return 'Sanatçı: $artist';
  }

  @override
  String cueSplitTrackCount(int count) {
    return '$count şarkı var';
  }

  @override
  String get cueSplitConfirmTitle => 'CUE Dosyasını Böl';

  @override
  String cueSplitConfirmMessage(String album, int count) {
    return '\"$album\" albümünü $count ayrı FLAC dosyasına bölmek istiyor musunuz?\n\nYeni dosyalar orijinal dosyanın bulunduğu klasöre kaydedilecektir.';
  }

  @override
  String cueSplitSplitting(int current, int total) {
    return 'CUE dosyası ayrıştırılıyor... ($current/$total)';
  }

  @override
  String cueSplitSuccess(int count) {
    return 'Dosya başarıyla $count şarkıya bölündü';
  }

  @override
  String get cueSplitFailed => 'CUE bölme işlemi başarısız';

  @override
  String get cueSplitNoAudioFile =>
      'Bu CUE ile eşleşen bir ses dosyası bulunamadı';

  @override
  String get cueSplitButton => 'Şarkılara Böl';

  @override
  String get actionCreate => 'Oluştur';

  @override
  String get collectionFoldersTitle => 'Klasörlerim';

  @override
  String get collectionWishlist => 'İstek Listesi';

  @override
  String get collectionLoved => 'Favoriler';

  @override
  String get collectionPlaylists => 'Çalma Listeleri';

  @override
  String get collectionPlaylist => 'Çalma Listesi';

  @override
  String get collectionAddToPlaylist => 'Çalma listesine ekle';

  @override
  String get collectionCreatePlaylist => 'Yeni çalma listesi oluştur';

  @override
  String get collectionNoPlaylistsYet => 'Henüz listeniz yok';

  @override
  String get collectionNoPlaylistsSubtitle =>
      'Müziklerinizi kategorize etmek için bir çalma listesi oluşturun';

  @override
  String collectionPlaylistTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şarkı',
      one: '1 şarkı',
    );
    return '$_temp0';
  }

  @override
  String collectionAddedToPlaylist(String playlistName) {
    return '\"$playlistName\" listesine eklendi';
  }

  @override
  String collectionAlreadyInPlaylist(String playlistName) {
    return 'Zaten \"$playlistName\" listesinde var';
  }

  @override
  String get collectionPlaylistCreated => 'Çalma listesi oluşturuldu';

  @override
  String get collectionPlaylistNameHint => 'Çalma listesi adı';

  @override
  String get collectionPlaylistNameRequired =>
      'Lütfen liste için bir isim girin';

  @override
  String get collectionRenamePlaylist => 'Yeniden adlandır';

  @override
  String get collectionDeletePlaylist => 'Listeyi sil';

  @override
  String collectionDeletePlaylistMessage(String playlistName) {
    return '\"$playlistName\" listesini ve içindeki tüm şarkıları silmek istiyor musunuz?';
  }

  @override
  String get collectionPlaylistDeleted => 'Çalma listesi silindi';

  @override
  String get collectionPlaylistRenamed => 'Çalma listesi adı değiştirildi';

  @override
  String get collectionWishlistEmptyTitle => 'İstek Listeniz boş';

  @override
  String get collectionWishlistEmptySubtitle =>
      'Daha sonra indirmek istediğiniz şarkıların yanındaki (+) simgesine dokunun';

  @override
  String get collectionLovedEmptyTitle => 'Favori klasörünüz boş';

  @override
  String get collectionLovedEmptySubtitle =>
      'Sevdiğiniz şarkıları burada toplamak için kalp ikonuna dokunun';

  @override
  String get collectionPlaylistEmptyTitle => 'Bu çalma listesi boş';

  @override
  String get collectionPlaylistEmptySubtitle =>
      'Buraya eklemek için istediğiniz şarkının üzerindeki (+) butonuna basılı tutun';

  @override
  String get collectionRemoveFromPlaylist => 'Çalma listesinden çıkar';

  @override
  String get collectionRemoveFromFolder => 'Klasörden çıkar';

  @override
  String collectionRemoved(String trackName) {
    return '\"$trackName\" listeden çıkarıldı';
  }

  @override
  String collectionAddedToLoved(String trackName) {
    return '\"$trackName\" Favoriler klasörüne eklendi';
  }

  @override
  String collectionRemovedFromLoved(String trackName) {
    return '\"$trackName\" Favorilerinizden çıkarıldı';
  }

  @override
  String collectionAddedToWishlist(String trackName) {
    return '\"$trackName\" İstek Listenize eklendi';
  }

  @override
  String collectionRemovedFromWishlist(String trackName) {
    return '\"$trackName\" İstek Listenizden çıkarıldı';
  }

  @override
  String get trackOptionAddToLoved => 'Favorilere Ekle';

  @override
  String get trackOptionRemoveFromLoved => 'Favorilerden Çıkar';

  @override
  String get trackOptionAddToWishlist => 'İstek Listesine Ekle';

  @override
  String get trackOptionRemoveFromWishlist => 'İstek Listesinden Çıkar';

  @override
  String get collectionPlaylistChangeCover => 'Kapak resmini değiştir';

  @override
  String get collectionPlaylistRemoveCover => 'Kapak resmini kaldır';

  @override
  String selectionShareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şarkıyı',
      one: 'şarkıyı',
    );
    return '$count $_temp0 paylaş';
  }

  @override
  String get selectionShareNoFiles => 'Paylaşılabilir bir dosya bulunamadı';

  @override
  String selectionConvertCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şarkıyı',
      one: 'şarkıyı',
    );
    return '$count $_temp0 dönüştür';
  }

  @override
  String get selectionConvertNoConvertible =>
      'Dönüştürülebilir formatta bir şarkı seçilmedi';

  @override
  String get selectionBatchConvertConfirmTitle => 'Toplu Dönüştürme';

  @override
  String selectionBatchConvertConfirmMessage(
    int count,
    String format,
    String bitrate,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şarkıyı',
      one: 'şarkıyı',
    );
    return '$count $_temp0 $format formatına ($bitrate) dönüştürmek istiyor musunuz?\n\nDönüşüm işlemi bittikten sonra orijinal dosyalar tamamen silinecektir.';
  }

  @override
  String selectionBatchConvertConfirmMessageLossless(int count, String format) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şarkıyı',
      one: 'şarkıyı',
    );
    return '$count $_temp0 $format formatına dönüştürmek istiyor musunuz? (Kayıpsız işlem — kalite kaybı olmaz)\n\nDönüşüm işlemi bittikten sonra orijinal dosyalar tamamen silinecektir.';
  }

  @override
  String selectionBatchConvertProgress(int current, int total) {
    return 'Dönüştürülüyor: $current / $total...';
  }

  @override
  String selectionBatchConvertSuccess(int success, int total, String format) {
    return '$total şarkıdan $success tanesi $format formatına dönüştürüldü';
  }

  @override
  String downloadedAlbumDownloadedCount(int count) {
    return '$count tanesi indirildi';
  }

  @override
  String get downloadUseAlbumArtistForFoldersAlbumSubtitle =>
      'Sanatçı klasörleri için Albüm Sanatçısı adı kullanılır';

  @override
  String get downloadUseAlbumArtistForFoldersTrackSubtitle =>
      'Sanatçı klasörleri için sadece Şarkı Sanatçısı adı kullanılır';

  @override
  String get lyricsProvidersTitle => 'Şarkı Sözü Sağlayıcıları';

  @override
  String get lyricsProvidersDescription =>
      'Şarkı sözü kaynaklarını açıp kapatın veya sıralamalarını değiştirin. Uygulama sözleri bulana kadar sağlayıcıları yukarıdan aşağıya doğru sırayla dener.';

  @override
  String get lyricsProvidersInfoText =>
      'Mağazadan yüklediğiniz eklentiler her zaman varsayılan yerleşik sağlayıcılardan önce çalışır. En az bir sağlayıcı her zaman açık kalmalıdır.';

  @override
  String lyricsProvidersEnabledSection(int count) {
    return 'Açık ($count)';
  }

  @override
  String lyricsProvidersDisabledSection(int count) {
    return 'Kapalı ($count)';
  }

  @override
  String get lyricsProvidersAtLeastOne =>
      'En az bir sağlayıcı her zaman açık kalmalıdır';

  @override
  String get lyricsProvidersSaved =>
      'Şarkı sözü sağlayıcılarının sıralaması kaydedildi';

  @override
  String get lyricsProvidersDiscardContent =>
      'Kaydedilmemiş değişiklikleriniz iptal edilecek.';

  @override
  String get lyricsProviderLrclibDesc =>
      'Açık kaynaklı, senkronize şarkı sözü veritabanı';

  @override
  String get lyricsProviderNeteaseDesc =>
      'NetEase Cloud Music (Özellikle Asya müzikleri için ideal)';

  @override
  String get lyricsProviderMusixmatchDesc =>
      'En geniş şarkı sözü arşivi (Çok dilli)';

  @override
  String get lyricsProviderAppleMusicDesc =>
      'Kelime kelime akan senkronize sözler (Proxy üzerinden)';

  @override
  String get lyricsProviderQqMusicDesc =>
      'QQ Music (Özellikle Çince şarkılar için, Proxy üzerinden)';

  @override
  String get lyricsProviderExtensionDesc => 'Eklenti ile sağlanan kaynak';

  @override
  String get safMigrationTitle => 'Depolama Sistem Güncellemesi';

  @override
  String get safMigrationMessage1 =>
      'SpotiFLAC artık indirme işlemleri için Android\'in yeni Depolama Erişim Çerçevesi\'ni (SAF) kullanıyor. Bu sayede Android 10 ve üzeri sürümlerdeki \"izin reddedildi\" hataları ortadan kalkıyor.';

  @override
  String get safMigrationMessage2 =>
      'Yeni depolama sistemine geçiş yapmak için lütfen indirme klasörünüzü tekrar seçin.';

  @override
  String get safMigrationSuccess =>
      'İndirme klasörü başarıyla yeni (SAF) moda geçirildi';

  @override
  String get settingsDonate => 'Bağış Yap';

  @override
  String get settingsDonateSubtitle =>
      'SpotiFLAC-Mobile gelişimine destek olun';

  @override
  String get tooltipLoveAll => 'Tümünü Favorilere Ekle';

  @override
  String get tooltipAddToPlaylist => 'Çalma Listesine Ekle';

  @override
  String snackbarRemovedTracksFromLoved(int count) {
    return '$count şarkı Favoriler\'den çıkarıldı';
  }

  @override
  String snackbarAddedTracksToLoved(int count) {
    return '$count şarkı Favoriler\'e eklendi';
  }

  @override
  String get dialogDownloadAllTitle => 'Tümünü İndir';

  @override
  String dialogDownloadAllMessage(int count) {
    return 'Bu listedeki $count şarkı indirilsin mi?';
  }

  @override
  String get homeSkipAlreadyDownloaded => 'Daha önce inmiş olan şarkıları atla';

  @override
  String get homeGoToAlbum => 'Albüme Git';

  @override
  String get homeAlbumInfoUnavailable => 'Albüm bilgisine ulaşılamıyor';

  @override
  String get snackbarLoadingCueSheet => 'CUE dosyası yükleniyor...';

  @override
  String get snackbarMetadataSaved =>
      'Şarkı verileri dosyaya başarıyla kaydedildi';

  @override
  String get snackbarFailedToEmbedLyrics => 'Şarkı sözleri dosyaya eklenemedi';

  @override
  String get snackbarFailedToWriteStorage =>
      'Değişiklikler asıl dosyaya yazılamadı';

  @override
  String snackbarError(String error) {
    return 'Hata: $error';
  }

  @override
  String get snackbarNoActionDefined =>
      'Bu buton için henüz bir işlev tanımlanmamış';

  @override
  String get noTracksFoundForAlbum => 'Bu albümün içinde hiç şarkı bulunamadı';

  @override
  String get downloadLocationSubtitle =>
      'İndirdiğiniz dosyaların cihazınızda nasıl tutulacağını seçin.';

  @override
  String get storageModeAppFolder => 'Uygulama Klasörü';

  @override
  String get storageModeAppFolderSubtitle =>
      'Telefonunuzdaki varsayılan Müzik klasörünü kullanır';

  @override
  String get storageModeSaf => 'SAF ile Özel Klasör (Önerilen)';

  @override
  String get storageModeSafSubtitle =>
      'Android dosya seçicisi ile cihazınızdan dilediğiniz klasörü seçin';

  @override
  String get downloadFilenameDescription =>
      'Şarkıların cihazınızda hangi dosya adıyla kaydedileceğini özelleştirin.';

  @override
  String get downloadFilenameInsertTag => 'Eklemek için dokunun:';

  @override
  String get downloadSeparateSinglesEnabled =>
      'Sanatçı klasörünün içinde Single\'ları ayrı bir klasöre ayırır';

  @override
  String get downloadSeparateSinglesDisabled =>
      'Single\'lar ile albümler aynı yerde durur';

  @override
  String get downloadArtistNameFilters => 'Sanatçı Adı Filtreleri';

  @override
  String get downloadCreatePlaylistSourceFolder =>
      'Çalma Listeleri İçin Ana Klasör Oluştur';

  @override
  String get downloadCreatePlaylistSourceFolderEnabled =>
      'Çalma listesi indirildiğinde en dışa \'Çalma Listesi Adı\' isimli bir klasör oluşturur ve içini normal düzeninize göre dizer.';

  @override
  String get downloadCreatePlaylistSourceFolderDisabled =>
      'Çalma listesindeki şarkılar da diğerleri gibi doğrudan albüm ve sanatçı klasörlerinize atılır.';

  @override
  String get downloadCreatePlaylistSourceFolderRedundant =>
      'Klasör Düzeni zaten \'Çalma Listesine Göre\' ayarlı olduğu için bu seçenek pasiftir.';

  @override
  String get downloadSongLinkRegion => 'SongLink Arama Bölgesi';

  @override
  String get downloadNetworkCompatibilityMode => 'Ağ Uyumluluk Modu';

  @override
  String get downloadNetworkCompatibilityModeEnabled =>
      'Açık: Bağlantı HTTP ile denenir ve geçersiz sertifikalar kabul edilir (Güvensiz ama çözümleyici)';

  @override
  String get downloadNetworkCompatibilityModeDisabled =>
      'Kapalı: Katı HTTPS kuralları uygulanır (Önerilen)';

  @override
  String get downloadSelectServiceToEnable =>
      'Seçenekleri açmak için yerleşik bir sağlayıcı seçin';

  @override
  String get downloadSelectTidalQobuz =>
      'Kaliteyi ayarlamak için lütfen yukarıdan Tidal veya Qobuz seçin';

  @override
  String get downloadEmbedLyricsDisabled =>
      'Şarkı Verilerini Dosyaya Gömme ayarı kapalıyken kullanılamaz';

  @override
  String get downloadNeteaseIncludeTranslation =>
      'Netease: Çevirileri Dahil Et';

  @override
  String get downloadNeteaseIncludeTranslationEnabled =>
      'Varsa, orijinal sözlere çevirilerini ekler';

  @override
  String get downloadNeteaseIncludeTranslationDisabled =>
      'Sadece şarkının kendi sözleri kullanılır';

  @override
  String get downloadNeteaseIncludeRomanization =>
      'Netease: Okunuşları (Romanizasyon) Dahil Et';

  @override
  String get downloadNeteaseIncludeRomanizationEnabled =>
      'Varsa, Asya şarkıları için Latin alfabesi okunuşlarını ekler';

  @override
  String get downloadNeteaseIncludeRomanizationDisabled => 'Kapalı';

  @override
  String get downloadAppleQqMultiPerson =>
      'Apple/QQ: Çoklu Sanatçı Düzeni (Kelime kelime akan sözler)';

  @override
  String get downloadAppleQqMultiPersonEnabled =>
      'Gelişmiş v1/v2 ve arka plan [bg:] etiketlerini açık tutar';

  @override
  String get downloadAppleQqMultiPersonDisabled =>
      'Standart kelime kelime senkronizasyon kullanır';

  @override
  String get downloadMusixmatchLanguage => 'Musixmatch Tercih Edilen Dil';

  @override
  String get downloadMusixmatchLanguageAuto => 'Otomatik (Orijinal Dil)';

  @override
  String get downloadFilterContributing =>
      'Albüm Sanatçısı etiketinde konuk sanatçıları filtrele';

  @override
  String get downloadFilterContributingEnabled =>
      'Albüm Sanatçısı verisinde sadece ana sanatçı ismi tutulur';

  @override
  String get downloadFilterContributingDisabled =>
      'Tüm sanatçı isimlerini olduğu gibi korur';

  @override
  String get downloadProvidersNoneEnabled => 'Hiçbir sağlayıcı açık değil';

  @override
  String get downloadMusixmatchLanguageCode => 'Dil Kodu';

  @override
  String get downloadMusixmatchLanguageHint => 'auto / tr / en / es';

  @override
  String get downloadMusixmatchLanguageDesc =>
      'Tercih ettiğiniz söz dilini belirleyin (örnek: tr, en, es). Otomatik seçim için boş bırakın.';

  @override
  String get downloadMusixmatchAuto => 'Otomatik';

  @override
  String get downloadNetworkAnySubtitle => 'Wi-Fi + Mobil Veri üzerinden indir';

  @override
  String get downloadNetworkWifiOnlySubtitle =>
      'Wi-Fi\'dan çıkarsanız indirmeler duraklatılır';

  @override
  String get downloadSongLinkRegionDesc =>
      'Şarkı aramalarında SongLink API\'ye iletilecek ülke kodunu belirler.';

  @override
  String get snackbarUnsupportedAudioFormat => 'Bu ses formatı desteklenmiyor';

  @override
  String get cacheRefresh => 'Yenile';

  @override
  String dialogDownloadPlaylistsMessage(int trackCount, int playlistCount) {
    String _temp0 = intl.Intl.pluralLogic(
      playlistCount,
      locale: localeName,
      other: 'listeden',
      one: 'listeden',
    );
    return '$playlistCount $_temp0 toplam $trackCount şarkı indirilsin mi?';
  }

  @override
  String bulkDownloadPlaylistsButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'listeyi',
      one: 'listeyi',
    );
    return 'Seçili $count $_temp0 indir';
  }

  @override
  String get bulkDownloadSelectPlaylists =>
      'İndirilecek çalma listelerini seçin';

  @override
  String get snackbarSelectedPlaylistsEmpty =>
      'Seçilen çalma listelerinde şarkı yok';

  @override
  String playlistsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çalma listesi',
      one: '1 çalma listesi',
    );
    return '$_temp0';
  }

  @override
  String get editMetadataAutoFill => 'İnternetten Otomatik Doldur';

  @override
  String get editMetadataAutoFillDesc =>
      'İnternetteki verilerle otomatik doldurulmasını istediğiniz alanları seçin';

  @override
  String get editMetadataAutoFillFetch => 'Bul ve Doldur';

  @override
  String get editMetadataAutoFillSearching => 'İnternette eşleşme aranıyor...';

  @override
  String get editMetadataAutoFillNoResults =>
      'İnternette bu şarkıya uygun bir veri bulunamadı';

  @override
  String editMetadataAutoFillDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'alan',
      one: 'alan',
    );
    return 'Şarkı verilerinden $count $_temp0 internetten çekilerek dolduruldu';
  }

  @override
  String get editMetadataAutoFillNoneSelected =>
      'Lütfen otomatik doldurulacak en az bir alan seçin';

  @override
  String get editMetadataFieldTitle => 'Şarkı Adı';

  @override
  String get editMetadataFieldArtist => 'Sanatçı';

  @override
  String get editMetadataFieldAlbum => 'Albüm';

  @override
  String get editMetadataFieldAlbumArtist => 'Albüm Sanatçısı';

  @override
  String get editMetadataFieldDate => 'Tarih';

  @override
  String get editMetadataFieldTrackNum => 'Şarkı Sırası';

  @override
  String get editMetadataFieldDiscNum => 'Disk #';

  @override
  String get editMetadataFieldGenre => 'Tür';

  @override
  String get editMetadataFieldIsrc => 'ISRC';

  @override
  String get editMetadataFieldLabel => 'Plak Şirketi';

  @override
  String get editMetadataFieldCopyright => 'Telif Hakkı';

  @override
  String get editMetadataFieldCover => 'Albüm Kapağı';

  @override
  String get editMetadataSelectAll => 'Tümü';

  @override
  String get editMetadataSelectEmpty => 'Sadece boşlar';

  @override
  String queueDownloadingCount(int count) {
    return 'Şu An İnenler ($count)';
  }

  @override
  String get queueDownloadedHeader => 'İnenler';

  @override
  String get queueFilteringIndicator => 'Filtreleniyor...';

  @override
  String queueTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şarkı',
      one: '1 şarkı',
    );
    return '$_temp0';
  }

  @override
  String queueAlbumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albüm',
      one: '1 albüm',
    );
    return '$_temp0';
  }

  @override
  String get queueEmptyAlbums => 'İndirilmiş bir albüm yok';

  @override
  String get queueEmptyAlbumsSubtitle =>
      'Bir albümden birden fazla şarkı indirdiğinizde burada görünecektir.';

  @override
  String get queueEmptySingles => 'İndirilmiş bir şarkı yok';

  @override
  String get queueEmptySinglesSubtitle =>
      'Tek tek indirdiğiniz şarkılar burada görünecektir.';

  @override
  String get queueEmptyHistory => 'İndirme geçmişi boş';

  @override
  String get queueEmptyHistorySubtitle =>
      'İndirdiğiniz şarkılar başarıyla tamamlandığında burada görünecektir.';

  @override
  String get selectionAllPlaylistsSelected => 'Tüm listeler seçildi';

  @override
  String get selectionTapPlaylistsToSelect => 'Seçmek için listelere dokunun';

  @override
  String get selectionSelectPlaylistsToDelete =>
      'Silinecek çalma listelerini seçin';

  @override
  String get audioAnalysisTitle => 'Ses Kalitesi Analizi';

  @override
  String get audioAnalysisDescription =>
      'Kayıpsız kalite doğrulaması için spektrum analizi yapın';

  @override
  String get audioAnalysisAnalyzing => 'Ses dosyası analiz ediliyor...';

  @override
  String get audioAnalysisSampleRate => 'Örnekleme Hızı (Sample Rate)';

  @override
  String get audioAnalysisBitDepth => 'Bit Derinliği';

  @override
  String get audioAnalysisChannels => 'Kanal';

  @override
  String get audioAnalysisDuration => 'Süre';

  @override
  String get audioAnalysisNyquist => 'Nyquist Frekansı';

  @override
  String get audioAnalysisFileSize => 'Boyut';

  @override
  String get audioAnalysisDynamicRange => 'Dinamik Aralık';

  @override
  String get audioAnalysisPeak => 'Tepe Değeri (Peak)';

  @override
  String get audioAnalysisRms => 'Ortalama Değer (RMS)';

  @override
  String get audioAnalysisSamples => 'Toplam Örneklem (Samples)';

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
