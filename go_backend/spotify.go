package gobackend

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"
)

const (
	spotifyTokenURL = "https://accounts.spotify.com/api/token"
	playlistBaseURL = "https://api.spotify.com/v1/playlists/%s"
	albumBaseURL    = "https://api.spotify.com/v1/albums/%s"
	trackBaseURL    = "https://api.spotify.com/v1/tracks/%s"
	artistBaseURL   = "https://api.spotify.com/v1/artists/%s"
	artistAlbumsURL = "https://api.spotify.com/v1/artists/%s/albums"
	searchBaseURL   = "https://api.spotify.com/v1/search"

	// Cache TTL settings
	artistCacheTTL = 10 * time.Minute
	searchCacheTTL = 5 * time.Minute
	albumCacheTTL  = 10 * time.Minute
)

var errInvalidSpotifyURL = errors.New("invalid or unsupported Spotify URL")

// cacheEntry holds cached data with expiration
type cacheEntry struct {
	data      interface{}
	expiresAt time.Time
}

func (e *cacheEntry) isExpired() bool {
	return time.Now().After(e.expiresAt)
}

// SpotifyMetadataClient handles Spotify API interactions
type SpotifyMetadataClient struct {
	httpClient     *http.Client
	clientID       string
	clientSecret   string
	cachedToken    string
	tokenExpiresAt time.Time
	tokenMu        sync.Mutex // Protects token cache for concurrent access
	rng            *rand.Rand
	rngMu          sync.Mutex
	userAgent      string

	// Caches to reduce API calls
	artistCache map[string]*cacheEntry // key: artistID
	searchCache map[string]*cacheEntry // key: query+type
	albumCache  map[string]*cacheEntry // key: albumID
	cacheMu     sync.RWMutex
}

// Custom credentials storage (set from Flutter)
var (
	customClientID     string
	customClientSecret string
	credentialsMu      sync.RWMutex
)

// ErrNoSpotifyCredentials is returned when Spotify credentials are not configured
var ErrNoSpotifyCredentials = errors.New("Spotify credentials not configured. Please set your own Client ID and Secret in Settings, or use Deezer as metadata source (free, no credentials required)")

// SetSpotifyCredentials sets custom Spotify API credentials
func SetSpotifyCredentials(clientID, clientSecret string) {
	credentialsMu.Lock()
	defer credentialsMu.Unlock()
	customClientID = clientID
	customClientSecret = clientSecret
}

// HasSpotifyCredentials checks if Spotify credentials are configured
func HasSpotifyCredentials() bool {
	credentialsMu.RLock()
	defer credentialsMu.RUnlock()

	// Check custom credentials first
	if customClientID != "" && customClientSecret != "" {
		return true
	}

	// Check environment variables
	if os.Getenv("SPOTIFY_CLIENT_ID") != "" && os.Getenv("SPOTIFY_CLIENT_SECRET") != "" {
		return true
	}

	return false
}

// getCredentials returns the current credentials or error if not configured
func getCredentials() (string, string, error) {
	credentialsMu.RLock()
	defer credentialsMu.RUnlock()

	// Check custom credentials first
	if customClientID != "" && customClientSecret != "" {
		return customClientID, customClientSecret, nil
	}

	// Check environment variables
	clientID := os.Getenv("SPOTIFY_CLIENT_ID")
	clientSecret := os.Getenv("SPOTIFY_CLIENT_SECRET")

	if clientID != "" && clientSecret != "" {
		return clientID, clientSecret, nil
	}

	// No credentials available
	return "", "", ErrNoSpotifyCredentials
}

// NewSpotifyMetadataClient creates a new Spotify client
// Returns error if credentials are not configured
func NewSpotifyMetadataClient() (*SpotifyMetadataClient, error) {
	// Get credentials - will error if not configured
	clientID, clientSecret, err := getCredentials()
	if err != nil {
		return nil, err
	}

	src := rand.NewSource(time.Now().UnixNano())

	c := &SpotifyMetadataClient{
		httpClient:   NewHTTPClientWithTimeout(15 * time.Second), // Use shared transport for connection pooling
		clientID:     clientID,
		clientSecret: clientSecret,
		rng:          rand.New(src),
		artistCache:  make(map[string]*cacheEntry),
		searchCache:  make(map[string]*cacheEntry),
		albumCache:   make(map[string]*cacheEntry),
	}
	c.userAgent = c.randomUserAgent()
	return c, nil
}

// TrackMetadata represents track information
type TrackMetadata struct {
	SpotifyID   string `json:"spotify_id,omitempty"`
	Artists     string `json:"artists"`
	Name        string `json:"name"`
	AlbumName   string `json:"album_name"`
	AlbumArtist string `json:"album_artist,omitempty"`
	DurationMS  int    `json:"duration_ms"`
	Images      string `json:"images"`
	ReleaseDate string `json:"release_date"`
	TrackNumber int    `json:"track_number"`
	TotalTracks int    `json:"total_tracks,omitempty"`
	DiscNumber  int    `json:"disc_number,omitempty"`
	ExternalURL string `json:"external_urls"`
	ISRC        string `json:"isrc"`
}

// AlbumTrackMetadata holds per-track info for album/playlist
type AlbumTrackMetadata struct {
	SpotifyID   string `json:"spotify_id,omitempty"`
	Artists     string `json:"artists"`
	Name        string `json:"name"`
	AlbumName   string `json:"album_name"`
	AlbumArtist string `json:"album_artist,omitempty"`
	DurationMS  int    `json:"duration_ms"`
	Images      string `json:"images"`
	ReleaseDate string `json:"release_date"`
	TrackNumber int    `json:"track_number"`
	TotalTracks int    `json:"total_tracks,omitempty"`
	DiscNumber  int    `json:"disc_number,omitempty"`
	ExternalURL string `json:"external_urls"`
	ISRC        string `json:"isrc"`
	AlbumID     string `json:"album_id,omitempty"`
	AlbumURL    string `json:"album_url,omitempty"`
}

// AlbumInfoMetadata holds album information
type AlbumInfoMetadata struct {
	TotalTracks int    `json:"total_tracks"`
	Name        string `json:"name"`
	ReleaseDate string `json:"release_date"`
	Artists     string `json:"artists"`
	Images      string `json:"images"`
}

// AlbumResponsePayload is the response for album requests
type AlbumResponsePayload struct {
	AlbumInfo AlbumInfoMetadata    `json:"album_info"`
	TrackList []AlbumTrackMetadata `json:"track_list"`
}

// PlaylistInfoMetadata holds playlist information
type PlaylistInfoMetadata struct {
	Tracks struct {
		Total int `json:"total"`
	} `json:"tracks"`
	Owner struct {
		DisplayName string `json:"display_name"`
		Name        string `json:"name"`
		Images      string `json:"images"`
	} `json:"owner"`
}

// PlaylistResponsePayload is the response for playlist requests
type PlaylistResponsePayload struct {
	PlaylistInfo PlaylistInfoMetadata `json:"playlist_info"`
	TrackList    []AlbumTrackMetadata `json:"track_list"`
}

// ArtistInfoMetadata holds artist information
type ArtistInfoMetadata struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	Images     string `json:"images"`
	Followers  int    `json:"followers"`
	Popularity int    `json:"popularity"`
}

// ArtistAlbumMetadata holds album info for artist discography
type ArtistAlbumMetadata struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	ReleaseDate string `json:"release_date"`
	TotalTracks int    `json:"total_tracks"`
	Images      string `json:"images"`
	AlbumType   string `json:"album_type"` // album, single, compilation
	Artists     string `json:"artists"`
}

// ArtistResponsePayload is the response for artist requests
type ArtistResponsePayload struct {
	ArtistInfo ArtistInfoMetadata    `json:"artist_info"`
	Albums     []ArtistAlbumMetadata `json:"albums"`
}

// TrackResponse is the response for single track requests
type TrackResponse struct {
	Track TrackMetadata `json:"track"`
}

// SearchResult represents search results
type SearchResult struct {
	Tracks []TrackMetadata `json:"tracks"`
	Total  int             `json:"total"`
}

// SearchArtistResult represents an artist in search results
type SearchArtistResult struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	Images     string `json:"images"`
	Followers  int    `json:"followers"`
	Popularity int    `json:"popularity"`
}

// SearchAllResult represents combined search results for tracks and artists
type SearchAllResult struct {
	Tracks  []TrackMetadata      `json:"tracks"`
	Artists []SearchArtistResult `json:"artists"`
}

type spotifyURI struct {
	Type string
	ID   string
}

type accessTokenResponse struct {
	AccessToken string      `json:"access_token"`
	ExpiresIn   interface{} `json:"expires_in"`
	TokenType   string      `json:"token_type"`
}

// Internal API response types
type image struct {
	URL string `json:"url"`
}

type externalURL struct {
	Spotify string `json:"spotify"`
}

type externalID struct {
	ISRC string `json:"isrc"`
}

type artist struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type albumSimplified struct {
	ID          string      `json:"id"`
	Name        string      `json:"name"`
	ReleaseDate string      `json:"release_date"`
	TotalTracks int         `json:"total_tracks"`
	Images      []image     `json:"images"`
	ExternalURL externalURL `json:"external_urls"`
	Artists     []artist    `json:"artists"`
}

type trackFull struct {
	ID          string          `json:"id"`
	Name        string          `json:"name"`
	DurationMS  int             `json:"duration_ms"`
	TrackNumber int             `json:"track_number"`
	DiscNumber  int             `json:"disc_number"`
	ExternalURL externalURL     `json:"external_urls"`
	ExternalID  externalID      `json:"external_ids"`
	Album       albumSimplified `json:"album"`
	Artists     []artist        `json:"artists"`
}

// GetFilteredData fetches and formats Spotify data
func (c *SpotifyMetadataClient) GetFilteredData(ctx context.Context, spotifyURL string, batch bool, delay time.Duration) (interface{}, error) {
	parsed, err := parseSpotifyURI(spotifyURL)
	if err != nil {
		return nil, err
	}

	token, err := c.getAccessToken(ctx)
	if err != nil {
		return nil, err
	}

	switch parsed.Type {
	case "track":
		return c.fetchTrack(ctx, parsed.ID, token)
	case "album":
		return c.fetchAlbum(ctx, parsed.ID, token)
	case "playlist":
		return c.fetchPlaylist(ctx, parsed.ID, token)
	case "artist":
		return c.fetchArtist(ctx, parsed.ID, token)
	default:
		return nil, fmt.Errorf("unsupported Spotify type: %s", parsed.Type)
	}
}

// SearchTracks searches for tracks on Spotify
func (c *SpotifyMetadataClient) SearchTracks(ctx context.Context, query string, limit int) (*SearchResult, error) {
	token, err := c.getAccessToken(ctx)
	if err != nil {
		return nil, err
	}

	searchURL := fmt.Sprintf("%s?q=%s&type=track&limit=%d", searchBaseURL, url.QueryEscape(query), limit)

	var response struct {
		Tracks struct {
			Items []trackFull `json:"items"`
			Total int         `json:"total"`
		} `json:"tracks"`
	}

	if err := c.getJSON(ctx, searchURL, token, &response); err != nil {
		return nil, err
	}

	result := &SearchResult{
		Tracks: make([]TrackMetadata, 0, len(response.Tracks.Items)),
		Total:  response.Tracks.Total,
	}

	for _, track := range response.Tracks.Items {
		result.Tracks = append(result.Tracks, TrackMetadata{
			SpotifyID:   track.ID,
			Artists:     joinArtists(track.Artists),
			Name:        track.Name,
			AlbumName:   track.Album.Name,
			AlbumArtist: joinArtists(track.Album.Artists),
			DurationMS:  track.DurationMS,
			Images:      firstImageURL(track.Album.Images),
			ReleaseDate: track.Album.ReleaseDate,
			TrackNumber: track.TrackNumber,
			TotalTracks: track.Album.TotalTracks,
			DiscNumber:  track.DiscNumber,
			ExternalURL: track.ExternalURL.Spotify,
			ISRC:        track.ExternalID.ISRC,
		})
	}

	return result, nil
}

// SearchAll searches for tracks and artists on Spotify
func (c *SpotifyMetadataClient) SearchAll(ctx context.Context, query string, trackLimit, artistLimit int) (*SearchAllResult, error) {
	// Create cache key
	cacheKey := fmt.Sprintf("all:%s:%d:%d", query, trackLimit, artistLimit)

	// Check cache first
	c.cacheMu.RLock()
	if entry, ok := c.searchCache[cacheKey]; ok && !entry.isExpired() {
		c.cacheMu.RUnlock()
		return entry.data.(*SearchAllResult), nil
	}
	c.cacheMu.RUnlock()

	token, err := c.getAccessToken(ctx)
	if err != nil {
		return nil, err
	}

	searchURL := fmt.Sprintf("%s?q=%s&type=track,artist&limit=%d", searchBaseURL, url.QueryEscape(query), trackLimit)

	var response struct {
		Tracks struct {
			Items []trackFull `json:"items"`
		} `json:"tracks"`
		Artists struct {
			Items []struct {
				ID        string  `json:"id"`
				Name      string  `json:"name"`
				Images    []image `json:"images"`
				Followers struct {
					Total int `json:"total"`
				} `json:"followers"`
				Popularity int `json:"popularity"`
			} `json:"items"`
		} `json:"artists"`
	}

	if err := c.getJSON(ctx, searchURL, token, &response); err != nil {
		return nil, err
	}

	result := &SearchAllResult{
		Tracks:  make([]TrackMetadata, 0, len(response.Tracks.Items)),
		Artists: make([]SearchArtistResult, 0, len(response.Artists.Items)),
	}

	for _, track := range response.Tracks.Items {
		result.Tracks = append(result.Tracks, TrackMetadata{
			SpotifyID:   track.ID,
			Artists:     joinArtists(track.Artists),
			Name:        track.Name,
			AlbumName:   track.Album.Name,
			AlbumArtist: joinArtists(track.Album.Artists),
			DurationMS:  track.DurationMS,
			Images:      firstImageURL(track.Album.Images),
			ReleaseDate: track.Album.ReleaseDate,
			TrackNumber: track.TrackNumber,
			TotalTracks: track.Album.TotalTracks,
			DiscNumber:  track.DiscNumber,
			ExternalURL: track.ExternalURL.Spotify,
			ISRC:        track.ExternalID.ISRC,
		})
	}

	// Limit artists to artistLimit
	artistCount := len(response.Artists.Items)
	if artistCount > artistLimit {
		artistCount = artistLimit
	}

	for i := 0; i < artistCount; i++ {
		artist := response.Artists.Items[i]
		result.Artists = append(result.Artists, SearchArtistResult{
			ID:         artist.ID,
			Name:       artist.Name,
			Images:     firstImageURL(artist.Images),
			Followers:  artist.Followers.Total,
			Popularity: artist.Popularity,
		})
	}

	// Store in cache
	c.cacheMu.Lock()
	c.searchCache[cacheKey] = &cacheEntry{
		data:      result,
		expiresAt: time.Now().Add(searchCacheTTL),
	}
	c.cacheMu.Unlock()

	return result, nil
}

func (c *SpotifyMetadataClient) fetchTrack(ctx context.Context, trackID, token string) (*TrackResponse, error) {
	var data trackFull
	if err := c.getJSON(ctx, fmt.Sprintf(trackBaseURL, trackID), token, &data); err != nil {
		return nil, err
	}

	return &TrackResponse{
		Track: TrackMetadata{
			SpotifyID:   data.ID,
			Artists:     joinArtists(data.Artists),
			Name:        data.Name,
			AlbumName:   data.Album.Name,
			AlbumArtist: joinArtists(data.Album.Artists),
			DurationMS:  data.DurationMS,
			Images:      firstImageURL(data.Album.Images),
			ReleaseDate: data.Album.ReleaseDate,
			TrackNumber: data.TrackNumber,
			TotalTracks: data.Album.TotalTracks,
			DiscNumber:  data.DiscNumber,
			ExternalURL: data.ExternalURL.Spotify,
			ISRC:        data.ExternalID.ISRC,
		},
	}, nil
}

func (c *SpotifyMetadataClient) fetchAlbum(ctx context.Context, albumID, token string) (*AlbumResponsePayload, error) {
	// Check cache first
	c.cacheMu.RLock()
	if entry, ok := c.albumCache[albumID]; ok && !entry.isExpired() {
		c.cacheMu.RUnlock()
		return entry.data.(*AlbumResponsePayload), nil
	}
	c.cacheMu.RUnlock()

	// Track item structure for pagination
	type trackItem struct {
		ID          string      `json:"id"`
		Name        string      `json:"name"`
		DurationMS  int         `json:"duration_ms"`
		TrackNumber int         `json:"track_number"`
		DiscNumber  int         `json:"disc_number"`
		ExternalURL externalURL `json:"external_urls"`
		Artists     []artist    `json:"artists"`
	}

	var data struct {
		Name        string   `json:"name"`
		ReleaseDate string   `json:"release_date"`
		TotalTracks int      `json:"total_tracks"`
		Images      []image  `json:"images"`
		Artists     []artist `json:"artists"`
		Tracks      struct {
			Items []trackItem `json:"items"`
			Next  string      `json:"next"`
		} `json:"tracks"`
	}

	if err := c.getJSON(ctx, fmt.Sprintf(albumBaseURL, albumID), token, &data); err != nil {
		return nil, err
	}

	albumImage := firstImageURL(data.Images)
	info := AlbumInfoMetadata{
		TotalTracks: data.TotalTracks,
		Name:        data.Name,
		ReleaseDate: data.ReleaseDate,
		Artists:     joinArtists(data.Artists),
		Images:      albumImage,
	}

	// Collect all tracks (including paginated)
	allTrackItems := data.Tracks.Items
	nextURL := data.Tracks.Next

	// Fetch remaining tracks using pagination (no limit)
	for nextURL != "" {
		var pageData struct {
			Items []trackItem `json:"items"`
			Next  string      `json:"next"`
		}
		if err := c.getJSON(ctx, nextURL, token, &pageData); err != nil {
			fmt.Printf("[Spotify] Warning: failed to fetch album tracks page: %v\n", err)
			break
		}
		allTrackItems = append(allTrackItems, pageData.Items...)
		nextURL = pageData.Next
	}

	fmt.Printf("[Spotify] Album has %d tracks (total: %d)\n", len(allTrackItems), data.TotalTracks)

	// Collect track IDs for parallel ISRC fetching
	trackIDs := make([]string, len(allTrackItems))
	for i, item := range allTrackItems {
		trackIDs[i] = item.ID
	}

	// Fetch ISRCs in parallel for ALL tracks (like Deezer implementation)
	isrcMap := c.fetchISRCsParallel(ctx, trackIDs, token)

	tracks := make([]AlbumTrackMetadata, 0, len(allTrackItems))
	for _, item := range allTrackItems {
		isrc := isrcMap[item.ID]

		tracks = append(tracks, AlbumTrackMetadata{
			SpotifyID:   item.ID,
			Artists:     joinArtists(item.Artists),
			Name:        item.Name,
			AlbumName:   data.Name,
			AlbumArtist: joinArtists(data.Artists),
			DurationMS:  item.DurationMS,
			Images:      albumImage,
			ReleaseDate: data.ReleaseDate,
			TrackNumber: item.TrackNumber,
			TotalTracks: data.TotalTracks,
			DiscNumber:  item.DiscNumber,
			ExternalURL: item.ExternalURL.Spotify,
			ISRC:        isrc,
			AlbumID:     albumID,
		})
	}

	result := &AlbumResponsePayload{
		AlbumInfo: info,
		TrackList: tracks,
	}

	// Store in cache
	c.cacheMu.Lock()
	c.albumCache[albumID] = &cacheEntry{
		data:      result,
		expiresAt: time.Now().Add(albumCacheTTL),
	}
	c.cacheMu.Unlock()

	return result, nil
}

// fetchISRCsParallel fetches ISRCs for multiple tracks in parallel
// Similar to Deezer implementation for consistency
func (c *SpotifyMetadataClient) fetchISRCsParallel(ctx context.Context, trackIDs []string, token string) map[string]string {
	const maxParallelISRC = 10 // Max concurrent ISRC fetches

	result := make(map[string]string)
	var resultMu sync.Mutex

	if len(trackIDs) == 0 {
		return result
	}

	// Use semaphore to limit concurrent requests
	sem := make(chan struct{}, maxParallelISRC)
	var wg sync.WaitGroup

	for _, trackID := range trackIDs {
		wg.Add(1)
		go func(id string) {
			defer wg.Done()

			// Acquire semaphore
			select {
			case sem <- struct{}{}:
				defer func() { <-sem }()
			case <-ctx.Done():
				return
			}

			isrc := c.fetchTrackISRC(ctx, id, token)

			resultMu.Lock()
			result[id] = isrc
			resultMu.Unlock()
		}(trackID)
	}

	wg.Wait()
	return result
}

func (c *SpotifyMetadataClient) fetchPlaylist(ctx context.Context, playlistID, token string) (*PlaylistResponsePayload, error) {
	// First request to get playlist info and first batch of tracks
	var data struct {
		Name   string  `json:"name"`
		Images []image `json:"images"`
		Owner  struct {
			DisplayName string `json:"display_name"`
		} `json:"owner"`
		Tracks struct {
			Items []struct {
				Track *trackFull `json:"track"`
			} `json:"items"`
			Total int    `json:"total"`
			Next  string `json:"next"`
		} `json:"tracks"`
	}

	if err := c.getJSON(ctx, fmt.Sprintf(playlistBaseURL, playlistID), token, &data); err != nil {
		return nil, err
	}

	var info PlaylistInfoMetadata
	info.Tracks.Total = data.Tracks.Total
	info.Owner.DisplayName = data.Owner.DisplayName
	info.Owner.Name = data.Name
	info.Owner.Images = firstImageURL(data.Images)

	// Pre-allocate with expected capacity
	tracks := make([]AlbumTrackMetadata, 0, data.Tracks.Total)

	// Add first batch of tracks
	for _, item := range data.Tracks.Items {
		if item.Track == nil {
			continue
		}
		tracks = append(tracks, AlbumTrackMetadata{
			SpotifyID:   item.Track.ID,
			Artists:     joinArtists(item.Track.Artists),
			Name:        item.Track.Name,
			AlbumName:   item.Track.Album.Name,
			AlbumArtist: joinArtists(item.Track.Album.Artists),
			DurationMS:  item.Track.DurationMS,
			Images:      firstImageURL(item.Track.Album.Images),
			ReleaseDate: item.Track.Album.ReleaseDate,
			TrackNumber: item.Track.TrackNumber,
			TotalTracks: item.Track.Album.TotalTracks,
			DiscNumber:  item.Track.DiscNumber,
			ExternalURL: item.Track.ExternalURL.Spotify,
			ISRC:        item.Track.ExternalID.ISRC,
			AlbumID:     item.Track.Album.ID,
			AlbumURL:    item.Track.Album.ExternalURL.Spotify,
		})
	}

	// Fetch remaining tracks using pagination (NO LIMIT - fetch all tracks)
	nextURL := data.Tracks.Next

	for nextURL != "" {
		var pageData struct {
			Items []struct {
				Track *trackFull `json:"track"`
			} `json:"items"`
			Next string `json:"next"`
		}

		if err := c.getJSON(ctx, nextURL, token, &pageData); err != nil {
			// Log error but return what we have so far
			fmt.Printf("[Spotify] Warning: failed to fetch page, returning %d tracks: %v\n", len(tracks), err)
			break
		}

		for _, item := range pageData.Items {
			if item.Track == nil {
				continue
			}
			tracks = append(tracks, AlbumTrackMetadata{
				SpotifyID:   item.Track.ID,
				Artists:     joinArtists(item.Track.Artists),
				Name:        item.Track.Name,
				AlbumName:   item.Track.Album.Name,
				AlbumArtist: joinArtists(item.Track.Album.Artists),
				DurationMS:  item.Track.DurationMS,
				Images:      firstImageURL(item.Track.Album.Images),
				ReleaseDate: item.Track.Album.ReleaseDate,
				TrackNumber: item.Track.TrackNumber,
				TotalTracks: item.Track.Album.TotalTracks,
				DiscNumber:  item.Track.DiscNumber,
				ExternalURL: item.Track.ExternalURL.Spotify,
				ISRC:        item.Track.ExternalID.ISRC,
				AlbumID:     item.Track.Album.ID,
				AlbumURL:    item.Track.Album.ExternalURL.Spotify,
			})
		}

		nextURL = pageData.Next
	}

	fmt.Printf("[Spotify] Fetched %d tracks from playlist (total: %d)\n", len(tracks), data.Tracks.Total)

	return &PlaylistResponsePayload{
		PlaylistInfo: info,
		TrackList:    tracks,
	}, nil
}

func (c *SpotifyMetadataClient) fetchArtist(ctx context.Context, artistID, token string) (*ArtistResponsePayload, error) {
	// Check cache first
	c.cacheMu.RLock()
	if entry, ok := c.artistCache[artistID]; ok && !entry.isExpired() {
		c.cacheMu.RUnlock()
		return entry.data.(*ArtistResponsePayload), nil
	}
	c.cacheMu.RUnlock()

	// Fetch artist info
	var artistData struct {
		ID        string  `json:"id"`
		Name      string  `json:"name"`
		Images    []image `json:"images"`
		Followers struct {
			Total int `json:"total"`
		} `json:"followers"`
		Popularity int `json:"popularity"`
	}

	if err := c.getJSON(ctx, fmt.Sprintf(artistBaseURL, artistID), token, &artistData); err != nil {
		return nil, err
	}

	artistInfo := ArtistInfoMetadata{
		ID:         artistData.ID,
		Name:       artistData.Name,
		Images:     firstImageURL(artistData.Images),
		Followers:  artistData.Followers.Total,
		Popularity: artistData.Popularity,
	}

	// Fetch artist albums (all types: album, single, compilation)
	albums := make([]ArtistAlbumMetadata, 0)
	offset := 0
	limit := 50

	for {
		albumsURL := fmt.Sprintf("%s?include_groups=album,single,compilation&limit=%d&offset=%d",
			fmt.Sprintf(artistAlbumsURL, artistID), limit, offset)

		var albumsData struct {
			Items []struct {
				ID          string      `json:"id"`
				Name        string      `json:"name"`
				ReleaseDate string      `json:"release_date"`
				TotalTracks int         `json:"total_tracks"`
				Images      []image     `json:"images"`
				AlbumType   string      `json:"album_type"`
				Artists     []artist    `json:"artists"`
				ExternalURL externalURL `json:"external_urls"`
			} `json:"items"`
			Next  string `json:"next"`
			Total int    `json:"total"`
		}

		if err := c.getJSON(ctx, albumsURL, token, &albumsData); err != nil {
			return nil, err
		}

		for _, album := range albumsData.Items {
			albums = append(albums, ArtistAlbumMetadata{
				ID:          album.ID,
				Name:        album.Name,
				ReleaseDate: album.ReleaseDate,
				TotalTracks: album.TotalTracks,
				Images:      firstImageURL(album.Images),
				AlbumType:   album.AlbumType,
				Artists:     joinArtists(album.Artists),
			})
		}

		// Check if there are more albums
		if albumsData.Next == "" || len(albumsData.Items) < limit {
			break
		}
		offset += limit

		// Safety limit to prevent infinite loops
		if offset > 500 {
			break
		}
	}

	result := &ArtistResponsePayload{
		ArtistInfo: artistInfo,
		Albums:     albums,
	}

	// Store in cache
	c.cacheMu.Lock()
	c.artistCache[artistID] = &cacheEntry{
		data:      result,
		expiresAt: time.Now().Add(artistCacheTTL),
	}
	c.cacheMu.Unlock()

	return result, nil
}

func (c *SpotifyMetadataClient) fetchTrackISRC(ctx context.Context, trackID, token string) string {
	var data struct {
		ExternalID externalID `json:"external_ids"`
	}
	if err := c.getJSON(ctx, fmt.Sprintf(trackBaseURL, trackID), token, &data); err != nil {
		return ""
	}
	return data.ExternalID.ISRC
}

func (c *SpotifyMetadataClient) getAccessToken(ctx context.Context) (string, error) {
	if c.cachedToken != "" && time.Now().Before(c.tokenExpiresAt) {
		return c.cachedToken, nil
	}

	data := url.Values{}
	data.Set("grant_type", "client_credentials")

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, spotifyTokenURL, strings.NewReader(data.Encode()))
	if err != nil {
		return "", err
	}

	req.SetBasicAuth(c.clientID, c.clientSecret)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to get access token: %d", resp.StatusCode)
	}

	var token accessTokenResponse
	if err := json.Unmarshal(body, &token); err != nil {
		return "", err
	}

	c.cachedToken = token.AccessToken
	if expiresIn, ok := token.ExpiresIn.(float64); ok {
		c.tokenExpiresAt = time.Now().Add(time.Duration(expiresIn-60) * time.Second)
	}

	return token.AccessToken, nil
}

func (c *SpotifyMetadataClient) getJSON(ctx context.Context, endpoint, token string, dst interface{}) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return err
	}

	// Set headers (same as PC version baseHeaders)
	req.Header.Set("User-Agent", c.userAgent)
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")
	req.Header.Set("sec-ch-ua-platform", "\"Windows\"")
	req.Header.Set("sec-fetch-dest", "empty")
	req.Header.Set("sec-fetch-mode", "cors")
	req.Header.Set("sec-fetch-site", "same-origin")
	req.Header.Set("Referer", "https://open.spotify.com/")
	req.Header.Set("Origin", "https://open.spotify.com")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("spotify API returned status %d", resp.StatusCode)
	}

	return json.Unmarshal(body, dst)
}

func (c *SpotifyMetadataClient) randomUserAgent() string {
	c.rngMu.Lock()
	defer c.rngMu.Unlock()

	// Use Mac User-Agent format (same as PC version)
	macMajor := c.rng.Intn(4) + 11         // 11-14
	macMinor := c.rng.Intn(5) + 4          // 4-8
	webkitMajor := c.rng.Intn(7) + 530     // 530-536
	webkitMinor := c.rng.Intn(7) + 30      // 30-36
	chromeMajor := c.rng.Intn(25) + 80     // 80-104
	chromeBuild := c.rng.Intn(1500) + 3000 // 3000-4499
	chromePatch := c.rng.Intn(65) + 60     // 60-124
	safariMajor := c.rng.Intn(7) + 530     // 530-536
	safariMinor := c.rng.Intn(6) + 30      // 30-35

	return fmt.Sprintf(
		"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_%d_%d) AppleWebKit/%d.%d (KHTML, like Gecko) Chrome/%d.0.%d.%d Safari/%d.%d",
		macMajor, macMinor,
		webkitMajor, webkitMinor,
		chromeMajor, chromeBuild, chromePatch,
		safariMajor, safariMinor,
	)
}

func parseSpotifyURI(input string) (spotifyURI, error) {
	trimmed := strings.TrimSpace(input)
	if trimmed == "" {
		return spotifyURI{}, errInvalidSpotifyURL
	}

	// Handle spotify: URI format
	if strings.HasPrefix(trimmed, "spotify:") {
		parts := strings.Split(trimmed, ":")
		if len(parts) == 3 {
			switch parts[1] {
			case "album", "track", "playlist", "artist":
				return spotifyURI{Type: parts[1], ID: parts[2]}, nil
			}
		}
	}

	// Handle URL format
	parsed, err := url.Parse(trimmed)
	if err != nil {
		return spotifyURI{}, err
	}

	// Handle embed.spotify.com URLs
	if parsed.Host == "embed.spotify.com" {
		if parsed.RawQuery == "" {
			return spotifyURI{}, errInvalidSpotifyURL
		}
		qs, _ := url.ParseQuery(parsed.RawQuery)
		embedded := qs.Get("uri")
		if embedded == "" {
			return spotifyURI{}, errInvalidSpotifyURL
		}
		return parseSpotifyURI(embedded)
	}

	// Handle plain ID (no scheme/host) - defaults to playlist
	if parsed.Scheme == "" && parsed.Host == "" {
		id := strings.Trim(strings.TrimSpace(parsed.Path), "/")
		if id == "" {
			return spotifyURI{}, errInvalidSpotifyURL
		}
		return spotifyURI{Type: "playlist", ID: id}, nil
	}

	if parsed.Host != "open.spotify.com" && parsed.Host != "play.spotify.com" {
		return spotifyURI{}, errInvalidSpotifyURL
	}

	parts := cleanPathParts(parsed.Path)
	if len(parts) == 0 {
		return spotifyURI{}, errInvalidSpotifyURL
	}

	// Skip embed prefix if present
	if parts[0] == "embed" {
		parts = parts[1:]
	}
	if len(parts) == 0 {
		return spotifyURI{}, errInvalidSpotifyURL
	}

	// Skip intl- prefix if present
	if strings.HasPrefix(parts[0], "intl-") {
		parts = parts[1:]
	}
	if len(parts) == 0 {
		return spotifyURI{}, errInvalidSpotifyURL
	}

	// Handle standard URLs: /album/{id}, /track/{id}, /playlist/{id}, /artist/{id}
	if len(parts) == 2 {
		switch parts[0] {
		case "album", "track", "playlist", "artist":
			return spotifyURI{Type: parts[0], ID: parts[1]}, nil
		}
	}

	// Handle nested playlist URLs: /user/{user}/playlist/{id}
	if len(parts) == 4 && parts[2] == "playlist" {
		return spotifyURI{Type: "playlist", ID: parts[3]}, nil
	}

	return spotifyURI{}, errInvalidSpotifyURL
}

func cleanPathParts(path string) []string {
	raw := strings.Split(path, "/")
	parts := make([]string, 0, len(raw))
	for _, part := range raw {
		if part != "" {
			parts = append(parts, part)
		}
	}
	return parts
}

func joinArtists(artists []artist) string {
	names := make([]string, len(artists))
	for i, a := range artists {
		names[i] = a.Name
	}
	return strings.Join(names, ", ")
}

func firstImageURL(images []image) string {
	if len(images) > 0 {
		return images[0].URL
	}
	return ""
}
