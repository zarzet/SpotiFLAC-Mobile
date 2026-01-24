import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/webdav_config.dart';
import 'package:spotiflac_android/providers/webdav_provider.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class WebDavSettingsPage extends ConsumerStatefulWidget {
  const WebDavSettingsPage({super.key});

  @override
  ConsumerState<WebDavSettingsPage> createState() => _WebDavSettingsPageState();
}

class _WebDavSettingsPageState extends ConsumerState<WebDavSettingsPage> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remotePathController = TextEditingController();
  bool _obscurePassword = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    // Load existing config
    final config = ref.read(webDavProvider).config;
    _serverUrlController.text = config.serverUrl;
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _remotePathController.text = config.remotePath;
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);

    final result = await ref.read(webDavProvider.notifier).testConnection();

    if (!mounted) return;
    setState(() => _isTesting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.webdavConnectionSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.webdavConnectionFailed(
              result.error ?? 'Unknown error',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final webDavState = ref.watch(webDavProvider);
    final config = webDavState.config;
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    final l10n = context.l10n;

    return Scaffold(
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
                final expandRatio =
                    ((constraints.maxHeight - minHeight) /
                            (maxHeight - minHeight))
                        .clamp(0.0, 1.0);
                return FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  titlePadding: EdgeInsets.only(
                    left: 56 - (32 * expandRatio),
                    bottom: 16,
                  ),
                  title: Text(
                    l10n.webdavTitle,
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

          // Enable toggle
          SliverToBoxAdapter(
            child: SettingsSectionHeader(title: l10n.webdavSectionConfig),
          ),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                SettingsSwitchItem(
                  icon: Icons.cloud_upload,
                  title: l10n.webdavEnable,
                  subtitle: config.isConfigured
                      ? l10n.webdavEnableSubtitleConfigured
                      : l10n.webdavEnableSubtitleNotConfigured,
                  value: config.enabled,
                  enabled: config.isConfigured,
                  onChanged: (value) {
                    ref.read(webDavProvider.notifier).setEnabled(value);
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),

          // Server configuration
          SliverToBoxAdapter(
            child: SettingsSectionHeader(title: l10n.webdavSectionServer),
          ),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                _buildTextField(
                  controller: _serverUrlController,
                  icon: Icons.link,
                  label: l10n.webdavServerUrl,
                  hint: 'https://webdav.example.com/dav',
                  onChanged: (value) {
                    ref.read(webDavProvider.notifier).setServerUrl(value);
                  },
                  keyboardType: TextInputType.url,
                ),
                _buildTextField(
                  controller: _usernameController,
                  icon: Icons.person,
                  label: l10n.webdavUsername,
                  hint: l10n.webdavUsernamePlaceholder,
                  onChanged: (value) {
                    ref.read(webDavProvider.notifier).setUsername(value);
                  },
                ),
                _buildTextField(
                  controller: _passwordController,
                  icon: Icons.lock,
                  label: l10n.webdavPassword,
                  hint: l10n.webdavPasswordPlaceholder,
                  obscureText: _obscurePassword,
                  onChanged: (value) {
                    ref.read(webDavProvider.notifier).setPassword(value);
                  },
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),

          // Test connection button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.icon(
                onPressed: config.isConfigured && !_isTesting
                    ? _testConnection
                    : null,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find),
                label: Text(
                  _isTesting ? l10n.webdavTesting : l10n.webdavTestConnection,
                ),
              ),
            ),
          ),

          // Remote path and options
          SliverToBoxAdapter(
            child: SettingsSectionHeader(title: l10n.webdavSectionOptions),
          ),
          SliverToBoxAdapter(
            child: SettingsGroup(
              children: [
                _buildTextField(
                  controller: _remotePathController,
                  icon: Icons.folder,
                  label: l10n.webdavRemotePath,
                  hint: '/SpotiFLAC',
                  onChanged: (value) {
                    ref.read(webDavProvider.notifier).setRemotePath(value);
                  },
                ),
                SettingsSwitchItem(
                  icon: Icons.delete_outline,
                  title: l10n.webdavDeleteLocal,
                  subtitle: l10n.webdavDeleteLocalSubtitle,
                  value: config.deleteLocalAfterUpload,
                  onChanged: (value) {
                    ref
                        .read(webDavProvider.notifier)
                        .setDeleteLocalAfterUpload(value);
                  },
                ),
                SettingsSwitchItem(
                  icon: Icons.refresh,
                  title: l10n.webdavRetryOnFailure,
                  subtitle: l10n.webdavRetrySubtitle(config.maxRetries),
                  value: config.retryOnFailure,
                  onChanged: (value) {
                    ref.read(webDavProvider.notifier).setRetryOnFailure(value);
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),

          // Upload Queue section
          SliverToBoxAdapter(
            child: SettingsSectionHeader(title: l10n.webdavSectionQueue),
          ),
          SliverToBoxAdapter(
            child: _buildQueueSummary(webDavState, l10n, colorScheme),
          ),

          // Queue items
          if (webDavState.activeItems.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.webdavActiveUploads,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (webDavState.failedCount > 0)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(webDavProvider.notifier).retryFailed();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(l10n.webdavRetryAll),
                      ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = webDavState.activeItems[index];
                return _buildQueueItem(item, colorScheme, l10n);
              }, childCount: webDavState.activeItems.length),
            ),
          ],

          // Clear completed button
          if (webDavState.completedCount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(webDavProvider.notifier).clearCompleted();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: Text(l10n.webdavClearCompleted),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    String? hint,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
    Widget? suffix,
    TextInputType? keyboardType,
    bool showDivider = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: colorScheme.onSurfaceVariant, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    border: const OutlineInputBorder(),
                    suffixIcon: suffix,
                  ),
                  onChanged: onChanged,
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
            endIndent: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }

  Widget _buildQueueSummary(
    WebDavState webDavState,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return SettingsGroup(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.schedule,
                count: webDavState.pendingCount,
                label: l10n.webdavPending,
                color: colorScheme.outline,
              ),
              _buildStatItem(
                icon: Icons.cloud_upload,
                count: webDavState.uploadingCount,
                label: l10n.webdavUploading,
                color: colorScheme.primary,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                count: webDavState.completedCount,
                label: l10n.webdavCompleted,
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.error,
                count: webDavState.failedCount,
                label: l10n.webdavFailed,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem(
    WebDavUploadItem item,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final statusIcon = switch (item.status) {
      WebDavUploadStatus.pending => Icons.schedule,
      WebDavUploadStatus.uploading => Icons.cloud_upload,
      WebDavUploadStatus.completed => Icons.check_circle,
      WebDavUploadStatus.failed => Icons.error,
    };

    final statusColor = switch (item.status) {
      WebDavUploadStatus.pending => colorScheme.outline,
      WebDavUploadStatus.uploading => colorScheme.primary,
      WebDavUploadStatus.completed => Colors.green,
      WebDavUploadStatus.failed => Colors.red,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Stack(
            alignment: Alignment.center,
            children: [
              if (item.status == WebDavUploadStatus.uploading)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: item.progress,
                    strokeWidth: 3,
                    color: colorScheme.primary,
                  ),
                ),
              Icon(statusIcon, color: statusColor),
            ],
          ),
          title: Text(
            item.trackName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              if (item.status == WebDavUploadStatus.uploading)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              if (item.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    item.error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.status == WebDavUploadStatus.uploading)
                Text('${(item.progress * 100).toInt()}%'),
              if (item.status == WebDavUploadStatus.failed)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(webDavProvider.notifier).retryItem(item.id);
                  },
                  tooltip: l10n.webdavRetry,
                ),
              if (item.status != WebDavUploadStatus.uploading)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(webDavProvider.notifier).removeFromQueue(item.id);
                  },
                  tooltip: l10n.webdavRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
