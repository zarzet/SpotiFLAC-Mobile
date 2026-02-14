import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class LyricsProviderPriorityPage extends ConsumerStatefulWidget {
  const LyricsProviderPriorityPage({super.key});

  @override
  ConsumerState<LyricsProviderPriorityPage> createState() =>
      _LyricsProviderPriorityPageState();
}

class _LyricsProviderPriorityPageState
    extends ConsumerState<LyricsProviderPriorityPage> {
  static const _allProviderIds = [
    'lrclib',
    'netease',
    'musixmatch',
    'apple_music',
    'qqmusic',
  ];

  late List<String> _enabledProviders;
  late List<String> _initialProviders;
  bool _hasChanges = false;

  List<String> get _disabledProviders => _allProviderIds
      .where((id) => !_enabledProviders.contains(id))
      .toList();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _enabledProviders = List.from(settings.lyricsProviders);
    _initialProviders = List.from(settings.lyricsProviders);
  }

  void _markChanged() {
    final changed = _enabledProviders.length != _initialProviders.length ||
        !_enabledProviders
            .asMap()
            .entries
            .every((e) =>
                e.key < _initialProviders.length &&
                _initialProviders[e.key] == e.value);
    setState(() => _hasChanges = changed);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);
    final disabled = _disabledProviders;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard(context);
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // ── Collapsing App Bar ──
            SliverAppBar(
              expandedHeight: 120 + topPadding,
              collapsedHeight: kToolbarHeight,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (_hasChanges) {
                    final shouldPop = await _confirmDiscard(context);
                    if (shouldPop && context.mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              actions: [
                if (_hasChanges)
                  TextButton(
                    onPressed: _saveChanges,
                    child: const Text('Save'),
                  ),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = 120 + topPadding;
                  final minHeight = kToolbarHeight + topPadding;
                  final expandRatio = ((constraints.maxHeight - minHeight) /
                          (maxHeight - minHeight))
                      .clamp(0.0, 1.0);
                  final leftPadding = 56 - (32 * expandRatio);
                  return FlexibleSpaceBar(
                    expandedTitleScale: 1.0,
                    titlePadding:
                        EdgeInsets.only(left: leftPadding, bottom: 16),
                    title: Text(
                      'Lyrics Providers',
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

            // ── Description ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'Enable, disable and reorder lyrics sources. '
                  'Providers are tried top-to-bottom until lyrics are found.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),

            // ── Enabled section header ──
            if (_enabledProviders.isNotEmpty)
              SliverToBoxAdapter(
                child: SettingsSectionHeader(
                  title: 'Enabled (${_enabledProviders.length})',
                ),
              ),

            // ── Reorderable enabled list ──
            if (_enabledProviders.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverReorderableList(
                  itemCount: _enabledProviders.length,
                  itemBuilder: (context, index) {
                    final id = _enabledProviders[index];
                    final info = _getLyricsProviderInfo(id);
                    return _EnabledProviderItem(
                      key: ValueKey(id),
                      providerId: id,
                      info: info,
                      index: index,
                      isFirst: index == 0,
                      onToggle: () => _disableProvider(id),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _enabledProviders.removeAt(oldIndex);
                      _enabledProviders.insert(newIndex, item);
                    });
                    _markChanged();
                  },
                ),
              ),

            // ── Disabled section header ──
            if (disabled.isNotEmpty)
              SliverToBoxAdapter(
                child: SettingsSectionHeader(
                  title: 'Disabled (${disabled.length})',
                ),
              ),

            // ── Disabled list ──
            if (disabled.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final id = disabled[index];
                      final info = _getLyricsProviderInfo(id);
                      return _DisabledProviderItem(
                        key: ValueKey(id),
                        providerId: id,
                        info: info,
                        onToggle: () => _enableProvider(id),
                      );
                    },
                    childCount: disabled.length,
                  ),
                ),
              ),

            // ── Info banner ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: colorScheme.tertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Extension lyrics providers always run before '
                          'built-in providers. At least one provider must '
                          'remain enabled.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ── State mutations ──

  void _enableProvider(String id) {
    setState(() => _enabledProviders.add(id));
    _markChanged();
  }

  void _disableProvider(String id) {
    if (_enabledProviders.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one provider must remain enabled'),
        ),
      );
      return;
    }
    setState(() => _enabledProviders.remove(id));
    _markChanged();
  }

  // ── Save / Discard ──

  Future<void> _saveChanges() async {
    ref
        .read(settingsProvider.notifier)
        .setLyricsProviders(List<String>.from(_enabledProviders));
    setState(() {
      _initialProviders = List.from(_enabledProviders);
      _hasChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lyrics provider priority saved')),
      );
    }
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content:
            const Text('You have unsaved changes that will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Provider metadata ──

  static _LyricsProviderInfo _getLyricsProviderInfo(String id) {
    switch (id) {
      case 'lrclib':
        return _LyricsProviderInfo(
          name: 'LRCLIB',
          description: 'Open-source synced lyrics database',
          icon: Icons.subtitles_outlined,
        );
      case 'netease':
        return _LyricsProviderInfo(
          name: 'Netease',
          description: 'NetEase Cloud Music (good for Asian songs)',
          icon: Icons.cloud_outlined,
        );
      case 'musixmatch':
        return _LyricsProviderInfo(
          name: 'Musixmatch',
          description: 'Largest lyrics database (multi-language)',
          icon: Icons.translate,
        );
      case 'apple_music':
        return _LyricsProviderInfo(
          name: 'Apple Music',
          description: 'Word-by-word synced lyrics (via proxy)',
          icon: Icons.music_note,
        );
      case 'qqmusic':
        return _LyricsProviderInfo(
          name: 'QQ Music',
          description: 'QQ Music (good for Chinese songs, via proxy)',
          icon: Icons.queue_music,
        );
      default:
        return _LyricsProviderInfo(
          name: id,
          description: 'Extension provider',
          icon: Icons.extension,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Enabled provider card (reorderable)
// ═══════════════════════════════════════════════════════════════════════════

class _EnabledProviderItem extends StatelessWidget {
  final String providerId;
  final _LyricsProviderInfo info;
  final int index;
  final bool isFirst;
  final VoidCallback onToggle;

  const _EnabledProviderItem({
    super.key,
    required this.providerId,
    required this.info,
    required this.index,
    required this.isFirst,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHigh;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Numbered badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFirst
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Icon
                Icon(info.icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                // Name + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.name,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                      Text(
                        info.description,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
                // Enable/disable switch
                SizedBox(
                  height: 32,
                  child: FittedBox(
                    child: Switch(
                      value: true,
                      onChanged: (_) => onToggle(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Drag handle
                Icon(
                  Icons.drag_handle,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Disabled provider card
// ═══════════════════════════════════════════════════════════════════════════

class _DisabledProviderItem extends StatelessWidget {
  final String providerId;
  final _LyricsProviderInfo info;
  final VoidCallback onToggle;

  const _DisabledProviderItem({
    super.key,
    required this.providerId,
    required this.info,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.03),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerLow;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: 0.6,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Empty space aligned with numbered badge
                  const SizedBox(width: 28),
                  const SizedBox(width: 16),
                  // Icon (muted)
                  Icon(info.icon, color: colorScheme.outline),
                  const SizedBox(width: 12),
                  // Name + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          info.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Switch
                  SizedBox(
                    height: 32,
                    child: FittedBox(
                      child: Switch(
                        value: false,
                        onChanged: (_) => onToggle(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Provider info model
// ═══════════════════════════════════════════════════════════════════════════

class _LyricsProviderInfo {
  final String name;
  final String description;
  final IconData icon;

  const _LyricsProviderInfo({
    required this.name,
    required this.description,
    required this.icon,
  });
}
