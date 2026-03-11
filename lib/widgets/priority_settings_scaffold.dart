import 'package:flutter/material.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';

class PrioritySettingsScaffold extends StatelessWidget {
  final bool hasChanges;
  final String title;
  final String description;
  final String infoText;
  final String saveLabel;
  final EdgeInsetsGeometry descriptionPadding;
  final List<Widget> slivers;
  final Future<void> Function() onSave;
  final Future<bool> Function(BuildContext context) onConfirmDiscard;

  const PrioritySettingsScaffold({
    super.key,
    required this.hasChanges,
    required this.title,
    required this.description,
    required this.infoText,
    required this.slivers,
    required this.onSave,
    required this.onConfirmDiscard,
    this.saveLabel = 'Save',
    this.descriptionPadding = const EdgeInsets.fromLTRB(16, 4, 16, 8),
  });

  Future<void> _handleBack(BuildContext context) async {
    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }
    final shouldPop = await onConfirmDiscard(context);
    if (shouldPop && context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await onConfirmDiscard(context);
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
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
                onPressed: () => _handleBack(context),
              ),
              actions: [
                if (hasChanges)
                  TextButton(onPressed: onSave, child: Text(saveLabel)),
              ],
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
                      title,
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
                padding: descriptionPadding,
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            ...slivers,
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          infoText,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onTertiaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
