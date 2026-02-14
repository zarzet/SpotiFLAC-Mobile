// Package gobackend provides extension manifest parsing and validation
package gobackend

import (
	"encoding/json"
	"fmt"
	"strings"
)

type ExtensionType string

const (
	ExtensionTypeMetadataProvider ExtensionType = "metadata_provider"
	ExtensionTypeDownloadProvider ExtensionType = "download_provider"
	ExtensionTypeLyricsProvider   ExtensionType = "lyrics_provider"
)

type SettingType string

const (
	SettingTypeString SettingType = "string"
	SettingTypeNumber SettingType = "number"
	SettingTypeBool   SettingType = "boolean"
	SettingTypeSelect SettingType = "select"
	SettingTypeButton SettingType = "button" // Action button that calls a JS function
)

type ExtensionPermissions struct {
	Network []string `json:"network"`
	Storage bool     `json:"storage"`
	File    bool     `json:"file"`
}

type ExtensionSetting struct {
	Key         string      `json:"key"`
	Type        SettingType `json:"type"`
	Label       string      `json:"label"`
	Description string      `json:"description,omitempty"`
	Required    bool        `json:"required,omitempty"`
	Secret      bool        `json:"secret,omitempty"`
	Default     interface{} `json:"default,omitempty"`
	Options     []string    `json:"options,omitempty"`
	Action      string      `json:"action,omitempty"`
}

type QualityOption struct {
	ID          string                   `json:"id"`
	Label       string                   `json:"label"`
	Description string                   `json:"description"`
	Settings    []QualitySpecificSetting `json:"settings,omitempty"`
}

type QualitySpecificSetting struct {
	Key         string      `json:"key"`
	Type        SettingType `json:"type"`
	Label       string      `json:"label"`
	Description string      `json:"description,omitempty"`
	Required    bool        `json:"required,omitempty"`
	Secret      bool        `json:"secret,omitempty"`
	Default     interface{} `json:"default,omitempty"`
	Options     []string    `json:"options,omitempty"`
}

type SearchFilter struct {
	ID    string `json:"id"`
	Label string `json:"label,omitempty"`
	Icon  string `json:"icon,omitempty"`
}

type SearchBehaviorConfig struct {
	Enabled         bool           `json:"enabled"`
	Placeholder     string         `json:"placeholder,omitempty"`
	Primary         bool           `json:"primary,omitempty"`
	Icon            string         `json:"icon,omitempty"`
	ThumbnailRatio  string         `json:"thumbnailRatio,omitempty"`
	ThumbnailWidth  int            `json:"thumbnailWidth,omitempty"`
	ThumbnailHeight int            `json:"thumbnailHeight,omitempty"`
	Filters         []SearchFilter `json:"filters,omitempty"`
}

type URLHandlerConfig struct {
	Enabled  bool     `json:"enabled"`
	Patterns []string `json:"patterns,omitempty"`
}

type TrackMatchingConfig struct {
	CustomMatching    bool   `json:"customMatching"`
	Strategy          string `json:"strategy,omitempty"`
	DurationTolerance int    `json:"durationTolerance,omitempty"`
}

type PostProcessingHook struct {
	ID               string   `json:"id"`
	Name             string   `json:"name"`
	Description      string   `json:"description,omitempty"`
	DefaultEnabled   bool     `json:"defaultEnabled,omitempty"`
	SupportedFormats []string `json:"supportedFormats,omitempty"`
}

type PostProcessingConfig struct {
	Enabled bool                 `json:"enabled"`
	Hooks   []PostProcessingHook `json:"hooks,omitempty"`
}

type ExtensionManifest struct {
	Name                   string                 `json:"name"`
	DisplayName            string                 `json:"displayName"`
	Version                string                 `json:"version"`
	Author                 string                 `json:"author"`
	Description            string                 `json:"description"`
	Homepage               string                 `json:"homepage,omitempty"`
	Icon                   string                 `json:"icon,omitempty"`
	Types                  []ExtensionType        `json:"type"`
	Permissions            ExtensionPermissions   `json:"permissions"`
	Settings               []ExtensionSetting     `json:"settings,omitempty"`
	QualityOptions         []QualityOption        `json:"qualityOptions,omitempty"`
	MinAppVersion          string                 `json:"minAppVersion,omitempty"`
	SkipMetadataEnrichment bool                   `json:"skipMetadataEnrichment,omitempty"`
	SkipBuiltInFallback    bool                   `json:"skipBuiltInFallback,omitempty"`
	SearchBehavior         *SearchBehaviorConfig  `json:"searchBehavior,omitempty"`
	URLHandler             *URLHandlerConfig      `json:"urlHandler,omitempty"`
	TrackMatching          *TrackMatchingConfig   `json:"trackMatching,omitempty"`
	PostProcessing         *PostProcessingConfig  `json:"postProcessing,omitempty"`
	Capabilities           map[string]interface{} `json:"capabilities,omitempty"`
}

type ManifestValidationError struct {
	Field   string
	Message string
}

func (e *ManifestValidationError) Error() string {
	return fmt.Sprintf("manifest validation error: %s - %s", e.Field, e.Message)
}

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

func (m *ExtensionManifest) Validate() error {
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

	for _, t := range m.Types {
		if t != ExtensionTypeMetadataProvider && t != ExtensionTypeDownloadProvider && t != ExtensionTypeLyricsProvider {
			return &ManifestValidationError{
				Field:   "type",
				Message: fmt.Sprintf("invalid extension type: %s (must be 'metadata_provider', 'download_provider', or 'lyrics_provider')", t),
			}
		}
	}

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

		// Select type requires options
		if setting.Type == SettingTypeSelect && len(setting.Options) == 0 {
			return &ManifestValidationError{
				Field:   fmt.Sprintf("settings[%d].options", i),
				Message: "select type requires options",
			}
		}

		if setting.Type == SettingTypeButton && setting.Action == "" {
			return &ManifestValidationError{
				Field:   fmt.Sprintf("settings[%d].action", i),
				Message: "button type requires action (JS function name)",
			}
		}
	}

	return nil
}

func (m *ExtensionManifest) HasType(t ExtensionType) bool {
	for _, et := range m.Types {
		if et == t {
			return true
		}
	}
	return false
}

func (m *ExtensionManifest) IsMetadataProvider() bool {
	return m.HasType(ExtensionTypeMetadataProvider)
}

func (m *ExtensionManifest) IsDownloadProvider() bool {
	return m.HasType(ExtensionTypeDownloadProvider)
}

func (m *ExtensionManifest) IsLyricsProvider() bool {
	return m.HasType(ExtensionTypeLyricsProvider)
}

func (m *ExtensionManifest) IsDomainAllowed(domain string) bool {
	domain = strings.ToLower(strings.TrimSpace(domain))
	for _, allowed := range m.Permissions.Network {
		allowed = strings.ToLower(strings.TrimSpace(allowed))
		if allowed == domain {
			return true
		}
		// Support wildcard subdomains (e.g., *.example.com)
		if strings.HasPrefix(allowed, "*.") {
			suffix := allowed[1:]
			if strings.HasSuffix(domain, suffix) {
				return true
			}
		}
	}
	return false
}

func (m *ExtensionManifest) HasCustomSearch() bool {
	return m.SearchBehavior != nil && m.SearchBehavior.Enabled
}

func (m *ExtensionManifest) HasCustomMatching() bool {
	return m.TrackMatching != nil && m.TrackMatching.CustomMatching
}

func (m *ExtensionManifest) HasPostProcessing() bool {
	return m.PostProcessing != nil && m.PostProcessing.Enabled
}

func (m *ExtensionManifest) HasURLHandler() bool {
	return m.URLHandler != nil && m.URLHandler.Enabled && len(m.URLHandler.Patterns) > 0
}

func (m *ExtensionManifest) MatchesURL(urlStr string) bool {
	if !m.HasURLHandler() {
		return false
	}

	urlStr = strings.ToLower(strings.TrimSpace(urlStr))
	for _, pattern := range m.URLHandler.Patterns {
		pattern = strings.ToLower(strings.TrimSpace(pattern))
		if strings.Contains(urlStr, pattern) {
			return true
		}
	}
	return false
}

func (m *ExtensionManifest) GetPostProcessingHooks() []PostProcessingHook {
	if m.PostProcessing == nil {
		return nil
	}
	return m.PostProcessing.Hooks
}

func (m *ExtensionManifest) ToJSON() ([]byte, error) {
	return json.Marshal(m)
}
