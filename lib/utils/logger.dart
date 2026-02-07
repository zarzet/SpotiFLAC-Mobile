import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String tag;
  final String message;
  final String? error;
  final bool isFromGo;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.isFromGo = false,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  String toString() {
    final errorPart = error != null ? ' | $error' : '';
    final goPart = isFromGo ? ' [Go]' : '';
    return '[$formattedTime] [$level]$goPart [$tag] $message$errorPart';
  }
}

class LogBuffer extends ChangeNotifier {
  static final LogBuffer _instance = LogBuffer._internal();
  factory LogBuffer() => _instance;
  LogBuffer._internal();

  static const int maxEntries = 500;
  static const Duration _goLogPollingInterval = Duration(milliseconds: 800);
  final Queue<LogEntry> _entries = Queue<LogEntry>();
  Timer? _goLogTimer;
  int _lastGoLogIndex = 0;

  static bool _loggingEnabled = false;
  static bool get loggingEnabled => _loggingEnabled;
  static set loggingEnabled(bool value) {
    _loggingEnabled = value;
    if (value) {
      PlatformBridge.setGoLoggingEnabled(true).catchError((_) {});
    } else {
      PlatformBridge.setGoLoggingEnabled(false).catchError((_) {});
    }
  }

  List<LogEntry> get entries => _entries.toList();
  int get length => _entries.length;

  void add(LogEntry entry) {
    if (!_loggingEnabled && entry.level != 'ERROR' && entry.level != 'FATAL') {
      return;
    }

    if (_entries.length >= maxEntries) {
      _entries.removeFirst();
    }
    _entries.add(entry);
    notifyListeners();
  }

  void startGoLogPolling() {
    _goLogTimer?.cancel();
    _goLogTimer = Timer.periodic(_goLogPollingInterval, (_) async {
      await _fetchGoLogs();
    });
  }

  void stopGoLogPolling() {
    _goLogTimer?.cancel();
    _goLogTimer = null;
  }

  Future<void> _fetchGoLogs() async {
    try {
      final result = await PlatformBridge.getGoLogsSince(_lastGoLogIndex);
      final logs = result['logs'] as List<dynamic>? ?? [];
      final nextIndex = result['next_index'] as int? ?? _lastGoLogIndex;

      for (final log in logs) {
        final timestamp = log['timestamp'] as String? ?? '';
        final level = log['level'] as String? ?? 'INFO';
        final tag = log['tag'] as String? ?? 'Go';
        final message = log['message'] as String? ?? '';

        DateTime parsedTime = DateTime.now();
        if (timestamp.isNotEmpty) {
          try {
            final parts = timestamp.split(':');
            if (parts.length >= 3) {
              final secParts = parts[2].split('.');
              parsedTime = DateTime(
                parsedTime.year,
                parsedTime.month,
                parsedTime.day,
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(secParts[0]),
                secParts.length > 1 ? int.parse(secParts[1]) : 0,
              );
            }
          } catch (_) {}
        }

        add(
          LogEntry(
            timestamp: parsedTime,
            level: level,
            tag: tag,
            message: message,
            isFromGo: true,
          ),
        );
      }

      _lastGoLogIndex = nextIndex;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to fetch Go logs: $e');
      }
    }
  }

  void clear() {
    _entries.clear();
    _lastGoLogIndex = 0;
    PlatformBridge.clearGoLogs().catchError((_) {});
    notifyListeners();
  }

  String export() {
    final buffer = StringBuffer();
    buffer.writeln('SpotiFLAC Log Export');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Entries: ${_entries.length}');
    buffer.writeln('=' * 60);
    buffer.writeln();
    for (final entry in _entries) {
      buffer.writeln(entry.toString());
    }
    return buffer.toString();
  }

  Future<String> exportWithDeviceInfo() async {
    final buffer = StringBuffer();

    buffer.writeln('=' * 60);
    buffer.writeln('SPOTIFLAC LOG EXPORT');
    buffer.writeln('=' * 60);
    buffer.writeln();

    buffer.writeln('--- App Information ---');
    buffer.writeln(
      'App Version: ${AppInfo.version} (Build ${AppInfo.buildNumber})',
    );
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    buffer.writeln('--- Device Information ---');
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        buffer.writeln('Platform: Android');
        buffer.writeln('Device: ${android.manufacturer} ${android.model}');
        buffer.writeln('Brand: ${android.brand}');
        buffer.writeln(
          'Android Version: ${android.version.release} (SDK ${android.version.sdkInt})',
        );
        buffer.writeln('Device ID: ${android.id}');
        buffer.writeln('Hardware: ${android.hardware}');
        buffer.writeln('Product: ${android.product}');
        buffer.writeln('Supported ABIs: ${android.supportedAbis.join(', ')}');
        buffer.writeln('Is Physical Device: ${android.isPhysicalDevice}');
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        buffer.writeln('Platform: iOS');
        buffer.writeln('Device: ${ios.utsname.machine}');
        buffer.writeln('Model: ${ios.model}');
        buffer.writeln('System Name: ${ios.systemName}');
        buffer.writeln('System Version: ${ios.systemVersion}');
        buffer.writeln('Device Name: ${ios.name}');
        buffer.writeln('Is Physical Device: ${ios.isPhysicalDevice}');
      }
    } catch (e) {
      buffer.writeln('Failed to get device info: $e');
    }
    buffer.writeln();

    buffer.writeln('--- Log Summary ---');
    buffer.writeln('Total Entries: ${_entries.length}');

    int errorCount = 0;
    int warnCount = 0;
    int infoCount = 0;
    int debugCount = 0;
    int goCount = 0;

    for (final entry in _entries) {
      switch (entry.level) {
        case 'ERROR':
        case 'FATAL':
          errorCount++;
          break;
        case 'WARN':
          warnCount++;
          break;
        case 'INFO':
          infoCount++;
          break;
        case 'DEBUG':
          debugCount++;
          break;
      }
      if (entry.isFromGo) goCount++;
    }

    buffer.writeln('Errors: $errorCount');
    buffer.writeln('Warnings: $warnCount');
    buffer.writeln('Info: $infoCount');
    buffer.writeln('Debug: $debugCount');
    buffer.writeln('From Go Backend: $goCount');
    buffer.writeln();

    buffer.writeln('=' * 60);
    buffer.writeln('LOG ENTRIES');
    buffer.writeln('=' * 60);
    buffer.writeln();

    for (final entry in _entries) {
      buffer.writeln(entry.toString());
    }

    return buffer.toString();
  }

  List<LogEntry> filter({String? level, String? tag, String? search}) {
    final tagLower = tag?.toLowerCase();
    final searchLower = search?.toLowerCase();

    return _entries.where((entry) {
      if (level != null && level != 'ALL' && entry.level != level) {
        return false;
      }
      if (tagLower != null && !entry.tag.toLowerCase().contains(tagLower)) {
        return false;
      }
      if (searchLower != null && searchLower.isNotEmpty) {
        return entry.message.toLowerCase().contains(searchLower) ||
            entry.tag.toLowerCase().contains(searchLower) ||
            (entry.error?.toLowerCase().contains(searchLower) ?? false);
      }
      return true;
    }).toList();
  }
}

class BufferedOutput extends LogOutput {
  final String tag;

  BufferedOutput(this.tag);

  @override
  void output(OutputEvent event) {
    if (kDebugMode) {
      for (final line in event.lines) {
        debugPrint(line);
      }
    }

    final level = _levelToString(event.level);
    final message = event.lines.join('\n');

    LogBuffer().add(
      LogEntry(
        timestamp: DateTime.now(),
        level: level,
        tag: tag,
        message: message,
      ),
    );
  }

  String _levelToString(Level level) {
    switch (level) {
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO';
      case Level.warning:
        return 'WARN';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      default:
        return 'LOG';
    }
  }
}

final log = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.none,
  ),
  level: Level.debug,
);

class AppLogger {
  final String _tag;
  late final Logger? _logger;

  AppLogger(this._tag) {
    if (kDebugMode) {
      _logger = Logger(
        printer: SimplePrinter(printTime: false, colors: false),
        output: BufferedOutput(_tag),
        level: Level.debug,
      );
    } else {
      _logger = null;
    }
  }

  void _addToBuffer(String level, String message, {String? error}) {
    LogBuffer().add(
      LogEntry(
        timestamp: DateTime.now(),
        level: level,
        tag: _tag,
        message: message,
        error: error,
      ),
    );
  }

  void d(String message) {
    if (kDebugMode) {
      _logger?.d(message);
    } else {
      _addToBuffer('DEBUG', message);
    }
  }

  void i(String message) {
    if (kDebugMode) {
      _logger?.i(message);
    } else {
      _addToBuffer('INFO', message);
    }
  }

  void w(String message) {
    if (kDebugMode) {
      _logger?.w(message);
    } else {
      _addToBuffer('WARN', message);
    }
  }

  void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (error != null) {
      _addToBuffer('ERROR', message, error: error.toString());
      if (kDebugMode) {
        debugPrint('[$_tag] ERROR: $message | $error');
        if (stackTrace != null) {
          debugPrint(stackTrace.toString());
        }
      }
    } else {
      if (kDebugMode) {
        _logger?.e(message);
      } else {
        _addToBuffer('ERROR', message);
      }
    }
  }
}
