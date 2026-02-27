import 'package:flutter/widgets.dart';

class ShellNavigationService {
  static final GlobalKey<NavigatorState> homeTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> libraryTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> storeTabNavigatorKey =
      GlobalKey<NavigatorState>();

  static int _currentTabIndex = 0;
  static bool _showStoreTab = false;

  static void syncState({
    required int currentTabIndex,
    required bool showStoreTab,
  }) {
    _currentTabIndex = currentTabIndex;
    _showStoreTab = showStoreTab;
  }

  static NavigatorState? activeTabNavigator() {
    if (_currentTabIndex == 0) return homeTabNavigatorKey.currentState;
    if (_currentTabIndex == 1) return libraryTabNavigatorKey.currentState;
    if (_showStoreTab && _currentTabIndex == 2) {
      return storeTabNavigatorKey.currentState;
    }
    return null;
  }
}
