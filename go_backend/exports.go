// Package gobackend provides exported functions for gomobile binding
// These functions are the bridge between Flutter and Go backend
package gobackend

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// ParseSpotifyURL parses and validates a Spotify URL
// Returns JSON with type (track/album/playlist) and ID
func ParseSpotifyURL(url string) (string, error) {
	parsed, err := parseSpotifyURI(url)
	if err != nil {
		return "", err
	}

	result := map[string]string{
		"type": parsed.Type,
		"id":   parsed.ID,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// SetSpotifyAPICredentials sets custom Spotify API credentials from Flutter
func SetSpotifyAPICredentials(clientID, clientSecret string) {
	SetSpotifyCredentials(clientID, clientSecret)
}

// CheckSpotifyCredentials checks if Spotify credentials are configured
// Returns true if credentials are available (custom or env vars)
func CheckSpotifyCredentials() bool {
	return HasSpotifyCredentials()
}

// GetSpotifyMetadata fetches metadata from Spotify URL
// Returns JSON with track/album/playlist data
func GetSpotifyMetadata(spotifyURL string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client, err := NewSpotifyMetadataClient()
	if err != nil {
		return "", err
	}
	data, err := client.GetFilteredData(ctx, spotifyURL, false, 0)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(data)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// SearchSpotify searches for tracks on Spotify
// Returns JSON array of track results
func SearchSpotify(query string, limit int) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client, err := NewSpotifyMetadataClient()
	if err != nil {
		return "", err
	}
	results, err := client.SearchTracks(ctx, query, limit)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(results)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// SearchSpotifyAll searches for tracks and artists on Spotify
// Returns JSON with tracks and artists arrays
func SearchSpotifyAll(query string, trackLimit, artistLimit int) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client, err := NewSpotifyMetadataClient()
	if err != nil {
		return "", err
	}
	results, err := client.SearchAll(ctx, query, trackLimit, artistLimit)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(results)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// CheckAvailability checks track availability on streaming services
// Returns JSON with availability info for Tidal, Qobuz, Amazon
func CheckAvailability(spotifyID, isrc string) (string, error) {
	client := NewSongLinkClient()
	availability, err := client.CheckTrackAvailability(spotifyID, isrc)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(availability)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// DownloadRequest represents a download request from Flutter
type DownloadRequest struct {
	ISRC                 string `json:"isrc"`
	Service              string `json:"service"`
	SpotifyID            string `json:"spotify_id"`
	TrackName            string `json:"track_name"`
	ArtistName           string `json:"artist_name"`
	AlbumName            string `json:"album_name"`
	AlbumArtist          string `json:"album_artist"`
	CoverURL             string `json:"cover_url"`
	OutputDir            string `json:"output_dir"`
	FilenameFormat       string `json:"filename_format"`
	Quality              string `json:"quality"` // LOSSLESS, HI_RES, HI_RES_LOSSLESS
	EmbedLyrics          bool   `json:"embed_lyrics"`
	EmbedMaxQualityCover bool   `json:"embed_max_quality_cover"`
	TrackNumber          int    `json:"track_number"`
	DiscNumber           int    `json:"disc_number"`
	TotalTracks          int    `json:"total_tracks"`
	ReleaseDate          string `json:"release_date"`
	ItemID               string `json:"item_id"`     // Unique ID for progress tracking
	DurationMS           int    `json:"duration_ms"` // Expected duration in milliseconds (for verification)
	Source               string `json:"source"`      // Extension ID that provided this track (prioritize this extension)
}

// DownloadResponse represents the result of a download
type DownloadResponse struct {
	Success       bool   `json:"success"`
	Message       string `json:"message"`
	FilePath      string `json:"file_path,omitempty"`
	Error         string `json:"error,omitempty"`
	ErrorType     string `json:"error_type,omitempty"` // "not_found", "rate_limit", "network", "unknown"
	AlreadyExists bool   `json:"already_exists,omitempty"`
	// Actual quality info from the source
	ActualBitDepth   int    `json:"actual_bit_depth,omitempty"`
	ActualSampleRate int    `json:"actual_sample_rate,omitempty"`
	Service          string `json:"service,omitempty"` // Actual service used (for fallback)
	Title            string `json:"title,omitempty"`
	Artist           string `json:"artist,omitempty"`
	Album            string `json:"album,omitempty"`
	AlbumArtist      string `json:"album_artist,omitempty"`
	ReleaseDate      string `json:"release_date,omitempty"`
	TrackNumber      int    `json:"track_number,omitempty"`
	DiscNumber       int    `json:"disc_number,omitempty"`
	ISRC             string `json:"isrc,omitempty"`
	CoverURL         string `json:"cover_url,omitempty"`
	// If true, skip metadata enrichment from Deezer/Spotify (extension already provides metadata)
	SkipMetadataEnrichment bool `json:"skip_metadata_enrichment,omitempty"`
}

// DownloadResult is a generic result type for all downloaders
// DownloadResult is a generic result type for all downloaders
type DownloadResult struct {
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

// DownloadTrack downloads a track from the specified service
// requestJSON is a JSON string of DownloadRequest
// Returns JSON string of DownloadResponse
func DownloadTrack(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return errorResponse("Invalid request: " + err.Error())
	}

	// Trim whitespace from string fields to prevent filename/path issues
	req.TrackName = strings.TrimSpace(req.TrackName)
	req.ArtistName = strings.TrimSpace(req.ArtistName)
	req.AlbumName = strings.TrimSpace(req.AlbumName)
	req.AlbumArtist = strings.TrimSpace(req.AlbumArtist)
	req.OutputDir = strings.TrimSpace(req.OutputDir)

	var result DownloadResult
	var err error

	switch req.Service {
	case "tidal":
		tidalResult, tidalErr := downloadFromTidal(req)
		if tidalErr == nil {
			result = DownloadResult{
				FilePath:    tidalResult.FilePath,
				BitDepth:    tidalResult.BitDepth,
				SampleRate:  tidalResult.SampleRate,
				Title:       tidalResult.Title,
				Artist:      tidalResult.Artist,
				Album:       tidalResult.Album,
				ReleaseDate: tidalResult.ReleaseDate,
				TrackNumber: tidalResult.TrackNumber,
				DiscNumber:  tidalResult.DiscNumber,
				ISRC:        tidalResult.ISRC,
			}
		}
		err = tidalErr
	case "qobuz":
		qobuzResult, qobuzErr := downloadFromQobuz(req)
		if qobuzErr == nil {
			result = DownloadResult{
				FilePath:    qobuzResult.FilePath,
				BitDepth:    qobuzResult.BitDepth,
				SampleRate:  qobuzResult.SampleRate,
				Title:       qobuzResult.Title,
				Artist:      qobuzResult.Artist,
				Album:       qobuzResult.Album,
				ReleaseDate: qobuzResult.ReleaseDate,
				TrackNumber: qobuzResult.TrackNumber,
				DiscNumber:  qobuzResult.DiscNumber,
				ISRC:        qobuzResult.ISRC,
			}
		}
		err = qobuzErr
	case "amazon":
		amazonResult, amazonErr := downloadFromAmazon(req)
		if amazonErr == nil {
			result = DownloadResult{
				FilePath:    amazonResult.FilePath,
				BitDepth:    amazonResult.BitDepth,
				SampleRate:  amazonResult.SampleRate,
				Title:       amazonResult.Title,
				Artist:      amazonResult.Artist,
				Album:       amazonResult.Album,
				ReleaseDate: amazonResult.ReleaseDate,
				TrackNumber: amazonResult.TrackNumber,
				DiscNumber:  amazonResult.DiscNumber,
				ISRC:        amazonResult.ISRC,
			}
		}
		err = amazonErr
	default:
		return errorResponse("Unknown service: " + req.Service)
	}

	if err != nil {
		return errorResponse(err.Error())
	}

	// Check if file already exists
	if len(result.FilePath) > 7 && result.FilePath[:7] == "EXISTS:" {
		actualPath := result.FilePath[7:]
		// Read actual quality from existing file
		quality, qErr := GetAudioQuality(actualPath)
		if qErr == nil {
			result.BitDepth = quality.BitDepth
			result.SampleRate = quality.SampleRate
		}
		resp := DownloadResponse{
			Success:          true,
			Message:          "File already exists",
			FilePath:         actualPath,
			AlreadyExists:    true,
			ActualBitDepth:   result.BitDepth,
			ActualSampleRate: result.SampleRate,
			Service:          req.Service,
			Title:            result.Title,
			Artist:           result.Artist,
			Album:            result.Album,
			ReleaseDate:      result.ReleaseDate,
			TrackNumber:      result.TrackNumber,
			DiscNumber:       result.DiscNumber,
			ISRC:             result.ISRC,
		}
		jsonBytes, _ := json.Marshal(resp)
		return string(jsonBytes), nil
	}

	// Read actual quality from downloaded file (more accurate than API)
	quality, qErr := GetAudioQuality(result.FilePath)
	if qErr == nil {
		result.BitDepth = quality.BitDepth
		result.SampleRate = quality.SampleRate
		GoLog("[Download] Actual quality from file: %d-bit/%dHz\n", quality.BitDepth, quality.SampleRate)
	} else {
		GoLog("[Download] Could not read quality from file: %v\n", qErr)
	}

	resp := DownloadResponse{
		Success:          true,
		Message:          "Download complete",
		FilePath:         result.FilePath,
		ActualBitDepth:   result.BitDepth,
		ActualSampleRate: result.SampleRate,
		Service:          req.Service,
		Title:            result.Title,
		Artist:           result.Artist,
		Album:            result.Album,
		ReleaseDate:      result.ReleaseDate,
		TrackNumber:      result.TrackNumber,
		DiscNumber:       result.DiscNumber,
		ISRC:             result.ISRC,
	}

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

// DownloadWithFallback tries to download from services in order
// Starts with the preferred service from request, then tries others
func DownloadWithFallback(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return errorResponse("Invalid request: " + err.Error())
	}

	// Trim whitespace from string fields to prevent filename/path issues
	req.TrackName = strings.TrimSpace(req.TrackName)
	req.ArtistName = strings.TrimSpace(req.ArtistName)
	req.AlbumName = strings.TrimSpace(req.AlbumName)
	req.AlbumArtist = strings.TrimSpace(req.AlbumArtist)
	req.OutputDir = strings.TrimSpace(req.OutputDir)

	// Build service order starting with preferred service
	allServices := []string{"tidal", "qobuz", "amazon"}
	preferredService := req.Service
	if preferredService == "" {
		preferredService = "tidal"
	}

	GoLog("[DownloadWithFallback] Preferred service from request: '%s'\n", req.Service)

	// Create ordered list: preferred first, then others
	services := []string{preferredService}
	for _, s := range allServices {
		if s != preferredService {
			services = append(services, s)
		}
	}

	GoLog("[DownloadWithFallback] Service order: %v\n", services)

	var lastErr error

	for _, service := range services {
		GoLog("[DownloadWithFallback] Trying service: %s\n", service)
		req.Service = service

		var result DownloadResult
		var err error

		switch service {
		case "tidal":
			tidalResult, tidalErr := downloadFromTidal(req)
			if tidalErr == nil {
				result = DownloadResult{
					FilePath:    tidalResult.FilePath,
					BitDepth:    tidalResult.BitDepth,
					SampleRate:  tidalResult.SampleRate,
					Title:       tidalResult.Title,
					Artist:      tidalResult.Artist,
					Album:       tidalResult.Album,
					ReleaseDate: tidalResult.ReleaseDate,
					TrackNumber: tidalResult.TrackNumber,
					DiscNumber:  tidalResult.DiscNumber,
					ISRC:        tidalResult.ISRC,
				}
			} else {
				GoLog("[DownloadWithFallback] Tidal error: %v\n", tidalErr)
			}
			err = tidalErr
		case "qobuz":
			qobuzResult, qobuzErr := downloadFromQobuz(req)
			if qobuzErr == nil {
				result = DownloadResult{
					FilePath:    qobuzResult.FilePath,
					BitDepth:    qobuzResult.BitDepth,
					SampleRate:  qobuzResult.SampleRate,
					Title:       qobuzResult.Title,
					Artist:      qobuzResult.Artist,
					Album:       qobuzResult.Album,
					ReleaseDate: qobuzResult.ReleaseDate,
					TrackNumber: qobuzResult.TrackNumber,
					DiscNumber:  qobuzResult.DiscNumber,
					ISRC:        qobuzResult.ISRC,
				}
			} else {
				GoLog("[DownloadWithFallback] Qobuz error: %v\n", qobuzErr)
			}
			err = qobuzErr
		case "amazon":
			amazonResult, amazonErr := downloadFromAmazon(req)
			if amazonErr == nil {
				result = DownloadResult{
					FilePath:    amazonResult.FilePath,
					BitDepth:    amazonResult.BitDepth,
					SampleRate:  amazonResult.SampleRate,
					Title:       amazonResult.Title,
					Artist:      amazonResult.Artist,
					Album:       amazonResult.Album,
					ReleaseDate: amazonResult.ReleaseDate,
					TrackNumber: amazonResult.TrackNumber,
					DiscNumber:  amazonResult.DiscNumber,
					ISRC:        amazonResult.ISRC,
				}
			} else {
				GoLog("[DownloadWithFallback] Amazon error: %v\n", amazonErr)
			}
			err = amazonErr
		}

		if err == nil {
			// Check if file already exists
			if len(result.FilePath) > 7 && result.FilePath[:7] == "EXISTS:" {
				actualPath := result.FilePath[7:]
				// Read actual quality from existing file
				quality, qErr := GetAudioQuality(actualPath)
				if qErr == nil {
					result.BitDepth = quality.BitDepth
					result.SampleRate = quality.SampleRate
				}
				resp := DownloadResponse{
					Success:          true,
					Message:          "File already exists",
					FilePath:         actualPath,
					AlreadyExists:    true,
					ActualBitDepth:   result.BitDepth,
					ActualSampleRate: result.SampleRate,
					Service:          service,
					Title:            result.Title,
					Artist:           result.Artist,
					Album:            result.Album,
					ReleaseDate:      result.ReleaseDate,
					TrackNumber:      result.TrackNumber,
					DiscNumber:       result.DiscNumber,
					ISRC:             result.ISRC,
				}
				jsonBytes, _ := json.Marshal(resp)
				return string(jsonBytes), nil
			}

			// Read actual quality from downloaded file (more accurate than API)
			quality, qErr := GetAudioQuality(result.FilePath)
			if qErr == nil {
				result.BitDepth = quality.BitDepth
				result.SampleRate = quality.SampleRate
				GoLog("[Download] Actual quality from file: %d-bit/%dHz\n", quality.BitDepth, quality.SampleRate)
			} else {
				GoLog("[Download] Could not read quality from file: %v\n", qErr)
			}

			resp := DownloadResponse{
				Success:          true,
				Message:          "Downloaded from " + service,
				FilePath:         result.FilePath,
				ActualBitDepth:   result.BitDepth,
				ActualSampleRate: result.SampleRate,
				Service:          service,
				Title:            result.Title,
				Artist:           result.Artist,
				Album:            result.Album,
				ReleaseDate:      result.ReleaseDate,
				TrackNumber:      result.TrackNumber,
				DiscNumber:       result.DiscNumber,
				ISRC:             result.ISRC,
			}
			jsonBytes, _ := json.Marshal(resp)
			return string(jsonBytes), nil
		}

		lastErr = err
	}

	return errorResponse("All services failed. Last error: " + lastErr.Error())
}

// GetDownloadProgress returns current download progress
func GetDownloadProgress() string {
	progress := getProgress()
	jsonBytes, _ := json.Marshal(progress)
	return string(jsonBytes)
}

// GetAllDownloadProgress returns progress for all active downloads (concurrent mode)
func GetAllDownloadProgress() string {
	return GetMultiProgress()
}

// InitItemProgress initializes progress tracking for a download item
func InitItemProgress(itemID string) {
	StartItemProgress(itemID)
}

// FinishItemProgress marks a download item as complete and removes tracking
func FinishItemProgress(itemID string) {
	CompleteItemProgress(itemID)
	// Don't remove immediately - let Flutter poll one more time to see 100%
}

// ClearItemProgress removes progress tracking for a specific item
func ClearItemProgress(itemID string) {
	RemoveItemProgress(itemID)
}

// CleanupConnections closes idle HTTP connections
// Call this periodically during large batch downloads to prevent TCP exhaustion
func CleanupConnections() {
	CloseIdleConnections()
}

// ReadFileMetadata reads metadata directly from a FLAC file
// Returns JSON with all embedded metadata (title, artist, album, track number, etc.)
// This is useful for displaying accurate metadata in the UI without relying on cached data
func ReadFileMetadata(filePath string) (string, error) {
	metadata, err := ReadMetadata(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to read metadata: %w", err)
	}

	// Also get audio quality info
	quality, qualityErr := GetAudioQuality(filePath)

	// Get duration from FLAC stream info
	duration := 0
	if qualityErr == nil && quality.SampleRate > 0 && quality.TotalSamples > 0 {
		duration = int(quality.TotalSamples / int64(quality.SampleRate))
	}

	result := map[string]interface{}{
		"title":        metadata.Title,
		"artist":       metadata.Artist,
		"album":        metadata.Album,
		"album_artist": metadata.AlbumArtist,
		"date":         metadata.Date,
		"track_number": metadata.TrackNumber,
		"disc_number":  metadata.DiscNumber,
		"isrc":         metadata.ISRC,
		"lyrics":       metadata.Lyrics,
		"duration":     duration,
	}

	// Add quality info if available
	if qualityErr == nil {
		result["bit_depth"] = quality.BitDepth
		result["sample_rate"] = quality.SampleRate
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// SetDownloadDirectory sets the default download directory
func SetDownloadDirectory(path string) error {
	return setDownloadDir(path)
}

// CheckDuplicate checks if a file with the given ISRC exists
func CheckDuplicate(outputDir, isrc string) (string, error) {
	existingFile, exists := CheckISRCExists(outputDir, isrc)

	result := map[string]interface{}{
		"exists":   exists,
		"filepath": existingFile,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// CheckDuplicatesBatch checks multiple files for duplicates in parallel
// Uses ISRC index for fast lookup (builds index once, checks all tracks)
// tracksJSON format: [{"isrc": "...", "track_name": "...", "artist_name": "..."}, ...]
// Returns JSON array of results
func CheckDuplicatesBatch(outputDir, tracksJSON string) (string, error) {
	return CheckFilesExistParallel(outputDir, tracksJSON)
}

// PreBuildDuplicateIndex pre-builds the ISRC index for a directory
// Call this when entering album/playlist screen for faster duplicate checking
func PreBuildDuplicateIndex(outputDir string) error {
	return PreBuildISRCIndex(outputDir)
}

// InvalidateDuplicateIndex clears the ISRC index cache for a directory
// Call this when files are deleted or moved
func InvalidateDuplicateIndex(outputDir string) {
	InvalidateISRCCache(outputDir)
}

// BuildFilename builds a filename from template and metadata
func BuildFilename(template string, metadataJSON string) (string, error) {
	var metadata map[string]interface{}
	if err := json.Unmarshal([]byte(metadataJSON), &metadata); err != nil {
		return "", err
	}

	filename := buildFilenameFromTemplate(template, metadata)
	return filename, nil
}

// SanitizeFilename removes invalid characters from filename
func SanitizeFilename(filename string) string {
	return sanitizeFilename(filename)
}

// FetchLyrics fetches lyrics for a track from LRCLIB
// Returns JSON with lyrics data
func FetchLyrics(spotifyID, trackName, artistName string) (string, error) {
	client := NewLyricsClient()
	lyrics, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName)
	if err != nil {
		return "", err
	}

	result := map[string]interface{}{
		"success":   true,
		"source":    lyrics.Source,
		"sync_type": lyrics.SyncType,
		"lines":     lyrics.Lines,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// GetLyricsLRC fetches lyrics and converts to LRC format string with metadata headers
// First tries to extract from file, then falls back to fetching from internet
func GetLyricsLRC(spotifyID, trackName, artistName string, filePath string) (string, error) {
	// Try to extract from file first (much faster)
	if filePath != "" {
		lyrics, err := ExtractLyrics(filePath)
		if err == nil && lyrics != "" {
			return lyrics, nil
		}
	}

	// Fallback to fetching from internet
	client := NewLyricsClient()
	lyricsData, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName)
	if err != nil {
		return "", err
	}

	// Convert to LRC format with metadata headers (like PC version)
	lrcContent := convertToLRCWithMetadata(lyricsData, trackName, artistName)
	return lrcContent, nil
}

// EmbedLyricsToFile embeds lyrics into an existing FLAC file
func EmbedLyricsToFile(filePath, lyrics string) (string, error) {
	err := EmbedLyrics(filePath, lyrics)
	if err != nil {
		return errorResponse("Failed to embed lyrics: " + err.Error())
	}

	resp := map[string]interface{}{
		"success": true,
		"message": "Lyrics embedded successfully",
	}

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

// PreWarmTrackCacheJSON pre-warms the track ID cache for album/playlist tracks
// tracksJSON is a JSON array of objects with: isrc, track_name, artist_name, spotify_id, service
// This runs in background and returns immediately
func PreWarmTrackCacheJSON(tracksJSON string) (string, error) {
	var tracks []struct {
		ISRC       string `json:"isrc"`
		TrackName  string `json:"track_name"`
		ArtistName string `json:"artist_name"`
		SpotifyID  string `json:"spotify_id"`
		Service    string `json:"service"`
	}

	if err := json.Unmarshal([]byte(tracksJSON), &tracks); err != nil {
		return errorResponse("Invalid JSON: " + err.Error())
	}

	// Convert to PreWarmCacheRequest
	requests := make([]PreWarmCacheRequest, len(tracks))
	for i, t := range tracks {
		requests[i] = PreWarmCacheRequest{
			ISRC:       t.ISRC,
			TrackName:  t.TrackName,
			ArtistName: t.ArtistName,
			SpotifyID:  t.SpotifyID,
			Service:    t.Service,
		}
	}

	// Run in background
	go PreWarmTrackCache(requests)

	resp := map[string]interface{}{
		"success": true,
		"message": fmt.Sprintf("Pre-warming cache for %d tracks in background", len(tracks)),
	}

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

// GetTrackCacheSize returns the current track ID cache size
func GetTrackCacheSize() int {
	return GetCacheSize()
}

// ClearTrackIDCache clears the track ID cache
func ClearTrackIDCache() {
	ClearTrackCache()
}

// ==================== DEEZER API ====================

// SearchDeezerAll searches for tracks and artists on Deezer (no API key required)
// Returns JSON with tracks and artists arrays
func SearchDeezerAll(query string, trackLimit, artistLimit int) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client := GetDeezerClient()
	results, err := client.SearchAll(ctx, query, trackLimit, artistLimit)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(results)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// GetDeezerMetadata fetches metadata from Deezer URL or ID
// resourceType: track, album, artist, playlist
// resourceID: Deezer ID
func GetDeezerMetadata(resourceType, resourceID string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client := GetDeezerClient()
	var data interface{}
	var err error

	switch resourceType {
	case "track":
		data, err = client.GetTrack(ctx, resourceID)
	case "album":
		data, err = client.GetAlbum(ctx, resourceID)
	case "artist":
		data, err = client.GetArtist(ctx, resourceID)
	case "playlist":
		data, err = client.GetPlaylist(ctx, resourceID)
	default:
		return "", fmt.Errorf("unsupported Deezer resource type: %s", resourceType)
	}

	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(data)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// ParseDeezerURLExport parses a Deezer URL and returns type and ID
func ParseDeezerURLExport(url string) (string, error) {
	resourceType, resourceID, err := parseDeezerURL(url)
	if err != nil {
		return "", err
	}

	result := map[string]string{
		"type": resourceType,
		"id":   resourceID,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// SearchDeezerByISRC searches for a track by ISRC on Deezer
func SearchDeezerByISRC(isrc string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client := GetDeezerClient()
	track, err := client.SearchByISRC(ctx, isrc)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(track)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// ConvertSpotifyToDeezer converts a Spotify track/album ID to Deezer and fetches metadata
// This uses SongLink API to find the Deezer equivalent, then fetches from Deezer
// Useful when Spotify API is rate limited
func ConvertSpotifyToDeezer(resourceType, spotifyID string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	songlink := NewSongLinkClient()
	deezerClient := GetDeezerClient()

	// For tracks, we can use SongLink to get Deezer ID
	if resourceType == "track" {
		deezerID, err := songlink.GetDeezerIDFromSpotify(spotifyID)
		if err != nil {
			return "", fmt.Errorf("could not find Deezer equivalent: %w", err)
		}

		// Fetch metadata from Deezer
		trackResp, err := deezerClient.GetTrack(ctx, deezerID)
		if err != nil {
			return "", fmt.Errorf("failed to fetch Deezer metadata: %w", err)
		}

		jsonBytes, err := json.Marshal(trackResp)
		if err != nil {
			return "", err
		}

		return string(jsonBytes), nil
	}

	// For albums, SongLink also provides mapping
	if resourceType == "album" {
		deezerID, err := songlink.GetDeezerAlbumIDFromSpotify(spotifyID)
		if err != nil {
			return "", fmt.Errorf("could not find Deezer album: %w", err)
		}

		// Fetch album metadata from Deezer
		albumResp, err := deezerClient.GetAlbum(ctx, deezerID)
		if err != nil {
			return "", fmt.Errorf("failed to fetch Deezer album metadata: %w", err)
		}

		jsonBytes, err := json.Marshal(albumResp)
		if err != nil {
			return "", err
		}

		return string(jsonBytes), nil
	}

	// For artists/playlists, SongLink doesn't provide direct mapping
	return "", fmt.Errorf("Spotify to Deezer conversion only supported for tracks and albums. Please search by name for %s", resourceType)
}

// GetSpotifyMetadataWithDeezerFallback tries Spotify first, falls back to Deezer on rate limit
func GetSpotifyMetadataWithDeezerFallback(spotifyURL string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Try Spotify first
	client, err := NewSpotifyMetadataClient()
	if err != nil {
		// No Spotify credentials - fall through to Deezer fallback
		LogWarn("Spotify", "Credentials not configured, falling back to Deezer")
	} else {
		data, err := client.GetFilteredData(ctx, spotifyURL, false, 0)
		if err == nil {
			jsonBytes, err := json.Marshal(data)
			if err != nil {
				return "", err
			}
			return string(jsonBytes), nil
		}

		// Check if it's a rate limit error
		errStr := strings.ToLower(err.Error())
		if !strings.Contains(errStr, "429") && !strings.Contains(errStr, "rate") && !strings.Contains(errStr, "limit") {
			// Not a rate limit error, return original error
			return "", err
		}
	}

	// Rate limited - try Deezer fallback for tracks and albums
	parsed, parseErr := parseSpotifyURI(spotifyURL)
	if parseErr != nil {
		return "", fmt.Errorf("spotify rate limited and failed to parse URL: %w", parseErr)
	}

	GoLog("[Fallback] Spotify rate limited for %s, trying Deezer...\n", parsed.Type)

	if parsed.Type == "track" || parsed.Type == "album" {
		// Convert to Deezer
		return ConvertSpotifyToDeezer(parsed.Type, parsed.ID)
	}

	// Artist and playlist not supported for fallback
	if parsed.Type == "artist" {
		return "", fmt.Errorf("spotify rate limited. Artist pages require Spotify API - please try again later")
	}

	return "", fmt.Errorf("spotify rate limited. Playlists are user-specific and require Spotify API")
}

// ==================== SONGLINK DEEZER SUPPORT ====================

// CheckAvailabilityFromDeezerID checks track availability using Deezer track ID as source
// Returns JSON with availability info for Spotify, Tidal, Amazon, etc.
func CheckAvailabilityFromDeezerID(deezerTrackID string) (string, error) {
	client := NewSongLinkClient()
	availability, err := client.CheckAvailabilityFromDeezer(deezerTrackID)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(availability)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// CheckAvailabilityByPlatformID checks track availability using any platform as source
// platform: "spotify", "deezer", "tidal", "amazonMusic", "appleMusic", "youtube"
// entityType: "song" or "album"
// entityID: the ID on that platform
func CheckAvailabilityByPlatformID(platform, entityType, entityID string) (string, error) {
	client := NewSongLinkClient()
	availability, err := client.CheckAvailabilityByPlatform(platform, entityType, entityID)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(availability)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// GetSpotifyIDFromDeezerTrack converts a Deezer track ID to Spotify track ID
func GetSpotifyIDFromDeezerTrack(deezerTrackID string) (string, error) {
	client := NewSongLinkClient()
	return client.GetSpotifyIDFromDeezer(deezerTrackID)
}

// GetTidalURLFromDeezerTrack converts a Deezer track ID to Tidal URL
func GetTidalURLFromDeezerTrack(deezerTrackID string) (string, error) {
	client := NewSongLinkClient()
	return client.GetTidalURLFromDeezer(deezerTrackID)
}

// GetAmazonURLFromDeezerTrack converts a Deezer track ID to Amazon Music URL
func GetAmazonURLFromDeezerTrack(deezerTrackID string) (string, error) {
	client := NewSongLinkClient()
	return client.GetAmazonURLFromDeezer(deezerTrackID)
}

func errorResponse(msg string) (string, error) {
	// Determine error type based on message
	errorType := "unknown"
	lowerMsg := strings.ToLower(msg)

	if strings.Contains(lowerMsg, "isp blocking") ||
		strings.Contains(lowerMsg, "try using vpn") ||
		strings.Contains(lowerMsg, "change dns") {
		errorType = "isp_blocked"
	} else if strings.Contains(lowerMsg, "not found") ||
		strings.Contains(lowerMsg, "not available") ||
		strings.Contains(lowerMsg, "no results") ||
		strings.Contains(lowerMsg, "track not found") ||
		strings.Contains(lowerMsg, "all services failed") {
		errorType = "not_found"
	} else if strings.Contains(lowerMsg, "rate limit") ||
		strings.Contains(lowerMsg, "429") ||
		strings.Contains(lowerMsg, "too many requests") {
		errorType = "rate_limit"
	} else if strings.Contains(lowerMsg, "network") ||
		strings.Contains(lowerMsg, "connection") ||
		strings.Contains(lowerMsg, "timeout") ||
		strings.Contains(lowerMsg, "dial") {
		errorType = "network"
	}

	resp := DownloadResponse{
		Success:   false,
		Error:     msg,
		ErrorType: errorType,
	}
	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

// ==================== EXTENSION SYSTEM ====================

// InitExtensionSystem initializes the extension system with directories
func InitExtensionSystem(extensionsDir, dataDir string) error {
	manager := GetExtensionManager()
	if err := manager.SetDirectories(extensionsDir, dataDir); err != nil {
		return err
	}

	settingsStore := GetExtensionSettingsStore()
	if err := settingsStore.SetDataDir(dataDir); err != nil {
		return err
	}

	return nil
}

// LoadExtensionsFromDir loads all extensions from a directory
func LoadExtensionsFromDir(dirPath string) (string, error) {
	manager := GetExtensionManager()
	loaded, errors := manager.LoadExtensionsFromDirectory(dirPath)

	result := map[string]interface{}{
		"loaded": loaded,
		"errors": make([]string, len(errors)),
	}

	for i, err := range errors {
		result["errors"].([]string)[i] = err.Error()
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// LoadExtensionFromPath loads a single extension from a .spotiflac-ext file
func LoadExtensionFromPath(filePath string) (string, error) {
	manager := GetExtensionManager()
	ext, err := manager.LoadExtensionFromFile(filePath)
	if err != nil {
		return "", err
	}

	// Initialize with saved settings
	settingsStore := GetExtensionSettingsStore()
	settings := settingsStore.GetAll(ext.ID)
	if len(settings) > 0 {
		manager.InitializeExtension(ext.ID, settings)
	}

	result := map[string]interface{}{
		"id":           ext.ID,
		"name":         ext.Manifest.Name,
		"display_name": ext.Manifest.DisplayName,
		"version":      ext.Manifest.Version,
		"enabled":      ext.Enabled,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// UnloadExtensionByID unloads an extension
func UnloadExtensionByID(extensionID string) error {
	manager := GetExtensionManager()
	return manager.UnloadExtension(extensionID)
}

// RemoveExtensionByID completely removes an extension (unload + delete files)
func RemoveExtensionByID(extensionID string) error {
	manager := GetExtensionManager()
	return manager.RemoveExtension(extensionID)
}

// UpgradeExtensionFromPath upgrades an existing extension from a new package file
func UpgradeExtensionFromPath(filePath string) (string, error) {
	manager := GetExtensionManager()
	ext, err := manager.UpgradeExtension(filePath)
	if err != nil {
		return "", err
	}

	// Initialize with saved settings
	settingsStore := GetExtensionSettingsStore()
	settings := settingsStore.GetAll(ext.ID)
	if len(settings) > 0 {
		manager.InitializeExtension(ext.ID, settings)
	}

	// Return extension info as JSON
	result := map[string]interface{}{
		"id":           ext.ID,
		"display_name": ext.Manifest.DisplayName,
		"version":      ext.Manifest.Version,
		"enabled":      ext.Enabled,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// CheckExtensionUpgradeFromPath checks if a package file is an upgrade for an existing extension
func CheckExtensionUpgradeFromPath(filePath string) (string, error) {
	manager := GetExtensionManager()
	return manager.CheckExtensionUpgradeJSON(filePath)
}

// GetInstalledExtensions returns all installed extensions as JSON
func GetInstalledExtensions() (string, error) {
	manager := GetExtensionManager()
	return manager.GetInstalledExtensionsJSON()
}

// SetExtensionEnabledByID enables or disables an extension
func SetExtensionEnabledByID(extensionID string, enabled bool) error {
	manager := GetExtensionManager()
	return manager.SetExtensionEnabled(extensionID, enabled)
}

// SetProviderPriorityJSON sets the provider priority order from JSON array
func SetProviderPriorityJSON(priorityJSON string) error {
	var priority []string
	if err := json.Unmarshal([]byte(priorityJSON), &priority); err != nil {
		return err
	}

	SetProviderPriority(priority)
	return nil
}

// GetProviderPriorityJSON returns the provider priority order as JSON
func GetProviderPriorityJSON() (string, error) {
	priority := GetProviderPriority()
	jsonBytes, err := json.Marshal(priority)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

// SetMetadataProviderPriorityJSON sets the metadata provider priority order from JSON array
func SetMetadataProviderPriorityJSON(priorityJSON string) error {
	var priority []string
	if err := json.Unmarshal([]byte(priorityJSON), &priority); err != nil {
		return err
	}

	SetMetadataProviderPriority(priority)
	return nil
}

// GetMetadataProviderPriorityJSON returns the metadata provider priority order as JSON
func GetMetadataProviderPriorityJSON() (string, error) {
	priority := GetMetadataProviderPriority()
	jsonBytes, err := json.Marshal(priority)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

// GetExtensionSettingsJSON returns settings for an extension as JSON
func GetExtensionSettingsJSON(extensionID string) (string, error) {
	store := GetExtensionSettingsStore()
	settings := store.GetAll(extensionID)

	jsonBytes, err := json.Marshal(settings)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// SetExtensionSettingsJSON sets settings for an extension from JSON
func SetExtensionSettingsJSON(extensionID, settingsJSON string) error {
	var settings map[string]interface{}
	if err := json.Unmarshal([]byte(settingsJSON), &settings); err != nil {
		return err
	}

	store := GetExtensionSettingsStore()
	if err := store.SetAll(extensionID, settings); err != nil {
		return err
	}

	// Re-initialize extension with new settings
	manager := GetExtensionManager()
	return manager.InitializeExtension(extensionID, settings)
}

// SearchTracksWithExtensionsJSON searches all extension metadata providers
func SearchTracksWithExtensionsJSON(query string, limit int) (string, error) {
	manager := GetExtensionManager()
	tracks, err := manager.SearchTracksWithExtensions(query, limit)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(tracks)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// DownloadWithExtensionsJSON downloads using extension providers with fallback
func DownloadWithExtensionsJSON(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return "", fmt.Errorf("invalid request: %w", err)
	}

	result, err := DownloadWithExtensionFallback(req)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// CleanupExtensions unloads all extensions gracefully
func CleanupExtensions() {
	manager := GetExtensionManager()
	manager.UnloadAllExtensions()
}

// ==================== EXTENSION AUTH API ====================

// GetExtensionPendingAuthJSON returns pending auth request for an extension
func GetExtensionPendingAuthJSON(extensionID string) (string, error) {
	req := GetPendingAuthRequest(extensionID)
	if req == nil {
		return "", nil
	}

	result := map[string]interface{}{
		"extension_id": req.ExtensionID,
		"auth_url":     req.AuthURL,
		"callback_url": req.CallbackURL,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// SetExtensionAuthCodeByID sets auth code for an extension (called from Flutter after OAuth callback)
func SetExtensionAuthCodeByID(extensionID, authCode string) {
	SetExtensionAuthCode(extensionID, authCode)
}

// SetExtensionTokensByID sets tokens for an extension
func SetExtensionTokensByID(extensionID, accessToken, refreshToken string, expiresIn int) {
	var expiresAt time.Time
	if expiresIn > 0 {
		expiresAt = time.Now().Add(time.Duration(expiresIn) * time.Second)
	}
	SetExtensionTokens(extensionID, accessToken, refreshToken, expiresAt)
}

// ClearExtensionPendingAuthByID clears pending auth request for an extension
func ClearExtensionPendingAuthByID(extensionID string) {
	ClearPendingAuthRequest(extensionID)
}

// IsExtensionAuthenticatedByID checks if an extension is authenticated
func IsExtensionAuthenticatedByID(extensionID string) bool {
	extensionAuthStateMu.RLock()
	defer extensionAuthStateMu.RUnlock()

	state, exists := extensionAuthState[extensionID]
	if !exists {
		return false
	}

	// Check if token is expired
	if state.IsAuthenticated && !state.ExpiresAt.IsZero() && time.Now().After(state.ExpiresAt) {
		return false
	}

	return state.IsAuthenticated
}

// GetAllPendingAuthRequestsJSON returns all pending auth requests
func GetAllPendingAuthRequestsJSON() (string, error) {
	pendingAuthRequestsMu.RLock()
	defer pendingAuthRequestsMu.RUnlock()

	requests := make([]map[string]interface{}, 0, len(pendingAuthRequests))
	for _, req := range pendingAuthRequests {
		requests = append(requests, map[string]interface{}{
			"extension_id": req.ExtensionID,
			"auth_url":     req.AuthURL,
			"callback_url": req.CallbackURL,
		})
	}

	jsonBytes, err := json.Marshal(requests)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// ==================== EXTENSION FFMPEG API ====================

// GetPendingFFmpegCommandJSON returns a pending FFmpeg command for Flutter to execute
func GetPendingFFmpegCommandJSON(commandID string) (string, error) {
	cmd := GetPendingFFmpegCommand(commandID)
	if cmd == nil {
		return "", nil
	}

	result := map[string]interface{}{
		"command_id":   commandID,
		"extension_id": cmd.ExtensionID,
		"command":      cmd.Command,
		"input_path":   cmd.InputPath,
		"output_path":  cmd.OutputPath,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// SetFFmpegCommandResultByID sets the result of an FFmpeg command
func SetFFmpegCommandResultByID(commandID string, success bool, output, errorMsg string) {
	SetFFmpegCommandResult(commandID, success, output, errorMsg)
}

// GetAllPendingFFmpegCommandsJSON returns all pending FFmpeg commands
func GetAllPendingFFmpegCommandsJSON() (string, error) {
	ffmpegCommandsMu.RLock()
	defer ffmpegCommandsMu.RUnlock()

	commands := make([]map[string]interface{}, 0)
	for cmdID, cmd := range ffmpegCommands {
		if !cmd.Completed {
			commands = append(commands, map[string]interface{}{
				"command_id":   cmdID,
				"extension_id": cmd.ExtensionID,
				"command":      cmd.Command,
			})
		}
	}

	jsonBytes, err := json.Marshal(commands)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// ==================== EXTENSION CUSTOM SEARCH ====================

// CustomSearchWithExtensionJSON performs custom search using an extension
func CustomSearchWithExtensionJSON(extensionID, query string, optionsJSON string) (string, error) {
	manager := GetExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return "", err
	}

	if !ext.Manifest.HasCustomSearch() {
		return "", fmt.Errorf("extension '%s' does not support custom search", extensionID)
	}

	var options map[string]interface{}
	if optionsJSON != "" {
		if err := json.Unmarshal([]byte(optionsJSON), &options); err != nil {
			options = make(map[string]interface{})
		}
	}

	provider := NewExtensionProviderWrapper(ext)
	tracks, err := provider.CustomSearch(query, options)
	if err != nil {
		return "", err
	}

	// Convert to map format for Flutter, ensuring images field is set
	result := make([]map[string]interface{}, len(tracks))
	for i, track := range tracks {
		result[i] = map[string]interface{}{
			"id":           track.ID,
			"name":         track.Name,
			"artists":      track.Artists,
			"album_name":   track.AlbumName,
			"album_artist": track.AlbumArtist,
			"duration_ms":  track.DurationMS,
			"images":       track.ResolvedCoverURL(), // Use helper to get cover URL from either field
			"release_date": track.ReleaseDate,
			"track_number": track.TrackNumber,
			"disc_number":  track.DiscNumber,
			"isrc":         track.ISRC,
			"provider_id":  track.ProviderID,
		}
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// GetSearchProvidersJSON returns all extensions that provide custom search
func GetSearchProvidersJSON() (string, error) {
	manager := GetExtensionManager()
	providers := manager.GetSearchProviders()

	result := make([]map[string]interface{}, 0, len(providers))
	for _, p := range providers {
		result = append(result, map[string]interface{}{
			"id":           p.extension.ID,
			"display_name": p.extension.Manifest.DisplayName,
			"placeholder":  p.extension.Manifest.SearchBehavior.Placeholder,
			"primary":      p.extension.Manifest.SearchBehavior.Primary,
			"icon":         p.extension.Manifest.SearchBehavior.Icon,
		})
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// ==================== EXTENSION POST-PROCESSING ====================

// RunPostProcessingJSON runs post-processing hooks on a file
func RunPostProcessingJSON(filePath, metadataJSON string) (string, error) {
	var metadata map[string]interface{}
	if metadataJSON != "" {
		if err := json.Unmarshal([]byte(metadataJSON), &metadata); err != nil {
			metadata = make(map[string]interface{})
		}
	}

	manager := GetExtensionManager()
	result, err := manager.RunPostProcessing(filePath, metadata)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// GetPostProcessingProvidersJSON returns all extensions that provide post-processing
func GetPostProcessingProvidersJSON() (string, error) {
	manager := GetExtensionManager()
	providers := manager.GetPostProcessingProviders()

	result := make([]map[string]interface{}, 0, len(providers))
	for _, p := range providers {
		hooks := make([]map[string]interface{}, 0)
		for _, h := range p.extension.Manifest.GetPostProcessingHooks() {
			hooks = append(hooks, map[string]interface{}{
				"id":                h.ID,
				"name":              h.Name,
				"description":       h.Description,
				"default_enabled":   h.DefaultEnabled,
				"supported_formats": h.SupportedFormats,
			})
		}

		result = append(result, map[string]interface{}{
			"id":           p.extension.ID,
			"display_name": p.extension.Manifest.DisplayName,
			"hooks":        hooks,
		})
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}
