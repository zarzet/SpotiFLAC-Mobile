import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as p;
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/playback_provider.dart';
import 'package:spotiflac_android/screens/queue_tab.dart'; // To use UnifiedLibraryItem

class _FolderEntry {
  final String name;
  final String path;
  final bool isFolder;
  final UnifiedLibraryItem? track;
  final List<UnifiedLibraryItem> descendantTracks;

  _FolderEntry({
    required this.name,
    required this.path,
    required this.isFolder,
    this.track,
    required this.descendantTracks,
  });
}

class UnifiedFolderScreen extends ConsumerStatefulWidget {
  final String folderName;
  final String folderPath;
  final List<UnifiedLibraryItem> tracks;

  const UnifiedFolderScreen({
    super.key,
    required this.folderName,
    required this.folderPath,
    required this.tracks,
  });

  @override
  ConsumerState<UnifiedFolderScreen> createState() =>
      _UnifiedFolderScreenState();
}

class _UnifiedFolderScreenState extends ConsumerState<UnifiedFolderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInAppBar = false;
  late List<_FolderEntry> _entries;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _calculateEntries();
  }

  void _calculateEntries() {
    final entriesMap = <String, _FolderEntry>{};
    final root = widget.folderPath;

    String safGetRelative(String path, String root) {
      if (path == root) return '.';
      if (!path.startsWith('content://')) {
        return p.relative(path, from: root);
      }

      try {
        final pathUri = Uri.parse(path);
        final rootUri = Uri.parse(root);

        final pathSegments = pathUri.pathSegments;
        final documentIdx = pathSegments.indexOf('document');
        if (documentIdx == -1 || documentIdx == pathSegments.length - 1) {
          return p.relative(path, from: root);
        }

        final fullDocId = Uri.decodeComponent(
          pathSegments.sublist(documentIdx + 1).join('/'),
        ).replaceAll(':', '/');

        // Extract root doc ID. Prefer document ID over tree ID if both exist.
        String rootDocId = '';
        final rootSegments = rootUri.pathSegments;
        final rootDocIdx = rootSegments.indexOf('document');
        final rootTreeIdx = rootSegments.indexOf('tree');

        if (rootDocIdx != -1 && rootDocIdx < rootSegments.length - 1) {
          rootDocId = Uri.decodeComponent(
            rootSegments.sublist(rootDocIdx + 1).join('/'),
          );
        } else if (rootTreeIdx != -1 && rootTreeIdx < rootSegments.length - 1) {
          rootDocId = Uri.decodeComponent(rootSegments[rootTreeIdx + 1]);
        }
        rootDocId = rootDocId.replaceAll(':', '/');

        if (fullDocId == rootDocId) return '.';
        if (fullDocId.startsWith('$rootDocId/')) {
          return fullDocId.substring(rootDocId.length + 1);
        } else if (fullDocId.startsWith(rootDocId)) {
          var relative = fullDocId.substring(rootDocId.length);
          if (relative.startsWith('/')) relative = relative.substring(1);
          return relative.isEmpty ? '.' : relative;
        }
      } catch (_) {}

      return p.relative(path, from: root);
    }

    String safJoin(String root, String segment) {
      if (!root.startsWith('content://')) return p.join(root, segment);
      try {
        final uri = Uri.parse(root);
        final segments = List<String>.from(uri.pathSegments);
        final documentIdx = segments.indexOf('document');
        final treeIdx = segments.indexOf('tree');

        if (documentIdx != -1) {
          if (documentIdx == segments.length - 1) {
            segments.add(Uri.encodeComponent(segment));
          } else {
            final docId = Uri.decodeComponent(segments[documentIdx + 1]);
            final newDocId = '$docId/$segment'.replaceAll('//', '/');
            segments[documentIdx + 1] = Uri.encodeComponent(newDocId);
          }
        } else if (treeIdx != -1 && treeIdx < segments.length - 1) {
          final treeId = Uri.decodeComponent(segments[treeIdx + 1]);
          final newDocId = '$treeId/$segment';
          segments.add('document');
          segments.add(Uri.encodeComponent(newDocId));
        }
        return uri.replace(pathSegments: segments).toString();
      } catch (_) {}
      return p.join(root, segment);
    }

    for (final item in widget.tracks) {
      try {
        final relative = safGetRelative(item.filePath, root);
        final parts = p.split(relative);

        if (parts.length == 1 && relative != '.') {
          // Direct track
          entriesMap[item.id] = _FolderEntry(
            name: item.trackName,
            path: item.filePath,
            isFolder: false,
            track: item,
            descendantTracks: [item],
          );
        } else if (parts.length > 1 || (parts.length == 1 && relative == '.')) {
          if (relative == '.') continue;

          // Subfolder
          final subfolderName = parts[0];
          if (subfolderName == 'document' || subfolderName == 'primary') {
            continue;
          }

          final subfolderPath = safJoin(root, subfolderName);
          if (entriesMap.containsKey(subfolderPath)) {
            entriesMap[subfolderPath]!.descendantTracks.add(item);
          } else {
            entriesMap[subfolderPath] = _FolderEntry(
              name: subfolderName,
              path: subfolderPath,
              isFolder: true,
              descendantTracks: [item],
            );
          }
        }
      } catch (_) {
        // Ignore
      }
    }

    _entries = entriesMap.values.toList();
    // Sort: folders first, then tracks
    _entries.sort((a, b) {
      if (a.isFolder != b.isFolder) {
        return a.isFolder ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final expandedHeight = _calculateExpandedHeight(context);
    final shouldShow =
        _scrollController.offset > (expandedHeight - kToolbarHeight - 20);
    if (shouldShow != _showTitleInAppBar) {
      if (mounted) setState(() => _showTitleInAppBar = shouldShow);
    }
  }

  double _calculateExpandedHeight(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    return (mediaSize.height * 0.4).clamp(300.0, 400.0);
  }

  Track _toTrack(UnifiedLibraryItem item) {
    // If it's a local item, we can get more metadata from localItem if present
    final local = item.localItem;
    return Track(
      id: item.id,
      name: item.trackName,
      artistName: item.artistName,
      albumName: item.albumName,
      albumArtist: local?.albumArtist,
      duration: local?.duration ?? 0,
      trackNumber: local?.trackNumber,
      discNumber: local?.discNumber,
      releaseDate: local?.releaseDate,
      coverUrl: item.localCoverPath ?? item.coverUrl,
      source: 'local',
    );
  }

  void _playAll({bool shuffle = false}) {
    // Collect all tracks recursively
    final tracksToPlay = widget.tracks.map(_toTrack).toList();
    if (shuffle) {
      tracksToPlay.shuffle();
    } else {
      // Sort alphabetically by name
      tracksToPlay.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    final playbackService = ref.read(playbackProvider.notifier);
    playbackService.setShuffle(shuffle);
    playbackService.playTrackList(tracksToPlay);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final expandedHeight = _calculateExpandedHeight(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showTitleInAppBar ? 1.0 : 0.0,
              child: Text(
                widget.folderName,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.folder,
                        size: 80,
                        color: colorScheme.primary.withAlpha(128),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _showTitleInAppBar ? 0.0 : 1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.folderName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          Text(
                            '${widget.tracks.length} tracks',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              stretchModes: const [StretchMode.zoomBackground],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _playAll(shuffle: false),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _playAll(shuffle: true),
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Shuffle'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = _entries[index];
                if (entry.isFolder) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.folder,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    title: Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${entry.descendantTracks.length} tracks',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UnifiedFolderScreen(
                            folderName: entry.name,
                            folderPath: entry.path,
                            tracks: entry.descendantTracks,
                          ),
                        ),
                      );
                    },
                  );
                }

                final track = entry.track!;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: colorScheme.surfaceContainerHighest,
                      child:
                          track.localCoverPath != null &&
                              track.localCoverPath!.isNotEmpty
                          ? Image.file(
                              File(track.localCoverPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Icon(
                                      Icons.music_note,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                            )
                          : (track.coverUrl != null &&
                                track.coverUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: track.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.music_note,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.music_note,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    track.trackName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    track.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  onTap: () {
                    // Sort all tracks in this folder alphabetically
                    final allTracks = widget.tracks.map(_toTrack).toList();
                    allTracks.sort(
                      (a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    );

                    // Find index of clicked track
                    final startIndex = allTracks.indexWhere(
                      (t) => t.id == track.id,
                    );

                    ref
                        .read(playbackProvider.notifier)
                        .playTrackList(
                          allTracks,
                          startIndex: startIndex >= 0 ? startIndex : 0,
                        );
                  },
                );
              }, childCount: _entries.length),
            ),
          ),
        ],
      ),
    );
  }
}
