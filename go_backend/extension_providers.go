// Package gobackend provides extension provider interfaces
package gobackend

import (
	"encoding/json"
	"fmt"
	"path/filepath"
	"strings"
	"sync"

	"github.com/dop251/goja"
)

// ==================== Metadata Types ====================

// ExtTrackMetadata represents track metadata from an extension
type ExtTrackMetadata struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Artists     string `json:"artists"`
	AlbumName   string `json:"album_name"`
	AlbumArtist string `json:"album_artist,omitempty"`
	DurationMS  int    `json:"duration_ms"`
	CoverURL    string `json:"cover_url,omitempty"`
	Images      string `json:"images,omitempty"` // Alternative field for cover URL (used by some extensions)
	ReleaseDate string `json:"release_date,omitempty"`
	TrackNumber int    `json:"track_number,omitempty"`
	DiscNumber  int    `json:"disc_number,omitempty"`
	ISRC        string `json:"isrc,omitempty"`
	ProviderID  string `json:"provider_id"`
}

// ResolvedCoverURL returns the cover URL, checking both CoverURL and Images fields
func (t *ExtTrackMetadata) ResolvedCoverURL() string {
	if t.CoverURL != "" {
		return t.CoverURL
	}
	return t.Images
}

// ExtAlbumMetadata represents album metadata from an extension
type ExtAlbumMetadata struct {
	ID          string             `json:"id"`
	Name        string             `json:"name"`
	Artists     string             `json:"artists"`
	CoverURL    string             `json:"cover_url,omitempty"`
	ReleaseDate string             `json:"release_date,omitempty"`
	TotalTracks int                `json:"total_tracks"`
	Tracks      []ExtTrackMetadata `json:"tracks"`
	ProviderID  string             `json:"provider_id"`
}

// ExtArtistMetadata represents artist metadata from an extension
type ExtArtistMetadata struct {
	ID         string             `json:"id"`
	Name       string             `json:"name"`
	ImageURL   string             `json:"image_url,omitempty"`
	Albums     []ExtAlbumMetadata `json:"albums,omitempty"`
	ProviderID string             `json:"provider_id"`
}

// ExtSearchResult represents search results from an extension
type ExtSearchResult struct {
	Tracks []ExtTrackMetadata `json:"tracks"`
	Total  int                `json:"total"`
}

// ==================== Download Types ====================

// ExtAvailabilityResult represents availability check result
type ExtAvailabilityResult struct {
	Available bool   `json:"available"`
	Reason    string `json:"reason,omitempty"`
	TrackID   string `json:"track_id,omitempty"`
}

// ExtDownloadURLResult represents download URL info
type ExtDownloadURLResult struct {
	URL        string `json:"url"`
	Format     string `json:"format"`
	BitDepth   int    `json:"bit_depth,omitempty"`
	SampleRate int    `json:"sample_rate,omitempty"`
}

// ExtDownloadResult represents download result from an extension
type ExtDownloadResult struct {
	Success      bool   `json:"success"`
	FilePath     string `json:"file_path,omitempty"`
	BitDepth     int    `json:"bit_depth,omitempty"`
	SampleRate   int    `json:"sample_rate,omitempty"`
	ErrorMessage string `json:"error_message,omitempty"`
	ErrorType    string `json:"error_type,omitempty"`
	// Metadata returned by extension (optional - if provided, can skip enrichment)
	Title       string `json:"title,omitempty"`
	Artist      string `json:"artist,omitempty"`
	Album       string `json:"album,omitempty"`
	AlbumArtist string `json:"album_artist,omitempty"`
	TrackNumber int    `json:"track_number,omitempty"`
	DiscNumber  int    `json:"disc_number,omitempty"`
	ReleaseDate string `json:"release_date,omitempty"`
	CoverURL    string `json:"cover_url,omitempty"`
	ISRC        string `json:"isrc,omitempty"`
}

// ==================== Provider Wrapper ====================

// ExtensionProviderWrapper wraps an extension to call its provider methods
type ExtensionProviderWrapper struct {
	extension *LoadedExtension
	vm        *goja.Runtime
}

// NewExtensionProviderWrapper creates a new provider wrapper
func NewExtensionProviderWrapper(ext *LoadedExtension) *ExtensionProviderWrapper {
	return &ExtensionProviderWrapper{
		extension: ext,
		vm:        ext.VM,
	}
}

// ==================== Metadata Provider Methods ====================

// SearchTracks searches for tracks using the extension
func (p *ExtensionProviderWrapper) SearchTracks(query string, limit int) (*ExtSearchResult, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	// Call extension's searchTracks function
	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.searchTracks === 'function') {
				return extension.searchTracks(%q, %d);
			}
			return null;
		})()
	`, query, limit)

	result, err := p.vm.RunString(script)
	if err != nil {
		return nil, fmt.Errorf("searchTracks failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return nil, fmt.Errorf("searchTracks returned null")
	}

	// Convert result to Go struct
	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal result: %w", err)
	}

	var searchResult ExtSearchResult
	if err := json.Unmarshal(jsonBytes, &searchResult); err != nil {
		return nil, fmt.Errorf("failed to parse search result: %w", err)
	}

	// Set provider ID on all tracks
	for i := range searchResult.Tracks {
		searchResult.Tracks[i].ProviderID = p.extension.ID
	}

	return &searchResult, nil
}

// GetTrack gets track details by ID
func (p *ExtensionProviderWrapper) GetTrack(trackID string) (*ExtTrackMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.getTrack === 'function') {
				return extension.getTrack(%q);
			}
			return null;
		})()
	`, trackID)

	result, err := p.vm.RunString(script)
	if err != nil {
		return nil, fmt.Errorf("getTrack failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return nil, fmt.Errorf("getTrack returned null")
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal result: %w", err)
	}

	var track ExtTrackMetadata
	if err := json.Unmarshal(jsonBytes, &track); err != nil {
		return nil, fmt.Errorf("failed to parse track: %w", err)
	}

	track.ProviderID = p.extension.ID
	return &track, nil
}

// GetAlbum gets album details by ID
func (p *ExtensionProviderWrapper) GetAlbum(albumID string) (*ExtAlbumMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.getAlbum === 'function') {
				return extension.getAlbum(%q);
			}
			return null;
		})()
	`, albumID)

	result, err := p.vm.RunString(script)
	if err != nil {
		return nil, fmt.Errorf("getAlbum failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return nil, fmt.Errorf("getAlbum returned null")
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal result: %w", err)
	}

	var album ExtAlbumMetadata
	if err := json.Unmarshal(jsonBytes, &album); err != nil {
		return nil, fmt.Errorf("failed to parse album: %w", err)
	}

	album.ProviderID = p.extension.ID
	for i := range album.Tracks {
		album.Tracks[i].ProviderID = p.extension.ID
	}
	return &album, nil
}

// GetArtist gets artist details by ID
func (p *ExtensionProviderWrapper) GetArtist(artistID string) (*ExtArtistMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.getArtist === 'function') {
				return extension.getArtist(%q);
			}
			return null;
		})()
	`, artistID)

	result, err := p.vm.RunString(script)
	if err != nil {
		return nil, fmt.Errorf("getArtist failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return nil, fmt.Errorf("getArtist returned null")
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal result: %w", err)
	}

	var artist ExtArtistMetadata
	if err := json.Unmarshal(jsonBytes, &artist); err != nil {
		return nil, fmt.Errorf("failed to parse artist: %w", err)
	}

	artist.ProviderID = p.extension.ID
	return &artist, nil
}

// ==================== Download Provider Methods ====================

// CheckAvailability checks if a track is available for download
func (p *ExtensionProviderWrapper) CheckAvailability(isrc, trackName, artistName string) (*ExtAvailabilityResult, error) {
	if !p.extension.Manifest.IsDownloadProvider() {
		return nil, fmt.Errorf("extension '%s' is not a download provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.checkAvailability === 'function') {
				return extension.checkAvailability(%q, %q, %q);
			}
			return null;
		})()
	`, isrc, trackName, artistName)

	result, err := p.vm.RunString(script)
	if err != nil {
		return nil, fmt.Errorf("checkAvailability failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return &ExtAvailabilityResult{Available: false, Reason: "not implemented"}, nil
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal result: %w", err)
	}

	var availability ExtAvailabilityResult
	if err := json.Unmarshal(jsonBytes, &availability); err != nil {
		return nil, fmt.Errorf("failed to parse availability: %w", err)
	}

	return &availability, nil
}

// GetDownloadURL gets the download URL for a track
func (p *ExtensionProviderWrapper) GetDownloadURL(trackID, quality string) (*ExtDownloadURLResult, error) {
	if !p.extension.Manifest.IsDownloadProvider() {
		return nil, fmt.Errorf("extension '%s' is not a download provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.getDownloadUrl === 'function') {
				return extension.getDownloadUrl(%q, %q);
			}
			return null;
		})()
	`, trackID, quality)

	result, err := p.vm.RunString(script)
	if err != nil {
		return nil, fmt.Errorf("getDownloadUrl failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return nil, fmt.Errorf("getDownloadUrl returned null")
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal result: %w", err)
	}

	var urlResult ExtDownloadURLResult
	if err := json.Unmarshal(jsonBytes, &urlResult); err != nil {
		return nil, fmt.Errorf("failed to parse download URL: %w", err)
	}

	return &urlResult, nil
}

// Download downloads a track with progress reporting
func (p *ExtensionProviderWrapper) Download(trackID, quality, outputPath string, onProgress func(percent int)) (*ExtDownloadResult, error) {
	if !p.extension.Manifest.IsDownloadProvider() {
		return nil, fmt.Errorf("extension '%s' is not a download provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	// Set up progress callback in VM
	p.vm.Set("__onProgress", func(call goja.FunctionCall) goja.Value {
		if len(call.Arguments) > 0 {
			percent := int(call.Arguments[0].ToInteger())
			// Clamp to 0-100
			if percent < 0 {
				percent = 0
			}
			if percent > 100 {
				percent = 100
			}
			if onProgress != nil {
				onProgress(percent)
			}
		}
		return goja.Undefined()
	})

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.download === 'function') {
				return extension.download(%q, %q, %q, __onProgress);
			}
			return null;
		})()
	`, trackID, quality, outputPath)

	result, err := p.vm.RunString(script)
	if err != nil {
		return &ExtDownloadResult{
			Success:      false,
			ErrorMessage: err.Error(),
			ErrorType:    "script_error",
		}, nil
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return &ExtDownloadResult{
			Success:      false,
			ErrorMessage: "download returned null",
			ErrorType:    "not_implemented",
		}, nil
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return &ExtDownloadResult{
			Success:      false,
			ErrorMessage: fmt.Sprintf("failed to marshal result: %v", err),
			ErrorType:    "internal_error",
		}, nil
	}

	var downloadResult ExtDownloadResult
	if err := json.Unmarshal(jsonBytes, &downloadResult); err != nil {
		return &ExtDownloadResult{
			Success:      false,
			ErrorMessage: fmt.Sprintf("failed to parse result: %v", err),
			ErrorType:    "internal_error",
		}, nil
	}

	return &downloadResult, nil
}

// ==================== Extension Manager Provider Methods ====================

// GetMetadataProviders returns all enabled metadata provider extensions
func (m *ExtensionManager) GetMetadataProviders() []*ExtensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*ExtensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.IsMetadataProvider() && ext.Error == "" {
			providers = append(providers, NewExtensionProviderWrapper(ext))
		}
	}
	return providers
}

// GetDownloadProviders returns all enabled download provider extensions
func (m *ExtensionManager) GetDownloadProviders() []*ExtensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*ExtensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.IsDownloadProvider() && ext.Error == "" {
			providers = append(providers, NewExtensionProviderWrapper(ext))
		}
	}
	return providers
}

// SearchTracksWithExtensions searches all metadata providers
func (m *ExtensionManager) SearchTracksWithExtensions(query string, limit int) ([]ExtTrackMetadata, error) {
	providers := m.GetMetadataProviders()
	if len(providers) == 0 {
		return nil, nil
	}

	var allTracks []ExtTrackMetadata
	for _, provider := range providers {
		result, err := provider.SearchTracks(query, limit)
		if err != nil {
			GoLog("[Extension] Search error from %s: %v\n", provider.extension.ID, err)
			continue
		}
		if result != nil {
			allTracks = append(allTracks, result.Tracks...)
		}
	}

	return allTracks, nil
}

// ==================== Provider Priority ====================

// providerPriority stores the order of download providers
var providerPriority []string
var providerPriorityMu sync.RWMutex

// metadataProviderPriority stores the order of metadata providers
var metadataProviderPriority []string
var metadataProviderPriorityMu sync.RWMutex

// SetProviderPriority sets the order of download providers
// providerIDs should include both built-in ("tidal", "qobuz", "amazon") and extension IDs
func SetProviderPriority(providerIDs []string) {
	providerPriorityMu.Lock()
	defer providerPriorityMu.Unlock()
	providerPriority = providerIDs
	GoLog("[Extension] Download provider priority set: %v\n", providerIDs)
}

// GetProviderPriority returns the current provider priority order
func GetProviderPriority() []string {
	providerPriorityMu.RLock()
	defer providerPriorityMu.RUnlock()

	if len(providerPriority) == 0 {
		// Default order: built-in providers first
		return []string{"tidal", "qobuz", "amazon"}
	}

	result := make([]string, len(providerPriority))
	copy(result, providerPriority)
	return result
}

// SetMetadataProviderPriority sets the order of metadata providers
// providerIDs should include both built-in ("spotify", "deezer") and extension IDs
func SetMetadataProviderPriority(providerIDs []string) {
	metadataProviderPriorityMu.Lock()
	defer metadataProviderPriorityMu.Unlock()
	metadataProviderPriority = providerIDs
	GoLog("[Extension] Metadata provider priority set: %v\n", providerIDs)
}

// GetMetadataProviderPriority returns the current metadata provider priority order
func GetMetadataProviderPriority() []string {
	metadataProviderPriorityMu.RLock()
	defer metadataProviderPriorityMu.RUnlock()

	if len(metadataProviderPriority) == 0 {
		// Default order: built-in providers first
		return []string{"deezer", "spotify"}
	}

	result := make([]string, len(metadataProviderPriority))
	copy(result, metadataProviderPriority)
	return result
}

// isBuiltInProvider checks if a provider ID is a built-in provider
func isBuiltInProvider(providerID string) bool {
	switch providerID {
	case "tidal", "qobuz", "amazon":
		return true
	default:
		return false
	}
}

// ==================== Download with Fallback ====================

// DownloadWithExtensionFallback tries to download from providers in priority order
// Includes both built-in providers and extension providers
// If req.Source is set (extension ID), that extension is tried first
func DownloadWithExtensionFallback(req DownloadRequest) (*DownloadResponse, error) {
	priority := GetProviderPriority()
	extManager := GetExtensionManager()

	var lastErr error
	var skipBuiltIn bool // If source extension has skipBuiltInFallback, don't try built-in providers

	// If source extension is specified, try it first before the priority list
	if req.Source != "" && !isBuiltInProvider(req.Source) {
		GoLog("[DownloadWithExtensionFallback] Track source is extension '%s', trying it first\n", req.Source)

		ext, err := extManager.GetExtension(req.Source)
		if err == nil && ext.Enabled && ext.Error == "" && ext.Manifest.IsDownloadProvider() {
			// Check if this extension wants to skip built-in fallback
			skipBuiltIn = ext.Manifest.SkipBuiltInFallback

			provider := NewExtensionProviderWrapper(ext)

			// For tracks from extension search, use the track ID directly (e.g., "youtube:VIDEO_ID")
			// The extension already knows how to handle this ID
			trackID := req.SpotifyID // This contains the extension's track ID (e.g., "youtube:xxx")

			GoLog("[DownloadWithExtensionFallback] Downloading from source extension with trackID: %s (skipBuiltInFallback: %v)\n", trackID, skipBuiltIn)

			// Build output path
			outputPath := buildOutputPath(req)

			// Download directly using the track ID from the extension
			result, err := provider.Download(trackID, req.Quality, outputPath, func(percent int) {
				if req.ItemID != "" {
					SetItemProgress(req.ItemID, float64(percent), 0, 0)
				}
			})

			if err == nil && result.Success {
				resp := &DownloadResponse{
					Success:          true,
					Message:          "Downloaded from " + req.Source,
					FilePath:         result.FilePath,
					ActualBitDepth:   result.BitDepth,
					ActualSampleRate: result.SampleRate,
					Service:          req.Source,
				}

				// If extension has skipMetadataEnrichment, copy metadata
				if ext.Manifest.SkipMetadataEnrichment {
					resp.SkipMetadataEnrichment = true
					if result.Title != "" {
						resp.Title = result.Title
					}
					if result.Artist != "" {
						resp.Artist = result.Artist
					}
					if result.Album != "" {
						resp.Album = result.Album
					}
					if result.AlbumArtist != "" {
						resp.AlbumArtist = result.AlbumArtist
					}
					if result.TrackNumber > 0 {
						resp.TrackNumber = result.TrackNumber
					}
					if result.DiscNumber > 0 {
						resp.DiscNumber = result.DiscNumber
					}
					if result.ReleaseDate != "" {
						resp.ReleaseDate = result.ReleaseDate
					}
					if result.CoverURL != "" {
						resp.CoverURL = result.CoverURL
					}
					if result.ISRC != "" {
						resp.ISRC = result.ISRC
					}
				}

				return resp, nil
			}

			if err != nil {
				lastErr = err
			} else if result.ErrorMessage != "" {
				lastErr = fmt.Errorf("%s", result.ErrorMessage)
			}
			GoLog("[DownloadWithExtensionFallback] Source extension %s failed: %v\n", req.Source, lastErr)

			// If skipBuiltInFallback is true, don't continue to other providers
			if skipBuiltIn {
				GoLog("[DownloadWithExtensionFallback] skipBuiltInFallback is true, not trying other providers\n")
				return &DownloadResponse{
					Success:   false,
					Error:     fmt.Sprintf("Download failed: %v", lastErr),
					ErrorType: "extension_error",
					Service:   req.Source,
				}, nil
			}
		} else {
			GoLog("[DownloadWithExtensionFallback] Source extension %s not available or not a download provider\n", req.Source)
		}
	}

	// Continue with priority list
	for _, providerID := range priority {
		// Skip if we already tried this as source
		if providerID == req.Source {
			continue
		}

		// Skip built-in providers if skipBuiltIn is set
		if skipBuiltIn && isBuiltInProvider(providerID) {
			GoLog("[DownloadWithExtensionFallback] Skipping built-in provider %s (skipBuiltInFallback)\n", providerID)
			continue
		}

		GoLog("[DownloadWithExtensionFallback] Trying provider: %s\n", providerID)

		if isBuiltInProvider(providerID) {
			// Use built-in provider
			result, err := tryBuiltInProvider(providerID, req)
			if err == nil && result.Success {
				result.Service = providerID
				return result, nil
			}
			if err != nil {
				lastErr = err
				GoLog("[DownloadWithExtensionFallback] %s failed: %v\n", providerID, err)
			}
		} else {
			// Try extension provider
			ext, err := extManager.GetExtension(providerID)
			if err != nil || !ext.Enabled || ext.Error != "" {
				GoLog("[DownloadWithExtensionFallback] Extension %s not available\n", providerID)
				continue
			}

			if !ext.Manifest.IsDownloadProvider() {
				continue
			}

			provider := NewExtensionProviderWrapper(ext)

			// Check availability first
			availability, err := provider.CheckAvailability(req.ISRC, req.TrackName, req.ArtistName)
			if err != nil || !availability.Available {
				GoLog("[DownloadWithExtensionFallback] %s: not available\n", providerID)
				if err != nil {
					lastErr = err
				}
				continue
			}

			// Build output path
			outputPath := buildOutputPath(req)

			// Download
			result, err := provider.Download(availability.TrackID, req.Quality, outputPath, func(percent int) {
				// Update progress
				if req.ItemID != "" {
					SetItemProgress(req.ItemID, float64(percent), 0, 0)
				}
			})

			if err == nil && result.Success {
				resp := &DownloadResponse{
					Success:          true,
					Message:          "Downloaded from " + providerID,
					FilePath:         result.FilePath,
					ActualBitDepth:   result.BitDepth,
					ActualSampleRate: result.SampleRate,
					Service:          providerID,
				}

				// If extension has skipMetadataEnrichment and returned metadata, use it
				if ext.Manifest.SkipMetadataEnrichment {
					resp.SkipMetadataEnrichment = true
					// Copy metadata from extension result if provided
					if result.Title != "" {
						resp.Title = result.Title
					}
					if result.Artist != "" {
						resp.Artist = result.Artist
					}
					if result.Album != "" {
						resp.Album = result.Album
					}
					if result.AlbumArtist != "" {
						resp.AlbumArtist = result.AlbumArtist
					}
					if result.TrackNumber > 0 {
						resp.TrackNumber = result.TrackNumber
					}
					if result.DiscNumber > 0 {
						resp.DiscNumber = result.DiscNumber
					}
					if result.ReleaseDate != "" {
						resp.ReleaseDate = result.ReleaseDate
					}
					if result.CoverURL != "" {
						resp.CoverURL = result.CoverURL
					}
					if result.ISRC != "" {
						resp.ISRC = result.ISRC
					}
				}

				return resp, nil
			}

			if err != nil {
				lastErr = err
			} else if result.ErrorMessage != "" {
				lastErr = fmt.Errorf("%s", result.ErrorMessage)
			}
			GoLog("[DownloadWithExtensionFallback] %s failed: %v\n", providerID, lastErr)
		}
	}

	if lastErr != nil {
		return &DownloadResponse{
			Success:   false,
			Error:     fmt.Sprintf("All providers failed. Last error: %v", lastErr),
			ErrorType: "not_found",
		}, nil
	}

	return &DownloadResponse{
		Success:   false,
		Error:     "No providers available",
		ErrorType: "not_found",
	}, nil
}

// tryBuiltInProvider attempts download from a built-in provider
func tryBuiltInProvider(providerID string, req DownloadRequest) (*DownloadResponse, error) {
	req.Service = providerID

	var result DownloadResult
	var err error

	switch providerID {
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
		return nil, fmt.Errorf("unknown built-in provider: %s", providerID)
	}

	if err != nil {
		return nil, err
	}

	return &DownloadResponse{
		Success:          true,
		Message:          "Download complete",
		FilePath:         result.FilePath,
		ActualBitDepth:   result.BitDepth,
		ActualSampleRate: result.SampleRate,
		Title:            result.Title,
		Artist:           result.Artist,
		Album:            result.Album,
		ReleaseDate:      result.ReleaseDate,
		TrackNumber:      result.TrackNumber,
		DiscNumber:       result.DiscNumber,
		ISRC:             result.ISRC,
	}, nil
}

// buildOutputPath builds the output file path from request
func buildOutputPath(req DownloadRequest) string {
	metadata := map[string]interface{}{
		"title":        req.TrackName,
		"artist":       req.ArtistName,
		"album":        req.AlbumName,
		"album_artist": req.AlbumArtist,
		"track_number": req.TrackNumber,
		"disc_number":  req.DiscNumber,
		"isrc":         req.ISRC,
	}

	filename := buildFilenameFromTemplate(req.FilenameFormat, metadata)
	if filename == "" {
		filename = sanitizeFilename(fmt.Sprintf("%s - %s", req.ArtistName, req.TrackName))
	}

	return fmt.Sprintf("%s/%s.flac", req.OutputDir, filename)
}

// ==================== Custom Search ====================

// CustomSearch performs a custom search using an extension's search function
func (p *ExtensionProviderWrapper) CustomSearch(query string, options map[string]interface{}) ([]ExtTrackMetadata, error) {
	if !p.extension.Manifest.HasCustomSearch() {
		return nil, fmt.Errorf("extension '%s' does not support custom search", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	// Convert options to JSON
	optionsJSON, _ := json.Marshal(options)

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.customSearch === 'function') {
				return extension.customSearch(%q, %s);
			}
			return null;
		})()
	`, query, string(optionsJSON))

	result, err := p.vm.RunString(script)
	if err != nil {
		return nil, fmt.Errorf("customSearch failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		// Return empty array instead of error for no results
		return []ExtTrackMetadata{}, nil
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal result: %w", err)
	}

	var tracks []ExtTrackMetadata
	if err := json.Unmarshal(jsonBytes, &tracks); err != nil {
		return nil, fmt.Errorf("failed to parse search result: %w", err)
	}

	// Return empty array if no tracks found
	if tracks == nil {
		tracks = []ExtTrackMetadata{}
	}

	// Set provider ID on all tracks
	for i := range tracks {
		tracks[i].ProviderID = p.extension.ID
	}

	return tracks, nil
}

// ==================== Custom Track Matching ====================

// MatchTrackResult represents the result of custom track matching
type MatchTrackResult struct {
	Matched    bool    `json:"matched"`
	TrackID    string  `json:"track_id,omitempty"`
	Confidence float64 `json:"confidence,omitempty"`
	Reason     string  `json:"reason,omitempty"`
}

// MatchTrack uses extension's custom matching algorithm
func (p *ExtensionProviderWrapper) MatchTrack(sourceTrack map[string]interface{}, candidates []map[string]interface{}) (*MatchTrackResult, error) {
	if !p.extension.Manifest.HasCustomMatching() {
		return nil, fmt.Errorf("extension '%s' does not support custom matching", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	sourceJSON, _ := json.Marshal(sourceTrack)
	candidatesJSON, _ := json.Marshal(candidates)

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.matchTrack === 'function') {
				return extension.matchTrack(%s, %s);
			}
			return null;
		})()
	`, string(sourceJSON), string(candidatesJSON))

	result, err := p.vm.RunString(script)
	if err != nil {
		return nil, fmt.Errorf("matchTrack failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return &MatchTrackResult{Matched: false, Reason: "not implemented"}, nil
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal result: %w", err)
	}

	var matchResult MatchTrackResult
	if err := json.Unmarshal(jsonBytes, &matchResult); err != nil {
		return nil, fmt.Errorf("failed to parse match result: %w", err)
	}

	return &matchResult, nil
}

// ==================== Post-Processing ====================

// PostProcessResult represents the result of post-processing
type PostProcessResult struct {
	Success     bool   `json:"success"`
	NewFilePath string `json:"new_file_path,omitempty"`
	Error       string `json:"error,omitempty"`
	// Additional metadata that may have changed
	BitDepth   int `json:"bit_depth,omitempty"`
	SampleRate int `json:"sample_rate,omitempty"`
}

// PostProcess runs post-processing hooks on a downloaded file
func (p *ExtensionProviderWrapper) PostProcess(filePath string, metadata map[string]interface{}, hookID string) (*PostProcessResult, error) {
	if !p.extension.Manifest.HasPostProcessing() {
		return nil, fmt.Errorf("extension '%s' does not support post-processing", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	metadataJSON, _ := json.Marshal(metadata)

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.postProcess === 'function') {
				return extension.postProcess(%q, %s, %q);
			}
			return null;
		})()
	`, filePath, string(metadataJSON), hookID)

	result, err := p.vm.RunString(script)
	if err != nil {
		return &PostProcessResult{
			Success: false,
			Error:   err.Error(),
		}, nil
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return &PostProcessResult{
			Success: false,
			Error:   "postProcess returned null",
		}, nil
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return &PostProcessResult{
			Success: false,
			Error:   fmt.Sprintf("failed to marshal result: %v", err),
		}, nil
	}

	var postResult PostProcessResult
	if err := json.Unmarshal(jsonBytes, &postResult); err != nil {
		return &PostProcessResult{
			Success: false,
			Error:   fmt.Sprintf("failed to parse result: %v", err),
		}, nil
	}

	return &postResult, nil
}

// ==================== Extension Manager Advanced Methods ====================

// GetSearchProviders returns all extensions that provide custom search
func (m *ExtensionManager) GetSearchProviders() []*ExtensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*ExtensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.HasCustomSearch() && ext.Error == "" {
			providers = append(providers, NewExtensionProviderWrapper(ext))
		}
	}
	return providers
}

// GetPostProcessingProviders returns all extensions that provide post-processing
func (m *ExtensionManager) GetPostProcessingProviders() []*ExtensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*ExtensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.HasPostProcessing() && ext.Error == "" {
			providers = append(providers, NewExtensionProviderWrapper(ext))
		}
	}
	return providers
}

// RunPostProcessing runs all enabled post-processing hooks on a file
func (m *ExtensionManager) RunPostProcessing(filePath string, metadata map[string]interface{}) (*PostProcessResult, error) {
	providers := m.GetPostProcessingProviders()
	if len(providers) == 0 {
		return &PostProcessResult{Success: true, NewFilePath: filePath}, nil
	}

	currentPath := filePath
	for _, provider := range providers {
		hooks := provider.extension.Manifest.GetPostProcessingHooks()
		for _, hook := range hooks {
			// Check if hook is enabled (TODO: check user settings)
			if !hook.DefaultEnabled {
				continue
			}

			// Check if format is supported
			ext := strings.ToLower(filepath.Ext(currentPath))
			if len(hook.SupportedFormats) > 0 {
				supported := false
				for _, format := range hook.SupportedFormats {
					if "."+format == ext || format == ext[1:] {
						supported = true
						break
					}
				}
				if !supported {
					continue
				}
			}

			GoLog("[PostProcess] Running hook %s from %s on %s\n", hook.ID, provider.extension.ID, currentPath)

			result, err := provider.PostProcess(currentPath, metadata, hook.ID)
			if err != nil {
				GoLog("[PostProcess] Hook %s failed: %v\n", hook.ID, err)
				continue
			}

			if result.Success && result.NewFilePath != "" {
				currentPath = result.NewFilePath
			}
		}
	}

	return &PostProcessResult{Success: true, NewFilePath: currentPath}, nil
}
