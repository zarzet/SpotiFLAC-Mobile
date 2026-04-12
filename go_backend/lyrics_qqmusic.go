package gobackend

import (
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"strings"
	"time"
)

type QQMusicClient struct {
	httpClient *http.Client
}

type qqLyricsMetadataRequest struct {
	Artist   []string `json:"artist"`
	Album    string   `json:"album,omitempty"`
	SongID   int64    `json:"songid,omitempty"`
	Title    string   `json:"title"`
	Duration int64    `json:"duration,omitempty"`
}

type qqLyricsMetadataResponse struct {
	Lyrics []paxLyrics `json:"lyrics"`
}

func NewQQMusicClient() *QQMusicClient {
	return &QQMusicClient{
		httpClient: NewMetadataHTTPClient(15 * time.Second),
	}
}

func (c *QQMusicClient) fetchLyricsByMetadata(trackName, artistName string, durationSec float64) (string, error) {
	payload := qqLyricsMetadataRequest{
		Artist: []string{artistName},
		Title:  trackName,
	}
	if durationSec > 0 {
		payload.Duration = int64(math.Round(durationSec))
	}

	lyricsURL := "https://lyrics.paxsenix.org/qq/lyrics-metadata"

	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("POST", lyricsURL, strings.NewReader(string(payloadBytes)))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", appUserAgent())

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

func formatQQLyricsMetadataToLRC(rawJSON string, multiPersonWordByWord bool) (string, error) {
	var response qqLyricsMetadataResponse
	if err := json.Unmarshal([]byte(rawJSON), &response); err != nil {
		return "", fmt.Errorf("failed to parse qq metadata lyrics response")
	}
	if len(response.Lyrics) == 0 {
		return "", fmt.Errorf("qq metadata lyrics response was empty")
	}
	return formatPaxContent("Syllable", response.Lyrics, multiPersonWordByWord), nil
}

func (c *QQMusicClient) FetchLyrics(
	trackName,
	artistName string,
	durationSec float64,
	multiPersonWordByWord bool,
) (*LyricsResponse, error) {
	rawLyrics, err := c.fetchLyricsByMetadata(trackName, artistName, durationSec)
	if err != nil {
		return nil, err
	}
	if errMsg, isErrorPayload := detectLyricsErrorPayload(rawLyrics); isErrorPayload {
		return nil, fmt.Errorf("qqmusic proxy returned non-lyric payload: %s", errMsg)
	}

	lrcText, err := formatQQLyricsMetadataToLRC(rawLyrics, multiPersonWordByWord)
	if err != nil {
		if fallback, fallbackErr := formatPaxLyricsToLRC(rawLyrics, multiPersonWordByWord); fallbackErr == nil {
			lrcText = fallback
		} else {
			lrcText = rawLyrics
		}
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

	resultLines := plainTextLyricsLines(lrcText)

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
