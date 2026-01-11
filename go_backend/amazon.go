package gobackend

import (
	"bufio"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// AmazonDownloader handles Amazon Music downloads using DoubleDouble service (same as PC)
type AmazonDownloader struct {
	client           *http.Client
	regions          []string  // us, eu regions for DoubleDouble service
	lastAPICallTime  time.Time // Rate limiting: track last API call
	apiCallCount     int       // Rate limiting: counter per minute
	apiCallResetTime time.Time // Rate limiting: reset time
}

var (
	// Global Amazon downloader instance for connection reuse
	globalAmazonDownloader *AmazonDownloader
	amazonDownloaderOnce   sync.Once
	amazonRateLimitMu      sync.Mutex // Mutex for rate limiting
)

// DoubleDoubleSubmitResponse is the response from DoubleDouble submit endpoint
type DoubleDoubleSubmitResponse struct {
	Success bool   `json:"success"`
	ID      string `json:"id"`
}

// DoubleDoubleStatusResponse is the response from DoubleDouble status endpoint
type DoubleDoubleStatusResponse struct {
	Status         string `json:"status"`
	FriendlyStatus string `json:"friendlyStatus"`
	URL            string `json:"url"`
	Current        struct {
		Name   string `json:"name"`
		Artist string `json:"artist"`
	} `json:"current"`
}

// amazonArtistsMatch checks if the artist names are similar enough
func amazonArtistsMatch(expectedArtist, foundArtist string) bool {
	normExpected := strings.ToLower(strings.TrimSpace(expectedArtist))
	normFound := strings.ToLower(strings.TrimSpace(foundArtist))

	// Exact match
	if normExpected == normFound {
		return true
	}

	// Check if one contains the other
	if strings.Contains(normExpected, normFound) || strings.Contains(normFound, normExpected) {
		return true
	}

	// Check first artist (before comma or feat)
	expectedFirst := strings.Split(normExpected, ",")[0]
	expectedFirst = strings.Split(expectedFirst, " feat")[0]
	expectedFirst = strings.Split(expectedFirst, " ft.")[0]
	expectedFirst = strings.TrimSpace(expectedFirst)

	foundFirst := strings.Split(normFound, ",")[0]
	foundFirst = strings.Split(foundFirst, " feat")[0]
	foundFirst = strings.Split(foundFirst, " ft.")[0]
	foundFirst = strings.TrimSpace(foundFirst)

	if expectedFirst == foundFirst {
		return true
	}

	// Check if first artist is contained in the other
	if strings.Contains(expectedFirst, foundFirst) || strings.Contains(foundFirst, expectedFirst) {
		return true
	}

	// If scripts are different (one is ASCII, one is non-ASCII like Japanese/Chinese/Korean),
	// assume they're the same artist with different transliteration
	expectedASCII := amazonIsASCIIString(expectedArtist)
	foundASCII := amazonIsASCIIString(foundArtist)
	if expectedASCII != foundASCII {
		GoLog("[Amazon] Artist names in different scripts, assuming match: '%s' vs '%s'\n", expectedArtist, foundArtist)
		return true
	}

	return false
}

// amazonIsASCIIString checks if a string contains only ASCII characters
func amazonIsASCIIString(s string) bool {
	for _, r := range s {
		if r > 127 {
			return false
		}
	}
	return true
}

// NewAmazonDownloader creates a new Amazon downloader (returns singleton for connection reuse)
func NewAmazonDownloader() *AmazonDownloader {
	amazonDownloaderOnce.Do(func() {
		globalAmazonDownloader = &AmazonDownloader{
			client:           NewHTTPClientWithTimeout(120 * time.Second), // 120s timeout like PC
			regions:          []string{"us", "eu"},                        // Same regions as PC
			apiCallResetTime: time.Now(),
		}
	})
	return globalAmazonDownloader
}

// waitForRateLimit implements rate limiting similar to PC version
// Max 9 requests per minute with 7 second delay between requests
func (a *AmazonDownloader) waitForRateLimit() {
	amazonRateLimitMu.Lock()
	defer amazonRateLimitMu.Unlock()

	now := time.Now()

	// Reset counter every minute
	if now.Sub(a.apiCallResetTime) >= time.Minute {
		a.apiCallCount = 0
		a.apiCallResetTime = now
	}

	// If we've hit the limit (9 requests per minute), wait until next minute
	if a.apiCallCount >= 9 {
		waitTime := time.Minute - now.Sub(a.apiCallResetTime)
		if waitTime > 0 {
			GoLog("[Amazon] Rate limit reached, waiting %v...\n", waitTime.Round(time.Second))
			time.Sleep(waitTime)
			a.apiCallCount = 0
			a.apiCallResetTime = time.Now()
		}
	}

	// Add delay between requests (7 seconds like PC version)
	if !a.lastAPICallTime.IsZero() {
		timeSinceLastCall := now.Sub(a.lastAPICallTime)
		minDelay := 7 * time.Second
		if timeSinceLastCall < minDelay {
			waitTime := minDelay - timeSinceLastCall
			GoLog("[Amazon] Rate limiting: waiting %v...\n", waitTime.Round(time.Second))
			time.Sleep(waitTime)
		}
	}

	// Update tracking
	a.lastAPICallTime = time.Now()
	a.apiCallCount++
}

// GetAvailableAPIs returns list of available DoubleDouble regions
// Uses same service as PC version (doubledouble.top)
func (a *AmazonDownloader) GetAvailableAPIs() []string {
	// DoubleDouble service regions (same as PC)
	// Format: https://{region}.doubledouble.top
	var apis []string
	for _, region := range a.regions {
		apis = append(apis, fmt.Sprintf("https://%s.doubledouble.top", region))
	}
	return apis
}

// downloadFromDoubleDoubleService downloads a track using DoubleDouble service (same as PC)
// This uses submit → poll → download mechanism
// Internal function - not exported to gomobile
func (a *AmazonDownloader) downloadFromDoubleDoubleService(amazonURL, _ string) (string, string, string, error) {
	var lastError error

	for _, region := range a.regions {
		GoLog("[Amazon] Trying region: %s...\n", region)

		// Build base URL for DoubleDouble service
		// Decode base64 service URL (same as PC)
		serviceBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly8=")               // https://
		serviceDomain, _ := base64.StdEncoding.DecodeString("LmRvdWJsZWRvdWJsZS50b3A=") // .doubledouble.top
		baseURL := fmt.Sprintf("%s%s%s", string(serviceBase), region, string(serviceDomain))

		// Step 1: Submit download request with rate limiting
		encodedURL := url.QueryEscape(amazonURL)
		submitURL := fmt.Sprintf("%s/dl?url=%s", baseURL, encodedURL)

		// Apply rate limiting before request (like PC version)
		a.waitForRateLimit()

		req, err := http.NewRequest("GET", submitURL, nil)
		if err != nil {
			lastError = fmt.Errorf("failed to create request: %w", err)
			continue
		}

		req.Header.Set("User-Agent", getRandomUserAgent())

		fmt.Println("[Amazon] Submitting download request...")

		// Retry logic for 429 errors (like PC version: 3 retries with 15s wait)
		var resp *http.Response
		maxRetries := 3
		for retry := 0; retry < maxRetries; retry++ {
			resp, err = a.client.Do(req)
			if err != nil {
				lastError = fmt.Errorf("failed to submit request: %w", err)
				break
			}

			if resp.StatusCode == 429 { // Too Many Requests
				resp.Body.Close()
				if retry < maxRetries-1 {
					waitTime := 15 * time.Second
					GoLog("[Amazon] Rate limited (429), waiting %v before retry %d/%d...\n", waitTime, retry+2, maxRetries)
					time.Sleep(waitTime)
					continue
				}
				lastError = fmt.Errorf("API rate limit exceeded after %d retries", maxRetries)
				break
			}

			if resp.StatusCode != 200 {
				resp.Body.Close()
				lastError = fmt.Errorf("submit failed with status %d", resp.StatusCode)
				break
			}

			// Success - break retry loop
			break
		}

		if err != nil || lastError != nil {
			if resp != nil {
				resp.Body.Close()
			}
			continue
		}

		var submitResp DoubleDoubleSubmitResponse
		if err := json.NewDecoder(resp.Body).Decode(&submitResp); err != nil {
			resp.Body.Close()
			lastError = fmt.Errorf("failed to decode submit response: %w", err)
			continue
		}
		resp.Body.Close()

		if !submitResp.Success || submitResp.ID == "" {
			lastError = fmt.Errorf("submit request failed")
			continue
		}

		downloadID := submitResp.ID
		GoLog("[Amazon] Download ID: %s\n", downloadID)

		// Step 2: Poll for completion
		statusURL := fmt.Sprintf("%s/dl/%s", baseURL, downloadID)
		fmt.Println("[Amazon] Waiting for download to complete...")

		maxWait := 300 * time.Second // 5 minutes max wait
		elapsed := time.Duration(0)
		pollInterval := 3 * time.Second

		for elapsed < maxWait {
			time.Sleep(pollInterval)
			elapsed += pollInterval

			statusReq, err := http.NewRequest("GET", statusURL, nil)
			if err != nil {
				continue
			}

			statusReq.Header.Set("User-Agent", getRandomUserAgent())

			statusResp, err := a.client.Do(statusReq)
			if err != nil {
				fmt.Printf("\r[Amazon] Status check failed, retrying...")
				continue
			}

			if statusResp.StatusCode != 200 {
				statusResp.Body.Close()
				fmt.Printf("\r[Amazon] Status check failed (status %d), retrying...", statusResp.StatusCode)
				continue
			}

			var status DoubleDoubleStatusResponse
			if err := json.NewDecoder(statusResp.Body).Decode(&status); err != nil {
				statusResp.Body.Close()
				fmt.Printf("\r[Amazon] Invalid JSON response, retrying...")
				continue
			}
			statusResp.Body.Close()

			if status.Status == "done" {
				fmt.Println("\n[Amazon] Download ready!")

				// Build download URL
				fileURL := status.URL
				if strings.HasPrefix(fileURL, "./") {
					fileURL = fmt.Sprintf("%s/%s", baseURL, fileURL[2:])
				} else if strings.HasPrefix(fileURL, "/") {
					fileURL = fmt.Sprintf("%s%s", baseURL, fileURL)
				}

				trackName := status.Current.Name
				artist := status.Current.Artist

				GoLog("[Amazon] Downloading: %s - %s\n", artist, trackName)
				return fileURL, trackName, artist, nil

			} else if status.Status == "error" {
				errorMsg := status.FriendlyStatus
				if errorMsg == "" {
					errorMsg = "Unknown error"
				}
				lastError = fmt.Errorf("processing failed: %s", errorMsg)
				break
			} else {
				// Still processing
				friendlyStatus := status.FriendlyStatus
				if friendlyStatus == "" {
					friendlyStatus = status.Status
				}
				fmt.Printf("\r[Amazon] %s...", friendlyStatus)
			}
		}

		if elapsed >= maxWait {
			lastError = fmt.Errorf("download timeout")
			fmt.Printf("\n[Amazon] Error with %s region: %v\n", region, lastError)
			continue
		}

		if lastError != nil {
			fmt.Printf("\n[Amazon] Error with %s region: %v\n", region, lastError)
		}
	}

	return "", "", "", fmt.Errorf("all regions failed. Last error: %v", lastError)
}

// DownloadFile downloads a file from URL with User-Agent and progress tracking
func (a *AmazonDownloader) DownloadFile(downloadURL, outputPath, itemID string) error {
	// Initialize item progress (required for all downloads)
	if itemID != "" {
		StartItemProgress(itemID)
		defer CompleteItemProgress(itemID)
	}

	req, err := http.NewRequest("GET", downloadURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := a.client.Do(req)
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
		pw := NewItemProgressWriter(bufWriter, itemID)
		written, err = io.Copy(pw, resp.Body)
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

	fmt.Printf("\r[Amazon] Downloaded: %.2f MB (Complete)\n", float64(written)/(1024*1024))
	return nil
}

// AmazonDownloadResult contains download result with quality info
type AmazonDownloadResult struct {
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

// downloadFromAmazon downloads a track using the request parameters
// Uses DoubleDouble service (same as PC version)
func downloadFromAmazon(req DownloadRequest) (AmazonDownloadResult, error) {
	downloader := NewAmazonDownloader()

	// Check for existing file first
	if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
		return AmazonDownloadResult{FilePath: "EXISTS:" + existingFile}, nil
	}

	// Get Amazon URL from SongLink
	songlink := NewSongLinkClient()
	var availability *TrackAvailability
	var err error

	// Check if SpotifyID is actually a Deezer ID (format: "deezer:xxxxx")
	if strings.HasPrefix(req.SpotifyID, "deezer:") {
		// Extract Deezer ID and use Deezer-based lookup
		deezerID := strings.TrimPrefix(req.SpotifyID, "deezer:")
		GoLog("[Amazon] Using Deezer ID for SongLink lookup: %s\n", deezerID)
		availability, err = songlink.CheckAvailabilityFromDeezer(deezerID)
	} else if req.SpotifyID != "" {
		// Use Spotify ID
		availability, err = songlink.CheckTrackAvailability(req.SpotifyID, req.ISRC)
	} else {
		return AmazonDownloadResult{}, fmt.Errorf("no valid Spotify or Deezer ID provided for Amazon lookup")
	}

	if err != nil {
		return AmazonDownloadResult{}, fmt.Errorf("failed to check Amazon availability via SongLink: %w", err)
	}

	if !availability.Amazon || availability.AmazonURL == "" {
		return AmazonDownloadResult{}, fmt.Errorf("track not available on Amazon Music (SongLink returned no Amazon URL)")
	}

	// Create output directory if needed
	if req.OutputDir != "." {
		if err := os.MkdirAll(req.OutputDir, 0755); err != nil {
			return AmazonDownloadResult{}, fmt.Errorf("failed to create output directory: %w", err)
		}
	}

	// Download using DoubleDouble service (same as PC)
	downloadURL, trackName, artistName, err := downloader.downloadFromDoubleDoubleService(availability.AmazonURL, req.OutputDir)
	if err != nil {
		return AmazonDownloadResult{}, fmt.Errorf("failed to get download URL: %w", err)
	}

	// Verify artist matches
	if artistName != "" && !amazonArtistsMatch(req.ArtistName, artistName) {
		GoLog("[Amazon] Artist mismatch: expected '%s', got '%s'. Rejecting.\n", req.ArtistName, artistName)
		return AmazonDownloadResult{}, fmt.Errorf("artist mismatch: expected '%s', got '%s'", req.ArtistName, artistName)
	}

	// Log match found
	GoLog("[Amazon] Match found: '%s' by '%s'\n", trackName, artistName)

	// Build filename using Spotify metadata (more accurate)
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
		return AmazonDownloadResult{FilePath: "EXISTS:" + outputPath}, nil
	}

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
	if err := downloader.DownloadFile(downloadURL, outputPath, req.ItemID); err != nil {
		return AmazonDownloadResult{}, fmt.Errorf("download failed: %w", err)
	}

	// Wait for parallel operations to complete
	<-parallelDone

	// Set progress to 100% and status to finalizing (before embedding)
	// This makes the UI show "Finalizing..." while embedding happens
	if req.ItemID != "" {
		SetItemProgress(req.ItemID, 1.0, 0, 0)
		SetItemFinalizing(req.ItemID)
	}

	// Log track info from DoubleDouble (for debugging)
	if trackName != "" && artistName != "" {
		GoLog("[Amazon] DoubleDouble returned: %s - %s\n", artistName, trackName)
	}

	// Read existing metadata from downloaded file BEFORE embedding
	// Amazon/DoubleDouble files often have correct track/disc numbers that we should preserve
	existingMeta, metaErr := ReadMetadata(outputPath)
	actualTrackNum := req.TrackNumber
	actualDiscNum := req.DiscNumber

	if metaErr == nil && existingMeta != nil {
		// Use file metadata if it has valid track/disc numbers and request doesn't have them
		if existingMeta.TrackNumber > 0 && (req.TrackNumber == 0 || req.TrackNumber == 1) {
			actualTrackNum = existingMeta.TrackNumber
			GoLog("[Amazon] Using track number from file: %d (request had: %d)\n", actualTrackNum, req.TrackNumber)
		}
		if existingMeta.DiscNumber > 0 && (req.DiscNumber == 0 || req.DiscNumber == 1) {
			actualDiscNum = existingMeta.DiscNumber
			GoLog("[Amazon] Using disc number from file: %d (request had: %d)\n", actualDiscNum, req.DiscNumber)
		}
	}

	// Embed metadata using Spotify data (more accurate than DoubleDouble)
	// But preserve track/disc numbers from file if they were better
	metadata := Metadata{
		Title:       req.TrackName,
		Artist:      req.ArtistName,
		Album:       req.AlbumName,
		AlbumArtist: req.AlbumArtist,
		Date:        req.ReleaseDate,
		TrackNumber: actualTrackNum,
		TotalTracks: req.TotalTracks,
		DiscNumber:  actualDiscNum,
		ISRC:        req.ISRC,
	}

	// Use cover data from parallel fetch
	var coverData []byte
	if parallelResult != nil && parallelResult.CoverData != nil {
		coverData = parallelResult.CoverData
		GoLog("[Amazon] Using parallel-fetched cover (%d bytes)\n", len(coverData))
	}

	if err := EmbedMetadataWithCoverData(outputPath, metadata, coverData); err != nil {
		fmt.Printf("Warning: failed to embed metadata: %v\n", err)
	}

	// Embed lyrics from parallel fetch
	if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
		GoLog("[Amazon] Embedding parallel-fetched lyrics (%d lines)...\n", len(parallelResult.LyricsData.Lines))
		if embedErr := EmbedLyrics(outputPath, parallelResult.LyricsLRC); embedErr != nil {
			GoLog("[Amazon] Warning: failed to embed lyrics: %v\n", embedErr)
		} else {
			fmt.Println("[Amazon] Lyrics embedded successfully")
		}
	} else if req.EmbedLyrics {
		fmt.Println("[Amazon] No lyrics available from parallel fetch")
	}

	fmt.Println("[Amazon] ✓ Downloaded successfully from Amazon Music")

	// Read actual quality from the downloaded FLAC file
	// Amazon API doesn't provide quality info, but we can read it from the file itself
	quality, err := GetAudioQuality(outputPath)
	if err != nil {
		GoLog("[Amazon] Warning: couldn't read quality from file: %v\n", err)
	} else {
		GoLog("[Amazon] Actual quality: %d-bit/%dHz\n", quality.BitDepth, quality.SampleRate)
	}

	// Read metadata from file AFTER embedding to get accurate values
	// This ensures we return what's actually in the file
	finalMeta, metaReadErr := ReadMetadata(outputPath)
	if metaReadErr == nil && finalMeta != nil {
		GoLog("[Amazon] Final metadata from file - Track: %d, Disc: %d, Date: %s\n",
			finalMeta.TrackNumber, finalMeta.DiscNumber, finalMeta.Date)
		actualTrackNum = finalMeta.TrackNumber
		actualDiscNum = finalMeta.DiscNumber
		if finalMeta.Date != "" {
			// Use date from file if available
			req.ReleaseDate = finalMeta.Date
		}
	}

	// Add to ISRC index for fast duplicate checking
	AddToISRCIndex(req.OutputDir, req.ISRC, outputPath)

	bitDepth := 0
	sampleRate := 0
	if err == nil {
		bitDepth = quality.BitDepth
		sampleRate = quality.SampleRate
	}

	return AmazonDownloadResult{
		FilePath:    outputPath,
		BitDepth:    bitDepth,
		SampleRate:  sampleRate,
		Title:       req.TrackName,
		Artist:      req.ArtistName,
		Album:       req.AlbumName,
		ReleaseDate: req.ReleaseDate,
		TrackNumber: actualTrackNum,
		DiscNumber:  actualDiscNum,
		ISRC:        req.ISRC,
	}, nil
}
