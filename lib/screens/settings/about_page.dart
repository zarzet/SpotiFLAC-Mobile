import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);

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
                      context.l10n.aboutTitle,
                      style: TextStyle(
                        fontSize: 20 + (8 * expandRatio), // 20 -> 28
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _AppHeaderCard(),
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.aboutContributors,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _ContributorItem(
                    name: AppInfo.mobileAuthor,
                    description: context.l10n.aboutMobileDeveloper,
                    githubUsername: AppInfo.mobileAuthor,
                    showDivider: true,
                  ),
                  _ContributorItem(
                    name: AppInfo.originalAuthor,
                    description: context.l10n.aboutOriginalCreator,
                    githubUsername: AppInfo.originalAuthor,
                    showDivider: true,
                  ),
                  _ContributorItem(
                    name: 'Amonoman',
                    description: context.l10n.aboutLogoArtist,
                    githubUsername: 'Amonoman',
                    showDivider: false,
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.aboutTranslators,
              ),
            ),
            const SliverToBoxAdapter(child: _TranslatorsSection()),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: context.l10n.aboutSpecialThanks,
              ),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _ContributorItem(
                    name: 'binimum',
                    description: context.l10n.aboutBinimumDesc,
                    githubUsername: 'binimum',
                    showDivider: true,
                  ),
                  _ContributorItem(
                    name: 'sachinsenal0x64',
                    description: context.l10n.aboutSachinsenalDesc,
                    githubUsername: 'sachinsenal0x64',
                    showDivider: true,
                  ),
                  _ContributorItem(
                    name: 'sjdonado',
                    description: context.l10n.aboutSjdonadoDesc,
                    githubUsername: 'sjdonado',
                    showDivider: true,
                  ),
                  _AboutSettingsItem(
                    icon: Icons.music_note_outlined,
                    title: context.l10n.aboutDabMusic,
                    subtitle: context.l10n.aboutDabMusicDesc,
                    onTap: () => _launchUrl('https://dabmusic.xyz'),
                    showDivider: true,
                  ),
                  _AboutSettingsItem(
                    icon: Icons.music_note_outlined,
                    title: context.l10n.aboutSpotiSaver,
                    subtitle: context.l10n.aboutSpotiSaverDesc,
                    onTap: () => _launchUrl('https://spotisaver.net'),
                    showDivider: true,
                  ),
                  _AboutSettingsItem(
                    icon: Icons.lyrics_outlined,
                    title: 'Paxsenix',
                    subtitle:
                        'Partner lyrics proxy for Apple Music and QQ Music sources',
                    onTap: () => _launchUrl('https://lyrics.paxsenix.org'),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.aboutLinks),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _AboutSettingsItem(
                    icon: Icons.phone_android,
                    title: context.l10n.aboutMobileSource,
                    subtitle: 'github.com/${AppInfo.githubRepo}',
                    onTap: () => _launchUrl(AppInfo.githubUrl),
                    showDivider: true,
                  ),
                  _AboutSettingsItem(
                    icon: Icons.computer,
                    title: context.l10n.aboutPCSource,
                    subtitle: 'github.com/${AppInfo.originalAuthor}/SpotiFLAC',
                    onTap: () => _launchUrl(AppInfo.originalGithubUrl),
                    showDivider: true,
                  ),
                  _AboutSettingsItem(
                    icon: Icons.bug_report_outlined,
                    title: context.l10n.aboutReportIssue,
                    subtitle: context.l10n.aboutReportIssueSubtitle,
                    onTap: () => _launchUrl('${AppInfo.githubUrl}/issues/new'),
                    showDivider: true,
                  ),
                  _AboutSettingsItem(
                    icon: Icons.lightbulb_outline,
                    title: context.l10n.aboutFeatureRequest,
                    subtitle: context.l10n.aboutFeatureRequestSubtitle,
                    onTap: () => _launchUrl('${AppInfo.githubUrl}/issues/new'),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.aboutSocial),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _AboutSettingsItem(
                    icon: Icons.telegram,
                    title: context.l10n.aboutTelegramChannel,
                    subtitle: context.l10n.aboutTelegramChannelSubtitle,
                    onTap: () => _launchUrl('https://t.me/spotiflac'),
                    showDivider: true,
                  ),
                  _AboutSettingsItem(
                    icon: Icons.forum_outlined,
                    title: context.l10n.aboutTelegramChat,
                    subtitle: context.l10n.aboutTelegramChatSubtitle,
                    onTap: () => _launchUrl('https://t.me/spotiflac_chat'),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.aboutApp),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  _AboutSettingsItem(
                    icon: Icons.info_outline,
                    title: context.l10n.aboutVersion,
                    subtitle:
                        'v${AppInfo.version} (build ${AppInfo.buildNumber})',
                    showDivider: false,
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    AppInfo.copyright,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

class _AppHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.08),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHighest;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final shortestSide = MediaQuery.sizeOf(context).shortestSide;
        final textScale = MediaQuery.textScalerOf(
          context,
        ).scale(1.0).clamp(1.0, 1.4);
        final logoSize = (shortestSide * 0.22).clamp(72.0, 88.0);
        final contentPadding = (cardWidth * 0.06).clamp(16.0, 24.0);
        final titleGap = (16 * (1 + ((textScale - 1) * 0.2))).clamp(12.0, 20.0);

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/logo-transparant.png',
                  color: colorScheme.onPrimary,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: titleGap),
              Text(
                AppInfo.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'v${AppInfo.version}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: titleGap),
              Text(
                context.l10n.aboutAppDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContributorItem extends StatelessWidget {
  final String name;
  final String description;
  final String githubUsername;
  final bool showDivider;

  const _ContributorItem({
    required this.name,
    required this.description,
    required this.githubUsername,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _launchGitHub(githubUsername),
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: 'https://github.com/$githubUsername.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    memCacheWidth: 120,
                    memCacheHeight: 120,
                    cacheManager: CoverCacheManager.instance,
                    placeholder: (context, url) => Container(
                      width: 40,
                      height: 40,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.person,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 40,
                      height: 40,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.person,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 76,
            endIndent: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }

  Future<void> _launchGitHub(String username) async {
    final uri = Uri.parse('https://github.com/$username');
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

/// Translator data model
class _Translator {
  final String name;
  final String crowdinUsername;
  final String language;
  final String flag;

  const _Translator({
    required this.name,
    required this.crowdinUsername,
    required this.language,
    required this.flag,
  });
}

/// Translators section with compact chip-style layout
class _TranslatorsSection extends StatelessWidget {
  const _TranslatorsSection();

  static const List<_Translator> _translators = [
    _Translator(
      name: 'Pedro Marcondes',
      crowdinUsername: 'justapedro',
      language: 'Portuguese',
      flag: '🇵🇹',
    ),
    _Translator(
      name: 'Credits 125',
      crowdinUsername: 'credits125',
      language: 'Spanish',
      flag: '🇪🇸',
    ),
    _Translator(
      name: 'Владислав',
      crowdinUsername: 'odinokiy_kot',
      language: 'Russian',
      flag: '🇷🇺',
    ),
    _Translator(
      name: 'Amonoman',
      crowdinUsername: 'amonoman',
      language: 'German',
      flag: '🇩🇪',
    ),
    _Translator(
      name: 'Re*Index.(ot_inc)',
      crowdinUsername: 'ot_inc',
      language: 'Japanese',
      flag: '🇯🇵',
    ),
    _Translator(
      name: 'Kaan',
      crowdinUsername: 'glai',
      language: 'Turkish',
      flag: '🇹🇷',
    ),
    _Translator(
      name: 'BedirhanGltkn',
      crowdinUsername: 'bedirhangltkn',
      language: 'Turkish',
      flag: '🇹🇷',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.08),
            colorScheme.surface,
          )
        : colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _translators
              .map((translator) => _TranslatorChip(translator: translator))
              .toList(),
        ),
      ),
    );
  }
}

/// Individual translator chip
class _TranslatorChip extends StatelessWidget {
  final _Translator translator;

  const _TranslatorChip({required this.translator});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _launchCrowdin(translator.crowdinUsername),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                child: Text(
                  translator.name.isNotEmpty
                      ? translator.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                translator.name,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Text(translator.flag, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchCrowdin(String username) async {
    final uri = Uri.parse('https://crowdin.com/profile/$username');
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

class _AboutSettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showDivider;

  const _AboutSettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
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
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    icon,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodyLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 76, // 20 + 40 + 16 = 76 (same as contributor item)
            endIndent: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
