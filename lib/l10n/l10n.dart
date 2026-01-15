import 'package:flutter/material.dart';
import 'package:spotiflac_android/l10n/app_localizations.dart';

export 'package:spotiflac_android/l10n/app_localizations.dart';

/// Extension to easily access AppLocalizations from BuildContext
extension AppLocalizationsX on BuildContext {
  /// Get the AppLocalizations instance
  /// Usage: context.l10n.navHome
  AppLocalizations get l10n => AppLocalizations.of(this);
}
