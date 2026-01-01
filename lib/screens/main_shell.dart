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
      print('[MainShell] Processing pending shared URL: $pendingUrl');
      _handleSharedUrl(pendingUrl);
    }

    // Listen for future shared URLs
    _shareSubscription = ShareIntentService().sharedUrlStream.listen((url) {
      print('[MainShell] Received shared URL from stream: $url');
      _handleSharedUrl(url);
    });
  }

  void _handleSharedUrl(String url) {
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

    final updateInfo = await UpdateChecker.checkForUpdate();
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

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(downloadQueueProvider.select((s) => s.queuedCount));
    final trackState = ref.watch(trackProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // If on Search tab and can go back in track history, go back
        if (_currentIndex == 0 && trackState.canGoBack) {
          ref.read(trackProvider.notifier).goBack();
          return;
        }
        
        // If not on Search tab, go to Search tab first
        if (_currentIndex != 0) {
          _onNavTap(0);
          return;
        }
        
        // Already at root, show exit dialog
        final shouldPop = await _showExitDialog();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
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
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Search',
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
