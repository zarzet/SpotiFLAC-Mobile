import 'package:flutter/material.dart';

/// A collapsing header widget
/// Title collapses from large to small when scrolling
class CollapsingHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final Widget? infoCard;
  final List<Widget> slivers;

  const CollapsingHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.infoCard,
    required this.slivers,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 140,
          floating: false,
          pinned: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          automaticallyImplyLeading: false,
          flexibleSpace: LayoutBuilder(
            builder: (context, constraints) {
              final expandRatio = _calculateExpandRatio(constraints, topPadding);
              final animation = AlwaysStoppedAnimation(expandRatio);

              return FlexibleSpaceBar(
                expandedTitleScale: 1.0,
                titlePadding: EdgeInsets.zero,
                title: Container(
                  alignment: Alignment.bottomLeft,
                  padding: EdgeInsets.only(
                    left: Tween<double>(begin: showBackButton ? 56 : 24, end: 24).evaluate(animation),
                    bottom: Tween<double>(begin: 16, end: 24).evaluate(animation),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: Tween<double>(begin: 20, end: 28).evaluate(animation),
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (infoCard != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: infoCard,
            ),
          ),

        ...slivers,
      ],
    );
  }

  double _calculateExpandRatio(BoxConstraints constraints, double topPadding) {
    final maxHeight = 140;
    final minHeight = kToolbarHeight + topPadding;
    final currentHeight = constraints.maxHeight;
    final expandRatio = (currentHeight - minHeight) / (maxHeight - minHeight);
    return expandRatio.clamp(0.0, 1.0);
  }
}

/// Section header for settings
class SettingsSection extends StatelessWidget {
  final String title;
  const SettingsSection({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Info card widget (like version info)
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
