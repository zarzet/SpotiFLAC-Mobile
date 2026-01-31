package gobackend

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
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
}

var (
	globalSongLinkClient *SongLinkClient
	songLinkClientOnce   sync.Once
)

func NewSongLinkClient() *SongLinkClient {
	songLinkClientOnce.Do(func() {
		globalSongLinkClient = &SongLinkClient{
			client: NewHTTPClientWithTimeout(SongLinkTimeout),
		}
	})
	return globalSongLinkClient
}

func (s *SongLinkClient) CheckTrackAvailability(spotifyTrackID string, isrc string) (*TrackAvailability, error) {
	if spotifyTrackID == "" {
		return nil, fmt.Errorf("spotify track ID is empty")
	}

	// Try SongLink first
	availability, err := s.checkTrackAvailabilitySongLink(spotifyTrackID)
	if err != nil {
		// Fallback to IDHS if SongLink fails
		LogWarn("SongLink", "SongLink failed, trying IDHS fallback: %v", err)
		idhsClient := NewIDHSClient()
		availability, err = idhsClient.GetAvailabilityFromSpotify(spotifyTrackID)
		if err != nil {
			return nil, fmt.Errorf("both SongLink and IDHS failed: %w", err)
		}
		LogInfo("SongLink", "IDHS fallback successful for %s", spotifyTrackID)
	}

	// Check Qobuz availability separately via ISRC
	if isrc != "" {
		availability.Qobuz = checkQobuzAvailability(isrc)
	}

	return availability, nil
}

// checkTrackAvailabilitySongLink is the original SongLink implementation
func (s *SongLinkClient) checkTrackAvailabilitySongLink(spotifyTrackID string) (*TrackAvailability, error) {
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

func checkQobuzAvailability(isrc string) bool {
	client := NewHTTPClientWithTimeout(10 * time.Second)
	appID := "798273057"

	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly93d3cucW9idXouY29tL2FwaS5qc29uLzAuMi90cmFjay9zZWFyY2g/cXVlcnk9")
	searchURL := fmt.Sprintf("%s%s&limit=1&app_id=%s", string(apiBase), isrc, appID)

	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return false
	}

	resp, err := DoRequestWithUserAgent(client, req)
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return false
	}

	var searchResp struct {
		Tracks struct {
			Total int `json:"total"`
		} `json:"tracks"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&searchResp); err != nil {
		return false
	}

	return searchResp.Tracks.Total > 0
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
	// Use global rate limiter
	songLinkRateLimiter.WaitForSlot()

	// Build API URL for album
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

	// Try SongLink first
	availability, err := s.checkAvailabilityFromDeezerSongLink(deezerTrackID)
	if err != nil {
		// Fallback to IDHS if SongLink fails
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

	// Handle specific error codes
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
	}

	if amazonLink, ok := songLinkResp.LinksByPlatform["amazonMusic"]; ok && amazonLink.URL != "" {
		availability.Amazon = true
		availability.AmazonURL = amazonLink.URL
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

	// Use global rate limiter
	songLinkRateLimiter.WaitForSlot()

	// Build API URL using platform, type, and id parameters (as per API docs)
	// https://api.song.link/v1-alpha.1/links?platform=deezer&type=song&id=123456
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

	// Handle specific error codes
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
