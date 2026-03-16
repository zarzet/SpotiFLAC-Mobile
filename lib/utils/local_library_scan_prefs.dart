import 'package:shared_preferences/shared_preferences.dart';

const localLibraryLastScannedAtKey = 'local_library_last_scanned_at';

DateTime? readLocalLibraryLastScannedAt(SharedPreferences prefs) {
  final lastScannedAtStr = prefs.getString(localLibraryLastScannedAtKey);
  if (lastScannedAtStr != null && lastScannedAtStr.isNotEmpty) {
    return DateTime.tryParse(lastScannedAtStr);
  }

  // Backward compatibility for older builds that may have stored epoch millis.
  final lastScannedAtMs = prefs.getInt(localLibraryLastScannedAtKey);
  if (lastScannedAtMs != null) {
    return DateTime.fromMillisecondsSinceEpoch(lastScannedAtMs);
  }

  return null;
}

Future<void> writeLocalLibraryLastScannedAt(
  SharedPreferences prefs,
  DateTime value,
) {
  return prefs.setString(localLibraryLastScannedAtKey, value.toIso8601String());
}

Future<void> clearLocalLibraryLastScannedAt(SharedPreferences prefs) {
  return prefs.remove(localLibraryLastScannedAtKey);
}
