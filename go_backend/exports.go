// Package gobackend provides exported functions for gomobile binding
// These functions are the bridge between Flutter and Go backend
package gobackend

import (
	"context"
	"encoding/json"
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

// GetSpotifyMetadata fetches metadata from Spotify URL
// Returns JSON with track/album/playlist data
func GetSpotifyMetadata(spotifyURL string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	
	client := NewSpotifyMetadataClient()
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
	
	client := NewSpotifyMetadataClient()
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
}

// DownloadResponse represents the result of a download
type DownloadResponse struct {
	Success       bool   `json:"success"`
	Message       string `json:"message"`
	FilePath      string `json:"file_path,omitempty"`
	Error         string `json:"error,omitempty"`
	AlreadyExists bool   `json:"already_exists,omitempty"`
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
	
	var filePath string
	var err error
	
	switch req.Service {
	case "tidal":
		filePath, err = downloadFromTidal(req)
	case "qobuz":
		filePath, err = downloadFromQobuz(req)
	case "amazon":
		filePath, err = downloadFromAmazon(req)
	default:
		return errorResponse("Unknown service: " + req.Service)
	}
	
	if err != nil {
		return errorResponse(err.Error())
	}
	
	// Check if file already exists
	if len(filePath) > 7 && filePath[:7] == "EXISTS:" {
		resp := DownloadResponse{
			Success:       true,
			Message:       "File already exists",
			FilePath:      filePath[7:],
			AlreadyExists: true,
		}
		jsonBytes, _ := json.Marshal(resp)
		return string(jsonBytes), nil
	}
	
	resp := DownloadResponse{
		Success:  true,
		Message:  "Download complete",
		FilePath: filePath,
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
	
	// Create ordered list: preferred first, then others
	services := []string{preferredService}
	for _, s := range allServices {
		if s != preferredService {
			services = append(services, s)
		}
	}
	
	var lastErr error
	
	for _, service := range services {
		req.Service = service
		
		var filePath string
		var err error
		
		switch service {
		case "tidal":
			filePath, err = downloadFromTidal(req)
		case "qobuz":
			filePath, err = downloadFromQobuz(req)
		case "amazon":
			filePath, err = downloadFromAmazon(req)
		}
		
		if err == nil {
			// Check if file already exists
			if len(filePath) > 7 && filePath[:7] == "EXISTS:" {
				resp := DownloadResponse{
					Success:       true,
					Message:       "File already exists",
					FilePath:      filePath[7:],
					AlreadyExists: true,
				}
				jsonBytes, _ := json.Marshal(resp)
				return string(jsonBytes), nil
			}
			
			resp := DownloadResponse{
				Success:  true,
				Message:  "Downloaded from " + service,
				FilePath: filePath,
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

// CleanupConnections closes idle HTTP connections
// Call this periodically during large batch downloads to prevent TCP exhaustion
func CleanupConnections() {
	CloseIdleConnections()
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

// GetLyricsLRC fetches lyrics and converts to LRC format string
func GetLyricsLRC(spotifyID, trackName, artistName string) (string, error) {
	client := NewLyricsClient()
	lyrics, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName)
	if err != nil {
		return "", err
	}

	lrcContent := convertToLRC(lyrics)
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

func errorResponse(msg string) (string, error) {
	resp := DownloadResponse{
		Success: false,
		Error:   msg,
	}
	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}
