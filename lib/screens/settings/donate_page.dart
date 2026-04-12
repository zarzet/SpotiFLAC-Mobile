import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/widgets/donate_icons.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);

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
                  titlePadding: EdgeInsets.only(left: leftPadding, bottom: 16),
                  title: Text(
                    'Donate',
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DonateLinksCard(colorScheme: colorScheme),

                  const SizedBox(height: 24),

                  _RecentDonorsCard(colorScheme: colorScheme),

                  const SizedBox(height: 16),

                  Card(
                    elevation: 0,
                    color: colorScheme.secondaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.volunteer_activism_rounded,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Good to Know',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _NoticeLine(
                            icon: Icons.block,
                            text:
                                'Not selling early access, premium features, or paywalls',
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 6),
                          _NoticeLine(
                            icon: Icons.build_outlined,
                            text: 'Funds go to dev tools & testing devices',
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 6),
                          _NoticeLine(
                            icon: Icons.favorite_border,
                            text:
                                'Your support is the only way to keep this project alive',
                            colorScheme: colorScheme,
                          ),
                          Divider(
                            height: 24,
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          _NoticeLine(
                            icon: Icons.history,
                            text:
                                'Your name stays permanently in every version it was included in',
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 6),
                          _NoticeLine(
                            icon: Icons.update,
                            text:
                                'Supporter list is updated monthly and embedded in the app',
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 6),
                          _NoticeLine(
                            icon: Icons.cloud_off,
                            text:
                                'No remote server -- everything is stored locally',
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentDonorsCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _RecentDonorsCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const donorNames = <String>[
      'Ldav',
      'Nico',
      'Feuerstern',
      'R4ND0MIZ3D',
      'Isra',
      'bigJr48',
      'Mick',
    ];

    // Match SettingsGroup color logic
    final cardColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.08),
            colorScheme.surface,
          )
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.04),
            colorScheme.surface,
          );

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Recent Supporters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Thank you for your generosity!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (donorNames.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 32,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No supporters yet — be the first!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: donorNames
                    .map(
                      (name) =>
                          _SupporterChip(name: name, colorScheme: colorScheme),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _DonateLinksCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DonateLinksCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.08),
            colorScheme.surface,
          )
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.04),
            colorScheme.surface,
          );

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _DonateCardItem(
            title: 'Ko-fi',
            subtitle: 'ko-fi.com/zarzet',
            customIcon: const KofiIcon(size: 22, color: Colors.white),
            color: const Color(0xFFFF5E5B),
            url: AppInfo.kofiUrl,
            colorScheme: colorScheme,
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 74,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          _DonateCardItem(
            title: 'GitHub Sponsors',
            subtitle: 'github.com/sponsors/zarzet',
            customIcon: const GitHubIcon(size: 22, color: Colors.white),
            color: const Color(0xFF2D333B),
            url: AppInfo.githubSponsorsUrl,
            colorScheme: colorScheme,
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 74,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          _CryptoWalletItem(
            title: 'USDT (TRC20)',
            walletAddress: 'TL7iAqjq9M8BwVMi9AtHvuAGHtdwEvsDta',
            color: const Color(0xFF26A17B),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _DonateCardItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget customIcon;
  final Color color;
  final String url;
  final ColorScheme colorScheme;

  const _DonateCardItem({
    required this.title,
    required this.subtitle,
    required this.customIcon,
    required this.color,
    required this.url,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: customIcon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _CryptoWalletItem extends StatelessWidget {
  final String title;
  final String walletAddress;
  final Color color;
  final ColorScheme colorScheme;

  const _CryptoWalletItem({
    required this.title,
    required this.walletAddress,
    required this.color,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: walletAddress));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title address copied to clipboard'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    walletAddress,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.copy_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupporterChip extends StatelessWidget {
  final String name;
  final ColorScheme colorScheme;

  const _SupporterChip({required this.name, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.secondaryContainer,
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
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;

  const _NoticeLine({
    required this.icon,
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
