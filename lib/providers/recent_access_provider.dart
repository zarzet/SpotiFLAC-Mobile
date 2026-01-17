import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _recentAccessKey = 'recent_access_history';
const _maxRecentItems = 20;

/// Types of items that can be accessed
enum RecentAccessType {
  artist,
  album,
  track,
  playlist,
}

/// Represents a recently accessed item
class RecentAccessItem {
  final String id;
  final String name;
  final String? subtitle; // Artist name for tracks/albums, null for artists
  final String? imageUrl;
  final RecentAccessType type;
  final DateTime accessedAt;
  final String? providerId; // Extension ID or 'deezer' for built-in

  const RecentAccessItem({
    required this.id,
    required this.name,
    this.subtitle,
    this.imageUrl,
    required this.type,
    required this.accessedAt,
    this.providerId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'type': type.name,
    'accessedAt': accessedAt.toIso8601String(),
    'providerId': providerId,
  };

  factory RecentAccessItem.fromJson(Map<String, dynamic> json) {
    return RecentAccessItem(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String?,
      type: RecentAccessType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecentAccessType.track,
      ),
      accessedAt: DateTime.parse(json['accessedAt'] as String),
      providerId: json['providerId'] as String?,
    );
  }

  /// Create a unique key for deduplication
  String get uniqueKey => '${type.name}:${providerId ?? 'default'}:$id';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentAccessItem &&
          runtimeType == other.runtimeType &&
          uniqueKey == other.uniqueKey;

  @override
  int get hashCode => uniqueKey.hashCode;
}

/// State for recent access history
class RecentAccessState {
  final List<RecentAccessItem> items;
  final bool isLoaded;

  const RecentAccessState({
    this.items = const [],
    this.isLoaded = false,
  });

  RecentAccessState copyWith({
    List<RecentAccessItem>? items,
    bool? isLoaded,
  }) {
    return RecentAccessState(
      items: items ?? this.items,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// Provider for managing recent access history
class RecentAccessNotifier extends Notifier<RecentAccessState> {
  @override
  RecentAccessState build() {
    _loadHistory();
    return const RecentAccessState();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_recentAccessKey);
    if (json != null) {
      try {
        final List<dynamic> decoded = jsonDecode(json);
        final items = decoded
            .map((e) => RecentAccessItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(items: items, isLoaded: true);
      } catch (e) {
        state = state.copyWith(isLoaded: true);
      }
    } else {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.items.map((e) => e.toJson()).toList());
    await prefs.setString(_recentAccessKey, json);
  }

  /// Record an access to an artist
  void recordArtistAccess({
    required String id,
    required String name,
    String? imageUrl,
    String? providerId,
  }) {
    _recordAccess(RecentAccessItem(
      id: id,
      name: name,
      imageUrl: imageUrl,
      type: RecentAccessType.artist,
      accessedAt: DateTime.now(),
      providerId: providerId,
    ));
  }

  /// Record an access to an album
  void recordAlbumAccess({
    required String id,
    required String name,
    String? artistName,
    String? imageUrl,
    String? providerId,
  }) {
    _recordAccess(RecentAccessItem(
      id: id,
      name: name,
      subtitle: artistName,
      imageUrl: imageUrl,
      type: RecentAccessType.album,
      accessedAt: DateTime.now(),
      providerId: providerId,
    ));
  }

  /// Record an access to a track
  void recordTrackAccess({
    required String id,
    required String name,
    String? artistName,
    String? imageUrl,
    String? providerId,
  }) {
    _recordAccess(RecentAccessItem(
      id: id,
      name: name,
      subtitle: artistName,
      imageUrl: imageUrl,
      type: RecentAccessType.track,
      accessedAt: DateTime.now(),
      providerId: providerId,
    ));
  }

  /// Record an access to a playlist
  void recordPlaylistAccess({
    required String id,
    required String name,
    String? ownerName,
    String? imageUrl,
    String? providerId,
  }) {
    _recordAccess(RecentAccessItem(
      id: id,
      name: name,
      subtitle: ownerName,
      imageUrl: imageUrl,
      type: RecentAccessType.playlist,
      accessedAt: DateTime.now(),
      providerId: providerId,
    ));
  }

  void _recordAccess(RecentAccessItem item) {
    // ignore: avoid_print
    print('[RecentAccess] Recording: ${item.type.name} - ${item.name} (${item.id})');
    
    final updatedItems = state.items
        .where((e) => e.uniqueKey != item.uniqueKey)
        .toList();
    
    updatedItems.insert(0, item);
    
    if (updatedItems.length > _maxRecentItems) {
      updatedItems.removeRange(_maxRecentItems, updatedItems.length);
    }
    
    state = state.copyWith(items: updatedItems);
    _saveHistory();
    
    // ignore: avoid_print
    print('[RecentAccess] Total items now: ${updatedItems.length}');
  }

  /// Remove a specific item from history
  void removeItem(RecentAccessItem item) {
    final updatedItems = state.items
        .where((e) => e.uniqueKey != item.uniqueKey)
        .toList();
    state = state.copyWith(items: updatedItems);
    _saveHistory();
  }

  /// Clear all history
  void clearHistory() {
    state = state.copyWith(items: []);
    _saveHistory();
  }
}

/// Provider instance
final recentAccessProvider = NotifierProvider<RecentAccessNotifier, RecentAccessState>(
  RecentAccessNotifier.new,
);
