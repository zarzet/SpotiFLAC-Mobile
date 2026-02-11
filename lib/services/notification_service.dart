import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _notificationPermissionRequested = false;

  static const int downloadProgressId = 1;
  static const int updateDownloadId = 2;
  static const int libraryScanId = 3;
  static const String channelId = 'download_progress';
  static const String channelName = 'Download Progress';
  static const String channelDescription = 'Shows download progress for tracks';
  static const String libraryChannelId = 'library_scan';
  static const String libraryChannelName = 'Library Scan';
  static const String libraryChannelDescription =
      'Shows local library scan progress';

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: initSettings);

    if (Platform.isAndroid) {
      final androidImpl = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.low,
          showBadge: false,
          playSound: false,
          enableVibration: false,
        ),
      );
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          libraryChannelId,
          libraryChannelName,
          description: libraryChannelDescription,
          importance: Importance.low,
          showBadge: false,
          playSound: false,
          enableVibration: false,
        ),
      );
    }

    _isInitialized = true;
  }

  Future<bool> _ensureNotificationPermission() async {
    if (!Platform.isIOS) return true;

    final status = await Permission.notification.status;
    if (status.isGranted || status.isProvisional) return true;

    if (_notificationPermissionRequested ||
        status.isPermanentlyDenied ||
        status.isRestricted) {
      return false;
    }

    _notificationPermissionRequested = true;
    final requested = await Permission.notification.request();
    return requested.isGranted || requested.isProvisional;
  }

  Future<void> _showSafely({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    if (!await _ensureNotificationPermission()) return;

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } on PlatformException catch (e) {
      final isNotificationsNotAllowed =
          Platform.isIOS &&
          (e.code == 'Error 1' ||
              (e.message?.contains('UNErrorDomain error 1') ?? false) ||
              e.toString().contains('UNErrorDomain error 1'));

      if (isNotificationsNotAllowed) {
        debugPrint(
          'iOS notifications not allowed; skipping local notification',
        );
        return;
      }
      rethrow;
    }
  }

  Future<void> showDownloadProgress({
    required String trackName,
    required String artistName,
    required int progress,
    required int total,
  }) async {
    if (!_isInitialized) await initialize();

    final percentage = total > 0 ? (progress * 100 ~/ total) : 0;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: percentage,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: downloadProgressId,
      title: 'Downloading $trackName',
      body: '$artistName • $percentage%',
      details: details,
    );
  }

  Future<void> showDownloadFinalizing({
    required String trackName,
    required String artistName,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: 100,
      indeterminate: false,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: downloadProgressId,
      title: 'Finalizing $trackName',
      body: '$artistName • Embedding metadata...',
      details: details,
    );
  }

  Future<void> showDownloadComplete({
    required String trackName,
    required String artistName,
    int? completedCount,
    int? totalCount,
    bool alreadyInLibrary = false,
  }) async {
    if (!_isInitialized) await initialize();

    String title;
    if (alreadyInLibrary) {
      title = completedCount != null && totalCount != null
          ? 'Already in Library ($completedCount/$totalCount)'
          : 'Already in Library';
    } else {
      title = completedCount != null && totalCount != null
          ? 'Download Complete ($completedCount/$totalCount)'
          : 'Download Complete';
    }

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      playSound: false,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: downloadProgressId,
      title: title,
      body: '$trackName - $artistName',
      details: details,
    );
  }

  Future<void> showQueueComplete({
    required int completedCount,
    required int failedCount,
  }) async {
    if (!_isInitialized) await initialize();

    final title = failedCount > 0
        ? 'Downloads Finished ($completedCount done, $failedCount failed)'
        : 'All Downloads Complete';

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: downloadProgressId,
      title: title,
      body: '$completedCount tracks downloaded successfully',
      details: details,
    );
  }

  Future<void> cancelDownloadNotification() async {
    await _notifications.cancel(id: downloadProgressId);
  }

  Future<void> showLibraryScanProgress({
    required double progress,
    required int scannedFiles,
    required int totalFiles,
    String? currentFile,
  }) async {
    if (!_isInitialized) await initialize();

    final clampedProgress = progress.clamp(0.0, 100.0);
    final percentage = clampedProgress.round();
    final progressBody = totalFiles > 0
        ? '$scannedFiles/$totalFiles files • $percentage%'
        : '$scannedFiles files scanned • $percentage%';
    final body = (currentFile != null && currentFile.isNotEmpty)
        ? '$progressBody\n$currentFile'
        : progressBody;

    final androidDetails = AndroidNotificationDetails(
      libraryChannelId,
      libraryChannelName,
      channelDescription: libraryChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: percentage,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: libraryScanId,
      title: 'Scanning local library',
      body: body,
      details: details,
    );
  }

  Future<void> showLibraryScanComplete({
    required int totalTracks,
    int excludedDownloadedCount = 0,
    int errorCount = 0,
  }) async {
    if (!_isInitialized) await initialize();

    final extras = <String>[];
    if (excludedDownloadedCount > 0) {
      extras.add('$excludedDownloadedCount excluded');
    }
    if (errorCount > 0) {
      extras.add('$errorCount errors');
    }
    final suffix = extras.isEmpty ? '' : ' (${extras.join(', ')})';

    const androidDetails = AndroidNotificationDetails(
      libraryChannelId,
      libraryChannelName,
      channelDescription: libraryChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      playSound: false,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: libraryScanId,
      title: 'Library scan complete',
      body: '$totalTracks tracks indexed$suffix',
      details: details,
    );
  }

  Future<void> showLibraryScanFailed(String message) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      libraryChannelId,
      libraryChannelName,
      channelDescription: libraryChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      playSound: false,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: libraryScanId,
      title: 'Library scan failed',
      body: message,
      details: details,
    );
  }

  Future<void> showLibraryScanCancelled() async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      libraryChannelId,
      libraryChannelName,
      channelDescription: libraryChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      playSound: false,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: libraryScanId,
      title: 'Library scan cancelled',
      body: 'Scan stopped before completion.',
      details: details,
    );
  }

  Future<void> cancelLibraryScanNotification() async {
    await _notifications.cancel(id: libraryScanId);
  }

  Future<void> showUpdateDownloadProgress({
    required String version,
    required int received,
    required int total,
  }) async {
    if (!_isInitialized) await initialize();

    final percentage = total > 0 ? (received * 100 ~/ total) : 0;
    final receivedMB = (received / 1024 / 1024).toStringAsFixed(1);
    final totalMB = (total / 1024 / 1024).toStringAsFixed(1);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: percentage,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: updateDownloadId,
      title: 'Downloading SpotiFLAC v$version',
      body: '$receivedMB / $totalMB MB • $percentage%',
      details: details,
    );
  }

  Future<void> showUpdateDownloadComplete({required String version}) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: updateDownloadId,
      title: 'Update Ready',
      body: 'SpotiFLAC v$version downloaded. Tap to install.',
      details: details,
    );
  }

  Future<void> showUpdateDownloadFailed() async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _showSafely(
      id: updateDownloadId,
      title: 'Update Failed',
      body: 'Could not download update. Try again later.',
      details: details,
    );
  }

  Future<void> cancelUpdateNotification() async {
    await _notifications.cancel(id: updateDownloadId);
  }
}
