import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:spotiflac_android/utils/file_access.dart';

final _log = AppLogger('LibraryDatabase');

class LocalLibraryItem {
  final String id;
  final String trackName;
  final String artistName;
  final String albumName;
  final String? albumArtist;
  final String filePath;
  final String? coverPath;
  final DateTime scannedAt;
  final int? fileModTime;
  final String? isrc;
  final int? trackNumber;
  final int? discNumber;
  final int? duration;
  final String? releaseDate;
  final int? bitDepth;
  final int? sampleRate;
  final int? bitrate; // kbps, for lossy formats (mp3, opus, ogg)
  final String? genre;
  final String? label;
  final String? copyright;
  final String? format; // flac, mp3, opus, m4a

  const LocalLibraryItem({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.albumArtist,
    required this.filePath,
    this.coverPath,
    required this.scannedAt,
    this.fileModTime,
    this.isrc,
    this.trackNumber,
    this.discNumber,
    this.duration,
    this.releaseDate,
    this.bitDepth,
    this.sampleRate,
    this.bitrate,
    this.genre,
    this.label,
    this.copyright,
    this.format,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'trackName': trackName,
    'artistName': artistName,
    'albumName': albumName,
    'albumArtist': albumArtist,
    'filePath': filePath,
    'coverPath': coverPath,
    'scannedAt': scannedAt.toIso8601String(),
    'fileModTime': fileModTime,
    'isrc': isrc,
    'trackNumber': trackNumber,
    'discNumber': discNumber,
    'duration': duration,
    'releaseDate': releaseDate,
    'bitDepth': bitDepth,
    'sampleRate': sampleRate,
    'bitrate': bitrate,
    'genre': genre,
    'label': label,
    'copyright': copyright,
    'format': format,
  };

  factory LocalLibraryItem.fromJson(Map<String, dynamic> json) =>
      LocalLibraryItem(
        id: json['id'] as String,
        trackName: json['trackName'] as String,
        artistName: json['artistName'] as String,
        albumName: json['albumName'] as String,
        albumArtist: json['albumArtist'] as String?,
        filePath: json['filePath'] as String,
        coverPath: json['coverPath'] as String?,
        scannedAt: DateTime.parse(json['scannedAt'] as String),
        fileModTime: (json['fileModTime'] as num?)?.toInt(),
        isrc: json['isrc'] as String?,
        trackNumber: json['trackNumber'] as int?,
        discNumber: json['discNumber'] as int?,
        duration: json['duration'] as int?,
        releaseDate: json['releaseDate'] as String?,
        bitDepth: json['bitDepth'] as int?,
        sampleRate: json['sampleRate'] as int?,
        bitrate: (json['bitrate'] as num?)?.toInt(),
        genre: json['genre'] as String?,
        label: json['label'] as String?,
        copyright: json['copyright'] as String?,
        format: json['format'] as String?,
      );

  String get matchKey =>
      '${trackName.toLowerCase()}|${artistName.toLowerCase()}';
  String get albumKey =>
      '${albumName.toLowerCase()}|${(albumArtist ?? artistName).toLowerCase()}';
}

class LibraryDatabase {
  static final LibraryDatabase instance = LibraryDatabase._init();
  static Database? _database;

  LibraryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('local_library.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, fileName);

    _log.i('Initializing library database at: $path');

    return await openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA synchronous = NORMAL');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    _log.i('Creating library database schema v$version');

    await db.execute('''
      CREATE TABLE library (
        id TEXT PRIMARY KEY,
        track_name TEXT NOT NULL,
        artist_name TEXT NOT NULL,
        album_name TEXT NOT NULL,
        album_artist TEXT,
        file_path TEXT NOT NULL UNIQUE,
        cover_path TEXT,
        scanned_at TEXT NOT NULL,
        file_mod_time INTEGER,
        isrc TEXT,
        track_number INTEGER,
        disc_number INTEGER,
        duration INTEGER,
        release_date TEXT,
        bit_depth INTEGER,
        sample_rate INTEGER,
        bitrate INTEGER,
        genre TEXT,
        label TEXT,
        copyright TEXT,
        format TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_library_isrc ON library(isrc)');
    await db.execute(
      'CREATE INDEX idx_library_track_artist ON library(track_name, artist_name)',
    );
    await db.execute(
      'CREATE INDEX idx_library_album ON library(album_name, album_artist)',
    );
    await db.execute(
      'CREATE INDEX idx_library_file_path ON library(file_path)',
    );

    _log.i('Library database schema created with indexes');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    _log.i('Upgrading library database from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      await db.execute('ALTER TABLE library ADD COLUMN cover_path TEXT');
      _log.i('Added cover_path column');
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE library ADD COLUMN file_mod_time INTEGER');
      _log.i('Added file_mod_time column for incremental scanning');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE library ADD COLUMN bitrate INTEGER');
      _log.i('Added bitrate column for lossy format quality');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE library ADD COLUMN label TEXT');
      await db.execute('ALTER TABLE library ADD COLUMN copyright TEXT');
      _log.i('Added label/copyright columns');
    }
  }

  Map<String, dynamic> _jsonToDbRow(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'track_name': json['trackName'],
      'artist_name': json['artistName'],
      'album_name': json['albumName'],
      'album_artist': json['albumArtist'],
      'file_path': json['filePath'],
      'cover_path': json['coverPath'],
      'scanned_at': json['scannedAt'],
      'file_mod_time': json['fileModTime'],
      'isrc': json['isrc'],
      'track_number': json['trackNumber'],
      'disc_number': json['discNumber'],
      'duration': json['duration'],
      'release_date': json['releaseDate'],
      'bit_depth': json['bitDepth'],
      'sample_rate': json['sampleRate'],
      'bitrate': json['bitrate'],
      'genre': json['genre'],
      'label': json['label'],
      'copyright': json['copyright'],
      'format': json['format'],
    };
  }

  Map<String, dynamic> _dbRowToJson(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'trackName': row['track_name'],
      'artistName': row['artist_name'],
      'albumName': row['album_name'],
      'albumArtist': row['album_artist'],
      'filePath': row['file_path'],
      'coverPath': row['cover_path'],
      'scannedAt': row['scanned_at'],
      'fileModTime': row['file_mod_time'],
      'isrc': row['isrc'],
      'trackNumber': row['track_number'],
      'discNumber': row['disc_number'],
      'duration': row['duration'],
      'releaseDate': row['release_date'],
      'bitDepth': row['bit_depth'],
      'sampleRate': row['sample_rate'],
      'bitrate': row['bitrate'],
      'genre': row['genre'],
      'label': row['label'],
      'copyright': row['copyright'],
      'format': row['format'],
    };
  }

  Future<void> upsert(Map<String, dynamic> json) async {
    final db = await database;
    await db.insert(
      'library',
      _jsonToDbRow(json),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertBatch(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final json in items) {
        batch.insert(
          'library',
          _jsonToDbRow(json),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
    _log.i('Batch inserted ${items.length} items');
  }

  Future<void> replaceAll(List<Map<String, dynamic>> items) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('library');
      if (items.isEmpty) {
        return;
      }

      final batch = txn.batch();
      for (final json in items) {
        batch.insert(
          'library',
          _jsonToDbRow(json),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
    _log.i('Replaced library with ${items.length} items');
  }

  Future<List<Map<String, dynamic>>> getAll({int? limit, int? offset}) async {
    final db = await database;
    final rows = await db.query(
      'library',
      orderBy: 'album_artist, album_name, disc_number, track_number',
      limit: limit,
      offset: offset,
    );
    return rows.map(_dbRowToJson).toList();
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await database;
    final rows = await db.query(
      'library',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _dbRowToJson(rows.first);
  }

  Future<Map<String, dynamic>?> getByIsrc(String isrc) async {
    final db = await database;
    final rows = await db.query(
      'library',
      where: 'isrc = ?',
      whereArgs: [isrc],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _dbRowToJson(rows.first);
  }

  Future<bool> existsByIsrc(String isrc) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT 1 FROM library WHERE isrc = ? LIMIT 1',
      [isrc],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> findByTrackAndArtist(
    String trackName,
    String artistName,
  ) async {
    final db = await database;
    final rows = await db.query(
      'library',
      where: 'LOWER(track_name) = ? AND LOWER(artist_name) = ?',
      whereArgs: [trackName.toLowerCase(), artistName.toLowerCase()],
    );
    return rows.map(_dbRowToJson).toList();
  }

  Future<Map<String, dynamic>?> findExisting({
    String? isrc,
    String? trackName,
    String? artistName,
  }) async {
    if (isrc != null && isrc.isNotEmpty) {
      final byIsrc = await getByIsrc(isrc);
      if (byIsrc != null) return byIsrc;
    }

    if (trackName != null && artistName != null) {
      final matches = await findByTrackAndArtist(trackName, artistName);
      if (matches.isNotEmpty) return matches.first;
    }

    return null;
  }

  Future<Set<String>> getAllIsrcs() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT isrc FROM library WHERE isrc IS NOT NULL AND isrc != ""',
    );
    return rows.map((r) => r['isrc'] as String).toSet();
  }

  Future<Set<String>> getAllTrackKeys() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT LOWER(track_name) || "|" || LOWER(artist_name) as match_key FROM library',
    );
    return rows.map((r) => r['match_key'] as String).toSet();
  }

  Future<void> deleteByPath(String filePath) async {
    final db = await database;
    await db.delete('library', where: 'file_path = ?', whereArgs: [filePath]);
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete('library', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> cleanupMissingFiles() async {
    final db = await database;
    final rows = await db.query('library', columns: ['id', 'file_path']);

    final missingIds = <String>[];
    const checkChunkSize = 16;
    for (var i = 0; i < rows.length; i += checkChunkSize) {
      final end = (i + checkChunkSize < rows.length)
          ? i + checkChunkSize
          : rows.length;
      final chunk = rows.sublist(i, end);
      final checks = await Future.wait<MapEntry<String, bool>>(
        chunk.map((row) async {
          final id = row['id'] as String;
          final filePath = row['file_path'] as String;
          return MapEntry(id, await fileExists(filePath));
        }),
      );
      for (final check in checks) {
        if (!check.value) {
          missingIds.add(check.key);
        }
      }
    }

    if (missingIds.isEmpty) {
      return 0;
    }

    var removed = 0;
    const deleteChunkSize = 500;
    for (var i = 0; i < missingIds.length; i += deleteChunkSize) {
      final end = (i + deleteChunkSize < missingIds.length)
          ? i + deleteChunkSize
          : missingIds.length;
      final idChunk = missingIds.sublist(i, end);
      final placeholders = List.filled(idChunk.length, '?').join(',');
      removed += await db.rawDelete(
        'DELETE FROM library WHERE id IN ($placeholders)',
        idChunk,
      );
    }

    if (removed > 0) {
      _log.i('Cleaned up $removed missing files from library');
    }
    return removed;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('library');
    _log.i('Cleared all library data');
  }

  Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM library');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> search(
    String query, {
    int limit = 50,
  }) async {
    final db = await database;
    final searchQuery = '%${query.toLowerCase()}%';
    final rows = await db.query(
      'library',
      where:
          'LOWER(track_name) LIKE ? OR LOWER(artist_name) LIKE ? OR LOWER(album_name) LIKE ?',
      whereArgs: [searchQuery, searchQuery, searchQuery],
      orderBy: 'track_name',
      limit: limit,
    );
    return rows.map(_dbRowToJson).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<Map<String, int>> getFileModTimes() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT file_path, COALESCE(file_mod_time, 0) AS file_mod_time FROM library',
    );
    final result = <String, int>{};
    for (final row in rows) {
      final path = row['file_path'] as String;
      final modTime = (row['file_mod_time'] as num?)?.toInt() ?? 0;
      result[path] = modTime;
    }
    return result;
  }

  Future<String> writeFileModTimesSnapshot() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT file_path, COALESCE(file_mod_time, 0) AS file_mod_time FROM library',
    );
    final tempDir = await getTemporaryDirectory();
    final file = File(
      join(
        tempDir.path,
        'library_file_mod_times_${DateTime.now().microsecondsSinceEpoch}.tsv',
      ),
    );
    final buffer = StringBuffer();
    for (final row in rows) {
      final path = row['file_path'] as String?;
      if (path == null || path.isEmpty) continue;
      final modTime = (row['file_mod_time'] as num?)?.toInt() ?? 0;
      buffer
        ..write(modTime)
        ..write('\t')
        ..writeln(path);
    }
    await file.writeAsString(buffer.toString(), flush: true);
    return file.path;
  }

  Future<void> updateFileModTimes(Map<String, int> fileModTimes) async {
    if (fileModTimes.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final entry in fileModTimes.entries) {
      batch.update(
        'library',
        {'file_mod_time': entry.value},
        where: 'file_path = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Set<String>> getAllFilePaths() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT file_path FROM library');
    return rows.map((r) => r['file_path'] as String).toSet();
  }

  Future<int> deleteByPaths(List<String> filePaths) async {
    if (filePaths.isEmpty) return 0;
    final db = await database;
    var totalDeleted = 0;
    const chunkSize = 500;
    for (var i = 0; i < filePaths.length; i += chunkSize) {
      final end = (i + chunkSize < filePaths.length)
          ? i + chunkSize
          : filePaths.length;
      final chunk = filePaths.sublist(i, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      totalDeleted += await db.rawDelete(
        'DELETE FROM library WHERE file_path IN ($placeholders)',
        chunk,
      );
    }
    if (totalDeleted > 0) {
      _log.i('Deleted $totalDeleted items from library');
    }
    return totalDeleted;
  }
}
