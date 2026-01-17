import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';

/// Log entry with timestamp and level
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String tag;
  final String message;
  final String? error;
  final bool isFromGo; // Track if this log came from Go backend

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

/// Circular buffer for storing logs in memory
class LogBuffer extends ChangeNotifier {
  static final LogBuffer _instance = LogBuffer._internal();
  factory LogBuffer() => _instance;
  LogBuffer._internal();

  static const int maxEntries = 500;
  final Queue<LogEntry> _entries = Queue<LogEntry>();
  Timer? _goLogTimer;
  int _lastGoLogIndex = 0;
  
  /// Whether logging is enabled (controlled by settings)
  /// User must enable "Detailed Logging" in settings to capture logs
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
    // Skip adding if logging is disabled (except for errors which are always logged)
    if (!_loggingEnabled && entry.level != 'ERROR' && entry.level != 'FATAL') {
      return;
    }
    
    if (_entries.length >= maxEntries) {
      _entries.removeFirst();
    }
    _entries.add(entry);
    notifyListeners();
  }

  /// Start polling Go backend logs
  void startGoLogPolling() {
    _goLogTimer?.cancel();
    _goLogTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      await _fetchGoLogs();
    });
  }

  /// Stop polling Go backend logs
  void stopGoLogPolling() {
    _goLogTimer?.cancel();
    _goLogTimer = null;
  }

  /// Fetch logs from Go backend since last index
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
        
        // Parse timestamp (format: "15:04:05.000")
        DateTime parsedTime = DateTime.now();
        if (timestamp.isNotEmpty) {
          try {
            final parts = timestamp.split(':');
            if (parts.length >= 3) {
              final secParts = parts[2].split('.');
              parsedTime = DateTime(
                parsedTime.year, parsedTime.month, parsedTime.day,
                int.parse(parts[0]), int.parse(parts[1]),
                int.parse(secParts[0]),
                secParts.length > 1 ? int.parse(secParts[1]) : 0,
              );
            }
          } catch (_) {
          }
        }
        
        add(LogEntry(
          timestamp: parsedTime,
          level: level,
          tag: tag,
          message: message,
          isFromGo: true,
        ));
      }
      
      _lastGoLogIndex = nextIndex;
    } catch (e) {
      // Ignore errors - Go backend might not be ready
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

  List<LogEntry> filter({String? level, String? tag, String? search}) {
    return _entries.where((entry) {
      if (level != null && level != 'ALL' && entry.level != level) {
        return false;
      }
      if (tag != null && !entry.tag.toLowerCase().contains(tag.toLowerCase())) {
        return false;
      }
      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return entry.message.toLowerCase().contains(searchLower) ||
            entry.tag.toLowerCase().contains(searchLower) ||
            (entry.error?.toLowerCase().contains(searchLower) ?? false);
      }
      return true;
    }).toList();
  }
}

/// Custom log output that writes to both console and buffer
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
    
    LogBuffer().add(LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    ));
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

/// Global logger instance for the app
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

/// Logger with class/tag prefix for better traceability
/// Now also writes to LogBuffer for in-app viewing
/// Works in both debug and release mode
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
    LogBuffer().add(LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: _tag,
      message: message,
      error: error,
    ));
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
