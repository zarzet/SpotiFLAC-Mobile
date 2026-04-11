// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'SpotiFLAC';

  @override
  String get navHome => 'Главная';

  @override
  String get navLibrary => 'Библиотека';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navStore => 'Магазин';

  @override
  String get homeTitle => 'Главная';

  @override
  String get homeSubtitle => 'Вставьте ссылку Spotify или ищите по названию';

  @override
  String get homeSupports =>
      'Поддерживается: Трек, Альбом, Плейлист, URL исполнителя';

  @override
  String get homeRecent => 'Недавние';

  @override
  String get historyFilterAll => 'Все';

  @override
  String get historyFilterAlbums => 'Альбомы';

  @override
  String get historyFilterSingles => 'Синглы';

  @override
  String get historySearchHint => 'Поиск в истории...';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsDownload => 'Скачивание';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsOptions => 'Опции';

  @override
  String get settingsExtensions => 'Расширения';

  @override
  String get settingsAbout => 'О программе';

  @override
  String get downloadTitle => 'Скачать';

  @override
  String get downloadAskQualitySubtitle =>
      'Показывать выбор качества для каждого скачивания';

  @override
  String get downloadFilenameFormat => 'Формат имени файла';

  @override
  String get downloadSingleFilenameFormat => 'Single Filename Format';

  @override
  String get downloadSingleFilenameFormatDescription =>
      'Filename pattern for singles and EPs. Uses the same tags as the album format.';

  @override
  String get downloadFolderOrganization => 'Организация папок';

  @override
  String get appearanceTitle => 'Внешний вид';

  @override
  String get appearanceThemeSystem => 'Системная';

  @override
  String get appearanceThemeLight => 'Светлая';

  @override
  String get appearanceThemeDark => 'Тёмная';

  @override
  String get appearanceDynamicColor => 'Динамический цвет';

  @override
  String get appearanceDynamicColorSubtitle =>
      'Использовать цвета из ваших обоев';

  @override
  String get appearanceHistoryView => 'Отображение истории';

  @override
  String get appearanceHistoryViewList => 'Список';

  @override
  String get appearanceHistoryViewGrid => 'Сетка';

  @override
  String get optionsTitle => 'Опции';

  @override
  String get optionsPrimaryProvider => 'Основной провайдер';

  @override
  String get optionsPrimaryProviderSubtitle =>
      'Сервис, используемый при поиске по названию трека.';

  @override
  String optionsUsingExtension(String extensionName) {
    return 'Используется расширение: $extensionName';
  }

  @override
  String get optionsDefaultSearchTab => 'Default Search Tab';

  @override
  String get optionsDefaultSearchTabSubtitle =>
      'Choose which tab opens first for new search results.';

  @override
  String get optionsSwitchBack =>
      'Нажмите Deezer или Spotify для возврата с расширения';

  @override
  String get optionsAutoFallback => 'Автоматический переход';

  @override
  String get optionsAutoFallbackSubtitle =>
      'Попробовать другие сервисы при сбое загрузки';

  @override
  String get optionsUseExtensionProviders =>
      'Использовать провайдера расширений';

  @override
  String get optionsUseExtensionProvidersOn =>
      'Сначала будут опробованы расширения';

  @override
  String get optionsUseExtensionProvidersOff =>
      'Использование только встроенных провайдеров';

  @override
  String get optionsEmbedLyrics => 'Вписать текст песни';

  @override
  String get optionsEmbedLyricsSubtitle =>
      'Вписать синхронизированные тексты во FLAC файлы';

  @override
  String get optionsMaxQualityCover => 'Максимальное качество обложки';

  @override
  String get optionsMaxQualityCoverSubtitle =>
      'Скачивать обложку в макс. разрешении';

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
  String get optionsConcurrentDownloads => 'Одновременные загрузки';

  @override
  String get optionsConcurrentSequential => 'Последовательно (1 за раз)';

  @override
  String optionsConcurrentParallel(int count) {
    return '$count параллельных загрузок';
  }

  @override
  String get optionsConcurrentWarning =>
      'Параллельные загрузки могут вызвать ограничение скорости';

  @override
  String get optionsExtensionStore => 'Магазин расширений';

  @override
  String get optionsExtensionStoreSubtitle =>
      'Показывать вкладку Магазин в гл. меню';

  @override
  String get optionsCheckUpdates => 'Проверить обновления';

  @override
  String get optionsCheckUpdatesSubtitle => 'Уведомлять о наличии новой версии';

  @override
  String get optionsUpdateChannel => 'Канал обновлений';

  @override
  String get optionsUpdateChannelStable => 'Только стабильные релизы';

  @override
  String get optionsUpdateChannelPreview => 'Предварительные версии';

  @override
  String get optionsUpdateChannelWarning =>
      'Предварительная версия может содержать ошибки или неполные функции';

  @override
  String get optionsClearHistory => 'Очистить историю загрузок';

  @override
  String get optionsClearHistorySubtitle =>
      'Удалить все скачанные треки из истории';

  @override
  String get optionsDetailedLogging => 'Подробный лог';

  @override
  String get optionsDetailedLoggingOn => 'Ведутся подробные логи';

  @override
  String get optionsDetailedLoggingOff => 'Включить для отчётов об ошибках';

  @override
  String get optionsSpotifyCredentials => 'Учётные данные Spotify';

  @override
  String optionsSpotifyCredentialsConfigured(String clientId) {
    return 'Client ID: $clientId...';
  }

  @override
  String get optionsSpotifyCredentialsRequired =>
      'Необходимо - нажмите для настройки';

  @override
  String get optionsSpotifyWarning =>
      'Spotify требует ваши собственные учетные данные API. Получите их бесплатно на сайте developer.spotify.com';

  @override
  String get optionsSpotifyDeprecationWarning =>
      'Поиск Spotify устареет 3 марта 2026 года из-за изменений Spotify API. Пожалуйста, перейдите на Deezer.';

  @override
  String get extensionsTitle => 'Расширения';

  @override
  String get extensionsDisabled => 'Выключено';

  @override
  String extensionsVersion(String version) {
    return 'Версия $version';
  }

  @override
  String extensionsAuthor(String author) {
    return 'от $author';
  }

  @override
  String get extensionsUninstall => 'Удалить';

  @override
  String get storeTitle => 'Магазин расширений';

  @override
  String get storeSearch => 'Поиск расширений...';

  @override
  String get storeInstall => 'Установить';

  @override
  String get storeInstalled => 'Установлено';

  @override
  String get storeUpdate => 'Обновить';

  @override
  String get aboutTitle => 'О программе';

  @override
  String get aboutContributors => 'Участники';

  @override
  String get aboutMobileDeveloper => 'Разработчик мобильной версии';

  @override
  String get aboutOriginalCreator => 'Создатель оригинального SpotiFLAC';

  @override
  String get aboutLogoArtist =>
      'Талантливый художник, который создал наш красивый логотип приложения!';

  @override
  String get aboutTranslators => 'Переводчики';

  @override
  String get aboutSpecialThanks => 'Особая благодарность';

  @override
  String get aboutLinks => 'Ссылки';

  @override
  String get aboutMobileSource => 'Исходный код мобильной версии';

  @override
  String get aboutPCSource => 'Исходный код ПК версии';

  @override
  String get aboutKeepAndroidOpen => 'Keep Android Open';

  @override
  String get aboutReportIssue => 'Сообщить о проблеме';

  @override
  String get aboutReportIssueSubtitle => 'Сообщите о возникших проблемах';

  @override
  String get aboutFeatureRequest => 'Предложить новую функцию';

  @override
  String get aboutFeatureRequestSubtitle =>
      'Предложить новые функции для приложения';

  @override
  String get aboutTelegramChannel => 'Telegram канал';

  @override
  String get aboutTelegramChannelSubtitle => 'Объявления и обновления';

  @override
  String get aboutTelegramChat => 'Сообщество в Telegram';

  @override
  String get aboutTelegramChatSubtitle => 'Чат с другими пользователями';

  @override
  String get aboutSocial => 'Соцсети';

  @override
  String get aboutApp => 'Приложение';

  @override
  String get aboutVersion => 'Версия';

  @override
  String get aboutBinimumDesc =>
      'Создатель QQDL & HiFi API. Без него API загрузки Tidal не существовали бы!';

  @override
  String get aboutSachinsenalDesc =>
      'Оригинальный создатель проекта HiFi. Основатель Tidal интеграции!';

  @override
  String get aboutSjdonadoDesc =>
      'Создатель I Don\'t Have Spotify (IDHS). Резервный резолвер ссылки';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'Лучший API для стриминга Qobuz. Без него загрузка файлов в высоком разрешении была бы невозможна!';

  @override
  String get aboutSpotiSaver => 'SpotiSaver';

  @override
  String get aboutSpotiSaverDesc =>
      'Потоковая передача Tidal Hi-Res FLAC. Ключевая часть lossless головоломки!';

  @override
  String get aboutAppDescription =>
      'Скачивайте треки Spotify в lossless качестве с Tidal и Qobuz.';

  @override
  String get artistAlbums => 'Альбомы';

  @override
  String get artistSingles => 'Синглы и EP';

  @override
  String get artistCompilations => 'Сборники';

  @override
  String get artistPopular => 'Популярное';

  @override
  String artistMonthlyListeners(String count) {
    return '$count слушателей в месяц';
  }

  @override
  String get trackMetadataService => 'Сервис';

  @override
  String get trackMetadataPlay => 'Воспроизвести';

  @override
  String get trackMetadataShare => 'Поделиться';

  @override
  String get trackMetadataDelete => 'Удалить';

  @override
  String get setupGrantPermission => 'Предоставить разрешение';

  @override
  String get setupSkip => 'Пропустить';

  @override
  String get setupStorageAccessRequired => 'Требуется доступ к хранилищу';

  @override
  String get setupStorageAccessMessageAndroid11 =>
      'Для Android 11+ требуется разрешение \"Доступ ко всем файлам\" для сохранения файлов в выбранную вами папку загрузки.';

  @override
  String get setupOpenSettings => 'Открыть настройки';

  @override
  String get setupPermissionDeniedMessage =>
      'В разрешении отказано. Пожалуйста, предоставьте все разрешения для продолжения.';

  @override
  String setupPermissionRequired(String permissionType) {
    return 'Требуется разрешение $permissionType';
  }

  @override
  String setupPermissionRequiredMessage(String permissionType) {
    return 'Для оптимальной работы требуется разрешение $permissionType. Вы можете изменить это позже в настройках.';
  }

  @override
  String get setupUseDefaultFolder => 'Использовать папку по умолчанию?';

  @override
  String get setupNoFolderSelected =>
      'Папка не выбрана. Хотите использовать папку Музыка по умолчанию?';

  @override
  String get setupUseDefault => 'По умолчанию';

  @override
  String get setupDownloadLocationTitle => 'Папка для скачивания';

  @override
  String get setupDownloadLocationIosMessage =>
      'В iOS загрузки сохраняются в папке Документы приложения. Вы можете получить к ним доступ через приложение Файлы.';

  @override
  String get setupAppDocumentsFolder => 'Папка Документы приложения';

  @override
  String get setupAppDocumentsFolderSubtitle =>
      'Рекомендуется - доступ через Файлы';

  @override
  String get setupChooseFromFiles => 'Выбрать из файлов';

  @override
  String get setupChooseFromFilesSubtitle =>
      'Выберите iCloud или другое местоположение';

  @override
  String get setupIosEmptyFolderWarning =>
      'Ограничение iOS: пустые папки не могут быть выбраны. Выберите папку, содержащую хотя бы один файл.';

  @override
  String get setupIcloudNotSupported =>
      'iCloud Drive не поддерживается. Пожалуйста, используйте папку Документы.';

  @override
  String get setupDownloadInFlac => 'Скачать Spotify треки во FLAC';

  @override
  String get setupStorageGranted => 'Доступ к хранилищу предоставлен!';

  @override
  String get setupStorageRequired => 'Требуется доступ к хранилищу';

  @override
  String get setupStorageDescription =>
      'SpotiFLAC требуется разрешение на хранение для сохранения скачанных файлов.';

  @override
  String get setupNotificationGranted =>
      'Разрешение на уведомление предоставлено!';

  @override
  String get setupNotificationEnable => 'Включить уведомления';

  @override
  String get setupFolderChoose => 'Выбрать папку для скачивания';

  @override
  String get setupFolderDescription =>
      'Выберите папку, в которой будет сохраняться скачанная музыка.';

  @override
  String get setupSelectFolder => 'Выбрать папку';

  @override
  String get setupEnableNotifications => 'Включить уведомления';

  @override
  String get setupNotificationBackgroundDescription =>
      'Получайте уведомления о ходе и завершении загрузки. Это поможет вам отслеживать загрузки, когда приложение находится в фоновом режиме.';

  @override
  String get setupSkipForNow => 'Пропустить';

  @override
  String get setupNext => 'Далее';

  @override
  String get setupGetStarted => 'Приступить к работе';

  @override
  String get setupAllowAccessToManageFiles =>
      'Пожалуйста, включите \"Разрешить доступ для управления всеми файлами\" на следующем экране.';

  @override
  String get dialogCancel => 'Отмена';

  @override
  String get dialogSave => 'Сохранить';

  @override
  String get dialogDelete => 'Удалить';

  @override
  String get dialogRetry => 'Повторить';

  @override
  String get dialogClear => 'Очистить';

  @override
  String get dialogDone => 'Готово';

  @override
  String get dialogImport => 'Импорт';

  @override
  String get dialogDownload => 'Download';

  @override
  String get dialogDiscard => 'Отменить';

  @override
  String get dialogRemove => 'Убрать';

  @override
  String get dialogUninstall => 'Удалить';

  @override
  String get dialogDiscardChanges => 'Отменить изменения?';

  @override
  String get dialogUnsavedChanges =>
      'Есть несохраненные изменения. Отменить их?';

  @override
  String get dialogClearAll => 'Очистить всё';

  @override
  String get dialogRemoveExtension => 'Удалить расширение';

  @override
  String get dialogRemoveExtensionMessage =>
      'Вы уверены, что хотите удалить это расширение? Это действие не может быть отменено.';

  @override
  String get dialogUninstallExtension => 'Удалить расширение?';

  @override
  String dialogUninstallExtensionMessage(String extensionName) {
    return 'Вы уверены, что хотите удалить $extensionName?';
  }

  @override
  String get dialogClearHistoryTitle => 'Очистить историю';

  @override
  String get dialogClearHistoryMessage =>
      'Вы уверены, что хотите удалить всю историю загрузок? Это действие необратимо.';

  @override
  String get dialogDeleteSelectedTitle => 'Удалить выбранные';

  @override
  String dialogDeleteSelectedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'треков',
      many: 'треков',
      few: 'трека',
      one: 'трек',
    );
    return 'Удалить $count $_temp0 из истории?\n\nЭто также удалит файлы из хранилища.';
  }

  @override
  String get dialogImportPlaylistTitle => 'Импорт плейлиста';

  @override
  String dialogImportPlaylistMessage(int count) {
    return 'Найдено $count треков в CSV. Добавить их в очередь загрузки?';
  }

  @override
  String csvImportTracks(int count) {
    return '$count трек(-ов) из CSV';
  }

  @override
  String snackbarAddedToQueue(String trackName) {
    return '\"$trackName\" добавлен в очередь';
  }

  @override
  String snackbarAddedTracksToQueue(int count) {
    return 'Добавлено $count треков в очередь';
  }

  @override
  String snackbarAlreadyDownloaded(String trackName) {
    return '\"$trackName\" уже скачан';
  }

  @override
  String snackbarAlreadyInLibrary(String trackName) {
    return '\"$trackName\" уже есть в вашей библиотеке';
  }

  @override
  String get snackbarHistoryCleared => 'История очищена';

  @override
  String get snackbarCredentialsSaved => 'Учётные данные сохранены';

  @override
  String get snackbarCredentialsCleared => 'Учётные данные очищены';

  @override
  String snackbarDeletedTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'треков',
      many: 'треков',
      few: 'трека',
      one: 'трек',
    );
    return 'Удалено $count $_temp0';
  }

  @override
  String snackbarCannotOpenFile(String error) {
    return 'Невозможно открыть файл: $error';
  }

  @override
  String get snackbarFillAllFields => 'Пожалуйста, заполните все поля';

  @override
  String get snackbarViewQueue => 'Просмотр очереди';

  @override
  String snackbarUrlCopied(String platform) {
    return '$platform ссылка скопирована в буфер обмена';
  }

  @override
  String get snackbarFileNotFound => 'Файл не найден';

  @override
  String get snackbarSelectExtFile =>
      'Пожалуйста, выберите .spotiflac-ext-файл';

  @override
  String get snackbarProviderPrioritySaved => 'Приоритет провайдера сохранён';

  @override
  String get snackbarMetadataProviderSaved =>
      'Приоритет провайдера метаданных сохранён';

  @override
  String snackbarExtensionInstalled(String extensionName) {
    return '$extensionName установлено.';
  }

  @override
  String snackbarExtensionUpdated(String extensionName) {
    return '$extensionName Обновлено.';
  }

  @override
  String get snackbarFailedToInstall => 'Не удалось установить расширение';

  @override
  String get snackbarFailedToUpdate => 'Не удалось обновить расширение';

  @override
  String get errorRateLimited => 'Слишком много запросов';

  @override
  String get errorRateLimitedMessage =>
      'Слишком много запросов. Пожалуйста, подождите минуту перед повторным поиском.';

  @override
  String get errorNoTracksFound => 'Треки не найдены';

  @override
  String get errorUrlNotRecognized => 'Ссылка не распознана';

  @override
  String get errorUrlNotRecognizedMessage =>
      'Эта ссылка не поддерживается. Убедитесь, что URL-адрес указан правильно и установлено совместимое расширение.';

  @override
  String get errorUrlFetchFailed =>
      'Не удалось загрузить контент по этой ссылке. Пожалуйста, попробуйте еще раз.';

  @override
  String errorMissingExtensionSource(String item) {
    return 'Невозможно загрузить $item: отсутствует источник расширения';
  }

  @override
  String get actionPause => 'Пауза';

  @override
  String get actionResume => 'Возобновить';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionSelectAll => 'Выбрать все';

  @override
  String get actionDeselect => 'Снять выделение';

  @override
  String get actionRemoveCredentials => 'Удалить учётные данные';

  @override
  String get actionSaveCredentials => 'Сохранить учётные данные';

  @override
  String selectionSelected(int count) {
    return '$count выбрано';
  }

  @override
  String get selectionAllSelected => 'Все треки выбраны';

  @override
  String get selectionSelectToDelete => 'Выберите треки для удаления';

  @override
  String progressFetchingMetadata(int current, int total) {
    return 'Получение метаданных... $current/$total';
  }

  @override
  String get progressReadingCsv => 'Чтение CSV...';

  @override
  String get searchSongs => 'Песни';

  @override
  String get searchArtists => 'Исполнители';

  @override
  String get searchAlbums => 'Альбомы';

  @override
  String get searchPlaylists => 'Плейлисты';

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
  String get tooltipPlay => 'Воспроизвести';

  @override
  String get filenameFormat => 'Формат имени файла';

  @override
  String get filenameShowAdvancedTags => 'Показать расширенные теги';

  @override
  String get filenameShowAdvancedTagsDescription =>
      'Включить форматированные теги для отслеживания заполнения и шаблонов дат';

  @override
  String get folderOrganizationNone => 'Без организации';

  @override
  String get folderOrganizationByPlaylist => 'По плейлисту';

  @override
  String get folderOrganizationByPlaylistSubtitle =>
      'Отдельная папка для каждого плейлиста';

  @override
  String get folderOrganizationByArtist => 'По исполнителю';

  @override
  String get folderOrganizationByAlbum => 'По альбому';

  @override
  String get folderOrganizationByArtistAlbum => 'Исполнитель/Альбом';

  @override
  String get folderOrganizationDescription =>
      'Сортировать скачанные файлы по папкам';

  @override
  String get folderOrganizationNoneSubtitle => 'Все файлы в папке загрузок';

  @override
  String get folderOrganizationByArtistSubtitle =>
      'Отдельная папка для каждого исполнителя';

  @override
  String get folderOrganizationByAlbumSubtitle =>
      'Отдельная папка для каждого альбома';

  @override
  String get folderOrganizationByArtistAlbumSubtitle =>
      'Вложенные папки для исполнителей и альбомов';

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get updateLater => 'Позже';

  @override
  String get updateStartingDownload => 'Загрузка началась...';

  @override
  String get updateDownloadFailed => 'Не удалось скачать';

  @override
  String get updateFailedMessage => 'Сбой загрузки обновления';

  @override
  String get updateNewVersionReady => 'Доступна новая версия';

  @override
  String get updateCurrent => 'Текущая';

  @override
  String get updateNew => 'Новая';

  @override
  String get updateDownloading => 'Скачивание...';

  @override
  String get updateWhatsNew => 'Что нового';

  @override
  String get updateDownloadInstall => 'Скачать и установить';

  @override
  String get updateDontRemind => 'Не напоминать';

  @override
  String get providerPriorityTitle => 'Приоритет провайдера';

  @override
  String get providerPriorityDescription =>
      'Перетаскивайте, чтобы изменить порядок провайдеров загрузки. Приложение будет пробовать провайдеров сверху вниз при загрузке треков.';

  @override
  String get providerPriorityInfo =>
      'Если трек не доступен у первого провайдера, приложение автоматически попробует следующий.';

  @override
  String get providerPriorityFallbackExtensionsTitle => 'Extension Fallback';

  @override
  String get providerPriorityFallbackExtensionsDescription =>
      'Choose which installed download extensions can be used during automatic fallback. Built-in providers still follow the priority order above.';

  @override
  String get providerPriorityFallbackExtensionsHint =>
      'Only enabled extensions with download-provider capability are listed here.';

  @override
  String get providerBuiltIn => 'Встроенные';

  @override
  String get providerExtension => 'Расширение';

  @override
  String get metadataProviderPriorityTitle => 'Приоритет метаданных';

  @override
  String get metadataProviderPriorityDescription =>
      'Перетаскивайте, чтобы изменить порядок провайдеров метаданных. Приложение будет пробовать провайдеров сверху вниз при поиске треков и извлечении метаданных.';

  @override
  String get metadataProviderPriorityInfo =>
      'Deezer не имеет ограничений по скорости и рекомендуется в качестве основного. Spotify может ограничивать скорость после большого количества запросов.';

  @override
  String get metadataNoRateLimits => 'Без ограничений по скорости';

  @override
  String get metadataMayRateLimit => 'Есть ограничения по скорости';

  @override
  String get logTitle => 'Логи';

  @override
  String get logCopied => 'Логи скопированы в буфер обмена';

  @override
  String get logSearchHint => 'Поиск логов...';

  @override
  String get logFilterLevel => 'Уровень';

  @override
  String get logFilterSection => 'Фильтр';

  @override
  String get logShareLogs => 'Поделиться логами';

  @override
  String get logClearLogs => 'Очистить логи';

  @override
  String get logClearLogsTitle => 'Очистить логи';

  @override
  String get logClearLogsMessage => 'Вы уверены, что хотите очистить все логи?';

  @override
  String get logFilterBySeverity => 'Фильтровать логи по серьезности';

  @override
  String get logNoLogsYet => 'Логов нет';

  @override
  String get logNoLogsYetSubtitle =>
      'Логи появятся здесь по мере использования приложения';

  @override
  String logEntriesFiltered(int count) {
    return 'Записи ($count фильтровано)';
  }

  @override
  String logEntries(int count) {
    return 'Записи ($count)';
  }

  @override
  String get credentialsTitle => 'Учётные данные Spotify';

  @override
  String get credentialsDescription =>
      'Введите свой Client ID и Secret, чтобы использовать собственные квоты в Spotify.';

  @override
  String get credentialsClientId => 'Client ID';

  @override
  String get credentialsClientIdHint => 'Вставьте Client ID';

  @override
  String get credentialsClientSecret => 'Client Secret';

  @override
  String get credentialsClientSecretHint => 'Вставьте Client Secret';

  @override
  String get channelStable => 'Стабильный';

  @override
  String get channelPreview => 'Предварительный';

  @override
  String get sectionSearchSource => 'Поиск источника';

  @override
  String get sectionDownload => 'Скачивание';

  @override
  String get sectionPerformance => 'Производительность';

  @override
  String get sectionApp => 'Приложение';

  @override
  String get sectionData => 'Данные';

  @override
  String get sectionDebug => 'Отладка';

  @override
  String get sectionService => 'Сервис';

  @override
  String get sectionAudioQuality => 'Качество аудио';

  @override
  String get sectionFileSettings => 'Настройки файла';

  @override
  String get sectionLyrics => 'Тексты песен';

  @override
  String get lyricsMode => 'Режим текстов песен';

  @override
  String get lyricsModeDescription =>
      'Выберите как сохранить тексты песен при скачивании';

  @override
  String get lyricsModeEmbed => 'Вписать в файл';

  @override
  String get lyricsModeEmbedSubtitle => 'Встроить текст в метаданные FLAC';

  @override
  String get lyricsModeExternal => 'Внешний файл .lrc';

  @override
  String get lyricsModeExternalSubtitle =>
      'Отдельный файл .lrc для плееров, таких, как Samsung Music';

  @override
  String get lyricsModeBoth => 'Оба варианта';

  @override
  String get lyricsModeBothSubtitle => 'Вписать и сохранить .lrc файл';

  @override
  String get sectionColor => 'Цвет';

  @override
  String get sectionTheme => 'Тема';

  @override
  String get sectionLayout => 'Разметка';

  @override
  String get sectionLanguage => 'Язык';

  @override
  String get appearanceLanguage => 'Язык приложения';

  @override
  String get settingsAppearanceSubtitle => 'Тема, цвета, дисплей';

  @override
  String get settingsDownloadSubtitle =>
      'Сервисы, качество, формат имени файла';

  @override
  String get settingsOptionsSubtitle =>
      'Резерв. сервер, тексты песен, обложки, обновления';

  @override
  String get settingsExtensionsSubtitle => 'Управление провайдерами скачивания';

  @override
  String get settingsLogsSubtitle => 'Просмотреть логи для отладки';

  @override
  String get loadingSharedLink => 'Загрузка общедоступной ссылки...';

  @override
  String get pressBackAgainToExit => 'Нажмите «Назад» ещё раз, чтобы выйти';

  @override
  String downloadAllCount(int count) {
    return 'Скачать все ($count)';
  }

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count треков',
      many: '$count треков',
      few: '$count трека',
      one: '$count трек',
    );
    return '$_temp0';
  }

  @override
  String get trackCopyFilePath => 'Скопировать путь к файлу';

  @override
  String get trackRemoveFromDevice => 'Удалить с устройства';

  @override
  String get trackLoadLyrics => 'Загрузить текст песни';

  @override
  String get trackMetadata => 'Метаданные';

  @override
  String get trackFileInfo => 'Информация о файле';

  @override
  String get trackLyrics => 'Текст песни';

  @override
  String get trackFileNotFound => 'Файл не найден';

  @override
  String get trackOpenInDeezer => 'Открыть в Deezer';

  @override
  String get trackOpenInSpotify => 'Открыть в Spotify';

  @override
  String get trackTrackName => 'Название';

  @override
  String get trackArtist => 'Исполнитель';

  @override
  String get trackAlbumArtist => 'Исполнитель альбома';

  @override
  String get trackAlbum => 'Альбом';

  @override
  String get trackTrackNumber => 'Номер трека';

  @override
  String get trackDiscNumber => 'Номер диска';

  @override
  String get trackDuration => 'Продолжительность';

  @override
  String get trackAudioQuality => 'Качество записи';

  @override
  String get trackReleaseDate => 'Дата выхода';

  @override
  String get trackGenre => 'Жанр';

  @override
  String get trackLabel => 'Заголовок';

  @override
  String get trackCopyright => 'Авторские права';

  @override
  String get trackDownloaded => 'Скачано';

  @override
  String get trackCopyLyrics => 'Копировать текст';

  @override
  String get trackLyricsNotAvailable =>
      'Текст песни недоступен для этого трека';

  @override
  String get trackLyricsNotInFile => 'No lyrics found in this file';

  @override
  String get trackFetchOnlineLyrics => 'Fetch from Online';

  @override
  String get trackLyricsTimeout =>
      'Время ожидания запроса истекло. Повторите попытку позже.';

  @override
  String get trackLyricsLoadFailed => 'Не удалось загрузить текст песни';

  @override
  String get trackEmbedLyrics => 'Вписать текст песни';

  @override
  String get trackLyricsEmbedded => 'Текст успешно добавлен';

  @override
  String get trackInstrumental => 'Инструментальный трек';

  @override
  String get trackCopiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get trackDeleteConfirmTitle => 'Удалить с устройства?';

  @override
  String get trackDeleteConfirmMessage =>
      'Это приведет к окончательному удалению загруженного файла и его удалению из истории.';

  @override
  String get dateToday => 'Сегодня';

  @override
  String get dateYesterday => 'Вчера';

  @override
  String dateDaysAgo(int count) {
    return '$count дней назад';
  }

  @override
  String dateWeeksAgo(int count) {
    return '$count недель назад';
  }

  @override
  String dateMonthsAgo(int count) {
    return '$count месяцев назад';
  }

  @override
  String get storeFilterAll => 'Все';

  @override
  String get storeFilterMetadata => 'Метаданные';

  @override
  String get storeFilterDownload => 'Скачивание';

  @override
  String get storeFilterUtility => 'Утилиты';

  @override
  String get storeFilterLyrics => 'Тексты песен';

  @override
  String get storeFilterIntegration => 'Интеграция';

  @override
  String get storeClearFilters => 'Очистить фильтры';

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
  String get extensionDefaultProvider => 'По умолчанию (Deezer/Spotify)';

  @override
  String get extensionDefaultProviderSubtitle =>
      'Использовать встроенный поиск';

  @override
  String get extensionAuthor => 'Автор';

  @override
  String get extensionId => 'ID';

  @override
  String get extensionError => 'Ошибка';

  @override
  String get extensionCapabilities => 'Возможности';

  @override
  String get extensionMetadataProvider => 'Провайдер метаданных';

  @override
  String get extensionDownloadProvider => 'Провайдер скачивания';

  @override
  String get extensionLyricsProvider => 'Провайдер текстов';

  @override
  String get extensionUrlHandler => 'URL-обработчик';

  @override
  String get extensionQualityOptions => 'Параметры качества';

  @override
  String get extensionPostProcessingHooks => 'Хуки постобработки';

  @override
  String get extensionPermissions => 'Разрешения';

  @override
  String get extensionSettings => 'Настройки';

  @override
  String get extensionRemoveButton => 'Удалить расширение';

  @override
  String get extensionUpdated => 'Обновлено';

  @override
  String get extensionMinAppVersion => 'Мин. версия приложения';

  @override
  String get extensionCustomTrackMatching =>
      'Соответствие пользовательских треков';

  @override
  String get extensionPostProcessing => 'Постобработка';

  @override
  String extensionHooksAvailable(int count) {
    return 'Доступно $count хуков(ов)';
  }

  @override
  String extensionPatternsCount(int count) {
    return '$count шаблон(ов)';
  }

  @override
  String extensionStrategy(String strategy) {
    return 'Стратегия: $strategy';
  }

  @override
  String get extensionsProviderPrioritySection => 'Приоритет провайдера';

  @override
  String get extensionsInstalledSection => 'Установленные расширения';

  @override
  String get extensionsNoExtensions => 'Нет установленных расширений';

  @override
  String get extensionsNoExtensionsSubtitle =>
      'Установите .spotiflac-ext файлы для добавления новых провайдеров';

  @override
  String get extensionsInstallButton => 'Установить расширение';

  @override
  String get extensionsInfoTip =>
      'Расширения могут добавлять новые метаданные и провайдеров загрузки. Устанавливайте только расширения из надежных источников.';

  @override
  String get extensionsInstalledSuccess => 'Расширение успешно установлено';

  @override
  String get extensionsDownloadPriority => 'Приоритет скачивания';

  @override
  String get extensionsDownloadPrioritySubtitle =>
      'Установка порядок сервисов скачивания';

  @override
  String get extensionsFallbackTitle => 'Fallback Extensions';

  @override
  String get extensionsFallbackSubtitle =>
      'Choose which installed download extensions can be used as fallback';

  @override
  String get extensionsNoDownloadProvider =>
      'Нет расширений с провайдером загрузки';

  @override
  String get extensionsMetadataPriority => 'Приоритет метаданных';

  @override
  String get extensionsMetadataPrioritySubtitle =>
      'Установка порядка поиска и источника метаданных';

  @override
  String get extensionsNoMetadataProvider =>
      'Нет расширений с провайдером метаданных';

  @override
  String get extensionsSearchProvider => 'Провайдер поиска';

  @override
  String get extensionsNoCustomSearch =>
      'Нет расширений с пользовательским поиском';

  @override
  String get extensionsSearchProviderDescription =>
      'Выберите, какой сервис использовать для поиска треков';

  @override
  String get extensionsCustomSearch => 'Пользовательский поиск';

  @override
  String get extensionsErrorLoading => 'Ошибка загрузки расширения';

  @override
  String get qualityFlacLossless => 'FLAC Lossless';

  @override
  String get qualityFlacLosslessSubtitle => '16-бит / 44.1 кГц';

  @override
  String get qualityHiResFlac => 'Hi-Res FLAC';

  @override
  String get qualityHiResFlacSubtitle => '24-бит / до 96кГц';

  @override
  String get qualityHiResFlacMax => 'Hi-Res FLAC Макс.';

  @override
  String get qualityHiResFlacMaxSubtitle => '24-бит / до 192кГц';

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
      'Фактическое качество зависит от доступности треков в сервисе';

  @override
  String get downloadAskBeforeDownload => 'Спрашивать перед скачиванием';

  @override
  String get downloadDirectory => 'Папка для скачивания';

  @override
  String get downloadSeparateSinglesFolder => 'Отдельная папка для синглов';

  @override
  String get downloadAlbumFolderStructure => 'Структура папок альбома';

  @override
  String get downloadUseAlbumArtistForFolders =>
      'Использовать исполнителя альбома для папок';

  @override
  String get downloadUsePrimaryArtistOnly =>
      'Основной исполнитель только для папок';

  @override
  String get downloadUsePrimaryArtistOnlyEnabled =>
      'Список исполнителей, чьи работы были удалены из названия папки (например, Джастин Бибер, Quavo → Джастин Бибер)';

  @override
  String get downloadUsePrimaryArtistOnlyDisabled =>
      'Полная строка исполнителя, используемая для имени папки';

  @override
  String get downloadSelectQuality => 'Выбор качества';

  @override
  String get downloadFrom => 'Скачивать из';

  @override
  String get appearanceAmoledDark => 'AMOLED';

  @override
  String get appearanceAmoledDarkSubtitle => 'Глубокий чёрный фон';

  @override
  String get queueClearAll => 'Очистить всё';

  @override
  String get queueClearAllMessage =>
      'Вы уверены, что хотите очистить все загрузки?';

  @override
  String get settingsAutoExportFailed => 'Автоэкспорт неудачных загрузок';

  @override
  String get settingsAutoExportFailedSubtitle =>
      'Автоматическое сохранение неудачных загрузок в TXT файл';

  @override
  String get settingsDownloadNetwork => 'Сеть для скачивания';

  @override
  String get settingsDownloadNetworkAny => 'WiFi и Мобильная сеть';

  @override
  String get settingsDownloadNetworkWifiOnly => 'Только WiFi';

  @override
  String get settingsDownloadNetworkSubtitle =>
      'Выберите, какую сеть использовать для скачивания. Когда установлено значение только WiFi — скачивания через мобильную сеть будут приостановлены.';

  @override
  String get albumFolderArtistAlbum => 'Исполнитель / Альбом';

  @override
  String get albumFolderArtistAlbumSubtitle =>
      'Альбомы/Исполнитель/Название Альбома/';

  @override
  String get albumFolderArtistYearAlbum => 'Исполнитель / [Год] Альбом';

  @override
  String get albumFolderArtistYearAlbumSubtitle =>
      'Альбомы/Исполнитель/[2005] Название Альбома/';

  @override
  String get albumFolderAlbumOnly => 'Только альбом';

  @override
  String get albumFolderAlbumOnlySubtitle => 'Альбомы/Название Альбома/';

  @override
  String get albumFolderYearAlbum => '[Год] Альбом';

  @override
  String get albumFolderYearAlbumSubtitle =>
      'Альбомы/[2005] Название Альбома /';

  @override
  String get albumFolderArtistAlbumSingles => 'Исполнитель / Альбом + Синглы';

  @override
  String get albumFolderArtistAlbumSinglesSubtitle =>
      'Исполнитель/Альбом и Исполнитель/Сингл/';

  @override
  String get albumFolderArtistAlbumFlat => 'Artist / Album (Singles flat)';

  @override
  String get albumFolderArtistAlbumFlatSubtitle =>
      'Artist/Album/ and Artist/song.flac';

  @override
  String get downloadedAlbumDeleteSelected => 'Удалить выбранные';

  @override
  String downloadedAlbumDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'треков',
      many: 'треков',
      few: 'трека',
      one: 'трек',
    );
    return 'Удалить $count $_temp0 из этого альбома?\n\nЭто также удалит файлы из хранилища.';
  }

  @override
  String downloadedAlbumSelectedCount(int count) {
    return '$count выбрано';
  }

  @override
  String get downloadedAlbumAllSelected => 'Все треки выбраны';

  @override
  String get downloadedAlbumTapToSelect => 'Нажмите на треки для выбора';

  @override
  String downloadedAlbumDeleteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'треков',
      many: 'треков',
      few: 'трека',
      one: 'трек',
    );
    return 'Удалить $count $_temp0';
  }

  @override
  String get downloadedAlbumSelectToDelete => 'Выберите треки для удаления';

  @override
  String downloadedAlbumDiscHeader(int discNumber) {
    return 'Диск $discNumber';
  }

  @override
  String get recentTypeArtist => 'Исполнитель';

  @override
  String get recentTypeAlbum => 'Альбом';

  @override
  String get recentTypeSong => 'Песня';

  @override
  String get recentTypePlaylist => 'Плейлист';

  @override
  String get recentEmpty => 'Нет недавних элементов';

  @override
  String get recentShowAllDownloads => 'Показать все загрузки';

  @override
  String recentPlaylistInfo(String name) {
    return 'Плейлист: $name';
  }

  @override
  String get discographyDownload => 'Скачать дискографию';

  @override
  String get discographyDownloadAll => 'Скачать всё';

  @override
  String discographyDownloadAllSubtitle(int count, int albumCount) {
    return '$count треков из $albumCount релизов';
  }

  @override
  String get discographyAlbumsOnly => 'Только альбомы';

  @override
  String discographyAlbumsOnlySubtitle(int count, int albumCount) {
    return '$count треков из $albumCount альбомов';
  }

  @override
  String get discographySinglesOnly => 'Только синглы и EP';

  @override
  String discographySinglesOnlySubtitle(int count, int albumCount) {
    return '$count треков из $albumCount синглов';
  }

  @override
  String get discographySelectAlbums => 'Выбрать альбомы...';

  @override
  String get discographySelectAlbumsSubtitle =>
      'Выберите конкретные альбомы или синглы';

  @override
  String get discographyFetchingTracks => 'Получение треков...';

  @override
  String discographyFetchingAlbum(int current, int total) {
    return 'Получение $current из $total...';
  }

  @override
  String discographySelectedCount(int count) {
    return '$count выбрано';
  }

  @override
  String get discographyDownloadSelected => 'Скачать выбранное';

  @override
  String discographyAddedToQueue(int count) {
    return 'Добавлено $count треков в очередь';
  }

  @override
  String discographySkippedDownloaded(int added, int skipped) {
    return '$added добавлено, $skipped уже скачано';
  }

  @override
  String get discographyNoAlbums => 'Нет доступных альбомов';

  @override
  String get discographyFailedToFetch =>
      'Не удалось получить некоторые альбомы';

  @override
  String get sectionStorageAccess => 'Доступ к хранилищу';

  @override
  String get allFilesAccess => 'Доступ ко всем файлам';

  @override
  String get allFilesAccessEnabledSubtitle => 'Можно записать в любую папку';

  @override
  String get allFilesAccessDisabledSubtitle =>
      'Ограничено только папками медиа';

  @override
  String get allFilesAccessDescription =>
      'Включите, если вы сталкиваетесь с ошибками записи при сохранении в пользовательские папки. Android 13+ по умолчанию ограничивает доступ к определенным папкам.';

  @override
  String get allFilesAccessDeniedMessage =>
      'В разрешении отказано. Пожалуйста, включите функцию «Доступ ко всем файлам» в настройках системы.';

  @override
  String get allFilesAccessDisabledMessage =>
      'Доступ ко всем файлам отключен. Приложение будет использовать ограниченный доступ к хранилищу.';

  @override
  String get settingsLocalLibrary => 'Локальная библиотека';

  @override
  String get settingsLocalLibrarySubtitle =>
      'Сканировать и обнаружить дубликаты';

  @override
  String get settingsCache => 'Хранилище и кэш';

  @override
  String get settingsCacheSubtitle => 'Просмотреть размер и очистить кэш';

  @override
  String get libraryTitle => 'Локальная библиотека';

  @override
  String get libraryScanSettings => 'Настройки сканирования';

  @override
  String get libraryEnableLocalLibrary => 'Включить локальную библиотеку';

  @override
  String get libraryEnableLocalLibrarySubtitle =>
      'Сканировать и отслеживать вашу существующую музыку';

  @override
  String get libraryFolder => 'Папка библиотеки';

  @override
  String get libraryFolderHint => 'Нажмите, чтобы выбрать папку';

  @override
  String get libraryShowDuplicateIndicator => 'Показать индикатор дубликатов';

  @override
  String get libraryShowDuplicateIndicatorSubtitle =>
      'Показать при поиске существующих треков';

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
  String get libraryActions => 'Действия';

  @override
  String get libraryScan => 'Сканировать библиотеку';

  @override
  String get libraryScanSubtitle => 'Сканировать аудио файлы';

  @override
  String get libraryScanSelectFolderFirst => 'Сначала выберите папку';

  @override
  String get libraryCleanupMissingFiles => 'Очистка отсутствующих файлов';

  @override
  String get libraryCleanupMissingFilesSubtitle =>
      'Удалить записи для файлов, которых больше не существует';

  @override
  String get libraryClear => 'Очистить библиотеку';

  @override
  String get libraryClearSubtitle => 'Удалить все сканированные треки';

  @override
  String get libraryClearConfirmTitle => 'Очистить библиотеку';

  @override
  String get libraryClearConfirmMessage =>
      'Это удалит все сканированные треки из вашей библиотеки. Ваши фактические файлы не будут удалены.';

  @override
  String get libraryAbout => 'О локальной библиотеке';

  @override
  String get libraryAboutDescription =>
      'Сканирует существующую коллекцию музыки для обнаружения дубликатов при загрузке. Поддерживает форматы FLAC, M4A, MP3, Opus и OGG. Метаданные читаются из тегов файлов, если доступны.';

  @override
  String libraryTracksUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'треков',
      many: 'треков',
      few: 'трека',
      one: 'трек',
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
    return 'Последнее сканирование: $time';
  }

  @override
  String get libraryLastScannedNever => 'Никогда';

  @override
  String get libraryScanning => 'Сканирование...';

  @override
  String get libraryScanFinalizing => 'Finalizing library...';

  @override
  String libraryScanProgress(String progress, int total) {
    return '$progress% из $total файлов';
  }

  @override
  String get libraryInLibrary => 'В библиотеке';

  @override
  String libraryRemovedMissingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'отсутствующих файлов',
      many: 'отсутствующих файлов',
      few: 'трека',
      one: 'отсутствующий файл',
    );
    return 'Удалено $count $_temp0 в библиотеке';
  }

  @override
  String get libraryCleared => 'Библиотека очищена';

  @override
  String get libraryStorageAccessRequired => 'Требуется доступ к хранилищу';

  @override
  String get libraryStorageAccessMessage =>
      'SpotiFLAC требуется доступ к хранилищу для сканирования вашей библиотеки музыки. Пожалуйста, предоставьте разрешение в настройках.';

  @override
  String get libraryFolderNotExist => 'Выбранной папки не существует';

  @override
  String get librarySourceDownloaded => 'Скачанные';

  @override
  String get librarySourceLocal => 'Локальные';

  @override
  String get libraryFilterAll => 'Все';

  @override
  String get libraryFilterDownloaded => 'Скачанные';

  @override
  String get libraryFilterLocal => 'Локальные';

  @override
  String get libraryFilterTitle => 'Фильтры';

  @override
  String get libraryFilterReset => 'Сброс';

  @override
  String get libraryFilterApply => 'Применить';

  @override
  String get libraryFilterSource => 'Источник';

  @override
  String get libraryFilterQuality => 'Качество';

  @override
  String get libraryFilterQualityHiRes => 'Hi-Res (24 бит)';

  @override
  String get libraryFilterQualityCD => 'CD (16 бит)';

  @override
  String get libraryFilterQualityLossy => 'Lossy';

  @override
  String get libraryFilterFormat => 'Формат';

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
  String get libraryFilterSort => 'Сортировка';

  @override
  String get libraryFilterSortLatest => 'Последние';

  @override
  String get libraryFilterSortOldest => 'Старые';

  @override
  String get libraryFilterSortAlbumAsc => 'Album (A-Z)';

  @override
  String get libraryFilterSortAlbumDesc => 'Album (Z-A)';

  @override
  String get libraryFilterSortGenreAsc => 'Genre (A-Z)';

  @override
  String get libraryFilterSortGenreDesc => 'Genre (Z-A)';

  @override
  String get timeJustNow => 'Только что';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минут',
      many: '$count минут',
      few: '$count минуты',
      one: '$count минуту',
    );
    return '$_temp0 назад';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часов',
      many: '$count часов',
      few: '$count часа',
      one: '$count час',
    );
    return '$_temp0 назад';
  }

  @override
  String get tutorialWelcomeTitle => 'Добро пожаловать в SpotiFLAC!';

  @override
  String get tutorialWelcomeDesc =>
      'Давайте научимся скачивать свою любимую музыку в качестве без потерь. В этом кратком руководстве мы покажем вам основы.';

  @override
  String get tutorialWelcomeTip1 =>
      'Скачивайте музыку из Spotify, Deezer, или вставьте любой поддерживаемый URL';

  @override
  String get tutorialWelcomeTip2 =>
      'Получите аудио в качестве FLAC от Tidal, Qobuz или Deezer';

  @override
  String get tutorialWelcomeTip3 =>
      'Автоматическое встраивание метаданных, обложек и текстов песен';

  @override
  String get tutorialSearchTitle => 'Поиск музыки';

  @override
  String get tutorialSearchDesc =>
      'Есть два простых способа найти музыку, которую вы хотите скачать.';

  @override
  String get tutorialDownloadTitle => 'Скачивание музыки';

  @override
  String get tutorialDownloadDesc =>
      'Скачивание музыки просто и быстро. Вот как это работает.';

  @override
  String get tutorialLibraryTitle => 'Ваша библиотека';

  @override
  String get tutorialLibraryDesc =>
      'Вся скачанная музыка организована во вкладке Библиотека.';

  @override
  String get tutorialLibraryTip1 =>
      'Просмотр прогресса загрузки и очереди на вкладке Библиотека';

  @override
  String get tutorialLibraryTip2 =>
      'Нажмите на любой трек, чтобы воспроизвести его с помощью вашего музыкального плеера';

  @override
  String get tutorialLibraryTip3 =>
      'Переключение между списком и сеткой для лучшего просмотра';

  @override
  String get tutorialExtensionsTitle => 'Расширения';

  @override
  String get tutorialExtensionsDesc =>
      'Расширьте возможности приложения с расширениями от сообщества.';

  @override
  String get tutorialExtensionsTip1 =>
      'Просмотрите вкладку Магазина, чтобы найти полезные расширения';

  @override
  String get tutorialExtensionsTip2 =>
      'Добавить новых поставщиков загрузок или поиска';

  @override
  String get tutorialExtensionsTip3 =>
      'Получайте тексты песен, улучшенные метаданные и другие возможности';

  @override
  String get tutorialSettingsTitle => 'Настройте приложение под себя';

  @override
  String get tutorialSettingsDesc =>
      'Персонализируйте приложение в Настройках, чтобы оно соответствовало вашим предпочтениям.';

  @override
  String get tutorialSettingsTip1 =>
      'Изменить местоположение и организацию папок для скачивания';

  @override
  String get tutorialSettingsTip2 =>
      'Настройте качество и формата аудиофайла по умолчанию';

  @override
  String get tutorialSettingsTip3 => 'Настроить тему и внешний вид приложения';

  @override
  String get tutorialReadyMessage =>
      'Всё готово! Начните загружать любимую музыку прямо сейчас.';

  @override
  String get libraryForceFullScan => 'Полное сканирование';

  @override
  String get libraryForceFullScanSubtitle =>
      'Пересканировать все файлы, игнорировать кэш';

  @override
  String get cleanupOrphanedDownloads => 'Очистка отложенных скачиваний';

  @override
  String get cleanupOrphanedDownloadsSubtitle =>
      'Удалить историю записи для файлов, которых больше не существует';

  @override
  String cleanupOrphanedDownloadsResult(int count) {
    return 'Удалено $count утерянных записей из истории';
  }

  @override
  String get cleanupOrphanedDownloadsNone => 'Записей без описания не найдено';

  @override
  String get cacheTitle => 'Хранилище и кэш';

  @override
  String get cacheSummaryTitle => 'Просмотр кэша';

  @override
  String get cacheSummarySubtitle =>
      'Очистка кэша не приведет к удалению загруженных музыкальных файлов.';

  @override
  String cacheEstimatedTotal(String size) {
    return 'Приблизительное использование кэша: $size';
  }

  @override
  String get cacheSectionStorage => 'Кэшированные данные';

  @override
  String get cacheSectionMaintenance => 'Обслуживание';

  @override
  String get cacheAppDirectory => 'Папка кэша приложения';

  @override
  String get cacheAppDirectoryDesc =>
      'HTTP-ответы, данные WebView и другие временные данные приложения.';

  @override
  String get cacheTempDirectory => 'Временная директория';

  @override
  String get cacheTempDirectoryDesc =>
      'Временные файлы из загрузок и аудио конвертации.';

  @override
  String get cacheCoverImage => 'Кэш обложек';

  @override
  String get cacheCoverImageDesc =>
      'Скачанный альбом и трек обложки. Будет заново скачан после просмотра.';

  @override
  String get cacheLibraryCover => 'Кэш обложек библиотеки';

  @override
  String get cacheLibraryCoverDesc =>
      'Обложка извлечена из локальных музыкальных файлов. Будет повторно извлечено при следующем сканировании.';

  @override
  String get cacheExploreFeed => 'Просмотреть кэш ленты';

  @override
  String get cacheExploreFeedDesc =>
      'Изучите содержимое вкладки (новые релизы, тренды). Они обновятся при следующем посещении.';

  @override
  String get cacheTrackLookup => 'Отслеживать кэш поиска';

  @override
  String get cacheTrackLookupDesc =>
      'Поиск ID трека в Spotify/Deezer. Очистка может замедлить следующие несколько поисков.';

  @override
  String get cacheCleanupUnusedDesc =>
      'Удалить записи из истории загрузок и библиотеки, которые остались без файлов.';

  @override
  String get cacheNoData => 'Нет кэшированных данных';

  @override
  String cacheSizeWithFiles(String size, int count) {
    return '$size в $count файлах';
  }

  @override
  String cacheSizeOnly(String size) {
    return '$size';
  }

  @override
  String cacheEntries(int count) {
    return '$count записей';
  }

  @override
  String cacheClearSuccess(String target) {
    return 'Очищено: $target';
  }

  @override
  String get cacheClearConfirmTitle => 'Очистить кэш?';

  @override
  String cacheClearConfirmMessage(String target) {
    return 'Это очистит кэш для $target. Загруженные музыкальные файлы не будут удалены.';
  }

  @override
  String get cacheClearAllConfirmTitle => 'Очистить весь кэш?';

  @override
  String get cacheClearAllConfirmMessage =>
      'Это очистит все категории кэша на этой странице. Скачанные музыкальные файлы не будут удалены.';

  @override
  String get cacheClearAll => 'Очистить весь кэш';

  @override
  String get cacheCleanupUnused => 'Очистка неиспользуемых данных';

  @override
  String get cacheCleanupUnusedSubtitle =>
      'Удалить историю загрузок, оставшихся без просмотра, и отсутствующие записи в библиотеке';

  @override
  String cacheCleanupResult(int downloadCount, int libraryCount) {
    return 'Очистка завершена: $downloadCount потерянных загрузок, $libraryCount отсутствующих записей в библиотеке';
  }

  @override
  String get cacheRefreshStats => 'Обновить статистику';

  @override
  String get trackSaveCoverArt => 'Сохранить обложку';

  @override
  String get trackSaveCoverArtSubtitle => 'Сохранить обложку как файл .jpg';

  @override
  String get trackSaveLyrics => 'Сохранить текст (.lrc)';

  @override
  String get trackSaveLyricsSubtitle =>
      'Получить и сохранить текст песни в формате .lrc';

  @override
  String get trackSaveLyricsProgress => 'Сохранение текста...';

  @override
  String get trackReEnrich => 'Обновить';

  @override
  String get trackReEnrichOnlineSubtitle =>
      'Поиск в сети метаданных и встраивание в файл';

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
  String get trackEditMetadata => 'Редактировать метаданные';

  @override
  String trackCoverSaved(String fileName) {
    return 'Обложка сохранена в $fileName';
  }

  @override
  String get trackCoverNoSource => 'Нет доступных источников обложки';

  @override
  String trackLyricsSaved(String fileName) {
    return 'Текст песни сохранен в $fileName';
  }

  @override
  String get trackReEnrichProgress => 'Обновление метаданных...';

  @override
  String get trackReEnrichSearching => 'Поиск метаданных в сети...';

  @override
  String get trackReEnrichSuccess => 'Метаданные успешно обновлены';

  @override
  String get trackReEnrichFfmpegFailed =>
      'Ошибка встраивания метаданных FFmpeg';

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
    return 'Ошибка: $error';
  }

  @override
  String get trackConvertFormat => 'Переконвертировать формат';

  @override
  String get trackConvertFormatSubtitle => 'Конвертировать в MP3 или Opus';

  @override
  String get trackConvertTitle => 'Конвертировать аудио';

  @override
  String get trackConvertTargetFormat => 'Целевой формат';

  @override
  String get trackConvertBitrate => 'Битрейт';

  @override
  String get trackConvertConfirmTitle => 'Подтвердить конвертацию';

  @override
  String trackConvertConfirmMessage(
    String sourceFormat,
    String targetFormat,
    String bitrate,
  ) {
    return 'Конвертировать из $sourceFormat в $targetFormat $bitrate?\n\nОригинальный файл будет удален после конвертации.';
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
  String get trackConvertConverting => 'Конвертация аудио...';

  @override
  String trackConvertSuccess(String format) {
    return 'Успешно конвертировано в $format';
  }

  @override
  String get trackConvertFailed => 'Ошибка конвертации';

  @override
  String get cueSplitTitle => 'Разделить CUE Sheet';

  @override
  String get cueSplitSubtitle => 'Разделить файл CUE+FLAC на отдельные треки';

  @override
  String cueSplitAlbum(String album) {
    return 'Альбом: $album';
  }

  @override
  String cueSplitArtist(String artist) {
    return 'Артист: $artist';
  }

  @override
  String cueSplitTrackCount(int count) {
    return '$count треков';
  }

  @override
  String get cueSplitConfirmTitle => 'Разделенный CUE-альбом';

  @override
  String cueSplitConfirmMessage(String album, int count) {
    return 'Разбить \"$album\" на $count отдельных FLAC-файлов?';
  }

  @override
  String cueSplitSplitting(int current, int total) {
    return 'Разделение CUE sheet... ($current/$total)';
  }

  @override
  String cueSplitSuccess(int count) {
    return 'Успешно разделено на $count треков';
  }

  @override
  String get cueSplitFailed => 'Разделение CUE не удалось';

  @override
  String get cueSplitNoAudioFile => 'Аудиофайл для этого CUE sheet не найден';

  @override
  String get cueSplitButton => 'Разделить на Треки';

  @override
  String get actionCreate => 'Создать';

  @override
  String get collectionFoldersTitle => 'Мои папки';

  @override
  String get collectionWishlist => 'Список желаемого';

  @override
  String get collectionLoved => 'Любимые';

  @override
  String get collectionPlaylists => 'Плейлисты';

  @override
  String get collectionPlaylist => 'Плейлист';

  @override
  String get collectionAddToPlaylist => 'Добавить в плейлист';

  @override
  String get collectionCreatePlaylist => 'Создать плейлист';

  @override
  String get collectionNoPlaylistsYet => 'Плейлисты отсутствуют';

  @override
  String get collectionNoPlaylistsSubtitle =>
      'Создайте плейлист, чтобы начать классифицировать треки';

  @override
  String collectionPlaylistTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count треков',
      many: '$count треков',
      few: '$count трека',
      one: '$count трек',
    );
    return '$_temp0';
  }

  @override
  String collectionAddedToPlaylist(String playlistName) {
    return 'Добавлено в \"$playlistName\"';
  }

  @override
  String collectionAlreadyInPlaylist(String playlistName) {
    return 'Уже в \"$playlistName\"';
  }

  @override
  String get collectionPlaylistCreated => 'Плейлист создан';

  @override
  String get collectionPlaylistNameHint => 'Название плейлиста';

  @override
  String get collectionPlaylistNameRequired => 'Имя плейлиста обязательно';

  @override
  String get collectionRenamePlaylist => 'Переименовать плейлист';

  @override
  String get collectionDeletePlaylist => 'Удалить плейлист';

  @override
  String collectionDeletePlaylistMessage(String playlistName) {
    return 'Удалить \"$playlistName\" и все треки внутри него?';
  }

  @override
  String get collectionPlaylistDeleted => 'Плейлист удалён';

  @override
  String get collectionPlaylistRenamed => 'Плейлист переименован';

  @override
  String get collectionWishlistEmptyTitle => 'Список желаний пуст';

  @override
  String get collectionWishlistEmptySubtitle =>
      'Нажмите + на треках, чтобы сохранить то, что вы хотите скачать позже';

  @override
  String get collectionLovedEmptyTitle => 'Папка Любимые пуста';

  @override
  String get collectionLovedEmptySubtitle =>
      'Нажмите \"любовь\" на треках, чтобы сохранить ваши избранные';

  @override
  String get collectionPlaylistEmptyTitle => 'Плейлист пуст';

  @override
  String get collectionPlaylistEmptySubtitle =>
      'Удерживайте + на любом треке, чтобы добавить его сюда';

  @override
  String get collectionRemoveFromPlaylist => 'Удалить из плейлиста';

  @override
  String get collectionRemoveFromFolder => 'Убрать из папки';

  @override
  String collectionRemoved(String trackName) {
    return '\"$trackName\" удалён';
  }

  @override
  String collectionAddedToLoved(String trackName) {
    return '\"$trackName\" добавлен в Любимые';
  }

  @override
  String collectionRemovedFromLoved(String trackName) {
    return '\"$trackName\" удалено из Любимых';
  }

  @override
  String collectionAddedToWishlist(String trackName) {
    return '\"$trackName\" добавлен в список желаний';
  }

  @override
  String collectionRemovedFromWishlist(String trackName) {
    return '\"$trackName\" удалён из списка желаний';
  }

  @override
  String get trackOptionAddToLoved => 'Добавить в Любимое';

  @override
  String get trackOptionRemoveFromLoved => 'Исключить из Любимых';

  @override
  String get trackOptionAddToWishlist => 'Добавить в список желаний';

  @override
  String get trackOptionRemoveFromWishlist => 'Удалить из списка желаний';

  @override
  String get collectionPlaylistChangeCover => 'Изменить обложку';

  @override
  String get collectionPlaylistRemoveCover => 'Удалить обложку';

  @override
  String selectionShareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'треков',
      many: 'треков',
      few: 'трека',
      one: 'трек',
    );
    return 'Отправить $count $_temp0';
  }

  @override
  String get selectionShareNoFiles =>
      'Файлы, доступные для совместного доступа, не найдены';

  @override
  String selectionConvertCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'треков',
      many: 'треков',
      few: 'трека',
      one: 'трек',
    );
    return 'Конвертировать $count $_temp0';
  }

  @override
  String get selectionConvertNoConvertible => 'Не выбраны конвертируемые треки';

  @override
  String get selectionBatchConvertConfirmTitle => 'Пакетная конвертация';

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
    return 'Преобразовать $count $_temp0 в $format с $bitrate?';
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
    return 'Конвертация $current из $total...';
  }

  @override
  String selectionBatchConvertSuccess(int success, int total, String format) {
    return 'Конвертировано $success треков $total в $format';
  }

  @override
  String downloadedAlbumDownloadedCount(int count) {
    return '$count скачано';
  }

  @override
  String get downloadUseAlbumArtistForFoldersAlbumSubtitle =>
      'Для папок исполнителей используется исполнитель альбома, если он указан';

  @override
  String get downloadUseAlbumArtistForFoldersTrackSubtitle =>
      'Папки исполнителя используют только трек исполнителя';

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
