// Package gobackend provides exported functions for gomobile binding
// These functions are the bridge between Flutter and Go backend
package gobackend

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/dop251/goja"
)

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

func SetSpotifyAPICredentials(clientID, clientSecret string) {
	SetSpotifyCredentials(clientID, clientSecret)
}

func CheckSpotifyCredentials() bool {
	return HasSpotifyCredentials()
}

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
	OutputPath           string `json:"output_path,omitempty"`
	OutputFD             int    `json:"output_fd,omitempty"`
	OutputExt            string `json:"output_ext,omitempty"`
	FilenameFormat       string `json:"filename_format"`
	Quality              string `json:"quality"`
	EmbedLyrics          bool   `json:"embed_lyrics"`
	EmbedMaxQualityCover bool   `json:"embed_max_quality_cover"`
	TrackNumber          int    `json:"track_number"`
	DiscNumber           int    `json:"disc_number"`
	TotalTracks          int    `json:"total_tracks"`
	ReleaseDate          string `json:"release_date"`
	ItemID               string `json:"item_id"`
	DurationMS           int    `json:"duration_ms"`
	Source               string `json:"source"`
	Genre                string `json:"genre,omitempty"`
	Label                string `json:"label,omitempty"`
	Copyright            string `json:"copyright,omitempty"`
	TidalID              string `json:"tidal_id,omitempty"`
	QobuzID              string `json:"qobuz_id,omitempty"`
	DeezerID             string `json:"deezer_id,omitempty"`
	LyricsMode           string `json:"lyrics_mode,omitempty"`
}

type DownloadResponse struct {
	Success                bool   `json:"success"`
	Message                string `json:"message"`
	FilePath               string `json:"file_path,omitempty"`
	Error                  string `json:"error,omitempty"`
	ErrorType              string `json:"error_type,omitempty"`
	AlreadyExists          bool   `json:"already_exists,omitempty"`
	ActualBitDepth         int    `json:"actual_bit_depth,omitempty"`
	ActualSampleRate       int    `json:"actual_sample_rate,omitempty"`
	Service                string `json:"service,omitempty"`
	Title                  string `json:"title,omitempty"`
	Artist                 string `json:"artist,omitempty"`
	Album                  string `json:"album,omitempty"`
	AlbumArtist            string `json:"album_artist,omitempty"`
	ReleaseDate            string `json:"release_date,omitempty"`
	TrackNumber            int    `json:"track_number,omitempty"`
	DiscNumber             int    `json:"disc_number,omitempty"`
	ISRC                   string `json:"isrc,omitempty"`
	CoverURL               string `json:"cover_url,omitempty"`
	Genre                  string `json:"genre,omitempty"`
	Label                  string `json:"label,omitempty"`
	Copyright              string `json:"copyright,omitempty"`
	SkipMetadataEnrichment bool   `json:"skip_metadata_enrichment,omitempty"`
	LyricsLRC              string `json:"lyrics_lrc,omitempty"`
}

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
	LyricsLRC   string
}

func DownloadTrack(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return errorResponse("Invalid request: " + err.Error())
	}

	req.TrackName = strings.TrimSpace(req.TrackName)
	req.ArtistName = strings.TrimSpace(req.ArtistName)
	req.AlbumName = strings.TrimSpace(req.AlbumName)
	req.AlbumArtist = strings.TrimSpace(req.AlbumArtist)
	req.OutputDir = strings.TrimSpace(req.OutputDir)
	req.OutputPath = strings.TrimSpace(req.OutputPath)
	req.OutputExt = strings.TrimSpace(req.OutputExt)

	if req.OutputPath == "" && req.OutputFD <= 0 && req.OutputDir != "" {
		AddAllowedDownloadDir(req.OutputDir)
	}

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
				LyricsLRC:   tidalResult.LyricsLRC,
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
				LyricsLRC:   qobuzResult.LyricsLRC,
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
				LyricsLRC:   amazonResult.LyricsLRC,
			}
		}
		err = amazonErr
	default:
		return errorResponse("Unknown service: " + req.Service)
	}

	if err != nil {
		return errorResponse(err.Error())
	}

	if len(result.FilePath) > 7 && result.FilePath[:7] == "EXISTS:" {
		actualPath := result.FilePath[7:]
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
		LyricsLRC:        result.LyricsLRC,
	}

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

func DownloadWithFallback(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return errorResponse("Invalid request: " + err.Error())
	}

	req.TrackName = strings.TrimSpace(req.TrackName)
	req.ArtistName = strings.TrimSpace(req.ArtistName)
	req.AlbumName = strings.TrimSpace(req.AlbumName)
	req.AlbumArtist = strings.TrimSpace(req.AlbumArtist)
	req.OutputDir = strings.TrimSpace(req.OutputDir)
	req.OutputPath = strings.TrimSpace(req.OutputPath)
	req.OutputExt = strings.TrimSpace(req.OutputExt)

	if req.OutputPath == "" && req.OutputFD <= 0 && req.OutputDir != "" {
		AddAllowedDownloadDir(req.OutputDir)
	}

	allServices := []string{"tidal", "qobuz", "amazon"}
	preferredService := req.Service
	if preferredService == "" {
		preferredService = "tidal"
	}

	GoLog("[DownloadWithFallback] Preferred service from request: '%s'\n", req.Service)

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
					LyricsLRC:   tidalResult.LyricsLRC,
				}
			} else if !errors.Is(tidalErr, ErrDownloadCancelled) {
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
					LyricsLRC:   qobuzResult.LyricsLRC,
				}
			} else if !errors.Is(qobuzErr, ErrDownloadCancelled) {
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
					LyricsLRC:   amazonResult.LyricsLRC,
				}
			} else if !errors.Is(amazonErr, ErrDownloadCancelled) {
				GoLog("[DownloadWithFallback] Amazon error: %v\n", amazonErr)
			}
			err = amazonErr
		}

		if err != nil && errors.Is(err, ErrDownloadCancelled) {
			return errorResponse("Download cancelled")
		}

		if err == nil {
			if len(result.FilePath) > 7 && result.FilePath[:7] == "EXISTS:" {
				actualPath := result.FilePath[7:]
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
					LyricsLRC:        result.LyricsLRC,
				}
				jsonBytes, _ := json.Marshal(resp)
				return string(jsonBytes), nil
			}

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
				LyricsLRC:        result.LyricsLRC,
			}
			jsonBytes, _ := json.Marshal(resp)
			return string(jsonBytes), nil
		}

		lastErr = err
	}

	return errorResponse("All services failed. Last error: " + lastErr.Error())
}

func GetDownloadProgress() string {
	progress := getProgress()
	jsonBytes, _ := json.Marshal(progress)
	return string(jsonBytes)
}

func GetAllDownloadProgress() string {
	return GetMultiProgress()
}

func InitItemProgress(itemID string) {
	StartItemProgress(itemID)
}

func FinishItemProgress(itemID string) {
	CompleteItemProgress(itemID)
}

func ClearItemProgress(itemID string) {
	RemoveItemProgress(itemID)
}

func CancelDownload(itemID string) {
	cancelDownload(itemID)
}

func CleanupConnections() {
	CloseIdleConnections()
}

func ReadFileMetadata(filePath string) (string, error) {
	metadata, err := ReadMetadata(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to read metadata: %w", err)
	}

	quality, qualityErr := GetAudioQuality(filePath)

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

func SetDownloadDirectory(path string) error {
	return setDownloadDir(path)
}

// AllowDownloadDir adds a directory to the extension file sandbox allowlist.
func AllowDownloadDir(path string) {
	if strings.TrimSpace(path) == "" {
		return
	}
	AddAllowedDownloadDir(path)
}

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

func CheckDuplicatesBatch(outputDir, tracksJSON string) (string, error) {
	return CheckFilesExistParallel(outputDir, tracksJSON)
}

func PreBuildDuplicateIndex(outputDir string) error {
	return PreBuildISRCIndex(outputDir)
}

func InvalidateDuplicateIndex(outputDir string) {
	InvalidateISRCCache(outputDir)
}

func BuildFilename(template string, metadataJSON string) (string, error) {
	var metadata map[string]interface{}
	if err := json.Unmarshal([]byte(metadataJSON), &metadata); err != nil {
		return "", err
	}

	filename := buildFilenameFromTemplate(template, metadata)
	return filename, nil
}

func SanitizeFilename(filename string) string {
	return sanitizeFilename(filename)
}

func FetchLyrics(spotifyID, trackName, artistName string, durationMs int64) (string, error) {
	client := NewLyricsClient()
	durationSec := float64(durationMs) / 1000.0
	lyrics, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName, durationSec)
	if err != nil {
		return "", err
	}

	result := map[string]interface{}{
		"success":      true,
		"source":       lyrics.Source,
		"sync_type":    lyrics.SyncType,
		"lines":        lyrics.Lines,
		"instrumental": lyrics.Instrumental,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetLyricsLRC(spotifyID, trackName, artistName string, filePath string, durationMs int64) (string, error) {
	if filePath != "" {
		lyrics, err := ExtractLyrics(filePath)
		if err == nil && lyrics != "" {
			return lyrics, nil
		}
		return "", nil
	}

	client := NewLyricsClient()
	durationSec := float64(durationMs) / 1000.0
	lyricsData, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName, durationSec)
	if err != nil {
		return "", err
	}

	if lyricsData.Instrumental {
		return "[instrumental:true]", nil
	}

	lrcContent := convertToLRCWithMetadata(lyricsData, trackName, artistName)
	return lrcContent, nil
}

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

	go PreWarmTrackCache(requests)

	resp := map[string]interface{}{
		"success": true,
		"message": fmt.Sprintf("Pre-warming cache for %d tracks in background", len(tracks)),
	}

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

func GetTrackCacheSize() int {
	return GetCacheSize()
}

func ClearTrackIDCache() {
	ClearTrackCache()
}

func SearchDeezerAll(query string, trackLimit, artistLimit int, filter string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client := GetDeezerClient()
	results, err := client.SearchAll(ctx, query, trackLimit, artistLimit, filter)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(results)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

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

func ParseTidalURLExport(url string) (string, error) {
	resourceType, resourceID, err := parseTidalURL(url)
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

func ConvertTidalToSpotifyDeezer(tidalURL string) (string, error) {
	client := NewSongLinkClient()
	availability, err := client.CheckAvailabilityFromURL(tidalURL)
	if err != nil {
		return "", err
	}

	result := map[string]string{
		"spotify_id":  availability.SpotifyID,
		"deezer_id":   availability.DeezerID,
		"deezer_url":  availability.DeezerURL,
		"spotify_url": "",
	}

	if availability.SpotifyID != "" {
		result["spotify_url"] = "https://open.spotify.com/track/" + availability.SpotifyID
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetDeezerExtendedMetadata(trackID string) (string, error) {
	if trackID == "" {
		return "", fmt.Errorf("empty track ID")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client := GetDeezerClient()
	metadata, err := client.GetExtendedMetadataByTrackID(ctx, trackID)
	if err != nil {
		GoLog("[Deezer] Failed to get extended metadata: %v\n", err)
		return "", err
	}

	result := map[string]string{
		"genre": metadata.Genre,
		"label": metadata.Label,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

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

func ConvertSpotifyToDeezer(resourceType, spotifyID string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	songlink := NewSongLinkClient()
	deezerClient := GetDeezerClient()

	if resourceType == "track" {
		deezerID, err := songlink.GetDeezerIDFromSpotify(spotifyID)
		if err != nil {
			return "", fmt.Errorf("could not find Deezer equivalent: %w", err)
		}

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

	if resourceType == "album" {
		deezerID, err := songlink.GetDeezerAlbumIDFromSpotify(spotifyID)
		if err != nil {
			return "", fmt.Errorf("could not find Deezer album: %w", err)
		}

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

func GetSpotifyMetadataWithDeezerFallback(spotifyURL string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client, err := NewSpotifyMetadataClient()
	if err != nil {
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

		errStr := strings.ToLower(err.Error())
		if !strings.Contains(errStr, "429") && !strings.Contains(errStr, "rate") && !strings.Contains(errStr, "limit") {
			return "", err
		}
	}

	parsed, parseErr := parseSpotifyURI(spotifyURL)
	if parseErr != nil {
		return "", fmt.Errorf("spotify rate limited and failed to parse URL: %w", parseErr)
	}

	GoLog("[Fallback] Spotify rate limited for %s, trying Deezer...\n", parsed.Type)

	if parsed.Type == "track" || parsed.Type == "album" {
		return ConvertSpotifyToDeezer(parsed.Type, parsed.ID)
	}

	if parsed.Type == "artist" {
		return "", fmt.Errorf("spotify rate limited. Artist pages require Spotify API - please try again later")
	}

	return "", fmt.Errorf("spotify rate limited. Playlists are user-specific and require Spotify API")
}

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

func GetSpotifyIDFromDeezerTrack(deezerTrackID string) (string, error) {
	client := NewSongLinkClient()
	return client.GetSpotifyIDFromDeezer(deezerTrackID)
}

func GetTidalURLFromDeezerTrack(deezerTrackID string) (string, error) {
	client := NewSongLinkClient()
	return client.GetTidalURLFromDeezer(deezerTrackID)
}

func GetAmazonURLFromDeezerTrack(deezerTrackID string) (string, error) {
	client := NewSongLinkClient()
	return client.GetAmazonURLFromDeezer(deezerTrackID)
}

func errorResponse(msg string) (string, error) {
	errorType := "unknown"
	lowerMsg := strings.ToLower(msg)

	if strings.Contains(lowerMsg, "isp blocking") ||
		strings.Contains(lowerMsg, "try using vpn") ||
		strings.Contains(lowerMsg, "change dns") {
		errorType = "isp_blocked"
	} else if strings.Contains(lowerMsg, "cancel") {
		errorType = "cancelled"
	} else if strings.Contains(lowerMsg, "permission") ||
		strings.Contains(lowerMsg, "operation not permitted") ||
		strings.Contains(lowerMsg, "access denied") ||
		strings.Contains(lowerMsg, "failed to create file") ||
		strings.Contains(lowerMsg, "failed to create directory") {
		errorType = "permission"
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

func LoadExtensionFromPath(filePath string) (string, error) {
	manager := GetExtensionManager()
	ext, err := manager.LoadExtensionFromFile(filePath)
	if err != nil {
		return "", err
	}

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

func UnloadExtensionByID(extensionID string) error {
	manager := GetExtensionManager()
	return manager.UnloadExtension(extensionID)
}

func RemoveExtensionByID(extensionID string) error {
	manager := GetExtensionManager()
	return manager.RemoveExtension(extensionID)
}

func UpgradeExtensionFromPath(filePath string) (string, error) {
	manager := GetExtensionManager()
	ext, err := manager.UpgradeExtension(filePath)
	if err != nil {
		return "", err
	}

	settingsStore := GetExtensionSettingsStore()
	settings := settingsStore.GetAll(ext.ID)
	if len(settings) > 0 {
		manager.InitializeExtension(ext.ID, settings)
	}

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

func CheckExtensionUpgradeFromPath(filePath string) (string, error) {
	manager := GetExtensionManager()
	return manager.CheckExtensionUpgradeJSON(filePath)
}

func GetInstalledExtensions() (string, error) {
	manager := GetExtensionManager()
	return manager.GetInstalledExtensionsJSON()
}

func SetExtensionEnabledByID(extensionID string, enabled bool) error {
	manager := GetExtensionManager()
	return manager.SetExtensionEnabled(extensionID, enabled)
}

func SetProviderPriorityJSON(priorityJSON string) error {
	var priority []string
	if err := json.Unmarshal([]byte(priorityJSON), &priority); err != nil {
		return err
	}

	SetProviderPriority(priority)
	return nil
}

func GetProviderPriorityJSON() (string, error) {
	priority := GetProviderPriority()
	jsonBytes, err := json.Marshal(priority)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

func SetMetadataProviderPriorityJSON(priorityJSON string) error {
	var priority []string
	if err := json.Unmarshal([]byte(priorityJSON), &priority); err != nil {
		return err
	}

	SetMetadataProviderPriority(priority)
	return nil
}

func GetMetadataProviderPriorityJSON() (string, error) {
	priority := GetMetadataProviderPriority()
	jsonBytes, err := json.Marshal(priority)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

func GetExtensionSettingsJSON(extensionID string) (string, error) {
	store := GetExtensionSettingsStore()
	settings := store.GetAll(extensionID)

	jsonBytes, err := json.Marshal(settings)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func SetExtensionSettingsJSON(extensionID, settingsJSON string) error {
	var settings map[string]interface{}
	if err := json.Unmarshal([]byte(settingsJSON), &settings); err != nil {
		return err
	}

	store := GetExtensionSettingsStore()
	if err := store.SetAll(extensionID, settings); err != nil {
		return err
	}

	manager := GetExtensionManager()
	return manager.InitializeExtension(extensionID, settings)
}

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

func DownloadWithExtensionsJSON(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return "", fmt.Errorf("invalid request: %w", err)
	}

	req.TrackName = strings.TrimSpace(req.TrackName)
	req.ArtistName = strings.TrimSpace(req.ArtistName)
	req.AlbumName = strings.TrimSpace(req.AlbumName)
	req.AlbumArtist = strings.TrimSpace(req.AlbumArtist)
	req.OutputDir = strings.TrimSpace(req.OutputDir)
	req.OutputPath = strings.TrimSpace(req.OutputPath)
	req.OutputExt = strings.TrimSpace(req.OutputExt)
	if req.OutputPath == "" && req.OutputFD <= 0 && req.OutputDir != "" {
		AddAllowedDownloadDir(req.OutputDir)
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

func CleanupExtensions() {
	manager := GetExtensionManager()
	manager.UnloadAllExtensions()
}

func InvokeExtensionActionJSON(extensionID, actionName string) (string, error) {
	manager := GetExtensionManager()
	result, err := manager.InvokeAction(extensionID, actionName)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

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

func SetExtensionAuthCodeByID(extensionID, authCode string) {
	SetExtensionAuthCode(extensionID, authCode)
}

func SetExtensionTokensByID(extensionID, accessToken, refreshToken string, expiresIn int) {
	var expiresAt time.Time
	if expiresIn > 0 {
		expiresAt = time.Now().Add(time.Duration(expiresIn) * time.Second)
	}
	SetExtensionTokens(extensionID, accessToken, refreshToken, expiresAt)
}

func ClearExtensionPendingAuthByID(extensionID string) {
	ClearPendingAuthRequest(extensionID)
}

func IsExtensionAuthenticatedByID(extensionID string) bool {
	extensionAuthStateMu.RLock()
	defer extensionAuthStateMu.RUnlock()

	state, exists := extensionAuthState[extensionID]
	if !exists {
		return false
	}

	if state.IsAuthenticated && !state.ExpiresAt.IsZero() && time.Now().After(state.ExpiresAt) {
		return false
	}

	return state.IsAuthenticated
}

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

func SetFFmpegCommandResultByID(commandID string, success bool, output, errorMsg string) {
	SetFFmpegCommandResult(commandID, success, output, errorMsg)
}

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

func EnrichTrackWithExtensionJSON(extensionID, trackJSON string) (string, error) {
	manager := GetExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return trackJSON, nil
	}

	if !ext.Manifest.IsMetadataProvider() {
		return trackJSON, nil
	}

	var track ExtTrackMetadata
	if err := json.Unmarshal([]byte(trackJSON), &track); err != nil {
		return trackJSON, fmt.Errorf("failed to parse track: %w", err)
	}

	provider := NewExtensionProviderWrapper(ext)
	enrichedTrack, err := provider.EnrichTrack(&track)
	if err != nil {
		return trackJSON, nil
	}

	jsonBytes, err := json.Marshal(enrichedTrack)
	if err != nil {
		return trackJSON, nil
	}

	return string(jsonBytes), nil
}

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
			"item_type":    track.ItemType,
			"album_type":   track.AlbumType,
		}
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

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

func HandleURLWithExtensionJSON(url string) (string, error) {
	manager := GetExtensionManager()
	resultWithID, err := manager.HandleURLWithExtension(url)
	if err != nil {
		return "", err
	}

	result := resultWithID.Result
	extensionID := resultWithID.ExtensionID

	if result == nil {
		return "", fmt.Errorf("extension %s failed to handle URL", extensionID)
	}

	response := map[string]interface{}{
		"type":         result.Type,
		"extension_id": extensionID,
		"name":         result.Name,
		"cover_url":    result.CoverURL,
	}

	if result.Track != nil {
		response["track"] = map[string]interface{}{
			"id":           result.Track.ID,
			"name":         result.Track.Name,
			"artists":      result.Track.Artists,
			"album_name":   result.Track.AlbumName,
			"album_artist": result.Track.AlbumArtist,
			"duration_ms":  result.Track.DurationMS,
			"images":       result.Track.ResolvedCoverURL(),
			"release_date": result.Track.ReleaseDate,
			"track_number": result.Track.TrackNumber,
			"disc_number":  result.Track.DiscNumber,
			"isrc":         result.Track.ISRC,
			"provider_id":  result.Track.ProviderID,
		}
	}

	if len(result.Tracks) > 0 {
		tracks := make([]map[string]interface{}, len(result.Tracks))
		for i, track := range result.Tracks {
			tracks[i] = map[string]interface{}{
				"id":           track.ID,
				"name":         track.Name,
				"artists":      track.Artists,
				"album_name":   track.AlbumName,
				"album_artist": track.AlbumArtist,
				"duration_ms":  track.DurationMS,
				"images":       track.ResolvedCoverURL(),
				"release_date": track.ReleaseDate,
				"track_number": track.TrackNumber,
				"disc_number":  track.DiscNumber,
				"isrc":         track.ISRC,
				"provider_id":  track.ProviderID,
				"item_type":    track.ItemType,
				"album_type":   track.AlbumType,
			}
		}
		response["tracks"] = tracks
	}

	if result.Album != nil {
		response["album"] = map[string]interface{}{
			"id":           result.Album.ID,
			"name":         result.Album.Name,
			"artists":      result.Album.Artists,
			"cover_url":    result.Album.CoverURL,
			"release_date": result.Album.ReleaseDate,
			"total_tracks": result.Album.TotalTracks,
			"album_type":   result.Album.AlbumType,
			"provider_id":  result.Album.ProviderID,
		}
	}

	if result.Artist != nil {
		artistResponse := map[string]interface{}{
			"id":           result.Artist.ID,
			"name":         result.Artist.Name,
			"image_url":    result.Artist.ImageURL,
			"header_image": result.Artist.HeaderImage,
			"listeners":    result.Artist.Listeners,
			"provider_id":  result.Artist.ProviderID,
		}

		if len(result.Artist.Albums) > 0 {
			albums := make([]map[string]interface{}, len(result.Artist.Albums))
			for i, album := range result.Artist.Albums {
				albumType := album.AlbumType
				if albumType == "" {
					albumType = "album"
				}
				albums[i] = map[string]interface{}{
					"id":           album.ID,
					"name":         album.Name,
					"artists":      album.Artists,
					"images":       album.CoverURL,
					"cover_url":    album.CoverURL,
					"release_date": album.ReleaseDate,
					"total_tracks": album.TotalTracks,
					"album_type":   albumType,
					"provider_id":  album.ProviderID,
				}
			}
			artistResponse["albums"] = albums
		}

		if len(result.Artist.TopTracks) > 0 {
			topTracks := make([]map[string]interface{}, len(result.Artist.TopTracks))
			for i, track := range result.Artist.TopTracks {
				topTracks[i] = map[string]interface{}{
					"id":           track.ID,
					"name":         track.Name,
					"artists":      track.Artists,
					"album_name":   track.AlbumName,
					"album_artist": track.AlbumArtist,
					"duration_ms":  track.DurationMS,
					"images":       track.ResolvedCoverURL(),
					"release_date": track.ReleaseDate,
					"track_number": track.TrackNumber,
					"disc_number":  track.DiscNumber,
					"isrc":         track.ISRC,
					"provider_id":  track.ProviderID,
					"spotify_id":   track.SpotifyID,
				}
			}
			artistResponse["top_tracks"] = topTracks
		}

		response["artist"] = artistResponse
	}

	jsonBytes, err := json.Marshal(response)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func FindURLHandlerJSON(url string) string {
	manager := GetExtensionManager()
	handler := manager.FindURLHandler(url)
	if handler == nil {
		return ""
	}
	return handler.extension.ID
}

func GetAlbumWithExtensionJSON(extensionID, albumID string) (string, error) {
	manager := GetExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return "", err
	}

	if !ext.Manifest.IsMetadataProvider() {
		return "", fmt.Errorf("extension '%s' is not a metadata provider", extensionID)
	}
	if !ext.Enabled {
		return "", fmt.Errorf("extension '%s' is disabled", extensionID)
	}

	provider := NewExtensionProviderWrapper(ext)
	album, err := provider.GetAlbum(albumID)
	if err != nil {
		return "", err
	}

	if album == nil {
		return "", fmt.Errorf("album not found")
	}

	tracks := make([]map[string]interface{}, len(album.Tracks))
	for i, track := range album.Tracks {
		trackCover := track.ResolvedCoverURL()
		if trackCover == "" {
			trackCover = album.CoverURL
		}
		trackNum := track.TrackNumber
		if trackNum == 0 {
			trackNum = i + 1
		}
		tracks[i] = map[string]interface{}{
			"id":           track.ID,
			"name":         track.Name,
			"artists":      track.Artists,
			"album_name":   track.AlbumName,
			"album_artist": track.AlbumArtist,
			"duration_ms":  track.DurationMS,
			"cover_url":    trackCover,
			"release_date": track.ReleaseDate,
			"track_number": trackNum,
			"disc_number":  track.DiscNumber,
			"isrc":         track.ISRC,
			"provider_id":  track.ProviderID,
			"item_type":    track.ItemType,
			"album_type":   track.AlbumType,
		}
	}

	response := map[string]interface{}{
		"id":           album.ID,
		"name":         album.Name,
		"artists":      album.Artists,
		"artist_id":    album.ArtistID,
		"cover_url":    album.CoverURL,
		"release_date": album.ReleaseDate,
		"total_tracks": album.TotalTracks,
		"album_type":   album.AlbumType,
		"tracks":       tracks,
		"provider_id":  album.ProviderID,
	}

	jsonBytes, err := json.Marshal(response)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetPlaylistWithExtensionJSON(extensionID, playlistID string) (string, error) {
	manager := GetExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return "", err
	}

	if !ext.Manifest.IsMetadataProvider() {
		return "", fmt.Errorf("extension '%s' is not a metadata provider", extensionID)
	}

	provider := NewExtensionProviderWrapper(ext)

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.getPlaylist === 'function') {
				return extension.getPlaylist(%q);
			}
			if (typeof extension !== 'undefined' && typeof extension.getAlbum === 'function') {
				return extension.getAlbum(%q);
			}
			return null;
		})()
	`, playlistID, playlistID)

	result, err := RunWithTimeoutAndRecover(provider.vm, script, DefaultJSTimeout)
	if err != nil {
		return "", fmt.Errorf("getPlaylist failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return "", fmt.Errorf("playlist not found")
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return "", fmt.Errorf("failed to marshal result: %w", err)
	}

	var album ExtAlbumMetadata
	if err := json.Unmarshal(jsonBytes, &album); err != nil {
		return "", fmt.Errorf("failed to parse playlist: %w", err)
	}
	album.ProviderID = ext.ID
	for i := range album.Tracks {
		album.Tracks[i].ProviderID = ext.ID
	}

	tracks := make([]map[string]interface{}, len(album.Tracks))
	for i, track := range album.Tracks {
		trackCover := track.ResolvedCoverURL()
		if trackCover == "" {
			trackCover = album.CoverURL
		}
		tracks[i] = map[string]interface{}{
			"id":           track.ID,
			"name":         track.Name,
			"artists":      track.Artists,
			"album_name":   track.AlbumName,
			"album_artist": track.AlbumArtist,
			"duration_ms":  track.DurationMS,
			"cover_url":    trackCover,
			"release_date": track.ReleaseDate,
			"track_number": track.TrackNumber,
			"disc_number":  track.DiscNumber,
			"isrc":         track.ISRC,
			"provider_id":  track.ProviderID,
			"item_type":    track.ItemType,
			"album_type":   track.AlbumType,
		}
	}

	response := map[string]interface{}{
		"id":           album.ID,
		"name":         album.Name,
		"owner":        album.Artists,
		"cover_url":    album.CoverURL,
		"total_tracks": album.TotalTracks,
		"tracks":       tracks,
		"provider_id":  album.ProviderID,
	}

	jsonBytes, err = json.Marshal(response)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetArtistWithExtensionJSON(extensionID, artistID string) (string, error) {
	manager := GetExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return "", err
	}

	if !ext.Manifest.IsMetadataProvider() {
		return "", fmt.Errorf("extension '%s' is not a metadata provider", extensionID)
	}

	provider := NewExtensionProviderWrapper(ext)
	artist, err := provider.GetArtist(artistID)
	if err != nil {
		return "", err
	}

	if artist == nil {
		return "", fmt.Errorf("artist not found")
	}

	albums := make([]map[string]interface{}, len(artist.Albums))
	for i, album := range artist.Albums {
		albums[i] = map[string]interface{}{
			"id":           album.ID,
			"name":         album.Name,
			"artists":      album.Artists,
			"cover_url":    album.CoverURL,
			"release_date": album.ReleaseDate,
			"total_tracks": album.TotalTracks,
			"album_type":   album.AlbumType,
			"provider_id":  album.ProviderID,
		}
	}

	response := map[string]interface{}{
		"id":          artist.ID,
		"name":        artist.Name,
		"cover_url":   artist.ImageURL,
		"albums":      albums,
		"provider_id": artist.ProviderID,
	}

	if artist.HeaderImage != "" {
		response["header_image"] = artist.HeaderImage
	}

	if artist.Listeners > 0 {
		response["listeners"] = artist.Listeners
	}

	if len(artist.TopTracks) > 0 {
		topTracks := make([]map[string]interface{}, len(artist.TopTracks))
		for i, track := range artist.TopTracks {
			topTracks[i] = map[string]interface{}{
				"id":           track.ID,
				"name":         track.Name,
				"artists":      track.Artists,
				"album_name":   track.AlbumName,
				"album_artist": track.AlbumArtist,
				"duration_ms":  track.DurationMS,
				"images":       track.ResolvedCoverURL(),
				"release_date": track.ReleaseDate,
				"track_number": track.TrackNumber,
				"disc_number":  track.DiscNumber,
				"isrc":         track.ISRC,
				"provider_id":  track.ProviderID,
				"spotify_id":   track.SpotifyID,
			}
		}
		response["top_tracks"] = topTracks
	}

	jsonBytes, err := json.Marshal(response)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetURLHandlersJSON() (string, error) {
	manager := GetExtensionManager()
	handlers := manager.GetURLHandlers()

	result := make([]map[string]interface{}, 0, len(handlers))
	for _, h := range handlers {
		result = append(result, map[string]interface{}{
			"id":           h.extension.ID,
			"display_name": h.extension.Manifest.DisplayName,
			"patterns":     h.extension.Manifest.URLHandler.Patterns,
		})
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

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

func RunPostProcessingV2JSON(inputJSON, metadataJSON string) (string, error) {
	var metadata map[string]interface{}
	if metadataJSON != "" {
		if err := json.Unmarshal([]byte(metadataJSON), &metadata); err != nil {
			metadata = make(map[string]interface{})
		}
	}

	var input PostProcessInput
	if inputJSON != "" {
		if err := json.Unmarshal([]byte(inputJSON), &input); err != nil {
			input = PostProcessInput{}
		}
	}

	manager := GetExtensionManager()
	result, err := manager.RunPostProcessingV2(input, metadata)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

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

func InitExtensionStoreJSON(cacheDir string) error {
	InitExtensionStore(cacheDir)
	return nil
}

func GetStoreExtensionsJSON(forceRefresh bool) (string, error) {
	store := GetExtensionStore()
	if store == nil {
		return "", fmt.Errorf("extension store not initialized")
	}

	if forceRefresh {
		store.FetchRegistry(true)
	}

	extensions, err := store.GetExtensionsWithStatus()
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(extensions)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func SearchStoreExtensionsJSON(query, category string) (string, error) {
	store := GetExtensionStore()
	if store == nil {
		return "", fmt.Errorf("extension store not initialized")
	}

	extensions, err := store.SearchExtensions(query, category)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(extensions)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetStoreCategoriesJSON() (string, error) {
	store := GetExtensionStore()
	if store == nil {
		return "", fmt.Errorf("extension store not initialized")
	}

	categories := store.GetCategories()
	jsonBytes, err := json.Marshal(categories)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func DownloadStoreExtensionJSON(extensionID, destDir string) (string, error) {
	store := GetExtensionStore()
	if store == nil {
		return "", fmt.Errorf("extension store not initialized")
	}

	destPath := fmt.Sprintf("%s/%s.spotiflac-ext", destDir, extensionID)
	err := store.DownloadExtension(extensionID, destPath)
	if err != nil {
		return "", err
	}

	return destPath, nil
}

func ClearStoreCacheJSON() error {
	store := GetExtensionStore()
	if store == nil {
		return fmt.Errorf("extension store not initialized")
	}

	store.ClearCache()
	return nil
}

func callExtensionFunctionJSON(extensionID, functionName string, timeout time.Duration) (string, error) {
	manager := GetExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return "", err
	}

	if !ext.Enabled {
		return "", fmt.Errorf("extension '%s' is disabled", extensionID)
	}

	provider := NewExtensionProviderWrapper(ext)

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.%s === 'function') {
				return extension.%s();
			}
			return null;
		})()
	`, functionName, functionName)

	result, err := RunWithTimeoutAndRecover(provider.vm, script, timeout)
	if err != nil {
		return "", fmt.Errorf("%s failed: %w", functionName, err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return "", fmt.Errorf("%s returned null", functionName)
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return "", fmt.Errorf("failed to marshal result: %w", err)
	}

	return string(jsonBytes), nil
}

func GetExtensionHomeFeedJSON(extensionID string) (string, error) {
	return callExtensionFunctionJSON(extensionID, "getHomeFeed", 60*time.Second)
}

func GetExtensionBrowseCategoriesJSON(extensionID string) (string, error) {
	return callExtensionFunctionJSON(extensionID, "getBrowseCategories", 30*time.Second)
}

// ==================== LOCAL LIBRARY SCANNING ====================

// SetLibraryCoverCacheDirJSON sets the directory for caching extracted cover art
func SetLibraryCoverCacheDirJSON(cacheDir string) {
	SetLibraryCoverCacheDir(cacheDir)
}

func ScanLibraryFolderJSON(folderPath string) (string, error) {
	return ScanLibraryFolder(folderPath)
}

func GetLibraryScanProgressJSON() string {
	return GetLibraryScanProgress()
}

func CancelLibraryScanJSON() {
	CancelLibraryScan()
}

func ReadAudioMetadataJSON(filePath string) (string, error) {
	return ReadAudioMetadata(filePath)
}
