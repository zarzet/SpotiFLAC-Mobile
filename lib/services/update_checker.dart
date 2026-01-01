import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spotiflac_android/constants/app_info.dart';

class UpdateInfo {
  final String version;
  final String changelog;
  final String downloadUrl;
  final DateTime publishedAt;

  const UpdateInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    required this.publishedAt,
  });
}

class UpdateChecker {
  static const String _apiUrl = 'https://api.github.com/repos/${AppInfo.githubRepo}/releases/latest';

  /// Check for updates from GitHub releases
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('[UpdateChecker] GitHub API returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceFirst('v', '');
      
      if (!_isNewerVersion(latestVersion, AppInfo.version)) {
        print('[UpdateChecker] No update available (current: ${AppInfo.version}, latest: $latestVersion)');
        return null;
      }

      // Get changelog from release body
      final body = data['body'] as String? ?? 'No changelog available';
      final htmlUrl = data['html_url'] as String? ?? '${AppInfo.githubUrl}/releases';
      final publishedAt = DateTime.tryParse(data['published_at'] as String? ?? '') ?? DateTime.now();

      print('[UpdateChecker] Update available: $latestVersion');
      
      return UpdateInfo(
        version: latestVersion,
        changelog: body,
        downloadUrl: htmlUrl,
        publishedAt: publishedAt,
      );
    } catch (e) {
      print('[UpdateChecker] Error checking for updates: $e');
      return null;
    }
  }

  /// Compare version strings (e.g., "1.1.1" vs "1.1.0")
  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      // Pad with zeros if needed
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
      return false; // Same version
    } catch (e) {
      return false;
    }
  }

  static String get currentVersion => AppInfo.version;
}
