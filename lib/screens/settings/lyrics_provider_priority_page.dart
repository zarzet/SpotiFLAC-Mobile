import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/widgets/priority_settings_scaffold.dart';
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
    'spotify_api',
    'netease',
    'musixmatch',
    'apple_music',
    'qqmusic',
  ];

  late List<String> _enabledProviders;
  late List<String> _initialProviders;
  bool _hasChanges = false;

  List<String> get _disabledProviders =>
      _allProviderIds.where((id) => !_enabledProviders.contains(id)).toList();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _enabledProviders = List.from(settings.lyricsProviders);
    _initialProviders = List.from(settings.lyricsProviders);
  }

  void _markChanged() {
    final changed =
        _enabledProviders.length != _initialProviders.length ||
        !_enabledProviders.asMap().entries.every(
          (e) =>
              e.key < _initialProviders.length &&
              _initialProviders[e.key] == e.value,
        );
    setState(() => _hasChanges = changed);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _disabledProviders;

    return PrioritySettingsScaffold(
      hasChanges: _hasChanges,
      title: context.l10n.lyricsProvidersTitle,
      description: context.l10n.lyricsProvidersDescription,
      infoText: context.l10n.lyricsProvidersInfoText,
      onSave: _saveChanges,
      onConfirmDiscard: _confirmDiscard,
      slivers: [
        if (_enabledProviders.isNotEmpty)
          SliverToBoxAdapter(
            child: SettingsSectionHeader(
              title: context.l10n.lyricsProvidersEnabledSection(
                _enabledProviders.length,
              ),
            ),
          ),
        if (_enabledProviders.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverReorderableList(
              itemCount: _enabledProviders.length,
              itemBuilder: (context, index) {
                final id = _enabledProviders[index];
                final info = _getLyricsProviderInfo(id, context);
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
        if (disabled.isNotEmpty)
          SliverToBoxAdapter(
            child: SettingsSectionHeader(
              title: context.l10n.lyricsProvidersDisabledSection(
                disabled.length,
              ),
            ),
          ),
        if (disabled.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final id = disabled[index];
                final info = _getLyricsProviderInfo(id, context);
                return _DisabledProviderItem(
                  key: ValueKey(id),
                  providerId: id,
                  info: info,
                  onToggle: () => _enableProvider(id),
                );
              }, childCount: disabled.length),
            ),
          ),
      ],
    );
  }

  void _enableProvider(String id) {
    setState(() => _enabledProviders.add(id));
    _markChanged();
  }

  void _disableProvider(String id) {
    if (_enabledProviders.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.lyricsProvidersAtLeastOne),
        ),
      );
      return;
    }
    setState(() => _enabledProviders.remove(id));
    _markChanged();
  }

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
        SnackBar(content: Text(context.l10n.lyricsProvidersSaved)),
      );
    }
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.dialogDiscardChanges),
        content: Text(context.l10n.lyricsProvidersDiscardContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.dialogDiscard),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static _LyricsProviderInfo _getLyricsProviderInfo(
    String id,
    BuildContext context,
  ) {
    switch (id) {
      case 'spotify_api':
        return _LyricsProviderInfo(
          name: 'Spotify Lyrics API',
          description: context.l10n.lyricsProviderSpotifyApiDesc,
          icon: Icons.music_note_outlined,
        );
      case 'lrclib':
        return _LyricsProviderInfo(
          name: 'LRCLIB',
          description: context.l10n.lyricsProviderLrclibDesc,
          icon: Icons.subtitles_outlined,
        );
      case 'netease':
        return _LyricsProviderInfo(
          name: 'Netease',
          description: context.l10n.lyricsProviderNeteaseDesc,
          icon: Icons.cloud_outlined,
        );
      case 'musixmatch':
        return _LyricsProviderInfo(
          name: 'Musixmatch',
          description: context.l10n.lyricsProviderMusixmatchDesc,
          icon: Icons.translate,
        );
      case 'apple_music':
        return _LyricsProviderInfo(
          name: 'Apple Music',
          description: context.l10n.lyricsProviderAppleMusicDesc,
          icon: Icons.music_note,
        );
      case 'qqmusic':
        return _LyricsProviderInfo(
          name: 'QQ Music',
          description: context.l10n.lyricsProviderQqMusicDesc,
          icon: Icons.queue_music,
        );
      default:
        return _LyricsProviderInfo(
          name: id,
          description: context.l10n.lyricsProviderExtensionDesc,
          icon: Icons.extension,
        );
    }
  }
}

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
                Icon(info.icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        info.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: FittedBox(
                    child: Switch(value: true, onChanged: (_) => onToggle()),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.drag_handle, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Empty space aligned with numbered badge
                  const SizedBox(width: 28),
                  const SizedBox(width: 16),
                  Icon(info.icon, color: colorScheme.outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.name,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          info.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: FittedBox(
                      child: Switch(value: false, onChanged: (_) => onToggle()),
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
