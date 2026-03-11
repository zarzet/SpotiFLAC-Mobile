import 'package:json_annotation/json_annotation.dart';

part 'track.g.dart';

@JsonSerializable()
class Track {
  final String id;
  final String name;
  final String artistName;
  final String albumName;
  final String? albumArtist;
  final String? artistId;
  final String? albumId;
  final String? coverUrl;
  final String? isrc;
  final int duration;
  final int? trackNumber;
  final int? discNumber;
  final String? releaseDate;
  final String? deezerId;
  final ServiceAvailability? availability;
  final String? source;
  final String? albumType;
  final int? totalTracks;
  final String? itemType;

  const Track({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumName,
    this.albumArtist,
    this.artistId,
    this.albumId,
    this.coverUrl,
    this.isrc,
    required this.duration,
    this.trackNumber,
    this.discNumber,
    this.releaseDate,
    this.deezerId,
    this.availability,
    this.source,
    this.albumType,
    this.totalTracks,
    this.itemType,
  });

  bool get isSingle {
    switch (albumType?.toLowerCase()) {
      case 'single':
        return true;
      case 'ep':
        final count = totalTracks;
        return count == null || count <= 1;
      default:
        return false;
    }
  }
  
  bool get isAlbumItem => itemType == 'album';
  
  bool get isPlaylistItem => itemType == 'playlist';
  
  bool get isArtistItem => itemType == 'artist';
  
  bool get isCollection => isAlbumItem || isPlaylistItem || isArtistItem;

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);
  Map<String, dynamic> toJson() => _$TrackToJson(this);
  
  bool get isFromExtension => source != null && source!.isNotEmpty;
}

@JsonSerializable()
class ServiceAvailability {
  final bool tidal;
  final bool qobuz;
  final bool amazon;
  final bool deezer;
  final String? tidalUrl;
  final String? qobuzUrl;
  final String? amazonUrl;
  final String? deezerUrl;
  final String? deezerId;

  const ServiceAvailability({
    this.tidal = false,
    this.qobuz = false,
    this.amazon = false,
    this.deezer = false,
    this.tidalUrl,
    this.qobuzUrl,
    this.amazonUrl,
    this.deezerUrl,
    this.deezerId,
  });

  factory ServiceAvailability.fromJson(Map<String, dynamic> json) =>
      _$ServiceAvailabilityFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceAvailabilityToJson(this);
}
