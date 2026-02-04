import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/store_provider.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/screens/home_tab.dart';
import 'package:spotiflac_android/screens/store_tab.dart';
import 'package:spotiflac_android/screens/queue_tab.dart';
import 'package:spotiflac_android/screens/settings/settings_tab.dart';
import 'package:spotiflac_android/services/share_intent_service.dart';
import 'package:spotiflac_android/services/update_checker.dart';
import 'package:spotiflac_android/widgets/update_dialog.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('MainShell');

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  late PageController _pageController;
  bool _hasCheckedUpdate = false;
  StreamSubscription<String>? _shareSubscription;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _setupShareListener();
    });
  }

  void _setupShareListener() {
    final pendingUrl = ShareIntentService().consumePendingUrl();
    if (pendingUrl != null) {
      _log.d('Processing pending shared URL: $pendingUrl');
      _handleSharedUrl(pendingUrl);
    }

    _shareSubscription = ShareIntentService().sharedUrlStream.listen(
      (url) {
        _log.d('Received shared URL from stream: $url');
        _handleSharedUrl(url);
      },
      onError: (error) {
        _log.e('Share stream error: $error');
      },
      cancelOnError: false,
    );
  }

  void _handleSharedUrl(String url) {
    Navigator.of(context).popUntil((route) => route.isFirst);

    if (_currentIndex != 0) {
      _onNavTap(0);
    }
    ref.read(trackProvider.notifier).fetchFromUrl(url);
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.loadingSharedLink)));
    }
  }

  Future<void> _checkForUpdates() async {
    if (_hasCheckedUpdate) return;
    _hasCheckedUpdate = true;

    final settings = ref.read(settingsProvider);
    if (!settings.checkForUpdates) return;

    final updateInfo = await UpdateChecker.checkForUpdate(
      channel: settings.updateChannel,
    );
    if (updateInfo != null && mounted) {
      showUpdateDialog(
        context,
        updateInfo: updateInfo,
        onDisableUpdates: () {
          ref.read(settingsProvider.notifier).setCheckForUpdates(false);
        },
      );
    }
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _handleBackPress() {
    final trackState = ref.read(trackProvider);

    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardVisible) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    if (_currentIndex == 0 && trackState.isShowingRecentAccess) {
      ref.read(trackProvider.notifier).setShowingRecentAccess(false);
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    if (_currentIndex == 0 &&
        !trackState.isLoading &&
        (trackState.hasSearchText || trackState.hasContent)) {
      ref.read(trackProvider.notifier).clear();
      return;
    }

    if (_currentIndex != 0) {
      _onNavTap(0);
      return;
    }

    if (trackState.isLoading) {
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
    } else {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pressBackAgainToExit),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(
      downloadQueueProvider.select((s) => s.queuedCount),
    );
    final trackState = ref.watch(trackProvider);
    final showStore = ref.watch(
      settingsProvider.select((s) => s.showExtensionStore),
    );
    final storeUpdatesCount = ref.watch(
      storeProvider.select((s) => s.updatesAvailableCount),
    );

    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    final canPop =
        _currentIndex == 0 &&
        !trackState.hasSearchText &&
        !trackState.hasContent &&
        !trackState.isLoading &&
        !trackState.isShowingRecentAccess &&
        !isKeyboardVisible;

    final tabs = <Widget>[
      const HomeTab(),
      QueueTab(
        parentPageController: _pageController,
        parentPageIndex: 1,
        nextPageIndex: showStore ? 2 : 3,
      ),
      if (showStore) const StoreTab(),
      const SettingsTab(),
    ];

    final l10n = context.l10n;
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: BouncingIcon(child: const Icon(Icons.home)),
        label: l10n.navHome,
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: queueState > 0,
          label: Text('$queueState'),
          child: const Icon(Icons.library_music_outlined),
        ),
        selectedIcon: SlidingIcon(
          child: Badge(
            isLabelVisible: queueState > 0,
            label: Text('$queueState'),
            child: const Icon(Icons.library_music),
          ),
        ),
        label: l10n.navLibrary,
      ),
      if (showStore)
        NavigationDestination(
          icon: Badge(
            isLabelVisible: storeUpdatesCount > 0,
            label: Text('$storeUpdatesCount'),
            child: const Icon(Icons.store_outlined),
          ),
          selectedIcon: SwingIcon(
            child: Badge(
              isLabelVisible: storeUpdatesCount > 0,
              label: Text('$storeUpdatesCount'),
              child: const Icon(Icons.store),
            ),
          ),
          label: l10n.navStore,
        ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: SpinIcon(child: const Icon(Icons.settings)),
        label: l10n.navSettings,
      ),
    ];

    final maxIndex = tabs.length - 1;
    if (_currentIndex > maxIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentIndex = maxIndex);
          _pageController.jumpToPage(maxIndex);
        }
      });
    }

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        _handleBackPress();
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const ClampingScrollPhysics(),
          children: tabs,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex.clamp(0, maxIndex),
          onDestinationSelected: _onNavTap,
          animationDuration: const Duration(milliseconds: 500),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.05),
                  Theme.of(context).colorScheme.surface,
                )
              : Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.03),
                  Theme.of(context).colorScheme.surface,
                ),
          destinations: destinations,
        ),
      ),
    );
  }
}

class BouncingIcon extends StatefulWidget {
  final Widget child;
  const BouncingIcon({super.key, required this.child});

  @override
  State<BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<BouncingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.1,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

class SlidingIcon extends StatefulWidget {
  final Widget child;
  const SlidingIcon({super.key, required this.child});

  @override
  State<SlidingIcon> createState() => _SlidingIconState();
}

class _SlidingIconState extends State<SlidingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _offsetAnimation, child: widget.child),
    );
  }
}

class SwingIcon extends StatefulWidget {
  final Widget child;
  const SwingIcon({super.key, required this.child});

  @override
  State<SwingIcon> createState() => _SwingIconState();
}

class _SwingIconState extends State<SwingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    // Create a swinging motion (like a pendulum/sign)
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.15), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SpinIcon extends StatefulWidget {
  final Widget child;
  const SpinIcon({super.key, required this.child});

  @override
  State<SpinIcon> createState() => _SpinIconState();
}

class _SpinIconState extends State<SpinIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(turns: _rotationAnimation, child: widget.child);
  }
}
