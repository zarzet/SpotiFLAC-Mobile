import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

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

    // Listen to media sharing coming from outside the app while the app is in memory
    _mediaSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleSharedMedia,
      onError: (err) => print('[ShareIntent] Error: $err'),
    );

    // Get the media sharing coming from outside the app while the app is closed
    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initialMedia.isNotEmpty) {
      _handleSharedMedia(initialMedia, isInitial: true);
      // Tell the library that we are done processing the intent
      ReceiveSharingIntent.instance.reset();
    }
  }

  void _handleSharedMedia(List<SharedMediaFile> files, {bool isInitial = false}) {
    for (final file in files) {
      // Check the path - for text shares, the path contains the shared text
      final textToCheck = file.path;
      
      final url = _extractSpotifyUrl(textToCheck);
      if (url != null) {
        print('[ShareIntent] Received Spotify URL: $url (initial: $isInitial)');
        if (isInitial) {
          // Store for later - listener might not be ready yet
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

    // Check for spotify: URI format
    final uriMatch = RegExp(r'spotify:(track|album|playlist|artist):[a-zA-Z0-9]+').firstMatch(text);
    if (uriMatch != null) {
      return uriMatch.group(0);
    }

    // Check for open.spotify.com URL
    final urlMatch = RegExp(
      r'https?://open\.spotify\.com/(track|album|playlist|artist)/[a-zA-Z0-9]+(\?[^\s]*)?',
    ).firstMatch(text);
    if (urlMatch != null) {
      // Return URL without query params for cleaner handling
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
