# Changelog

## [2.0.3] - 2026-01-03

### Added
- **Custom Spotify API Credentials**: Set your own Spotify Client ID and Secret in Settings > Options to avoid rate limiting
  - Toggle to enable/disable custom credentials without deleting them
  - Material Expressive 3 bottom sheet UI for entering credentials
- **Keyboard Dismiss on Scroll**: Keyboard now automatically dismisses when scrolling search results
- **Rate Limit Error UI**: Shows friendly error card when API rate limit (429) is hit on Home, Artist, and Album screens

### Changed
- **Search on Enter Only**: Removed auto-search debounce, now only searches when pressing Enter key (saves API calls)

### Fixed
- **Download Cancel**: Fixed cancelled downloads still completing in background and appearing in history. Cancelled files are now properly deleted.
- **Search Keyboard Dismiss**: Fixed keyboard randomly dismissing and navigating back when starting to search
- **Back Button During Search**: Back button now properly dismisses keyboard first before clearing search
- **Search Error Navigation**: Fixed pressing Enter during search (when loading or error) navigating back to home instead of staying on search screen
- **Duplicate Search on Enter**: Enter key no longer triggers duplicate search if results already loaded

## [2.0.2] - 2026-01-03

### Added
- **Actual Quality Display**: Shows real audio quality (bit depth/sample rate) after download
  - Quality badge on download history items (e.g., "24-bit", "16-bit")
  - Full quality info in Track Metadata screen (e.g., "24-bit/96kHz")
  - Tertiary color highlight for Hi-Res (24-bit) downloads
- **Quality Disclaimer**: Added note in quality picker explaining that actual quality depends on track availability
- **Instant Lyrics Loading**: Lyrics now load from embedded file first (instant) before falling back to internet fetch

### Fixed
- **Fallback Service Display**: Fixed download history showing wrong service when fallback occurs (e.g., showing "TIDAL" when actually downloaded from "QOBUZ")
- **Open in Spotify**: Fixed "Open in Spotify" button not opening Spotify app correctly

### Removed
- **Romaji Conversion**: Removed Japanese lyrics to romaji conversion feature (Kanji not supported, results were incomplete)

### Technical
- Go backend now returns `actual_bit_depth` and `actual_sample_rate` in download response
- Go backend now returns `service` field indicating actual service used (important for fallback)
- Tidal API v2 response provides exact quality info
- Qobuz uses track metadata for quality info
- Amazon now reads quality from downloaded FLAC file (previously returned unknown)

## [2.0.1] - 2026-01-03

### Added
- **Quality Picker Track Info**: Shows track name, artist, and cover in quality picker
  - Tap to expand long track titles
  - Expand icon only shows when title is truncated
  - Ripple effect follows rounded corners including drag handle

### Changed
- **Unified Progress Tracking System**: Deprecated legacy single-download progress
  - All downloads now use item-based progress tracking
  - Fixes duplicate notification bug when finalizing
  - Cleaner codebase with single progress system

### Fixed
- **Duplicate Notification Bug**: Fixed issue where "Finalizing" and "Downloading" notifications appeared simultaneously
- **Update Notification Stuck**: Fixed notification staying at 100% after download completes
- **Quality Picker Consistency**: Unified quality picker UI across all screens (Home, Album, Playlist)
  - Container with `primaryContainer` background for each option
  - Distinct icons: music_note (Lossless), high_quality (Hi-Res), four_k (Max)

## [2.0.0] - 2026-01-03

### Added
- **Artist Search Results**: Search now shows artists alongside tracks
  - Horizontal scrollable artist cards with circular avatars
  - Tap artist to view their discography
- **Multi-Layer Caching System**: Aggressive caching to minimize API calls
  - Go backend cache: Artist (10 min), Album (10 min), Search (5 min)
  - Flutter memory cache: Instant navigation for previously viewed artists/albums
  - Duplicate search prevention: Same query won't trigger new API call
- **Real-time Download Status**: Track items show live download progress
  - Queued: Hourglass icon
  - Downloading: Circular progress with percentage
  - Completed: Check icon
  - Works in Home search, Album, and Playlist screens
- **Downloaded Track Indicator**: Tracks already in history show check mark
  - Lazy file verification: Only checks file existence when tapped
  - Auto-removes from history if file was deleted, allowing re-download
  - Prevents accidental duplicate downloads
- **Pre-release Support**: GitHub Actions auto-detects preview/beta/rc/alpha tags
  - Stable users won't receive update notifications for preview versions

### Changed
- **Instant Navigation UX**: Navigate to Artist/Album screens immediately
  - Header (name, cover) shows instantly from available data
  - Content (albums/tracks) loads in background inside the screen
  - Second visit to same artist/album is instant from Flutter cache
- **Search Results UI Redesign**: 
  - Removed "Download All" button from search results
  - Added "Songs" section header (matches "Artists" header style)
  - Track list now in grouped card with rounded corners (like Settings)
  - Track items with dividers and InkWell ripple effect
- **Larger UI Elements**: Improved touch targets and visual hierarchy
  - Recent downloads: Album art 56→100px, section height 80→130px
  - Artist cards: Avatar 72→88px, container 90→100px
  - Track items: Album art 48→56px
- **Optimized Search**: Pressing Enter with same query no longer triggers duplicate search
- **Smoother Progress Animation**: Progress jumps to 100% after download completes
  - Embedding (cover, metadata, lyrics) happens in background without blocking UI
- **Finalizing Status**: Shows "Finalizing" indicator while embedding metadata
  - Distinct icon (edit_note) with tertiary color
  - User knows download is complete, just processing metadata
- **Consistent Download Button Sizes**: All download/status buttons now 44x44px
- **Better Dynamic Color Contrast**: Improved visibility for cards and chips with dynamic color
  - Settings cards use overlay colors for better contrast
  - Theme/view mode chips have visible borders in light mode
- **Navigation Bar Styling**: Distinct background color from content area
- **Ask Before Download Default**: Now enabled by default for better UX

### Fixed
- **Artist Profile Images**: Fixed artist images not showing in search results (field name mismatch)
- **Album Card Overflow**: Fixed 5px overflow in artist discography album cards
- **Optimized Rebuilds**: Each track item only rebuilds when its own status changes
  - Uses Riverpod `select()` for granular state watching
  - Prevents entire list rebuild on progress updates
- **Update Notification Stuck**: Fixed notification staying at 100% after download complete

## [1.6.3] - 2026-01-03

### Added
- **Predictive Back Navigation**: Support for Android 14+ predictive back gesture with smooth animations
- **Separate Detail Screens**: Album, Artist, and Playlist now open as dedicated screens with Material Expressive 3 design
  - Collapsing header with cover art and gradient overlay
  - Card-based info section with rounded corners (20px radius)
  - Tonal download buttons with circular shape
  - Quality picker bottom sheet with drag handle
- **Double-Tap to Exit**: Press back twice to exit app when at home screen (replaces exit dialog)

### Changed
- **Navigation Architecture**: Refactored from state-based to screen-based navigation
  - Album/Artist/Playlist URLs navigate to dedicated screens via `Navigator.push()`
  - Enables native predictive back gesture animations
  - Search results stay on Home tab for quick downloads
- **Simplified State Management**: Removed `previousState` chain from TrackProvider since Navigator handles back navigation

## [1.6.2] - 2026-01-02

### Added
- **HTTPS-Only Downloads**: APK downloads and update checks now enforce HTTPS-only connections for security

### Changed
- **Home Tab Rename**: Renamed "Search" tab to "Home" with home icon
- **Branding**: Changed idle screen title from "Search Music" to "SpotiFLAC"
- **About Page Redesign**: New Material Expressive 3 grouped layout with app header, contributors section with GitHub avatars, and organized links

### Fixed
- **Play Button Flash**: Fixed play button briefly showing red error icon on app start (now uses optimistic rendering)

### Performance
- **Optimized State Management**: Use `.select()` for Riverpod providers to prevent unnecessary widget rebuilds
- **List Keys**: Added keys to all list builders for efficient list updates and reordering
- **Request Cancellation**: Outdated API requests are ignored when new search/fetch is triggered
- **Debounced URL Fetches**: All network requests now debounced to prevent rapid duplicate calls
- **Bounded File Cache**: File existence cache now limited to 500 entries to prevent memory leak
- **Timer Cleanup**: Progress polling timer properly disposed when provider is destroyed
- **Stream Error Handling**: Share intent stream now has proper error handling

## [1.6.1] - 2026-01-02

### Added
- **Background Download Service**: Downloads now continue running when app is in background
  - Foreground service with wake lock prevents Android from killing downloads
  - Persistent notification shows download progress
  - No more "connection abort" errors when switching apps

### Fixed
- **Share Intent App Restart**: Fixed download queue being lost when sharing from Spotify while downloads are in progress
  - Download queue is now persisted to storage and automatically restored on app restart
  - Interrupted downloads (marked as "downloading") are reset to "queued" and auto-resumed
  - Changed launch mode to `singleTask` to reuse existing activity instead of restarting
  - Added `onNewIntent` handler to properly receive new share intents
- **Back Button During Loading**: Back button no longer clears state while loading shared URL

### Changed
- **Kotlin**: Upgraded from 2.2.20 to 2.3.0 for better plugin compatibility

## [1.6.0] - 2026-01-02

### Added
- **Manual Quality Selection**: New option to choose audio quality before each download
  - Toggle "Ask Before Download" in Download Settings
  - When enabled, shows quality picker (Lossless, Hi-Res, Hi-Res Max) before downloading
  - Works for both single track and batch downloads
- **Live Search**: Search results appear as you type with 400ms debounce
  - Animated search bar moves from center to top when typing
  - Keyboard stays open during transition
  - Back button navigates through search history (album → artist → idle)
  - Clear button to reset search
  - URLs still require manual submit
- **Search Tab Header**: Added collapsing app bar to centered search view for consistent UI across all tabs
- **Share Audio File**: Share downloaded tracks to other apps from Track Metadata screen

### Fixed
- **Update Checker**: Fixed version comparison for versions with suffix (e.g., `1.5.0-hotfix6`)
  - Users on hotfix versions now properly receive update notifications
  - Handles `-hotfix`, `-beta`, `-rc` suffixes correctly
- **Settings Ripple Effect**: Fixed splash/ripple effect to properly clip within rounded card corners

### Changed
- **Settings UI Redesign**: New Android-style grouped settings with connected cards
  - Items in same group are connected with rounded card container
  - Section headers outside cards for clear visual hierarchy
  - Better contrast with white overlay for dark mode dynamic colors
- **Larger Tab Titles**: Increased app bar title size (28px) and height (130px) for better visibility
- **Consistent Header Position**: Fixed Search tab header alignment to match History and Settings tabs

### Improved
- **Code Quality**: Replaced all `print()` statements with structured logging using `logger` package
- **Dependencies Updated**:
  - `share_plus`: 10.1.4 → 12.0.1
  - `flutter_local_notifications`: 18.0.1 → 19.0.0
  - `build_runner`: 2.4.15 → 2.10.4

## [1.5.5] - 2026-01-02

### Added
- **Share to App**: Share Spotify links directly from Spotify app or browser to SpotiFLAC
  - Supports track, album, playlist, and artist URLs
  - Auto-fetches metadata when link is shared
  - Works with both `open.spotify.com` URLs and `spotify:` URIs
- **Lyrics Viewer**: View lyrics for downloaded tracks in Track Metadata screen
  - Fetches lyrics from LRCLIB on-demand
  - Clean display without timestamps
  - Copy lyrics to clipboard
- **Artist URL Support**: Paste artist URL to browse their discography
  - Shows all albums, singles, and compilations
  - Horizontal scrollable album cards grouped by type
  - Tap any album to view and download its tracks
- **Folder Organization**: Organize downloads into folders by artist or album
  - Options: None, By Artist, By Album, By Artist & Album
  - Configurable in Settings > Download
- **Japanese Lyrics to Romaji**: Auto-convert Hiragana/Katakana lyrics to romaji
  - Useful for non-Japanese speakers who want to sing along
  - Toggle in Settings > Options > Lyrics
  - Kanji characters are preserved (requires dictionary lookup)
- **History View Mode**: Choose between grid or list view for download history
  - Grid view shows album art in a 3-column layout (default)
  - List view shows detailed track info with date
  - Configurable in Settings > Appearance > Layout
- **Exit Confirmation**: Dialog prompt when pressing back to exit app (only at root)

### Changed
- **Downloads Tab Renamed to History**: Better reflects the tab's purpose
  - Shows download queue at top when active
  - Completed downloads auto-move to history section
  - Cleaner separation between active downloads and history
- **Smarter Back Navigation**: Back button now navigates properly
  - Goes back through search history (album → artist → empty)
  - Returns to Search tab from other tabs
  - Only shows exit dialog when truly at root

### Fixed
- **Download Progress**: Fixed progress stuck at 0% when using item-based progress tracking (affected sequential downloads after multi-download feature was added)
- **Artist View State**: Fixed UI state not clearing properly when switching between artist and album views
- **Share Intent Timing**: Fixed shared URLs not being processed when app was cold-started from share intent

### Improved
- **Cleaner UI for Returning Users**: Helper text "Supports: Track, Album, Playlist URLs" now only shows for new users and hides after first search
- **Cleaner Home Tab**: Removed redundant "Recent Downloads" section, renamed to "Search" tab
- **Centered Search Bar**: Search bar now appears centered on screen when empty, moves to top when results are shown - easier to reach on large phones
- **Back Navigation**: Android back button now works as expected - returns to previous view (album → artist → empty search)

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
