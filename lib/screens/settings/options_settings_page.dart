import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      canPop: true,
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
                      'Options',
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
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Search Source'),
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
                                    'Spotify requires your own API credentials. Get them free from developer.spotify.com',
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
                      title: 'Spotify Credentials',
                      subtitle: settings.spotifyClientId.isNotEmpty
                          ? 'Client ID: ${settings.spotifyClientId.length > 8 ? '${settings.spotifyClientId.substring(0, 8)}...' : settings.spotifyClientId}'
                          : 'Required - tap to configure',
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
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Download'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.sync,
                    title: 'Auto Fallback',
                    subtitle: 'Try other services if download fails',
                    value: settings.autoFallback,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setAutoFallback(v),
                  ),
                  if (hasExtensions)
                    SettingsSwitchItem(
                      icon: Icons.extension,
                      title: 'Use Extension Providers',
                      subtitle: settings.useExtensionProviders
                          ? 'Extensions will be tried first'
                          : 'Using built-in providers only',
                      value: settings.useExtensionProviders,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setUseExtensionProviders(v),
                    ),
                  SettingsSwitchItem(
                    icon: Icons.lyrics,
                    title: 'Embed Lyrics',
                    subtitle: 'Embed synced lyrics into FLAC files',
                    value: settings.embedLyrics,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setEmbedLyrics(v),
                  ),
                  SettingsSwitchItem(
                    icon: Icons.image,
                    title: 'Max Quality Cover',
                    subtitle: 'Download highest resolution cover art',
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
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Performance'),
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
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'App'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.system_update,
                    title: 'Check for Updates',
                    subtitle: 'Notify when new version is available',
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
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Data'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.delete_forever,
                    title: 'Clear Download History',
                    subtitle: 'Remove all downloaded tracks from history',
                    onTap: () =>
                        _showClearHistoryDialog(context, ref, colorScheme),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            // Debug section
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Debug'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.bug_report,
                    title: 'Detailed Logging',
                    subtitle: settings.enableLogging
                        ? 'Detailed logs are being recorded'
                        : 'Enable for bug reports',
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
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all download history? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('History cleared')));
            },
            child: Text('Clear', style: TextStyle(color: colorScheme.error)),
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
                    'Spotify Credentials',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your Client ID and Secret to use your own Spotify application quota.',
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
                      labelText: 'Client ID',
                      hintText: 'Paste Client ID',
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
                      labelText: 'Client Secret',
                      hintText: 'Paste Client Secret',
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
                          const SnackBar(content: Text('Credentials saved')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
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
                    child: const Text(
                      'Save Credentials',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                          const SnackBar(content: Text('Credentials cleared')),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Remove Credentials'),
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
                      'Concurrent Downloads',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentValue == 1
                          ? 'Sequential (1 at a time)'
                          : '$currentValue parallel downloads',
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
                  'Parallel downloads may trigger rate limiting',
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
                      'Update Channel',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentChannel == 'preview'
                          ? 'Get preview releases'
                          : 'Stable releases only',
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
                label: 'Stable',
                isSelected: currentChannel == 'stable',
                onTap: () => onChanged('stable'),
              ),
              const SizedBox(width: 8),
              _ChannelChip(
                label: 'Preview',
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
                  'Preview may contain bugs or incomplete features',
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
    
    // Check if extension search provider is active
    final hasExtensionSearch = settings.searchProvider != null && 
        settings.searchProvider!.isNotEmpty;
    
    String? extensionName;
    if (hasExtensionSearch) {
      final ext = extState.extensions.where((e) => e.id == settings.searchProvider).firstOrNull;
      extensionName = ext?.displayName ?? settings.searchProvider;
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary Provider',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            hasExtensionSearch
                ? 'Using extension: $extensionName'
                : 'Service used when searching by track name.',
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
                badge: 'Free',
                badgeColor: colorScheme.tertiary,
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
                badge: 'API Key',
                badgeColor: colorScheme.secondary,
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
                    'Tap Deezer or Spotify to switch back from extension',
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
  final String? badge;
  final Color? badgeColor;

  const _SourceChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.badge,
    this.badgeColor,
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
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? colorScheme.tertiary).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: badgeColor ?? colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
