package gobackend

import (
	"fmt"
	"sync"
	"time"
)

// ========================================
// ISRC to Track ID Cache
// ========================================

// TrackIDCacheEntry holds cached track ID with metadata
type TrackIDCacheEntry struct {
	TidalTrackID  int64
	QobuzTrackID  int64
	AmazonTrackID string
	ExpiresAt     time.Time
}

// TrackIDCache caches ISRC to track ID mappings
type TrackIDCache struct {
	cache map[string]*TrackIDCacheEntry
	mu    sync.RWMutex
	ttl   time.Duration
}

var (
	globalTrackIDCache *TrackIDCache
	trackIDCacheOnce   sync.Once
)

// GetTrackIDCache returns the global track ID cache
func GetTrackIDCache() *TrackIDCache {
	trackIDCacheOnce.Do(func() {
		globalTrackIDCache = &TrackIDCache{
			cache: make(map[string]*TrackIDCacheEntry),
			ttl:   30 * time.Minute, // Cache for 30 minutes
		}
	})
	return globalTrackIDCache
}

// Get retrieves a cached entry by ISRC
func (c *TrackIDCache) Get(isrc string) *TrackIDCacheEntry {
	c.mu.RLock()
	defer c.mu.RUnlock()

	entry, exists := c.cache[isrc]
	if !exists || time.Now().After(entry.ExpiresAt) {
		return nil
	}
	return entry
}

// SetTidal caches Tidal track ID for an ISRC
func (c *TrackIDCache) SetTidal(isrc string, trackID int64) {
	c.mu.Lock()
	defer c.mu.Unlock()

	entry, exists := c.cache[isrc]
	if !exists {
		entry = &TrackIDCacheEntry{}
		c.cache[isrc] = entry
	}
	entry.TidalTrackID = trackID
	entry.ExpiresAt = time.Now().Add(c.ttl)
}

// SetQobuz caches Qobuz track ID for an ISRC
func (c *TrackIDCache) SetQobuz(isrc string, trackID int64) {
	c.mu.Lock()
	defer c.mu.Unlock()

	entry, exists := c.cache[isrc]
	if !exists {
		entry = &TrackIDCacheEntry{}
		c.cache[isrc] = entry
	}
	entry.QobuzTrackID = trackID
	entry.ExpiresAt = time.Now().Add(c.ttl)
}

// SetAmazon caches Amazon track ID for an ISRC
func (c *TrackIDCache) SetAmazon(isrc string, trackID string) {
	c.mu.Lock()
	defer c.mu.Unlock()

	entry, exists := c.cache[isrc]
	if !exists {
		entry = &TrackIDCacheEntry{}
		c.cache[isrc] = entry
	}
	entry.AmazonTrackID = trackID
	entry.ExpiresAt = time.Now().Add(c.ttl)
}

// Clear removes all cached entries
func (c *TrackIDCache) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.cache = make(map[string]*TrackIDCacheEntry)
}

// Size returns the number of cached entries
func (c *TrackIDCache) Size() int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return len(c.cache)
}

// ========================================
// Parallel Download Helper
// ========================================

// ParallelDownloadResult holds results from parallel operations
type ParallelDownloadResult struct {
	CoverData  []byte
	LyricsData *LyricsResponse
	LyricsLRC  string
	CoverErr   error
	LyricsErr  error
}

// FetchCoverAndLyricsParallel downloads cover and fetches lyrics in parallel
// This runs while the main audio download is happening
func FetchCoverAndLyricsParallel(
	coverURL string,
	maxQualityCover bool,
	spotifyID string,
	trackName string,
	artistName string,
	embedLyrics bool,
) *ParallelDownloadResult {
	result := &ParallelDownloadResult{}
	var wg sync.WaitGroup

	// Download cover in parallel
	if coverURL != "" {
		wg.Add(1)
		go func() {
			defer wg.Done()
			fmt.Println("[Parallel] Starting cover download...")
			data, err := downloadCoverToMemory(coverURL, maxQualityCover)
			if err != nil {
				result.CoverErr = err
				fmt.Printf("[Parallel] Cover download failed: %v\n", err)
			} else {
				result.CoverData = data
				fmt.Printf("[Parallel] Cover downloaded: %d bytes\n", len(data))
			}
		}()
	}

	// Fetch lyrics in parallel
	if embedLyrics {
		wg.Add(1)
		go func() {
			defer wg.Done()
			fmt.Println("[Parallel] Starting lyrics fetch...")
			client := NewLyricsClient()
			lyrics, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName)
			if err != nil {
				result.LyricsErr = err
				fmt.Printf("[Parallel] Lyrics fetch failed: %v\n", err)
			} else if lyrics != nil && len(lyrics.Lines) > 0 {
				result.LyricsData = lyrics
				// Use LRC with metadata headers (like PC version)
				result.LyricsLRC = convertToLRCWithMetadata(lyrics, trackName, artistName)
				fmt.Printf("[Parallel] Lyrics fetched: %d lines\n", len(lyrics.Lines))
			} else {
				result.LyricsErr = fmt.Errorf("no lyrics found")
				fmt.Println("[Parallel] No lyrics found")
			}
		}()
	}

	wg.Wait()
	return result
}

// ========================================
// Pre-warm Cache for Album/Playlist
// ========================================

// PreWarmCacheRequest represents a track to pre-warm cache for
type PreWarmCacheRequest struct {
	ISRC       string
	TrackName  string
	ArtistName string
	SpotifyID  string // Needed for Amazon (SongLink lookup)
	Service    string // "tidal", "qobuz", "amazon"
}

// PreWarmTrackCache pre-fetches track IDs for multiple tracks (for album/playlist)
// This runs in background while user is viewing the track list
func PreWarmTrackCache(requests []PreWarmCacheRequest) {
	if len(requests) == 0 {
		return
	}

	fmt.Printf("[Cache] Pre-warming cache for %d tracks...\n", len(requests))
	cache := GetTrackIDCache()

	// Limit concurrent pre-warm requests
	semaphore := make(chan struct{}, 3) // Max 3 concurrent
	var wg sync.WaitGroup

	for _, req := range requests {
		// Skip if already cached
		if cached := cache.Get(req.ISRC); cached != nil {
			continue
		}

		wg.Add(1)
		go func(r PreWarmCacheRequest) {
			defer wg.Done()
			semaphore <- struct{}{}        // Acquire
			defer func() { <-semaphore }() // Release

			switch r.Service {
			case "tidal":
				preWarmTidalCache(r.ISRC, r.TrackName, r.ArtistName)
			case "qobuz":
				preWarmQobuzCache(r.ISRC)
			case "amazon":
				preWarmAmazonCache(r.ISRC, r.SpotifyID)
			}
		}(req)
	}

	wg.Wait()
	fmt.Printf("[Cache] Pre-warm complete. Cache size: %d\n", cache.Size())
}

func preWarmTidalCache(isrc, _, _ string) {
	downloader := NewTidalDownloader()
	track, err := downloader.SearchTrackByISRC(isrc)
	if err == nil && track != nil {
		GetTrackIDCache().SetTidal(isrc, track.ID)
		fmt.Printf("[Cache] Cached Tidal ID for ISRC %s: %d\n", isrc, track.ID)
	}
}

func preWarmQobuzCache(isrc string) {
	downloader := NewQobuzDownloader()
	track, err := downloader.SearchTrackByISRC(isrc)
	if err == nil && track != nil {
		GetTrackIDCache().SetQobuz(isrc, track.ID)
		fmt.Printf("[Cache] Cached Qobuz ID for ISRC %s: %d\n", isrc, track.ID)
	}
}

func preWarmAmazonCache(isrc, spotifyID string) {
	// Amazon uses SongLink to get URL, so we pre-warm by checking availability
	client := NewSongLinkClient()
	availability, err := client.CheckTrackAvailability(spotifyID, isrc)
	if err == nil && availability != nil && availability.Amazon {
		// Store Amazon URL in cache (using ISRC as key)
		GetTrackIDCache().SetAmazon(isrc, availability.AmazonURL)
		fmt.Printf("[Cache] Cached Amazon URL for ISRC %s\n", isrc)
	}
}

// ========================================
// Exported Functions for Flutter
// ========================================

// PreWarmCache is called from Flutter to pre-warm cache for album/playlist tracks
// tracksJSON is a JSON array of {isrc, track_name, artist_name, service}
func PreWarmCache(tracksJSON string) error {
	var requests []PreWarmCacheRequest
	// Parse JSON (simplified - in production use proper JSON parsing)
	// For now, this is called from exports.go with proper parsing

	go PreWarmTrackCache(requests) // Run in background
	return nil
}

// ClearTrackCache clears the track ID cache
func ClearTrackCache() {
	GetTrackIDCache().Clear()
	fmt.Println("[Cache] Track ID cache cleared")
}

// GetCacheSize returns the current cache size
func GetCacheSize() int {
	return GetTrackIDCache().Size()
}
