import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/services/update_checker.dart';
import 'package:spotiflac_android/services/apk_downloader.dart';
import 'package:spotiflac_android/services/notification_service.dart';
import 'package:spotiflac_android/l10n/l10n.dart';

class UpdateDialog extends StatefulWidget {
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
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0;
  String _statusText = '';

  Future<void> _downloadAndInstall() async {
    final apkUrl = widget.updateInfo.apkDownloadUrl;
    
    if (apkUrl == null) {
      final uri = Uri.parse(widget.updateInfo.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0;
      _statusText = context.l10n.updateStartingDownload;
    });

    final notificationService = NotificationService();
    
    final filePath = await ApkDownloader.downloadApk(
      url: apkUrl,
      version: widget.updateInfo.version,
      onProgress: (received, total) {
        if (mounted) {
          setState(() {
            _progress = total > 0 ? received / total : 0;
            final receivedMB = (received / 1024 / 1024).toStringAsFixed(1);
            final totalMB = (total / 1024 / 1024).toStringAsFixed(1);
            _statusText = '$receivedMB / $totalMB MB';
          });
        }
        notificationService.showUpdateDownloadProgress(
          version: widget.updateInfo.version,
          received: received,
          total: total,
        );
      },
    );

    if (filePath != null) {
      await notificationService.cancelUpdateNotification();
      
      await notificationService.showUpdateDownloadComplete(
        version: widget.updateInfo.version,
      );
      
      if (mounted) {
        Navigator.pop(context);
      }
      
      await ApkDownloader.installApk(filePath);
    } else {
      await notificationService.cancelUpdateNotification();
      
      await notificationService.showUpdateDownloadFailed();
      
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = context.l10n.updateDownloadFailed;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.updateFailedMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.system_update_rounded, color: colorScheme.onPrimaryContainer, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.updateAvailable, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(context.l10n.updateNewVersionReady, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark 
                    ? Color.alphaBlend(Colors.white.withValues(alpha: 0.08), colorScheme.surface)
                    : Color.alphaBlend(Colors.black.withValues(alpha: 0.04), colorScheme.surface),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _VersionChip(version: AppInfo.version, label: context.l10n.updateCurrent, colorScheme: colorScheme),
                  const SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  _VersionChip(version: widget.updateInfo.version, label: context.l10n.updateNew, colorScheme: colorScheme, isNew: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            if (_isDownloading) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), colorScheme.surface)
                      : Color.alphaBlend(Colors.black.withValues(alpha: 0.03), colorScheme.surface),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Text(context.l10n.updateDownloading, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_statusText, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                        Text('${(_progress * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(context.l10n.updateWhatsNew, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), colorScheme.surface)
                      : Color.alphaBlend(Colors.black.withValues(alpha: 0.03), colorScheme.surface),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _formatChangelog(widget.updateInfo.changelog),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            if (_isDownloading)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(context.l10n.dialogCancel),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _downloadAndInstall,
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: Text(context.l10n.updateDownloadInstall),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            widget.onDisableUpdates();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(context.l10n.updateDontRemind, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            widget.onDismiss();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(context.l10n.updateLater),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Format changelog - clean up markdown and extract relevant content
  String _formatChangelog(String changelog) {
    var content = changelog;
    
    final whatsNewMatch = RegExp(r"###?\s*What'?s\s*New\s*\n", caseSensitive: false).firstMatch(content);
    if (whatsNewMatch != null) {
      content = content.substring(whatsNewMatch.end);
    }
    
    final cutoffMatch = RegExp(r'\n---|\n###?\s*Downloads', caseSensitive: false).firstMatch(content);
    if (cutoffMatch != null) {
      content = content.substring(0, cutoffMatch.start);
    }
    
    final lines = content.split('\n');
    final formattedLines = <String>[];
    
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      final sectionMatch = RegExp(r'^#{1,3}\s*(.+)$').firstMatch(line);
      if (sectionMatch != null) {
        final section = sectionMatch.group(1)?.trim();
        if (section != null && section.isNotEmpty) {
          if (formattedLines.isNotEmpty) formattedLines.add('');
          formattedLines.add(section);
        }
        continue;
      }
      
      final listMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(line);
      if (listMatch != null) {
        var itemText = listMatch.group(1) ?? '';
        itemText = itemText.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
        itemText = itemText.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? '');
        formattedLines.add('• $itemText');
        continue;
      }
      
      final subListMatch = RegExp(r'^\s+[-*]\s+(.+)$').firstMatch(line);
      if (subListMatch != null) {
        var itemText = subListMatch.group(1) ?? '';
        itemText = itemText.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
        formattedLines.add('  - $itemText');
        continue;
      }
    }
    
    var formatted = formattedLines.join('\n').trim();
    if (formatted.length > 2000) {
      formatted = '${formatted.substring(0, 2000)}...';
    }
    
    return formatted.isEmpty ? 'See release notes for details.' : formatted;
  }
}

class _VersionChip extends StatelessWidget {
  final String version;
  final String label;
  final ColorScheme colorScheme;
  final bool isNew;

  const _VersionChip({
    required this.version,
    required this.label,
    required this.colorScheme,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isNew ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'v$version',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isNew ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              fontWeight: isNew ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

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
