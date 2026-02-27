import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/library_collections_provider.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';

Future<void> showAddTrackToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  return showAddTracksToPlaylistSheet(context, ref, [track]);
}

Future<void> showAddTracksToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  List<Track> tracks,
) async {
  if (tracks.isEmpty) return;

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _PlaylistPickerSheetContent(tracks: tracks);
    },
  );
}

class _PlaylistPickerSheetContent extends ConsumerStatefulWidget {
  final List<Track> tracks;

  const _PlaylistPickerSheetContent({required this.tracks});

  @override
  ConsumerState<_PlaylistPickerSheetContent> createState() =>
      _PlaylistPickerSheetContentState();
}

class _PlaylistPickerSheetContentState
    extends ConsumerState<_PlaylistPickerSheetContent> {
  final Set<String> _selectedPlaylistIds = {};
  final Set<String> _initialDisabledIds = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final playlists = ref.read(libraryCollectionsProvider).playlists;
      for (final playlist in playlists) {
        final alreadyInPlaylist =
            widget.tracks.every((t) => playlist.containsTrack(t));
        if (alreadyInPlaylist) {
          _initialDisabledIds.add(playlist.id);
          _selectedPlaylistIds.add(playlist.id);
        }
      }
      _initialized = true;
    }
  }

  void _handleDone() async {
    final notifier = ref.read(libraryCollectionsProvider.notifier);
    final idsToAdd = _selectedPlaylistIds.difference(_initialDisabledIds);
    final addedNames = <String>[];

    for (final playlistId in idsToAdd) {
      final playlist =
          ref.read(libraryCollectionsProvider).playlistById(playlistId);
      if (playlist != null) {
        addedNames.add(playlist.name);
      }
      await notifier.addTracksToPlaylist(playlistId, widget.tracks);
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    if (addedNames.isNotEmpty) {
      final name =
          addedNames.length == 1 ? addedNames.first : addedNames.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.collectionAddedToPlaylist(name)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(
      libraryCollectionsProvider.select((state) => state.playlists),
    );
    final notifier = ref.read(libraryCollectionsProvider.notifier);

    final String subtitle;
    if (widget.tracks.length == 1) {
      final track = widget.tracks.first;
      subtitle = '${track.name} • ${track.artistName}';
    } else {
      subtitle =
          '${widget.tracks.length} ${widget.tracks.length == 1 ? 'track' : 'tracks'}';
    }

    final idsToAdd = _selectedPlaylistIds.difference(_initialDisabledIds);
    final hasNewSelections = idsToAdd.isNotEmpty;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: Text(context.l10n.collectionAddToPlaylist),
            subtitle: Text(subtitle),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(context.l10n.collectionCreatePlaylist),
            onTap: () async {
              final name = await _promptPlaylistName(context);
              if (name == null || name.trim().isEmpty || !context.mounted) {
                return;
              }
              final playlistId = await notifier.createPlaylist(name.trim());
              await notifier.addTracksToPlaylist(playlistId, widget.tracks);
              setState(() {
                _initialDisabledIds.add(playlistId);
                _selectedPlaylistIds.add(playlistId);
              });
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.collectionAddedToPlaylist(name.trim())),
                ),
              );
            },
          ),
          if (playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Text(
                context.l10n.collectionNoPlaylistsYet,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final isAlreadyIn = _initialDisabledIds.contains(playlist.id);
                    final isSelected = _selectedPlaylistIds.contains(playlist.id);

                    return ListTile(
                      leading: _PlaylistPickerThumbnail(
                        playlist: playlist,
                        isSelected: isSelected,
                      ),
                      title: Text(playlist.name),
                      subtitle: Text(
                        context.l10n.collectionPlaylistTracks(
                          playlist.tracks.length,
                        ),
                      ),
                      enabled: !isAlreadyIn,
                      onTap: !isAlreadyIn
                          ? () {
                              setState(() {
                                if (isSelected) {
                                  _selectedPlaylistIds.remove(playlist.id);
                                } else {
                                  _selectedPlaylistIds.add(playlist.id);
                                }
                              });
                            }
                          : null,
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (hasNewSelections) {
                    _handleDone();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(context.l10n.dialogDone),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _promptPlaylistName(BuildContext context) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(dialogContext.l10n.collectionCreatePlaylist),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: dialogContext.l10n.collectionPlaylistNameHint,
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return dialogContext.l10n.collectionPlaylistNameRequired;
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(dialogContext).pop(controller.text.trim());
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(dialogContext).pop(controller.text.trim());
            },
            child: Text(dialogContext.l10n.actionCreate),
          ),
        ],
      );
    },
  );

  return result;
}

class _PlaylistPickerThumbnail extends StatelessWidget {
  final UserPlaylistCollection playlist;
  final bool isSelected;

  const _PlaylistPickerThumbnail({
    required this.playlist,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const double size = 48;
    final borderRadius = BorderRadius.circular(8);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: _buildCoverImage(colorScheme, size),
          ),
          if (isSelected) ...[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  borderRadius: borderRadius,
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 1.5),
                ),
                child: Icon(
                  Icons.check,
                  color: colorScheme.onPrimary,
                  size: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoverImage(ColorScheme colorScheme, double size) {
    final customCoverPath = playlist.coverImagePath;
    if (customCoverPath != null && customCoverPath.isNotEmpty) {
      return Image.file(
        File(customCoverPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _iconFallback(colorScheme, size),
      );
    }

    String? firstCoverUrl;
    for (final entry in playlist.tracks) {
      final coverUrl = entry.track.coverUrl;
      if (coverUrl != null && coverUrl.isNotEmpty) {
        firstCoverUrl = coverUrl;
        break;
      }
    }

    if (firstCoverUrl != null) {
      final isLocalPath =
          !firstCoverUrl.startsWith('http://') &&
          !firstCoverUrl.startsWith('https://');

      if (isLocalPath) {
        return Image.file(
          File(firstCoverUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _iconFallback(colorScheme, size),
        );
      }

      return CachedNetworkImage(
        imageUrl: firstCoverUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * 2).toInt(),
        cacheManager: CoverCacheManager.instance,
        placeholder: (_, _) => _iconFallback(colorScheme, size),
        errorWidget: (_, _, _) => _iconFallback(colorScheme, size),
      );
    }

    return _iconFallback(colorScheme, size);
  }

  Widget _iconFallback(ColorScheme colorScheme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.queue_music, color: colorScheme.onSurfaceVariant),
    );
  }
}
