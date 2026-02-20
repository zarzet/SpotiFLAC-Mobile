package gobackend

import (
	"bufio"
	"context"
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

type QobuzDownloader struct {
	client *http.Client
	appID  string
	apiURL string
}

var (
	globalQobuzDownloader *QobuzDownloader
	qobuzDownloaderOnce   sync.Once
)

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

func qobuzArtistsMatch(expectedArtist, foundArtist string) bool {
	normExpected := strings.ToLower(strings.TrimSpace(expectedArtist))
	normFound := strings.ToLower(strings.TrimSpace(foundArtist))

	if normExpected == normFound {
		return true
	}

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

func qobuzSplitArtists(artists string) []string {
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

func qobuzSameWordsUnordered(a, b string) bool {
	wordsA := strings.Fields(a)
	wordsB := strings.Fields(b)

	if len(wordsA) != len(wordsB) || len(wordsA) == 0 {
		return false
	}

	sortedA := make([]string, len(wordsA))
	sortedB := make([]string, len(wordsB))
	copy(sortedA, wordsA)
	copy(sortedB, wordsB)

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

func qobuzTitlesMatch(expectedTitle, foundTitle string) bool {
	normExpected := strings.ToLower(strings.TrimSpace(expectedTitle))
	normFound := strings.ToLower(strings.TrimSpace(foundTitle))

	if normExpected == normFound {
		return true
	}

	if strings.Contains(normExpected, normFound) || strings.Contains(normFound, normExpected) {
		return true
	}

	cleanExpected := qobuzCleanTitle(normExpected)
	cleanFound := qobuzCleanTitle(normFound)

	if cleanExpected == cleanFound {
		return true
	}

	if cleanExpected != "" && cleanFound != "" {
		if strings.Contains(cleanExpected, cleanFound) || strings.Contains(cleanFound, cleanExpected) {
			return true
		}
	}

	coreExpected := qobuzExtractCoreTitle(normExpected)
	coreFound := qobuzExtractCoreTitle(normFound)

	if coreExpected != "" && coreFound != "" && coreExpected == coreFound {
		return true
	}

	looseExpected := normalizeLooseTitle(normExpected)
	looseFound := normalizeLooseTitle(normFound)
	if looseExpected != "" && looseFound != "" {
		if looseExpected == looseFound {
			return true
		}
		if strings.Contains(looseExpected, looseFound) || strings.Contains(looseFound, looseExpected) {
			return true
		}
	}

	// Some tracks are symbol/emoji-heavy and providers can return textual
	// aliases. If artist/duration already matched upstream, avoid false rejects.
	if (!hasAlphaNumericRunes(expectedTitle) || !hasAlphaNumericRunes(foundTitle)) &&
		strings.TrimSpace(expectedTitle) != "" &&
		strings.TrimSpace(foundTitle) != "" {
		GoLog("[Qobuz] Symbol-heavy title detected, relaxing match: '%s' vs '%s'\n", expectedTitle, foundTitle)
		return true
	}

	expectedLatin := qobuzIsLatinScript(expectedTitle)
	foundLatin := qobuzIsLatinScript(foundTitle)
	if expectedLatin != foundLatin {
		GoLog("[Qobuz] Titles in different scripts, assuming match: '%s' vs '%s'\n", expectedTitle, foundTitle)
		return true
	}

	return false
}

func qobuzExtractCoreTitle(title string) string {
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

func qobuzCleanTitle(title string) string {
	cleaned := title

	versionPatterns := []string{
		"remaster", "remastered", "deluxe", "bonus", "single",
		"album version", "radio edit", "original mix", "extended",
		"club mix", "remix", "live", "acoustic", "demo",
	}

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

	dashPatterns := []string{
		" - remaster", " - remastered", " - single version", " - radio edit",
		" - live", " - acoustic", " - demo", " - remix",
	}
	for _, pattern := range dashPatterns {
		if strings.HasSuffix(strings.ToLower(cleaned), pattern) {
			cleaned = cleaned[:len(cleaned)-len(pattern)]
		}
	}

	for strings.Contains(cleaned, "  ") {
		cleaned = strings.ReplaceAll(cleaned, "  ", " ")
	}

	return strings.TrimSpace(cleaned)
}

func qobuzIsLatinScript(s string) bool {
	for _, r := range s {
		if r < 128 {
			continue
		}
		if (r >= 0x0100 && r <= 0x024F) ||
			(r >= 0x1E00 && r <= 0x1EFF) ||
			(r >= 0x00C0 && r <= 0x00FF) {
			continue
		}
		if (r >= 0x4E00 && r <= 0x9FFF) ||
			(r >= 0x3040 && r <= 0x309F) ||
			(r >= 0x30A0 && r <= 0x30FF) ||
			(r >= 0xAC00 && r <= 0xD7AF) ||
			(r >= 0x0600 && r <= 0x06FF) ||
			(r >= 0x0400 && r <= 0x04FF) {
			return false
		}
	}
	return true
}

func containsQueryQobuz(queries []string, query string) bool {
	for _, q := range queries {
		if q == query {
			return true
		}
	}
	return false
}

func NewQobuzDownloader() *QobuzDownloader {
	qobuzDownloaderOnce.Do(func() {
		globalQobuzDownloader = &QobuzDownloader{
			client: NewHTTPClientWithTimeout(DefaultTimeout),
			appID:  "798273057",
		}
	})
	return globalQobuzDownloader
}

func (q *QobuzDownloader) GetTrackByID(trackID int64) (*QobuzTrack, error) {
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

func (q *QobuzDownloader) GetAvailableAPIs() []string {
	encodedAPIs := []string{
		"ZGFiLnllZXQuc3UvYXBpL3N0cmVhbT90cmFja0lkPQ==",
		"ZGFibXVzaWMueHl6L2FwaS9zdHJlYW0/dHJhY2tJZD0=",
		"cW9idXouc3F1aWQud3RmL2FwaS9kb3dubG9hZC1tdXNpYz90cmFja19pZD0=",
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

func mapJumoQuality(quality string) int {
	switch quality {
	case "6":
		return 6
	case "7":
		return 7
	case "27":
		return 27
	default:
		return 6
	}
}

func decodeXOR(data []byte) string {
	text := string(data)
	runes := []rune(text)
	result := make([]rune, len(runes))
	for i, char := range runes {
		key := rune((i * 17) % 128)
		result[i] = char ^ 253 ^ key
	}
	return string(result)
}

func extractQobuzDownloadURLFromBody(body []byte) (string, error) {
	var raw map[string]any
	if err := json.Unmarshal(body, &raw); err != nil {
		return "", fmt.Errorf("invalid JSON: %v", err)
	}

	if errMsg, ok := raw["error"].(string); ok && strings.TrimSpace(errMsg) != "" {
		return "", fmt.Errorf("%s", errMsg)
	}

	if success, ok := raw["success"].(bool); ok && !success {
		if msg, ok := raw["message"].(string); ok && strings.TrimSpace(msg) != "" {
			return "", fmt.Errorf("%s", msg)
		}
		return "", fmt.Errorf("api returned success=false")
	}

	if urlVal, ok := raw["url"].(string); ok && strings.TrimSpace(urlVal) != "" {
		return strings.TrimSpace(urlVal), nil
	}
	if linkVal, ok := raw["link"].(string); ok && strings.TrimSpace(linkVal) != "" {
		return strings.TrimSpace(linkVal), nil
	}

	if data, ok := raw["data"].(map[string]any); ok {
		if urlVal, ok := data["url"].(string); ok && strings.TrimSpace(urlVal) != "" {
			return strings.TrimSpace(urlVal), nil
		}
		if linkVal, ok := data["link"].(string); ok && strings.TrimSpace(linkVal) != "" {
			return strings.TrimSpace(linkVal), nil
		}
	}

	return "", fmt.Errorf("no download URL in response")
}

func (q *QobuzDownloader) downloadFromJumo(trackID int64, quality string) (string, error) {
	formatID := mapJumoQuality(quality)
	region := "US"
	jumoURL := fmt.Sprintf("https://jumo-dl.pages.dev/get?track_id=%d&format_id=%d&region=%s", trackID, formatID, region)

	GoLog("[Qobuz] Trying Jumo API fallback...\n")

	client := NewHTTPClientWithTimeout(30 * time.Second)
	req, err := http.NewRequest("GET", jumoURL, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", getRandomUserAgent())
	req.Header.Set("Referer", "https://jumo-dl.pages.dev/")

	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("Jumo API returned HTTP %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	var result map[string]any
	if err := json.Unmarshal(body, &result); err != nil {
		decoded := decodeXOR(body)
		if err := json.Unmarshal([]byte(decoded), &result); err != nil {
			return "", fmt.Errorf("failed to parse Jumo response (plain or XOR): %w", err)
		}
	}

	if urlVal, ok := result["url"].(string); ok && urlVal != "" {
		GoLog("[Qobuz] Jumo API returned URL successfully\n")
		return urlVal, nil
	}

	if data, ok := result["data"].(map[string]any); ok {
		if urlVal, ok := data["url"].(string); ok && urlVal != "" {
			GoLog("[Qobuz] Jumo API returned URL successfully (from data)\n")
			return urlVal, nil
		}
	}

	if linkVal, ok := result["link"].(string); ok && linkVal != "" {
		GoLog("[Qobuz] Jumo API returned URL successfully (from link)\n")
		return linkVal, nil
	}

	return "", fmt.Errorf("URL not found in Jumo response")
}

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

	var isrcMatches []*QobuzTrack
	for i := range result.Tracks.Items {
		if result.Tracks.Items[i].ISRC == isrc {
			isrcMatches = append(isrcMatches, &result.Tracks.Items[i])
		}
	}

	GoLog("[Qobuz] Found %d exact ISRC matches\n", len(isrcMatches))

	if len(isrcMatches) > 0 {
		if expectedDurationSec > 0 {
			var durationVerifiedMatches []*QobuzTrack
			for _, track := range isrcMatches {
				durationDiff := track.Duration - expectedDurationSec
				if durationDiff < 0 {
					durationDiff = -durationDiff
				}
				if durationDiff <= 10 {
					durationVerifiedMatches = append(durationVerifiedMatches, track)
				}
			}

			if len(durationVerifiedMatches) > 0 {
				GoLog("[Qobuz] ISRC match with duration verification: '%s' (expected %ds, found %ds)\n",
					durationVerifiedMatches[0].Title, expectedDurationSec, durationVerifiedMatches[0].Duration)
				return durationVerifiedMatches[0], nil
			}

			GoLog("[Qobuz] WARNING: ISRC %s found but duration mismatch. Expected=%ds, Found=%ds. Rejecting.\n",
				isrc, expectedDurationSec, isrcMatches[0].Duration)
			return nil, fmt.Errorf("ISRC found but duration mismatch: expected %ds, found %ds (likely different version)",
				expectedDurationSec, isrcMatches[0].Duration)
		}

		GoLog("[Qobuz] ISRC match (no duration verification): '%s'\n", isrcMatches[0].Title)
		return isrcMatches[0], nil
	}

	if len(result.Tracks.Items) == 0 {
		return nil, fmt.Errorf("no tracks found for ISRC: %s", isrc)
	}

	return nil, fmt.Errorf("no exact ISRC match found for: %s", isrc)
}

func (q *QobuzDownloader) SearchTrackByISRCWithTitle(isrc, expectedTitle string) (*QobuzTrack, error) {
	return q.SearchTrackByISRCWithDuration(isrc, 0)
}

func (q *QobuzDownloader) SearchTrackByMetadata(trackName, artistName string) (*QobuzTrack, error) {
	return q.SearchTrackByMetadataWithDuration(trackName, artistName, 0)
}

func (q *QobuzDownloader) SearchTrackByMetadataWithDuration(trackName, artistName string, expectedDurationSec int) (*QobuzTrack, error) {
	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly93d3cucW9idXouY29tL2FwaS5qc29uLzAuMi90cmFjay9zZWFyY2g/cXVlcnk9")

	queries := []string{}

	if artistName != "" && trackName != "" {
		queries = append(queries, artistName+" "+trackName)
	}

	if trackName != "" {
		queries = append(queries, trackName)
	}

	if ContainsJapanese(trackName) || ContainsJapanese(artistName) {
		romajiTrack := JapaneseToRomaji(trackName)
		romajiArtist := JapaneseToRomaji(artistName)

		cleanRomajiTrack := CleanToASCII(romajiTrack)
		cleanRomajiArtist := CleanToASCII(romajiArtist)

		if cleanRomajiArtist != "" && cleanRomajiTrack != "" {
			romajiQuery := cleanRomajiArtist + " " + cleanRomajiTrack
			if !containsQueryQobuz(queries, romajiQuery) {
				queries = append(queries, romajiQuery)
				GoLog("[Qobuz] Japanese detected, adding romaji query: %s\n", romajiQuery)
			}
		}

		if cleanRomajiTrack != "" && cleanRomajiTrack != trackName {
			if !containsQueryQobuz(queries, cleanRomajiTrack) {
				queries = append(queries, cleanRomajiTrack)
			}
		}
	}

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

	var titleMatches []*QobuzTrack
	for i := range allTracks {
		track := &allTracks[i]
		if qobuzTitlesMatch(trackName, track.Title) {
			titleMatches = append(titleMatches, track)
		}
	}

	GoLog("[Qobuz] Title matches: %d out of %d results\n", len(titleMatches), len(allTracks))

	tracksToCheck := titleMatches
	if len(titleMatches) == 0 {
		GoLog("[Qobuz] WARNING: No title matches for '%s', checking all %d results\n", trackName, len(allTracks))
		for i := range allTracks {
			tracksToCheck = append(tracksToCheck, &allTracks[i])
		}
	}

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
			for _, track := range durationMatches {
				if track.MaximumBitDepth >= 24 {
					GoLog("[Qobuz] Match found: '%s' by '%s' (title+duration verified, hi-res)\n",
						track.Title, track.Performer.Name)
					return track, nil
				}
			}
			GoLog("[Qobuz] Match found: '%s' by '%s' (title+duration verified)\n",
				durationMatches[0].Title, durationMatches[0].Performer.Name)
			return durationMatches[0], nil
		}

		return nil, fmt.Errorf("no tracks found with matching title and duration (expected '%s', %ds)", trackName, expectedDurationSec)
	}

	for _, track := range tracksToCheck {
		if track.MaximumBitDepth >= 24 {
			GoLog("[Qobuz] Match found: '%s' by '%s' (title verified, hi-res)\n",
				track.Title, track.Performer.Name)
			return track, nil
		}
	}

	if len(tracksToCheck) > 0 {
		GoLog("[Qobuz] Match found: '%s' by '%s' (title verified)\n",
			tracksToCheck[0].Title, tracksToCheck[0].Performer.Name)
		return tracksToCheck[0], nil
	}

	return nil, fmt.Errorf("no matching track found for: %s - %s", artistName, trackName)
}

type qobuzAPIResult struct {
	apiURL      string
	downloadURL string
	err         error
	duration    time.Duration
}

// Qobuz API timeout configuration
// Mobile networks are more unstable, so we use longer timeouts
const (
	qobuzAPITimeoutMobile = 25 * time.Second
	qobuzMaxRetries       = 2 // Number of retries per API
	qobuzRetryDelay       = 500 * time.Millisecond
)

// getQobuzAPITimeout returns appropriate timeout based on platform
// For mobile (gomobile builds), we use longer timeouts
func getQobuzAPITimeout() time.Duration {
	// Since this runs in gomobile context, we always use mobile timeout
	// The Go backend is only used on mobile (Android/iOS)
	return qobuzAPITimeoutMobile
}

// qobuzSquidCountries defines the region fallback order for squid.wtf API
var qobuzSquidCountries = []string{"US", "FR"}

// fetchQobuzURLWithRetry fetches download URL from a single Qobuz API with retry logic
// For squid.wtf APIs, it tries US region first, then falls back to FR
func fetchQobuzURLWithRetry(api string, trackID int64, quality string, timeout time.Duration) (string, error) {
	isSquid := strings.Contains(api, "squid.wtf")

	if isSquid {
		for _, country := range qobuzSquidCountries {
			GoLog("[Qobuz] Trying squid.wtf with country=%s\n", country)
			result, err := fetchQobuzURLSingleAttempt(api, trackID, quality, timeout, country)
			if err == nil {
				return result, nil
			}
			GoLog("[Qobuz] squid.wtf country=%s failed: %v\n", country, err)
		}
		return "", fmt.Errorf("squid.wtf failed for all regions (US, FR)")
	}

	return fetchQobuzURLSingleAttempt(api, trackID, quality, timeout, "")
}

// fetchQobuzURLSingleAttempt fetches download URL with retry logic for a single API+country combination
func fetchQobuzURLSingleAttempt(api string, trackID int64, quality string, timeout time.Duration, country string) (string, error) {
	var lastErr error
	retryDelay := qobuzRetryDelay

	for attempt := 0; attempt <= qobuzMaxRetries; attempt++ {
		if attempt > 0 {
			GoLog("[Qobuz] Retry %d/%d for %s after %v\n", attempt, qobuzMaxRetries, api, retryDelay)
			time.Sleep(retryDelay)
			retryDelay *= 2 // Exponential backoff
		}

		client := NewHTTPClientWithTimeout(timeout)
		reqURL := fmt.Sprintf("%s%d&quality=%s", api, trackID, quality)
		if country != "" {
			reqURL += "&country=" + country
		}

		req, err := http.NewRequest("GET", reqURL, nil)
		if err != nil {
			lastErr = err
			continue
		}

		resp, err := client.Do(req)
		if err != nil {
			lastErr = err
			// Check for retryable errors (timeout, connection reset)
			errStr := strings.ToLower(err.Error())
			if strings.Contains(errStr, "timeout") ||
				strings.Contains(errStr, "reset") ||
				strings.Contains(errStr, "connection refused") ||
				strings.Contains(errStr, "eof") {
				continue // Retry
			}
			break // Non-retryable error
		}
		// Server errors are retryable
		if resp.StatusCode >= 500 {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			lastErr = fmt.Errorf("HTTP %d", resp.StatusCode)
			continue
		}

		// 429 rate limit - wait and retry
		if resp.StatusCode == 429 {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			lastErr = fmt.Errorf("rate limited")
			retryDelay = 2 * time.Second // Wait longer for rate limit
			continue
		}

		if resp.StatusCode != 200 {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			return "", fmt.Errorf("HTTP %d", resp.StatusCode)
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			lastErr = err
			continue
		}

		if len(body) > 0 && body[0] == '<' {
			return "", fmt.Errorf("received HTML instead of JSON")
		}

		urlVal, parseErr := extractQobuzDownloadURLFromBody(body)
		if parseErr == nil {
			return urlVal, nil
		}
		lastErr = parseErr
		continue
	}

	if lastErr != nil {
		return "", lastErr
	}
	return "", fmt.Errorf("all retries failed")
}

func getQobuzDownloadURLParallel(apis []string, trackID int64, quality string) (string, string, error) {
	if len(apis) == 0 {
		return "", "", fmt.Errorf("no APIs available")
	}

	GoLog("[Qobuz] Requesting download URL from %d APIs in parallel (with retry)...\n", len(apis))

	resultChan := make(chan qobuzAPIResult, len(apis))
	startTime := time.Now()
	timeout := getQobuzAPITimeout()

	for _, apiURL := range apis {
		go func(api string) {
			reqStart := time.Now()
			downloadURL, err := fetchQobuzURLWithRetry(api, trackID, quality, timeout)
			resultChan <- qobuzAPIResult{
				apiURL:      api,
				downloadURL: downloadURL,
				err:         err,
				duration:    time.Since(reqStart),
			}
		}(apiURL)
	}

	var errors []string

	for i := 0; i < len(apis); i++ {
		result := <-resultChan
		if result.err == nil {
			GoLog("[Qobuz] [Parallel] Got response from %s in %v\n", result.apiURL, result.duration)

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

func (q *QobuzDownloader) GetDownloadURL(trackID int64, quality string) (string, error) {
	apis := q.GetAvailableAPIs()
	if len(apis) == 0 {
		return "", fmt.Errorf("no Qobuz API available")
	}

	_, downloadURL, err := getQobuzDownloadURLParallel(apis, trackID, quality)
	if err == nil {
		return downloadURL, nil
	}

	GoLog("[Qobuz] Standard APIs failed, trying Jumo fallback...\n")
	jumoURL, jumoErr := q.downloadFromJumo(trackID, quality)
	if jumoErr == nil {
		return jumoURL, nil
	}

	if quality == "27" {
		GoLog("[Qobuz] Hi-res (27) failed, trying 24-bit (7)...\n")
		jumoURL, jumoErr = q.downloadFromJumo(trackID, "7")
		if jumoErr == nil {
			return jumoURL, nil
		}
	}

	if quality == "27" || quality == "7" {
		GoLog("[Qobuz] 24-bit failed, trying 16-bit (6)...\n")
		jumoURL, jumoErr = q.downloadFromJumo(trackID, "6")
		if jumoErr == nil {
			return jumoURL, nil
		}
	}

	return "", fmt.Errorf("all Qobuz APIs and Jumo fallback failed: %w", err)
}

func (q *QobuzDownloader) DownloadFile(downloadURL, outputPath string, outputFD int, itemID string) error {
	ctx := context.Background()

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

	out, err := openOutputForWrite(outputPath, outputFD)
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

	flushErr := bufWriter.Flush()
	closeErr := out.Close()

	if err != nil {
		cleanupOutputOnError(outputPath, outputFD)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return fmt.Errorf("download interrupted: %w", err)
	}
	if flushErr != nil {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("failed to flush buffer: %w", flushErr)
	}
	if closeErr != nil {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("failed to close file: %w", closeErr)
	}

	if expectedSize > 0 && written != expectedSize {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
	}

	return nil
}

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
	LyricsLRC   string
}

func resolveQobuzTrackForRequest(req DownloadRequest, downloader *QobuzDownloader, logPrefix string) (*QobuzTrack, error) {
	if downloader == nil {
		downloader = NewQobuzDownloader()
	}
	if strings.TrimSpace(logPrefix) == "" {
		logPrefix = "Qobuz"
	}

	expectedDurationSec := req.DurationMS / 1000

	var track *QobuzTrack
	var err error

	// Strategy 1: Use Qobuz ID from Odesli enrichment (fastest, most accurate)
	if req.QobuzID != "" {
		GoLog("[%s] Using Qobuz ID from Odesli enrichment: %s\n", logPrefix, req.QobuzID)
		var trackID int64
		if _, parseErr := fmt.Sscanf(req.QobuzID, "%d", &trackID); parseErr == nil && trackID > 0 {
			track, err = downloader.GetTrackByID(trackID)
			if err != nil {
				GoLog("[%s] Failed to get track by Odesli ID %d: %v\n", logPrefix, trackID, err)
				track = nil
			} else if track != nil {
				GoLog("[%s] Successfully found track via Odesli ID: '%s' by '%s'\n", logPrefix, track.Title, track.Performer.Name)
			}
		}
	}

	// Strategy 2: Use cached Qobuz Track ID (fast, no search needed)
	if track == nil && req.ISRC != "" {
		if cached := GetTrackIDCache().Get(req.ISRC); cached != nil && cached.QobuzTrackID > 0 {
			GoLog("[%s] Cache hit! Using cached track ID: %d\n", logPrefix, cached.QobuzTrackID)
			track, err = downloader.GetTrackByID(cached.QobuzTrackID)
			if err != nil {
				GoLog("[%s] Cache hit but GetTrackByID failed: %v\n", logPrefix, err)
				track = nil
			}
		}
	}

	// Strategy 3: Try to get QobuzID from SongLink if we have SpotifyID
	if track == nil && req.SpotifyID != "" && req.QobuzID == "" {
		GoLog("[%s] Trying to get Qobuz ID from SongLink for Spotify ID: %s\n", logPrefix, req.SpotifyID)
		songLinkClient := NewSongLinkClient()
		availability, slErr := songLinkClient.CheckTrackAvailability(req.SpotifyID, req.ISRC)
		if slErr == nil && availability != nil && availability.QobuzID != "" {
			var trackID int64
			if _, parseErr := fmt.Sscanf(availability.QobuzID, "%d", &trackID); parseErr == nil && trackID > 0 {
				GoLog("[%s] Got Qobuz ID %d from SongLink\n", logPrefix, trackID)
				track, err = downloader.GetTrackByID(trackID)
				if err != nil {
					GoLog("[%s] Failed to get track by SongLink ID %d: %v\n", logPrefix, trackID, err)
					track = nil
				} else if track != nil {
					GoLog("[%s] Successfully found track via SongLink ID: '%s' by '%s'\n", logPrefix, track.Title, track.Performer.Name)
					// Cache for future use
					if req.ISRC != "" {
						GetTrackIDCache().SetQobuz(req.ISRC, track.ID)
					}
				}
			}
		}
	}

	// Strategy 4: ISRC search with duration verification
	if track == nil && req.ISRC != "" {
		GoLog("[%s] Trying ISRC search: %s\n", logPrefix, req.ISRC)
		track, err = downloader.SearchTrackByISRCWithDuration(req.ISRC, expectedDurationSec)
		if track != nil {
			if !qobuzArtistsMatch(req.ArtistName, track.Performer.Name) {
				GoLog("[%s] Artist mismatch from ISRC search: expected '%s', got '%s'. Rejecting.\n",
					logPrefix, req.ArtistName, track.Performer.Name)
				track = nil
			} else if !qobuzTitlesMatch(req.TrackName, track.Title) {
				GoLog("[%s] Title mismatch from ISRC search: expected '%s', got '%s'. Rejecting.\n",
					logPrefix, req.TrackName, track.Title)
				track = nil
			}
		}
	}

	// Strategy 5: Metadata search with strict matching (duration tolerance: 10 seconds)
	if track == nil {
		GoLog("[%s] Trying metadata search: '%s' by '%s'\n", logPrefix, req.TrackName, req.ArtistName)
		track, err = downloader.SearchTrackByMetadataWithDuration(req.TrackName, req.ArtistName, expectedDurationSec)
		if track != nil && !qobuzArtistsMatch(req.ArtistName, track.Performer.Name) {
			GoLog("[%s] Artist mismatch from metadata search: expected '%s', got '%s'. Rejecting.\n",
				logPrefix, req.ArtistName, track.Performer.Name)
			track = nil
		}
	}

	if track == nil {
		errMsg := "could not find matching track on Qobuz (artist/duration mismatch)"
		if err != nil {
			errMsg = err.Error()
		}
		return nil, fmt.Errorf("qobuz search failed: %s", errMsg)
	}

	GoLog("[%s] Match found: '%s' by '%s' (duration: %ds)\n", logPrefix, track.Title, track.Performer.Name, track.Duration)
	if req.ISRC != "" {
		GetTrackIDCache().SetQobuz(req.ISRC, track.ID)
	}

	return track, nil
}

func downloadFromQobuz(req DownloadRequest) (QobuzDownloadResult, error) {
	downloader := NewQobuzDownloader()

	isSafOutput := isFDOutput(req.OutputFD) || strings.TrimSpace(req.OutputPath) != ""
	if !isSafOutput {
		if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
			return QobuzDownloadResult{FilePath: "EXISTS:" + existingFile}, nil
		}
	}

	track, err := resolveQobuzTrackForRequest(req, downloader, "Qobuz")
	if err != nil {
		return QobuzDownloadResult{}, err
	}

	filename := buildFilenameFromTemplate(req.FilenameFormat, map[string]interface{}{
		"title":  req.TrackName,
		"artist": req.ArtistName,
		"album":  req.AlbumName,
		"track":  req.TrackNumber,
		"year":   extractYear(req.ReleaseDate),
		"date":   req.ReleaseDate,
		"disc":   req.DiscNumber,
	})
	var outputPath string
	if isSafOutput {
		outputPath = strings.TrimSpace(req.OutputPath)
		if outputPath == "" && isFDOutput(req.OutputFD) {
			outputPath = fmt.Sprintf("/proc/self/fd/%d", req.OutputFD)
		}
	} else {
		filename = sanitizeFilename(filename) + ".flac"
		outputPath = filepath.Join(req.OutputDir, filename)
		if fileInfo, statErr := os.Stat(outputPath); statErr == nil && fileInfo.Size() > 0 {
			return QobuzDownloadResult{FilePath: "EXISTS:" + outputPath}, nil
		}
	}

	qobuzQuality := "27"
	switch req.Quality {
	case "LOSSLESS":
		qobuzQuality = "6"
	case "HI_RES":
		qobuzQuality = "7"
	case "HI_RES_LOSSLESS":
		qobuzQuality = "27"
	}
	GoLog("[Qobuz] Using quality: %s (mapped from %s)\n", qobuzQuality, req.Quality)

	actualBitDepth := track.MaximumBitDepth
	actualSampleRate := int(track.MaximumSamplingRate * 1000)
	GoLog("[Qobuz] Actual quality: %d-bit/%.1fkHz\n", actualBitDepth, track.MaximumSamplingRate)

	downloadURL, err := downloader.GetDownloadURL(track.ID, qobuzQuality)
	if err != nil {
		return QobuzDownloadResult{}, fmt.Errorf("failed to get download URL: %w", err)
	}

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
			int64(req.DurationMS),
		)
	}()

	if err := downloader.DownloadFile(downloadURL, outputPath, req.OutputFD, req.ItemID); err != nil {
		if errors.Is(err, ErrDownloadCancelled) {
			return QobuzDownloadResult{}, ErrDownloadCancelled
		}
		return QobuzDownloadResult{}, fmt.Errorf("download failed: %w", err)
	}

	<-parallelDone

	if req.ItemID != "" {
		SetItemProgress(req.ItemID, 1.0, 0, 0)
		SetItemFinalizing(req.ItemID)
	}

	albumName := track.Album.Title
	if req.AlbumName != "" {
		albumName = req.AlbumName
	}

	actualTrackNumber := req.TrackNumber
	if actualTrackNumber == 0 {
		actualTrackNumber = track.TrackNumber
	}

	metadata := Metadata{
		Title:       track.Title,
		Artist:      track.Performer.Name,
		Album:       albumName,
		AlbumArtist: req.AlbumArtist,
		Date:        track.Album.ReleaseDate,
		TrackNumber: actualTrackNumber,
		TotalTracks: req.TotalTracks,
		DiscNumber:  req.DiscNumber,
		ISRC:        track.ISRC,
		Genre:       req.Genre,
		Label:       req.Label,
		Copyright:   req.Copyright,
	}

	var coverData []byte
	if parallelResult != nil && parallelResult.CoverData != nil {
		coverData = parallelResult.CoverData
		GoLog("[Qobuz] Using parallel-fetched cover (%d bytes)\n", len(coverData))
	}

	if isSafOutput {
		GoLog("[Qobuz] SAF output detected - skipping in-backend metadata/lyrics embedding (handled in Flutter)\n")
	} else {
		if err := EmbedMetadataWithCoverData(outputPath, metadata, coverData); err != nil {
			fmt.Printf("Warning: failed to embed metadata: %v\n", err)
		}

		if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
			lyricsMode := req.LyricsMode
			if lyricsMode == "" {
				lyricsMode = "embed"
			}

			if lyricsMode == "external" || lyricsMode == "both" {
				GoLog("[Qobuz] Saving external LRC file...\n")
				if lrcPath, lrcErr := SaveLRCFile(outputPath, parallelResult.LyricsLRC); lrcErr != nil {
					GoLog("[Qobuz] Warning: failed to save LRC file: %v\n", lrcErr)
				} else {
					GoLog("[Qobuz] LRC file saved: %s\n", lrcPath)
				}
			}

			if lyricsMode == "embed" || lyricsMode == "both" {
				GoLog("[Qobuz] Embedding parallel-fetched lyrics (%d lines)...\n", len(parallelResult.LyricsData.Lines))
				if embedErr := EmbedLyrics(outputPath, parallelResult.LyricsLRC); embedErr != nil {
					GoLog("[Qobuz] Warning: failed to embed lyrics: %v\n", embedErr)
				} else {
					fmt.Println("[Qobuz] Lyrics embedded successfully")
				}
			}
		} else if req.EmbedLyrics {
			fmt.Println("[Qobuz] No lyrics available from parallel fetch")
		}
	}

	if !isSafOutput {
		AddToISRCIndex(req.OutputDir, req.ISRC, outputPath)
	}

	lyricsLRC := ""
	if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
		lyricsLRC = parallelResult.LyricsLRC
	}

	return QobuzDownloadResult{
		FilePath:    outputPath,
		BitDepth:    actualBitDepth,
		SampleRate:  actualSampleRate,
		Title:       track.Title,
		Artist:      track.Performer.Name,
		Album:       track.Album.Title,
		ReleaseDate: track.Album.ReleaseDate,
		TrackNumber: actualTrackNumber,
		DiscNumber:  req.DiscNumber,
		ISRC:        track.ISRC,
		LyricsLRC:   lyricsLRC,
	}, nil
}
