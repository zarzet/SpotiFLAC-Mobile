import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';

class CsvImportService {
  static final _log = AppLogger('CsvImportService');

  /// Pick and parse CSV file, then enrich metadata from Deezer
  /// [onProgress] callback receives (current, total) for progress updates
  static Future<List<Track>> pickAndParseCsv({
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final tracks = _parseCsv(content);
        
        // Enrich tracks with metadata from Deezer (cover URL, duration, etc.)
        if (tracks.isNotEmpty) {
          return await _enrichTracksMetadata(tracks, onProgress: onProgress);
        }
        return tracks;
      }
    } catch (e) {
      _log.e('Error picking/parsing CSV: $e');
    }
    return [];
  }

  /// Enrich tracks with metadata from Deezer using ISRC
  /// This fetches cover URL, duration, and other metadata that CSV doesn't have
  static Future<List<Track>> _enrichTracksMetadata(
    List<Track> tracks, {
    void Function(int current, int total)? onProgress,
  }) async {
    _log.i('Enriching metadata for ${tracks.length} tracks from Deezer...');
    final enrichedTracks = <Track>[];
    
    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      onProgress?.call(i + 1, tracks.length);
      
      // Only enrich if we have ISRC and missing cover/duration
      if (track.isrc != null && 
          track.isrc!.isNotEmpty && 
          (track.coverUrl == null || track.duration == 0)) {
        try {
          // searchDeezerByISRC returns TrackMetadata directly (not wrapped in "track" key)
          final trackData = await PlatformBridge.searchDeezerByISRC(track.isrc!);
          
          // Extract enriched data from TrackMetadata
          final coverUrl = trackData['images'] as String?;
          final durationMs = trackData['duration_ms'] as int? ?? 0;
          final deezerIdRaw = trackData['spotify_id'] as String?; // Format: "deezer:123456"
          
          enrichedTracks.add(Track(
            id: deezerIdRaw ?? track.id, // Use Deezer ID if available
            name: trackData['name'] as String? ?? track.name,
            artistName: trackData['artists'] as String? ?? track.artistName,
            albumName: trackData['album_name'] as String? ?? track.albumName,
            albumArtist: trackData['album_artist'] as String?,
            coverUrl: coverUrl ?? track.coverUrl,
            isrc: trackData['isrc'] as String? ?? track.isrc,
            duration: durationMs > 0 ? durationMs ~/ 1000 : track.duration,
            trackNumber: trackData['track_number'] as int? ?? track.trackNumber,
            discNumber: trackData['disc_number'] as int? ?? track.discNumber,
            releaseDate: trackData['release_date'] as String? ?? track.releaseDate,
          ));
          
          _log.d('Enriched: ${track.name} - cover: ${coverUrl != null}, duration: ${durationMs ~/ 1000}s');
          
          // Small delay to avoid rate limiting (50ms between requests)
          if (i < tracks.length - 1) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
          continue;
        } catch (e) {
          _log.w('Failed to enrich ${track.name}: $e');
        }
      }
      
      // Keep original track if enrichment failed or not needed
      enrichedTracks.add(track);
    }
    
    _log.i('Enrichment complete: ${enrichedTracks.length} tracks');
    return enrichedTracks;
  }

  static List<Track> _parseCsv(String content) {
    final List<Track> tracks = [];
    final lines = content.split(RegExp(r'\r\n|\r|\n')); // Handle various newline formats
    if (lines.isEmpty) return tracks;

    // Detect headers line (assume first non-empty line)
    int startIdx = 0;
    while (startIdx < lines.length && lines[startIdx].trim().isEmpty) {
      startIdx++;
    }
    if (startIdx >= lines.length) return tracks;

    final headers = _parseLine(lines[startIdx]);
    final colMap = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
        // Normalize header: lowercase, trim, remove quotes
        String h = _cleanValue(headers[i]).toLowerCase();
        colMap[h] = i;
    }

    _log.d('CSV Headers: ${colMap.keys.toList()}');

    // Parse rows
    for (int i = startIdx + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = _parseLine(line);
      
      // Helper to get value securely
      String? getVal(List<String> keys) {
        return _getValue(values, colMap, keys);
      }

      String? trackName = getVal(['track name', 'track', 'name', 'title']);
      String? artistName = getVal(['artist name', 'artist']);
      String? albumName = getVal(['album name', 'album']);
      String? isrc = getVal(['isrc']); // Often formatted with leading/trailing quotes
      String? spotifyId = getVal(['spotify - id', 'spotify id', 'id', 'uri']); // Uri might need parsing

      // If 'spotify uri' contains the id: 'spotify:track:ID'
      if (spotifyId != null && spotifyId.startsWith('spotify:track:')) {
        spotifyId = spotifyId.replaceAll('spotify:track:', '');
      }

      // Basic validation: Need at least name and artist, OR a spotify ID
      if ((trackName != null && trackName.isNotEmpty && artistName != null) || (spotifyId != null && spotifyId.isNotEmpty)) {
          tracks.add(Track(
              id: spotifyId ?? 'csv_${DateTime.now().millisecondsSinceEpoch}_$i', 
              name: trackName ?? 'Unknown Track',
              artistName: artistName ?? 'Unknown Artist',
              albumName: albumName ?? 'Unknown Album',
              isrc: isrc,
              duration: 0, // Will be updated by enrichment later
              coverUrl: null, // Will be fetched by enrichment
          ));
      }
    }
    
    _log.i('Parsed ${tracks.length} tracks from CSV');
    return tracks;
  }
  
  static String? _getValue(List<String> values, Map<String, int> colMap, List<String> possibleKeys) {
      for (final key in possibleKeys) {
          if (colMap.containsKey(key)) {
              final index = colMap[key]!;
              if (index < values.length) {
                   return _cleanValue(values[index]);
              }
          }
      }
      return null;
  }

  static String _cleanValue(String val) {
    val = val.trim();
    if (val.startsWith('"') && val.endsWith('"') && val.length >= 2) {
      val = val.substring(1, val.length - 1);
    }
    // Handle double quotes escape in CSV ("" -> ")
    val = val.replaceAll('""', '"');
    return val;
  }

  // Robust CSV Line Parser
  static List<String> _parseLine(String line) {
     final List<String> result = [];
     bool inQuote = false;
     StringBuffer buffer = StringBuffer();
     
     for (int i=0; i<line.length; i++) {
         String char = line[i];
         if (char == '"') {
             // Look ahead to check for escaped quote
             if (i + 1 < line.length && line[i+1] == '"') {
                buffer.write('"'); // Keep format for now, _cleanValue handles unescaping logic differently... 
                // Wait, standard CSV: "Thumb ""Up""" -> Thumb "Up"
                // My _cleanValue handles it, so I should just preserve raw content here mostly, 
                // BUT I need to know if " toggles inQuote.
                // Escaped "" does NOT toggle inQuote mode effectively (it counts as literal char inside quote).
                buffer.write('"'); // Write 1st quote
                i++; // Skip next quote char loop
                buffer.write('"'); // Write 2nd quote
             } else {
                inQuote = !inQuote;
                buffer.write(char);
             }
         } else if (char == ',' && !inQuote) {
             result.add(buffer.toString());
             buffer.clear();
         } else {
             buffer.write(char);
         }
     }
     result.add(buffer.toString());
     return result;
  }
}
