import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/store_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';

class ExtensionDetailsScreen extends ConsumerStatefulWidget {
  final StoreExtension extension;

  const ExtensionDetailsScreen({super.key, required this.extension});

  @override
  ConsumerState<ExtensionDetailsScreen> createState() =>
      _ExtensionDetailsScreenState();
}

class _ExtensionDetailsScreenState
    extends ConsumerState<ExtensionDetailsScreen> {

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeProvider);

    final liveExtension =
        storeState.extensions
            .where((e) => e.id == widget.extension.id)
            .firstOrNull ??
        widget.extension;

    final isDownloading = storeState.downloadingId == liveExtension.id;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, liveExtension, colorScheme),
          _buildInfoCard(context, liveExtension, colorScheme, isDownloading),
          _buildSectionHeader(
            context,
            context.l10n.aboutTitle,
            Icons.info_outline,
            colorScheme,
          ),
          _buildDescription(context, liveExtension, colorScheme),

          if (liveExtension.tags.isNotEmpty) ...[
            _buildSectionHeader(context, 'Tags', Icons.tag, colorScheme),
            _buildTags(context, liveExtension, colorScheme),
          ],

          _buildSectionHeader(
            context,
            'Information',
            Icons.table_chart_outlined,
            colorScheme,
          ),
          _buildMetadataTable(context, liveExtension, colorScheme),

          _buildSectionHeader(
            context,
            context.l10n.extensionCapabilities,
            Icons.extension_outlined,
            colorScheme,
          ),
          _buildCapabilities(context, liveExtension, colorScheme),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    StoreExtension ext,
    ColorScheme colorScheme,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: colorScheme.surfaceContainerHighest,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ext.iconUrl != null && ext.iconUrl!.isNotEmpty
                    ? Image.network(
                        ext.iconUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackIcon(ext, colorScheme, 50),
                      )
                    : _buildFallbackIcon(ext, colorScheme, 50),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildFallbackIcon(
    StoreExtension ext,
    ColorScheme colorScheme,
    double size,
  ) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        _getCategoryIcon(ext.category),
        size: size,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    StoreExtension ext,
    ColorScheme colorScheme,
    bool isDownloading,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ext.displayName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        const SizedBox(height: 4),
                          Text(
                            context.l10n.extensionsAuthor(ext.author),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      label: 'v${ext.version}',
                      color: colorScheme.secondaryContainer,
                      textColor: colorScheme.onSecondaryContainer,
                    ),
                    _Badge(
                      label: _getCategoryName(ext.category),
                      color: colorScheme.tertiaryContainer,
                      textColor: colorScheme.onTertiaryContainer,
                    ),
                    if (ext.isInstalled)
                      _Badge(
                        label: context.l10n.storeInstalled,
                        color: colorScheme.primaryContainer,
                        textColor: colorScheme.onPrimaryContainer,
                        icon: Icons.check,
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                if (isDownloading)
                  Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                else ...[
                  if (ext.hasUpdate)
                    FilledButton.icon(
                      onPressed: () => _updateExtension(ext),
                      icon: const Icon(Icons.update),
                      label: Text('${context.l10n.storeUpdate} v${ext.version}'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    )
                  else if (ext.isInstalled)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check),
                            label: Text(context.l10n.storeInstalled),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: () => _uninstallExtension(ext),
                          icon: const Icon(Icons.delete_outline),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.errorContainer,
                            foregroundColor: colorScheme.onErrorContainer,
                            minimumSize: const Size(52, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          tooltip: context.l10n.extensionsUninstall,
                        ),
                      ],
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _installExtension(ext),
                      icon: const Icon(Icons.download),
                      label: Text(context.l10n.storeInstall),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(
    BuildContext context,
    StoreExtension ext,
    ColorScheme colorScheme,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          ext.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTags(
    BuildContext context,
    StoreExtension ext,
    ColorScheme colorScheme,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ext.tags
              .map(
                (tag) => Chip(
                  label: Text(tag),
                  backgroundColor: colorScheme.surfaceContainer,
                  labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMetadataTable(
    BuildContext context,
    StoreExtension ext,
    ColorScheme colorScheme,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _MetadataRow(
                label: context.l10n.extensionUpdated,
                value: ext.updatedAt.isNotEmpty
                    ? _formatDate(context, ext.updatedAt)
                    : '-',
                colorScheme: colorScheme,
              ),
              _MetadataRow(
                label: context.l10n.extensionId,
                value: ext.id,
                colorScheme: colorScheme,
              ),
              _MetadataRow(
                label: context.l10n.extensionMinAppVersion,
                value: ext.minAppVersion ?? 'Any',
                colorScheme: colorScheme,
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilities(
    BuildContext context,
    StoreExtension ext,
    ColorScheme colorScheme,
  ) {
    final isMetadataProvider = ext.category == 'metadata' || ext.category == 'integration';
    final isDownloadProvider = ext.category == 'download';
    final isLyricsProvider = ext.category == 'lyrics';
    final isUtility = ext.category == 'utility';

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _CapabilityRow(
                icon: Icons.search,
                label: context.l10n.extensionMetadataProvider,
                enabled: isMetadataProvider,
                colorScheme: colorScheme,
              ),
              _CapabilityRow(
                icon: Icons.download,
                label: context.l10n.extensionDownloadProvider,
                enabled: isDownloadProvider,
                colorScheme: colorScheme,
              ),
              _CapabilityRow(
                icon: Icons.lyrics,
                label: context.l10n.extensionLyricsProvider,
                enabled: isLyricsProvider,
                colorScheme: colorScheme,
              ),
              _CapabilityRow(
                icon: Icons.build,
                label: 'Utility Functions',
                enabled: isUtility,
                colorScheme: colorScheme,
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        return context.l10n.dateToday;
      } else if (diff.inDays == 1) {
        return context.l10n.dateYesterday;
      } else if (diff.inDays < 7) {
        return context.l10n.dateDaysAgo(diff.inDays);
      } else if (diff.inDays < 30) {
        return context.l10n.dateWeeksAgo((diff.inDays / 7).floor());
      } else if (diff.inDays < 365) {
        return context.l10n.dateMonthsAgo((diff.inDays / 30).floor());
      } else {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return dateStr.split('T').first;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'metadata':
        return Icons.label_outline;
      case 'download':
        return Icons.download_outlined;
      case 'utility':
        return Icons.build_outlined;
      case 'lyrics':
        return Icons.lyrics_outlined;
      case 'integration':
        return Icons.link;
      default:
        return Icons.extension;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'metadata':
        return 'Metadata';
      case 'download':
        return 'Download';
      case 'utility':
        return 'Utility';
      case 'lyrics':
        return 'Lyrics';
      case 'integration':
        return 'Integration';
      default:
        return category;
    }
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
                ? context.l10n.snackbarExtensionInstalled(ext.displayName)
                : context.l10n.snackbarFailedToInstall,
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
                ? context.l10n.snackbarExtensionUpdated(ext.displayName)
                : context.l10n.snackbarFailedToUpdate,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uninstallExtension(StoreExtension ext) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.dialogUninstallExtension),
        content: Text(context.l10n.dialogUninstallExtensionMessage(ext.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.dialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.dialogUninstall,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(extensionProvider.notifier).removeExtension(ext.id);
      await ref.read(storeProvider.notifier).refresh();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool isLast;

  const _MetadataRow({
    required this.label,
    required this.value,
    required this.colorScheme,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final ColorScheme colorScheme;
  final bool isLast;

  const _CapabilityRow({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.colorScheme,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled ? colorScheme.primary : colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                enabled ? Icons.check_circle : Icons.cancel_outlined,
                size: 20,
                color: enabled ? colorScheme.primary : colorScheme.outline,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
