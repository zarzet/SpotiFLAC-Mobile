import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('ShareIntent');

/// Service to handle incoming share intents from other apps (e.g., Spotify)
class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  final _sharedUrlController = StreamController<String>.broadcast();
  StreamSubscription<List<SharedMediaFile>>? _mediaSubscription;
  bool _initialized = false;
  String? _pendingUrl; // Store URL received before listener is ready

  /// Stream of shared Spotify URLs
  Stream<String> get sharedUrlStream => _sharedUrlController.stream;

  /// Get pending URL that was received before listener was ready
  String? consumePendingUrl() {
    final url = _pendingUrl;
    _pendingUrl = null;
    return url;
  }

  /// Initialize the service and start listening for share intents
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
      
      final url = _extractSpotifyUrl(textToCheck);
      if (url != null) {
        _log.i('Received Spotify URL: $url (initial: $isInitial)');
        if (isInitial) {
          _pendingUrl = url;
        }
        _sharedUrlController.add(url);
        return; // Only process first valid URL
      }
    }
  }

  /// Extract Spotify URL from shared text
  /// Handles various formats:
  /// - Direct URL: https://open.spotify.com/track/xxx
  /// - With text: "Check out this song! https://open.spotify.com/track/xxx"
  /// - Spotify URI: spotify:track:xxx
  String? _extractSpotifyUrl(String text) {
    if (text.isEmpty) return null;

    final uriMatch = RegExp(r'spotify:(track|album|playlist|artist):[a-zA-Z0-9]+').firstMatch(text);
    if (uriMatch != null) {
      return uriMatch.group(0);
    }

    final urlMatch = RegExp(
      r'https?://open\.spotify\.com/(track|album|playlist|artist)/[a-zA-Z0-9]+(\?[^\s]*)?',
    ).firstMatch(text);
    if (urlMatch != null) {
      final fullUrl = urlMatch.group(0)!;
      final queryIndex = fullUrl.indexOf('?');
      return queryIndex > 0 ? fullUrl.substring(0, queryIndex) : fullUrl;
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    _mediaSubscription?.cancel();
    _sharedUrlController.close();
  }
}
