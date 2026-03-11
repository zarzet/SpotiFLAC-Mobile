package gobackend

import (
	"encoding/json"
	"fmt"
	"sync"
	"time"
)

type TrackIDCacheEntry struct {
	TidalTrackID  int64
	QobuzTrackID  int64
	ExpiresAt     time.Time
}

type TrackIDCache struct {
	cache           map[string]*TrackIDCacheEntry
	mu              sync.RWMutex
	ttl             time.Duration
	lastCleanup     time.Time
	cleanupInterval time.Duration
}

var (
	globalTrackIDCache *TrackIDCache
	trackIDCacheOnce   sync.Once
)

func GetTrackIDCache() *TrackIDCache {
	trackIDCacheOnce.Do(func() {
		globalTrackIDCache = &TrackIDCache{
			cache:           make(map[string]*TrackIDCacheEntry),
			ttl:             30 * time.Minute,
			cleanupInterval: 5 * time.Minute,
		}
	})
	return globalTrackIDCache
}

func (c *TrackIDCache) Get(isrc string) *TrackIDCacheEntry {
	c.mu.RLock()
	entry, exists := c.cache[isrc]
	if !exists {
		c.mu.RUnlock()
		return nil
	}
	expired := time.Now().After(entry.ExpiresAt)
	c.mu.RUnlock()

	if !expired {
		return entry
	}

	c.mu.Lock()
	entry, exists = c.cache[isrc]
	if exists && time.Now().After(entry.ExpiresAt) {
		delete(c.cache, isrc)
	}
	c.mu.Unlock()
	return nil
}

func (c *TrackIDCache) pruneExpiredLocked(now time.Time) {
	for key, entry := range c.cache {
		if now.After(entry.ExpiresAt) {
			delete(c.cache, key)
		}
	}
}

func (c *TrackIDCache) SetTidal(isrc string, trackID int64) {
	c.mu.Lock()
	defer c.mu.Unlock()

	entry, exists := c.cache[isrc]
	if !exists {
		entry = &TrackIDCacheEntry{}
		c.cache[isrc] = entry
	}
	entry.TidalTrackID = trackID
	now := time.Now()
	entry.ExpiresAt = now.Add(c.ttl)

	if c.cleanupInterval > 0 && (c.lastCleanup.IsZero() || now.Sub(c.lastCleanup) >= c.cleanupInterval) {
		c.pruneExpiredLocked(now)
		c.lastCleanup = now
	}
}

func (c *TrackIDCache) SetQobuz(isrc string, trackID int64) {
	c.mu.Lock()
	defer c.mu.Unlock()

	entry, exists := c.cache[isrc]
	if !exists {
		entry = &TrackIDCacheEntry{}
		c.cache[isrc] = entry
	}
	entry.QobuzTrackID = trackID
	now := time.Now()
	entry.ExpiresAt = now.Add(c.ttl)

	if c.cleanupInterval > 0 && (c.lastCleanup.IsZero() || now.Sub(c.lastCleanup) >= c.cleanupInterval) {
		c.pruneExpiredLocked(now)
		c.lastCleanup = now
	}
}

func (c *TrackIDCache) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.cache = make(map[string]*TrackIDCacheEntry)
}

func (c *TrackIDCache) Size() int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return len(c.cache)
}

type ParallelDownloadResult struct {
	CoverData  []byte
	LyricsData *LyricsResponse
	LyricsLRC  string
	CoverErr   error
	LyricsErr  error
}

func FetchCoverAndLyricsParallel(
	coverURL string,
	maxQualityCover bool,
	spotifyID string,
	trackName string,
	artistName string,
	embedLyrics bool,
	durationMs int64,
) *ParallelDownloadResult {
	result := &ParallelDownloadResult{}
	var wg sync.WaitGroup
	var resultMu sync.Mutex

	if coverURL != "" {
		wg.Add(1)
		go func() {
			defer wg.Done()
			data, err := downloadCoverToMemory(coverURL, maxQualityCover)
			resultMu.Lock()
			if err != nil {
				result.CoverErr = err
			} else {
				result.CoverData = data
			}
			resultMu.Unlock()
		}()
	}

	if embedLyrics {
		wg.Add(1)
		go func() {
			defer wg.Done()
			client := NewLyricsClient()
			durationSec := float64(durationMs) / 1000.0
			lyrics, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName, durationSec)
			resultMu.Lock()
			if err != nil {
				result.LyricsErr = err
			} else if lyrics != nil && len(lyrics.Lines) > 0 {
				result.LyricsData = lyrics
				result.LyricsLRC = convertToLRCWithMetadata(lyrics, trackName, artistName)
			} else {
				result.LyricsErr = fmt.Errorf("no lyrics found")
			}
			resultMu.Unlock()
		}()
	}

	wg.Wait()
	return result
}

type PreWarmCacheRequest struct {
	ISRC       string
	TrackName  string
	ArtistName string
	SpotifyID  string
	Service    string
}

func PreWarmTrackCache(requests []PreWarmCacheRequest) {
	if len(requests) == 0 {
		return
	}

	cache := GetTrackIDCache()

	semaphore := make(chan struct{}, 3)
	var wg sync.WaitGroup

	for _, req := range requests {
		if req.ISRC == "" {
			continue
		}
		if cached := cache.Get(req.ISRC); cached != nil {
			continue
		}

		wg.Add(1)
		go func(r PreWarmCacheRequest) {
			defer wg.Done()
			semaphore <- struct{}{}
			defer func() { <-semaphore }()

			switch r.Service {
			case "tidal":
				preWarmTidalCache(r.ISRC, r.TrackName, r.ArtistName)
			case "qobuz":
				preWarmQobuzCache(r.ISRC, r.SpotifyID)
			}
		}(req)
	}

	wg.Wait()
}

func preWarmTidalCache(isrc, _, _ string) {
	downloader := NewTidalDownloader()
	track, err := downloader.SearchTrackByISRC(isrc)
	if err == nil && track != nil {
		GetTrackIDCache().SetTidal(isrc, track.ID)
	}
}

// preWarmQobuzCache tries to get Qobuz Track ID in the following order:
// 1. From SongLink (fast, no Qobuz API call needed)
// 2. Direct ISRC search on Qobuz API (slower, may fail if ISRC not in Qobuz database)
func preWarmQobuzCache(isrc, spotifyID string) {
	if spotifyID != "" {
		client := NewSongLinkClient()
		availability, err := client.CheckTrackAvailability(spotifyID, isrc)
		if err == nil && availability != nil && availability.QobuzID != "" {
			var trackID int64
			if _, parseErr := fmt.Sscanf(availability.QobuzID, "%d", &trackID); parseErr == nil && trackID > 0 {
				GoLog("[Qobuz] Pre-warm cache: Got Qobuz ID %d from SongLink for ISRC %s\n", trackID, isrc)
				GetTrackIDCache().SetQobuz(isrc, trackID)
				return
			}
		}
	}

	downloader := NewQobuzDownloader()
	track, err := downloader.SearchTrackByISRC(isrc)
	if err == nil && track != nil {
		GoLog("[Qobuz] Pre-warm cache: Got Qobuz ID %d from direct ISRC search for %s\n", track.ID, isrc)
		GetTrackIDCache().SetQobuz(isrc, track.ID)
	}
}

func PreWarmCache(tracksJSON string) error {
	var tracks []struct {
		ISRC       string `json:"isrc"`
		TrackName  string `json:"track_name"`
		ArtistName string `json:"artist_name"`
		SpotifyID  string `json:"spotify_id"`
		Service    string `json:"service"`
	}

	if err := json.Unmarshal([]byte(tracksJSON), &tracks); err != nil {
		return fmt.Errorf("failed to parse tracks JSON: %w", err)
	}

	requests := make([]PreWarmCacheRequest, len(tracks))
	for i, t := range tracks {
		requests[i] = PreWarmCacheRequest{
			ISRC:       t.ISRC,
			TrackName:  t.TrackName,
			ArtistName: t.ArtistName,
			SpotifyID:  t.SpotifyID,
			Service:    t.Service,
		}
	}

	go PreWarmTrackCache(requests)
	return nil
}

func ClearTrackCache() {
	GetTrackIDCache().Clear()
}

func GetCacheSize() int {
	return GetTrackIDCache().Size()
}
