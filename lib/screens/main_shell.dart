import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/screens/home_tab.dart';
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
  DateTime? _lastBackPress; // For double-tap to exit

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // Check for updates after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _setupShareListener();
    });
  }

  void _setupShareListener() {
    // Check for pending URL that was received before listener was ready
    final pendingUrl = ShareIntentService().consumePendingUrl();
    if (pendingUrl != null) {
      _log.d('Processing pending shared URL: $pendingUrl');
      _handleSharedUrl(pendingUrl);
    }

    // Listen for future shared URLs with error handling
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
    // Pop any existing screens (Album, Artist, Settings sub-pages) to return to root
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // Navigate to Home tab
    if (_currentIndex != 0) {
      _onNavTap(0);
    }
    // Fetch metadata for shared URL
    ref.read(trackProvider.notifier).fetchFromUrl(url);
    // Mark that user has searched (hide helper text)
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loading shared link...')),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    if (_hasCheckedUpdate) return;
    _hasCheckedUpdate = true;

    final settings = ref.read(settingsProvider);
    if (!settings.checkForUpdates) return;

    final updateInfo = await UpdateChecker.checkForUpdate(channel: settings.updateChannel);
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
    }
  }

  /// Handle back press with double-tap to exit
  void _handleBackPress() {
    final trackState = ref.read(trackProvider);
    
    // Check if keyboard is visible - if so, just dismiss keyboard, don't clear search
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardVisible) {
      FocusScope.of(context).unfocus();
      return;
    }
    
    // If on Home tab and has text in search bar or has content (but not loading), clear it
    if (_currentIndex == 0 && !trackState.isLoading && (trackState.hasSearchText || trackState.hasContent)) {
      ref.read(trackProvider.notifier).clear();
      return;
    }
    
    // If not on Home tab, go to Home tab first
    if (_currentIndex != 0) {
      _onNavTap(0);
      return;
    }
    
    // If loading, ignore back press
    if (trackState.isLoading) {
      return;
    }
    
    // Double-tap to exit
    final now = DateTime.now();
    if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
    } else {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(downloadQueueProvider.select((s) => s.queuedCount));
    final trackState = ref.watch(trackProvider);
    
    // Check if keyboard is visible (bottom inset > 0 means keyboard is showing)
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    // Determine if we can pop (for predictive back animation)
    // canPop is true when we're at root with no content - enables predictive back gesture
    // IMPORTANT: Never allow pop when keyboard is visible to prevent accidental navigation
    final canPop = _currentIndex == 0 && 
                   !trackState.hasSearchText && 
                   !trackState.hasContent && 
                   !trackState.isLoading &&
                   !isKeyboardVisible;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // System handled the pop - this means predictive back completed
          // We need to handle double-tap to exit here
          return;
        }
        
        // Handle back press manually when canPop is false
        _handleBackPress();
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: const [
            HomeTab(),
            QueueTab(),
            SettingsTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavTap,
          animationDuration: const Duration(milliseconds: 200),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), Theme.of(context).colorScheme.surface)
              : Color.alphaBlend(Colors.black.withValues(alpha: 0.03), Theme.of(context).colorScheme.surface),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: queueState > 0,
                label: Text('$queueState'),
                child: const Icon(Icons.history_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: queueState > 0,
                label: Text('$queueState'),
                child: const Icon(Icons.history),
              ),
              label: 'History',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
