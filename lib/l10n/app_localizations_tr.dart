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
  String get appDescription =>
      'Spotify şarkılarını Tidal, Qobuz ve Amazon Music\'den yüksek kalitede indir.';

  @override
  String get navHome => 'Ara';

  @override
  String get navHistory => 'Geçmiş';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get navStore => 'Dükkan';

  @override
  String get homeTitle => 'Ara';

  @override
  String get homeSearchHint => 'Spotify URL\'i yapıştır veya ara...';

  @override
  String homeSearchHintExtension(String extensionName) {
    return '$extensionName ile arat...';
  }

  @override
  String get homeSubtitle => 'Spotify linki yapıştır veya isimle arat';

  @override
  String get homeSupports =>
      'Desteklenen linkler: Şarkı, Albüm, Çalma Listesi, Sanatçı linkleri';

  @override
  String get homeRecent => 'En son';

  @override
  String get historyTitle => 'Geçmiş';

  @override
  String historyDownloading(int count) {
    return '($count) tane indiriliyor';
  }

  @override
  String get historyDownloaded => 'İndirildi';

  @override
  String get historyFilterAll => 'Tümü';

  @override
  String get historyFilterAlbums => 'Albümler';

  @override
  String get historyFilterSingles => 'Single\'lar';

  @override
  String historyTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şarkı',
      one: '1 şarkı',
    );
    return '$_temp0';
  }

  @override
  String historyAlbumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albüm',
      one: '1 albüm',
    );
    return '$_temp0';
  }

  @override
  String get historyNoDownloads => 'İndirme geçmişi yok';

  @override
  String get historyNoDownloadsSubtitle =>
      'İndirilen şarkılar burada gözükecek';

  @override
  String get historyNoAlbums => 'İndirilen albüm yok';

  @override
  String get historyNoAlbumsSubtitle =>
      'Albümleri burada görmek için bir albümden birden fazla şarkı indir';

  @override
  String get historyNoSingles => 'Single indirilmemiş';

  @override
  String get historyNoSinglesSubtitle => 'Single şarkılar burada gözükecek';

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
  String get downloadLocation => 'İndirme Konumu';

  @override
  String get downloadLocationSubtitle =>
      'Dosyaları nereye kaydedeceğinizi seçin';

  @override
  String get downloadLocationDefault => 'Varsayılan dizin';

  @override
  String get downloadDefaultService => 'Varsayılan Hizmet';

  @override
  String get downloadDefaultServiceSubtitle =>
      'İndirmeler için kullanılan hizmet';

  @override
  String get downloadDefaultQuality => 'Varsayılan Kalite';

  @override
  String get downloadAskQuality => 'İndirmeden Önce Kaliteyi Sor';

  @override
  String get downloadAskQualitySubtitle =>
      'Her indirmeden önce kalite seçim ekranını göster';

  @override
  String get downloadFilenameFormat => 'Dosya adı formatı';

  @override
  String get downloadFolderOrganization => 'Dosya Organizasyonu';

  @override
  String get downloadSeparateSingles => 'Single\'ları Ayır';

  @override
  String get downloadSeparateSinglesSubtitle =>
      'Single şarkıları ayrı dosyaya koy';

  @override
  String get qualityBest => 'Mevcut en iyi';

  @override
  String get qualityFlac => 'FLAC';

  @override
  String get quality320 => '320 kbps';

  @override
  String get quality128 => '128 kbps';

  @override
  String get appearanceTitle => 'Görünüm';

  @override
  String get appearanceTheme => 'Tema';

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
  String get appearanceAccentColor => 'Vurgu Rengi';

  @override
  String get appearanceHistoryView => 'Geçmiş Düzeni';

  @override
  String get appearanceHistoryViewList => 'Liste';

  @override
  String get appearanceHistoryViewGrid => 'Izgara';

  @override
  String get optionsTitle => 'Seçenekler';

  @override
  String get optionsSearchSource => 'Arama Kaynağı';

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
  String get extensionsTitle => 'Eklentiler';

  @override
  String get extensionsInstalled => 'Kurulu Eklentiler';

  @override
  String get extensionsNone => 'Hiçbir eklenti kurulmamış';

  @override
  String get extensionsNoneSubtitle => 'Dükkan sekmesinden eklenti indir';

  @override
  String get extensionsEnabled => 'Etkin';

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
  String get extensionsSetAsSearch => 'Arama Sağlayıcı olarak Ayarla';

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
  String get aboutSupport => 'Destek';

  @override
  String get aboutBuyMeCoffee => 'Bana bir kahve ısmarla';

  @override
  String get aboutBuyMeCoffeeSubtitle => 'Ko-fi üzerinden uygulamayı destekle';

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
  String get aboutDoubleDouble => 'DoubleDouble';

  @override
  String get aboutDoubleDoubleDesc =>
      'Amazom Music indirmeleri için harika bir API. Ücretsiz yaptığın için teşekkürler!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'En iyi Qobuz streaming API\'ı. Yüksek kalite indirmeler bunun sayesinde!';

  @override
  String get aboutAppDescription =>
      'Spotify şarkılarını Tidal, Qobuz ve Amazon Music\'den yüksek kalitede indir.';

  @override
  String get albumTitle => 'Albüm';

  @override
  String albumTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şarkı',
      one: '1 şarkı',
    );
    return '$_temp0';
  }

  @override
  String get albumDownloadAll => 'Tümünü İndir';

  @override
  String get albumDownloadRemaining => 'Kalanını İndir';

  @override
  String get playlistTitle => 'Çalma Listesi';

  @override
  String get artistTitle => 'Sanatçı';

  @override
  String get artistAlbums => 'Albümler';

  @override
  String get artistSingles => 'Single\'lar ve EP\'ler';

  @override
  String get artistCompilations => 'Derlemeler';

  @override
  String artistReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yayın',
      one: '1 yayın',
    );
    return '$_temp0';
  }

  @override
  String get artistPopular => 'Popüler';

  @override
  String artistMonthlyListeners(String count) {
    return 'Aylık $count dinleyici';
  }

  @override
  String get trackMetadataTitle => 'Şarkı Bilgisi';

  @override
  String get trackMetadataArtist => 'Sanatçı';

  @override
  String get trackMetadataAlbum => 'Albüm';

  @override
  String get trackMetadataDuration => 'Süre';

  @override
  String get trackMetadataQuality => 'Kalite';

  @override
  String get trackMetadataPath => 'Dosya Yolu';

  @override
  String get trackMetadataDownloadedAt => 'İndirme tarihi';

  @override
  String get trackMetadataService => 'Hizmet';

  @override
  String get trackMetadataPlay => 'Oynat';

  @override
  String get trackMetadataShare => 'Paylaş';

  @override
  String get trackMetadataDelete => 'Sil';

  @override
  String get trackMetadataRedownload => 'Yeniden İndir';

  @override
  String get trackMetadataOpenFolder => 'Klasörü Aç';

  @override
  String get setupTitle => 'SpotiFLAC\'e Hoşgeldiniz';

  @override
  String get setupSubtitle => 'Hadi başlayalım';

  @override
  String get setupStoragePermission => 'Depolama İzni';

  @override
  String get setupStoragePermissionSubtitle =>
      'İndirilen dosyaları kaydetmek için gerekli';

  @override
  String get setupStoragePermissionGranted => 'İzin verildi';

  @override
  String get setupStoragePermissionDenied => 'İzin reddedildi';

  @override
  String get setupGrantPermission => 'İzin Ver';

  @override
  String get setupDownloadLocation => 'İndirme Konumu';

  @override
  String get setupChooseFolder => 'Klasör Seç';

  @override
  String get setupContinue => 'Devam';

  @override
  String get setupSkip => 'Şimdilik atla';

  @override
  String get setupStorageAccessRequired => 'Depolama Erişimi Gerekli';

  @override
  String get setupStorageAccessMessage =>
      'SpotiFLAC\'ın şarkıları seçili klasörünüze kaydetmek için \"Bütün dosyalara eriş\" iznine ihtiyacı var.';

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
  String get setupSelectDownloadFolder => 'İndirilecek Klasörü Seç';

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
  String get setupDownloadInFlac => 'Spotify şarkılarını FLAC olarak indirin';

  @override
  String get setupStepStorage => 'Depolama';

  @override
  String get setupStepNotification => 'Bildirim';

  @override
  String get setupStepFolder => 'Klasör';

  @override
  String get setupStepSpotify => 'Spotify';

  @override
  String get setupStepPermission => 'İzin';

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
  String get setupNotificationDescription =>
      'İndirmeler bittiğinde veya bakılması gereken bir şey olduğunda haberdar olun.';

  @override
  String get setupFolderSelected => 'İndirilecek Klasör Seçildi!';

  @override
  String get setupFolderChoose => 'İndirilecek Klasörü Seç';

  @override
  String get setupFolderDescription =>
      'İndirdiğin şarkıların kaydedileceği klasörü seç.';

  @override
  String get setupChangeFolder => 'Klasörü Değiştir';

  @override
  String get setupSelectFolder => 'Klasör Seç';

  @override
  String get setupSpotifyApiOptional => 'Spotify API (İsteğe Bağlı)';

  @override
  String get setupSpotifyApiDescription =>
      'Daha iyi arama sonuçları ve Spotify\'a özel içeriklere erişmek için Spotify API kimlik bilgilerini gir.';

  @override
  String get setupUseSpotifyApi => 'Spotify API\'ı kullan';

  @override
  String get setupEnterCredentialsBelow => 'Kimlik bilgilerini aşağıya gir';

  @override
  String get setupUsingDeezer => 'Deezer kullanılıyor (hesap gerekli değil)';

  @override
  String get setupEnterClientId => 'Spotify Client ID gir';

  @override
  String get setupEnterClientSecret => 'Spotify Client Secret gir';

  @override
  String get setupGetFreeCredentials =>
      'Spotify Developer Dashboard\'tan API kimlik bilgilerini ücretsiz alın.';

  @override
  String get setupEnableNotifications => 'Bildirimleri Etkinleştir';

  @override
  String get setupProceedToNextStep => 'Bir sonraki adıma geçebilirsin.';

  @override
  String get setupNotificationProgressDescription =>
      'İndirme ilerlemelerinin bildirimlerini alacaksın.';

  @override
  String get setupNotificationBackgroundDescription =>
      'İndirmelerin durumu hakkında bildirim al. Bunu açmak uygulama arka plandayken indirmelerinizi takip etmenizi sağlar.';

  @override
  String get setupSkipForNow => 'Şimdilik atla';

  @override
  String get setupBack => 'Geri';

  @override
  String get setupNext => 'Sıradaki';

  @override
  String get setupGetStarted => 'Başla';

  @override
  String get setupSkipAndStart => 'Kurulumu atla';

  @override
  String get setupAllowAccessToManageFiles =>
      'Lütfen bir sonraki ekranda \"Bütün dosyalara eriş\" iznini sağlayın.';

  @override
  String get setupGetCredentialsFromSpotify =>
      'Kimlik bilgilerini developer.spotify.com\'dan alın';

  @override
  String get dialogCancel => 'İptal';

  @override
  String get dialogOk => 'Tamam';

  @override
  String get dialogSave => 'Kaydet';

  @override
  String get dialogDelete => 'Sil';

  @override
  String get dialogRetry => 'Yeniden dene';

  @override
  String get dialogClose => 'Kapat';

  @override
  String get dialogYes => 'Evet';

  @override
  String get dialogNo => 'Hayır';

  @override
  String get dialogClear => 'Temizle';

  @override
  String get dialogConfirm => 'Onayla';

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
  String get dialogDownloadFailed => 'İndirme Başarısız';

  @override
  String get dialogTrackLabel => 'Şarkı:';

  @override
  String get dialogArtistLabel => 'Sanatçı:';

  @override
  String get dialogErrorLabel => 'Hata:';

  @override
  String get dialogClearAll => 'Tümünü Temizle';

  @override
  String get dialogClearAllDownloads =>
      'Bütün indirmeleri temizlemek istediğinize emin misiniz?';

  @override
  String get dialogRemoveFromDevice => 'Cihazdan kaldır?';

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
  String snackbarFailedToLoad(String error) {
    return 'Yüklenemedi: $error';
  }

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
  String errorFailedToLoad(String item) {
    return '$item yüklenirken hata oluştu';
  }

  @override
  String get errorNoTracksFound => 'Parça bulunamadı';

  @override
  String errorMissingExtensionSource(String item) {
    return '$item yüklenemedi: Eksik eklenti kaynağı';
  }

  @override
  String get statusQueued => 'Sıraya alındı';

  @override
  String get statusDownloading => 'İndiriliyor';

  @override
  String get statusFinalizing => 'Tamamlanıyor';

  @override
  String get statusCompleted => 'Tamamlandı';

  @override
  String get statusFailed => 'Başarısız';

  @override
  String get statusSkipped => 'Atlandı';

  @override
  String get statusPaused => 'Durduruldu';

  @override
  String get actionPause => 'Duraklat';

  @override
  String get actionResume => 'Devam et';

  @override
  String get actionCancel => 'Vazgeç';

  @override
  String get actionStop => 'Durdur';

  @override
  String get actionSelect => 'Seç';

  @override
  String get actionSelectAll => 'Tümünü Seç';

  @override
  String get actionDeselect => 'Seçimi kaldır';

  @override
  String get actionPaste => 'Yapıştır';

  @override
  String get actionImportCsv => 'CSV İçe Aktar';

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
  String get selectionTapToSelect => 'Seçmek için parçalara dokunun';

  @override
  String selectionDeleteTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'şarkıyı',
      one: 'şarkıyı',
    );
    return '$count $_temp0 sil';
  }

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
  String get tooltipCancel => 'Vazgeç';

  @override
  String get tooltipStop => 'Durdur';

  @override
  String get tooltipRetry => 'Yeniden dene';

  @override
  String get tooltipRemove => 'Kaldır';

  @override
  String get tooltipClear => 'Temizle';

  @override
  String get tooltipPaste => 'Yapıştır';

  @override
  String get filenameFormat => 'Dosya adı formatı';

  @override
  String filenameFormatPreview(String preview) {
    return 'Önizleme: $preview';
  }

  @override
  String get filenameAvailablePlaceholders => 'Kullanılabilir yer tutucular:';

  @override
  String filenameHint(Object artist, Object title) {
    return '$artist - $title';
  }

  @override
  String get folderOrganization => 'Klasör Organizasyonu';

  @override
  String get folderOrganizationNone => 'Organizasyon yok';

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
  String updateNewVersion(String version) {
    return '$version sürümü mevcut';
  }

  @override
  String get updateDownload => 'İndir';

  @override
  String get updateLater => 'Daha Sonra';

  @override
  String get updateChangelog => 'Değişiklikler';

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
  String get providerPriority => 'İndirme hizmetleri öncelik sırası';

  @override
  String get providerPrioritySubtitle =>
      'İndirme hizmetlerini sıralamak için kaydır';

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
  String get metadataProviderPriority => 'Metadata Sağlayıcı Önceliği';

  @override
  String get metadataProviderPrioritySubtitle =>
      'Şarkı metadata\'sı alınırken kullanılan sıra';

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
  String get logCopy => 'Kayıtları Kopyala';

  @override
  String get logClear => 'Kayıtları temizle';

  @override
  String get logShare => 'Kayıtları Paylaş';

  @override
  String get logEmpty => 'Henüz kayıt yok';

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
  String get logIspBlocking => 'ISP BLOCKING DETECTED';

  @override
  String get logRateLimited => 'RATE LIMITED';

  @override
  String get logNetworkError => 'NETWORK ERROR';

  @override
  String get logTrackNotFound => 'TRACK NOT FOUND';

  @override
  String get logFilterBySeverity => 'Kayıtları önem derecesine göre filtrele';

  @override
  String get logNoLogsYet => 'Henüz kayıt yok';

  @override
  String get logNoLogsYetSubtitle =>
      'Uygulamayı kullandıkça kayıtlar burada görünecek';

  @override
  String get logIssueSummary => 'Sorun Özeti';

  @override
  String get logIspBlockingDescription =>
      'İnternet sağlayıcınız indirme hizmetlerine erişimi engelliyor olabilir';

  @override
  String get logIspBlockingSuggestion =>
      'VPN kullanmayı veya DNS\'i 1.1.1.1 ya da 8.8.8.8 olarak değiştirmeyi deneyin';

  @override
  String get logRateLimitedDescription => 'Hizmete çok fazla istek gönderildi';

  @override
  String get logRateLimitedSuggestion =>
      'Tekrar denemeden önce birkaç dakika bekleyin';

  @override
  String get logNetworkErrorDescription => 'Bağlantı sorunları tespit edildi';

  @override
  String get logNetworkErrorSuggestion => 'İnternet bağlantınızı kontrol edin';

  @override
  String get logTrackNotFoundDescription =>
      'Bazı şarkılar indirme hizmetlerinde bulunamadı';

  @override
  String get logTrackNotFoundSuggestion =>
      'Şarkı kayıpsız kalitede mevcut olmayabilir';

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
  String get appearanceLanguageSubtitle => 'Tercih ettiğiniz dili seçin';

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
  String get tracksHeader => 'Şarkılar';

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
  String trackCannotOpen(String message) {
    return 'Cannot open: $message';
  }

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
  String get concurrentSequential => 'Sıralı';

  @override
  String get concurrentParallel2 => '2 Paralel';

  @override
  String get concurrentParallel3 => '3 Paralel';

  @override
  String get tapToSeeError => 'Hata detaylarını görmek için dokun';

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
  String get storeNoResults => 'Eklenti bulunamadı';

  @override
  String get extensionProviderPriority => 'Sağlayıcı Önceliği';

  @override
  String get extensionInstallButton => 'Eklenti Yükle';

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
}
