import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/store_provider.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';
import 'package:spotiflac_android/screens/store/extension_details_screen.dart';

class StoreTab extends ConsumerStatefulWidget {
  const StoreTab({super.key});

  @override
  ConsumerState<StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends ConsumerState<StoreTab> {
  final _searchController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final cacheDir = await getApplicationCacheDirectory();

    // Check if widget is still mounted after async operation
    if (!mounted) return;

    await ref.read(storeProvider.notifier).initialize(cacheDir.path);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(storeProvider.notifier).refresh(forceRefresh: true),
        child: CustomScrollView(
          slivers: [
            // App Bar - consistent with other tabs
            SliverAppBar(
              expandedHeight: 120 + topPadding,
              collapsedHeight: kToolbarHeight,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = 120 + topPadding;
                  final minHeight = kToolbarHeight + topPadding;
                  final expandRatio =
                      ((constraints.maxHeight - minHeight) /
                              (maxHeight - minHeight))
                          .clamp(0.0, 1.0);

                  return FlexibleSpaceBar(
                    expandedTitleScale: 1.0,
                    titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                    title: Text(
                      context.l10n.storeTitle,
                      style: TextStyle(
                        fontSize: 20 + (14 * expandRatio),
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.l10n.storeSearch,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(storeProvider.notifier)
                                  .setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Color.alphaBlend(
                            Colors.white.withValues(alpha: 0.08),
                            colorScheme.surface,
                          )
                        : colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(storeProvider.notifier).setSearchQuery(value);
                    setState(() {}); // Update suffix icon
                  },
                ),
              ),
            ),

            // Category Chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _CategoryChip(
                      label: context.l10n.storeFilterAll,
                      icon: Icons.apps,
                      isSelected: state.selectedCategory == null,
                      onTap: () =>
                          ref.read(storeProvider.notifier).setCategory(null),
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: context.l10n.storeFilterMetadata,
                      icon: Icons.label_outline,
                      isSelected:
                          state.selectedCategory == StoreCategory.metadata,
                      onTap: () => ref
                          .read(storeProvider.notifier)
                          .setCategory(StoreCategory.metadata),
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: context.l10n.storeFilterDownload,
                      icon: Icons.download_outlined,
                      isSelected:
                          state.selectedCategory == StoreCategory.download,
                      onTap: () => ref
                          .read(storeProvider.notifier)
                          .setCategory(StoreCategory.download),
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: context.l10n.storeFilterUtility,
                      icon: Icons.build_outlined,
                      isSelected:
                          state.selectedCategory == StoreCategory.utility,
                      onTap: () => ref
                          .read(storeProvider.notifier)
                          .setCategory(StoreCategory.utility),
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: context.l10n.storeFilterLyrics,
                      icon: Icons.lyrics_outlined,
                      isSelected:
                          state.selectedCategory == StoreCategory.lyrics,
                      onTap: () => ref
                          .read(storeProvider.notifier)
                          .setCategory(StoreCategory.lyrics),
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: context.l10n.storeFilterIntegration,
                      icon: Icons.link,
                      isSelected:
                          state.selectedCategory == StoreCategory.integration,
                      onTap: () => ref
                          .read(storeProvider.notifier)
                          .setCategory(StoreCategory.integration),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            if (state.isLoading && state.extensions.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && state.extensions.isEmpty)
              SliverFillRemaining(
                child: _buildErrorState(state.error!, colorScheme),
              )
            else if (state.filteredExtensions.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(state, colorScheme))
            else ...[
              // Extensions count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    '${state.filteredExtensions.length} ${state.filteredExtensions.length == 1 ? 'extension' : 'extensions'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              // Extensions list in grouped card (like queue_tab)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SettingsGroup(
                    children: state.filteredExtensions.asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final ext = entry.value;
                      return _ExtensionItem(
                        extension: ext,
                        showDivider:
                            index < state.filteredExtensions.length - 1,
                        isDownloading: state.downloadingId == ext.id,
                        onInstall: () => _installExtension(ext),
                        onUpdate: () => _updateExtension(ext),
                        onTap: () => _showExtensionDetails(ext),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load store',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(storeProvider.notifier).refresh(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.dialogRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(StoreState state, ColorScheme colorScheme) {
    final hasFilters =
        state.searchQuery.isNotEmpty || state.selectedCategory != null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.extension_off,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No extensions found' : 'No extensions available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                ref.read(storeProvider.notifier).clearSearch();
              },
              child: Text(context.l10n.storeClearFilters),
            ),
          ],
        ],
      ),
    );
  }

  void _showExtensionDetails(StoreExtension ext) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExtensionDetailsScreen(extension: ext),
      ),
    );
  }

  Future<void> _installExtension(StoreExtension ext) async {
    final tempDir = await getTemporaryDirectory();
    final appDir = await getApplicationDocumentsDirectory();
    final extensionsDir = '${appDir.path}/extensions';

    final success = await ref
        .read(storeProvider.notifier)
        .installExtension(ext.id, tempDir.path, extensionsDir);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${ext.displayName} installed. Enable it in Settings > Extensions'
                : 'Failed to install ${ext.displayName}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updateExtension(StoreExtension ext) async {
    final tempDir = await getTemporaryDirectory();

    final success = await ref
        .read(storeProvider.notifier)
        .updateExtension(ext.id, tempDir.path);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${ext.displayName} updated to v${ext.version}'
                : 'Failed to update ${ext.displayName}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _ExtensionItem extends StatelessWidget {
  final StoreExtension extension;
  final bool showDivider;
  final bool isDownloading;
  final VoidCallback onInstall;
  final VoidCallback onUpdate;
  final VoidCallback? onTap;

  const _ExtensionItem({
    required this.extension,
    required this.showDivider,
    required this.isDownloading,
    required this.onInstall,
    required this.onUpdate,
    this.onTap,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case StoreCategory.metadata:
        return Icons.label_outline;
      case StoreCategory.download:
        return Icons.download_outlined;
      case StoreCategory.utility:
        return Icons.build_outlined;
      case StoreCategory.lyrics:
        return Icons.lyrics_outlined;
      case StoreCategory.integration:
        return Icons.link;
      default:
        return Icons.extension;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Extension icon - custom or category-based
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: extension.isInstalled
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      extension.iconUrl != null && extension.iconUrl!.isNotEmpty
                      ? Image.network(
                          extension.iconUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            _getCategoryIcon(extension.category),
                            color: extension.isInstalled
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : Icon(
                          _getCategoryIcon(extension.category),
                          color: extension.isInstalled
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 16),
                // Extension info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              extension.displayName,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          // Version badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${extension.version}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by ${extension.author}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        extension.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Action button
                if (isDownloading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (extension.hasUpdate)
                  FilledButton.tonal(
                    onPressed: onUpdate,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(context.l10n.storeUpdate),
                  )
                else if (extension.isInstalled)
                  OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 16, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          'Installed',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  )
                else
                  FilledButton(
                    onPressed: onInstall,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(context.l10n.storeInstall),
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
