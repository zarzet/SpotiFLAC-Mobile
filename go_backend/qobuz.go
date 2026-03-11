package gobackend

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
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

type QobuzDownloader struct {
	client *http.Client
	appID  string
	apiURL string
}

var (
	globalQobuzDownloader *QobuzDownloader
	qobuzDownloaderOnce   sync.Once
)

const (
	qobuzTrackGetBaseURL    = "https://www.qobuz.com/api.json/0.2/track/get?track_id="
	qobuzTrackSearchBaseURL = "https://www.qobuz.com/api.json/0.2/track/search?query="
	qobuzStoreSearchBaseURL = "https://www.qobuz.com/us-en/search/tracks/"
	qobuzTrackPlayBaseURL   = "https://play.qobuz.com/track/"
	qobuzDownloadAPIURL     = "https://www.musicdl.me/api/qobuz/download"
	qobuzDabMusicAPIURL     = "https://dabmusic.xyz/api/stream?trackId="
	qobuzDeebAPIURL         = "https://dab.yeet.su/api/stream?trackId="
	qobuzSquidAPIURL        = "https://qobuz.squid.wtf/api/download-music?country=US&track_id="
	qobuzDebugKeyXORMask    = byte(0x5A)
)

var qobuzStoreTrackIDRegex = regexp.MustCompile(`/v4/ajax/popin-add-cart/track/([0-9]+)`)

var qobuzDebugKeyObfuscated = []byte{
	0x69, 0x3b, 0x38, 0x3e, 0x36, 0x37, 0x35, 0x2f, 0x36, 0x3b,
	0x33, 0x29, 0x2e, 0x32, 0x3f, 0x3d, 0x35, 0x3b, 0x2e, 0x3b,
	0x34, 0x3e, 0x34, 0x35, 0x35, 0x34, 0x3f, 0x39, 0x35, 0x37,
	0x3f, 0x29, 0x3f, 0x2c, 0x3f, 0x34, 0x39, 0x36, 0x35, 0x29,
	0x3f,
}

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

	// Emoji/symbol-only titles must be matched strictly to avoid false positives
	// like mapping "🪐" to unrelated textual tracks.
	if (!hasAlphaNumericRunes(expectedTitle) || !hasAlphaNumericRunes(foundTitle)) &&
		strings.TrimSpace(expectedTitle) != "" &&
		strings.TrimSpace(foundTitle) != "" {
		expectedSymbols := normalizeSymbolOnlyTitle(expectedTitle)
		foundSymbols := normalizeSymbolOnlyTitle(foundTitle)
		if expectedSymbols != "" && foundSymbols != "" && expectedSymbols == foundSymbols {
			GoLog("[Qobuz] Symbol-heavy title matched strictly: '%s' vs '%s'\n", expectedTitle, foundTitle)
			return true
		}
		GoLog("[Qobuz] Symbol-heavy title mismatch: '%s' vs '%s'\n", expectedTitle, foundTitle)
		return false
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
	trackURL := fmt.Sprintf("%s%d&app_id=%s", qobuzTrackGetBaseURL, trackID, q.appID)

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
	return []string{
		qobuzDownloadAPIURL,
	}
}

type qobuzAPIProvider struct {
	Name string
	URL  string
	Kind string
}

const (
	qobuzAPIKindMusicDL  = "musicdl"
	qobuzAPIKindStandard = "standard"
)

func (q *QobuzDownloader) GetAvailableProviders() []qobuzAPIProvider {
	return []qobuzAPIProvider{
		{Name: "musicdl", URL: qobuzDownloadAPIURL, Kind: qobuzAPIKindMusicDL},
		{Name: "dabmusic", URL: qobuzDabMusicAPIURL, Kind: qobuzAPIKindStandard},
		// "deeb" is mapped from the legacy reference fallback endpoint.
		{Name: "deeb", URL: qobuzDeebAPIURL, Kind: qobuzAPIKindStandard},
		{Name: "squid", URL: qobuzSquidAPIURL, Kind: qobuzAPIKindStandard},
	}
}

type qobuzDownloadInfo struct {
	DownloadURL string
	BitDepth    int
	SampleRate  int
}

func extractQobuzDownloadInfoFromBody(body []byte) (qobuzDownloadInfo, error) {
	var raw map[string]any
	if err := json.Unmarshal(body, &raw); err != nil {
		return qobuzDownloadInfo{}, fmt.Errorf("invalid JSON: %v", err)
	}

	if errMsg, ok := raw["error"].(string); ok && strings.TrimSpace(errMsg) != "" {
		return qobuzDownloadInfo{}, fmt.Errorf("%s", errMsg)
	}
	if detail, ok := raw["detail"].(string); ok && strings.TrimSpace(detail) != "" {
		return qobuzDownloadInfo{}, fmt.Errorf("%s", detail)
	}

	if success, ok := raw["success"].(bool); ok && !success {
		if msg, ok := raw["message"].(string); ok && strings.TrimSpace(msg) != "" {
			return qobuzDownloadInfo{}, fmt.Errorf("%s", msg)
		}
		return qobuzDownloadInfo{}, fmt.Errorf("api returned success=false")
	}

	info := qobuzDownloadInfo{
		BitDepth:   qobuzParseBitDepth(raw["bit_depth"]),
		SampleRate: qobuzParseSampleRate(raw["sampling_rate"]),
	}
	if urlVal, ok := raw["download_url"].(string); ok && strings.TrimSpace(urlVal) != "" {
		info.DownloadURL = strings.TrimSpace(urlVal)
		return info, nil
	}
	if urlVal, ok := raw["url"].(string); ok && strings.TrimSpace(urlVal) != "" {
		info.DownloadURL = strings.TrimSpace(urlVal)
		return info, nil
	}
	if linkVal, ok := raw["link"].(string); ok && strings.TrimSpace(linkVal) != "" {
		info.DownloadURL = strings.TrimSpace(linkVal)
		return info, nil
	}

	if data, ok := raw["data"].(map[string]any); ok {
		if info.BitDepth == 0 {
			info.BitDepth = qobuzParseBitDepth(data["bit_depth"])
		}
		if info.SampleRate == 0 {
			info.SampleRate = qobuzParseSampleRate(data["sampling_rate"])
		}
		if urlVal, ok := data["download_url"].(string); ok && strings.TrimSpace(urlVal) != "" {
			info.DownloadURL = strings.TrimSpace(urlVal)
			return info, nil
		}
		if urlVal, ok := data["url"].(string); ok && strings.TrimSpace(urlVal) != "" {
			info.DownloadURL = strings.TrimSpace(urlVal)
			return info, nil
		}
		if linkVal, ok := data["link"].(string); ok && strings.TrimSpace(linkVal) != "" {
			info.DownloadURL = strings.TrimSpace(linkVal)
			return info, nil
		}
	}

	return qobuzDownloadInfo{}, fmt.Errorf("no download URL in response")
}

func extractQobuzDownloadURLFromBody(body []byte) (string, error) {
	info, err := extractQobuzDownloadInfoFromBody(body)
	if err != nil {
		return "", err
	}
	return info.DownloadURL, nil
}

func qobuzParseBitDepth(value any) int {
	switch v := value.(type) {
	case float64:
		return int(v)
	case int:
		return v
	case int64:
		return int(v)
	case json.Number:
		n, _ := v.Int64()
		return int(n)
	default:
		return 0
	}
}

func qobuzParseSampleRate(value any) int {
	switch v := value.(type) {
	case float64:
		if v > 0 && v < 1000 {
			return int(v * 1000)
		}
		return int(v)
	case int:
		if v > 0 && v < 1000 {
			return v * 1000
		}
		return v
	case int64:
		if v > 0 && v < 1000 {
			return int(v * 1000)
		}
		return int(v)
	case json.Number:
		if n, err := v.Float64(); err == nil {
			if n > 0 && n < 1000 {
				return int(n * 1000)
			}
			return int(n)
		}
		return 0
	default:
		return 0
	}
}

func normalizeQobuzQualityCode(quality string) string {
	switch strings.ToLower(strings.TrimSpace(quality)) {
	case "", "5", "6", "cd", "lossless":
		return "6"
	case "7", "hi-res":
		return "7"
	case "27", "hi-res-max":
		return "27"
	default:
		return "6"
	}
}

func mapQobuzQualityCodeToAPI(qualityCode string) string {
	switch normalizeQobuzQualityCode(qualityCode) {
	case "27":
		return "hi-res-max"
	case "7":
		return "hi-res"
	default:
		return "cd"
	}
}

func getQobuzDebugKey() string {
	decoded := make([]byte, len(qobuzDebugKeyObfuscated))
	for i, b := range qobuzDebugKeyObfuscated {
		decoded[i] = b ^ qobuzDebugKeyXORMask
	}
	return string(decoded)
}

func (q *QobuzDownloader) SearchTrackByISRC(isrc string) (*QobuzTrack, error) {
	candidates, err := q.searchQobuzTracksWithFallback(isrc, 50)
	if err != nil {
		return nil, err
	}

	for i := range candidates {
		if candidates[i].ISRC == isrc {
			return &candidates[i], nil
		}
	}

	if len(candidates) == 0 {
		return nil, fmt.Errorf("no tracks found for ISRC: %s", isrc)
	}

	return nil, fmt.Errorf("no exact ISRC match found for: %s", isrc)
}

func (q *QobuzDownloader) SearchTrackByISRCWithDuration(isrc string, expectedDurationSec int) (*QobuzTrack, error) {
	GoLog("[Qobuz] Searching by ISRC: %s\n", isrc)

	candidates, err := q.searchQobuzTracksWithFallback(isrc, 50)
	if err != nil {
		return nil, err
	}

	GoLog("[Qobuz] ISRC search returned %d results\n", len(candidates))

	var isrcMatches []*QobuzTrack
	for i := range candidates {
		if candidates[i].ISRC == isrc {
			isrcMatches = append(isrcMatches, &candidates[i])
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

	if len(candidates) == 0 {
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
	seenTrackIDs := make(map[int64]struct{})

	for _, query := range queries {
		cleanQuery := strings.TrimSpace(query)
		if cleanQuery == "" || searchedQueries[cleanQuery] {
			continue
		}
		searchedQueries[cleanQuery] = true

		GoLog("[Qobuz] Searching for: %s\n", cleanQuery)

		result, err := q.searchQobuzTracksWithFallback(cleanQuery, 50)
		if err != nil {
			GoLog("[Qobuz] Search error for '%s': %v\n", cleanQuery, err)
			continue
		}

		if len(result) > 0 {
			GoLog("[Qobuz] Found %d results for '%s'\n", len(result), cleanQuery)
			for i := range result {
				trackID := result[i].ID
				if trackID <= 0 {
					allTracks = append(allTracks, result[i])
					continue
				}
				if _, ok := seenTrackIDs[trackID]; ok {
					continue
				}
				seenTrackIDs[trackID] = struct{}{}
				allTracks = append(allTracks, result[i])
			}
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

func (q *QobuzDownloader) searchQobuzTracksViaAPI(query string, limit int) ([]QobuzTrack, error) {
	searchURL := fmt.Sprintf("%s%s&limit=%d&app_id=%s", qobuzTrackSearchBaseURL, url.QueryEscape(query), limit, q.appID)
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
	return result.Tracks.Items, nil
}

func extractQobuzTrackIDsFromStoreSearchHTML(body []byte) []int64 {
	matches := qobuzStoreTrackIDRegex.FindAllSubmatch(body, -1)
	if len(matches) == 0 {
		return nil
	}

	trackIDs := make([]int64, 0, len(matches))
	seen := make(map[int64]struct{}, len(matches))
	for _, match := range matches {
		if len(match) < 2 {
			continue
		}
		id, err := strconv.ParseInt(string(match[1]), 10, 64)
		if err != nil || id <= 0 {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		trackIDs = append(trackIDs, id)
	}
	return trackIDs
}

func (q *QobuzDownloader) searchQobuzTracksViaStore(query string, limit int) ([]QobuzTrack, error) {
	searchURL := qobuzStoreSearchBaseURL + url.PathEscape(query)
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
		return nil, fmt.Errorf("store search failed: HTTP %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	trackIDs := extractQobuzTrackIDsFromStoreSearchHTML(body)
	if len(trackIDs) == 0 {
		return nil, fmt.Errorf("store search did not contain track IDs")
	}

	if limit > 0 && len(trackIDs) > limit {
		trackIDs = trackIDs[:limit]
	}

	tracks := make([]QobuzTrack, 0, len(trackIDs))
	for _, id := range trackIDs {
		track, trackErr := q.GetTrackByID(id)
		if trackErr != nil || track == nil {
			continue
		}
		tracks = append(tracks, *track)
	}

	if len(tracks) == 0 {
		return nil, fmt.Errorf("store fallback returned IDs but no track metadata could be loaded")
	}
	return tracks, nil
}

func (q *QobuzDownloader) searchQobuzTracksWithFallback(query string, limit int) ([]QobuzTrack, error) {
	apiTracks, apiErr := q.searchQobuzTracksViaAPI(query, limit)
	if apiErr == nil {
		if len(apiTracks) > 0 {
			return apiTracks, nil
		}
		GoLog("[Qobuz] API search returned 0 results for '%s', trying store fallback\n", query)
	} else {
		GoLog("[Qobuz] API search failed for '%s': %v. Trying store fallback.\n", query, apiErr)
	}

	storeTracks, storeErr := q.searchQobuzTracksViaStore(query, limit)
	if storeErr == nil && len(storeTracks) > 0 {
		GoLog("[Qobuz] Store fallback returned %d candidate tracks for '%s'\n", len(storeTracks), query)
		return storeTracks, nil
	}

	if apiErr != nil && storeErr != nil {
		return nil, fmt.Errorf("api search failed (%v); store fallback failed (%v)", apiErr, storeErr)
	}
	if storeErr != nil {
		return nil, storeErr
	}
	return nil, fmt.Errorf("no tracks found for query: %s", query)
}

type qobuzAPIResult struct {
	provider qobuzAPIProvider
	info     qobuzDownloadInfo
	err      error
	duration time.Duration
}

// Mobile networks are more unstable, so we use longer timeouts
const (
	qobuzAPITimeoutMobile = 25 * time.Second
	qobuzMaxRetries       = 2
	qobuzRetryDelay       = 500 * time.Millisecond
)

func getQobuzAPITimeout() time.Duration {
	// The Go backend is only used on mobile (Android/iOS)
	return qobuzAPITimeoutMobile
}

// fetchQobuzURLWithRetry fetches download URL from a single Qobuz API with retry logic
func fetchQobuzURLWithRetry(provider qobuzAPIProvider, trackID int64, quality string, timeout time.Duration) (qobuzDownloadInfo, error) {
	return fetchQobuzURLSingleAttempt(provider, trackID, quality, timeout, "")
}

func fetchQobuzURLSingleAttempt(provider qobuzAPIProvider, trackID int64, quality string, timeout time.Duration, country string) (qobuzDownloadInfo, error) {
	var lastErr error
	retryDelay := qobuzRetryDelay
	var payloadBytes []byte
	if provider.Kind == qobuzAPIKindMusicDL {
		requestQuality := mapQobuzQualityCodeToAPI(quality)
		payload := map[string]any{
			"quality":      requestQuality,
			"upload_to_r2": false,
			"url":          fmt.Sprintf("%s%d", qobuzTrackPlayBaseURL, trackID),
		}
		var err error
		payloadBytes, err = json.Marshal(payload)
		if err != nil {
			return qobuzDownloadInfo{}, fmt.Errorf("failed to encode qobuz request: %w", err)
		}
	}

	for attempt := 0; attempt <= qobuzMaxRetries; attempt++ {
		if attempt > 0 {
			GoLog("[Qobuz] Retry %d/%d for %s after %v\n", attempt, qobuzMaxRetries, provider.Name, retryDelay)
			time.Sleep(retryDelay)
			retryDelay *= 2
		}

		client := NewHTTPClientWithTimeout(timeout)
		reqURL := provider.URL
		if country != "" {
			reqURL += "?country=" + url.QueryEscape(country)
		}

		var (
			req *http.Request
			err error
		)
		if provider.Kind == qobuzAPIKindStandard {
			separator := "&"
			if !strings.Contains(reqURL, "?") {
				separator = "?"
			}
			reqURL = fmt.Sprintf(
				"%s%d%squality=%s",
				reqURL,
				trackID,
				separator,
				url.QueryEscape(normalizeQobuzQualityCode(quality)),
			)
			req, err = http.NewRequest("GET", reqURL, nil)
		} else {
			req, err = http.NewRequest("POST", reqURL, bytes.NewReader(payloadBytes))
		}
		if err != nil {
			lastErr = err
			continue
		}
		if provider.Kind == qobuzAPIKindMusicDL {
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("X-Debug-Key", getQobuzDebugKey())
		}

		resp, err := DoRequestWithUserAgent(client, req)
		if err != nil {
			lastErr = err
			// Check for retryable errors (timeout, connection reset)
			errStr := strings.ToLower(err.Error())
			if strings.Contains(errStr, "timeout") ||
				strings.Contains(errStr, "reset") ||
				strings.Contains(errStr, "connection refused") ||
				strings.Contains(errStr, "eof") {
				continue
			}
			break
		}
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
			retryDelay = 2 * time.Second
			continue
		}

		if resp.StatusCode != 200 {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			return qobuzDownloadInfo{}, fmt.Errorf("HTTP %d", resp.StatusCode)
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			lastErr = err
			continue
		}

		if len(body) > 0 && body[0] == '<' {
			return qobuzDownloadInfo{}, fmt.Errorf("received HTML instead of JSON")
		}

		info, parseErr := extractQobuzDownloadInfoFromBody(body)
		if parseErr == nil {
			return info, nil
		}
		lastErr = parseErr
		continue
	}

	if lastErr != nil {
		return qobuzDownloadInfo{}, lastErr
	}
	return qobuzDownloadInfo{}, fmt.Errorf("all retries failed")
}

func getQobuzDownloadURLParallel(providers []qobuzAPIProvider, trackID int64, quality string) (qobuzAPIProvider, qobuzDownloadInfo, error) {
	if len(providers) == 0 {
		return qobuzAPIProvider{}, qobuzDownloadInfo{}, fmt.Errorf("no APIs available")
	}

	GoLog("[Qobuz] Requesting download URL from %d APIs in parallel (with retry)...\n", len(providers))

	resultChan := make(chan qobuzAPIResult, len(providers))
	startTime := time.Now()
	timeout := getQobuzAPITimeout()

	for _, provider := range providers {
		go func(provider qobuzAPIProvider) {
			reqStart := time.Now()
			info, err := fetchQobuzURLWithRetry(provider, trackID, quality, timeout)
			resultChan <- qobuzAPIResult{
				provider: provider,
				info:     info,
				err:      err,
				duration: time.Since(reqStart),
			}
		}(provider)
	}

	var errors []string

	for i := 0; i < len(providers); i++ {
		result := <-resultChan
		if result.err == nil {
			GoLog("[Qobuz] [Parallel] Got response from %s in %v\n", result.provider.Name, result.duration)

			go func(remaining int) {
				for j := 0; j < remaining; j++ {
					<-resultChan
				}
			}(len(providers) - i - 1)

			GoLog("[Qobuz] [Parallel] Total time: %v (first success)\n", time.Since(startTime))
			return result.provider, result.info, nil
		}
		errMsg := result.err.Error()
		if len(errMsg) > 50 {
			errMsg = errMsg[:50] + "..."
		}
		errors = append(errors, fmt.Sprintf("%s: %s", result.provider.Name, errMsg))
	}

	GoLog("[Qobuz] [Parallel] All %d APIs failed in %v\n", len(providers), time.Since(startTime))
	return qobuzAPIProvider{}, qobuzDownloadInfo{}, fmt.Errorf("all %d Qobuz APIs failed. Errors: %v", len(providers), errors)
}

func (q *QobuzDownloader) GetDownloadURL(trackID int64, quality string) (qobuzDownloadInfo, error) {
	providers := q.GetAvailableProviders()
	if len(providers) == 0 {
		return qobuzDownloadInfo{}, fmt.Errorf("no Qobuz API available")
	}

	qualityCode := normalizeQobuzQualityCode(quality)

	downloadFunc := func(qual string) (qobuzDownloadInfo, error) {
		provider, info, err := getQobuzDownloadURLParallel(providers, trackID, qual)
		if err != nil {
			return qobuzDownloadInfo{}, err
		}
		GoLog("[Qobuz] Download URL resolved via %s\n", provider.Name)
		return info, nil
	}

	downloadInfo, err := downloadFunc(qualityCode)
	if err == nil {
		return downloadInfo, nil
	}

	currentQuality := qualityCode
	if currentQuality == "27" {
		GoLog("[Qobuz] Hi-res (27) failed, trying 24-bit (7)...\n")
		downloadInfo, err = downloadFunc("7")
		if err == nil {
			return downloadInfo, nil
		}
		currentQuality = "7"
	}

	if currentQuality == "7" {
		GoLog("[Qobuz] 24-bit failed, trying 16-bit (6)...\n")
		downloadInfo, err = downloadFunc("6")
		if err == nil {
			return downloadInfo, nil
		}
	}

	return qobuzDownloadInfo{}, fmt.Errorf("all Qobuz APIs failed: %w", err)
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

	downloadInfo, err := downloader.GetDownloadURL(track.ID, qobuzQuality)
	if err != nil {
		return QobuzDownloadResult{}, fmt.Errorf("failed to get download URL: %w", err)
	}
	if downloadInfo.BitDepth > 0 {
		actualBitDepth = downloadInfo.BitDepth
	}
	if downloadInfo.SampleRate > 0 {
		actualSampleRate = downloadInfo.SampleRate
	}
	if actualBitDepth > 0 || actualSampleRate > 0 {
		GoLog("[Qobuz] API returned quality: %d-bit/%dHz\n", actualBitDepth, actualSampleRate)
	}

	var parallelResult *ParallelDownloadResult
	parallelDone := make(chan struct{})
	go func() {
		defer close(parallelDone)
		coverURL := req.CoverURL
		embedLyrics := req.EmbedLyrics
		if !req.EmbedMetadata {
			coverURL = ""
			embedLyrics = false
		}
		parallelResult = FetchCoverAndLyricsParallel(
			coverURL,
			req.EmbedMaxQualityCover,
			req.SpotifyID,
			req.TrackName,
			req.ArtistName,
			embedLyrics,
			int64(req.DurationMS),
		)
	}()

	if err := downloader.DownloadFile(downloadInfo.DownloadURL, outputPath, req.OutputFD, req.ItemID); err != nil {
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

	if isSafOutput || !req.EmbedMetadata {
		if !req.EmbedMetadata {
			GoLog("[Qobuz] Metadata embedding disabled by settings, skipping in-backend metadata/lyrics embedding\n")
		} else {
			GoLog("[Qobuz] SAF output detected - skipping in-backend metadata/lyrics embedding (handled in Flutter)\n")
		}
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
	if req.EmbedMetadata && req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
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
