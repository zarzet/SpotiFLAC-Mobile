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
  String get appDescription =>
      'Скачайте треки Spotify в Lossless качестве из Tidal, Qobuz и Amazon Music.';

  @override
  String get navHome => 'Главная';

  @override
  String get navLibrary => 'Library';

  @override
  String get navHistory => 'История';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navStore => 'Магазин';

  @override
  String get homeTitle => 'Главная';

  @override
  String get homeSearchHint => 'Вставьте URL Spotify или выполните поиск...';

  @override
  String homeSearchHintExtension(String extensionName) {
    return 'Искать с помощью $extensionName...';
  }

  @override
  String get homeSubtitle => 'Вставьте ссылку Spotify или ищите по названию';

  @override
  String get homeSupports =>
      'Поддерживается: Трек, Альбом, Плейлист, URL исполнителя';

  @override
  String get homeRecent => 'Недавние';

  @override
  String get historyTitle => 'История';

  @override
  String historyDownloading(int count) {
    return 'Скачивание ($count)';
  }

  @override
  String get historyDownloaded => 'Скачано';

  @override
  String get historyFilterAll => 'Все';

  @override
  String get historyFilterAlbums => 'Альбомы';

  @override
  String get historyFilterSingles => 'Синглы';

  @override
  String historyTracksCount(int count) {
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
  String historyAlbumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count альбомов',
      many: '$count альбомов',
      few: '$count альбома',
      one: '$count альбом',
    );
    return '$_temp0';
  }

  @override
  String get historyNoDownloads => 'Нет истории скачиваний';

  @override
  String get historyNoDownloadsSubtitle => 'Скачанные треки появятся здесь';

  @override
  String get historyNoAlbums => 'Нет скачанных альбомов';

  @override
  String get historyNoAlbumsSubtitle =>
      'Скачайте несколько треков из альбома, чтобы увидеть их здесь';

  @override
  String get historyNoSingles => 'Нет скачанных синглов';

  @override
  String get historyNoSinglesSubtitle =>
      'Здесь будут отображаться загрузки синглов';

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
  String get downloadTitle => 'Скачивание';

  @override
  String get downloadLocation => 'Папка для скачивания';

  @override
  String get downloadLocationSubtitle => 'Выберите, куда сохранить файлы';

  @override
  String get downloadLocationDefault => 'Расположение по умолчанию';

  @override
  String get downloadDefaultService => 'Сервис по умолчанию';

  @override
  String get downloadDefaultServiceSubtitle =>
      'Сервис, используемый для скачивания';

  @override
  String get downloadDefaultQuality => 'Качество по умолчанию';

  @override
  String get downloadAskQuality => 'Спрашивать качество перед скачиванием';

  @override
  String get downloadAskQualitySubtitle =>
      'Показывать выбор качества для каждого скачивания';

  @override
  String get downloadFilenameFormat => 'Формат имени файла';

  @override
  String get downloadFolderOrganization => 'Организация папок';

  @override
  String get downloadSeparateSingles => 'Разделять синглы';

  @override
  String get downloadSeparateSinglesSubtitle =>
      'Помещать синглы в отдельную папку';

  @override
  String get qualityBest => 'Лучшее из доступных';

  @override
  String get qualityFlac => 'FLAC';

  @override
  String get quality320 => '320 кбит/с';

  @override
  String get quality128 => '128 кбит/с';

  @override
  String get appearanceTitle => 'Внешний вид';

  @override
  String get appearanceTheme => 'Тема';

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
  String get appearanceAccentColor => 'Акцентный цвет';

  @override
  String get appearanceHistoryView => 'Отображение истории';

  @override
  String get appearanceHistoryViewList => 'Список';

  @override
  String get appearanceHistoryViewGrid => 'Сетка';

  @override
  String get optionsTitle => 'Опции';

  @override
  String get optionsSearchSource => 'Поиск источника';

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
  String get optionsEmbedLyrics => 'Вставить текст песни';

  @override
  String get optionsEmbedLyricsSubtitle =>
      'Вставить синхронизированные тексты в FLAC файлы';

  @override
  String get optionsMaxQualityCover => 'Максимальное качество обложки';

  @override
  String get optionsMaxQualityCoverSubtitle =>
      'Скачивать обложку в макс. разрешении';

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
      'Spotify search will be deprecated on March 3, 2026 due to Spotify API changes. Please switch to Deezer.';

  @override
  String get extensionsTitle => 'Расширения';

  @override
  String get extensionsInstalled => 'Установленные расширения';

  @override
  String get extensionsNone => 'Нет установленных расширений';

  @override
  String get extensionsNoneSubtitle =>
      'Установка расширений из вкладки Магазин';

  @override
  String get extensionsEnabled => 'Включено';

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
  String get extensionsSetAsSearch => 'Установить в качестве поисковой системы';

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
  String get aboutSupport => 'Поддержка';

  @override
  String get aboutApp => 'Приложение';

  @override
  String get aboutVersion => 'Версия';

  @override
  String get aboutBinimumDesc =>
      'Создатель QQDL & HiFi API. Без этого API загрузки Tidal не существовали бы!';

  @override
  String get aboutSachinsenalDesc =>
      'Оригинальный создатель проекта HiFi. Основатель Tidal интеграции!';

  @override
  String get aboutSjdonadoDesc =>
      'Creator of I Don\'t Have Spotify (IDHS). The fallback link resolver that saves the day!';

  @override
  String get aboutDoubleDouble => 'DoubleDouble';

  @override
  String get aboutDoubleDoubleDesc =>
      'Удивительный API для загрузок Amazon Music. Спасибо за то, что сделали это бесплатно!';

  @override
  String get aboutDabMusic => 'DAB Music';

  @override
  String get aboutDabMusicDesc =>
      'Лучший API для стриминга Qobuz. Без него загрузка файлов в высоком разрешении была бы невозможна!';

  @override
  String get aboutSpotiSaver => 'SpotiSaver';

  @override
  String get aboutSpotiSaverDesc =>
      'Tidal Hi-Res FLAC streaming endpoints. A key piece of the lossless puzzle!';

  @override
  String get aboutAppDescription =>
      'Скачайте треки Spotify в Lossless качестве из Tidal, Qobuz и Amazon Music.';

  @override
  String get albumTitle => 'Альбом';

  @override
  String albumTracks(int count) {
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
  String get albumDownloadAll => 'Скачать всё';

  @override
  String get albumDownloadRemaining => 'Скачать оставшиеся';

  @override
  String get playlistTitle => 'Плейлист';

  @override
  String get artistTitle => 'Исполнитель';

  @override
  String get artistAlbums => 'Альбомы';

  @override
  String get artistSingles => 'Синглы и EP';

  @override
  String get artistCompilations => 'Сборники';

  @override
  String artistReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count релизов',
      many: '$count релизов',
      few: '$count релиза',
      one: '$count релиз',
    );
    return '$_temp0';
  }

  @override
  String get artistPopular => 'Популярное';

  @override
  String artistMonthlyListeners(String count) {
    return '$count слушателей в месяц';
  }

  @override
  String get trackMetadataTitle => 'Информация о треке';

  @override
  String get trackMetadataArtist => 'Исполнитель';

  @override
  String get trackMetadataAlbum => 'Альбом';

  @override
  String get trackMetadataDuration => 'Продолжительность';

  @override
  String get trackMetadataQuality => 'Качество';

  @override
  String get trackMetadataPath => 'Путь к файлу';

  @override
  String get trackMetadataDownloadedAt => 'Скачано';

  @override
  String get trackMetadataService => 'Сервис';

  @override
  String get trackMetadataPlay => 'Воспроизвести';

  @override
  String get trackMetadataShare => 'Поделиться';

  @override
  String get trackMetadataDelete => 'Удалить';

  @override
  String get trackMetadataRedownload => 'Скачать снова';

  @override
  String get trackMetadataOpenFolder => 'Открыть папку';

  @override
  String get setupTitle => 'Добро пожаловать в SpotiFLAC';

  @override
  String get setupSubtitle => 'Давайте начнем';

  @override
  String get setupStoragePermission => 'Доступ к хранилищу';

  @override
  String get setupStoragePermissionSubtitle =>
      'Необходимо для сохранения загруженных файлов';

  @override
  String get setupStoragePermissionGranted => 'Разрешение предоставлено';

  @override
  String get setupStoragePermissionDenied => 'Разрешение не предоставлено';

  @override
  String get setupGrantPermission => 'Предоставить разрешение';

  @override
  String get setupDownloadLocation => 'Папка для скачивания';

  @override
  String get setupChooseFolder => 'Выбрать папку';

  @override
  String get setupContinue => 'Продолжить';

  @override
  String get setupSkip => 'Пропустить';

  @override
  String get setupStorageAccessRequired => 'Требуется доступ к хранилищу';

  @override
  String get setupStorageAccessMessage =>
      'SpotiFLAC требуется разрешение \"Доступ ко всем файлам\" для сохранения музыкальных файлов в выбранную папку.';

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
  String get setupSelectDownloadFolder => 'Выбрать папку для скачивания';

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
      'iCloud Drive is not supported. Please use the app Documents folder.';

  @override
  String get setupDownloadInFlac => 'Скачать Spotify треки во FLAC';

  @override
  String get setupStepStorage => 'Хранилище';

  @override
  String get setupStepNotification => 'Уведомления';

  @override
  String get setupStepFolder => 'Папка';

  @override
  String get setupStepSpotify => 'Spotify';

  @override
  String get setupStepPermission => 'Разрешение';

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
  String get setupNotificationDescription =>
      'Получайте уведомления о завершении загрузки или о необходимости привлечения внимания.';

  @override
  String get setupFolderSelected => 'Папка для загрузки выбрана!';

  @override
  String get setupFolderChoose => 'Выбрать папку для скачивания';

  @override
  String get setupFolderDescription =>
      'Выберите папку, в которой будет сохраняться скачанная музыка.';

  @override
  String get setupChangeFolder => 'Сменить папку';

  @override
  String get setupSelectFolder => 'Выбрать папку';

  @override
  String get setupSpotifyApiOptional => 'Spotify API (необязательно)';

  @override
  String get setupSpotifyApiDescription =>
      'Добавьте свои учётные данные Spotify для улучшения результатов поиска и доступа к эксклюзивному контенту Spotify.';

  @override
  String get setupUseSpotifyApi => 'Использовать Spotify API';

  @override
  String get setupEnterCredentialsBelow => 'Введите ваши учётные данные ниже';

  @override
  String get setupUsingDeezer => 'Использование Deezer (аккаунт не требуется)';

  @override
  String get setupEnterClientId => 'Введите Client ID Spotify';

  @override
  String get setupEnterClientSecret => 'Введите Spotify Client Secret';

  @override
  String get setupGetFreeCredentials =>
      'Получите бесплатный API учётной записи на панели разработчика Spotify.';

  @override
  String get setupEnableNotifications => 'Включить уведомления';

  @override
  String get setupProceedToNextStep =>
      'Теперь вы можете перейти к следующему шагу.';

  @override
  String get setupNotificationProgressDescription =>
      'Вы будете получать уведомления о ходе загрузки.';

  @override
  String get setupNotificationBackgroundDescription =>
      'Получайте уведомления о ходе и завершении загрузки. Это поможет вам отслеживать загрузки, когда приложение находится в фоновом режиме.';

  @override
  String get setupSkipForNow => 'Пропустить';

  @override
  String get setupBack => 'Назад';

  @override
  String get setupNext => 'Далее';

  @override
  String get setupGetStarted => 'Приступить к работе';

  @override
  String get setupSkipAndStart => 'Пропустить и начать';

  @override
  String get setupAllowAccessToManageFiles =>
      'Пожалуйста, включите \"Разрешить доступ для управления всеми файлами\" на следующем экране.';

  @override
  String get setupGetCredentialsFromSpotify =>
      'Получить учётные данные с developer.spotify.com';

  @override
  String get dialogCancel => 'Отмена';

  @override
  String get dialogOk => 'ОК';

  @override
  String get dialogSave => 'Сохранить';

  @override
  String get dialogDelete => 'Удалить';

  @override
  String get dialogRetry => 'Повторить';

  @override
  String get dialogClose => 'Закрыть';

  @override
  String get dialogYes => 'Да';

  @override
  String get dialogNo => 'Нет';

  @override
  String get dialogClear => 'Очистить';

  @override
  String get dialogConfirm => 'Подтвердить';

  @override
  String get dialogDone => 'Готово';

  @override
  String get dialogImport => 'Импорт';

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
  String get dialogDownloadFailed => 'Ошибка скачивания';

  @override
  String get dialogTrackLabel => 'Трек:';

  @override
  String get dialogArtistLabel => 'Исполнитель:';

  @override
  String get dialogErrorLabel => 'Ошибка:';

  @override
  String get dialogClearAll => 'Очистить всё';

  @override
  String get dialogClearAllDownloads =>
      'Вы уверены, что хотите очистить все загрузки?';

  @override
  String get dialogRemoveFromDevice => 'Удалить с устройства?';

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
    return '$count треков из CSV';
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
    return '\"$trackName\" already exists in your library';
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
  String snackbarFailedToLoad(String error) {
    return 'Ошибка загрузки: $error';
  }

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
  String errorFailedToLoad(String item) {
    return 'Ошибка загрузки $item';
  }

  @override
  String get errorNoTracksFound => 'Треки не найдены';

  @override
  String errorMissingExtensionSource(String item) {
    return 'Невозможно загрузить $item: отсутствует источник расширения';
  }

  @override
  String get statusQueued => 'В очереди';

  @override
  String get statusDownloading => 'Скачивание';

  @override
  String get statusFinalizing => 'Завершение';

  @override
  String get statusCompleted => 'Завершено';

  @override
  String get statusFailed => 'Неудачно';

  @override
  String get statusSkipped => 'Пропущено';

  @override
  String get statusPaused => 'Приостановлено';

  @override
  String get actionPause => 'Пауза';

  @override
  String get actionResume => 'Возобновить';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionStop => 'Стоп';

  @override
  String get actionSelect => 'Выбрать';

  @override
  String get actionSelectAll => 'Выбрать все';

  @override
  String get actionDeselect => 'Снять выделение';

  @override
  String get actionPaste => 'Вставить';

  @override
  String get actionImportCsv => 'Импорт CSV';

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
  String get selectionTapToSelect => 'Нажмите на треки для выбора';

  @override
  String selectionDeleteTracks(int count) {
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
  String get tooltipPlay => 'Воспроизвести';

  @override
  String get tooltipCancel => 'Отмена';

  @override
  String get tooltipStop => 'Стоп';

  @override
  String get tooltipRetry => 'Повторить';

  @override
  String get tooltipRemove => 'Убрать';

  @override
  String get tooltipClear => 'Очистить';

  @override
  String get tooltipPaste => 'Вставить';

  @override
  String get filenameFormat => 'Формат имени файла';

  @override
  String filenameFormatPreview(String preview) {
    return 'Предпросмотр: $preview';
  }

  @override
  String get filenameAvailablePlaceholders => 'Доступные заполнители:';

  @override
  String filenameHint(Object artist, Object title) {
    return '$artist - $title';
  }

  @override
  String get folderOrganization => 'Организация папок';

  @override
  String get folderOrganizationNone => 'Без организации';

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
  String updateNewVersion(String version) {
    return 'Версия $version доступна';
  }

  @override
  String get updateDownload => 'Скачать';

  @override
  String get updateLater => 'Позже';

  @override
  String get updateChangelog => 'Список изменений';

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
  String get providerPriority => 'Приоритет провайдера';

  @override
  String get providerPrioritySubtitle => 'Перетащите для изменения порядка';

  @override
  String get providerPriorityTitle => 'Приоритет провайдера';

  @override
  String get providerPriorityDescription =>
      'Перетаскивайте, чтобы изменить порядок провайдеров загрузки. Приложение будет пробовать провайдеров сверху вниз при загрузке треков.';

  @override
  String get providerPriorityInfo =>
      'Если трек не доступен у первого провайдера, приложение автоматически попробует следующий.';

  @override
  String get providerBuiltIn => 'Встроенные';

  @override
  String get providerExtension => 'Расширение';

  @override
  String get metadataProviderPriority => 'Приоритет провайдера метаданных';

  @override
  String get metadataProviderPrioritySubtitle =>
      'Порядок, используемый при получении метаданных';

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
  String get logCopy => 'Скопировать логи';

  @override
  String get logClear => 'Очистить логи';

  @override
  String get logShare => 'Поделиться логами';

  @override
  String get logEmpty => 'Логов нет';

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
  String get logIspBlocking => 'ОБНАРУЖЕНА БЛОКИРОВКА ИНТЕРНЕТ ПРОВАЙДЕРОМ';

  @override
  String get logRateLimited => 'ОГРАНИЧЕННАЯ СКОРОСТЬ';

  @override
  String get logNetworkError => 'ОШИБКА СЕТИ';

  @override
  String get logTrackNotFound => 'ТРЕК НЕ НАЙДЕН';

  @override
  String get logFilterBySeverity => 'Фильтровать логи по серьезности';

  @override
  String get logNoLogsYet => 'Логов нет';

  @override
  String get logNoLogsYetSubtitle =>
      'Логи появятся здесь по мере использования приложения';

  @override
  String get logIssueSummary => 'Краткое описание проблемы';

  @override
  String get logIspBlockingDescription =>
      'Ваш провайдер может блокировать доступ к сервисам скачивания';

  @override
  String get logIspBlockingSuggestion =>
      'Попробуйте использовать VPN или измените DNS на 1.1.1.1 или 8.8.8.8';

  @override
  String get logRateLimitedDescription => 'Слишком много запросов к сервису';

  @override
  String get logRateLimitedSuggestion =>
      'Подождите несколько минут, прежде чем повторить попытку';

  @override
  String get logNetworkErrorDescription => 'Обнаружены проблемы с подключением';

  @override
  String get logNetworkErrorSuggestion => 'Проверьте подключение к Интернету';

  @override
  String get logTrackNotFoundDescription =>
      'Некоторые треки не найдены в сервисах загрузки';

  @override
  String get logTrackNotFoundSuggestion =>
      'Трек может быть недоступен в lossless формате';

  @override
  String logTotalErrors(int count) {
    return 'Всего ошибок: $count';
  }

  @override
  String logAffected(String domains) {
    return 'Затронуто: $domains';
  }

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
  String get lyricsModeEmbed => 'Вставить в файл';

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
  String get lyricsModeBothSubtitle => 'Вставить и сохранить файл .lrc';

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
  String get appearanceLanguageSubtitle => 'Выберите предпочитаемый язык';

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
  String get tracksHeader => 'Треки';

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
  String get trackLyricsTimeout =>
      'Время ожидания запроса истекло. Повторите попытку позже.';

  @override
  String get trackLyricsLoadFailed => 'Не удалось загрузить текст песни';

  @override
  String get trackEmbedLyrics => 'Вставить текст песни';

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
  String trackCannotOpen(String message) {
    return 'Невозможно открыть: $message';
  }

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
  String get concurrentSequential => 'Последовательно';

  @override
  String get concurrentParallel2 => '2 параллельно';

  @override
  String get concurrentParallel3 => '3 параллельно';

  @override
  String get tapToSeeError => 'Нажмите, чтобы увидеть подробности ошибки';

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
  String get storeNoResults => 'Расширения не найдены';

  @override
  String get extensionProviderPriority => 'Приоритет провайдера';

  @override
  String get extensionInstallButton => 'Установить расширение';

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
      'Фактическое качество зависит от доступности треков в сервисе';

  @override
  String get youtubeQualityNote =>
      'YouTube provides lossy audio only. Not part of lossless fallback.';

  @override
  String get downloadAskBeforeDownload => 'Спрашивать перед скачиванием';

  @override
  String get downloadDirectory => 'Папка для скачивания';

  @override
  String get downloadSeparateSinglesFolder => 'Отдельная папка для синглов';

  @override
  String get downloadAlbumFolderStructure => 'Структура папок альбома';

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
  String get downloadSaveFormat => 'Формат сохранения';

  @override
  String get downloadSelectService => 'Выбор сервиса';

  @override
  String get downloadSelectQuality => 'Выбор качества';

  @override
  String get downloadFrom => 'Скачивать из';

  @override
  String get downloadDefaultQualityLabel => 'Качество по умолчанию';

  @override
  String get downloadBestAvailable => 'Лучшее из доступных';

  @override
  String get folderNone => 'Отсутствует';

  @override
  String get folderNoneSubtitle =>
      'Сохранить все файлы непосредственно в папку загрузки';

  @override
  String get folderArtist => 'Исполнитель';

  @override
  String get folderArtistSubtitle => 'Исполнитель/имя файла';

  @override
  String get folderAlbum => 'Альбом';

  @override
  String get folderAlbumSubtitle => 'Альбом/имя файла';

  @override
  String get folderArtistAlbum => 'Исполнитель/Альбом';

  @override
  String get folderArtistAlbumSubtitle => 'Исполнитель/ Альбом/имя файла';

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
  String get appearanceAmoledDark => 'AMOLED';

  @override
  String get appearanceAmoledDarkSubtitle => 'Глубокий чёрный фон';

  @override
  String get appearanceChooseAccentColor => 'Выберите акцентный цвет';

  @override
  String get appearanceChooseTheme => 'Режим темы';

  @override
  String get queueTitle => 'Очередь скачиваний';

  @override
  String get queueClearAll => 'Очистить всё';

  @override
  String get queueClearAllMessage =>
      'Вы уверены, что хотите очистить все загрузки?';

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
  String get queueEmpty => 'Нет загрузок в очереди';

  @override
  String get queueEmptySubtitle => 'Добавить треки с главного экрана';

  @override
  String get queueClearCompleted => 'Очистка завершена';

  @override
  String get queueDownloadFailed => 'Ошибка скачивания';

  @override
  String get queueTrackLabel => 'Трек:';

  @override
  String get queueArtistLabel => 'Исполнитель:';

  @override
  String get queueErrorLabel => 'Ошибка:';

  @override
  String get queueUnknownError => 'Неизвестная ошибка';

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
  String get downloadedAlbumTracksHeader => 'Треки';

  @override
  String downloadedAlbumDownloadedCount(int count) {
    return '$count скачано';
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
  String get utilityFunctions => 'Функции утилиты';

  @override
  String get recentTypeArtist => 'Исполнитель';

  @override
  String get recentTypeAlbum => 'Альбом';

  @override
  String get recentTypeSong => 'Песня';

  @override
  String get recentTypePlaylist => 'Плейлист';

  @override
  String get recentEmpty => 'No recent items yet';

  @override
  String get recentShowAllDownloads => 'Show All Downloads';

  @override
  String recentPlaylistInfo(String name) {
    return 'Плейлист: $name';
  }

  @override
  String errorGeneric(String message) {
    return 'Ошибка: $message';
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
}
