package gobackend

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
)

// QobuzDownloader handles Qobuz downloads
type QobuzDownloader struct {
	client *http.Client
	appID  string
	apiURL string
}

// QobuzTrack represents a Qobuz track
type QobuzTrack struct {
	ID                  int64   `json:"id"`
	Title               string  `json:"title"`
	ISRC                string  `json:"isrc"`
	Duration            int     `json:"duration"`
	TrackNumber         int     `json:"track_number"`
	MaximumBitDepth     int     `json:"maximum_bit_depth"`
	MaximumSamplingRate float64 `json:"maximum_sampling_rate"`
	Album               struct {
		Title       string `json:"title"`
		ReleaseDate string `json:"release_date_original"`
		Image       struct {
			Large string `json:"large"`
		} `json:"image"`
	} `json:"album"`
	Performer struct {
		Name string `json:"name"`
	} `json:"performer"`
}

// NewQobuzDownloader creates a new Qobuz downloader
func NewQobuzDownloader() *QobuzDownloader {
	return &QobuzDownloader{
		client: NewHTTPClientWithTimeout(DefaultTimeout), // 60s timeout
		appID:  "798273057",
	}
}

// GetAvailableAPIs returns list of available Qobuz APIs
// Uses same APIs as PC version for compatibility
func (q *QobuzDownloader) GetAvailableAPIs() []string {
	// Same APIs as PC version (referensi/backend/qobuz.go)
	// Primary: dab.yeet.su, Fallback: dabmusic.xyz
	encodedAPIs := []string{
		"ZGFiLnllZXQuc3UvYXBpL3N0cmVhbT90cmFja0lkPQ==",     // dab.yeet.su/api/stream?trackId= (PRIMARY - same as PC)
		"ZGFibXVzaWMueHl6L2FwaS9zdHJlYW0/dHJhY2tJZD0=",     // dabmusic.xyz/api/stream?trackId= (FALLBACK - same as PC)
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

// SearchTrackByISRC searches for a track by ISRC
func (q *QobuzDownloader) SearchTrackByISRC(isrc string) (*QobuzTrack, error) {
	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly93d3cucW9idXouY29tL2FwaS5qc29uLzAuMi90cmFjay9zZWFyY2g/cXVlcnk9")
	searchURL := fmt.Sprintf("%s%s&limit=50&app_id=%s", string(apiBase), url.QueryEscape(isrc), q.appID)

	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("search failed: HTTP %d", resp.StatusCode)
	}

	var result struct {
		Tracks struct {
			Items []QobuzTrack `json:"items"`
		} `json:"tracks"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	// Find exact ISRC match
	for i := range result.Tracks.Items {
		if result.Tracks.Items[i].ISRC == isrc {
			return &result.Tracks.Items[i], nil
		}
	}

	if len(result.Tracks.Items) == 0 {
		return nil, fmt.Errorf("no tracks found for ISRC: %s", isrc)
	}

	return nil, fmt.Errorf("no exact ISRC match found for: %s", isrc)
}

// SearchTrackByMetadata searches for a track using artist name and track name
func (q *QobuzDownloader) SearchTrackByMetadata(trackName, artistName string) (*QobuzTrack, error) {
	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly93d3cucW9idXouY29tL2FwaS5qc29uLzAuMi90cmFjay9zZWFyY2g/cXVlcnk9")

	// Try multiple search strategies
	queries := []string{}

	// Strategy 1: Artist + Track name
	if artistName != "" && trackName != "" {
		queries = append(queries, artistName+" "+trackName)
	}

	// Strategy 2: Track name only
	if trackName != "" {
		queries = append(queries, trackName)
	}

	for _, query := range queries {
		searchURL := fmt.Sprintf("%s%s&limit=50&app_id=%s", string(apiBase), url.QueryEscape(query), q.appID)

		req, err := http.NewRequest("GET", searchURL, nil)
		if err != nil {
			continue
		}

		resp, err := DoRequestWithUserAgent(q.client, req)
		if err != nil {
			continue
		}

		if resp.StatusCode != 200 {
			resp.Body.Close()
			continue
		}

		var result struct {
			Tracks struct {
				Items []QobuzTrack `json:"items"`
			} `json:"tracks"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			resp.Body.Close()
			continue
		}
		resp.Body.Close()

		if len(result.Tracks.Items) > 0 {
			// Return first result with best quality
			for i := range result.Tracks.Items {
				track := &result.Tracks.Items[i]
				if track.MaximumBitDepth >= 24 {
					return track, nil
				}
			}
			// Return first result if no hi-res found
			return &result.Tracks.Items[0], nil
		}
	}

	return nil, fmt.Errorf("no tracks found for: %s - %s", artistName, trackName)
}

// getQobuzDownloadURLSequential requests download URL from APIs sequentially
// Uses same URL format as PC version: /api/stream?trackId={id}&quality={quality}
func getQobuzDownloadURLSequential(apis []string, trackID int64, quality string) (string, string, error) {
	if len(apis) == 0 {
		return "", "", fmt.Errorf("no APIs available")
	}

	client := NewHTTPClientWithTimeout(DefaultTimeout)
	retryConfig := DefaultRetryConfig()
	var errors []string

	for _, apiURL := range apis {
		// All APIs now use same format: https://domain/api/stream?trackId={id}&quality={quality}
		// The apiURL already includes the path, just append trackID and quality
		reqURL := fmt.Sprintf("%s%d&quality=%s", apiURL, trackID, quality)

		fmt.Printf("[Qobuz] Trying: %s\n", reqURL)

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

		// Check if response is HTML (error page)
		if len(body) > 0 && body[0] == '<' {
			errors = append(errors, BuildErrorMessage(apiURL, resp.StatusCode, "received HTML instead of JSON"))
			continue
		}

		// Check for error in JSON response
		var errorResp struct {
			Error string `json:"error"`
		}
		if json.Unmarshal(body, &errorResp) == nil && errorResp.Error != "" {
			errors = append(errors, BuildErrorMessage(apiURL, resp.StatusCode, errorResp.Error))
			continue
		}

		var result struct {
			URL string `json:"url"`
		}
		if err := json.Unmarshal(body, &result); err != nil {
			errors = append(errors, BuildErrorMessage(apiURL, resp.StatusCode, "invalid JSON: "+err.Error()))
			continue
		}

		if result.URL != "" {
			fmt.Printf("[Qobuz] Got download URL from: %s\n", apiURL)
			return apiURL, result.URL, nil
		}

		errors = append(errors, BuildErrorMessage(apiURL, resp.StatusCode, "no download URL in response"))
	}

	return "", "", fmt.Errorf("all %d Qobuz APIs failed. Errors: %v", len(apis), errors)
}

// GetDownloadURL gets download URL for a track - tries APIs sequentially
func (q *QobuzDownloader) GetDownloadURL(trackID int64, quality string) (string, error) {
	apis := q.GetAvailableAPIs()
	if len(apis) == 0 {
		return "", fmt.Errorf("no Qobuz API available")
	}

	_, downloadURL, err := getQobuzDownloadURLSequential(apis, trackID, quality)
	if err != nil {
		return "", err
	}

	return downloadURL, nil
}

// DownloadFile downloads a file from URL with User-Agent and progress tracking
func (q *QobuzDownloader) DownloadFile(downloadURL, outputPath, itemID string) error {
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

	resp, err := DoRequestWithUserAgent(q.client, req)
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

// downloadFromQobuz downloads a track using the request parameters
func downloadFromQobuz(req DownloadRequest) (string, error) {
	downloader := NewQobuzDownloader()

	// Check for existing file first
	if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
		return "EXISTS:" + existingFile, nil
	}

	var track *QobuzTrack
	var err error

	// Strategy 1: Search by ISRC
	if req.ISRC != "" {
		track, err = downloader.SearchTrackByISRC(req.ISRC)
	}

	// Strategy 2: Search by metadata
	if track == nil {
		track, err = downloader.SearchTrackByMetadata(req.TrackName, req.ArtistName)
	}

	if track == nil {
		errMsg := "could not find track on Qobuz"
		if err != nil {
			errMsg = err.Error()
		}
		return "", fmt.Errorf("qobuz search failed: %s", errMsg)
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

	// Map quality from Tidal format to Qobuz format
	// Tidal: LOSSLESS (16-bit), HI_RES (24-bit), HI_RES_LOSSLESS (24-bit hi-res)
	// Qobuz: 5 (MP3 320), 6 (16-bit), 7 (24-bit 96kHz), 27 (24-bit 192kHz)
	qobuzQuality := "27" // Default to highest quality
	switch req.Quality {
	case "LOSSLESS":
		qobuzQuality = "6" // 16-bit FLAC
	case "HI_RES":
		qobuzQuality = "7" // 24-bit 96kHz
	case "HI_RES_LOSSLESS":
		qobuzQuality = "27" // 24-bit 192kHz
	}
	fmt.Printf("[Qobuz] Using quality: %s (mapped from %s)\n", qobuzQuality, req.Quality)

	// Get download URL using parallel API requests
	downloadURL, err := downloader.GetDownloadURL(track.ID, qobuzQuality)
	if err != nil {
		return "", fmt.Errorf("failed to get download URL: %w", err)
	}

	// Download file with item ID for progress tracking
	if err := downloader.DownloadFile(downloadURL, outputPath, req.ItemID); err != nil {
		return "", fmt.Errorf("download failed: %w", err)
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
		fmt.Println("[Qobuz] Downloading cover to memory...")
		data, err := downloadCoverToMemory(req.CoverURL, req.EmbedMaxQualityCover)
		if err == nil {
			coverData = data
			fmt.Printf("[Qobuz] Cover downloaded successfully (%d bytes)\n", len(coverData))
		} else {
			fmt.Printf("[Qobuz] Warning: failed to download cover: %v\n", err)
		}
	}

	if err := EmbedMetadataWithCoverData(outputPath, metadata, coverData); err != nil {
		fmt.Printf("Warning: failed to embed metadata: %v\n", err)
	}

	// Embed lyrics if enabled
	if req.EmbedLyrics {
		fmt.Println("[Qobuz] Fetching lyrics...")
		lyricsClient := NewLyricsClient()
		lyrics, lyricsErr := lyricsClient.FetchLyricsAllSources(req.SpotifyID, req.TrackName, req.ArtistName)
		if lyricsErr != nil {
			fmt.Printf("[Qobuz] Warning: lyrics fetch error: %v\n", lyricsErr)
		} else if lyrics == nil || len(lyrics.Lines) == 0 {
			fmt.Println("[Qobuz] No lyrics found for this track")
		} else {
			fmt.Printf("[Qobuz] Lyrics found (%d lines), embedding...\n", len(lyrics.Lines))
			
			// Convert Japanese lyrics to romaji if enabled
			if req.ConvertLyricsToRomaji {
				for i := range lyrics.Lines {
					if ContainsKana(lyrics.Lines[i].Words) {
						lyrics.Lines[i].Words = ToRomaji(lyrics.Lines[i].Words)
					}
				}
				fmt.Println("[Qobuz] Converted Japanese lyrics to romaji")
			}
			
			lrcContent := convertToLRC(lyrics)
			if embedErr := EmbedLyrics(outputPath, lrcContent); embedErr != nil {
				fmt.Printf("[Qobuz] Warning: failed to embed lyrics: %v\n", embedErr)
			} else {
				fmt.Println("[Qobuz] Lyrics embedded successfully")
			}
		}
	}

	return outputPath, nil
}
