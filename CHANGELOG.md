# Changelog

## [3.2.1] - 2026-01-22

### Added

- **Artist/Album + Singles Folder Structure**: Singles go inside artist folder (`Artist/Album/`, `Artist/Singles/`)
- **Embed Lyrics Button**: Manually embed online lyrics into tracks from Track Info screen (preserves synced timestamps)
- **Pause/Resume Button**: Added pause and resume controls next to "Downloading" header in History screen
- **Instrumental Detection**: Tracks marked as instrumental on lrclib.net now show "Instrumental track" instead of "Lyrics not available"

### Fixed

- **Lyrics**: Multi-artist tracks now search by primary artist first, then full string
- **Lyrics**: Metadata tags (`[ti:...]`, `[ar:...]`, `[by:...]`) no longer shown in display
- **Lyrics**: Embed button now correctly appears for tracks with online lyrics
- **Lyrics**: Manual embed preserves original timestamps instead of plain text
- **iOS**: Fixed "File not found" after 3.1.x → 3.2.0 update (container UUID migration)
- **Home Feed**: Greeting now uses device local time
- **Deezer**: Track position fallback to index+1 when API returns 0
- **Localization**: Fixed 16 ICU plural syntax warnings in Spanish & Portuguese

### Performance

- **Home Feed**: Precomputed Quick Picks section flag and reduced per-page allocations; explore state now watched by field to cut rebuilds
- **Home Recent**: Cached recent-access aggregation and limited list allocations for recent downloads
- **Settings/Theme/Recent**: Cached SharedPreferences instance to avoid repeated `getInstance()` calls
- **History/DB**: Batched iOS path migration updates to reduce write overhead
- **Download Queue**: Reduced polling allocations and avoided double-load scheduling for history
- **Misc**: Precompiled regex in share intent, update dialog, extensions error parsing, log analysis, and LRC cleanup; faster palette cache hits and log filtering

---

## [3.2.0] - 2026-01-22

> **Note:** Starting from v3.2.0, changelogs will be concise.

### Highlights

- **Discography Download** (Highly Requested): Download entire artist discography with album selection mode
- **Home Feed / Explore**: Personalized sections from spotify-web and ytmusic extensions
- **SQLite History Database**: O(1) lookups, non-blocking writes

### Added

- Discography download with options: All, Albums Only, Singles Only, or Select Albums
- Artist navigation from album screen (tap artist name)
- Home feed sections with pull-to-refresh
- YT Music Quick Picks swipeable UI
- `gobackend.getLocalTime()` API for extensions
- Track duration in home feed items
- Release date badge in album info card

### Improved

- Album track list shows track number instead of cover image
- Download buttons with more rounded corners
- Downloaded songs in Recent show primary-colored subtitle

### Fixed

- Home feed timezone detection
- Track duration 0:00 when downloading from home feed

### Extensions

- spotify-web v1.8.1: Home feed, artist_id support
- ytmusic v1.6.1: Home feed, artist_id support

---

## [3.1.3] - 2026-01-19

### Added

- **External LRC Lyrics File Support**: Option to save lyrics as separate .lrc files for compatibility with external music players
  - New "Lyrics Mode" setting in Settings > Download > Lyrics section
  - Three modes available:
    - **Embed in file** (default): Lyrics stored inside FLAC metadata
    - **External .lrc file**: Save lyrics as separate .lrc file next to audio file
    - **Both**: Embed and save external .lrc file
  - Perfect for players like Samsung Music that prefer external .lrc files
  - LRC files include metadata headers (title, artist, by:SpotiFLAC-Mobile)
  - Works with all download services (Tidal, Qobuz, Amazon)

- **CSV Import Quality Selection**: Choose audio quality when importing CSV playlists
  - Quality picker now appears before adding CSV tracks to download queue
  - Select between FLAC qualities (Lossless, Hi-Res, Hi-Res Max) or MP3
  - Respects "Ask quality before download" setting - uses default quality if disabled

  - **Persistent Cover Image Cache**: Album/track cover images now cached to persistent storage instead of temporary directory
  - Cover images no longer disappear when app is closed or device restarts
  - Cache stored in `app_flutter/cover_cache/` directory (not cleared by system)
  - Maximum 1000 images cached for up to 365 days
  - Covers are cached when displayed in History, Home, Album, Artist, or any other screen
  - New `CoverCacheManager` service with `clearCache()` and `getStats()` methods for future cache management

- **Extended Metadata from Deezer Enrichment**: Track downloads now include label, copyright, and genre metadata from Deezer
  - New fields in `ExtTrackMetadata`: `label`, `copyright`, `genre`
  - Metadata fetched during `enrichTrack()` via Deezer album API
  - Embedded as FLAC Vorbis comments: `GENRE`, `ORGANIZATION` (label), `COPYRIGHT`
  - Works for both extension downloads and built-in provider downloads (Tidal, Qobuz, Amazon)

- **Track Metadata Screen Extended Info**: Genre, label, and copyright now displayed in track metadata screen
  - Added `genre`, `label`, `copyright` fields to `DownloadHistoryItem` model
  - Metadata is stored in download history and persists across app restarts
  - New localization strings: `trackGenre`, `trackLabel`, `trackCopyright`

- **`utils.randomUserAgent()` for Extensions**: New utility function for extensions to get random browser User-Agent strings
  - Returns modern Chrome User-Agent format: `Chrome/{120-145}.0.{6000-7499}.{100-299}` with `Windows NT 10.0`
  - Useful for extensions that need to rotate User-Agents to avoid detection

### Fixed

- **Portuguese Language Bug**: Fixed locale parsing for languages with country codes (e.g., pt_PT, es_ES)
  - App now correctly loads Portuguese and Spanish translations
  - Updated Portuguese label to "Português (Brasil)"

- **VM Race Condition Panic**: Fixed `panic during execution: runtime error: index out of range [-2]` crash when switching search providers
  - Root cause: Goja VM was being accessed concurrently by multiple goroutines without synchronization
  - Added `VMMu sync.Mutex` to `LoadedExtension` struct
  - Added mutex lock/unlock to ALL `ExtensionProviderWrapper` methods:
    - `SearchTracks`, `GetTrack`, `GetAlbum`, `GetArtist`
    - `EnrichTrack`, `CheckAvailability`, `GetDownloadURL`, `Download`
    - `CustomSearch`, `HandleURL`, `MatchTrack`, `PostProcess`
  - Prevents race conditions when rapidly switching between extension search providers

- **Tidal Release Date Fallback**: Fixed missing release date in FLAC metadata when downloading from Tidal
  - Now uses Tidal API's release date when `req.ReleaseDate` is empty
  - Ensures release date is always embedded in downloaded files

- **Extended Metadata for M4A→FLAC Conversion**: Fixed genre, label, and copyright not being embedded when converting Amazon M4A to FLAC
  - Flutter now extracts extended metadata from Go backend response
  - Passes `genre`, `label`, `copyright` parameters to `_embedMetadataAndCover()`
  - Tags correctly embedded during FFmpeg conversion

- **Extended Metadata for MP3 Conversion**: Genre, label, and copyright now embedded in MP3 files when converting from FLAC
  - Added `genre`, `label`, `copyright` parameters to `_embedMetadataToMp3()`
  - Tags embedded as ID3v2: `GENRE`, `ORGANIZATION` (label), `COPYRIGHT`

### Extensions

- **spotify-web Extension**: Updated to v1.7.0
  - Added `getMetadataFromDeezer()` function to fetch extended metadata:
    - ISRC from track
    - Label from album
    - Copyright (generated as "YEAR LABEL")
    - Genre from album genres
    - Release date
  - `enrichTrack()` now returns all extended metadata to Go backend
  - Replaced all hardcoded User-Agent strings with `utils.randomUserAgent()`

### Performance

- **Faster App Startup**: Notification, Share Intent, and Cover Cache Manager initialization now run in parallel
- **Download Queue Polling**: Batched progress updates reduce rebuilds and list allocations during active downloads
- **Queue Item Updates**: Status/progress updates now skip no-op changes and update by index for fewer allocations
- **Directory Creation**: Download output folders are created once per path, reducing repeated I/O for albums/singles
- **Search Results Rendering**: Single-pass filtering avoids repeated `indexOf` calls for large result sets
- **Queue Lookups in UI**: O(1) lookup for queue status in Home/Album/Playlist/Artist track lists
- **History Filtering**: Album/single counts and grouping are computed once per build
- **Downloaded Album View**: Tracks are grouped by disc in one pass to reduce filtering overhead
- **Track Metadata Screen**:
  - Palette extraction deferred until after transition; reduced sample size for smoother navigation
  - File stat uses a single syscall and only triggers state updates on change
  - Static regex/month table avoids repeated allocations
  - Cover precached before opening metadata from history/queue/recents
- **Flutter Provider Optimizations**:
  - Cache `SharedPreferences` instance in `DownloadHistoryNotifier` and `DownloadQueueNotifier` to avoid repeated `getInstance()` calls
  - Precompile regex for folder name sanitization and year extraction (top-level `final`)
  - Use `indexWhere` instead of `firstWhere` with placeholder object to reduce allocations in queue processing
- **Flutter UI Optimizations**:
  - Selective `ref.watch()` for `downloadQueueProvider` (watch only `queuedCount` or `items` instead of entire state)
  - Pass `Track` directly to `_buildTrackTile()` instead of index lookup inside builder
  - Pass `historyItems` as parameter to `_buildRecentAccess()` to avoid `ref.read()` inside method
- **M4A Metadata Embedding**: Streaming implementation reduces memory usage for large files
  - Uses `os.Open()` + `ReadAt` instead of `os.ReadFile()` (no full file load into memory)
  - Atomic file replacement via temp file + rename for safer writes
  - New helper functions: `findAtomInRange()`, `readAtomHeaderAt()`, `copyRange()`

### Backend

- **Deezer ISRC Fetching**: Uses ISRCs already present in payloads and caches them, cutting extra API calls
- **SearchAll Allocation**: Preallocated slices to reduce allocations during Deezer search
- **HTTP Client Helper**: Refactored HTTP client creation to use `NewHTTPClientWithTimeout()` helper function across `lyrics.go`, `qobuz.go`, `tidal.go`

### Technical

- **Go Backend Changes**:
  - `go_backend/extension_providers.go`: Added `Label`, `Copyright`, `Genre` fields to `ExtTrackMetadata`; added mutex locks to all provider methods
  - `go_backend/extension_manager.go`: Added `VMMu sync.Mutex` to `LoadedExtension` struct
  - `go_backend/extension_runtime.go`: Added `utils.randomUserAgent` function
  - `go_backend/extension_runtime_utils.go`: Added `randomUserAgent()` implementation
  - `go_backend/httputil.go`: Updated `getRandomUserAgent()` to use modern Chrome versions
  - `go_backend/tidal.go`: Added release date fallback logic
  - `go_backend/exports.go`: Added `Genre`, `Label`, `Copyright` fields to `DownloadResponse`

- **Flutter Changes**:
  - `lib/services/cover_cache_manager.dart`: New persistent cache manager for cover images (365 days, 1000 images max)
  - `lib/widgets/cached_cover_image.dart`: Wrapper widget for CachedNetworkImage with persistent cache
  - `lib/main.dart`: Added `CoverCacheManager.initialize()` to app startup
  - `lib/screens/*.dart`: All 11 screens updated to use persistent cache manager for CachedNetworkImage
  - `lib/providers/download_queue_provider.dart`: Updated `_embedMetadataAndCover()` to accept and embed genre, label, copyright; added `genre`, `label`, `copyright` fields to `DownloadHistoryItem`
  - `lib/screens/track_metadata_screen.dart`: Display genre, label, copyright in metadata grid
  - `lib/l10n/arb/app_en.arb`: Added `trackGenre`, `trackLabel`, `trackCopyright` localization strings

### Dependencies

- Added `flutter_cache_manager: ^3.4.1` (explicit dependency for persistent cache)
- Added `path: ^1.9.0` (for cache directory path handling)

---

## [3.1.2] - 2026-01-19

### Added

- **New Languages**: Added Spanish (es) and Portuguese (pt) translations
  - Spanish: Credits 125 ([@credits125](https://crowdin.com/profile/credits125))
  - Portuguese: Pedro Marcondes ([@justapedro](https://crowdin.com/profile/justapedro))
  - Russian: Владислав ([@odinokiy_kot](https://crowdin.com/profile/odinokiy_kot))

- **Quick Search Provider Switcher** ([#76](https://github.com/zarzet/SpotiFLAC-Mobile/issues/76)): Dropdown menu in search bar for instant provider switching
  - Tap the search icon to reveal a dropdown menu with all available search providers
  - Shows default provider (Deezer based on metadata source setting) at the top
  - Lists all enabled extensions with custom search capability
  - Displays extension icons when available
  - Checkmark indicates currently selected provider
  - Search hint text updates immediately when switching providers
  - Re-triggers search automatically if there's existing text in the search bar
  - Eliminates need to navigate to Settings > Extensions > Search Provider

- **Extension Button Setting Type** ([#74](https://github.com/zarzet/SpotiFLAC-Mobile/issues/74)): New setting type for extension actions
  - Extensions can define `button` type in manifest settings
  - Triggers JavaScript function when tapped (e.g., start OAuth flow)
  - Useful for authentication, manual sync, or any custom action

- **Genre & Label Metadata** ([#75](https://github.com/zarzet/SpotiFLAC-Mobile/issues/75)): Downloaded tracks now include genre and record label information
  - Fetches genre and label from Deezer album API for each track
  - Embeds GENRE, ORGANIZATION (label), and COPYRIGHT tags into FLAC files
  - Works automatically when Deezer track ID is available (via ISRC matching)
  - Supports all download services (Tidal, Qobuz, Amazon) and extension downloads

- **MP3 Quality Option** ([#69](https://github.com/zarzet/SpotiFLAC-Mobile/issues/69)): Optional MP3 download format with FLAC-to-MP3 conversion
  - New "Enable MP3 Option" toggle in Settings > Download > Audio Quality
  - When enabled, MP3 (320kbps) appears as a quality option alongside FLAC options
  - Available in both the quality picker dialog and default quality settings
  - Works with all services (Tidal, Qobuz, Amazon) and extensions

- **MP3 Metadata Embedding**: Full metadata support for MP3 files
  - Cover art embedded using ID3v2 tags
  - Synced lyrics embedded (fetched from lrclib.net)
  - All metadata preserved: title, artist, album, album artist, track/disc number, date, ISRC
  - Automatic tag conversion from Vorbis comments (FLAC) to ID3v2 (MP3)

- **Dominant Color Header**: Album, Playlist, Downloaded Album, and Track Metadata screens now feature dynamic header backgrounds
  - Extracts dominant color from cover art using `palette_generator`
  - Creates a gradient from dominant color to theme surface color
  - Smooth 500ms color transition animation

- **Larger Cover Art**: Cover images on detail screens are now 50% of screen width (previously 140px fixed)
  - More prominent album artwork display
  - Larger shadow and rounded corners (20px radius)
  - Higher resolution cover caching

- **Sticky Title**: Title appears in AppBar when scrolling past the info card
  - Smooth fade-in animation (200ms) when scrolling down
  - Title hidden when header is expanded (shows in info card instead)
  - AppBar uses theme color (surface) for clean, native look
  - Works on Album, Playlist, Downloaded Album, Track Metadata, and Artist screens

- **Artist Name in Album Screen**: Album info card now displays artist name below album title
  - Extracted from first track's artist metadata
  - Styled with `onSurfaceVariant` color for visual hierarchy

- **Disc Separation for Multi-Disc Albums** ([#70](https://github.com/zarzet/SpotiFLAC-Mobile/issues/70)): Downloaded albums with multiple discs now display tracks grouped by disc
  - Visual disc separator header showing "Disc 1", "Disc 2", etc.
  - Tracks sorted by disc number first, then by track number
  - Single-disc albums display normally without separators
  - Fixes confusion when albums have duplicate track numbers across discs

- **Album Grouping in Recents** ([#70](https://github.com/zarzet/SpotiFLAC-Mobile/issues/70)): Downloads now show as albums instead of individual tracks in the Recent section
  - Prevents flooding the recents list when downloading full albums
  - Groups tracks by album name and artist
  - Tapping navigates directly to the downloaded album screen
  - Shows the most recent download time for each album

### Changed

- **FFmpeg FLAC-to-MP3 Conversion**: Improved conversion process
  - MP3 files now saved in the same folder as FLAC (no separate MP3 subfolder)
  - Original FLAC file automatically deleted after successful conversion
  - New `embedMetadataToMp3()` method for MP3-specific tag embedding

- **Sticky Header Theme Integration**: AppBar background uses `colorScheme.surface` instead of dominant color when collapsed
  - Dark theme: Black background with white text
  - Light theme: White background with black text
  - Matches modern app behavior for better readability

### Fixed

- **MP3 Quality Display in Track Metadata**: Fixed incorrect quality display for MP3 files
  - MP3 files now show "320kbps" instead of FLAC's bit depth/sample rate
  - History no longer stores FLAC audio specs for converted MP3 files
  - Both File Info badges and metadata grid show correct MP3 quality

- **Empty Catch Blocks**: Fixed analyzer warnings for empty catch blocks
  - `download_queue_provider.dart`: Added comments explaining why polling errors are silently ignored
  - `track_provider.dart`: Added comments explaining why availability check errors are silently ignored
  - `ffmpeg_service.dart`: Added proper error logging for temp file cleanup failures

- **Russian Plural Forms**: Fixed ICU syntax warnings in Russian localization
  - Removed redundant `=1` clauses that were overriding `one` plural category
  - Affected 10 plural strings including track counts and delete confirmations
  - Plurals now correctly handle Russian grammar (1 трек, 2 трека, 5 треков)

### Dependencies

- Added `palette_generator: ^0.3.3+4` for cover art color extraction

---

## [3.1.1] - 2026-01-17

### Added

- **Lyrics Caching**: Lyrics are now cached for 24 hours to reduce API calls and improve performance
  - Thread-safe cache with automatic expiration
  - Cache key based on artist, track, and duration
  - Log indicator shows "(cached)" when lyrics are served from cache

- **Lyrics Duration Matching**: Improved lyrics accuracy with duration-based matching
  - Compares track duration with lrclib.net results
  - 10-second tolerance to handle version differences (radio edit, remaster, etc.)
  - Prioritizes synced lyrics over plain text when duration matches
  - Falls back gracefully if no duration match found

- **Deezer Cover Art Upgrade**: Cover art from Deezer CDN now automatically upgraded to maximum quality
  - Detects Deezer CDN URLs (`cdn-images.dzcdn.net`)
  - Upgrades cover resolution to 1800x1800 (max available)
  - Works alongside existing cover upgrade

- **Live Search for Extensions**: Search-as-you-type functionality for extension search
  - 800ms debounce delay to prevent excessive API calls
  - Minimum 3 characters required before searching
  - Concurrency control to prevent race conditions in extension runtime
  - Queues pending searches if a search is already in progress

- **Russian Language Support**: Added Russian (Русский) translation - 99% complete
  - Translated via Crowdin community contributions
  - Covers all UI elements, settings, and error messages

### Fixed

- **ISRC Index Race Condition**: Fixed repeated index rebuilding during parallel downloads
  - Added per-directory build lock using `sync.Map` and `sync.Mutex`
  - Double-check locking pattern ensures index is built only once
  - Significantly improves performance during CSV import with many tracks

- **Queue Tab Scroll Exception**: Fixed Flutter rendering exception with NestedScrollView
  - Disabled Material 3 stretch overscroll indicator that caused `_StretchController` assertion
  - Wrapped NestedScrollView with ScrollConfiguration to prevent `setState during build` errors
  - Issue was especially noticeable during rapid queue updates (CSV import)

- **CSV Import**: Fixed CSV export not being parsed correctly
  - Added support for `Artist Name(s)` header (with parentheses)
  - Added support for `Track URI` header for track IDs
  - Added `artists` and `track_id` as alternative header names
  - Now correctly parses "Liked Songs" and playlist exports

---

## [3.1.0] - 2026-01-16

### Added

- **Recent Access History**: Quick access to recently visited content when tapping the search bar
- **Artist Screen Redesign**: Full-width header, monthly listeners, top tracks section
- **Extension Store Update Badge**: Badge indicator showing available extension updates
- **Extension Compatibility Warning**: Warning for extensions requiring newer app version
- **Year in Album Folder Name**: New folder structure options with release year
- **Extension Album/Playlist/Artist Support**: Extensions can now return collections in search
- **Odesli Integration**: YouTube Music extension can now match tracks to Deezer/Tidal/Qobuz
- **Download Cancel**: Properly stops in-flight downloads

### Changed

- Search bar behavior improved with recent access history

### Fixed

- Multiple extension-related fixes for artist, album, and playlist handling
- UI fixes for search, settings, and navigation

---

## [3.0.0] - 2026-01-14

### Extension System (Major Feature)

SpotiFLAC 3.0 introduces a powerful extension system that allows third-party integrations for metadata, downloads, and more.

- **Extension Store**: Browse and install extensions directly from the app
- **Web Extension**: Metadata provider for personalized playlists
- **Extension Capabilities**: Custom search, URL handlers, thumbnail ratios, post-processing
- **Extension APIs**: Full HTTP, storage, file, and crypto support
- **Security**: Sandboxed JavaScript runtime with permission-based access

### Added

- Album folder structure settings
- Separate singles folder option
- Year in album folder name
- Parallel API calls for faster downloads
- Swipeable history filters

### Fixed

- Tab edge overscroll
- Extension duplicate load error
- Settings item highlight on swipe
- Back gesture freeze on Android 13+
- Bottom overflow in dialogs
- Japanese artist name matching
- Multi-artist matching
- Max resolution cover download
- Various extension-related fixes

---

*For older versions, see [GitHub Releases](https://github.com/zarzet/SpotiFLAC-Mobile/releases)*
