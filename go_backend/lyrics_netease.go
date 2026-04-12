package gobackend

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type NeteaseClient struct {
	httpClient *http.Client
}

type neteaseSearchResponse struct {
	Result struct {
		Songs []struct {
			Name    string `json:"name"`
			ID      int64  `json:"id"`
			Artists []struct {
				Name string `json:"name"`
			} `json:"artists"`
		} `json:"songs"`
		SongCount int `json:"songCount"`
	} `json:"result"`
	Code int `json:"code"`
}

type neteaseLyricsResponse struct {
	LRC     *neteaseLyricField `json:"lrc"`
	TLyric  *neteaseLyricField `json:"tlyric"`
	RomaLRC *neteaseLyricField `json:"romalrc"`
	Code    int                `json:"code"`
}

type neteaseLyricField struct {
	Lyric string `json:"lyric"`
}

var neteaseHeaders = map[string]string{
	"Accept":          "application/json",
	"Accept-Language": "en-US,en;q=0.9",
	"Cache-Control":   "max-age=0",
}

func NewNeteaseClient() *NeteaseClient {
	return &NeteaseClient{
		httpClient: NewMetadataHTTPClient(15 * time.Second),
	}
}

func (c *NeteaseClient) SearchSong(trackName, artistName string) (int64, error) {
	query := trackName + " " + artistName
	if strings.TrimSpace(query) == "" {
		return 0, fmt.Errorf("empty search query")
	}

	searchURL := "https://lyrics.paxsenix.org/netease/search"
	params := url.Values{}
	params.Set("q", query)

	fullURL := searchURL + "?" + params.Encode()

	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return 0, fmt.Errorf("failed to create request: %w", err)
	}

	for k, v := range neteaseHeaders {
		req.Header.Set(k, v)
	}
	req.Header.Set("User-Agent", appUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return 0, fmt.Errorf("netease search failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return 0, fmt.Errorf("netease search returned HTTP %d", resp.StatusCode)
	}

	var searchResp neteaseSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&searchResp); err != nil {
		return 0, fmt.Errorf("failed to decode netease search: %w", err)
	}

	if searchResp.Result.SongCount == 0 || len(searchResp.Result.Songs) == 0 {
		return 0, fmt.Errorf("no songs found on netease")
	}

	return searchResp.Result.Songs[0].ID, nil
}

func (c *NeteaseClient) FetchLyricsByID(songID int64, includeTranslation, includeRomanization bool) (string, error) {
	lyricsURL := "https://lyrics.paxsenix.org/netease/lyrics"
	params := url.Values{}
	params.Set("id", fmt.Sprintf("%d", songID))

	fullURL := lyricsURL + "?" + params.Encode()

	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	for k, v := range neteaseHeaders {
		req.Header.Set(k, v)
	}
	req.Header.Set("User-Agent", appUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("netease lyrics fetch failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("netease lyrics returned HTTP %d", resp.StatusCode)
	}

	var lyricsResp neteaseLyricsResponse
	if err := json.NewDecoder(resp.Body).Decode(&lyricsResp); err != nil {
		return "", fmt.Errorf("failed to decode netease lyrics: %w", err)
	}

	if lyricsResp.LRC == nil || strings.TrimSpace(lyricsResp.LRC.Lyric) == "" {
		return "", fmt.Errorf("no lyrics available on netease")
	}

	lyric := lyricsResp.LRC.Lyric

	if includeTranslation && lyricsResp.TLyric != nil && strings.TrimSpace(lyricsResp.TLyric.Lyric) != "" {
		lyric += "\n\n" + lyricsResp.TLyric.Lyric
	}

	if includeRomanization && lyricsResp.RomaLRC != nil && strings.TrimSpace(lyricsResp.RomaLRC.Lyric) != "" {
		lyric += "\n\n" + lyricsResp.RomaLRC.Lyric
	}

	return lyric, nil
}

func (c *NeteaseClient) FetchLyrics(
	trackName,
	artistName string,
	durationSec float64,
	includeTranslation,
	includeRomanization bool,
) (*LyricsResponse, error) {
	songID, err := c.SearchSong(trackName, artistName)
	if err != nil {
		return nil, err
	}

	lrcText, err := c.FetchLyricsByID(songID, includeTranslation, includeRomanization)
	if err != nil {
		return nil, err
	}

	lines := parseSyncedLyrics(lrcText)
	if len(lines) == 0 {
		plainLines := strings.Split(lrcText, "\n")
		for _, line := range plainLines {
			trimmed := strings.TrimSpace(line)
			if trimmed != "" {
				lines = append(lines, LyricsLine{
					StartTimeMs: 0,
					Words:       trimmed,
					EndTimeMs:   0,
				})
			}
		}

		if len(lines) == 0 {
			return nil, fmt.Errorf("netease returned empty lyrics")
		}

		return &LyricsResponse{
			Lines:    lines,
			SyncType: "UNSYNCED",
			Provider: "Netease",
			Source:   "Netease",
		}, nil
	}

	return &LyricsResponse{
		Lines:    lines,
		SyncType: "LINE_SYNCED",
		Provider: "Netease",
		Source:   "Netease",
	}, nil
}
