// Package gobackend provides extension manifest parsing and validation
package gobackend

import (
	"encoding/json"
	"fmt"
	"strings"
)

// ExtensionType represents the type of extension
type ExtensionType string

const (
	ExtensionTypeMetadataProvider ExtensionType = "metadata_provider"
	ExtensionTypeDownloadProvider ExtensionType = "download_provider"
)

// SettingType represents the type of a setting field
type SettingType string

const (
	SettingTypeString SettingType = "string"
	SettingTypeNumber SettingType = "number"
	SettingTypeBool   SettingType = "boolean"
	SettingTypeSelect SettingType = "select"
)

// ExtensionPermissions defines what resources an extension can access
type ExtensionPermissions struct {
	Network []string `json:"network"` // List of allowed domains
	Storage bool     `json:"storage"` // Whether extension can use storage API
}

// ExtensionSetting defines a configurable setting for an extension
type ExtensionSetting struct {
	Key         string      `json:"key"`
	Type        SettingType `json:"type"`
	Label       string      `json:"label"`
	Description string      `json:"description,omitempty"`
	Required    bool        `json:"required,omitempty"`
	Secret      bool        `json:"secret,omitempty"`
	Default     interface{} `json:"default,omitempty"`
	Options     []string    `json:"options,omitempty"` // For select type
}

// QualityOption represents a quality option for download providers
type QualityOption struct {
	ID          string                   `json:"id"`                 // Unique identifier (e.g., "mp3_320", "opus_128")
	Label       string                   `json:"label"`              // Display name (e.g., "MP3 320kbps")
	Description string                   `json:"description"`        // Optional description (e.g., "Best quality MP3")
	Settings    []QualitySpecificSetting `json:"settings,omitempty"` // Quality-specific settings
}

// QualitySpecificSetting represents a setting that's specific to a quality option
type QualitySpecificSetting struct {
	Key         string      `json:"key"`
	Type        SettingType `json:"type"`
	Label       string      `json:"label"`
	Description string      `json:"description,omitempty"`
	Required    bool        `json:"required,omitempty"`
	Secret      bool        `json:"secret,omitempty"`
	Default     interface{} `json:"default,omitempty"`
	Options     []string    `json:"options,omitempty"` // For select type
}

// SearchBehaviorConfig defines custom search behavior for an extension
type SearchBehaviorConfig struct {
	Enabled         bool   `json:"enabled"`                   // Whether extension provides custom search
	Placeholder     string `json:"placeholder,omitempty"`     // Placeholder text for search box
	Primary         bool   `json:"primary,omitempty"`         // If true, show as primary search tab
	Icon            string `json:"icon,omitempty"`            // Icon for search tab
	ThumbnailRatio  string `json:"thumbnailRatio,omitempty"`  // Thumbnail aspect ratio: "square" (1:1), "wide" (16:9), "portrait" (2:3)
	ThumbnailWidth  int    `json:"thumbnailWidth,omitempty"`  // Custom thumbnail width in pixels
	ThumbnailHeight int    `json:"thumbnailHeight,omitempty"` // Custom thumbnail height in pixels
}

// TrackMatchingConfig defines custom track matching behavior
type TrackMatchingConfig struct {
	CustomMatching    bool   `json:"customMatching"`              // Whether extension handles matching
	Strategy          string `json:"strategy,omitempty"`          // "isrc", "name", "duration", "custom"
	DurationTolerance int    `json:"durationTolerance,omitempty"` // Tolerance in seconds for duration matching
}

// PostProcessingHook defines a post-processing hook
type PostProcessingHook struct {
	ID               string   `json:"id"`                         // Unique identifier
	Name             string   `json:"name"`                       // Display name
	Description      string   `json:"description,omitempty"`      // Description
	DefaultEnabled   bool     `json:"defaultEnabled,omitempty"`   // Whether enabled by default
	SupportedFormats []string `json:"supportedFormats,omitempty"` // Supported file formats (e.g., ["flac", "mp3"])
}

// PostProcessingConfig defines post-processing capabilities
type PostProcessingConfig struct {
	Enabled bool                 `json:"enabled"`         // Whether extension provides post-processing
	Hooks   []PostProcessingHook `json:"hooks,omitempty"` // Available hooks
}

// ExtensionManifest represents the manifest.json of an extension
type ExtensionManifest struct {
	Name                   string                `json:"name"`
	DisplayName            string                `json:"displayName"`
	Version                string                `json:"version"`
	Author                 string                `json:"author"`
	Description            string                `json:"description"`
	Homepage               string                `json:"homepage,omitempty"`
	Icon                   string                `json:"icon,omitempty"` // Icon filename (e.g., "icon.png")
	Types                  []ExtensionType       `json:"type"`
	Permissions            ExtensionPermissions  `json:"permissions"`
	Settings               []ExtensionSetting    `json:"settings,omitempty"`
	QualityOptions         []QualityOption       `json:"qualityOptions,omitempty"` // Custom quality options for download providers
	MinAppVersion          string                `json:"minAppVersion,omitempty"`
	SkipMetadataEnrichment bool                  `json:"skipMetadataEnrichment,omitempty"` // If true, don't enrich metadata from Deezer/Spotify
	SkipBuiltInFallback    bool                  `json:"skipBuiltInFallback,omitempty"`    // If true, don't fallback to built-in providers (tidal/qobuz/amazon)
	SearchBehavior         *SearchBehaviorConfig `json:"searchBehavior,omitempty"`         // Custom search behavior
	TrackMatching          *TrackMatchingConfig  `json:"trackMatching,omitempty"`          // Custom track matching
	PostProcessing         *PostProcessingConfig `json:"postProcessing,omitempty"`         // Post-processing hooks
}

// ManifestValidationError represents a validation error in the manifest
type ManifestValidationError struct {
	Field   string
	Message string
}

func (e *ManifestValidationError) Error() string {
	return fmt.Sprintf("manifest validation error: %s - %s", e.Field, e.Message)
}

// ParseManifest parses and validates a manifest from JSON bytes
func ParseManifest(data []byte) (*ExtensionManifest, error) {
	var manifest ExtensionManifest
	if err := json.Unmarshal(data, &manifest); err != nil {
		return nil, fmt.Errorf("failed to parse manifest JSON: %w", err)
	}

	if err := manifest.Validate(); err != nil {
		return nil, err
	}

	return &manifest, nil
}

// Validate checks if the manifest has all required fields and valid values
func (m *ExtensionManifest) Validate() error {
	// Check required fields
	if strings.TrimSpace(m.Name) == "" {
		return &ManifestValidationError{Field: "name", Message: "name is required"}
	}

	if strings.TrimSpace(m.Version) == "" {
		return &ManifestValidationError{Field: "version", Message: "version is required"}
	}

	if strings.TrimSpace(m.Author) == "" {
		return &ManifestValidationError{Field: "author", Message: "author is required"}
	}

	if strings.TrimSpace(m.Description) == "" {
		return &ManifestValidationError{Field: "description", Message: "description is required"}
	}

	if len(m.Types) == 0 {
		return &ManifestValidationError{Field: "type", Message: "at least one type is required"}
	}

	// Validate extension types
	for _, t := range m.Types {
		if t != ExtensionTypeMetadataProvider && t != ExtensionTypeDownloadProvider {
			return &ManifestValidationError{
				Field:   "type",
				Message: fmt.Sprintf("invalid extension type: %s (must be 'metadata_provider' or 'download_provider')", t),
			}
		}
	}

	// Validate settings if present
	for i, setting := range m.Settings {
		if strings.TrimSpace(setting.Key) == "" {
			return &ManifestValidationError{
				Field:   fmt.Sprintf("settings[%d].key", i),
				Message: "setting key is required",
			}
		}

		if setting.Type == "" {
			return &ManifestValidationError{
				Field:   fmt.Sprintf("settings[%d].type", i),
				Message: "setting type is required",
			}
		}

		// Validate setting type
		validTypes := map[SettingType]bool{
			SettingTypeString: true,
			SettingTypeNumber: true,
			SettingTypeBool:   true,
			SettingTypeSelect: true,
		}
		if !validTypes[setting.Type] {
			return &ManifestValidationError{
				Field:   fmt.Sprintf("settings[%d].type", i),
				Message: fmt.Sprintf("invalid setting type: %s", setting.Type),
			}
		}

		// Select type requires options
		if setting.Type == SettingTypeSelect && len(setting.Options) == 0 {
			return &ManifestValidationError{
				Field:   fmt.Sprintf("settings[%d].options", i),
				Message: "select type requires options",
			}
		}
	}

	return nil
}

// HasType checks if the extension has a specific type
func (m *ExtensionManifest) HasType(t ExtensionType) bool {
	for _, et := range m.Types {
		if et == t {
			return true
		}
	}
	return false
}

// IsMetadataProvider returns true if extension provides metadata
func (m *ExtensionManifest) IsMetadataProvider() bool {
	return m.HasType(ExtensionTypeMetadataProvider)
}

// IsDownloadProvider returns true if extension provides downloads
func (m *ExtensionManifest) IsDownloadProvider() bool {
	return m.HasType(ExtensionTypeDownloadProvider)
}

// IsDomainAllowed checks if a domain is in the allowed network permissions
func (m *ExtensionManifest) IsDomainAllowed(domain string) bool {
	domain = strings.ToLower(strings.TrimSpace(domain))
	for _, allowed := range m.Permissions.Network {
		allowed = strings.ToLower(strings.TrimSpace(allowed))
		if allowed == domain {
			return true
		}
		// Support wildcard subdomains (e.g., *.example.com)
		if strings.HasPrefix(allowed, "*.") {
			suffix := allowed[1:] // Remove the *
			if strings.HasSuffix(domain, suffix) {
				return true
			}
		}
	}
	return false
}

// HasCustomSearch returns true if extension provides custom search
func (m *ExtensionManifest) HasCustomSearch() bool {
	return m.SearchBehavior != nil && m.SearchBehavior.Enabled
}

// HasCustomMatching returns true if extension provides custom track matching
func (m *ExtensionManifest) HasCustomMatching() bool {
	return m.TrackMatching != nil && m.TrackMatching.CustomMatching
}

// HasPostProcessing returns true if extension provides post-processing
func (m *ExtensionManifest) HasPostProcessing() bool {
	return m.PostProcessing != nil && m.PostProcessing.Enabled
}

// GetPostProcessingHooks returns all post-processing hooks
func (m *ExtensionManifest) GetPostProcessingHooks() []PostProcessingHook {
	if m.PostProcessing == nil {
		return nil
	}
	return m.PostProcessing.Hooks
}

// ToJSON serializes the manifest to JSON
func (m *ExtensionManifest) ToJSON() ([]byte, error) {
	return json.Marshal(m)
}
