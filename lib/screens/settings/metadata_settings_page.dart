import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/utils/artist_utils.dart';
import 'package:spotiflac_android/screens/settings/metadata_provider_priority_page.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class MetadataSettingsPage extends ConsumerWidget {
  const MetadataSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);

    return PopScope(
      canPop: true,
      child: Scaffold(
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
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                    titlePadding: EdgeInsets.only(
                      left: leftPadding,
                      bottom: 16,
                    ),
                    title: Text(
                      context.l10n.settingsMetadata,
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

            // ── Embedding ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionDownload),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.sell_outlined,
                    title: 'Embed Metadata',
                    subtitle: settings.embedMetadata
                        ? 'Write metadata, cover art, and lyrics to files'
                        : 'Disabled (advanced): skip all metadata embedding',
                    value: settings.embedMetadata,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setEmbedMetadata(v),
                    showDivider: settings.embedMetadata,
                  ),
                  if (settings.embedMetadata) ...[
                    SettingsItem(
                      icon: Icons.people_alt_outlined,
                      title: context.l10n.optionsArtistTagMode,
                      subtitle: _getArtistTagModeLabel(
                        context,
                        settings.artistTagMode,
                      ),
                      onTap: () =>
                          _showArtistTagModePicker(context, ref, settings.artistTagMode),
                    ),
                    SettingsSwitchItem(
                      icon: Icons.image,
                      title: context.l10n.optionsMaxQualityCover,
                      subtitle: context.l10n.optionsMaxQualityCoverSubtitle,
                      value: settings.maxQualityCover,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setMaxQualityCover(v),
                    ),
                    SettingsSwitchItem(
                      icon: Icons.graphic_eq,
                      title: context.l10n.optionsReplayGain,
                      subtitle: settings.embedReplayGain
                          ? context.l10n.optionsReplayGainSubtitleOn
                          : context.l10n.optionsReplayGainSubtitleOff,
                      value: settings.embedReplayGain,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setEmbedReplayGain(v),
                      showDivider: false,
                    ),
                  ],
                ],
              ),
            ),

            // ── Providers ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.sectionMetadataProviders,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.source_outlined,
                    title: context.l10n.metadataProvidersTitle,
                    subtitle: context.l10n.metadataProvidersSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const MetadataProviderPriorityPage(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            // ── Deduplication ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.sectionDuplicates,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.filter_list_outlined,
                    title: context.l10n.downloadDeduplication,
                    subtitle: settings.deduplicateDownloads
                        ? context.l10n.downloadDeduplicationEnabled
                        : context.l10n.downloadDeduplicationDisabled,
                    value: settings.deduplicateDownloads,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setDeduplicateDownloads(value),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _getArtistTagModeLabel(BuildContext context, String mode) {
    switch (mode) {
      case artistTagModeSplitVorbis:
        return context.l10n.optionsArtistTagModeSplitVorbis;
      default:
        return context.l10n.optionsArtistTagModeJoined;
    }
  }

  void _showArtistTagModePicker(
    BuildContext context,
    WidgetRef ref,
    String currentMode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                context.l10n.optionsArtistTagMode,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.optionsArtistTagModeDescription,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.segment_outlined),
              title: Text(context.l10n.optionsArtistTagModeJoined),
              subtitle: Text(context.l10n.optionsArtistTagModeJoinedSubtitle),
              trailing: currentMode == artistTagModeJoined
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setArtistTagMode(artistTagModeJoined);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_music_outlined),
              title: Text(context.l10n.optionsArtistTagModeSplitVorbis),
              subtitle: Text(context.l10n.optionsArtistTagModeSplitVorbisSubtitle),
              trailing: currentMode == artistTagModeSplitVorbis
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setArtistTagMode(artistTagModeSplitVorbis);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
