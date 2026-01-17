# Changelog

## [3.1.0] - 2026-01-19

### Added

- **Recent Access History**: Quick access to recently visited content when tapping the search bar
  - Shows recently visited artists, albums, playlists, and downloaded tracks
  - Merged view combining navigation history and download history
  - Tap to quickly navigate back to previously accessed content
  - X button to remove individual items from history
  - "Clear All" button to clear entire history
  - Persists across app restarts (stored in SharedPreferences)
  - Max 20 items stored, sorted by most recent
  - Multi-language support (Artist/Album/Song/Playlist labels localized)

- **Artist Screen Redesign**
  - Full-width header image (380px) with gradient overlay
  - Artist name displayed at bottom of header with text shadow
  - Monthly listeners count display (formatted with compact notation)
  - "Popular" section showing top 5 tracks with download status indicators
  - Dynamic download button states (queued, downloading, completed)
  - Header image and top tracks fetched from extension metadata
  - Image alignment set to top-center to show faces properly

- **Extension Store Update Badge**: Badge indicator on Store tab icon showing number of available updates
  - Users can see extension updates are available without opening Store tab
  - Badge shows count of extensions with updates

- **Extension Compatibility Warning**: Warning badge for extensions requiring newer app version
  - Extensions with `minAppVersion` higher than current app show warning label
  - Label displays "Requires vX.X.X+" to encourage users to upgrade
  - Users can still install the extension (not blocked)

- **Year in Album Folder Name** ([#50](https://github.com/zarzet/SpotiFLAC-Mobile/issues/50)): New album folder structure options with release year

  - `Artist / [Year] Album`: Albums/Coldplay/[2005] X&Y/
  - `[Year] Album Only`: Albums/[2005] X&Y/
  - Year extracted from release date metadata
  - Matches desktop SpotiFLAC folder structure

- **Extension Album/Playlist/Artist Support**: Extensions can now return albums, playlists, and artists in search results

  - Search results now properly separated into Albums, Playlists, Artists, and Songs sections
  - Albums, playlists, and artists show chevron icon (navigate to detail) instead of download button
  - Tap album/playlist to view track list and download
  - Tap artist to view their albums/discography
  - New `getAlbum()`, `getPlaylist()`, and `getArtist()` extension functions
  - New `ExtensionAlbumScreen`, `ExtensionPlaylistScreen`, and `ExtensionArtistScreen` for fetching content from extensions
  - YouTube Music extension updated with album/playlist/artist support

- **Odesli (song.link) Integration for YouTube Music Extension**
  - New `enrichTrack()` function to fetch ISRC and external service links
  - Uses Odesli API to convert YouTube Music tracks to Deezer/Tidal/Qobuz
  - Enables built-in service fallback for high-quality audio downloads
  - Extension version updated to 1.4.0 with `api.song.link` and `odesli.io` network permissions
- **Download Cancel**: Canceling a download now stops in-flight built-in provider downloads (Tidal/Qobuz/Amazon) and clears backend progress tracking.

### Changed

- **Search Bar Behavior**: Tapping search bar now immediately moves it to top position
  - Logo and subtitle hide when search bar is focused
  - Recent access history appears in the content area below
  - More space for recent items, not blocked by keyboard

### Fixed

- Fixed search source chips still referencing removed badge props.
- Fixed extension artist album metadata to preserve provider IDs and cover URLs for correct navigation.
- Fixed extension playlist fetch to populate provider IDs and reject disabled extensions.
- Fixed extension collection screens calling setState after dispose during async loads.
- Fixed URL handler responses to include provider IDs for extension albums and artists.
- Fixed YTMusic extension not extracting album name and duration from search results.
  - Album name is now extracted from flexColumns/subtitle when linked to album browseId.
  - Duration is now extracted from fixedColumns/flexColumns in addition to existing sources.
- Fixed "Separate Singles" setting not working ([#54](https://github.com/zarzet/SpotiFLAC-Mobile/issues/54)) - singles were going to Albums folder.
  - Root cause: `albumType` was not being extracted from Deezer API during metadata enrichment.
  - Deezer track responses now correctly include `album_type` (single/ep/album/compilation).
  - Track creation now preserves `albumType` and `source` fields throughout download flow.
- Fixed PageView overscroll at edges (BouncingScrollPhysics → ClampingScrollPhysics)
- Fixed settings item highlight on swipe (highlightColor: Colors.transparent)
- Fixed extension duplicate load error (skip silently instead of throwing error)
- Fixed keyboard appearing when swiping between tabs (unfocus on page change)
- Removed "Free"/"API Key" badges from search source selector
- Fixed cancel action briefly resuming downloads in the queue UI after ~1 second.
- Fixed cancelled downloads being marked as failed when the backend returns after cancellation.
- Fixed cancel triggering provider fallback (cancel now stops the download flow immediately).
- Fixed stale ISRC cache returning deleted files after cancel.
- Fixed search results mixing extension and built-in artists when using default provider.
- Fixed audio files opening with non-music apps by passing audio MIME type on open.
- Fixed album artist showing null/blank by normalizing empty metadata and using artist fallback for tags.
- Fixed `use_build_context_synchronously` lint warnings in `home_tab.dart`
- Fixed `unnecessary_underscores` lint warnings in error widget callbacks
- Fixed duplicate artist entries in recent history (recording now only happens in screen's initState)
- **Go Backend: Missing `item_type` and `album_type` fields**
  - Added `ItemType` and `AlbumType` fields to `ExtTrackMetadata` struct
  - Fixed `CustomSearchWithExtensionJSON` - now includes `item_type` and `album_type` in response
  - Fixed `HandleURLWithExtensionJSON` - now includes `item_type` and `album_type` for tracks
  - Fixed `GetAlbumWithExtensionJSON` - now includes `item_type` and `album_type` for album tracks
  - Fixed `GetPlaylistWithExtensionJSON` - now includes `item_type` and `album_type` for playlist tracks
- **Album/Playlist Track Thumbnails**: Tracks inside albums/playlists now use album/playlist cover as fallback when no individual cover exists
- **YouTube Music Extension getArtist**: Fixed `getArtist()` function not being registered in extension, causing artist pages to fail with "returned null" error
- **Recent Access UI**: Fixed recent access list disappearing when keyboard is dismissed - now stays visible until user presses Back button
- **Extension Artist Top Tracks**: Fixed top tracks not appearing when opening artist from extension search results
  - YT Music extension `getArtist()` now returns `top_tracks` array with up to 10 popular songs
  - Go backend `GetArtistWithExtensionJSON` now forwards `top_tracks`, `header_image`, and `listeners` to Flutter
  - `ExtensionArtistScreen` now parses and passes top tracks to `ArtistScreen`
  - `ArtistScreen` with `extensionId` skips Spotify/Deezer fetch, uses extension data only (fixes "Rate Limited" errors)
- **Search Bar Unfocus**: Fixed search bar not unfocusing when tapping outside - now properly dismisses keyboard and unfocus when tapping anywhere outside the search field
- **Keyboard Appearing on Settings Navigation**: Fixed keyboard randomly appearing when returning from Settings sub-pages (e.g., Appearance) - now uses `FocusManager.instance.primaryFocus?.unfocus()` for more aggressive unfocus
- **Recent Access Artist Navigation**: Fixed opening artist from recent access using wrong screen - now correctly uses `ExtensionArtistScreen` for extension artists (YT Music, Spotify Web) instead of trying to fetch from Spotify API

### Extensions

- **YouTube Music Extension**: Updated to v1.5.0
  - `getArtist()` now returns `top_tracks` array with popular songs
  - Added `header_image` and `listeners` to artist response
- **Spotify Web Extension**: Updated to v1.6.0

### Localization

- **Multi-Language Support**: App now supports multiple languages with community contributions via Crowdin
  - Available languages: English, Indonesian (Bahasa Indonesia)
  - More languages coming soon with community translations
  - Contribute translations at [Crowdin](https://crowdin.com/project/spotiflac-mobile)
- Added new localization strings for recent access types:
  - `recentTypeArtist` - "Artist" / "Artis"
  - `recentTypeAlbum` - "Album" / "Album"
  - `recentTypeSong` - "Song" / "Lagu"
  - `recentTypePlaylist` - "Playlist" / "Playlist"
  - `recentPlaylistInfo` - "Playlist: {name}"
  - `errorGeneric` - "Error: {message}"

---

## [3.0.0] - 2026-01-14

### Extension System (Major Feature)

SpotiFLAC 3.0 introduces a powerful extension system that allows third-party integrations for metadata, downloads, and more.

#### Extension Store

- Browse and install extensions directly from the app
- New "Store" tab in bottom navigation
- Browse by category: Metadata, Download, Utility, Lyrics, Integration
- Search extensions by name, description, or tags
- One-tap install, update, and uninstall
- Offline cache for browsing without internet

#### Spotify Web Extension

- Available in Extension Store - install and enable in Settings > Extensions
- Metadata provider using Spotify's internal web player API
- Download tracks from Daily Mix, Discover Weekly, and other personalized playlists
- Useful when official Spotify API is rate-limited or unavailable

#### Extension Capabilities

- **Custom Search Providers**
- **Custom URL Handlers**
- **Custom Thumbnail Ratios**: Square (1:1), Wide (16:9), Portrait (2:3)
- **Post-Processing Hooks**: Extensions can process downloaded files
- **Quality Options**: Extensions can define custom quality settings

#### Extension APIs

- Full HTTP support: GET, POST, PUT, DELETE, PATCH
- Persistent cookie jar per extension
- Browser-like polyfills: `fetch()`, `atob()`/`btoa()`, `TextEncoder`/`TextDecoder`, `URL`/`URLSearchParams`
- Storage API for persistent data
- File API for file operations
- HMAC-SHA1 utility for cryptographic operations

#### Security

- Sandboxed JavaScript runtime (goja)
- Permission-based access control
- Network domain whitelisting
- Improved credential encryption with per-installation random salt

### Added

- **Album Folder Structure Setting**: Option to remove artist folder from album path

  - `Artist / Album` (default): `Albums/Artist Name/Album Name/`
  - `Album Only`: `Albums/Album Name/`

- **Separate Singles Folder**: Organize downloads into Albums/ and Singles/ folders

  - Based on `album_type` from Spotify/Deezer metadata
  - Toggle in Settings > Download > Separate Singles Folder

- **Year in Album Folder Name**: New album folder structure options with release year

  - `Artist / [Year] Album`: Albums/Coldplay/[2005] X&Y/
  - `[Year] Album Only`: Albums/[2005] X&Y/
  - Year extracted from release date metadata
  - Matches desktop SpotiFLAC folder structure

- **Parallel API Calls**: Download URL fetching now uses parallel requests
  - Tidal: All 8 APIs requested simultaneously, first success wins
  - Qobuz: Both APIs requested simultaneously, first success wins
  - Significantly reduces download URL fetch time

### UI/UX Improvements

- **Swipeable History Filters**: History tab now supports swipe gestures between All, Albums, and Singles filters

  - Swipe left/right to switch between filter tabs
  - Filter chips sync with swipe position
  - Smooth edge-to-edge transition: swipe past Singles to go to Store, swipe past All to go to Home
  - Natural gesture feel - drag connects to parent navigation

  - **Improved File Open Intent**: Play button in History now correctly opens music players only
  - Added proper MIME type (`audio/flac`, `audio/mpeg`, etc.) when opening downloaded files
  - Prevents system from showing unrelated apps in the "Open with" dialog

### Fixed

- **Fixed Tab Edge Overscroll**: Home and Settings tabs now stop at edges instead of bouncing into empty space

- **Fixed Extension Duplicate Load Error**: Extension loading now silently skips already-loaded extensions instead of throwing error

- **Fixed Settings Item Highlight on Swipe**: Settings items no longer highlight when swiping at page edge

- **Fixed Keyboard Appearing on Tab Switch**: Keyboard now auto-dismisses when swiping between tabs

- **Removed Search Source Badges**: Removed "Free" and "API Key" labels from Deezer/Spotify selector in Options

- **Back Gesture Freeze on Android 13+**: Fixed app freeze when using back gesture in settings

  - Added `PopScope` with `canPop: true` to all settings pages
  - Changed navigation to use `PageRouteBuilder` with proper slide transition

- **Bottom Overflow in Folder Organization Dialog**: Fixed overflow in portrait and landscape mode

  - Made dialog scrollable with max height constraint

- **Japanese Artist Name Order**: Fixed artist mismatch for Japanese names

  - "Sawano Hiroyuki" vs "Hiroyuki Sawano" now correctly matches

- **Multi-Artist Matching**: Fixed artist mismatch for collaboration tracks

  - "RADWIMPS feat. Toko Miura" now matches when service only shows "Toko Miura"

- **Max Resolution Cover Download**: Fixed cover not upgrading to max resolution on mobile

  - Mobile now correctly upgrades 300x300 → 640x640 → max resolution (~2000x2000)

- **EXISTS: Prefix in File Path**: Fixed "File not found" error in metadata screen

  - Duplicate detection prefix now stripped before saving to history

- **Extension Search Result Parsing**: Fixed "cannot unmarshal array" error

  - Go backend now handles both array and object formats from extensions

- **Store Tab Unmount Crash**: Fixed "Using ref when widget is unmounted" error

- **Duplicate History Entries**: Fixed duplicate entries when re-downloading same track

  - Detects existing entries by Spotify ID, Deezer ID, or ISRC

- **Permission Error Message**: Fixed download showing "Song not found" when actually permission error

  - Now shows proper message: "Cannot write to folder, check storage permission"

- **Android 13+ Storage Permission**: Fixed storage permission not working on Android 13+
  - Now requests both `MANAGE_EXTERNAL_STORAGE` and `READ_MEDIA_AUDIO`

### Changed

- **Extension Manifest**: New `file` permission required for file operations
  ```json
  "permissions": {
    "network": ["api.example.com"],
    "storage": true,
    "file": true
  }
  ```

### Technical

- Go backend: Simplified parallel download result handling in Tidal/Qobuz
- Go backend: Removed unused functions and fixed bit shifting warnings
- Release workflow: Fixed duplicate `---` separator in release notes

---

## [3.0.0-beta.2] - 2026-01-13

### Added

- **Album Folder Structure Setting**: Option to remove artist folder from album path
  - New setting in Download Settings when "Separate Singles Folder" is enabled
  - `Artist / Album` (default): `Albums/Artist Name/Album Name/`
  - `Album Only`: `Albums/Album Name/`
  - Requested by user who prefers flat album organization

### Fixed

- **Back Gesture Freeze on OnePlus/Android 13+**: Fixed app freeze when using back gesture in settings

  - Added `PopScope` with `canPop: true` to all settings pages
  - Changed navigation to use `PageRouteBuilder` with proper slide transition
  - Fixes predictive back gesture conflict on devices with gesture navigation
  - Affected pages: Download, Appearance, Options, Extensions, About, Logs, Extension Detail

- **Extension Search Result Parsing**: Fixed "cannot unmarshal array into Go value" error

  - Go backend now handles both array and object formats from extensions
  - Extensions returning `[{track}, {track}]` now work correctly
  - Extensions returning `{tracks: [...], total: N}` still work as before

- **Max Resolution Cover Download**: Fixed cover not upgrading to max resolution on mobile

  - Added missing `spotifySize300` constant (300x300 size code)
  - Mobile now correctly upgrades 300x300 → 640x640 → max resolution (~2000x2000)
  - Added `_upgradeToMaxQualityCover()` helper in Flutter for M4A conversion path
  - Go backend `cover.go` now directly replaces URL without HEAD verification

- **Extension Search Provider Reset**: Fixed search provider not resetting to default when disabled

  - `copyWith` in `AppSettings` couldn't set `searchProvider` to `null`
  - Added `clearSearchProvider` boolean parameter to properly clear the value
  - Settings menu now correctly switches back to default provider

- **Extension Disabled Search Fallback**: Fixed error when extension is disabled but still called

  - `_performSearch` now checks if extension is still enabled before calling custom search
  - Automatically falls back to Deezer/Spotify search if extension was disabled
  - Clears `searchProvider` setting if extension no longer available

- **Store Tab Unmount Crash**: Fixed "Using ref when widget is unmounted" error

  - Added `mounted` check after async operation in `_initialize()`
  - Prevents crash when navigating away from Store tab during initialization

- **EXISTS: Prefix in File Path**: Fixed "File not found" error in metadata screen after download

  - Duplicate detection was adding `EXISTS:` prefix to file paths
  - Prefix now stripped before saving to download history
  - Legacy history items with prefix are handled gracefully

- **History Error Badge**: Fixed error badge showing on history items even when file exists

  - `queue_tab.dart` now strips `EXISTS:` prefix before checking file existence
  - File open and delete operations also use cleaned path

- **Extension Artist URL Handler**: Fixed artist pages showing "0 releases" from extensions

  - Extension `fetchArtist` now returns correct format: `{ type: "artist", artist: { albums } }`
  - Go backend `HandleURLWithExtensionJSON` now includes albums in artist response
  - Added `AlbumType` field to `ExtAlbumMetadata` struct

- **Extension Artist Name in Logs**: Fixed empty artist name in extension track logs

  - Now uses `firstArtist` + `otherArtists` instead of deprecated `artists.items`
  - Logs correctly show "Fetched track: {title} by {artist}"

- **Japanese Artist Name Order**: Fixed artist mismatch for Japanese names with different order

  - "Sawano Hiroyuki" vs "Hiroyuki Sawano" now correctly matches
  - Added `sameWordsUnordered` check to both Tidal and Qobuz artist matching
  - Handles Japanese name order (family name first) vs Western name order (given name first)

- **Multi-Artist Matching**: Fixed artist mismatch for collaboration tracks

  - "RADWIMPS feat. Toko Miura" now matches when Qobuz/Tidal only shows "Toko Miura"
  - Split artists by separators (`, `, `feat.`, `ft.`, `&`, `and`, `x`)
  - Match if ANY expected artist matches ANY found artist

- **Cover Download Logging**: Improved cover download logs for debugging
  - Shows original URL, upgrade steps, and final URL
  - Displays estimated resolution based on file size
  - Logs now appear in Settings > Logs via GoLog

---

## [3.0.0-beta.1] - 2026-01-13

### Security

- Improved extension sandbox security
- Improved credential encryption with per-installation random salt

### Changed

- **Extension Manifest**: New `file` permission required for file operations
  ```json
  "permissions": {
    "network": ["api.example.com"],
    "storage": true,
    "file": true
  }
  ```
  Extensions that need to download files must declare `"file": true` in manifest.

### Fixed

- Extension packages now preserve directory structure (subdirectories supported)
- Back gesture freeze in settings pages on Android gesture navigation

---

## [3.0.0-alpha.4] - 2026-01-12

### Added

- **Extension Store**: Browse and install extensions directly from the app

  - New "Store" tab in bottom navigation
  - Browse extensions by category (Metadata, Download, Utility, Lyrics, Integration)
  - Search extensions by name, description, or tags
  - One-tap install and update
  - Offline cache for browsing without internet
  - Extensions hosted at github.com/zarzet/SpotiFLAC-Extension

- **Custom URL Handler for Extensions**: Extensions can now register custom URL patterns

  - Handle URLs from YouTube Music, SoundCloud, Bandcamp, etc.
  - Manifest config: `urlHandler: { enabled: true, patterns: ["music.youtube.com"] }`
  - Implement `handleUrl(url)` function in extension to parse and return track metadata
  - SpotiFLAC automatically routes matching URLs to the appropriate extension
  - Supports share intents and paste from clipboard

- **Artist URL Handler Support**: Extensions can now return artist data from URL handlers

  - Added `type: "artist"` handling in track_provider.dart
  - Navigate to artist screen with albums list from extension

- **HMAC-SHA1 Utility**: New `utils.hmacSHA1(key, message)` function for extensions
  - Enables TOTP generation and other cryptographic operations
  - Returns byte array for flexible use

### Fixed

- **Extension Store Refresh**: Store tab now properly refreshes after uninstalling an extension
  - "Installed" badge correctly updates to "Install" button

### Documentation

- Updated `docs/EXTENSION_DEVELOPMENT.md`:
  - Added Custom URL Handler section with examples
  - Added `handleUrl` function documentation
  - Added URL pattern examples for YouTube, SoundCloud, Bandcamp
  - Added `utils.hmacSHA1` documentation with TOTP example

### Extensions

- **Spotify Web Extension** (example): New extension for Spotify metadata via web API
  - Supports personalized playlists (Daily Mix, Discover Weekly, Release Radar, etc.)
  - Search, album, playlist, track, and artist fetching
  - Available in Extension Store (3.0.0-alpha.4)

---

## [3.0.0-alpha.3] - 2026-01-12

### Added

- **Separate Singles Folder**: Option to organize downloads into Albums/ and Singles/ folders
  - Based on `album_type` from Spotify/Deezer metadata
  - Toggle in Settings > Download > Separate Singles Folder
  - Singles saved to `{output}/Singles/`, albums to `{output}/Albums/`
- **Browser-like Polyfills**: New global APIs for easier library porting
  - `fetch()` - Browser-compatible HTTP API with `json()`, `text()`, `arrayBuffer()` methods
  - `atob()` / `btoa()` - Global Base64 encoding/decoding
  - `TextEncoder` / `TextDecoder` - UTF-8 text encoding classes
  - `URL` / `URLSearchParams` - URL parsing and manipulation classes
  - Makes porting browser libraries (like `youtubei.js`) much easier

### Performance

- **Parallel API Calls**: Download URL fetching now uses parallel requests
  - Tidal: All 8 APIs requested simultaneously, first success wins
  - Qobuz: Both APIs requested simultaneously, first success wins
  - Significantly reduces download URL fetch time

### Fixed

- **Duplicate History Entries**: Fixed duplicate entries when re-downloading same track
  - Detects existing entries by Spotify ID, Deezer ID, or ISRC
  - Replaces existing entry and moves to top of list
  - Auto-deduplicates existing history on app load
- **Extension Search Fallback**: Fixed error when extension is disabled but still called for search
  - Now checks if extension is still enabled before calling custom search
  - Auto-resets search provider to default if extension was disabled
- **Permission Error Message**: Fixed download showing "Song not found" when actually a permission error
  - Now shows proper message: "Cannot write to folder, check storage permission"
  - Added `permission` error type detection in backend
- **Android 13+ Storage Permission**: Fixed storage permission not working on Android 13+
  - Android 13+ now requests both `MANAGE_EXTERNAL_STORAGE` and `READ_MEDIA_AUDIO`
  - `MANAGE_EXTERNAL_STORAGE` opens Settings (system-level, persists across app data clear)
  - `READ_MEDIA_AUDIO` shows dialog (app-level, resets on app data clear)
  - Proper permission check before showing "granted" status

---

## [3.0.0-alpha.2] - 2026-01-12

### Added

- **Full HTTP Method Support**: New shortcut methods for all common HTTP verbs
  - `http.put(url, body, headers)` - PUT requests
  - `http.delete(url, headers)` - DELETE requests
  - `http.patch(url, body, headers)` - PATCH requests
  - `http.clearCookies()` - Clear all cookies for the extension
- **Persistent Cookie Jar**: Each extension now has its own cookie jar
  - Cookies automatically stored from `Set-Cookie` headers
  - Cookies automatically sent with subsequent requests to same domain
  - Useful for APIs requiring session cookies (YouTube, etc.)
- **Multi-Value Header Support**: Response headers now return arrays for multi-value headers
  - `Set-Cookie` and other headers with multiple values returned as arrays
  - Single-value headers still returned as strings for convenience
- **Generic HTTP Request Method**: New `http.request()` for full HTTP control
  - Supports all HTTP methods (GET, POST, PUT, DELETE, PATCH, etc.)
  - Single options object for cleaner API: `http.request(url, { method, body, headers })`
- **Response Helper Properties**: HTTP responses now include convenience properties
  - `response.ok` - true if status code is 2xx
  - `response.status` - alias for `statusCode`

### Fixed

- **User-Agent Header Respect**: Custom `User-Agent` headers are now respected
  - Previously, extension-provided User-Agent was overwritten
  - Now only sets default User-Agent if extension doesn't provide one
- **HTTP POST Body Auto-Stringify**: `http.post()` now automatically stringifies objects to JSON
  - Previously, passing an object as body resulted in `[object Object]`
  - Now objects and arrays are automatically JSON.stringify'd
  - String bodies still work as before (no double-encoding)

### Documentation

- Updated `docs/EXTENSION_DEVELOPMENT.md`:
  - Added complete HTTP API documentation with all methods
  - Added Cookie Jar documentation
  - Added `http.put()`, `http.delete()`, `http.patch()`, `http.clearCookies()` docs
  - Added YouTube Music / Innertube API example with custom User-Agent
  - Added common domain lists for YouTube, SoundCloud, Bandcamp
  - Improved HTTP API documentation with response properties

---

## [3.0.0-alpha.1] - 2026-01-11

#### Extension System

- **Custom Search Providers**: Extensions can now provide custom search functionality
  - YouTube, SoundCloud, and other platforms via extensions
  - Custom search placeholder text per extension
  - Configurable thumbnail aspect ratios (square, wide, portrait)
- **Extension Upgrade System**: Upgrade extensions without losing data
  - Preserves extension settings and cached data during upgrades
  - Version comparison prevents downgrades
  - Auto-detects upgrades when installing same extension
- **Custom Thumbnail Ratios**: Extensions can specify thumbnail display format
  - `"square"` (1:1) - Album art style (default)
  - `"wide"` (16:9) - YouTube/video style
  - `"portrait"` (2:3) - Poster style
  - Custom width/height override available

### Added

- **Track Source Tracking**: Tracks now remember which extension provided them
  - `Track.source` field stores extension ID
  - `TrackState.searchExtensionId` for current search context
  - Enables extension-specific UI customization
- **Extension Upgrade API**: New methods for extension management
  - `upgradeExtension(filePath)` - Upgrade existing extension
  - `checkExtensionUpgrade(filePath)` - Check if file is an upgrade
  - `RemoveExtensionByID` - Remove extension by ID
- **iOS Extension Support**: Added missing iOS method handlers
  - `upgradeExtension` - Upgrade extension from file
  - `checkExtensionUpgrade` - Check upgrade compatibility
- **Extension Documentation**: Comprehensive extension development guide
  - Thumbnail ratio customization documentation
  - Extension upgrade workflow documentation
  - New troubleshooting entries for common issues

### Changed

- **Version Bump**: 2.2.7 → 3.0.0-alpha.1 (major version for extension system)
- **Build Number**: 49 → 50
- **Extension Manager**: Improved upgrade detection in `LoadExtensionFromFile`
  - Auto-detects if installing same extension with higher version
  - Calls `UpgradeExtension` automatically for seamless upgrades

### Fixed

- **Extension `registerExtension`**: Fixed global `extension` variable not being set
  - Extensions can now access their own functions via `extension.functionName()`
  - Required for `customSearch` and other provider functions
- **Custom Search Empty Results**: Fixed error when extension returns null
  - Now returns empty array instead of error
  - Prevents crash when no results found
- **Mutex Crash on Upgrade**: Fixed "Unlock of unlocked RWMutex" crash
  - Removed `defer m.mu.Unlock()` when manual unlock is used
  - Proper lock handling in upgrade flow
- **Duplicate Error Messages**: Fixed extension install errors showing twice
  - Added `clearError()` method to extension provider
  - Improved PlatformException parsing to remove "null, null" artifacts
- **Extension Images Field**: Fixed thumbnails not showing in search results
  - Added `Images` field to `ExtTrackMetadata` struct
  - Renamed `GetCoverURL` to `ResolvedCoverURL` (gomobile conflict)

### Technical

- **Go Backend Changes**:
  - `go_backend/extension_manager.go`: Added `compareVersions()`, `UpgradeExtension()`, `CheckExtensionUpgradeJSON()`
  - `go_backend/extension_providers.go`: Added `Images` field, `ResolvedCoverURL()` method
  - `go_backend/extension_manifest.go`: Added `ThumbnailRatio`, `ThumbnailWidth`, `ThumbnailHeight` to `SearchBehaviorConfig`
  - `go_backend/exports.go`: Added `RemoveExtensionByID`, `UpgradeExtensionFromPath`, `CheckExtensionUpgradeFromPath`
- **Flutter Changes**:
  - `lib/models/track.dart`: Added `source` field
  - `lib/models/track.g.dart`: Updated for `source` field
  - `lib/providers/track_provider.dart`: Added `searchExtensionId`, updated `_parseSearchTrack` with source parameter
  - `lib/providers/extension_provider.dart`: Added `SearchBehavior.getThumbnailSize()`, `clearError()`
  - `lib/screens/home_tab.dart`: Dynamic thumbnail size based on extension config
  - `lib/screens/settings/extensions_page.dart`: Improved error handling
  - `lib/services/platform_bridge.dart`: Added `upgradeExtension()`, `checkExtensionUpgrade()`, `removeExtension()`
- **iOS Changes**:
  - `ios/Runner/AppDelegate.swift`: Added `upgradeExtension`, `checkExtensionUpgrade` handlers
- **Android Changes**:
  - `android/app/src/main/kotlin/com/zarz/spotiflac/MainActivity.kt`: Already had upgrade methods

---

## [2.2.8] - 2026-01-12

### Added

- **Multi-Select Batch Delete**: Long-press tracks in History to enter selection mode
  - Select multiple tracks at once
  - "Select All" and "Delete Selected" actions
  - Modern Material 3 bottom action bar (slides up from bottom)
  - Works in both grid and list view modes
- **History Filter Tabs**: Filter history by All/Albums/Singles
  - Album = tracks where album has >1 track in history
  - Single = tracks where album has only 1 track in history
  - Filter chips show counts for each category
- **Album Grouping View**: When "Albums" filter is selected, tracks are grouped by album
  - Album cards displayed in 2-column grid with cover art and track count badge
  - Tap album to open dedicated album detail screen
  - Album detail shows all downloaded tracks from that album
  - Multi-select delete support within album view
  - Auto-navigates back when album has <2 tracks remaining

### Changed

- **Issue Templates**: Updated version confirmation checkbox to specify "(Stable Version)"

---

## [2.2.7] - 2026-01-11

### Added

- **CSV Import Metadata Enrichment**: Tracks imported from CSV now automatically fetch metadata from Deezer
  - Cover art, duration, track/disc number fetched via ISRC lookup
  - Fallback to text search (artist + track name) when ISRC not found in Deezer
  - Progress dialog shows enrichment status during import
  - Ensures downloaded files have proper cover art and metadata
- **Deezer Metadata Support**: Enhanced metadata viewer for Deezer tracks
  - "Open in Deezer" button for Deezer-sourced tracks (opens app or web)
  - Displays "Deezer ID" instead of "Spotify ID" when applicable
- **Smart Tag Injection**: Filename format editor intelligently handles separators
  - Auto-detects if " - " is needed between tags
  - Prevents double separators or missing spaces
- **Dynamic Source Info**: Search source selector now shows helpful context
  - "No login required" for Deezer
  - "Requires credentials" for Spotify

### Changed

- **UI Modernization**: Major UI consistency updates across the app
  - **Unified App Bars**: Home, History, and Settings now share identical behavior
    - Lowered expanded header for easier one-handed reachability
    - Dynamic title text scaling (20px to 34px)
  - **Appearance Settings**: Completely redesigned appearance page
    - New "Theme Preview" card showing visualizing current theme
    - Modern color palette picker replacing old color dots
    - Clean, grouped layout
    - "AMOLED Dark" switch is now hidden when using Light Mode
  - **App Logo**: Refined logo style on Home and About screens
    - Inverted colors: Filled primary color circle with on-color icon
    - Removed padding for a cleaner, bolder look
  - **Material 3 Switches**: Added checkmark icon to active switches
- **UI Modernization (Global)**: Complete design refresh for a cleaner, modern look
  - **Rounded Corners**: Standardized 16px radius for all cards, buttons, and input fields
  - **Transparent Elements**: Applied subtle transparency to input fields and containers using `surfaceContainerHighest`
  - **Consistent Buttons**: Unified button styling across the app (pill shape, 16px radius)
- **Options Settings Redesign**: improved layout and usability
  - **Search Source Priority**: Moved "Search Source" section to the very top for quick access
  - **Compact Source Selector**: Redesigned provider toggle (Deezer/Spotify) to be compact and consistent
  - **Credentials Workflow**: Reorganized Custom Credentials settings; toggle now auto-prompts if credentials missing
  - **Modern Credentials Dialog**: Totally redesigned input dialog for Spotify Client ID/Secret
- **Filename Format Editor 2.0**:
  - **Modern Sheet UI**: Replaced legacy dialog with a clean, full-width bottom sheet
  - **Tag Chips**: Added clickable chips ({artist}, {title}) for one-tap insertion
  - **Smart Formatting**: Automatically injects separators (" - ") when adding tags for faster editing

### Fixed

- **CSV Import Missing Cover Art**: Fixed tracks from CSV having no cover art in download history
  - Cover URL now properly fetched from Deezer during enrichment
  - Falls back to text search when ISRC lookup fails
- **CSV Import Missing Duration**: Fixed duration showing 0:00 for CSV-imported tracks
  - Duration now fetched from Deezer metadata during enrichment
- **Disc Number Not Displayed**: Fixed disc number not showing in track metadata screen
  - Changed condition from `discNumber > 0` to `discNumber > 0`
  - Now displays disc 1 instead of hiding it
- **Download History Using Wrong Track Data**: Fixed history using original CSV data instead of enriched data
  - Now uses `trackToDownload` (enriched) instead of `item.track` (original)

### Technical

- Updated `lib/services/csv_import_service.dart`:
  - Added `_enrichTracksMetadata()` with ISRC lookup + text search fallback
  - Added progress callback for UI feedback
- Updated `lib/screens/home_tab.dart`:
  - Added progress dialog during CSV enrichment
- Updated `lib/providers/download_queue_provider.dart`:
  - Uses enriched track data for download history
- Updated `lib/screens/track_metadata_screen.dart`:
  - Show disc number when > 0 (was > 1)
- Updated `go_backend/metadata.go`:
  - Added `TotalSamples` to `AudioQuality` struct for duration calculation
- Updated `go_backend/exports.go`:
  - `ReadFileMetadata` now returns duration calculated from FLAC stream info
- Updated `AppTheme` with new `InputDecorationTheme` and `ButtonTheme` definitions
- Refactored `DownloadSettingsPage` to use new `_showFormatEditor` with cursor-aware capabilities
- Optimized various dialogs to use `showModalBottomSheet` with `isScrollControlled` for better keyboard handling

---

## [2.2.6] - 2026-01-11

### Fixed

- **Release Mode Logging**: Flutter app logs now properly captured in release builds
  - Previously only Go backend logs appeared when "Detailed Logging" was enabled
  - Now both Flutter and Go logs are captured in release mode
  - Bypasses Logger package which filters logs in release mode

### Added

- **Detailed Deezer Search Logging**: Better debugging for search issues
  - Logs API URLs, response counts, and errors
  - Helps diagnose geo-restriction and API issues
  - Detects Deezer API error responses

### Changed

- **Home Screen Logo**: Replaced music note icon with app logo
  - Uses `assets/images/logo.png`
  - Rounded corners (24px radius)
  - Fallback to music note icon if logo fails to load
- **About Page Logo**: Removed shadow/border from logo
  - Cleaner appearance without background container
- **About Page Icon Alignment**: Icons now aligned with contributor avatars
  - DoubleDouble and DAB Music icons use 40x40 area
  - Text now properly aligned with contributor items

## [2.2.5] - 2026-01-10

### Added

- **In-App Log Viewer with Go Backend Logs**: Complete logging system for debugging
  - Go backend logs now captured and displayed in app
  - Circular buffer stores up to 500 log entries
  - Real-time polling (500ms) for Go backend logs
  - Logs include timestamp, level, tag, and message
  - "Go" badge indicates logs from backend
- **Detailed Logging Toggle**: Control logging in Settings > Options > Debug
  - Disabled by default for performance
  - Errors are always logged regardless of setting
  - Enable before reproducing bugs for detailed logs
- **Log Issue Summary**: Automatic detection of common issues in logs
  - ISP Blocking detection with affected domains
  - Rate limiting detection
  - Network error detection
  - Track not found detection
  - Shows suggestions for each issue type
- **ISP Blocking Detection**: Detects when ISP blocks download services
  - DNS resolution failure detection
  - Connection reset/refused detection
  - TLS handshake failure detection
  - HTTP 403/451 blocking page detection
  - Suggests VPN or DNS change (1.1.1.1 / 8.8.8.8)

### Fixed

- **Artist Profile Placeholder**: Shows person icon when artist has no profile image
  - Validates image URL before loading
  - Fallback icon on load error
- **Latin Extended Character Detection**: Fixed wrong track downloads for Polish, Czech, French, Spanish songs
  - Characters like Ł, ę, ć, ñ, é now correctly treated as Latin script
  - Previously treated as "different script" causing false matches
  - Affects both Tidal and Qobuz search

### Changed

- **Log Screen UI Improvements**:
  - Copy button moved to app bar (left of menu)
  - Removed redundant info card
  - Cleaner interface
- **Issue Templates Updated**: Instructions for enabling detailed logging before submitting bug reports

### Technical

- New file: `go_backend/logbuffer.go` with circular buffer and GoLog function
- Updated `go_backend/httputil.go` with ISP blocking detection
- Updated `go_backend/tidal.go` and `go_backend/qobuz.go` with `isLatinScript()` function
- Updated `lib/utils/logger.dart` with Go log polling
- Updated `lib/screens/settings/log_screen.dart` with issue summary
- Added method channel handlers for logging in Android and iOS
- New error type: `isp_blocked` for ISP blocking errors

---

## [2.2.0] - 2026-01-10

### Fixed

- **ISRC Metadata Missing:** Fixed an issue where ISRC codes were not being saved to the download history or embedded in file metadata for certain downloads. The backend now correctly propagates the ISRC found from streaming services (Tidal, Qobuz, Amazon) back to the application.
- **Tidal Track/Disc Numbers:** Fixed missing Track Number and Disc Number in Tidal downloads. The downloader now prioritizes the actual metadata returned by Tidal over the potentially incomplete metadata from the initial search request.
- **Concurrent Download Race Condition:** Fixed a potential race condition where temporary cover art files could overwrite each other during rapid concurrent downloads by adding randomization to temporary filenames.
- **Qobuz Search Accuracy:** Reduced the duration tolerance for Qobuz search matches from 30s to 10s to prevent matching with incorrect versions/remixes.
- **Metadata Enrichment Null Safety**: Fixed `type 'Null' is not a subtype of type 'String'` error
  - Added proper null checks when parsing Go backend response
  - Added type checking for track data before parsing
- **Duration Calculation in Enrichment**: Fixed duration conversion bug
  - Go backend returns `duration_ms` (milliseconds)
  - Now properly converts to seconds for Track model

### Changed

- **Default Service Priority:** Updated the default download fallback order to **Tidal → Qobuz → Amazon**.
  - Tidal is now the default download service (was Qobuz)
  - Tidal has faster and more reliable ISRC matching
  - Existing users need to change setting manually or clear app data
- **Metadata Enrichment:** Improved metadata handling for Deezer tracks. If critical metadata (ISRC, Track Number) is missing from the initial search, the app now automatically fetches full details from the Deezer API before finding a source.

### Added

- **ISRC in History:** The Download History now reliably displays the ISRC code for downloaded tracks.
- **Tidal Search Optimization:** Optimized Tidal search logic to immediately check for ISRC matches within search results, improving match speed and accuracy.
  - Returns as soon as ISRC match is found in first query results
  - Significantly faster for tracks with valid ISRC
- **ISRC Enrichment for Search Results**: Tracks from Home search now fetch ISRC before download
  - Search results don't include ISRC (for performance)
  - ISRC is now fetched via metadata enrichment when download starts
  - Ensures accurate track matching on all streaming services
- **Deezer-to-Tidal Fallback:** Added native support for converting Deezer IDs to Tidal links via SongLink when using the fallback mechanism.
- **Better Logging for Qobuz ISRC Search**: Added detailed logs for debugging
  - Shows when ISRC search is attempted
  - Shows number of results and exact ISRC matches found

### Technical

- Updated `go_backend/tidal.go`:
  - Early exit optimization in `SearchTrackByMetadataWithISRC()`
  - Deezer ID support in SongLink lookup
- Updated `go_backend/qobuz.go`:
  - Added logging for ISRC search flow
  - Duration tolerance reduced from 30s to 10s
- Updated `go_backend/exports.go`:
  - Default service order changed to `[tidal, qobuz, amazon]`
- Updated `lib/providers/download_queue_provider.dart`:
  - ISRC-based enrichment condition
  - Null-safe parsing of Go backend response
- Updated `lib/services/platform_bridge.dart`:
  - Null check for `getDeezerMetadata` result
- Updated `lib/models/settings.dart`:
  - Default service changed to `tidal`

---

## [2.1.7] - 2026-01-09

### Added

- **Special Thanks Section**: Added new "Special Thanks" section in About page to credit API creators
  - **uimaxbai** - Creator of QQDL & HiFi API for Tidal downloads
  - **sachinsenal0x64** - Original HiFi project creator, foundation of Tidal integration
  - **DoubleDouble** - Amazing API for Amazon Music downloads
  - **DAB Music** - The best Qobuz streaming API for Hi-Res downloads
- **New Contributor**: Added Amonoman to Contributors section as the app logo creator

### Fixed

- **Missing PlatformBridge Import**: Fixed build errors in `home_tab.dart` and `playlist_screen.dart`
  - Added missing `import 'package:spotiflac_android/services/platform_bridge.dart'`
- **iOS Method Channel Crash**: Fixed "Method not implemented" crash when searching Deezer from iOS
  - Implemented missing `searchDeezerAll` handler in `AppDelegate.swift`
  - Ensures full compatibility with new Deezer integration features on iOS

---

## [2.1.6] - 2026-01-08

### Added

- **Metadata Enrichment**: Automatically fetches full track details if metadata is incomplete (e.g., Track Number 0)
  - Fixes missing Track Number, Disc Number, and Year for tracks added from Search results
  - Ensures accurate tagging for Deezer/Tidal downloads
- **ISRC Index Building**: Fast duplicate checking with cached ISRC index

  - Scans download folder once and builds index of all ISRCs
  - 5 minute cache TTL for optimal performance
  - Parallel duplicate checking for album/playlist tracks
  - Auto-adds new downloads to index (no rebuild needed)

- **Japanese to Romaji Search**: Better search results for Japanese tracks

  - Converts Hiragana/Katakana to Romaji for Tidal/Qobuz search
  - 4 fallback search strategies (like PC version):
    1. Original text (artist + track)
    2. Romaji converted (artist + track)
    3. ASCII-only cleaned version
    4. Artist name only as last resort
  - Handles combination characters (きゃ →kya, シャ →sha, etc.)

- **SongLink Deezer Support**: Query SongLink using Deezer ID as source

  - `CheckAvailabilityFromDeezer()` - find track on other platforms using Deezer ID
  - `CheckAvailabilityByPlatform()` - generic function for any platform
  - `GetSpotifyIDFromDeezer()`, `GetTidalURLFromDeezer()`, `GetAmazonURLFromDeezer()`
  - Useful when starting from Deezer metadata

- **LRC Metadata Headers**: Lyrics now include metadata headers

  - `[ti:Track Name]` - track title
  - `[ar:Artist Name]` - artist name
  - `[by:SpotiFLAC-Mobile]` - generator tag

- **Download Error Types**: Better error categorization for UI

  - `not_found` - track not available on any service
  - `rate_limit` - API rate limit exceeded
  - `network` - connection/timeout errors
  - `unknown` - other errors

- **Amazon Rate Limiting**: Proper rate limiting for Amazon via SongLink
  - 7 second minimum delay between requests
  - Max 9 requests per minute
  - 3x retry with 15s wait on 429 rate limit

### Fixed

- **SongLink 400 Error**: Added validation for empty Spotify ID

  - Specific error messages for 400, 404, 429 status codes
  - Better error handling for invalid track IDs

- **gomobile Compatibility**: Fixed `ISRCIndex.Lookup()` signature
  - Changed from `(string, bool)` to `(string, error)` for gomobile binding

### Technical

- New file: `go_backend/romaji.go` with Japanese to Romaji conversion
- New file: `go_backend/duplicate.go` with ISRC index building
- Updated `go_backend/tidal.go` and `go_backend/qobuz.go` with romaji search strategies
- Updated `go_backend/songlink.go` with Deezer support functions
- Updated `go_backend/exports.go` with new export functions for Flutter
- Updated `go_backend/lyrics.go` with `convertToLRCWithMetadata()`
- Updated `go_backend/progress.go` with `SpeedMBps` field
- Updated `lib/models/download_item.dart` with `DownloadErrorType` enum
- Updated `lib/screens/queue_tab.dart` with speed display and error messages

---

## [2.1.6-preview] - 2026-01-08

### Added

- **Deezer as Alternative Metadata Source**: Choose between Deezer or Spotify for search

  - Configure in Settings > Options > Spotify API > Search Source
  - Default is Deezer for better reliability
  - Spotify URLs are always supported regardless of this setting

- **Automatic Deezer Fallback for Spotify URLs**: When Spotify API is rate limited (429), automatically falls back to Deezer
  - Uses SongLink/Odesli API to convert Spotify track/album ID to Deezer ID
  - Fetches metadata from Deezer instead

### Changed

- **Default Download Service**: Changed from Tidal to Qobuz
  - Fallback order is now: Qobuz → Tidal → Amazon
- **Deezer API Updated to v2.0**: More reliable and complete metadata
  - Direct ISRC lookup via `/track/isrc:{ISRC}` endpoint
  - Search results now fetch full track info to include ISRC

### Fixed

- **Progress Bar Not Updating**: Fixed bug where download progress jumped from 1% directly to 100%
  - Progress now updates smoothly every 64KB of data received
  - First progress update happens immediately when download starts
- **Incomplete Downloads**: Fixed bug where interrupted downloads could result in corrupted/incomplete files
  - File size is validated against server's Content-Length header
  - Incomplete files are automatically deleted and error is reported
  - Applies to all services: Tidal, Qobuz, and Amazon
- **ISRC Not Available from Deezer Search**: Search results now fetch full track details to get ISRC

### Technical

- Settings migration for existing users to set Deezer as default metadata source

---

## [2.1.5] - 2026-01-08

### Added

- **Service Switcher in Quality Picker**: Choose download service (Tidal/Qobuz/Amazon) directly when selecting quality
  - Service selector chips appear above quality options
  - Defaults to your preferred service from settings
  - Change service on-the-fly without going to settings
  - Available in Home, Album, and Playlist screens
- **AMOLED Dark Theme**: Pure black background for OLED screens
  - Toggle in Settings > Appearance > Theme
  - Saves battery on OLED/AMOLED displays
  - All surface colors adjusted for true black background
- **Update Channel Setting**: Choose between Stable and Preview release channels
  - Stable: Only receive stable release notifications
  - Preview: Get notified about preview/beta releases too
  - Configure in Settings > Options > App

### Changed

- **Reduced APK Size**: Replaced FFmpeg plugin with custom AAR containing only required codecs
  - arm64 APK: 46.6 MB (previously 51 MB)
  - arm32 APK: 59 MB (previously 64 MB)
  - Only includes FLAC, MP3 (LAME), and AAC codecs
  - Custom FFmpeg AAR with arm64-v8a and armeabi-v7a only
  - Native MethodChannel bridge for FFmpeg operations
  - Separate iOS build configuration with ffmpeg_kit_flutter plugin

### Fixed

- **Retry Failed Downloads**: Fixed issue where retrying failed downloads sometimes did nothing
  - Now properly handles retry when queue processing has finished
  - Also allows retrying skipped (cancelled) downloads
- **Lyrics Loading Timeout**: Added 20 second timeout for lyrics fetching
  - Shows "Lyrics not available" instead of loading forever
- **iOS Directory Picker**: Fixed unable to select download folder on iOS
  - iOS limitation: Empty folders cannot be selected via document picker
  - Added "App Documents Folder" option as recommended default
  - Files saved to app Documents folder are accessible via iOS Files app

### Performance

- **Download Speed Optimizations**: Significant improvements to download initialization and throughput
  - Token caching for Tidal (eliminates redundant auth requests)
  - Singleton pattern for all downloaders (HTTP connection reuse)
  - ISRC search first strategy (faster than SongLink API)
  - Track ID cache with 30 minute TTL for album/playlist downloads
  - Pre-warm cache when viewing album/playlist
  - Parallel cover art and lyrics fetching during audio download
  - 64KB HTTP read/write buffers
  - 256KB buffered file writer for all downloaders
  - Progress updates every 64KB (reduced lock contention)
- **Amazon Music Optimizations**: Same optimizations now applied to Amazon downloader

## [2.1.0-preview2] - 2026-01-06

### Added

- **Service Switcher in Quality Picker**: Choose download service (Tidal/Qobuz/Amazon) directly when selecting quality
  - Service selector chips appear above quality options
  - Defaults to your preferred service from settings
  - Change service on-the-fly without going to settings
  - Available in Home, Album, and Playlist screens
- **AMOLED Dark Theme**: Pure black background for OLED screens
  - Toggle in Settings > Appearance > Theme
  - Saves battery on OLED/AMOLED displays
  - All surface colors adjusted for true black background
- **Update Channel Setting**: Choose between Stable and Preview release channels
  - Stable: Only receive stable release notifications
  - Preview: Get notified about preview/beta releases too
  - Configure in Settings > Options > App

### Fixed

- **Retry Failed Downloads**: Fixed issue where retrying failed downloads sometimes did nothing
  - Now properly handles retry when queue processing has finished
  - Also allows retrying skipped (cancelled) downloads
  - Added logging for better debugging
- **Lyrics Loading Timeout**: Added 20 second timeout for lyrics fetching
  - Shows "Lyrics not available" instead of loading forever
  - Better error messages for timeout and not found cases

## [2.1.0-preview] - 2026-01-06

### Performance

- **Download Speed Optimizations**: Significant improvements to download initialization and throughput
  - Token caching for Tidal (eliminates redundant auth requests)
  - Singleton pattern for all downloaders (HTTP connection reuse)
  - ISRC search first strategy (faster than SongLink API)
  - Track ID cache with 30 minute TTL for album/playlist downloads
  - Pre-warm cache when viewing album/playlist
  - Parallel cover art and lyrics fetching during audio download
  - 64KB HTTP read/write buffers
  - 256KB buffered file writer for all downloaders
  - Progress updates every 64KB (reduced lock contention)
- **Amazon Music Optimizations**: Same optimizations now applied to Amazon downloader

### Technical

- New `go_backend/parallel.go` with `TrackIDCache`, `FetchCoverAndLyricsParallel()`, `PreWarmTrackCache()`
- Flutter: `_preWarmCacheForTracks()` in `track_provider.dart`
- New method channels: `preWarmTrackCache`, `getTrackCacheSize`, `clearTrackCache`

## [2.0.7-preview2] - 2026-01-06

### Fixed

- **iOS Directory Picker**: Fixed unable to select download folder on iOS
  - iOS limitation: Empty folders cannot be selected via document picker
  - Added "App Documents Folder" option as recommended default
  - Shows info message explaining iOS limitation
  - Files saved to app Documents folder are accessible via iOS Files app

## [2.0.7-preview] - 2026-01-05

### Changed

- **Reduced APK Size**: Replaced FFmpeg plugin with custom AAR containing only required codecs
  - arm64 APK: 46.6 MB (previously 51 MB)
  - arm32 APK: 59 MB (previously 64 MB)
  - Only includes FLAC, MP3 (LAME), and AAC codecs
  - Removed x86/x86_64 architectures (emulator only)

### Technical

- Custom FFmpeg AAR with arm64-v8a and armeabi-v7a only
- Native MethodChannel bridge for FFmpeg operations
- Separate iOS build configuration with ffmpeg_kit_flutter plugin

## [2.0.6] - 2026-01-05

### Fixed

- **Duration Display Bug**: Fixed duration showing incorrect values like "4135:53" instead of "4:14"
  - `duration_ms` (milliseconds) was being stored directly without conversion to seconds
  - Now properly converts milliseconds to seconds before display
- **Audio Quality from File**: Quality info (bit depth/sample rate) now read from actual FLAC file instead of trusting API
  - More accurate quality display for all services (Tidal, Qobuz, Amazon)
  - Also reads quality from existing files when skipping duplicates
- **Artist Verification for Downloads**: Added artist name verification to prevent downloading wrong tracks
  - Verifies artist matches between Spotify metadata and streaming service
  - Handles different scripts (Japanese/Chinese vs Latin) as same artist with different transliteration
  - Applied to Tidal, Qobuz, and Amazon downloads
- **Metadata Case-Sensitivity**: Fixed FLAC metadata not being properly overwritten when downloaded file has lowercase tags
  - Now uses case-insensitive comparison when replacing existing Vorbis comments
  - Fixes issue where Amazon downloads could have duplicate metadata tags
- **Settings Navigation Freeze**: Fixed app freezing when navigating back from settings sub-menus on some devices
  - Added proper PopScope handling for predictive back gesture on Android 14+

## [2.0.5] - 2026-01-05

### Added

- **Large Playlist Support**: Playlists with up to 1000 tracks are now fully fetched (was limited to 100)

### Fixed

- **Wrong Track Download**: Fixed issue where tracks with same ISRC but different versions (e.g., short/instrumental vs full version) would download the wrong track. Now verifies duration matches before downloading (30 second tolerance).

## [2.0.4] - 2026-01-04

### Fixed

- **Android 11 Storage Permission**: Fixed "Permission denied" error on Android 11 (API 30) devices
  - Added `MANAGE_EXTERNAL_STORAGE` permission for Android 11-12
  - Shows explanation dialog before opening system settings

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
