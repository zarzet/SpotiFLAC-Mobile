import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/screens/settings/lyrics_provider_priority_page.dart';
import 'package:spotiflac_android/widgets/settings_group.dart';

class LyricsSettingsPage extends ConsumerWidget {
  const LyricsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
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
                    titlePadding: EdgeInsets.only(
                      left: leftPadding,
                      bottom: 16,
                    ),
                    title: Text(
                      context.l10n.settingsLyrics,
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

            // ── Lyrics Embedding ───────────────────────────────────────
            SliverToBoxAdapter(
              child: SettingsSectionHeader(title: context.l10n.sectionLyrics),
            ),
            SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.subtitles_outlined,
                    title: context.l10n.optionsEmbedLyrics,
                    subtitle: settings.embedMetadata
                        ? context.l10n.optionsEmbedLyricsSubtitle
                        : context.l10n.downloadEmbedLyricsDisabled,
                    value: settings.embedLyrics,
                    enabled: settings.embedMetadata,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setEmbedLyrics(value),
                    showDivider:
                        settings.embedMetadata && settings.embedLyrics,
                  ),
                  if (settings.embedMetadata && settings.embedLyrics) ...[
                    SettingsItem(
                      icon: Icons.lyrics_outlined,
                      title: context.l10n.lyricsMode,
                      subtitle: _getLyricsModeLabel(
                        context,
                        settings.lyricsMode,
                      ),
                      onTap: () =>
                          _showLyricsModePicker(context, ref, settings.lyricsMode),
                    ),
                    SettingsItem(
                      icon: Icons.source_outlined,
                      title: context.l10n.lyricsProvidersTitle,
                      subtitle: _getLyricsProvidersSubtitle(
                        context,
                        settings.lyricsProviders,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const LyricsProviderPriorityPage(),
                        ),
                      ),
                      showDivider: false,
                    ),
                  ],
                ],
              ),
            ),

            // ── Provider Options ───────────────────────────────────────
            if (settings.embedMetadata && settings.embedLyrics) ...[
              SliverToBoxAdapter(
                child: SettingsSectionHeader(
                  title: context.l10n.sectionLyricsProviderOptions,
                ),
              ),
              SliverToBoxAdapter(
                child: SettingsGroup(
                  children: [
                    SettingsSwitchItem(
                      icon: Icons.translate_outlined,
                      title: context.l10n.downloadNeteaseIncludeTranslation,
                      subtitle: settings.lyricsIncludeTranslationNetease
                          ? context.l10n.downloadNeteaseIncludeTranslationEnabled
                          : context.l10n.downloadNeteaseIncludeTranslationDisabled,
                      value: settings.lyricsIncludeTranslationNetease,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .setLyricsIncludeTranslationNetease(value),
                    ),
                    SettingsSwitchItem(
                      icon: Icons.text_fields_outlined,
                      title: context.l10n.downloadNeteaseIncludeRomanization,
                      subtitle: settings.lyricsIncludeRomanizationNetease
                          ? context
                                .l10n
                                .downloadNeteaseIncludeRomanizationEnabled
                          : context
                                .l10n
                                .downloadNeteaseIncludeRomanizationDisabled,
                      value: settings.lyricsIncludeRomanizationNetease,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .setLyricsIncludeRomanizationNetease(value),
                    ),
                    SettingsSwitchItem(
                      icon: Icons.record_voice_over_outlined,
                      title: context.l10n.downloadAppleQqMultiPerson,
                      subtitle: settings.lyricsMultiPersonWordByWord
                          ? context.l10n.downloadAppleQqMultiPersonEnabled
                          : context.l10n.downloadAppleQqMultiPersonDisabled,
                      value: settings.lyricsMultiPersonWordByWord,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .setLyricsMultiPersonWordByWord(value),
                    ),
                    SettingsItem(
                      icon: Icons.language_outlined,
                      title: context.l10n.downloadMusixmatchLanguage,
                      subtitle: settings.musixmatchLanguage.isEmpty
                          ? context.l10n.downloadMusixmatchLanguageAuto
                          : settings.musixmatchLanguage.toUpperCase(),
                      onTap: () => _showMusixmatchLanguagePicker(
                        context,
                        ref,
                        settings.musixmatchLanguage,
                      ),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _getLyricsModeLabel(BuildContext context, String mode) {
    switch (mode) {
      case 'external':
        return context.l10n.lyricsModeExternal;
      case 'both':
        return context.l10n.lyricsModeBoth;
      default:
        return context.l10n.lyricsModeEmbed;
    }
  }

  static const _providerDisplayNames = <String, String>{
    'lrclib': 'LRCLIB',
    'netease': 'Netease',
    'musixmatch': 'Musixmatch',
    'apple_music': 'Apple Music',
    'qqmusic': 'QQ Music',
  };

  String _getLyricsProvidersSubtitle(
    BuildContext context,
    List<String> providers,
  ) {
    if (providers.isEmpty) return context.l10n.downloadProvidersNoneEnabled;
    return providers
        .map((p) => _providerDisplayNames[p] ?? p)
        .join(' > ');
  }

  void _showLyricsModePicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                context.l10n.lyricsMode,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.lyricsModeDescription,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: Text(context.l10n.lyricsModeEmbed),
              subtitle: Text(context.l10n.lyricsModeEmbedSubtitle),
              trailing: current == 'embed' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLyricsMode('embed');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(context.l10n.lyricsModeExternal),
              subtitle: Text(context.l10n.lyricsModeExternalSubtitle),
              trailing: current == 'external' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLyricsMode('external');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_music_outlined),
              title: Text(context.l10n.lyricsModeBoth),
              subtitle: Text(context.l10n.lyricsModeBothSubtitle),
              trailing: current == 'both' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLyricsMode('both');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMusixmatchLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    String currentLanguage,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: currentLanguage);

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.downloadMusixmatchLanguage,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.downloadMusixmatchLanguageDesc,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.l10n.downloadMusixmatchLanguageCode,
                hintText: context.l10n.downloadMusixmatchLanguageHint,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.dialogCancel),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setMusixmatchLanguage('');
                    Navigator.pop(context);
                  },
                  child: Text(context.l10n.downloadMusixmatchAuto),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final normalized = controller.text
                        .trim()
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9\-_]'), '');
                    ref
                        .read(settingsProvider.notifier)
                        .setMusixmatchLanguage(normalized);
                    Navigator.pop(context);
                  },
                  child: Text(context.l10n.dialogSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
