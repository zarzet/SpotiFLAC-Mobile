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
  
  // Spotify API credentials
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  bool _useSpotifyApi = false;
  bool _showClientSecret = false;

  // Total steps: Storage -> Notification (Android 13+) -> Folder -> Spotify API
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
      // Check storage permission
      PermissionStatus storageStatus;
      if (_androidSdkVersion >= 33) {
        storageStatus = await Permission.audio.status;
      } else if (_androidSdkVersion >= 30) {
        storageStatus = await Permission.manageExternalStorage.status;
      } else {
        storageStatus = await Permission.storage.status;
      }
      
      // Check notification permission (Android 13+)
      PermissionStatus notificationStatus = PermissionStatus.granted;
      if (_androidSdkVersion >= 33) {
        notificationStatus = await Permission.notification.status;
      }
      
      if (mounted) {
        setState(() {
          _storagePermissionGranted = storageStatus.isGranted;
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
        PermissionStatus status;
        
        if (_androidSdkVersion >= 33) {
          // Android 13+: Use audio permission
          status = await Permission.audio.request();
        } else if (_androidSdkVersion >= 30) {
          // Android 11-12: Need MANAGE_EXTERNAL_STORAGE
          // This opens system settings, not a dialog
          status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            // Show explanation dialog first
            if (mounted) {
              final shouldOpen = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Storage Access Required'),
                  content: const Text(
                    'Android 11+ requires "All files access" permission to save music files.\n\n'
                    'Please enable "Allow access to manage all files" in the next screen.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              );
              
              if (shouldOpen == true) {
                status = await Permission.manageExternalStorage.request();
              }
            }
          }
        } else {
          // Android 10 and below: Use legacy storage permission
          status = await Permission.storage.request();
        }
        
        if (status.isGranted) {
          setState(() => _storagePermissionGranted = true);
        } else if (status.isPermanentlyDenied) {
          _showPermissionDeniedDialog('Storage');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission denied. Please grant permission to continue.')),
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
        // Notification permission not needed for older Android
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
        title: Text('$permissionType Permission Required'),
        content: Text(
          '$permissionType permission is required for the best experience. '
          'Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDirectory() async {
    setState(() => _isLoading = true);

    try {
      if (Platform.isIOS) {
        // iOS: Show options dialog
        await _showIOSDirectoryOptions();
      } else {
        // Android: Use file picker
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select Download Folder',
        );

        if (selectedDirectory != null) {
          setState(() => _selectedDirectory = selectedDirectory);
        } else {
          final defaultDir = await _getDefaultDirectory();
          if (mounted) {
            final useDefault = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Use Default Folder?'),
                content: Text('No folder selected. Would you like to use the default Music folder?\n\n$defaultDir'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Use Default')),
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
              child: Text('Download Location', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'On iOS, downloads are saved to the app\'s Documents folder which is accessible via the Files app.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: Icon(Icons.folder_special, color: colorScheme.primary),
              title: const Text('App Documents Folder'),
              subtitle: const Text('Recommended - accessible via Files app'),
              trailing: Icon(Icons.check_circle, color: colorScheme.primary),
              onTap: () async {
                final dir = await _getDefaultDirectory();
                setState(() => _selectedDirectory = dir);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud, color: colorScheme.onSurfaceVariant),
              title: const Text('Choose from Files'),
              subtitle: const Text('Select iCloud or other location'),
              onTap: () async {
                Navigator.pop(ctx);
                // Note: iOS requires folder to have at least one file to be selectable
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
                        'iOS limitation: Empty folders cannot be selected. Create a file inside first or use App Documents.',
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
      
      // Save Spotify credentials if provided
      if (_useSpotifyApi && 
          _clientIdController.text.trim().isNotEmpty && 
          _clientSecretController.text.trim().isNotEmpty) {
        ref.read(settingsProvider.notifier).setSpotifyCredentials(
          _clientIdController.text.trim(),
          _clientSecretController.text.trim(),
        );
        // Set search source to Spotify when credentials are provided
        ref.read(settingsProvider.notifier).setMetadataSource('spotify');
      } else {
        // Use Deezer as default search source (free, no credentials required)
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
                // Top section - Logo/Title
                Column(
                  children: [
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/images/logo.png', width: 96, height: 96),
                    ),
                    const SizedBox(height: 12),
                    Text('SpotiFLAC',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('Download Spotify tracks in FLAC',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
                  ],
                ),

                // Middle section - Steps and Content
                Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildStepIndicator(colorScheme),
                    const SizedBox(height: 24),
                    _buildCurrentStepContent(colorScheme),
                  ],
                ),

                // Bottom section - Navigation Buttons
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
        ? ['Storage', 'Notification', 'Folder', 'Spotify']
        : ['Permission', 'Folder', 'Spotify'];
    
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
      // 4 steps: Storage, Notification, Folder, Spotify
      switch (step) {
        case 0: return _storagePermissionGranted;
        case 1: return _notificationPermissionGranted;
        case 2: return _selectedDirectory != null;
        case 3: return false; // Spotify step never shows checkmark (optional)
      }
    } else {
      // 3 steps: Permission, Folder, Spotify
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
        // Icon with container background (M3 style)
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
          _storagePermissionGranted ? 'Storage Permission Granted!' : 'Storage Permission Required',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _storagePermissionGranted
                ? 'You can now proceed to the next step.'
                : 'SpotiFLAC needs storage access to save downloaded music files to your device.',
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
            label: const Text('Grant Permission'),
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
        // Icon with container background (M3 style)
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
          _notificationPermissionGranted ? 'Notification Permission Granted!' : 'Enable Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _notificationPermissionGranted
                ? 'You will receive download progress notifications.'
                : 'Get notified about download progress and completion. This helps you track downloads when the app is in background.',
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
            label: const Text('Enable Notifications'),
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
            child: const Text('Skip for now'),
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
        // Icon with container background (M3 style)
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
          _selectedDirectory != null ? 'Download Folder Selected!' : 'Choose Download Folder',
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
              'Select a folder where your downloaded music will be saved.',
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
          label: Text(_selectedDirectory != null ? 'Change Folder' : 'Select Folder'),
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
        // Icon with container background (M3 style)
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
          'Spotify API (Optional)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Add your Spotify API credentials for better search results, or skip to use Deezer instead.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        
        // Toggle card (M3 style)
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text('Use Spotify API', style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text(
              _useSpotifyApi ? 'Enter your credentials below' : 'Using Deezer (no account needed)',
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
        
        // Credentials form (animated)
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
                    // Client ID
                    Text('Client ID', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientIdController,
                      decoration: InputDecoration(
                        hintText: 'Enter Spotify Client ID',
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
                    
                    // Client Secret
                    Text('Client Secret', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientSecretController,
                      obscureText: !_showClientSecret,
                      decoration: InputDecoration(
                        hintText: 'Enter Spotify Client Secret',
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
                    
                    // Info banner
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
                              'Get credentials from developer.spotify.com',
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
    
    // For Spotify step, check if credentials are valid when enabled
    final isSpotifyStepValid = !_useSpotifyApi || 
        (_clientIdController.text.trim().isNotEmpty && _clientSecretController.text.trim().isNotEmpty);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        if (_currentStep > 0)
          TextButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          )
        else
          const SizedBox(width: 100),

        // Next/Finish button
        if (!isLastStep)
          FilledButton(
            onPressed: canProceed ? () => setState(() => _currentStep++) : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Next'), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 18)],
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
                      Text(_useSpotifyApi ? 'Get Started' : 'Skip & Start'),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_rounded, size: 18),
                    ],
                  ),
          ),
      ],
    );
  }
}
