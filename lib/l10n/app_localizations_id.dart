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
  String get navStore => 'Repo';

  @override
  String get homeTitle => 'Beranda';

  @override
  String get homeSubtitle =>
      'Tempel URL yang didukung atau cari berdasarkan nama';

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
  String get downloadSingleFilenameFormat => 'Single Filename Format';

  @override
  String get downloadSingleFilenameFormatDescription =>
      'Filename pattern for singles and EPs. Uses the same tags as the album format.';

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
  String get optionsDefaultSearchTab => 'Tab Pencarian Default';

  @override
  String get optionsDefaultSearchTabSubtitle =>
      'Pilih tab yang dibuka lebih dulu untuk hasil pencarian baru.';

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
  String get optionsExtensionStore => 'Repo Ekstensi';

  @override
  String get optionsExtensionStoreSubtitle => 'Tampilkan tab Repo di navigasi';

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
  String get storeTitle => 'Repo Ekstensi';

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
  String get aboutKeepAndroidOpen => 'Keep Android Open';

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
      'Unduh lagu-lagu Spotify dalam kualitas lossless dari Tidal dan Qobuz.';

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
  String get dialogDownload => 'Download';

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
  String get tooltipPlay => 'Putar';

  @override
  String get filenameFormat => 'Format Nama File';

  @override
  String get filenameShowAdvancedTags => 'Tampilkan tag lanjutan';

  @override
  String get filenameShowAdvancedTagsDescription =>
      'Aktifkan tag yang diformat untuk padding trek dan pola tanggal';

  @override
  String get folderOrganizationNone => 'Tidak ada';

  @override
  String get folderOrganizationByPlaylist => 'Berdasarkan Daftar Putar';

  @override
  String get folderOrganizationByPlaylistSubtitle =>
      'Setiap daftar putar memerlukan folder terpisah';

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
  String get providerPriorityFallbackExtensionsTitle => 'Fallback Ekstensi';

  @override
  String get providerPriorityFallbackExtensionsDescription =>
      'Pilih ekstensi unduhan terpasang mana yang boleh dipakai saat fallback otomatis. Provider bawaan tetap mengikuti urutan prioritas di atas.';

  @override
  String get providerPriorityFallbackExtensionsHint =>
      'Hanya ekstensi aktif dengan kemampuan download provider yang ditampilkan di sini.';

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
  String get credentialsClientId => 'ID Klien';

  @override
  String get credentialsClientIdHint => 'Tempel Client ID';

  @override
  String get credentialsClientSecret => 'Rahasia Klien';

  @override
  String get credentialsClientSecretHint => 'Tempel Client Secret';

  @override
  String get channelStable => 'Stabil';

  @override
  String get channelPreview => 'Pratinjau';

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
  String get sectionLyrics => 'Lirik';

  @override
  String get lyricsMode => 'Mode Lirik';

  @override
  String get lyricsModeDescription =>
      'Pilih cara lirik disimpan bersama unduhan Anda';

  @override
  String get lyricsModeEmbed => 'Sematkan dalam file';

  @override
  String get lyricsModeEmbedSubtitle =>
      'Lirik tersimpan di dalam metadata FLAC';

  @override
  String get lyricsModeExternal => 'File .lrc eksternal';

  @override
  String get lyricsModeExternalSubtitle =>
      'File .lrc terpisah untuk pemutar musik seperti Samsung Music';

  @override
  String get lyricsModeBoth => 'Keduanya';

  @override
  String get lyricsModeBothSubtitle => 'Sematkan dan simpan file .lrc';

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
  String get trackLabel => 'Lebel';

  @override
  String get trackCopyright => 'Hak cipta';

  @override
  String get trackDownloaded => 'Diunduh';

  @override
  String get trackCopyLyrics => 'Salin lirik';

  @override
  String get trackLyricsNotAvailable => 'Lirik tidak tersedia untuk lagu ini';

  @override
  String get trackLyricsNotInFile => 'No lyrics found in this file';

  @override
  String get trackFetchOnlineLyrics => 'Fetch from Online';

  @override
  String get trackLyricsTimeout => 'Permintaan timeout. Coba lagi nanti.';

  @override
  String get trackLyricsLoadFailed => 'Gagal memuat lirik';

  @override
  String get trackEmbedLyrics => 'Sematkan Lirik';

  @override
  String get trackLyricsEmbedded => 'Lirik berhasil disematkan';

  @override
  String get trackInstrumental => 'Lagu instrumental';

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
  String get storeLoadError => 'Gagal memuat repo';

  @override
  String get storeEmptyNoExtensions => 'No extensions available';

  @override
  String get storeEmptyNoResults => 'No extensions found';

  @override
  String get extensionDefaultProvider => 'Bawaan (Deezer/Spotify)';

  @override
  String get extensionDefaultProviderSubtitle => 'Gunakan pencarian bawaan';

  @override
  String get extensionAuthor => 'Pembuat';

  @override
  String get extensionId => 'ID';

  @override
  String get extensionError => 'Terjadi kesalahan';

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
  String get extensionsFallbackTitle => 'Fallback Extensions';

  @override
  String get extensionsFallbackSubtitle =>
      'Pilih ekstensi unduhan terpasang yang boleh dipakai saat fallback';

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
      'Kualitas sebenarnya tergantung ketersediaan lagu dari layanan';

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
      'Gunakan Artis Album untuk folder';

  @override
  String get downloadUsePrimaryArtistOnly => 'Hanya artis utama untuk folder';

  @override
  String get downloadUsePrimaryArtistOnlyEnabled =>
      'Artis unggulan dihapus dari nama folder (misalnya Justin Bieber, Quavo → Justin Bieber)';

  @override
  String get downloadUsePrimaryArtistOnlyDisabled =>
      'Nama lengkap artis digunakan untuk nama folder';

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
  String get settingsAutoExportFailed => 'Unduhan yang gagal diekspor otomatis';

  @override
  String get settingsAutoExportFailedSubtitle =>
      'Simpan unduhan yang gagal ke file TXT secara otomatis';

  @override
  String get settingsDownloadNetwork => 'Jaringan Unduhan';

  @override
  String get settingsDownloadNetworkAny => 'WiFi + Data Seluler';

  @override
  String get settingsDownloadNetworkWifiOnly => 'Hanya WiFi';

  @override
  String get settingsDownloadNetworkSubtitle =>
      'Pilih jaringan mana yang akan digunakan untuk mengunduh. Jika diatur ke Hanya WiFi, unduhan akan berhenti sementara dan menggunakan data seluler.';

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
  String get albumFolderArtistAlbumSingles => 'Artis / Album + Singel';

  @override
  String get albumFolderArtistAlbumSinglesSubtitle =>
      'Artis/Album/ dan Artis/Single/';

  @override
  String get albumFolderArtistAlbumFlat => 'Artist / Album (Singles flat)';

  @override
  String get albumFolderArtistAlbumFlatSubtitle =>
      'Artist/Album/ and Artist/song.flac';

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
  String get recentTypePlaylist => 'Daftar putar';

  @override
  String get recentEmpty => 'Belum ada item terbaru';

  @override
  String get recentShowAllDownloads => 'Tampilkan Semua Unduhan';

  @override
  String recentPlaylistInfo(String name) {
    return 'Daftar Putar: $name';
  }

  @override
  String get discographyDownload => 'Unduh Diskografi';

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
    return 'Last scanned: $time';
  }

  @override
  String get libraryLastScannedNever => 'Never';

  @override
  String get libraryScanning => 'Scanning...';

  @override
  String get libraryScanFinalizing => 'Finalizing library...';

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
  String get libraryFilterSort => 'Sort';

  @override
  String get libraryFilterSortLatest => 'Latest';

  @override
  String get libraryFilterSortOldest => 'Oldest';

  @override
  String get libraryFilterSortAlbumAsc => 'Album (A-Z)';

  @override
  String get libraryFilterSortAlbumDesc => 'Album (Z-A)';

  @override
  String get libraryFilterSortGenreAsc => 'Genre (A-Z)';

  @override
  String get libraryFilterSortGenreDesc => 'Genre (Z-A)';

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
  String get tutorialWelcomeTitle => 'Selamat Datang di SpotiFLAC!';

  @override
  String get tutorialWelcomeDesc =>
      'Mari kita pelajari cara mengunduh musik favorit Anda dalam kualitas lossless. Tutorial singkat ini akan menunjukkan dasar-dasarnya.';

  @override
  String get tutorialWelcomeTip1 =>
      'Unduh musik dari Spotify, Deezer, atau tempel URL yang didukung';

  @override
  String get tutorialWelcomeTip2 =>
      'Dapatkan audio berkualitas FLAC dari Tidal, Qobuz, atau Deezer';

  @override
  String get tutorialWelcomeTip3 =>
      'Penyematan metadata, sampul album, dan lirik secara otomatis';

  @override
  String get tutorialSearchTitle => 'Menemukan Musik';

  @override
  String get tutorialSearchDesc =>
      'Ada dua cara mudah untuk menemukan musik yang ingin Anda unduh.';

  @override
  String get tutorialDownloadTitle => 'Mengunduh Musik';

  @override
  String get tutorialDownloadDesc =>
      'Mengunduh musik itu mudah dan cepat. Begini cara kerjanya.';

  @override
  String get tutorialLibraryTitle => 'Perpustakaan Anda';

  @override
  String get tutorialLibraryDesc =>
      'Semua musik yang Anda unduh tersusun rapi di tab Perpustakaan.';

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
      'Buka tab Repo untuk menemukan ekstensi yang berguna';

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
  String get queueFlacAction => 'Antrekan FLAC';

  @override
  String queueFlacConfirmMessage(int count) {
    return 'Cari kecocokan online untuk track yang dipilih lalu antrekan download FLAC.\n\nFile yang sudah ada tidak akan diubah atau dihapus.\n\nHanya kecocokan dengan keyakinan tinggi yang akan diantrikan otomatis.\n\n$count dipilih';
  }

  @override
  String queueFlacFindingProgress(int current, int total) {
    return 'Mencari kecocokan FLAC... ($current/$total)';
  }

  @override
  String get queueFlacNoReliableMatches =>
      'Tidak ada kecocokan online yang cukup meyakinkan untuk pilihan ini';

  @override
  String queueFlacQueuedWithSkipped(int addedCount, int skippedCount) {
    return 'Menambahkan $addedCount track ke antrean, melewati $skippedCount';
  }

  @override
  String trackSaveFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get trackConvertFormat => 'Convert Format';

  @override
  String get trackConvertFormatSubtitle =>
      'Konversi ke MP3, Opus, ALAC, atau FLAC';

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
  String trackConvertConfirmMessageLossless(
    String sourceFormat,
    String targetFormat,
  ) {
    return 'Konversi dari $sourceFormat ke $targetFormat? (Lossless — tanpa kehilangan kualitas)\n\nFile asli akan dihapus setelah konversi.';
  }

  @override
  String get trackConvertLosslessHint =>
      'Konversi lossless — tanpa kehilangan kualitas';

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
      'Buat folder sumber playlist';

  @override
  String get downloadCreatePlaylistSourceFolderEnabled =>
      'Unduhan dari playlist memakai Playlist/ lalu struktur folder normal Anda.';

  @override
  String get downloadCreatePlaylistSourceFolderDisabled =>
      'Unduhan dari playlist hanya memakai struktur folder normal.';

  @override
  String get downloadCreatePlaylistSourceFolderRedundant =>
      'Mode Berdasarkan Playlist sudah menaruh unduhan ke dalam folder playlist.';

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
