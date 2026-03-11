import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/widgets/priority_settings_scaffold.dart';

class MetadataProviderPriorityPage extends ConsumerStatefulWidget {
  const MetadataProviderPriorityPage({super.key});

  @override
  ConsumerState<MetadataProviderPriorityPage> createState() =>
      _MetadataProviderPriorityPageState();
}

class _MetadataProviderPriorityPageState
    extends ConsumerState<MetadataProviderPriorityPage> {
  late List<String> _providers;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  void _loadProviders() {
    final extState = ref.read(extensionProvider);
    final allProviders = ref
        .read(extensionProvider.notifier)
        .getAllMetadataProviders();

    if (extState.metadataProviderPriority.isNotEmpty) {
      _providers = List.from(extState.metadataProviderPriority);
      for (final provider in allProviders) {
        if (!_providers.contains(provider)) {
          _providers.add(provider);
        }
      }
      _providers.removeWhere((p) => !allProviders.contains(p));
    } else {
      _providers = allProviders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrioritySettingsScaffold(
      hasChanges: _hasChanges,
      title: context.l10n.metadataProviderPriorityTitle,
      description: context.l10n.metadataProviderPriorityDescription,
      descriptionPadding: const EdgeInsets.all(16),
      infoText: context.l10n.metadataProviderPriorityInfo,
      saveLabel: context.l10n.dialogSave,
      onSave: _saveChanges,
      onConfirmDiscard: _confirmDiscard,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverReorderableList(
            itemCount: _providers.length,
            itemBuilder: (context, index) {
              final provider = _providers[index];
              return _MetadataProviderItem(
                key: ValueKey(provider),
                provider: provider,
                index: index,
                isFirst: index == 0,
                isLast: index == _providers.length - 1,
              );
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _providers.removeAt(oldIndex);
                _providers.insert(newIndex, item);
                _hasChanges = true;
              });
            },
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.dialogDiscardChanges),
        content: Text(context.l10n.dialogUnsavedChanges),
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

  Future<void> _saveChanges() async {
    await ref
        .read(extensionProvider.notifier)
        .setMetadataProviderPriority(_providers);
    setState(() {
      _hasChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.snackbarMetadataProviderSaved)),
      );
    }
  }
}

class _MetadataProviderItem extends StatelessWidget {
  final String provider;
  final int index;
  final bool isFirst;
  final bool isLast;

  const _MetadataProviderItem({
    super.key,
    required this.provider,
    required this.index,
    required this.isFirst,
    required this.isLast,
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

    final info = _getProviderInfo(context, provider);

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
                Icon(
                  info.icon,
                  color: info.isBuiltIn
                      ? colorScheme.primary
                      : colorScheme.secondary,
                ),
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
                Icon(Icons.drag_handle, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _MetadataProviderInfo _getProviderInfo(
    BuildContext context,
    String provider,
  ) {
    switch (provider) {
      case 'deezer':
        return _MetadataProviderInfo(
          name: 'Deezer',
          icon: Icons.album,
          description: context.l10n.metadataNoRateLimits,
          isBuiltIn: true,
        );
      default:
        return _MetadataProviderInfo(
          name: provider,
          icon: Icons.extension,
          description: context.l10n.providerExtension,
          isBuiltIn: false,
        );
    }
  }
}

class _MetadataProviderInfo {
  final String name;
  final IconData icon;
  final String description;
  final bool isBuiltIn;

  _MetadataProviderInfo({
    required this.name,
    required this.icon,
    required this.description,
    required this.isBuiltIn,
  });
}
