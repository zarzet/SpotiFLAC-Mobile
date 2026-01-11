package gobackend

import (
	"bufio"
	"encoding/base64"
	"encoding/json"
	"encoding/xml"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"
)

// TidalDownloader handles Tidal downloads
type TidalDownloader struct {
	client         *http.Client
	clientID       string
	clientSecret   string
	apiURL         string
	cachedToken    string
	tokenExpiresAt time.Time
	tokenMu        sync.Mutex
}

var (
	// Global Tidal downloader instance for token reuse
	globalTidalDownloader *TidalDownloader
	tidalDownloaderOnce   sync.Once
)

// TidalTrack represents a Tidal track
type TidalTrack struct {
	ID           int64  `json:"id"`
	Title        string `json:"title"`
	ISRC         string `json:"isrc"`
	AudioQuality string `json:"audioQuality"`
	TrackNumber  int    `json:"trackNumber"`
	VolumeNumber int    `json:"volumeNumber"`
	Duration     int    `json:"duration"`
	Album        struct {
		Title       string `json:"title"`
		Cover       string `json:"cover"`
		ReleaseDate string `json:"releaseDate"`
	} `json:"album"`
	Artists []struct {
		Name string `json:"name"`
	} `json:"artists"`
	Artist struct {
		Name string `json:"name"`
	} `json:"artist"`
	MediaMetadata struct {
		Tags []string `json:"tags"`
	} `json:"mediaMetadata"`
}

// TidalAPIResponseV2 is the new API response format (version 2.0)
type TidalAPIResponseV2 struct {
	Version string `json:"version"`
	Data    struct {
		TrackID           int64  `json:"trackId"`
		AssetPresentation string `json:"assetPresentation"`
		AudioMode         string `json:"audioMode"`
		AudioQuality      string `json:"audioQuality"`
		ManifestMimeType  string `json:"manifestMimeType"`
		ManifestHash      string `json:"manifestHash"`
		Manifest          string `json:"manifest"`
		BitDepth          int    `json:"bitDepth"`
		SampleRate        int    `json:"sampleRate"`
	} `json:"data"`
}

// TidalBTSManifest is the BTS (application/vnd.tidal.bts) manifest format
type TidalBTSManifest struct {
	MimeType       string   `json:"mimeType"`
	Codecs         string   `json:"codecs"`
	EncryptionType string   `json:"encryptionType"`
	URLs           []string `json:"urls"`
}

// MPD represents DASH manifest structure
type MPD struct {
	XMLName xml.Name `xml:"MPD"`
	Period  struct {
		AdaptationSet struct {
			Representation struct {
				SegmentTemplate struct {
					Initialization string `xml:"initialization,attr"`
					Media          string `xml:"media,attr"`
					Timeline       struct {
						Segments []struct {
							Duration int `xml:"d,attr"`
							Repeat   int `xml:"r,attr"`
						} `xml:"S"`
					} `xml:"SegmentTimeline"`
				} `xml:"SegmentTemplate"`
			} `xml:"Representation"`
		} `xml:"AdaptationSet"`
	} `xml:"Period"`
}

// NewTidalDownloader creates a new Tidal downloader (returns singleton for token reuse)
func NewTidalDownloader() *TidalDownloader {
	tidalDownloaderOnce.Do(func() {
		clientID, _ := base64.StdEncoding.DecodeString("NkJEU1JkcEs5aHFFQlRnVQ==")
		clientSecret, _ := base64.StdEncoding.DecodeString("eGV1UG1ZN25icFo5SUliTEFjUTkzc2hrYTFWTmhlVUFxTjZJY3N6alRHOD0=")

		globalTidalDownloader = &TidalDownloader{
			client:       NewHTTPClientWithTimeout(DefaultTimeout), // 60s timeout
			clientID:     string(clientID),
			clientSecret: string(clientSecret),
		}

		// Get first available API
		apis := globalTidalDownloader.GetAvailableAPIs()
		if len(apis) > 0 {
			globalTidalDownloader.apiURL = apis[0]
		}
	})
	return globalTidalDownloader
}

// GetAvailableAPIs returns list of available Tidal APIs
func (t *TidalDownloader) GetAvailableAPIs() []string {
	encodedAPIs := []string{
		// Priority 1: APIs that return FULL tracks (not PREVIEW)
		"dGlkYWwua2lub3BsdXMub25saW5l", // tidal.kinoplus.online - returns FULL
		"dGlkYWwtYXBpLmJpbmltdW0ub3Jn", // tidal-api.binimum.org
		"dHJpdG9uLnNxdWlkLnd0Zg==",     // triton.squid.wtf
		// Priority 2: qqdl.site APIs (often return PREVIEW only)
		"dm9nZWwucXFkbC5zaXRl", // vogel.qqdl.site
		"bWF1cy5xcWRsLnNpdGU=", // maus.qqdl.site
		"aHVuZC5xcWRsLnNpdGU=", // hund.qqdl.site
		"a2F0emUucXFkbC5zaXRl", // katze.qqdl.site
		"d29sZi5xcWRsLnNpdGU=", // wolf.qqdl.site
	}

	var apis []string
	for _, encoded := range encodedAPIs {
		decoded, err := base64.StdEncoding.DecodeString(encoded)
		if err != nil {
			continue
		}
		apis = append(apis, "https://"+string(decoded))
	}

	return apis
}

// GetAccessToken gets Tidal access token (with caching)
func (t *TidalDownloader) GetAccessToken() (string, error) {
	t.tokenMu.Lock()
	defer t.tokenMu.Unlock()

	// Return cached token if still valid (with 60s buffer)
	if t.cachedToken != "" && time.Now().Add(60*time.Second).Before(t.tokenExpiresAt) {
		return t.cachedToken, nil
	}

	data := fmt.Sprintf("client_id=%s&grant_type=client_credentials", t.clientID)

	authURL, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hdXRoLnRpZGFsLmNvbS92MS9vYXV0aDIvdG9rZW4=")
	req, err := http.NewRequest("POST", string(authURL), strings.NewReader(data))
	if err != nil {
		return "", err
	}

	req.SetBasicAuth(t.clientID, t.clientSecret)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("failed to get access token: HTTP %d", resp.StatusCode)
	}

	var result struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}

	// Cache the token
	t.cachedToken = result.AccessToken
	if result.ExpiresIn > 0 {
		t.tokenExpiresAt = time.Now().Add(time.Duration(result.ExpiresIn) * time.Second)
	} else {
		t.tokenExpiresAt = time.Now().Add(55 * time.Minute) // Default 55 min
	}

	return result.AccessToken, nil
}

// GetTidalURLFromSpotify gets Tidal URL from Spotify track ID using SongLink
func (t *TidalDownloader) GetTidalURLFromSpotify(spotifyTrackID string) (string, error) {
	spotifyBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9vcGVuLnNwb3RpZnkuY29tL3RyYWNrLw==")
	spotifyURL := fmt.Sprintf("%s%s", string(spotifyBase), spotifyTrackID)

	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkuc29uZy5saW5rL3YxLWFscGhhLjEvbGlua3M/dXJsPQ==")
	apiURL := fmt.Sprintf("%s%s", string(apiBase), url.QueryEscape(spotifyURL))

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		return "", fmt.Errorf("failed to get Tidal URL: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("SongLink API returned status %d", resp.StatusCode)
	}

	var songLinkResp struct {
		LinksByPlatform map[string]struct {
			URL string `json:"url"`
		} `json:"linksByPlatform"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&songLinkResp); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	tidalLink, ok := songLinkResp.LinksByPlatform["tidal"]
	if !ok || tidalLink.URL == "" {
		return "", fmt.Errorf("tidal link not found in SongLink")
	}

	return tidalLink.URL, nil
}

// GetTrackIDFromURL extracts track ID from Tidal URL
func (t *TidalDownloader) GetTrackIDFromURL(tidalURL string) (int64, error) {
	parts := strings.Split(tidalURL, "/track/")
	if len(parts) < 2 {
		return 0, fmt.Errorf("invalid tidal URL format")
	}

	trackIDStr := strings.Split(parts[1], "?")[0]
	trackIDStr = strings.TrimSpace(trackIDStr)

	var trackID int64
	_, err := fmt.Sscanf(trackIDStr, "%d", &trackID)
	if err != nil {
		return 0, fmt.Errorf("failed to parse track ID: %w", err)
	}

	return trackID, nil
}

// GetTrackInfoByID gets track info by Tidal track ID
func (t *TidalDownloader) GetTrackInfoByID(trackID int64) (*TidalTrack, error) {
	token, err := t.GetAccessToken()
	if err != nil {
		return nil, fmt.Errorf("failed to get access token: %w", err)
	}

	trackBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkudGlkYWwuY29tL3YxL3RyYWNrcy8=")
	trackURL := fmt.Sprintf("%s%d?countryCode=US", string(trackBase), trackID)

	req, err := http.NewRequest("GET", trackURL, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("failed to get track info: HTTP %d", resp.StatusCode)
	}

	var trackInfo TidalTrack
	if err := json.NewDecoder(resp.Body).Decode(&trackInfo); err != nil {
		return nil, err
	}

	return &trackInfo, nil
}

// SearchTrackByISRC searches for a track by ISRC
func (t *TidalDownloader) SearchTrackByISRC(isrc string) (*TidalTrack, error) {
	token, err := t.GetAccessToken()
	if err != nil {
		return nil, err
	}

	searchBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkudGlkYWwuY29tL3YxL3NlYXJjaC90cmFja3M/cXVlcnk9")
	searchURL := fmt.Sprintf("%s%s&limit=50&countryCode=US", string(searchBase), url.QueryEscape(isrc))

	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("search failed: HTTP %d", resp.StatusCode)
	}

	var result struct {
		Items []TidalTrack `json:"items"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	// Find exact ISRC match
	for i := range result.Items {
		if result.Items[i].ISRC == isrc {
			return &result.Items[i], nil
		}
	}

	if len(result.Items) == 0 {
		return nil, fmt.Errorf("no tracks found for ISRC: %s", isrc)
	}

	return nil, fmt.Errorf("no exact ISRC match found for: %s", isrc)
}

// normalizeTitle normalizes a track title for comparison
// Kept for potential future use
// func normalizeTitle(title string) string {
// 	normalized := strings.ToLower(strings.TrimSpace(title))
//
// 	// Remove common suffixes in parentheses or brackets
// 	suffixPatterns := []string{
// 		" (remaster)", " (remastered)", " (deluxe)", " (deluxe edition)",
// 		" (bonus track)", " (single)", " (album version)", " (radio edit)",
// 		" [remaster]", " [remastered]", " [deluxe]", " [bonus track]",
// 	}
// 	for _, suffix := range suffixPatterns {
// 		normalized = strings.TrimSuffix(normalized, suffix)
// 	}
//
// 	// Remove multiple spaces
// 	for strings.Contains(normalized, "  ") {
// 		normalized = strings.ReplaceAll(normalized, "  ", " ")
// 	}
//
// 	return normalized
// }

// SearchTrackByMetadataWithISRC searches for a track with ISRC matching priority
// Now includes romaji conversion for Japanese text (4 search strategies like PC)
func (t *TidalDownloader) SearchTrackByMetadataWithISRC(trackName, artistName, spotifyISRC string, expectedDuration int) (*TidalTrack, error) {
	token, err := t.GetAccessToken()
	if err != nil {
		return nil, err
	}

	// Build search queries - multiple strategies (same as PC version)
	queries := []string{}

	// Strategy 1: Artist + Track name (original)
	if artistName != "" && trackName != "" {
		queries = append(queries, artistName+" "+trackName)
	}

	// Strategy 2: Track name only
	if trackName != "" {
		queries = append(queries, trackName)
	}

	// Strategy 3: Romaji versions if Japanese detected (NEW - from PC version)
	if ContainsJapanese(trackName) || ContainsJapanese(artistName) {
		// Convert to romaji (hiragana/katakana only, kanji stays)
		romajiTrack := JapaneseToRomaji(trackName)
		romajiArtist := JapaneseToRomaji(artistName)

		// Clean and remove ALL non-ASCII characters (including kanji)
		cleanRomajiTrack := CleanToASCII(romajiTrack)
		cleanRomajiArtist := CleanToASCII(romajiArtist)

		// Artist + Track romaji (cleaned to ASCII only)
		if cleanRomajiArtist != "" && cleanRomajiTrack != "" {
			romajiQuery := cleanRomajiArtist + " " + cleanRomajiTrack
			if !containsQuery(queries, romajiQuery) {
				queries = append(queries, romajiQuery)
				GoLog("[Tidal] Japanese detected, adding romaji query: %s\n", romajiQuery)
			}
		}

		// Track romaji only (cleaned)
		if cleanRomajiTrack != "" && cleanRomajiTrack != trackName {
			if !containsQuery(queries, cleanRomajiTrack) {
				queries = append(queries, cleanRomajiTrack)
			}
		}

		// Also try with partial romaji (artist + cleaned track)
		if artistName != "" && cleanRomajiTrack != "" {
			partialQuery := artistName + " " + cleanRomajiTrack
			if !containsQuery(queries, partialQuery) {
				queries = append(queries, partialQuery)
			}
		}
	}

	// Strategy 4: Artist only as last resort
	if artistName != "" {
		artistOnly := CleanToASCII(JapaneseToRomaji(artistName))
		if artistOnly != "" && !containsQuery(queries, artistOnly) {
			queries = append(queries, artistOnly)
		}
	}

	searchBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkudGlkYWwuY29tL3YxL3NlYXJjaC90cmFja3M/cXVlcnk9")

	// Collect all search results from all queries
	var allTracks []TidalTrack
	searchedQueries := make(map[string]bool)

	for _, query := range queries {
		cleanQuery := strings.TrimSpace(query)
		if cleanQuery == "" || searchedQueries[cleanQuery] {
			continue
		}
		searchedQueries[cleanQuery] = true

		GoLog("[Tidal] Searching for: %s\n", cleanQuery)

		searchURL := fmt.Sprintf("%s%s&limit=100&countryCode=US", string(searchBase), url.QueryEscape(cleanQuery))

		req, err := http.NewRequest("GET", searchURL, nil)
		if err != nil {
			continue
		}

		req.Header.Set("Authorization", "Bearer "+token)

		resp, err := DoRequestWithUserAgent(t.client, req)
		if err != nil {
			GoLog("[Tidal] Search error for '%s': %v\n", cleanQuery, err)
			continue
		}

		if resp.StatusCode != 200 {
			resp.Body.Close()
			continue
		}

		var result struct {
			Items []TidalTrack `json:"items"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			resp.Body.Close()
			continue
		}
		resp.Body.Close()

		if len(result.Items) > 0 {
			GoLog("[Tidal] Found %d results for '%s'\n", len(result.Items), cleanQuery)

			// OPTIMIZATION: If ISRC provided, check for match immediately and return early
			if spotifyISRC != "" {
				for i := range result.Items {
					if result.Items[i].ISRC == spotifyISRC {
						track := &result.Items[i]
						// Verify duration if provided
						if expectedDuration > 0 {
							durationDiff := track.Duration - expectedDuration
							if durationDiff < 0 {
								durationDiff = -durationDiff
							}
							if durationDiff <= 3 {
								GoLog("[Tidal] ✓ ISRC match: '%s' (duration verified)\n", track.Title)
								return track, nil
							}
							// Duration mismatch, continue searching
							GoLog("[Tidal] ISRC match but duration mismatch (expected %ds, got %ds), continuing...\n",
								expectedDuration, track.Duration)
						} else {
							GoLog("[Tidal] ✓ ISRC match: '%s'\n", track.Title)
							return track, nil
						}
					}
				}
			}

			allTracks = append(allTracks, result.Items...)
		}
	}

	if len(allTracks) == 0 {
		return nil, fmt.Errorf("no tracks found for any search query")
	}

	// Priority 1: Match by ISRC (exact match) WITH title verification
	if spotifyISRC != "" {
		GoLog("[Tidal] Looking for ISRC match: %s\n", spotifyISRC)
		var isrcMatches []*TidalTrack
		for i := range allTracks {
			track := &allTracks[i]
			if track.ISRC == spotifyISRC {
				isrcMatches = append(isrcMatches, track)
			}
		}

		if len(isrcMatches) > 0 {
			// Verify duration first (most important check)
			if expectedDuration > 0 {
				var durationVerifiedMatches []*TidalTrack
				for _, track := range isrcMatches {
					durationDiff := track.Duration - expectedDuration
					if durationDiff < 0 {
						durationDiff = -durationDiff
					}
					// Allow 3 seconds tolerance for duration (same as PC version)
					if durationDiff <= 3 {
						durationVerifiedMatches = append(durationVerifiedMatches, track)
					}
				}

				if len(durationVerifiedMatches) > 0 {
					// Return first duration-verified match
					GoLog("[Tidal] ✓ ISRC match with duration verification: '%s' (expected %ds, found %ds)\n",
						durationVerifiedMatches[0].Title, expectedDuration, durationVerifiedMatches[0].Duration)
					return durationVerifiedMatches[0], nil
				}

				// ISRC matches but duration doesn't - this is likely wrong version
				GoLog("[Tidal] WARNING: ISRC %s found but duration mismatch. Expected=%ds, Found=%ds. Rejecting.\n",
					spotifyISRC, expectedDuration, isrcMatches[0].Duration)
				return nil, fmt.Errorf("ISRC found but duration mismatch: expected %ds, found %ds (likely different version/edit)",
					expectedDuration, isrcMatches[0].Duration)
			}

			// No duration to verify, just return first ISRC match
			GoLog("[Tidal] ✓ ISRC match (no duration verification): '%s'\n", isrcMatches[0].Title)
			return isrcMatches[0], nil
		}

		// If ISRC was provided but no match found, return error
		GoLog("[Tidal] ✗ No ISRC match found for: %s\n", spotifyISRC)
		return nil, fmt.Errorf("ISRC mismatch: no track found with ISRC %s on Tidal", spotifyISRC)
	}

	// Priority 2: Match by duration (within tolerance) + prefer best quality
	if expectedDuration > 0 {
		tolerance := 3 // 3 seconds tolerance
		var durationMatches []*TidalTrack

		for i := range allTracks {
			track := &allTracks[i]
			durationDiff := track.Duration - expectedDuration
			if durationDiff < 0 {
				durationDiff = -durationDiff
			}
			if durationDiff <= tolerance {
				durationMatches = append(durationMatches, track)
			}
		}

		if len(durationMatches) > 0 {
			// Find best quality among duration matches
			bestMatch := durationMatches[0]
			for _, track := range durationMatches {
				for _, tag := range track.MediaMetadata.Tags {
					if tag == "HIRES_LOSSLESS" {
						bestMatch = track
						break
					}
				}
			}
			GoLog("[Tidal] Found via duration match: %s - %s (%s)\n",
				bestMatch.Artist.Name, bestMatch.Title, bestMatch.AudioQuality)
			return bestMatch, nil
		}
	}

	// Priority 3: Just take the best quality from first results
	bestMatch := &allTracks[0]
	for i := range allTracks {
		track := &allTracks[i]
		for _, tag := range track.MediaMetadata.Tags {
			if tag == "HIRES_LOSSLESS" {
				bestMatch = track
				break
			}
		}
		if bestMatch != &allTracks[0] {
			break
		}
	}

	GoLog("[Tidal] Found via search (no ISRC provided): %s - %s (ISRC: %s, Quality: %s)\n",
		bestMatch.Artist.Name, bestMatch.Title, bestMatch.ISRC, bestMatch.AudioQuality)

	return bestMatch, nil
}

// containsQuery checks if a query already exists in the list
func containsQuery(queries []string, query string) bool {
	for _, q := range queries {
		if q == query {
			return true
		}
	}
	return false
}

// SearchTrackByMetadata searches for a track using artist name and track name
func (t *TidalDownloader) SearchTrackByMetadata(trackName, artistName string) (*TidalTrack, error) {
	return t.SearchTrackByMetadataWithISRC(trackName, artistName, "", 0)
}

// TidalDownloadInfo contains download URL and quality info
type TidalDownloadInfo struct {
	URL        string
	BitDepth   int
	SampleRate int
}

// tidalAPIResult holds the result from a parallel API request
// Kept for potential future use with _getDownloadURLParallel
// type tidalAPIResult struct {
// 	apiURL   string
// 	info     TidalDownloadInfo
// 	err      error
// 	duration time.Duration
// }

// _getDownloadURLParallel requests download URL from all APIs in parallel
// Returns the first successful result (supports both v1 and v2 API formats)
// Kept for potential future use - currently using sequential approach
// func _getDownloadURLParallel(apis []string, trackID int64, quality string) (string, TidalDownloadInfo, error) {
// 	... implementation commented out ...
// }

// getDownloadURLSequential requests download URL from APIs sequentially (fallback)
// Returns the first successful result (supports both v1 and v2 API formats)
func getDownloadURLSequential(apis []string, trackID int64, quality string) (string, TidalDownloadInfo, error) {
	if len(apis) == 0 {
		return "", TidalDownloadInfo{}, fmt.Errorf("no APIs available")
	}

	client := NewHTTPClientWithTimeout(DefaultTimeout)
	retryConfig := DefaultRetryConfig()
	var errors []string

	for _, apiURL := range apis {
		reqURL := fmt.Sprintf("%s/track/?id=%d&quality=%s", apiURL, trackID, quality)
		GoLog("[Tidal] Trying API: %s\n", reqURL)

		req, err := http.NewRequest("GET", reqURL, nil)
		if err != nil {
			errors = append(errors, BuildErrorMessage(apiURL, 0, err.Error()))
			continue
		}

		resp, err := DoRequestWithRetry(client, req, retryConfig)
		if err != nil {
			GoLog("[Tidal] API error: %v\n", err)
			errors = append(errors, BuildErrorMessage(apiURL, 0, err.Error()))
			continue
		}

		body, err := ReadResponseBody(resp)
		resp.Body.Close()
		if err != nil {
			GoLog("[Tidal] Read body error: %v\n", err)
			errors = append(errors, BuildErrorMessage(apiURL, resp.StatusCode, err.Error()))
			continue
		}

		// Log response preview
		bodyPreview := string(body)
		if len(bodyPreview) > 300 {
			bodyPreview = bodyPreview[:300] + "..."
		}
		GoLog("[Tidal] API response (HTTP %d): %s\n", resp.StatusCode, bodyPreview)

		// Try v2 format first (object with manifest)
		var v2Response TidalAPIResponseV2
		if err := json.Unmarshal(body, &v2Response); err == nil && v2Response.Data.Manifest != "" {
			GoLog("[Tidal] Got v2 response from %s - Quality: %d-bit/%dHz, AssetPresentation: %s\n",
				apiURL, v2Response.Data.BitDepth, v2Response.Data.SampleRate, v2Response.Data.AssetPresentation)

			// IMPORTANT: Reject PREVIEW responses - we need FULL tracks
			if v2Response.Data.AssetPresentation == "PREVIEW" {
				GoLog("[Tidal] ✗ Rejecting PREVIEW response from %s, trying next API...\n", apiURL)
				errors = append(errors, BuildErrorMessage(apiURL, resp.StatusCode, "returned PREVIEW instead of FULL"))
				continue
			}

			GoLog("[Tidal] ✓ Got FULL track from %s\n", apiURL)
			info := TidalDownloadInfo{
				URL:        "MANIFEST:" + v2Response.Data.Manifest,
				BitDepth:   v2Response.Data.BitDepth,
				SampleRate: v2Response.Data.SampleRate,
			}
			return apiURL, info, nil
		}

		// Fallback to v1 format (array with OriginalTrackUrl)
		var v1Responses []struct {
			OriginalTrackURL string `json:"OriginalTrackUrl"`
		}
		if err := json.Unmarshal(body, &v1Responses); err == nil {
			for _, item := range v1Responses {
				if item.OriginalTrackURL != "" {
					// v1 format doesn't have quality info, assume 16-bit/44.1kHz
					info := TidalDownloadInfo{
						URL:        item.OriginalTrackURL,
						BitDepth:   16,
						SampleRate: 44100,
					}
					return apiURL, info, nil
				}
			}
		}

		errors = append(errors, BuildErrorMessage(apiURL, resp.StatusCode, "no download URL or manifest in response"))
	}

	return "", TidalDownloadInfo{}, fmt.Errorf("all %d Tidal APIs failed. Errors: %v", len(apis), errors)
}

// GetDownloadURL gets download URL for a track - tries APIs sequentially
func (t *TidalDownloader) GetDownloadURL(trackID int64, quality string) (TidalDownloadInfo, error) {
	apis := t.GetAvailableAPIs()
	if len(apis) == 0 {
		return TidalDownloadInfo{}, fmt.Errorf("no API URL configured")
	}

	_, info, err := getDownloadURLSequential(apis, trackID, quality)
	if err != nil {
		return TidalDownloadInfo{}, fmt.Errorf("failed to get download URL: %w", err)
	}

	return info, nil
}

// parseManifest parses Tidal manifest (supports both BTS and DASH formats)
func parseManifest(manifestB64 string) (directURL string, initURL string, mediaURLs []string, err error) {
	manifestBytes, err := base64.StdEncoding.DecodeString(manifestB64)
	if err != nil {
		return "", "", nil, fmt.Errorf("failed to decode manifest: %w", err)
	}

	manifestStr := string(manifestBytes)

	// Debug: log first 500 chars of manifest for debugging
	manifestPreview := manifestStr
	if len(manifestPreview) > 500 {
		manifestPreview = manifestPreview[:500] + "..."
	}
	GoLog("[Tidal] Manifest content: %s\n", manifestPreview)

	// Check if it's BTS format (JSON) or DASH format (XML)
	if strings.HasPrefix(manifestStr, "{") {
		// BTS format - JSON with direct URLs
		var btsManifest TidalBTSManifest
		if err := json.Unmarshal(manifestBytes, &btsManifest); err != nil {
			return "", "", nil, fmt.Errorf("failed to parse BTS manifest: %w", err)
		}

		if len(btsManifest.URLs) == 0 {
			return "", "", nil, fmt.Errorf("no URLs in BTS manifest")
		}

		return btsManifest.URLs[0], "", nil, nil
	}

	// DASH format - XML with segments
	var mpd MPD
	if err := xml.Unmarshal(manifestBytes, &mpd); err != nil {
		return "", "", nil, fmt.Errorf("failed to parse manifest XML: %w", err)
	}

	segTemplate := mpd.Period.AdaptationSet.Representation.SegmentTemplate
	initURL = segTemplate.Initialization
	mediaTemplate := segTemplate.Media

	if initURL == "" || mediaTemplate == "" {
		// Fallback: try regex extraction
		initRe := regexp.MustCompile(`initialization="([^"]+)"`)
		mediaRe := regexp.MustCompile(`media="([^"]+)"`)

		if match := initRe.FindStringSubmatch(manifestStr); len(match) > 1 {
			initURL = match[1]
		}
		if match := mediaRe.FindStringSubmatch(manifestStr); len(match) > 1 {
			mediaTemplate = match[1]
		}
	}

	if initURL == "" {
		return "", "", nil, fmt.Errorf("no initialization URL found in manifest")
	}

	// Unescape HTML entities in URLs
	initURL = strings.ReplaceAll(initURL, "&amp;", "&")
	mediaTemplate = strings.ReplaceAll(mediaTemplate, "&amp;", "&")

	// Calculate segment count from timeline
	segmentCount := 0
	GoLog("[Tidal] XML parsed segments: %d entries in timeline\n", len(segTemplate.Timeline.Segments))
	for i, seg := range segTemplate.Timeline.Segments {
		GoLog("[Tidal] Segment[%d]: d=%d, r=%d\n", i, seg.Duration, seg.Repeat)
		segmentCount += seg.Repeat + 1
	}
	GoLog("[Tidal] Segment count from XML: %d\n", segmentCount)

	// If no segments found via XML, try regex
	if segmentCount == 0 {
		fmt.Println("[Tidal] No segments from XML, trying regex...")
		// Match <S d="..." /> or <S d="..." r="..." />
		segRe := regexp.MustCompile(`<S\s+d="(\d+)"(?:\s+r="(\d+)")?`)
		matches := segRe.FindAllStringSubmatch(manifestStr, -1)
		GoLog("[Tidal] Regex found %d segment entries\n", len(matches))
		for i, match := range matches {
			repeat := 0
			if len(match) > 2 && match[2] != "" {
				fmt.Sscanf(match[2], "%d", &repeat)
			}
			if i < 5 || i == len(matches)-1 {
				GoLog("[Tidal] Regex segment[%d]: d=%s, r=%d\n", i, match[1], repeat)
			}
			segmentCount += repeat + 1
		}
		GoLog("[Tidal] Total segments from regex: %d\n", segmentCount)
	}

	// Generate media URLs for each segment
	for i := 1; i <= segmentCount; i++ {
		mediaURL := strings.ReplaceAll(mediaTemplate, "$Number$", fmt.Sprintf("%d", i))
		mediaURLs = append(mediaURLs, mediaURL)
	}

	return "", initURL, mediaURLs, nil
}

// DownloadFile downloads a file from URL with progress tracking
func (t *TidalDownloader) DownloadFile(downloadURL, outputPath, itemID string) error {
	// Handle manifest-based download (DASH/BTS)
	if strings.HasPrefix(downloadURL, "MANIFEST:") {
		// Initialize progress tracking for manifest downloads
		if itemID != "" {
			StartItemProgress(itemID)
			defer CompleteItemProgress(itemID)
		}
		return t.downloadFromManifest(strings.TrimPrefix(downloadURL, "MANIFEST:"), outputPath, itemID)
	}

	// Initialize item progress for direct downloads
	if itemID != "" {
		StartItemProgress(itemID)
		defer CompleteItemProgress(itemID)
	}

	req, err := http.NewRequest("GET", downloadURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("download failed: HTTP %d", resp.StatusCode)
	}

	expectedSize := resp.ContentLength
	// Set total bytes if available
	if expectedSize > 0 && itemID != "" {
		SetItemBytesTotal(itemID, expectedSize)
	}

	out, err := os.Create(outputPath)
	if err != nil {
		return err
	}

	// Use buffered writer for better performance (256KB buffer)
	bufWriter := bufio.NewWriterSize(out, 256*1024)

	// Use item progress writer with buffered output
	var written int64
	if itemID != "" {
		progressWriter := NewItemProgressWriter(bufWriter, itemID)
		written, err = io.Copy(progressWriter, resp.Body)
	} else {
		// Fallback: direct copy without progress tracking
		written, err = io.Copy(bufWriter, resp.Body)
	}

	// Flush buffer before checking for errors
	flushErr := bufWriter.Flush()
	closeErr := out.Close()

	// Check for any errors
	if err != nil {
		os.Remove(outputPath)
		return fmt.Errorf("download interrupted: %w", err)
	}
	if flushErr != nil {
		os.Remove(outputPath)
		return fmt.Errorf("failed to flush buffer: %w", flushErr)
	}
	if closeErr != nil {
		os.Remove(outputPath)
		return fmt.Errorf("failed to close file: %w", closeErr)
	}

	// Verify file size if Content-Length was provided
	if expectedSize > 0 && written != expectedSize {
		os.Remove(outputPath)
		return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
	}

	return nil
}

func (t *TidalDownloader) downloadFromManifest(manifestB64, outputPath, itemID string) error {
	fmt.Println("[Tidal] Parsing manifest...")
	directURL, initURL, mediaURLs, err := parseManifest(manifestB64)
	if err != nil {
		GoLog("[Tidal] Manifest parse error: %v\n", err)
		return fmt.Errorf("failed to parse manifest: %w", err)
	}
	GoLog("[Tidal] Manifest parsed - directURL: %v, initURL: %v, mediaURLs count: %d\n",
		directURL != "", initURL != "", len(mediaURLs))

	client := &http.Client{
		Timeout: 120 * time.Second,
	}

	// If we have a direct URL (BTS format), download directly with progress tracking
	if directURL != "" {
		GoLog("[Tidal] BTS format - downloading from direct URL: %s...\n", directURL[:min(80, len(directURL))])
		// Note: Progress tracking is initialized by the caller (DownloadFile)

		req, err := http.NewRequest("GET", directURL, nil)
		if err != nil {
			GoLog("[Tidal] BTS request creation failed: %v\n", err)
			return fmt.Errorf("failed to create request: %w", err)
		}

		resp, err := client.Do(req)
		if err != nil {
			GoLog("[Tidal] BTS download failed: %v\n", err)
			return fmt.Errorf("failed to download file: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			GoLog("[Tidal] BTS download HTTP error: %d\n", resp.StatusCode)
			return fmt.Errorf("download failed with status %d", resp.StatusCode)
		}
		GoLog("[Tidal] BTS response OK, Content-Length: %d\n", resp.ContentLength)

		expectedSize := resp.ContentLength
		// Set total bytes for progress tracking
		if expectedSize > 0 && itemID != "" {
			SetItemBytesTotal(itemID, expectedSize)
		}

		out, err := os.Create(outputPath)
		if err != nil {
			return fmt.Errorf("failed to create file: %w", err)
		}

		// Use item progress writer
		var written int64
		if itemID != "" {
			progressWriter := NewItemProgressWriter(out, itemID)
			written, err = io.Copy(progressWriter, resp.Body)
		} else {
			written, err = io.Copy(out, resp.Body)
		}

		closeErr := out.Close()

		if err != nil {
			os.Remove(outputPath)
			return fmt.Errorf("download interrupted: %w", err)
		}
		if closeErr != nil {
			os.Remove(outputPath)
			return fmt.Errorf("failed to close file: %w", closeErr)
		}

		// Verify file size if Content-Length was provided
		if expectedSize > 0 && written != expectedSize {
			os.Remove(outputPath)
			return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
		}

		return nil
	}

	// DASH format - download segments directly to M4A file (no temp file to avoid Android permission issues)
	// On Android, we can't use ffmpeg, so we save as M4A directly
	m4aPath := strings.TrimSuffix(outputPath, ".flac") + ".m4a"
	GoLog("[Tidal] DASH format - downloading %d segments directly to: %s\n", len(mediaURLs), m4aPath)

	// Note: Progress tracking is initialized by the caller (DownloadFile or downloadFromTidal)
	// We just update progress here based on segment count

	out, err := os.Create(m4aPath)
	if err != nil {
		GoLog("[Tidal] Failed to create M4A file: %v\n", err)
		return fmt.Errorf("failed to create M4A file: %w", err)
	}

	// Download initialization segment
	GoLog("[Tidal] Downloading init segment...\n")
	resp, err := client.Get(initURL)
	if err != nil {
		out.Close()
		os.Remove(m4aPath)
		GoLog("[Tidal] Init segment download failed: %v\n", err)
		return fmt.Errorf("failed to download init segment: %w", err)
	}
	if resp.StatusCode != 200 {
		resp.Body.Close()
		out.Close()
		os.Remove(m4aPath)
		GoLog("[Tidal] Init segment HTTP error: %d\n", resp.StatusCode)
		return fmt.Errorf("init segment download failed with status %d", resp.StatusCode)
	}
	_, err = io.Copy(out, resp.Body)
	resp.Body.Close()
	if err != nil {
		out.Close()
		os.Remove(m4aPath)
		GoLog("[Tidal] Init segment write failed: %v\n", err)
		return fmt.Errorf("failed to write init segment: %w", err)
	}

	// Download media segments with progress
	totalSegments := len(mediaURLs)
	for i, mediaURL := range mediaURLs {
		if i%10 == 0 || i == totalSegments-1 {
			GoLog("[Tidal] Downloading segment %d/%d...\n", i+1, totalSegments)
		}

		// Update progress based on segment count
		if itemID != "" {
			progress := float64(i+1) / float64(totalSegments)
			SetItemProgress(itemID, progress, 0, 0)
		}

		resp, err := client.Get(mediaURL)
		if err != nil {
			out.Close()
			os.Remove(m4aPath)
			GoLog("[Tidal] Segment %d download failed: %v\n", i+1, err)
			return fmt.Errorf("failed to download segment %d: %w", i+1, err)
		}
		if resp.StatusCode != 200 {
			resp.Body.Close()
			out.Close()
			os.Remove(m4aPath)
			GoLog("[Tidal] Segment %d HTTP error: %d\n", i+1, resp.StatusCode)
			return fmt.Errorf("segment %d download failed with status %d", i+1, resp.StatusCode)
		}
		_, err = io.Copy(out, resp.Body)
		resp.Body.Close()
		if err != nil {
			out.Close()
			os.Remove(m4aPath)
			GoLog("[Tidal] Segment %d write failed: %v\n", i+1, err)
			return fmt.Errorf("failed to write segment %d: %w", i+1, err)
		}
	}

	if err := out.Close(); err != nil {
		os.Remove(m4aPath)
		GoLog("[Tidal] Failed to close M4A file: %v\n", err)
		return fmt.Errorf("failed to close M4A file: %w", err)
	}

	GoLog("[Tidal] DASH download completed: %s\n", m4aPath)
	return nil
}

// TidalDownloadResult contains download result with quality info
type TidalDownloadResult struct {
	FilePath    string
	BitDepth    int
	SampleRate  int
	Title       string
	Artist      string
	Album       string
	ReleaseDate string
	TrackNumber int
	DiscNumber  int
	ISRC        string
}

// artistsMatch checks if the artist names are similar enough
func artistsMatch(spotifyArtist, tidalArtist string) bool {
	normSpotify := strings.ToLower(strings.TrimSpace(spotifyArtist))
	normTidal := strings.ToLower(strings.TrimSpace(tidalArtist))

	// Exact match
	if normSpotify == normTidal {
		return true
	}

	// Check if one contains the other (for cases like "Artist" vs "Artist feat. Someone")
	if strings.Contains(normSpotify, normTidal) || strings.Contains(normTidal, normSpotify) {
		return true
	}

	// Check first artist (before comma or feat)
	spotifyFirst := strings.Split(normSpotify, ",")[0]
	spotifyFirst = strings.Split(spotifyFirst, " feat")[0]
	spotifyFirst = strings.Split(spotifyFirst, " ft.")[0]
	spotifyFirst = strings.TrimSpace(spotifyFirst)

	tidalFirst := strings.Split(normTidal, ",")[0]
	tidalFirst = strings.Split(tidalFirst, " feat")[0]
	tidalFirst = strings.Split(tidalFirst, " ft.")[0]
	tidalFirst = strings.TrimSpace(tidalFirst)

	if spotifyFirst == tidalFirst {
		return true
	}

	// Check if first artist is contained in the other
	if strings.Contains(spotifyFirst, tidalFirst) || strings.Contains(tidalFirst, spotifyFirst) {
		return true
	}

	// If scripts are TRULY different (Latin vs CJK/Arabic/Cyrillic), assume match (transliteration)
	// Don't treat Latin Extended (Polish, French, etc.) as different script
	// This handles cases like "鈴木雅之" vs "Masayuki Suzuki"
	spotifyLatin := isLatinScript(spotifyArtist)
	tidalLatin := isLatinScript(tidalArtist)
	if spotifyLatin != tidalLatin {
		GoLog("[Tidal] Artist names in different scripts, assuming match: '%s' vs '%s'\n", spotifyArtist, tidalArtist)
		return true
	}

	return false
}

// titlesMatch checks if track titles are similar enough
func titlesMatch(expectedTitle, foundTitle string) bool {
	normExpected := strings.ToLower(strings.TrimSpace(expectedTitle))
	normFound := strings.ToLower(strings.TrimSpace(foundTitle))

	// Exact match
	if normExpected == normFound {
		return true
	}

	// Check if one contains the other
	if strings.Contains(normExpected, normFound) || strings.Contains(normFound, normExpected) {
		return true
	}

	// Clean both titles and compare
	cleanExpected := cleanTitle(normExpected)
	cleanFound := cleanTitle(normFound)

	if cleanExpected == cleanFound {
		return true
	}

	// Check if cleaned versions contain each other
	if cleanExpected != "" && cleanFound != "" {
		if strings.Contains(cleanExpected, cleanFound) || strings.Contains(cleanFound, cleanExpected) {
			return true
		}
	}

	// Extract core title (before any parentheses/brackets)
	coreExpected := extractCoreTitle(normExpected)
	coreFound := extractCoreTitle(normFound)

	if coreExpected != "" && coreFound != "" && coreExpected == coreFound {
		return true
	}

	// If scripts are TRULY different (Latin vs CJK/Arabic/Cyrillic), assume match (transliteration)
	// Don't treat Latin Extended (Polish, French, etc.) as different script
	expectedLatin := isLatinScript(expectedTitle)
	foundLatin := isLatinScript(foundTitle)
	if expectedLatin != foundLatin {
		GoLog("[Tidal] Titles in different scripts, assuming match: '%s' vs '%s'\n", expectedTitle, foundTitle)
		return true
	}

	return false
}

// extractCoreTitle extracts the main title before any parentheses or brackets
func extractCoreTitle(title string) string {
	// Find first occurrence of ( or [
	parenIdx := strings.Index(title, "(")
	bracketIdx := strings.Index(title, "[")
	dashIdx := strings.Index(title, " - ")

	cutIdx := len(title)
	if parenIdx > 0 && parenIdx < cutIdx {
		cutIdx = parenIdx
	}
	if bracketIdx > 0 && bracketIdx < cutIdx {
		cutIdx = bracketIdx
	}
	if dashIdx > 0 && dashIdx < cutIdx {
		cutIdx = dashIdx
	}

	return strings.TrimSpace(title[:cutIdx])
}

// cleanTitle removes common suffixes from track titles for comparison
func cleanTitle(title string) string {
	cleaned := title

	// Version indicators to remove from parentheses/brackets
	versionPatterns := []string{
		"remaster", "remastered", "deluxe", "bonus", "single",
		"album version", "radio edit", "original mix", "extended",
		"club mix", "remix", "live", "acoustic", "demo",
	}

	// Remove parenthetical content if it contains version indicators
	for {
		startParen := strings.LastIndex(cleaned, "(")
		endParen := strings.LastIndex(cleaned, ")")
		if startParen >= 0 && endParen > startParen {
			content := strings.ToLower(cleaned[startParen+1 : endParen])
			isVersionIndicator := false
			for _, pattern := range versionPatterns {
				if strings.Contains(content, pattern) {
					isVersionIndicator = true
					break
				}
			}
			if isVersionIndicator {
				cleaned = strings.TrimSpace(cleaned[:startParen]) + cleaned[endParen+1:]
				continue
			}
		}
		break
	}

	// Same for brackets
	for {
		startBracket := strings.LastIndex(cleaned, "[")
		endBracket := strings.LastIndex(cleaned, "]")
		if startBracket >= 0 && endBracket > startBracket {
			content := strings.ToLower(cleaned[startBracket+1 : endBracket])
			isVersionIndicator := false
			for _, pattern := range versionPatterns {
				if strings.Contains(content, pattern) {
					isVersionIndicator = true
					break
				}
			}
			if isVersionIndicator {
				cleaned = strings.TrimSpace(cleaned[:startBracket]) + cleaned[endBracket+1:]
				continue
			}
		}
		break
	}

	// Remove trailing " - version" patterns
	dashPatterns := []string{
		" - remaster", " - remastered", " - single version", " - radio edit",
		" - live", " - acoustic", " - demo", " - remix",
	}
	for _, pattern := range dashPatterns {
		if strings.HasSuffix(strings.ToLower(cleaned), pattern) {
			cleaned = cleaned[:len(cleaned)-len(pattern)]
		}
	}

	// Remove multiple spaces
	for strings.Contains(cleaned, "  ") {
		cleaned = strings.ReplaceAll(cleaned, "  ", " ")
	}

	return strings.TrimSpace(cleaned)
}

// isLatinScript checks if a string is primarily Latin script
// Returns true for ASCII and Latin Extended characters (European languages)
// Returns false for CJK, Arabic, Cyrillic, etc.
func isLatinScript(s string) bool {
	for _, r := range s {
		// Skip common punctuation and numbers
		if r < 128 {
			continue
		}
		// Latin Extended-A: U+0100 to U+017F (Polish, Czech, etc.)
		// Latin Extended-B: U+0180 to U+024F
		// Latin Extended Additional: U+1E00 to U+1EFF
		if (r >= 0x0100 && r <= 0x024F) || // Latin Extended A & B
			(r >= 0x1E00 && r <= 0x1EFF) || // Latin Extended Additional
			(r >= 0x00C0 && r <= 0x00FF) { // Latin-1 Supplement (accented chars)
			continue
		}
		// CJK ranges - definitely different script
		if (r >= 0x4E00 && r <= 0x9FFF) || // CJK Unified Ideographs
			(r >= 0x3040 && r <= 0x309F) || // Hiragana
			(r >= 0x30A0 && r <= 0x30FF) || // Katakana
			(r >= 0xAC00 && r <= 0xD7AF) || // Hangul (Korean)
			(r >= 0x0600 && r <= 0x06FF) || // Arabic
			(r >= 0x0400 && r <= 0x04FF) { // Cyrillic
			return false
		}
	}
	return true
}

// isASCIIString checks if a string contains only ASCII characters
// Kept for potential future use
// func isASCIIString(s string) bool {
// 	for _, r := range s {
// 		if r > 127 {
// 			return false
// 		}
// 	}
// 	return true
// }

// downloadFromTidal downloads a track using the request parameters
func downloadFromTidal(req DownloadRequest) (TidalDownloadResult, error) {
	downloader := NewTidalDownloader()

	// Check for existing file first
	if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
		return TidalDownloadResult{FilePath: "EXISTS:" + existingFile}, nil
	}

	// Convert expected duration from ms to seconds
	expectedDurationSec := req.DurationMS / 1000

	var track *TidalTrack
	var err error

	// OPTIMIZATION: Check cache first for track ID
	if req.ISRC != "" {
		if cached := GetTrackIDCache().Get(req.ISRC); cached != nil && cached.TidalTrackID > 0 {
			GoLog("[Tidal] Cache hit! Using cached track ID: %d\n", cached.TidalTrackID)
			track, err = downloader.GetTrackInfoByID(cached.TidalTrackID)
			if err != nil {
				GoLog("[Tidal] Cache hit but failed to get track info: %v\n", err)
				track = nil // Fall through to normal search
			}
		}
	}

	// OPTIMIZED: Try ISRC search with metadata (search by name, filter by ISRC)
	// Strategy 1: Search by metadata, match by ISRC (most accurate)
	if track == nil && req.ISRC != "" {
		GoLog("[Tidal] Trying ISRC search: %s\n", req.ISRC)
		track, err = downloader.SearchTrackByMetadataWithISRC(req.TrackName, req.ArtistName, req.ISRC, expectedDurationSec)
		if track != nil {
			// Verify artist only (ISRC match is already accurate)
			tidalArtist := track.Artist.Name
			if len(track.Artists) > 0 {
				var artistNames []string
				for _, a := range track.Artists {
					artistNames = append(artistNames, a.Name)
				}
				tidalArtist = strings.Join(artistNames, ", ")
			}
			if !artistsMatch(req.ArtistName, tidalArtist) {
				GoLog("[Tidal] Artist mismatch from ISRC search: expected '%s', got '%s'. Rejecting.\n",
					req.ArtistName, tidalArtist)
				track = nil
			}
		}
	}

	// Strategy 2: Try SongLink only if ISRC search failed (slower but more accurate)
	if track == nil && req.SpotifyID != "" {
		GoLog("[Tidal] ISRC search failed, trying SongLink...\n")
		var tidalURL string
		var slErr error

		// Check if SpotifyID is actually a Deezer ID (format: "deezer:xxxxx")
		if strings.HasPrefix(req.SpotifyID, "deezer:") {
			deezerID := strings.TrimPrefix(req.SpotifyID, "deezer:")
			GoLog("[Tidal] Using Deezer ID for SongLink lookup: %s\n", deezerID)
			songlink := NewSongLinkClient()
			tidalURL, slErr = songlink.GetTidalURLFromDeezer(deezerID)
		} else {
			tidalURL, slErr = downloader.GetTidalURLFromSpotify(req.SpotifyID)
		}

		if slErr == nil && tidalURL != "" {
			// Extract track ID and get track info
			trackID, idErr := downloader.GetTrackIDFromURL(tidalURL)
			if idErr == nil {
				track, err = downloader.GetTrackInfoByID(trackID)
				if track != nil {
					// Get artist name from track
					tidalArtist := track.Artist.Name
					if len(track.Artists) > 0 {
						var artistNames []string
						for _, a := range track.Artists {
							artistNames = append(artistNames, a.Name)
						}
						tidalArtist = strings.Join(artistNames, ", ")
					}

					// Verify artist matches (SongLink is already accurate, no title check needed)
					if !artistsMatch(req.ArtistName, tidalArtist) {
						GoLog("[Tidal] Artist mismatch from SongLink: expected '%s', got '%s'. Rejecting.\n",
							req.ArtistName, tidalArtist)
						track = nil
					}

					// Verify duration if we have expected duration
					if track != nil && expectedDurationSec > 0 {
						durationDiff := track.Duration - expectedDurationSec
						if durationDiff < 0 {
							durationDiff = -durationDiff
						}
						// Allow 3 seconds tolerance (same as PC version)
						if durationDiff > 3 {
							GoLog("[Tidal] Duration mismatch from SongLink: expected %ds, got %ds. Rejecting.\n",
								expectedDurationSec, track.Duration)
							track = nil // Reject this match
						}
					}
				}
			}
		}
	}

	// Strategy 3: Search by metadata only (no ISRC requirement) - last resort
	if track == nil {
		GoLog("[Tidal] Trying metadata search as last resort...\n")
		track, err = downloader.SearchTrackByMetadataWithISRC(req.TrackName, req.ArtistName, "", expectedDurationSec)
		// Verify artist AND title for metadata search
		if track != nil {
			tidalArtist := track.Artist.Name
			if len(track.Artists) > 0 {
				var artistNames []string
				for _, a := range track.Artists {
					artistNames = append(artistNames, a.Name)
				}
				tidalArtist = strings.Join(artistNames, ", ")
			}

			// Verify title first
			if !titlesMatch(req.TrackName, track.Title) {
				GoLog("[Tidal] Title mismatch from metadata search: expected '%s', got '%s'. Rejecting.\n",
					req.TrackName, track.Title)
				track = nil
			} else if !artistsMatch(req.ArtistName, tidalArtist) {
				GoLog("[Tidal] Artist mismatch from metadata search: expected '%s', got '%s'. Rejecting.\n",
					req.ArtistName, tidalArtist)
				track = nil
			}
		}
	}

	if track == nil {
		errMsg := "could not find matching track on Tidal (artist/duration mismatch)"
		if err != nil {
			errMsg = err.Error()
		}
		return TidalDownloadResult{}, fmt.Errorf("tidal search failed: %s", errMsg)
	}

	// Final verification logging
	tidalArtist := track.Artist.Name
	if len(track.Artists) > 0 {
		var artistNames []string
		for _, a := range track.Artists {
			artistNames = append(artistNames, a.Name)
		}
		tidalArtist = strings.Join(artistNames, ", ")
	}
	GoLog("[Tidal] Match found: '%s' by '%s' (duration: %ds)\n", track.Title, tidalArtist, track.Duration)

	// Cache the track ID for future use
	if req.ISRC != "" {
		GetTrackIDCache().SetTidal(req.ISRC, track.ID)
	}

	// Build filename
	filename := buildFilenameFromTemplate(req.FilenameFormat, map[string]interface{}{
		"title":  req.TrackName,
		"artist": req.ArtistName,
		"album":  req.AlbumName,
		"track":  req.TrackNumber,
		"year":   extractYear(req.ReleaseDate),
		"disc":   req.DiscNumber,
	})
	filename = sanitizeFilename(filename) + ".flac"
	outputPath := filepath.Join(req.OutputDir, filename)

	// Check if file already exists (both FLAC and M4A)
	if fileInfo, statErr := os.Stat(outputPath); statErr == nil && fileInfo.Size() > 0 {
		return TidalDownloadResult{FilePath: "EXISTS:" + outputPath}, nil
	}
	m4aPath := strings.TrimSuffix(outputPath, ".flac") + ".m4a"
	if fileInfo, statErr := os.Stat(m4aPath); statErr == nil && fileInfo.Size() > 0 {
		return TidalDownloadResult{FilePath: "EXISTS:" + m4aPath}, nil
	}

	// Clean up any leftover .tmp files from previous failed downloads
	tmpPath := outputPath + ".m4a.tmp"
	if _, err := os.Stat(tmpPath); err == nil {
		GoLog("[Tidal] Cleaning up leftover temp file: %s\n", tmpPath)
		os.Remove(tmpPath)
	}

	// Determine quality to use (default to LOSSLESS if not specified)
	quality := req.Quality
	if quality == "" {
		quality = "LOSSLESS"
	}
	GoLog("[Tidal] Using quality: %s\n", quality)

	// Get download URL using parallel API requests
	downloadInfo, err := downloader.GetDownloadURL(track.ID, quality)
	if err != nil {
		return TidalDownloadResult{}, fmt.Errorf("failed to get download URL: %w", err)
	}

	// Log actual quality received
	GoLog("[Tidal] Actual quality: %d-bit/%dHz\n", downloadInfo.BitDepth, downloadInfo.SampleRate)

	// START PARALLEL: Fetch cover and lyrics while downloading audio
	var parallelResult *ParallelDownloadResult
	parallelDone := make(chan struct{})
	go func() {
		defer close(parallelDone)
		parallelResult = FetchCoverAndLyricsParallel(
			req.CoverURL,
			req.EmbedMaxQualityCover,
			req.SpotifyID,
			req.TrackName,
			req.ArtistName,
			req.EmbedLyrics,
		)
	}()

	// Download audio file with item ID for progress tracking
	GoLog("[Tidal] Starting download to: %s\n", outputPath)
	GoLog("[Tidal] Download URL type: %s\n", func() string {
		if strings.HasPrefix(downloadInfo.URL, "MANIFEST:") {
			return "MANIFEST (DASH/BTS)"
		}
		return "Direct URL"
	}())

	if err := downloader.DownloadFile(downloadInfo.URL, outputPath, req.ItemID); err != nil {
		GoLog("[Tidal] Download failed with error: %v\n", err)
		return TidalDownloadResult{}, fmt.Errorf("download failed: %w", err)
	}
	fmt.Println("[Tidal] Download completed successfully")

	// Wait for parallel operations to complete
	<-parallelDone

	// Set progress to 100% and status to finalizing (before embedding)
	// This makes the UI show "Finalizing..." while embedding happens
	if req.ItemID != "" {
		SetItemProgress(req.ItemID, 1.0, 0, 0)
		SetItemFinalizing(req.ItemID)
	}

	// Check if file was saved as M4A (DASH stream) instead of FLAC
	// downloadFromManifest saves DASH streams as .m4a (m4aPath already defined above)
	actualOutputPath := outputPath
	if _, err := os.Stat(m4aPath); err == nil {
		// File was saved as M4A, use that path
		actualOutputPath = m4aPath
		GoLog("[Tidal] File saved as M4A (DASH stream): %s\n", actualOutputPath)
	} else if _, err := os.Stat(outputPath); err != nil {
		// Neither FLAC nor M4A exists
		return TidalDownloadResult{}, fmt.Errorf("download completed but file not found at %s or %s", outputPath, m4aPath)
	}

	// Embed metadata using parallel-fetched cover data
	metadata := Metadata{
		Title:       req.TrackName,
		Artist:      req.ArtistName,
		Album:       req.AlbumName,
		AlbumArtist: req.AlbumArtist,
		Date:        req.ReleaseDate,
		TrackNumber: track.TrackNumber, // Use actual track number from Tidal
		TotalTracks: req.TotalTracks,
		DiscNumber:  track.VolumeNumber, // Use actual disc number from Tidal
		ISRC:        track.ISRC,         // Use actual ISRC from Tidal
	}

	// Use cover data from parallel fetch
	var coverData []byte
	if parallelResult != nil && parallelResult.CoverData != nil {
		coverData = parallelResult.CoverData
		GoLog("[Tidal] Using parallel-fetched cover (%d bytes)\n", len(coverData))
	}

	// Embed metadata based on file type
	if strings.HasSuffix(actualOutputPath, ".flac") {
		if err := EmbedMetadataWithCoverData(actualOutputPath, metadata, coverData); err != nil {
			fmt.Printf("Warning: failed to embed metadata: %v\n", err)
		}

		// Embed lyrics from parallel fetch
		if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
			GoLog("[Tidal] Embedding parallel-fetched lyrics (%d lines)...\n", len(parallelResult.LyricsData.Lines))
			if embedErr := EmbedLyrics(actualOutputPath, parallelResult.LyricsLRC); embedErr != nil {
				GoLog("[Tidal] Warning: failed to embed lyrics: %v\n", embedErr)
			} else {
				fmt.Println("[Tidal] Lyrics embedded successfully")
			}
		} else if req.EmbedLyrics {
			fmt.Println("[Tidal] No lyrics available from parallel fetch")
		}
	} else if strings.HasSuffix(actualOutputPath, ".m4a") {
		// Embed metadata to M4A file
		// GoLog("[Tidal] Embedding metadata to M4A file...\n")

		// Add lyrics to metadata if available
		// if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
		// 	metadata.Lyrics = parallelResult.LyricsLRC
		// }

		// SKIP metadata embedding for M4A to prevent issues with FFmpeg conversion
		// M4A files from DASH are often fragmented and editing metadata might corrupt the container
		// structure that FFmpeg expects. Metadata will be re-embedded after conversion to FLAC in Flutter.

		fmt.Println("[Tidal] Skipping metadata embedding for M4A file (will be handled after FFmpeg conversion)")

		// if err := EmbedM4AMetadata(actualOutputPath, metadata, coverData); err != nil {
		// 	GoLog("[Tidal] Warning: failed to embed M4A metadata: %v\n", err)
		// } else {
		// 	fmt.Println("[Tidal] M4A metadata embedded successfully")
		// }
	}

	// Add to ISRC index for fast duplicate checking
	AddToISRCIndex(req.OutputDir, req.ISRC, actualOutputPath)

	return TidalDownloadResult{
		FilePath:    actualOutputPath,
		BitDepth:    downloadInfo.BitDepth,
		SampleRate:  downloadInfo.SampleRate,
		Title:       track.Title,
		Artist:      track.Artist.Name,
		Album:       track.Album.Title,
		ReleaseDate: track.Album.ReleaseDate,
		TrackNumber: track.TrackNumber,
		DiscNumber:  track.VolumeNumber,
		ISRC:        track.ISRC,
	}, nil
}
