# Changelog

## [3.6.8] - 2026-02-14

### Added

- **Lyrics Source Tracking**: Track Metadata screen now displays the source of loaded lyrics (LRCLIB, Musixmatch, Netease, Apple Music, QQ Music, Embedded, or Extension)
  - New `getLyricsLRCWithSource` API returns lyrics with source metadata
  - Source badge appears below lyrics section in Track Metadata screen
- **Dedicated Lyrics Provider Priority Page**: Lyrics providers can now be configured from a dedicated settings page with full-screen reorderable list
  - Replaced inline bottom sheet with `LyricsProviderPriorityPage`
  - Cleaner UI with provider descriptions and priority ordering
- **Paxsenix Integration**: Added Paxsenix API as official lyrics proxy partner for Apple Music, QQ Music, Musixmatch, and Netease sources
  - Listed in About page and Partners page on project site
  - README updated with partner attribution

### Fixed

- **LRC Background Vocal Preservation**: Apple Music/QQ Music `[bg:...]` background vocal tags are now preserved during LRC parsing instead of being stripped
  - Background vocals attach to the previous timed line in exported LRC files
- **LRC Display Improvements**:
  - Inline word-by-word timestamps (`<mm:ss.xx>`) are stripped from lyrics display
  - Speaker prefixes (`v1:`, `v2:`) are removed for cleaner display
  - Multi-line background vocals converted to readable secondary vocal lines
- **Apple Music Lyrics Case Sensitivity**: Fixed `lyricsType` comparison to use case-insensitive matching for "Syllable" type

### Changed

- Track Metadata lyrics fetching now uses `getLyricsLRCWithSource` for consistent source attribution across embedded and online lyrics

---

## [3.6.7] - 2026-02-13

### Added

- "Advanced Filename Templates" - new placeholders for custom track/disc formatting and date patterns
  - `{track_raw}` and `{disc_raw}` - unpadded raw numbers
  - `{track:N}` and `{disc:N}` - zero-padded to N digits (e.g. `{track:02}` → `01`)
  - `{date}` - full release date from metadata
  - `{date:%Y-%m-%d}` - date formatting with strftime patterns
  - "Show advanced tags" toggle in Settings > Download > Filename Format to reveal these placeholders
- Low-RAM / ARM32-only device profiling - detects constrained devices at startup and reduces image cache (120 items / 24 MiB) and disables overscroll effects for smoother performance
- Responsive selection bar on artist screen - switches to compact stacked layout on narrow screens (< 430dp) or large text scale (> 1.15x)
- Quality picker dialog before downloading individual tracks from artist screen (when "Ask quality before download" is enabled)
- Project website with GitHub Pages deployment workflow
  - Mobile burger menu navigation for all site pages
- Go filename template test suite
- "Lyrics Provider" extension type - extensions can now provide lyrics (synced or plain text) via `fetchLyrics()` function
  - Lyrics provider extensions are called before built-in providers, giving extensions highest priority
  - New `lyrics_provider` manifest type alongside `metadata_provider` and `download_provider`
  - Shows "Lyrics Provider" capability badge on extension detail page
- "Lyrics Providers" settings - configurable provider cascade order and per-provider options
  - Reorderable provider list: LRCLIB, Musixmatch, Netease, Apple Music, QQ Music
  - Netease: toggle translated/romanized lyrics appending
  - Apple Music / QQ Music: multi-person word-by-word speaker tags
  - Musixmatch: selectable language code for localized lyrics
- "Documentation Search" - global search modal on all site pages
  - Opens with Ctrl+K / Cmd+K / `/` keyboard shortcuts on every page
  - Search button with bordered pill styling in desktop nav and mobile hamburger menu
  - On non-docs pages, search results navigate to the docs page at the matching section
  - Full keyboard navigation: arrow keys, Enter to select, Esc to close

### Fixed

- Fixed ICU plural syntax errors in DE, ES, PT, RU translations - incorrect `=1` clause was causing missing plural forms
- Fixed featured-artist regex incorrectly splitting on `&` character (e.g. "Simon & Garfunkel" was being split) - removed `&` from separator pattern
- Fixed `{date}` placeholder not working in filename templates - release date was not being passed to the template builder across all providers (Amazon, Qobuz, Tidal, YouTube, extensions)

### Changed

- Improved Go backend metadata handling - filename builder now supports fallback metadata keys and automatic type conversion for more robust template rendering
- Extension providers now pass full metadata set to filename builder (track, disc, year, date, release_date)
- Updated translations: added filename advanced tags strings (EN, ID), regenerated all locale dart files
- Updated app screenshot assets

---

## [3.6.6] - 2026-02-12

### Added

- "Filter Contributing Artists in Album Artist" setting - strips featured/contributing artists from Album Artist metadata tag
- Library scan notifications (Android and iOS) - shows progress, completion, failure, and cancellation status
- Collapsible "Artist Name Filters" section in download settings UI

### Fixed

- Fixed downloads not working on iOS - missing `downloadByStrategy` and `downloadFromYouTube` method channel handlers in AppDelegate.swift
- Fixed extended metadata (genre, label, copyright) lost during service fallback (e.g. Tidal unavailable, falls back to Qobuz) - Go backend now enriches metadata from Deezer by ISRC before download and preserves it through the fallback chain
- Fixed local library showing incorrect "16-bit" quality label for lossy formats (MP3, Opus) - now displays actual bitrate (e.g. "MP3 320kbps")
- Fixed inaccurate Opus/Vorbis duration calculation (e.g. 4:11 showing as 8:44) - now reads granule position from last Ogg page for precise duration
- Fixed MP3 duration/bitrate inaccuracy for VBR files - added Xing/Info and VBRI header parsing with MPEG2/2.5 bitrate table support
- Fixed Track Metadata screen showing scan date instead of file date for local library items
- Fixed SAF content URI paths displayed as raw `content://` strings in Track Metadata - now shows human-readable paths

### Changed

- Removed legacy iOS download handlers (`downloadTrack`, `downloadWithFallback`, `downloadFromYouTube`) - iOS now uses `downloadByStrategy` only
- Updated translations from Crowdin (all 14 languages)

---

## [3.6.5] - 2026-02-10

### Highlights

- **Audio Format Conversion**: Convert between FLAC, MP3, and Opus directly from Track Metadata screen with full metadata and cover art preservation
- **PC v7.0.8 Backend Merge**: Adopts several Go backend improvements from SpotiFLAC PC v7.0.8 including Amazon encrypted stream support, SpotFetch metadata fallback, and Qobuz API update
- **Amazon Music Re-enabled**: Amazon provider back in service with new API

### Added

- "Use Primary Artist Only" setting: strips featured artists from folder names (e.g. "Justin Bieber, Quavo" becomes "Justin Bieber") for cleaner folder organization
  - Supports separators: `, ` `;` `&` `feat.` `ft.` `featuring` `with` `x`
  - Available in Settings > Download > below "Use Album Artist for folders"
- Audio format conversion from Track Metadata screen
  - Convert between FLAC, MP3, and Opus formats (any direction)
  - Selectable bitrate: 128k, 192k, 256k, 320k
  - Full metadata and cover art preservation during conversion
  - Confirmation dialog before converting (original file deleted after)
  - SAF storage support: copies to temp, converts, writes back via SAF
  - Download history automatically updated with new file path
- Unified download request contract (`DownloadRequestPayload`) for all providers/flows
  - Includes full superset fields: lyrics mode, genre/label/copyright, provider IDs, SAF params, cover/quality settings
  - Added strategy flags in payload: `use_extensions`, `use_fallback`
- New Go unified router entrypoint: `DownloadByStrategy(requestJSON)`
  - Routing priority: YouTube service -> extension fallback -> built-in fallback -> direct service
- New Android method channel handler: `"downloadByStrategy"` -> `Gobackend.downloadByStrategy(...)`
- SpotFetch metadata fallback integration for Spotify-blocked regions
  - New backend client for `spotify.afkarxyz.fun/api`
  - Automatic fallback in Spotify metadata fetch path when primary source fails
- Lyrics extraction now supports MP3 (ID3v2) and Opus/OGG (Vorbis comments) in addition to FLAC
  - Includes heuristic detection of lyrics stored in Comment fields
- Edit Metadata now supports manual cover selection (pick/replace cover image) and embeds it into audio tags on save
- Save Lyrics now shows an immediate in-progress snackbar (`Saving lyrics...`) so users know the operation has started

### Changed

- Merged several Go backend improvements from SpotiFLAC PC v7.0.8: Amazon new API with encrypted stream/decryption support, SpotFetch metadata fallback for Spotify-blocked regions, multi-format lyrics extraction (MP3/Opus/OGG), Qobuz Jumo API update.
- Download queue execution now builds one payload and uses a single bridge entrypoint (`PlatformBridge.downloadByStrategy`) instead of branching into multiple bridge methods
- Dart `downloadByStrategy` now sends a single request to Go (`downloadByStrategy` channel); routing concern is centralized in Go backend
- Legacy Dart bridge methods (`downloadTrack`, `downloadWithFallback`, `downloadWithExtensions`, `downloadFromYouTube`) are now thin wrappers and marked `@Deprecated`
- Qobuz downloader updated to latest Jumo API contract (`/get` endpoint, required headers)
- Amazon download flow now returns `decryption_key` from Go and performs decryption in Flutter (local file + SAF paths)
- Amazon now uses the new `amazon.afkarxyz.fun` API flow (ASIN-based track endpoint + legacy fallback) with encrypted stream support
- Amazon ASIN extraction rewritten with robust URL/query-param parsing and regex fallback
- Amazon provider re-enabled in download service picker and download settings (alongside Tidal, Qobuz, and YouTube picker flow)
- Track Metadata cover UI now refreshes from the embedded file after Edit Metadata/Re-enrich, so the displayed art matches actual file tags
- Edit Metadata cover section moved to the top of the form and now previews current embedded cover before replacement (plus selected replacement preview)
- Edit Metadata cover preview enlarged (120px to 160px) with shadow, side-by-side layout for current vs selected cover, and label repositioned below image

### Fixed

- Fixed lyrics mode "External .LRC" still embedding lyrics into metadata - `lyrics_mode` was not being sent to Go backend for single-service downloads and YouTube provider, causing Go to default to "embed"
- Fixed `flutter_local_notifications` v20 breaking changes - migrated all `initialize()`, `show()`, and `cancel()` calls from positional parameters to named parameters
- Fixed SAF duplicate folder bug: concurrent batch downloads creating empty folders with `(1)`, `(2)`, `(3)` suffixes - added synchronized lock to `ensureDocumentDir` in Kotlin with duplicate detection and cleanup
- Track Metadata lyrics section now hides "Embed Lyrics" when lyrics are already embedded in file, preventing redundant embed attempts
- Fixed lyrics embed path to support FLAC/MP3/Opus consistently (including SAF files) without forcing unsupported parser paths
- Inconsistent parameter parity across download paths
  - `downloadWithExtensions` now carries `copyright`
  - YouTube path now carries `embed_max_quality_cover` and metadata parity fields
- Inconsistent success response metadata between direct/fallback flows
  - Added shared Go response builder for `DownloadTrack` and `DownloadWithFallback`
  - Success responses now consistently include `genre`, `label`, `copyright`, and `lyrics_lrc`
- YouTube success response now also includes extended metadata fields (`cover_url`, `genre`, `label`, `copyright`) for parity with other providers
- Fixed `Save Lyrics` crash on Android (`java.lang.Integer cannot be cast to java.lang.Long`) by normalizing `duration_ms` channel argument as `Number -> Long`
- Fixed FLAC Re-enrich cover edge case where metadata could be written without cover when temp cover file creation failed; FLAC cover embed now uses in-memory bytes and verifies cover after write
- Fixed FLAC picture-block embed robustness by detecting image MIME via magic bytes (JPEG/PNG/GIF/WEBP) instead of relying on filename extension
- Fixed MP3/Opus metadata rewrite flows to preserve existing embedded cover when no new cover is available
- Fixed Library tab cover not updating after manual cover edit/re-embed for downloaded tracks
  - Queue/Library now prefers embedded cover art extracted from local files (not just cached `coverUrl`)
  - Added per-track extraction cache with file-modification invalidation so updated embedded art is reflected in Library
  - Extraction is now on-demand for edited tracks only (not full-library reload)
  - Returning from Track Metadata now refreshes cover cache only for the affected track
  - Cover refresh is now skipped when file modification time is unchanged, removing unnecessary flash when simply opening/closing metadata screen
- Fixed repeated cover preview extraction in Track Metadata screen (`track_cover_preview_*`) causing visible flash when reopening
  - Added in-memory preview cache keyed by file path so reopening metadata reuses existing preview without re-extract
  - Cache validation uses file modification time for filesystem paths; SAF paths are refreshed only after successful edit actions
  - Queue/Library now also compares SAF file last-modified (`getSafFileModTimes`) before refreshing embedded-cover cache
  - Preview cache key is now stable per track item (not volatile temp SAF path), eliminating false cache misses on SAF-backed files
  - Track Metadata no longer auto-extracts cover preview on every screen open; extraction now runs only after actual edit/re-enrich changes (or when explicitly forced)
- Track metadata edits/re-enrich now sync updated tags back into `downloadHistoryProvider` + SQLite history rows
  - Non-Library screens that read download history (Home/album/history views) now reflect updated title/artist/album/tags without manual rescan
  - Track Metadata back-navigation now returns an explicit update result after successful edits/re-enrich, enabling History-tab cover refresh fallback when SAF timestamps are unreliable

### Performance

- Configured Flutter image cache limits (240 entries / 60 MiB) and added `ResizeImage` wrappers for cover art precaching across all screens, reducing peak memory usage on cover-heavy pages
- Added LRU eviction to Deezer cache with configurable max entries per cache type (search/album/artist/ISRC) and periodic expired-entry cleanup to prevent unbounded memory growth in long sessions
- Download progress notifications are now normalized (2-decimal progress, 1-decimal speed, 0.1 MiB byte steps) and deduplicated by track/artist/percent/queue-count, reducing notification overhead during batch downloads
- Each queue item now uses a dedicated `ConsumerWidget` with per-item `.select()` instead of rebuilding the entire list on any item change; items are wrapped in `RepaintBoundary` for paint isolation
- Queue/Library search indexes are now built on-demand per item instead of upfront for all items, with bounded LRU caches (max 4000 entries)
- `copyWith` now preserves derived lookup indexes (ISRC map, track key set) when items list is unchanged, avoiding O(n) rebuild on every scan progress update
- Scan progress polling now compares values before calling `setState`, skipping unnecessary widget rebuilds when nothing changed
- Added in-flight flag to download progress and library scan polling to prevent concurrent timer callbacks from overlapping
- New `DownloadedEmbeddedCoverResolver` service replaces per-screen cover extraction logic with a shared bounded cache (160 entries), mod-time validation, and throttled refresh checks
- Multiple embedded cover change callbacks are now coalesced into a single frame via `addPostFrameCallback`, preventing redundant rebuilds
- Downloaded album screen now caches filtered/sorted track lists and reuses them when the source data reference is unchanged
- Home tab recent downloads now use single-pass aggregation instead of building full per-album lists, and store only IDs instead of full item objects for the clear-all action
- Removed duplicate `_downloadedSpotifyIds` Set and `_isrcSet` (both now use existing map lookups), removed unused `_isTyping` state in home tab
- Track cache pre-warming is now capped at 80 tracks per request to avoid excessive backend calls on large playlists
- About page contributor avatars now use `memCacheWidth`/`memCacheHeight` to decode at display size instead of full resolution
- Orphaned download cleanup now checks file existence in parallel (chunk 16) instead of sequentially
- Local library `findByTrackAndArtist` now uses O(1) map lookup (`_byTrackKey`) instead of O(n) linear scan
- Local library database load and SharedPreferences fetch now run in parallel
- Legacy mod-time backfill now uses chunked parallel `File.stat` (chunk 24) with per-chunk cancel check
- Downloaded album screen now caches disc grouping, sorted disc numbers, common quality, and embedded cover path with reference-identity invalidation
- Local album screen common quality is now computed once during cache rebuild instead of per-build
- Batch delete in album screens now uses O(1) map lookup (`tracksById`) instead of `.where().firstOrNull`
- Cache management page now fires all async init calls in parallel and uses chunked async directory deletion (chunk 24)
- Cover resolver preview file existence check is now throttled (2.2s interval) to reduce synchronous I/O in build path
- History and library database DELETE operations are now chunked (500 per batch) to stay within SQLite variable limits
- Library database `cleanupMissingFiles` now checks file existence in parallel (chunk 16) and deletes in batched SQL

### Security

- All logs (Go and Dart) now automatically redact Bearer tokens, access/refresh tokens, client secrets, API keys, and passwords using regex-based sanitization before storage
- Extension auth URLs are now validated for HTTPS-only, no embedded credentials, and no private/local network targets before opening
- Auth URLs in logs are summarized to scheme+host+path only (query params stripped) to prevent token leakage; token exchange error bodies are truncated and sanitized
- Extension HTTP requests now block URLs with embedded credentials (`user:pass@host`)
- Extension storage files changed from `0644` to `0600` (owner-only read/write)
- All SAF relative directory paths are now sanitized per-segment with `.`/`..` filtering; all user-provided file names pass through `sanitizeFilename()` before use
- Extension ID is sanitized before building download destination path
- Log export device info now shows Build ID and Security Patch level instead of masked Device ID

### Technical

- Centralized request serialization in `PlatformBridge` via shared invoke helper and unified payload model
- Go strategy router normalizes incoming service casing before dispatch
- Extension runtime: `customSearch` now passes query/options via VM globals instead of string interpolation, preventing parser edge cases on certain devices
- Extension runtime: JS panic handler now logs full stack trace for easier debugging
- `DownloadQueueLookup` expanded with `byItemId` map and `itemIds` list for O(1) queue item access from UI
- Non-error/non-fatal log entries are now skipped entirely (not just hidden) when detailed logging is disabled, reducing buffer growth and Go log polling overhead

### Removed

- Buy Me a Coffee references removed from donate page, FUNDING.yml, README, and all localization files (account suspended)

---

## [3.6.0] - 2026-02-09

### Highlights

- **YouTube Provider (Lossy)**: New download option via Cobalt API for tracks not available on lossless services
  - Opus 256kbps (recommended) or MP3 320kbps quality options
  - Full metadata embedding: cover art, title, artist, album, track/disc number, year, ISRC
  - Lyrics fetching from lrclib.net with embed and external .lrc support
  - Works as fallback when Tidal/Qobuz/Amazon downloads fail
- **Edit Metadata**: Edit embedded metadata directly from the Track Metadata screen (FLAC, MP3, Opus)
  - Editable fields: Title, Artist, Album, Album Artist, Date, Track#, Disc#, Genre, ISRC
  - Advanced fields: Label, Copyright, Composer, Comment
  - FLAC: native Go writer, MP3/Opus: FFmpeg-based writer
  - UI refreshes in-place after save without needing to re-open the screen
  - iOS and Android support

### Added

- Save Cover Art: download high-quality album art as standalone .jpg from track metadata screen
- Save Lyrics (.lrc): fetch and save lyrics as standalone .lrc file without downloading the song
- Re-enrich Metadata: re-embed metadata, cover art, and lyrics into existing audio files without re-downloading (FLAC native, MP3/Opus via FFmpeg)
- Re-enrich now supports local library items: searches Spotify/Deezer by track name + artist to fetch complete metadata from the internet, then embeds cover art, lyrics, genre, label, and all tags into the file
- YouTube download provider using Cobalt API with SongLink/Odesli integration for Spotify/Deezer ID → YouTube URL conversion
- SpotubeDL as fallback Cobalt proxy when primary API fails
- YouTube video ID detection for YT Music extension compatibility
- Parallel cover art and lyrics fetching during YouTube download
- Queue progress now shows "X.X MB" instead of "0%" for streaming downloads where total size is unknown (Cobalt tunnel mode)
- Full metadata pipeline for YouTube downloads: cover art, lyrics, title, artist, album, track#, disc#, year, ISRC

### Changed

- Removed Tidal HIGH (lossy AAC) quality option - use YouTube provider for lossy downloads instead
- Simplified download service picker by removing dead lossy format code
- Removed Amazon from download settings UI (now only used as automatic fallback)
- Cleaned up dead disabled-chip code in download service selector

### Fixed

- Fixed `error.api.youtube.login` by using YouTube Music URLs instead of regular YouTube URLs for Cobalt requests
- Fixed SongLink to prioritize `youtubeMusic` platform URL over `youtube` for Cobalt compatibility
- Fixed YouTube metadata not being overwritten by setting `DisableMetadata: true` in Cobalt requests
- Fixed ISRC validation in metadata enrichment flow - invalid ISRCs no longer trigger failed Deezer lookups
- Fixed YouTube metadata enrichment to work like other providers (SongLink Deezer ID extraction, proper metadata embedding)
- Go metadata parsers now read Composer, Comment, Label, Copyright from FLAC, MP3 (ID3v2.2/v2.3/v2.4), and Opus/OGG files
- Added proper COMM frame parser for ID3v2 (handles language code + description prefix correctly)
- Fixed Re-enrich Metadata failing on SAF storage files (`content://` URIs) - Kotlin now copies SAF file to temp, Go processes temp file, then writes back for FLAC or returns temp path for FFmpeg (MP3/Opus)
- Fixed Save Cover Art and Save Lyrics crashing on SAF-stored download history items - now saves to temp then writes to SAF tree via `createSafFileFromPath`
- Fixed `_getFileDirectory()` crash when called with `content://` URI by adding SAF guard
- Fixed `readAudioMetadata` Kotlin handler not handling SAF URIs - now copies to temp for reading
- Added metadata summary log in Re-enrich flow showing all fields before embedding (title, artist, album, track#, disc#, date, ISRC, genre, label)

---

## [3.5.3] - 2026-02-09

### Added

- CSV import flow now includes a new option: **Skip already downloaded songs** before enqueueing tracks
- Added regression test suite for cross-script matching behavior in Go backend (`go_backend/matching_test.go`)

### Changed

- CSV import confirmation dialog now supports filtering out tracks already present in download history (matched by Spotify ID and ISRC)
- CSV import enqueue feedback now reports added/skipped counts when duplicate downloads are skipped
- Home search now prioritizes **Recent Access** when search field is focused with empty input, even if old search results still exist in memory
- Search filter/result sections are now hidden while Recent Access mode is active to avoid stale-result overlap
- Recent Access now shows a localized empty-state message when no recent items are available
- Normalized collapsing AppBar top inset across iOS/Android so header height/animation stays visually consistent on Apple devices
- Storage & Cache UX improved: `Clear all cache` now preserves web/runtime cache by default (optional), with explicit warnings/actions for runtime cache resets
- Local library settings now include a display count for tracks excluded because they already exist in download history
- Responsive layout tuning applied across key screens to reduce hardcoded-height overflow issues on smaller devices

### Fixed

- Fixed false-positive cross-script matching in Qobuz/Tidal where unrelated titles/artists in different scripts could be incorrectly accepted
- Cross-script title/artist matching now requires transliteration-aware normalization and strict similarity checks instead of auto-accepting script differences
- Qobuz metadata fallback no longer scans all results when zero title matches are found; title verification is now required
- Qobuz metadata final validation now rejects results when title does not match expected track name
- Fixed Home search regression where Recent Access panel could disappear after previous searches
- Fixed Local Library card/layout crash caused by `Flex` usage under unbounded height constraints
- Hardened FFmpeg metadata embedding temp-file naming to prevent rare collisions during parallel downloads/fallback flows (Qobuz → Tidal) that could cause missing embedded metadata
- Fixed SAF external lyrics naming where some providers saved `.lrc` files as `.lrc.txt`; LRC export now uses neutral MIME to preserve `.lrc` extension

## [3.5.2] - 2026-02-08

### Performance

- Home tab search result sections are now virtualized with `SliverList` (lazy item build) instead of eager `Column` rendering, reducing frame drops on large result sets
- Home tab now narrows Riverpod subscriptions using field-level `select(...)` for search/provider state to reduce unnecessary full-tab rebuilds
- Search provider dropdown now watches only required fields (`searchProvider`, `metadataSource`, `extensions`) instead of full provider states
- Track row rendering in Home search now receives precomputed thumbnail sizing/local-library flags from parent to avoid repeated per-item provider watches
- Removed thumbnail `debugPrint` calls inside track row `build()` to reduce runtime overhead during scrolling/rebuilds
- Queue tab root subscription no longer watches full queue item list; it now watches only queue presence (`items.isNotEmpty`) to avoid full Library UI rebuilds on every progress tick
- Queue download header/list rendering has been isolated into dedicated `Consumer` slivers; header now watches only queue length (`items.length`) while item list watches queue item updates
- Queue filter/sort computations are now centralized and memoized per filter mode within a build pass (`all`/`albums`/`singles`), reducing repeated list transforms for chip counts and page content
- Selection bottom bar content is now computed only when selection mode is active, removing hidden-state heavy list preparation
- File existence checks in queue/library rows now use per-path `ValueNotifier` + `ValueListenableBuilder` updates instead of triggering global `setState`, reducing unnecessary whole-tab repaints

### Changed

- Replaced date range filter with sorting options in Library tab: Latest, Oldest, A-Z, Z-A
- Sorting applies to all views: unified items, downloaded albums, and local library albums
- Local library items now use file modification time (`fileModTime`) for sorting instead of scan time, providing more accurate chronological ordering
- Removed redundant manual "Export Failed Downloads" button from Library UI (auto-export setting in Settings is sufficient)
- Library filters (quality, format, source) now correctly apply to album tabs and update tab chip counts (All/Albums/Singles)

### Fixed

- Fixed local library scan crashing on Samsung One UI devices due to MediaStore URI mismatch in SAF tree traversal
- Added MediaStore URI fallback in SAF file reader: when SAF permission is denied for Samsung-returned MediaStore URIs, automatically retries using READ_MEDIA_AUDIO permission
- Hardened SAF scan with per-directory and per-file error handling: scan now skips problematic files instead of aborting entirely
- Added visited directory tracking to prevent infinite loops from circular SAF references
- Fixed metadata enrichment cascading failure after one queued download fails: metadata APIs (Deezer, SongLink, Spotify) now use isolated `metadataTransport` so failed download connections cannot poison metadata requests
- Added immediate connection cleanup on every download failure path (error response and exception), not only periodic cleanup every N downloads
- Fixed incremental SAF scan edge case where `lastModified()` failure could misclassify existing files as removed (`removedUris`)
- Fixed tracks marked "In Library" still showing active download button - download button now shows as completed (checkmark) for local library tracks across all screens (album, playlist, artist, home/search)
- Fixed FFmpeg M4A-to-FLAC conversion erroneously triggered on already-existing FLAC files when re-downloading duplicates via Tidal
- Fixed SAF download creating empty artist/album folders when re-downloading duplicate tracks; directory is now only created after confirming the file does not already exist

## [3.5.1] - 2026-02-08

### Performance

- Removed PaletteService (palette_generator) from all screens for faster navigation and reduced memory usage
- Album, Playlist, Downloaded Album, Local Album, and Track Metadata screens now use blurred cover art as header background instead of dominant color extraction
- Removed `palette_generator` dependency
- App startup now renders immediately (`runApp`) while service initialization runs asynchronously in eager init
- Main shell provider subscriptions now use field-level `select(...)` to reduce unnecessary rebuilds
- Settings persistence now uses single-flight + queued save coalescing to avoid redundant disk writes
- Progress polling cadence adjusted to 800ms for download queue, local library scan progress, and Go log polling
- Android foreground download service progress updates are throttled (change-based updates + 5s heartbeat)
- SAF history repair is now batched (`20` items per batch) and capped per launch (`60`) to reduce startup I/O spikes
- Incremental library scan now builds final item list in-memory instead of reloading from database
- Local cover images in queue/library use direct `Image.file` with `errorBuilder` instead of `FutureBuilder` existence check
- CSV parser `_parseLine` rewritten: correct escaped-quote handling, no quote characters in output
- Removed unused legacy screen files (`home_screen.dart`, `queue_screen.dart`, `settings_screen.dart`, `settings_tab.dart`)
- Incremental local library scan now merges delta results in-memory and sorts once, avoiding full-state reload churn
- Queue local cover rendering now uses direct `Image.file` + `errorBuilder` (removed repeated async file-exists checks)

### Added

- Auto-cleanup orphaned downloads on history load (files that no longer exist are automatically removed from history)

### Changed

- Removed legacy screen files that were no longer used after the tab/part refactor:
  - `lib/screens/home_screen.dart`
  - `lib/screens/queue_screen.dart`
  - `lib/screens/settings_screen.dart`
  - `lib/screens/settings_tab.dart`
- Concurrent download limit increased from `3` to `5` (settings clamp + Options UI chips now support `1..5`)
- Download queue now uses a single parallel scheduler path; `1` concurrency is handled as parallel-with-limit-1 (no separate sequential engine)
- Download queue now listens to settings updates in real-time so concurrency/output settings stay in sync while queue is active

### Fixed

- CSV parser now correctly handles escaped quotes (`""`) inside quoted fields during import
- Fixed dynamic concurrency update during active downloads: changing limit (e.g. `1 -> 3`) now schedules additional queued items without waiting current active item to finish
- Queue scheduler now re-checks capacity/queued items on short intervals to avoid blocking on long-running single active download

### Dependencies

#### Flutter
- `flutter_local_notifications` 19.x → 20.0.0 (breaking: all positional params converted to named params)
- `connectivity_plus` 6.x → 7.0.0
- `flutter_secure_storage` 9.x → 10.0.0
- Removed `palette_generator` dependency

#### Go
- `go-flac/go-flac` v1.0.0 → v2.0.4
- `go-flac/flacvorbis` v0.2.0 → v2.0.2
- `go-flac/flacpicture` v0.3.0 → v2.0.2
- Go toolchain 1.24 → 1.25.7

#### Android
- Android Gradle Plugin 8.x → 9.0.0
- Kotlin 2.1.x → 2.3.10
- `desugar_jdk_libs` → 2.1.5
- `kotlinx-coroutines-android` → 1.10.2
- `lifecycle-runtime-ktx` → 2.10.0
- `activity-ktx` → 1.12.3

#### CI/CD
- `actions/cache` v4 → v5
- `actions/checkout` v4 → v6
- `actions/setup-go` v5 → v6
- `actions/setup-java` v4 → v5
- `softprops/action-gh-release` v1 → v2
- GitHub artifact actions updated

---

## [3.5.0] - 2026-02-07

### Highlights

- **SAF Storage (Android 10+)**: Proper Storage Access Framework support for download destination (content URIs)
  - Select download folder via SAF tree picker
  - Downloads now write to SAF file descriptors (`/proc/self/fd/*`) instead of raw filesystem paths
  - Works around Android 10+ scoped storage permission errors
- **Modern Onboarding Experience**: Completely redesigned Setup and Tutorial screens

### Added

- Home feed disk caching via SharedPreferences for instant restore on app startup
- SAF display path resolver in native Android layer (converts tree URIs to readable paths)
- New settings fields for storage mode + SAF tree URI
- SAF platform bridge methods: pick tree, stat/exists/delete, open content URI, copy to temp, write back to SAF
- SAF library scan mode (DocumentFile traversal + metadata read)
- Incremental library scanning for filesystem and SAF paths (only scans new/modified files and detects removed files)
- Force Full Scan action in Library Settings to rescan all files on demand
- Downloaded files are now excluded from Local Library scan results to prevent duplicate entries
- Legacy library rows now support `file_mod_time` backfill before incremental scans (faster follow-up scans after upgrade)
- Library UI toggle to show SAF-repaired history items
- Scan cancelled banner + retry action for library scans
- Android DocumentFile dependency for SAF operations
- Post-processing API v2 (SAF-aware, ready to replace v1)
- Donate page in Settings with Ko-fi and Buy Me a Coffee links
- Per-App Language support on Android 13+ (locale_config.xml)
- Interactive tutorial with working search bar simulation and clickable download buttons
- Tutorial completion state is persisted after onboarding
- Visual feedback animations for page transitions, entrance effects, and feature lists
- New dedicated welcome step in setup wizard with improved branding

### Changed

- Download pipeline supports `output_path` + `output_ext` for Go backend
- Tidal/Qobuz/Amazon/Extension downloads use SAF-aware output when enabled
- Post-processing hooks run for SAF content URIs (via temp file bridge)
- File operations in Library/Queue/Track screens now SAF-aware (`open`, `exists`, `delete`, `stat`)
- Local Library scan defaults to incremental mode; full rescan is available via Force Full Scan
- Local library database upgraded to schema v3 with `file_mod_time` tracking for incremental scan cache
- Platform channels expanded with incremental scan APIs (`scanLibraryFolderIncremental`) on Android and iOS
- Android platform channel adds `getSafFileModTimes` for SAF legacy cache backfill
- Android build tooling upgraded to Gradle 9.3.1 (wrapper)
- Android build path validated with Java 25 (Gradle/Kotlin/assemble debug)
- SAF tree picker flow in `MainActivity` migrated to Activity Result API (`registerForActivityResult`)
- `MainActivity` host migrated to `FlutterFragmentActivity` for SAF picker compatibility
- Legacy `startActivityForResult` / `onActivityResult` SAF picker path removed
- Setup screen UI polish: smaller logo, thin outline borders on text fields
- Removed support section from About page (moved to Donate page)
- Qobuz squid.wtf region fallback for blocked regions
- Setup screen converted to PageView flow with animated progress bar and modern card layouts
- Tutorial screen aligned with Setup Screen design, updated typography and softened UI shapes
- Larger, more accessible navigation buttons for onboarding flow
- Reduced visual noise by removing unnecessary glow effects

### Fixed

- Android 10+ `permission denied` when writing to `/storage/emulated/0` (now handled via SAF)
- SAF history repair: auto-resolve missing content URIs using tree + filename
- SAF download fallback: retry in app-private storage when SAF write fails
- Tidal DASH manifest writing when output path is a file descriptor (no invalid `.m4a` path)
- External LRC output in SAF mode
- Restored old-device renderer fallback while using `FlutterFragmentActivity` by injecting shell args from a custom `FlutterFragment` (`--enable-impeller=false` on problematic devices)
- Preserved Flutter fragment creation behavior (cached engine, engine group, new engine) while adding Impeller fallback support
- SAF tree picker result now consistently returns `tree_uri` payload with persisted URI permission handling
- SAF share file now copies to temp before sharing (fixes share from SAF content URI)
- Home feed not updating after installing extension with homeFeed capability (no longer requires app restart)
- Library scan hero card showing 0 tracks during scan (now shows scanned file count in real-time)
- Library folder picker no longer requires MANAGE_EXTERNAL_STORAGE on Android 10+ (uses SAF tree picker)
- One-time SAF migration prompt for users updating from pre-SAF versions
- Fixed `fileModTime` propagation across Go/Android/Dart so incremental scan cache is stored and reused correctly
- Fixed SAF incremental scan key mismatch (`lastModified` vs `fileModTime`) and normalized result fields (`skippedCount`, `totalFiles`)
- Fixed incremental scan progress when all files are skipped (`scanned_files` now reaches total files)
- Removed duplicate `"removeExtension"` branch in Android method channel handler (eliminates Kotlin duplicate-branch warning)

---

## [3.4.2] - 2026-02-04

### Improved

- **Mobile Network Reliability**: All providers (Qobuz, Tidal, Amazon, Deezer) now have retry logic with exponential backoff
  - Increased API timeouts: 15s → 25s (Deezer, Qobuz, Tidal), 30s (Amazon)
  - Up to 3 retry attempts per API call (500ms → 1s → 2s backoff)
  - Retryable: timeout, connection reset/refused, EOF, HTTP 5xx, HTTP 429
- **SongLink ID Extraction**: Extract QobuzID/TidalID directly from SongLink URLs
  - New fields in `TrackAvailability`: `QobuzID`, `TidalID`
  - Qobuz/Tidal now use direct Track ID from SongLink instead of re-parsing URLs
- **Qobuz Download Flow**: New Strategy 3 - get QobuzID from SongLink before ISRC search
  - Cache hit now uses `GetTrackByID()` directly instead of searching again
  - Pre-warm cache tries SongLink first before direct ISRC search
- **Tidal Download Flow**: Use `availability.TidalID` directly from SongLink struct

---

## [3.4.1] - 2026-02-04

### Fixed

- Metadata Priority order now persists after app restart
- Download Provider Priority order now persists after app restart

---

## [3.4.0] - 2026-02-03

### Highlights

- **Local Library Scanning** ([#117](https://github.com/zarzet/SpotiFLAC-Mobile/issues/117)): Scan existing music collection to detect duplicates (FLAC, M4A, MP3, Opus, OGG)
- **Duplicate Detection** ([#117](https://github.com/zarzet/SpotiFLAC-Mobile/issues/117)): "In Library" badge on tracks matching by ISRC or track name + artist
- **Unified Library Tab**: History renamed to Library, shows Downloaded + Local Library tracks with source badges

### Added

- Local Album Screen with cover art, disc grouping, and selection mode
- Albums tab shows local library albums with folder icon badge
- Singles filter includes local library singles
- Advanced library filters: Source, Quality, Format, Date
- Cover art extraction from embedded tags (FLAC, MP3, Opus/Ogg)
- "Already in Library" notification when downloading existing tracks
- Spotify secrets now stored in secure storage (`flutter_secure_storage`)
- **Multi-Service Link Support**: Share links from Deezer, Tidal, and YouTube Music (in addition to Spotify)
  - Deezer: Full support for track, album, playlist, artist links
  - Tidal: Track links converted via SongLink to Spotify/Deezer for metadata
  - YouTube Music: Handled via ytmusic extension URL handler
- Local library tracks now open metadata screen on tap

### Changed

- Extension HTTP sandbox enforces HTTPS and blocks private IPs
- Extension file sandbox validates paths with boundary-safe checks

### Fixed

- Search filter bar now only appears after results load, not during loading
- MP3/Ogg metadata parsing (ID3v2 extended headers, Ogg packet reassembly)
- Library scan metadata (ISRC, disc number, release date)
- Cover cache robustness (size + mtime cache key)
- Local library selection and delete in list/grid views
- Albums/Singles count includes local library items

---

## [3.3.6] - 2026-02-02

### Added

- **WiFi-Only Download Mode**: Pause downloads on mobile data, auto-resume on WiFi (Settings > Download > Download Network)
- Added `connectivity_plus: ^6.0.3` dependency

---

## [3.3.5] - 2026-02-01

Same as 3.3.1 but fixes crash issues caused by FFmpeg.

### Added

- **Export Failed Downloads**: Export failed downloads to TXT file for easy lookup on other platforms
- **Auto-Export Setting**: Option to automatically export failed downloads when queue finishes

### Fixed

- **FFmpeg Crash**: Fixed crash issues during M4A to MP3/Opus conversion
- **Service Selection Ignored**: Fixed bug where selecting Qobuz/Amazon from service picker was ignored and always used Tidal instead
- **iOS iCloud Drive Permission Error**: Block iCloud Drive folder selection on iOS (Go backend cannot access iCloud due to sandboxing)

### Changed

- **Amazon Fallback Only**: Amazon Music is now grayed out in service picker and can only be used as fallback provider

---

## [3.3.1] - 2026-02-01

### Added

- **Clear All Queue Button**: Cancel all queued downloads with one tap ([#96](https://github.com/zarzet/SpotiFLAC-Mobile/issues/96))
- **IDHS Fallback**: Fallback link resolver when SongLink fails (rate limited 8 req/min)
- **Lossy Bitrate Options**: MP3 (320/256/192/128kbps), Opus (128/96/64kbps)
- **Search Filters**: Filter results by type (Tracks, Artists, Albums, Playlists)
- **Album/Playlist Search**: Deezer search now includes albums and playlists
- **New Languages**: Turkish (Kaan, BedirhanGltkn), Japanese (Re\*Index.(ot_inc))
- **Optional All Files Access**: Android 13+ no longer requires full storage access; enable in Settings if needed
- **Improved VPN Compatibility**: Better HTTP/2 support for users behind VPN or restricted networks

### Changed

- **Amazon Download API**: Switched to AfkarXYZ API
- **Qobuz Download API**: Added Jumo API as fallback
- **Search Results**: Reduced artist limit from 5 to 2

### Fixed

- **MP3 Download Error 403**: Fixed 403 Forbidden error when downloading MP3 files ([#108](https://github.com/zarzet/SpotiFLAC-Mobile/issues/108))
- **Opus Cover Art**: Implemented METADATA_BLOCK_PICTURE for proper cover embedding
- **Deezer Pagination**: Fixed >25 tracks only showing first 25 ([#112](https://github.com/zarzet/SpotiFLAC-Mobile/issues/112))
- **Duplicate Embed Lyrics Setting**: Removed from Options page ([#110](https://github.com/zarzet/SpotiFLAC-Mobile/issues/110))

---

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
- `**utils.randomUserAgent()` for Extensions\*\*: New utility function for extensions to get random browser User-Agent strings
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

_For older versions, see [GitHub Releases_](https://github.com/zarzet/SpotiFLAC-Mobile/releases)
