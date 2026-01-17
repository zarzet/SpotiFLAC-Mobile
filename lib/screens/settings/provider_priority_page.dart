import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';

class ProviderPriorityPage extends ConsumerStatefulWidget {
  const ProviderPriorityPage({super.key});

  @override
  ConsumerState<ProviderPriorityPage> createState() => _ProviderPriorityPageState();
}

class _ProviderPriorityPageState extends ConsumerState<ProviderPriorityPage> {
  late List<String> _providers;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  void _loadProviders() {
    final extState = ref.read(extensionProvider);
    final allProviders = ref.read(extensionProvider.notifier).getAllDownloadProviders();
    
    if (extState.providerPriority.isNotEmpty) {
      _providers = List.from(extState.providerPriority);
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
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

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
                    child: Text(context.l10n.dialogSave),
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
                    titlePadding: EdgeInsets.only(left: leftPadding, bottom: 16),
                    title: Text(
                      context.l10n.providerPriorityTitle,
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.providerPriorityDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverReorderableList(
                itemCount: _providers.length,
                itemBuilder: (context, index) {
                  final provider = _providers[index];
                  return _ProviderItem(
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

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: colorScheme.tertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.l10n.providerPriorityInfo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    await ref.read(extensionProvider.notifier).setProviderPriority(_providers);
    setState(() {
      _hasChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.snackbarProviderPrioritySaved)),
      );
    }
  }
}

class _ProviderItem extends StatelessWidget {
  final String provider;
  final int index;
  final bool isFirst;
  final bool isLast;

  const _ProviderItem({
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

    final info = _getProviderInfo(provider);

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
                        info.isBuiltIn ? context.l10n.providerBuiltIn : context.l10n.providerExtension,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
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

  _ProviderInfo _getProviderInfo(String provider) {
    switch (provider) {
      case 'tidal':
        return _ProviderInfo(
          name: 'Tidal',
          icon: Icons.music_note,
          isBuiltIn: true,
        );
      case 'qobuz':
        return _ProviderInfo(
          name: 'Qobuz',
          icon: Icons.album,
          isBuiltIn: true,
        );
      case 'amazon':
        return _ProviderInfo(
          name: 'Amazon Music',
          icon: Icons.shopping_bag,
          isBuiltIn: true,
        );
      default:
        return _ProviderInfo(
          name: provider,
          icon: Icons.extension,
          isBuiltIn: false,
        );
    }
  }
}

class _ProviderInfo {
  final String name;
  final IconData icon;
  final bool isBuiltIn;

  _ProviderInfo({
    required this.name,
    required this.icon,
    required this.isBuiltIn,
  });
}
