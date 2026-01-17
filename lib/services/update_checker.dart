import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('UpdateChecker');

class UpdateInfo {
  final String version;
  final String changelog;
  final String downloadUrl;
  final String? apkDownloadUrl;
  final DateTime publishedAt;
  final bool isPrerelease;

  const UpdateInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    this.apkDownloadUrl,
    required this.publishedAt,
    this.isPrerelease = false,
  });
}

class UpdateChecker {
  static const String _latestApiUrl = 'https://api.github.com/repos/${AppInfo.githubRepo}/releases/latest';
  static const String _allReleasesApiUrl = 'https://api.github.com/repos/${AppInfo.githubRepo}/releases';

  static Future<String> _getDeviceArch() async {
    if (!Platform.isAndroid) return 'unknown';
    
    try {
      final cpuInfo = await File('/proc/cpuinfo').readAsString();
      
      if (cpuInfo.contains('AArch64') || cpuInfo.contains('aarch64')) {
        return 'arm64';
      }
      
      final result = await Process.run('uname', ['-m']);
      final arch = result.stdout.toString().trim().toLowerCase();
      
      if (arch.contains('aarch64') || arch.contains('arm64')) {
        return 'arm64';
      } else if (arch.contains('armv7') || arch.contains('arm')) {
        return 'arm32';
      } else if (arch.contains('x86_64')) {
        return 'x86_64';
      } else if (arch.contains('x86') || arch.contains('i686')) {
        return 'x86';
      }
      
      return 'arm64';
    } catch (e) {
      _log.e('Error detecting arch: $e');
      return 'arm64';
    }
  }

  /// Check for updates based on channel preference
  /// [channel] can be 'stable' or 'preview'
  static Future<UpdateInfo?> checkForUpdate({String channel = 'stable'}) async {
    try {
      Map<String, dynamic>? releaseData;
      
      if (channel == 'preview') {
        final response = await http.get(
          Uri.parse('$_allReleasesApiUrl?per_page=10'),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          _log.w('GitHub API returned ${response.statusCode}');
          return null;
        }

        final releases = jsonDecode(response.body) as List<dynamic>;
        if (releases.isEmpty) {
          _log.i('No releases found');
          return null;
        }
        
        releaseData = releases.first as Map<String, dynamic>;
      } else {
        final response = await http.get(
          Uri.parse(_latestApiUrl),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          _log.w('GitHub API returned ${response.statusCode}');
          return null;
        }

        releaseData = jsonDecode(response.body) as Map<String, dynamic>;
      }

      final tagName = releaseData['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceFirst('v', '');
      final isPrerelease = releaseData['prerelease'] as bool? ?? false;
      
      if (!_isNewerVersion(latestVersion, AppInfo.version)) {
        _log.i('No update available (current: ${AppInfo.version}, latest: $latestVersion, channel: $channel)');
        return null;
      }

      final body = releaseData['body'] as String? ?? 'No changelog available';
      final htmlUrl = releaseData['html_url'] as String? ?? '${AppInfo.githubUrl}/releases';
      final publishedAt = DateTime.tryParse(releaseData['published_at'] as String? ?? '') ?? DateTime.now();

      final deviceArch = await _getDeviceArch();
      _log.d('Device architecture: $deviceArch');
      
      String? arm64Url;
      String? arm32Url;
      String? universalUrl;
      
      final assets = releaseData['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          final downloadUrl = asset['browser_download_url'] as String?;
          final uri = downloadUrl != null ? Uri.tryParse(downloadUrl) : null;
          if (uri == null || uri.scheme != 'https') {
            _log.w('Skipping non-HTTPS APK URL: $downloadUrl');
            continue;
          }
          if (name.contains('arm64') || name.contains('v8a')) {
            arm64Url = downloadUrl;
          } else if (name.contains('arm32') || name.contains('v7a') || name.contains('armeabi')) {
            arm32Url = downloadUrl;
          } else if (name.contains('universal')) {
            universalUrl = downloadUrl;
          }
        }
      }
      
      String? apkUrl;
      if (deviceArch == 'arm64') {
        apkUrl = arm64Url ?? universalUrl ?? arm32Url;
      } else if (deviceArch == 'arm32') {
        apkUrl = arm32Url ?? universalUrl;
      } else {
        apkUrl = universalUrl ?? arm64Url ?? arm32Url;
      }

      _log.i('Update available: $latestVersion (prerelease: $isPrerelease), APK URL: $apkUrl');
      
      return UpdateInfo(
        version: latestVersion,
        changelog: body,
        downloadUrl: htmlUrl,
        apkDownloadUrl: apkUrl,
        publishedAt: publishedAt,
        isPrerelease: isPrerelease,
      );
    } catch (e) {
      _log.e('Error checking for updates: $e');
      return null;
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestBase = latest.split('-').first;
      final currentBase = current.split('-').first;
      
      final latestParts = latestBase.split('.').map(int.parse).toList();
      final currentParts = currentBase.split('.').map(int.parse).toList();

      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      
      final latestHasSuffix = latest.contains('-');
      final currentHasSuffix = current.contains('-');
      
      if (!latestHasSuffix && currentHasSuffix) return true;
      
      return false;
    } catch (e) {
      _log.e('Error comparing versions: $e');
      return false;
    }
  }

  static String get currentVersion => AppInfo.version;
}
