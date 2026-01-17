import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/app.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/services/notification_service.dart';
import 'package:spotiflac_android/services/share_intent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService().initialize();
  
  await ShareIntentService().initialize();
  
  runApp(
    ProviderScope(
      child: const _EagerInitialization(
        child: SpotiFLACApp(),
      ),
    ),
  );
}

/// Widget to eagerly initialize providers that need to load data on startup
class _EagerInitialization extends ConsumerStatefulWidget {
  const _EagerInitialization({required this.child});
  final Widget child;

  @override
  ConsumerState<_EagerInitialization> createState() => _EagerInitializationState();
}

class _EagerInitializationState extends ConsumerState<_EagerInitialization> {
  @override
  void initState() {
    super.initState();
    _initializeExtensions();
  }

  Future<void> _initializeExtensions() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final extensionsDir = '${appDir.path}/extensions';
      final dataDir = '${appDir.path}/extension_data';
      
      await Directory(extensionsDir).create(recursive: true);
      await Directory(dataDir).create(recursive: true);
      
      await ref.read(extensionProvider.notifier).initialize(extensionsDir, dataDir);
    } catch (e) {
      debugPrint('Failed to initialize extensions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(downloadHistoryProvider);
    return widget.child;
  }
}
