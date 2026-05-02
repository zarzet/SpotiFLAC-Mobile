import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/screens/settings/appearance_settings_page.dart';
import 'package:spotiflac_android/screens/settings/download_settings_page.dart';
import 'package:spotiflac_android/screens/settings/files_settings_page.dart';
import 'package:spotiflac_android/screens/settings/lyrics_settings_page.dart';
import 'package:spotiflac_android/screens/settings/metadata_settings_page.dart';
import 'package:spotiflac_android/screens/settings/extensions_page.dart';
import 'package:spotiflac_android/screens/settings/library_settings_page.dart';
import 'package:spotiflac_android/screens/settings/app_settings_page.dart';
import 'package:spotiflac_android/screens/settings/about_page.dart';
import 'package:spotiflac_android/screens/settings/cache_management_page.dart';
import 'package:spotiflac_android/screens/settings/donate_page.dart';
import 'package:spotiflac_android/screens/settings/log_screen.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';
import 'package:spotiflac_android/widgets/animation_utils.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);

    return CustomScrollView(
      slivers: [
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
                  context.l10n.settingsTitle,
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

        // ── Group 1: Appearance & Content ──────────────────────────────
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              final l10n = context.l10n;
              return SettingsGroup(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                children: [
                  SettingsItem(
                    icon: Icons.palette_outlined,
                    title: l10n.settingsAppearance,
                    subtitle: l10n.settingsAppearanceSubtitle,
                    onTap: () =>
                        _navigateTo(context, const AppearanceSettingsPage()),
                  ),
                  SettingsItem(
                    icon: Icons.library_music_outlined,
                    title: l10n.settingsLocalLibrary,
                    subtitle: l10n.settingsLocalLibrarySubtitle,
                    onTap: () =>
                        _navigateTo(context, const LibrarySettingsPage()),
                  ),
                  SettingsItem(
                    icon: Icons.extension_outlined,
                    title: l10n.settingsExtensions,
                    subtitle: l10n.settingsExtensionsSubtitle,
                    onTap: () => _navigateTo(context, const ExtensionsPage()),
                    showDivider: false,
                  ),
                ],
              );
            },
          ),
        ),

        // ── Group 2: Download ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              final l10n = context.l10n;
              return SettingsGroup(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                children: [
                  SettingsItem(
                    icon: Icons.download_outlined,
                    title: l10n.settingsDownload,
                    subtitle: l10n.settingsDownloadSubtitle,
                    onTap: () =>
                        _navigateTo(context, const DownloadSettingsPage()),
                  ),
                  SettingsItem(
                    icon: Icons.folder_outlined,
                    title: l10n.settingsFiles,
                    subtitle: l10n.settingsFilesSubtitle,
                    onTap: () =>
                        _navigateTo(context, const FilesSettingsPage()),
                  ),
                  SettingsItem(
                    icon: Icons.sell_outlined,
                    title: l10n.settingsMetadata,
                    subtitle: l10n.settingsMetadataSubtitle,
                    onTap: () =>
                        _navigateTo(context, const MetadataSettingsPage()),
                  ),
                  SettingsItem(
                    icon: Icons.lyrics_outlined,
                    title: l10n.settingsLyrics,
                    subtitle: l10n.settingsLyricsSubtitle,
                    onTap: () =>
                        _navigateTo(context, const LyricsSettingsPage()),
                    showDivider: false,
                  ),
                ],
              );
            },
          ),
        ),

        // ── Group 3: App ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              final l10n = context.l10n;
              return SettingsGroup(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                children: [
                  SettingsItem(
                    icon: Icons.storage_outlined,
                    title: l10n.settingsCache,
                    subtitle: l10n.settingsCacheSubtitle,
                    onTap: () =>
                        _navigateTo(context, const CacheManagementPage()),
                  ),
                  SettingsItem(
                    icon: Icons.tune_outlined,
                    title: l10n.settingsApp,
                    subtitle: l10n.settingsAppSubtitle,
                    onTap: () =>
                        _navigateTo(context, const AppSettingsPage()),
                  ),
                  SettingsItem(
                    icon: Icons.article_outlined,
                    title: l10n.logTitle,
                    subtitle: l10n.settingsLogsSubtitle,
                    onTap: () => _navigateTo(context, const LogScreen()),
                  ),
                  SettingsItem(
                    icon: Icons.favorite_outline,
                    title: l10n.settingsDonate,
                    subtitle: l10n.settingsDonateSubtitle,
                    onTap: () => _navigateTo(context, const DonatePage()),
                  ),
                  SettingsItem(
                    icon: Icons.info_outline,
                    title: l10n.settingsAbout,
                    subtitle: '${l10n.aboutVersion} ${AppInfo.displayVersion}',
                    onTap: () => _navigateTo(context, const AboutPage()),
                    showDivider: false,
                  ),
                ],
              );
            },
          ),
        ),

        const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
      ],
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(slidePageRoute<void>(page: page));
  }
}
