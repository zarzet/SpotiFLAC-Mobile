import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/widgets/download_service_picker.dart';
import 'package:spotiflac_android/utils/clickable_metadata.dart';

class TrackCollectionQuickActions extends ConsumerWidget {
  final Track track;

  const TrackCollectionQuickActions({super.key, required this.track});

  static void showTrackOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    Track track,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _TrackOptionsSheet(track: track),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      onPressed: () => showTrackOptionsSheet(context, ref, track),
      padding: const EdgeInsets.only(left: 12),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

class _TrackOptionsSheet extends ConsumerWidget {
  final Track track;

  const _TrackOptionsSheet({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final container = ProviderScope.containerOf(rootContext, listen: false);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with drag handle + track info (matches _TrackInfoHeader)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              track.coverUrl != null &&
                                  track.coverUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: track.coverUrl!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 112,
                                  cacheManager: CoverCacheManager.instance,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: 56,
                                        height: 56,
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.music_note,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.music_note,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              ClickableArtistName(
                                artistName: track.artistName,
                                artistId: track.artistId,
                                coverUrl: track.coverUrl,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

              // Action items (matches _QualityOption style)
              _OptionTile(
                icon: Icons.download_rounded,
                title: context.l10n.downloadTitle,
                onTap: () async {
                  Navigator.pop(context);
                  if (settings.askQualityBeforeDownload) {
                    DownloadServicePicker.show(
                      rootContext,
                      trackName: track.name,
                      artistName: track.artistName,
                      coverUrl: track.coverUrl,
                      onSelect: (quality, service) {
                        container
                            .read(downloadQueueProvider.notifier)
                            .addToQueue(
                              track,
                              service,
                              qualityOverride: quality,
                            );
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              rootContext.l10n.snackbarAddedToQueue(track.name),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    container
                        .read(downloadQueueProvider.notifier)
                        .addToQueue(track, settings.defaultService);
                    if (!rootContext.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          rootContext.l10n.snackbarAddedToQueue(track.name),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Styled like _QualityOption in download_service_picker.dart
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
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
        child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
