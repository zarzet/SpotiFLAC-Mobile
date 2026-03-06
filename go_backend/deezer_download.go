package gobackend

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

const deezerYoinkifyURL = "https://yoinkify.lol/api/download"
const deezerMusicDLURL = "https://www.musicdl.me/api/download"

type YoinkifyRequest struct {
	URL         string `json:"url"`
	Format      string `json:"format"`
	GenreSource string `json:"genreSource"`
}

type DeezerDownloadResult struct {
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

func resolveSpotifyURLForYoinkify(req DownloadRequest) (string, error) {
	rawSpotify := strings.TrimSpace(req.SpotifyID)
	if rawSpotify != "" {
		if isLikelySpotifyTrackID(rawSpotify) {
			return fmt.Sprintf("https://open.spotify.com/track/%s", rawSpotify), nil
		}

		if parsed, err := parseSpotifyURI(rawSpotify); err == nil && parsed.Type == "track" && parsed.ID != "" {
			return fmt.Sprintf("https://open.spotify.com/track/%s", parsed.ID), nil
		}
	}

	deezerID := strings.TrimSpace(req.DeezerID)
	if deezerID == "" {
		if prefixed, found := strings.CutPrefix(rawSpotify, "deezer:"); found {
			deezerID = strings.TrimSpace(prefixed)
		}
	}

	if deezerID != "" {
		songlink := NewSongLinkClient()
		spotifyID, err := songlink.GetSpotifyIDFromDeezer(deezerID)
		if err != nil {
			return "", fmt.Errorf("failed to map deezer:%s to Spotify ID: %w", deezerID, err)
		}
		spotifyID = strings.TrimSpace(spotifyID)
		if spotifyID == "" {
			return "", fmt.Errorf("SongLink returned empty Spotify ID for deezer:%s", deezerID)
		}
		return fmt.Sprintf("https://open.spotify.com/track/%s", spotifyID), nil
	}

	return "", fmt.Errorf("missing Spotify track ID for Deezer Yoinkify")
}

func isLikelySpotifyTrackID(value string) bool {
	if len(value) != 22 {
		return false
	}
	for _, r := range value {
		switch {
		case r >= 'A' && r <= 'Z':
		case r >= 'a' && r <= 'z':
		case r >= '0' && r <= '9':
		default:
			return false
		}
	}
	return true
}

func (c *DeezerClient) DownloadFromYoinkify(spotifyURL, outputPath string, outputFD int, itemID string) error {
	payload := YoinkifyRequest{
		URL:         spotifyURL,
		Format:      "flac",
		GenreSource: "spotify",
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to encode Yoinkify request: %w", err)
	}

	ctx := context.Background()
	if itemID != "" {
		StartItemProgress(itemID)
		defer CompleteItemProgress(itemID)
		ctx = initDownloadCancel(itemID)
		defer clearDownloadCancel(itemID)
	}

	if isDownloadCancelled(itemID) {
		return ErrDownloadCancelled
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, deezerYoinkifyURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create Yoinkify request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "*/*")
	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return fmt.Errorf("failed to call Yoinkify: %w", err)
	}
	defer resp.Body.Close()

	contentType := strings.ToLower(strings.TrimSpace(resp.Header.Get("Content-Type")))
	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		bodyText := strings.TrimSpace(string(bodyBytes))
		if bodyText != "" {
			return fmt.Errorf("Yoinkify returned status %d: %s", resp.StatusCode, bodyText)
		}
		return fmt.Errorf("Yoinkify returned status %d", resp.StatusCode)
	}

	if strings.Contains(contentType, "application/json") {
		bodyBytes, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		bodyText := strings.TrimSpace(string(bodyBytes))
		if bodyText == "" {
			bodyText = "empty JSON payload"
		}
		return fmt.Errorf("Yoinkify returned JSON instead of audio: %s", bodyText)
	}

	expectedSize := resp.ContentLength
	if expectedSize > 0 && itemID != "" {
		SetItemBytesTotal(itemID, expectedSize)
	}

	out, err := openOutputForWrite(outputPath, outputFD)
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

	flushErr := bufWriter.Flush()
	closeErr := out.Close()

	if err != nil {
		cleanupOutputOnError(outputPath, outputFD)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return fmt.Errorf("download interrupted: %w", err)
	}
	if flushErr != nil {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("failed to flush output: %w", flushErr)
	}
	if closeErr != nil {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("failed to close output: %w", closeErr)
	}

	if expectedSize > 0 && written != expectedSize {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
	}

	GoLog("[Deezer] Downloaded via Yoinkify: %.2f MB\n", float64(written)/(1024*1024))
	return nil
}

func resolveDeezerTrackURL(req DownloadRequest) (string, error) {
	deezerID := strings.TrimSpace(req.DeezerID)
	if deezerID == "" {
		if prefixed, found := strings.CutPrefix(strings.TrimSpace(req.SpotifyID), "deezer:"); found {
			deezerID = strings.TrimSpace(prefixed)
		}
	}
	if deezerID != "" {
		return fmt.Sprintf("https://www.deezer.com/track/%s", deezerID), nil
	}

	// Try resolving Deezer ID from Spotify ID via SongLink
	spotifyID := strings.TrimSpace(req.SpotifyID)
	if spotifyID != "" && isLikelySpotifyTrackID(spotifyID) {
		songlink := NewSongLinkClient()
		availability, err := songlink.CheckTrackAvailability(spotifyID, "")
		if err == nil && availability.Deezer && availability.DeezerURL != "" {
			return availability.DeezerURL, nil
		}
	}

	// Try resolving from ISRC
	isrc := strings.TrimSpace(req.ISRC)
	if isrc != "" {
		ctx, cancel := context.WithTimeout(context.Background(), SongLinkTimeout)
		defer cancel()
		track, err := GetDeezerClient().SearchByISRC(ctx, isrc)
		if err == nil && track != nil {
			deezerID = songLinkExtractDeezerTrackID(track)
			if deezerID != "" {
				return fmt.Sprintf("https://www.deezer.com/track/%s", deezerID), nil
			}
		}
	}

	return "", fmt.Errorf("could not resolve Deezer track URL")
}

type deezerMusicDLRequest struct {
	Platform string `json:"platform"`
	URL      string `json:"url"`
}

func (c *DeezerClient) GetMusicDLDownloadURL(deezerTrackURL string) (string, error) {
	payload := deezerMusicDLRequest{
		Platform: "deezer",
		URL:      deezerTrackURL,
	}
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("failed to encode MusicDL request: %w", err)
	}

	req, err := http.NewRequest(http.MethodPost, deezerMusicDLURL, bytes.NewReader(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to create MusicDL request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Debug-Key", getQobuzDebugKey())
	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("MusicDL request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	if err != nil {
		return "", fmt.Errorf("failed to read MusicDL response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("MusicDL returned HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	var raw map[string]any
	if err := json.Unmarshal(body, &raw); err != nil {
		return "", fmt.Errorf("invalid MusicDL JSON: %w", err)
	}

	if errMsg, ok := raw["error"].(string); ok && strings.TrimSpace(errMsg) != "" {
		return "", fmt.Errorf("MusicDL error: %s", errMsg)
	}

	// Try various response fields for download URL
	for _, key := range []string{"download_url", "url", "link"} {
		if urlVal, ok := raw[key].(string); ok && strings.TrimSpace(urlVal) != "" {
			return strings.TrimSpace(urlVal), nil
		}
	}
	if data, ok := raw["data"].(map[string]any); ok {
		for _, key := range []string{"download_url", "url", "link"} {
			if urlVal, ok := data[key].(string); ok && strings.TrimSpace(urlVal) != "" {
				return strings.TrimSpace(urlVal), nil
			}
		}
	}

	return "", fmt.Errorf("no download URL found in MusicDL response")
}

func (c *DeezerClient) DownloadFromMusicDL(deezerTrackURL, outputPath string, outputFD int, itemID string) error {
	GoLog("[Deezer] Resolving download URL via MusicDL for: %s\n", deezerTrackURL)

	downloadURL, err := c.GetMusicDLDownloadURL(deezerTrackURL)
	if err != nil {
		return err
	}
	GoLog("[Deezer] MusicDL returned download URL, starting download...\n")

	ctx := context.Background()
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
		return fmt.Errorf("failed to create download request: %w", err)
	}
	req.Header.Set("User-Agent", getRandomUserAgent())

	resp, err := c.httpClient.Do(req)
	if err != nil {
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return fmt.Errorf("download request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("download returned HTTP %d", resp.StatusCode)
	}

	expectedSize := resp.ContentLength
	if expectedSize > 0 && itemID != "" {
		SetItemBytesTotal(itemID, expectedSize)
	}

	out, err := openOutputForWrite(outputPath, outputFD)
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

	flushErr := bufWriter.Flush()
	closeErr := out.Close()

	if err != nil {
		cleanupOutputOnError(outputPath, outputFD)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return fmt.Errorf("download interrupted: %w", err)
	}
	if flushErr != nil {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("failed to flush output: %w", flushErr)
	}
	if closeErr != nil {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("failed to close output: %w", closeErr)
	}

	if expectedSize > 0 && written != expectedSize {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
	}

	GoLog("[Deezer] Downloaded via MusicDL: %.2f MB\n", float64(written)/(1024*1024))
	return nil
}

func downloadFromDeezer(req DownloadRequest) (DeezerDownloadResult, error) {
	deezerClient := GetDeezerClient()
	isSafOutput := isFDOutput(req.OutputFD) || strings.TrimSpace(req.OutputPath) != ""

	if !isSafOutput {
		if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
			return DeezerDownloadResult{FilePath: "EXISTS:" + existingFile}, nil
		}
	}

	spotifyURL, err := resolveSpotifyURLForYoinkify(req)
	if err != nil {
		return DeezerDownloadResult{}, err
	}

	filename := buildFilenameFromTemplate(req.FilenameFormat, map[string]interface{}{
		"title":  req.TrackName,
		"artist": req.ArtistName,
		"album":  req.AlbumName,
		"track":  req.TrackNumber,
		"year":   extractYear(req.ReleaseDate),
		"date":   req.ReleaseDate,
		"disc":   req.DiscNumber,
	})

	var outputPath string
	if isSafOutput {
		outputPath = strings.TrimSpace(req.OutputPath)
		if outputPath == "" && isFDOutput(req.OutputFD) {
			outputPath = fmt.Sprintf("/proc/self/fd/%d", req.OutputFD)
		}
	} else {
		filename = sanitizeFilename(filename) + ".flac"
		outputPath = filepath.Join(req.OutputDir, filename)
		if fileInfo, statErr := os.Stat(outputPath); statErr == nil && fileInfo.Size() > 0 {
			return DeezerDownloadResult{FilePath: "EXISTS:" + outputPath}, nil
		}
	}

	var parallelResult *ParallelDownloadResult
	parallelDone := make(chan struct{})
	go func() {
		defer close(parallelDone)
		coverURL := req.CoverURL
		embedLyrics := req.EmbedLyrics
		if !req.EmbedMetadata {
			coverURL = ""
			embedLyrics = false
		}
		parallelResult = FetchCoverAndLyricsParallel(
			coverURL,
			req.EmbedMaxQualityCover,
			req.SpotifyID,
			req.TrackName,
			req.ArtistName,
			embedLyrics,
			int64(req.DurationMS),
		)
	}()

	// Try MusicDL first (better quality), fallback to Yoinkify
	var downloadErr error
	deezerTrackURL, deezerURLErr := resolveDeezerTrackURL(req)
	if deezerURLErr == nil {
		GoLog("[Deezer] Trying MusicDL for: %s\n", deezerTrackURL)
		downloadErr = deezerClient.DownloadFromMusicDL(deezerTrackURL, outputPath, req.OutputFD, req.ItemID)
		if downloadErr != nil {
			if errors.Is(downloadErr, ErrDownloadCancelled) {
				return DeezerDownloadResult{}, ErrDownloadCancelled
			}
			GoLog("[Deezer] MusicDL failed: %v, falling back to Yoinkify\n", downloadErr)
		}
	} else {
		GoLog("[Deezer] Could not resolve Deezer URL: %v, using Yoinkify directly\n", deezerURLErr)
	}

	if downloadErr != nil || deezerURLErr != nil {
		downloadErr = deezerClient.DownloadFromYoinkify(spotifyURL, outputPath, req.OutputFD, req.ItemID)
		if downloadErr != nil {
			if errors.Is(downloadErr, ErrDownloadCancelled) {
				return DeezerDownloadResult{}, ErrDownloadCancelled
			}
			return DeezerDownloadResult{}, fmt.Errorf("deezer download failed (MusicDL + Yoinkify): %w", downloadErr)
		}
	}

	<-parallelDone

	if req.ItemID != "" {
		SetItemProgress(req.ItemID, 1.0, 0, 0)
		SetItemFinalizing(req.ItemID)
	}

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
		Genre:       req.Genre,
		Label:       req.Label,
		Copyright:   req.Copyright,
	}

	var coverData []byte
	if parallelResult != nil && parallelResult.CoverData != nil {
		coverData = parallelResult.CoverData
	}

	if isSafOutput || !req.EmbedMetadata {
		if !req.EmbedMetadata {
			GoLog("[Deezer] Metadata embedding disabled by settings, skipping in-backend metadata/lyrics embedding\n")
		} else {
			GoLog("[Deezer] SAF output detected - skipping in-backend metadata/lyrics embedding (handled in Flutter)\n")
		}
	} else {
		if err := EmbedMetadataWithCoverData(outputPath, metadata, coverData); err != nil {
			GoLog("[Deezer] Warning: failed to embed metadata: %v\n", err)
		}

		if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
			lyricsMode := req.LyricsMode
			if lyricsMode == "" {
				lyricsMode = "embed"
			}

			if lyricsMode == "external" || lyricsMode == "both" {
				if lrcPath, lrcErr := SaveLRCFile(outputPath, parallelResult.LyricsLRC); lrcErr != nil {
					GoLog("[Deezer] Warning: failed to save LRC file: %v\n", lrcErr)
				} else {
					GoLog("[Deezer] LRC file saved: %s\n", lrcPath)
				}
			}

			if lyricsMode == "embed" || lyricsMode == "both" {
				if embedErr := EmbedLyrics(outputPath, parallelResult.LyricsLRC); embedErr != nil {
					GoLog("[Deezer] Warning: failed to embed lyrics: %v\n", embedErr)
				}
			}
		}
	}

	if !isSafOutput {
		AddToISRCIndex(req.OutputDir, req.ISRC, outputPath)
	}

	bitDepth, sampleRate := 0, 0
	if quality, qErr := GetAudioQuality(outputPath); qErr == nil {
		bitDepth = quality.BitDepth
		sampleRate = quality.SampleRate
	}

	lyricsLRC := ""
	if req.EmbedMetadata && req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
		lyricsLRC = parallelResult.LyricsLRC
	}

	return DeezerDownloadResult{
		FilePath:    outputPath,
		BitDepth:    bitDepth,
		SampleRate:  sampleRate,
		Title:       req.TrackName,
		Artist:      req.ArtistName,
		Album:       req.AlbumName,
		ReleaseDate: req.ReleaseDate,
		TrackNumber: req.TrackNumber,
		DiscNumber:  req.DiscNumber,
		ISRC:        req.ISRC,
		LyricsLRC:   lyricsLRC,
	}, nil
}
