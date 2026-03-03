import 'dart:io';

void main() {
  final file = File('lib/widgets/mini_player_bar.dart');
  var content = file.readAsStringSync();

  // Add dart:ui import
  if (!content.contains("import 'dart:ui';")) {
    content = content.replaceFirst(
      "import 'dart:async';",
      "import 'dart:async';\nimport 'dart:ui';",
    );
  }

  // Update Scaffold
  content = content.replaceFirst(
    '''
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
''',
    '''
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (item.coverUrl.isNotEmpty || item.hasLocalCover)
            _CoverArt(
              url: item.coverUrl,
              isLocal: item.hasLocalCover,
              size: double.infinity,
              borderRadius: 0,
            )
          else
            Container(color: colorScheme.surface),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
''',
  );

  // Update title and artist styles to be white and modern
  content = content.replaceAll(
    '''
                            style:
                                (isCompactLayout
                                        ? textTheme.titleMedium
                                        : textTheme.titleLarge)
                                    ?.copyWith(fontWeight: FontWeight.w700),
''',
    '''
                            style:
                                (isCompactLayout
                                        ? textTheme.titleMedium
                                        : textTheme.headlineSmall)
                                    ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
''',
  );

  content = content.replaceAll(
    '''
                            style:
                                (isCompactLayout
                                        ? textTheme.bodySmall
                                        : textTheme.bodyMedium)
                                    ?.copyWith(color: colorScheme.primary),
''',
    '''
                            style:
                                (isCompactLayout
                                        ? textTheme.bodyMedium
                                        : textTheme.titleMedium)
                                    ?.copyWith(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
''',
  );

  // Thicker modern slider
  content = content.replaceAll(
    '''
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor: colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                        ),
''',
    '''
                        data: SliderThemeData(
                          trackHeight: 5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 0, // Hidden when not dragged
                            elevationOverride: 0,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10,
                          ),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withValues(
                            alpha: 0.2,
                          ),
                          thumbColor: Colors.white,
                        ),
''',
  );

  // Add margin and clip to cover art
  content = content.replaceFirst(
    '''
              child: _CoverArt(
                url: item.coverUrl,
                isLocal: item.hasLocalCover,
                size: double.infinity,
                borderRadius: 20,
              ),
''',
    '''
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: _CoverArt(
                  url: item.coverUrl,
                  isLocal: item.hasLocalCover,
                  size: double.infinity,
                  borderRadius: 20,
                ),
              ),
''',
  );

  file.writeAsStringSync(content);
}
