package gobackend

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"path/filepath"
	"strings"
	"time"
)

type StreamResponse struct {
	Success            bool   `json:"success"`
	Service            string `json:"service,omitempty"`
	StreamURL          string `json:"stream_url,omitempty"`
	Format             string `json:"format,omitempty"`
	BitDepth           int    `json:"bit_depth,omitempty"`
	SampleRate         int    `json:"sample_rate,omitempty"`
	Bitrate            int    `json:"bitrate,omitempty"`
	RequiresDecryption bool   `json:"requires_decryption,omitempty"`
	DecryptionKey      string `json:"decryption_key,omitempty"`
	Error              string `json:"error,omitempty"`
	ErrorType          string `json:"error_type,omitempty"`
}

func ResolveStreamByStrategy(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return marshalStreamResponse(StreamResponse{
			Success:   false,
			Error:     "Invalid request: " + err.Error(),
			ErrorType: "invalid_request",
		})
	}

	applySongLinkRegionFromRequest(&req)
	req.Service = strings.TrimSpace(strings.ToLower(req.Service))
	req.Source = strings.TrimSpace(req.Source)
	req.TrackName = strings.TrimSpace(req.TrackName)
	req.ArtistName = strings.TrimSpace(req.ArtistName)
	req.AlbumName = strings.TrimSpace(req.AlbumName)
	req.ISRC = normalizeISRC(req.ISRC)

	enrichStreamRequestIdentifiers(&req)

	resp, err := resolveStreamInternal(req)
	if err != nil {
		errorType := classifyStreamResolveErrorType(err)
		return marshalStreamResponse(StreamResponse{
			Success:   false,
			Service:   req.Service,
			Error:     err.Error(),
			ErrorType: errorType,
		})
	}

	return marshalStreamResponse(*resp)
}

func classifyStreamResolveErrorType(err error) string {
	if err == nil {
		return "resolve_failed"
	}
	if isStreamNotFoundErrorMessage(err.Error()) {
		return "not_found"
	}
	return "resolve_failed"
}

func isStreamNotFoundErrorMessage(message string) bool {
	lower := strings.ToLower(strings.TrimSpace(message))
	if lower == "" {
		return false
	}

	patterns := []string{
		"failed to find tidal track",
		"failed to find qobuz track",
		"could not find amazon url",
		"could not find youtube url",
		"could not find track",
		"no tracks found",
		"track not available",
		"track not found",
		"no stream provider available",
	}

	for _, pattern := range patterns {
		if strings.Contains(lower, pattern) {
			return true
		}
	}

	return false
}

func resolveStreamInternal(req DownloadRequest) (*StreamResponse, error) {
	service := strings.TrimSpace(strings.ToLower(req.Service))
	if service == "" {
		service = "tidal"
	}

	if service == "youtube" {
		return resolveYouTubeStream(req)
	}

	if req.UseExtensions {
		// Strict mode: keep selected built-in provider when fallback is disabled.
		if !req.UseFallback && isBuiltInStreamProvider(service) {
			return resolveBuiltInStream(service, req)
		}
		return resolveStreamWithExtensions(req)
	}

	if req.UseFallback {
		return resolveStreamWithFallback(req)
	}

	return resolveBuiltInStream(service, req)
}

func enrichStreamRequestIdentifiers(req *DownloadRequest) {
	if req == nil {
		return
	}

	req.SpotifyID = strings.TrimSpace(req.SpotifyID)
	req.DeezerID = strings.TrimSpace(req.DeezerID)
	req.ISRC = normalizeISRC(req.ISRC)

	spotifyTrackID := extractSpotifyTrackID(req.SpotifyID)
	if spotifyTrackID != "" {
		req.SpotifyID = spotifyTrackID
	}

	deezerTrackID := req.DeezerID
	if deezerTrackID == "" {
		if prefixed, found := strings.CutPrefix(req.SpotifyID, "deezer:"); found {
			deezerTrackID = strings.TrimSpace(prefixed)
		}
	}

	// Priority 1: get ISRC directly from Deezer track ID.
	if req.ISRC == "" && deezerTrackID != "" {
		if isrc, err := getISRCFromDeezerTrackID(deezerTrackID); err == nil {
			req.DeezerID = deezerTrackID
			req.ISRC = isrc
			GoLog("[Stream] ISRC enriched from Deezer: %s (deezer:%s)\n", req.ISRC, deezerTrackID)
			return
		} else {
			GoLog("[Stream] Deezer ISRC lookup failed for deezer:%s: %v\n", deezerTrackID, err)
		}
	}

	// Priority 2: fallback to SongLink (Spotify -> Deezer/Tidal/Qobuz IDs), then retry Deezer ISRC.
	if spotifyTrackID == "" {
		return
	}

	songLinkClient := NewSongLinkClient()
	availability, err := songLinkClient.CheckTrackAvailability(spotifyTrackID, req.ISRC)
	if err != nil || availability == nil {
		if err != nil {
			GoLog("[Stream] SongLink lookup failed for Spotify %s: %v\n", spotifyTrackID, err)
		}
		return
	}

	if req.DeezerID == "" && availability.DeezerID != "" {
		req.DeezerID = availability.DeezerID
	}
	if req.TidalID == "" && availability.TidalID != "" {
		req.TidalID = availability.TidalID
	}
	if req.QobuzID == "" && availability.QobuzID != "" {
		req.QobuzID = availability.QobuzID
	}

	if req.ISRC == "" && req.DeezerID != "" {
		if isrc, derr := getISRCFromDeezerTrackID(req.DeezerID); derr == nil {
			req.ISRC = isrc
			GoLog("[Stream] ISRC enriched via SongLink->Deezer: %s (deezer:%s)\n", req.ISRC, req.DeezerID)
		} else {
			GoLog("[Stream] SongLink got DeezerID but Deezer ISRC lookup failed (deezer:%s): %v\n", req.DeezerID, derr)
		}
	}
}

func getISRCFromDeezerTrackID(trackID string) (string, error) {
	trackID = strings.TrimSpace(trackID)
	if trackID == "" {
		return "", fmt.Errorf("empty deezer track id")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	isrc, err := GetDeezerClient().GetTrackISRC(ctx, trackID)
	if err != nil {
		return "", err
	}

	isrc = normalizeISRC(isrc)
	if isrc == "" {
		return "", fmt.Errorf("deezer track has no valid ISRC")
	}
	return isrc, nil
}

func normalizeISRC(value string) string {
	trimmed := strings.ToUpper(strings.TrimSpace(value))
	if !isLikelyISRC(trimmed) {
		return ""
	}
	return trimmed
}

func isLikelyISRC(value string) bool {
	if len(value) != 12 {
		return false
	}

	for _, r := range value {
		switch {
		case r >= 'A' && r <= 'Z':
		case r >= '0' && r <= '9':
		default:
			return false
		}
	}
	return true
}

func extractSpotifyTrackID(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" || strings.HasPrefix(trimmed, "deezer:") {
		return ""
	}

	if isLikelySpotifyTrackID(trimmed) {
		return trimmed
	}

	if strings.HasPrefix(trimmed, "spotify:") || strings.Contains(trimmed, "open.spotify.com/") || strings.Contains(trimmed, "play.spotify.com/") {
		parsed, err := parseSpotifyURI(trimmed)
		if err == nil && parsed.Type == "track" {
			return strings.TrimSpace(parsed.ID)
		}
	}

	return ""
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

func resolveStreamWithFallback(req DownloadRequest) (*StreamResponse, error) {
	preferred := strings.TrimSpace(strings.ToLower(req.Service))
	if !isBuiltInStreamProvider(preferred) {
		preferred = "tidal"
	}

	allServices := []string{"tidal", "qobuz", "amazon", "youtube"}
	services := []string{preferred}
	for _, s := range allServices {
		if s != preferred {
			services = append(services, s)
		}
	}

	var lastErr error
	for _, service := range services {
		resp, err := resolveBuiltInStream(service, req)
		if err == nil && resp != nil && resp.Success {
			return resp, nil
		}
		if err != nil {
			lastErr = err
		}
	}

	if lastErr != nil {
		return nil, fmt.Errorf("all services failed: %w", lastErr)
	}
	return nil, fmt.Errorf("no stream provider available")
}

func resolveStreamWithExtensions(req DownloadRequest) (*StreamResponse, error) {
	priority := GetProviderPriority()
	priority = appendMissingStreamBuiltIns(priority)
	selectedProvider := strings.TrimSpace(req.Service)
	strictMode := !req.UseFallback

	if strictMode && selectedProvider != "" {
		priority = []string{selectedProvider}
	}

	if !strictMode && selectedProvider != "" && isBuiltInStreamProvider(strings.ToLower(selectedProvider)) {
		newPriority := []string{selectedProvider}
		for _, p := range priority {
			if !strings.EqualFold(p, selectedProvider) {
				newPriority = append(newPriority, p)
			}
		}
		priority = newPriority
	}

	var lastErr error

	// Track from extension source should prefer that same extension.
	if req.Source != "" && !isBuiltInStreamProvider(strings.ToLower(req.Source)) {
		if !strictMode || selectedProvider == "" || strings.EqualFold(selectedProvider, req.Source) {
			resp, err := resolveExtensionProviderStream(req.Source, req)
			if err == nil && resp != nil && resp.Success {
				return resp, nil
			}
			if err != nil {
				lastErr = err
			}
		}
	}

	for _, providerID := range priority {
		providerID = strings.TrimSpace(providerID)
		if providerID == "" {
			continue
		}
		providerNormalized := strings.ToLower(providerID)
		if strings.EqualFold(providerID, req.Source) {
			continue
		}

		if isBuiltInStreamProvider(providerNormalized) {
			resp, err := resolveBuiltInStream(providerNormalized, req)
			if err == nil && resp != nil && resp.Success {
				return resp, nil
			}
			if err != nil {
				lastErr = err
			}
			continue
		}

		resp, err := resolveExtensionProviderStream(providerID, req)
		if err == nil && resp != nil && resp.Success {
			return resp, nil
		}
		if err != nil {
			lastErr = err
		}
	}

	if lastErr != nil {
		return nil, fmt.Errorf("all providers failed: %w", lastErr)
	}
	return nil, fmt.Errorf("no providers available")
}

func isBuiltInStreamProvider(providerID string) bool {
	switch strings.ToLower(strings.TrimSpace(providerID)) {
	case "tidal", "qobuz", "amazon", "youtube":
		return true
	default:
		return false
	}
}

func appendMissingStreamBuiltIns(priority []string) []string {
	result := make([]string, 0, len(priority)+4)
	result = append(result, priority...)

	required := []string{"tidal", "qobuz", "amazon", "youtube"}
	for _, provider := range required {
		found := false
		for _, existing := range result {
			if strings.EqualFold(existing, provider) {
				found = true
				break
			}
		}
		if !found {
			result = append(result, provider)
		}
	}

	return result
}

func resolveExtensionProviderStream(providerID string, req DownloadRequest) (*StreamResponse, error) {
	manager := GetExtensionManager()
	ext, err := manager.GetExtension(providerID)
	if err != nil {
		return nil, fmt.Errorf("extension %s not found", providerID)
	}
	if !ext.Enabled || ext.Error != "" || !ext.Manifest.IsDownloadProvider() {
		return nil, fmt.Errorf("extension %s is not available", providerID)
	}

	provider := NewExtensionProviderWrapper(ext)
	trackID := strings.TrimSpace(req.SpotifyID)

	// For non-source providers, resolve proper provider-specific track ID first.
	if !strings.EqualFold(providerID, req.Source) || trackID == "" {
		availability, avErr := provider.CheckAvailability(req.ISRC, req.TrackName, req.ArtistName)
		if avErr == nil && availability != nil && availability.Available {
			if availability.TrackID != "" {
				trackID = availability.TrackID
			}
		} else if trackID == "" {
			if avErr != nil {
				return nil, avErr
			}
			return nil, fmt.Errorf("%s: track not available", providerID)
		}
	}

	if trackID == "" {
		return nil, fmt.Errorf("%s: missing track id", providerID)
	}

	urlResult, err := provider.GetDownloadURL(trackID, req.Quality)
	if err != nil {
		return nil, err
	}
	streamURL := strings.TrimSpace(urlResult.URL)
	if streamURL == "" {
		return nil, fmt.Errorf("%s: empty stream URL", providerID)
	}

	format := inferStreamFormat(streamURL, urlResult.Format)
	return &StreamResponse{
		Success:    true,
		Service:    providerID,
		StreamURL:  streamURL,
		Format:     format,
		BitDepth:   urlResult.BitDepth,
		SampleRate: urlResult.SampleRate,
	}, nil
}

func resolveBuiltInStream(providerID string, req DownloadRequest) (*StreamResponse, error) {
	switch strings.ToLower(strings.TrimSpace(providerID)) {
	case "tidal":
		return resolveTidalStream(req)
	case "qobuz":
		return resolveQobuzStream(req)
	case "amazon":
		return resolveAmazonStream(req)
	case "youtube":
		return resolveYouTubeStream(req)
	default:
		return nil, fmt.Errorf("unsupported stream provider: %s", providerID)
	}
}

func resolveTidalStream(req DownloadRequest) (*StreamResponse, error) {
	downloader := NewTidalDownloader()
	track, err := resolveTidalTrackForRequest(req, downloader, "Stream:Tidal")
	if err != nil {
		return nil, fmt.Errorf("failed to find Tidal track: %w", err)
	}

	quality := req.Quality
	if strings.TrimSpace(quality) == "" {
		quality = "LOSSLESS"
	}

	info, err := downloader.GetDownloadURL(track.ID, quality)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve Tidal stream URL: %w", err)
	}

	streamURL := strings.TrimSpace(info.URL)
	if streamURL == "" {
		return nil, fmt.Errorf("Tidal returned empty stream URL")
	}

	if strings.HasPrefix(streamURL, "MANIFEST:") {
		directURL, _, _, parseErr := parseManifest(strings.TrimPrefix(streamURL, "MANIFEST:"))
		if parseErr != nil || strings.TrimSpace(directURL) == "" {
			return nil, fmt.Errorf("Tidal DASH segmented stream is not directly playable")
		}
		streamURL = directURL
	}

	fallbackFormat := "flac"
	if strings.EqualFold(quality, "HIGH") {
		fallbackFormat = "m4a"
	}

	return &StreamResponse{
		Success:    true,
		Service:    "tidal",
		StreamURL:  streamURL,
		Format:     inferStreamFormat(streamURL, fallbackFormat),
		BitDepth:   info.BitDepth,
		SampleRate: info.SampleRate,
	}, nil
}

func resolveQobuzStream(req DownloadRequest) (*StreamResponse, error) {
	downloader := NewQobuzDownloader()
	track, err := resolveQobuzTrackForRequest(req, downloader, "Stream:Qobuz")
	if err != nil {
		return nil, fmt.Errorf("failed to find Qobuz track: %w", err)
	}

	qobuzQuality := "27"
	switch strings.TrimSpace(req.Quality) {
	case "LOSSLESS":
		qobuzQuality = "6"
	case "HI_RES":
		qobuzQuality = "7"
	case "HI_RES_LOSSLESS":
		qobuzQuality = "27"
	}

	streamURL, err := downloader.GetDownloadURL(track.ID, qobuzQuality)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve Qobuz stream URL: %w", err)
	}
	streamURL = strings.TrimSpace(streamURL)
	if streamURL == "" {
		return nil, fmt.Errorf("Qobuz returned empty stream URL")
	}

	return &StreamResponse{
		Success:    true,
		Service:    "qobuz",
		StreamURL:  streamURL,
		Format:     inferStreamFormat(streamURL, "flac"),
		BitDepth:   track.MaximumBitDepth,
		SampleRate: int(track.MaximumSamplingRate * 1000),
	}, nil
}

func resolveAmazonStream(req DownloadRequest) (*StreamResponse, error) {
	downloader := NewAmazonDownloader()
	amazonURL, err := resolveAmazonURLForRequest(req, "Stream:Amazon")
	if err != nil {
		return nil, fmt.Errorf("failed to check Amazon availability: %w", err)
	}

	streamURL, fileName, decryptionKey, err := downloader.downloadFromAfkarXYZ(amazonURL)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve Amazon stream URL: %w", err)
	}
	streamURL = strings.TrimSpace(streamURL)
	if streamURL == "" {
		return nil, fmt.Errorf("Amazon returned empty stream URL")
	}

	format := inferStreamFormat(streamURL, strings.TrimPrefix(strings.ToLower(filepath.Ext(fileName)), "."))
	if format == "" {
		format = "m4a"
	}

	if strings.TrimSpace(decryptionKey) != "" {
		return &StreamResponse{
			Success:            true,
			Service:            "amazon",
			StreamURL:          streamURL,
			Format:             format,
			RequiresDecryption: true,
			DecryptionKey:      decryptionKey,
			Error:              "Amazon stream requires decryption (client will decrypt on-the-fly)",
			ErrorType:          "encrypted_stream",
		}, nil
	}

	return &StreamResponse{
		Success:   true,
		Service:   "amazon",
		StreamURL: streamURL,
		Format:    format,
	}, nil
}

func resolveYouTubeStream(req DownloadRequest) (*StreamResponse, error) {
	downloader := NewYouTubeDownloader()
	format, bitrate, quality := parseYouTubeQualityInput(req.Quality)

	youtubeURL, err := resolveYouTubeURLForRequest(req)
	if err != nil {
		return nil, err
	}

	cobaltResp, err := downloader.GetDownloadURL(youtubeURL, quality)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve YouTube stream URL: %w", err)
	}
	if cobaltResp == nil || strings.TrimSpace(cobaltResp.URL) == "" {
		return nil, fmt.Errorf("YouTube resolver returned empty URL")
	}

	if cobaltResp.Filename != "" {
		lowerName := strings.ToLower(strings.TrimSpace(cobaltResp.Filename))
		switch {
		case strings.HasSuffix(lowerName, ".mp3"):
			format = "mp3"
		case strings.HasSuffix(lowerName, ".opus"), strings.HasSuffix(lowerName, ".ogg"):
			format = "opus"
		}
	}

	return &StreamResponse{
		Success:   true,
		Service:   "youtube",
		StreamURL: strings.TrimSpace(cobaltResp.URL),
		Format:    inferStreamFormat(cobaltResp.URL, format),
		Bitrate:   bitrate,
	}, nil
}

func resolveYouTubeURLForRequest(req DownloadRequest) (string, error) {
	var youtubeURL string
	var lookupErr error

	if req.SpotifyID != "" && isYouTubeVideoID(req.SpotifyID) {
		youtubeURL = BuildYouTubeWatchURL(req.SpotifyID)
	}

	if youtubeURL == "" && req.SpotifyID != "" && !isYouTubeVideoID(req.SpotifyID) {
		songlink := NewSongLinkClient()
		youtubeURL, lookupErr = songlink.GetYouTubeURLFromSpotify(req.SpotifyID)
		if lookupErr != nil {
			GoLog("[Stream:YouTube] Spotify lookup failed: %v\n", lookupErr)
		}
	}

	if youtubeURL == "" && req.DeezerID != "" {
		songlink := NewSongLinkClient()
		youtubeURL, lookupErr = songlink.GetYouTubeURLFromDeezer(req.DeezerID)
		if lookupErr != nil {
			GoLog("[Stream:YouTube] Deezer lookup failed: %v\n", lookupErr)
		}
	}

	if youtubeURL == "" && req.ISRC != "" {
		songlink := NewSongLinkClient()
		availability, isrcErr := songlink.CheckTrackAvailability("", req.ISRC)
		if isrcErr == nil && availability.YouTube && availability.YouTubeURL != "" {
			youtubeURL = availability.YouTubeURL
		} else if isrcErr != nil {
			GoLog("[Stream:YouTube] ISRC lookup failed: %v\n", isrcErr)
		}
	}

	if strings.TrimSpace(youtubeURL) == "" {
		return "", fmt.Errorf("could not find YouTube URL for %s - %s", req.ArtistName, req.TrackName)
	}

	return youtubeURL, nil
}

func inferStreamFormat(rawURL, fallback string) string {
	fallback = strings.TrimPrefix(strings.ToLower(strings.TrimSpace(fallback)), ".")

	if strings.TrimSpace(rawURL) != "" {
		if parsed, err := url.Parse(rawURL); err == nil {
			ext := strings.TrimPrefix(strings.ToLower(filepath.Ext(parsed.Path)), ".")
			if mapped := normalizeStreamFormat(ext); mapped != "" {
				return mapped
			}
		}
	}

	if mapped := normalizeStreamFormat(fallback); mapped != "" {
		return mapped
	}
	return ""
}

func normalizeStreamFormat(format string) string {
	switch strings.TrimPrefix(strings.ToLower(strings.TrimSpace(format)), ".") {
	case "flac":
		return "flac"
	case "m4a", "mp4", "aac":
		return "m4a"
	case "mp3":
		return "mp3"
	case "opus", "ogg":
		return "opus"
	case "wav":
		return "wav"
	default:
		return ""
	}
}

func marshalStreamResponse(resp StreamResponse) (string, error) {
	jsonBytes, err := json.Marshal(resp)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}
