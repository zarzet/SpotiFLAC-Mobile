package gobackend

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strings"
	"sync"
	"time"
)

// AppleMusicClient fetches lyrics from Apple Music.
// Uses a scraped JWT token for search and a proxy for lyrics.
type AppleMusicClient struct {
	httpClient *http.Client
}

// Apple Music token manager — singleton with mutex for thread safety
type appleTokenManager struct {
	mu    sync.Mutex
	token string
}

var globalAppleTokenManager = &appleTokenManager{}

func (m *appleTokenManager) getToken(client *http.Client) (string, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.token != "" {
		return m.token, nil
	}

	// Step 1: Fetch the Apple Music beta page
	req, err := http.NewRequest("GET", "https://beta.music.apple.com", nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to fetch Apple Music page: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read Apple Music page: %w", err)
	}

	// Step 2: Find the index JS file URL
	indexJsRegex := regexp.MustCompile(`/assets/index~[^/]+\.js`)
	match := indexJsRegex.Find(body)
	if match == nil {
		return "", fmt.Errorf("could not find index JS script URL on Apple Music page")
	}

	indexJsURL := "https://beta.music.apple.com" + string(match)

	// Step 3: Fetch the JS file
	jsReq, err := http.NewRequest("GET", indexJsURL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create JS request: %w", err)
	}
	jsReq.Header.Set("User-Agent", getRandomUserAgent())

	jsResp, err := client.Do(jsReq)
	if err != nil {
		return "", fmt.Errorf("failed to fetch Apple Music JS: %w", err)
	}
	defer jsResp.Body.Close()

	jsBody, err := io.ReadAll(jsResp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read Apple Music JS: %w", err)
	}

	// Step 4: Extract JWT token (starts with eyJh)
	tokenRegex := regexp.MustCompile(`eyJh[^"]*`)
	tokenMatch := tokenRegex.Find(jsBody)
	if tokenMatch == nil {
		return "", fmt.Errorf("could not find JWT token in Apple Music JS")
	}

	m.token = string(tokenMatch)
	GoLog("[AppleMusic] Token obtained successfully (length: %d)\n", len(m.token))
	return m.token, nil
}

func (m *appleTokenManager) clearToken() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.token = ""
}

// Apple Music API response models
type appleMusicSearchResponse struct {
	Results struct {
		Songs *struct {
			Data []struct {
				ID   string `json:"id"`
				Type string `json:"type"`
			} `json:"data"`
		} `json:"songs"`
	} `json:"results"`
	Resources *struct {
		Songs map[string]struct {
			Attributes struct {
				Name       string `json:"name"`
				ArtistName string `json:"artistName"`
				AlbumName  string `json:"albumName"`
				URL        string `json:"url"`
				Artwork    struct {
					URL string `json:"url"`
				} `json:"artwork"`
			} `json:"attributes"`
		} `json:"songs"`
	} `json:"resources"`
}

// PaxResponse represents the lyrics proxy response for word-by-word / line lyrics
type paxResponse struct {
	Type    string      `json:"type"`    // "Syllable" or "Line"
	Content []paxLyrics `json:"content"` // List of lyric lines
}

type paxLyrics struct {
	Text           []paxLyricDetail `json:"text"`
	Timestamp      int              `json:"timestamp"`
	OppositeTurn   bool             `json:"oppositeTurn"`
	Background     bool             `json:"background"`
	BackgroundText []paxLyricDetail `json:"backgroundText"`
	EndTime        int              `json:"endtime"`
}

type paxLyricDetail struct {
	Text      string `json:"text"`
	Part      bool   `json:"part"`
	Timestamp *int   `json:"timestamp"`
	EndTime   *int   `json:"endtime"`
}

func NewAppleMusicClient() *AppleMusicClient {
	return &AppleMusicClient{
		httpClient: NewMetadataHTTPClient(20 * time.Second),
	}
}

// SearchSong searches for a song on Apple Music and returns its ID.
func (c *AppleMusicClient) SearchSong(trackName, artistName string) (string, error) {
	query := trackName + " " + artistName
	if strings.TrimSpace(query) == "" {
		return "", fmt.Errorf("empty search query")
	}

	token, err := globalAppleTokenManager.getToken(c.httpClient)
	if err != nil {
		return "", fmt.Errorf("apple music token error: %w", err)
	}

	encodedQuery := url.QueryEscape(query)
	searchURL := fmt.Sprintf(
		"https://amp-api.music.apple.com/v1/catalog/us/search?term=%s&types=songs&limit=5&l=en-US&platform=web&format[resources]=map&include[songs]=artists&extend=artistUrl",
		encodedQuery,
	)

	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Origin", "https://music.apple.com")
	req.Header.Set("Referer", "https://music.apple.com/")
	req.Header.Set("User-Agent", getRandomUserAgent())
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("apple music search failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 401 {
		globalAppleTokenManager.clearToken()
		return "", fmt.Errorf("apple music token expired")
	}

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("apple music search returned HTTP %d", resp.StatusCode)
	}

	var searchResp appleMusicSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&searchResp); err != nil {
		return "", fmt.Errorf("failed to decode apple music response: %w", err)
	}

	if searchResp.Results.Songs == nil || len(searchResp.Results.Songs.Data) == 0 {
		return "", fmt.Errorf("no songs found on apple music")
	}

	return searchResp.Results.Songs.Data[0].ID, nil
}

// FetchLyricsByID fetches lyrics from the paxsenix proxy using Apple Music song ID.
func (c *AppleMusicClient) FetchLyricsByID(songID string) (string, error) {
	lyricsURL := fmt.Sprintf("https://lyrics.paxsenix.org/apple-music/lyrics?id=%s", songID)

	req, err := http.NewRequest("GET", lyricsURL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("apple music lyrics fetch failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("apple music lyrics proxy returned HTTP %d", resp.StatusCode)
	}

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read lyrics response: %w", err)
	}

	bodyStr := strings.TrimSpace(string(bodyBytes))
	if bodyStr == "" {
		return "", fmt.Errorf("empty lyrics response from apple music")
	}

	return bodyStr, nil
}

// formatPaxLyricsToLRC converts a pax proxy response to standard LRC format.
func formatPaxLyricsToLRC(rawJSON string, multiPersonWordByWord bool) (string, error) {
	// Try to parse as PaxResponse first
	var paxResp paxResponse
	if err := json.Unmarshal([]byte(rawJSON), &paxResp); err == nil && paxResp.Content != nil {
		return formatPaxContent(paxResp.Type, paxResp.Content, multiPersonWordByWord), nil
	}

	// Try to parse as a direct list of PaxLyrics
	var directLyrics []paxLyrics
	if err := json.Unmarshal([]byte(rawJSON), &directLyrics); err == nil && len(directLyrics) > 0 {
		return formatPaxContent("Syllable", directLyrics, multiPersonWordByWord), nil
	}

	return "", fmt.Errorf("failed to parse pax lyrics response")
}

func appendPaxLyricDetail(builder *strings.Builder, details []paxLyricDetail) {
	lastStart := ""

	for _, syllable := range details {
		if syllable.Timestamp != nil {
			start := fmt.Sprintf("<%s>", msToLRCTimestampInline(int64(*syllable.Timestamp)))
			if start != lastStart {
				builder.WriteString(start)
				lastStart = start
			}
		}

		builder.WriteString(syllable.Text)
		if !syllable.Part {
			builder.WriteString(" ")
		}

		if syllable.EndTime != nil {
			builder.WriteString(fmt.Sprintf("<%s>", msToLRCTimestampInline(int64(*syllable.EndTime))))
		}
	}
}

func formatPaxContent(lyricsType string, content []paxLyrics, multiPersonWordByWord bool) string {
	var sb strings.Builder

	for i, line := range content {
		if i > 0 {
			sb.WriteString("\n")
		}

		timestamp := msToLRCTimestamp(int64(line.Timestamp))

		if strings.EqualFold(lyricsType, "Syllable") {
			sb.WriteString(timestamp)
			if multiPersonWordByWord {
				if line.OppositeTurn {
					sb.WriteString("v2:")
				} else {
					sb.WriteString("v1:")
				}
			}

			appendPaxLyricDetail(&sb, line.Text)

			if line.Background && multiPersonWordByWord && len(line.BackgroundText) > 0 {
				sb.WriteString("\n[bg:")
				appendPaxLyricDetail(&sb, line.BackgroundText)
				sb.WriteString("]")
			}
		} else {
			if len(line.Text) > 0 {
				sb.WriteString(timestamp)
				sb.WriteString(line.Text[0].Text)
			}
		}
	}

	return strings.TrimSpace(sb.String())
}

// FetchLyrics searches Apple Music and returns parsed LyricsResponse.
func (c *AppleMusicClient) FetchLyrics(
	trackName,
	artistName string,
	durationSec float64,
	multiPersonWordByWord bool,
) (*LyricsResponse, error) {
	songID, err := c.SearchSong(trackName, artistName)
	if err != nil {
		return nil, err
	}

	rawLyrics, err := c.FetchLyricsByID(songID)
	if err != nil {
		return nil, err
	}

	// Try to parse as pax format (word-by-word or line)
	lrcText, err := formatPaxLyricsToLRC(rawLyrics, multiPersonWordByWord)
	if err != nil {
		// If pax parsing fails, try to parse as direct LRC text
		lrcText = rawLyrics
	}

	lines := parseSyncedLyrics(lrcText)
	if len(lines) > 0 {
		return &LyricsResponse{
			Lines:    lines,
			SyncType: "LINE_SYNCED",
			Provider: "Apple Music",
			Source:   "Apple Music",
		}, nil
	}

	// Fall back to plain text if no timestamps found
	plainLines := strings.Split(lrcText, "\n")
	var resultLines []LyricsLine
	for _, line := range plainLines {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" {
			resultLines = append(resultLines, LyricsLine{
				StartTimeMs: 0,
				Words:       trimmed,
				EndTimeMs:   0,
			})
		}
	}

	if len(resultLines) > 0 {
		return &LyricsResponse{
			Lines:    resultLines,
			SyncType: "UNSYNCED",
			Provider: "Apple Music",
			Source:   "Apple Music",
		}, nil
	}

	return nil, fmt.Errorf("no lyrics found on apple music")
}
