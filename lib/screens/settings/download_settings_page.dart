import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/settings.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/screens/settings/download_fallback_extensions_page.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class DownloadSettingsPage extends ConsumerStatefulWidget {
  const DownloadSettingsPage({super.key});

  @override
  ConsumerState<DownloadSettingsPage> createState() =>
      _DownloadSettingsPageState();
}

class _DownloadSettingsPageState extends ConsumerState<DownloadSettingsPage> {
  static const _builtInServices = ['tidal', 'qobuz'];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final extensionState = ref.watch(extensionProvider);
    final hasExtensions = extensionState.extensions.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);

    final isBuiltInService = _builtInServices.contains(settings.defaultService);
    final isTidalService = settings.defaultService == 'tidal';

    return PopScope(
      canPop: true,
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
                  final leftPadding = 56 - (32 * expandRatio);
                  return FlexibleSpaceBar(
                    expandedTitleScale: 1.0,
                    titlePadding: EdgeInsets.only(
                      left: leftPadding,
                      bottom: 16,
                    ),
                    title: Text(
                      context.l10n.settingsDownload,
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

            // ── Service ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionService),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _ServiceSelector(
                    currentService: settings.defaultService,
                    onChanged: (service) => ref
                        .read(settingsProvider.notifier)
                        .setDefaultService(service),
                  ),
                ],
              ),
            ),

            // ── Audio Quality ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.sectionAudioQuality,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.tune,
                    title: context.l10n.downloadAskBeforeDownload,
                    subtitle: isBuiltInService
                        ? context.l10n.downloadAskQualitySubtitle
                        : context.l10n.downloadSelectServiceToEnable,
                    value: settings.askQualityBeforeDownload,
                    enabled: isBuiltInService,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setAskQualityBeforeDownload(value),
                  ),
                  if (!settings.askQualityBeforeDownload &&
                      isBuiltInService) ...[
                    _QualityOption(
                      title: context.l10n.qualityFlacLossless,
                      subtitle: context.l10n.qualityFlacLosslessSubtitle,
                      isSelected: settings.audioQuality == 'LOSSLESS',
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAudioQuality('LOSSLESS'),
                    ),
                    _QualityOption(
                      title: context.l10n.qualityHiResFlac,
                      subtitle: context.l10n.qualityHiResFlacSubtitle,
                      isSelected: settings.audioQuality == 'HI_RES',
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAudioQuality('HI_RES'),
                    ),
                    _QualityOption(
                      title: context.l10n.qualityHiResFlacMax,
                      subtitle: context.l10n.qualityHiResFlacMaxSubtitle,
                      isSelected: settings.audioQuality == 'HI_RES_LOSSLESS',
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAudioQuality('HI_RES_LOSSLESS'),
                      showDivider: isTidalService,
                    ),
                    if (isTidalService)
                      _QualityOption(
                        title: context.l10n.downloadLossy320,
                        subtitle: _getTidalHighFormatLabel(
                          context,
                          settings.tidalHighFormat,
                        ),
                        isSelected: settings.audioQuality == 'HIGH',
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setAudioQuality('HIGH'),
                        showDivider: false,
                      ),
                    if (isTidalService && settings.audioQuality == 'HIGH')
                      SettingsItem(
                        icon: Icons.tune,
                        title: context.l10n.downloadLossyFormat,
                        subtitle: _getTidalHighFormatLabel(
                          context,
                          settings.tidalHighFormat,
                        ),
                        onTap: () => _showTidalHighFormatPicker(
                          context,
                          ref,
                          settings.tidalHighFormat,
                        ),
                        showDivider: false,
                      ),
                  ],
                  if (!isBuiltInService)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.downloadSelectTidalQobuz,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Network & Performance ──────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.sectionPerformance,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _ConcurrentDownloadsItem(
                    currentValue: settings.concurrentDownloads,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setConcurrentDownloads(v),
                  ),
                  SettingsItem(
                    icon: Icons.wifi,
                    title: context.l10n.settingsDownloadNetwork,
                    subtitle: settings.downloadNetworkMode == 'wifi_only'
                        ? context.l10n.settingsDownloadNetworkWifiOnly
                        : context.l10n.settingsDownloadNetworkAny,
                    onTap: () => _showNetworkModePicker(
                      context,
                      ref,
                      settings.downloadNetworkMode,
                    ),
                  ),
                  SettingsSwitchItem(
                    icon: Icons.security_outlined,
                    title: context.l10n.downloadNetworkCompatibilityMode,
                    subtitle: settings.networkCompatibilityMode
                        ? context.l10n.downloadNetworkCompatibilityModeEnabled
                        : context.l10n.downloadNetworkCompatibilityModeDisabled,
                    value: settings.networkCompatibilityMode,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setNetworkCompatibilityMode(value),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            // ── Fallback & Search ──────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.sectionSearchSource,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  const _MetadataSourceSelector(),
                  const _DefaultSearchTabSelector(),
                  SettingsSwitchItem(
                    icon: Icons.sync,
                    title: context.l10n.optionsAutoFallback,
                    subtitle: context.l10n.optionsAutoFallbackSubtitle,
                    value: settings.autoFallback,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setAutoFallback(v),
                  ),
                  if (hasExtensions)
                    SettingsSwitchItem(
                      icon: Icons.extension,
                      title: context.l10n.optionsUseExtensionProviders,
                      subtitle: settings.useExtensionProviders
                          ? context.l10n.optionsUseExtensionProvidersOn
                          : context.l10n.optionsUseExtensionProvidersOff,
                      value: settings.useExtensionProviders,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .setUseExtensionProviders(v),
                    ),
                  SettingsItem(
                    icon: Icons.extension_outlined,
                    title: context.l10n.downloadFallbackExtensions,
                    subtitle: context.l10n.downloadFallbackExtensionsSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const DownloadFallbackExtensionsPage(),
                      ),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            // ── Misc ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionDownload),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.public,
                    title: context.l10n.downloadSongLinkRegion,
                    subtitle: _getSongLinkRegionLabel(settings.songLinkRegion),
                    onTap: () => _showSongLinkRegionPicker(
                      context,
                      ref,
                      settings.songLinkRegion,
                    ),
                  ),
                  SettingsSwitchItem(
                    icon: Icons.file_download_outlined,
                    title: context.l10n.settingsAutoExportFailed,
                    subtitle: context.l10n.settingsAutoExportFailedSubtitle,
                    value: settings.autoExportFailedDownloads,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setAutoExportFailedDownloads(value),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _getTidalHighFormatLabel(BuildContext context, String format) {
    switch (format) {
      case 'mp3_320':
        return context.l10n.downloadLossyMp3;
      case 'opus_256':
        return context.l10n.downloadLossyOpus256;
      case 'opus_128':
        return context.l10n.downloadLossyOpus128;
      default:
        return context.l10n.downloadLossyMp3;
    }
  }

  String _getSongLinkRegionLabel(String code) {
    const names = <String, String>{
      'US': 'United States', 'GB': 'United Kingdom', 'FR': 'France',
      'DE': 'Germany', 'JP': 'Japan', 'KR': 'South Korea',
      'IN': 'India', 'ID': 'Indonesia', 'BR': 'Brazil',
      'MX': 'Mexico', 'AU': 'Australia', 'CA': 'Canada', 'XK': 'Kosovo',
    };
    final normalized = code.trim().toUpperCase();
    final effective = normalized.isEmpty ? 'US' : normalized;
    final name = names[effective];
    return name == null ? effective : '$effective - $name';
  }

  void _showTidalHighFormatPicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                context.l10n.downloadLossy320Format,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.downloadLossy320FormatDesc,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: Text(context.l10n.downloadLossyMp3),
              subtitle: Text(context.l10n.downloadLossyMp3Subtitle),
              trailing: current == 'mp3_320'
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setTidalHighFormat('mp3_320');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq),
              title: Text(context.l10n.downloadLossyOpus256),
              subtitle: Text(context.l10n.downloadLossyOpus256Subtitle),
              trailing: current == 'opus_256'
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setTidalHighFormat('opus_256');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq),
              title: Text(context.l10n.downloadLossyOpus128),
              subtitle: Text(context.l10n.downloadLossyOpus128Subtitle),
              trailing: current == 'opus_128'
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setTidalHighFormat('opus_128');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showNetworkModePicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                context.l10n.settingsDownloadNetwork,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.settingsDownloadNetworkSubtitle,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.signal_cellular_alt),
              title: Text(context.l10n.settingsDownloadNetworkAny),
              subtitle: Text(context.l10n.downloadNetworkAnySubtitle),
              trailing: current == 'any'
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setDownloadNetworkMode('any');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wifi),
              title: Text(context.l10n.settingsDownloadNetworkWifiOnly),
              subtitle: Text(context.l10n.downloadNetworkWifiOnlySubtitle),
              trailing: current == 'wifi_only'
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setDownloadNetworkMode('wifi_only');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSongLinkRegionPicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    const regions = [
      'AD','AE','AG','AL','AM','AO','AR','AT','AU','AZ','BA','BB','BD','BE',
      'BF','BG','BH','BI','BJ','BN','BO','BR','BS','BT','BW','BZ','CA','CD',
      'CG','CH','CI','CL','CM','CO','CR','CV','CW','CY','CZ','DE','DJ','DK',
      'DM','DO','DZ','EC','EE','EG','ES','ET','FI','FJ','FM','FR','GA','GB',
      'GD','GE','GH','GM','GN','GQ','GR','GT','GW','GY','HK','HN','HR','HT',
      'HU','ID','IE','IL','IN','IQ','IS','IT','JM','JO','JP','KE','KG','KH',
      'KI','KM','KN','KR','KW','KZ','LA','LB','LC','LI','LK','LR','LS','LT',
      'LU','LV','LY','MA','MC','MD','ME','MG','MH','MK','ML','MN','MO','MR',
      'MT','MU','MV','MW','MX','MY','MZ','NA','NE','NG','NI','NL','NO','NP',
      'NR','NZ','OM','PA','PE','PG','PH','PK','PL','PS','PT','PW','PY','QA',
      'RO','RS','RW','SA','SB','SC','SE','SG','SI','SK','SL','SM','SN','SR',
      'ST','SV','SZ','TD','TG','TH','TJ','TL','TN','TO','TR','TT','TV','TW',
      'TZ','UA','UG','US','UY','UZ','VC','VE','VN','VU','WS','XK','ZA','ZM','ZW',
    ];
    const names = <String, String>{
      'US': 'United States', 'GB': 'United Kingdom', 'FR': 'France',
      'DE': 'Germany', 'JP': 'Japan', 'KR': 'South Korea',
      'IN': 'India', 'ID': 'Indonesia', 'BR': 'Brazil',
      'MX': 'Mexico', 'AU': 'Australia', 'CA': 'Canada', 'XK': 'Kosovo',
    };
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedCurrent = current.trim().toUpperCase();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  context.l10n.downloadSongLinkRegion,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  context.l10n.downloadSongLinkRegionDesc,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: regions.length,
                  itemBuilder: (context, index) {
                    final code = regions[index];
                    final isSelected = code == normalizedCurrent;
                    return ListTile(
                      title: Text(code),
                      subtitle: names[code] != null ? Text(names[code]!) : null,
                      trailing: isSelected
                          ? Icon(Icons.check, color: colorScheme.primary)
                          : null,
                      onTap: () {
                        ref
                            .read(settingsProvider.notifier)
                            .setSongLinkRegion(code);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets (reused from original) ─────────────────────────────────

class _ServiceSelector extends ConsumerWidget {
  final String currentService;
  final ValueChanged<String> onChanged;
  const _ServiceSelector({
    required this.currentService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extState = ref.watch(extensionProvider);
    final builtInServiceIds = ['tidal', 'qobuz'];

    final extensionProviders = extState.extensions
        .where((e) => e.enabled && e.hasDownloadProvider)
        .toList();

    final isExtensionService = !builtInServiceIds.contains(currentService);
    final isCurrentExtensionEnabled = isExtensionService
        ? extensionProviders.any((e) => e.id == currentService)
        : true;

    final effectiveService = isCurrentExtensionEnabled ? currentService : '';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ServiceChip(
                  icon: Icons.music_note,
                  label: 'Tidal',
                  isSelected: effectiveService == 'tidal',
                  onTap: () => onChanged('tidal'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ServiceChip(
                  icon: Icons.album,
                  label: 'Qobuz',
                  isSelected: effectiveService == 'qobuz',
                  onTap: () => onChanged('qobuz'),
                ),
              ),
            ],
          ),
          if (extensionProviders.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final extension in extensionProviders)
                  _ServiceChip(
                    icon: Icons.extension,
                    label: extension.displayName,
                    isSelected: effectiveService == extension.id,
                    onTap: () => onChanged(extension.id),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ServiceChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHigh;
    return Material(
      color: isSelected ? colorScheme.primaryContainer : unselectedColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDivider;
  const _QualityOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                isSelected
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : Icon(Icons.circle_outlined, color: colorScheme.outline),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

class _ConcurrentDownloadsItem extends StatelessWidget {
  final int currentValue;
  final ValueChanged<int> onChanged;
  const _ConcurrentDownloadsItem({
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.download_for_offline,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.optionsConcurrentDownloads,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentValue == 1
                          ? context.l10n.optionsConcurrentSequential
                          : context.l10n.optionsConcurrentParallel(currentValue),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final n in [1, 2, 3, 4, 5]) ...[
                if (n > 1) const SizedBox(width: 8),
                _ConcurrentChip(
                  label: '$n',
                  isSelected: currentValue == n,
                  onTap: () => onChanged(n),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.optionsConcurrentWarning,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConcurrentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ConcurrentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHigh;
    return Expanded(
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : unselectedColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Imported from options_settings_page — search source selectors
class _MetadataSourceSelector extends ConsumerWidget {
  const _MetadataSourceSelector();

  static const _builtInProviders = {'tidal': 'Tidal', 'qobuz': 'Qobuz'};

  Extension? _defaultSearchExtension(List<Extension> extensions) {
    return extensions
            .where(
              (ext) =>
                  ext.enabled &&
                  ext.hasCustomSearch &&
                  ext.searchBehavior?.primary == true,
            )
            .firstOrNull ??
        extensions
            .where((ext) => ext.enabled && ext.hasCustomSearch)
            .firstOrNull;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final extState = ref.watch(extensionProvider);

    final rawSearchProvider = settings.searchProvider?.trim() ?? '';
    final isValidBuiltIn = _builtInProviders.containsKey(rawSearchProvider);
    final primarySearchExtension = _defaultSearchExtension(extState.extensions);
    final defaultProviderTarget =
        primarySearchExtension?.displayName ?? 'Tidal';
    final defaultProviderLabel =
        '${context.l10n.extensionsHomeFeedAuto} ($defaultProviderTarget)';
    final searchProvider =
        isValidBuiltIn ||
            extState.extensions.any(
              (e) =>
                  e.enabled && e.hasCustomSearch && e.id == rawSearchProvider,
            )
        ? rawSearchProvider
        : '';
    final isBuiltIn = _builtInProviders.containsKey(searchProvider);

    Extension? activeExtension;
    if (searchProvider.isNotEmpty && !isBuiltIn) {
      activeExtension = extState.extensions
          .where((e) => e.id == searchProvider && e.enabled)
          .firstOrNull;
    }
    final hasNonDefaultProvider = isBuiltIn || activeExtension != null;

    String subtitle;
    if (isBuiltIn) {
      subtitle = 'Using ${_builtInProviders[searchProvider]}';
    } else if (activeExtension != null) {
      subtitle = context.l10n.optionsUsingExtension(activeExtension.displayName);
    } else {
      subtitle = context.l10n.optionsPrimaryProviderSubtitle;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.optionsPrimaryProvider,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: hasNonDefaultProvider
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SearchProviderChip(
                label: defaultProviderLabel,
                isSelected: searchProvider.isEmpty,
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setSearchProvider(''),
              ),
              for (final entry in _builtInProviders.entries)
                _SearchProviderChip(
                  label: entry.value,
                  isSelected: searchProvider == entry.key,
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setSearchProvider(entry.key),
                ),
              for (final ext in extState.extensions.where(
                (e) => e.enabled && e.hasCustomSearch,
              ))
                _SearchProviderChip(
                  label: ext.displayName,
                  isSelected: searchProvider == ext.id,
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setSearchProvider(ext.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchProviderChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SearchProviderChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
      ),
    );
  }
}

class _DefaultSearchTabSelector extends ConsumerWidget {
  const _DefaultSearchTabSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return SettingsItem(
      icon: Icons.tab_outlined,
      title: context.l10n.optionsDefaultSearchTab,
      subtitle: settings.defaultSearchTab == 'albums'
          ? context.l10n.optionsDefaultSearchTabAlbums
          : context.l10n.optionsDefaultSearchTabTracks,
      onTap: () {
        final current = settings.defaultSearchTab;
        ref.read(settingsProvider.notifier).setDefaultSearchTab(
          current == 'albums' ? 'tracks' : 'albums',
        );
      },
    );
  }
}
