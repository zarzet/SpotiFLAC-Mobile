import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/settings.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class OptionsSettingsPage extends ConsumerWidget {
  const OptionsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final extensionState = ref.watch(extensionProvider);
    final hasExtensions = extensionState.extensions.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: true, // Always allow back gesture
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // Collapsing App Bar with back button
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
                final leftPadding = 56 - (32 * expandRatio); // 56 -> 24
                return FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  titlePadding: EdgeInsets.only(
                    left: leftPadding,
                    bottom: 16,
                  ),
                  title: Text(
                    context.l10n.optionsTitle,
                    style: TextStyle(
                      fontSize: 20 + (8 * expandRatio), // 20 -> 28
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),

            // Search Source section
            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionSearchSource),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _MetadataSourceSelector(
                    currentSource: settings.metadataSource,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setMetadataSource(v),
                  ),
                  if (settings.metadataSource == 'spotify') ...[
                    // Info card about Spotify credentials requirement
                    if (settings.spotifyClientId.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    context.l10n.optionsSpotifyWarning,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SettingsItem(
                      icon: Icons.key,
                      title: context.l10n.optionsSpotifyCredentials,
                      subtitle: settings.spotifyClientId.isNotEmpty
                          ? context.l10n.optionsSpotifyCredentialsConfigured(settings.spotifyClientId.length > 8 ? settings.spotifyClientId.substring(0, 8) : settings.spotifyClientId)
                          : context.l10n.optionsSpotifyCredentialsRequired,
                      onTap: () =>
                          _showSpotifyCredentialsDialog(context, ref, settings),
                      trailing: Icon(
                        settings.spotifyClientId.isNotEmpty
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: settings.spotifyClientId.isNotEmpty
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      showDivider: false,
                    ),
                  ],
                ],
              ),
            ),

            // Download options section
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
                    icon: Icons.lyrics,
                    title: context.l10n.optionsEmbedLyrics,
                    subtitle: context.l10n.optionsEmbedLyricsSubtitle,
                    value: settings.embedLyrics,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setEmbedLyrics(v),
                  ),
                  SettingsSwitchItem(
                    icon: Icons.image,
                    title: context.l10n.optionsMaxQualityCover,
                    subtitle: context.l10n.optionsMaxQualityCoverSubtitle,
                    value: settings.maxQualityCover,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setMaxQualityCover(v),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            // Performance section
            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionPerformance),
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

            // App section
            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionApp),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.store,
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

            // Data section
            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionData),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
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

            // Debug section
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

  void _showClearHistoryDialog(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.dialogClearHistoryTitle),
        content: Text(
          context.l10n.dialogClearHistoryMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.dialogCancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(context.l10n.snackbarHistoryCleared)));
            },
            child: Text(context.l10n.dialogClear, style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showSpotifyCredentialsDialog(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final clientIdController = TextEditingController(
      text: settings.spotifyClientId,
    );
    final clientSecretController = TextEditingController(
      text: settings.spotifyClientSecret,
    );
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.credentialsTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.credentialsDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Client ID
                  TextField(
                    controller: clientIdController,
                    decoration: InputDecoration(
                      labelText: context.l10n.credentialsClientId,
                      hintText: context.l10n.credentialsClientIdHint,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Client Secret
                  TextField(
                    controller: clientSecretController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.credentialsClientSecret,
                      hintText: context.l10n.credentialsClientSecretHint,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),

                  const SizedBox(height: 32),

                  FilledButton(
                    onPressed: () {
                      final clientId = clientIdController.text.trim();
                      final clientSecret = clientSecretController.text.trim();

                      if (clientId.isNotEmpty && clientSecret.isNotEmpty) {
                        ref
                            .read(settingsProvider.notifier)
                            .setSpotifyCredentials(clientId, clientSecret);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.snackbarCredentialsSaved)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.snackbarFillAllFields),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      context.l10n.actionSaveCredentials,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  if (settings.spotifyClientId.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(settingsProvider.notifier)
                            .clearSpotifyCredentials();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.snackbarCredentialsCleared)),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(context.l10n.actionRemoveCredentials),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
                          : context.l10n.optionsConcurrentParallel(currentValue),
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
  final String currentSource;
  final ValueChanged<String> onChanged;
  const _MetadataSourceSelector({
    required this.currentSource,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final extState = ref.watch(extensionProvider);
    
    // Check if extension search provider is active AND enabled
    Extension? activeExtension;
    if (settings.searchProvider != null && settings.searchProvider!.isNotEmpty) {
      activeExtension = extState.extensions
          .where((e) => e.id == settings.searchProvider && e.enabled)
          .firstOrNull;
    }
    final hasExtensionSearch = activeExtension != null;
    
    String? extensionName;
    if (hasExtensionSearch) {
      extensionName = activeExtension.displayName;
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
            hasExtensionSearch
                ? context.l10n.optionsUsingExtension(extensionName!)
                : context.l10n.optionsPrimaryProviderSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: hasExtensionSearch 
                  ? colorScheme.primary 
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SourceChip(
                icon: Icons.graphic_eq,
                label: 'Deezer',
                // Not selected if extension is active
                isSelected: currentSource == 'deezer' && !hasExtensionSearch,
                onTap: () {
                  // If extension was active, reset it to default
                  if (hasExtensionSearch) {
                    ref.read(settingsProvider.notifier).setSearchProvider(null);
                  }
                  onChanged('deezer');
                },
              ),
              const SizedBox(width: 12),
              _SourceChip(
                icon: Icons.music_note,
                label: 'Spotify',
                // Not selected if extension is active
                isSelected: currentSource == 'spotify' && !hasExtensionSearch,
                onTap: () {
                  // If extension was active, reset it to default
                  if (hasExtensionSearch) {
                    ref.read(settingsProvider.notifier).setSearchProvider(null);
                  }
                  onChanged('spotify');
                },
              ),
            ],
          ),
          if (hasExtensionSearch) ...[
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
                    context.l10n.optionsSwitchBack,
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

    return Expanded(
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : unselectedColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
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
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
