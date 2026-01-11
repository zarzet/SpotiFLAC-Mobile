import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
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
      
      // Create directories if they don't exist
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
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
                    'Extensions',
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

          // Loading indicator
          if (extState.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // Error message
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

          // Provider Priority
          const SliverToBoxAdapter(
            child: SettingsSectionHeader(title: 'Provider Priority'),
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

          // Installed Extensions
          const SliverToBoxAdapter(
            child: SettingsSectionHeader(title: 'Installed Extensions'),
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
                        'No extensions installed',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Install .spotiflac-ext files to add new providers',
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

          // Install button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _installExtension,
                icon: const Icon(Icons.add),
                label: const Text('Install Extension'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          // Info section
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
                        'Extensions can add new metadata and download providers. '
                        'Only install extensions from trusted sources.',
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
              const SnackBar(
                content: Text('Please select a .spotiflac-ext file'),
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
            message = 'Extension installed successfully';
          } else {
            // Parse friendly error message
            message = _getFriendlyErrorMessage(extState.error);
          }
          
          // Clear the error from state to avoid showing it twice (in error container)
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
    
    // Remove PlatformException wrapper if present
    // Format: PlatformException(ERROR, actual message, null, null)
    if (message.contains('PlatformException')) {
      // Try to extract the actual error message
      final match = RegExp(r'PlatformException\([^,]+,\s*([^,]+(?:,[^,]+)?),').firstMatch(message);
      if (match != null) {
        message = match.group(1)?.trim() ?? message;
      } else {
        // Fallback: try simpler extraction
        final simpleMatch = RegExp(r'PlatformException\([^,]+,\s*(.+?),\s*null').firstMatch(message);
        if (simpleMatch != null) {
          message = simpleMatch.group(1)?.trim() ?? message;
        }
      }
    }
    
    // Clean up any remaining artifacts
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
                // Extension icon
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
                // Extension info
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
                            ? extension.errorMessage ?? 'Error loading extension'
                            : 'v${extension.version} by ${extension.author}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasError
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle switch
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
    
    // Check if any extension has download provider
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
                    'Download Priority',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: hasDownloadExtensions 
                          ? null 
                          : colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDownloadExtensions 
                        ? 'Set download service order'
                        : 'No extensions with download provider',
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
    
    // Check if any extension has metadata provider
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
                    'Metadata Priority',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: hasMetadataExtensions 
                          ? null 
                          : colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasMetadataExtensions 
                        ? 'Set search & metadata source order'
                        : 'No extensions with metadata provider',
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
    
    // Get extensions with custom search
    final searchProviders = extState.extensions
        .where((e) => e.enabled && e.hasCustomSearch)
        .toList();
    
    // Get current provider name
    String currentProviderName = 'Default (Deezer/Spotify)';
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
                        'Search Provider',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: searchProviders.isEmpty 
                              ? colorScheme.outline 
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        searchProviders.isEmpty 
                            ? 'No extensions with custom search'
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
                'Search Provider',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Choose which service to use for searching tracks',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Default option
            ListTile(
              leading: Icon(Icons.music_note, color: colorScheme.primary),
              title: const Text('Default (Deezer/Spotify)'),
              subtitle: const Text('Use built-in search'),
              trailing: (settings.searchProvider == null || settings.searchProvider!.isEmpty)
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : Icon(Icons.circle_outlined, color: colorScheme.outline),
              onTap: () {
                ref.read(settingsProvider.notifier).setSearchProvider(null);
                Navigator.pop(ctx);
              },
            ),
            // Extension options
            ...searchProviders.map((ext) => ListTile(
              leading: Icon(Icons.extension, color: colorScheme.secondary),
              title: Text(ext.displayName),
              subtitle: Text(ext.searchBehavior?.placeholder ?? 'Custom search'),
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
