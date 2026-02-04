import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('ShareIntent');

class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  // Spotify patterns
  static final RegExp _spotifyUriPattern =
      RegExp(r'spotify:(track|album|playlist|artist):[a-zA-Z0-9]+');
  static final RegExp _spotifyUrlPattern = RegExp(
    r'https?://open\.spotify\.com/(track|album|playlist|artist)/[a-zA-Z0-9]+(\?[^\s]*)?',
  );

  // Deezer patterns
  static final RegExp _deezerUrlPattern = RegExp(
    r'https?://(www\.)?deezer\.com/(track|album|playlist|artist)/\d+(\?[^\s]*)?',
  );
  static final RegExp _deezerShortLinkPattern = RegExp(
    r'https?://deezer\.page\.link/[a-zA-Z0-9]+',
  );

  // Tidal patterns
  static final RegExp _tidalUrlPattern = RegExp(
    r'https?://(listen\.)?tidal\.com/(track|album|playlist|artist)/[a-zA-Z0-9-]+(\?[^\s]*)?',
  );

  // YouTube Music patterns
  static final RegExp _ytMusicUrlPattern = RegExp(
    r'https?://music\.youtube\.com/(watch\?v=|playlist\?list=|channel/)[a-zA-Z0-9_-]+(\&[^\s]*)?',
  );

  final _sharedUrlController = StreamController<String>.broadcast();
  StreamSubscription<List<SharedMediaFile>>? _mediaSubscription;
  bool _initialized = false;
  String? _pendingUrl;

  Stream<String> get sharedUrlStream => _sharedUrlController.stream;

  String? consumePendingUrl() {
    final url = _pendingUrl;
    _pendingUrl = null;
    return url;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _mediaSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleSharedMedia,
      onError: (err) => _log.e('Error: $err'),
    );

    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initialMedia.isNotEmpty) {
      _handleSharedMedia(initialMedia, isInitial: true);
      ReceiveSharingIntent.instance.reset();
    }
  }

  void _handleSharedMedia(List<SharedMediaFile> files, {bool isInitial = false}) {
    for (final file in files) {
      final textToCheck = file.path;
      
      final url = _extractMusicUrl(textToCheck);
      if (url != null) {
        _log.i('Received music URL: $url (initial: $isInitial)');
        if (isInitial) {
          _pendingUrl = url;
        }
        _sharedUrlController.add(url);
        return;
      }
    }
  }

  String? _extractMusicUrl(String text) {
    if (text.isEmpty) return null;

    // Try Spotify URI first
    final uriMatch = _spotifyUriPattern.firstMatch(text);
    if (uriMatch != null) {
      return uriMatch.group(0);
    }

    // Try all URL patterns
    final patterns = [
      _spotifyUrlPattern,
      _deezerUrlPattern,
      _deezerShortLinkPattern,
      _tidalUrlPattern,
      _ytMusicUrlPattern,
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final fullUrl = match.group(0)!;
        // Remove query params for cleaner URL (except for YT Music which needs them)
        if (pattern == _ytMusicUrlPattern) {
          return fullUrl;
        }
        final queryIndex = fullUrl.indexOf('?');
        return queryIndex > 0 ? fullUrl.substring(0, queryIndex) : fullUrl;
      }
    }

    return null;
  }

  void dispose() {
    _mediaSubscription?.cancel();
    _sharedUrlController.close();
  }
}
