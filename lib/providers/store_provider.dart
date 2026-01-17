import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/constants/app_info.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';

final _log = AppLogger('StoreProvider');

/// Compare two semantic version strings
/// Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
int compareVersions(String v1, String v2) {
  final parts1 = v1.replaceAll(RegExp(r'^v'), '').split('.');
  final parts2 = v2.replaceAll(RegExp(r'^v'), '').split('.');
  
  final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
  
  for (var i = 0; i < maxLen; i++) {
    final n1 = i < parts1.length ? (int.tryParse(parts1[i]) ?? 0) : 0;
    final n2 = i < parts2.length ? (int.tryParse(parts2[i]) ?? 0) : 0;
    
    if (n1 < n2) return -1;
    if (n1 > n2) return 1;
  }
  return 0;
}

/// Extension categories
class StoreCategory {
  static const String metadata = 'metadata';
  static const String download = 'download';
  static const String utility = 'utility';
  static const String lyrics = 'lyrics';
  static const String integration = 'integration';

  static const List<String> all = [metadata, download, utility, lyrics, integration];

  static String getDisplayName(String category) {
    switch (category) {
      case metadata:
        return 'Metadata';
      case download:
        return 'Download';
      case utility:
        return 'Utility';
      case lyrics:
        return 'Lyrics';
      case integration:
        return 'Integration';
      default:
        return category;
    }
  }
}

/// Represents an extension in the store
class StoreExtension {
  final String id;
  final String name;
  final String displayName;
  final String version;
  final String author;
  final String description;
  final String downloadUrl;
  final String? iconUrl;
  final String category;
  final List<String> tags;
  final int downloads;
  final String updatedAt;
  final String? minAppVersion;
  final bool isInstalled;
  final String? installedVersion;
  final bool hasUpdate;

  const StoreExtension({
    required this.id,
    required this.name,
    required this.displayName,
    required this.version,
    required this.author,
    required this.description,
    required this.downloadUrl,
    this.iconUrl,
    required this.category,
    this.tags = const [],
    this.downloads = 0,
    required this.updatedAt,
    this.minAppVersion,
    this.isInstalled = false,
    this.installedVersion,
    this.hasUpdate = false,
  });

  factory StoreExtension.fromJson(Map<String, dynamic> json) {
    return StoreExtension(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['name'] as String? ?? '',
      version: json['version'] as String? ?? '0.0.0',
      author: json['author'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      category: json['category'] as String? ?? 'utility',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      downloads: json['downloads'] as int? ?? 0,
      updatedAt: json['updated_at'] as String? ?? '',
      minAppVersion: json['min_app_version'] as String?,
      isInstalled: json['is_installed'] as bool? ?? false,
      installedVersion: json['installed_version'] as String?,
      hasUpdate: json['has_update'] as bool? ?? false,
    );
  }

  /// Check if this extension requires a higher app version than current
  bool get requiresNewerApp {
    if (minAppVersion == null || minAppVersion!.isEmpty) return false;
    return compareVersions(minAppVersion!, AppInfo.version) > 0;
  }
}

/// State for extension store
class StoreState {
  final List<StoreExtension> extensions;
  final String? selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final bool isDownloading;
  final String? downloadingId;
  final String? error;
  final bool isInitialized;

  const StoreState({
    this.extensions = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.isLoading = false,
    this.isDownloading = false,
    this.downloadingId,
    this.error,
    this.isInitialized = false,
  });

  StoreState copyWith({
    List<StoreExtension>? extensions,
    String? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    bool? isLoading,
    bool? isDownloading,
    String? downloadingId,
    bool clearDownloadingId = false,
    String? error,
    bool clearError = false,
    bool? isInitialized,
  }) {
    return StoreState(
      extensions: extensions ?? this.extensions,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadingId: clearDownloadingId ? null : (downloadingId ?? this.downloadingId),
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  /// Get filtered extensions based on category and search
  List<StoreExtension> get filteredExtensions {
    var result = extensions;

    if (selectedCategory != null) {
      result = result.where((e) => e.category == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((e) =>
        e.name.toLowerCase().contains(query) ||
        e.displayName.toLowerCase().contains(query) ||
        e.description.toLowerCase().contains(query) ||
        e.author.toLowerCase().contains(query) ||
        e.tags.any((t) => t.toLowerCase().contains(query))
      ).toList();
    }

    return result;
  }

  /// Count of extensions with updates available
  int get updatesAvailableCount {
    return extensions.where((e) => e.hasUpdate).length;
  }
}

/// Provider for managing extension store
class StoreNotifier extends Notifier<StoreState> {
  @override
  StoreState build() {
    return const StoreState();
  }

  /// Initialize the store
  Future<void> initialize(String cacheDir) async {
    if (state.isInitialized) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await PlatformBridge.initExtensionStore(cacheDir);
      await refresh();
      state = state.copyWith(isInitialized: true, isLoading: false);
      _log.i('Extension store initialized');
    } catch (e) {
      _log.e('Failed to initialize store: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh extensions from store
  Future<void> refresh({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final extensions = await PlatformBridge.getStoreExtensions(forceRefresh: forceRefresh);
      state = state.copyWith(
        extensions: extensions.map((e) => StoreExtension.fromJson(e)).toList(),
        isLoading: false,
      );
      _log.d('Loaded ${state.extensions.length} extensions from store');
    } catch (e) {
      _log.e('Failed to refresh store: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set category filter
  void setCategory(String? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(searchQuery: '', clearCategory: true);
  }

  /// Download and install extension
  Future<bool> installExtension(String extensionId, String tempDir, String extensionsDir) async {
    state = state.copyWith(isDownloading: true, downloadingId: extensionId, clearError: true);

    try {
      _log.i('Downloading extension: $extensionId');
      final downloadPath = await PlatformBridge.downloadStoreExtension(extensionId, tempDir);

      _log.i('Installing extension from: $downloadPath');
      final extNotifier = ref.read(extensionProvider.notifier);
      final success = await extNotifier.installExtension(downloadPath);

      if (success) {
        _log.i('Extension installed: $extensionId');
        await refresh();
      }

      state = state.copyWith(isDownloading: false, clearDownloadingId: true);
      return success;
    } catch (e) {
      _log.e('Failed to install extension: $e');
      state = state.copyWith(isDownloading: false, clearDownloadingId: true, error: e.toString());
      return false;
    }
  }

  /// Update an installed extension
  Future<bool> updateExtension(String extensionId, String tempDir) async {
    state = state.copyWith(isDownloading: true, downloadingId: extensionId, clearError: true);

    try {
      _log.i('Downloading update for: $extensionId');
      final downloadPath = await PlatformBridge.downloadStoreExtension(extensionId, tempDir);

      _log.i('Upgrading extension from: $downloadPath');
      final extNotifier = ref.read(extensionProvider.notifier);
      final success = await extNotifier.upgradeExtension(downloadPath);

      if (success) {
        _log.i('Extension updated: $extensionId');
        await refresh();
      }

      state = state.copyWith(isDownloading: false, clearDownloadingId: true);
      return success;
    } catch (e) {
      _log.e('Failed to update extension: $e');
      state = state.copyWith(isDownloading: false, clearDownloadingId: true, error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final storeProvider = NotifierProvider<StoreNotifier, StoreState>(
  StoreNotifier.new,
);
