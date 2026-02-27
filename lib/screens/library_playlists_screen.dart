import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/library_collections_provider.dart';
import 'package:spotiflac_android/screens/library_tracks_folder_screen.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';

class LibraryPlaylistsScreen extends ConsumerWidget {
  const LibraryPlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(
      libraryCollectionsProvider.select((state) => state.playlists),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120 + topPadding,
            collapsedHeight: kToolbarHeight,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),

            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = 120 + topPadding;
                final minHeight = kToolbarHeight + topPadding;
                final expandRatio =
                    ((constraints.maxHeight - minHeight) /
                            (maxHeight - minHeight))
                        .clamp(0.0, 1.0);
                final leftPadding = 56 - (32 * expandRatio);

                return FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  titlePadding: EdgeInsets.only(left: leftPadding, bottom: 16),
                  title: Text(
                    context.l10n.collectionPlaylists,
                    style: TextStyle(
                      fontSize: 20 + (8 * expandRatio),
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),
          if (playlists.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.playlist_play,
                        size: 60,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.collectionNoPlaylistsYet,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.collectionNoPlaylistsSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                // Even indices = playlist tiles, odd indices = dividers
                if (index.isOdd) {
                  return const Divider(height: 1);
                }
                final playlistIndex = index ~/ 2;
                final playlist = playlists[playlistIndex];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  leading: _buildPlaylistThumbnail(context, playlist),
                  title: Text(playlist.name),
                  subtitle: Text(
                    context.l10n.collectionPlaylistTracks(
                      playlist.tracks.length,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LibraryTracksFolderScreen(
                          mode: LibraryTracksFolderMode.playlist,
                          playlistId: playlist.id,
                        ),
                      ),
                    );
                  },
                  onLongPress: () =>
                      _showPlaylistOptionsSheet(context, ref, playlist),
                );
              }, childCount: playlists.length * 2 - 1),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlaylistDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.collectionCreatePlaylist),
      ),
    );
  }

  void _showPlaylistOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    UserPlaylistCollection playlist,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: drag handle + thumbnail + playlist info
            Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      _buildPlaylistThumbnail(context, playlist),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.collectionPlaylistTracks(
                                playlist.tracks.length,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),

            // Rename
            _PlaylistOptionTile(
              icon: Icons.edit_outlined,
              title: context.l10n.collectionRenamePlaylist,
              onTap: () {
                Navigator.pop(sheetContext);
                _showRenamePlaylistDialog(
                  context,
                  ref,
                  playlist.id,
                  playlist.name,
                );
              },
            ),

            // Change cover
            _PlaylistOptionTile(
              icon: Icons.image_outlined,
              title: context.l10n.collectionPlaylistChangeCover,
              onTap: () {
                Navigator.pop(sheetContext);
                _pickCoverImage(context, ref, playlist.id);
              },
            ),

            // Delete
            _PlaylistOptionTile(
              icon: Icons.delete_outline,
              iconColor: colorScheme.error,
              title: context.l10n.collectionDeletePlaylist,
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeletePlaylist(
                  context,
                  ref,
                  playlist.id,
                  playlist.name,
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistThumbnail(
    BuildContext context,
    UserPlaylistCollection playlist,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    const double size = 48;
    final borderRadius = BorderRadius.circular(8);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (size * dpr).round().clamp(64, 512);
    final placeholder = _playlistIconFallback(colorScheme, size);

    // Priority: custom cover > first track cover URL > icon fallback
    final customCoverPath = playlist.coverImagePath;
    if (customCoverPath != null && customCoverPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.file(
          File(customCoverPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
          filterQuality: FilterQuality.low,
          frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return placeholder;
          },
          errorBuilder: (_, _, _) => placeholder,
        ),
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
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.file(
            File(firstCoverUrl),
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) return child;
              return placeholder;
            },
            errorBuilder: (_, _, _) => placeholder,
          ),
        );
      }

      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: firstCoverUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: cacheWidth,
          cacheManager: CoverCacheManager.instance,
          placeholder: (_, _) => placeholder,
          errorWidget: (_, _, _) => placeholder,
        ),
      );
    }

    return placeholder;
  }

  Widget _playlistIconFallback(ColorScheme colorScheme, double size) {
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

  Future<void> _pickCoverImage(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null || path.isEmpty) return;

    await ref
        .read(libraryCollectionsProvider.notifier)
        .setPlaylistCover(playlistId, path);
  }

  Future<void> _showCreatePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final playlistName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.l10n.collectionCreatePlaylist),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
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

    if (playlistName == null ||
        playlistName.trim().isEmpty ||
        !context.mounted) {
      return;
    }

    await ref
        .read(libraryCollectionsProvider.notifier)
        .createPlaylist(playlistName.trim());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.collectionPlaylistCreated)),
    );
  }

  Future<void> _showRenamePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final nextName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.l10n.collectionRenamePlaylist),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
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
              child: Text(dialogContext.l10n.dialogSave),
            ),
          ],
        );
      },
    );

    if (nextName == null || nextName.trim().isEmpty || !context.mounted) {
      return;
    }

    await ref
        .read(libraryCollectionsProvider.notifier)
        .renamePlaylist(playlistId, nextName.trim());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.collectionPlaylistRenamed)),
    );
  }

  Future<void> _confirmDeletePlaylist(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
    String playlistName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.l10n.collectionDeletePlaylist),
          content: Text(
            dialogContext.l10n.collectionDeletePlaylistMessage(playlistName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogContext.l10n.dialogDelete),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await ref
        .read(libraryCollectionsProvider.notifier)
        .deletePlaylist(playlistId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.collectionPlaylistDeleted)),
    );
  }
}

/// Styled like _OptionTile in track_collection_quick_actions.dart
class _PlaylistOptionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final VoidCallback onTap;

  const _PlaylistOptionTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
