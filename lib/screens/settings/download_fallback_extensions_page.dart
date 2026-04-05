import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class DownloadFallbackExtensionsPage extends ConsumerStatefulWidget {
  const DownloadFallbackExtensionsPage({super.key});

  @override
  ConsumerState<DownloadFallbackExtensionsPage> createState() =>
      _DownloadFallbackExtensionsPageState();
}

class _DownloadFallbackExtensionsPageState
    extends ConsumerState<DownloadFallbackExtensionsPage> {
  late List<Extension> _extensions;
  late Set<String> _selectedExtensionIds;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadExtensions();
  }

  void _loadExtensions() {
    final extState = ref.read(extensionProvider);
    final settings = ref.read(settingsProvider);

    _extensions = extState.extensions
        .where(
          (extension) => extension.enabled && extension.hasDownloadProvider,
        )
        .toList();

    final savedIds = settings.downloadFallbackExtensionIds;
    if (savedIds == null) {
      _selectedExtensionIds = _extensions
          .map((extension) => extension.id)
          .toSet();
    } else {
      final allowedIds = _extensions.map((extension) => extension.id).toSet();
      _selectedExtensionIds = savedIds
          .where((extensionId) => allowedIds.contains(extensionId))
          .toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);

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
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                      context.l10n.extensionsFallbackTitle,
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
                  context.l10n.providerPriorityFallbackExtensionsDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (_extensions.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      context.l10n.extensionsNoDownloadProvider,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            if (_extensions.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: SettingsGroup(
                    margin: EdgeInsets.zero,
                    children: List.generate(_extensions.length, (index) {
                      final extension = _extensions[index];
                      final isSelected = _selectedExtensionIds.contains(
                        extension.id,
                      );
                      return SettingsSwitchItem(
                        icon: Icons.extension_rounded,
                        title: extension.displayName,
                        subtitle: extension.id,
                        value: isSelected,
                        showDivider: index != _extensions.length - 1,
                        onChanged: (value) {
                          setState(() {
                            if (value) {
                              _selectedExtensionIds.add(extension.id);
                            } else {
                              _selectedExtensionIds.remove(extension.id);
                            }
                            _hasChanges = true;
                          });
                        },
                      );
                    }),
                  ),
                ),
              ),
            if (_extensions.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    context.l10n.providerPriorityFallbackExtensionsHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  void _saveChanges() {
    final allExtensionIds = _extensions
        .map((extension) => extension.id)
        .toList();
    final selectedExtensionIds = allExtensionIds
        .where(_selectedExtensionIds.contains)
        .toList();
    final fallbackExtensionIds =
        selectedExtensionIds.length == allExtensionIds.length
        ? null
        : selectedExtensionIds;

    ref
        .read(settingsProvider.notifier)
        .setDownloadFallbackExtensionIds(fallbackExtensionIds);
    setState(() {
      _hasChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.snackbarProviderPrioritySaved)),
    );
  }
}
