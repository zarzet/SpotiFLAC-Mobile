import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';

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
                        bottom: Tween<double>(begin: 12, end: 16).evaluate(animation),
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
          SliverToBoxAdapter(child: _SectionHeader(title: 'Download')),
          SliverList(delegate: SliverChildListDelegate([
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              secondary: Icon(Icons.sync, color: colorScheme.onSurfaceVariant),
              title: const Text('Auto Fallback'),
              subtitle: const Text('Try other services if download fails'),
              value: settings.autoFallback,
              onChanged: (v) => ref.read(settingsProvider.notifier).setAutoFallback(v),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              secondary: Icon(Icons.lyrics, color: colorScheme.onSurfaceVariant),
              title: const Text('Embed Lyrics'),
              subtitle: const Text('Embed synced lyrics into FLAC files'),
              value: settings.embedLyrics,
              onChanged: (v) => ref.read(settingsProvider.notifier).setEmbedLyrics(v),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              secondary: Icon(Icons.image, color: colorScheme.onSurfaceVariant),
              title: const Text('Max Quality Cover'),
              subtitle: const Text('Download highest resolution cover art'),
              value: settings.maxQualityCover,
              onChanged: (v) => ref.read(settingsProvider.notifier).setMaxQualityCover(v),
            ),
          ])),

          // Performance section
          SliverToBoxAdapter(child: _SectionHeader(title: 'Performance')),
          SliverToBoxAdapter(
            child: _ConcurrentDownloadsSelector(
              currentValue: settings.concurrentDownloads,
              onChanged: (v) => ref.read(settingsProvider.notifier).setConcurrentDownloads(v),
            ),
          ),

          // Lyrics section
          SliverToBoxAdapter(child: _SectionHeader(title: 'Lyrics')),
          SliverList(delegate: SliverChildListDelegate([
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              secondary: Icon(Icons.translate, color: colorScheme.onSurfaceVariant),
              title: const Text('Convert Japanese to Romaji'),
              subtitle: const Text('Auto-convert Hiragana/Katakana lyrics'),
              value: settings.convertLyricsToRomaji,
              onChanged: (v) => ref.read(settingsProvider.notifier).setConvertLyricsToRomaji(v),
            ),
          ])),

          // App section
          SliverToBoxAdapter(child: _SectionHeader(title: 'App')),
          SliverToBoxAdapter(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              secondary: Icon(Icons.system_update, color: colorScheme.onSurfaceVariant),
              title: const Text('Check for Updates'),
              subtitle: const Text('Notify when new version is available'),
              value: settings.checkForUpdates,
              onChanged: (v) => ref.read(settingsProvider.notifier).setCheckForUpdates(v),
            ),
          ),

          // Data section
          SliverToBoxAdapter(child: _SectionHeader(title: 'Data')),
          SliverToBoxAdapter(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(Icons.delete_forever, color: colorScheme.error),
              title: const Text('Clear Download History'),
              subtitle: const Text('Remove all downloaded tracks from history'),
              onTap: () => _showClearHistoryDialog(context, ref, colorScheme),
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
  );
}

class _ConcurrentDownloadsSelector extends StatelessWidget {
  final int currentValue;
  final ValueChanged<int> onChanged;
  const _ConcurrentDownloadsSelector({required this.currentValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.download_for_offline, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Concurrent Downloads'),
            Text(currentValue == 1 ? 'Sequential (1 at a time)' : '$currentValue parallel downloads',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
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
    return Expanded(
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
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
