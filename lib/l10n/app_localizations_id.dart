// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'SpotiFLAC';

  @override
  String get appDescription =>
      'Unduh lagu Spotify dalam kualitas lossless dari Tidal, Qobuz, dan Amazon Music.';

  @override
  String get navHome => 'Beranda';

  @override
  String get navLibrary => 'Library';

  @override
  String get navHistory => 'Riwayat';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get navStore => 'Toko';

  @override
  String get homeTitle => 'Beranda';

  @override
  String get homeSearchHint => 'Tempel URL Spotify atau cari...';

  @override
  String homeSearchHintExtension(String extensionName) {
    return 'Cari dengan $extensionName...';
  }

  @override
  String get homeSubtitle => 'Tempel link Spotify atau cari berdasarkan nama';

  @override
  String get homeSupports => 'Mendukung: URL Track, Album, Playlist, Artis';

  @override
  String get homeRecent => 'Terbaru';

  @override
  String get historyTitle => 'Riwayat';

  @override
  String historyDownloading(int count) {
    return 'Mengunduh ($count)';
  }

  @override
  String get historyDownloaded => 'Terunduh';

  @override
  String get historyFilterAll => 'Semua';

  @override
  String get historyFilterAlbums => 'Album';

  @override
  String get historyFilterSingles => 'Single';

  @override
  String historyTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu',
      one: '1 lagu',
    );
    return '$_temp0';
  }

  @override
  String historyAlbumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count album',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String get historyNoDownloads => 'Tidak ada riwayat unduhan';

  @override
  String get historyNoDownloadsSubtitle =>
      'Lagu yang diunduh akan muncul di sini';

  @override
  String get historyNoAlbums => 'Tidak ada unduhan album';

  @override
  String get historyNoAlbumsSubtitle =>
      'Unduh beberapa lagu dari album untuk melihatnya di sini';

  @override
  String get historyNoSingles => 'Tidak ada unduhan single';

  @override
  String get historyNoSinglesSubtitle =>
      'Unduhan lagu satuan akan muncul di sini';

  @override
  String get historySearchHint => 'Search history...';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsDownload => 'Unduhan';

  @override
  String get settingsAppearance => 'Tampilan';

  @override
  String get settingsOptions => 'Opsi';

  @override
  String get settingsExtensions => 'Ekstensi';

  @override
  String get settingsAbout => 'Tentang';

  @override
  String get downloadTitle => 'Unduhan';

  @override
  String get downloadLocation => 'Lokasi Unduhan';

  @override
  String get downloadLocationSubtitle => 'Pilih tempat menyimpan file';

  @override
  String get downloadLocationDefault => 'Lokasi default';

  @override
  String get downloadDefaultService => 'Layanan Default';

  @override
  String get downloadDefaultServiceSubtitle =>
      'Layanan yang digunakan untuk unduhan';

  @override
  String get downloadDefaultQuality => 'Kualitas Default';

  @override
  String get downloadAskQuality => 'Tanya Kualitas Sebelum Unduh';

  @override
  String get downloadAskQualitySubtitle =>
      'Tampilkan pemilih kualitas untuk setiap unduhan';

  @override
  String get downloadFilenameFormat => 'Format Nama File';

  @override
  String get downloadFolderOrganization => 'Organisasi Folder';

  @override
  String get downloadSeparateSingles => 'Pisahkan Single';

  @override
  String get downloadSeparateSinglesSubtitle =>
      'Letakkan lagu satuan di folder terpisah';

  @override
  String get qualityBest => 'Terbaik';

  @override
  String get qualityFlac => 'FLAC';

  @override
  String get quality320 => '320 kbps';

  @override
  String get quality128 => '128 kbps';

  @override
  String get appearanceTitle => 'Tampilan';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceThemeSystem => 'Sistem';

  @override
  String get appearanceThemeLight => 'Terang';

  @override
  String get appearanceThemeDark => 'Gelap';

  @override
  String get appearanceDynamicColor => 'Warna Dinamis';

  @override
  String get appearanceDynamicColorSubtitle =>
      'Gunakan warna dari wallpaper Anda';

  @override
  String get appearanceAccentColor => 'Warna Aksen';

  @override
  String get appearanceHistoryView => 'Tampilan Riwayat';

  @override
  String get appearanceHistoryViewList => 'Daftar';

  @override
  String get appearanceHistoryViewGrid => 'Grid';

  @override
  String get optionsTitle => 'Opsi';

  @override
  String get optionsSearchSource => 'Sumber Pencarian';

  @override
  String get optionsPrimaryProvider => 'Provider Utama';

  @override
  String get optionsPrimaryProviderSubtitle =>
      'Layanan yang digunakan saat mencari berdasarkan nama lagu.';

  @override
  String optionsUsingExtension(String extensionName) {
    return 'Menggunakan ekstensi: $extensionName';
  }

  @override
  String get optionsSwitchBack =>
      'Ketuk Deezer atau Spotify untuk beralih dari ekstensi';

  @override
  String get optionsAutoFallback => 'Auto Fallback';

  @override
  String get optionsAutoFallbackSubtitle =>
      'Coba layanan lain jika unduhan gagal';

  @override
  String get optionsUseExtensionProviders => 'Gunakan Provider Ekstensi';

  @override
  String get optionsUseExtensionProvidersOn =>
      'Ekstensi akan dicoba terlebih dahulu';

  @override
  String get optionsUseExtensionProvidersOff =>
      'Hanya menggunakan provider bawaan';

  @override
  String get optionsEmbedLyrics => 'Sematkan Lirik';

  @override
  String get optionsEmbedLyricsSubtitle =>
      'Sematkan lirik sinkron ke file FLAC';

  @override
  String get optionsMaxQualityCover => 'Cover Kualitas Maksimal';

  @override
  String get optionsMaxQualityCoverSubtitle =>
      'Unduh cover art resolusi tertinggi';

  @override
  String get optionsConcurrentDownloads => 'Unduhan Bersamaan';

  @override
  String get optionsConcurrentSequential => 'Berurutan (1 per waktu)';

  @override
  String optionsConcurrentParallel(int count) {
    return '$count unduhan paralel';
  }

  @override
  String get optionsConcurrentWarning =>
      'Unduhan paralel dapat memicu pembatasan rate';

  @override
  String get optionsExtensionStore => 'Toko Ekstensi';

  @override
  String get optionsExtensionStoreSubtitle => 'Tampilkan tab Toko di navigasi';

  @override
  String get optionsCheckUpdates => 'Periksa Pembaruan';

  @override
  String get optionsCheckUpdatesSubtitle => 'Beritahu saat versi baru tersedia';

  @override
  String get optionsUpdateChannel => 'Saluran Pembaruan';

  @override
  String get optionsUpdateChannelStable => 'Hanya rilis stabil';

  @override
  String get optionsUpdateChannelPreview => 'Dapatkan rilis preview';

  @override
  String get optionsUpdateChannelWarning =>
      'Preview mungkin mengandung bug atau fitur belum lengkap';

  @override
  String get optionsClearHistory => 'Hapus Riwayat Unduhan';

  @override
  String get optionsClearHistorySubtitle => 'Hapus semua lagu dari riwayat';

  @override
  String get optionsDetailedLogging => 'Log Detail';

  @override
  String get optionsDetailedLoggingOn => 'Log detail sedang direkam';

  @override
  String get optionsDetailedLoggingOff => 'Aktifkan untuk laporan bug';

  @override
  String get optionsSpotifyCredentials => 'Kredensial Spotify';

  @override
  String optionsSpotifyCredentialsConfigured(String clientId) {
    return 'Client ID: $clientId...';
  }

  @override
  String get optionsSpotifyCredentialsRequired =>
      'Diperlukan - ketuk untuk mengatur';

  @override
  String get optionsSpotifyWarning =>
      'Spotify memerlukan kredensial API Anda sendiri. Dapatkan gratis dari developer.spotify.com';

  @override
  String get optionsSpotifyDeprecationWarning =>
      'Pencarian Spotify akan dihentikan pada 3 Maret 2026 karena perubahan API Spotify. Silakan beralih ke Deezer.';

  @override
  String get extensionsTitle => 'Ekstensi';

  @override
  String get extensionsInstalled => 'Ekstensi Terpasang';

  @override
  String get extensionsNone => 'Tidak ada ekstensi terpasang';

  @override
  String get extensionsNoneSubtitle => 'Pasang ekstensi dari tab Toko';

  @override
  String get extensionsEnabled => 'Aktif';

  @override
  String get extensionsDisabled => 'Nonaktif';

  @override
  String extensionsVersion(String version) {
    return 'Versi $version';
  }

  @override
  String extensionsAuthor(String author) {
    return 'oleh $author';
  }

  @override
  String get extensionsUninstall => 'Copot';

  @override
  String get extensionsSetAsSearch => 'Jadikan Provider Pencarian';

  @override
  String get storeTitle => 'Toko Ekstensi';

  @override
  String get storeSearch => 'Cari ekstensi...';

  @override
  String get storeInstall => 'Pasang';

  @override
  String get storeInstalled => 'Terpasang';

  @override
  String get storeUpdate => 'Perbarui';

  @override
  String get aboutTitle => 'Tentang';

  @override
  String get aboutContributors => 'Kontributor';

  @override
  String get aboutMobileDeveloper => 'Pengembang versi mobile';

  @override
  String get aboutOriginalCreator => 'Pembuat SpotiFLAC asli';

  @override
  String get aboutLogoArtist =>
      'Seniman berbakat yang membuat logo aplikasi kita yang indah!';

  @override
  String get aboutTranslators => 'Translators';

  @override
  String get aboutSpecialThanks => 'Terima Kasih Khusus';

  @override
  String get aboutLinks => 'Tautan';

  @override
  String get aboutMobileSource => 'Kode sumber mobile';

  @override
  String get aboutPCSource => 'Kode sumber PC';

  @override
  String get aboutReportIssue => 'Laporkan masalah';

  @override
  String get aboutReportIssueSubtitle => 'Laporkan masalah yang Anda temui';

  @override
  String get aboutFeatureRequest => 'Permintaan fitur';

  @override
  String get aboutFeatureRequestSubtitle =>
      'Sarankan fitur baru untuk aplikasi';

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
  String get aboutSupport => 'Dukungan';

  @override
  String get aboutApp => 'Aplikasi';

  @override
  String get aboutVersion => 'Versi';

  @override
  String get aboutBinimumDesc =>
      'Pembuat QQDL & HiFi API. Tanpa API ini, unduhan Tidal tidak akan ada!';

  @override
  String get aboutSachinsenalDesc =>
      'Pembuat proyek HiFi asli. Fondasi dari integrasi Tidal!';

  @override
  String get aboutSjdonadoDesc =>
      'Creator of I Don\'t Have Spotify (IDHS). The fallback link resolver that saves the day!';

  @override
  String get aboutDoubleDouble => 'DoubleDouble';

  @override
  String get aboutDoubleDoubleDesc =>
      'API luar biasa untuk unduhan Amazon Music. Terima kasih sudah membuatnya gratis!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'API streaming Qobuz terbaik. Unduhan Hi-Res tidak akan mungkin tanpa ini!';

  @override
  String get aboutSpotiSaver => 'SpotiSaver';

  @override
  String get aboutSpotiSaverDesc =>
      'Tidal Hi-Res FLAC streaming endpoints. A key piece of the lossless puzzle!';

  @override
  String get aboutAppDescription =>
      'Unduh lagu Spotify dalam kualitas lossless dari Tidal, Qobuz, dan Amazon Music.';

  @override
  String get albumTitle => 'Album';

  @override
  String albumTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu',
      one: '1 lagu',
    );
    return '$_temp0';
  }

  @override
  String get albumDownloadAll => 'Unduh Semua';

  @override
  String get albumDownloadRemaining => 'Unduh Sisanya';

  @override
  String get playlistTitle => 'Playlist';

  @override
  String get artistTitle => 'Artis';

  @override
  String get artistAlbums => 'Album';

  @override
  String get artistSingles => 'Single & EP';

  @override
  String get artistCompilations => 'Kompilasi';

  @override
  String artistReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rilis',
      one: '1 rilis',
    );
    return '$_temp0';
  }

  @override
  String get artistPopular => 'Populer';

  @override
  String artistMonthlyListeners(String count) {
    return '$count pendengar bulanan';
  }

  @override
  String get trackMetadataTitle => 'Info Lagu';

  @override
  String get trackMetadataArtist => 'Artis';

  @override
  String get trackMetadataAlbum => 'Album';

  @override
  String get trackMetadataDuration => 'Durasi';

  @override
  String get trackMetadataQuality => 'Kualitas';

  @override
  String get trackMetadataPath => 'Lokasi File';

  @override
  String get trackMetadataDownloadedAt => 'Diunduh';

  @override
  String get trackMetadataService => 'Layanan';

  @override
  String get trackMetadataPlay => 'Putar';

  @override
  String get trackMetadataShare => 'Bagikan';

  @override
  String get trackMetadataDelete => 'Hapus';

  @override
  String get trackMetadataRedownload => 'Unduh ulang';

  @override
  String get trackMetadataOpenFolder => 'Buka Folder';

  @override
  String get setupTitle => 'Selamat Datang di SpotiFLAC';

  @override
  String get setupSubtitle => 'Mari mulai pengaturan';

  @override
  String get setupStoragePermission => 'Izin Penyimpanan';

  @override
  String get setupStoragePermissionSubtitle =>
      'Diperlukan untuk menyimpan file unduhan';

  @override
  String get setupStoragePermissionGranted => 'Izin diberikan';

  @override
  String get setupStoragePermissionDenied => 'Izin ditolak';

  @override
  String get setupGrantPermission => 'Berikan Izin';

  @override
  String get setupDownloadLocation => 'Lokasi Unduhan';

  @override
  String get setupChooseFolder => 'Pilih Folder';

  @override
  String get setupContinue => 'Lanjutkan';

  @override
  String get setupSkip => 'Lewati untuk sekarang';

  @override
  String get setupStorageAccessRequired => 'Akses Penyimpanan Diperlukan';

  @override
  String get setupStorageAccessMessage =>
      'SpotiFLAC membutuhkan izin \"Akses semua file\" untuk menyimpan file musik ke folder pilihan Anda.';

  @override
  String get setupStorageAccessMessageAndroid11 =>
      'Android 11+ memerlukan izin \"Akses semua file\" untuk menyimpan file ke folder unduhan pilihan Anda.';

  @override
  String get setupOpenSettings => 'Buka Pengaturan';

  @override
  String get setupPermissionDeniedMessage =>
      'Izin ditolak. Harap berikan semua izin untuk melanjutkan.';

  @override
  String setupPermissionRequired(String permissionType) {
    return 'Izin $permissionType Diperlukan';
  }

  @override
  String setupPermissionRequiredMessage(String permissionType) {
    return 'Izin $permissionType diperlukan untuk pengalaman terbaik. Anda dapat mengubahnya nanti di Pengaturan.';
  }

  @override
  String get setupSelectDownloadFolder => 'Pilih Folder Unduhan';

  @override
  String get setupUseDefaultFolder => 'Gunakan Folder Default?';

  @override
  String get setupNoFolderSelected =>
      'Tidak ada folder dipilih. Apakah Anda ingin menggunakan folder Musik default?';

  @override
  String get setupUseDefault => 'Gunakan Default';

  @override
  String get setupDownloadLocationTitle => 'Lokasi Unduhan';

  @override
  String get setupDownloadLocationIosMessage =>
      'Di iOS, unduhan disimpan ke folder Documents aplikasi. Anda dapat mengaksesnya melalui aplikasi Files.';

  @override
  String get setupAppDocumentsFolder => 'Folder Documents Aplikasi';

  @override
  String get setupAppDocumentsFolderSubtitle =>
      'Direkomendasikan - dapat diakses via aplikasi Files';

  @override
  String get setupChooseFromFiles => 'Pilih dari Files';

  @override
  String get setupChooseFromFilesSubtitle => 'Pilih lokasi iCloud atau lainnya';

  @override
  String get setupIosEmptyFolderWarning =>
      'Batasan iOS: Folder kosong tidak dapat dipilih. Pilih folder dengan minimal satu file.';

  @override
  String get setupIcloudNotSupported =>
      'iCloud Drive is not supported. Please use the app Documents folder.';

  @override
  String get setupDownloadInFlac => 'Unduh lagu Spotify dalam format FLAC';

  @override
  String get setupStepStorage => 'Penyimpanan';

  @override
  String get setupStepNotification => 'Notifikasi';

  @override
  String get setupStepFolder => 'Folder';

  @override
  String get setupStepSpotify => 'Spotify';

  @override
  String get setupStepPermission => 'Izin';

  @override
  String get setupStorageGranted => 'Izin Penyimpanan Diberikan!';

  @override
  String get setupStorageRequired => 'Izin Penyimpanan Diperlukan';

  @override
  String get setupStorageDescription =>
      'SpotiFLAC membutuhkan izin penyimpanan untuk menyimpan file musik yang diunduh.';

  @override
  String get setupNotificationGranted => 'Izin Notifikasi Diberikan!';

  @override
  String get setupNotificationEnable => 'Aktifkan Notifikasi';

  @override
  String get setupNotificationDescription =>
      'Dapatkan pemberitahuan saat unduhan selesai atau membutuhkan perhatian.';

  @override
  String get setupFolderSelected => 'Folder Unduhan Dipilih!';

  @override
  String get setupFolderChoose => 'Pilih Folder Unduhan';

  @override
  String get setupFolderDescription =>
      'Pilih folder tempat musik yang diunduh akan disimpan.';

  @override
  String get setupChangeFolder => 'Ubah Folder';

  @override
  String get setupSelectFolder => 'Pilih Folder';

  @override
  String get setupSpotifyApiOptional => 'Spotify API (Opsional)';

  @override
  String get setupSpotifyApiDescription =>
      'Tambahkan kredensial Spotify API untuk hasil pencarian lebih baik dan akses ke konten eksklusif Spotify.';

  @override
  String get setupUseSpotifyApi => 'Gunakan Spotify API';

  @override
  String get setupEnterCredentialsBelow => 'Masukkan kredensial Anda di bawah';

  @override
  String get setupUsingDeezer => 'Menggunakan Deezer (tidak perlu akun)';

  @override
  String get setupEnterClientId => 'Masukkan Spotify Client ID';

  @override
  String get setupEnterClientSecret => 'Masukkan Spotify Client Secret';

  @override
  String get setupGetFreeCredentials =>
      'Dapatkan kredensial API gratis dari Spotify Developer Dashboard.';

  @override
  String get setupEnableNotifications => 'Aktifkan Notifikasi';

  @override
  String get setupProceedToNextStep =>
      'Anda dapat melanjutkan ke langkah berikutnya.';

  @override
  String get setupNotificationProgressDescription =>
      'Anda akan menerima notifikasi progres unduhan.';

  @override
  String get setupNotificationBackgroundDescription =>
      'Dapatkan notifikasi tentang progres dan penyelesaian unduhan. Ini membantu Anda melacak unduhan saat aplikasi di latar belakang.';

  @override
  String get setupSkipForNow => 'Lewati untuk sekarang';

  @override
  String get setupBack => 'Kembali';

  @override
  String get setupNext => 'Lanjut';

  @override
  String get setupGetStarted => 'Mulai';

  @override
  String get setupSkipAndStart => 'Lewati & Mulai';

  @override
  String get setupAllowAccessToManageFiles =>
      'Harap aktifkan \"Izinkan akses untuk mengelola semua file\" di layar berikutnya.';

  @override
  String get setupGetCredentialsFromSpotify =>
      'Dapatkan kredensial dari developer.spotify.com';

  @override
  String get dialogCancel => 'Batal';

  @override
  String get dialogOk => 'OK';

  @override
  String get dialogSave => 'Simpan';

  @override
  String get dialogDelete => 'Hapus';

  @override
  String get dialogRetry => 'Coba Lagi';

  @override
  String get dialogClose => 'Tutup';

  @override
  String get dialogYes => 'Ya';

  @override
  String get dialogNo => 'Tidak';

  @override
  String get dialogClear => 'Hapus';

  @override
  String get dialogConfirm => 'Konfirmasi';

  @override
  String get dialogDone => 'Selesai';

  @override
  String get dialogImport => 'Impor';

  @override
  String get dialogDiscard => 'Buang';

  @override
  String get dialogRemove => 'Hapus';

  @override
  String get dialogUninstall => 'Copot';

  @override
  String get dialogDiscardChanges => 'Buang Perubahan?';

  @override
  String get dialogUnsavedChanges =>
      'Anda memiliki perubahan yang belum disimpan. Apakah Anda ingin membuangnya?';

  @override
  String get dialogDownloadFailed => 'Unduhan Gagal';

  @override
  String get dialogTrackLabel => 'Lagu:';

  @override
  String get dialogArtistLabel => 'Artis:';

  @override
  String get dialogErrorLabel => 'Error:';

  @override
  String get dialogClearAll => 'Hapus Semua';

  @override
  String get dialogClearAllDownloads =>
      'Apakah Anda yakin ingin menghapus semua unduhan?';

  @override
  String get dialogRemoveFromDevice => 'Hapus dari perangkat?';

  @override
  String get dialogRemoveExtension => 'Hapus Ekstensi';

  @override
  String get dialogRemoveExtensionMessage =>
      'Apakah Anda yakin ingin menghapus ekstensi ini? Tindakan ini tidak dapat dibatalkan.';

  @override
  String get dialogUninstallExtension => 'Copot Ekstensi?';

  @override
  String dialogUninstallExtensionMessage(String extensionName) {
    return 'Apakah Anda yakin ingin menghapus $extensionName?';
  }

  @override
  String get dialogClearHistoryTitle => 'Hapus Riwayat';

  @override
  String get dialogClearHistoryMessage =>
      'Apakah Anda yakin ingin menghapus semua riwayat unduhan? Ini tidak dapat dibatalkan.';

  @override
  String get dialogDeleteSelectedTitle => 'Hapus yang Dipilih';

  @override
  String dialogDeleteSelectedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lagu',
      one: 'lagu',
    );
    return 'Hapus $count $_temp0 dari riwayat?\n\nIni juga akan menghapus file dari penyimpanan.';
  }

  @override
  String get dialogImportPlaylistTitle => 'Impor Playlist';

  @override
  String dialogImportPlaylistMessage(int count) {
    return 'Ditemukan $count lagu di CSV. Tambahkan ke antrian unduhan?';
  }

  @override
  String csvImportTracks(int count) {
    return '$count tracks from CSV';
  }

  @override
  String snackbarAddedToQueue(String trackName) {
    return 'Menambahkan \"$trackName\" ke antrian';
  }

  @override
  String snackbarAddedTracksToQueue(int count) {
    return 'Menambahkan $count lagu ke antrian';
  }

  @override
  String snackbarAlreadyDownloaded(String trackName) {
    return '\"$trackName\" sudah diunduh';
  }

  @override
  String snackbarAlreadyInLibrary(String trackName) {
    return '\"$trackName\" already exists in your library';
  }

  @override
  String get snackbarHistoryCleared => 'Riwayat dihapus';

  @override
  String get snackbarCredentialsSaved => 'Kredensial disimpan';

  @override
  String get snackbarCredentialsCleared => 'Kredensial dihapus';

  @override
  String snackbarDeletedTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lagu',
      one: 'lagu',
    );
    return 'Menghapus $count $_temp0';
  }

  @override
  String snackbarCannotOpenFile(String error) {
    return 'Tidak dapat membuka file: $error';
  }

  @override
  String get snackbarFillAllFields => 'Harap isi semua field';

  @override
  String get snackbarViewQueue => 'Lihat Antrian';

  @override
  String snackbarFailedToLoad(String error) {
    return 'Gagal memuat: $error';
  }

  @override
  String snackbarUrlCopied(String platform) {
    return 'URL $platform disalin ke clipboard';
  }

  @override
  String get snackbarFileNotFound => 'File tidak ditemukan';

  @override
  String get snackbarSelectExtFile => 'Harap pilih file .spotiflac-ext';

  @override
  String get snackbarProviderPrioritySaved => 'Prioritas provider disimpan';

  @override
  String get snackbarMetadataProviderSaved =>
      'Prioritas provider metadata disimpan';

  @override
  String snackbarExtensionInstalled(String extensionName) {
    return '$extensionName terpasang.';
  }

  @override
  String snackbarExtensionUpdated(String extensionName) {
    return '$extensionName diperbarui.';
  }

  @override
  String get snackbarFailedToInstall => 'Gagal memasang ekstensi';

  @override
  String get snackbarFailedToUpdate => 'Gagal memperbarui ekstensi';

  @override
  String get errorRateLimited => 'Dibatasi';

  @override
  String get errorRateLimitedMessage =>
      'Terlalu banyak permintaan. Harap tunggu sebentar sebelum mencari lagi.';

  @override
  String errorFailedToLoad(String item) {
    return 'Gagal memuat $item';
  }

  @override
  String get errorNoTracksFound => 'Tidak ada lagu ditemukan';

  @override
  String errorMissingExtensionSource(String item) {
    return 'Tidak dapat memuat $item: sumber ekstensi tidak ada';
  }

  @override
  String get statusQueued => 'Mengantri';

  @override
  String get statusDownloading => 'Mengunduh';

  @override
  String get statusFinalizing => 'Menyelesaikan';

  @override
  String get statusCompleted => 'Selesai';

  @override
  String get statusFailed => 'Gagal';

  @override
  String get statusSkipped => 'Dilewati';

  @override
  String get statusPaused => 'Dijeda';

  @override
  String get actionPause => 'Jeda';

  @override
  String get actionResume => 'Lanjutkan';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionStop => 'Hentikan';

  @override
  String get actionSelect => 'Pilih';

  @override
  String get actionSelectAll => 'Pilih Semua';

  @override
  String get actionDeselect => 'Batal Pilih';

  @override
  String get actionPaste => 'Tempel';

  @override
  String get actionImportCsv => 'Impor CSV';

  @override
  String get actionRemoveCredentials => 'Hapus Kredensial';

  @override
  String get actionSaveCredentials => 'Simpan Kredensial';

  @override
  String selectionSelected(int count) {
    return '$count dipilih';
  }

  @override
  String get selectionAllSelected => 'Semua lagu dipilih';

  @override
  String get selectionTapToSelect => 'Ketuk lagu untuk memilih';

  @override
  String selectionDeleteTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lagu',
      one: 'lagu',
    );
    return 'Hapus $count $_temp0';
  }

  @override
  String get selectionSelectToDelete => 'Pilih lagu untuk dihapus';

  @override
  String progressFetchingMetadata(int current, int total) {
    return 'Mengambil metadata... $current/$total';
  }

  @override
  String get progressReadingCsv => 'Membaca CSV...';

  @override
  String get searchSongs => 'Lagu';

  @override
  String get searchArtists => 'Artis';

  @override
  String get searchAlbums => 'Album';

  @override
  String get searchPlaylists => 'Playlist';

  @override
  String get tooltipPlay => 'Putar';

  @override
  String get tooltipCancel => 'Batal';

  @override
  String get tooltipStop => 'Hentikan';

  @override
  String get tooltipRetry => 'Coba Lagi';

  @override
  String get tooltipRemove => 'Hapus';

  @override
  String get tooltipClear => 'Hapus';

  @override
  String get tooltipPaste => 'Tempel';

  @override
  String get filenameFormat => 'Format Nama File';

  @override
  String filenameFormatPreview(String preview) {
    return 'Pratinjau: $preview';
  }

  @override
  String get filenameAvailablePlaceholders => 'Placeholder yang tersedia:';

  @override
  String filenameHint(Object artist, Object title) {
    return '$artist - $title';
  }

  @override
  String get folderOrganization => 'Organisasi Folder';

  @override
  String get folderOrganizationNone => 'Tidak ada';

  @override
  String get folderOrganizationByArtist => 'Berdasarkan Artis';

  @override
  String get folderOrganizationByAlbum => 'Berdasarkan Album';

  @override
  String get folderOrganizationByArtistAlbum => 'Berdasarkan Artis & Album';

  @override
  String get folderOrganizationDescription =>
      'Atur file yang diunduh ke dalam folder';

  @override
  String get folderOrganizationNoneSubtitle => 'Semua file di folder unduhan';

  @override
  String get folderOrganizationByArtistSubtitle =>
      'Folder terpisah untuk setiap artis';

  @override
  String get folderOrganizationByAlbumSubtitle =>
      'Folder terpisah untuk setiap album';

  @override
  String get folderOrganizationByArtistAlbumSubtitle =>
      'Folder bersarang untuk artis dan album';

  @override
  String get updateAvailable => 'Pembaruan Tersedia';

  @override
  String updateNewVersion(String version) {
    return 'Versi $version tersedia';
  }

  @override
  String get updateDownload => 'Unduh';

  @override
  String get updateLater => 'Nanti';

  @override
  String get updateChangelog => 'Log Perubahan';

  @override
  String get updateStartingDownload => 'Memulai unduhan...';

  @override
  String get updateDownloadFailed => 'Unduhan gagal';

  @override
  String get updateFailedMessage => 'Gagal mengunduh pembaruan';

  @override
  String get updateNewVersionReady => 'Versi baru sudah siap';

  @override
  String get updateCurrent => 'Saat ini';

  @override
  String get updateNew => 'Baru';

  @override
  String get updateDownloading => 'Mengunduh...';

  @override
  String get updateWhatsNew => 'Yang Baru';

  @override
  String get updateDownloadInstall => 'Unduh & Pasang';

  @override
  String get updateDontRemind => 'Jangan ingatkan';

  @override
  String get providerPriority => 'Prioritas Provider';

  @override
  String get providerPrioritySubtitle =>
      'Seret untuk mengatur ulang provider unduhan';

  @override
  String get providerPriorityTitle => 'Prioritas Provider';

  @override
  String get providerPriorityDescription =>
      'Seret untuk mengatur ulang urutan provider unduhan. Aplikasi akan mencoba provider dari atas ke bawah saat mengunduh lagu.';

  @override
  String get providerPriorityInfo =>
      'Jika lagu tidak tersedia di provider pertama, aplikasi akan otomatis mencoba yang berikutnya.';

  @override
  String get providerBuiltIn => 'Bawaan';

  @override
  String get providerExtension => 'Ekstensi';

  @override
  String get metadataProviderPriority => 'Prioritas Provider Metadata';

  @override
  String get metadataProviderPrioritySubtitle =>
      'Urutan yang digunakan saat mengambil metadata lagu';

  @override
  String get metadataProviderPriorityTitle => 'Prioritas Metadata';

  @override
  String get metadataProviderPriorityDescription =>
      'Seret untuk mengatur ulang urutan provider metadata. Aplikasi akan mencoba provider dari atas ke bawah saat mencari lagu dan mengambil metadata.';

  @override
  String get metadataProviderPriorityInfo =>
      'Deezer tidak memiliki batas rate dan direkomendasikan sebagai utama. Spotify mungkin membatasi rate setelah banyak permintaan.';

  @override
  String get metadataNoRateLimits => 'Tidak ada batas rate';

  @override
  String get metadataMayRateLimit => 'Mungkin dibatasi rate';

  @override
  String get logTitle => 'Log';

  @override
  String get logCopy => 'Salin Log';

  @override
  String get logClear => 'Hapus Log';

  @override
  String get logShare => 'Bagikan Log';

  @override
  String get logEmpty => 'Belum ada log';

  @override
  String get logCopied => 'Log disalin ke clipboard';

  @override
  String get logSearchHint => 'Cari log...';

  @override
  String get logFilterLevel => 'Level';

  @override
  String get logFilterSection => 'Filter';

  @override
  String get logShareLogs => 'Bagikan log';

  @override
  String get logClearLogs => 'Hapus log';

  @override
  String get logClearLogsTitle => 'Hapus Log';

  @override
  String get logClearLogsMessage =>
      'Apakah Anda yakin ingin menghapus semua log?';

  @override
  String get logIspBlocking => 'PEMBLOKIRAN ISP TERDETEKSI';

  @override
  String get logRateLimited => 'DIBATASI';

  @override
  String get logNetworkError => 'ERROR JARINGAN';

  @override
  String get logTrackNotFound => 'LAGU TIDAK DITEMUKAN';

  @override
  String get logFilterBySeverity => 'Filter log berdasarkan tingkat keparahan';

  @override
  String get logNoLogsYet => 'Belum ada log';

  @override
  String get logNoLogsYetSubtitle =>
      'Log akan muncul di sini saat Anda menggunakan aplikasi';

  @override
  String get logIssueSummary => 'Ringkasan Masalah';

  @override
  String get logIspBlockingDescription =>
      'ISP Anda mungkin memblokir akses ke layanan unduhan';

  @override
  String get logIspBlockingSuggestion =>
      'Coba gunakan VPN atau ubah DNS ke 1.1.1.1 atau 8.8.8.8';

  @override
  String get logRateLimitedDescription =>
      'Terlalu banyak permintaan ke layanan';

  @override
  String get logRateLimitedSuggestion =>
      'Tunggu beberapa menit sebelum mencoba lagi';

  @override
  String get logNetworkErrorDescription => 'Masalah koneksi terdeteksi';

  @override
  String get logNetworkErrorSuggestion => 'Periksa koneksi internet Anda';

  @override
  String get logTrackNotFoundDescription =>
      'Beberapa lagu tidak dapat ditemukan di layanan unduhan';

  @override
  String get logTrackNotFoundSuggestion =>
      'Lagu mungkin tidak tersedia dalam kualitas lossless';

  @override
  String logTotalErrors(int count) {
    return 'Total error: $count';
  }

  @override
  String logAffected(String domains) {
    return 'Terpengaruh: $domains';
  }

  @override
  String logEntriesFiltered(int count) {
    return 'Entri ($count difilter)';
  }

  @override
  String logEntries(int count) {
    return 'Entri ($count)';
  }

  @override
  String get credentialsTitle => 'Kredensial Spotify';

  @override
  String get credentialsDescription =>
      'Masukkan Client ID dan Secret Anda untuk menggunakan kuota aplikasi Spotify Anda sendiri.';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Tempel Client ID';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => 'Tempel Client Secret';

  @override
  String get channelStable => 'Stabil';

  @override
  String get channelPreview => 'Preview';

  @override
  String get sectionSearchSource => 'Sumber Pencarian';

  @override
  String get sectionDownload => 'Unduhan';

  @override
  String get sectionPerformance => 'Performa';

  @override
  String get sectionApp => 'Aplikasi';

  @override
  String get sectionData => 'Data';

  @override
  String get sectionDebug => 'Debug';

  @override
  String get sectionService => 'Layanan';

  @override
  String get sectionAudioQuality => 'Kualitas Audio';

  @override
  String get sectionFileSettings => 'Pengaturan File';

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
  String get sectionColor => 'Warna';

  @override
  String get sectionTheme => 'Tema';

  @override
  String get sectionLayout => 'Tata Letak';

  @override
  String get sectionLanguage => 'Bahasa';

  @override
  String get appearanceLanguage => 'Bahasa Aplikasi';

  @override
  String get appearanceLanguageSubtitle => 'Pilih bahasa yang kamu inginkan';

  @override
  String get settingsAppearanceSubtitle => 'Tema, warna, tampilan';

  @override
  String get settingsDownloadSubtitle => 'Layanan, kualitas, format nama file';

  @override
  String get settingsOptionsSubtitle => 'Fallback, lirik, cover art, pembaruan';

  @override
  String get settingsExtensionsSubtitle => 'Kelola provider unduhan';

  @override
  String get settingsLogsSubtitle => 'Lihat log aplikasi untuk debugging';

  @override
  String get loadingSharedLink => 'Memuat link yang dibagikan...';

  @override
  String get pressBackAgainToExit => 'Tekan kembali sekali lagi untuk keluar';

  @override
  String get tracksHeader => 'Lagu';

  @override
  String downloadAllCount(int count) {
    return 'Unduh Semua ($count)';
  }

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu',
      one: '1 lagu',
    );
    return '$_temp0';
  }

  @override
  String get trackCopyFilePath => 'Salin lokasi file';

  @override
  String get trackRemoveFromDevice => 'Hapus dari perangkat';

  @override
  String get trackLoadLyrics => 'Muat Lirik';

  @override
  String get trackMetadata => 'Metadata';

  @override
  String get trackFileInfo => 'Info File';

  @override
  String get trackLyrics => 'Lirik';

  @override
  String get trackFileNotFound => 'File tidak ditemukan';

  @override
  String get trackOpenInDeezer => 'Buka di Deezer';

  @override
  String get trackOpenInSpotify => 'Buka di Spotify';

  @override
  String get trackTrackName => 'Nama lagu';

  @override
  String get trackArtist => 'Artis';

  @override
  String get trackAlbumArtist => 'Artis album';

  @override
  String get trackAlbum => 'Album';

  @override
  String get trackTrackNumber => 'Nomor lagu';

  @override
  String get trackDiscNumber => 'Nomor disc';

  @override
  String get trackDuration => 'Durasi';

  @override
  String get trackAudioQuality => 'Kualitas audio';

  @override
  String get trackReleaseDate => 'Tanggal rilis';

  @override
  String get trackGenre => 'Genre';

  @override
  String get trackLabel => 'Label';

  @override
  String get trackCopyright => 'Copyright';

  @override
  String get trackDownloaded => 'Diunduh';

  @override
  String get trackCopyLyrics => 'Salin lirik';

  @override
  String get trackLyricsNotAvailable => 'Lirik tidak tersedia untuk lagu ini';

  @override
  String get trackLyricsTimeout => 'Permintaan timeout. Coba lagi nanti.';

  @override
  String get trackLyricsLoadFailed => 'Gagal memuat lirik';

  @override
  String get trackEmbedLyrics => 'Embed Lyrics';

  @override
  String get trackLyricsEmbedded => 'Lyrics embedded successfully';

  @override
  String get trackInstrumental => 'Instrumental track';

  @override
  String get trackCopiedToClipboard => 'Disalin ke clipboard';

  @override
  String get trackDeleteConfirmTitle => 'Hapus dari perangkat?';

  @override
  String get trackDeleteConfirmMessage =>
      'Ini akan menghapus file unduhan secara permanen dan menghapusnya dari riwayat Anda.';

  @override
  String trackCannotOpen(String message) {
    return 'Tidak dapat membuka: $message';
  }

  @override
  String get dateToday => 'Hari ini';

  @override
  String get dateYesterday => 'Kemarin';

  @override
  String dateDaysAgo(int count) {
    return '$count hari lalu';
  }

  @override
  String dateWeeksAgo(int count) {
    return '$count minggu lalu';
  }

  @override
  String dateMonthsAgo(int count) {
    return '$count bulan lalu';
  }

  @override
  String get concurrentSequential => 'Berurutan';

  @override
  String get concurrentParallel2 => '2 Paralel';

  @override
  String get concurrentParallel3 => '3 Paralel';

  @override
  String get tapToSeeError => 'Ketuk untuk melihat detail error';

  @override
  String get storeFilterAll => 'Semua';

  @override
  String get storeFilterMetadata => 'Metadata';

  @override
  String get storeFilterDownload => 'Unduhan';

  @override
  String get storeFilterUtility => 'Utilitas';

  @override
  String get storeFilterLyrics => 'Lirik';

  @override
  String get storeFilterIntegration => 'Integrasi';

  @override
  String get storeClearFilters => 'Hapus filter';

  @override
  String get storeNoResults => 'Tidak ada ekstensi ditemukan';

  @override
  String get extensionProviderPriority => 'Prioritas Provider';

  @override
  String get extensionInstallButton => 'Pasang Ekstensi';

  @override
  String get extensionDefaultProvider => 'Default (Deezer/Spotify)';

  @override
  String get extensionDefaultProviderSubtitle => 'Gunakan pencarian bawaan';

  @override
  String get extensionAuthor => 'Pembuat';

  @override
  String get extensionId => 'ID';

  @override
  String get extensionError => 'Error';

  @override
  String get extensionCapabilities => 'Kemampuan';

  @override
  String get extensionMetadataProvider => 'Provider Metadata';

  @override
  String get extensionDownloadProvider => 'Provider Unduhan';

  @override
  String get extensionLyricsProvider => 'Provider Lirik';

  @override
  String get extensionUrlHandler => 'Penanganan URL';

  @override
  String get extensionQualityOptions => 'Opsi Kualitas';

  @override
  String get extensionPostProcessingHooks => 'Hook Pasca-Pemrosesan';

  @override
  String get extensionPermissions => 'Izin';

  @override
  String get extensionSettings => 'Pengaturan';

  @override
  String get extensionRemoveButton => 'Hapus Ekstensi';

  @override
  String get extensionUpdated => 'Diperbarui';

  @override
  String get extensionMinAppVersion => 'Versi App Minimum';

  @override
  String get extensionCustomTrackMatching => 'Pencocokan Lagu Kustom';

  @override
  String get extensionPostProcessing => 'Pasca-Pemrosesan';

  @override
  String extensionHooksAvailable(int count) {
    return '$count hook tersedia';
  }

  @override
  String extensionPatternsCount(int count) {
    return '$count pola';
  }

  @override
  String extensionStrategy(String strategy) {
    return 'Strategi: $strategy';
  }

  @override
  String get extensionsProviderPrioritySection => 'Prioritas Provider';

  @override
  String get extensionsInstalledSection => 'Ekstensi Terpasang';

  @override
  String get extensionsNoExtensions => 'Tidak ada ekstensi terpasang';

  @override
  String get extensionsNoExtensionsSubtitle =>
      'Pasang file .spotiflac-ext untuk menambahkan provider baru';

  @override
  String get extensionsInstallButton => 'Pasang Ekstensi';

  @override
  String get extensionsInfoTip =>
      'Ekstensi dapat menambahkan provider metadata dan unduhan baru. Hanya pasang ekstensi dari sumber terpercaya.';

  @override
  String get extensionsInstalledSuccess => 'Ekstensi berhasil dipasang';

  @override
  String get extensionsDownloadPriority => 'Prioritas Unduhan';

  @override
  String get extensionsDownloadPrioritySubtitle =>
      'Atur urutan layanan unduhan';

  @override
  String get extensionsNoDownloadProvider =>
      'Tidak ada ekstensi dengan provider unduhan';

  @override
  String get extensionsMetadataPriority => 'Prioritas Metadata';

  @override
  String get extensionsMetadataPrioritySubtitle =>
      'Atur urutan sumber pencarian & metadata';

  @override
  String get extensionsNoMetadataProvider =>
      'Tidak ada ekstensi dengan provider metadata';

  @override
  String get extensionsSearchProvider => 'Provider Pencarian';

  @override
  String get extensionsNoCustomSearch =>
      'Tidak ada ekstensi dengan pencarian kustom';

  @override
  String get extensionsSearchProviderDescription =>
      'Pilih layanan yang digunakan untuk mencari lagu';

  @override
  String get extensionsCustomSearch => 'Pencarian kustom';

  @override
  String get extensionsErrorLoading => 'Error memuat ekstensi';

  @override
  String get qualityFlacLossless => 'FLAC Lossless';

  @override
  String get qualityFlacLosslessSubtitle => '16-bit / 44.1kHz';

  @override
  String get qualityHiResFlac => 'Hi-Res FLAC';

  @override
  String get qualityHiResFlacSubtitle => '24-bit / hingga 96kHz';

  @override
  String get qualityHiResFlacMax => 'Hi-Res FLAC Max';

  @override
  String get qualityHiResFlacMaxSubtitle => '24-bit / hingga 192kHz';

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
      'Kualitas sebenarnya tergantung ketersediaan lagu dari layanan';

  @override
  String get youtubeQualityNote =>
      'YouTube provides lossy audio only. Not part of lossless fallback.';

  @override
  String get downloadAskBeforeDownload => 'Tanya Sebelum Unduh';

  @override
  String get downloadDirectory => 'Direktori Unduhan';

  @override
  String get downloadSeparateSinglesFolder => 'Folder Singles Terpisah';

  @override
  String get downloadAlbumFolderStructure => 'Struktur Folder Album';

  @override
  String get downloadUseAlbumArtistForFolders =>
      'Gunakan Album Artist untuk folder';

  @override
  String get downloadUseAlbumArtistForFoldersAlbumSubtitle =>
      'Folder artis memakai Album Artist jika tersedia';

  @override
  String get downloadUseAlbumArtistForFoldersTrackSubtitle =>
      'Folder artis hanya memakai Track Artist';

  @override
  String get downloadUsePrimaryArtistOnly => 'Hanya artis utama untuk folder';

  @override
  String get downloadUsePrimaryArtistOnlyEnabled =>
      'Featured artist dihapus dari nama folder (misal Justin Bieber, Quavo → Justin Bieber)';

  @override
  String get downloadUsePrimaryArtistOnlyDisabled =>
      'Nama artis lengkap dipakai untuk folder';

  @override
  String get downloadSaveFormat => 'Simpan Format';

  @override
  String get downloadSelectService => 'Pilih Layanan';

  @override
  String get downloadSelectQuality => 'Pilih Kualitas';

  @override
  String get downloadFrom => 'Unduh Dari';

  @override
  String get downloadDefaultQualityLabel => 'Kualitas Default';

  @override
  String get downloadBestAvailable => 'Terbaik tersedia';

  @override
  String get folderNone => 'Tidak ada';

  @override
  String get folderNoneSubtitle =>
      'Simpan semua file langsung ke folder unduhan';

  @override
  String get folderArtist => 'Artis';

  @override
  String get folderArtistSubtitle => 'Nama Artis/namafile';

  @override
  String get folderAlbum => 'Album';

  @override
  String get folderAlbumSubtitle => 'Nama Album/namafile';

  @override
  String get folderArtistAlbum => 'Artis/Album';

  @override
  String get folderArtistAlbumSubtitle => 'Nama Artis/Nama Album/namafile';

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
  String get appearanceAmoledDark => 'AMOLED Gelap';

  @override
  String get appearanceAmoledDarkSubtitle => 'Latar belakang hitam murni';

  @override
  String get appearanceChooseAccentColor => 'Pilih Warna Aksen';

  @override
  String get appearanceChooseTheme => 'Mode Tema';

  @override
  String get queueTitle => 'Antrian Unduhan';

  @override
  String get queueClearAll => 'Hapus Semua';

  @override
  String get queueClearAllMessage =>
      'Apakah Anda yakin ingin menghapus semua unduhan?';

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
  String get queueEmpty => 'Tidak ada unduhan dalam antrian';

  @override
  String get queueEmptySubtitle => 'Tambahkan lagu dari layar beranda';

  @override
  String get queueClearCompleted => 'Hapus yang selesai';

  @override
  String get queueDownloadFailed => 'Unduhan Gagal';

  @override
  String get queueTrackLabel => 'Lagu:';

  @override
  String get queueArtistLabel => 'Artis:';

  @override
  String get queueErrorLabel => 'Error:';

  @override
  String get queueUnknownError => 'Error tidak diketahui';

  @override
  String get albumFolderArtistAlbum => 'Artis / Album';

  @override
  String get albumFolderArtistAlbumSubtitle => 'Albums/Nama Artis/Nama Album/';

  @override
  String get albumFolderArtistYearAlbum => 'Artis / [Tahun] Album';

  @override
  String get albumFolderArtistYearAlbumSubtitle =>
      'Albums/Nama Artis/[2005] Nama Album/';

  @override
  String get albumFolderAlbumOnly => 'Album Saja';

  @override
  String get albumFolderAlbumOnlySubtitle => 'Albums/Nama Album/';

  @override
  String get albumFolderYearAlbum => '[Tahun] Album';

  @override
  String get albumFolderYearAlbumSubtitle => 'Albums/[2005] Nama Album/';

  @override
  String get albumFolderArtistAlbumSingles => 'Artist / Album + Singles';

  @override
  String get albumFolderArtistAlbumSinglesSubtitle =>
      'Artist/Album/ and Artist/Singles/';

  @override
  String get downloadedAlbumDeleteSelected => 'Hapus yang Dipilih';

  @override
  String downloadedAlbumDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lagu',
      one: 'lagu',
    );
    return 'Hapus $count $_temp0 dari album ini?\n\nIni juga akan menghapus file dari penyimpanan.';
  }

  @override
  String get downloadedAlbumTracksHeader => 'Lagu';

  @override
  String downloadedAlbumDownloadedCount(int count) {
    return '$count diunduh';
  }

  @override
  String downloadedAlbumSelectedCount(int count) {
    return '$count dipilih';
  }

  @override
  String get downloadedAlbumAllSelected => 'Semua lagu dipilih';

  @override
  String get downloadedAlbumTapToSelect => 'Ketuk lagu untuk memilih';

  @override
  String downloadedAlbumDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lagu',
      one: 'lagu',
    );
    return 'Hapus $count $_temp0';
  }

  @override
  String get downloadedAlbumSelectToDelete => 'Pilih lagu untuk dihapus';

  @override
  String downloadedAlbumDiscHeader(int discNumber) {
    return 'Disc $discNumber';
  }

  @override
  String get utilityFunctions => 'Fungsi Utilitas';

  @override
  String get recentTypeArtist => 'Artis';

  @override
  String get recentTypeAlbum => 'Album';

  @override
  String get recentTypeSong => 'Lagu';

  @override
  String get recentTypePlaylist => 'Playlist';

  @override
  String get recentEmpty => 'Belum ada item terbaru';

  @override
  String get recentShowAllDownloads => 'Tampilkan Semua Download';

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
  String get discographyDownloadAll => 'Unduh Semua';

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
  String get settingsCache => 'Penyimpanan & Cache';

  @override
  String get settingsCacheSubtitle => 'Lihat ukuran dan bersihkan data cache';

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
  String get tutorialWelcomeTitle => 'Selamat Datang di SpotiFLAC!';

  @override
  String get tutorialWelcomeDesc =>
      'Mari pelajari cara mengunduh musik favorit Anda dalam kualitas lossless. Tutorial singkat ini akan menunjukkan dasar-dasarnya.';

  @override
  String get tutorialWelcomeTip1 =>
      'Unduh musik dari Spotify, Deezer, atau tempel URL yang didukung';

  @override
  String get tutorialWelcomeTip2 =>
      'Dapatkan audio kualitas FLAC dari Tidal, Qobuz, atau Amazon Music';

  @override
  String get tutorialWelcomeTip3 =>
      'Metadata, cover art, dan lirik otomatis tertanam';

  @override
  String get tutorialSearchTitle => 'Mencari Musik';

  @override
  String get tutorialSearchDesc =>
      'Ada dua cara mudah untuk menemukan musik yang ingin Anda unduh.';

  @override
  String get tutorialSearchTip1 =>
      'Tempel URL Spotify atau Deezer langsung di kotak pencarian';

  @override
  String get tutorialSearchTip2 =>
      'Atau ketik nama lagu, artis, atau album untuk mencari';

  @override
  String get tutorialSearchTip3 =>
      'Mendukung lagu, album, playlist, dan halaman artis';

  @override
  String get tutorialDownloadTitle => 'Mengunduh Musik';

  @override
  String get tutorialDownloadDesc =>
      'Mengunduh musik itu mudah dan cepat. Begini caranya.';

  @override
  String get tutorialDownloadTip1 =>
      'Ketuk tombol unduh di samping lagu mana pun untuk mulai mengunduh';

  @override
  String get tutorialDownloadTip2 =>
      'Pilih kualitas yang Anda inginkan (FLAC, Hi-Res, atau MP3)';

  @override
  String get tutorialDownloadTip3 =>
      'Unduh seluruh album atau playlist dengan satu ketukan';

  @override
  String get tutorialLibraryTitle => 'Perpustakaan Anda';

  @override
  String get tutorialLibraryDesc =>
      'Semua musik yang Anda unduh terorganisir di tab Perpustakaan.';

  @override
  String get tutorialLibraryTip1 =>
      'Lihat progres unduhan dan antrian di tab Perpustakaan';

  @override
  String get tutorialLibraryTip2 =>
      'Ketuk lagu mana pun untuk memutarnya dengan pemutar musik';

  @override
  String get tutorialLibraryTip3 =>
      'Beralih antara tampilan daftar dan grid untuk penjelajahan lebih baik';

  @override
  String get tutorialExtensionsTitle => 'Ekstensi';

  @override
  String get tutorialExtensionsDesc =>
      'Tingkatkan kemampuan aplikasi dengan ekstensi komunitas.';

  @override
  String get tutorialExtensionsTip1 =>
      'Jelajahi tab Toko untuk menemukan ekstensi berguna';

  @override
  String get tutorialExtensionsTip2 =>
      'Tambahkan provider unduhan atau sumber pencarian baru';

  @override
  String get tutorialExtensionsTip3 =>
      'Dapatkan lirik, metadata lebih baik, dan fitur lainnya';

  @override
  String get tutorialSettingsTitle => 'Sesuaikan Pengalaman Anda';

  @override
  String get tutorialSettingsDesc =>
      'Personalisasi aplikasi di Pengaturan sesuai preferensi Anda.';

  @override
  String get tutorialSettingsTip1 =>
      'Ubah lokasi unduhan dan organisasi folder';

  @override
  String get tutorialSettingsTip2 =>
      'Atur kualitas audio dan preferensi format default';

  @override
  String get tutorialSettingsTip3 => 'Sesuaikan tema dan tampilan aplikasi';

  @override
  String get tutorialReadyMessage =>
      'Anda siap! Mulai unduh musik favorit Anda sekarang.';

  @override
  String get tutorialExample => 'CONTOH';

  @override
  String get libraryForceFullScan => 'Pindai Ulang Penuh';

  @override
  String get libraryForceFullScanSubtitle =>
      'Pindai ulang semua file, abaikan cache';

  @override
  String get cleanupOrphanedDownloads => 'Bersihkan Entri Unduhan Tidak Valid';

  @override
  String get cleanupOrphanedDownloadsSubtitle =>
      'Hapus entri riwayat untuk file yang tidak ada lagi';

  @override
  String cleanupOrphanedDownloadsResult(int count) {
    return 'Menghapus $count entri unduhan tidak valid dari riwayat';
  }

  @override
  String get cleanupOrphanedDownloadsNone =>
      'Tidak ada entri unduhan tidak valid';

  @override
  String get cacheTitle => 'Penyimpanan & Cache';

  @override
  String get cacheSummaryTitle => 'Ringkasan cache';

  @override
  String get cacheSummarySubtitle =>
      'Membersihkan cache tidak akan menghapus file musik yang sudah diunduh.';

  @override
  String cacheEstimatedTotal(String size) {
    return 'Estimasi penggunaan cache: $size';
  }

  @override
  String get cacheSectionStorage => 'Data Cache';

  @override
  String get cacheSectionMaintenance => 'Perawatan';

  @override
  String get cacheAppDirectory => 'Direktori cache aplikasi';

  @override
  String get cacheAppDirectoryDesc =>
      'Respons HTTP, data WebView, dan data sementara aplikasi.';

  @override
  String get cacheTempDirectory => 'Direktori sementara';

  @override
  String get cacheTempDirectoryDesc =>
      'File sementara dari proses download dan konversi audio.';

  @override
  String get cacheCoverImage => 'Cache gambar cover';

  @override
  String get cacheCoverImageDesc =>
      'Gambar cover album dan lagu yang diunduh. Akan diunduh ulang saat dilihat.';

  @override
  String get cacheLibraryCover => 'Cache cover library';

  @override
  String get cacheLibraryCoverDesc =>
      'Cover dari file musik lokal. Akan diekstrak ulang saat scan berikutnya.';

  @override
  String get cacheExploreFeed => 'Cache feed Explore';

  @override
  String get cacheExploreFeedDesc =>
      'Konten tab Explore (rilis baru, trending). Akan dimuat ulang saat dikunjungi.';

  @override
  String get cacheTrackLookup => 'Cache pencocokan lagu';

  @override
  String get cacheTrackLookupDesc =>
      'Cache pencarian ID lagu Spotify/Deezer. Menghapus mungkin memperlambat beberapa pencarian.';

  @override
  String get cacheCleanupUnusedDesc =>
      'Hapus entri riwayat download dan library yang filenya sudah tidak ada.';

  @override
  String get cacheNoData => 'Tidak ada data cache';

  @override
  String cacheSizeWithFiles(String size, int count) {
    return '$size dalam $count file';
  }

  @override
  String cacheSizeOnly(String size) {
    return '$size';
  }

  @override
  String cacheEntries(int count) {
    return '$count entri';
  }

  @override
  String cacheClearSuccess(String target) {
    return 'Berhasil dibersihkan: $target';
  }

  @override
  String get cacheClearConfirmTitle => 'Bersihkan cache?';

  @override
  String cacheClearConfirmMessage(String target) {
    return 'Ini akan membersihkan data cache untuk $target. File musik yang sudah diunduh tidak akan dihapus.';
  }

  @override
  String get cacheClearAllConfirmTitle => 'Bersihkan semua cache?';

  @override
  String get cacheClearAllConfirmMessage =>
      'Ini akan membersihkan semua kategori cache di halaman ini. File musik yang sudah diunduh tidak akan dihapus.';

  @override
  String get cacheClearAll => 'Bersihkan semua cache';

  @override
  String get cacheCleanupUnused => 'Bersihkan data tidak terpakai';

  @override
  String get cacheCleanupUnusedSubtitle =>
      'Hapus riwayat unduhan yatim dan entri library yang file-nya hilang';

  @override
  String cacheCleanupResult(int downloadCount, int libraryCount) {
    return 'Pembersihan selesai: $downloadCount unduhan yatim, $libraryCount entri library hilang';
  }

  @override
  String get cacheRefreshStats => 'Segarkan statistik';

  @override
  String get trackSaveCoverArt => 'Simpan Cover Art';

  @override
  String get trackSaveCoverArtSubtitle =>
      'Simpan cover album sebagai file .jpg';

  @override
  String get trackSaveLyrics => 'Simpan Lirik (.lrc)';

  @override
  String get trackSaveLyricsSubtitle =>
      'Ambil dan simpan lirik sebagai file .lrc';

  @override
  String get trackSaveLyricsProgress => 'Menyimpan lirik...';

  @override
  String get trackReEnrich => 'Perkaya Ulang Metadata';

  @override
  String get trackReEnrichSubtitle =>
      'Tanamkan ulang metadata tanpa mengunduh ulang';

  @override
  String get trackReEnrichOnlineSubtitle =>
      'Cari metadata dari internet dan tanamkan ke file';

  @override
  String get trackEditMetadata => 'Edit Metadata';

  @override
  String trackCoverSaved(String fileName) {
    return 'Cover art disimpan ke $fileName';
  }

  @override
  String get trackCoverNoSource => 'Tidak ada sumber cover art';

  @override
  String trackLyricsSaved(String fileName) {
    return 'Lirik disimpan ke $fileName';
  }

  @override
  String get trackReEnrichProgress => 'Memperkaya ulang metadata...';

  @override
  String get trackReEnrichSearching => 'Mencari metadata dari internet...';

  @override
  String get trackReEnrichSuccess => 'Metadata berhasil diperkaya ulang';

  @override
  String get trackReEnrichFfmpegFailed =>
      'Gagal menanamkan metadata via FFmpeg';

  @override
  String trackSaveFailed(String error) {
    return 'Gagal: $error';
  }

  @override
  String get trackConvertFormat => 'Konversi Format';

  @override
  String get trackConvertFormatSubtitle => 'Konversi ke MP3 atau Opus';

  @override
  String get trackConvertTitle => 'Konversi Audio';

  @override
  String get trackConvertTargetFormat => 'Format Tujuan';

  @override
  String get trackConvertBitrate => 'Bitrate';

  @override
  String get trackConvertConfirmTitle => 'Konfirmasi Konversi';

  @override
  String trackConvertConfirmMessage(
    String sourceFormat,
    String targetFormat,
    String bitrate,
  ) {
    return 'Konversi dari $sourceFormat ke $targetFormat pada $bitrate?\n\nFile asli akan dihapus setelah konversi.';
  }

  @override
  String get trackConvertConverting => 'Mengkonversi audio...';

  @override
  String trackConvertSuccess(String format) {
    return 'Berhasil dikonversi ke $format';
  }

  @override
  String get trackConvertFailed => 'Konversi gagal';
}
