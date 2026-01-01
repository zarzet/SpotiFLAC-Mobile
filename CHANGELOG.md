# Changelog

## [1.5.0-hotfix6] - 2026-01-02

### Fixed
- **App Signing**: Use r0adkll/sign-android-release GitHub Action for reliable signing

## [1.5.0-hotfix5] - 2026-01-02

### Fixed
- **App Signing**: Use key.properties as per Flutter official documentation

## [1.5.0-hotfix4] - 2026-01-02

### Fixed
- **App Signing**: Create keystore.properties in workflow for Gradle

## [1.5.0-hotfix] - 2026-01-02

### Important Notice
We apologize for the inconvenience. Previous releases were signed with different keys, causing "package conflicts" errors when upgrading. Starting from this version, all releases will use a consistent signing key.

**If you're upgrading from v1.5.0 or earlier, please uninstall the app first before installing this version.** This is a one-time requirement. Future updates will work seamlessly without uninstalling.

### Added
- **In-App Update**: Download and install updates directly from the app
  - Progress bar shows download status
  - Automatic device architecture detection (arm64/arm32)
  - Downloads correct APK for your device
- **Consistent App Signing**: All future releases will use the same signing key

### Fixed
- **Update Checker**: Now downloads APK directly instead of opening browser

## [1.5.0] - 2026-01-02

### Added
- **Download Progress Notification**: Shows notification with download progress percentage while downloading
  - Progress bar in notification during download
  - Completion notification when track finishes
  - Summary notification when all downloads complete
- **Notification Permission in Setup**: Android 13+ users will be prompted for notification permission during initial setup
  - New step in setup wizard for notification permission
  - Option to skip if user doesn't want notifications
- **Per-Item Queue Controls**: Each track in download queue now has individual controls
  - Cancel button for queued items
  - Stop button for currently downloading items
  - Retry and Remove buttons for failed/skipped items
  - Visual progress bar with percentage for each downloading track
- **Pull-to-Refresh on Home**: Swipe down to clear URL input and fetched tracks
  - No need to exit app to clear current search/fetch
- **Multi-Progress Tracking for Concurrent Downloads**: Each concurrent download now shows individual progress percentage
  - Previously concurrent downloads jumped from 0% to 100%
  - Now each track shows real-time progress when downloading in parallel
- **In-App Update**: Download and install updates directly from the app
  - Progress bar shows download status
  - Automatic device architecture detection (arm64/arm32)
  - Downloads correct APK for your device

### Changed
- **Recent Downloads**: Now shows up to 10 items (was 5) for better scrolling
- **Queue UI Redesign**: Card-based layout with clearer status indicators
  - Removed global pause/resume in favor of per-item controls
  - Better visual hierarchy with cover art, track info, and action buttons
- **Settings UI**: Redesigned with category-based navigation (One UI style)
  - Main settings tab with 4 categories: Appearance, Download, Options, About
  - Each category opens a detail page
  - Large title at top with menu items below
  - One-handed friendly layout
- **Collapsing Toolbar**: Implemented One UI style collapsing header for all tabs
  - Title animates from 28px (expanded) to 20px (collapsed)
  - Back button only on settings detail pages
  - Consistent across Home, Downloads, and Settings tabs
- **Home Search Bar Redesign**: More prominent and user-friendly input
  - Larger card-style search bar with border outline
  - Tap to open bottom sheet with full input experience
  - Paste and Search buttons clearly visible
  - Helper text showing supported URL types
- **Empty State Improved**: Better onboarding for new users
  - "Ready to Download" title with icon
  - Clear instructions on how to use the app
  - "Add Music" button for quick access

### Technical
- Added `flutter_local_notifications` package for notifications
- Added notification permission request in setup screen for Android 13+
- Enabled core library desugaring for all Android subprojects
- Added multi-progress tracking in Go backend (`ItemProgress`, `ItemProgressWriter`)
- Added `GetAllDownloadProgress`, `InitItemProgress`, `FinishItemProgress`, `ClearItemProgress` exports
- Updated platform channel handlers for both Android (Kotlin) and iOS (Swift)

### Performance
- Optimized SliverAppBar: Removed LayoutBuilder that was called every frame during scroll
- Optimized image caching: Added `memCacheWidth/Height` to CachedNetworkImage for memory efficiency
- Optimized state management: Use `select()` to only rebuild when specific state changes
- Smoother animations: Changed to `BouncingScrollPhysics` and `Curves.easeOutCubic`

## [1.2.0] - 2026-01-02

### Added
- **Track Metadata Screen**: New detailed metadata view when tapping on downloaded tracks
  - Material Expressive 3 design with cover art header and gradient
  - Hero animation from list to detail view
  - Displays: track name, artist, album artist, album, track number, disc number, duration, release date, ISRC, Spotify ID, quality, service, download date
  - File info: format (FLAC/M4A), file size, quality badge, service badge with colors
  - Tap to copy ISRC and Spotify ID
  - "Open in Spotify" button to open track in Spotify app/browser
  - File path display with copy functionality
  - Play and Delete action buttons
- **Hi-Res Lossless MAX**: New highest quality option for maximum audio fidelity

### Fixed
- **Hi-Res Quality Bug**: Fixed issue where Hi-Res downloads were stuck at Lossless quality
  - Users on previous versions are recommended to upgrade to get proper Hi-Res downloads
- **Settings Navigation Bug**: Fixed issue where changing settings (like audio quality) would navigate back to Home tab
- **Tidal Badge Color**: Fixed unreadable Tidal service badge (was too bright cyan, now darker blue)

### Changed
- **Recent Downloads**: Tapping on a track now opens metadata screen instead of playing directly
  - Play button still available for quick playback
- **Download History Model**: Extended with additional metadata fields (albumArtist, isrc, spotifyId, trackNumber, discNumber, duration, releaseDate, quality)
- Removed unused `history_screen.dart` and `history_tab.dart` files

## [1.1.2] - 2026-01-01

### Added
- **Update Checker**: Automatic check for new versions from GitHub releases
  - Shows changelog in update dialog
  - Option to disable update notifications
- **Release Changelog**: GitHub releases now include full changelog

### Changed
- Updated version to 1.1.2

## [1.1.1] - 2026-01-01

### Fixed
- **About Dialog**: Custom About dialog with cleaner layout
- **Setup Screen**: Fixed step indicator line alignment
- **Warning Text**: Fixed parallel downloads warning to use Material theme colors
- **Copyright Year**: Updated to 2026

### Changed
- Removed Theme Preview from Settings
- Added MIT License


## [1.1.0] - 2026-01-01

### Added
- **Parallel Downloads**: Download up to 3 tracks simultaneously (configurable in Settings)
  - Default: Sequential (1 at a time) for stability
  - Options: 1, 2, or 3 concurrent downloads
  - Warning about potential rate limiting from streaming services
- **Download Progress Tracking**: Real-time progress for BTS manifest downloads from Tidal
- **History Persistence**: Download history now persists across app restarts using SharedPreferences
- **Connection Pooling**: Shared HTTP transport to prevent TCP connection exhaustion during large batch downloads
- **Connection Cleanup**: Automatic cleanup of idle connections every 50 downloads and at queue end

### Fixed
- **Download Progress Bug**: Fixed 0% → 100% jump by adding proper progress tracking for BTS format downloads
- **TCP Connection Exhaustion**: Fixed slow downloads after ~300 tracks by implementing connection pooling and periodic cleanup
- **Trailing Space in Names**: Fixed download failures when playlist/album/track names have trailing spaces
- **History Loss on Debug**: History no longer disappears when sideloading via `flutter run --debug`

### Changed
- Updated version to 1.1.0

### Technical Details
- Added `concurrentDownloads` field to `AppSettings` model (default: 1, max: 3)
- Implemented worker pool pattern in `DownloadQueueNotifier` for parallel processing
- Added `SetCurrentFile()`, `SetBytesTotal()`, and `ProgressWriter` for BTS downloads in Go backend
- Added `strings.TrimSpace()` to all string fields in `DownloadTrack()` and `DownloadWithFallback()`
- Added shared `http.Transport` with connection pooling in `httputil.go`
- Added `CleanupConnections()` export for Flutter to call via method channel

## [1.0.5] - Previous Release
- Material Expressive 3 UI
- Dynamic color support
- Swipe navigation with PageView
- Settings as bottom navigation tab
- APK size optimization
