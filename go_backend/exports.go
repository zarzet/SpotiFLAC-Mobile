// Package gobackend provides exported functions for gomobile binding
// These functions are the bridge between Flutter and Go backend
package gobackend

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
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
		if shouldTrySpotFetchFallback(err) {
			data, apiErr := GetSpotifyDataWithAPI(ctx, spotifyURL, DefaultSpotFetchAPIBaseURL)
			if apiErr == nil {
				jsonBytes, marshalErr := json.Marshal(data)
				if marshalErr != nil {
					return "", marshalErr
				}
				return string(jsonBytes), nil
			}
		}
		return "", err
	}
	data, err := client.GetFilteredData(ctx, spotifyURL, false, 0)
	if err != nil {
		if shouldTrySpotFetchFallback(err) {
			fallbackData, apiErr := GetSpotifyDataWithAPI(ctx, spotifyURL, DefaultSpotFetchAPIBaseURL)
			if apiErr == nil {
				jsonBytes, marshalErr := json.Marshal(fallbackData)
				if marshalErr != nil {
					return "", marshalErr
				}
				return string(jsonBytes), nil
			}
		}
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
	UseExtensions        bool   `json:"use_extensions,omitempty"`
	UseFallback          bool   `json:"use_fallback,omitempty"`
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
	DecryptionKey          string `json:"decryption_key,omitempty"`
}

type DownloadResult struct {
	FilePath      string
	BitDepth      int
	SampleRate    int
	Title         string
	Artist        string
	Album         string
	ReleaseDate   string
	TrackNumber   int
	DiscNumber    int
	ISRC          string
	Genre         string
	Label         string
	Copyright     string
	LyricsLRC     string
	DecryptionKey string
}

func buildDownloadSuccessResponse(
	req DownloadRequest,
	result DownloadResult,
	service string,
	message string,
	filePath string,
	alreadyExists bool,
) DownloadResponse {
	title := result.Title
	if title == "" {
		title = req.TrackName
	}

	artist := result.Artist
	if artist == "" {
		artist = req.ArtistName
	}

	album := result.Album
	if album == "" {
		album = req.AlbumName
	}

	releaseDate := result.ReleaseDate
	if releaseDate == "" {
		releaseDate = req.ReleaseDate
	}

	trackNumber := result.TrackNumber
	if trackNumber == 0 {
		trackNumber = req.TrackNumber
	}

	discNumber := result.DiscNumber
	if discNumber == 0 {
		discNumber = req.DiscNumber
	}

	isrc := result.ISRC
	if isrc == "" {
		isrc = req.ISRC
	}

	genre := result.Genre
	if genre == "" {
		genre = req.Genre
	}

	label := result.Label
	if label == "" {
		label = req.Label
	}

	copyright := result.Copyright
	if copyright == "" {
		copyright = req.Copyright
	}

	return DownloadResponse{
		Success:          true,
		Message:          message,
		FilePath:         filePath,
		AlreadyExists:    alreadyExists,
		ActualBitDepth:   result.BitDepth,
		ActualSampleRate: result.SampleRate,
		Service:          service,
		Title:            title,
		Artist:           artist,
		Album:            album,
		AlbumArtist:      req.AlbumArtist,
		ReleaseDate:      releaseDate,
		TrackNumber:      trackNumber,
		DiscNumber:       discNumber,
		ISRC:             isrc,
		CoverURL:         req.CoverURL,
		Genre:            genre,
		Label:            label,
		Copyright:        copyright,
		LyricsLRC:        result.LyricsLRC,
		DecryptionKey:    result.DecryptionKey,
	}
}

func shouldSkipQualityProbe(filePath string) bool {
	path := strings.TrimSpace(filePath)
	if path == "" {
		return true
	}
	if strings.HasPrefix(path, "/proc/self/fd/") {
		return true
	}
	// Content URI and other non-filesystem schemes cannot be read directly by os.Open.
	if strings.Contains(path, "://") {
		return true
	}
	return false
}

func enrichResultQualityFromFile(result *DownloadResult) {
	if result == nil {
		return
	}

	path := strings.TrimSpace(result.FilePath)
	if shouldSkipQualityProbe(path) {
		if strings.HasPrefix(path, "/proc/self/fd/") {
			LogDebug("Download", "Skipping quality probe for ephemeral SAF FD output: %s", path)
		}
		return
	}

	quality, qErr := GetAudioQuality(path)
	if qErr == nil {
		result.BitDepth = quality.BitDepth
		result.SampleRate = quality.SampleRate
		GoLog("[Download] Actual quality from file: %d-bit/%dHz\n", quality.BitDepth, quality.SampleRate)
		return
	}

	LogDebug("Download", "Post-download quality probe unavailable for %s: %v", path, qErr)
}

func enrichRequestExtendedMetadata(req *DownloadRequest) {
	if req == nil {
		return
	}

	if req.ISRC == "" || (req.Genre != "" && req.Label != "") {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	deezerClient := GetDeezerClient()
	extMeta, err := deezerClient.GetExtendedMetadataByISRC(ctx, req.ISRC)
	if err != nil || extMeta == nil {
		if err != nil {
			GoLog("[DownloadWithFallback] Failed to get extended metadata from Deezer: %v\n", err)
		}
		return
	}

	if req.Genre == "" && extMeta.Genre != "" {
		req.Genre = extMeta.Genre
	}
	if req.Label == "" && extMeta.Label != "" {
		req.Label = extMeta.Label
	}
	if req.Genre != "" || req.Label != "" {
		GoLog("[DownloadWithFallback] Extended metadata ready: genre=%s, label=%s\n", req.Genre, req.Label)
	}
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

	enrichRequestExtendedMetadata(&req)

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
				FilePath:      amazonResult.FilePath,
				BitDepth:      amazonResult.BitDepth,
				SampleRate:    amazonResult.SampleRate,
				Title:         amazonResult.Title,
				Artist:        amazonResult.Artist,
				Album:         amazonResult.Album,
				ReleaseDate:   amazonResult.ReleaseDate,
				TrackNumber:   amazonResult.TrackNumber,
				DiscNumber:    amazonResult.DiscNumber,
				ISRC:          amazonResult.ISRC,
				LyricsLRC:     amazonResult.LyricsLRC,
				DecryptionKey: amazonResult.DecryptionKey,
			}
		}
		err = amazonErr
	case "youtube":
		youtubeResult, youtubeErr := downloadFromYouTube(req)
		if youtubeErr == nil {
			result = DownloadResult{
				FilePath:    youtubeResult.FilePath,
				BitDepth:    0, // Lossy format, no bit depth
				SampleRate:  0, // Lossy format
				Title:       youtubeResult.Title,
				Artist:      youtubeResult.Artist,
				Album:       youtubeResult.Album,
				ReleaseDate: youtubeResult.ReleaseDate,
				TrackNumber: youtubeResult.TrackNumber,
				DiscNumber:  youtubeResult.DiscNumber,
				ISRC:        youtubeResult.ISRC,
				LyricsLRC:   youtubeResult.LyricsLRC,
			}
		}
		err = youtubeErr
	default:
		return errorResponse("Unknown service: " + req.Service)
	}

	if err != nil {
		return errorResponse(err.Error())
	}

	if len(result.FilePath) > 7 && result.FilePath[:7] == "EXISTS:" {
		actualPath := result.FilePath[7:]
		result.FilePath = actualPath
		enrichResultQualityFromFile(&result)
		resp := buildDownloadSuccessResponse(
			req,
			result,
			req.Service,
			"File already exists",
			actualPath,
			true,
		)
		jsonBytes, _ := json.Marshal(resp)
		return string(jsonBytes), nil
	}

	enrichResultQualityFromFile(&result)

	resp := buildDownloadSuccessResponse(
		req,
		result,
		req.Service,
		"Download complete",
		result.FilePath,
		false,
	)

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

// DownloadByStrategy routes a unified download request to the appropriate flow.
// Routing priority: YouTube service > extension fallback > built-in fallback > direct service.
func DownloadByStrategy(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return errorResponse("Invalid request: " + err.Error())
	}

	serviceRaw := strings.TrimSpace(req.Service)
	serviceNormalized := strings.ToLower(serviceRaw)

	normalizedReq := req
	if serviceNormalized == "youtube" || isBuiltInProvider(serviceNormalized) {
		normalizedReq.Service = serviceNormalized
	}

	normalizedBytes, err := json.Marshal(normalizedReq)
	if err != nil {
		return errorResponse("Invalid request: " + err.Error())
	}
	normalizedJSON := string(normalizedBytes)

	if serviceNormalized == "youtube" {
		return DownloadFromYouTube(normalizedJSON)
	}

	if req.UseExtensions {
		resp, err := DownloadWithExtensionsJSON(normalizedJSON)
		if err != nil {
			return errorResponse(err.Error())
		}
		return resp, nil
	}

	if req.UseFallback {
		return DownloadWithFallback(normalizedJSON)
	}

	return DownloadTrack(normalizedJSON)
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

	enrichRequestExtendedMetadata(&req)

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
					FilePath:      amazonResult.FilePath,
					BitDepth:      amazonResult.BitDepth,
					SampleRate:    amazonResult.SampleRate,
					Title:         amazonResult.Title,
					Artist:        amazonResult.Artist,
					Album:         amazonResult.Album,
					ReleaseDate:   amazonResult.ReleaseDate,
					TrackNumber:   amazonResult.TrackNumber,
					DiscNumber:    amazonResult.DiscNumber,
					ISRC:          amazonResult.ISRC,
					LyricsLRC:     amazonResult.LyricsLRC,
					DecryptionKey: amazonResult.DecryptionKey,
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
				result.FilePath = actualPath
				enrichResultQualityFromFile(&result)
				resp := buildDownloadSuccessResponse(
					req,
					result,
					service,
					"File already exists",
					actualPath,
					true,
				)
				jsonBytes, _ := json.Marshal(resp)
				return string(jsonBytes), nil
			}

			enrichResultQualityFromFile(&result)

			resp := buildDownloadSuccessResponse(
				req,
				result,
				service,
				"Downloaded from "+service,
				result.FilePath,
				false,
			)
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
	lower := strings.ToLower(filePath)
	isFlac := strings.HasSuffix(lower, ".flac")
	isMp3 := strings.HasSuffix(lower, ".mp3")
	isOgg := strings.HasSuffix(lower, ".opus") || strings.HasSuffix(lower, ".ogg")

	result := map[string]interface{}{
		"title":        "",
		"artist":       "",
		"album":        "",
		"album_artist": "",
		"date":         "",
		"track_number": 0,
		"disc_number":  0,
		"isrc":         "",
		"lyrics":       "",
		"genre":        "",
		"label":        "",
		"copyright":    "",
		"composer":     "",
		"comment":      "",
		"duration":     0,
	}

	if isFlac {
		metadata, err := ReadMetadata(filePath)
		if err != nil {
			return "", fmt.Errorf("failed to read metadata: %w", err)
		}
		result["title"] = metadata.Title
		result["artist"] = metadata.Artist
		result["album"] = metadata.Album
		result["album_artist"] = metadata.AlbumArtist
		result["date"] = metadata.Date
		result["track_number"] = metadata.TrackNumber
		result["disc_number"] = metadata.DiscNumber
		result["isrc"] = metadata.ISRC
		result["lyrics"] = metadata.Lyrics
		result["genre"] = metadata.Genre
		result["label"] = metadata.Label
		result["copyright"] = metadata.Copyright
		result["composer"] = metadata.Composer
		result["comment"] = metadata.Comment

		quality, qualityErr := GetAudioQuality(filePath)
		if qualityErr == nil {
			result["bit_depth"] = quality.BitDepth
			result["sample_rate"] = quality.SampleRate
			if quality.SampleRate > 0 && quality.TotalSamples > 0 {
				result["duration"] = int(quality.TotalSamples / int64(quality.SampleRate))
			}
		}
	} else if isMp3 {
		meta, err := ReadID3Tags(filePath)
		if err == nil && meta != nil {
			result["title"] = meta.Title
			result["artist"] = meta.Artist
			result["album"] = meta.Album
			result["album_artist"] = meta.AlbumArtist
			result["date"] = meta.Date
			if meta.Date == "" {
				result["date"] = meta.Year
			}
			result["track_number"] = meta.TrackNumber
			result["disc_number"] = meta.DiscNumber
			result["isrc"] = meta.ISRC
			result["lyrics"] = meta.Lyrics
			result["genre"] = meta.Genre
			result["composer"] = meta.Composer
			result["comment"] = meta.Comment
		}
		quality, qualityErr := GetMP3Quality(filePath)
		if qualityErr == nil {
			result["bit_depth"] = quality.BitDepth
			result["sample_rate"] = quality.SampleRate
			result["duration"] = quality.Duration
		}
	} else if isOgg {
		meta, err := ReadOggVorbisComments(filePath)
		if err == nil && meta != nil {
			result["title"] = meta.Title
			result["artist"] = meta.Artist
			result["album"] = meta.Album
			result["album_artist"] = meta.AlbumArtist
			result["date"] = meta.Date
			if meta.Date == "" {
				result["date"] = meta.Year
			}
			result["track_number"] = meta.TrackNumber
			result["disc_number"] = meta.DiscNumber
			result["isrc"] = meta.ISRC
			result["lyrics"] = meta.Lyrics
			result["genre"] = meta.Genre
			result["composer"] = meta.Composer
			result["comment"] = meta.Comment
		}
		quality, qualityErr := GetOggQuality(filePath)
		if qualityErr == nil {
			result["sample_rate"] = quality.SampleRate
			result["duration"] = quality.Duration
		}
	} else {
		return "", fmt.Errorf("unsupported file format: %s", filePath)
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// EditFileMetadata writes metadata to an audio file.
// For FLAC files, uses native Go FLAC library.
// For MP3/Opus, returns the metadata map so Dart can use FFmpeg.
func EditFileMetadata(filePath, metadataJSON string) (string, error) {
	var fields map[string]string
	if err := json.Unmarshal([]byte(metadataJSON), &fields); err != nil {
		return "", fmt.Errorf("invalid metadata JSON: %w", err)
	}

	lower := strings.ToLower(filePath)
	isFlac := strings.HasSuffix(lower, ".flac")
	coverPath := strings.TrimSpace(fields["cover_path"])

	if isFlac {
		trackNum := 0
		discNum := 0
		if v, ok := fields["track_number"]; ok && v != "" {
			fmt.Sscanf(v, "%d", &trackNum)
		}
		if v, ok := fields["disc_number"]; ok && v != "" {
			fmt.Sscanf(v, "%d", &discNum)
		}

		meta := Metadata{
			Title:       fields["title"],
			Artist:      fields["artist"],
			Album:       fields["album"],
			AlbumArtist: fields["album_artist"],
			Date:        fields["date"],
			TrackNumber: trackNum,
			DiscNumber:  discNum,
			ISRC:        fields["isrc"],
			Genre:       fields["genre"],
			Label:       fields["label"],
			Copyright:   fields["copyright"],
			Composer:    fields["composer"],
			Comment:     fields["comment"],
		}

		if err := EmbedMetadata(filePath, meta, coverPath); err != nil {
			return "", fmt.Errorf("failed to write FLAC metadata: %w", err)
		}

		resp := map[string]any{
			"success": true,
			"method":  "native",
		}
		jsonBytes, _ := json.Marshal(resp)
		return string(jsonBytes), nil
	}

	// MP3/Opus: return metadata for Dart-side FFmpeg embedding
	resp := map[string]any{
		"success": true,
		"method":  "ffmpeg",
		"fields":  fields,
	}
	jsonBytes, _ := json.Marshal(resp)
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

func GetLyricsLRCWithSource(spotifyID, trackName, artistName string, filePath string, durationMs int64) (string, error) {
	if filePath != "" {
		lyrics, err := ExtractLyrics(filePath)
		if err == nil && lyrics != "" {
			result := map[string]interface{}{
				"lyrics":       lyrics,
				"source":       "Embedded",
				"sync_type":    "EMBEDDED",
				"instrumental": false,
			}
			jsonBytes, err := json.Marshal(result)
			if err != nil {
				return "", err
			}
			return string(jsonBytes), nil
		}

		result := map[string]interface{}{
			"lyrics":       "",
			"source":       "",
			"sync_type":    "",
			"instrumental": false,
		}
		jsonBytes, err := json.Marshal(result)
		if err != nil {
			return "", err
		}
		return string(jsonBytes), nil
	}

	client := NewLyricsClient()
	durationSec := float64(durationMs) / 1000.0
	lyricsData, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName, durationSec)
	if err != nil {
		return "", err
	}

	lrcContent := ""
	if lyricsData.Instrumental {
		lrcContent = "[instrumental:true]"
	} else {
		lrcContent = convertToLRCWithMetadata(lyricsData, trackName, artistName)
	}

	result := map[string]interface{}{
		"lyrics":       lrcContent,
		"source":       lyricsData.Source,
		"sync_type":    lyricsData.SyncType,
		"instrumental": lyricsData.Instrumental,
	}
	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
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

	var spotifyErr error

	client, err := NewSpotifyMetadataClient()
	if err != nil {
		LogWarn("Spotify", "Credentials not configured, falling back to Deezer")
		spotifyErr = err
	} else {
		data, err := client.GetFilteredData(ctx, spotifyURL, false, 0)
		if err == nil {
			jsonBytes, err := json.Marshal(data)
			if err != nil {
				return "", err
			}
			return string(jsonBytes), nil
		}

		spotifyErr = err
		if !shouldTrySpotFetchFallback(err) {
			return "", err
		}
	}

	spotFetchData, apiErr := GetSpotifyDataWithAPI(ctx, spotifyURL, DefaultSpotFetchAPIBaseURL)
	if apiErr == nil {
		GoLog("[Fallback] Spotify metadata fetched via SpotFetch API\n")
		jsonBytes, err := json.Marshal(spotFetchData)
		if err != nil {
			return "", err
		}
		return string(jsonBytes), nil
	}
	GoLog("[Fallback] SpotFetch API fallback failed: %v\n", apiErr)

	parsed, parseErr := parseSpotifyURI(spotifyURL)
	if parseErr != nil {
		if spotifyErr != nil {
			return "", fmt.Errorf("spotify failed (%v), SpotFetch fallback failed (%v), and URL parsing failed: %w", spotifyErr, apiErr, parseErr)
		}
		return "", fmt.Errorf("SpotFetch fallback failed (%v) and URL parsing failed: %w", apiErr, parseErr)
	}

	GoLog("[Fallback] Trying Deezer conversion fallback for %s...\n", parsed.Type)

	if parsed.Type == "track" || parsed.Type == "album" {
		return ConvertSpotifyToDeezer(parsed.Type, parsed.ID)
	}

	if parsed.Type == "artist" {
		if spotifyErr != nil {
			return "", fmt.Errorf("spotify metadata unavailable (%v) and SpotFetch fallback failed (%v). Artist pages require Spotify/SpotFetch API", spotifyErr, apiErr)
		}
		return "", fmt.Errorf("SpotFetch fallback failed (%v). Artist pages require Spotify/SpotFetch API", apiErr)
	}

	if spotifyErr != nil {
		return "", fmt.Errorf("spotify metadata unavailable (%v), SpotFetch fallback failed (%v), and Deezer conversion is unavailable for playlists", spotifyErr, apiErr)
	}
	return "", fmt.Errorf("SpotFetch fallback failed (%v), and Deezer conversion is unavailable for playlists", apiErr)
}

func shouldTrySpotFetchFallback(err error) bool {
	if err == nil {
		return false
	}
	if errors.Is(err, ErrNoSpotifyCredentials) {
		return true
	}

	errStr := strings.ToLower(err.Error())
	indicators := []string{
		"429",
		"rate",
		"limit",
		"403",
		"forbidden",
		"401",
		"unauthorized",
		"timeout",
		"connection",
		"spotify error",
		"access token",
		"client token",
		"eof",
	}

	for _, indicator := range indicators {
		if strings.Contains(errStr, indicator) {
			return true
		}
	}
	return false
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

// ==================== YOUTUBE PROVIDER (LOSSY ONLY) ====================

// DownloadFromYouTube downloads a track from YouTube via Cobalt API
// This is a lossy-only provider (Opus 256kbps or MP3 320kbps)
// It does NOT participate in the lossless fallback chain
func DownloadFromYouTube(requestJSON string) (string, error) {
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

	youtubeResult, err := downloadFromYouTube(req)
	if err != nil {
		return errorResponse(err.Error())
	}

	resp := DownloadResponse{
		Success:     true,
		Message:     "Downloaded from YouTube",
		FilePath:    youtubeResult.FilePath,
		Service:     "youtube",
		Title:       youtubeResult.Title,
		Artist:      youtubeResult.Artist,
		Album:       youtubeResult.Album,
		ReleaseDate: youtubeResult.ReleaseDate,
		TrackNumber: youtubeResult.TrackNumber,
		DiscNumber:  youtubeResult.DiscNumber,
		ISRC:        youtubeResult.ISRC,
		LyricsLRC:   youtubeResult.LyricsLRC,
		CoverURL:    req.CoverURL,
		Genre:       req.Genre,
		Label:       req.Label,
		Copyright:   req.Copyright,
	}

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

// IsYouTubeURLExport checks if a URL is a YouTube URL (exported for Flutter)
func IsYouTubeURLExport(urlStr string) bool {
	return IsYouTubeURL(urlStr)
}

// ExtractYouTubeVideoIDExport extracts video ID from YouTube URL (exported for Flutter)
func ExtractYouTubeVideoIDExport(urlStr string) (string, error) {
	return ExtractYouTubeVideoID(urlStr)
}

// ==================== COVER & LYRICS SAVE ====================

// DownloadCoverToFile downloads cover art from URL and saves to outputPath.
// If maxQuality is true, upgrades to highest available resolution.
func DownloadCoverToFile(coverURL string, outputPath string, maxQuality bool) error {
	if coverURL == "" {
		return fmt.Errorf("no cover URL provided")
	}

	data, err := downloadCoverToMemory(coverURL, maxQuality)
	if err != nil {
		return fmt.Errorf("failed to download cover: %w", err)
	}

	if err := os.WriteFile(outputPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write cover file: %w", err)
	}

	GoLog("[Cover] Saved cover art to: %s (%d KB)\n", outputPath, len(data)/1024)
	return nil
}

// ExtractCoverToFile extracts embedded cover art from audio file and saves to outputPath.
func ExtractCoverToFile(audioPath string, outputPath string) error {
	lower := strings.ToLower(audioPath)

	var coverData []byte
	var err error

	if strings.HasSuffix(lower, ".flac") {
		coverData, err = ExtractCoverArt(audioPath)
	} else if strings.HasSuffix(lower, ".mp3") {
		coverData, _, err = extractMP3CoverArt(audioPath)
	} else if strings.HasSuffix(lower, ".opus") || strings.HasSuffix(lower, ".ogg") {
		coverData, _, err = extractOggCoverArt(audioPath)
	} else {
		return fmt.Errorf("unsupported audio format for cover extraction")
	}

	if err != nil {
		return fmt.Errorf("failed to extract cover: %w", err)
	}

	if err := os.WriteFile(outputPath, coverData, 0644); err != nil {
		return fmt.Errorf("failed to write cover file: %w", err)
	}

	GoLog("[Cover] Extracted cover art to: %s (%d KB)\n", outputPath, len(coverData)/1024)
	return nil
}

// FetchAndSaveLyrics fetches lyrics from lrclib and saves as .lrc file.
func FetchAndSaveLyrics(trackName, artistName, spotifyID string, durationMs int64, outputPath string) error {
	client := NewLyricsClient()
	durationSec := float64(durationMs) / 1000.0

	lyrics, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName, durationSec)
	if err != nil {
		return fmt.Errorf("lyrics not found: %w", err)
	}

	if lyrics.Instrumental {
		return fmt.Errorf("track is instrumental, no lyrics available")
	}

	lrcContent := convertToLRCWithMetadata(lyrics, trackName, artistName)
	if lrcContent == "" {
		return fmt.Errorf("failed to generate LRC content")
	}

	if err := os.WriteFile(outputPath, []byte(lrcContent), 0644); err != nil {
		return fmt.Errorf("failed to write LRC file: %w", err)
	}

	GoLog("[Lyrics] Saved LRC to: %s (%d lines)\n", outputPath, len(lyrics.Lines))
	return nil
}

// ==================== LYRICS PROVIDER SETTINGS ====================

// SetLyricsProvidersJSON sets the lyrics provider order from a JSON array of provider IDs.
func SetLyricsProvidersJSON(providersJSON string) error {
	var providers []string
	if err := json.Unmarshal([]byte(providersJSON), &providers); err != nil {
		return err
	}

	SetLyricsProviderOrder(providers)
	return nil
}

// GetLyricsProvidersJSON returns the current lyrics provider order as JSON.
func GetLyricsProvidersJSON() (string, error) {
	providers := GetLyricsProviderOrder()
	jsonBytes, err := json.Marshal(providers)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

// GetAvailableLyricsProvidersJSON returns metadata about all available lyrics providers.
func GetAvailableLyricsProvidersJSON() (string, error) {
	providers := GetAvailableLyricsProviders()
	jsonBytes, err := json.Marshal(providers)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

// SetLyricsFetchOptionsJSON sets lyrics provider fetch options.
func SetLyricsFetchOptionsJSON(optionsJSON string) error {
	opts := GetLyricsFetchOptions()
	if strings.TrimSpace(optionsJSON) != "" {
		if err := json.Unmarshal([]byte(optionsJSON), &opts); err != nil {
			return err
		}
	}

	SetLyricsFetchOptions(opts)
	return nil
}

// GetLyricsFetchOptionsJSON returns current lyrics provider fetch options.
func GetLyricsFetchOptionsJSON() (string, error) {
	opts := GetLyricsFetchOptions()
	jsonBytes, err := json.Marshal(opts)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

// ReEnrichFile re-embeds metadata, cover art, and lyrics into an existing audio file.
// When search_online is true, searches Spotify/Deezer by track name + artist to fetch
// complete metadata from the internet before embedding.
func ReEnrichFile(requestJSON string) (string, error) {
	var req struct {
		FilePath     string `json:"file_path"`
		CoverURL     string `json:"cover_url"`
		MaxQuality   bool   `json:"max_quality"`
		EmbedLyrics  bool   `json:"embed_lyrics"`
		SpotifyID    string `json:"spotify_id"`
		TrackName    string `json:"track_name"`
		ArtistName   string `json:"artist_name"`
		AlbumName    string `json:"album_name"`
		AlbumArtist  string `json:"album_artist"`
		TrackNumber  int    `json:"track_number"`
		DiscNumber   int    `json:"disc_number"`
		ReleaseDate  string `json:"release_date"`
		ISRC         string `json:"isrc"`
		Genre        string `json:"genre"`
		Label        string `json:"label"`
		Copyright    string `json:"copyright"`
		DurationMs   int64  `json:"duration_ms"`
		SearchOnline bool   `json:"search_online"`
	}

	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return "", fmt.Errorf("failed to parse request: %w", err)
	}

	if req.FilePath == "" {
		return "", fmt.Errorf("file_path is required")
	}

	GoLog("[ReEnrich] Starting re-enrichment for: %s\n", req.FilePath)

	// When search_online is true, search for metadata from internet
	// Priority: 1) Deezer (reliable, no credentials) 2) Extension providers (spotify-web etc) 3) Spotify built-in API (last resort, deprecated)
	if req.SearchOnline && req.TrackName != "" && req.ArtistName != "" {
		GoLog("[ReEnrich] Searching online metadata for: %s - %s\n", req.TrackName, req.ArtistName)
		searchQuery := req.TrackName + " " + req.ArtistName
		found := false

		// 1) Try Deezer first (reliable, no credentials needed)
		GoLog("[ReEnrich] Trying Deezer search...\n")
		deezerClient := GetDeezerClient()
		{
			ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
			deezerResults, err := deezerClient.SearchAll(ctx, searchQuery, 5, 0, "track")
			cancel()
			if err == nil && len(deezerResults.Tracks) > 0 {
				track := deezerResults.Tracks[0]
				GoLog("[ReEnrich] Deezer match: %s - %s (album: %s)\n", track.Name, track.Artists, track.AlbumName)
				req.SpotifyID = "deezer:" + track.SpotifyID
				req.AlbumName = track.AlbumName
				req.AlbumArtist = track.AlbumArtist
				req.TrackNumber = track.TrackNumber
				req.DiscNumber = track.DiscNumber
				req.ReleaseDate = track.ReleaseDate
				req.ISRC = track.ISRC
				if track.Images != "" {
					req.CoverURL = track.Images
				}
				req.DurationMs = int64(track.DurationMS)
				found = true
			} else if err != nil {
				GoLog("[ReEnrich] Deezer search failed: %v\n", err)
			}
		}

		// 2) Try extension metadata providers (spotify-web etc) if Deezer failed
		if !found {
			GoLog("[ReEnrich] Trying extension metadata providers...\n")
			manager := GetExtensionManager()
			extTracks, extErr := manager.SearchTracksWithExtensions(searchQuery, 5)
			if extErr == nil && len(extTracks) > 0 {
				track := extTracks[0]
				GoLog("[ReEnrich] Extension match (%s): %s - %s (album: %s)\n", track.ProviderID, track.Name, track.Artists, track.AlbumName)
				if track.SpotifyID != "" {
					req.SpotifyID = track.SpotifyID
				} else if track.DeezerID != "" {
					req.SpotifyID = "deezer:" + track.DeezerID
				} else {
					req.SpotifyID = track.ID
				}
				req.AlbumName = track.AlbumName
				req.AlbumArtist = track.AlbumArtist
				req.TrackNumber = track.TrackNumber
				req.DiscNumber = track.DiscNumber
				req.ReleaseDate = track.ReleaseDate
				req.ISRC = track.ISRC
				coverURL := track.ResolvedCoverURL()
				if coverURL != "" {
					req.CoverURL = coverURL
				}
				req.DurationMs = int64(track.DurationMS)
				if track.Genre != "" {
					req.Genre = track.Genre
				}
				if track.Label != "" {
					req.Label = track.Label
				}
				if track.Copyright != "" {
					req.Copyright = track.Copyright
				}
				found = true
			} else if extErr != nil {
				GoLog("[ReEnrich] Extension search failed: %v\n", extErr)
			}
		}

		// 3) Try Spotify built-in API as last resort (will be deprecated)
		if !found {
			GoLog("[ReEnrich] Trying Spotify API (fallback)...\n")
			spotifyClient, spotifyErr := NewSpotifyMetadataClient()
			if spotifyErr == nil {
				ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
				results, err := spotifyClient.SearchTracks(ctx, searchQuery, 5)
				cancel()
				if err == nil && len(results.Tracks) > 0 {
					track := results.Tracks[0]
					GoLog("[ReEnrich] Spotify match: %s - %s (album: %s)\n", track.Name, track.Artists, track.AlbumName)
					req.SpotifyID = track.SpotifyID
					req.AlbumName = track.AlbumName
					req.AlbumArtist = track.AlbumArtist
					req.TrackNumber = track.TrackNumber
					req.DiscNumber = track.DiscNumber
					req.ReleaseDate = track.ReleaseDate
					req.ISRC = track.ISRC
					if track.Images != "" {
						req.CoverURL = track.Images
					}
					req.DurationMs = int64(track.DurationMS)
					found = true
				} else if err != nil {
					GoLog("[ReEnrich] Spotify search failed: %v\n", err)
				}
			} else {
				GoLog("[ReEnrich] Spotify client unavailable: %v\n", spotifyErr)
			}
		}

		// Try to get extended metadata (genre, label) from Deezer if not already set
		if found && req.ISRC != "" && (req.Genre == "" || req.Label == "") {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			extMeta, err := deezerClient.GetExtendedMetadataByISRC(ctx, req.ISRC)
			cancel()
			if err == nil && extMeta != nil {
				if req.Genre == "" && extMeta.Genre != "" {
					req.Genre = extMeta.Genre
				}
				if req.Label == "" && extMeta.Label != "" {
					req.Label = extMeta.Label
				}
				GoLog("[ReEnrich] Extended metadata: genre=%s, label=%s\n", req.Genre, req.Label)
			}
		}

		if !found {
			GoLog("[ReEnrich] No online match found, using existing metadata\n")
		}
	}

	// Log metadata summary before embedding
	GoLog("[ReEnrich] Metadata to embed: title=%s, artist=%s, album=%s, albumArtist=%s\n",
		req.TrackName, req.ArtistName, req.AlbumName, req.AlbumArtist)
	GoLog("[ReEnrich] track=%d, disc=%d, date=%s, isrc=%s, genre=%s, label=%s\n",
		req.TrackNumber, req.DiscNumber, req.ReleaseDate, req.ISRC, req.Genre, req.Label)

	lower := strings.ToLower(req.FilePath)
	isFlac := strings.HasSuffix(lower, ".flac")

	// Download cover art to temp file
	var coverTempPath string
	var coverDataBytes []byte
	if req.CoverURL != "" {
		coverData, err := downloadCoverToMemory(req.CoverURL, req.MaxQuality)
		if err != nil {
			GoLog("[ReEnrich] Failed to download cover: %v\n", err)
		} else {
			coverDataBytes = coverData
			GoLog("[ReEnrich] Cover downloaded: %d KB\n", len(coverData)/1024)
			// MP3/Opus requires a real image file path for Dart FFmpeg.
			// FLAC uses in-memory embed and does not require temp files.
			if !isFlac {
				tmpFile, err := os.CreateTemp("", "reenrich_cover_*.jpg")
				if err != nil {
					fallbackDir := filepath.Dir(req.FilePath)
					if fallbackDir == "" || fallbackDir == "." {
						GoLog("[ReEnrich] Failed to create cover temp file: %v\n", err)
					} else {
						tmpFile, err = os.CreateTemp(fallbackDir, "reenrich_cover_*.jpg")
						if err != nil {
							GoLog("[ReEnrich] Failed to create cover temp file (fallback dir %s): %v\n", fallbackDir, err)
						}
					}
				}
				if err == nil && tmpFile != nil {
					coverTempPath = tmpFile.Name()
					if _, writeErr := tmpFile.Write(coverData); writeErr != nil {
						GoLog("[ReEnrich] Failed writing cover temp file: %v\n", writeErr)
						tmpFile.Close()
						os.Remove(coverTempPath)
						coverTempPath = ""
					} else if closeErr := tmpFile.Close(); closeErr != nil {
						GoLog("[ReEnrich] Failed closing cover temp file: %v\n", closeErr)
						os.Remove(coverTempPath)
						coverTempPath = ""
					}
				}
			}
		}
	}
	// Only cleanup cover temp for FLAC (native embed).
	// For MP3/Opus, Dart needs the file for FFmpeg — Dart handles cleanup.
	cleanupCover := true

	defer func() {
		if cleanupCover && coverTempPath != "" {
			os.Remove(coverTempPath)
		}
	}()

	// Fetch lyrics
	var lyricsLRC string
	if req.EmbedLyrics {
		client := NewLyricsClient()
		durationSec := float64(req.DurationMs) / 1000.0
		lyrics, err := client.FetchLyricsAllSources(req.SpotifyID, req.TrackName, req.ArtistName, durationSec)
		if err != nil {
			GoLog("[ReEnrich] Lyrics not found: %v\n", err)
		} else if !lyrics.Instrumental {
			lyricsLRC = convertToLRCWithMetadata(lyrics, req.TrackName, req.ArtistName)
			GoLog("[ReEnrich] Lyrics fetched: %d lines\n", len(lyrics.Lines))
		} else {
			GoLog("[ReEnrich] Track is instrumental\n")
		}
	}

	// Build enriched metadata response for Dart (includes online search results)
	enrichedMeta := map[string]interface{}{
		"track_name":   req.TrackName,
		"artist_name":  req.ArtistName,
		"album_name":   req.AlbumName,
		"album_artist": req.AlbumArtist,
		"release_date": req.ReleaseDate,
		"track_number": req.TrackNumber,
		"disc_number":  req.DiscNumber,
		"isrc":         req.ISRC,
		"genre":        req.Genre,
		"label":        req.Label,
		"copyright":    req.Copyright,
		"cover_url":    req.CoverURL,
		"spotify_id":   req.SpotifyID,
		"duration_ms":  req.DurationMs,
	}

	if isFlac {
		// Native Go FLAC metadata embedding
		metadata := Metadata{
			Title:       req.TrackName,
			Artist:      req.ArtistName,
			Album:       req.AlbumName,
			AlbumArtist: req.AlbumArtist,
			Date:        req.ReleaseDate,
			TrackNumber: req.TrackNumber,
			DiscNumber:  req.DiscNumber,
			ISRC:        req.ISRC,
			Genre:       req.Genre,
			Label:       req.Label,
			Copyright:   req.Copyright,
			Lyrics:      lyricsLRC,
		}

		if len(coverDataBytes) > 0 {
			if err := EmbedMetadataWithCoverData(req.FilePath, metadata, coverDataBytes); err != nil {
				return "", fmt.Errorf("failed to embed metadata with cover: %w", err)
			}
		} else {
			if err := EmbedMetadata(req.FilePath, metadata, ""); err != nil {
				return "", fmt.Errorf("failed to embed metadata: %w", err)
			}
		}
		if len(coverDataBytes) > 0 {
			embeddedCover, err := ExtractCoverArt(req.FilePath)
			if err != nil || len(embeddedCover) == 0 {
				if err != nil {
					return "", fmt.Errorf("metadata embedded but cover verification failed: %w", err)
				}
				return "", fmt.Errorf("metadata embedded but cover verification failed: empty embedded cover")
			}
			GoLog("[ReEnrich] Cover verified after embed (%d bytes)\n", len(embeddedCover))
		}

		GoLog("[ReEnrich] FLAC metadata embedded successfully\n")

		result := map[string]interface{}{
			"method":            "native",
			"success":           true,
			"enriched_metadata": enrichedMeta,
		}
		jsonBytes, _ := json.Marshal(result)
		return string(jsonBytes), nil
	}

	// MP3/Opus: return metadata map for Dart to use FFmpeg
	// Don't cleanup cover temp — Dart needs it for FFmpeg embed
	cleanupCover = false
	result := map[string]interface{}{
		"method":            "ffmpeg",
		"cover_path":        coverTempPath,
		"lyrics":            lyricsLRC,
		"enriched_metadata": enrichedMeta,
		"metadata": map[string]string{
			"TITLE":       req.TrackName,
			"ARTIST":      req.ArtistName,
			"ALBUM":       req.AlbumName,
			"ALBUMARTIST": req.AlbumArtist,
			"DATE":        req.ReleaseDate,
			"ISRC":        req.ISRC,
			"GENRE":       req.Genre,
		},
	}
	if req.TrackNumber > 0 {
		result["metadata"].(map[string]string)["TRACKNUMBER"] = fmt.Sprintf("%d", req.TrackNumber)
	}
	if req.DiscNumber > 0 {
		result["metadata"].(map[string]string)["DISCNUMBER"] = fmt.Sprintf("%d", req.DiscNumber)
	}
	if req.Label != "" {
		result["metadata"].(map[string]string)["ORGANIZATION"] = req.Label
	}
	if req.Copyright != "" {
		result["metadata"].(map[string]string)["COPYRIGHT"] = req.Copyright
	}
	if lyricsLRC != "" {
		result["metadata"].(map[string]string)["LYRICS"] = lyricsLRC
		result["metadata"].(map[string]string)["UNSYNCEDLYRICS"] = lyricsLRC
	}

	jsonBytes, _ := json.Marshal(result)
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

func buildStoreExtensionDestPath(destDir, extensionID string) (string, error) {
	if strings.TrimSpace(extensionID) == "" {
		return "", fmt.Errorf("invalid extension id")
	}

	safeExtensionID := sanitizeFilename(extensionID)
	return filepath.Join(destDir, safeExtensionID+".spotiflac-ext"), nil
}

func DownloadStoreExtensionJSON(extensionID, destDir string) (string, error) {
	store := GetExtensionStore()
	if store == nil {
		return "", fmt.Errorf("extension store not initialized")
	}

	destPath, err := buildStoreExtensionDestPath(destDir, extensionID)
	if err != nil {
		return "", err
	}
	err = store.DownloadExtension(extensionID, destPath)
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

// ScanLibraryFolderIncrementalJSON performs an incremental library scan
// existingFilesJSON: JSON object mapping filePath -> modTime (unix millis)
// Returns IncrementalScanResult as JSON
func ScanLibraryFolderIncrementalJSON(folderPath, existingFilesJSON string) (string, error) {
	return ScanLibraryFolderIncremental(folderPath, existingFilesJSON)
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
