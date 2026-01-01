import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/services/update_checker.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback onDismiss;
  final VoidCallback onDisableUpdates;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onDismiss,
    required this.onDisableUpdates,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Update Available'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'v${AppInfo.version}',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    'v${updateInfo.version}',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Changelog header
            Text(
              'What\'s New:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Changelog content (scrollable)
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _formatChangelog(updateInfo.changelog),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Don't remind again button
        TextButton(
          onPressed: () {
            onDisableUpdates();
            Navigator.pop(context);
          },
          child: Text(
            'Don\'t remind',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        // Later button
        TextButton(
          onPressed: () {
            onDismiss();
            Navigator.pop(context);
          },
          child: const Text('Later'),
        ),
        // Download button
        FilledButton(
          onPressed: () async {
            final uri = Uri.parse(updateInfo.downloadUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Download'),
        ),
      ],
    );
  }

  /// Format changelog - clean up markdown
  String _formatChangelog(String changelog) {
    // Remove markdown headers but keep content
    var formatted = changelog
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1') // Remove bold
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1') // Remove code
        .trim();
    
    // Limit length
    if (formatted.length > 1000) {
      formatted = '${formatted.substring(0, 1000)}...';
    }
    
    return formatted;
  }
}

/// Show update dialog
Future<void> showUpdateDialog(
  BuildContext context, {
  required UpdateInfo updateInfo,
  required VoidCallback onDisableUpdates,
}) async {
  return showDialog(
    context: context,
    builder: (context) => UpdateDialog(
      updateInfo: updateInfo,
      onDismiss: () {},
      onDisableUpdates: onDisableUpdates,
    ),
  );
}
