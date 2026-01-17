import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/l10n/l10n.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _currentStep = 0;
  bool _storagePermissionGranted = false;
  bool _notificationPermissionGranted = false;
  String? _selectedDirectory;
  bool _isLoading = false;
  int _androidSdkVersion = 0;
  
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  bool _useSpotifyApi = false;
  bool _showClientSecret = false;

  int get _totalSteps => _androidSdkVersion >= 33 ? 4 : 3;

  @override
  void initState() {
    super.initState();
    _initDeviceInfo();
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _initDeviceInfo() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _androidSdkVersion = androidInfo.version.sdkInt;
      debugPrint('Android SDK Version: $_androidSdkVersion');
    }
    await _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    if (Platform.isIOS) {
      if (mounted) {
        setState(() {
          _storagePermissionGranted = true;
          _notificationPermissionGranted = true;
        });
      }
    } else if (Platform.isAndroid) {
      bool storageGranted = false;
      
      if (_androidSdkVersion >= 33) {
        final manageStatus = await Permission.manageExternalStorage.status;
        final audioStatus = await Permission.audio.status;
        debugPrint('[Permission] Android 13+ check: MANAGE_EXTERNAL_STORAGE=$manageStatus, READ_MEDIA_AUDIO=$audioStatus');
        storageGranted = manageStatus.isGranted && audioStatus.isGranted;
      } else if (_androidSdkVersion >= 30) {
        final manageStatus = await Permission.manageExternalStorage.status;
        debugPrint('[Permission] Android 11-12 check: MANAGE_EXTERNAL_STORAGE=$manageStatus');
        storageGranted = manageStatus.isGranted;
      } else {
        final storageStatus = await Permission.storage.status;
        debugPrint('[Permission] Android 10- check: STORAGE=$storageStatus');
        storageGranted = storageStatus.isGranted;
      }
      
      debugPrint('[Permission] Final storageGranted=$storageGranted');
      
      PermissionStatus notificationStatus = PermissionStatus.granted;
      if (_androidSdkVersion >= 33) {
        notificationStatus = await Permission.notification.status;
        debugPrint('[Permission] Notification=$notificationStatus');
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
          var manageStatus = await Permission.manageExternalStorage.status;
          if (!manageStatus.isGranted) {
            if (mounted) {
              final shouldOpen = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.l10n.setupStorageAccessRequired),
                  content: Text(
                    '${context.l10n.setupStorageAccessMessage}\n\n'
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
              
              if (shouldOpen == true) {
                await Permission.manageExternalStorage.request();
                await Future.delayed(const Duration(milliseconds: 500));
                manageStatus = await Permission.manageExternalStorage.status;
              }
            }
          }
          
          var audioStatus = await Permission.audio.status;
          if (!audioStatus.isGranted && manageStatus.isGranted) {
            audioStatus = await Permission.audio.request();
          }
          
          allGranted = manageStatus.isGranted && audioStatus.isGranted;
          
        } else if (_androidSdkVersion >= 30) {
          var manageStatus = await Permission.manageExternalStorage.status;
          if (!manageStatus.isGranted) {
            if (mounted) {
              final shouldOpen = await showDialog<bool>(
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
              
              if (shouldOpen == true) {
                await Permission.manageExternalStorage.request();
                await Future.delayed(const Duration(milliseconds: 500));
                manageStatus = await Permission.manageExternalStorage.status;
              }
            }
          }
          allGranted = manageStatus.isGranted;
          
        } else {
          final status = await Permission.storage.request();
          allGranted = status.isGranted;
          
          if (status.isPermanentlyDenied) {
            _showPermissionDeniedDialog('Storage');
            setState(() => _isLoading = false);
            return;
          }
        }
        
        if (allGranted) {
          setState(() => _storagePermissionGranted = true);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.setupPermissionDeniedMessage)),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Permission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);

    try {
      if (_androidSdkVersion >= 33) {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          setState(() => _notificationPermissionGranted = true);
        } else if (status.isPermanentlyDenied) {
          _showPermissionDeniedDialog('Notification');
        }
      } else {
        setState(() => _notificationPermissionGranted = true);
      }
    } catch (e) {
      debugPrint('Notification permission error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _skipNotificationPermission() {
    setState(() => _notificationPermissionGranted = true);
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
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
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: context.l10n.setupSelectDownloadFolder,
        );

        if (selectedDirectory != null) {
          setState(() => _selectedDirectory = selectedDirectory);
        } else {
          final defaultDir = await _getDefaultDirectory();
          if (mounted) {
            final useDefault = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.l10n.setupUseDefaultFolder),
                content: Text('${context.l10n.setupNoFolderSelected}\n\n$defaultDir'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.dialogCancel)),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.setupUseDefault)),
                ],
              ),
            );

            if (useDefault == true) {
              setState(() => _selectedDirectory = defaultDir);
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(context.l10n.setupDownloadLocationTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                context.l10n.setupDownloadLocationIosMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: Icon(Icons.folder_special, color: colorScheme.primary),
              title: Text(context.l10n.setupAppDocumentsFolder),
              subtitle: Text(context.l10n.setupAppDocumentsFolderSubtitle),
              trailing: Icon(Icons.check_circle, color: colorScheme.primary),
              onTap: () async {
                final dir = await _getDefaultDirectory();
                setState(() => _selectedDirectory = dir);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud, color: colorScheme.onSurfaceVariant),
              title: Text(context.l10n.setupChooseFromFiles),
              subtitle: Text(context.l10n.setupChooseFromFilesSubtitle),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.getDirectoryPath();
                if (result != null) {
                  setState(() => _selectedDirectory = result);
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: colorScheme.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.setupIosEmptyFolderWarning,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onTertiaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String> _getDefaultDirectory() async {
    if (Platform.isIOS) {
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${appDir.path}/SpotiFLAC');
      try {
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        return musicDir.path;
      } catch (e) {
        debugPrint('Cannot create SpotiFLAC folder: $e');
      }
      return '${appDir.path}/SpotiFLAC';
    } else if (Platform.isAndroid) {
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
      final dir = Directory(_selectedDirectory!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      ref.read(settingsProvider.notifier).setDownloadDirectory(_selectedDirectory!);
      
      if (_useSpotifyApi && 
          _clientIdController.text.trim().isNotEmpty && 
          _clientSecretController.text.trim().isNotEmpty) {
        ref.read(settingsProvider.notifier).setSpotifyCredentials(
          _clientIdController.text.trim(),
          _clientSecretController.text.trim(),
        );
        ref.read(settingsProvider.notifier).setMetadataSource('spotify');
      } else {
        ref.read(settingsProvider.notifier).setMetadataSource('deezer');
      }
      
      ref.read(settingsProvider.notifier).setFirstLaunchComplete();

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom - 48),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 24),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/images/logo.png', width: 96, height: 96),
                    ),
                    const SizedBox(height: 12),
                    Text(context.l10n.appName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text(context.l10n.setupDownloadInFlac,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
                  ],
                ),

                Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildStepIndicator(colorScheme),
                    const SizedBox(height: 24),
                    _buildCurrentStepContent(colorScheme),
                  ],
                ),

                Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildNavigationButtons(colorScheme),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme colorScheme) {
    final steps = _androidSdkVersion >= 33
        ? [context.l10n.setupStepStorage, context.l10n.setupStepNotification, context.l10n.setupStepFolder, context.l10n.setupStepSpotify]
        : [context.l10n.setupStepPermission, context.l10n.setupStepFolder, context.l10n.setupStepSpotify];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                width: 32,
                height: 2,
                color: _currentStep >= i ? colorScheme.primary : colorScheme.surfaceContainerHighest,
              ),
            ),
          _buildStepDot(i, steps[i], colorScheme),
        ],
      ],
    );
  }

  Widget _buildStepDot(int step, String label, ColorScheme colorScheme) {
    final isActive = _currentStep >= step;
    final isCompleted = _isStepCompleted(step);
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? colorScheme.primary
                : isCurrent 
                    ? colorScheme.primaryContainer 
                    : colorScheme.surfaceContainerHighest,
            border: isCurrent && !isCompleted
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check_rounded, size: 20, color: colorScheme.onPrimary)
                : Text('${step + 1}',
                    style: TextStyle(
                      color: isCurrent ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          )),
      ],
    );
  }

  bool _isStepCompleted(int step) {
    if (_androidSdkVersion >= 33) {
      switch (step) {
        case 0: return _storagePermissionGranted;
        case 1: return _notificationPermissionGranted;
        case 2: return _selectedDirectory != null;
        case 3: return false;
      }
    } else {
      switch (step) {
        case 0: return _storagePermissionGranted;
        case 1: return _selectedDirectory != null;
        case 2: return false; // Spotify step never shows checkmark (optional)
      }
    }
    return false;
  }

  Widget _buildCurrentStepContent(ColorScheme colorScheme) {
    if (_androidSdkVersion >= 33) {
      switch (_currentStep) {
        case 0: return _buildStoragePermissionStep(colorScheme);
        case 1: return _buildNotificationPermissionStep(colorScheme);
        case 2: return _buildDirectoryStep(colorScheme);
        case 3: return _buildSpotifyApiStep(colorScheme);
      }
    } else {
      switch (_currentStep) {
        case 0: return _buildStoragePermissionStep(colorScheme);
        case 1: return _buildDirectoryStep(colorScheme);
        case 2: return _buildSpotifyApiStep(colorScheme);
      }
    }
    return const SizedBox();
  }

  Widget _buildStoragePermissionStep(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _storagePermissionGranted ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            _storagePermissionGranted ? Icons.check_rounded : Icons.folder_open_rounded,
            size: 40,
            color: _storagePermissionGranted ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _storagePermissionGranted ? context.l10n.setupStorageGranted : context.l10n.setupStorageRequired,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _storagePermissionGranted
                ? context.l10n.setupProceedToNextStep
                : context.l10n.setupStorageDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        if (!_storagePermissionGranted)
          FilledButton.icon(
            onPressed: _isLoading ? null : _requestStoragePermission,
            icon: _isLoading
                ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                : const Icon(Icons.security_rounded),
            label: Text(context.l10n.setupGrantPermission),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationPermissionStep(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _notificationPermissionGranted ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            _notificationPermissionGranted ? Icons.check_rounded : Icons.notifications_outlined,
            size: 40,
            color: _notificationPermissionGranted ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _notificationPermissionGranted ? context.l10n.setupNotificationGranted : context.l10n.setupNotificationEnable,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _notificationPermissionGranted
                ? context.l10n.setupNotificationProgressDescription
                : context.l10n.setupNotificationBackgroundDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        if (!_notificationPermissionGranted) ...[
          FilledButton.icon(
            onPressed: _isLoading ? null : _requestNotificationPermission,
            icon: _isLoading
                ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                : const Icon(Icons.notifications_active_rounded),
            label: Text(context.l10n.setupEnableNotifications),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skipNotificationPermission,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(context.l10n.setupSkipForNow),
          ),
        ],
      ],
    );
  }

  Widget _buildDirectoryStep(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _selectedDirectory != null ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            _selectedDirectory != null ? Icons.folder_rounded : Icons.create_new_folder_rounded,
            size: 40,
            color: _selectedDirectory != null ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _selectedDirectory != null ? context.l10n.setupFolderSelected : context.l10n.setupFolderChoose,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (_selectedDirectory != null)
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _selectedDirectory!,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.l10n.setupFolderDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isLoading ? null : _selectDirectory,
          icon: _isLoading
              ? SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
              : Icon(_selectedDirectory != null ? Icons.edit_rounded : Icons.folder_open_rounded),
          label: Text(_selectedDirectory != null ? context.l10n.setupChangeFolder : context.l10n.setupSelectFolder),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildSpotifyApiStep(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _useSpotifyApi ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.api_rounded,
            size: 40,
            color: _useSpotifyApi ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.setupSpotifyApiOptional,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            context.l10n.setupSpotifyApiDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(context.l10n.setupUseSpotifyApi, style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text(
              _useSpotifyApi ? context.l10n.setupEnterCredentialsBelow : context.l10n.setupUsingDeezer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _useSpotifyApi ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _useSpotifyApi ? Icons.music_note_rounded : Icons.album_rounded,
                size: 20,
                color: _useSpotifyApi ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
            value: _useSpotifyApi,
            onChanged: (value) => setState(() => _useSpotifyApi = value),
          ),
        ),
        
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _useSpotifyApi ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.credentialsClientId, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientIdController,
                      decoration: InputDecoration(
                        hintText: context.l10n.setupEnterClientId,
                        prefixIcon: const Icon(Icons.key_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(context.l10n.credentialsClientSecret, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientSecretController,
                      obscureText: !_showClientSecret,
                      decoration: InputDecoration(
                        hintText: context.l10n.setupEnterClientSecret,
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_showClientSecret ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setState(() => _showClientSecret = !_showClientSecret),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.onTertiaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.l10n.setupGetCredentialsFromSpotify,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onTertiaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(ColorScheme colorScheme) {
    final isLastStep = _currentStep == _totalSteps - 1;
    final canProceed = _isStepCompleted(_currentStep);
    
    final isSpotifyStepValid = !_useSpotifyApi || 
        (_clientIdController.text.trim().isNotEmpty && _clientSecretController.text.trim().isNotEmpty);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(context.l10n.setupBack),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          )
        else
          const SizedBox(width: 100),

        if (!isLastStep)
          FilledButton(
            onPressed: canProceed ? () => setState(() => _currentStep++) : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text(context.l10n.setupNext), const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded, size: 18)],
            ),
          )
        else
          FilledButton(
            onPressed: isSpotifyStepValid && !_isLoading ? _completeSetup : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_useSpotifyApi ? context.l10n.setupGetStarted : context.l10n.setupSkipAndStart),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_rounded, size: 18),
                    ],
                  ),
          ),
      ],
    );
  }
}
