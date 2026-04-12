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

type AppleMusicClient struct {
	httpClient *http.Client
}

type appleMusicSearchResult struct {
	ID         string `json:"id"`
	SongName   string `json:"songName"`
	ArtistName string `json:"artistName"`
	AlbumName  string `json:"albumName"`
	Duration   int    `json:"duration"`
}

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

func selectBestAppleMusicSearchResult(results []appleMusicSearchResult, trackName, artistName string, durationSec float64) *appleMusicSearchResult {
	if len(results) == 0 {
		return nil
	}

	normalizedTrack := strings.ToLower(strings.TrimSpace(simplifyTrackName(trackName)))
	normalizedArtist := strings.ToLower(strings.TrimSpace(normalizeArtistName(artistName)))
	if normalizedArtist == "" {
		normalizedArtist = strings.ToLower(strings.TrimSpace(artistName))
	}

	bestIndex := 0
	bestScore := -1
	for i := range results {
		result := &results[i]
		score := 0

		candidateTrack := strings.ToLower(strings.TrimSpace(simplifyTrackName(result.SongName)))
		candidateArtist := strings.ToLower(strings.TrimSpace(normalizeArtistName(result.ArtistName)))

		switch {
		case candidateTrack == normalizedTrack:
			score += 50
		case strings.Contains(candidateTrack, normalizedTrack) || strings.Contains(normalizedTrack, candidateTrack):
			score += 25
		}

		switch {
		case candidateArtist == normalizedArtist:
			score += 60
		case strings.Contains(candidateArtist, normalizedArtist) || strings.Contains(normalizedArtist, candidateArtist):
			score += 30
		}

		if durationSec > 0 && result.Duration > 0 {
			diff := math.Abs(float64(result.Duration)/1000.0 - durationSec)
			if diff <= durationToleranceSec {
				score += 20
			}
		}

		if score > bestScore {
			bestScore = score
			bestIndex = i
		}
	}

	return &results[bestIndex]
}

func (c *AppleMusicClient) SearchSong(trackName, artistName string, durationSec float64) (string, error) {
	query := trackName + " " + artistName
	if strings.TrimSpace(query) == "" {
		return "", fmt.Errorf("empty search query")
	}

	encodedQuery := url.QueryEscape(query)
	searchURL := fmt.Sprintf("https://lyrics.paxsenix.org/apple-music/search?q=%s", encodedQuery)

	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("User-Agent", appUserAgent())
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("apple music search failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("apple music search returned HTTP %d", resp.StatusCode)
	}

	var searchResp []appleMusicSearchResult
	if err := json.NewDecoder(resp.Body).Decode(&searchResp); err != nil {
		return "", fmt.Errorf("failed to decode apple music response: %w", err)
	}

	best := selectBestAppleMusicSearchResult(searchResp, trackName, artistName, durationSec)
	if best == nil || strings.TrimSpace(best.ID) == "" {
		return "", fmt.Errorf("no songs found on apple music")
	}

	return strings.TrimSpace(best.ID), nil
}

func (c *AppleMusicClient) FetchLyricsByID(songID string) (string, error) {
	lyricsURL := fmt.Sprintf("https://lyrics.paxsenix.org/apple-music/lyrics?id=%s", songID)

	req, err := http.NewRequest("GET", lyricsURL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("User-Agent", appUserAgent())
	req.Header.Set("Accept", "application/json")

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

func formatPaxLyricsToLRC(rawJSON string, multiPersonWordByWord bool) (string, error) {
	var paxResp paxResponse
	if err := json.Unmarshal([]byte(rawJSON), &paxResp); err == nil && paxResp.Content != nil {
		return formatPaxContent(paxResp.Type, paxResp.Content, multiPersonWordByWord), nil
	}

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

func (c *AppleMusicClient) FetchLyrics(
	trackName,
	artistName string,
	durationSec float64,
	multiPersonWordByWord bool,
) (*LyricsResponse, error) {
	songID, err := c.SearchSong(trackName, artistName, durationSec)
	if err != nil {
		return nil, err
	}

	rawLyrics, err := c.FetchLyricsByID(songID)
	if err != nil {
		return nil, err
	}
	if errMsg, isErrorPayload := detectLyricsErrorPayload(rawLyrics); isErrorPayload {
		return nil, fmt.Errorf("apple music proxy returned non-lyric payload: %s", errMsg)
	}

	lrcText, err := formatPaxLyricsToLRC(rawLyrics, multiPersonWordByWord)
	if err != nil {
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

	resultLines := plainTextLyricsLines(lrcText)

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
