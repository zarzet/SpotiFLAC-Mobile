// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'SpotiFLAC';

  @override
  String get navHome => 'ホーム';

  @override
  String get navLibrary => 'ライブラリ';

  @override
  String get navSettings => '設定';

  @override
  String get navStore => 'ストア';

  @override
  String get homeTitle => 'ホーム';

  @override
  String get homeSubtitle => 'Spotify のリンクを貼り付けるか、名前で検索します';

  @override
  String get homeSupports => 'サポート: トラック、アルバム、プレイリスト、アーティスト、URL';

  @override
  String get homeRecent => '最近';

  @override
  String get historyFilterAll => 'すべて';

  @override
  String get historyFilterAlbums => 'アルバム';

  @override
  String get historyFilterSingles => 'シングル';

  @override
  String get historySearchHint => '検索履歴...';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsDownload => 'ダウンロード';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsOptions => 'オプション';

  @override
  String get settingsExtensions => '拡張';

  @override
  String get settingsAbout => 'アプリについて';

  @override
  String get downloadTitle => 'ダウンロード';

  @override
  String get downloadAskQualitySubtitle =>
      'Show quality picker for each download';

  @override
  String get downloadFilenameFormat => 'ファイル名の形式';

  @override
  String get downloadFolderOrganization => 'フォルダ構成';

  @override
  String get appearanceTitle => '外観';

  @override
  String get appearanceThemeSystem => 'システム';

  @override
  String get appearanceThemeLight => 'ライト';

  @override
  String get appearanceThemeDark => 'ダーク';

  @override
  String get appearanceDynamicColor => 'ダイナミックカラー';

  @override
  String get appearanceDynamicColorSubtitle => '壁紙の色を使用する';

  @override
  String get appearanceHistoryView => '履歴の表示';

  @override
  String get appearanceHistoryViewList => 'リスト';

  @override
  String get appearanceHistoryViewGrid => 'グリッド';

  @override
  String get optionsTitle => 'オプション';

  @override
  String get optionsPrimaryProvider => 'プライマリーのプロバイダー';

  @override
  String get optionsPrimaryProviderSubtitle =>
      'Service used when searching by track name.';

  @override
  String optionsUsingExtension(String extensionName) {
    return '拡張の使用: $extensionName';
  }

  @override
  String get optionsSwitchBack =>
      'Tap Deezer or Spotify to switch back from extension';

  @override
  String get optionsAutoFallback => 'Auto Fallback';

  @override
  String get optionsAutoFallbackSubtitle =>
      'Try other services if download fails';

  @override
  String get optionsUseExtensionProviders => '拡張のプロバイダーを使用する';

  @override
  String get optionsUseExtensionProvidersOn => '最初に拡張で試みます';

  @override
  String get optionsUseExtensionProvidersOff => '内蔵のプロバイダーのみを使用する';

  @override
  String get optionsEmbedLyrics => '歌詞を埋め込む';

  @override
  String get optionsEmbedLyricsSubtitle => '同期する歌詞を FLAC ファイルに埋め込む';

  @override
  String get optionsMaxQualityCover => '最大品質のカバー';

  @override
  String get optionsMaxQualityCoverSubtitle => '最高解像度のカバーアートをダウンロード';

  @override
  String get optionsConcurrentDownloads => '同時ダウンロード';

  @override
  String get optionsConcurrentSequential => 'Sequential (1 at a time)';

  @override
  String optionsConcurrentParallel(int count) {
    return '$count 件の分割ダウンロード';
  }

  @override
  String get optionsConcurrentWarning =>
      'Parallel downloads may trigger rate limiting';

  @override
  String get optionsExtensionStore => '拡張ストア';

  @override
  String get optionsExtensionStoreSubtitle => 'ナビゲーションにストアタブを表示';

  @override
  String get optionsCheckUpdates => '更新を確認';

  @override
  String get optionsCheckUpdatesSubtitle =>
      'Notify when new version is available';

  @override
  String get optionsUpdateChannel => '更新チャンネル';

  @override
  String get optionsUpdateChannelStable => '安定版リリースのみ';

  @override
  String get optionsUpdateChannelPreview => 'プレビューリリースを入手';

  @override
  String get optionsUpdateChannelWarning =>
      'Preview may contain bugs or incomplete features';

  @override
  String get optionsClearHistory => 'ダウンロード履歴を消去';

  @override
  String get optionsClearHistorySubtitle => 'ダウンロード済みのすべてのトラックを履歴から削除';

  @override
  String get optionsDetailedLogging => '詳細ログ';

  @override
  String get optionsDetailedLoggingOn => '詳細なログを記録しています';

  @override
  String get optionsDetailedLoggingOff => 'バグレポートを有効';

  @override
  String get optionsSpotifyCredentials => 'Spotify の認証情報';

  @override
  String optionsSpotifyCredentialsConfigured(String clientId) {
    return 'クライアント ID: $clientId...';
  }

  @override
  String get optionsSpotifyCredentialsRequired => '必須 - タップで設定';

  @override
  String get optionsSpotifyWarning =>
      'Spotify は独自の API 認証情報が必要です。developer.spotify.com から取得できます。';

  @override
  String get optionsSpotifyDeprecationWarning =>
      'Spotify search will be deprecated on March 3, 2026 due to Spotify API changes. Please switch to Deezer.';

  @override
  String get extensionsTitle => '拡張';

  @override
  String get extensionsDisabled => '無効';

  @override
  String extensionsVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String extensionsAuthor(String author) {
    return '作者 $author';
  }

  @override
  String get extensionsUninstall => 'アンインストール';

  @override
  String get storeTitle => '拡張ストア';

  @override
  String get storeSearch => '拡張を検索...';

  @override
  String get storeInstall => 'インストール';

  @override
  String get storeInstalled => 'インストール済み';

  @override
  String get storeUpdate => '更新';

  @override
  String get aboutTitle => 'アプリについて';

  @override
  String get aboutContributors => '貢献者';

  @override
  String get aboutMobileDeveloper => 'モバイルバージョンの開発者';

  @override
  String get aboutOriginalCreator => 'オリジナルの SpotiFLAC の作者';

  @override
  String get aboutLogoArtist => '美しいアプリロゴを作成した才能あるアーティストです！';

  @override
  String get aboutTranslators => '翻訳者';

  @override
  String get aboutSpecialThanks => 'スペシャルサンクス';

  @override
  String get aboutLinks => 'リンク';

  @override
  String get aboutMobileSource => 'モバイル版のソースコード';

  @override
  String get aboutPCSource => 'PC 版のソースコード';

  @override
  String get aboutReportIssue => '問題を報告する';

  @override
  String get aboutReportIssueSubtitle => '問題が発生した場合に報告してください';

  @override
  String get aboutFeatureRequest => '機能の要望';

  @override
  String get aboutFeatureRequestSubtitle => 'アプリの新機能を提案する';

  @override
  String get aboutTelegramChannel => 'Telegram チャンネル';

  @override
  String get aboutTelegramChannelSubtitle => 'お知らせと更新';

  @override
  String get aboutTelegramChat => 'Telegram コミュニティ';

  @override
  String get aboutTelegramChatSubtitle => 'その他のユーザーとチャット';

  @override
  String get aboutSocial => 'ソーシャル';

  @override
  String get aboutApp => 'アプリ';

  @override
  String get aboutVersion => 'バージョン';

  @override
  String get aboutBinimumDesc =>
      'The creator of QQDL & HiFi API. Without this API, Tidal downloads wouldn\'t exist!';

  @override
  String get aboutSachinsenalDesc =>
      'The original HiFi project creator. The foundation of Tidal integration!';

  @override
  String get aboutSjdonadoDesc =>
      'Creator of I Don\'t Have Spotify (IDHS). The fallback link resolver that saves the day!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'The best Qobuz streaming API. Hi-Res downloads wouldn\'t be possible without this!';

  @override
  String get aboutSpotiSaver => 'SpotiSaver';

  @override
  String get aboutSpotiSaverDesc =>
      'Tidal Hi-Res FLAC streaming endpoints. A key piece of the lossless puzzle!';

  @override
  String get aboutAppDescription =>
      'Tidal、Qobuz、Amazon Music から Spotify のトラックをロスレス品質でダウンロードします。';

  @override
  String get artistAlbums => 'アルバム';

  @override
  String get artistSingles => 'シングルと EP';

  @override
  String get artistCompilations => 'コンピレーション';

  @override
  String get artistPopular => '人気';

  @override
  String artistMonthlyListeners(String count) {
    return '$count 人の月間リスナー';
  }

  @override
  String get trackMetadataService => 'サービス';

  @override
  String get trackMetadataPlay => '再生';

  @override
  String get trackMetadataShare => '共有';

  @override
  String get trackMetadataDelete => '削除';

  @override
  String get setupGrantPermission => '権限を許可';

  @override
  String get setupSkip => '今はスキップ';

  @override
  String get setupStorageAccessRequired => 'ストレージアクセスが必要です';

  @override
  String get setupStorageAccessMessageAndroid11 =>
      'Android 11+ requires \"All files access\" permission to save files to your chosen download folder.';

  @override
  String get setupOpenSettings => '設定を開く';

  @override
  String get setupPermissionDeniedMessage =>
      'Permission denied. Please grant all permissions to continue.';

  @override
  String setupPermissionRequired(String permissionType) {
    return '$permissionType の権限が必要です';
  }

  @override
  String setupPermissionRequiredMessage(String permissionType) {
    return '最適な体験を得るには $permissionType の権限が必要です。この権限は設定で後から変更できます。';
  }

  @override
  String get setupUseDefaultFolder => 'デフォルトのフォルダを使用しますか？';

  @override
  String get setupNoFolderSelected =>
      'No folder selected. Would you like to use the default Music folder?';

  @override
  String get setupUseDefault => 'デフォルトを使用する';

  @override
  String get setupDownloadLocationTitle => 'ダウンロード先';

  @override
  String get setupDownloadLocationIosMessage =>
      'On iOS, downloads are saved to the app\'s Documents folder. You can access them via the Files app.';

  @override
  String get setupAppDocumentsFolder => 'アプリのドキュメントフォルダ';

  @override
  String get setupAppDocumentsFolderSubtitle =>
      'Recommended - accessible via Files app';

  @override
  String get setupChooseFromFiles => 'ファイルから選択';

  @override
  String get setupChooseFromFilesSubtitle => 'iCloud またはその他の場所を選択';

  @override
  String get setupIosEmptyFolderWarning =>
      'iOS limitation: Empty folders cannot be selected. Choose a folder with at least one file.';

  @override
  String get setupIcloudNotSupported =>
      'iCloud Drive is not supported. Please use the app Documents folder.';

  @override
  String get setupDownloadInFlac => 'Spotify のトラックを FLAC でダウンロード';

  @override
  String get setupStorageGranted => 'ストレージの権限が許可されました！';

  @override
  String get setupStorageRequired => 'ストレージの権限が必要です';

  @override
  String get setupStorageDescription =>
      'SpotiFLAC はダウンロードした音楽ファイルを保存するためにストレージの権限が必要です。';

  @override
  String get setupNotificationGranted => '通知の権限が許可されました！';

  @override
  String get setupNotificationEnable => '通知を有効化する';

  @override
  String get setupFolderChoose => 'ダウンロードフォルダを選択';

  @override
  String get setupFolderDescription =>
      'Select a folder where your downloaded music will be saved.';

  @override
  String get setupSelectFolder => 'フォルダを選択';

  @override
  String get setupEnableNotifications => '通知を有効化する';

  @override
  String get setupNotificationBackgroundDescription =>
      'Get notified about download progress and completion. This helps you track downloads when the app is in background.';

  @override
  String get setupSkipForNow => '今はスキップ';

  @override
  String get setupNext => '次へ';

  @override
  String get setupGetStarted => 'Get Started';

  @override
  String get setupAllowAccessToManageFiles =>
      'Please enable \"Allow access to manage all files\" in the next screen.';

  @override
  String get dialogCancel => 'キャンセル';

  @override
  String get dialogSave => '保存';

  @override
  String get dialogDelete => '削除';

  @override
  String get dialogRetry => '再試行';

  @override
  String get dialogClear => '消去';

  @override
  String get dialogDone => '完了';

  @override
  String get dialogImport => 'インポート';

  @override
  String get dialogDiscard => '破棄';

  @override
  String get dialogRemove => '削除';

  @override
  String get dialogUninstall => 'アンインストール';

  @override
  String get dialogDiscardChanges => '変更を破棄しますか？';

  @override
  String get dialogUnsavedChanges =>
      'You have unsaved changes. Do you want to discard them?';

  @override
  String get dialogClearAll => 'すべて消去';

  @override
  String get dialogRemoveExtension => '拡張を削除';

  @override
  String get dialogRemoveExtensionMessage =>
      'Are you sure you want to remove this extension? This cannot be undone.';

  @override
  String get dialogUninstallExtension => '拡張をアンインストールしますか？';

  @override
  String dialogUninstallExtensionMessage(String extensionName) {
    return 'Are you sure you want to remove $extensionName?';
  }

  @override
  String get dialogClearHistoryTitle => '履歴を消去';

  @override
  String get dialogClearHistoryMessage =>
      'Are you sure you want to clear all download history? This cannot be undone.';

  @override
  String get dialogDeleteSelectedTitle => '選択済みを削除';

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
  String get dialogImportPlaylistTitle => 'プレイリストをインポート';

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
    return '「$trackName」をキューに追加しました';
  }

  @override
  String snackbarAddedTracksToQueue(int count) {
    return '$count 個のトラックをキューに追加しました';
  }

  @override
  String snackbarAlreadyDownloaded(String trackName) {
    return '「$trackName」は既にダウンロードされています';
  }

  @override
  String snackbarAlreadyInLibrary(String trackName) {
    return '\"$trackName\" already exists in your library';
  }

  @override
  String get snackbarHistoryCleared => '履歴を消去しました';

  @override
  String get snackbarCredentialsSaved => '認証情報を保存しました';

  @override
  String get snackbarCredentialsCleared => '認証情報を消去しました';

  @override
  String snackbarDeletedTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '個のトラック',
      one: '個のトラック',
    );
    return '$count $_temp0を削除';
  }

  @override
  String snackbarCannotOpenFile(String error) {
    return 'ファイルが開けません: $error';
  }

  @override
  String get snackbarFillAllFields => 'すべての項目を入力してください';

  @override
  String get snackbarViewQueue => 'キューを表示';

  @override
  String snackbarUrlCopied(String platform) {
    return '$platform の URL をクリップボードにコピーしました';
  }

  @override
  String get snackbarFileNotFound => 'ファイルがありません';

  @override
  String get snackbarSelectExtFile => '.spotiflac-ext ファイルを選択してください';

  @override
  String get snackbarProviderPrioritySaved => 'プロバイダーの優先度を保存しました';

  @override
  String get snackbarMetadataProviderSaved => 'メタデータプロバイダーの優先度を保存しました';

  @override
  String snackbarExtensionInstalled(String extensionName) {
    return '$extensionName をインストールしました。';
  }

  @override
  String snackbarExtensionUpdated(String extensionName) {
    return '$extensionName を更新しました。';
  }

  @override
  String get snackbarFailedToInstall => '拡張のインストールに失敗しました';

  @override
  String get snackbarFailedToUpdate => '拡張の更新に失敗しました';

  @override
  String get errorRateLimited => 'レート制限';

  @override
  String get errorRateLimitedMessage =>
      'Too many requests. Please wait a moment before searching again.';

  @override
  String get errorNoTracksFound => 'トラックがありません';

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
    return '$item を読み込めません: 拡張ソースがありません';
  }

  @override
  String get actionPause => '一時停止';

  @override
  String get actionResume => '再開';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionSelectAll => 'すべて選択';

  @override
  String get actionDeselect => '選択を解除';

  @override
  String get actionRemoveCredentials => '認証情報を削除';

  @override
  String get actionSaveCredentials => '認証情報を保存';

  @override
  String selectionSelected(int count) {
    return '$count 個を選択済み';
  }

  @override
  String get selectionAllSelected => 'すべてのトラックを選択済み';

  @override
  String get selectionSelectToDelete => 'トラックを選択で削除';

  @override
  String progressFetchingMetadata(int current, int total) {
    return 'メタデータを取得中... $current/$total';
  }

  @override
  String get progressReadingCsv => 'CSV を読み取り中...';

  @override
  String get searchSongs => '曲';

  @override
  String get searchArtists => 'アーティスト';

  @override
  String get searchAlbums => 'アルバム';

  @override
  String get searchPlaylists => 'プレイリスト';

  @override
  String get tooltipPlay => '再生';

  @override
  String get filenameFormat => 'ファイル名の形式';

  @override
  String get filenameShowAdvancedTags => 'Show advanced tags';

  @override
  String get filenameShowAdvancedTagsDescription =>
      'Enable formatted tags for track padding and date patterns';

  @override
  String get folderOrganizationNone => '構成がありません';

  @override
  String get folderOrganizationByPlaylist => 'By Playlist';

  @override
  String get folderOrganizationByPlaylistSubtitle =>
      'Separate folder for each playlist';

  @override
  String get folderOrganizationByArtist => 'アーティスト別';

  @override
  String get folderOrganizationByAlbum => 'アルバム別';

  @override
  String get folderOrganizationByArtistAlbum => 'アーティスト/アルバム';

  @override
  String get folderOrganizationDescription => 'ダウンロードしたファイルをフォルダに整理する';

  @override
  String get folderOrganizationNoneSubtitle => 'ダウンロードフォルダ内のすべてのファイル';

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
  String get updateAvailable => '更新が利用可能です';

  @override
  String get updateLater => '後で';

  @override
  String get updateStartingDownload => 'ダウンロードを開始中...';

  @override
  String get updateDownloadFailed => 'ダウンロードに失敗しました';

  @override
  String get updateFailedMessage => '更新のダウンロードに失敗しました';

  @override
  String get updateNewVersionReady => '新しいバージョンの準備ができています';

  @override
  String get updateCurrent => '現在';

  @override
  String get updateNew => '新着';

  @override
  String get updateDownloading => 'ダウンロード中...';

  @override
  String get updateWhatsNew => '新着情報';

  @override
  String get updateDownloadInstall => 'ダウンロードとインストール';

  @override
  String get updateDontRemind => '通知しない';

  @override
  String get providerPriorityTitle => 'プロバイダーの優先度';

  @override
  String get providerPriorityDescription =>
      'Drag to reorder download providers. The app will try providers from top to bottom when downloading tracks.';

  @override
  String get providerPriorityInfo =>
      'If a track is not available on the first provider, the app will automatically try the next one.';

  @override
  String get providerBuiltIn => '内蔵';

  @override
  String get providerExtension => '拡張';

  @override
  String get metadataProviderPriorityTitle => 'メタデータの優先度';

  @override
  String get metadataProviderPriorityDescription =>
      'Drag to reorder metadata providers. The app will try providers from top to bottom when searching for tracks and fetching metadata.';

  @override
  String get metadataProviderPriorityInfo =>
      'Deezer has no rate limits and is recommended as primary. Spotify may rate limit after many requests.';

  @override
  String get metadataNoRateLimits => 'レート制限はありません';

  @override
  String get metadataMayRateLimit => 'May rate limit';

  @override
  String get logTitle => 'ログ';

  @override
  String get logCopied => 'ログをクリップボードにコピーしました';

  @override
  String get logSearchHint => 'ログを検索...';

  @override
  String get logFilterLevel => 'レベル';

  @override
  String get logFilterSection => 'フィルター';

  @override
  String get logShareLogs => 'ログを共有';

  @override
  String get logClearLogs => 'ログを消去';

  @override
  String get logClearLogsTitle => 'ログを消去';

  @override
  String get logClearLogsMessage => 'すべてのログを消去してもよろしいですか？';

  @override
  String get logFilterBySeverity => 'Filter logs by severity';

  @override
  String get logNoLogsYet => 'まだログはありません';

  @override
  String get logNoLogsYetSubtitle => 'Logs will appear here as you use the app';

  @override
  String logEntriesFiltered(int count) {
    return 'エントリー ($count 個をフィルター済み)';
  }

  @override
  String logEntries(int count) {
    return 'エントリー ($count)';
  }

  @override
  String get credentialsTitle => 'Spotify の認証情報';

  @override
  String get credentialsDescription =>
      'Enter your Client ID and Secret to use your own Spotify application quota.';

  @override
  String get credentialsClientId => 'クライアント ID';

  @override
  String get credentialsClientIdHint => 'クライアント ID を貼り付け';

  @override
  String get credentialsClientSecret => 'クライアントシークレット';

  @override
  String get credentialsClientSecretHint => 'クライアントシークレットを貼り付け';

  @override
  String get channelStable => '安定版';

  @override
  String get channelPreview => 'プレビュー';

  @override
  String get sectionSearchSource => '検索ソース';

  @override
  String get sectionDownload => 'ダウンロード';

  @override
  String get sectionPerformance => 'パフォーマンス';

  @override
  String get sectionApp => 'アプリ';

  @override
  String get sectionData => 'データ';

  @override
  String get sectionDebug => 'デバッグ';

  @override
  String get sectionService => 'サービス';

  @override
  String get sectionAudioQuality => 'オーディオ品質';

  @override
  String get sectionFileSettings => 'ファイル設定';

  @override
  String get sectionLyrics => '歌詞';

  @override
  String get lyricsMode => '歌詞モード';

  @override
  String get lyricsModeDescription =>
      'Choose how lyrics are saved with your downloads';

  @override
  String get lyricsModeEmbed => 'Embed in file';

  @override
  String get lyricsModeEmbedSubtitle => 'FLAC メタデータに保存された歌詞';

  @override
  String get lyricsModeExternal => '外部 .lrc ファイル';

  @override
  String get lyricsModeExternalSubtitle =>
      'Separate .lrc file for players like Samsung Music';

  @override
  String get lyricsModeBoth => '両方';

  @override
  String get lyricsModeBothSubtitle => 'Embed and save .lrc file';

  @override
  String get sectionColor => 'カラー';

  @override
  String get sectionTheme => 'テーマ';

  @override
  String get sectionLayout => 'レイアウト';

  @override
  String get sectionLanguage => '言語';

  @override
  String get appearanceLanguage => 'アプリの言語';

  @override
  String get settingsAppearanceSubtitle => 'テーマ、カラー、画面';

  @override
  String get settingsDownloadSubtitle => 'サービス、品質、ファイル名、形式';

  @override
  String get settingsOptionsSubtitle => 'Fallback, lyrics, cover art, updates';

  @override
  String get settingsExtensionsSubtitle => 'ダウンロードプロバイダーを管理';

  @override
  String get settingsLogsSubtitle => 'デバッグのためのアプリログを表示';

  @override
  String get loadingSharedLink => '共有リンクを読み込み中...';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String downloadAllCount(int count) {
    return 'すべてダウンロード ($count)';
  }

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のトラック',
      one: '1 個のトラック',
    );
    return '$_temp0';
  }

  @override
  String get trackCopyFilePath => 'ファイルパスをコピー';

  @override
  String get trackRemoveFromDevice => 'デバイスから削除';

  @override
  String get trackLoadLyrics => '歌詞を読み込み';

  @override
  String get trackMetadata => 'メタデータ';

  @override
  String get trackFileInfo => 'ファイル情報';

  @override
  String get trackLyrics => '歌詞';

  @override
  String get trackFileNotFound => 'ファイルがありません';

  @override
  String get trackOpenInDeezer => 'Deezer で開く';

  @override
  String get trackOpenInSpotify => 'Spotify で開く';

  @override
  String get trackTrackName => 'トラック名';

  @override
  String get trackArtist => 'アーティスト';

  @override
  String get trackAlbumArtist => 'アルバムアーティスト';

  @override
  String get trackAlbum => 'アルバム';

  @override
  String get trackTrackNumber => 'トラック番号';

  @override
  String get trackDiscNumber => 'ディスク番号';

  @override
  String get trackDuration => '再生時間';

  @override
  String get trackAudioQuality => 'オーディオ品質';

  @override
  String get trackReleaseDate => 'リリース日';

  @override
  String get trackGenre => 'ジャンル';

  @override
  String get trackLabel => 'レーベル';

  @override
  String get trackCopyright => '著作権';

  @override
  String get trackDownloaded => 'ダウンロード済み';

  @override
  String get trackCopyLyrics => '歌詞をコピー';

  @override
  String get trackLyricsNotAvailable => 'このトラックの歌詞は利用できません';

  @override
  String get trackLyricsTimeout => 'リクエストがタイムアウトしました。後ほどお試しください。';

  @override
  String get trackLyricsLoadFailed => '歌詞の読み込みに失敗しました';

  @override
  String get trackEmbedLyrics => '歌詞を埋め込む';

  @override
  String get trackLyricsEmbedded => 'Lyrics embedded successfully';

  @override
  String get trackInstrumental => 'Instrumental track';

  @override
  String get trackCopiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get trackDeleteConfirmTitle => 'デバイスから削除しますか？';

  @override
  String get trackDeleteConfirmMessage =>
      'This will permanently delete the downloaded file and remove it from your history.';

  @override
  String get dateToday => '今日';

  @override
  String get dateYesterday => '昨日';

  @override
  String dateDaysAgo(int count) {
    return '$count 日前';
  }

  @override
  String dateWeeksAgo(int count) {
    return '$count 週間前';
  }

  @override
  String dateMonthsAgo(int count) {
    return '$count ヶ月前';
  }

  @override
  String get storeFilterAll => 'すべて';

  @override
  String get storeFilterMetadata => 'メタデータ';

  @override
  String get storeFilterDownload => 'ダウンロード';

  @override
  String get storeFilterUtility => 'ユーティリティ';

  @override
  String get storeFilterLyrics => '歌詞';

  @override
  String get storeFilterIntegration => '統合';

  @override
  String get storeClearFilters => 'フィルターを消去';

  @override
  String get extensionDefaultProvider => 'デフォルト (Deezer/Spotify)';

  @override
  String get extensionDefaultProviderSubtitle => '内蔵の検索を使用する';

  @override
  String get extensionAuthor => '作者';

  @override
  String get extensionId => 'ID';

  @override
  String get extensionError => 'エラー';

  @override
  String get extensionCapabilities => '機能';

  @override
  String get extensionMetadataProvider => 'メタデータのプロバイダー';

  @override
  String get extensionDownloadProvider => 'ダウンロードのプロバイダー';

  @override
  String get extensionLyricsProvider => '歌詞のプロバイダー';

  @override
  String get extensionUrlHandler => 'URL ハンドラ';

  @override
  String get extensionQualityOptions => '品質のオプション';

  @override
  String get extensionPostProcessingHooks => 'ポストプロセスフック';

  @override
  String get extensionPermissions => '権限';

  @override
  String get extensionSettings => '設定';

  @override
  String get extensionRemoveButton => '拡張を削除';

  @override
  String get extensionUpdated => '更新済み';

  @override
  String get extensionMinAppVersion => '最小のアプリバージョン';

  @override
  String get extensionCustomTrackMatching => 'カスタムトラックマッチング';

  @override
  String get extensionPostProcessing => 'ポストプロセス';

  @override
  String extensionHooksAvailable(int count) {
    return '$count 個のフックが利用可能です';
  }

  @override
  String extensionPatternsCount(int count) {
    return '$count 個のパターン';
  }

  @override
  String extensionStrategy(String strategy) {
    return 'ストラテジー: $strategy';
  }

  @override
  String get extensionsProviderPrioritySection => 'プロバイダーの優先度';

  @override
  String get extensionsInstalledSection => 'インストール済みの拡張';

  @override
  String get extensionsNoExtensions => '拡張はインストールされていません';

  @override
  String get extensionsNoExtensionsSubtitle =>
      '新しいプロバイダーを追加するには .spotiflac-ext ファイルをインストールします';

  @override
  String get extensionsInstallButton => '拡張をインストール';

  @override
  String get extensionsInfoTip =>
      '拡張は新しいメタデータとダウンロードプロバイダーを追加することがあります。信頼できるソースからの拡張のみをインストールしてください。';

  @override
  String get extensionsInstalledSuccess => '拡張のインストールが成功しました';

  @override
  String get extensionsDownloadPriority => 'ダウンロードの優先度';

  @override
  String get extensionsDownloadPrioritySubtitle => 'ダウンロードサービスの順序を設定';

  @override
  String get extensionsNoDownloadProvider => 'ダウンロードプロバイダーの拡張はありません';

  @override
  String get extensionsMetadataPriority => 'メタデータの優先度';

  @override
  String get extensionsMetadataPrioritySubtitle => '検索とメタデータソースの順序を設定';

  @override
  String get extensionsNoMetadataProvider => 'メタデータプロバイダーの拡張はありません';

  @override
  String get extensionsSearchProvider => '検索のプロバイダー';

  @override
  String get extensionsNoCustomSearch => 'カスタム検索の拡張はありません';

  @override
  String get extensionsSearchProviderDescription => 'トラックの検索に使用するサービスを選択してください';

  @override
  String get extensionsCustomSearch => 'カスタム検索';

  @override
  String get extensionsErrorLoading => '拡張の読み込みエラー';

  @override
  String get qualityFlacLossless => 'FLAC ロスレス';

  @override
  String get qualityFlacLosslessSubtitle => '16-bit / 44.1kHz';

  @override
  String get qualityHiResFlac => 'ハイレゾ FLAC';

  @override
  String get qualityHiResFlacSubtitle => '24-bit / 最大 96kHz';

  @override
  String get qualityHiResFlacMax => 'ハイレゾ FLAC 最大';

  @override
  String get qualityHiResFlacMaxSubtitle => '24-bit / 最大 192kHz';

  @override
  String get qualityNote => '実際の品質はサービスからのトラックの可用性に依存します';

  @override
  String get youtubeQualityNote =>
      'YouTube provides lossy audio only. Not part of lossless fallback.';

  @override
  String get youtubeOpusBitrateTitle => 'YouTube Opus のビットレート';

  @override
  String get youtubeMp3BitrateTitle => 'YouTube MP3 のビットレート';

  @override
  String get downloadAskBeforeDownload => 'ダウンロード前に確認する';

  @override
  String get downloadDirectory => 'ダウンロードディレクトリ';

  @override
  String get downloadSeparateSinglesFolder => 'シングルのフォルダを分割';

  @override
  String get downloadAlbumFolderStructure => 'アルバムフォルダの構造';

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
  String get downloadSelectQuality => '品質を選択';

  @override
  String get downloadFrom => 'ダウンロード元';

  @override
  String get appearanceAmoledDark => 'AMOLED ダーク';

  @override
  String get appearanceAmoledDarkSubtitle => 'ピュアブラックの背景';

  @override
  String get queueClearAll => 'すべて消去';

  @override
  String get queueClearAllMessage => 'すべてのダウンロードを消去してもよろしいですか？';

  @override
  String get settingsAutoExportFailed => 'ダウンロードの自動エクスポートに失敗しました';

  @override
  String get settingsAutoExportFailedSubtitle =>
      'Save failed downloads to TXT file automatically';

  @override
  String get settingsDownloadNetwork => 'ダウンロードネットワーク';

  @override
  String get settingsDownloadNetworkAny => 'Wi-Fi + モバイルデータ';

  @override
  String get settingsDownloadNetworkWifiOnly => 'Wi-Fi のみ';

  @override
  String get settingsDownloadNetworkSubtitle =>
      'Choose which network to use for downloads. When set to WiFi Only, downloads will pause on mobile data.';

  @override
  String get albumFolderArtistAlbum => 'アーティスト / アルバム';

  @override
  String get albumFolderArtistAlbumSubtitle => 'アルバム/アーティスト名/アルバム名/';

  @override
  String get albumFolderArtistYearAlbum => 'アーティスト / [年] アルバム';

  @override
  String get albumFolderArtistYearAlbumSubtitle => 'アルバム/アーティスト名/[2005] アルバム名/';

  @override
  String get albumFolderAlbumOnly => 'アルバムのみ';

  @override
  String get albumFolderAlbumOnlySubtitle => 'アルバム/アルバム名/';

  @override
  String get albumFolderYearAlbum => '[年] アルバム';

  @override
  String get albumFolderYearAlbumSubtitle => 'アルバム/[2005] アルバム名/';

  @override
  String get albumFolderArtistAlbumSingles => 'アーティスト / アルバム + シングル';

  @override
  String get albumFolderArtistAlbumSinglesSubtitle =>
      'Artist/Album/ and Artist/Singles/';

  @override
  String get downloadedAlbumDeleteSelected => '選択済みを削除';

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
    return '$count 個を選択済み';
  }

  @override
  String get downloadedAlbumAllSelected => 'すべてのトラックを選択済み';

  @override
  String get downloadedAlbumTapToSelect => 'トラックをタップで選択';

  @override
  String downloadedAlbumDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '個のトラック',
      one: '個のトラック',
    );
    return '$count $_temp0を削除';
  }

  @override
  String get downloadedAlbumSelectToDelete => 'トラックを選択で削除';

  @override
  String downloadedAlbumDiscHeader(int discNumber) {
    return 'ディスク $discNumber';
  }

  @override
  String get recentTypeArtist => 'アーティスト';

  @override
  String get recentTypeAlbum => 'アルバム';

  @override
  String get recentTypeSong => '曲';

  @override
  String get recentTypePlaylist => 'プレイリスト';

  @override
  String get recentEmpty => 'No recent items yet';

  @override
  String get recentShowAllDownloads => 'すべてのダウンロードを表示';

  @override
  String recentPlaylistInfo(String name) {
    return 'プレイリスト: $name';
  }

  @override
  String get discographyDownload => 'ディスコグラフィをダウンロード';

  @override
  String get discographyDownloadAll => 'すべてダウンロード';

  @override
  String discographyDownloadAllSubtitle(int count, int albumCount) {
    return '$albumCount 個のリリースから $count 個のトラック';
  }

  @override
  String get discographyAlbumsOnly => 'アルバムのみ';

  @override
  String discographyAlbumsOnlySubtitle(int count, int albumCount) {
    return '$count tracks from $albumCount albums';
  }

  @override
  String get discographySinglesOnly => 'シングルと EP のみ';

  @override
  String discographySinglesOnlySubtitle(int count, int albumCount) {
    return '$count tracks from $albumCount singles';
  }

  @override
  String get discographySelectAlbums => 'アルバムを選択...';

  @override
  String get discographySelectAlbumsSubtitle =>
      'Choose specific albums or singles';

  @override
  String get discographyFetchingTracks => 'トラックを取得中です...';

  @override
  String discographyFetchingAlbum(int current, int total) {
    return 'Fetching $current of $total...';
  }

  @override
  String discographySelectedCount(int count) {
    return '$count 個を選択済み';
  }

  @override
  String get discographyDownloadSelected => '選択済みをダウンロード';

  @override
  String discographyAddedToQueue(int count) {
    return 'Added $count tracks to queue';
  }

  @override
  String discographySkippedDownloaded(int added, int skipped) {
    return '$added added, $skipped already downloaded';
  }

  @override
  String get discographyNoAlbums => '利用可能なアルバムがありません';

  @override
  String get discographyFailedToFetch => '一部のアルバムの取得に失敗しました';

  @override
  String get sectionStorageAccess => 'ストレージアクセス';

  @override
  String get allFilesAccess => 'すべてのファイルへのアクセス';

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
  String get settingsLocalLibrary => 'ローカルライブラリ';

  @override
  String get settingsLocalLibrarySubtitle => 'Scan music & detect duplicates';

  @override
  String get settingsCache => 'ストレージとキャッシュ';

  @override
  String get settingsCacheSubtitle => 'View size and clear cached data';

  @override
  String get libraryTitle => 'ローカルライブラリ';

  @override
  String get libraryScanSettings => 'スキャン設定';

  @override
  String get libraryEnableLocalLibrary => 'ローカルライブラリを有効';

  @override
  String get libraryEnableLocalLibrarySubtitle =>
      'Scan and track your existing music';

  @override
  String get libraryFolder => 'ライブラリのフォルダ';

  @override
  String get libraryFolderHint => 'タップでフォルダを選択';

  @override
  String get libraryShowDuplicateIndicator => 'Show Duplicate Indicator';

  @override
  String get libraryShowDuplicateIndicatorSubtitle =>
      'Show when searching for existing tracks';

  @override
  String get libraryActions => 'アクション';

  @override
  String get libraryScan => 'ライブラリをスキャン';

  @override
  String get libraryScanSubtitle => 'オーディオファイルをスキャン';

  @override
  String get libraryScanSelectFolderFirst => 'Select a folder first';

  @override
  String get libraryCleanupMissingFiles => 'Cleanup Missing Files';

  @override
  String get libraryCleanupMissingFilesSubtitle =>
      'Remove entries for files that no longer exist';

  @override
  String get libraryClear => 'ライブラリを消去';

  @override
  String get libraryClearSubtitle => 'Remove all scanned tracks';

  @override
  String get libraryClearConfirmTitle => 'ライブラリを消去';

  @override
  String get libraryClearConfirmMessage =>
      'This will remove all scanned tracks from your library. Your actual music files will not be deleted.';

  @override
  String get libraryAbout => 'ローカルライブラリについて';

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
    return '最終スキャン: $time';
  }

  @override
  String get libraryLastScannedNever => 'Never';

  @override
  String get libraryScanning => 'スキャン中...';

  @override
  String libraryScanProgress(String progress, int total) {
    return '$progress% of $total files';
  }

  @override
  String get libraryInLibrary => 'ライブラリ内';

  @override
  String libraryRemovedMissingFiles(int count) {
    return 'Removed $count missing files from library';
  }

  @override
  String get libraryCleared => 'Library cleared';

  @override
  String get libraryStorageAccessRequired => 'ストレージアクセスが必要です';

  @override
  String get libraryStorageAccessMessage =>
      'SpotiFLAC needs storage access to scan your music library. Please grant permission in settings.';

  @override
  String get libraryFolderNotExist => 'Selected folder does not exist';

  @override
  String get librarySourceDownloaded => 'ダウンロード済み';

  @override
  String get librarySourceLocal => 'ローカル';

  @override
  String get libraryFilterAll => 'すべて';

  @override
  String get libraryFilterDownloaded => 'ダウンロード済み';

  @override
  String get libraryFilterLocal => 'ローカル';

  @override
  String get libraryFilterTitle => 'フィルター';

  @override
  String get libraryFilterReset => 'リセット';

  @override
  String get libraryFilterApply => '適用';

  @override
  String get libraryFilterSource => 'ソース';

  @override
  String get libraryFilterQuality => '品質';

  @override
  String get libraryFilterQualityHiRes => 'ハイレゾ (24bit)';

  @override
  String get libraryFilterQualityCD => 'CD (16bit)';

  @override
  String get libraryFilterQualityLossy => 'Lossy';

  @override
  String get libraryFilterFormat => '形式';

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
      other: '$count 分前',
      one: '1 分前',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 時間前',
      one: '1 時間前',
    );
    return '$_temp0';
  }

  @override
  String get tutorialWelcomeTitle => 'SpotiFLAC へようこそ！';

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
  String get tutorialDownloadTitle => '音楽をダウンロード中';

  @override
  String get tutorialDownloadDesc =>
      'Downloading music is simple and fast. Here\'s how it works.';

  @override
  String get tutorialLibraryTitle => 'あなたのライブラリ';

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
  String get tutorialExtensionsTitle => '拡張';

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
  String get libraryForceFullScan => '強制フルスキャン';

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
  String get cacheTitle => 'ストレージとキャッシュ';

  @override
  String get cacheSummaryTitle => 'キャッシュの概要';

  @override
  String get cacheSummarySubtitle =>
      'Clearing cache will not remove downloaded music files.';

  @override
  String cacheEstimatedTotal(String size) {
    return 'Estimated cache usage: $size';
  }

  @override
  String get cacheSectionStorage => 'キャッシュ済みデータ';

  @override
  String get cacheSectionMaintenance => 'メンテナンス';

  @override
  String get cacheAppDirectory => 'アプリキャッシュのディレクトリ';

  @override
  String get cacheAppDirectoryDesc =>
      'HTTP responses, WebView data, and other temporary app data.';

  @override
  String get cacheTempDirectory => '一時ディレクトリ';

  @override
  String get cacheTempDirectoryDesc =>
      'Temporary files from downloads and audio conversion.';

  @override
  String get cacheCoverImage => 'カバー画像のキャッシュ';

  @override
  String get cacheCoverImageDesc =>
      'Downloaded album and track cover art. Will re-download when viewed.';

  @override
  String get cacheLibraryCover => 'ライブラリのカバーキャッシュ';

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
  String get cacheNoData => 'キャッシュデータはありません';

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
    return '$count 個のエントリ';
  }

  @override
  String cacheClearSuccess(String target) {
    return '消去済み: $target';
  }

  @override
  String get cacheClearConfirmTitle => 'キャッシュを消去しますか？';

  @override
  String cacheClearConfirmMessage(String target) {
    return 'This will clear cached data for $target. Downloaded music files will not be deleted.';
  }

  @override
  String get cacheClearAllConfirmTitle => 'すべてのキャッシュを消去しますか？';

  @override
  String get cacheClearAllConfirmMessage =>
      'This will clear all cache categories on this page. Downloaded music files will not be deleted.';

  @override
  String get cacheClearAll => 'すべてのキャッシュを消去';

  @override
  String get cacheCleanupUnused => '未使用のデータを削除';

  @override
  String get cacheCleanupUnusedSubtitle =>
      'Remove orphaned download history and missing library entries';

  @override
  String cacheCleanupResult(int downloadCount, int libraryCount) {
    return 'Cleanup completed: $downloadCount orphaned downloads, $libraryCount missing library entries';
  }

  @override
  String get cacheRefreshStats => '状態を更新';

  @override
  String get trackSaveCoverArt => 'カバー画像を保存';

  @override
  String get trackSaveCoverArtSubtitle => 'Save album art as .jpg file';

  @override
  String get trackSaveLyrics => '歌詞を保存 (.lrc)';

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
  String get trackEditMetadata => 'メタデータを編集';

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
    return '失敗: $error';
  }

  @override
  String get trackConvertFormat => '変換の形式';

  @override
  String get trackConvertFormatSubtitle => 'MP3 または Opus に変換';

  @override
  String get trackConvertTitle => 'オーディオを変換';

  @override
  String get trackConvertTargetFormat => 'ターゲットの形式';

  @override
  String get trackConvertBitrate => 'ビットレート';

  @override
  String get trackConvertConfirmTitle => '変換を確認';

  @override
  String trackConvertConfirmMessage(
    String sourceFormat,
    String targetFormat,
    String bitrate,
  ) {
    return 'Convert from $sourceFormat to $targetFormat at $bitrate?\n\nThe original file will be deleted after conversion.';
  }

  @override
  String get trackConvertConverting => 'オーディオを変換中...';

  @override
  String trackConvertSuccess(String format) {
    return 'Converted to $format successfully';
  }

  @override
  String get trackConvertFailed => '変換に失敗しました';

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
    return '$count 個をダウンロード済み';
  }

  @override
  String get downloadUseAlbumArtistForFoldersAlbumSubtitle =>
      'Artist folders use Album Artist when available';

  @override
  String get downloadUseAlbumArtistForFoldersTrackSubtitle =>
      'Artist folders use Track Artist only';
}
