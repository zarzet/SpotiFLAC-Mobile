package gobackend

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/dop251/goja"
)

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
	TotalTracks int    `json:"total_tracks,omitempty"`
	DiscNumber  int    `json:"disc_number,omitempty"`
	TotalDiscs  int    `json:"total_discs,omitempty"`
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
	Composer  string `json:"composer,omitempty"`
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
	Releases    []ExtAlbumMetadata `json:"releases,omitempty"`
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

type DownloadDecryptionInfo struct {
	Strategy        string                 `json:"strategy,omitempty"`
	Key             string                 `json:"key,omitempty"`
	IV              string                 `json:"iv,omitempty"`
	InputFormat     string                 `json:"input_format,omitempty"`
	OutputExtension string                 `json:"output_extension,omitempty"`
	Options         map[string]interface{} `json:"options,omitempty"`
}

type ExtDownloadResult struct {
	Success      bool   `json:"success"`
	FilePath     string `json:"file_path,omitempty"`
	BitDepth     int    `json:"bit_depth,omitempty"`
	SampleRate   int    `json:"sample_rate,omitempty"`
	ErrorMessage string `json:"error_message,omitempty"`
	ErrorType    string `json:"error_type,omitempty"`

	Title         string                  `json:"title,omitempty"`
	Artist        string                  `json:"artist,omitempty"`
	Album         string                  `json:"album,omitempty"`
	AlbumArtist   string                  `json:"album_artist,omitempty"`
	TrackNumber   int                     `json:"track_number,omitempty"`
	DiscNumber    int                     `json:"disc_number,omitempty"`
	ReleaseDate   string                  `json:"release_date,omitempty"`
	CoverURL      string                  `json:"cover_url,omitempty"`
	ISRC          string                  `json:"isrc,omitempty"`
	DecryptionKey string                  `json:"decryption_key,omitempty"`
	Decryption    *DownloadDecryptionInfo `json:"decryption,omitempty"`
}

const genericFFmpegMOVDecryptionStrategy = "ffmpeg.mov_key"

func cloneDownloadDecryptionInfo(info *DownloadDecryptionInfo) *DownloadDecryptionInfo {
	if info == nil {
		return nil
	}

	cloned := &DownloadDecryptionInfo{
		Strategy:        strings.TrimSpace(info.Strategy),
		Key:             strings.TrimSpace(info.Key),
		IV:              strings.TrimSpace(info.IV),
		InputFormat:     strings.TrimSpace(info.InputFormat),
		OutputExtension: strings.TrimSpace(info.OutputExtension),
	}
	if len(info.Options) > 0 {
		cloned.Options = make(map[string]interface{}, len(info.Options))
		for key, value := range info.Options {
			cloned.Options[key] = value
		}
	}
	return cloned
}

func normalizeDownloadDecryptionStrategy(strategy string) string {
	switch strings.ToLower(strings.TrimSpace(strategy)) {
	case "", "ffmpeg.mov_key", "ffmpeg_mov_key", "mov_decryption_key", "mp4_decryption_key", "ffmpeg.mp4_decryption_key":
		return genericFFmpegMOVDecryptionStrategy
	default:
		return strings.TrimSpace(strategy)
	}
}

func normalizeDownloadDecryptionInfo(info *DownloadDecryptionInfo, legacyKey string) *DownloadDecryptionInfo {
	normalized := cloneDownloadDecryptionInfo(info)
	trimmedLegacyKey := strings.TrimSpace(legacyKey)

	if normalized == nil {
		if trimmedLegacyKey == "" {
			return nil
		}
		return &DownloadDecryptionInfo{
			Strategy:    genericFFmpegMOVDecryptionStrategy,
			Key:         trimmedLegacyKey,
			InputFormat: "mov",
		}
	}

	normalized.Strategy = normalizeDownloadDecryptionStrategy(normalized.Strategy)
	if normalized.Key == "" && trimmedLegacyKey != "" {
		normalized.Key = trimmedLegacyKey
	}
	if normalized.Strategy == "" && normalized.Key != "" {
		normalized.Strategy = genericFFmpegMOVDecryptionStrategy
	}
	if normalized.Strategy == genericFFmpegMOVDecryptionStrategy && normalized.InputFormat == "" {
		normalized.InputFormat = "mov"
	}
	if normalized.Strategy == genericFFmpegMOVDecryptionStrategy && normalized.Key == "" {
		return nil
	}

	return normalized
}

func normalizedDownloadDecryptionKey(info *DownloadDecryptionInfo, legacyKey string) string {
	if normalized := normalizeDownloadDecryptionInfo(info, legacyKey); normalized != nil {
		if normalized.Strategy == genericFFmpegMOVDecryptionStrategy {
			return normalized.Key
		}
	}
	return strings.TrimSpace(legacyKey)
}

type extensionProviderWrapper struct {
	extension *loadedExtension
	vm        *goja.Runtime
}

func newExtensionProviderWrapper(ext *loadedExtension) *extensionProviderWrapper {
	return &extensionProviderWrapper{
		extension: ext,
		vm:        ext.VM,
	}
}

func (p *extensionProviderWrapper) lockReadyVM() error {
	vm, err := p.extension.lockReadyVM()
	if err != nil {
		return err
	}
	p.vm = vm
	return nil
}

func (p *extensionProviderWrapper) SearchTracks(query string, limit int) (*ExtSearchResult, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return nil, err
	}
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

func (p *extensionProviderWrapper) GetTrack(trackID string) (*ExtTrackMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return nil, err
	}
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

func (p *extensionProviderWrapper) GetAlbum(albumID string) (*ExtAlbumMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return nil, err
	}
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

func (p *extensionProviderWrapper) GetArtist(artistID string) (*ExtArtistMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return nil, fmt.Errorf("extension '%s' is not a metadata provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return nil, err
	}
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
	for i := range artist.Releases {
		artist.Releases[i].ProviderID = p.extension.ID
		for j := range artist.Releases[i].Tracks {
			artist.Releases[i].Tracks[j].ProviderID = p.extension.ID
		}
	}
	return &artist, nil
}

func (p *extensionProviderWrapper) EnrichTrack(track *ExtTrackMetadata) (*ExtTrackMetadata, error) {
	if !p.extension.Manifest.IsMetadataProvider() {
		return track, nil
	}

	if !p.extension.Enabled {
		return track, nil
	}
	if err := p.lockReadyVM(); err != nil {
		GoLog("[Extension] EnrichTrack init error for %s: %v\n", p.extension.ID, err)
		return track, nil
	}
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

func (p *extensionProviderWrapper) CheckAvailability(isrc, trackName, artistName, spotifyID, deezerID string) (*ExtAvailabilityResult, error) {
	if !p.extension.Manifest.IsDownloadProvider() {
		return nil, fmt.Errorf("extension '%s' is not a download provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return nil, err
	}
	defer p.extension.VMMu.Unlock()

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.checkAvailability === 'function') {
				return extension.checkAvailability(%q, %q, %q, {spotify_id: %q, deezer_id: %q});
			}
			return null;
		})()
	`, isrc, trackName, artistName, spotifyID, deezerID)

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

func (p *extensionProviderWrapper) GetDownloadURL(trackID, quality string) (*ExtDownloadURLResult, error) {
	if !p.extension.Manifest.IsDownloadProvider() {
		return nil, fmt.Errorf("extension '%s' is not a download provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return nil, err
	}
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

const ExtDownloadTimeout = DownloadTimeout

func (p *extensionProviderWrapper) Download(trackID, quality, outputPath, itemID string, onProgress func(percent int)) (*ExtDownloadResult, error) {
	if !p.extension.Manifest.IsDownloadProvider() {
		return nil, fmt.Errorf("extension '%s' is not a download provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return &ExtDownloadResult{
			Success:      false,
			ErrorMessage: err.Error(),
			ErrorType:    "init_error",
		}, nil
	}
	defer p.extension.VMMu.Unlock()
	if p.extension.runtime != nil {
		p.extension.runtime.setActiveDownloadItemID(itemID)
		defer p.extension.runtime.clearActiveDownloadItemID()
	}

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
	downloadResult.Decryption = normalizeDownloadDecryptionInfo(
		downloadResult.Decryption,
		downloadResult.DecryptionKey,
	)
	downloadResult.DecryptionKey = normalizedDownloadDecryptionKey(
		downloadResult.Decryption,
		downloadResult.DecryptionKey,
	)

	return &downloadResult, nil
}

func (m *extensionManager) GetMetadataProviders() []*extensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*extensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.IsMetadataProvider() && ext.Error == "" {
			providers = append(providers, newExtensionProviderWrapper(ext))
		}
	}
	return providers
}

func (m *extensionManager) GetDownloadProviders() []*extensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*extensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.IsDownloadProvider() && ext.Error == "" {
			providers = append(providers, newExtensionProviderWrapper(ext))
		}
	}
	return providers
}

func (m *extensionManager) SearchTracksWithExtensions(query string, limit int) ([]ExtTrackMetadata, error) {
	providers := m.GetMetadataProviders()
	if len(providers) == 0 {
		return nil, nil
	}

	providerByID := make(map[string]*extensionProviderWrapper, len(providers))
	orderedProviders := make([]*extensionProviderWrapper, 0, len(providers))
	for _, provider := range providers {
		providerByID[provider.extension.ID] = provider
	}
	for _, providerID := range GetMetadataProviderPriority() {
		if provider := providerByID[providerID]; provider != nil {
			orderedProviders = append(orderedProviders, provider)
			delete(providerByID, providerID)
		}
	}
	if len(providerByID) > 0 {
		remainingIDs := make([]string, 0, len(providerByID))
		for providerID := range providerByID {
			remainingIDs = append(remainingIDs, providerID)
		}
		sort.Strings(remainingIDs)
		for _, providerID := range remainingIDs {
			orderedProviders = append(orderedProviders, providerByID[providerID])
		}
	}

	var allTracks []ExtTrackMetadata
	for _, provider := range orderedProviders {
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

var extensionFallbackProviderIDs []string
var extensionFallbackProviderIDsMu sync.RWMutex

var metadataProviderPriority []string
var metadataProviderPriorityMu sync.RWMutex

var searchBuiltInMetadataTracksFunc = searchBuiltInMetadataTracks

func SetProviderPriority(providerIDs []string) {
	providerPriorityMu.Lock()
	defer providerPriorityMu.Unlock()
	providerPriority = sanitizeDownloadProviderPriority(providerIDs)
	GoLog("[Extension] Download provider priority set: %v\n", providerPriority)
}

func GetProviderPriority() []string {
	providerPriorityMu.RLock()
	defer providerPriorityMu.RUnlock()

	if len(providerPriority) == 0 {
		return []string{"tidal", "qobuz"}
	}

	result := make([]string, len(providerPriority))
	copy(result, providerPriority)
	return result
}

func sanitizeDownloadProviderPriority(providerIDs []string) []string {
	sanitized := make([]string, 0, len(providerIDs)+2)
	seen := map[string]struct{}{}

	for _, providerID := range providerIDs {
		providerID = strings.TrimSpace(providerID)
		if providerID == "" {
			continue
		}

		normalizedBuiltIn := strings.ToLower(providerID)
		if isBuiltInDownloadProvider(normalizedBuiltIn) {
			providerID = normalizedBuiltIn
		}

		seenKey := strings.ToLower(providerID)
		if _, exists := seen[seenKey]; exists {
			continue
		}
		seen[seenKey] = struct{}{}
		sanitized = append(sanitized, providerID)
	}

	for _, providerID := range []string{"tidal", "qobuz"} {
		if _, exists := seen[providerID]; exists {
			continue
		}
		seen[providerID] = struct{}{}
		sanitized = append(sanitized, providerID)
	}

	return sanitized
}

func SetExtensionFallbackProviderIDs(providerIDs []string) {
	extensionFallbackProviderIDsMu.Lock()
	defer extensionFallbackProviderIDsMu.Unlock()

	if providerIDs == nil {
		extensionFallbackProviderIDs = nil
		GoLog("[Extension] Extension fallback providers reset to default (all enabled download extensions)\n")
		return
	}

	sanitized := make([]string, 0, len(providerIDs))
	seen := map[string]struct{}{}
	for _, providerID := range providerIDs {
		providerID = strings.TrimSpace(providerID)
		if providerID == "" || isBuiltInDownloadProvider(strings.ToLower(providerID)) {
			continue
		}
		if _, exists := seen[providerID]; exists {
			continue
		}
		seen[providerID] = struct{}{}
		sanitized = append(sanitized, providerID)
	}

	extensionFallbackProviderIDs = sanitized
	GoLog("[Extension] Extension fallback providers set: %v\n", sanitized)
}

func GetExtensionFallbackProviderIDs() []string {
	extensionFallbackProviderIDsMu.RLock()
	defer extensionFallbackProviderIDsMu.RUnlock()

	if extensionFallbackProviderIDs == nil {
		return nil
	}

	result := make([]string, len(extensionFallbackProviderIDs))
	copy(result, extensionFallbackProviderIDs)
	return result
}

func isExtensionFallbackAllowed(providerID string) bool {
	if isBuiltInDownloadProvider(strings.ToLower(providerID)) {
		return true
	}

	allowed := GetExtensionFallbackProviderIDs()
	if allowed == nil {
		return true
	}

	for _, allowedProviderID := range allowed {
		if allowedProviderID == providerID {
			return true
		}
	}
	return false
}

func SetMetadataProviderPriority(providerIDs []string) {
	metadataProviderPriorityMu.Lock()
	defer metadataProviderPriorityMu.Unlock()

	sanitized := make([]string, 0, len(providerIDs)+2)
	seen := map[string]struct{}{}
	for _, providerID := range providerIDs {
		providerID = strings.TrimSpace(providerID)
		if providerID == "" || providerID == "spotify" {
			continue
		}
		if _, exists := seen[providerID]; exists {
			continue
		}
		seen[providerID] = struct{}{}
		sanitized = append(sanitized, providerID)
	}
	for _, providerID := range []string{"qobuz", "tidal"} {
		if _, exists := seen[providerID]; exists {
			continue
		}
		seen[providerID] = struct{}{}
		sanitized = append(sanitized, providerID)
	}

	metadataProviderPriority = sanitized
	GoLog("[Extension] Metadata provider priority set: %v\n", sanitized)
}

func GetMetadataProviderPriority() []string {
	metadataProviderPriorityMu.RLock()
	defer metadataProviderPriorityMu.RUnlock()

	if len(metadataProviderPriority) == 0 {
		return []string{"qobuz", "tidal"}
	}

	result := make([]string, len(metadataProviderPriority))
	copy(result, metadataProviderPriority)
	return result
}

func isBuiltInProvider(providerID string) bool {
	switch providerID {
	case "tidal", "qobuz":
		return true
	default:
		return false
	}
}

func isBuiltInDownloadProvider(providerID string) bool {
	switch providerID {
	case "tidal", "qobuz":
		return true
	default:
		return false
	}
}

func normalizeBuiltInMetadataTrack(track TrackMetadata, providerID string) ExtTrackMetadata {
	deezerID := ""
	tidalID := ""
	qobuzID := ""
	prefixedID := strings.TrimSpace(track.SpotifyID)

	switch providerID {
	case "deezer":
		deezerID = strings.TrimPrefix(prefixedID, "deezer:")
	case "tidal":
		tidalID = strings.TrimPrefix(prefixedID, "tidal:")
	case "qobuz":
		qobuzID = strings.TrimPrefix(prefixedID, "qobuz:")
	}

	return ExtTrackMetadata{
		ID:          prefixedID,
		Name:        track.Name,
		Artists:     track.Artists,
		AlbumName:   track.AlbumName,
		AlbumArtist: track.AlbumArtist,
		DurationMS:  track.DurationMS,
		CoverURL:    track.Images,
		Images:      track.Images,
		ReleaseDate: track.ReleaseDate,
		TrackNumber: track.TrackNumber,
		TotalTracks: track.TotalTracks,
		DiscNumber:  track.DiscNumber,
		TotalDiscs:  track.TotalDiscs,
		ISRC:        track.ISRC,
		ProviderID:  providerID,
		SpotifyID:   prefixedID,
		DeezerID:    deezerID,
		TidalID:     tidalID,
		QobuzID:     qobuzID,
		AlbumType:   track.AlbumType,
		Composer:    track.Composer,
	}
}

func metadataTrackDedupKey(track ExtTrackMetadata) string {
	if isrc := strings.TrimSpace(track.ISRC); isrc != "" {
		return "isrc:" + strings.ToUpper(isrc)
	}
	if spotifyID := strings.TrimSpace(track.SpotifyID); spotifyID != "" {
		return "spotify:" + spotifyID
	}
	if providerID := strings.TrimSpace(track.ProviderID); providerID != "" && strings.TrimSpace(track.ID) != "" {
		return providerID + ":" + strings.TrimSpace(track.ID)
	}
	return strings.TrimSpace(track.Name) + "|" + strings.TrimSpace(track.Artists)
}

func searchBuiltInMetadataTracks(providerID, query string, limit int) ([]ExtTrackMetadata, error) {
	switch providerID {
	case "qobuz":
		return NewQobuzDownloader().SearchTracks(query, limit)
	case "tidal":
		return NewTidalDownloader().SearchTracks(query, limit)
	default:
		return nil, fmt.Errorf("unsupported built-in metadata provider: %s", providerID)
	}
}

func (m *extensionManager) SearchTracksWithMetadataProviders(query string, limit int, includeExtensions bool) ([]ExtTrackMetadata, error) {
	priority := GetMetadataProviderPriority()
	if limit <= 0 {
		limit = 20
	}

	extensionProviders := make(map[string]*extensionProviderWrapper)
	if includeExtensions {
		for _, provider := range m.GetMetadataProviders() {
			extensionProviders[provider.extension.ID] = provider
		}
	}

	orderedProviderIDs := make([]string, 0, len(priority)+len(extensionProviders))
	seenProviderIDs := make(map[string]struct{}, len(priority)+len(extensionProviders))
	for _, providerID := range priority {
		providerID = strings.TrimSpace(providerID)
		if providerID == "" {
			continue
		}
		orderedProviderIDs = append(orderedProviderIDs, providerID)
		seenProviderIDs[providerID] = struct{}{}
	}
	if includeExtensions {
		remainingIDs := make([]string, 0, len(extensionProviders))
		for providerID := range extensionProviders {
			if _, exists := seenProviderIDs[providerID]; exists {
				continue
			}
			remainingIDs = append(remainingIDs, providerID)
		}
		sort.Strings(remainingIDs)
		orderedProviderIDs = append(orderedProviderIDs, remainingIDs...)
	}

	tracks := make([]ExtTrackMetadata, 0, limit)
	seenTracks := make(map[string]struct{})
	for _, providerID := range orderedProviderIDs {
		var (
			providerTracks []ExtTrackMetadata
			err            error
		)

		if isBuiltInProvider(providerID) {
			providerTracks, err = searchBuiltInMetadataTracksFunc(providerID, query, limit)
		} else {
			if !includeExtensions {
				continue
			}
			provider := extensionProviders[providerID]
			if provider == nil {
				continue
			}
			var result *ExtSearchResult
			result, err = provider.SearchTracks(query, limit)
			if result != nil {
				providerTracks = result.Tracks
			}
		}

		if err != nil {
			GoLog("[MetadataSearch] Search error from %s: %v\n", providerID, err)
			continue
		}

		for _, track := range providerTracks {
			key := metadataTrackDedupKey(track)
			if key == "" {
				continue
			}
			if _, exists := seenTracks[key]; exists {
				continue
			}
			seenTracks[key] = struct{}{}
			tracks = append(tracks, track)
			if len(tracks) >= limit {
				return tracks, nil
			}
		}
	}

	return tracks, nil
}

func DownloadWithExtensionFallback(req DownloadRequest) (*DownloadResponse, error) {
	priority := GetProviderPriority()
	extManager := getExtensionManager()
	strictMode := !req.UseFallback
	selectedProvider := strings.TrimSpace(req.Service)

	if strictMode {
		if selectedProvider == "" {
			selectedProvider = strings.TrimSpace(req.Source)
		}
		if selectedProvider != "" {
			priority = []string{selectedProvider}
			GoLog("[DownloadWithExtensionFallback] Strict mode enabled, provider locked to: %s\n", selectedProvider)
		}
	}

	if !strictMode && req.Service != "" && isBuiltInDownloadProvider(strings.ToLower(req.Service)) {
		GoLog("[DownloadWithExtensionFallback] User selected service: %s, prioritizing it first\n", req.Service)
		newPriority := []string{req.Service}
		for _, p := range priority {
			if p != req.Service {
				newPriority = append(newPriority, p)
			}
		}
		priority = newPriority
		GoLog("[DownloadWithExtensionFallback] New priority order: %v\n", priority)
	} else if !strictMode && req.Service != "" && !isBuiltInDownloadProvider(strings.ToLower(req.Service)) {
		found := false
		for _, p := range priority {
			if strings.EqualFold(p, req.Service) {
				found = true
				break
			}
		}
		newPriority := []string{req.Service}
		for _, p := range priority {
			if !strings.EqualFold(p, req.Service) {
				newPriority = append(newPriority, p)
			}
		}
		priority = newPriority
		if !found {
			GoLog("[DownloadWithExtensionFallback] Extension service '%s' added to priority front\n", req.Service)
		} else {
			GoLog("[DownloadWithExtensionFallback] Extension service '%s' moved to priority front\n", req.Service)
		}
		GoLog("[DownloadWithExtensionFallback] New priority order: %v\n", priority)
	}

	var lastErr error
	var skipBuiltIn bool

	if req.Source != "" && !isBuiltInProvider(strings.ToLower(req.Source)) {
		ext, err := extManager.GetExtension(req.Source)
		if err == nil && ext.Enabled && ext.Error == "" && ext.Manifest.IsMetadataProvider() {
			GoLog("[DownloadWithExtensionFallback] Enriching track from extension '%s'...\n", req.Source)

			provider := newExtensionProviderWrapper(ext)
			trackMeta := &ExtTrackMetadata{
				ID:          req.SpotifyID,
				Name:        req.TrackName,
				Artists:     req.ArtistName,
				AlbumName:   req.AlbumName,
				DurationMS:  req.DurationMS,
				ISRC:        req.ISRC,
				ReleaseDate: req.ReleaseDate,
				TrackNumber: req.TrackNumber,
				TotalTracks: req.TotalTracks,
				DiscNumber:  req.DiscNumber,
				TotalDiscs:  req.TotalDiscs,
				ProviderID:  req.Source,
				Composer:    req.Composer,
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
				if enrichedTrack.AlbumName != "" && req.AlbumName == "" {
					GoLog("[DownloadWithExtensionFallback] AlbumName from enrichment: %s\n", enrichedTrack.AlbumName)
					req.AlbumName = enrichedTrack.AlbumName
				}
				if enrichedTrack.AlbumArtist != "" && req.AlbumArtist == "" {
					req.AlbumArtist = enrichedTrack.AlbumArtist
				}
				if enrichedTrack.DurationMS > 0 && req.DurationMS == 0 {
					GoLog("[DownloadWithExtensionFallback] DurationMS from enrichment: %d\n", enrichedTrack.DurationMS)
					req.DurationMS = enrichedTrack.DurationMS
				}
				if enrichedTrack.CoverURL != "" && req.CoverURL == "" {
					req.CoverURL = enrichedTrack.CoverURL
				}
				if enrichedTrack.ID != "" && req.SpotifyID == "" {
					GoLog("[DownloadWithExtensionFallback] Track ID from enrichment: %s\n", enrichedTrack.ID)
					req.SpotifyID = enrichedTrack.ID
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
				if enrichedTrack.TrackNumber > 0 && req.TrackNumber == 0 {
					GoLog("[DownloadWithExtensionFallback] TrackNumber from enrichment: %d\n", enrichedTrack.TrackNumber)
					req.TrackNumber = enrichedTrack.TrackNumber
				}
				if enrichedTrack.TotalTracks > 0 && req.TotalTracks == 0 {
					GoLog("[DownloadWithExtensionFallback] TotalTracks from enrichment: %d\n", enrichedTrack.TotalTracks)
					req.TotalTracks = enrichedTrack.TotalTracks
				}
				if enrichedTrack.DiscNumber > 0 && req.DiscNumber == 0 {
					GoLog("[DownloadWithExtensionFallback] DiscNumber from enrichment: %d\n", enrichedTrack.DiscNumber)
					req.DiscNumber = enrichedTrack.DiscNumber
				}
				if enrichedTrack.TotalDiscs > 0 && req.TotalDiscs == 0 {
					GoLog("[DownloadWithExtensionFallback] TotalDiscs from enrichment: %d\n", enrichedTrack.TotalDiscs)
					req.TotalDiscs = enrichedTrack.TotalDiscs
				}
				if enrichedTrack.Composer != "" && req.Composer == "" {
					GoLog("[DownloadWithExtensionFallback] Composer from enrichment: %s\n", enrichedTrack.Composer)
					req.Composer = enrichedTrack.Composer
				}
			}
		}
	}

	if req.Source != "" && !isBuiltInProvider(strings.ToLower(req.Source)) &&
		req.TrackName != "" && req.ArtistName != "" &&
		(req.AlbumName == "" || req.ReleaseDate == "" || req.ISRC == "") {

		searchQuery := req.TrackName + " " + req.ArtistName
		GoLog("[DownloadWithExtensionFallback] Metadata incomplete, searching providers for: %s\n", searchQuery)

		tracks, searchErr := extManager.SearchTracksWithMetadataProviders(searchQuery, 5, true)
		if searchErr == nil && len(tracks) > 0 {
			track := tracks[0]
			GoLog("[DownloadWithExtensionFallback] Metadata match (%s): %s - %s (album: %s, date: %s, isrc: %s)\n",
				track.ProviderID, track.Name, track.Artists, track.AlbumName, track.ReleaseDate, track.ISRC)

			if track.AlbumName != "" && req.AlbumName == "" {
				req.AlbumName = track.AlbumName
			}
			if track.AlbumArtist != "" && req.AlbumArtist == "" {
				req.AlbumArtist = track.AlbumArtist
			}
			if track.ReleaseDate != "" && req.ReleaseDate == "" {
				req.ReleaseDate = track.ReleaseDate
			}
			if track.ISRC != "" && req.ISRC == "" {
				req.ISRC = track.ISRC
			}
			if track.TrackNumber > 0 && req.TrackNumber == 0 {
				req.TrackNumber = track.TrackNumber
			}
			if track.TotalTracks > 0 && req.TotalTracks == 0 {
				req.TotalTracks = track.TotalTracks
			}
			if track.DiscNumber > 0 && req.DiscNumber == 0 {
				req.DiscNumber = track.DiscNumber
			}
			if track.TotalDiscs > 0 && req.TotalDiscs == 0 {
				req.TotalDiscs = track.TotalDiscs
			}
			if track.Composer != "" && req.Composer == "" {
				req.Composer = track.Composer
			}
			if track.CoverURL != "" && req.CoverURL == "" {
				req.CoverURL = track.CoverURL
			}
			if track.Genre != "" && req.Genre == "" {
				req.Genre = track.Genre
			}
			if track.Label != "" && req.Label == "" {
				req.Label = track.Label
			}
			if track.Copyright != "" && req.Copyright == "" {
				req.Copyright = track.Copyright
			}
		} else if searchErr != nil {
			GoLog("[DownloadWithExtensionFallback] Metadata provider search failed (non-fatal): %v\n", searchErr)
		}

		if req.ISRC != "" &&
			(req.Genre == "" || req.Label == "" || req.Copyright == "") {
			enrichExtraMetadataByISRC("DownloadWithExtensionFallback", req.ISRC, &req.Genre, &req.Label, &req.Copyright)
		}
	}

	if req.Source != "" &&
		!isBuiltInProvider(strings.ToLower(req.Source)) &&
		(!strictMode || selectedProvider == "" || strings.EqualFold(selectedProvider, req.Source)) {
		GoLog("[DownloadWithExtensionFallback] Track source is extension '%s', trying it first\n", req.Source)

		ext, err := extManager.GetExtension(req.Source)
		if err == nil && ext.Enabled && ext.Error == "" && ext.Manifest.IsDownloadProvider() {
			skipBuiltIn = ext.Manifest.SkipBuiltInFallback

			provider := newExtensionProviderWrapper(ext)

			trackID := req.SpotifyID

			GoLog("[DownloadWithExtensionFallback] Downloading from source extension with trackID: %s (skipBuiltInFallback: %v)\n", trackID, skipBuiltIn)

			outputPath := buildOutputPathForExtension(req, ext)
			if req.ItemID != "" {
				StartItemProgress(req.ItemID)
			}

			result, err := provider.Download(trackID, req.Quality, outputPath, req.ItemID, func(percent int) {
				if req.ItemID != "" {
					normalized := float64(percent) / 100.0
					if normalized < 0 {
						normalized = 0
					}
					if normalized > 1 {
						normalized = 1
					}
					SetItemProgress(req.ItemID, normalized, 0, 0)
				}
			})
			if req.ItemID != "" {
				if err == nil && result != nil && result.Success {
					CompleteItemProgress(req.ItemID)
				} else {
					RemoveItemProgress(req.ItemID)
				}
			}

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
					DecryptionKey:    result.DecryptionKey,
					Decryption:       normalizeDownloadDecryptionInfo(result.Decryption, result.DecryptionKey),
				}

				if req.EmbedMetadata && (req.Genre != "" || req.Label != "") && canEmbedGenreLabel(result.FilePath) {
					if err := EmbedGenreLabel(result.FilePath, req.Genre, req.Label); err != nil {
						GoLog("[DownloadWithExtensionFallback] Warning: failed to embed genre/label: %v\n", err)
					} else {
						GoLog("[DownloadWithExtensionFallback] Embedded genre=%q label=%q\n", req.Genre, req.Label)
					}
				} else if req.EmbedMetadata && (req.Genre != "" || req.Label != "") {
					GoLog("[DownloadWithExtensionFallback] Skipping genre/label embed for non-local output path: %q\n", result.FilePath)
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

				if req.AlbumName != "" && resp.Album == "" {
					resp.Album = req.AlbumName
				}
				if req.AlbumArtist != "" && resp.AlbumArtist == "" {
					resp.AlbumArtist = req.AlbumArtist
				}
				if req.ReleaseDate != "" && resp.ReleaseDate == "" {
					resp.ReleaseDate = req.ReleaseDate
				}
				if req.ISRC != "" && resp.ISRC == "" {
					resp.ISRC = req.ISRC
				}
				if req.TrackNumber > 0 && resp.TrackNumber == 0 {
					resp.TrackNumber = req.TrackNumber
				}
				if req.DiscNumber > 0 && resp.DiscNumber == 0 {
					resp.DiscNumber = req.DiscNumber
				}
				if req.CoverURL != "" && resp.CoverURL == "" {
					resp.CoverURL = req.CoverURL
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
		providerID = strings.TrimSpace(providerID)
		if providerID == "" {
			continue
		}
		providerIDNormalized := strings.ToLower(providerID)
		if providerID == req.Source {
			continue
		}

		if skipBuiltIn && isBuiltInDownloadProvider(providerIDNormalized) {
			GoLog("[DownloadWithExtensionFallback] Skipping built-in provider %s (skipBuiltInFallback)\n", providerID)
			continue
		}

		if !isBuiltInDownloadProvider(providerIDNormalized) && !isExtensionFallbackAllowed(providerID) {
			GoLog("[DownloadWithExtensionFallback] Skipping extension provider %s (not enabled for fallback)\n", providerID)
			continue
		}

		GoLog("[DownloadWithExtensionFallback] Trying provider: %s\n", providerID)

		if isBuiltInDownloadProvider(providerIDNormalized) {
			if (req.Genre == "" || req.Label == "" || req.Copyright == "") &&
				req.ISRC != "" {
				GoLog("[DownloadWithExtensionFallback] Enriching extra metadata from ISRC: %s\n", req.ISRC)
				enrichExtraMetadataByISRC("DownloadWithExtensionFallback", req.ISRC, &req.Genre, &req.Label, &req.Copyright)
			}

			result, err := tryBuiltInProvider(providerIDNormalized, req)
			if err == nil && result.Success {
				result.Service = providerIDNormalized
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
						Service:   providerIDNormalized,
					}, nil
				}
				lastErr = err
				GoLog("[DownloadWithExtensionFallback] %s failed: %v\n", providerIDNormalized, err)
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

			provider := newExtensionProviderWrapper(ext)

			availability, err := provider.CheckAvailability(req.ISRC, req.TrackName, req.ArtistName, req.SpotifyID, req.DeezerID)
			if err != nil || !availability.Available {
				GoLog("[DownloadWithExtensionFallback] %s: not available\n", providerID)
				if err != nil {
					lastErr = err
				}
				continue
			}

			outputPath := buildOutputPathForExtension(req, ext)
			if req.ItemID != "" {
				StartItemProgress(req.ItemID)
			}

			result, err := provider.Download(availability.TrackID, req.Quality, outputPath, req.ItemID, func(percent int) {
				if req.ItemID != "" {
					normalized := float64(percent) / 100.0
					if normalized < 0 {
						normalized = 0
					}
					if normalized > 1 {
						normalized = 1
					}
					SetItemProgress(req.ItemID, normalized, 0, 0)
				}
			})
			if req.ItemID != "" {
				if err == nil && result != nil && result.Success {
					CompleteItemProgress(req.ItemID)
				} else {
					RemoveItemProgress(req.ItemID)
				}
			}

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
					DecryptionKey:    result.DecryptionKey,
					Decryption:       normalizeDownloadDecryptionInfo(result.Decryption, result.DecryptionKey),
				}

				if req.EmbedMetadata && (req.Genre != "" || req.Label != "") && canEmbedGenreLabel(result.FilePath) {
					if err := EmbedGenreLabel(result.FilePath, req.Genre, req.Label); err != nil {
						GoLog("[DownloadWithExtensionFallback] Warning: failed to embed genre/label: %v\n", err)
					} else {
						GoLog("[DownloadWithExtensionFallback] Embedded genre=%q label=%q\n", req.Genre, req.Label)
					}
				} else if req.EmbedMetadata && (req.Genre != "" || req.Label != "") {
					GoLog("[DownloadWithExtensionFallback] Skipping genre/label embed for non-local output path: %q\n", result.FilePath)
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

				if req.AlbumName != "" && resp.Album == "" {
					resp.Album = req.AlbumName
				}
				if req.AlbumArtist != "" && resp.AlbumArtist == "" {
					resp.AlbumArtist = req.AlbumArtist
				}
				if req.ReleaseDate != "" && resp.ReleaseDate == "" {
					resp.ReleaseDate = req.ReleaseDate
				}
				if req.ISRC != "" && resp.ISRC == "" {
					resp.ISRC = req.ISRC
				}
				if req.TrackNumber > 0 && resp.TrackNumber == 0 {
					resp.TrackNumber = req.TrackNumber
				}
				if req.DiscNumber > 0 && resp.DiscNumber == 0 {
					resp.DiscNumber = req.DiscNumber
				}
				if req.CoverURL != "" && resp.CoverURL == "" {
					resp.CoverURL = req.CoverURL
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
				CoverURL:    qobuzResult.CoverURL,
			}
		}
		err = qobuzErr
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
		CoverURL:         result.CoverURL,
		Genre:            req.Genre,
		Label:            req.Label,
		Copyright:        req.Copyright,
		LyricsLRC:        result.LyricsLRC,
		DecryptionKey:    result.DecryptionKey,
		Decryption:       normalizeDownloadDecryptionInfo(result.Decryption, result.DecryptionKey),
	}, nil
}

func buildOutputPath(req DownloadRequest) string {
	if strings.TrimSpace(req.OutputPath) != "" {
		return strings.TrimSpace(req.OutputPath)
	}

	metadata := map[string]interface{}{
		"title":        req.TrackName,
		"artist":       req.ArtistName,
		"album":        req.AlbumName,
		"album_artist": req.AlbumArtist,
		"track":        req.TrackNumber,
		"track_number": req.TrackNumber,
		"total_tracks": req.TotalTracks,
		"disc":         req.DiscNumber,
		"disc_number":  req.DiscNumber,
		"total_discs":  req.TotalDiscs,
		"year":         extractYear(req.ReleaseDate),
		"date":         req.ReleaseDate,
		"release_date": req.ReleaseDate,
		"isrc":         req.ISRC,
		"composer":     req.Composer,
	}

	filename := buildFilenameFromTemplate(req.FilenameFormat, metadata)
	if filename == "" {
		filename = sanitizeFilename(fmt.Sprintf("%s - %s", req.ArtistName, req.TrackName))
	}

	ext := strings.TrimSpace(req.OutputExt)
	if ext == "" {
		ext = ".flac"
	} else if !strings.HasPrefix(ext, ".") {
		ext = "." + ext
	}

	outputDir := req.OutputDir
	if strings.TrimSpace(outputDir) == "" {
		outputDir = filepath.Join(os.TempDir(), "spotiflac-downloads")
	}
	os.MkdirAll(outputDir, 0755)
	AddAllowedDownloadDir(outputDir)

	return filepath.Join(outputDir, filename+ext)
}

func buildOutputPathForExtension(req DownloadRequest, ext *loadedExtension) string {
	if strings.TrimSpace(req.OutputPath) != "" {
		outputPath := strings.TrimSpace(req.OutputPath)
		AddAllowedDownloadDir(filepath.Dir(outputPath))
		return outputPath
	}

	// SAF downloads hand extensions a detached output FD owned by the host.
	// Extensions still need a real local temp file so Android can copy it into
	// the target document after provider-specific post-processing completes.
	if !isFDOutput(req.OutputFD) && strings.TrimSpace(req.OutputDir) != "" {
		return buildOutputPath(req)
	}

	tempDir := filepath.Join(ext.DataDir, "downloads")
	os.MkdirAll(tempDir, 0755)
	AddAllowedDownloadDir(tempDir)

	metadata := map[string]interface{}{
		"title":        req.TrackName,
		"artist":       req.ArtistName,
		"album":        req.AlbumName,
		"album_artist": req.AlbumArtist,
		"track":        req.TrackNumber,
		"track_number": req.TrackNumber,
		"total_tracks": req.TotalTracks,
		"disc":         req.DiscNumber,
		"disc_number":  req.DiscNumber,
		"total_discs":  req.TotalDiscs,
		"year":         extractYear(req.ReleaseDate),
		"date":         req.ReleaseDate,
		"release_date": req.ReleaseDate,
		"isrc":         req.ISRC,
		"composer":     req.Composer,
	}

	filename := buildFilenameFromTemplate(req.FilenameFormat, metadata)
	if filename == "" {
		filename = sanitizeFilename(fmt.Sprintf("%s - %s", req.ArtistName, req.TrackName))
	}

	outputExt := strings.TrimSpace(req.OutputExt)
	if outputExt == "" {
		outputExt = ".flac"
	} else if !strings.HasPrefix(outputExt, ".") {
		outputExt = "." + outputExt
	}

	return filepath.Join(tempDir, filename+outputExt)
}

func canEmbedGenreLabel(filePath string) bool {
	path := strings.TrimSpace(filePath)
	if path == "" || strings.HasPrefix(path, "content://") || strings.HasPrefix(path, "/proc/self/fd/") {
		return false
	}
	if !filepath.IsAbs(path) {
		return false
	}
	info, err := os.Stat(path)
	return err == nil && !info.IsDir() && info.Size() > 0
}

func (p *extensionProviderWrapper) CustomSearch(query string, options map[string]interface{}) ([]ExtTrackMetadata, error) {
	if !p.extension.Manifest.HasCustomSearch() {
		return nil, fmt.Errorf("extension '%s' does not support custom search", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return nil, err
	}
	defer p.extension.VMMu.Unlock()

	if options == nil {
		options = map[string]interface{}{}
	}

	// Avoid embedding user input directly into JS source. Some inputs can trigger
	// parser/runtime edge cases on specific devices/Goja builds.
	const queryVar = "__sf_custom_search_query"
	const optionsVar = "__sf_custom_search_options"
	global := p.vm.GlobalObject()
	_ = global.Set(queryVar, query)
	_ = global.Set(optionsVar, options)
	defer func() {
		global.Delete(queryVar)
		global.Delete(optionsVar)
	}()

	const script = `
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.customSearch === 'function') {
				return extension.customSearch(__sf_custom_search_query, __sf_custom_search_options);
			}
			return null;
		})()
	`

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

func (p *extensionProviderWrapper) HandleURL(url string) (*ExtURLHandleResult, error) {
	if !p.extension.Manifest.HasURLHandler() {
		return nil, fmt.Errorf("extension '%s' does not support URL handling", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return nil, err
	}
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
		for i := range handleResult.Artist.Releases {
			handleResult.Artist.Releases[i].ProviderID = p.extension.ID
			for j := range handleResult.Artist.Releases[i].Tracks {
				handleResult.Artist.Releases[i].Tracks[j].ProviderID = p.extension.ID
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

func (p *extensionProviderWrapper) MatchTrack(sourceTrack map[string]interface{}, candidates []map[string]interface{}) (*MatchTrackResult, error) {
	if !p.extension.Manifest.HasCustomMatching() {
		return nil, fmt.Errorf("extension '%s' does not support custom matching", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return nil, err
	}
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
	NewFileURI  string `json:"new_file_uri,omitempty"`
	Error       string `json:"error,omitempty"`
	BitDepth    int    `json:"bit_depth,omitempty"`
	SampleRate  int    `json:"sample_rate,omitempty"`
}

type PostProcessInput struct {
	Path     string `json:"path,omitempty"`
	URI      string `json:"uri,omitempty"`
	Name     string `json:"name,omitempty"`
	MimeType string `json:"mime_type,omitempty"`
	Size     int64  `json:"size,omitempty"`
	IsSAF    bool   `json:"is_saf,omitempty"`
}

const PostProcessTimeout = 2 * time.Minute

func (p *extensionProviderWrapper) PostProcess(filePath string, metadata map[string]interface{}, hookID string) (*PostProcessResult, error) {
	if !p.extension.Manifest.HasPostProcessing() {
		return nil, fmt.Errorf("extension '%s' does not support post-processing", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return &PostProcessResult{Success: false, Error: err.Error()}, nil
	}
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

func (p *extensionProviderWrapper) PostProcessV2(input PostProcessInput, metadata map[string]interface{}, hookID string) (*PostProcessResult, error) {
	if !p.extension.Manifest.HasPostProcessing() {
		return nil, fmt.Errorf("extension '%s' does not support post-processing", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return &PostProcessResult{Success: false, Error: err.Error()}, nil
	}
	defer p.extension.VMMu.Unlock()

	metadataJSON, _ := json.Marshal(metadata)
	inputJSON, _ := json.Marshal(input)
	filePath := input.Path

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined') {
				if (typeof extension.postProcessV2 === 'function') {
					return extension.postProcessV2(%s, %s, %q);
				}
				if (typeof extension.postProcess === 'function') {
					return extension.postProcess(%q, %s, %q);
				}
			}
			return null;
		})()
	`, string(inputJSON), string(metadataJSON), hookID, filePath, string(metadataJSON), hookID)

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

func (m *extensionManager) GetSearchProviders() []*extensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*extensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.HasCustomSearch() && ext.Error == "" {
			providers = append(providers, newExtensionProviderWrapper(ext))
		}
	}
	return providers
}

func (m *extensionManager) GetURLHandlers() []*extensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*extensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.HasURLHandler() && ext.Error == "" {
			providers = append(providers, newExtensionProviderWrapper(ext))
		}
	}
	return providers
}

func (m *extensionManager) FindURLHandler(url string) *extensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.MatchesURL(url) && ext.Error == "" {
			return newExtensionProviderWrapper(ext)
		}
	}
	return nil
}

type ExtURLHandleResultWithExtID struct {
	Result      *ExtURLHandleResult
	ExtensionID string
}

func (m *extensionManager) HandleURLWithExtension(url string) (*ExtURLHandleResultWithExtID, error) {
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

func (m *extensionManager) GetPostProcessingProviders() []*extensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*extensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.HasPostProcessing() && ext.Error == "" {
			providers = append(providers, newExtensionProviderWrapper(ext))
		}
	}
	return providers
}

func (m *extensionManager) RunPostProcessing(filePath string, metadata map[string]interface{}) (*PostProcessResult, error) {
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

func (m *extensionManager) RunPostProcessingV2(input PostProcessInput, metadata map[string]interface{}) (*PostProcessResult, error) {
	providers := m.GetPostProcessingProviders()
	if len(providers) == 0 {
		return &PostProcessResult{Success: true, NewFilePath: input.Path, NewFileURI: input.URI}, nil
	}

	currentInput := input
	for _, provider := range providers {
		hooks := provider.extension.Manifest.GetPostProcessingHooks()
		for _, hook := range hooks {
			if !hook.DefaultEnabled {
				continue
			}

			ext := strings.ToLower(filepath.Ext(currentInput.Path))
			if ext == "" && currentInput.Name != "" {
				ext = strings.ToLower(filepath.Ext(currentInput.Name))
			}
			if len(hook.SupportedFormats) > 0 && ext != "" {
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

			GoLog("[PostProcessV2] Running hook %s from %s on %s\n", hook.ID, provider.extension.ID, currentInput.Path)

			result, err := provider.PostProcessV2(currentInput, metadata, hook.ID)
			if err != nil {
				GoLog("[PostProcessV2] Hook %s failed: %v\n", hook.ID, err)
				continue
			}

			if result.Success && result.NewFilePath != "" {
				currentInput.Path = result.NewFilePath
				if currentInput.Name == "" {
					currentInput.Name = filepath.Base(result.NewFilePath)
				}
			}
			if result.Success && result.NewFileURI != "" {
				currentInput.URI = result.NewFileURI
			}
		}
	}

	return &PostProcessResult{Success: true, NewFilePath: currentInput.Path, NewFileURI: currentInput.URI}, nil
}

type ExtLyricsResult struct {
	Lines        []ExtLyricsLine `json:"lines"`
	SyncType     string          `json:"syncType"`
	Instrumental bool            `json:"instrumental"`
	PlainLyrics  string          `json:"plainLyrics"`
	Provider     string          `json:"provider"`
}

type ExtLyricsLine struct {
	StartTimeMs int64  `json:"startTimeMs"`
	Words       string `json:"words"`
	EndTimeMs   int64  `json:"endTimeMs"`
}

func (p *extensionProviderWrapper) FetchLyrics(trackName, artistName, albumName string, durationSec float64) (*LyricsResponse, error) {
	if !p.extension.Manifest.IsLyricsProvider() {
		return nil, fmt.Errorf("extension '%s' is not a lyrics provider", p.extension.ID)
	}

	if !p.extension.Enabled {
		return nil, fmt.Errorf("extension '%s' is disabled", p.extension.ID)
	}
	if err := p.lockReadyVM(); err != nil {
		return nil, err
	}
	defer p.extension.VMMu.Unlock()

	// Use global variables to avoid JS injection issues with special characters in track/artist names
	const trackVar = "__sf_lyrics_track"
	const artistVar = "__sf_lyrics_artist"
	const albumVar = "__sf_lyrics_album"
	const durationVar = "__sf_lyrics_duration"
	global := p.vm.GlobalObject()
	_ = global.Set(trackVar, trackName)
	_ = global.Set(artistVar, artistName)
	_ = global.Set(albumVar, albumName)
	_ = global.Set(durationVar, durationSec)
	defer func() {
		global.Delete(trackVar)
		global.Delete(artistVar)
		global.Delete(albumVar)
		global.Delete(durationVar)
	}()

	const script = `
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.fetchLyrics === 'function') {
				return extension.fetchLyrics(__sf_lyrics_track, __sf_lyrics_artist, __sf_lyrics_album, __sf_lyrics_duration);
			}
			return null;
		})()
	`

	result, err := RunWithTimeoutAndRecover(p.vm, script, DefaultJSTimeout)
	if err != nil {
		if IsTimeoutError(err) {
			return nil, fmt.Errorf("fetchLyrics timeout: extension took too long to respond")
		}
		return nil, fmt.Errorf("fetchLyrics failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return nil, fmt.Errorf("fetchLyrics returned null")
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal lyrics result: %w", err)
	}

	var extResult ExtLyricsResult
	if err := json.Unmarshal(jsonBytes, &extResult); err != nil {
		return nil, fmt.Errorf("failed to parse lyrics result: %w", err)
	}

	response := &LyricsResponse{
		SyncType:     extResult.SyncType,
		Instrumental: extResult.Instrumental,
		PlainLyrics:  extResult.PlainLyrics,
		Provider:     extResult.Provider,
		Source:       "Extension: " + p.extension.ID,
	}

	if response.Provider == "" {
		response.Provider = p.extension.Manifest.DisplayName
	}

	for _, line := range extResult.Lines {
		response.Lines = append(response.Lines, LyricsLine{
			StartTimeMs: line.StartTimeMs,
			Words:       line.Words,
			EndTimeMs:   line.EndTimeMs,
		})
	}

	if len(response.Lines) == 0 && response.PlainLyrics != "" && !response.Instrumental {
		response.SyncType = "UNSYNCED"
		for _, line := range strings.Split(response.PlainLyrics, "\n") {
			if strings.TrimSpace(line) != "" {
				response.Lines = append(response.Lines, LyricsLine{
					StartTimeMs: 0,
					Words:       line,
					EndTimeMs:   0,
				})
			}
		}
	}

	return response, nil
}

func (m *extensionManager) GetLyricsProviders() []*extensionProviderWrapper {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var providers []*extensionProviderWrapper
	for _, ext := range m.extensions {
		if ext.Enabled && ext.Manifest.IsLyricsProvider() && ext.Error == "" {
			providers = append(providers, newExtensionProviderWrapper(ext))
		}
	}

	sort.Slice(providers, func(i, j int) bool {
		return providers[i].extension.ID < providers[j].extension.ID
	})

	return providers
}
