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
  String get navHome => 'Beranda';

  @override
  String get navLibrary => 'Pustaka';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get navStore => 'Toko';

  @override
  String get homeTitle => 'Beranda';

  @override
  String get homeSubtitle => 'Tempel link Spotify atau cari berdasarkan nama';

  @override
  String get homeSupports => 'Mendukung: URL Track, Album, Playlist, Artis';

  @override
  String get homeRecent => 'Terbaru';

  @override
  String get historyFilterAll => 'Semua';

  @override
  String get historyFilterAlbums => 'Album';

  @override
  String get historyFilterSingles => 'Single';

  @override
  String get historySearchHint => 'Cari riwayat...';

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
  String get downloadAskQualitySubtitle =>
      'Tampilkan pemilih kualitas untuk setiap unduhan';

  @override
  String get downloadFilenameFormat => 'Format Nama File';

  @override
  String get downloadFolderOrganization => 'Organisasi Folder';

  @override
  String get appearanceTitle => 'Tampilan';

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
  String get appearanceHistoryView => 'Tampilan Riwayat';

  @override
  String get appearanceHistoryViewList => 'Daftar';

  @override
  String get appearanceHistoryViewGrid => 'Kisi';

  @override
  String get optionsTitle => 'Opsi';

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
  String get optionsAutoFallback => 'Cadangan Otomatis';

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
    return 'ID Klien: $clientId...';
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
  String get aboutTranslators => 'Penerjemah';

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
  String get aboutTelegramChannel => 'Saluran Telegram';

  @override
  String get aboutTelegramChannelSubtitle => 'Pengumuman dan pembaruan';

  @override
  String get aboutTelegramChat => 'Komunitas Telegram';

  @override
  String get aboutTelegramChatSubtitle => 'Berbincang dengan pengguna lain';

  @override
  String get aboutSocial => 'Sosial';

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
      'Pencipta I Don\'t Have Spotify (IDHS). Penyelesai tautan cadangan yang menyelamatkan keadaan!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'API streaming Qobuz terbaik. Unduhan Hi-Res tidak akan mungkin tanpa ini!';

  @override
  String get aboutSpotiSaver => 'SpotiSaver';

  @override
  String get aboutSpotiSaverDesc =>
      'Tidal perangkat streaming FLAC resolusi tinggi. Bagian penting dari teka-teki tanpa kehilangan kualitas!';

  @override
  String get aboutAppDescription =>
      'Unduh lagu Spotify dalam kualitas lossless dari Tidal, Qobuz, dan Amazon Music.';

  @override
  String get artistAlbums => 'Album';

  @override
  String get artistSingles => 'Single & EP';

  @override
  String get artistCompilations => 'Kompilasi';

  @override
  String get artistPopular => 'Populer';

  @override
  String artistMonthlyListeners(String count) {
    return '$count pendengar bulanan';
  }

  @override
  String get trackMetadataService => 'Layanan';

  @override
  String get trackMetadataPlay => 'Putar';

  @override
  String get trackMetadataShare => 'Bagikan';

  @override
  String get trackMetadataDelete => 'Hapus';

  @override
  String get setupGrantPermission => 'Berikan Izin';

  @override
  String get setupSkip => 'Lewati untuk sekarang';

  @override
  String get setupStorageAccessRequired => 'Akses Penyimpanan Diperlukan';

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
      'iCloud Drive tidak didukung. Silakan gunakan folder Dokumen di aplikasi.';

  @override
  String get setupDownloadInFlac => 'Unduh lagu Spotify dalam format FLAC';

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
  String get setupFolderChoose => 'Pilih Folder Unduhan';

  @override
  String get setupFolderDescription =>
      'Pilih folder tempat musik yang diunduh akan disimpan.';

  @override
  String get setupSelectFolder => 'Pilih Folder';

  @override
  String get setupEnableNotifications => 'Aktifkan Notifikasi';

  @override
  String get setupNotificationBackgroundDescription =>
      'Dapatkan notifikasi tentang progres dan penyelesaian unduhan. Ini membantu Anda melacak unduhan saat aplikasi di latar belakang.';

  @override
  String get setupSkipForNow => 'Lewati untuk sekarang';

  @override
  String get setupNext => 'Lanjut';

  @override
  String get setupGetStarted => 'Mulai';

  @override
  String get setupAllowAccessToManageFiles =>
      'Harap aktifkan \"Izinkan akses untuk mengelola semua file\" di layar berikutnya.';

  @override
  String get dialogCancel => 'Batal';

  @override
  String get dialogSave => 'Simpan';

  @override
  String get dialogDelete => 'Hapus';

  @override
  String get dialogRetry => 'Coba Lagi';

  @override
  String get dialogClear => 'Hapus';

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
  String get dialogClearAll => 'Hapus Semua';

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
    return '$count trek dari CSV';
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
    return '\"$trackName\" sudah ada di perpustakaan Anda';
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
  String get errorNoTracksFound => 'Tidak ada lagu ditemukan';

  @override
  String get errorUrlNotRecognized => 'Link tidak dikenali';

  @override
  String get errorUrlNotRecognizedMessage =>
      'Link ini tidak didukung. Pastikan URL benar dan ekstensi yang kompatibel sudah terpasang.';

  @override
  String get errorUrlFetchFailed =>
      'Gagal memuat konten dari link ini. Silakan coba lagi.';

  @override
  String errorMissingExtensionSource(String item) {
    return 'Tidak dapat memuat $item: sumber ekstensi tidak ada';
  }

  @override
  String get actionPause => 'Jeda';

  @override
  String get actionResume => 'Lanjutkan';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionSelectAll => 'Pilih Semua';

  @override
  String get actionDeselect => 'Batal Pilih';

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
  String get filenameFormat => 'Format Nama File';

  @override
  String get filenameShowAdvancedTags => 'Show advanced tags';

  @override
  String get filenameShowAdvancedTagsDescription =>
      'Enable formatted tags for track padding and date patterns';

  @override
  String get folderOrganizationNone => 'Tidak ada';

  @override
  String get folderOrganizationByPlaylist => 'By Playlist';

  @override
  String get folderOrganizationByPlaylistSubtitle =>
      'Separate folder for each playlist';

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
  String get updateLater => 'Nanti';

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
  String get logFilterBySeverity => 'Filter log berdasarkan tingkat keparahan';

  @override
  String get logNoLogsYet => 'Belum ada log';

  @override
  String get logNoLogsYetSubtitle =>
      'Log akan muncul di sini saat Anda menggunakan aplikasi';

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
  String get qualityNote =>
      'Kualitas sebenarnya tergantung ketersediaan lagu dari layanan';

  @override
  String get youtubeQualityNote =>
      'YouTube provides lossy audio only. Not part of lossless fallback.';

  @override
  String get youtubeOpusBitrateTitle => 'YouTube Opus Bitrate';

  @override
  String get youtubeMp3BitrateTitle => 'YouTube MP3 Bitrate';

  @override
  String get downloadAskBeforeDownload => 'Tanya Sebelum Unduh';

  @override
  String get downloadDirectory => 'Direktori Unduhan';

  @override
  String get downloadSeparateSinglesFolder => 'Folder Singles Terpisah';

  @override
  String get downloadAlbumFolderStructure => 'Struktur Folder Album';

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
  String get downloadSelectQuality => 'Pilih Kualitas';

  @override
  String get downloadFrom => 'Unduh Dari';

  @override
  String get appearanceAmoledDark => 'AMOLED Gelap';

  @override
  String get appearanceAmoledDarkSubtitle => 'Latar belakang hitam murni';

  @override
  String get queueClearAll => 'Hapus Semua';

  @override
  String get queueClearAllMessage =>
      'Apakah Anda yakin ingin menghapus semua unduhan?';

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
  String get recentTypeArtist => 'Artis';

  @override
  String get recentTypeAlbum => 'Album';

  @override
  String get recentTypeSong => 'Lagu';

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
    return '$count diunduh';
  }

  @override
  String get downloadUseAlbumArtistForFoldersAlbumSubtitle =>
      'Artist folders use Album Artist when available';

  @override
  String get downloadUseAlbumArtistForFoldersTrackSubtitle =>
      'Artist folders use Track Artist only';
}
