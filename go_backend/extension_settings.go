// Package gobackend provides extension settings storage
package gobackend

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
)

// ExtensionSettingsStore manages settings for all extensions
type ExtensionSettingsStore struct {
	mu       sync.RWMutex
	dataDir  string
	settings map[string]map[string]interface{} // extensionID -> settings
}

// Global settings store
var (
	globalSettingsStore     *ExtensionSettingsStore
	globalSettingsStoreOnce sync.Once
)

// GetExtensionSettingsStore returns the global settings store
func GetExtensionSettingsStore() *ExtensionSettingsStore {
	globalSettingsStoreOnce.Do(func() {
		globalSettingsStore = &ExtensionSettingsStore{
			settings: make(map[string]map[string]interface{}),
		}
	})
	return globalSettingsStore
}

// SetDataDir sets the data directory for settings storage
func (s *ExtensionSettingsStore) SetDataDir(dataDir string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.dataDir = dataDir
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return fmt.Errorf("failed to create settings directory: %w", err)
	}

	// Load all existing settings
	return s.loadAllSettings()
}

// getSettingsPath returns the path to an extension's settings file
func (s *ExtensionSettingsStore) getSettingsPath(extensionID string) string {
	return filepath.Join(s.dataDir, extensionID, "settings.json")
}

// loadAllSettings loads settings for all extensions from disk
func (s *ExtensionSettingsStore) loadAllSettings() error {
	entries, err := os.ReadDir(s.dataDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}

	for _, entry := range entries {
		if entry.IsDir() {
			extensionID := entry.Name()
			settings, err := s.loadSettings(extensionID)
			if err != nil {
				GoLog("[ExtensionSettings] Failed to load settings for %s: %v\n", extensionID, err)
				continue
			}
			s.settings[extensionID] = settings
		}
	}

	return nil
}

// loadSettings loads settings for a specific extension
func (s *ExtensionSettingsStore) loadSettings(extensionID string) (map[string]interface{}, error) {
	settingsPath := s.getSettingsPath(extensionID)
	data, err := os.ReadFile(settingsPath)
	if err != nil {
		if os.IsNotExist(err) {
			return make(map[string]interface{}), nil
		}
		return nil, err
	}

	var settings map[string]interface{}
	if err := json.Unmarshal(data, &settings); err != nil {
		return nil, err
	}

	return settings, nil
}

// saveSettings saves settings for a specific extension
func (s *ExtensionSettingsStore) saveSettings(extensionID string, settings map[string]interface{}) error {
	settingsPath := s.getSettingsPath(extensionID)

	// Create directory if needed
	dir := filepath.Dir(settingsPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	data, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(settingsPath, data, 0644)
}

// Get retrieves a setting value for an extension
// Returns error if extension or key not found (gomobile compatible)
func (s *ExtensionSettingsStore) Get(extensionID, key string) (interface{}, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	extSettings, exists := s.settings[extensionID]
	if !exists {
		return nil, fmt.Errorf("extension '%s' settings not found", extensionID)
	}

	value, exists := extSettings[key]
	if !exists {
		return nil, fmt.Errorf("setting '%s' not found for extension '%s'", key, extensionID)
	}
	return value, nil
}

// GetAll retrieves all settings for an extension
func (s *ExtensionSettingsStore) GetAll(extensionID string) map[string]interface{} {
	s.mu.RLock()
	defer s.mu.RUnlock()

	extSettings, exists := s.settings[extensionID]
	if !exists {
		return make(map[string]interface{})
	}

	// Return a copy
	result := make(map[string]interface{})
	for k, v := range extSettings {
		result[k] = v
	}
	return result
}

// Set stores a setting value for an extension
func (s *ExtensionSettingsStore) Set(extensionID, key string, value interface{}) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.settings[extensionID]; !exists {
		s.settings[extensionID] = make(map[string]interface{})
	}

	s.settings[extensionID][key] = value

	// Persist to disk
	return s.saveSettings(extensionID, s.settings[extensionID])
}

// SetAll stores all settings for an extension
func (s *ExtensionSettingsStore) SetAll(extensionID string, settings map[string]interface{}) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.settings[extensionID] = settings

	// Persist to disk
	return s.saveSettings(extensionID, settings)
}

// Remove removes a setting for an extension
func (s *ExtensionSettingsStore) Remove(extensionID, key string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	extSettings, exists := s.settings[extensionID]
	if !exists {
		return nil
	}

	delete(extSettings, key)

	// Persist to disk
	return s.saveSettings(extensionID, extSettings)
}

// RemoveAll removes all settings for an extension
func (s *ExtensionSettingsStore) RemoveAll(extensionID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	delete(s.settings, extensionID)

	// Remove settings file
	settingsPath := s.getSettingsPath(extensionID)
	if err := os.Remove(settingsPath); err != nil && !os.IsNotExist(err) {
		return err
	}

	return nil
}

// GetAllExtensionSettings returns settings for all extensions as JSON
func (s *ExtensionSettingsStore) GetAllExtensionSettingsJSON() (string, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	data, err := json.Marshal(s.settings)
	if err != nil {
		return "", err
	}

	return string(data), nil
}
