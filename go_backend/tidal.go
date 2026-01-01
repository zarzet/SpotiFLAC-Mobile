package gobackend

import (
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
	"time"
)

// TidalDownloader handles Tidal downloads
type TidalDownloader struct {
	client       *http.Client
	clientID     string
	clientSecret string
	apiURL       string
}

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

// NewTidalDownloader creates a new Tidal downloader
func NewTidalDownloader() *TidalDownloader {
	clientID, _ := base64.StdEncoding.DecodeString("NkJEU1JkcEs5aHFFQlRnVQ==")
	clientSecret, _ := base64.StdEncoding.DecodeString("eGV1UG1ZN25icFo5SUliTEFjUTkzc2hrYTFWTmhlVUFxTjZJY3N6alRHOD0=")

	downloader := &TidalDownloader{
		client:       NewHTTPClientWithTimeout(DefaultTimeout), // 60s timeout
		clientID:     string(clientID),
		clientSecret: string(clientSecret),
	}

	// Get first available API
	apis := downloader.GetAvailableAPIs()
	if len(apis) > 0 {
		downloader.apiURL = apis[0]
	}

	return downloader
}

// GetAvailableAPIs returns list of available Tidal APIs
func (t *TidalDownloader) GetAvailableAPIs() []string {
	encodedAPIs := []string{
		"dm9nZWwucXFkbC5zaXRl",         // API 1 - vogel.qqdl.site
		"bWF1cy5xcWRsLnNpdGU=",         // API 2 - maus.qqdl.site
		"aHVuZC5xcWRsLnNpdGU=",         // API 3 - hund.qqdl.site
		"a2F0emUucXFkbC5zaXRl",         // API 4 - katze.qqdl.site
		"d29sZi5xcWRsLnNpdGU=",         // API 5 - wolf.qqdl.site
		"dGlkYWwua2lub3BsdXMub25saW5l", // API 6 - tidal.kinoplus.online
		"dGlkYWwtYXBpLmJpbmltdW0ub3Jn", // API 7 - tidal-api.binimum.org
		"dHJpdG9uLnNxdWlkLnd0Zg==",     // API 8 - triton.squid.wtf
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

// GetAccessToken gets Tidal access token
func (t *TidalDownloader) GetAccessToken() (string, error) {
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
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
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

// SearchTrackByMetadataWithISRC searches for a track with ISRC matching priority
func (t *TidalDownloader) SearchTrackByMetadataWithISRC(trackName, artistName, spotifyISRC string, expectedDuration int) (*TidalTrack, error) {
	token, err := t.GetAccessToken()
	if err != nil {
		return nil, err
	}

	// Build search queries - multiple strategies
	queries := []string{}

	// Strategy 1: Artist + Track name (original)
	if artistName != "" && trackName != "" {
		queries = append(queries, artistName+" "+trackName)
	}

	// Strategy 2: Track name only
	if trackName != "" {
		queries = append(queries, trackName)
	}

	// Strategy 3: Romaji versions if Japanese detected
	if ContainsJapanese(trackName) || ContainsJapanese(artistName) {
		// Try romaji version of track name
		if ContainsKana(trackName) {
			romajiTrack := ToRomaji(trackName)
			if romajiTrack != trackName {
				if artistName != "" {
					queries = append(queries, artistName+" "+romajiTrack)
				}
				queries = append(queries, romajiTrack)
			}
		}
		// Try romaji version of artist name
		if ContainsKana(artistName) {
			romajiArtist := ToRomaji(artistName)
			if romajiArtist != artistName {
				queries = append(queries, romajiArtist+" "+trackName)
				// Try both romaji
				if ContainsKana(trackName) {
					romajiTrack := ToRomaji(trackName)
					queries = append(queries, romajiArtist+" "+romajiTrack)
				}
			}
		}
	}

	// Strategy 4: Artist only as last resort
	if artistName != "" {
		queries = append(queries, artistName)
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

		searchURL := fmt.Sprintf("%s%s&limit=100&countryCode=US", string(searchBase), url.QueryEscape(cleanQuery))

		req, err := http.NewRequest("GET", searchURL, nil)
		if err != nil {
			continue
		}

		req.Header.Set("Authorization", "Bearer "+token)

		resp, err := DoRequestWithUserAgent(t.client, req)
		if err != nil {
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
			allTracks = append(allTracks, result.Items...)
		}
	}

	if len(allTracks) == 0 {
		return nil, fmt.Errorf("no tracks found for any search query")
	}

	// Priority 1: Match by ISRC (exact match)
	if spotifyISRC != "" {
		for i := range allTracks {
			track := &allTracks[i]
			if track.ISRC == spotifyISRC {
				return track, nil
			}
		}
		// If ISRC was provided but no match found, return error
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

	return bestMatch, nil
}

// SearchTrackByMetadata searches for a track using artist name and track name
func (t *TidalDownloader) SearchTrackByMetadata(trackName, artistName string) (*TidalTrack, error) {
	return t.SearchTrackByMetadataWithISRC(trackName, artistName, "", 0)
}


// getDownloadURLSequential requests download URL from APIs sequentially
// Returns the first successful result (supports both v1 and v2 API formats)
func getDownloadURLSequential(apis []string, trackID int64, quality string) (string, string, error) {
	if len(apis) == 0 {
		return "", "", fmt.Errorf("no APIs available")
	}

	client := NewHTTPClientWithTimeout(DefaultTimeout)
	retryConfig := DefaultRetryConfig()
	var errors []string

	for _, apiURL := range apis {
		reqURL := fmt.Sprintf("%s/track/?id=%d&quality=%s", apiURL, trackID, quality)

		req, err := http.NewRequest("GET", reqURL, nil)
		if err != nil {
			errors = append(errors, BuildErrorMessage(apiURL, 0, err.Error()))
			continue
		}

		resp, err := DoRequestWithRetry(client, req, retryConfig)
		if err != nil {
			errors = append(errors, BuildErrorMessage(apiURL, 0, err.Error()))
			continue
		}

		body, err := ReadResponseBody(resp)
		resp.Body.Close()
		if err != nil {
			errors = append(errors, BuildErrorMessage(apiURL, resp.StatusCode, err.Error()))
			continue
		}

		// Try v2 format first (object with manifest)
		var v2Response TidalAPIResponseV2
		if err := json.Unmarshal(body, &v2Response); err == nil && v2Response.Data.Manifest != "" {
			return apiURL, "MANIFEST:" + v2Response.Data.Manifest, nil
		}

		// Fallback to v1 format (array with OriginalTrackUrl)
		var v1Responses []struct {
			OriginalTrackURL string `json:"OriginalTrackUrl"`
		}
		if err := json.Unmarshal(body, &v1Responses); err == nil {
			for _, item := range v1Responses {
				if item.OriginalTrackURL != "" {
					return apiURL, item.OriginalTrackURL, nil
				}
			}
		}

		errors = append(errors, BuildErrorMessage(apiURL, resp.StatusCode, "no download URL or manifest in response"))
	}

	return "", "", fmt.Errorf("all %d Tidal APIs failed. Errors: %v", len(apis), errors)
}

// GetDownloadURL gets download URL for a track - tries APIs sequentially
func (t *TidalDownloader) GetDownloadURL(trackID int64, quality string) (string, error) {
	apis := t.GetAvailableAPIs()
	if len(apis) == 0 {
		return "", fmt.Errorf("no API URL configured")
	}

	_, downloadURL, err := getDownloadURLSequential(apis, trackID, quality)
	if err != nil {
		return "", fmt.Errorf("failed to get download URL: %w", err)
	}

	return downloadURL, nil
}

// parseManifest parses Tidal manifest (supports both BTS and DASH formats)
func parseManifest(manifestB64 string) (directURL string, initURL string, mediaURLs []string, err error) {
	manifestBytes, err := base64.StdEncoding.DecodeString(manifestB64)
	if err != nil {
		return "", "", nil, fmt.Errorf("failed to decode manifest: %w", err)
	}

	manifestStr := string(manifestBytes)

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
	for _, seg := range segTemplate.Timeline.Segments {
		segmentCount += seg.Repeat + 1
	}

	// If no segments found via XML, try regex
	if segmentCount == 0 {
		segRe := regexp.MustCompile(`<S d="\d+"(?: r="(\d+)")?`)
		matches := segRe.FindAllStringSubmatch(manifestStr, -1)
		for _, match := range matches {
			repeat := 0
			if len(match) > 1 && match[1] != "" {
				fmt.Sscanf(match[1], "%d", &repeat)
			}
			segmentCount += repeat + 1
		}
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
	// Handle manifest-based download
	if strings.HasPrefix(downloadURL, "MANIFEST:") {
		return t.downloadFromManifest(strings.TrimPrefix(downloadURL, "MANIFEST:"), outputPath, itemID)
	}

	// Set current file being downloaded (legacy)
	SetCurrentFile(filepath.Base(outputPath))
	SetDownloading(true)
	defer SetDownloading(false)

	// Initialize item progress if itemID provided
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

	// Set total bytes if available
	if resp.ContentLength > 0 {
		SetBytesTotal(resp.ContentLength)
		if itemID != "" {
			SetItemBytesTotal(itemID, resp.ContentLength)
		}
	}

	out, err := os.Create(outputPath)
	if err != nil {
		return err
	}
	defer out.Close()

	// Use appropriate progress writer
	if itemID != "" {
		progressWriter := NewItemProgressWriter(out, itemID)
		_, err = io.Copy(progressWriter, resp.Body)
	} else {
		progressWriter := NewProgressWriter(out)
		_, err = io.Copy(progressWriter, resp.Body)
	}
	return err
}

func (t *TidalDownloader) downloadFromManifest(manifestB64, outputPath, itemID string) error {
	directURL, initURL, mediaURLs, err := parseManifest(manifestB64)
	if err != nil {
		return fmt.Errorf("failed to parse manifest: %w", err)
	}

	client := &http.Client{
		Timeout: 120 * time.Second,
	}

	// If we have a direct URL (BTS format), download directly with progress tracking
	if directURL != "" {
		// Set current file being downloaded (legacy)
		SetCurrentFile(filepath.Base(outputPath))
		SetDownloading(true)
		defer SetDownloading(false)

		// Initialize item progress if itemID provided
		if itemID != "" {
			StartItemProgress(itemID)
			defer CompleteItemProgress(itemID)
		}

		req, err := http.NewRequest("GET", directURL, nil)
		if err != nil {
			return fmt.Errorf("failed to create request: %w", err)
		}

		resp, err := client.Do(req)
		if err != nil {
			return fmt.Errorf("failed to download file: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			return fmt.Errorf("download failed with status %d", resp.StatusCode)
		}

		// Set total bytes for progress tracking
		if resp.ContentLength > 0 {
			SetBytesTotal(resp.ContentLength)
			if itemID != "" {
				SetItemBytesTotal(itemID, resp.ContentLength)
			}
		}

		out, err := os.Create(outputPath)
		if err != nil {
			return fmt.Errorf("failed to create file: %w", err)
		}
		defer out.Close()

		// Use appropriate progress writer
		if itemID != "" {
			progressWriter := NewItemProgressWriter(out, itemID)
			_, err = io.Copy(progressWriter, resp.Body)
		} else {
			progressWriter := NewProgressWriter(out)
			_, err = io.Copy(progressWriter, resp.Body)
		}
		return err
	}

	// DASH format - download segments to temporary file
	// Note: On Android, we can't use ffmpeg, so we'll try to download as M4A
	// and hope the player can handle it, or we save as .m4a instead of .flac
	tempPath := outputPath + ".m4a.tmp"
	out, err := os.Create(tempPath)
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}

	// Download initialization segment
	resp, err := client.Get(initURL)
	if err != nil {
		out.Close()
		os.Remove(tempPath)
		return fmt.Errorf("failed to download init segment: %w", err)
	}
	if resp.StatusCode != 200 {
		resp.Body.Close()
		out.Close()
		os.Remove(tempPath)
		return fmt.Errorf("init segment download failed with status %d", resp.StatusCode)
	}
	_, err = io.Copy(out, resp.Body)
	resp.Body.Close()
	if err != nil {
		out.Close()
		os.Remove(tempPath)
		return fmt.Errorf("failed to write init segment: %w", err)
	}

	// Download media segments
	for i, mediaURL := range mediaURLs {
		resp, err := client.Get(mediaURL)
		if err != nil {
			out.Close()
			os.Remove(tempPath)
			return fmt.Errorf("failed to download segment %d: %w", i+1, err)
		}
		if resp.StatusCode != 200 {
			resp.Body.Close()
			out.Close()
			os.Remove(tempPath)
			return fmt.Errorf("segment %d download failed with status %d", i+1, resp.StatusCode)
		}
		_, err = io.Copy(out, resp.Body)
		resp.Body.Close()
		if err != nil {
			out.Close()
			os.Remove(tempPath)
			return fmt.Errorf("failed to write segment %d: %w", i+1, err)
		}
	}

	out.Close()

	// For Android, we'll save as M4A since we can't use ffmpeg
	// Rename temp file to final output (change extension to .m4a if needed)
	m4aPath := strings.TrimSuffix(outputPath, ".flac") + ".m4a"
	if err := os.Rename(tempPath, m4aPath); err != nil {
		os.Remove(tempPath)
		return fmt.Errorf("failed to rename temp file: %w", err)
	}

	// If the original output was .flac, we need to indicate this is actually m4a
	// For now, we'll just keep it as m4a
	return nil
}

// downloadFromTidal downloads a track using the request parameters
func downloadFromTidal(req DownloadRequest) (string, error) {
	downloader := NewTidalDownloader()

	// Check for existing file first
	if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
		return "EXISTS:" + existingFile, nil
	}

	var track *TidalTrack
	var err error

	// Strategy 1: Try to get Tidal URL from SongLink (using Spotify ID)
	if req.SpotifyID != "" {
		tidalURL, slErr := downloader.GetTidalURLFromSpotify(req.SpotifyID)
		if slErr == nil && tidalURL != "" {
			// Extract track ID and get track info
			trackID, idErr := downloader.GetTrackIDFromURL(tidalURL)
			if idErr == nil {
				track, err = downloader.GetTrackInfoByID(trackID)
			}
		}
	}

	// Strategy 2: Search by ISRC with multi-strategy fallback
	if track == nil && req.ISRC != "" {
		track, err = downloader.SearchTrackByMetadataWithISRC(req.TrackName, req.ArtistName, req.ISRC, 0)
	}

	// Strategy 3: Search by metadata only (no ISRC requirement)
	if track == nil {
		track, err = downloader.SearchTrackByMetadata(req.TrackName, req.ArtistName)
	}

	if track == nil {
		errMsg := "could not find track on Tidal"
		if err != nil {
			errMsg = err.Error()
		}
		return "", fmt.Errorf("tidal search failed: %s", errMsg)
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

	// Check if file already exists
	if fileInfo, statErr := os.Stat(outputPath); statErr == nil && fileInfo.Size() > 0 {
		return "EXISTS:" + outputPath, nil
	}

	// Determine quality to use (default to LOSSLESS if not specified)
	quality := req.Quality
	if quality == "" {
		quality = "LOSSLESS"
	}
	fmt.Printf("[Tidal] Using quality: %s\n", quality)

	// Get download URL using parallel API requests
	downloadURL, err := downloader.GetDownloadURL(track.ID, quality)
	if err != nil {
		return "", fmt.Errorf("failed to get download URL: %w", err)
	}

	// Download file with item ID for progress tracking
	if err := downloader.DownloadFile(downloadURL, outputPath, req.ItemID); err != nil {
		return "", fmt.Errorf("download failed: %w", err)
	}

	// Check if file was saved as M4A (DASH stream) instead of FLAC
	// downloadFromManifest saves DASH streams as .m4a
	actualOutputPath := outputPath
	m4aPath := strings.TrimSuffix(outputPath, ".flac") + ".m4a"
	if _, err := os.Stat(m4aPath); err == nil {
		// File was saved as M4A, use that path
		actualOutputPath = m4aPath
		fmt.Printf("[Tidal] File saved as M4A (DASH stream): %s\n", actualOutputPath)
	} else if _, err := os.Stat(outputPath); err != nil {
		// Neither FLAC nor M4A exists
		return "", fmt.Errorf("download completed but file not found at %s or %s", outputPath, m4aPath)
	}

	// Embed metadata
	metadata := Metadata{
		Title:       req.TrackName,
		Artist:      req.ArtistName,
		Album:       req.AlbumName,
		AlbumArtist: req.AlbumArtist,
		Date:        req.ReleaseDate,
		TrackNumber: req.TrackNumber,
		TotalTracks: req.TotalTracks,
		DiscNumber:  req.DiscNumber,
		ISRC:        req.ISRC,
	}

	// Download cover to memory (avoids file permission issues on Android)
	var coverData []byte
	if req.CoverURL != "" {
		fmt.Println("[Tidal] Downloading cover to memory...")
		data, err := downloadCoverToMemory(req.CoverURL, req.EmbedMaxQualityCover)
		if err == nil {
			coverData = data
			fmt.Printf("[Tidal] Cover downloaded successfully (%d bytes)\n", len(coverData))
		} else {
			fmt.Printf("[Tidal] Warning: failed to download cover: %v\n", err)
		}
	}

	// Only embed metadata to FLAC files (M4A will be converted by Flutter)
	if strings.HasSuffix(actualOutputPath, ".flac") {
		if err := EmbedMetadataWithCoverData(actualOutputPath, metadata, coverData); err != nil {
			fmt.Printf("Warning: failed to embed metadata: %v\n", err)
		}

		// Embed lyrics if enabled
		if req.EmbedLyrics {
			fmt.Println("[Tidal] Fetching lyrics...")
			lyricsClient := NewLyricsClient()
			lyrics, lyricsErr := lyricsClient.FetchLyricsAllSources(req.SpotifyID, req.TrackName, req.ArtistName)
			if lyricsErr != nil {
				fmt.Printf("[Tidal] Warning: lyrics fetch error: %v\n", lyricsErr)
			} else if lyrics == nil || len(lyrics.Lines) == 0 {
				fmt.Println("[Tidal] No lyrics found for this track")
			} else {
				fmt.Printf("[Tidal] Lyrics found (%d lines), embedding...\n", len(lyrics.Lines))
				
				// Convert Japanese lyrics to romaji if enabled
				if req.ConvertLyricsToRomaji {
					for i := range lyrics.Lines {
						if ContainsKana(lyrics.Lines[i].Words) {
							lyrics.Lines[i].Words = ToRomaji(lyrics.Lines[i].Words)
						}
					}
					fmt.Println("[Tidal] Converted Japanese lyrics to romaji")
				}
				
				lrcContent := convertToLRC(lyrics)
				if embedErr := EmbedLyrics(actualOutputPath, lrcContent); embedErr != nil {
					fmt.Printf("[Tidal] Warning: failed to embed lyrics: %v\n", embedErr)
				} else {
					fmt.Println("[Tidal] Lyrics embedded successfully")
				}
			}
		}
	} else {
		fmt.Printf("[Tidal] Skipping metadata embed for M4A file (will be handled after conversion): %s\n", actualOutputPath)
	}

	return actualOutputPath, nil
}
