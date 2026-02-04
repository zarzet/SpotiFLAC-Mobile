// Package gobackend provides extension provider interfaces
package gobackend

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"path/filepath"
	"strings"
	"sync"
	"time"

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
	Images      string `json:"images,omitempty"`
	ReleaseDate string `json:"release_date,omitempty"`
	TrackNumber int    `json:"track_number,omitempty"`
	DiscNumber  int    `json:"disc_number,omitempty"`
	ISRC        string `json:"isrc,omitempty"`
	ProviderID  string `json:"provider_id"`
	ItemType    string `json:"item_type,omitempty"`
	AlbumType   string `json:"album_type,omitempty"`

	TidalID       string            `json:"tidal_id,omitempty"`
	QobuzID       string            `json:"qobuz_id,omitempty"`
	DeezerID      string            `json:"deezer_id,omitempty"`
	SpotifyID     string            `json:"spotify_id,omitempty"`
	ExternalLinks map[string]string `json:"external_links,omitempty"`

	Label     string `json:"label,omitempty"`
	Copyright string `json:"copyright,omitempty"`
	Genre     string `json:"genre,omitempty"`
}

func (t *ExtTrackMetadata) ResolvedCoverURL() string {
	if t.CoverURL != "" {
		return t.CoverURL
	}
	return t.Images
}

type ExtAlbumMetadata struct {
	ID          string             `json:"id"`
	Name        string             `json:"name"`
	Artists     string             `json:"artists"`
	ArtistID    string             `json:"artist_id,omitempty"`
	CoverURL    string             `json:"cover_url,omitempty"`
	ReleaseDate string             `json:"release_date,omitempty"`
	TotalTracks int                `json:"total_tracks"`
	AlbumType   string             `json:"album_type,omitempty"`
	Tracks      []ExtTrackMetadata `json:"tracks"`
	ProviderID  string             `json:"provider_id"`
}

type ExtArtistMetadata struct {
	ID          string             `json:"id"`
	Name        string             `json:"name"`
	ImageURL    string             `json:"image_url,omitempty"`
	HeaderImage string             `json:"header_image,omitempty"`
	Listeners   int                `json:"listeners,omitempty"`
	Albums      []ExtAlbumMetadata `json:"albums,omitempty"`
	TopTracks   []ExtTrackMetadata `json:"top_tracks,omitempty"`
	ProviderID  string             `json:"provider_id"`
}

type ExtSearchResult struct {
	Tracks []ExtTrackMetadata `json:"tracks"`
	Total  int                `json:"total"`
}

type ExtAvailabilityResult struct {
	Available bool   `json:"available"`
	Reason    string `json:"reason,omitempty"`
	TrackID   string `json:"track_id,omitempty"`
}

type ExtDownloadURLResult struct {
	URL        string `json:"url"`
	Format     string `json:"format"`
	BitDepth   int    `json:"bit_depth,omitempty"`
	SampleRate int    `json:"sample_rate,omitempty"`
}

type ExtDownloadResult struct {
	Success      bool   `json:"success"`
	FilePath     string `json:"file_path,omitempty"`
	BitDepth     int    `json:"bit_depth,omitempty"`
	SampleRate   int    `json:"sample_rate,omitempty"`
	ErrorMessage string `json:"error_message,omitempty"`
	ErrorType    string `json:"error_type,omitempty"`

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

type ExtensionProviderWrapper struct {
	extension *LoadedExtension
	vm        *goja.Runtime
}

func NewExtensionProviderWrapper(ext *LoadedExtension) *ExtensionProviderWrapper {
	return &ExtensionProviderWrapper{
		extension: ext,
		vm:        ext.VM,
	}
}

func (p *ExtensionProviderWrapper) SearchTracks(query string, limit int) (*ExtSearchResult, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.searchTracks === 'function') {
				return extension.searchTracks(%q, %d);
			}
			return null;
		})()
	`, query, limit)

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			return nil, fmt.Errorf("searchTracks timeout: extension took too long to respond")
		}
		return nil, fmt.Errorf("searchTracks failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return nil, fmt.Errorf("searchTracks returned null")
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal result: %w", err)
	}

	var searchResult ExtSearchResult

	if err := json.Unmarshal(jsonBytes, &searchResult); err != nil {
		var tracks []ExtTrackMetadata
		if arrErr := json.Unmarshal(jsonBytes, &tracks); arrErr != nil {
			return nil, fmt.Errorf("failed to parse search result: %w (also tried array: %v)", err, arrErr)
		}
		searchResult = ExtSearchResult{
			Tracks: tracks,
			Total:  len(tracks),
		}
	}

	for i := range searchResult.Tracks {
		searchResult.Tracks[i].ProviderID = p.extension.ID
	}

	return &searchResult, nil
}

func (p *ExtensionProviderWrapper) GetTrack(trackID string) (*ExtTrackMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.getTrack === 'function') {
				return extension.getTrack(%q);
			}
			return null;
		})()
	`, trackID)

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			return nil, fmt.Errorf("getTrack timeout: extension took too long to respond")
		}
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

func (p *ExtensionProviderWrapper) GetAlbum(albumID string) (*ExtAlbumMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.getAlbum === 'function') {
				return extension.getAlbum(%q);
			}
			return null;
		})()
	`, albumID)

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			return nil, fmt.Errorf("getAlbum timeout: extension took too long to respond")
		}
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

func (p *ExtensionProviderWrapper) GetArtist(artistID string) (*ExtArtistMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.getArtist === 'function') {
				return extension.getArtist(%q);
			}
			return null;
		})()
	`, artistID)

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			return nil, fmt.Errorf("getArtist timeout: extension took too long to respond")
		}
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

func (p *ExtensionProviderWrapper) EnrichTrack(track *ExtTrackMetadata) (*ExtTrackMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return track, nil
	}

	if !p.extension.Enabled {
		return track, nil
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	trackJSON, err := json.Marshal(track)
	if err != nil {
		GoLog("[Extension] EnrichTrack: failed to marshal track: %v\n", err)
		return track, nil
	}

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.enrichTrack === 'function') {
				var track = %s;
				return extension.enrichTrack(track);
			}
			return null;
		})()
	`, string(trackJSON))

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			GoLog("[Extension] EnrichTrack timeout for %s\n", p.extension.ID)
		} else {
			GoLog("[Extension] EnrichTrack error for %s: %v\n", p.extension.ID, err)
		}
		return track, nil
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return track, nil
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		GoLog("[Extension] EnrichTrack: failed to marshal result: %v\n", err)
		return track, nil
	}

	var enrichedTrack ExtTrackMetadata
	if err := json.Unmarshal(jsonBytes, &enrichedTrack); err != nil {
		GoLog("[Extension] EnrichTrack: failed to parse enriched track: %v\n", err)
		return track, nil
	}

	enrichedTrack.ProviderID = track.ProviderID

	return &enrichedTrack, nil
}

func (p *ExtensionProviderWrapper) CheckAvailability(isrc, trackName, artistName string) (*ExtAvailabilityResult, error) {
	if !p.extension.Manifest.IsDownloadProvider() {
		return nil, fmt.Errorf("extension '%s' is not a download provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.checkAvailability === 'function') {
				return extension.checkAvailability(%q, %q, %q);
			}
			return null;
		})()
	`, isrc, trackName, artistName)

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			return nil, fmt.Errorf("checkAvailability timeout: extension took too long to respond")
		}
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

func (p *ExtensionProviderWrapper) GetDownloadURL(trackID, quality string) (*ExtDownloadURLResult, error) {
	if !p.extension.Manifest.IsDownloadProvider() {
		return nil, fmt.Errorf("extension '%s' is not a download provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.getDownloadUrl === 'function') {
				return extension.getDownloadUrl(%q, %q);
			}
			return null;
		})()
	`, trackID, quality)

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			return nil, fmt.Errorf("getDownloadUrl timeout: extension took too long to respond")
		}
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

const ExtDownloadTimeout = 5 * time.Minute

func (p *ExtensionProviderWrapper) Download(trackID, quality, outputPath string, onProgress func(percent int)) (*ExtDownloadResult, error) {
	if !p.extension.Manifest.IsDownloadProvider() {
		return nil, fmt.Errorf("extension '%s' is not a download provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	p.vm.Set("__onProgress", func(call goja.FunctionCall) goja.Value {
		if len(call.Arguments) > 0 {
			percent := int(call.Arguments[0].ToInteger())
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

	result, err := RunWithTimeoutAndRecover(p.vm, script, ExtDownloadTimeout)
	if err != nil {
		errMsg := err.Error()
		errType := "script_error"
		if IsTimeoutError(err) {
			errMsg = "download timeout: extension took too long to complete"
			errType = "timeout"
		}
		return &ExtDownloadResult{
			Success:      false,
			ErrorMessage: errMsg,
			ErrorType:    errType,
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

var providerPriority []string
var providerPriorityMu sync.RWMutex

var metadataProviderPriority []string
var metadataProviderPriorityMu sync.RWMutex
func persist(key string, value any) {
	if store := GetExtensionSettingsStore(); store != nil {
		if err := store.Set("_system", key, value); err != nil {
			GoLog("[Extension] Failed to persist setting %s: %v\n", key, err)
		}
	}
}

func SetProviderPriority(providerIDs []string) {
	providerPriorityMu.Lock()
	defer providerPriorityMu.Unlock()
	providerPriority = providerIDs
	GoLog("[Extension] Download provider priority set: %v\n", providerIDs)
	persist("provider_priority", providerIDs)
}

func GetProviderPriority() []string {
	providerPriorityMu.RLock()
	if len(providerPriority) > 0 {
		res := make([]string, len(providerPriority))
		copy(res, providerPriority)
		providerPriorityMu.RUnlock()
		return res
	}
	providerPriorityMu.RUnlock()

	providerPriorityMu.Lock()
	defer providerPriorityMu.Unlock()

	if len(providerPriority) > 0 {
		res := make([]string, len(providerPriority))
		copy(res, providerPriority)
		return res
	}

	if loaded := loadPriorityFromSettings("provider_priority"); len(loaded) > 0 {
		providerPriority = loaded
		GoLog("[Extension] Loaded provider priority: %v\n", loaded)
	} else {
		providerPriority = []string{"tidal", "qobuz", "amazon"}
		GoLog("[Extension] Using default provider priority: %v\n", providerPriority)
	}

	result := make([]string, len(providerPriority))
	copy(result, providerPriority)
	return result
}

func SetMetadataProviderPriority(providerIDs []string) {
	metadataProviderPriorityMu.Lock()
	defer metadataProviderPriorityMu.Unlock()
	metadataProviderPriority = providerIDs
	GoLog("[Extension] Metadata provider priority set: %v\n", providerIDs)
	persist("metadata_provider_priority", providerIDs)
}

func GetMetadataProviderPriority() []string {
	metadataProviderPriorityMu.RLock()
	if len(metadataProviderPriority) > 0 {
		res := make([]string, len(metadataProviderPriority))
		copy(res, metadataProviderPriority)
		metadataProviderPriorityMu.RUnlock()
		return res
	}
	metadataProviderPriorityMu.RUnlock()

	metadataProviderPriorityMu.Lock()
	defer metadataProviderPriorityMu.Unlock()

	if len(metadataProviderPriority) > 0 {
		res := make([]string, len(metadataProviderPriority))
		copy(res, metadataProviderPriority)
		return res
	}

	if loaded := loadPriorityFromSettings("metadata_provider_priority"); len(loaded) > 0 {
		metadataProviderPriority = loaded
		GoLog("[Extension] Loaded metadata provider priority: %v\n", loaded)
	} else {
		metadataProviderPriority = []string{"deezer", "spotify"}
		GoLog("[Extension] Using default metadata provider priority: %v\n", metadataProviderPriority)
	}

	result := make([]string, len(metadataProviderPriority))
	copy(result, metadataProviderPriority)
	return result
}

func loadPriorityFromSettings(key string) []string {
	if store := GetExtensionSettingsStore(); store != nil {
		if val, err := store.Get("_system", key); err == nil {
			if list, ok := val.([]interface{}); ok {
				out := make([]string, 0, len(list))
				for _, v := range list {
					if s, ok := v.(string); ok {
						out = append(out, s)
					}
				}
				return out
			}
		}
	}
	return nil
}

func isBuiltInProvider(providerID string) bool {
	switch providerID {
	case "tidal", "qobuz", "amazon", "deezer":
		return true
	default:
		return false
	}
}

func DownloadWithExtensionFallback(req DownloadRequest) (*DownloadResponse, error) {
	priority := GetProviderPriority()
	extManager := GetExtensionManager()

	if req.Service != "" && isBuiltInProvider(req.Service) {
		GoLog("[DownloadWithExtensionFallback] User selected service: %s, prioritizing it first\n", req.Service)
		newPriority := []string{req.Service}
		for _, p := range priority {
			if p != req.Service {
				newPriority = append(newPriority, p)
			}
		}
		priority = newPriority
		GoLog("[DownloadWithExtensionFallback] New priority order: %v\n", priority)
	}

	var lastErr error
	var skipBuiltIn bool

	if req.Source != "" && !isBuiltInProvider(req.Source) {
		ext, err := extManager.GetExtension(req.Source)
		if err == nil && ext.Enabled && ext.Error == "" && ext.Manifest.IsMetadataProvider() {
			GoLog("[DownloadWithExtensionFallback] Enriching track from extension '%s'...\n", req.Source)

			provider := NewExtensionProviderWrapper(ext)
			trackMeta := &ExtTrackMetadata{
				ID:          req.SpotifyID,
				Name:        req.TrackName,
				Artists:     req.ArtistName,
				AlbumName:   req.AlbumName,
				DurationMS:  req.DurationMS,
				ISRC:        req.ISRC,
				ReleaseDate: req.ReleaseDate,
				TrackNumber: req.TrackNumber,
				DiscNumber:  req.DiscNumber,
				ProviderID:  req.Source,
			}

			enrichedTrack, err := provider.EnrichTrack(trackMeta)
			if err == nil && enrichedTrack != nil {
				if enrichedTrack.ISRC != "" && enrichedTrack.ISRC != req.ISRC {
					GoLog("[DownloadWithExtensionFallback] ISRC enriched: %s -> %s\n", req.ISRC, enrichedTrack.ISRC)
					req.ISRC = enrichedTrack.ISRC
				}
				if enrichedTrack.TidalID != "" {
					GoLog("[DownloadWithExtensionFallback] Tidal ID from Odesli: %s\n", enrichedTrack.TidalID)
					req.TidalID = enrichedTrack.TidalID
				}
				if enrichedTrack.QobuzID != "" {
					GoLog("[DownloadWithExtensionFallback] Qobuz ID from Odesli: %s\n", enrichedTrack.QobuzID)
					req.QobuzID = enrichedTrack.QobuzID
				}
				if enrichedTrack.DeezerID != "" {
					GoLog("[DownloadWithExtensionFallback] Deezer ID from Odesli: %s\n", enrichedTrack.DeezerID)
					req.DeezerID = enrichedTrack.DeezerID
				}
				if enrichedTrack.Name != "" {
					req.TrackName = enrichedTrack.Name
				}
				if enrichedTrack.Artists != "" {
					req.ArtistName = enrichedTrack.Artists
				}
				if enrichedTrack.Label != "" && req.Label == "" {
					GoLog("[DownloadWithExtensionFallback] Label from enrichment: %s\n", enrichedTrack.Label)
					req.Label = enrichedTrack.Label
				}
				if enrichedTrack.Copyright != "" && req.Copyright == "" {
					GoLog("[DownloadWithExtensionFallback] Copyright from enrichment: %s\n", enrichedTrack.Copyright)
					req.Copyright = enrichedTrack.Copyright
				}
				if enrichedTrack.Genre != "" && req.Genre == "" {
					GoLog("[DownloadWithExtensionFallback] Genre from enrichment: %s\n", enrichedTrack.Genre)
					req.Genre = enrichedTrack.Genre
				}
				if enrichedTrack.ReleaseDate != "" && req.ReleaseDate == "" {
					GoLog("[DownloadWithExtensionFallback] ReleaseDate from enrichment: %s\n", enrichedTrack.ReleaseDate)
					req.ReleaseDate = enrichedTrack.ReleaseDate
				}
			}
		}
	}

	if req.Source != "" && !isBuiltInProvider(req.Source) {
		GoLog("[DownloadWithExtensionFallback] Track source is extension '%s', trying it first\n", req.Source)

		ext, err := extManager.GetExtension(req.Source)
		if err == nil && ext.Enabled && ext.Error == "" && ext.Manifest.IsDownloadProvider() {
			skipBuiltIn = ext.Manifest.SkipBuiltInFallback

			provider := NewExtensionProviderWrapper(ext)

			trackID := req.SpotifyID

			GoLog("[DownloadWithExtensionFallback] Downloading from source extension with trackID: %s (skipBuiltInFallback: %v)\n", trackID, skipBuiltIn)

			outputPath := buildOutputPath(req)

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
					Genre:            req.Genre,
					Label:            req.Label,
					Copyright:        req.Copyright,
				}

				if req.Genre != "" || req.Label != "" {
					if err := EmbedGenreLabel(result.FilePath, req.Genre, req.Label); err != nil {
						GoLog("[DownloadWithExtensionFallback] Warning: failed to embed genre/label: %v\n", err)
					} else {
						GoLog("[DownloadWithExtensionFallback] Embedded genre=%q label=%q\n", req.Genre, req.Label)
					}
				}

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
				if errors.Is(err, ErrDownloadCancelled) {
					return &DownloadResponse{
						Success:   false,
						Error:     "Download cancelled",
						ErrorType: "cancelled",
						Service:   req.Source,
					}, nil
				}
				lastErr = err
			} else if result.ErrorMessage != "" {
				lastErr = fmt.Errorf("%s", result.ErrorMessage)
			}
			GoLog("[DownloadWithExtensionFallback] Source extension %s failed: %v\n", req.Source, lastErr)

			if skipBuiltIn {
				GoLog("[DownloadWithExtensionFallback] skipBuiltInFallback is true, not trying other providers\n")
				return &DownloadResponse{
					Success:   false,
					Error:     "Download failed: " + lastErr.Error(),
					ErrorType: "extension_error",
					Service:   req.Source,
				}, nil
			}
		} else {
			GoLog("[DownloadWithExtensionFallback] Source extension %s not available or not a download provider\n", req.Source)
		}
	}

	for _, providerID := range priority {
		if providerID == req.Source {
			continue
		}

		if skipBuiltIn && isBuiltInProvider(providerID) {
			GoLog("[DownloadWithExtensionFallback] Skipping built-in provider %s (skipBuiltInFallback)\n", providerID)
			continue
		}

		GoLog("[DownloadWithExtensionFallback] Trying provider: %s\n", providerID)

		if isBuiltInProvider(providerID) {
			if (req.Genre == "" || req.Label == "") && req.ISRC != "" {
				GoLog("[DownloadWithExtensionFallback] Enriching extended metadata from Deezer for ISRC: %s\n", req.ISRC)
				ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
				deezerClient := GetDeezerClient()
				extMeta, err := deezerClient.GetExtendedMetadataByISRC(ctx, req.ISRC)
				cancel()
				if err == nil && extMeta != nil {
					if req.Genre == "" && extMeta.Genre != "" {
						req.Genre = extMeta.Genre
						GoLog("[DownloadWithExtensionFallback] Genre from Deezer: %s\n", req.Genre)
					}
					if req.Label == "" && extMeta.Label != "" {
						req.Label = extMeta.Label
						GoLog("[DownloadWithExtensionFallback] Label from Deezer: %s\n", req.Label)
					}
				} else if err != nil {
					GoLog("[DownloadWithExtensionFallback] Failed to get extended metadata from Deezer: %v\n", err)
				}
			}

			result, err := tryBuiltInProvider(providerID, req)
			if err == nil && result.Success {
				result.Service = providerID
				if req.Label != "" {
					result.Label = req.Label
				}
				if req.Copyright != "" {
					result.Copyright = req.Copyright
				}
				if req.Genre != "" {
					result.Genre = req.Genre
				}
				if req.ReleaseDate != "" && result.ReleaseDate == "" {
					result.ReleaseDate = req.ReleaseDate
				}
				return result, nil
			}
			if err != nil {
				if errors.Is(err, ErrDownloadCancelled) {
					return &DownloadResponse{
						Success:   false,
						Error:     "Download cancelled",
						ErrorType: "cancelled",
						Service:   providerID,
					}, nil
				}
				lastErr = err
				GoLog("[DownloadWithExtensionFallback] %s failed: %v\n", providerID, err)
			}
		} else {
			ext, err := extManager.GetExtension(providerID)
			if err != nil || !ext.Enabled || ext.Error != "" {
				GoLog("[DownloadWithExtensionFallback] Extension %s not available\n", providerID)
				continue
			}

			if !ext.Manifest.IsDownloadProvider() {
				continue
			}

			provider := NewExtensionProviderWrapper(ext)

			availability, err := provider.CheckAvailability(req.ISRC, req.TrackName, req.ArtistName)
			if err != nil || !availability.Available {
				GoLog("[DownloadWithExtensionFallback] %s: not available\n", providerID)
				if err != nil {
					lastErr = err
				}
				continue
			}

			outputPath := buildOutputPath(req)

			result, err := provider.Download(availability.TrackID, req.Quality, outputPath, func(percent int) {
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
					Genre:            req.Genre,
					Label:            req.Label,
					Copyright:        req.Copyright,
				}

				if req.Genre != "" || req.Label != "" {
					if err := EmbedGenreLabel(result.FilePath, req.Genre, req.Label); err != nil {
						GoLog("[DownloadWithExtensionFallback] Warning: failed to embed genre/label: %v\n", err)
					} else {
						GoLog("[DownloadWithExtensionFallback] Embedded genre=%q label=%q\n", req.Genre, req.Label)
					}
				}

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
				if errors.Is(err, ErrDownloadCancelled) {
					return &DownloadResponse{
						Success:   false,
						Error:     "Download cancelled",
						ErrorType: "cancelled",
						Service:   providerID,
					}, nil
				}
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
			Error:     "All providers failed. Last error: " + lastErr.Error(),
			ErrorType: "not_found",
		}, nil
	}

	return &DownloadResponse{
		Success:   false,
		Error:     "No providers available",
		ErrorType: "not_found",
	}, nil
}

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
		Genre:            req.Genre,
		Label:            req.Label,
		Copyright:        req.Copyright,
	}, nil
}

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

func (p *ExtensionProviderWrapper) CustomSearch(query string, options map[string]interface{}) ([]ExtTrackMetadata, error) {
	if !p.extension.Manifest.HasCustomSearch() {
		return nil, fmt.Errorf("extension '%s' does not support custom search", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	optionsJSON, _ := json.Marshal(options)

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.customSearch === 'function') {
				return extension.customSearch(%q, %s);
			}
			return null;
		})()
	`, query, string(optionsJSON))

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			return nil, fmt.Errorf("customSearch timeout: extension took too long to respond")
		}
		return nil, fmt.Errorf("customSearch failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
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

	if tracks == nil {
		tracks = []ExtTrackMetadata{}
	}

	for i := range tracks {
		tracks[i].ProviderID = p.extension.ID
	}

	return tracks, nil
}

type ExtURLHandleResult struct {
	Type     string             `json:"type"`
	Track    *ExtTrackMetadata  `json:"track,omitempty"`
	Tracks   []ExtTrackMetadata `json:"tracks,omitempty"`
	Album    *ExtAlbumMetadata  `json:"album,omitempty"`
	Artist   *ExtArtistMetadata `json:"artist,omitempty"`
	Name     string             `json:"name,omitempty"`
	CoverURL string             `json:"cover_url,omitempty"`
}

func (p *ExtensionProviderWrapper) HandleURL(url string) (*ExtURLHandleResult, error) {
	if !p.extension.Manifest.HasURLHandler() {
		return nil, fmt.Errorf("extension '%s' does not support URL handling", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.handleUrl === 'function') {
				return extension.handleUrl(%q);
			}
			return null;
		})()
	`, url)

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			return nil, fmt.Errorf("handleUrl timeout: extension took too long to respond")
		}
		return nil, fmt.Errorf("handleUrl failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return nil, fmt.Errorf("handleUrl returned null - URL not recognized")
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal result: %w", err)
	}

	var handleResult ExtURLHandleResult
	if err := json.Unmarshal(jsonBytes, &handleResult); err != nil {
		return nil, fmt.Errorf("failed to parse URL handle result: %w", err)
	}

	if handleResult.Track != nil {
		handleResult.Track.ProviderID = p.extension.ID
	}
	for i := range handleResult.Tracks {
		handleResult.Tracks[i].ProviderID = p.extension.ID
	}
	if handleResult.Album != nil {
		handleResult.Album.ProviderID = p.extension.ID
		for i := range handleResult.Album.Tracks {
			handleResult.Album.Tracks[i].ProviderID = p.extension.ID
		}
	}
	if handleResult.Artist != nil {
		handleResult.Artist.ProviderID = p.extension.ID
		for i := range handleResult.Artist.Albums {
			handleResult.Artist.Albums[i].ProviderID = p.extension.ID
			for j := range handleResult.Artist.Albums[i].Tracks {
				handleResult.Artist.Albums[i].Tracks[j].ProviderID = p.extension.ID
			}
		}
		for i := range handleResult.Artist.TopTracks {
			handleResult.Artist.TopTracks[i].ProviderID = p.extension.ID
		}
	}

	return &handleResult, nil
}

type MatchTrackResult struct {
	Matched    bool    `json:"matched"`
	TrackID    string  `json:"track_id,omitempty"`
	Confidence float64 `json:"confidence,omitempty"`
	Reason     string  `json:"reason,omitempty"`
}

func (p *ExtensionProviderWrapper) MatchTrack(sourceTrack map[string]interface{}, candidates []map[string]interface{}) (*MatchTrackResult, error) {
	if !p.extension.Manifest.HasCustomMatching() {
		return nil, fmt.Errorf("extension '%s' does not support custom matching", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

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

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			return nil, fmt.Errorf("matchTrack timeout: extension took too long to respond")
		}
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

type PostProcessResult struct {
	Success     bool   `json:"success"`
	NewFilePath string `json:"new_file_path,omitempty"`
	Error       string `json:"error,omitempty"`
	BitDepth    int    `json:"bit_depth,omitempty"`
	SampleRate  int    `json:"sample_rate,omitempty"`
}

const PostProcessTimeout = 2 * time.Minute

func (p *ExtensionProviderWrapper) PostProcess(filePath string, metadata map[string]interface{}, hookID string) (*PostProcessResult, error) {
	if !p.extension.Manifest.HasPostProcessing() {
		return nil, fmt.Errorf("extension '%s' does not support post-processing", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}

	p.extension.VMMu.Lock()
	defer p.extension.VMMu.Unlock()

	metadataJSON, _ := json.Marshal(metadata)

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.postProcess === 'function') {
				return extension.postProcess(%q, %s, %q);
			}
			return null;
		})()
	`, filePath, string(metadataJSON), hookID)

	result, err := RunWithTimeoutAndRecover(p.vm, script, PostProcessTimeout)
	if err != nil {
		errMsg := err.Error()
		if IsTimeoutError(err) {
			errMsg = "postProcess timeout: extension took too long to complete"
		}
		return &PostProcessResult{
			Success: false,
			Error:   errMsg,
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

func (m *ExtensionManager) GetURLHandlers() []*ExtensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*ExtensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.HasURLHandler() && ext.Error == "" {
			providers = append(providers, NewExtensionProviderWrapper(ext))
		}
	}
	return providers
}

func (m *ExtensionManager) FindURLHandler(url string) *ExtensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.MatchesURL(url) && ext.Error == "" {
			return NewExtensionProviderWrapper(ext)
		}
	}
	return nil
}

type ExtURLHandleResultWithExtID struct {
	Result      *ExtURLHandleResult
	ExtensionID string
}

func (m *ExtensionManager) HandleURLWithExtension(url string) (*ExtURLHandleResultWithExtID, error) {
	handler := m.FindURLHandler(url)
	if handler == nil {
		return nil, fmt.Errorf("no extension found to handle URL: %s", url)
	}

	result, err := handler.HandleURL(url)
	if err != nil {
		return &ExtURLHandleResultWithExtID{
			Result:      nil,
			ExtensionID: handler.extension.ID,
		}, err
	}

	return &ExtURLHandleResultWithExtID{
		Result:      result,
		ExtensionID: handler.extension.ID,
	}, nil
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
			if !hook.DefaultEnabled {
				continue
			}

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
