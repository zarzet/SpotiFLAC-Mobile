package gobackend

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
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

type AmazonDownloader struct {
	client *http.Client
}

var (
	globalAmazonDownloader *AmazonDownloader
	amazonDownloaderOnce   sync.Once
)

// AfkarXYZResponse is the response from AfkarXYZ API
type AfkarXYZResponse struct {
	Success bool `json:"success"`
	Data    struct {
		DirectLink string `json:"direct_link"`
		FileName   string `json:"file_name"`
		FileSize   int64  `json:"file_size"`
	} `json:"data"`
}

func amazonArtistsMatch(expectedArtist, foundArtist string) bool {
	normExpected := strings.ToLower(strings.TrimSpace(expectedArtist))
	normFound := strings.ToLower(strings.TrimSpace(foundArtist))

	if normExpected == normFound {
		return true
	}

	if strings.Contains(normExpected, normFound) || strings.Contains(normFound, normExpected) {
		return true
	}

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

	if strings.Contains(expectedFirst, foundFirst) || strings.Contains(foundFirst, expectedFirst) {
		return true
	}

	expectedASCII := amazonIsASCIIString(expectedArtist)
	foundASCII := amazonIsASCIIString(foundArtist)
	if expectedASCII != foundASCII {
		GoLog("[Amazon] Artist names in different scripts, assuming match: '%s' vs '%s'\n", expectedArtist, foundArtist)
		return true
	}

	return false
}

func amazonIsASCIIString(s string) bool {
	for _, r := range s {
		if r > 127 {
			return false
		}
	}
	return true
}

func NewAmazonDownloader() *AmazonDownloader {
	amazonDownloaderOnce.Do(func() {
		globalAmazonDownloader = &AmazonDownloader{
			client: NewHTTPClientWithTimeout(120 * time.Second),
		}
	})
	return globalAmazonDownloader
}

// downloadFromAfkarXYZ downloads a track using AfkarXYZ API
// Returns: downloadURL, fileName, error
func (a *AmazonDownloader) downloadFromAfkarXYZ(amazonURL string) (string, string, error) {
	// AfkarXYZ API endpoint
	apiURL := "https://amazon.afkarxyz.fun/convert?url=" + url.QueryEscape(amazonURL)

	GoLog("[Amazon] Fetching from AfkarXYZ API...\n")

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return "", "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := a.client.Do(req)
	if err != nil {
		return "", "", fmt.Errorf("failed to call AfkarXYZ API: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", "", fmt.Errorf("AfkarXYZ API returned status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", "", fmt.Errorf("failed to read response: %w", err)
	}

	var apiResp AfkarXYZResponse
	if err := json.Unmarshal(body, &apiResp); err != nil {
		return "", "", fmt.Errorf("failed to decode response: %w", err)
	}

	if !apiResp.Success || apiResp.Data.DirectLink == "" {
		return "", "", fmt.Errorf("AfkarXYZ API failed or no download link found")
	}

	fileName := apiResp.Data.FileName
	if fileName == "" {
		fileName = "track.flac"
	}

	// Sanitize filename
	reg := regexp.MustCompile(`[<>:"/\\|?*]`)
	fileName = reg.ReplaceAllString(fileName, "")

	GoLog("[Amazon] AfkarXYZ returned: %s (%.2f MB)\n", fileName, float64(apiResp.Data.FileSize)/(1024*1024))

	return apiResp.Data.DirectLink, fileName, nil
}

func (a *AmazonDownloader) DownloadFile(downloadURL, outputPath, itemID string) error {
	ctx := context.Background()

	// Initialize item progress (required for all downloads)
	if itemID != "" {
		StartItemProgress(itemID)
		defer CompleteItemProgress(itemID)
		ctx = initDownloadCancel(itemID)
		defer clearDownloadCancel(itemID)
	}

	if isDownloadCancelled(itemID) {
		return ErrDownloadCancelled
	}

	req, err := http.NewRequestWithContext(ctx, "GET", downloadURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := a.client.Do(req)
	if err != nil {
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("download failed: HTTP %d", resp.StatusCode)
	}

	expectedSize := resp.ContentLength
	if expectedSize > 0 && itemID != "" {
		SetItemBytesTotal(itemID, expectedSize)
	}

	out, err := os.Create(outputPath)
	if err != nil {
		return err
	}

	bufWriter := bufio.NewWriterSize(out, 256*1024)

	var written int64
	if itemID != "" {
		pw := NewItemProgressWriter(bufWriter, itemID)
		written, err = io.Copy(pw, resp.Body)
	} else {
		written, err = io.Copy(bufWriter, resp.Body)
	}

	// Flush buffer before checking for errors
	flushErr := bufWriter.Flush()
	closeErr := out.Close()

	if err != nil {
		os.Remove(outputPath)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
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

	GoLog("[Amazon] Downloaded: %.2f MB (Complete)\n", float64(written)/(1024*1024))
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

// downloadFromAmazon uses AfkarXYZ API to download from Amazon Music
func downloadFromAmazon(req DownloadRequest) (AmazonDownloadResult, error) {
	downloader := NewAmazonDownloader()

	if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
		return AmazonDownloadResult{FilePath: "EXISTS:" + existingFile}, nil
	}

	songlink := NewSongLinkClient()
	var availability *TrackAvailability
	var err error

	if deezerID, found := strings.CutPrefix(req.SpotifyID, "deezer:"); found {
		GoLog("[Amazon] Using Deezer ID for SongLink lookup: %s\n", deezerID)
		availability, err = songlink.CheckAvailabilityFromDeezer(deezerID)
	} else if req.SpotifyID != "" {
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

	if req.OutputDir != "." {
		if err := os.MkdirAll(req.OutputDir, 0755); err != nil {
			return AmazonDownloadResult{}, fmt.Errorf("failed to create output directory: %w", err)
		}
	}

	// Download using AfkarXYZ API
	downloadURL, _, err := downloader.downloadFromAfkarXYZ(availability.AmazonURL)
	if err != nil {
		return AmazonDownloadResult{}, fmt.Errorf("failed to get download URL from AfkarXYZ: %w", err)
	}

	GoLog("[Amazon] Match found: '%s' by '%s'\n", req.TrackName, req.ArtistName)

	filename := buildFilenameFromTemplate(req.FilenameFormat, map[string]any{
		"title":  req.TrackName,
		"artist": req.ArtistName,
		"album":  req.AlbumName,
		"track":  req.TrackNumber,
		"year":   extractYear(req.ReleaseDate),
		"disc":   req.DiscNumber,
	})
	filename = sanitizeFilename(filename) + ".flac"
	outputPath := filepath.Join(req.OutputDir, filename)

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
			int64(req.DurationMS),
		)
	}()

	// Download audio file with item ID for progress tracking
	if err := downloader.DownloadFile(downloadURL, outputPath, req.ItemID); err != nil {
		if errors.Is(err, ErrDownloadCancelled) {
			return AmazonDownloadResult{}, ErrDownloadCancelled
		}
		return AmazonDownloadResult{}, fmt.Errorf("download failed: %w", err)
	}

	// Wait for parallel operations to complete
	<-parallelDone

	if req.ItemID != "" {
		SetItemProgress(req.ItemID, 1.0, 0, 0)
		SetItemFinalizing(req.ItemID)
	}

	existingMeta, metaErr := ReadMetadata(outputPath)
	actualTrackNum := req.TrackNumber
	actualDiscNum := req.DiscNumber

	if metaErr == nil && existingMeta != nil {
		if existingMeta.TrackNumber > 0 && (req.TrackNumber == 0 || req.TrackNumber == 1) {
			actualTrackNum = existingMeta.TrackNumber
			GoLog("[Amazon] Using track number from file: %d (request had: %d)\n", actualTrackNum, req.TrackNumber)
		}
		if existingMeta.DiscNumber > 0 && (req.DiscNumber == 0 || req.DiscNumber == 1) {
			actualDiscNum = existingMeta.DiscNumber
			GoLog("[Amazon] Using disc number from file: %d (request had: %d)\n", actualDiscNum, req.DiscNumber)
		}
	}

	// Embed metadata using Spotify data
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
		Genre:       req.Genre,
		Label:       req.Label,
		Copyright:   req.Copyright,
	}

	// Use cover data from parallel fetch
	var coverData []byte
	if parallelResult != nil && parallelResult.CoverData != nil {
		coverData = parallelResult.CoverData
		GoLog("[Amazon] Using parallel-fetched cover (%d bytes)\n", len(coverData))
	}

	if err := EmbedMetadataWithCoverData(outputPath, metadata, coverData); err != nil {
		GoLog("[Amazon] Warning: failed to embed metadata: %v\n", err)
	}

	if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
		lyricsMode := req.LyricsMode
		if lyricsMode == "" {
			lyricsMode = "embed" // default
		}

		if lyricsMode == "external" || lyricsMode == "both" {
			GoLog("[Amazon] Saving external LRC file...\n")
			if lrcPath, lrcErr := SaveLRCFile(outputPath, parallelResult.LyricsLRC); lrcErr != nil {
				GoLog("[Amazon] Warning: failed to save LRC file: %v\n", lrcErr)
			} else {
				GoLog("[Amazon] LRC file saved: %s\n", lrcPath)
			}
		}

		if lyricsMode == "embed" || lyricsMode == "both" {
			GoLog("[Amazon] Embedding parallel-fetched lyrics (%d lines)...\n", len(parallelResult.LyricsData.Lines))
			if embedErr := EmbedLyrics(outputPath, parallelResult.LyricsLRC); embedErr != nil {
				GoLog("[Amazon] Warning: failed to embed lyrics: %v\n", embedErr)
			} else {
				GoLog("[Amazon] Lyrics embedded successfully\n")
			}
		}
	} else if req.EmbedLyrics {
		GoLog("[Amazon] No lyrics available from parallel fetch\n")
	}

	GoLog("[Amazon] ✓ Downloaded successfully from Amazon Music\n")

	quality, err := GetAudioQuality(outputPath)
	if err != nil {
		GoLog("[Amazon] Warning: couldn't read quality from file: %v\n", err)
	} else {
		GoLog("[Amazon] Actual quality: %d-bit/%dHz\n", quality.BitDepth, quality.SampleRate)
	}

	finalMeta, metaReadErr := ReadMetadata(outputPath)
	if metaReadErr == nil && finalMeta != nil {
		GoLog("[Amazon] Final metadata from file - Track: %d, Disc: %d, Date: %s\n",
			finalMeta.TrackNumber, finalMeta.DiscNumber, finalMeta.Date)
		actualTrackNum = finalMeta.TrackNumber
		actualDiscNum = finalMeta.DiscNumber
		if finalMeta.Date != "" {
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
