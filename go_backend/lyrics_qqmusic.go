package gobackend

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// QQMusicClient fetches lyrics from QQ Music.
// Search uses public QQ Music API, lyrics use the paxsenix proxy.
type QQMusicClient struct {
	httpClient *http.Client
}

// QQ Music search response models
type qqMusicSearchResponse struct {
	Data struct {
		Song struct {
			List []struct {
				Title  string `json:"title"`
				Singer []struct {
					Name string `json:"name"`
				} `json:"singer"`
				Album struct {
					Name string `json:"name"`
				} `json:"album"`
				ID int64 `json:"id"`
			} `json:"list"`
		} `json:"song"`
	} `json:"data"`
}

// QQ Music lyrics request payload for paxsenix proxy
type qqLyricsPayload struct {
	Artist []string `json:"artist"`
	Album  string   `json:"album"`
	ID     int64    `json:"id"`
	Title  string   `json:"title"`
}

func NewQQMusicClient() *QQMusicClient {
	return &QQMusicClient{
		httpClient: NewMetadataHTTPClient(15 * time.Second),
	}
}

// searchSong searches QQ Music and returns the song info needed for lyrics fetch.
func (c *QQMusicClient) searchSong(trackName, artistName string) (*qqLyricsPayload, error) {
	query := trackName + " " + artistName
	if strings.TrimSpace(query) == "" {
		return nil, fmt.Errorf("empty search query")
	}

	searchURL := "https://c.y.qq.com/soso/fcgi-bin/client_search_cp"
	params := url.Values{}
	params.Set("format", "json")
	params.Set("inCharset", "utf8")
	params.Set("outCharset", "utf8")
	params.Set("platform", "yqq.json")
	params.Set("new_json", "1")
	params.Set("w", query)

	fullURL := searchURL + "?" + params.Encode()

	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("qqmusic search failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("qqmusic search returned HTTP %d", resp.StatusCode)
	}

	var searchResp qqMusicSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&searchResp); err != nil {
		return nil, fmt.Errorf("failed to decode qqmusic response: %w", err)
	}

	if len(searchResp.Data.Song.List) == 0 {
		return nil, fmt.Errorf("no songs found on qqmusic")
	}

	song := searchResp.Data.Song.List[0]

	var artists []string
	for _, singer := range song.Singer {
		artists = append(artists, singer.Name)
	}

	return &qqLyricsPayload{
		Artist: artists,
		Album:  song.Album.Name,
		ID:     song.ID,
		Title:  song.Title,
	}, nil
}

// fetchLyricsByPayload fetches lyrics from the paxsenix proxy using QQ Music song info.
func (c *QQMusicClient) fetchLyricsByPayload(payload *qqLyricsPayload) (string, error) {
	lyricsURL := "https://paxsenix.alwaysdata.net/getQQLyrics.php"

	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("POST", lyricsURL, bytes.NewReader(payloadBytes))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("qqmusic lyrics fetch failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("qqmusic lyrics proxy returned HTTP %d", resp.StatusCode)
	}

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read lyrics response: %w", err)
	}

	bodyStr := strings.TrimSpace(string(bodyBytes))
	if bodyStr == "" {
		return "", fmt.Errorf("empty lyrics response from qqmusic")
	}

	return bodyStr, nil
}

// FetchLyrics searches QQ Music and returns parsed LyricsResponse.
func (c *QQMusicClient) FetchLyrics(
	trackName,
	artistName string,
	durationSec float64,
	multiPersonWordByWord bool,
) (*LyricsResponse, error) {
	payload, err := c.searchSong(trackName, artistName)
	if err != nil {
		return nil, err
	}

	rawLyrics, err := c.fetchLyricsByPayload(payload)
	if err != nil {
		return nil, err
	}
	if errMsg, isErrorPayload := detectLyricsErrorPayload(rawLyrics); isErrorPayload {
		return nil, fmt.Errorf("qqmusic proxy returned non-lyric payload: %s", errMsg)
	}

	// Try to parse as pax format (word-by-word or line)
	lrcText, err := formatPaxLyricsToLRC(rawLyrics, multiPersonWordByWord)
	if err != nil {
		// If pax parsing fails, try to use as direct LRC text
		lrcText = rawLyrics
	}

	lines := parseSyncedLyrics(lrcText)
	if len(lines) > 0 {
		return &LyricsResponse{
			Lines:    lines,
			SyncType: "LINE_SYNCED",
			Provider: "QQ Music",
			Source:   "QQ Music",
		}, nil
	}

	// Fall back to plain text
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
			Provider: "QQ Music",
			Source:   "QQ Music",
		}, nil
	}

	return nil, fmt.Errorf("no lyrics found on qqmusic")
}
