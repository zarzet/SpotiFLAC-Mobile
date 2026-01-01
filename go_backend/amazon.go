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
	"strings"
	"time"
)

// AmazonDownloader handles Amazon Music downloads using DoubleDouble service (same as PC)
type AmazonDownloader struct {
	client  *http.Client
	regions []string // us, eu regions for DoubleDouble service
}

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

// NewAmazonDownloader creates a new Amazon downloader using DoubleDouble service
func NewAmazonDownloader() *AmazonDownloader {
	return &AmazonDownloader{
		client:  NewHTTPClientWithTimeout(120 * time.Second), // 120s timeout like PC
		regions: []string{"us", "eu"},                        // Same regions as PC
	}
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
func (a *AmazonDownloader) downloadFromDoubleDoubleService(amazonURL, outputDir string) (string, string, string, error) {
	var lastError error

	for _, region := range a.regions {
		fmt.Printf("[Amazon] Trying region: %s...\n", region)

		// Build base URL for DoubleDouble service
		// Decode base64 service URL (same as PC)
		serviceBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly8=")         // https://
		serviceDomain, _ := base64.StdEncoding.DecodeString("LmRvdWJsZWRvdWJsZS50b3A=") // .doubledouble.top
		baseURL := fmt.Sprintf("%s%s%s", string(serviceBase), region, string(serviceDomain))

		// Step 1: Submit download request
		encodedURL := url.QueryEscape(amazonURL)
		submitURL := fmt.Sprintf("%s/dl?url=%s", baseURL, encodedURL)

		req, err := http.NewRequest("GET", submitURL, nil)
		if err != nil {
			lastError = fmt.Errorf("failed to create request: %w", err)
			continue
		}

		req.Header.Set("User-Agent", getRandomUserAgent())

		fmt.Println("[Amazon] Submitting download request...")
		resp, err := a.client.Do(req)
		if err != nil {
			lastError = fmt.Errorf("failed to submit request: %w", err)
			continue
		}

		if resp.StatusCode != 200 {
			resp.Body.Close()
			lastError = fmt.Errorf("submit failed with status %d", resp.StatusCode)
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
		fmt.Printf("[Amazon] Download ID: %s\n", downloadID)

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

				fmt.Printf("[Amazon] Downloading: %s - %s\n", artist, trackName)
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

	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := a.client.Do(req)
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
	var bytesWritten int64
	if itemID != "" {
		pw := NewItemProgressWriter(out, itemID)
		bytesWritten, err = io.Copy(pw, resp.Body)
	} else {
		pw := NewProgressWriter(out)
		bytesWritten, err = io.Copy(pw, resp.Body)
	}
	if err != nil {
		return fmt.Errorf("failed to write file: %w", err)
	}

	fmt.Printf("\r[Amazon] Downloaded: %.2f MB (Complete)\n", float64(bytesWritten)/(1024*1024))
	return nil
}

// downloadFromAmazon downloads a track using the request parameters
// Uses DoubleDouble service (same as PC version)
func downloadFromAmazon(req DownloadRequest) (string, error) {
	downloader := NewAmazonDownloader()

	// Check for existing file first
	if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
		return "EXISTS:" + existingFile, nil
	}

	// Get Amazon URL from SongLink
	songlink := NewSongLinkClient()
	availability, err := songlink.CheckTrackAvailability(req.SpotifyID, req.ISRC)
	if err != nil {
		return "", fmt.Errorf("failed to check Amazon availability via SongLink: %w", err)
	}

	if !availability.Amazon || availability.AmazonURL == "" {
		return "", fmt.Errorf("track not available on Amazon Music (SongLink returned no Amazon URL)")
	}

	// Create output directory if needed
	if req.OutputDir != "." {
		if err := os.MkdirAll(req.OutputDir, 0755); err != nil {
			return "", fmt.Errorf("failed to create output directory: %w", err)
		}
	}

	// Download using DoubleDouble service (same as PC)
	downloadURL, trackName, artistName, err := downloader.downloadFromDoubleDoubleService(availability.AmazonURL, req.OutputDir)
	if err != nil {
		return "", fmt.Errorf("failed to get download URL: %w", err)
	}

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
		return "EXISTS:" + outputPath, nil
	}

	// Download file with item ID for progress tracking
	if err := downloader.DownloadFile(downloadURL, outputPath, req.ItemID); err != nil {
		return "", fmt.Errorf("download failed: %w", err)
	}

	// Log track info from DoubleDouble (for debugging)
	if trackName != "" && artistName != "" {
		fmt.Printf("[Amazon] DoubleDouble returned: %s - %s\n", artistName, trackName)
	}

	// Embed metadata using Spotify data (more accurate than DoubleDouble)
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
		fmt.Println("[Amazon] Downloading cover to memory...")
		data, err := downloadCoverToMemory(req.CoverURL, req.EmbedMaxQualityCover)
		if err == nil {
			coverData = data
			fmt.Printf("[Amazon] Cover downloaded successfully (%d bytes)\n", len(coverData))
		} else {
			fmt.Printf("[Amazon] Warning: failed to download cover: %v\n", err)
		}
	}

	if err := EmbedMetadataWithCoverData(outputPath, metadata, coverData); err != nil {
		fmt.Printf("Warning: failed to embed metadata: %v\n", err)
	}

	// Embed lyrics if enabled
	if req.EmbedLyrics {
		fmt.Println("[Amazon] Fetching lyrics...")
		lyricsClient := NewLyricsClient()
		lyrics, lyricsErr := lyricsClient.FetchLyricsAllSources(req.SpotifyID, req.TrackName, req.ArtistName)
		if lyricsErr != nil {
			fmt.Printf("[Amazon] Warning: lyrics fetch error: %v\n", lyricsErr)
		} else if lyrics == nil || len(lyrics.Lines) == 0 {
			fmt.Println("[Amazon] No lyrics found for this track")
		} else {
			fmt.Printf("[Amazon] Lyrics found (%d lines), embedding...\n", len(lyrics.Lines))
			
			// Convert Japanese lyrics to romaji if enabled
			if req.ConvertLyricsToRomaji {
				for i := range lyrics.Lines {
					if ContainsKana(lyrics.Lines[i].Words) {
						lyrics.Lines[i].Words = ToRomaji(lyrics.Lines[i].Words)
					}
				}
				fmt.Println("[Amazon] Converted Japanese lyrics to romaji")
			}
			
			lrcContent := convertToLRC(lyrics)
			if embedErr := EmbedLyrics(outputPath, lrcContent); embedErr != nil {
				fmt.Printf("[Amazon] Warning: failed to embed lyrics: %v\n", embedErr)
			} else {
				fmt.Println("[Amazon] Lyrics embedded successfully")
			}
		}
	}

	fmt.Println("[Amazon] ✓ Downloaded successfully from Amazon Music")
	return outputPath, nil
}
