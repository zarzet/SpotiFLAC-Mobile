import 'package:flutter/foundation.dart';

/// App version and info constants
/// Update version here only - all other files will reference this
class AppInfo {
  static const String version = '4.2.3';
  static const String buildNumber = '124';
  static const String fullVersion = '$version+$buildNumber';

  /// Shows "Internal" in debug builds, actual version in release.
  static String get displayVersion => kDebugMode ? 'Internal' : version;

  static const String appName = 'SpotiFLAC Mobile';
  static const String copyright = '© 2026 SpotiFLAC';

  static const String mobileAuthor = 'zarzet';
  static const String originalAuthor = 'afkarxyz';

  static const String githubRepo = 'zarzet/SpotiFLAC-Mobile';
  static const String githubUrl = 'https://github.com/$githubRepo';
  static const String originalGithubUrl =
      'https://github.com/afkarxyz/SpotiFLAC';

  static const String kofiUrl = 'https://ko-fi.com/zarzet';
  static const String githubSponsorsUrl = 'https://github.com/sponsors/zarzet/';
}
