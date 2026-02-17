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

// Lyrics provider names (used in settings and cascade ordering)
const (
	LyricsProviderLRCLIB     = "lrclib"
	LyricsProviderNetease    = "netease"
	LyricsProviderMusixmatch = "musixmatch"
	LyricsProviderAppleMusic = "apple_music"
	LyricsProviderQQMusic    = "qqmusic"
)

// DefaultLyricsProviders is the default cascade order for lyrics fetching.
// LRCLIB first (no proxy dependency), then the others.
var DefaultLyricsProviders = []string{
	LyricsProviderLRCLIB,
	LyricsProviderMusixmatch,
	LyricsProviderNetease,
	LyricsProviderAppleMusic,
	LyricsProviderQQMusic,
}

// Global lyrics provider configuration
var (
	lyricsProvidersMu sync.RWMutex
	lyricsProviders   []string // ordered list of enabled providers
)

// LyricsFetchOptions controls optional provider-specific enhancements.
type LyricsFetchOptions struct {
	IncludeTranslationNetease  bool   `json:"include_translation_netease"`
	IncludeRomanizationNetease bool   `json:"include_romanization_netease"`
	MultiPersonWordByWord      bool   `json:"multi_person_word_by_word"`
	MusixmatchLanguage         string `json:"musixmatch_language,omitempty"`
}

var defaultLyricsFetchOptions = LyricsFetchOptions{
	IncludeTranslationNetease:  false,
	IncludeRomanizationNetease: false,
	MultiPersonWordByWord:      true,
	MusixmatchLanguage:         "",
}

var (
	lyricsFetchOptionsMu sync.RWMutex
	lyricsFetchOptions   = defaultLyricsFetchOptions
)

// SetLyricsProviderOrder sets the ordered list of lyrics providers to try.
// Providers not in the list are disabled. An empty list resets to defaults.
func SetLyricsProviderOrder(providers []string) {
	lyricsProvidersMu.Lock()
	defer lyricsProvidersMu.Unlock()

	if len(providers) == 0 {
		lyricsProviders = nil
		return
	}

	// Validate provider names
	validNames := map[string]bool{
		LyricsProviderLRCLIB:     true,
		LyricsProviderNetease:    true,
		LyricsProviderMusixmatch: true,
		LyricsProviderAppleMusic: true,
		LyricsProviderQQMusic:    true,
	}

	var valid []string
	for _, p := range providers {
		normalized := strings.ToLower(strings.TrimSpace(p))
		if validNames[normalized] {
			valid = append(valid, normalized)
		}
	}

	lyricsProviders = valid
	GoLog("[Lyrics] Provider order set to: %v\n", valid)
}

// GetLyricsProviderOrder returns the current lyrics provider order.
func GetLyricsProviderOrder() []string {
	lyricsProvidersMu.RLock()
	defer lyricsProvidersMu.RUnlock()

	if len(lyricsProviders) == 0 {
		return DefaultLyricsProviders
	}

	result := make([]string, len(lyricsProviders))
	copy(result, lyricsProviders)
	return result
}

// GetAvailableLyricsProviders returns metadata about all available providers.
func GetAvailableLyricsProviders() []map[string]interface{} {
	return []map[string]interface{}{
		{"id": LyricsProviderLRCLIB, "name": "LRCLIB", "has_proxy_dependency": false, "description": "Open-source synced lyrics database"},
		{"id": LyricsProviderNetease, "name": "Netease", "has_proxy_dependency": false, "description": "NetEase Cloud Music (good for Asian songs)"},
		{"id": LyricsProviderMusixmatch, "name": "Musixmatch", "has_proxy_dependency": true, "description": "Largest lyrics database (multi-language)"},
		{"id": LyricsProviderAppleMusic, "name": "Apple Music", "has_proxy_dependency": true, "description": "Word-by-word synced lyrics"},
		{"id": LyricsProviderQQMusic, "name": "QQ Music", "has_proxy_dependency": true, "description": "QQ Music lyrics (good for Chinese songs)"},
	}
}

func normalizeLyricsFetchOptions(opts LyricsFetchOptions) LyricsFetchOptions {
	opts.MusixmatchLanguage = strings.ToLower(strings.TrimSpace(opts.MusixmatchLanguage))
	opts.MusixmatchLanguage = regexp.MustCompile(`[^a-z0-9\-_]`).ReplaceAllString(opts.MusixmatchLanguage, "")
	if len(opts.MusixmatchLanguage) > 16 {
		opts.MusixmatchLanguage = opts.MusixmatchLanguage[:16]
	}
	return opts
}

// SetLyricsFetchOptions sets provider-specific lyric fetch behavior.
func SetLyricsFetchOptions(opts LyricsFetchOptions) {
	normalized := normalizeLyricsFetchOptions(opts)

	lyricsFetchOptionsMu.Lock()
	defer lyricsFetchOptionsMu.Unlock()
	lyricsFetchOptions = normalized

	GoLog("[Lyrics] Fetch options set: translation=%v romanization=%v multi_person=%v musixmatch_lang=%q\n",
		normalized.IncludeTranslationNetease,
		normalized.IncludeRomanizationNetease,
		normalized.MultiPersonWordByWord,
		normalized.MusixmatchLanguage,
	)
}

// GetLyricsFetchOptions returns current provider-specific lyric fetch behavior.
func GetLyricsFetchOptions() LyricsFetchOptions {
	lyricsFetchOptionsMu.RLock()
	defer lyricsFetchOptionsMu.RUnlock()
	return lyricsFetchOptions
}

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

func (c *lyricsCache) ClearAll() int {
	c.mu.Lock()
	defer c.mu.Unlock()

	cleared := len(c.cache)
	c.cache = make(map[string]*lyricsCacheEntry)
	return cleared
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
	req.Header.Set("User-Agent", getRandomUserAgent())

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
	req.Header.Set("User-Agent", getRandomUserAgent())

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

func (c *LyricsClient) FetchLyricsAllSources(spotifyID, trackName, artistName string, durationSec float64) (*LyricsResponse, error) {
	primaryArtist := normalizeArtistName(artistName)
	fetchOptions := GetLyricsFetchOptions()

	extManager := GetExtensionManager()
	var extensionProviders []*ExtensionProviderWrapper
	if extManager != nil {
		extensionProviders = extManager.GetLyricsProviders()
	}

	var cachedNonExtension *LyricsResponse
	if cached, found := globalLyricsCache.Get(artistName, trackName, durationSec); found {
		isExtensionCache := strings.HasPrefix(cached.Source, "Extension:")
		if len(extensionProviders) == 0 || isExtensionCache {
			fmt.Printf("[Lyrics] Cache hit for: %s - %s\n", artistName, trackName)
			cachedCopy := *cached
			cachedCopy.Source = cached.Source + " (cached)"
			return &cachedCopy, nil
		}

		// If extension providers are currently enabled, don't let stale built-in cache
		// mask newly installed/activated extensions.
		cachedNonExtension = cached
		GoLog("[Lyrics] Ignoring cached non-extension lyrics because extension providers are available\n")
	}

	isValidResult := func(l *LyricsResponse) bool {
		return lyricsHasUsableText(l)
	}

	// Try extension lyrics providers first
	if len(extensionProviders) > 0 {
		for _, provider := range extensionProviders {
			GoLog("[Lyrics] Trying extension lyrics provider: %s\n", provider.extension.ID)
			lyrics, err := provider.FetchLyrics(trackName, artistName, "", durationSec)
			if err == nil && isValidResult(lyrics) {
				GoLog("[Lyrics] Got lyrics from extension: %s\n", provider.extension.ID)
				globalLyricsCache.Set(artistName, trackName, durationSec, lyrics)
				return lyrics, nil
			}
			if err != nil {
				GoLog("[Lyrics] Extension %s failed: %v\n", provider.extension.ID, err)
			}
		}
	}

	if cachedNonExtension != nil {
		cachedCopy := *cachedNonExtension
		cachedCopy.Source = cachedNonExtension.Source + " (cached fallback)"
		GoLog("[Lyrics] Extension providers unavailable for this track, using cached built-in lyrics\n")
		return &cachedCopy, nil
	}

	// Get configured provider order
	providerOrder := GetLyricsProviderOrder()
	simplifiedTrack := simplifyTrackName(trackName)

	GoLog("[Lyrics] Searching for: %s - %s (providers: %v)\n", artistName, trackName, providerOrder)

	// Cascade through all configured built-in providers
	for _, providerName := range providerOrder {
		GoLog("[Lyrics] Trying provider: %s\n", providerName)

		var lyrics *LyricsResponse
		var err error

		switch providerName {
		case LyricsProviderLRCLIB:
			lyrics, err = c.tryLRCLIB(primaryArtist, artistName, trackName, simplifiedTrack, durationSec)

		case LyricsProviderNetease:
			neteaseClient := NewNeteaseClient()
			lyrics, err = neteaseClient.FetchLyrics(
				trackName,
				primaryArtist,
				durationSec,
				fetchOptions.IncludeTranslationNetease,
				fetchOptions.IncludeRomanizationNetease,
			)
			if err != nil && primaryArtist != artistName {
				lyrics, err = neteaseClient.FetchLyrics(
					trackName,
					artistName,
					durationSec,
					fetchOptions.IncludeTranslationNetease,
					fetchOptions.IncludeRomanizationNetease,
				)
			}
			if err != nil && simplifiedTrack != trackName {
				lyrics, err = neteaseClient.FetchLyrics(
					simplifiedTrack,
					primaryArtist,
					durationSec,
					fetchOptions.IncludeTranslationNetease,
					fetchOptions.IncludeRomanizationNetease,
				)
			}

		case LyricsProviderMusixmatch:
			musixmatchClient := NewMusixmatchClient()
			lyrics, err = musixmatchClient.FetchLyrics(
				trackName,
				primaryArtist,
				durationSec,
				fetchOptions.MusixmatchLanguage,
			)
			if err != nil && primaryArtist != artistName {
				lyrics, err = musixmatchClient.FetchLyrics(
					trackName,
					artistName,
					durationSec,
					fetchOptions.MusixmatchLanguage,
				)
			}

		case LyricsProviderAppleMusic:
			appleClient := NewAppleMusicClient()
			lyrics, err = appleClient.FetchLyrics(trackName, primaryArtist, durationSec, fetchOptions.MultiPersonWordByWord)
			if err != nil && primaryArtist != artistName {
				lyrics, err = appleClient.FetchLyrics(trackName, artistName, durationSec, fetchOptions.MultiPersonWordByWord)
			}

		case LyricsProviderQQMusic:
			qqClient := NewQQMusicClient()
			lyrics, err = qqClient.FetchLyrics(trackName, primaryArtist, durationSec, fetchOptions.MultiPersonWordByWord)
			if err != nil && primaryArtist != artistName {
				lyrics, err = qqClient.FetchLyrics(trackName, artistName, durationSec, fetchOptions.MultiPersonWordByWord)
			}

		default:
			GoLog("[Lyrics] Unknown provider: %s, skipping\n", providerName)
			continue
		}

		if err == nil && isValidResult(lyrics) {
			GoLog("[Lyrics] Got lyrics from: %s\n", providerName)
			globalLyricsCache.Set(artistName, trackName, durationSec, lyrics)
			return lyrics, nil
		}

		if err != nil {
			GoLog("[Lyrics] Provider %s failed: %v\n", providerName, err)
		}
	}

	return nil, fmt.Errorf("lyrics not found from any source")
}

// tryLRCLIB attempts all LRCLIB search strategies (exact match, simplified, search).
func (c *LyricsClient) tryLRCLIB(primaryArtist, artistName, trackName, simplifiedTrack string, durationSec float64) (*LyricsResponse, error) {
	var lyrics *LyricsResponse
	var err error

	// 1. Exact match with primary artist
	lyrics, err = c.FetchLyricsWithMetadata(primaryArtist, trackName)
	if err == nil && lyrics != nil && (len(lyrics.Lines) > 0 || lyrics.Instrumental) {
		lyrics.Source = "LRCLIB"
		return lyrics, nil
	}

	// 2. Exact match with full artist name
	if primaryArtist != artistName {
		lyrics, err = c.FetchLyricsWithMetadata(artistName, trackName)
		if err == nil && lyrics != nil && (len(lyrics.Lines) > 0 || lyrics.Instrumental) {
			lyrics.Source = "LRCLIB"
			return lyrics, nil
		}
	}

	// 3. Simplified track name
	if simplifiedTrack != trackName {
		lyrics, err = c.FetchLyricsWithMetadata(primaryArtist, simplifiedTrack)
		if err == nil && lyrics != nil && (len(lyrics.Lines) > 0 || lyrics.Instrumental) {
			lyrics.Source = "LRCLIB (simplified)"
			return lyrics, nil
		}
	}

	// 4. Search by query
	query := primaryArtist + " " + trackName
	lyrics, err = c.FetchLyricsFromLRCLibSearch(query, durationSec)
	if err == nil && lyrics != nil && (len(lyrics.Lines) > 0 || lyrics.Instrumental) {
		lyrics.Source = "LRCLIB Search"
		return lyrics, nil
	}

	// 5. Search with simplified track name
	if simplifiedTrack != trackName {
		query = primaryArtist + " " + simplifiedTrack
		lyrics, err = c.FetchLyricsFromLRCLibSearch(query, durationSec)
		if err == nil && lyrics != nil && (len(lyrics.Lines) > 0 || lyrics.Instrumental) {
			lyrics.Source = "LRCLIB Search (simplified)"
			return lyrics, nil
		}
	}

	return nil, fmt.Errorf("LRCLIB: no lyrics found")
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

		// Preserve Apple/QQ background vocal tags by attaching them to
		// the previous timed line. This keeps [bg:...] in final exported LRC.
		if strings.HasPrefix(line, "[bg:") && len(lines) > 0 {
			lines[len(lines)-1].Words = strings.TrimSpace(lines[len(lines)-1].Words + "\n" + line)
			continue
		}

		matches := lrcPattern.FindStringSubmatch(line)
		if len(matches) == 5 {
			startMs := lrcTimestampToMs(matches[1], matches[2], matches[3])
			words := strings.TrimSpace(matches[4])
			if words == "" {
				continue
			}

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

func lyricsHasUsableText(lyrics *LyricsResponse) bool {
	if lyrics == nil {
		return false
	}
	if lyrics.Instrumental {
		return true
	}
	if strings.TrimSpace(lyrics.PlainLyrics) != "" {
		return true
	}
	for _, line := range lyrics.Lines {
		if strings.TrimSpace(line.Words) != "" {
			return true
		}
	}
	return false
}

// detectLyricsErrorPayload extracts human-readable error messages from
// JSON payloads returned by lyrics proxies when no lyric is available.
func detectLyricsErrorPayload(raw string) (string, bool) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" || !strings.HasPrefix(trimmed, "{") {
		return "", false
	}

	var payload map[string]interface{}
	if err := json.Unmarshal([]byte(trimmed), &payload); err != nil {
		return "", false
	}

	lyricsKeys := []string{"lyrics", "lyric", "lrc", "content", "lines", "syncedLyrics", "unsyncedLyrics"}
	hasLyricsKey := false
	for _, key := range lyricsKeys {
		if _, ok := payload[key]; ok {
			hasLyricsKey = true
			break
		}
	}

	errorKeys := []string{"message", "error", "detail", "reason"}
	for _, key := range errorKeys {
		if msg, ok := payload[key].(string); ok {
			msg = strings.TrimSpace(msg)
			if msg != "" && !hasLyricsKey {
				return msg, true
			}
		}
	}

	if success, ok := payload["success"].(bool); ok && !success && !hasLyricsKey {
		return "request unsuccessful", true
	}

	return "", false
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
	return fmt.Sprintf("[%s]", msToLRCTimestampInline(ms))
}

func msToLRCTimestampInline(ms int64) string {
	totalSeconds := ms / 1000
	minutes := totalSeconds / 60
	seconds := totalSeconds % 60
	centiseconds := (ms % 1000) / 10

	return fmt.Sprintf("%02d:%02d.%02d", minutes, seconds, centiseconds)
}

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
	result = strings.TrimSpace(result)
	if result == "" {
		return result
	}

	// Add a loose fallback form for provider queries where punctuation
	// and separators differ (e.g. "/" vs "_" vs spaces).
	if loose := normalizeLooseTitle(result); loose != "" {
		return loose
	}

	return result
}

func normalizeArtistName(name string) string {
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
