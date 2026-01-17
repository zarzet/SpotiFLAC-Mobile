import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
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
                    fontSize: 20 + (14 * expandRatio), // 20 -> 34
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              );
            },
          ),
        ),

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
                    icon: Icons.download_outlined,
                    title: l10n.settingsDownload,
                    subtitle: l10n.settingsDownloadSubtitle,
                    onTap: () => _navigateTo(context, const DownloadSettingsPage()),
                  ),
                  SettingsItem(
                    icon: Icons.tune_outlined,
                    title: l10n.settingsOptions,
                    subtitle: l10n.settingsOptionsSubtitle,
                    onTap: () => _navigateTo(context, const OptionsSettingsPage()),
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

        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              final l10n = context.l10n;
              return SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.article_outlined,
                    title: l10n.logTitle,
                    subtitle: l10n.settingsLogsSubtitle,
                    onTap: () => _navigateTo(context, const LogScreen()),
                  ),
                  SettingsItem(
                    icon: Icons.info_outline,
                    title: l10n.settingsAbout,
                    subtitle: '${l10n.aboutVersion} ${AppInfo.version}',
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
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }
}
