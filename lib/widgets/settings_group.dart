import 'package:flutter/material.dart';

/// A grouped settings card that connects items together like Android Settings
/// Items are connected with no gap between them, only separated when changing groups
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const SettingsGroup({
    super.key,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use a more contrasting color for cards
    // In dark mode with dynamic color, surfaceContainerHighest can be too similar to surface
    // So we add a slight white overlay to make it more visible
    // In light mode with dynamic color, we add a slight black overlay for the same reason
    final cardColor = isDark 
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.08), colorScheme.surface)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.04), colorScheme.surface);
    
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

/// A single settings item that can be used inside SettingsGroup
class SettingsItem extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const SettingsItem({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colorScheme.onSurfaceVariant, size: 24),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: icon != null ? 56 : 20,
            endIndent: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

/// A switch settings item for SettingsGroup
class SettingsSwitchItem extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;
  final bool enabled;

  const SettingsSwitchItem({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.showDivider = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = !enabled || onChanged == null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: InkWell(
            onTap: isDisabled ? null : () => onChanged!(!value),
            splashColor: colorScheme.primary.withValues(alpha: 0.12),
            highlightColor: colorScheme.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: isDisabled ? colorScheme.outline : colorScheme.onSurfaceVariant, size: 24),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDisabled ? colorScheme.outline : null,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDisabled ? colorScheme.outline : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: value,
                    onChanged: isDisabled ? null : onChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: icon != null ? 56 : 20,
            endIndent: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

/// Section header for settings groups
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
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
