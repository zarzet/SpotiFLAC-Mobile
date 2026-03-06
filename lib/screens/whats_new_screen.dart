import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/l10n/l10n.dart';

/// Screen shown to users upgrading from 3.x to 4.x,
/// highlighting the major features introduced in version 4.0.
class WhatsNewScreen extends ConsumerStatefulWidget {
  const WhatsNewScreen({super.key});

  @override
  ConsumerState<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends ConsumerState<WhatsNewScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 9;

  double _responsiveScale({
    required BuildContext context,
    double min = 0.82,
    double max = 1.08,
    double baseShortestSide = 390,
  }) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final scale = shortestSide / baseShortestSide;
    if (scale < min) return min;
    if (scale > max) return max;
    return scale;
  }

  double _effectiveTextScale(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    if (textScale < 1.0) return 1.0;
    if (textScale > 1.4) return 1.4;
    return textScale;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    } else {
      _dismiss();
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
    );
  }

  void _dismiss() {
    ref.read(settingsProvider.notifier).setWhatsNewSeen();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isLastPage = _currentPage == _totalPages - 1;
    final scale = _responsiveScale(context: context, min: 0.86, max: 1.05);
    final textScale = _effectiveTextScale(context);
    final topBarPaddingH = 24 * scale;
    final topBarPaddingV = 16 * scale;
    final pageIndicatorHeight = 8 * scale;
    final pageIndicatorWidth = 8 * scale;
    final activeIndicatorWidth = 32 * scale;
    final bottomGap = (32 * scale) + ((textScale - 1) * 8);
    final actionButtonHeight = (56 * scale) + ((textScale - 1) * 6);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (same as TutorialScreen)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: topBarPaddingH,
                vertical: topBarPaddingV,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _currentPage > 0 ? 1.0 : 0.0,
                    child: IconButton.filledTonal(
                      onPressed: _currentPage > 0 ? _prevPage : null,
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // Skip button
                  TextButton(
                    onPressed: _dismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      l10n.setupSkip,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _WhatsNewPage(
                    index: 0,
                    currentIndex: _currentPage,
                    icon: Icons.auto_awesome_rounded,
                    iconColor: Colors.amber,
                    title: l10n.whatsNewWelcomeTitle,
                    description: l10n.whatsNewWelcomeDesc,
                    content: _buildFeatureList(context, [
                      (Icons.headphones_rounded, l10n.whatsNewWelcomeTip1),
                      (Icons.library_music_rounded, l10n.whatsNewWelcomeTip2),
                      (Icons.speed_rounded, l10n.whatsNewWelcomeTip3),
                    ]),
                  ),
                  _WhatsNewPage(
                    index: 1,
                    currentIndex: _currentPage,
                    icon: Icons.headphones_rounded,
                    title: l10n.whatsNewStreamingTitle,
                    description: l10n.whatsNewStreamingDesc,
                    content: _buildFeatureList(context, [
                      (Icons.play_arrow_rounded, l10n.whatsNewStreamingTip1),
                      (Icons.lyrics_rounded, l10n.whatsNewStreamingTip2),
                      (Icons.download_rounded, l10n.whatsNewStreamingTip3),
                    ]),
                  ),
                  _WhatsNewPage(
                    index: 2,
                    currentIndex: _currentPage,
                    icon: Icons.auto_awesome_rounded,
                    title: l10n.whatsNewSmartQueueTitle,
                    description: l10n.whatsNewSmartQueueDesc,
                    content: _buildFeatureList(context, [
                      (Icons.queue_music_rounded, l10n.whatsNewSmartQueueTip1),
                      (Icons.explore_rounded, l10n.whatsNewSmartQueueTip2),
                      (
                        Icons.all_inclusive_rounded,
                        l10n.whatsNewSmartQueueTip3,
                      ),
                    ]),
                  ),
                  _WhatsNewPage(
                    index: 3,
                    currentIndex: _currentPage,
                    icon: Icons.swap_horiz_rounded,
                    title: l10n.whatsNewDualModeTitle,
                    description: l10n.whatsNewDualModeDesc,
                    content: _buildFeatureList(context, [
                      (Icons.toggle_on_rounded, l10n.whatsNewDualModeTip1),
                      (Icons.auto_fix_high_rounded, l10n.whatsNewDualModeTip2),
                      (
                        Icons.cloud_download_rounded,
                        l10n.whatsNewDualModeTip3,
                      ),
                    ]),
                  ),
                  _WhatsNewPage(
                    index: 4,
                    currentIndex: _currentPage,
                    icon: Icons.library_music_rounded,
                    title: l10n.whatsNewLibraryTitle,
                    description: l10n.whatsNewLibraryDesc,
                    content: _buildFeatureList(context, [
                      (Icons.drag_indicator_rounded, l10n.whatsNewLibraryTip1),
                      (Icons.image_rounded, l10n.whatsNewLibraryTip2),
                      (Icons.checklist_rounded, l10n.whatsNewLibraryTip3),
                    ]),
                  ),
                  _WhatsNewPage(
                    index: 5,
                    currentIndex: _currentPage,
                    icon: Icons.play_circle_filled_rounded,
                    title: l10n.whatsNewPlayerTitle,
                    description: l10n.whatsNewPlayerDesc,
                    content: _buildFeatureList(context, [
                      (Icons.panorama_rounded, l10n.whatsNewPlayerTip1),
                      (Icons.restart_alt_rounded, l10n.whatsNewPlayerTip2),
                      (Icons.lyrics_rounded, l10n.whatsNewPlayerTip3),
                    ]),
                  ),
                  _WhatsNewPage(
                    index: 6,
                    currentIndex: _currentPage,
                    icon: Icons.touch_app_rounded,
                    title: l10n.whatsNewContextMenuTitle,
                    description: l10n.whatsNewContextMenuDesc,
                    content: _buildFeatureList(context, [
                      (
                        Icons.playlist_add_rounded,
                        l10n.whatsNewContextMenuTip1,
                      ),
                      (Icons.share_rounded, l10n.whatsNewContextMenuTip2),
                      (
                        Icons.auto_fix_high_rounded,
                        l10n.whatsNewContextMenuTip3,
                      ),
                    ]),
                  ),
                  _WhatsNewPage(
                    index: 7,
                    currentIndex: _currentPage,
                    icon: Icons.checklist_rounded,
                    title: l10n.whatsNewBatchToolsTitle,
                    description: l10n.whatsNewBatchToolsDesc,
                    content: _buildFeatureList(context, [
                      (Icons.share_rounded, l10n.whatsNewBatchToolsTip1),
                      (Icons.transform_rounded, l10n.whatsNewBatchToolsTip2),
                      (
                        Icons.auto_fix_high_rounded,
                        l10n.whatsNewBatchToolsTip3,
                      ),
                    ]),
                  ),
                  _WhatsNewPage(
                    index: 8,
                    currentIndex: _currentPage,
                    icon: Icons.speed_rounded,
                    title: l10n.whatsNewPerformanceTitle,
                    description: l10n.whatsNewPerformanceDesc,
                    content: Column(
                      children: [
                        _buildFeatureList(context, [
                          (Icons.bolt_rounded, l10n.whatsNewPerformanceTip1),
                          (Icons.memory_rounded, l10n.whatsNewPerformanceTip2),
                          (
                            Icons.storage_rounded,
                            l10n.whatsNewPerformanceTip3,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _WhatsNewReadyCard(text: l10n.whatsNewReadyMessage),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Control Area (same as TutorialScreen)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Expressive Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        margin: EdgeInsets.symmetric(horizontal: 4 * scale),
                        height: pageIndicatorHeight,
                        width: isActive
                            ? activeIndicatorWidth
                            : pageIndicatorWidth,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: bottomGap),
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: actionButtonHeight,
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        isLastPage ? l10n.whatsNewGetStarted : l10n.setupNext,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(
    BuildContext context,
    List<(IconData, String)> features,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 600 + (index * 200)),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          feature.$1,
                          size: 24,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          feature.$2,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

/// A single page within the What's New PageView.
/// Layout matches _TutorialPage in tutorial_screen.dart exactly.
class _WhatsNewPage extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String title;
  final String description;
  final Widget content;
  final Color? iconColor;

  const _WhatsNewPage({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.title,
    required this.description,
    required this.content,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.4);
    final scale = (shortestSide / 390).clamp(0.86, 1.05);
    final topGap = (24 * scale).clamp(16.0, 24.0);
    final iconPadding = (24 * scale).clamp(18.0, 24.0);
    final iconSize = (56 * scale).clamp(44.0, 56.0);
    final iconTextGap = (48 * scale).clamp(28.0, 48.0);
    final descriptionGap = (20 * scale).clamp(12.0, 20.0);
    final contentGap = (56 * scale) + ((textScale - 1) * 10);
    final bottomGap = (32 * scale).clamp(20.0, 32.0);

    final isActive = currentIndex == index;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: topGap),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, isActive ? 0 : -20, 0),
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor ?? colorScheme.primary,
            ),
          ),
          SizedBox(height: iconTextGap),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isActive ? 1.0 : 0.0,
            curve: Curves.easeOut,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: descriptionGap),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: isActive ? 1.0 : 0.0,
            curve: Curves.easeOut,
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                    fontSize: 16 * (1 + ((textScale - 1) * 0.1)),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: contentGap),
          content,
          SizedBox(height: bottomGap),
        ],
      ),
    );
  }
}

/// Ready card shown on the last page,
/// matching _AnimatedReadyCard in tutorial_screen.dart.
class _WhatsNewReadyCard extends StatelessWidget {
  final String text;
  const _WhatsNewReadyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Icon(
            Icons.rocket_launch_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
