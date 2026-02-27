import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/screens/artist_screen.dart';
import 'package:spotiflac_android/screens/album_screen.dart';
import 'package:spotiflac_android/screens/home_tab.dart'
    show ExtensionArtistScreen, ExtensionAlbumScreen;
import 'package:spotiflac_android/services/shell_navigation_service.dart';
import 'package:spotiflac_android/utils/artist_utils.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('ClickableMetadata');

/// Navigate to an artist screen by searching Deezer for the artist ID.
///
/// If [artistId] is provided and valid, navigates directly.
/// Otherwise, searches Deezer by [artistName] to resolve the ID first.
/// For extension-based content, pass [extensionId] to use ExtensionArtistScreen.
Future<void> navigateToArtist(
  BuildContext context, {
  required String artistName,
  String? artistId,
  String? coverUrl,
  String? extensionId,
}) async {
  if (artistName.isEmpty) return;

  final normalizedArtistId = _normalizeArtistId(artistId);

  // If we have a valid artist ID already, navigate directly
  if (normalizedArtistId != null &&
      _canNavigateArtistDirectly(
        artistId: normalizedArtistId,
        extensionId: extensionId,
      )) {
    _pushArtistScreen(
      context,
      artistId: normalizedArtistId,
      artistName: artistName,
      coverUrl: coverUrl,
      extensionId: extensionId,
    );
    return;
  }

  // Search Deezer to resolve the artist ID
  _showLoadingSnackBar(context, 'Looking up artist...');
  try {
    final results = await PlatformBridge.searchDeezerAll(
      artistName,
      trackLimit: 0,
      artistLimit: 3,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final artistList = results['artists'] as List<dynamic>? ?? [];
    if (artistList.isEmpty) {
      _showUnavailable(context, 'Artist');
      return;
    }

    // Find best match - prefer exact name match (case-insensitive)
    Map<String, dynamic>? bestMatch;
    final lowerName = artistName.toLowerCase().trim();
    for (final a in artistList) {
      if (a is Map<String, dynamic>) {
        final name = (a['name'] as String? ?? '').toLowerCase().trim();
        if (name == lowerName) {
          bestMatch = a;
          break;
        }
      }
    }
    bestMatch ??= artistList.first as Map<String, dynamic>;

    final resolvedId = bestMatch['id'] as String? ?? '';
    final resolvedName = bestMatch['name'] as String? ?? artistName;
    final resolvedImage = bestMatch['images'] as String?;

    if (resolvedId.isEmpty) {
      _showUnavailable(context, 'Artist');
      return;
    }

    if (!context.mounted) return;
    _pushArtistScreen(
      context,
      artistId: resolvedId,
      artistName: resolvedName,
      coverUrl: resolvedImage ?? coverUrl,
    );
  } catch (e) {
    _log.e('Failed to look up artist "$artistName": $e', e);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _showUnavailable(context, 'Artist');
  }
}

/// Navigate to an album screen by searching Deezer for the album ID.
///
/// If [albumId] is provided and valid, navigates directly.
/// Otherwise, searches Deezer by [albumName] (optionally with [artistName]) to resolve the ID.
/// For extension-based content, pass [extensionId] to use ExtensionAlbumScreen.
Future<void> navigateToAlbum(
  BuildContext context, {
  required String albumName,
  String? albumId,
  String? artistName,
  String? coverUrl,
  String? extensionId,
}) async {
  if (albumName.isEmpty) return;

  // If we have a valid album ID already, navigate directly
  if (albumId != null &&
      albumId.isNotEmpty &&
      albumId != 'unknown' &&
      albumId != 'deezer:unknown') {
    _pushAlbumScreen(
      context,
      albumId: albumId,
      albumName: albumName,
      coverUrl: coverUrl,
      extensionId: extensionId,
    );
    return;
  }

  // If it's extension-based content without an ID, can't search Deezer for it
  if (extensionId != null) {
    _showUnavailable(context, 'Album');
    return;
  }

  // Search Deezer to resolve the album ID
  _showLoadingSnackBar(context, 'Looking up album...');
  try {
    // Build search query: "albumName artistName" for better accuracy
    final query = artistName != null && artistName.isNotEmpty
        ? '$albumName $artistName'
        : albumName;

    final results = await PlatformBridge.searchDeezerAll(
      query,
      trackLimit: 0,
      artistLimit: 0,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final albumList = results['albums'] as List<dynamic>? ?? [];
    if (albumList.isEmpty) {
      _showUnavailable(context, 'Album');
      return;
    }

    // Find best match - prefer exact name match (case-insensitive)
    Map<String, dynamic>? bestMatch;
    final lowerName = albumName.toLowerCase().trim();
    for (final a in albumList) {
      if (a is Map<String, dynamic>) {
        final name = (a['name'] as String? ?? '').toLowerCase().trim();
        if (name == lowerName) {
          bestMatch = a;
          break;
        }
      }
    }
    bestMatch ??= albumList.first as Map<String, dynamic>;

    final resolvedId = bestMatch['id'] as String? ?? '';
    final resolvedName = bestMatch['name'] as String? ?? albumName;
    final resolvedImage = bestMatch['images'] as String?;

    if (resolvedId.isEmpty) {
      _showUnavailable(context, 'Album');
      return;
    }

    if (!context.mounted) return;
    _pushAlbumScreen(
      context,
      albumId: resolvedId,
      albumName: resolvedName,
      coverUrl: resolvedImage ?? coverUrl,
    );
  } catch (e) {
    _log.e('Failed to look up album "$albumName": $e', e);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _showUnavailable(context, 'Album');
  }
}

void _pushArtistScreen(
  BuildContext context, {
  required String artistId,
  required String artistName,
  String? coverUrl,
  String? extensionId,
}) {
  _pushViaPreferredNavigator(
    context,
    (context) => extensionId != null
        ? ExtensionArtistScreen(
            extensionId: extensionId,
            artistId: artistId,
            artistName: artistName,
            coverUrl: coverUrl,
          )
        : ArtistScreen(
            artistId: artistId,
            artistName: artistName,
            coverUrl: coverUrl,
          ),
  );
}

void _pushAlbumScreen(
  BuildContext context, {
  required String albumId,
  required String albumName,
  String? coverUrl,
  String? extensionId,
}) {
  _pushViaPreferredNavigator(
    context,
    (context) => extensionId != null
        ? ExtensionAlbumScreen(
            extensionId: extensionId,
            albumId: albumId,
            albumName: albumName,
            coverUrl: coverUrl,
          )
        : AlbumScreen(
            albumId: albumId,
            albumName: albumName,
            coverUrl: coverUrl,
            tracks: const [],
          ),
  );
}

void _pushViaPreferredNavigator(BuildContext context, WidgetBuilder builder) {
  final currentNavigator = Navigator.of(context);
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final activeTabNavigator = ShellNavigationService.activeTabNavigator();

  final shouldRouteToTabNavigator =
      identical(currentNavigator, rootNavigator) && activeTabNavigator != null;

  if (!shouldRouteToTabNavigator) {
    currentNavigator.push(MaterialPageRoute(builder: builder));
    return;
  }

  final currentRoute = ModalRoute.of(context);
  final shouldPopCurrentRoute =
      currentRoute != null && currentRoute.isFirst == false;

  if (shouldPopCurrentRoute && currentNavigator.canPop()) {
    currentNavigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!activeTabNavigator.mounted) return;
      activeTabNavigator.push(MaterialPageRoute(builder: builder));
    });
    return;
  }

  activeTabNavigator.push(MaterialPageRoute(builder: builder));
}

void _showLoadingSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(message),
        ],
      ),
      duration: const Duration(seconds: 10),
    ),
  );
}

void _showUnavailable(BuildContext context, String type) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$type information not available')));
}

/// A reusable widget that makes text tappable to navigate to an artist screen.
///
/// Wraps the text in a GestureDetector that, when tapped, looks up the artist
/// via Deezer search and navigates to the ArtistScreen.
class ClickableArtistName extends StatefulWidget {
  final String artistName;
  final String? artistId;
  final String? coverUrl;
  final String? extensionId;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const ClickableArtistName({
    super.key,
    required this.artistName,
    this.artistId,
    this.coverUrl,
    this.extensionId,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  State<ClickableArtistName> createState() => _ClickableArtistNameState();
}

class _ClickableArtistNameState extends State<ClickableArtistName> {
  List<_ArtistTapTarget> _artistTargets = const [];
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _rebuildArtistTargets();
  }

  @override
  void didUpdateWidget(covariant ClickableArtistName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artistName != widget.artistName ||
        oldWidget.artistId != widget.artistId ||
        oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.extensionId != widget.extensionId) {
      _rebuildArtistTargets();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _rebuildArtistTargets() {
    _disposeRecognizers();
    _artistTargets = _buildArtistTapTargets(widget.artistName, widget.artistId);
    if (_artistTargets.length <= 1) return;

    for (final target in _artistTargets) {
      final recognizer = TapGestureRecognizer()
        ..onTap = () => navigateToArtist(
          context,
          artistName: target.name,
          artistId: target.artistId,
          coverUrl: widget.coverUrl,
          extensionId: _extensionIdForTarget(target),
        );
      _recognizers.add(recognizer);
    }
  }

  String? _extensionIdForTarget(_ArtistTapTarget target) {
    if (widget.extensionId == null) return null;
    if (_artistTargets.length == 1) return widget.extensionId;
    return target.artistId != null ? widget.extensionId : null;
  }

  List<InlineSpan> _buildMultiArtistSpans() {
    final spans = <InlineSpan>[];
    for (var i = 0; i < _artistTargets.length; i++) {
      final target = _artistTargets[i];
      spans.add(
        TextSpan(
          text: target.name,
          style: widget.style,
          recognizer: _recognizers[i],
        ),
      );
      if (i < _artistTargets.length - 1) {
        spans.add(TextSpan(text: ', ', style: widget.style));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (_artistTargets.isEmpty) {
      return Text(
        widget.artistName,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
      );
    }

    if (_artistTargets.length == 1) {
      final target = _artistTargets.first;
      return GestureDetector(
        onTap: () => navigateToArtist(
          context,
          artistName: target.name,
          artistId: target.artistId,
          coverUrl: widget.coverUrl,
          extensionId: _extensionIdForTarget(target),
        ),
        child: Text(
          target.name,
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          textAlign: widget.textAlign,
        ),
      );
    }

    return Text.rich(
      TextSpan(style: widget.style, children: _buildMultiArtistSpans()),
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.clip,
      textAlign: widget.textAlign ?? TextAlign.start,
    );
  }
}

class _ArtistTapTarget {
  final String name;
  final String? artistId;

  const _ArtistTapTarget({required this.name, this.artistId});
}

List<_ArtistTapTarget> _buildArtistTapTargets(
  String rawArtistNames,
  String? rawArtistIds,
) {
  final parsedNames = splitArtistNames(rawArtistNames);
  if (parsedNames.isEmpty) return const [];

  final uniqueNames = <String>[];
  final seen = <String>{};
  for (final parsed in parsedNames) {
    final key = parsed.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (key.isEmpty || !seen.add(key)) continue;
    uniqueNames.add(parsed);
  }
  if (uniqueNames.isEmpty) return const [];

  if (uniqueNames.length == 1) {
    return [
      _ArtistTapTarget(
        name: uniqueNames.first,
        artistId: _normalizeArtistId(rawArtistIds),
      ),
    ];
  }

  final parsedIds = _parseArtistIds(rawArtistIds);
  if (parsedIds.length == uniqueNames.length) {
    return List<_ArtistTapTarget>.generate(
      uniqueNames.length,
      (index) => _ArtistTapTarget(
        name: uniqueNames[index],
        artistId: parsedIds[index],
      ),
      growable: false,
    );
  }

  return uniqueNames
      .map((name) => _ArtistTapTarget(name: name))
      .toList(growable: false);
}

List<String> _parseArtistIds(String? rawArtistIds) {
  final raw = rawArtistIds?.trim();
  if (raw == null || raw.isEmpty) return const [];

  final parsed = <String>[];
  for (final part in raw.split(RegExp(r'\s*,\s*'))) {
    final normalized = _normalizeArtistId(part);
    if (normalized != null) {
      parsed.add(normalized);
    }
  }
  return parsed;
}

String? _normalizeArtistId(String? artistId) {
  final id = artistId?.trim();
  if (id == null || id.isEmpty || id == 'unknown' || id == 'deezer:unknown') {
    return null;
  }
  return id;
}

bool _canNavigateArtistDirectly({
  required String artistId,
  required String? extensionId,
}) {
  if (extensionId != null) return true;
  if (artistId.startsWith('deezer:')) return true;
  return _spotifyArtistIdPattern.hasMatch(artistId);
}

final RegExp _spotifyArtistIdPattern = RegExp(r'^[A-Za-z0-9]{22}$');

/// A reusable widget that makes text tappable to navigate to an album screen.
///
/// Wraps the text in a GestureDetector that, when tapped, looks up the album
/// via Deezer search and navigates to the AlbumScreen.
class ClickableAlbumName extends StatelessWidget {
  final String albumName;
  final String? albumId;
  final String? artistName;
  final String? coverUrl;
  final String? extensionId;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const ClickableAlbumName({
    super.key,
    required this.albumName,
    this.albumId,
    this.artistName,
    this.coverUrl,
    this.extensionId,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateToAlbum(
        context,
        albumName: albumName,
        albumId: albumId,
        artistName: artistName,
        coverUrl: coverUrl,
        extensionId: extensionId,
      ),
      child: Text(
        albumName,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}
