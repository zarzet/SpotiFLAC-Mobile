package gobackend

import (
	"context"
	"bufio"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// QobuzDownloader handles Qobuz downloads
type QobuzDownloader struct {
	client *http.Client
	appID  string
	apiURL string
}

var (
	globalQobuzDownloader *QobuzDownloader
	qobuzDownloaderOnce   sync.Once
)

// QobuzTrack represents a Qobuz track
type QobuzTrack struct {
	ID                  int64   `json:"id"`
	Title               string  `json:"title"`
	ISRC                string  `json:"isrc"`
	Duration            int     `json:"duration"`
	TrackNumber         int     `json:"track_number"`
	MaximumBitDepth     int     `json:"maximum_bit_depth"`
	MaximumSamplingRate float64 `json:"maximum_sampling_rate"`
	Album               struct {
		Title       string `json:"title"`
		ReleaseDate string `json:"release_date_original"`
		Image       struct {
			Large string `json:"large"`
		} `json:"image"`
	} `json:"album"`
	Performer struct {
		Name string `json:"name"`
	} `json:"performer"`
}

// qobuzArtistsMatch checks if the artist names are similar enough
func qobuzArtistsMatch(expectedArtist, foundArtist string) bool {
	normExpected := strings.ToLower(strings.TrimSpace(expectedArtist))
	normFound := strings.ToLower(strings.TrimSpace(foundArtist))

	// Exact match
	if normExpected == normFound {
		return true
	}

	// Check if one contains the other
	if strings.Contains(normExpected, normFound) || strings.Contains(normFound, normExpected) {
		return true
	}

	expectedArtists := qobuzSplitArtists(normExpected)
	foundArtists := qobuzSplitArtists(normFound)

	for _, exp := range expectedArtists {
		for _, fnd := range foundArtists {
			if exp == fnd {
				return true
			}
			if strings.Contains(exp, fnd) || strings.Contains(fnd, exp) {
				return true
			}
			if qobuzSameWordsUnordered(exp, fnd) {
				GoLog("[Qobuz] Artist names have same words in different order: '%s' vs '%s'\n", exp, fnd)
				return true
			}
		}
	}

	expectedLatin := qobuzIsLatinScript(expectedArtist)
	foundLatin := qobuzIsLatinScript(foundArtist)
	if expectedLatin != foundLatin {
		GoLog("[Qobuz] Artist names in different scripts, assuming match: '%s' vs '%s'\n", expectedArtist, foundArtist)
		return true
	}

	return false
}

// qobuzSplitArtists splits artist string by common separators
func qobuzSplitArtists(artists string) []string {
	// Replace common separators with a standard one
	normalized := artists
	normalized = strings.ReplaceAll(normalized, " feat. ", "|")
	normalized = strings.ReplaceAll(normalized, " feat ", "|")
	normalized = strings.ReplaceAll(normalized, " ft. ", "|")
	normalized = strings.ReplaceAll(normalized, " ft ", "|")
	normalized = strings.ReplaceAll(normalized, " & ", "|")
	normalized = strings.ReplaceAll(normalized, " and ", "|")
	normalized = strings.ReplaceAll(normalized, ", ", "|")
	normalized = strings.ReplaceAll(normalized, " x ", "|")

	parts := strings.Split(normalized, "|")
	result := make([]string, 0, len(parts))
	for _, p := range parts {
		trimmed := strings.TrimSpace(p)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

// qobuzSameWordsUnordered checks if two strings have the same words regardless of order
// Useful for Japanese names: "Sawano Hiroyuki" vs "Hiroyuki Sawano"
func qobuzSameWordsUnordered(a, b string) bool {
	wordsA := strings.Fields(a)
	wordsB := strings.Fields(b)

	// Must have same number of words
	if len(wordsA) != len(wordsB) || len(wordsA) == 0 {
		return false
	}

	// Sort and compare
	sortedA := make([]string, len(wordsA))
	sortedB := make([]string, len(wordsB))
	copy(sortedA, wordsA)
	copy(sortedB, wordsB)

	// Simple bubble sort (usually just 2-3 words)
	for i := 0; i < len(sortedA)-1; i++ {
		for j := i + 1; j < len(sortedA); j++ {
			if sortedA[i] > sortedA[j] {
				sortedA[i], sortedA[j] = sortedA[j], sortedA[i]
			}
			if sortedB[i] > sortedB[j] {
				sortedB[i], sortedB[j] = sortedB[j], sortedB[i]
			}
		}
	}

	for i := range sortedA {
		if sortedA[i] != sortedB[i] {
			return false
		}
	}
	return true
}

// qobuzTitlesMatch checks if track titles are similar enough
func qobuzTitlesMatch(expectedTitle, foundTitle string) bool {
	normExpected := strings.ToLower(strings.TrimSpace(expectedTitle))
	normFound := strings.ToLower(strings.TrimSpace(foundTitle))

	// Exact match
	if normExpected == normFound {
		return true
	}

	// Check if one contains the other
	if strings.Contains(normExpected, normFound) || strings.Contains(normFound, normExpected) {
		return true
	}

	// Clean BOTH titles and compare (removes suffixes like remaster, remix, etc)
	cleanExpected := qobuzCleanTitle(normExpected)
	cleanFound := qobuzCleanTitle(normFound)

	if cleanExpected == cleanFound {
		return true
	}

	// Check if cleaned versions contain each other
	if cleanExpected != "" && cleanFound != "" {
		if strings.Contains(cleanExpected, cleanFound) || strings.Contains(cleanFound, cleanExpected) {
			return true
		}
	}

	// Extract core title (before any parentheses/brackets)
	coreExpected := qobuzExtractCoreTitle(normExpected)
	coreFound := qobuzExtractCoreTitle(normFound)

	if coreExpected != "" && coreFound != "" && coreExpected == coreFound {
		return true
	}

	// If scripts are TRULY different (Latin vs CJK/Arabic/Cyrillic), assume match (transliteration)
	// Don't treat Latin Extended (Polish, French, etc.) as different script
	expectedLatin := qobuzIsLatinScript(expectedTitle)
	foundLatin := qobuzIsLatinScript(foundTitle)
	if expectedLatin != foundLatin {
		GoLog("[Qobuz] Titles in different scripts, assuming match: '%s' vs '%s'\n", expectedTitle, foundTitle)
		return true
	}

	return false
}

// qobuzExtractCoreTitle extracts the main title before any parentheses or brackets
func qobuzExtractCoreTitle(title string) string {
	// Find first occurrence of ( or [
	parenIdx := strings.Index(title, "(")
	bracketIdx := strings.Index(title, "[")
	dashIdx := strings.Index(title, " - ")

	cutIdx := len(title)
	if parenIdx > 0 && parenIdx < cutIdx {
		cutIdx = parenIdx
	}
	if bracketIdx > 0 && bracketIdx < cutIdx {
		cutIdx = bracketIdx
	}
	if dashIdx > 0 && dashIdx < cutIdx {
		cutIdx = dashIdx
	}

	return strings.TrimSpace(title[:cutIdx])
}

// qobuzCleanTitle removes common suffixes from track titles for comparison
func qobuzCleanTitle(title string) string {
	cleaned := title

	// Remove content in parentheses/brackets that are version indicators
	// This helps match "Song (Remastered)" with "Song" or "Song (2024 Remaster)"
	versionPatterns := []string{
		"remaster", "remastered", "deluxe", "bonus", "single",
		"album version", "radio edit", "original mix", "extended",
		"club mix", "remix", "live", "acoustic", "demo",
	}

	// Remove parenthetical content if it contains version indicators
	for {
		startParen := strings.LastIndex(cleaned, "(")
		endParen := strings.LastIndex(cleaned, ")")
		if startParen >= 0 && endParen > startParen {
			content := strings.ToLower(cleaned[startParen+1 : endParen])
			isVersionIndicator := false
			for _, pattern := range versionPatterns {
				if strings.Contains(content, pattern) {
					isVersionIndicator = true
					break
				}
			}
			if isVersionIndicator {
				cleaned = strings.TrimSpace(cleaned[:startParen]) + cleaned[endParen+1:]
				continue
			}
		}
		break
	}

	// Same for brackets
	for {
		startBracket := strings.LastIndex(cleaned, "[")
		endBracket := strings.LastIndex(cleaned, "]")
		if startBracket >= 0 && endBracket > startBracket {
			content := strings.ToLower(cleaned[startBracket+1 : endBracket])
			isVersionIndicator := false
			for _, pattern := range versionPatterns {
				if strings.Contains(content, pattern) {
					isVersionIndicator = true
					break
				}
			}
			if isVersionIndicator {
				cleaned = strings.TrimSpace(cleaned[:startBracket]) + cleaned[endBracket+1:]
				continue
			}
		}
		break
	}

	// Remove trailing " - version" patterns
	dashPatterns := []string{
		" - remaster", " - remastered", " - single version", " - radio edit",
		" - live", " - acoustic", " - demo", " - remix",
	}
	for _, pattern := range dashPatterns {
		if strings.HasSuffix(strings.ToLower(cleaned), pattern) {
			cleaned = cleaned[:len(cleaned)-len(pattern)]
		}
	}

	// Remove multiple spaces
	for strings.Contains(cleaned, "  ") {
		cleaned = strings.ReplaceAll(cleaned, "  ", " ")
	}

	return strings.TrimSpace(cleaned)
}

// qobuzIsLatinScript checks if a string is primarily Latin script
// Returns true for ASCII and Latin Extended characters (European languages)
// Returns false for CJK, Arabic, Cyrillic, etc.
func qobuzIsLatinScript(s string) bool {
	for _, r := range s {
		// Skip common punctuation and numbers
		if r < 128 {
			continue
		}
		// Latin Extended-A: U+0100 to U+017F (Polish, Czech, etc.)
		// Latin Extended-B: U+0180 to U+024F
		// Latin Extended Additional: U+1E00 to U+1EFF
		// Latin Extended-C/D/E: various ranges
		if (r >= 0x0100 && r <= 0x024F) || // Latin Extended A & B
			(r >= 0x1E00 && r <= 0x1EFF) || // Latin Extended Additional
			(r >= 0x00C0 && r <= 0x00FF) { // Latin-1 Supplement (accented chars)
			continue
		}
		// CJK ranges - definitely different script
		if (r >= 0x4E00 && r <= 0x9FFF) || // CJK Unified Ideographs
			(r >= 0x3040 && r <= 0x309F) || // Hiragana
			(r >= 0x30A0 && r <= 0x30FF) || // Katakana
			(r >= 0xAC00 && r <= 0xD7AF) || // Hangul (Korean)
			(r >= 0x0600 && r <= 0x06FF) || // Arabic
			(r >= 0x0400 && r <= 0x04FF) { // Cyrillic
			return false
		}
	}
	return true
}

// qobuzIsASCIIString checks if a string contains only ASCII characters
// Kept for potential future use
// func qobuzIsASCIIString(s string) bool {
// 	for _, r := range s {
// 		if r > 127 {
// 			return false
// 		}
// 	}
// 	return true
// }

// containsQueryQobuz checks if a query already exists in the list
func containsQueryQobuz(queries []string, query string) bool {
	for _, q := range queries {
		if q == query {
			return true
		}
	}
	return false
}

// NewQobuzDownloader creates a new Qobuz downloader (returns singleton for connection reuse)
func NewQobuzDownloader() *QobuzDownloader {
	qobuzDownloaderOnce.Do(func() {
		globalQobuzDownloader = &QobuzDownloader{
			client: NewHTTPClientWithTimeout(DefaultTimeout), // 60s timeout
			appID:  "798273057",
		}
	})
	return globalQobuzDownloader
}

// GetTrackByID fetches track info directly by Qobuz track ID
func (q *QobuzDownloader) GetTrackByID(trackID int64) (*QobuzTrack, error) {
	// Qobuz API: /track/get?track_id=XXX
	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly93d3cucW9idXouY29tL2FwaS5qc29uLzAuMi90cmFjay9nZXQ/dHJhY2tfaWQ9")
	trackURL := fmt.Sprintf("%s%d&app_id=%s", string(apiBase), trackID, q.appID)

	req, err := http.NewRequest("GET", trackURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("get track failed: HTTP %d", resp.StatusCode)
	}

	var track QobuzTrack
	if err := json.NewDecoder(resp.Body).Decode(&track); err != nil {
		return nil, err
	}

	return &track, nil
}

// GetAvailableAPIs returns list of available Qobuz APIs
// Uses same APIs as PC version for compatibility
func (q *QobuzDownloader) GetAvailableAPIs() []string {
	// Same APIs as PC version (referensi/backend/qobuz.go)
	// Primary: dab.yeet.su, Fallback: dabmusic.xyz
	encodedAPIs := []string{
		"ZGFiLnllZXQuc3UvYXBpL3N0cmVhbT90cmFja0lkPQ==", // dab.yeet.su/api/stream?trackId= (PRIMARY - same as PC)
		"ZGFibXVzaWMueHl6L2FwaS9zdHJlYW0/dHJhY2tJZD0=", // dabmusic.xyz/api/stream?trackId= (FALLBACK - same as PC)
	}

	var apis []string
	for _, encoded := range encodedAPIs {
		decoded, err := base64.StdEncoding.DecodeString(encoded)
		if err != nil {
			continue
		}
		apis = append(apis, "https://"+string(decoded))
	}

	return apis
}

// SearchTrackByISRC searches for a track by ISRC
func (q *QobuzDownloader) SearchTrackByISRC(isrc string) (*QobuzTrack, error) {
	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly93d3cucW9idXouY29tL2FwaS5qc29uLzAuMi90cmFjay9zZWFyY2g/cXVlcnk9")
	searchURL := fmt.Sprintf("%s%s&limit=50&app_id=%s", string(apiBase), url.QueryEscape(isrc), q.appID)

	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("search failed: HTTP %d", resp.StatusCode)
	}

	var result struct {
		Tracks struct {
			Items []QobuzTrack `json:"items"`
		} `json:"tracks"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	// Find exact ISRC match
	for i := range result.Tracks.Items {
		if result.Tracks.Items[i].ISRC == isrc {
			return &result.Tracks.Items[i], nil
		}
	}

	if len(result.Tracks.Items) == 0 {
		return nil, fmt.Errorf("no tracks found for ISRC: %s", isrc)
	}

	return nil, fmt.Errorf("no exact ISRC match found for: %s", isrc)
}

// SearchTrackByISRCWithTitle searches for a track by ISRC with duration verification
// expectedDurationSec is the expected duration in seconds (0 to skip verification)
func (q *QobuzDownloader) SearchTrackByISRCWithDuration(isrc string, expectedDurationSec int) (*QobuzTrack, error) {
	GoLog("[Qobuz] Searching by ISRC: %s\n", isrc)

	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly93d3cucW9idXouY29tL2FwaS5qc29uLzAuMi90cmFjay9zZWFyY2g/cXVlcnk9")
	searchURL := fmt.Sprintf("%s%s&limit=50&app_id=%s", string(apiBase), url.QueryEscape(isrc), q.appID)

	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("search failed: HTTP %d", resp.StatusCode)
	}

	var result struct {
		Tracks struct {
			Items []QobuzTrack `json:"items"`
		} `json:"tracks"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	GoLog("[Qobuz] ISRC search returned %d results\n", len(result.Tracks.Items))

	// Find ISRC matches
	var isrcMatches []*QobuzTrack
	for i := range result.Tracks.Items {
		if result.Tracks.Items[i].ISRC == isrc {
			isrcMatches = append(isrcMatches, &result.Tracks.Items[i])
		}
	}

	GoLog("[Qobuz] Found %d exact ISRC matches\n", len(isrcMatches))

	if len(isrcMatches) > 0 {
		// Verify duration if provided
		if expectedDurationSec > 0 {
			var durationVerifiedMatches []*QobuzTrack
			for _, track := range isrcMatches {
				durationDiff := track.Duration - expectedDurationSec
				if durationDiff < 0 {
					durationDiff = -durationDiff
				}
				// Allow 10 seconds tolerance
				if durationDiff <= 10 {
					durationVerifiedMatches = append(durationVerifiedMatches, track)
				}
			}

			if len(durationVerifiedMatches) > 0 {
				GoLog("[Qobuz] ISRC match with duration verification: '%s' (expected %ds, found %ds)\n",
					durationVerifiedMatches[0].Title, expectedDurationSec, durationVerifiedMatches[0].Duration)
				return durationVerifiedMatches[0], nil
			}

			// ISRC matches but duration doesn't
			GoLog("[Qobuz] WARNING: ISRC %s found but duration mismatch. Expected=%ds, Found=%ds. Rejecting.\n",
				isrc, expectedDurationSec, isrcMatches[0].Duration)
			return nil, fmt.Errorf("ISRC found but duration mismatch: expected %ds, found %ds (likely different version)",
				expectedDurationSec, isrcMatches[0].Duration)
		}

		// No duration to verify, return first match
		GoLog("[Qobuz] ISRC match (no duration verification): '%s'\n", isrcMatches[0].Title)
		return isrcMatches[0], nil
	}

	if len(result.Tracks.Items) == 0 {
		return nil, fmt.Errorf("no tracks found for ISRC: %s", isrc)
	}

	return nil, fmt.Errorf("no exact ISRC match found for: %s", isrc)
}

// SearchTrackByISRCWithTitle is deprecated, use SearchTrackByISRCWithDuration instead
func (q *QobuzDownloader) SearchTrackByISRCWithTitle(isrc, expectedTitle string) (*QobuzTrack, error) {
	return q.SearchTrackByISRCWithDuration(isrc, 0)
}

// SearchTrackByMetadata searches for a track using artist name and track name
func (q *QobuzDownloader) SearchTrackByMetadata(trackName, artistName string) (*QobuzTrack, error) {
	return q.SearchTrackByMetadataWithDuration(trackName, artistName, 0)
}

// SearchTrackByMetadataWithDuration searches for a track with duration verification
// Now includes romaji conversion for Japanese text (same as Tidal)
// Also includes title verification to prevent wrong song downloads
func (q *QobuzDownloader) SearchTrackByMetadataWithDuration(trackName, artistName string, expectedDurationSec int) (*QobuzTrack, error) {
	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly93d3cucW9idXouY29tL2FwaS5qc29uLzAuMi90cmFjay9zZWFyY2g/cXVlcnk9")

	// Try multiple search strategies (same as Tidal/PC version)
	queries := []string{}

	// Strategy 1: Artist + Track name
	if artistName != "" && trackName != "" {
		queries = append(queries, artistName+" "+trackName)
	}

	// Strategy 2: Track name only
	if trackName != "" {
		queries = append(queries, trackName)
	}

	// Strategy 3: Romaji versions if Japanese detected
	if ContainsJapanese(trackName) || ContainsJapanese(artistName) {
		// Convert to romaji (hiragana/katakana only, kanji stays)
		romajiTrack := JapaneseToRomaji(trackName)
		romajiArtist := JapaneseToRomaji(artistName)

		// Clean and remove ALL non-ASCII characters (including kanji)
		cleanRomajiTrack := CleanToASCII(romajiTrack)
		cleanRomajiArtist := CleanToASCII(romajiArtist)

		// Artist + Track romaji (cleaned to ASCII only)
		if cleanRomajiArtist != "" && cleanRomajiTrack != "" {
			romajiQuery := cleanRomajiArtist + " " + cleanRomajiTrack
			if !containsQueryQobuz(queries, romajiQuery) {
				queries = append(queries, romajiQuery)
				GoLog("[Qobuz] Japanese detected, adding romaji query: %s\n", romajiQuery)
			}
		}

		// Track romaji only (cleaned)
		if cleanRomajiTrack != "" && cleanRomajiTrack != trackName {
			if !containsQueryQobuz(queries, cleanRomajiTrack) {
				queries = append(queries, cleanRomajiTrack)
			}
		}
	}

	// Strategy 4: Artist only as last resort
	if artistName != "" {
		artistOnly := CleanToASCII(JapaneseToRomaji(artistName))
		if artistOnly != "" && !containsQueryQobuz(queries, artistOnly) {
			queries = append(queries, artistOnly)
		}
	}

	var allTracks []QobuzTrack
	searchedQueries := make(map[string]bool)

	for _, query := range queries {
		cleanQuery := strings.TrimSpace(query)
		if cleanQuery == "" || searchedQueries[cleanQuery] {
			continue
		}
		searchedQueries[cleanQuery] = true

		GoLog("[Qobuz] Searching for: %s\n", cleanQuery)

		searchURL := fmt.Sprintf("%s%s&limit=50&app_id=%s", string(apiBase), url.QueryEscape(cleanQuery), q.appID)

		req, err := http.NewRequest("GET", searchURL, nil)
		if err != nil {
			continue
		}

		resp, err := DoRequestWithUserAgent(q.client, req)
		if err != nil {
			GoLog("[Qobuz] Search error for '%s': %v\n", cleanQuery, err)
			continue
		}

		if resp.StatusCode != 200 {
			resp.Body.Close()
			continue
		}

		var result struct {
			Tracks struct {
				Items []QobuzTrack `json:"items"`
			} `json:"tracks"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			resp.Body.Close()
			continue
		}
		resp.Body.Close()

		if len(result.Tracks.Items) > 0 {
			GoLog("[Qobuz] Found %d results for '%s'\n", len(result.Tracks.Items), cleanQuery)
			allTracks = append(allTracks, result.Tracks.Items...)
		}
	}

	if len(allTracks) == 0 {
		return nil, fmt.Errorf("no tracks found for: %s - %s", artistName, trackName)
	}

	// Filter by title match first (NEW - like Tidal)
	var titleMatches []*QobuzTrack
	for i := range allTracks {
		track := &allTracks[i]
		if qobuzTitlesMatch(trackName, track.Title) {
			titleMatches = append(titleMatches, track)
		}
	}

	GoLog("[Qobuz] Title matches: %d out of %d results\n", len(titleMatches), len(allTracks))

	// If no title matches, log warning but continue with all tracks
	tracksToCheck := titleMatches
	if len(titleMatches) == 0 {
		GoLog("[Qobuz] WARNING: No title matches for '%s', checking all %d results\n", trackName, len(allTracks))
		for i := range allTracks {
			tracksToCheck = append(tracksToCheck, &allTracks[i])
		}
	}

	// If duration verification is requested
	if expectedDurationSec > 0 {
		var durationMatches []*QobuzTrack
		for _, track := range tracksToCheck {
			durationDiff := track.Duration - expectedDurationSec
			if durationDiff < 0 {
				durationDiff = -durationDiff
			}
			if durationDiff <= 10 {
				durationMatches = append(durationMatches, track)
			}
		}

		if len(durationMatches) > 0 {
			// Return best quality among duration matches
			for _, track := range durationMatches {
				if track.MaximumBitDepth >= 24 {
					GoLog("[Qobuz] ✓ Match found: '%s' by '%s' (title+duration verified, hi-res)\n",
						track.Title, track.Performer.Name)
					return track, nil
				}
			}
			GoLog("[Qobuz] ✓ Match found: '%s' by '%s' (title+duration verified)\n",
				durationMatches[0].Title, durationMatches[0].Performer.Name)
			return durationMatches[0], nil
		}

		// No duration match found
		return nil, fmt.Errorf("no tracks found with matching title and duration (expected '%s', %ds)", trackName, expectedDurationSec)
	}

	// No duration verification, return best quality from title matches
	for _, track := range tracksToCheck {
		if track.MaximumBitDepth >= 24 {
			GoLog("[Qobuz] ✓ Match found: '%s' by '%s' (title verified, hi-res)\n",
				track.Title, track.Performer.Name)
			return track, nil
		}
	}

	if len(tracksToCheck) > 0 {
		GoLog("[Qobuz] ✓ Match found: '%s' by '%s' (title verified)\n",
			tracksToCheck[0].Title, tracksToCheck[0].Performer.Name)
		return tracksToCheck[0], nil
	}

	return nil, fmt.Errorf("no matching track found for: %s - %s", artistName, trackName)
}

// qobuzAPIResult holds the result from a parallel API request
type qobuzAPIResult struct {
	apiURL      string
	downloadURL string
	err         error
	duration    time.Duration
}

// getQobuzDownloadURLParallel requests download URL from all APIs in parallel
// "Siapa cepat dia dapat" - first successful response wins
func getQobuzDownloadURLParallel(apis []string, trackID int64, quality string) (string, string, error) {
	if len(apis) == 0 {
		return "", "", fmt.Errorf("no APIs available")
	}

	GoLog("[Qobuz] Requesting download URL from %d APIs in parallel...\n", len(apis))

	resultChan := make(chan qobuzAPIResult, len(apis))
	startTime := time.Now()

	// Start all requests in parallel
	for _, apiURL := range apis {
		go func(api string) {
			reqStart := time.Now()

			client := &http.Client{
				Timeout: 15 * time.Second,
			}

			reqURL := fmt.Sprintf("%s%d&quality=%s", api, trackID, quality)

			req, err := http.NewRequest("GET", reqURL, nil)
			if err != nil {
				resultChan <- qobuzAPIResult{apiURL: api, err: err, duration: time.Since(reqStart)}
				return
			}

			resp, err := client.Do(req)
			if err != nil {
				resultChan <- qobuzAPIResult{apiURL: api, err: err, duration: time.Since(reqStart)}
				return
			}
			defer resp.Body.Close()

			if resp.StatusCode != 200 {
				resultChan <- qobuzAPIResult{apiURL: api, err: fmt.Errorf("HTTP %d", resp.StatusCode), duration: time.Since(reqStart)}
				return
			}

			body, err := io.ReadAll(resp.Body)
			if err != nil {
				resultChan <- qobuzAPIResult{apiURL: api, err: err, duration: time.Since(reqStart)}
				return
			}

			// Check if response is HTML (error page)
			if len(body) > 0 && body[0] == '<' {
				resultChan <- qobuzAPIResult{apiURL: api, err: fmt.Errorf("received HTML instead of JSON"), duration: time.Since(reqStart)}
				return
			}

			// Check for error in JSON response
			var errorResp struct {
				Error string `json:"error"`
			}
			if json.Unmarshal(body, &errorResp) == nil && errorResp.Error != "" {
				resultChan <- qobuzAPIResult{apiURL: api, err: fmt.Errorf("%s", errorResp.Error), duration: time.Since(reqStart)}
				return
			}

			var result struct {
				URL string `json:"url"`
			}
			if err := json.Unmarshal(body, &result); err != nil {
				resultChan <- qobuzAPIResult{apiURL: api, err: fmt.Errorf("invalid JSON: %v", err), duration: time.Since(reqStart)}
				return
			}

			if result.URL != "" {
				resultChan <- qobuzAPIResult{apiURL: api, downloadURL: result.URL, err: nil, duration: time.Since(reqStart)}
				return
			}

			resultChan <- qobuzAPIResult{apiURL: api, err: fmt.Errorf("no download URL in response"), duration: time.Since(reqStart)}
		}(apiURL)
	}

	// Collect results - return first success
	var errors []string

	for i := 0; i < len(apis); i++ {
		result := <-resultChan
		if result.err == nil {
			GoLog("[Qobuz] [Parallel] ✓ Got response from %s in %v\n", result.apiURL, result.duration)

			// Drain remaining results to avoid goroutine leaks
			go func(remaining int) {
				for j := 0; j < remaining; j++ {
					<-resultChan
				}
			}(len(apis) - i - 1)

			GoLog("[Qobuz] [Parallel] Total time: %v (first success)\n", time.Since(startTime))
			return result.apiURL, result.downloadURL, nil
		}
		errMsg := result.err.Error()
		if len(errMsg) > 50 {
			errMsg = errMsg[:50] + "..."
		}
		errors = append(errors, fmt.Sprintf("%s: %s", result.apiURL, errMsg))
	}

	GoLog("[Qobuz] [Parallel] All %d APIs failed in %v\n", len(apis), time.Since(startTime))
	return "", "", fmt.Errorf("all %d Qobuz APIs failed. Errors: %v", len(apis), errors)
}

// GetDownloadURL gets download URL for a track - tries ALL APIs in parallel
// "Siapa cepat dia dapat" - first successful response wins
func (q *QobuzDownloader) GetDownloadURL(trackID int64, quality string) (string, error) {
	apis := q.GetAvailableAPIs()
	if len(apis) == 0 {
		return "", fmt.Errorf("no Qobuz API available")
	}

	_, downloadURL, err := getQobuzDownloadURLParallel(apis, trackID, quality)
	if err != nil {
		return "", err
	}

	return downloadURL, nil
}

// DownloadFile downloads a file from URL with User-Agent and progress tracking
func (q *QobuzDownloader) DownloadFile(downloadURL, outputPath, itemID string) error {
	ctx := context.Background()

	// Initialize item progress (required for all downloads)
	if itemID != "" {
		StartItemProgress(itemID)
		defer CompleteItemProgress(itemID)
		ctx = initDownloadCancel(itemID)
		defer clearDownloadCancel(itemID)
	}

	if isDownloadCancelled(itemID) {
		return ErrDownloadCancelled
	}

	req, err := http.NewRequestWithContext(ctx, "GET", downloadURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("download failed: HTTP %d", resp.StatusCode)
	}

	expectedSize := resp.ContentLength
	if expectedSize > 0 && itemID != "" {
		SetItemBytesTotal(itemID, expectedSize)
	}

	out, err := os.Create(outputPath)
	if err != nil {
		return err
	}

	bufWriter := bufio.NewWriterSize(out, 256*1024)

	var written int64
	if itemID != "" {
		progressWriter := NewItemProgressWriter(bufWriter, itemID)
		written, err = io.Copy(progressWriter, resp.Body)
	} else {
		written, err = io.Copy(bufWriter, resp.Body)
	}

	// Flush buffer before checking for errors
	flushErr := bufWriter.Flush()
	closeErr := out.Close()

	if err != nil {
		os.Remove(outputPath)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return fmt.Errorf("download interrupted: %w", err)
	}
	if flushErr != nil {
		os.Remove(outputPath)
		return fmt.Errorf("failed to flush buffer: %w", flushErr)
	}
	if closeErr != nil {
		os.Remove(outputPath)
		return fmt.Errorf("failed to close file: %w", closeErr)
	}

	// Verify file size if Content-Length was provided
	if expectedSize > 0 && written != expectedSize {
		os.Remove(outputPath)
		return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
	}

	return nil
}

// QobuzDownloadResult contains download result with quality info
type QobuzDownloadResult struct {
	FilePath    string
	BitDepth    int
	SampleRate  int
	Title       string
	Artist      string
	Album       string
	ReleaseDate string
	TrackNumber int
	DiscNumber  int
	ISRC        string
}

// downloadFromQobuz downloads a track using the request parameters
func downloadFromQobuz(req DownloadRequest) (QobuzDownloadResult, error) {
	downloader := NewQobuzDownloader()

	if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
		return QobuzDownloadResult{FilePath: "EXISTS:" + existingFile}, nil
	}

	expectedDurationSec := req.DurationMS / 1000

	var track *QobuzTrack
	var err error

	if req.QobuzID != "" {
		GoLog("[Qobuz] Using Qobuz ID from Odesli enrichment: %s\n", req.QobuzID)
		var trackID int64
		if _, parseErr := fmt.Sscanf(req.QobuzID, "%d", &trackID); parseErr == nil && trackID > 0 {
			track, err = downloader.GetTrackByID(trackID)
			if err != nil {
				GoLog("[Qobuz] Failed to get track by Odesli ID %d: %v\n", trackID, err)
				track = nil
			} else if track != nil {
				GoLog("[Qobuz] Successfully found track via Odesli ID: '%s' by '%s'\n", track.Title, track.Performer.Name)
			}
		}
	}

	// OPTIMIZATION: Check cache first for track ID
	if track == nil && req.ISRC != "" {
		if cached := GetTrackIDCache().Get(req.ISRC); cached != nil && cached.QobuzTrackID > 0 {
			GoLog("[Qobuz] Cache hit! Using cached track ID: %d\n", cached.QobuzTrackID)
			// For Qobuz we need to search again to get full track info, but we can use the ID
			track, err = downloader.SearchTrackByISRC(req.ISRC)
			if err != nil {
				GoLog("[Qobuz] Cache hit but search failed: %v\n", err)
				track = nil
			}
		}
	}

	// Strategy 1: Search by ISRC with duration verification
	if track == nil && req.ISRC != "" {
		GoLog("[Qobuz] Trying ISRC search: %s\n", req.ISRC)
		track, err = downloader.SearchTrackByISRCWithDuration(req.ISRC, expectedDurationSec)
		// Verify artist AND title
		if track != nil {
			if !qobuzArtistsMatch(req.ArtistName, track.Performer.Name) {
				GoLog("[Qobuz] Artist mismatch from ISRC search: expected '%s', got '%s'. Rejecting.\n",
					req.ArtistName, track.Performer.Name)
				track = nil
			} else if !qobuzTitlesMatch(req.TrackName, track.Title) {
				GoLog("[Qobuz] Title mismatch from ISRC search: expected '%s', got '%s'. Rejecting.\n",
					req.TrackName, track.Title)
				track = nil
			}
		}
	}

	// Strategy 2: Search by metadata with duration verification (includes title verification)
	if track == nil {
		track, err = downloader.SearchTrackByMetadataWithDuration(req.TrackName, req.ArtistName, expectedDurationSec)
		// Verify artist (title already verified in SearchTrackByMetadataWithDuration)
		if track != nil && !qobuzArtistsMatch(req.ArtistName, track.Performer.Name) {
			GoLog("[Qobuz] Artist mismatch from metadata search: expected '%s', got '%s'. Rejecting.\n",
				req.ArtistName, track.Performer.Name)
			track = nil
		}
	}

	if track == nil {
		errMsg := "could not find matching track on Qobuz (artist/duration mismatch)"
		if err != nil {
			errMsg = err.Error()
		}
		return QobuzDownloadResult{}, fmt.Errorf("qobuz search failed: %s", errMsg)
	}

	// Log match found and cache the track ID
	GoLog("[Qobuz] Match found: '%s' by '%s' (duration: %ds)\n", track.Title, track.Performer.Name, track.Duration)
	if req.ISRC != "" {
		GetTrackIDCache().SetQobuz(req.ISRC, track.ID)
	}

	filename := buildFilenameFromTemplate(req.FilenameFormat, map[string]interface{}{
		"title":  req.TrackName,
		"artist": req.ArtistName,
		"album":  req.AlbumName,
		"track":  req.TrackNumber,
		"year":   extractYear(req.ReleaseDate),
		"disc":   req.DiscNumber,
	})
	filename = sanitizeFilename(filename) + ".flac"
	outputPath := filepath.Join(req.OutputDir, filename)

	if fileInfo, statErr := os.Stat(outputPath); statErr == nil && fileInfo.Size() > 0 {
		return QobuzDownloadResult{FilePath: "EXISTS:" + outputPath}, nil
	}

	// Map quality from Tidal format to Qobuz format
	// Tidal: LOSSLESS (16-bit), HI_RES (24-bit), HI_RES_LOSSLESS (24-bit hi-res)
	// Qobuz: 5 (MP3 320), 6 (16-bit), 7 (24-bit 96kHz), 27 (24-bit 192kHz)
	qobuzQuality := "27" // Default to highest quality
	switch req.Quality {
	case "LOSSLESS":
		qobuzQuality = "6" // 16-bit FLAC
	case "HI_RES":
		qobuzQuality = "7" // 24-bit 96kHz
	case "HI_RES_LOSSLESS":
		qobuzQuality = "27" // 24-bit 192kHz
	}
	GoLog("[Qobuz] Using quality: %s (mapped from %s)\n", qobuzQuality, req.Quality)

	actualBitDepth := track.MaximumBitDepth
	actualSampleRate := int(track.MaximumSamplingRate * 1000) // Convert kHz to Hz
	GoLog("[Qobuz] Actual quality: %d-bit/%.1fkHz\n", actualBitDepth, track.MaximumSamplingRate)

	downloadURL, err := downloader.GetDownloadURL(track.ID, qobuzQuality)
	if err != nil {
		return QobuzDownloadResult{}, fmt.Errorf("failed to get download URL: %w", err)
	}

	// START PARALLEL: Fetch cover and lyrics while downloading audio
	var parallelResult *ParallelDownloadResult
	parallelDone := make(chan struct{})
	go func() {
		defer close(parallelDone)
		parallelResult = FetchCoverAndLyricsParallel(
			req.CoverURL,
			req.EmbedMaxQualityCover,
			req.SpotifyID,
			req.TrackName,
			req.ArtistName,
			req.EmbedLyrics,
		)
	}()

	// Download audio file with item ID for progress tracking
	if err := downloader.DownloadFile(downloadURL, outputPath, req.ItemID); err != nil {
		if errors.Is(err, ErrDownloadCancelled) {
			return QobuzDownloadResult{}, ErrDownloadCancelled
		}
		return QobuzDownloadResult{}, fmt.Errorf("download failed: %w", err)
	}

	// Wait for parallel operations to complete
	<-parallelDone

	if req.ItemID != "" {
		SetItemProgress(req.ItemID, 1.0, 0, 0)
		SetItemFinalizing(req.ItemID)
	}

	albumName := track.Album.Title
	if req.AlbumName != "" {
		albumName = req.AlbumName
	}

	metadata := Metadata{
		Title:       track.Title,
		Artist:      track.Performer.Name,
		Album:       albumName,
		AlbumArtist: req.AlbumArtist, // Qobuz track struct might not have this handy, keep req or check album struct
		Date:        track.Album.ReleaseDate,
		TrackNumber: track.TrackNumber,
		TotalTracks: req.TotalTracks,
		DiscNumber:  req.DiscNumber, // QobuzTrack struct usually doesn't have disc info in simple search result
		ISRC:        track.ISRC,
	}

	var coverData []byte
	if parallelResult != nil && parallelResult.CoverData != nil {
		coverData = parallelResult.CoverData
		GoLog("[Qobuz] Using parallel-fetched cover (%d bytes)\n", len(coverData))
	}

	if err := EmbedMetadataWithCoverData(outputPath, metadata, coverData); err != nil {
		fmt.Printf("Warning: failed to embed metadata: %v\n", err)
	}

	// Embed lyrics from parallel fetch
	if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
		GoLog("[Qobuz] Embedding parallel-fetched lyrics (%d lines)...\n", len(parallelResult.LyricsData.Lines))
		if embedErr := EmbedLyrics(outputPath, parallelResult.LyricsLRC); embedErr != nil {
			GoLog("[Qobuz] Warning: failed to embed lyrics: %v\n", embedErr)
		} else {
			fmt.Println("[Qobuz] Lyrics embedded successfully")
		}
	} else if req.EmbedLyrics {
		fmt.Println("[Qobuz] No lyrics available from parallel fetch")
	}

	// Add to ISRC index for fast duplicate checking
	AddToISRCIndex(req.OutputDir, req.ISRC, outputPath)

	return QobuzDownloadResult{
		FilePath:    outputPath,
		BitDepth:    actualBitDepth,
		SampleRate:  actualSampleRate,
		Title:       track.Title,
		Artist:      track.Performer.Name,
		Album:       track.Album.Title,
		ReleaseDate: track.Album.ReleaseDate,
		TrackNumber: track.TrackNumber,
		DiscNumber:  req.DiscNumber, // Qobuz track struct limitations
		ISRC:        track.ISRC,
	}, nil
}
