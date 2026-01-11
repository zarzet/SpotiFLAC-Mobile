import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';

final _log = AppLogger('ExtensionProvider');

/// Represents an installed extension
class Extension {
  final String id;
  final String name;
  final String displayName;
  final String version;
  final String author;
  final String description;
  final bool enabled;
  final String status; // 'loaded', 'error', 'disabled'
  final String? errorMessage;
  final String? iconPath; // Path to extension icon
  final List<String> permissions;
  final List<ExtensionSetting> settings;
  final List<QualityOption> qualityOptions; // Custom quality options for download providers
  final bool hasMetadataProvider;
  final bool hasDownloadProvider;
  final bool skipMetadataEnrichment; // If true, use metadata from extension instead of enriching
  final SearchBehavior? searchBehavior; // Custom search behavior
  final TrackMatching? trackMatching; // Custom track matching
  final PostProcessing? postProcessing; // Post-processing hooks

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
    this.skipMetadataEnrichment = false,
    this.searchBehavior,
    this.trackMatching,
    this.postProcessing,
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
      skipMetadataEnrichment: json['skip_metadata_enrichment'] as bool? ?? false,
      searchBehavior: json['search_behavior'] != null 
          ? SearchBehavior.fromJson(json['search_behavior'] as Map<String, dynamic>)
          : null,
      trackMatching: json['track_matching'] != null
          ? TrackMatching.fromJson(json['track_matching'] as Map<String, dynamic>)
          : null,
      postProcessing: json['post_processing'] != null
          ? PostProcessing.fromJson(json['post_processing'] as Map<String, dynamic>)
          : null,
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
    bool? skipMetadataEnrichment,
    SearchBehavior? searchBehavior,
    TrackMatching? trackMatching,
    PostProcessing? postProcessing,
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
      skipMetadataEnrichment: skipMetadataEnrichment ?? this.skipMetadataEnrichment,
      searchBehavior: searchBehavior ?? this.searchBehavior,
      trackMatching: trackMatching ?? this.trackMatching,
      postProcessing: postProcessing ?? this.postProcessing,
    );
  }

  bool get hasCustomSearch => searchBehavior?.enabled ?? false;
  bool get hasCustomMatching => trackMatching?.customMatching ?? false;
  bool get hasPostProcessing => postProcessing?.enabled ?? false;
}

/// Custom search behavior configuration
class SearchBehavior {
  final bool enabled;
  final String? placeholder;
  final bool primary;
  final String? icon;
  final String? thumbnailRatio; // "square" (1:1), "wide" (16:9), "portrait" (2:3)
  final int? thumbnailWidth;
  final int? thumbnailHeight;

  const SearchBehavior({
    required this.enabled,
    this.placeholder,
    this.primary = false,
    this.icon,
    this.thumbnailRatio,
    this.thumbnailWidth,
    this.thumbnailHeight,
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
    );
  }

  /// Get thumbnail size based on configuration
  /// Returns (width, height) tuple
  (double, double) getThumbnailSize({double defaultSize = 56}) {
    // If custom dimensions specified, use them
    if (thumbnailWidth != null && thumbnailHeight != null) {
      return (thumbnailWidth!.toDouble(), thumbnailHeight!.toDouble());
    }
    
    // Otherwise use ratio presets
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

/// Custom track matching configuration
class TrackMatching {
  final bool customMatching;
  final String? strategy; // "isrc", "name", "duration", "custom"
  final int durationTolerance; // in seconds

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

/// Post-processing configuration
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

/// A post-processing hook
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

/// Represents a quality option for download providers
class QualityOption {
  final String id;
  final String label;
  final String? description;
  final List<QualitySpecificSetting> settings; // Quality-specific settings

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

/// Represents a setting that's specific to a quality option
class QualitySpecificSetting {
  final String key;
  final String label;
  final String type; // 'string', 'number', 'boolean', 'select'
  final dynamic defaultValue;
  final String? description;
  final List<String>? options; // For select type
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

/// Represents a setting field for an extension
class ExtensionSetting {
  final String key;
  final String label;
  final String type; // 'string', 'number', 'boolean', 'select'
  final dynamic defaultValue;
  final String? description;
  final List<String>? options; // For select type
  final bool required;

  const ExtensionSetting({
    required this.key,
    required this.label,
    required this.type,
    this.defaultValue,
    this.description,
    this.options,
    this.required = false,
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
    );
  }
}

/// State for extension management
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


/// Provider for managing extensions
class ExtensionNotifier extends Notifier<ExtensionState> {
  @override
  ExtensionState build() {
    return const ExtensionState();
  }

  /// Initialize the extension system
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

  /// Load all extensions from directory
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

  /// Refresh the list of installed extensions
  Future<void> refreshExtensions() async {
    try {
      final list = await PlatformBridge.getInstalledExtensions();
      final extensions = list.map((e) => Extension.fromJson(e)).toList();
      state = state.copyWith(extensions: extensions);
      _log.d('Loaded ${extensions.length} extensions');
      
      // Log search behavior for extensions that have it
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

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Install extension from file (auto-upgrades if already installed with newer version)
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

  /// Check if a package file is an upgrade for an existing extension
  /// Returns: {extension_id, current_version, new_version, can_upgrade, is_installed}
  Future<Map<String, dynamic>> checkExtensionUpgrade(String filePath) async {
    try {
      return await PlatformBridge.checkExtensionUpgrade(filePath);
    } catch (e) {
      _log.e('Failed to check extension upgrade: $e');
      return {'error': e.toString()};
    }
  }

  /// Upgrade an existing extension from a new package file
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

  /// Uninstall/remove an extension
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

  /// Enable or disable an extension
  Future<void> setExtensionEnabled(String extensionId, bool enabled) async {
    try {
      await PlatformBridge.setExtensionEnabled(extensionId, enabled);
      _log.d('Set extension $extensionId enabled: $enabled');
      
      // Update local state
      final extensions = state.extensions.map((ext) {
        if (ext.id == extensionId) {
          return ext.copyWith(enabled: enabled);
        }
        return ext;
      }).toList();
      
      state = state.copyWith(extensions: extensions);
      
      // If disabling an extension that is the current search provider, clear it
      if (!enabled) {
        final settings = ref.read(settingsProvider);
        if (settings.searchProvider == extensionId) {
          ref.read(settingsProvider.notifier).setSearchProvider(null);
          _log.d('Cleared search provider because extension $extensionId was disabled');
        }
      }
    } catch (e) {
      _log.e('Failed to set extension enabled: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get settings for an extension
  Future<Map<String, dynamic>> getExtensionSettings(String extensionId) async {
    try {
      return await PlatformBridge.getExtensionSettings(extensionId);
    } catch (e) {
      _log.e('Failed to get extension settings: $e');
      return {};
    }
  }

  /// Update settings for an extension
  Future<void> setExtensionSettings(String extensionId, Map<String, dynamic> settings) async {
    try {
      await PlatformBridge.setExtensionSettings(extensionId, settings);
      _log.d('Updated settings for extension: $extensionId');
    } catch (e) {
      _log.e('Failed to set extension settings: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load provider priority order
  Future<void> loadProviderPriority() async {
    try {
      final priority = await PlatformBridge.getProviderPriority();
      state = state.copyWith(providerPriority: priority);
    } catch (e) {
      _log.e('Failed to load provider priority: $e');
    }
  }

  /// Set provider priority order
  Future<void> setProviderPriority(List<String> priority) async {
    try {
      await PlatformBridge.setProviderPriority(priority);
      state = state.copyWith(providerPriority: priority);
      _log.d('Updated provider priority: $priority');
    } catch (e) {
      _log.e('Failed to set provider priority: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load metadata provider priority order
  Future<void> loadMetadataProviderPriority() async {
    try {
      final priority = await PlatformBridge.getMetadataProviderPriority();
      state = state.copyWith(metadataProviderPriority: priority);
    } catch (e) {
      _log.e('Failed to load metadata provider priority: $e');
    }
  }

  /// Set metadata provider priority order
  Future<void> setMetadataProviderPriority(List<String> priority) async {
    try {
      await PlatformBridge.setMetadataProviderPriority(priority);
      state = state.copyWith(metadataProviderPriority: priority);
      _log.d('Updated metadata provider priority: $priority');
    } catch (e) {
      _log.e('Failed to set metadata provider priority: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Cleanup all extensions (call on app close)
  Future<void> cleanup() async {
    try {
      await PlatformBridge.cleanupExtensions();
      _log.d('Extensions cleaned up');
    } catch (e) {
      _log.e('Failed to cleanup extensions: $e');
    }
  }

  /// Get extension by ID
  Extension? getExtension(String extensionId) {
    try {
      return state.extensions.firstWhere((ext) => ext.id == extensionId);
    } catch (_) {
      return null;
    }
  }

  /// Get all enabled extensions
  List<Extension> get enabledExtensions {
    return state.extensions.where((ext) => ext.enabled).toList();
  }

  /// Get all download providers (built-in + extensions)
  List<String> getAllDownloadProviders() {
    final providers = ['tidal', 'qobuz', 'amazon'];
    for (final ext in state.extensions) {
      if (ext.enabled && ext.hasDownloadProvider) {
        providers.add(ext.id);
      }
    }
    return providers;
  }

  /// Get all metadata providers (built-in + extensions)
  List<String> getAllMetadataProviders() {
    final providers = ['deezer', 'spotify'];
    for (final ext in state.extensions) {
      if (ext.enabled && ext.hasMetadataProvider) {
        providers.add(ext.id);
      }
    }
    return providers;
  }
  /// Get all extensions that provide custom search
  List<Extension> get searchProviders {
    return state.extensions.where((ext) => ext.enabled && ext.hasCustomSearch).toList();
  }
}

final extensionProvider = NotifierProvider<ExtensionNotifier, ExtensionState>(
  ExtensionNotifier.new,
);
