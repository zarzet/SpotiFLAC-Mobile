import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';

final _log = AppLogger('ExtensionProvider');

const _metadataProviderPriorityKey = 'metadata_provider_priority';
const _providerPriorityKey = 'provider_priority';

class Extension {
  final String id;
  final String name;
  final String displayName;
  final String version;
  final String author;
  final String description;
  final bool enabled;
  final String status;
  final String? errorMessage;
  final String? iconPath;
  final List<String> permissions;
  final List<ExtensionSetting> settings;
  final List<QualityOption> qualityOptions;
  final bool hasMetadataProvider;
  final bool hasDownloadProvider;
  final bool hasLyricsProvider;
  final bool skipMetadataEnrichment; // If true, use metadata from extension instead of enriching
  final SearchBehavior? searchBehavior;
  final URLHandler? urlHandler;
  final TrackMatching? trackMatching;
  final PostProcessing? postProcessing;
  final Map<String, dynamic> capabilities; // Extension capabilities (homeFeed, browseCategories, etc.)

  const Extension({
    required this.id,
    required this.name,
    required this.displayName,
    required this.version,
    required this.author,
    required this.description,
    required this.enabled,
    required this.status,
    this.errorMessage,
    this.iconPath,
    this.permissions = const [],
    this.settings = const [],
    this.qualityOptions = const [],
    this.hasMetadataProvider = false,
    this.hasDownloadProvider = false,
    this.hasLyricsProvider = false,
    this.skipMetadataEnrichment = false,
    this.searchBehavior,
    this.urlHandler,
    this.trackMatching,
    this.postProcessing,
    this.capabilities = const {},
  });

  factory Extension.fromJson(Map<String, dynamic> json) {
    return Extension(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['name'] as String? ?? '',
      version: json['version'] as String? ?? '0.0.0',
      author: json['author'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      status: json['status'] as String? ?? 'loaded',
      errorMessage: json['error_message'] as String?,
      iconPath: json['icon_path'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)?.cast<String>() ?? [],
      settings: (json['settings'] as List<dynamic>?)
          ?.map((s) => ExtensionSetting.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      qualityOptions: (json['quality_options'] as List<dynamic>?)
          ?.map((q) => QualityOption.fromJson(q as Map<String, dynamic>))
          .toList() ?? [],
      hasMetadataProvider: json['has_metadata_provider'] as bool? ?? false,
      hasDownloadProvider: json['has_download_provider'] as bool? ?? false,
      hasLyricsProvider: json['has_lyrics_provider'] as bool? ?? false,
      skipMetadataEnrichment: json['skip_metadata_enrichment'] as bool? ?? false,
      searchBehavior: json['search_behavior'] != null 
          ? SearchBehavior.fromJson(json['search_behavior'] as Map<String, dynamic>)
          : null,
      urlHandler: json['url_handler'] != null
          ? URLHandler.fromJson(json['url_handler'] as Map<String, dynamic>)
          : null,
      trackMatching: json['track_matching'] != null
          ? TrackMatching.fromJson(json['track_matching'] as Map<String, dynamic>)
          : null,
      postProcessing: json['post_processing'] != null
          ? PostProcessing.fromJson(json['post_processing'] as Map<String, dynamic>)
          : null,
      capabilities: (json['capabilities'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Extension copyWith({
    String? id,
    String? name,
    String? displayName,
    String? version,
    String? author,
    String? description,
    bool? enabled,
    String? status,
    String? errorMessage,
    String? iconPath,
    List<String>? permissions,
    List<ExtensionSetting>? settings,
    List<QualityOption>? qualityOptions,
    bool? hasMetadataProvider,
    bool? hasDownloadProvider,
    bool? hasLyricsProvider,
    bool? skipMetadataEnrichment,
    SearchBehavior? searchBehavior,
    URLHandler? urlHandler,
    TrackMatching? trackMatching,
    PostProcessing? postProcessing,
    Map<String, dynamic>? capabilities,
  }) {
    return Extension(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      version: version ?? this.version,
      author: author ?? this.author,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      iconPath: iconPath ?? this.iconPath,
      permissions: permissions ?? this.permissions,
      settings: settings ?? this.settings,
      qualityOptions: qualityOptions ?? this.qualityOptions,
      hasMetadataProvider: hasMetadataProvider ?? this.hasMetadataProvider,
      hasDownloadProvider: hasDownloadProvider ?? this.hasDownloadProvider,
      hasLyricsProvider: hasLyricsProvider ?? this.hasLyricsProvider,
      skipMetadataEnrichment: skipMetadataEnrichment ?? this.skipMetadataEnrichment,
      searchBehavior: searchBehavior ?? this.searchBehavior,
      urlHandler: urlHandler ?? this.urlHandler,
      trackMatching: trackMatching ?? this.trackMatching,
      postProcessing: postProcessing ?? this.postProcessing,
      capabilities: capabilities ?? this.capabilities,
    );
  }

  bool get hasCustomSearch => searchBehavior?.enabled ?? false;
  bool get hasURLHandler => urlHandler?.enabled ?? false;
  bool get hasCustomMatching => trackMatching?.customMatching ?? false;
  bool get hasPostProcessing => postProcessing?.enabled ?? false;
  bool get hasHomeFeed => capabilities['homeFeed'] == true;
  bool get hasBrowseCategories => capabilities['browseCategories'] == true;
}

class SearchFilter {
  final String id;
  final String? label;
  final String? icon;

  const SearchFilter({
    required this.id,
    this.label,
    this.icon,
  });

  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter(
      id: json['id'] as String? ?? '',
      label: json['label'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

class SearchBehavior {
  final bool enabled;
  final String? placeholder;
  final bool primary;
  final String? icon;
  final String? thumbnailRatio; // "square" (1:1), "wide" (16:9), "portrait" (2:3)
  final int? thumbnailWidth;
  final int? thumbnailHeight;
  final List<SearchFilter> filters; // Available search filters (e.g., track, album, artist, playlist)

  const SearchBehavior({
    required this.enabled,
    this.placeholder,
    this.primary = false,
    this.icon,
    this.thumbnailRatio,
    this.thumbnailWidth,
    this.thumbnailHeight,
    this.filters = const [],
  });

  factory SearchBehavior.fromJson(Map<String, dynamic> json) {
    return SearchBehavior(
      enabled: json['enabled'] as bool? ?? false,
      placeholder: json['placeholder'] as String?,
      primary: json['primary'] as bool? ?? false,
      icon: json['icon'] as String?,
      thumbnailRatio: json['thumbnailRatio'] as String?,
      thumbnailWidth: json['thumbnailWidth'] as int?,
      thumbnailHeight: json['thumbnailHeight'] as int?,
      filters: (json['filters'] as List<dynamic>?)
          ?.map((f) => SearchFilter.fromJson(f as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  (double, double) getThumbnailSize({double defaultSize = 56}) {
    if (thumbnailWidth != null && thumbnailHeight != null) {
      return (thumbnailWidth!.toDouble(), thumbnailHeight!.toDouble());
    }
    
    switch (thumbnailRatio) {
      case 'wide': // 16:9 - YouTube style
        return (defaultSize * 16 / 9, defaultSize);
      case 'portrait': // 2:3 - Poster style
        return (defaultSize * 2 / 3, defaultSize);
      case 'square': // 1:1 - Album art style
      default:
        return (defaultSize, defaultSize);
    }
  }
}

class TrackMatching {
  final bool customMatching;
  final String? strategy;
  final int durationTolerance;

  const TrackMatching({
    required this.customMatching,
    this.strategy,
    this.durationTolerance = 3,
  });

  factory TrackMatching.fromJson(Map<String, dynamic> json) {
    return TrackMatching(
      customMatching: json['customMatching'] as bool? ?? false,
      strategy: json['strategy'] as String?,
      durationTolerance: json['durationTolerance'] as int? ?? 3,
    );
  }
}

class PostProcessing {
  final bool enabled;
  final List<PostProcessingHook> hooks;

  const PostProcessing({
    required this.enabled,
    this.hooks = const [],
  });

  factory PostProcessing.fromJson(Map<String, dynamic> json) {
    return PostProcessing(
      enabled: json['enabled'] as bool? ?? false,
      hooks: (json['hooks'] as List<dynamic>?)
          ?.map((h) => PostProcessingHook.fromJson(h as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

/// URL handler configuration for custom URL patterns
class URLHandler {
  final bool enabled;
  final List<String> patterns;

  const URLHandler({
    required this.enabled,
    this.patterns = const [],
  });

  factory URLHandler.fromJson(Map<String, dynamic> json) {
    return URLHandler(
      enabled: json['enabled'] as bool? ?? false,
      patterns: (json['patterns'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Check if a URL matches any of the patterns
  bool matchesURL(String url) {
    if (!enabled || patterns.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    for (final pattern in patterns) {
      if (lowerUrl.contains(pattern.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}

class PostProcessingHook {
  final String id;
  final String name;
  final String? description;
  final bool defaultEnabled;
  final List<String> supportedFormats;

  const PostProcessingHook({
    required this.id,
    required this.name,
    this.description,
    this.defaultEnabled = false,
    this.supportedFormats = const [],
  });

  factory PostProcessingHook.fromJson(Map<String, dynamic> json) {
    return PostProcessingHook(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      defaultEnabled: json['defaultEnabled'] as bool? ?? false,
      supportedFormats: (json['supportedFormats'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class QualityOption {
  final String id;
  final String label;
  final String? description;
  final List<QualitySpecificSetting> settings;

  const QualityOption({
    required this.id,
    required this.label,
    this.description,
    this.settings = const [],
  });

  factory QualityOption.fromJson(Map<String, dynamic> json) {
    return QualityOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String?,
      settings: (json['settings'] as List<dynamic>?)
          ?.map((s) => QualitySpecificSetting.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class QualitySpecificSetting {
  final String key;
  final String label;
  final String type;
  final dynamic defaultValue;
  final String? description;
  final List<String>? options;
  final bool required;
  final bool secret;

  const QualitySpecificSetting({
    required this.key,
    required this.label,
    required this.type,
    this.defaultValue,
    this.description,
    this.options,
    this.required = false,
    this.secret = false,
  });

  factory QualitySpecificSetting.fromJson(Map<String, dynamic> json) {
    return QualitySpecificSetting(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      defaultValue: json['default'],
      description: json['description'] as String?,
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      required: json['required'] as bool? ?? false,
      secret: json['secret'] as bool? ?? false,
    );
  }
}

class ExtensionSetting {
  final String key;
  final String label;
  final String type;
  final dynamic defaultValue;
  final String? description;
  final List<String>? options;
  final bool required;
  final String? action;

  const ExtensionSetting({
    required this.key,
    required this.label,
    required this.type,
    this.defaultValue,
    this.description,
    this.options,
    this.required = false,
    this.action,
  });

  factory ExtensionSetting.fromJson(Map<String, dynamic> json) {
    return ExtensionSetting(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      defaultValue: json['default'],
      description: json['description'] as String?,
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      required: json['required'] as bool? ?? false,
      action: json['action'] as String?,
    );
  }
}

class ExtensionState {
  final List<Extension> extensions;
  final List<String> providerPriority;
  final List<String> metadataProviderPriority;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const ExtensionState({
    this.extensions = const [],
    this.providerPriority = const [],
    this.metadataProviderPriority = const [],
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  ExtensionState copyWith({
    List<Extension>? extensions,
    List<String>? providerPriority,
    List<String>? metadataProviderPriority,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return ExtensionState(
      extensions: extensions ?? this.extensions,
      providerPriority: providerPriority ?? this.providerPriority,
      metadataProviderPriority: metadataProviderPriority ?? this.metadataProviderPriority,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}


class ExtensionNotifier extends Notifier<ExtensionState> {
  @override
  ExtensionState build() {
    return const ExtensionState();
  }

  Future<void> initialize(String extensionsDir, String dataDir) async {
    if (state.isInitialized) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await PlatformBridge.initExtensionSystem(extensionsDir, dataDir);
      await loadExtensions(extensionsDir);
      await loadProviderPriority();
      await loadMetadataProviderPriority();
      state = state.copyWith(isInitialized: true, isLoading: false);
      _log.i('Extension system initialized');
    } catch (e) {
      _log.e('Failed to initialize extension system: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadExtensions(String dirPath) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await PlatformBridge.loadExtensionsFromDir(dirPath);
      _log.d('Load extensions result: $result');
      await refreshExtensions();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      _log.e('Failed to load extensions: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshExtensions() async {
    try {
      final list = await PlatformBridge.getInstalledExtensions();
      final extensions = list.map((e) => Extension.fromJson(e)).toList();
      state = state.copyWith(extensions: extensions);
      _log.d('Loaded ${extensions.length} extensions');
      
      for (final ext in extensions) {
        if (ext.searchBehavior != null) {
          _log.d('Extension ${ext.id}: thumbnailRatio=${ext.searchBehavior!.thumbnailRatio}');
        }
      }
    } catch (e) {
      _log.e('Failed to refresh extensions: $e');
      state = state.copyWith(error: e.toString());
    }
  }


  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> installExtension(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await PlatformBridge.loadExtensionFromPath(filePath);
      _log.i('Installed extension: ${result['name']}');
      await refreshExtensions();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      _log.e('Failed to install extension: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> checkExtensionUpgrade(String filePath) async {
    try {
      return await PlatformBridge.checkExtensionUpgrade(filePath);
    } catch (e) {
      _log.e('Failed to check extension upgrade: $e');
      return {'error': e.toString()};
    }
  }

  Future<bool> upgradeExtension(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await PlatformBridge.upgradeExtension(filePath);
      _log.i('Upgraded extension: ${result['display_name']} to v${result['version']}');
      await refreshExtensions();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      _log.e('Failed to upgrade extension: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> removeExtension(String extensionId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await PlatformBridge.removeExtension(extensionId);
      _log.i('Removed extension: $extensionId');
      await refreshExtensions();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      _log.e('Failed to remove extension: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }


  Future<void> setExtensionEnabled(String extensionId, bool enabled) async {
    try {
      await PlatformBridge.setExtensionEnabled(extensionId, enabled);
      _log.d('Set extension $extensionId enabled: $enabled');
      
      final ext = state.extensions.where((e) => e.id == extensionId).firstOrNull;
      
      final extensions = state.extensions.map((e) {
        if (e.id == extensionId) {
          return e.copyWith(enabled: enabled);
        }
        return e;
      }).toList();
      
      state = state.copyWith(extensions: extensions);
      
      if (!enabled && ext != null) {
        final settings = ref.read(settingsProvider);
        
        if (settings.searchProvider == extensionId) {
          ref.read(settingsProvider.notifier).setSearchProvider(null);
          ref.read(settingsProvider.notifier).setMetadataSource('deezer');
          _log.d('Cleared search provider and reset to Deezer because extension $extensionId was disabled');
        }
        
        if (ext.hasDownloadProvider && settings.defaultService == extensionId) {
          ref.read(settingsProvider.notifier).setDefaultService('tidal');
          _log.d('Reset default service to Tidal because extension $extensionId was disabled');
        }
      }
    } catch (e) {
      _log.e('Failed to set extension enabled: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Map<String, dynamic>> getExtensionSettings(String extensionId) async {
    try {
      return await PlatformBridge.getExtensionSettings(extensionId);
    } catch (e) {
      _log.e('Failed to get extension settings: $e');
      return {};
    }
  }

  Future<void> setExtensionSettings(String extensionId, Map<String, dynamic> settings) async {
    try {
      await PlatformBridge.setExtensionSettings(extensionId, settings);
      _log.d('Updated settings for extension: $extensionId');
    } catch (e) {
      _log.e('Failed to set extension settings: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadProviderPriority() async {
    try {
      // Load from SharedPreferences first (persisted)
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_providerPriorityKey);
      
      List<String> priority;
      if (savedJson != null) {
        final saved = jsonDecode(savedJson) as List<dynamic>;
        priority = saved.map((e) => e as String).toList();
        _log.d('Loaded provider priority from prefs: $priority');
        // Sync to Go backend
        await PlatformBridge.setProviderPriority(priority);
      } else {
        // Fallback to Go backend default
        priority = await PlatformBridge.getProviderPriority();
        _log.d('Using default provider priority: $priority');
      }
      
      state = state.copyWith(providerPriority: priority);
    } catch (e) {
      _log.e('Failed to load provider priority: $e');
    }
  }


  Future<void> setProviderPriority(List<String> priority) async {
    try {
      // Save to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_providerPriorityKey, jsonEncode(priority));
      
      // Sync to Go backend
      await PlatformBridge.setProviderPriority(priority);
      state = state.copyWith(providerPriority: priority);
      _log.d('Saved provider priority: $priority');
    } catch (e) {
      _log.e('Failed to set provider priority: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMetadataProviderPriority() async {
    try {
      // Load from SharedPreferences first (persisted)
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_metadataProviderPriorityKey);
      
      List<String> priority;
      if (savedJson != null) {
        final saved = jsonDecode(savedJson) as List<dynamic>;
        priority = saved.map((e) => e as String).toList();
        _log.d('Loaded metadata provider priority from prefs: $priority');
        // Sync to Go backend
        await PlatformBridge.setMetadataProviderPriority(priority);
      } else {
        // Fallback to Go backend default
        priority = await PlatformBridge.getMetadataProviderPriority();
        _log.d('Using default metadata provider priority: $priority');
      }
      
      state = state.copyWith(metadataProviderPriority: priority);
    } catch (e) {
      _log.e('Failed to load metadata provider priority: $e');
    }
  }

  Future<void> setMetadataProviderPriority(List<String> priority) async {
    try {
      // Save to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_metadataProviderPriorityKey, jsonEncode(priority));
      
      // Sync to Go backend
      await PlatformBridge.setMetadataProviderPriority(priority);
      state = state.copyWith(metadataProviderPriority: priority);
      _log.d('Saved metadata provider priority: $priority');
    } catch (e) {
      _log.e('Failed to set metadata provider priority: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cleanup() async {
    try {
      await PlatformBridge.cleanupExtensions();
      _log.d('Extensions cleaned up');
    } catch (e) {
      _log.e('Failed to cleanup extensions: $e');
    }
  }

  Extension? getExtension(String extensionId) {
    try {
      return state.extensions.firstWhere((ext) => ext.id == extensionId);
    } catch (_) {
      return null;
    }
  }

  List<Extension> get enabledExtensions {
    return state.extensions.where((ext) => ext.enabled).toList();
  }

  List<String> getAllDownloadProviders() {
    final providers = ['tidal', 'qobuz', 'amazon'];
    for (final ext in state.extensions) {
      if (ext.enabled && ext.hasDownloadProvider) {
        providers.add(ext.id);
      }
    }
    return providers;
  }

  List<String> getAllMetadataProviders() {
    final providers = ['deezer', 'spotify'];
    for (final ext in state.extensions) {
      if (ext.enabled && ext.hasMetadataProvider) {
        providers.add(ext.id);
      }
    }
    return providers;
  }

  List<Extension> get searchProviders {
    return state.extensions.where((ext) => ext.enabled && ext.hasCustomSearch).toList();
  }
}

final extensionProvider = NotifierProvider<ExtensionNotifier, ExtensionState>(
  ExtensionNotifier.new,
);
