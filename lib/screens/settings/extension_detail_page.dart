import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class ExtensionDetailPage extends ConsumerStatefulWidget {
  final String extensionId;

  const ExtensionDetailPage({super.key, required this.extensionId});

  @override
  ConsumerState<ExtensionDetailPage> createState() => _ExtensionDetailPageState();
}

class _ExtensionDetailPageState extends ConsumerState<ExtensionDetailPage> {
  Map<String, dynamic> _settings = {};
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref
        .read(extensionProvider.notifier)
        .getExtensionSettings(widget.extensionId);
    setState(() {
      _settings = settings;
      _isLoadingSettings = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final extState = ref.watch(extensionProvider);
    final extension = extState.extensions.firstWhere(
      (e) => e.id == widget.extensionId,
      orElse: () => const Extension(
        id: '',
        name: '',
        displayName: 'Unknown',
        version: '0.0.0',
        author: 'Unknown',
        description: '',
        enabled: false,
        status: 'error',
      ),
    );

    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    final hasError = extension.status == 'error';

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
                    extension.displayName,
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

          // Extension Info Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: hasError
                                ? colorScheme.errorContainer
                                : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: extension.iconPath != null && extension.iconPath!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    File(extension.iconPath!),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      hasError ? Icons.error_outline : Icons.extension,
                                      size: 28,
                                      color: hasError
                                          ? colorScheme.error
                                          : colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                )
                              : Icon(
                                  hasError ? Icons.error_outline : Icons.extension,
                                  size: 28,
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
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'v${extension.version}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: extension.enabled,
                          onChanged: hasError
                              ? null
                              : (enabled) => ref
                                  .read(extensionProvider.notifier)
                                  .setExtensionEnabled(widget.extensionId, enabled),
                        ),
                      ],
                    ),
                    if (extension.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        extension.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Author', value: extension.author),
                    _InfoRow(label: 'ID', value: extension.id),
                    if (hasError && extension.errorMessage != null)
                      _InfoRow(
                        label: 'Error',
                        value: extension.errorMessage!,
                        isError: true,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Capabilities
          const SliverToBoxAdapter(
            child: SettingsSectionHeader(title: 'Capabilities'),
          ),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                _CapabilityItem(
                  icon: Icons.search,
                  title: 'Metadata Provider',
                  enabled: extension.hasMetadataProvider,
                ),
                _CapabilityItem(
                  icon: Icons.download,
                  title: 'Download Provider',
                  enabled: extension.hasDownloadProvider,
                ),
                _CapabilityItem(
                  icon: Icons.manage_search,
                  title: 'Custom Search',
                  enabled: extension.hasCustomSearch,
                  subtitle: extension.searchBehavior?.placeholder,
                ),
                _CapabilityItem(
                  icon: Icons.compare_arrows,
                  title: 'Custom Track Matching',
                  enabled: extension.hasCustomMatching,
                  subtitle: extension.trackMatching?.strategy != null 
                      ? 'Strategy: ${extension.trackMatching!.strategy}'
                      : null,
                ),
                _CapabilityItem(
                  icon: Icons.auto_fix_high,
                  title: 'Post-Processing',
                  enabled: extension.hasPostProcessing,
                  subtitle: extension.postProcessing?.hooks.isNotEmpty == true
                      ? '${extension.postProcessing!.hooks.length} hook(s) available'
                      : null,
                  showDivider: false,
                ),
              ],
            ),
          ),

          // Search Provider Section (if extension has custom search)
          if (extension.hasCustomSearch) ...[
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Search Provider'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _SearchProviderInfo(
                    extension: extension,
                  ),
                ],
              ),
            ),
          ],

          // Post-Processing Hooks (if available)
          if (extension.hasPostProcessing && extension.postProcessing!.hooks.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Post-Processing Hooks'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: extension.postProcessing!.hooks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final hook = entry.value;
                  return _PostProcessingHookItem(
                    hook: hook,
                    showDivider: index < extension.postProcessing!.hooks.length - 1,
                  );
                }).toList(),
              ),
            ),
          ],

          // Permissions
          if (extension.permissions.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Permissions'),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: extension.permissions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final permission = entry.value;
                  return _PermissionItem(
                    permission: permission,
                    showDivider: index < extension.permissions.length - 1,
                  );
                }).toList(),
              ),
            ),
          ],

          // Settings
          if (extension.settings.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SettingsSectionHeader(title: 'Settings'),
            ),
            if (_isLoadingSettings)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SettingsGroup(
                  children: extension.settings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final setting = entry.value;
                    return _SettingItem(
                      setting: setting,
                      value: _settings[setting.key] ?? setting.defaultValue,
                      showDivider: index < extension.settings.length - 1,
                      onChanged: (value) => _updateSetting(setting.key, value),
                    );
                  }).toList(),
                ),
              ),
          ],

          // Remove button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _confirmRemove(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove Extension'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() {
      _settings[key] = value;
    });
    await ref
        .read(extensionProvider.notifier)
        .setExtensionSettings(widget.extensionId, _settings);
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Extension'),
        content: const Text(
          'Are you sure you want to remove this extension? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(extensionProvider.notifier)
          .removeExtension(widget.extensionId);
      if (success && mounted) {
        Navigator.pop(this.context);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isError ? colorScheme.error : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool enabled;
  final bool showDivider;
  final String? subtitle;

  const _CapabilityItem({
    required this.icon,
    required this.title,
    required this.enabled,
    this.showDivider = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled ? colorScheme.primary : colorScheme.outline,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (subtitle != null && enabled) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                enabled ? Icons.check_circle : Icons.cancel_outlined,
                color: enabled ? colorScheme.primary : colorScheme.outline,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final String permission;
  final bool showDivider;

  const _PermissionItem({
    required this.permission,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Parse permission to get icon and description
    IconData icon = Icons.security;
    String description = permission;
    
    if (permission.startsWith('network:')) {
      icon = Icons.language;
      description = 'Network access to: ${permission.substring(8)}';
    } else if (permission.startsWith('storage:')) {
      icon = Icons.folder;
      description = 'Storage access: ${permission.substring(8)}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final ExtensionSetting setting;
  final dynamic value;
  final bool showDivider;
  final ValueChanged<dynamic> onChanged;

  const _SettingItem({
    required this.setting,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget trailing;
    switch (setting.type) {
      case 'boolean':
        trailing = Switch(
          value: value as bool? ?? false,
          onChanged: onChanged,
        );
        break;
      case 'select':
        trailing = DropdownButton<String>(
          value: value as String?,
          items: setting.options?.map((opt) {
            return DropdownMenuItem(value: opt, child: Text(opt));
          }).toList(),
          onChanged: onChanged,
          underline: const SizedBox(),
        );
        break;
      default:
        trailing = Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: setting.type == 'string' || setting.type == 'number'
              ? () => _showEditDialog(context)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        setting.label,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (setting.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          setting.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (setting.type == 'string' || setting.type == 'number') ...[
                        const SizedBox(height: 4),
                        Text(
                          value?.toString() ?? 'Not set',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: value?.toString() ?? '');
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(setting.label),
        content: TextField(
          controller: controller,
          keyboardType: setting.type == 'number'
              ? TextInputType.number
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: setting.description ?? 'Enter value',
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newValue = setting.type == 'number'
                  ? num.tryParse(controller.text)
                  : controller.text;
              onChanged(newValue);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _PostProcessingHookItem extends StatelessWidget {
  final PostProcessingHook hook;
  final bool showDivider;

  const _PostProcessingHookItem({
    required this.hook,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_fix_high,
                  color: colorScheme.onTertiaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hook.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hook.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        hook.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (hook.supportedFormats.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: hook.supportedFormats.map((format) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              format.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (hook.defaultEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Auto',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 72,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

class _SearchProviderInfo extends StatelessWidget {
  final Extension extension;

  const _SearchProviderInfo({
    required this.extension,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchBehavior = extension.searchBehavior;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.manage_search,
                  color: colorScheme.onSecondaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Search Available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'This extension provides its own search functionality',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search placeholder info
          if (searchBehavior?.placeholder != null) ...[
            _InfoTile(
              icon: Icons.text_fields,
              label: 'Search Hint',
              value: searchBehavior!.placeholder!,
            ),
            const SizedBox(height: 8),
          ],
          // Primary search info
          _InfoTile(
            icon: searchBehavior?.primary == true ? Icons.star : Icons.star_border,
            label: 'Priority',
            value: searchBehavior?.primary == true 
                ? 'Primary search provider' 
                : 'Secondary search provider',
          ),
          const SizedBox(height: 16),
          // Usage instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To use this search provider, tap the search bar on the Home tab and select "${extension.displayName}" from the provider chips.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
