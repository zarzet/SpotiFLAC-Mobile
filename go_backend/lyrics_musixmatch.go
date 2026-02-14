package gobackend

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// MusixmatchClient fetches lyrics from Musixmatch via a proxy server.
// The proxy handles Musixmatch authentication internally.
type MusixmatchClient struct {
	httpClient *http.Client
	baseURL    string
}

// Musixmatch proxy response models
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
		baseURL:    "http://158.180.60.95",
	}
}

// searchAndGetLyrics searches for a song and retrieves its lyrics in one call.
// The Musixmatch proxy returns both search result and lyrics in a single response.
func (c *MusixmatchClient) searchAndGetLyrics(trackName, artistName string) (*musixmatchSearchResponse, error) {
	if strings.TrimSpace(trackName) == "" || strings.TrimSpace(artistName) == "" {
		return nil, fmt.Errorf("empty track or artist name")
	}

	encodedArtist := url.QueryEscape(artistName)
	encodedTrack := url.QueryEscape(trackName)

	fullURL := fmt.Sprintf("%s/v2/full?artist=%s&track=%s", c.baseURL, encodedArtist, encodedTrack)

	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("musixmatch search failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("musixmatch proxy returned HTTP %d", resp.StatusCode)
	}

	var result musixmatchSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode musixmatch response: %w", err)
	}

	return &result, nil
}

// FetchLyricsInLanguage retrieves lyrics from Musixmatch for a specific language code.
func (c *MusixmatchClient) FetchLyricsInLanguage(songID int64, language string) (*LyricsResponse, error) {
	lang := strings.ToLower(strings.TrimSpace(language))
	if songID <= 0 || lang == "" {
		return nil, fmt.Errorf("invalid song id or language")
	}

	fullURL := fmt.Sprintf("%s/v2/full?id=%d&lang=%s", c.baseURL, songID, url.QueryEscape(lang))

	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("musixmatch language fetch failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("musixmatch language endpoint returned HTTP %d", resp.StatusCode)
	}

	var result musixmatchSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode musixmatch language response: %w", err)
	}

	// Prefer synced lyrics for selected language
	if result.SyncedLyrics != nil && strings.TrimSpace(result.SyncedLyrics.Lyrics) != "" {
		lines := parseSyncedLyrics(result.SyncedLyrics.Lyrics)
		if len(lines) > 0 {
			return &LyricsResponse{
				Lines:    lines,
				SyncType: "LINE_SYNCED",
				Provider: "Musixmatch",
				Source:   fmt.Sprintf("Musixmatch (%s)", lang),
			}, nil
		}
	}

	// Fall back to unsynced lyrics for selected language
	if result.UnsyncedLyrics != nil && strings.TrimSpace(result.UnsyncedLyrics.Lyrics) != "" {
		var lines []LyricsLine
		for _, line := range strings.Split(result.UnsyncedLyrics.Lyrics, "\n") {
			trimmed := strings.TrimSpace(line)
			if trimmed != "" {
				lines = append(lines, LyricsLine{
					StartTimeMs: 0,
					Words:       trimmed,
					EndTimeMs:   0,
				})
			}
		}

		if len(lines) > 0 {
			return &LyricsResponse{
				Lines:       lines,
				SyncType:    "UNSYNCED",
				PlainLyrics: result.UnsyncedLyrics.Lyrics,
				Provider:    "Musixmatch",
				Source:      fmt.Sprintf("Musixmatch (%s)", lang),
			}, nil
		}
	}

	return nil, fmt.Errorf("no lyrics found on musixmatch for language %s", lang)
}

// FetchLyrics searches Musixmatch and returns parsed LyricsResponse.
func (c *MusixmatchClient) FetchLyrics(trackName, artistName string, durationSec float64, preferredLanguage string) (*LyricsResponse, error) {
	result, err := c.searchAndGetLyrics(trackName, artistName)
	if err != nil {
		return nil, err
	}

	if preferred := strings.ToLower(strings.TrimSpace(preferredLanguage)); preferred != "" && result.ID > 0 {
		localized, localizedErr := c.FetchLyricsInLanguage(result.ID, preferred)
		if localizedErr == nil {
			return localized, nil
		}
		GoLog("[Musixmatch] Language override '%s' failed: %v\n", preferred, localizedErr)
	}

	// Prefer synced lyrics
	if result.SyncedLyrics != nil && strings.TrimSpace(result.SyncedLyrics.Lyrics) != "" {
		lines := parseSyncedLyrics(result.SyncedLyrics.Lyrics)
		if len(lines) > 0 {
			return &LyricsResponse{
				Lines:    lines,
				SyncType: "LINE_SYNCED",
				Provider: "Musixmatch",
				Source:   "Musixmatch",
			}, nil
		}
	}

	// Fall back to unsynced lyrics
	if result.UnsyncedLyrics != nil && strings.TrimSpace(result.UnsyncedLyrics.Lyrics) != "" {
		var lines []LyricsLine
		for _, line := range strings.Split(result.UnsyncedLyrics.Lyrics, "\n") {
			trimmed := strings.TrimSpace(line)
			if trimmed != "" {
				lines = append(lines, LyricsLine{
					StartTimeMs: 0,
					Words:       trimmed,
					EndTimeMs:   0,
				})
			}
		}

		if len(lines) > 0 {
			return &LyricsResponse{
				Lines:       lines,
				SyncType:    "UNSYNCED",
				PlainLyrics: result.UnsyncedLyrics.Lyrics,
				Provider:    "Musixmatch",
				Source:      "Musixmatch",
			}, nil
		}
	}

	return nil, fmt.Errorf("no lyrics found on musixmatch")
}
