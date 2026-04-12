package gobackend

import (
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type MusixmatchClient struct {
	httpClient *http.Client
	baseURL    string
}

type musixmatchSearchResponse struct {
	ID                 int64                     `json:"id"`
	SongName           string                    `json:"songName"`
	ArtistName         string                    `json:"artistName"`
	AlbumName          string                    `json:"albumName"`
	Artwork            string                    `json:"artwork"`
	ReleaseDate        string                    `json:"releaseDate"`
	Duration           int                       `json:"duration"`
	URL                string                    `json:"url"`
	AlbumID            int64                     `json:"albumId"`
	HasSyncedLyrics    bool                      `json:"hasSyncedLyrics"`
	HasUnsyncedLyrics  bool                      `json:"hasUnsyncedLyrics"`
	AvailableLanguages []string                  `json:"availableLanguages"`
	OriginalLanguage   string                    `json:"originalLanguage"`
	SyncedLyrics       *musixmatchLyricsResponse `json:"syncedLyrics"`
	UnsyncedLyrics     *musixmatchLyricsResponse `json:"unsyncedLyrics"`
}

type musixmatchLyricsResponse struct {
	ID          int64  `json:"id"`
	Duration    int    `json:"duration"`
	Language    string `json:"language"`
	UpdatedTime string `json:"updatedTime"`
	Lyrics      string `json:"lyrics"`
}

func NewMusixmatchClient() *MusixmatchClient {
	return &MusixmatchClient{
		httpClient: NewMetadataHTTPClient(15 * time.Second),
		baseURL:    "https://lyrics.paxsenix.org/musixmatch/lyrics",
	}
}

func (c *MusixmatchClient) fetchLyricsPayload(trackName, artistName string, durationSec float64, lyricsType, language string) (string, error) {
	if strings.TrimSpace(trackName) == "" || strings.TrimSpace(artistName) == "" {
		return "", fmt.Errorf("empty track or artist name")
	}

	params := url.Values{}
	params.Set("t", trackName)
	params.Set("a", artistName)
	params.Set("type", lyricsType)
	params.Set("format", "lrc")
	if durationSec > 0 {
		params.Set("d", fmt.Sprintf("%d", int(math.Round(durationSec))))
	}
	if strings.TrimSpace(language) != "" {
		params.Set("l", strings.ToLower(strings.TrimSpace(language)))
	}
	fullURL := c.baseURL + "?" + params.Encode()

	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", appUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("musixmatch request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read musixmatch response: %w", err)
	}

	if resp.StatusCode != 200 {
		trimmed := strings.TrimSpace(string(body))
		if errMsg, isErrorPayload := detectLyricsErrorPayload(trimmed); isErrorPayload {
			return "", fmt.Errorf("musixmatch proxy returned HTTP %d: %s", resp.StatusCode, errMsg)
		}
		return "", fmt.Errorf("musixmatch proxy returned HTTP %d", resp.StatusCode)
	}

	var lrcPayload string
	if err := json.Unmarshal(body, &lrcPayload); err == nil {
		lrcPayload = strings.TrimSpace(lrcPayload)
		if lrcPayload == "" {
			return "", fmt.Errorf("empty musixmatch lyrics payload")
		}
		return lrcPayload, nil
	}

	trimmed := strings.TrimSpace(string(body))
	if errMsg, isErrorPayload := detectLyricsErrorPayload(trimmed); isErrorPayload {
		return "", fmt.Errorf("%s", errMsg)
	}
	if trimmed != "" && !strings.HasPrefix(trimmed, "{") {
		return trimmed, nil
	}
	return "", fmt.Errorf("failed to decode musixmatch response")
}

func (c *MusixmatchClient) FetchLyricsInLanguage(trackName, artistName string, durationSec float64, language string) (*LyricsResponse, error) {
	lang := strings.ToLower(strings.TrimSpace(language))
	if lang == "" {
		return nil, fmt.Errorf("invalid language")
	}

	lrcText, err := c.fetchLyricsPayload(trackName, artistName, durationSec, "translate", lang)
	if err != nil {
		return nil, err
	}

	lines := parseSyncedLyrics(lrcText)
	if len(lines) > 0 {
		return &LyricsResponse{
			Lines:       lines,
			SyncType:    "LINE_SYNCED",
			PlainLyrics: plainLyricsFromTimedLines(lines),
			Provider:    "Musixmatch",
			Source:      fmt.Sprintf("Musixmatch (%s)", lang),
		}, nil
	}

	plainLines := plainTextLyricsLines(lrcText)
	if len(plainLines) > 0 {
		return &LyricsResponse{
			Lines:       plainLines,
			SyncType:    "UNSYNCED",
			PlainLyrics: lrcText,
			Provider:    "Musixmatch",
			Source:      fmt.Sprintf("Musixmatch (%s)", lang),
		}, nil
	}

	return nil, fmt.Errorf("no lyrics found on musixmatch for language %s", lang)
}

func (c *MusixmatchClient) FetchLyrics(trackName, artistName string, durationSec float64, preferredLanguage string) (*LyricsResponse, error) {
	if preferred := strings.ToLower(strings.TrimSpace(preferredLanguage)); preferred != "" {
		localized, localizedErr := c.FetchLyricsInLanguage(trackName, artistName, durationSec, preferred)
		if localizedErr == nil {
			return localized, nil
		}
		GoLog("[Musixmatch] Language override '%s' failed: %v\n", preferred, localizedErr)
	}

	lrcText, err := c.fetchLyricsPayload(trackName, artistName, durationSec, "word", "")
	if err != nil {
		return nil, err
	}

	lines := parseSyncedLyrics(lrcText)
	if len(lines) > 0 {
		return &LyricsResponse{
			Lines:       lines,
			SyncType:    "LINE_SYNCED",
			PlainLyrics: plainLyricsFromTimedLines(lines),
			Provider:    "Musixmatch",
			Source:      "Musixmatch",
		}, nil
	}

	plainLines := plainTextLyricsLines(lrcText)
	if len(plainLines) > 0 {
		return &LyricsResponse{
			Lines:       plainLines,
			SyncType:    "UNSYNCED",
			PlainLyrics: lrcText,
			Provider:    "Musixmatch",
			Source:      "Musixmatch",
		}, nil
	}

	return nil, fmt.Errorf("no lyrics found on musixmatch")
}
