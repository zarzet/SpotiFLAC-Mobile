import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/utils/artist_utils.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class OptionsSettingsPage extends ConsumerWidget {
  const OptionsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final extensionState = ref.watch(extensionProvider);
    final hasExtensions = extensionState.extensions.isNotEmpty;
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
                      context.l10n.optionsTitle,
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

            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.sectionSearchSource,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: const [
                  _MetadataSourceSelector(),
                  _DefaultSearchTabSelector(),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionDownload),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.sync,
                    title: context.l10n.optionsAutoFallback,
                    subtitle: context.l10n.optionsAutoFallbackSubtitle,
                    value: settings.autoFallback,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setAutoFallback(v),
                  ),
                  if (hasExtensions)
                    SettingsSwitchItem(
                      icon: Icons.extension,
                      title: context.l10n.optionsUseExtensionProviders,
                      subtitle: settings.useExtensionProviders
                          ? context.l10n.optionsUseExtensionProvidersOn
                          : context.l10n.optionsUseExtensionProvidersOff,
                      value: settings.useExtensionProviders,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setUseExtensionProviders(v),
                    ),
                  SettingsSwitchItem(
                    icon: Icons.sell_outlined,
                    title: 'Embed Metadata',
                    subtitle: settings.embedMetadata
                        ? 'Write metadata, cover art, and embedded lyrics to files'
                        : 'Disabled (advanced): skip all metadata embedding',
                    value: settings.embedMetadata,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setEmbedMetadata(v),
                    showDivider: settings.embedMetadata,
                  ),
                  if (settings.embedMetadata)
                    SettingsItem(
                      icon: Icons.people_alt_outlined,
                      title: context.l10n.optionsArtistTagMode,
                      subtitle: _getArtistTagModeLabel(
                        context,
                        settings.artistTagMode,
                      ),
                      onTap: () => _showArtistTagModePicker(
                        context,
                        ref,
                        settings.artistTagMode,
                      ),
                    ),
                  SettingsSwitchItem(
                    icon: Icons.image,
                    title: context.l10n.optionsMaxQualityCover,
                    subtitle: settings.embedMetadata
                        ? context.l10n.optionsMaxQualityCoverSubtitle
                        : 'Disabled when metadata embedding is off',
                    value: settings.maxQualityCover,
                    enabled: settings.embedMetadata,
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
                    enabled: settings.embedMetadata,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setEmbedReplayGain(v),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.sectionPerformance,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _ConcurrentDownloadsItem(
                    currentValue: settings.concurrentDownloads,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setConcurrentDownloads(v),
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionApp),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.extension,
                    title: context.l10n.optionsExtensionStore,
                    subtitle: context.l10n.optionsExtensionStoreSubtitle,
                    value: settings.showExtensionStore,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setShowExtensionStore(v),
                  ),
                  SettingsSwitchItem(
                    icon: Icons.system_update,
                    title: context.l10n.optionsCheckUpdates,
                    subtitle: context.l10n.optionsCheckUpdatesSubtitle,
                    value: settings.checkForUpdates,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setCheckForUpdates(v),
                  ),
                  _UpdateChannelSelector(
                    currentChannel: settings.updateChannel,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setUpdateChannel(v),
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionData),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.cleaning_services_outlined,
                    title: context.l10n.cleanupOrphanedDownloads,
                    subtitle: context.l10n.cleanupOrphanedDownloadsSubtitle,
                    onTap: () => _cleanupOrphanedDownloads(context, ref),
                  ),
                  SettingsItem(
                    icon: Icons.delete_forever,
                    title: context.l10n.optionsClearHistory,
                    subtitle: context.l10n.optionsClearHistorySubtitle,
                    onTap: () =>
                        _showClearHistoryDialog(context, ref, colorScheme),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionDebug),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.bug_report,
                    title: context.l10n.optionsDetailedLogging,
                    subtitle: settings.enableLogging
                        ? context.l10n.optionsDetailedLoggingOn
                        : context.l10n.optionsDetailedLoggingOff,
                    value: settings.enableLogging,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setEnableLogging(v),
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.optionsArtistTagModeDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
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
              subtitle: Text(
                context.l10n.optionsArtistTagModeSplitVorbisSubtitle,
              ),
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

  void _showClearHistoryDialog(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.dialogClearHistoryTitle),
        content: Text(context.l10n.dialogClearHistoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.dialogCancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.snackbarHistoryCleared)),
              );
            },
            child: Text(
              context.l10n.dialogClear,
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cleanupOrphanedDownloads(
    BuildContext context,
    WidgetRef ref,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(context.l10n.cleanupOrphanedDownloads),
          ],
        ),
      ),
    );

    try {
      final removed = await ref
          .read(downloadHistoryProvider.notifier)
          .cleanupOrphanedDownloads();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              removed > 0
                  ? context.l10n.cleanupOrphanedDownloadsResult(removed)
                  : context.l10n.cleanupOrphanedDownloadsNone,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.snackbarError(e.toString()))),
        );
      }
    }
  }
}

class _ConcurrentDownloadsItem extends StatelessWidget {
  final int currentValue;
  final ValueChanged<int> onChanged;
  const _ConcurrentDownloadsItem({
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.download_for_offline,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.optionsConcurrentDownloads,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentValue == 1
                          ? context.l10n.optionsConcurrentSequential
                          : context.l10n.optionsConcurrentParallel(
                              currentValue,
                            ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ConcurrentChip(
                label: '1',
                isSelected: currentValue == 1,
                onTap: () => onChanged(1),
              ),
              const SizedBox(width: 8),
              _ConcurrentChip(
                label: '2',
                isSelected: currentValue == 2,
                onTap: () => onChanged(2),
              ),
              const SizedBox(width: 8),
              _ConcurrentChip(
                label: '3',
                isSelected: currentValue == 3,
                onTap: () => onChanged(3),
              ),
              const SizedBox(width: 8),
              _ConcurrentChip(
                label: '4',
                isSelected: currentValue == 4,
                onTap: () => onChanged(4),
              ),
              const SizedBox(width: 8),
              _ConcurrentChip(
                label: '5',
                isSelected: currentValue == 5,
                onTap: () => onChanged(5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.optionsConcurrentWarning,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConcurrentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ConcurrentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unselectedColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHigh;

    return Expanded(
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : unselectedColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateChannelSelector extends StatelessWidget {
  final String currentChannel;
  final ValueChanged<String> onChanged;
  const _UpdateChannelSelector({
    required this.currentChannel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.new_releases,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.optionsUpdateChannel,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentChannel == 'preview'
                          ? context.l10n.optionsUpdateChannelPreview
                          : context.l10n.optionsUpdateChannelStable,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ChannelChip(
                label: context.l10n.channelStable,
                isSelected: currentChannel == 'stable',
                onTap: () => onChanged('stable'),
              ),
              const SizedBox(width: 8),
              _ChannelChip(
                label: context.l10n.channelPreview,
                isSelected: currentChannel == 'preview',
                onTap: () => onChanged('preview'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.optionsUpdateChannelWarning,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ChannelChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unselectedColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHigh;

    return Expanded(
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : unselectedColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataSourceSelector extends ConsumerWidget {
  const _MetadataSourceSelector();

  static const _builtInProviders = {'tidal': 'Tidal', 'qobuz': 'Qobuz'};

  Extension? _defaultSearchExtension(List<Extension> extensions) {
    return extensions
            .where(
              (ext) =>
                  ext.enabled &&
                  ext.hasCustomSearch &&
                  ext.searchBehavior?.primary == true,
            )
            .firstOrNull ??
        extensions
            .where((ext) => ext.enabled && ext.hasCustomSearch)
            .firstOrNull;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final extState = ref.watch(extensionProvider);

    final rawSearchProvider = settings.searchProvider?.trim() ?? '';
    final isValidBuiltIn = _builtInProviders.containsKey(rawSearchProvider);
    final primarySearchExtension = _defaultSearchExtension(extState.extensions);
    final defaultProviderTarget =
        primarySearchExtension?.displayName ?? 'Tidal';
    final defaultProviderLabel =
        '${context.l10n.extensionsHomeFeedAuto} ($defaultProviderTarget)';
    final searchProvider =
        isValidBuiltIn ||
            extState.extensions.any(
              (e) =>
                  e.enabled && e.hasCustomSearch && e.id == rawSearchProvider,
            )
        ? rawSearchProvider
        : '';
    final isBuiltIn = _builtInProviders.containsKey(searchProvider);

    Extension? activeExtension;
    if (searchProvider.isNotEmpty && !isBuiltIn) {
      activeExtension = extState.extensions
          .where((e) => e.id == searchProvider && e.enabled)
          .firstOrNull;
    }
    final hasNonDefaultProvider = isBuiltIn || activeExtension != null;

    String subtitle;
    if (isBuiltIn) {
      subtitle = 'Using ${_builtInProviders[searchProvider]}';
    } else if (activeExtension != null) {
      subtitle = context.l10n.optionsUsingExtension(
        activeExtension.displayName,
      );
    } else {
      subtitle = context.l10n.optionsPrimaryProviderSubtitle;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.optionsPrimaryProvider,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: hasNonDefaultProvider
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SourceChip(
                  icon: Icons.graphic_eq,
                  label: defaultProviderLabel,
                  isSelected: searchProvider.isEmpty,
                  onTap: () {
                    if (hasNonDefaultProvider) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSearchProvider(null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SourceChip(
                  icon: Icons.waves,
                  label: 'Tidal',
                  isSelected: searchProvider == 'tidal',
                  onTap: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setSearchProvider('tidal');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SourceChip(
                  icon: Icons.album,
                  label: 'Qobuz',
                  isSelected: searchProvider == 'qobuz',
                  onTap: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setSearchProvider('qobuz');
                  },
                ),
              ),
            ],
          ),
          if (activeExtension != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap $defaultProviderLabel to switch back from extension',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DefaultSearchTabSelector extends ConsumerWidget {
  const _DefaultSearchTabSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedTab = ref.watch(
      settingsProvider.select((s) => s.defaultSearchTab),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.optionsDefaultSearchTab,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.optionsDefaultSearchTabSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SourceChip(
                  icon: Icons.dashboard_outlined,
                  label: context.l10n.historyFilterAll,
                  isSelected: selectedTab == 'all',
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setDefaultSearchTab('all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SourceChip(
                  icon: Icons.music_note,
                  label: context.l10n.searchSongs,
                  isSelected: selectedTab == 'track',
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setDefaultSearchTab('track'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SourceChip(
                  icon: Icons.person,
                  label: context.l10n.searchArtists,
                  isSelected: selectedTab == 'artist',
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setDefaultSearchTab('artist'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SourceChip(
                  icon: Icons.album,
                  label: context.l10n.searchAlbums,
                  isSelected: selectedTab == 'album',
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setDefaultSearchTab('album'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SourceChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unselectedColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHigh;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : unselectedColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
