import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/models/settings.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class OptionsSettingsPage extends ConsumerWidget {
  const OptionsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
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
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = 120 + topPadding;
                final minHeight = kToolbarHeight + topPadding;
                final expandRatio = ((constraints.maxHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);
                final animation = AlwaysStoppedAnimation(expandRatio);
                return FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  titlePadding: EdgeInsets.zero,
                  title: SafeArea(
                    child: Container(
                      alignment: Alignment.bottomLeft,
                      padding: EdgeInsets.only(
                        left: Tween<double>(begin: 56, end: 24).evaluate(animation),
                        bottom: Tween<double>(begin: 16, end: 16).evaluate(animation),
                      ),
                      child: Text('Options',
                        style: TextStyle(
                          fontSize: Tween<double>(begin: 20, end: 28).evaluate(animation),
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Download options section
          const SliverToBoxAdapter(child: SettingsSectionHeader(title: 'Download')),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                SettingsSwitchItem(
                  icon: Icons.sync,
                  title: 'Auto Fallback',
                  subtitle: 'Try other services if download fails',
                  value: settings.autoFallback,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setAutoFallback(v),
                ),
                SettingsSwitchItem(
                  icon: Icons.lyrics,
                  title: 'Embed Lyrics',
                  subtitle: 'Embed synced lyrics into FLAC files',
                  value: settings.embedLyrics,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setEmbedLyrics(v),
                ),
                SettingsSwitchItem(
                  icon: Icons.image,
                  title: 'Max Quality Cover',
                  subtitle: 'Download highest resolution cover art',
                  value: settings.maxQualityCover,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setMaxQualityCover(v),
                  showDivider: false,
                ),
              ],
            ),
          ),

          // Performance section
          const SliverToBoxAdapter(child: SettingsSectionHeader(title: 'Performance')),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                _ConcurrentDownloadsItem(
                  currentValue: settings.concurrentDownloads,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setConcurrentDownloads(v),
                ),
              ],
            ),
          ),

          // App section
          const SliverToBoxAdapter(child: SettingsSectionHeader(title: 'App')),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                SettingsSwitchItem(
                  icon: Icons.system_update,
                  title: 'Check for Updates',
                  subtitle: 'Notify when new version is available',
                  value: settings.checkForUpdates,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setCheckForUpdates(v),
                  showDivider: false,
                ),
              ],
            ),
          ),

          // Spotify API section
          const SliverToBoxAdapter(child: SettingsSectionHeader(title: 'Spotify API')),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                SettingsItem(
                  icon: Icons.key,
                  title: 'Custom Credentials',
                  subtitle: settings.spotifyClientId.isNotEmpty 
                      ? 'Client ID: ${settings.spotifyClientId.length > 8 ? '${settings.spotifyClientId.substring(0, 8)}...' : settings.spotifyClientId}' 
                      : 'Not configured',
                  onTap: () => _showSpotifyCredentialsDialog(context, ref, settings),
                  trailing: settings.spotifyClientId.isNotEmpty
                      ? Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20)
                      : Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 20),
                  showDivider: settings.spotifyClientId.isNotEmpty,
                ),
                if (settings.spotifyClientId.isNotEmpty)
                  SettingsSwitchItem(
                    icon: Icons.toggle_on,
                    title: 'Use Custom Credentials',
                    subtitle: settings.useCustomSpotifyCredentials 
                        ? 'Using your credentials' 
                        : 'Using default credentials',
                    value: settings.useCustomSpotifyCredentials,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setUseCustomSpotifyCredentials(v),
                    showDivider: false,
                  ),
              ],
            ),
          ),

          // Data section
          const SliverToBoxAdapter(child: SettingsSectionHeader(title: 'Data')),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                SettingsItem(
                  icon: Icons.delete_forever,
                  title: 'Clear Download History',
                  subtitle: 'Remove all downloaded tracks from history',
                  onTap: () => _showClearHistoryDialog(context, ref, colorScheme),
                  showDivider: false,
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all download history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            child: Text('Clear', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showSpotifyCredentialsDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final clientIdController = TextEditingController(text: settings.spotifyClientId);
    final clientSecretController = TextEditingController(text: settings.spotifyClientSecret);
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Text('Spotify API Credentials', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    'Use your own credentials to avoid rate limiting.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: clientIdController,
                    decoration: InputDecoration(
                      labelText: 'Client ID',
                      hintText: 'Enter Spotify Client ID',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: clientSecretController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Client Secret',
                      hintText: 'Enter Spotify Client Secret',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      if (settings.spotifyClientId.isNotEmpty)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ref.read(settingsProvider.notifier).clearSpotifyCredentials();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Credentials cleared')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: const Text('Clear'),
                          ),
                        ),
                      if (settings.spotifyClientId.isNotEmpty) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final clientId = clientIdController.text.trim();
                            final clientSecret = clientSecretController.text.trim();
                            
                            if (clientId.isNotEmpty && clientSecret.isNotEmpty) {
                              ref.read(settingsProvider.notifier).setSpotifyCredentials(clientId, clientSecret);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Credentials saved')),
                              );
                            } else if (clientId.isEmpty && clientSecret.isEmpty) {
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill both Client ID and Secret')),
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
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

class _ConcurrentDownloadsItem extends StatelessWidget {
  final int currentValue;
  final ValueChanged<int> onChanged;
  const _ConcurrentDownloadsItem({required this.currentValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.download_for_offline, color: colorScheme.onSurfaceVariant, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Concurrent Downloads', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 2),
            Text(currentValue == 1 ? 'Sequential (1 at a time)' : '$currentValue parallel downloads',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _ConcurrentChip(label: '1', isSelected: currentValue == 1, onTap: () => onChanged(1)),
          const SizedBox(width: 8),
          _ConcurrentChip(label: '2', isSelected: currentValue == 2, onTap: () => onChanged(2)),
          const SizedBox(width: 8),
          _ConcurrentChip(label: '3', isSelected: currentValue == 3, onTap: () => onChanged(3)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text('Parallel downloads may trigger rate limiting',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.error))),
        ]),
      ]),
    );
  }
}

class _ConcurrentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ConcurrentChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final unselectedColor = isDark 
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), colorScheme.surface)
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
            child: Center(child: Text(label, style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant))),
          ),
        ),
      ),
    );
  }
}
