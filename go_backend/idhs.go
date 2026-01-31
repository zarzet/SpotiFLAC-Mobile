package gobackend

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
)

// IDHSClient is a client for I Don't Have Spotify API
// Used as fallback when SongLink fails or is rate limited
type IDHSClient struct {
	client *http.Client
}

var (
	globalIDHSClient *IDHSClient
	idhsClientOnce   sync.Once
	idhsRateLimiter  = NewRateLimiter(8, time.Minute) // 8 req/min (below 10 limit)
)

// IDHSSearchRequest represents the request body for IDHS API
type IDHSSearchRequest struct {
	Link     string   `json:"link"`
	Adapters []string `json:"adapters,omitempty"`
}

// IDHSSearchResponse represents the response from IDHS API
type IDHSSearchResponse struct {
	ID            string     `json:"id"`
	Type          string     `json:"type"` // song, album, artist, podcast, show
	Title         string     `json:"title"`
	Description   string     `json:"description"`
	Image         string     `json:"image,omitempty"`
	Audio         string     `json:"audio,omitempty"`
	Source        string     `json:"source"`
	UniversalLink string     `json:"universalLink"`
	Links         []IDHSLink `json:"links"`
}

// IDHSLink represents a link to a streaming platform
type IDHSLink struct {
	Type         string `json:"type"` // spotify, youTube, appleMusic, deezer, soundCloud, tidal
	URL          string `json:"url"`
	IsVerified   bool   `json:"isVerified,omitempty"`
	NotAvailable bool   `json:"notAvailable,omitempty"`
}

// NewIDHSClient creates a new IDHS client
func NewIDHSClient() *IDHSClient {
	idhsClientOnce.Do(func() {
		globalIDHSClient = &IDHSClient{
			client: NewHTTPClientWithTimeout(15 * time.Second),
		}
	})
	return globalIDHSClient
}

// Search converts a music link to links on other platforms
func (c *IDHSClient) Search(link string, adapters []string) (*IDHSSearchResponse, error) {
	idhsRateLimiter.WaitForSlot()

	reqBody := IDHSSearchRequest{
		Link:     link,
		Adapters: adapters,
	}

	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", "https://idonthavespotify.sjdonado.com/api/search?v=1", bytes.NewBuffer(jsonBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 400 {
		return nil, fmt.Errorf("invalid link or missing parameters")
	}
	if resp.StatusCode == 429 {
		return nil, fmt.Errorf("IDHS rate limit exceeded")
	}
	if resp.StatusCode == 500 {
		return nil, fmt.Errorf("IDHS processing failed")
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("IDHS API returned status %d", resp.StatusCode)
	}

	body, err := ReadResponseBody(resp)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var result IDHSSearchResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &result, nil
}

// GetAvailabilityFromSpotify checks track availability using IDHS as fallback
func (c *IDHSClient) GetAvailabilityFromSpotify(spotifyTrackID string) (*TrackAvailability, error) {
	spotifyURL := fmt.Sprintf("https://open.spotify.com/track/%s", spotifyTrackID)

	// Request only the platforms we need
	adapters := []string{"tidal", "deezer"}

	result, err := c.Search(spotifyURL, adapters)
	if err != nil {
		return nil, err
	}

	availability := &TrackAvailability{
		SpotifyID: spotifyTrackID,
	}

	for _, link := range result.Links {
		if link.NotAvailable {
			continue
		}

		switch strings.ToLower(link.Type) {
		case "tidal":
			availability.Tidal = true
			availability.TidalURL = link.URL
		case "deezer":
			availability.Deezer = true
			availability.DeezerURL = link.URL
			availability.DeezerID = extractDeezerIDFromURL(link.URL)
		}
	}

	LogDebug("IDHS", "Availability from Spotify %s: Tidal=%v, Deezer=%v",
		spotifyTrackID, availability.Tidal, availability.Deezer)

	return availability, nil
}

// GetAvailabilityFromDeezer checks track availability using IDHS
func (c *IDHSClient) GetAvailabilityFromDeezer(deezerTrackID string) (*TrackAvailability, error) {
	deezerURL := fmt.Sprintf("https://www.deezer.com/track/%s", deezerTrackID)

	// Request only the platforms we need
	adapters := []string{"spotify", "tidal"}

	result, err := c.Search(deezerURL, adapters)
	if err != nil {
		return nil, err
	}

	availability := &TrackAvailability{
		Deezer:   true,
		DeezerID: deezerTrackID,
	}

	for _, link := range result.Links {
		if link.NotAvailable {
			continue
		}

		switch strings.ToLower(link.Type) {
		case "spotify":
			availability.SpotifyID = extractSpotifyIDFromURL(link.URL)
		case "tidal":
			availability.Tidal = true
			availability.TidalURL = link.URL
		}
	}

	LogDebug("IDHS", "Availability from Deezer %s: Spotify=%s, Tidal=%v",
		deezerTrackID, availability.SpotifyID, availability.Tidal)

	return availability, nil
}
