import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';

final _log = AppLogger('ExploreProvider');

class ExploreItem {
  final String id;
  final String uri;
  final String type;
  final String name;
  final String artists;
  final String? description;
  final String? coverUrl;
  final String? providerId;
  final String? albumId;
  final String? albumName;
  final String? releaseDate;
  final int durationMs;

  const ExploreItem({
    required this.id,
    required this.uri,
    required this.type,
    required this.name,
    required this.artists,
    this.description,
    this.coverUrl,
    this.providerId,
    this.albumId,
    this.albumName,
    this.releaseDate,
    this.durationMs = 0,
  });

  factory ExploreItem.fromJson(Map<String, dynamic> json) {
    return ExploreItem(
      id: json['id'] as String? ?? '',
      uri: json['uri'] as String? ?? '',
      type: json['type'] as String? ?? 'track',
      name: json['name'] as String? ?? '',
      artists: json['artists'] as String? ?? '',
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      providerId: json['provider_id'] as String?,
      albumId: json['album_id'] as String?,
      albumName: json['album_name'] as String?,
      releaseDate: json['release_date']?.toString(),
      durationMs: json['duration_ms'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uri': uri,
    'type': type,
    'name': name,
    'artists': artists,
    'description': description,
    'cover_url': coverUrl,
    'provider_id': providerId,
    'album_id': albumId,
    'album_name': albumName,
    'release_date': releaseDate,
    'duration_ms': durationMs,
  };
}

class ExploreSection {
  final String uri;
  final String title;
  final List<ExploreItem> items;
  final bool isYTMusicQuickPicks;

  const ExploreSection({
    required this.uri,
    required this.title,
    required this.items,
    this.isYTMusicQuickPicks = false,
  });

  factory ExploreSection.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((item) => ExploreItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final isQuickPicks = _isYTMusicQuickPicksItems(items);
    return ExploreSection(
      uri: json['uri'] as String? ?? '',
      title: json['title'] as String? ?? '',
      items: items,
      isYTMusicQuickPicks: isQuickPicks,
    );
  }

  Map<String, dynamic> toJson() => {
    'uri': uri,
    'title': title,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

class ExploreState {
  final bool isLoading;
  final String? error;
  final String? greeting;
  final List<ExploreSection> sections;
  final DateTime? lastFetched;

  const ExploreState({
    this.isLoading = false,
    this.error,
    this.greeting,
    this.sections = const [],
    this.lastFetched,
  });

  bool get hasContent => sections.isNotEmpty;

  ExploreState copyWith({
    bool? isLoading,
    String? error,
    String? greeting,
    List<ExploreSection>? sections,
    DateTime? lastFetched,
  }) {
    return ExploreState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      greeting: greeting ?? this.greeting,
      sections: sections ?? this.sections,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }
}

String _getLocalGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'Good morning';
  } else if (hour >= 12 && hour < 17) {
    return 'Good afternoon';
  } else if (hour >= 17 && hour < 21) {
    return 'Good evening';
  } else {
    return 'Good night';
  }
}

bool _isYTMusicQuickPicksItems(List<ExploreItem> items) {
  if (items.isEmpty) return false;
  if (items.first.providerId != 'ytmusic-spotiflac') return false;
  for (final item in items) {
    if (item.type != 'track') {
      return false;
    }
  }
  return true;
}

class ExploreNotifier extends Notifier<ExploreState> {
  static const _cacheKey = 'explore_home_feed_cache';
  static const _cacheTsKey = 'explore_home_feed_ts';

  @override
  ExploreState build() {
    _restoreFromCache();
    return const ExploreState();
  }

  Future<void> _restoreFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      final cachedTs = prefs.getInt(_cacheTsKey);
      if (cached == null || cached.isEmpty) return;

      final data = jsonDecode(cached) as Map<String, dynamic>;
      final sectionsData = data['sections'] as List<dynamic>? ?? [];
      final sections = sectionsData
          .map((s) => ExploreSection.fromJson(s as Map<String, dynamic>))
          .toList();

      if (sections.isEmpty) return;

      final lastFetched = cachedTs != null
          ? DateTime.fromMillisecondsSinceEpoch(cachedTs)
          : null;

      _log.i('Restored ${sections.length} cached explore sections');
      state = ExploreState(
        greeting: _getLocalGreeting(),
        sections: sections,
        lastFetched: lastFetched,
      );
    } catch (e) {
      _log.w('Failed to restore explore cache: $e');
    }
  }

  Future<void> _saveToCache(List<ExploreSection> sections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {'sections': sections.map((s) => s.toJson()).toList()};
      await prefs.setString(_cacheKey, jsonEncode(data));
      await prefs.setInt(_cacheTsKey, DateTime.now().millisecondsSinceEpoch);
      _log.d('Saved ${sections.length} explore sections to cache');
    } catch (e) {
      _log.w('Failed to save explore cache: $e');
    }
  }

  Future<void> fetchHomeFeed({bool forceRefresh = false}) async {
    _log.i('fetchHomeFeed called, forceRefresh=$forceRefresh');

    if (!forceRefresh &&
        state.hasContent &&
        state.lastFetched != null &&
        DateTime.now().difference(state.lastFetched!).inMinutes < 5) {
      _log.d('Using cached home feed (fresh enough)');
      return;
    }

    if (state.isLoading) {
      _log.d('Home feed fetch already in progress');
      return;
    }

    final showLoading = !state.hasContent;
    state = state.copyWith(isLoading: showLoading, error: null);

    try {
      final extState = ref.read(extensionProvider);
      final settings = ref.read(settingsProvider);
      final preferredId = settings.homeFeedProvider;
      _log.d(
        'Extensions count: ${extState.extensions.length}, preferred home feed: $preferredId',
      );

      Extension? targetExt;
      for (final extension in extState.extensions) {
        if (!extension.enabled || !extension.hasHomeFeed) {
          continue;
        }
        if (preferredId != null &&
            preferredId.isNotEmpty &&
            extension.id == preferredId) {
          targetExt = extension;
          break;
        }
        if (targetExt == null || extension.id == 'spotify-web') {
          targetExt = extension;
          if (preferredId == null && extension.id == 'spotify-web') {
            break;
          }
        }
      }

      if (targetExt == null) {
        _log.w('No extension with homeFeed capability found');
        state = state.copyWith(
          isLoading: false,
          error: 'No extension with home feed support enabled',
        );
        return;
      }

      _log.i('Fetching home feed from ${targetExt.id}...');
      final result = await PlatformBridge.getExtensionHomeFeed(targetExt.id);

      if (result == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch home feed',
        );
        return;
      }

      final success = result['success'] as bool? ?? false;
      _log.d('getExtensionHomeFeed success=$success');
      if (!success) {
        final error = result['error'] as String? ?? 'Unknown error';
        state = state.copyWith(isLoading: false, error: error);
        return;
      }

      final greeting = result['greeting'] as String?;
      final sectionsData = result['sections'] as List<dynamic>? ?? [];

      final sections = sectionsData
          .map((s) => ExploreSection.fromJson(s as Map<String, dynamic>))
          .toList();

      _log.i('Fetched ${sections.length} sections');

      if (sections.isNotEmpty && sections.first.items.isNotEmpty) {
        final firstItem = sections.first.items.first;
        _log.d(
          'First item: name=${firstItem.name}, artists=${firstItem.artists}, type=${firstItem.type}',
        );
      }

      final localGreeting = _getLocalGreeting();
      _log.d('Greeting from extension: $greeting, using local: $localGreeting');

      state = ExploreState(
        isLoading: false,
        greeting: localGreeting,
        sections: sections,
        lastFetched: DateTime.now(),
      );

      _saveToCache(sections);
    } catch (e, stack) {
      _log.e('Error fetching home feed: $e', e, stack);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const ExploreState();
  }

  Future<void> refresh() => fetchHomeFeed(forceRefresh: true);
}

final exploreProvider = NotifierProvider<ExploreNotifier, ExploreState>(() {
  return ExploreNotifier();
});
