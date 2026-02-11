import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/file_access.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // State variables
  bool _storagePermissionGranted = false;
  bool _notificationPermissionGranted = false;
  String? _selectedDirectory;
  String? _selectedTreeUri;
  bool _isLoading = false;
  int _androidSdkVersion = 0;

  // Spotify form
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  bool _useSpotifyApi = false;
  bool _showClientSecret = false;

  // We add 1 for the Welcome step
  int get _totalSteps => (_androidSdkVersion >= 33 ? 4 : 3) + 1;

  @override
  void initState() {
    super.initState();
    _initDeviceInfo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _initDeviceInfo() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (!mounted) return;
      setState(() {
        _androidSdkVersion = androidInfo.version.sdkInt;
      });
    }
    if (!mounted) return;
    await _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    if (Platform.isIOS) {
      final notificationStatus = await Permission.notification.status;
      if (mounted) {
        setState(() {
          _storagePermissionGranted = true;
          _notificationPermissionGranted =
              notificationStatus.isGranted || notificationStatus.isProvisional;
        });
      }
    } else if (Platform.isAndroid) {
      bool storageGranted = false;

      if (_androidSdkVersion >= 33) {
        final audioStatus = await Permission.audio.status;
        storageGranted = audioStatus.isGranted;
      } else if (_androidSdkVersion >= 30) {
        final manageStatus = await Permission.manageExternalStorage.status;
        storageGranted = manageStatus.isGranted;
      } else {
        final storageStatus = await Permission.storage.status;
        storageGranted = storageStatus.isGranted;
      }

      PermissionStatus notificationStatus = PermissionStatus.granted;
      if (_androidSdkVersion >= 33) {
        notificationStatus = await Permission.notification.status;
      }

      if (mounted) {
        setState(() {
          _storagePermissionGranted = storageGranted;
          _notificationPermissionGranted = notificationStatus.isGranted;
        });
      }
    }
  }

  Future<void> _requestStoragePermission() async {
    setState(() => _isLoading = true);
    try {
      if (Platform.isIOS) {
        setState(() => _storagePermissionGranted = true);
      } else if (Platform.isAndroid) {
        bool allGranted = false;

        if (_androidSdkVersion >= 33) {
          var audioStatus = await Permission.audio.status;
          if (!audioStatus.isGranted) {
            audioStatus = await Permission.audio.request();
          }
          allGranted = audioStatus.isGranted;

          if (audioStatus.isPermanentlyDenied) {
            await _showPermissionDeniedDialog('Audio');
            return;
          }
        } else if (_androidSdkVersion >= 30) {
          var manageStatus = await Permission.manageExternalStorage.status;
          if (!manageStatus.isGranted) {
            final shouldOpen = await _showAndroid11StorageDialog();
            if (shouldOpen == true) {
              await Permission.manageExternalStorage.request();
              await Future.delayed(const Duration(milliseconds: 500));
              manageStatus = await Permission.manageExternalStorage.status;
            }
          }
          allGranted = manageStatus.isGranted;
        } else {
          final status = await Permission.storage.request();
          allGranted = status.isGranted;
          if (status.isPermanentlyDenied) {
            await _showPermissionDeniedDialog('Storage');
            return;
          }
        }

        setState(() => _storagePermissionGranted = allGranted);
        if (!allGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.setupPermissionDeniedMessage)),
          );
        }
      }
    } catch (e) {
      debugPrint('Permission error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showAndroid11StorageDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.setupStorageAccessRequired),
        content: Text(
          '${context.l10n.setupStorageAccessMessageAndroid11}\n\n'
          '${context.l10n.setupAllowAccessToManageFiles}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.setupOpenSettings),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);
    try {
      if (Platform.isIOS) {
        final status = await Permission.notification.request();
        if (status.isGranted || status.isProvisional) {
          setState(() => _notificationPermissionGranted = true);
        } else if (status.isPermanentlyDenied) {
          await _showPermissionDeniedDialog('Notification');
        }
      } else if (_androidSdkVersion >= 33) {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          setState(() => _notificationPermissionGranted = true);
        } else if (status.isPermanentlyDenied) {
          await _showPermissionDeniedDialog('Notification');
        }
      } else {
        setState(() => _notificationPermissionGranted = true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showPermissionDeniedDialog(String permissionType) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.setupPermissionRequired(permissionType)),
        content: Text(
          context.l10n.setupPermissionRequiredMessage(permissionType),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.dialogCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(context.l10n.setupOpenSettings),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDirectory() async {
    setState(() => _isLoading = true);
    try {
      if (Platform.isIOS) {
        await _showIOSDirectoryOptions();
      } else {
        final result = await PlatformBridge.pickSafTree();
        if (result != null) {
          final treeUri = result['tree_uri'] as String? ?? '';
          final displayName = result['display_name'] as String? ?? '';
          if (treeUri.isNotEmpty) {
            setState(() {
              _selectedTreeUri = treeUri;
              _selectedDirectory = displayName.isNotEmpty
                  ? displayName
                  : treeUri;
            });
          }
        }

        // Android fallback if user cancelled SAF picker
        if (_selectedTreeUri == null || _selectedTreeUri!.isEmpty) {
          final defaultDir = await _getDefaultDirectory();
          if (mounted) {
            final useDefault = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.l10n.setupUseDefaultFolder),
                content: Text(
                  '${context.l10n.setupNoFolderSelected}\n\n$defaultDir',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.dialogCancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.setupUseDefault),
                  ),
                ],
              ),
            );
            if (useDefault == true) {
              setState(() {
                _selectedTreeUri = '';
                _selectedDirectory = defaultDir;
              });
            }
          }
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showIOSDirectoryOptions() async {
    final colorScheme = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                context.l10n.setupDownloadLocationTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.setupDownloadLocationIosMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.folder_special, color: colorScheme.primary),
              title: Text(context.l10n.setupAppDocumentsFolder),
              onTap: () async {
                final dir = await _getDefaultDirectory();
                setState(() => _selectedDirectory = dir);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud, color: colorScheme.onSurfaceVariant),
              title: Text(context.l10n.setupChooseFromFiles),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.getDirectoryPath();
                if (result != null) {
                  // iOS: Validate the selected path is writable
                  if (Platform.isIOS) {
                    final validation = validateIosPath(result);
                    if (!validation.isValid) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(validation.errorReason ?? 'Invalid folder selected'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                      return;
                    }
                  }
                  setState(() => _selectedDirectory = result);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<String> _getDefaultDirectory() async {
    if (Platform.isAndroid) {
      final musicDir = Directory('/storage/emulated/0/Music/SpotiFLAC');
      try {
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        return musicDir.path;
      } catch (e) {
        debugPrint('Cannot create Music folder: $e');
      }
    }
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/SpotiFLAC';
  }

  Future<void> _completeSetup() async {
    if (_selectedDirectory == null) return;
    setState(() => _isLoading = true);

    try {
      if (!Platform.isAndroid ||
          _selectedTreeUri == null ||
          _selectedTreeUri!.isEmpty) {
        final dir = Directory(_selectedDirectory!);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        ref.read(settingsProvider.notifier).setStorageMode('app');
        ref
            .read(settingsProvider.notifier)
            .setDownloadDirectory(_selectedDirectory!);
        ref.read(settingsProvider.notifier).setDownloadTreeUri('');
      } else {
        ref.read(settingsProvider.notifier).setStorageMode('saf');
        ref
            .read(settingsProvider.notifier)
            .setDownloadTreeUri(
              _selectedTreeUri!,
              displayName: _selectedDirectory,
            );
      }

      if (_useSpotifyApi &&
          _clientIdController.text.trim().isNotEmpty &&
          _clientSecretController.text.trim().isNotEmpty) {
        ref
            .read(settingsProvider.notifier)
            .setSpotifyCredentials(
              _clientIdController.text.trim(),
              _clientSecretController.text.trim(),
            );
        ref.read(settingsProvider.notifier).setMetadataSource('spotify');
      } else {
        ref.read(settingsProvider.notifier).setMetadataSource('deezer');
      }

      ref.read(settingsProvider.notifier).setFirstLaunchComplete();

      if (mounted) context.go('/tutorial');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    bool canProceed = false;
    // Step 0 is Welcome, always can proceed
    if (_currentStep == 0) {
      canProceed = true;
    } else {
      // Logic for other steps (offset by 1 because of welcome step)
      // Step 1: Storage
      // Step 2: Notification (if android 13+) OR Directory
      // etc.
      canProceed = _isStepCompleted(_currentStep);
    }

    if (canProceed) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep--);
  }

  bool _isStepCompleted(int step) {
    if (step == 0) return true; // Welcome

    // Adjust step index for logic because we added Welcome at 0
    final logicStep = step - 1;

    if (_androidSdkVersion >= 33) {
      switch (logicStep) {
        case 0:
          return _storagePermissionGranted;
        case 1:
          return _notificationPermissionGranted;
        case 2:
          return _selectedDirectory != null;
        case 3:
          return false; // Spotify is last/submit
      }
    } else {
      switch (logicStep) {
        case 0:
          return _storagePermissionGranted;
        case 1:
          return _selectedDirectory != null;
        case 2:
          return false; // Spotify
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate progress
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton.filledTonal(
                      onPressed: _prevPage,
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    const SizedBox(width: 48), // Spacer
                  const Spacer(),
                  // Progress Indicator
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: colorScheme.primary,
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Text(
                            '${_currentStep + 1}/$_totalSteps',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomeStep(colorScheme),
                  _buildStorageStep(colorScheme),
                  if (_androidSdkVersion >= 33)
                    _buildNotificationStep(colorScheme),
                  _buildDirectoryStep(colorScheme),
                  _buildSpotifyStep(colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentStep < _totalSteps - 1
          ? FloatingActionButton.extended(
              onPressed: _isStepCompleted(_currentStep) ? _nextPage : null,
              label: Row(
                children: [
                  Text(context.l10n.setupNext),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward),
                ],
              ),
              icon: const SizedBox.shrink(), // Custom layout
            )
          : FloatingActionButton.extended(
              onPressed:
                  (!_useSpotifyApi ||
                      (_clientIdController.text.isNotEmpty &&
                          _clientSecretController.text.isNotEmpty))
                  ? _completeSetup
                  : null,
              label: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(context.l10n.setupGetStarted),
              icon: const Icon(Icons.check),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
    );
  }

  Widget _buildWelcomeStep(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = MediaQuery.sizeOf(context).shortestSide;
        final textScale = MediaQuery.textScalerOf(
          context,
        ).scale(1.0).clamp(1.0, 1.4);
        final logoSize = (shortestSide * 0.24).clamp(80.0, 104.0);
        final titleGap = (shortestSide * 0.06).clamp(16.0, 32.0);
        final subtitleGap = (shortestSide * 0.04).clamp(8.0, 16.0);
        final minContentHeight = constraints.maxHeight > 48
            ? constraints.maxHeight - 48
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo-transparant.png',
                  width: logoSize,
                  height: logoSize,
                  color: colorScheme.primary,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: titleGap),
                Text(
                  context.l10n.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize:
                        (Theme.of(context).textTheme.displaySmall?.fontSize ??
                            36) *
                        (1 + ((textScale - 1) * 0.18)),
                  ),
                ),
                SizedBox(height: subtitleGap),
                Text(
                  context.l10n.setupDownloadInFlac,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStorageStep(ColorScheme colorScheme) {
    return _StepLayout(
      title: context.l10n.setupStorageRequired,
      description: context.l10n.setupStorageDescription,
      icon: Icons.folder,
      child: _storagePermissionGranted
          ? _SuccessCard(
              text: context.l10n.setupStorageGranted,
              colorScheme: colorScheme,
            )
          : FilledButton.tonalIcon(
              onPressed: _requestStoragePermission,
              icon: const Icon(Icons.folder_open),
              label: Text(context.l10n.setupGrantPermission),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
    );
  }

  Widget _buildNotificationStep(ColorScheme colorScheme) {
    return _StepLayout(
      title: context.l10n.setupNotificationEnable,
      description: context.l10n.setupNotificationBackgroundDescription,
      icon: Icons.notifications,
      child: _notificationPermissionGranted
          ? _SuccessCard(
              text: context.l10n.setupNotificationGranted,
              colorScheme: colorScheme,
            )
          : Column(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _requestNotificationPermission,
                  icon: const Icon(Icons.notifications_active),
                  label: Text(context.l10n.setupEnableNotifications),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _notificationPermissionGranted = true),
                  child: Text(context.l10n.setupSkipForNow),
                ),
              ],
            ),
    );
  }

  Widget _buildDirectoryStep(ColorScheme colorScheme) {
    return _StepLayout(
      title: context.l10n.setupFolderChoose,
      description: context.l10n.setupFolderDescription,
      icon: Icons.create_new_folder,
      child: Column(
        children: [
          if (_selectedDirectory != null)
            Card(
              color: colorScheme.secondaryContainer,
              child: ListTile(
                leading: Icon(
                  Icons.folder,
                  color: colorScheme.onSecondaryContainer,
                ),
                title: Text(
                  _selectedDirectory!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _selectDirectory,
                ),
              ),
            )
          else
            FilledButton.tonalIcon(
              onPressed: _selectDirectory,
              icon: const Icon(Icons.create_new_folder),
              label: Text(context.l10n.setupSelectFolder),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpotifyStep(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.api, size: 48, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            context.l10n.setupSpotifyApiOptional,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.setupSpotifyApiDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _useSpotifyApi,
                  onChanged: (v) => setState(() => _useSpotifyApi = v),
                  title: Text(context.l10n.setupUseSpotifyApi),
                  subtitle: Text(
                    _useSpotifyApi
                        ? context.l10n.setupEnterCredentialsBelow
                        : "Using bundled metadata",
                  ),
                ),
                if (_useSpotifyApi) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _clientIdController,
                          decoration: InputDecoration(
                            labelText: context.l10n.credentialsClientId,
                            prefixIcon: const Icon(Icons.key),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _clientSecretController,
                          obscureText: !_showClientSecret,
                          decoration: InputDecoration(
                            labelText: context.l10n.credentialsClientSecret,
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                                width: 0.5,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showClientSecret
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _showClientSecret = !_showClientSecret,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLayout extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Widget child;

  const _StepLayout({
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = MediaQuery.sizeOf(context).shortestSide;
        final iconPadding = (shortestSide * 0.06).clamp(16.0, 24.0);
        final iconSize = (shortestSide * 0.12).clamp(32.0, 48.0);
        final titleGap = (shortestSide * 0.06).clamp(16.0, 32.0);
        final descriptionGap = (shortestSide * 0.04).clamp(8.0, 16.0);
        final actionGap = (shortestSide * 0.09).clamp(20.0, 48.0);
        final minContentHeight = constraints.maxHeight > 48
            ? constraints.maxHeight - 48
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: iconSize, color: colorScheme.primary),
                ),
                SizedBox(height: titleGap),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: descriptionGap),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: actionGap),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _SuccessCard({required this.text, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
