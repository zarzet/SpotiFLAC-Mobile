import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/screens/settings/appearance_settings_page.dart';
import 'package:spotiflac_android/screens/settings/download_settings_page.dart';
import 'package:spotiflac_android/screens/settings/extensions_page.dart';
import 'package:spotiflac_android/screens/settings/options_settings_page.dart';
import 'package:spotiflac_android/screens/settings/about_page.dart';
import 'package:spotiflac_android/screens/settings/log_screen.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        // Collapsing App Bar
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
                  'Settings',
                  style: TextStyle(
                    fontSize: 20 + (14 * expandRatio), // 20 -> 34
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              );
            },
          ),
        ),

        // First group: Appearance & Download
        SliverToBoxAdapter(
          child: SettingsGroup(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            children: [
              SettingsItem(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: 'Theme, colors, display',
                onTap: () =>
                    _navigateTo(context, const AppearanceSettingsPage()),
              ),
              SettingsItem(
                icon: Icons.download_outlined,
                title: 'Download',
                subtitle: 'Service, quality, filename format',
                onTap: () => _navigateTo(context, const DownloadSettingsPage()),
              ),
              SettingsItem(
                icon: Icons.tune_outlined,
                title: 'Options',
                subtitle: 'Fallback, lyrics, cover art, updates',
                onTap: () => _navigateTo(context, const OptionsSettingsPage()),
              ),
              SettingsItem(
                icon: Icons.extension_outlined,
                title: 'Extensions',
                subtitle: 'Manage download providers',
                onTap: () => _navigateTo(context, const ExtensionsPage()),
                showDivider: false,
              ),
            ],
          ),
        ),

        // Second group: Logs & About
        SliverToBoxAdapter(
          child: SettingsGroup(
            children: [
              SettingsItem(
                icon: Icons.article_outlined,
                title: 'Logs',
                subtitle: 'View app logs for debugging',
                onTap: () => _navigateTo(context, const LogScreen()),
              ),
              SettingsItem(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Version ${AppInfo.version}, credits, GitHub',
                onTap: () => _navigateTo(context, const AboutPage()),
                showDivider: false,
              ),
            ],
          ),
        ),

        // Fill remaining space
        const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
      ],
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
