import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedLevel = 'ALL';
  String _searchQuery = '';
  bool _autoScroll = true;

  final List<String> _levels = ['ALL', 'DEBUG', 'INFO', 'WARN', 'ERROR'];

  @override
  void initState() {
    super.initState();
    LogBuffer().addListener(_onLogUpdate);
    LogBuffer().startGoLogPolling();
  }

  @override
  void dispose() {
    LogBuffer().removeListener(_onLogUpdate);
    LogBuffer().stopGoLogPolling();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onLogUpdate() {
    if (mounted) {
      setState(() {});
      if (_autoScroll && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  List<LogEntry> get _filteredLogs {
    return LogBuffer().filter(
      level: _selectedLevel,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  void _copyLogs() {
    final logs = LogBuffer().export();
    Clipboard.setData(ClipboardData(text: logs));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.logCopied),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareLogs() {
    final logs = LogBuffer().export();
    SharePlus.instance.share(ShareParams(text: logs, subject: 'SpotiFLAC Logs'));
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.logClearLogsTitle),
        content: Text(context.l10n.logClearLogsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () {
              LogBuffer().clear();
              Navigator.pop(context);
            },
            child: Text(context.l10n.dialogClear),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level, ColorScheme colorScheme) {
    switch (level) {
      case 'ERROR':
      case 'FATAL':
        return colorScheme.error;
      case 'WARN':
        return Colors.orange;
      case 'INFO':
        return colorScheme.primary;
      case 'DEBUG':
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    final logs = _filteredLogs;

    return PopScope(
      canPop: true, // Always allow back gesture
      child: Scaffold(
        body: CustomScrollView(
          controller: _scrollController,
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
            actions: [
              IconButton(
                icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center),
                tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
                onPressed: () => setState(() => _autoScroll = !_autoScroll),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy logs',
                onPressed: _copyLogs,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      _shareLogs();
                      break;
                    case 'clear':
                      _clearLogs();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: const Icon(Icons.share),
                      title: Text(context.l10n.logShareLogs),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                        title: Text(context.l10n.logClearLogs),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = 120 + topPadding;
                  final minHeight = kToolbarHeight + topPadding;
                  final expandRatio = ((constraints.maxHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);
                  final leftPadding = 56 - (32 * expandRatio);
                  return FlexibleSpaceBar(
                    expandedTitleScale: 1.0,
                    titlePadding: EdgeInsets.only(left: leftPadding, bottom: 16),
                    title: Text(
                      context.l10n.logTitle,
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
              child: SettingsSectionHeader(title: context.l10n.logFilterSection),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.logFilterLevel, style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.logFilterBySeverity,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedLevel,
                          underline: const SizedBox(),
                          items: _levels.map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Text(
                                level,
                                style: TextStyle(
                                  color: level == 'ALL' 
                                      ? colorScheme.onSurface 
                                      : _getLevelColor(level, colorScheme),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedLevel = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 20,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: context.l10n.logSearchHint,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSectionHeader(
                title: _selectedLevel != 'ALL' || _searchQuery.isNotEmpty 
                    ? context.l10n.logEntriesFiltered(logs.length)
                    : context.l10n.logEntries(logs.length),
              ),
            ),
            
            SliverToBoxAdapter(
              child: _LogSummaryCard(logs: LogBuffer().entries),
            ),
            
            logs.isEmpty
                ? SliverToBoxAdapter(
                    child: SettingsGroup(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.l10n.logNoLogsYet,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.logNoLogsYetSubtitle,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : SliverToBoxAdapter(
                    child: SettingsGroup(
                      children: [
                        ...logs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final log = entry.value;
                          return _LogEntryTile(
                            entry: log,
                            levelColor: _getLevelColor(log.level, colorScheme),
                            showDivider: index < logs.length - 1,
                          );
                        }),
                      ],
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;
  final Color levelColor;
  final bool showDivider;

  const _LogEntryTile({
    required this.entry,
    required this.levelColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = entry.level == 'ERROR' || entry.level == 'FATAL';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isError 
                ? colorScheme.errorContainer.withValues(alpha: 0.2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.formattedTime,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.level,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                  ),
                  if (entry.isFromGo) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Go',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                entry.message,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
              if (entry.error != null) ...[
                const SizedBox(height: 4),
                Text(
                  entry.error!,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: colorScheme.error,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

/// Summary card showing detected issues in logs
class _LogSummaryCard extends StatelessWidget {
  final List<LogEntry> logs;

  const _LogSummaryCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final analysis = _analyzeLogs();
    
    if (!analysis.hasIssues) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: analysis.hasISPBlocking 
            ? colorScheme.errorContainer.withValues(alpha: 0.5)
            : colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    analysis.hasISPBlocking ? Icons.block : Icons.warning_amber_rounded,
                    size: 20,
                    color: analysis.hasISPBlocking ? colorScheme.error : colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Issue Summary',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (analysis.hasISPBlocking) ...[
                _IssueBadge(
                  icon: Icons.block,
                  label: 'ISP BLOCKING DETECTED',
                  description: 'Your ISP may be blocking access to download services',
                  suggestion: 'Try using a VPN or change DNS to 1.1.1.1 or 8.8.8.8',
                  color: colorScheme.error,
                  domains: analysis.blockedDomains,
                ),
                const SizedBox(height: 8),
              ],
              
              if (analysis.hasRateLimit) ...[
                _IssueBadge(
                  icon: Icons.speed,
                  label: 'RATE LIMITED',
                  description: 'Too many requests to the service',
                  suggestion: 'Wait a few minutes before trying again',
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
              ],
              
              if (analysis.hasNetworkError && !analysis.hasISPBlocking) ...[
                _IssueBadge(
                  icon: Icons.wifi_off,
                  label: 'NETWORK ERROR',
                  description: 'Connection issues detected',
                  suggestion: 'Check your internet connection',
                  color: colorScheme.tertiary,
                ),
                const SizedBox(height: 8),
              ],
              
              if (analysis.hasNotFound) ...[
                _IssueBadge(
                  icon: Icons.search_off,
                  label: 'TRACK NOT FOUND',
                  description: 'Some tracks could not be found on download services',
                  suggestion: 'The track may not be available in lossless quality',
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
              
              const SizedBox(height: 12),
              Text(
                'Total errors: ${analysis.errorCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _LogAnalysis _analyzeLogs() {
    int errorCount = 0;
    bool hasISPBlocking = false;
    bool hasRateLimit = false;
    bool hasNetworkError = false;
    bool hasNotFound = false;
    final Set<String> blockedDomains = {};

    for (final log in logs) {
      if (log.level == 'ERROR' || log.level == 'FATAL') {
        errorCount++;
      }

      final msgLower = log.message.toLowerCase();
      final errorLower = (log.error ?? '').toLowerCase();
      final combined = '$msgLower $errorLower';

      if (combined.contains('isp blocking') ||
          combined.contains('isp may be') ||
          combined.contains('blocked by isp') ||
          combined.contains('connection reset') ||
          combined.contains('connection refused')) {
        hasISPBlocking = true;
        
        final domainMatch = RegExp(r'domain:\s*([^\s,]+)', caseSensitive: false).firstMatch(combined);
        if (domainMatch != null) {
          blockedDomains.add(domainMatch.group(1)!);
        }
      }

      if (combined.contains('rate limit') ||
          combined.contains('429') ||
          combined.contains('too many requests')) {
        hasRateLimit = true;
      }

      if (combined.contains('connection') ||
          combined.contains('timeout') ||
          combined.contains('network') ||
          combined.contains('dial')) {
        hasNetworkError = true;
      }

      if (combined.contains('not found') ||
          combined.contains('no results') ||
          combined.contains('could not find')) {
        hasNotFound = true;
      }
    }

    return _LogAnalysis(
      errorCount: errorCount,
      hasISPBlocking: hasISPBlocking,
      hasRateLimit: hasRateLimit,
      hasNetworkError: hasNetworkError,
      hasNotFound: hasNotFound,
      blockedDomains: blockedDomains.toList(),
    );
  }
}

class _LogAnalysis {
  final int errorCount;
  final bool hasISPBlocking;
  final bool hasRateLimit;
  final bool hasNetworkError;
  final bool hasNotFound;
  final List<String> blockedDomains;

  _LogAnalysis({
    required this.errorCount,
    required this.hasISPBlocking,
    required this.hasRateLimit,
    required this.hasNetworkError,
    required this.hasNotFound,
    required this.blockedDomains,
  });

  bool get hasIssues => errorCount > 0 || hasISPBlocking || hasRateLimit || hasNetworkError || hasNotFound;
}

class _IssueBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final String suggestion;
  final Color color;
  final List<String>? domains;

  const _IssueBadge({
    required this.icon,
    required this.label,
    required this.description,
    required this.suggestion,
    required this.color,
    this.domains,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          if (domains != null && domains!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Affected: ${domains!.join(", ")}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  suggestion,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
