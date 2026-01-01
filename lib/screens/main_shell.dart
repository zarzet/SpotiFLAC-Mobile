import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/screens/home_tab.dart';
import 'package:spotiflac_android/screens/queue_tab.dart';
import 'package:spotiflac_android/screens/settings_tab.dart';
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
  bool _isAnimating = false;

  // Cache tab widgets to prevent rebuilds
  final List<Widget> _tabs = const [
    HomeTab(),
    QueueTab(),
    SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // Check for updates after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
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
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex != index && !_isAnimating) {
      _isAnimating = true;
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ).then((_) => _isAnimating = false);
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(downloadQueueProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
            ),
          ),
        ),
        title: const Text('SpotiFLAC'),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavTap,
        animationDuration: const Duration(milliseconds: 300),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: queueState.queuedCount > 0,
              label: Text('${queueState.queuedCount}'),
              child: const Icon(Icons.download_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: queueState.queuedCount > 0,
              label: Text('${queueState.queuedCount}'),
              child: const Icon(Icons.download),
            ),
            label: 'Downloads',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
