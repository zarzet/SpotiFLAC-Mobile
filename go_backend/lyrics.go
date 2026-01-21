package gobackend

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	lyricsCacheTTL       = 24 * time.Hour
	durationToleranceSec = 10.0
)

type lyricsCacheEntry struct {
	response  *LyricsResponse
	expiresAt time.Time
}

type lyricsCache struct {
	mu    sync.RWMutex
	cache map[string]*lyricsCacheEntry
}

var globalLyricsCache = &lyricsCache{
	cache: make(map[string]*lyricsCacheEntry),
}

func (c *lyricsCache) generateKey(artist, track string, durationSec float64) string {
	normalizedArtist := strings.ToLower(strings.TrimSpace(artist))
	normalizedTrack := strings.ToLower(strings.TrimSpace(track))
	roundedDuration := math.Round(durationSec/10) * 10
	return fmt.Sprintf("%s|%s|%.0f", normalizedArtist, normalizedTrack, roundedDuration)
}

func (c *lyricsCache) Get(artist, track string, durationSec float64) (*LyricsResponse, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	key := c.generateKey(artist, track, durationSec)
	entry, exists := c.cache[key]
	if !exists {
		return nil, false
	}

	if time.Now().After(entry.expiresAt) {
		return nil, false
	}

	return entry.response, true
}

func (c *lyricsCache) Set(artist, track string, durationSec float64, response *LyricsResponse) {
	c.mu.Lock()
	defer c.mu.Unlock()

	key := c.generateKey(artist, track, durationSec)
	c.cache[key] = &lyricsCacheEntry{
		response:  response,
		expiresAt: time.Now().Add(lyricsCacheTTL),
	}
}

func (c *lyricsCache) CleanExpired() int {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := time.Now()
	cleaned := 0
	for key, entry := range c.cache {
		if now.After(entry.expiresAt) {
			delete(c.cache, key)
			cleaned++
		}
	}
	return cleaned
}

func (c *lyricsCache) Size() int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return len(c.cache)
}

type LRCLibResponse struct {
	ID           int     `json:"id"`
	Name         string  `json:"name"`
	TrackName    string  `json:"trackName"`
	ArtistName   string  `json:"artistName"`
	AlbumName    string  `json:"albumName"`
	Duration     float64 `json:"duration"`
	Instrumental bool    `json:"instrumental"`
	PlainLyrics  string  `json:"plainLyrics"`
	SyncedLyrics string  `json:"syncedLyrics"`
}

type LyricsLine struct {
	StartTimeMs int64  `json:"startTimeMs"`
	Words       string `json:"words"`
	EndTimeMs   int64  `json:"endTimeMs"`
}

type LyricsResponse struct {
	Lines        []LyricsLine `json:"lines"`
	SyncType     string       `json:"syncType"`
	Instrumental bool         `json:"instrumental"`
	PlainLyrics  string       `json:"plainLyrics"`
	Provider     string       `json:"provider"`
	Source       string       `json:"source"`
}

type LyricsClient struct {
	httpClient *http.Client
}

func NewLyricsClient() *LyricsClient {
	return &LyricsClient{
		httpClient: NewHTTPClientWithTimeout(15 * time.Second),
	}
}

func (c *LyricsClient) FetchLyricsWithMetadata(artist, track string) (*LyricsResponse, error) {
	baseURL := "https://lrclib.net/api/get"
	params := url.Values{}
	params.Set("artist_name", artist)
	params.Set("track_name", track)

	fullURL := baseURL + "?" + params.Encode()

	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("User-Agent", "SpotiFLAC-Android/1.0")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch lyrics: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 404 {
		return nil, fmt.Errorf("lyrics not found")
	}

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	var lrcResp LRCLibResponse
	if err := json.NewDecoder(resp.Body).Decode(&lrcResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return c.parseLRCLibResponse(&lrcResp), nil
}

func (c *LyricsClient) FetchLyricsFromLRCLibSearch(query string, durationSec float64) (*LyricsResponse, error) {
	baseURL := "https://lrclib.net/api/search"
	params := url.Values{}
	params.Set("q", query)

	fullURL := baseURL + "?" + params.Encode()

	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("User-Agent", "SpotiFLAC-Android/1.0")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to search lyrics: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	var results []LRCLibResponse
	if err := json.NewDecoder(resp.Body).Decode(&results); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	if len(results) == 0 {
		return nil, fmt.Errorf("no lyrics found")
	}

	bestMatch := c.findBestMatch(results, durationSec)
	if bestMatch != nil {
		return c.parseLRCLibResponse(bestMatch), nil
	}

	for _, result := range results {
		if result.SyncedLyrics != "" {
			return c.parseLRCLibResponse(&result), nil
		}
	}

	return c.parseLRCLibResponse(&results[0]), nil
}

func (c *LyricsClient) findBestMatch(results []LRCLibResponse, targetDurationSec float64) *LRCLibResponse {
	var bestSynced *LRCLibResponse
	var bestPlain *LRCLibResponse

	for i := range results {
		result := &results[i]

		durationMatches := targetDurationSec == 0 || c.durationMatches(result.Duration, targetDurationSec)

		if durationMatches {
			if result.SyncedLyrics != "" && bestSynced == nil {
				bestSynced = result
			} else if result.PlainLyrics != "" && bestPlain == nil {
				bestPlain = result
			}
		}
	}

	if bestSynced != nil {
		return bestSynced
	}
	return bestPlain
}

func (c *LyricsClient) durationMatches(lrcDuration, targetDuration float64) bool {
	diff := math.Abs(lrcDuration - targetDuration)
	return diff <= durationToleranceSec
}

// durationSec: track duration in seconds for matching, use 0 to skip duration matching
func (c *LyricsClient) FetchLyricsAllSources(spotifyID, trackName, artistName string, durationSec float64) (*LyricsResponse, error) {
	// Normalize artist name - take first artist before comma/semicolon for better matching
	primaryArtist := normalizeArtistName(artistName)

	// Check cache first (use original artist name for cache key)
	if cached, found := globalLyricsCache.Get(artistName, trackName, durationSec); found {
		fmt.Printf("[Lyrics] Cache hit for: %s - %s\n", artistName, trackName)
		cachedCopy := *cached
		cachedCopy.Source = cached.Source + " (cached)"
		return &cachedCopy, nil
	}

	var lyrics *LyricsResponse
	var err error

	// Helper to check if lyrics result is valid (has lines OR is instrumental)
	isValidResult := func(l *LyricsResponse) bool {
		return l != nil && (len(l.Lines) > 0 || l.Instrumental)
	}

	// Try exact match first with primary artist
	lyrics, err = c.FetchLyricsWithMetadata(primaryArtist, trackName)
	if err == nil && isValidResult(lyrics) {
		lyrics.Source = "LRCLIB"
		globalLyricsCache.Set(artistName, trackName, durationSec, lyrics)
		return lyrics, nil
	}

	// Try with full artist name if different from primary
	if primaryArtist != artistName {
		lyrics, err = c.FetchLyricsWithMetadata(artistName, trackName)
		if err == nil && isValidResult(lyrics) {
			lyrics.Source = "LRCLIB"
			globalLyricsCache.Set(artistName, trackName, durationSec, lyrics)
			return lyrics, nil
		}
	}

	// Try with simplified track name
	simplifiedTrack := simplifyTrackName(trackName)
	if simplifiedTrack != trackName {
		lyrics, err = c.FetchLyricsWithMetadata(primaryArtist, simplifiedTrack)
		if err == nil && isValidResult(lyrics) {
			lyrics.Source = "LRCLIB (simplified)"
			globalLyricsCache.Set(artistName, trackName, durationSec, lyrics)
			return lyrics, nil
		}
	}

	// Search with duration matching (use primary artist for search)
	query := primaryArtist + " " + trackName
	lyrics, err = c.FetchLyricsFromLRCLibSearch(query, durationSec)
	if err == nil && isValidResult(lyrics) {
		lyrics.Source = "LRCLIB Search"
		globalLyricsCache.Set(artistName, trackName, durationSec, lyrics)
		return lyrics, nil
	}

	// Search with simplified name and duration matching
	if simplifiedTrack != trackName {
		query = primaryArtist + " " + simplifiedTrack
		lyrics, err = c.FetchLyricsFromLRCLibSearch(query, durationSec)
		if err == nil && isValidResult(lyrics) {
			lyrics.Source = "LRCLIB Search (simplified)"
			globalLyricsCache.Set(artistName, trackName, durationSec, lyrics)
			return lyrics, nil
		}
	}

	return nil, fmt.Errorf("lyrics not found from any source")
}

func (c *LyricsClient) parseLRCLibResponse(resp *LRCLibResponse) *LyricsResponse {
	result := &LyricsResponse{
		Instrumental: resp.Instrumental,
		PlainLyrics:  resp.PlainLyrics,
		Provider:     "LRCLIB",
	}

	if resp.SyncedLyrics != "" {
		result.Lines = parseSyncedLyrics(resp.SyncedLyrics)
		result.SyncType = "LINE_SYNCED"
	} else if resp.PlainLyrics != "" {
		result.SyncType = "UNSYNCED"
		lines := strings.Split(resp.PlainLyrics, "\n")
		for _, line := range lines {
			if strings.TrimSpace(line) != "" {
				result.Lines = append(result.Lines, LyricsLine{
					StartTimeMs: 0,
					Words:       line,
					EndTimeMs:   0,
				})
			}
		}
	}

	return result
}

func parseSyncedLyrics(syncedLyrics string) []LyricsLine {
	var lines []LyricsLine
	lrcPattern := regexp.MustCompile(`\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)`)

	for _, line := range strings.Split(syncedLyrics, "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		matches := lrcPattern.FindStringSubmatch(line)
		if len(matches) == 5 {
			startMs := lrcTimestampToMs(matches[1], matches[2], matches[3])
			words := strings.TrimSpace(matches[4])

			lines = append(lines, LyricsLine{
				StartTimeMs: startMs,
				Words:       words,
				EndTimeMs:   0,
			})
		}
	}

	for i := 0; i < len(lines)-1; i++ {
		lines[i].EndTimeMs = lines[i+1].StartTimeMs
	}

	if len(lines) > 0 {
		lines[len(lines)-1].EndTimeMs = lines[len(lines)-1].StartTimeMs + 5000
	}

	return lines
}

func lrcTimestampToMs(minutes, seconds, centiseconds string) int64 {
	min, _ := strconv.ParseInt(minutes, 10, 64)
	sec, _ := strconv.ParseInt(seconds, 10, 64)
	cs, _ := strconv.ParseInt(centiseconds, 10, 64)

	if len(centiseconds) == 2 {
		cs *= 10
	}

	return min*60*1000 + sec*1000 + cs
}

func msToLRCTimestamp(ms int64) string {
	totalSeconds := ms / 1000
	minutes := totalSeconds / 60
	seconds := totalSeconds % 60
	centiseconds := (ms % 1000) / 10

	return fmt.Sprintf("[%02d:%02d.%02d]", minutes, seconds, centiseconds)
}

// Use convertToLRCWithMetadata for full LRC with headers
// Kept for potential future use
// func convertToLRC(lyrics *LyricsResponse) string {
// 	if lyrics == nil || len(lyrics.Lines) == 0 {
// 		return ""
// 	}
//
// 	var builder strings.Builder
//
// 	if lyrics.SyncType == "LINE_SYNCED" {
// 		for _, line := range lyrics.Lines {
// 			timestamp := msToLRCTimestamp(line.StartTimeMs)
// 			builder.WriteString(timestamp)
// 			builder.WriteString(line.Words)
// 			builder.WriteString("\n")
// 		}
// 	} else {
// 		for _, line := range lyrics.Lines {
// 			builder.WriteString(line.Words)
// 			builder.WriteString("\n")
// 		}
// 	}
//
// 	return builder.String()
// }

func convertToLRCWithMetadata(lyrics *LyricsResponse, trackName, artistName string) string {
	if lyrics == nil || len(lyrics.Lines) == 0 {
		return ""
	}

	var builder strings.Builder

	builder.WriteString(fmt.Sprintf("[ti:%s]\n", trackName))
	builder.WriteString(fmt.Sprintf("[ar:%s]\n", artistName))
	builder.WriteString("[by:SpotiFLAC-Mobile]\n")
	builder.WriteString("\n")

	if lyrics.SyncType == "LINE_SYNCED" {
		for _, line := range lyrics.Lines {
			if line.Words == "" {
				continue
			}
			timestamp := msToLRCTimestamp(line.StartTimeMs)
			builder.WriteString(timestamp)
			builder.WriteString(line.Words)
			builder.WriteString("\n")
		}
	} else {
		for _, line := range lyrics.Lines {
			if line.Words == "" {
				continue
			}
			builder.WriteString(line.Words)
			builder.WriteString("\n")
		}
	}

	return builder.String()
}

func simplifyTrackName(name string) string {
	patterns := []string{
		`\s*\(feat\..*?\)`,
		`\s*\(ft\..*?\)`,
		`\s*\(featuring.*?\)`,
		`\s*\(with.*?\)`,
		`\s*-\s*Remaster(ed)?.*$`,
		`\s*-\s*\d{4}\s*Remaster.*$`,
		`\s*\(Remaster(ed)?.*?\)`,
		`\s*\(Deluxe.*?\)`,
		`\s*\(Bonus.*?\)`,
		`\s*\(Live.*?\)`,
		`\s*\(Acoustic.*?\)`,
		`\s*\(Radio Edit\)`,
		`\s*\(Single Version\)`,
	}

	result := name
	for _, pattern := range patterns {
		re := regexp.MustCompile("(?i)" + pattern)
		result = re.ReplaceAllString(result, "")
	}

	return strings.TrimSpace(result)
}

// normalizeArtistName extracts the primary artist from multi-artist strings
// e.g., "HOYO-MiX, AURORA" -> "HOYO-MiX"
// e.g., "Artist1; Artist2" -> "Artist1"
func normalizeArtistName(name string) string {
	// Split by common separators: ", " or "; " or " & " or " feat. " or " ft. "
	separators := []string{", ", "; ", " & ", " feat. ", " ft. ", " featuring ", " with "}

	result := name
	for _, sep := range separators {
		if idx := strings.Index(strings.ToLower(result), strings.ToLower(sep)); idx > 0 {
			result = result[:idx]
			break
		}
	}

	return strings.TrimSpace(result)
}

func SaveLRCFile(audioFilePath, lrcContent string) (string, error) {
	if lrcContent == "" {
		return "", fmt.Errorf("empty LRC content")
	}

	dir := filepath.Dir(audioFilePath)
	ext := filepath.Ext(audioFilePath)
	baseName := strings.TrimSuffix(filepath.Base(audioFilePath), ext)

	lrcFilePath := filepath.Join(dir, baseName+".lrc")

	if err := os.WriteFile(lrcFilePath, []byte(lrcContent), 0644); err != nil {
		return "", fmt.Errorf("failed to write LRC file: %w", err)
	}

	GoLog("[Lyrics] Saved LRC file: %s\n", lrcFilePath)
	return lrcFilePath, nil
}
