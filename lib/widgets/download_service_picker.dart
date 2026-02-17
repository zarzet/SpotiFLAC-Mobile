import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/l10n/l10n.dart';

/// Built-in service info with quality options
class BuiltInService {
  final String id;
  final String label;
  final List<QualityOption> qualityOptions;
  final bool isDisabled; // If true, service is grayed out (fallback only)
  final String? disabledReason;

  const BuiltInService({
    required this.id,
    required this.label,
    required this.qualityOptions,
    this.isDisabled = false,
    this.disabledReason,
  });
}

/// Default quality options for built-in services (Tidal, Qobuz, Amazon, YouTube)
/// Note: Tidal lossy (HIGH) removed - use YouTube for lossy downloads
const _builtInServices = [
  BuiltInService(
    id: 'tidal',
    label: 'Tidal',
    qualityOptions: [
      QualityOption(
        id: 'LOSSLESS',
        label: 'FLAC Lossless',
        description: '16-bit / 44.1kHz',
      ),
      QualityOption(
        id: 'HI_RES',
        label: 'Hi-Res FLAC',
        description: '24-bit / up to 96kHz',
      ),
      QualityOption(
        id: 'HI_RES_LOSSLESS',
        label: 'Hi-Res FLAC Max',
        description: '24-bit / up to 192kHz',
      ),
    ],
  ),
  BuiltInService(
    id: 'qobuz',
    label: 'Qobuz',
    qualityOptions: [
      QualityOption(
        id: 'LOSSLESS',
        label: 'FLAC Lossless',
        description: '16-bit / 44.1kHz',
      ),
      QualityOption(
        id: 'HI_RES',
        label: 'Hi-Res FLAC',
        description: '24-bit / up to 96kHz',
      ),
      QualityOption(
        id: 'HI_RES_LOSSLESS',
        label: 'Hi-Res FLAC Max',
        description: '24-bit / up to 192kHz',
      ),
    ],
  ),
  BuiltInService(
    id: 'amazon',
    label: 'Amazon',
    qualityOptions: [
      QualityOption(
        id: 'LOSSLESS',
        label: 'FLAC Best Available',
        description: 'Amazon API delivers the best available lossless quality',
      ),
    ],
  ),
  BuiltInService(
    id: 'youtube',
    label: 'YouTube',
    qualityOptions: [
      QualityOption(
        id: 'opus_256',
        label: 'Opus 256kbps',
        description: 'Best quality lossy (~8MB per track)',
      ),
      QualityOption(
        id: 'mp3_320',
        label: 'MP3 320kbps',
        description: 'Best compatibility (~10MB per track)',
      ),
    ],
    isDisabled: false,
    disabledReason: null,
  ),
];

/// A reusable widget for selecting download service (built-in + extensions)
class DownloadServicePicker extends ConsumerStatefulWidget {
  final String? trackName;
  final String? artistName;
  final String? coverUrl;
  final void Function(String quality, String service) onSelect;

  const DownloadServicePicker({
    super.key,
    this.trackName,
    this.artistName,
    this.coverUrl,
    required this.onSelect,
  });

  @override
  ConsumerState<DownloadServicePicker> createState() =>
      _DownloadServicePickerState();

  /// Show the download service picker as a modal bottom sheet
  static void show(
    BuildContext context, {
    String? trackName,
    String? artistName,
    String? coverUrl,
    required void Function(String quality, String service) onSelect,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) => DownloadServicePicker(
        trackName: trackName,
        artistName: artistName,
        coverUrl: coverUrl,
        onSelect: onSelect,
      ),
    );
  }
}

class _DownloadServicePickerState extends ConsumerState<DownloadServicePicker> {
  static const List<int> _youtubeOpusSupportedBitrates = [128, 256];
  static const List<int> _youtubeMp3SupportedBitrates = [128, 256, 320];

  late String _selectedService;

  @override
  void initState() {
    super.initState();
    _selectedService = ref.read(settingsProvider).defaultService;
  }

  /// Get quality options for the selected service
  List<QualityOption> _getQualityOptions() {
    final settings = ref.read(settingsProvider);
    if (_selectedService == 'youtube') {
      final opusBitrate = _nearestSupportedBitrate(
        settings.youtubeOpusBitrate,
        _youtubeOpusSupportedBitrates,
      );
      final mp3Bitrate = _nearestSupportedBitrate(
        settings.youtubeMp3Bitrate,
        _youtubeMp3SupportedBitrates,
      );
      return [
        QualityOption(
          id: 'opus_$opusBitrate',
          label: 'Opus ${opusBitrate}kbps',
          description: 'Configured from YouTube settings',
        ),
        QualityOption(
          id: 'mp3_$mp3Bitrate',
          label: 'MP3 ${mp3Bitrate}kbps',
          description: 'Configured from YouTube settings',
        ),
      ];
    }

    final builtIn = _builtInServices
        .where((s) => s.id == _selectedService)
        .firstOrNull;
    if (builtIn != null) {
      return builtIn.qualityOptions;
    }

    final extensionState = ref.read(extensionProvider);
    final ext = extensionState.extensions
        .where((e) => e.id == _selectedService)
        .firstOrNull;
    if (ext != null && ext.qualityOptions.isNotEmpty) {
      return ext.qualityOptions;
    }

    // Default fallback options
    return [
      const QualityOption(
        id: 'DEFAULT',
        label: 'Default Quality',
        description: 'Best available',
      ),
    ];
  }

  int _nearestSupportedBitrate(int value, List<int> supported) {
    var nearest = supported.first;
    var nearestDistance = (value - nearest).abs();

    for (final option in supported.skip(1)) {
      final distance = (value - option).abs();
      if (distance < nearestDistance ||
          (distance == nearestDistance && option > nearest)) {
        nearest = option;
        nearestDistance = distance;
      }
    }

    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final extensionState = ref.watch(extensionProvider);

    final downloadExtensions = extensionState.extensions
        .where((ext) => ext.enabled && ext.hasDownloadProvider)
        .toList();

    final qualityOptions = _getQualityOptions();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.trackName != null) ...[
              _TrackInfoHeader(
                trackName: widget.trackName!,
                artistName: widget.artistName,
                coverUrl: widget.coverUrl,
              ),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                context.l10n.downloadFrom,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final service in _builtInServices)
                    _ServiceChip(
                      label: service.isDisabled
                          ? '${service.label} (${service.disabledReason})'
                          : service.label,
                      isSelected: _selectedService == service.id,
                      isDisabled: service.isDisabled,
                      onTap: service.isDisabled
                          ? null
                          : () => setState(() => _selectedService = service.id),
                    ),
                  for (final ext in downloadExtensions)
                    _ServiceChip(
                      label: ext.displayName,
                      isSelected: _selectedService == ext.id,
                      onTap: () => setState(() => _selectedService = ext.id),
                      iconPath: ext.iconPath,
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                context.l10n.downloadSelectQuality,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            if (_builtInServices.any(
              (s) => s.id == _selectedService && s.id != 'youtube',
            ))
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  context.l10n.qualityNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            if (_selectedService == 'youtube')
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  context.l10n.youtubeQualityNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            for (final quality in qualityOptions)
              _QualityOption(
                title: quality.label,
                subtitle: quality.description ?? '',
                icon: _getQualityIcon(quality.id),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSelect(quality.id, _selectedService);
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getQualityIcon(String qualityId) {
    final normalized = qualityId.toUpperCase();
    if (normalized.startsWith('MP3_') || normalized == 'MP3') {
      return Icons.audiotrack;
    }
    if (normalized.startsWith('OPUS_') || normalized == 'OPUS') {
      return Icons.graphic_eq;
    }

    switch (normalized) {
      case 'HI_RES_LOSSLESS':
        return Icons.four_k;
      case 'HI_RES':
        return Icons.high_quality;
      case 'LOSSLESS':
        return Icons.music_note;
      default:
        return Icons.music_note;
    }
  }
}

class _QualityOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QualityOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? iconPath;
  final bool isDisabled;

  const _ServiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconPath,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDisabled
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(iconPath!),
                  width: 18,
                  height: 18,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.extension,
                    size: 18,
                    color: isDisabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                        : isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isDisabled
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                    : isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackInfoHeader extends StatefulWidget {
  final String trackName;
  final String? artistName;
  final String? coverUrl;

  const _TrackInfoHeader({
    required this.trackName,
    this.artistName,
    this.coverUrl,
  });

  @override
  State<_TrackInfoHeader> createState() => _TrackInfoHeaderState();
}

class _TrackInfoHeaderState extends State<_TrackInfoHeader> {
  bool _expanded = false;
  bool _isOverflowing = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isOverflowing
            ? () => setState(() => _expanded = !_expanded)
            : null,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.coverUrl != null
                        ? Image.network(
                            widget.coverUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 56,
                                  height: 56,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.music_note,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.music_note,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final titleStyle = Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600);
                        final titleSpan = TextSpan(
                          text: widget.trackName,
                          style: titleStyle,
                        );
                        final titlePainter = TextPainter(
                          text: titleSpan,
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                        )..layout(maxWidth: constraints.maxWidth);
                        final titleOverflows = titlePainter.didExceedMaxLines;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _isOverflowing != titleOverflows) {
                            setState(() => _isOverflowing = titleOverflows);
                          }
                        });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.trackName,
                              style: titleStyle,
                              maxLines: _expanded ? 10 : 1,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                            ),
                            if (widget.artistName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.artistName!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: _expanded ? 3 : 1,
                                overflow: _expanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  if (_isOverflowing || _expanded)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
