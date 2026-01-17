import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/screens/settings/extension_detail_page.dart';
import 'package:spotiflac_android/screens/settings/provider_priority_page.dart';
import 'package:spotiflac_android/screens/settings/metadata_provider_priority_page.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class ExtensionsPage extends ConsumerStatefulWidget {
  const ExtensionsPage({super.key});

  @override
  ConsumerState<ExtensionsPage> createState() => _ExtensionsPageState();
}

class _ExtensionsPageState extends ConsumerState<ExtensionsPage> {
  @override
  void initState() {
    super.initState();
    _initializeExtensions();
  }

  Future<void> _initializeExtensions() async {
    final extState = ref.read(extensionProvider);
    if (!extState.isInitialized) {
      final appDir = await getApplicationDocumentsDirectory();
      final extensionsDir = '${appDir.path}/extensions';
      final dataDir = '${appDir.path}/extension_data';
      
      await Directory(extensionsDir).create(recursive: true);
      await Directory(dataDir).create(recursive: true);
      
      await ref.read(extensionProvider.notifier).initialize(extensionsDir, dataDir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final extState = ref.watch(extensionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: true, // Always allow back gesture
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
              onPressed: () => Navigator.pop(context),
            ),
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
                    context.l10n.extensionsTitle,
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

          if (extState.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          if (extState.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          extState.error!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: SettingsSectionHeader(title: context.l10n.extensionsProviderPrioritySection),
          ),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                _DownloadPriorityItem(),
                _MetadataPriorityItem(),
                _SearchProviderSelector(),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: SettingsSectionHeader(title: context.l10n.extensionsInstalledSection),
          ),

          if (extState.extensions.isEmpty && !extState.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.extension_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.extensionsNoExtensions,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.extensionsNoExtensionsSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (extState.extensions.isNotEmpty)
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: extState.extensions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ext = entry.value;
                  return _ExtensionItem(
                    extension: ext,
                    showDivider: index < extState.extensions.length - 1,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExtensionDetailPage(extensionId: ext.id),
                      ),
                    ),
                    onToggle: (enabled) => ref
                        .read(extensionProvider.notifier)
                        .setExtensionEnabled(ext.id, enabled),
                  );
                }).toList(),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _installExtension,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.extensionsInstallButton),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                        context.l10n.extensionsInfoTip,
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
        ],
      ),
    ),
    );
  }

  Future<void> _installExtension() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        if (!file.path!.endsWith('.spotiflac-ext')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.snackbarSelectExtFile),
              ),
            );
          }
          return;
        }

        final success = await ref
            .read(extensionProvider.notifier)
            .installExtension(file.path!);

        if (mounted) {
          final extState = ref.read(extensionProvider);
          String message;
          if (success) {
            message = context.l10n.extensionsInstalledSuccess;
          } else {
            message = _getFriendlyErrorMessage(extState.error);
          }
          
          ref.read(extensionProvider.notifier).clearError();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    }
  }

  /// Parse error message to be more user-friendly
  String _getFriendlyErrorMessage(String? error) {
    if (error == null) return 'Failed to install extension';
    
    String message = error;
    
    if (message.contains('PlatformException')) {
      final match = RegExp(r'PlatformException\([^,]+,\s*([^,]+(?:,[^,]+)?),').firstMatch(message);
      if (match != null) {
        message = match.group(1)?.trim() ?? message;
      } else {
        final simpleMatch = RegExp(r'PlatformException\([^,]+,\s*(.+?),\s*null').firstMatch(message);
        if (simpleMatch != null) {
          message = simpleMatch.group(1)?.trim() ?? message;
        }
      }
    }
    
    message = message.replaceAll(RegExp(r',\s*null\s*,\s*null\)?$'), '');
    message = message.replaceAll(RegExp(r'^\s*,\s*'), '');
    
    return message;
  }
}

class _ExtensionItem extends StatelessWidget {
  final Extension extension;
  final bool showDivider;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const _ExtensionItem({
    required this.extension,
    required this.showDivider,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = extension.status == 'error';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasError
                        ? colorScheme.errorContainer
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: extension.iconPath != null && extension.iconPath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(extension.iconPath!),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              hasError ? Icons.error_outline : Icons.extension,
                              color: hasError
                                  ? colorScheme.error
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        )
                      : Icon(
                          hasError ? Icons.error_outline : Icons.extension,
                          color: hasError
                              ? colorScheme.error
                              : colorScheme.onPrimaryContainer,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        extension.displayName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasError
                            ? extension.errorMessage ?? context.l10n.extensionsErrorLoading
                            : 'v${extension.version} ${context.l10n.extensionsAuthor(extension.author)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasError
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: extension.enabled,
                  onChanged: hasError ? null : onToggle,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 76,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

class _DownloadPriorityItem extends ConsumerWidget {
  const _DownloadPriorityItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extState = ref.watch(extensionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    final hasDownloadExtensions = extState.extensions
        .any((e) => e.enabled && e.hasDownloadProvider);
    
    return InkWell(
      onTap: hasDownloadExtensions 
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProviderPriorityPage(),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.download,
              color: hasDownloadExtensions 
                  ? colorScheme.onSurfaceVariant 
                  : colorScheme.outline,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.extensionsDownloadPriority,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: hasDownloadExtensions 
                          ? null 
                          : colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDownloadExtensions 
                        ? context.l10n.extensionsDownloadPrioritySubtitle
                        : context.l10n.extensionsNoDownloadProvider,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: hasDownloadExtensions 
                  ? colorScheme.onSurfaceVariant 
                  : colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataPriorityItem extends ConsumerWidget {
  const _MetadataPriorityItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extState = ref.watch(extensionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    final hasMetadataExtensions = extState.extensions
        .any((e) => e.enabled && e.hasMetadataProvider);
    
    return InkWell(
      onTap: hasMetadataExtensions 
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MetadataProviderPriorityPage(),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: hasMetadataExtensions 
                  ? colorScheme.onSurfaceVariant 
                  : colorScheme.outline,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.extensionsMetadataPriority,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: hasMetadataExtensions 
                          ? null 
                          : colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasMetadataExtensions 
                        ? context.l10n.extensionsMetadataPrioritySubtitle
                        : context.l10n.extensionsNoMetadataProvider,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: hasMetadataExtensions 
                  ? colorScheme.onSurfaceVariant 
                  : colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchProviderSelector extends ConsumerWidget {
  const _SearchProviderSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final extState = ref.watch(extensionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    final searchProviders = extState.extensions
        .where((e) => e.enabled && e.hasCustomSearch)
        .toList();
    
    String currentProviderName = context.l10n.extensionDefaultProvider;
    if (settings.searchProvider != null && settings.searchProvider!.isNotEmpty) {
      final ext = searchProviders.where((e) => e.id == settings.searchProvider).firstOrNull;
      currentProviderName = ext?.displayName ?? settings.searchProvider!;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: searchProviders.isEmpty 
              ? null 
              : () => _showSearchProviderPicker(context, ref, settings, searchProviders),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.manage_search,
                  color: searchProviders.isEmpty 
                      ? colorScheme.outline 
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.extensionsSearchProvider,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: searchProviders.isEmpty 
                              ? colorScheme.outline 
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        searchProviders.isEmpty 
                            ? context.l10n.extensionsNoCustomSearch
                            : currentProviderName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: searchProviders.isEmpty 
                      ? colorScheme.outline 
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchProviderPicker(
    BuildContext context,
    WidgetRef ref,
    dynamic settings,
    List<Extension> searchProviders,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                ctx.l10n.extensionsSearchProvider,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                ctx.l10n.extensionsSearchProviderDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.music_note, color: colorScheme.primary),
              title: Text(ctx.l10n.extensionDefaultProvider),
              subtitle: Text(ctx.l10n.extensionDefaultProviderSubtitle),
              trailing: (settings.searchProvider == null || settings.searchProvider!.isEmpty)
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : Icon(Icons.circle_outlined, color: colorScheme.outline),
              onTap: () {
                ref.read(settingsProvider.notifier).setSearchProvider(null);
                Navigator.pop(ctx);
              },
            ),
            ...searchProviders.map((ext) => ListTile(
              leading: Icon(Icons.extension, color: colorScheme.secondary),
              title: Text(ext.displayName),
              subtitle: Text(ext.searchBehavior?.placeholder ?? ctx.l10n.extensionsCustomSearch),
              trailing: settings.searchProvider == ext.id
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : Icon(Icons.circle_outlined, color: colorScheme.outline),
              onTap: () {
                ref.read(settingsProvider.notifier).setSearchProvider(ext.id);
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
