package gobackend

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"time"
)

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
		httpClient: &http.Client{
			Timeout: 15 * time.Second,
		},
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

func (c *LyricsClient) FetchLyricsFromLRCLibSearch(query string) (*LyricsResponse, error) {
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

	for _, result := range results {
		if result.SyncedLyrics != "" {
			return c.parseLRCLibResponse(&result), nil
		}
	}

	return c.parseLRCLibResponse(&results[0]), nil
}

func (c *LyricsClient) FetchLyricsAllSources(spotifyID, trackName, artistName string) (*LyricsResponse, error) {
	lyrics, err := c.FetchLyricsWithMetadata(artistName, trackName)
	if err == nil && lyrics != nil && len(lyrics.Lines) > 0 {
		lyrics.Source = "LRCLIB"
		return lyrics, nil
	}

	simplifiedTrack := simplifyTrackName(trackName)
	if simplifiedTrack != trackName {
		lyrics, err = c.FetchLyricsWithMetadata(artistName, simplifiedTrack)
		if err == nil && lyrics != nil && len(lyrics.Lines) > 0 {
			lyrics.Source = "LRCLIB (simplified)"
			return lyrics, nil
		}
	}

	query := artistName + " " + trackName
	lyrics, err = c.FetchLyricsFromLRCLibSearch(query)
	if err == nil && lyrics != nil && len(lyrics.Lines) > 0 {
		lyrics.Source = "LRCLIB Search"
		return lyrics, nil
	}

	if simplifiedTrack != trackName {
		query = artistName + " " + simplifiedTrack
		lyrics, err = c.FetchLyricsFromLRCLibSearch(query)
		if err == nil && lyrics != nil && len(lyrics.Lines) > 0 {
			lyrics.Source = "LRCLIB Search (simplified)"
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

// convertToLRC converts lyrics to LRC format string (without metadata headers)
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

// convertToLRCWithMetadata converts lyrics to LRC format with metadata headers
// Includes [ti:], [ar:], [by:] headers
func convertToLRCWithMetadata(lyrics *LyricsResponse, trackName, artistName string) string {
	if lyrics == nil || len(lyrics.Lines) == 0 {
		return ""
	}

	var builder strings.Builder

	// Add metadata headers
	builder.WriteString(fmt.Sprintf("[ti:%s]\n", trackName))
	builder.WriteString(fmt.Sprintf("[ar:%s]\n", artistName))
	builder.WriteString("[by:SpotiFLAC-Mobile]\n")
	builder.WriteString("\n")

	// Add lyrics lines
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
