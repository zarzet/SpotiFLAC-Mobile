package gobackend

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"sync"
)

type SongLinkClient struct {
	client *http.Client
}

type TrackAvailability struct {
	SpotifyID string `json:"spotify_id"`
	Tidal     bool   `json:"tidal"`
	Amazon    bool   `json:"amazon"`
	Qobuz     bool   `json:"qobuz"`
	Deezer    bool   `json:"deezer"`
	TidalURL  string `json:"tidal_url,omitempty"`
	AmazonURL string `json:"amazon_url,omitempty"`
	QobuzURL  string `json:"qobuz_url,omitempty"`
	DeezerURL string `json:"deezer_url,omitempty"`
	DeezerID  string `json:"deezer_id,omitempty"`
	QobuzID   string `json:"qobuz_id,omitempty"`
	TidalID   string `json:"tidal_id,omitempty"`
}

var (
	globalSongLinkClient *SongLinkClient
	songLinkClientOnce   sync.Once
)

func NewSongLinkClient() *SongLinkClient {
	songLinkClientOnce.Do(func() {
		globalSongLinkClient = &SongLinkClient{
			client: NewMetadataHTTPClient(SongLinkTimeout),
		}
	})
	return globalSongLinkClient
}

func (s *SongLinkClient) CheckTrackAvailability(spotifyTrackID string, isrc string) (*TrackAvailability, error) {
	songLinkRateLimiter.WaitForSlot()

	spotifyBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9vcGVuLnNwb3RpZnkuY29tL3RyYWNrLw==")
	spotifyURL := fmt.Sprintf("%s%s", string(spotifyBase), spotifyTrackID)

	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkuc29uZy5saW5rL3YxLWFscGhhLjEvbGlua3M/dXJsPQ==")
	apiURL := fmt.Sprintf("%s%s", string(apiBase), url.QueryEscape(spotifyURL))

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	retryConfig := DefaultRetryConfig()
	resp, err := DoRequestWithRetry(s.client, req, retryConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to check availability: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 400 {
		return nil, fmt.Errorf("track not found on SongLink (invalid Spotify ID or track unavailable)")
	}
	if resp.StatusCode == 404 {
		return nil, fmt.Errorf("track not found on any streaming platform")
	}
	if resp.StatusCode == 429 {
		return nil, fmt.Errorf("SongLink rate limit exceeded")
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("SongLink API returned status %d", resp.StatusCode)
	}

	body, err := ReadResponseBody(resp)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var songLinkResp struct {
		LinksByPlatform map[string]struct {
			URL string `json:"url"`
		} `json:"linksByPlatform"`
	}

	if err := json.Unmarshal(body, &songLinkResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	availability := &TrackAvailability{
		SpotifyID: spotifyTrackID,
	}

	if tidalLink, ok := songLinkResp.LinksByPlatform["tidal"]; ok && tidalLink.URL != "" {
		availability.Tidal = true
		availability.TidalURL = tidalLink.URL
		availability.TidalID = extractTidalIDFromURL(tidalLink.URL)
	}

	if amazonLink, ok := songLinkResp.LinksByPlatform["amazonMusic"]; ok && amazonLink.URL != "" {
		availability.Amazon = true
		availability.AmazonURL = amazonLink.URL
	}

	if deezerLink, ok := songLinkResp.LinksByPlatform["deezer"]; ok && deezerLink.URL != "" {
		availability.Deezer = true
		availability.DeezerURL = deezerLink.URL
		availability.DeezerID = extractDeezerIDFromURL(deezerLink.URL)
	}

	if qobuzLink, ok := songLinkResp.LinksByPlatform["qobuz"]; ok && qobuzLink.URL != "" {
		availability.Qobuz = true
		availability.QobuzURL = qobuzLink.URL
		availability.QobuzID = extractQobuzIDFromURL(qobuzLink.URL)
	}

	return availability, nil
}

func (s *SongLinkClient) GetStreamingURLs(spotifyTrackID string) (map[string]string, error) {
	availability, err := s.CheckTrackAvailability(spotifyTrackID, "")
	if err != nil {
		return nil, err
	}

	urls := make(map[string]string)
	if availability.TidalURL != "" {
		urls["tidal"] = availability.TidalURL
	}
	if availability.AmazonURL != "" {
		urls["amazon"] = availability.AmazonURL
	}

	return urls, nil
}

// extractDeezerIDFromURL extracts Deezer track/album/artist ID from URL
func extractDeezerIDFromURL(deezerURL string) string {
	parts := strings.Split(deezerURL, "/")
	if len(parts) > 0 {
		lastPart := parts[len(parts)-1]
		if idx := strings.Index(lastPart, "?"); idx > 0 {
			lastPart = lastPart[:idx]
		}
		return lastPart
	}
	return ""
}

// extractQobuzIDFromURL extracts Qobuz track ID from URL
// URL formats:
//   - https://www.qobuz.com/us-en/album/.../12345678 (album page with track highlight)
//   - https://open.qobuz.com/track/12345678
//   - https://www.qobuz.com/track/12345678
//   - https://play.qobuz.com/track/12345678
func extractQobuzIDFromURL(qobuzURL string) string {
	if qobuzURL == "" {
		return ""
	}

	// Try to find /track/ID pattern first
	if strings.Contains(qobuzURL, "/track/") {
		parts := strings.Split(qobuzURL, "/track/")
		if len(parts) > 1 {
			idPart := parts[1]
			// Remove query parameters
			if idx := strings.Index(idPart, "?"); idx > 0 {
				idPart = idPart[:idx]
			}
			// Remove trailing slash or path
			if idx := strings.Index(idPart, "/"); idx > 0 {
				idPart = idPart[:idx]
			}
			idPart = strings.TrimSpace(idPart)
			// Validate it's a number
			if idPart != "" && isNumeric(idPart) {
				return idPart
			}
		}
	}

	// Try to extract from album URL with track highlight
	// Format: /album/albumname/trackid or ?trackId=12345678
	if strings.Contains(qobuzURL, "trackId=") {
		parts := strings.Split(qobuzURL, "trackId=")
		if len(parts) > 1 {
			idPart := parts[1]
			if idx := strings.Index(idPart, "&"); idx > 0 {
				idPart = idPart[:idx]
			}
			idPart = strings.TrimSpace(idPart)
			if idPart != "" && isNumeric(idPart) {
				return idPart
			}
		}
	}

	// Last resort: get last numeric segment from URL
	parts := strings.Split(qobuzURL, "/")
	for i := len(parts) - 1; i >= 0; i-- {
		part := parts[i]
		// Remove query parameters
		if idx := strings.Index(part, "?"); idx > 0 {
			part = part[:idx]
		}
		part = strings.TrimSpace(part)
		if part != "" && isNumeric(part) {
			return part
		}
	}

	return ""
}

// extractTidalIDFromURL extracts Tidal track ID from URL
// URL formats:
//   - https://tidal.com/browse/track/12345678
//   - https://listen.tidal.com/track/12345678
func extractTidalIDFromURL(tidalURL string) string {
	if tidalURL == "" {
		return ""
	}

	if strings.Contains(tidalURL, "/track/") {
		parts := strings.Split(tidalURL, "/track/")
		if len(parts) > 1 {
			idPart := parts[1]
			if idx := strings.Index(idPart, "?"); idx > 0 {
				idPart = idPart[:idx]
			}
			if idx := strings.Index(idPart, "/"); idx > 0 {
				idPart = idPart[:idx]
			}
			idPart = strings.TrimSpace(idPart)
			if idPart != "" && isNumeric(idPart) {
				return idPart
			}
		}
	}

	return ""
}

// isNumeric is defined in library_scan.go

func (s *SongLinkClient) GetDeezerIDFromSpotify(spotifyTrackID string) (string, error) {
	availability, err := s.CheckTrackAvailability(spotifyTrackID, "")
	if err != nil {
		return "", err
	}

	if !availability.Deezer || availability.DeezerID == "" {
		return "", fmt.Errorf("track not found on Deezer")
	}

	return availability.DeezerID, nil
}

// AlbumAvailability represents album availability on different platforms
type AlbumAvailability struct {
	SpotifyID string `json:"spotify_id"`
	Deezer    bool   `json:"deezer"`
	DeezerURL string `json:"deezer_url,omitempty"`
	DeezerID  string `json:"deezer_id,omitempty"`
}

func (s *SongLinkClient) CheckAlbumAvailability(spotifyAlbumID string) (*AlbumAvailability, error) {
	songLinkRateLimiter.WaitForSlot()

	spotifyBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9vcGVuLnNwb3RpZnkuY29tL2FsYnVtLw==")
	spotifyURL := fmt.Sprintf("%s%s", string(spotifyBase), spotifyAlbumID)

	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkuc29uZy5saW5rL3YxLWFscGhhLjEvbGlua3M/dXJsPQ==")
	apiURL := fmt.Sprintf("%s%s", string(apiBase), url.QueryEscape(spotifyURL))

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	retryConfig := DefaultRetryConfig()
	resp, err := DoRequestWithRetry(s.client, req, retryConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to check album availability: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}

	body, err := ReadResponseBody(resp)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var songLinkResp struct {
		LinksByPlatform map[string]struct {
			URL string `json:"url"`
		} `json:"linksByPlatform"`
	}

	if err := json.Unmarshal(body, &songLinkResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	availability := &AlbumAvailability{
		SpotifyID: spotifyAlbumID,
	}

	if deezerLink, ok := songLinkResp.LinksByPlatform["deezer"]; ok && deezerLink.URL != "" {
		availability.Deezer = true
		availability.DeezerURL = deezerLink.URL
		availability.DeezerID = extractDeezerIDFromURL(deezerLink.URL)
	}

	return availability, nil
}

// GetDeezerAlbumIDFromSpotify converts a Spotify album ID to Deezer album ID using SongLink
func (s *SongLinkClient) GetDeezerAlbumIDFromSpotify(spotifyAlbumID string) (string, error) {
	availability, err := s.CheckAlbumAvailability(spotifyAlbumID)
	if err != nil {
		return "", err
	}

	if !availability.Deezer || availability.DeezerID == "" {
		return "", fmt.Errorf("album not found on Deezer")
	}

	return availability.DeezerID, nil
}

// This is useful when we have Deezer metadata and want to find the track on other platforms
func (s *SongLinkClient) CheckAvailabilityFromDeezer(deezerTrackID string) (*TrackAvailability, error) {
	if deezerTrackID == "" {
		return nil, fmt.Errorf("deezer track ID is empty")
	}

	availability, err := s.checkAvailabilityFromDeezerSongLink(deezerTrackID)
	if err != nil {
		LogWarn("SongLink", "SongLink failed for Deezer, trying IDHS fallback: %v", err)
		idhsClient := NewIDHSClient()
		availability, err = idhsClient.GetAvailabilityFromDeezer(deezerTrackID)
		if err != nil {
			return nil, fmt.Errorf("both SongLink and IDHS failed: %w", err)
		}
		LogInfo("SongLink", "IDHS fallback successful for Deezer %s", deezerTrackID)
	}

	return availability, nil
}

// checkAvailabilityFromDeezerSongLink is the original SongLink implementation for Deezer
func (s *SongLinkClient) checkAvailabilityFromDeezerSongLink(deezerTrackID string) (*TrackAvailability, error) {
	songLinkRateLimiter.WaitForSlot()

	deezerURL := fmt.Sprintf("https://www.deezer.com/track/%s", deezerTrackID)

	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkuc29uZy5saW5rL3YxLWFscGhhLjEvbGlua3M/dXJsPQ==")
	apiURL := fmt.Sprintf("%s%s&userCountry=US", string(apiBase), url.QueryEscape(deezerURL))

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	retryConfig := DefaultRetryConfig()
	resp, err := DoRequestWithRetry(s.client, req, retryConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to check availability: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 400 {
		return nil, fmt.Errorf("track not found on SongLink (invalid Deezer ID)")
	}
	if resp.StatusCode == 404 {
		return nil, fmt.Errorf("track not found on any streaming platform")
	}
	if resp.StatusCode == 429 {
		return nil, fmt.Errorf("SongLink rate limit exceeded")
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("SongLink API returned status %d", resp.StatusCode)
	}

	body, err := ReadResponseBody(resp)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var songLinkResp struct {
		LinksByPlatform map[string]struct {
			URL string `json:"url"`
		} `json:"linksByPlatform"`
		EntitiesByUniqueId map[string]struct {
			ID         string `json:"id"`
			Type       string `json:"type"`
			Title      string `json:"title"`
			ArtistName string `json:"artistName"`
		} `json:"entitiesByUniqueId"`
	}

	if err := json.Unmarshal(body, &songLinkResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	availability := &TrackAvailability{
		Deezer:   true,
		DeezerID: deezerTrackID,
	}

	if spotifyLink, ok := songLinkResp.LinksByPlatform["spotify"]; ok && spotifyLink.URL != "" {
		availability.SpotifyID = extractSpotifyIDFromURL(spotifyLink.URL)
	}

	if tidalLink, ok := songLinkResp.LinksByPlatform["tidal"]; ok && tidalLink.URL != "" {
		availability.Tidal = true
		availability.TidalURL = tidalLink.URL
		availability.TidalID = extractTidalIDFromURL(tidalLink.URL)
	}

	if amazonLink, ok := songLinkResp.LinksByPlatform["amazonMusic"]; ok && amazonLink.URL != "" {
		availability.Amazon = true
		availability.AmazonURL = amazonLink.URL
	}

	if qobuzLink, ok := songLinkResp.LinksByPlatform["qobuz"]; ok && qobuzLink.URL != "" {
		availability.Qobuz = true
		availability.QobuzURL = qobuzLink.URL
		availability.QobuzID = extractQobuzIDFromURL(qobuzLink.URL)
	}

	if deezerLink, ok := songLinkResp.LinksByPlatform["deezer"]; ok && deezerLink.URL != "" {
		availability.DeezerURL = deezerLink.URL
	}

	return availability, nil
}

// platform: "spotify", "deezer", "tidal", "amazonMusic", "appleMusic", "youtube", etc.
// entityType: "song" or "album"
// entityID: the ID on that platform
func (s *SongLinkClient) CheckAvailabilityByPlatform(platform, entityType, entityID string) (*TrackAvailability, error) {
	if entityID == "" {
		return nil, fmt.Errorf("%s ID is empty", platform)
	}

	songLinkRateLimiter.WaitForSlot()

	apiURL := fmt.Sprintf("https://api.song.link/v1-alpha.1/links?platform=%s&type=%s&id=%s&userCountry=US",
		url.QueryEscape(platform),
		url.QueryEscape(entityType),
		url.QueryEscape(entityID))

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	retryConfig := DefaultRetryConfig()
	resp, err := DoRequestWithRetry(s.client, req, retryConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to check availability: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 400 {
		return nil, fmt.Errorf("track not found on SongLink (invalid %s ID)", platform)
	}
	if resp.StatusCode == 404 {
		return nil, fmt.Errorf("track not found on any streaming platform")
	}
	if resp.StatusCode == 429 {
		return nil, fmt.Errorf("SongLink rate limit exceeded")
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("SongLink API returned status %d", resp.StatusCode)
	}

	body, err := ReadResponseBody(resp)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var songLinkResp struct {
		LinksByPlatform map[string]struct {
			URL string `json:"url"`
		} `json:"linksByPlatform"`
	}

	if err := json.Unmarshal(body, &songLinkResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	availability := &TrackAvailability{}

	if spotifyLink, ok := songLinkResp.LinksByPlatform["spotify"]; ok && spotifyLink.URL != "" {
		availability.SpotifyID = extractSpotifyIDFromURL(spotifyLink.URL)
	}

	if tidalLink, ok := songLinkResp.LinksByPlatform["tidal"]; ok && tidalLink.URL != "" {
		availability.Tidal = true
		availability.TidalURL = tidalLink.URL
		availability.TidalID = extractTidalIDFromURL(tidalLink.URL)
	}

	if amazonLink, ok := songLinkResp.LinksByPlatform["amazonMusic"]; ok && amazonLink.URL != "" {
		availability.Amazon = true
		availability.AmazonURL = amazonLink.URL
	}

	if qobuzLink, ok := songLinkResp.LinksByPlatform["qobuz"]; ok && qobuzLink.URL != "" {
		availability.Qobuz = true
		availability.QobuzURL = qobuzLink.URL
		availability.QobuzID = extractQobuzIDFromURL(qobuzLink.URL)
	}

	if deezerLink, ok := songLinkResp.LinksByPlatform["deezer"]; ok && deezerLink.URL != "" {
		availability.Deezer = true
		availability.DeezerURL = deezerLink.URL
		availability.DeezerID = extractDeezerIDFromURL(deezerLink.URL)
	}

	return availability, nil
}

// extractSpotifyIDFromURL extracts Spotify track ID from URL
func extractSpotifyIDFromURL(spotifyURL string) string {
	parts := strings.Split(spotifyURL, "/track/")
	if len(parts) > 1 {
		idPart := parts[1]
		if idx := strings.Index(idPart, "?"); idx > 0 {
			idPart = idPart[:idx]
		}
		return idPart
	}
	return ""
}

func (s *SongLinkClient) GetSpotifyIDFromDeezer(deezerTrackID string) (string, error) {
	availability, err := s.CheckAvailabilityFromDeezer(deezerTrackID)
	if err != nil {
		return "", err
	}

	if availability.SpotifyID == "" {
		return "", fmt.Errorf("track not found on Spotify")
	}

	return availability.SpotifyID, nil
}

// GetTidalURLFromDeezer converts a Deezer track ID to Tidal URL using SongLink
func (s *SongLinkClient) GetTidalURLFromDeezer(deezerTrackID string) (string, error) {
	availability, err := s.CheckAvailabilityFromDeezer(deezerTrackID)
	if err != nil {
		return "", err
	}

	if !availability.Tidal || availability.TidalURL == "" {
		return "", fmt.Errorf("track not found on Tidal")
	}

	return availability.TidalURL, nil
}

func (s *SongLinkClient) GetAmazonURLFromDeezer(deezerTrackID string) (string, error) {
	availability, err := s.CheckAvailabilityFromDeezer(deezerTrackID)
	if err != nil {
		return "", err
	}

	if !availability.Amazon || availability.AmazonURL == "" {
		return "", fmt.Errorf("track not found on Amazon Music")
	}

	return availability.AmazonURL, nil
}

func (s *SongLinkClient) CheckAvailabilityFromURL(inputURL string) (*TrackAvailability, error) {
	songLinkRateLimiter.WaitForSlot()

	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkuc29uZy5saW5rL3YxLWFscGhhLjEvbGlua3M/dXJsPQ==")
	apiURL := fmt.Sprintf("%s%s", string(apiBase), url.QueryEscape(inputURL))

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	retryConfig := DefaultRetryConfig()
	resp, err := DoRequestWithRetry(s.client, req, retryConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to check availability: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 400 || resp.StatusCode == 404 {
		return nil, fmt.Errorf("track not found on SongLink")
	}
	if resp.StatusCode == 429 {
		return nil, fmt.Errorf("SongLink rate limit exceeded")
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("SongLink API returned status %d", resp.StatusCode)
	}

	body, err := ReadResponseBody(resp)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var songLinkResp struct {
		LinksByPlatform map[string]struct {
			URL      string `json:"url"`
			EntityID string `json:"entityUniqueId"`
		} `json:"linksByPlatform"`
	}

	if err := json.Unmarshal(body, &songLinkResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	availability := &TrackAvailability{}

	if spotifyLink, ok := songLinkResp.LinksByPlatform["spotify"]; ok && spotifyLink.URL != "" {
		availability.SpotifyID = extractSpotifyIDFromURL(spotifyLink.URL)
	}
	if tidalLink, ok := songLinkResp.LinksByPlatform["tidal"]; ok && tidalLink.URL != "" {
		availability.Tidal = true
		availability.TidalURL = tidalLink.URL
		availability.TidalID = extractTidalIDFromURL(tidalLink.URL)
	}
	if amazonLink, ok := songLinkResp.LinksByPlatform["amazonMusic"]; ok && amazonLink.URL != "" {
		availability.Amazon = true
		availability.AmazonURL = amazonLink.URL
	}
	if qobuzLink, ok := songLinkResp.LinksByPlatform["qobuz"]; ok && qobuzLink.URL != "" {
		availability.Qobuz = true
		availability.QobuzURL = qobuzLink.URL
		availability.QobuzID = extractQobuzIDFromURL(qobuzLink.URL)
	}
	if deezerLink, ok := songLinkResp.LinksByPlatform["deezer"]; ok && deezerLink.URL != "" {
		availability.Deezer = true
		availability.DeezerURL = deezerLink.URL
		availability.DeezerID = extractDeezerIDFromURL(deezerLink.URL)
	}

	return availability, nil
}
