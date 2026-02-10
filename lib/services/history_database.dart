import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('HistoryDatabase');
final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

/// Cached current iOS container path for path normalization
String? _currentContainerPath;

/// SQLite database service for download history
/// Provides O(1) lookups by spotify_id and isrc with proper indexing
class HistoryDatabase {
  static final HistoryDatabase instance = HistoryDatabase._init();
  static Database? _database;

  HistoryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('history.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, fileName);

    _log.i('Initializing database at: $path');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    _log.i('Creating database schema v$version');

    await db.execute('''
      CREATE TABLE history (
        id TEXT PRIMARY KEY,
        track_name TEXT NOT NULL,
        artist_name TEXT NOT NULL,
        album_name TEXT NOT NULL,
        album_artist TEXT,
        cover_url TEXT,
        file_path TEXT NOT NULL,
        storage_mode TEXT,
        download_tree_uri TEXT,
        saf_relative_dir TEXT,
        saf_file_name TEXT,
        saf_repaired INTEGER,
        service TEXT NOT NULL,
        downloaded_at TEXT NOT NULL,
        isrc TEXT,
        spotify_id TEXT,
        track_number INTEGER,
        disc_number INTEGER,
        duration INTEGER,
        release_date TEXT,
        quality TEXT,
        bit_depth INTEGER,
        sample_rate INTEGER,
        genre TEXT,
        label TEXT,
        copyright TEXT
      )
    ''');

    // Indexes for fast lookups
    await db.execute('CREATE INDEX idx_spotify_id ON history(spotify_id)');
    await db.execute('CREATE INDEX idx_isrc ON history(isrc)');
    await db.execute(
      'CREATE INDEX idx_downloaded_at ON history(downloaded_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_album ON history(album_name, album_artist)',
    );

    _log.i('Database schema created with indexes');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    _log.i('Upgrading database from v$oldVersion to v$newVersion');
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE history ADD COLUMN storage_mode TEXT');
      await db.execute('ALTER TABLE history ADD COLUMN download_tree_uri TEXT');
      await db.execute('ALTER TABLE history ADD COLUMN saf_relative_dir TEXT');
      await db.execute('ALTER TABLE history ADD COLUMN saf_file_name TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE history ADD COLUMN saf_repaired INTEGER');
    }
  }

  // ==================== iOS Path Normalization ====================

  /// Pattern to match iOS container paths
  /// Example: /var/mobile/Containers/Data/Application/UUID-HERE/Documents/...
  static final _iosContainerPattern = RegExp(
    r'/var/mobile/Containers/Data/Application/[A-F0-9\-]+/',
    caseSensitive: false,
  );

  /// Initialize and cache the current iOS container path
  Future<void> _initContainerPath() async {
    if (!Platform.isIOS || _currentContainerPath != null) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      // Extract container path up to and including the UUID folder
      // e.g., /var/mobile/Containers/Data/Application/UUID/
      final match = _iosContainerPattern.firstMatch(docDir.path);
      if (match != null) {
        _currentContainerPath = match.group(0);
        _log.d('iOS container path: $_currentContainerPath');
      }
    } catch (e) {
      _log.w('Failed to get iOS container path: $e');
    }
  }

  /// Normalize iOS file path by replacing old container UUID with current one
  /// This fixes the issue where iOS changes container UUID after app updates
  String _normalizeIosPath(String? filePath) {
    if (filePath == null || filePath.isEmpty) return filePath ?? '';
    if (!Platform.isIOS || _currentContainerPath == null) return filePath;

    // Check if path contains an iOS container path
    if (_iosContainerPattern.hasMatch(filePath)) {
      final normalized = filePath.replaceFirst(
        _iosContainerPattern,
        _currentContainerPath!,
      );
      if (normalized != filePath) {
        _log.d('Normalized iOS path: $filePath -> $normalized');
      }
      return normalized;
    }

    return filePath;
  }

  /// Migrate iOS paths in database to use current container UUID
  /// This is called once after app update if container changed
  Future<bool> migrateIosContainerPaths() async {
    if (!Platform.isIOS) return false;

    await _initContainerPath();
    if (_currentContainerPath == null) return false;

    final prefs = await _prefs;
    final lastContainer = prefs.getString('ios_last_container_path');

    if (lastContainer == _currentContainerPath) {
      _log.d('iOS container path unchanged, skipping migration');
      return false;
    }

    _log.i('iOS container changed: $lastContainer -> $_currentContainerPath');

    try {
      final db = await database;

      // Get all items with iOS paths
      final rows = await db.query('history', columns: ['id', 'file_path']);
      int updatedCount = 0;
      final batch = db.batch();

      for (final row in rows) {
        final id = row['id'] as String;
        final oldPath = row['file_path'] as String?;

        if (oldPath != null && _iosContainerPattern.hasMatch(oldPath)) {
          final newPath = _normalizeIosPath(oldPath);
          if (newPath != oldPath) {
            batch.update(
              'history',
              {'file_path': newPath},
              where: 'id = ?',
              whereArgs: [id],
            );
            updatedCount++;
          }
        }
      }

      if (updatedCount > 0) {
        await batch.commit(noResult: true);
      }

      // Save current container path
      await prefs.setString('ios_last_container_path', _currentContainerPath!);

      _log.i('iOS path migration complete: $updatedCount paths updated');
      return updatedCount > 0;
    } catch (e, stack) {
      _log.e('iOS path migration failed: $e', e, stack);
      return false;
    }
  }

  /// Migrate data from SharedPreferences to SQLite
  /// Returns true if migration was performed, false if already migrated
  Future<bool> migrateFromSharedPreferences() async {
    final prefs = await _prefs;
    final migrationKey = 'history_migrated_to_sqlite';

    if (prefs.getBool(migrationKey) == true) {
      _log.d('Already migrated to SQLite');
      return false;
    }

    final jsonStr = prefs.getString('download_history');
    if (jsonStr == null || jsonStr.isEmpty) {
      _log.d('No SharedPreferences history to migrate');
      await prefs.setBool(migrationKey, true);
      return false;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      _log.i(
        'Migrating ${jsonList.length} items from SharedPreferences to SQLite',
      );

      final db = await database;
      final batch = db.batch();

      for (final json in jsonList) {
        final map = json as Map<String, dynamic>;
        batch.insert(
          'history',
          _jsonToDbRow(map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);

      // Mark as migrated but keep old data for safety
      await prefs.setBool(migrationKey, true);
      _log.i('Migration complete: ${jsonList.length} items');

      return true;
    } catch (e, stack) {
      _log.e('Migration failed: $e', e, stack);
      return false;
    }
  }

  /// Convert JSON format (camelCase) to DB row (snake_case)
  Map<String, dynamic> _jsonToDbRow(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'track_name': json['trackName'],
      'artist_name': json['artistName'],
      'album_name': json['albumName'],
      'album_artist': json['albumArtist'],
      'cover_url': json['coverUrl'],
      'file_path': json['filePath'],
      'storage_mode': json['storageMode'],
      'download_tree_uri': json['downloadTreeUri'],
      'saf_relative_dir': json['safRelativeDir'],
      'saf_file_name': json['safFileName'],
      'saf_repaired': json['safRepaired'] == true ? 1 : 0,
      'service': json['service'],
      'downloaded_at': json['downloadedAt'],
      'isrc': json['isrc'],
      'spotify_id': json['spotifyId'],
      'track_number': json['trackNumber'],
      'disc_number': json['discNumber'],
      'duration': json['duration'],
      'release_date': json['releaseDate'],
      'quality': json['quality'],
      'bit_depth': json['bitDepth'],
      'sample_rate': json['sampleRate'],
      'genre': json['genre'],
      'label': json['label'],
      'copyright': json['copyright'],
    };
  }

  /// Convert DB row (snake_case) to JSON format (camelCase)
  /// Also normalizes iOS paths if container UUID changed
  Map<String, dynamic> _dbRowToJson(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'trackName': row['track_name'],
      'artistName': row['artist_name'],
      'albumName': row['album_name'],
      'albumArtist': row['album_artist'],
      'coverUrl': row['cover_url'],
      'filePath': _normalizeIosPath(row['file_path'] as String?),
      'storageMode': row['storage_mode'],
      'downloadTreeUri': row['download_tree_uri'],
      'safRelativeDir': row['saf_relative_dir'],
      'safFileName': row['saf_file_name'],
      'safRepaired': row['saf_repaired'] == 1 || row['saf_repaired'] == true,
      'service': row['service'],
      'downloadedAt': row['downloaded_at'],
      'isrc': row['isrc'],
      'spotifyId': row['spotify_id'],
      'trackNumber': row['track_number'],
      'discNumber': row['disc_number'],
      'duration': row['duration'],
      'releaseDate': row['release_date'],
      'quality': row['quality'],
      'bitDepth': row['bit_depth'],
      'sampleRate': row['sample_rate'],
      'genre': row['genre'],
      'label': row['label'],
      'copyright': row['copyright'],
    };
  }

  // ==================== CRUD Operations ====================

  /// Insert or update a history item
  Future<void> upsert(Map<String, dynamic> json) async {
    final db = await database;
    await db.insert(
      'history',
      _jsonToDbRow(json),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all history items ordered by download date (newest first)
  Future<List<Map<String, dynamic>>> getAll({int? limit, int? offset}) async {
    final db = await database;
    final rows = await db.query(
      'history',
      orderBy: 'downloaded_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_dbRowToJson).toList();
  }

  /// Get item by ID
  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await database;
    final rows = await db.query(
      'history',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _dbRowToJson(rows.first);
  }

  /// Get item by Spotify ID - O(1) with index
  Future<Map<String, dynamic>?> getBySpotifyId(String spotifyId) async {
    final db = await database;
    final rows = await db.query(
      'history',
      where: 'spotify_id = ?',
      whereArgs: [spotifyId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _dbRowToJson(rows.first);
  }

  /// Get item by ISRC - O(1) with index
  Future<Map<String, dynamic>?> getByIsrc(String isrc) async {
    final db = await database;
    final rows = await db.query(
      'history',
      where: 'isrc = ?',
      whereArgs: [isrc],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _dbRowToJson(rows.first);
  }

  /// Check if spotify_id exists - O(1) with index
  Future<bool> existsBySpotifyId(String spotifyId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT 1 FROM history WHERE spotify_id = ? LIMIT 1',
      [spotifyId],
    );
    return result.isNotEmpty;
  }

  /// Get all spotify_ids as Set for fast in-memory lookup
  Future<Set<String>> getAllSpotifyIds() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT spotify_id FROM history WHERE spotify_id IS NOT NULL AND spotify_id != ""',
    );
    return rows.map((r) => r['spotify_id'] as String).toSet();
  }

  /// Delete by ID
  Future<void> deleteById(String id) async {
    final db = await database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete by Spotify ID
  Future<void> deleteBySpotifyId(String spotifyId) async {
    final db = await database;
    await db.delete('history', where: 'spotify_id = ?', whereArgs: [spotifyId]);
  }

  /// Clear all history
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('history');
    _log.i('Cleared all history');
  }

  /// Get total count
  Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM history');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Find existing item by spotify_id or isrc (for deduplication)
  Future<Map<String, dynamic>?> findExisting({
    String? spotifyId,
    String? isrc,
  }) async {
    if (spotifyId != null && spotifyId.isNotEmpty) {
      final bySpotify = await getBySpotifyId(spotifyId);
      if (bySpotify != null) return bySpotify;

      // Check for deezer: prefix matching
      if (spotifyId.startsWith('deezer:')) {
        final deezerId = spotifyId.substring(7);
        final db = await database;
        final rows = await db.query(
          'history',
          where: 'spotify_id LIKE ?',
          whereArgs: ['deezer:$deezerId'],
          limit: 1,
        );
        if (rows.isNotEmpty) return _dbRowToJson(rows.first);
      }
    }

    if (isrc != null && isrc.isNotEmpty) {
      return await getByIsrc(isrc);
    }

    return null;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Update file path for a history entry (e.g. after format conversion)
  Future<void> updateFilePath(
    String id,
    String newFilePath, {
    String? newSafFileName,
    String? newQuality,
    int? newBitDepth,
    int? newSampleRate,
    bool clearAudioSpecs = false,
  }) async {
    final db = await database;
    final values = <String, dynamic>{'file_path': newFilePath};
    if (newSafFileName != null) {
      values['saf_file_name'] = newSafFileName;
    }
    if (newQuality != null) {
      values['quality'] = newQuality;
    }
    if (clearAudioSpecs) {
      values['bit_depth'] = null;
      values['sample_rate'] = null;
    } else {
      if (newBitDepth != null) {
        values['bit_depth'] = newBitDepth;
      }
      if (newSampleRate != null) {
        values['sample_rate'] = newSampleRate;
      }
    }
    await db.update('history', values, where: 'id = ?', whereArgs: [id]);
  }

  /// Get all file paths from download history
  /// Used to exclude downloaded files from local library scan
  Future<Set<String>> getAllFilePaths() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT file_path FROM history WHERE file_path IS NOT NULL AND file_path != ""',
    );
    return rows.map((r) => r['file_path'] as String).toSet();
  }

  /// Get all entries with file paths for orphan detection
  /// Returns list of (id, file_path, storage_mode, download_tree_uri, saf_relative_dir, saf_file_name)
  Future<List<Map<String, dynamic>>> getAllEntriesWithPaths() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT id, file_path, storage_mode, download_tree_uri, saf_relative_dir, saf_file_name
      FROM history 
      WHERE file_path IS NOT NULL AND file_path != ""
    ''');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  /// Delete multiple entries by IDs
  Future<int> deleteByIds(List<String> ids) async {
    if (ids.isEmpty) return 0;

    final db = await database;
    var totalDeleted = 0;
    const chunkSize = 500;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      final chunk = ids.sublist(i, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      totalDeleted += await db.rawDelete(
        'DELETE FROM history WHERE id IN ($placeholders)',
        chunk,
      );
    }
    _log.i('Deleted $totalDeleted orphaned entries');
    return totalDeleted;
  }
}
