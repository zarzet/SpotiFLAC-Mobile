package gobackend

import (
	"archive/zip"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"

	"github.com/dop251/goja"
)

func compareVersions(v1, v2 string) int {
	parts1 := strings.Split(strings.TrimPrefix(v1, "v"), ".")
	parts2 := strings.Split(strings.TrimPrefix(v2, "v"), ".")

	maxLen := len(parts1)
	if len(parts2) > maxLen {
		maxLen = len(parts2)
	}

	for i := 0; i < maxLen; i++ {
		var n1, n2 int
		if i < len(parts1) {
			n1, _ = strconv.Atoi(parts1[i])
		}
		if i < len(parts2) {
			n2, _ = strconv.Atoi(parts2[i])
		}

		if n1 < n2 {
			return -1
		}
		if n1 > n2 {
			return 1
		}
	}

	return 0
}

type loadedExtension struct {
	ID          string             `json:"id"`
	Manifest    *ExtensionManifest `json:"manifest"`
	VM          *goja.Runtime      `json:"-"`
	VMMu        sync.Mutex         `json:"-"`
	runtime     *extensionRuntime
	initialized bool
	Enabled     bool   `json:"enabled"`
	Error       string `json:"error,omitempty"`
	DataDir     string `json:"data_dir"`
	SourceDir   string `json:"source_dir"`
	IconPath    string `json:"icon_path"`
}

func getExtensionInitSettings(extensionID string) map[string]interface{} {
	settings := GetExtensionSettingsStore().GetAll(extensionID)
	if len(settings) == 0 {
		return settings
	}

	filtered := make(map[string]interface{}, len(settings))
	for key, value := range settings {
		if strings.HasPrefix(key, "_") {
			continue
		}
		filtered[key] = value
	}
	return filtered
}

func ensureRuntimeReadyLocked(ext *loadedExtension, applyStoredSettings bool) error {
	if ext.VM == nil || ext.runtime == nil {
		if err := initializeVMLocked(ext); err != nil {
			ext.Error = err.Error()
			ext.Enabled = false
			return err
		}
	}

	if applyStoredSettings && !ext.initialized {
		settings := getExtensionInitSettings(ext.ID)
		if len(settings) > 0 {
			if err := initializeExtensionWithSettingsLocked(ext, settings); err != nil {
				teardownVMLocked(ext)
				ext.Error = err.Error()
				ext.Enabled = false
				return err
			}
		} else {
			ext.initialized = true
		}
	}

	ext.Error = ""
	return nil
}

func (ext *loadedExtension) ensureRuntimeReady() error {
	ext.VMMu.Lock()
	defer ext.VMMu.Unlock()

	return ensureRuntimeReadyLocked(ext, true)
}

func (ext *loadedExtension) lockReadyVM() (*goja.Runtime, error) {
	ext.VMMu.Lock()
	if err := ensureRuntimeReadyLocked(ext, true); err != nil {
		ext.VMMu.Unlock()
		return nil, err
	}
	return ext.VM, nil
}

type extensionManager struct {
	mu            sync.RWMutex
	extensions    map[string]*loadedExtension
	extensionsDir string
	dataDir       string
}

var (
	globalExtManager     *extensionManager
	globalExtManagerOnce sync.Once
)

func getExtensionManager() *extensionManager {
	globalExtManagerOnce.Do(func() {
		globalExtManager = &extensionManager{
			extensions: make(map[string]*loadedExtension),
		}
	})
	return globalExtManager
}

func (m *extensionManager) SetDirectories(extensionsDir, dataDir string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.extensionsDir = extensionsDir
	m.dataDir = dataDir

	if err := os.MkdirAll(extensionsDir, 0755); err != nil {
		return fmt.Errorf("failed to create extensions directory: %w", err)
	}
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return fmt.Errorf("failed to create data directory: %w", err)
	}

	return nil
}

func (m *extensionManager) LoadExtensionFromFile(filePath string) (*loadedExtension, error) {
	if !strings.HasSuffix(strings.ToLower(filePath), ".spotiflac-ext") {
		return nil, fmt.Errorf("Invalid file format. Please select a .spotiflac-ext file")
	}

	zipReader, err := zip.OpenReader(filePath)
	if err != nil {
		return nil, fmt.Errorf("Cannot open extension file. The file may be corrupted or not a valid extension package")
	}
	defer zipReader.Close()

	var manifestData []byte
	var hasIndexJS bool
	for _, file := range zipReader.File {
		name := filepath.Base(file.Name)
		if name == "manifest.json" {
			rc, err := file.Open()
			if err != nil {
				return nil, fmt.Errorf("failed to open manifest.json: %w", err)
			}
			manifestData, err = io.ReadAll(rc)
			rc.Close()
			if err != nil {
				return nil, fmt.Errorf("failed to read manifest.json: %w", err)
			}
		}
		if name == "index.js" {
			hasIndexJS = true
		}
	}

	if manifestData == nil {
		return nil, fmt.Errorf("Invalid extension package: manifest.json not found")
	}

	if !hasIndexJS {
		return nil, fmt.Errorf("Invalid extension package: index.js not found")
	}

	manifest, err := ParseManifest(manifestData)
	if err != nil {
		return nil, fmt.Errorf("Invalid extension manifest: %w", err)
	}

	m.mu.RLock()
	existing, exists := m.extensions[manifest.Name]
	var existingVersion string
	var existingDisplayName string
	if exists {
		existingVersion = existing.Manifest.Version
		existingDisplayName = existing.Manifest.DisplayName
	}
	m.mu.RUnlock()

	if exists {
		versionCompare := compareVersions(manifest.Version, existingVersion)
		if versionCompare > 0 {
			return m.UpgradeExtension(filePath)
		} else if versionCompare == 0 {
			return nil, fmt.Errorf("Extension '%s' v%s is already installed", existingDisplayName, existingVersion)
		} else {
			return nil, fmt.Errorf("Cannot downgrade '%s' from v%s to v%s", existingDisplayName, existingVersion, manifest.Version)
		}
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	if _, exists := m.extensions[manifest.Name]; exists {
		return nil, fmt.Errorf("Extension '%s' was installed by another process", manifest.DisplayName)
	}

	extDir := filepath.Join(m.extensionsDir, manifest.Name)
	if err := os.MkdirAll(extDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create extension directory: %w", err)
	}

	for _, file := range zipReader.File {
		if file.FileInfo().IsDir() {
			continue
		}

		relPath := filepath.Clean(file.Name)
		if strings.HasPrefix(relPath, "..") || filepath.IsAbs(relPath) {
			GoLog("[Extension] Skipping unsafe path in archive: %s\n", file.Name)
			continue
		}
		destPath := filepath.Join(extDir, relPath)

		destDir := filepath.Dir(destPath)
		if err := os.MkdirAll(destDir, 0755); err != nil {
			return nil, fmt.Errorf("failed to create directory %s: %w", destDir, err)
		}

		destFile, err := os.Create(destPath)
		if err != nil {
			return nil, fmt.Errorf("failed to create file %s: %w", destPath, err)
		}

		srcFile, err := file.Open()
		if err != nil {
			destFile.Close()
			return nil, fmt.Errorf("failed to open file in archive: %w", err)
		}

		_, err = io.Copy(destFile, srcFile)
		srcFile.Close()
		destFile.Close()
		if err != nil {
			return nil, fmt.Errorf("failed to extract file: %w", err)
		}
	}

	extDataDir := filepath.Join(m.dataDir, manifest.Name)
	if err := os.MkdirAll(extDataDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create extension data directory: %w", err)
	}

	ext := &loadedExtension{
		ID:        manifest.Name,
		Manifest:  manifest,
		Enabled:   false, // New extensions start disabled
		DataDir:   extDataDir,
		SourceDir: extDir,
	}

	if err := validateExtensionLoad(ext); err != nil {
		ext.Error = err.Error()
		ext.Enabled = false
		GoLog("[Extension] Failed to validate extension %s: %v\n", manifest.Name, err)
	}

	m.extensions[manifest.Name] = ext
	GoLog("[Extension] Loaded extension: %s v%s\n", manifest.DisplayName, manifest.Version)

	return ext, nil
}

func initializeVMLocked(ext *loadedExtension) error {
	ext.VM = nil
	ext.runtime = nil
	ext.initialized = false
	vm := goja.New()
	ext.VM = vm

	indexPath := filepath.Join(ext.SourceDir, "index.js")
	jsCode, err := os.ReadFile(indexPath)
	if err != nil {
		return fmt.Errorf("failed to read index.js: %w", err)
	}

	runtime := newExtensionRuntime(ext)
	ext.runtime = runtime
	runtime.RegisterAPIs(vm)
	runtime.RegisterGoBackendAPIs(vm)

	console := vm.NewObject()
	console.Set("log", func(call goja.FunctionCall) goja.Value {
		args := make([]interface{}, len(call.Arguments))
		for i, arg := range call.Arguments {
			args[i] = arg.Export()
		}
		GoLog("[Extension:%s] %v\n", ext.ID, args)
		return goja.Undefined()
	})
	vm.Set("console", console)

	var registeredExtension goja.Value
	vm.Set("registerExtension", func(call goja.FunctionCall) goja.Value {
		if len(call.Arguments) > 0 {
			registeredExtension = call.Arguments[0]
			vm.Set("extension", call.Arguments[0])
		}
		return goja.Undefined()
	})

	_, err = vm.RunString(string(jsCode))
	if err != nil {
		return fmt.Errorf("failed to execute extension code: %w", err)
	}

	if registeredExtension == nil || goja.IsUndefined(registeredExtension) {
		return fmt.Errorf("extension did not call registerExtension()")
	}

	return nil
}

func (m *extensionManager) initializeVM(ext *loadedExtension) error {
	ext.VMMu.Lock()
	defer ext.VMMu.Unlock()
	return initializeVMLocked(ext)
}

func initializeExtensionWithSettingsLocked(
	ext *loadedExtension,
	settings map[string]interface{},
) error {
	if ext.VM == nil {
		return fmt.Errorf("Extension failed to load. Please reinstall the extension")
	}

	settingsJSON, err := json.Marshal(settings)
	if err != nil {
		return fmt.Errorf("Failed to save settings")
	}

	script := fmt.Sprintf(`
		(function() {
			var settings = %s;
			if (typeof extension !== 'undefined' && typeof extension.initialize === 'function') {
				try {
					extension.initialize(settings);
					return { success: true };
				} catch (e) {
					return { success: false, error: e.toString() };
				}
			}
			return { success: true, message: 'no initialize function' };
		})()
	`, string(settingsJSON))

	result, err := ext.VM.RunString(script)
	if err != nil {
		ext.Error = fmt.Sprintf("initialize failed: %v", err)
		ext.Enabled = false
		GoLog("[Extension] Initialize error for %s: %v\n", ext.ID, err)
		return err
	}

	if result != nil && !goja.IsUndefined(result) {
		exported := result.Export()
		if resultMap, ok := exported.(map[string]interface{}); ok {
			if success, ok := resultMap["success"].(bool); ok && !success {
				errMsg := "unknown error"
				if e, ok := resultMap["error"].(string); ok {
					errMsg = e
				}
				ext.Error = errMsg
				ext.Enabled = false
				GoLog("[Extension] Initialize failed for %s: %s\n", ext.ID, errMsg)
				return fmt.Errorf("initialize failed: %s", errMsg)
			}
		}
	}

	ext.initialized = true
	GoLog("[Extension] Initialized %s\n", ext.ID)
	return nil
}

func runCleanupLocked(ext *loadedExtension) error {
	if ext.VM != nil {
		script := `
			(function() {
				if (typeof extension !== 'undefined' && typeof extension.cleanup === 'function') {
					try {
						extension.cleanup();
						return { success: true };
					} catch (e) {
						return { success: false, error: e.toString() };
					}
				}
				return { success: true, message: 'no cleanup function' };
			})()
		`

		result, err := ext.VM.RunString(script)
		if err != nil {
			return err
		}

		if result != nil && !goja.IsUndefined(result) {
			exported := result.Export()
			if resultMap, ok := exported.(map[string]interface{}); ok {
				if success, ok := resultMap["success"].(bool); ok && !success {
					errMsg := "unknown error"
					if e, ok := resultMap["error"].(string); ok {
						errMsg = e
					}
					return fmt.Errorf("cleanup failed: %s", errMsg)
				}
			}
		}

		if result != nil && !goja.IsUndefined(result) && !goja.IsNull(result) {
			GoLog("[Extension] Cleanup called for %s\n", ext.ID)
		}
	}
	return nil
}

func teardownVMLocked(ext *loadedExtension) {
	if err := runCleanupLocked(ext); err != nil {
		GoLog("[Extension] Error calling cleanup for %s: %v\n", ext.ID, err)
	}
	if ext.runtime != nil {
		if err := ext.runtime.flushStorageNow(); err != nil {
			GoLog("[Extension] Failed to flush storage for %s: %v\n", ext.ID, err)
		}
		ext.runtime.closeStorageFlusher()
	}
	ext.runtime = nil
	ext.VM = nil
	ext.initialized = false
}

func validateExtensionLoad(ext *loadedExtension) error {
	ext.VMMu.Lock()
	defer ext.VMMu.Unlock()

	if err := initializeVMLocked(ext); err != nil {
		return err
	}
	teardownVMLocked(ext)
	return nil
}

func (m *extensionManager) UnloadExtension(extensionID string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	ext, exists := m.extensions[extensionID]
	if !exists {
		return fmt.Errorf("Extension not found")
	}

	ext.VMMu.Lock()
	teardownVMLocked(ext)
	ext.VMMu.Unlock()

	delete(m.extensions, extensionID)
	GoLog("[Extension] Unloaded extension: %s\n", extensionID)

	return nil
}

func (m *extensionManager) GetExtension(extensionID string) (*loadedExtension, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	ext, exists := m.extensions[extensionID]
	if !exists {
		return nil, fmt.Errorf("Extension not found")
	}
	return ext, nil
}

func (m *extensionManager) GetAllExtensions() []*loadedExtension {
	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make([]*loadedExtension, 0, len(m.extensions))
	for _, ext := range m.extensions {
		result = append(result, ext)
	}
	return result
}

func (m *extensionManager) SetExtensionEnabled(extensionID string, enabled bool) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	ext, exists := m.extensions[extensionID]
	if !exists {
		return fmt.Errorf("Extension not found")
	}

	if enabled {
		ext.Enabled = true
		if err := ext.ensureRuntimeReady(); err != nil {
			store := GetExtensionSettingsStore()
			ext.Enabled = false
			_ = store.Set(extensionID, "_enabled", false)
			return err
		}
	} else {
		ext.Enabled = false
		ext.Error = ""
		ext.VMMu.Lock()
		teardownVMLocked(ext)
		ext.VMMu.Unlock()
	}
	GoLog("[Extension] %s %s\n", extensionID, map[bool]string{true: "enabled", false: "disabled"}[enabled])

	store := GetExtensionSettingsStore()
	if err := store.Set(extensionID, "_enabled", enabled); err != nil {
		GoLog("[Extension] Failed to persist enabled state for %s: %v\n", extensionID, err)
	}

	return nil
}

func (m *extensionManager) LoadExtensionsFromDirectory(dirPath string) ([]string, []error) {
	var loaded []string
	var errors []error

	entries, err := os.ReadDir(dirPath)
	if err != nil {
		if os.IsNotExist(err) {
			return loaded, errors
		}
		return nil, []error{fmt.Errorf("failed to read extensions directory: %w", err)}
	}

	for _, entry := range entries {
		if entry.IsDir() {
			manifestPath := filepath.Join(dirPath, entry.Name(), "manifest.json")
			if _, err := os.Stat(manifestPath); err == nil {
				ext, err := m.loadExtensionFromDirectory(filepath.Join(dirPath, entry.Name()))
				if err != nil {
					GoLog("[Extension] Failed to load %s: %v\n", entry.Name(), err)
					errors = append(errors, fmt.Errorf("%s: %w", entry.Name(), err))
				} else {
					loaded = append(loaded, ext.ID)
				}
			}
		} else if strings.HasSuffix(strings.ToLower(entry.Name()), ".spotiflac-ext") {
			ext, err := m.LoadExtensionFromFile(filepath.Join(dirPath, entry.Name()))
			if err != nil {
				GoLog("[Extension] Failed to load %s: %v\n", entry.Name(), err)
				errors = append(errors, fmt.Errorf("%s: %w", entry.Name(), err))
			} else {
				loaded = append(loaded, ext.ID)
			}
		}
	}

	return loaded, errors
}

func (m *extensionManager) loadExtensionFromDirectory(dirPath string) (*loadedExtension, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	manifestPath := filepath.Join(dirPath, "manifest.json")
	manifestData, err := os.ReadFile(manifestPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read manifest.json: %w", err)
	}

	manifest, err := ParseManifest(manifestData)
	if err != nil {
		return nil, fmt.Errorf("Invalid extension manifest: %w", err)
	}

	indexPath := filepath.Join(dirPath, "index.js")
	if _, err := os.Stat(indexPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("Extension is missing index.js file")
	}

	if existing, exists := m.extensions[manifest.Name]; exists {
		GoLog("[Extension] Extension '%s' already loaded, skipping\n", manifest.DisplayName)
		return existing, nil
	}

	extDataDir := filepath.Join(m.dataDir, manifest.Name)
	if err := os.MkdirAll(extDataDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create extension data directory: %w", err)
	}

	ext := &loadedExtension{
		ID:        manifest.Name,
		Manifest:  manifest,
		Enabled:   false, // Will be restored from settings store
		DataDir:   extDataDir,
		SourceDir: dirPath,
	}

	store := GetExtensionSettingsStore()
	if enabledVal, err := store.Get(manifest.Name, "_enabled"); err == nil {
		if enabled, ok := enabledVal.(bool); ok {
			ext.Enabled = enabled
			GoLog("[Extension] Restored enabled state for %s: %v\n", manifest.Name, enabled)
		}
	}

	if err := validateExtensionLoad(ext); err != nil {
		ext.Error = err.Error()
		ext.Enabled = false
		GoLog("[Extension] Failed to validate extension %s: %v\n", manifest.Name, err)
	}

	m.extensions[manifest.Name] = ext
	GoLog("[Extension] Loaded extension: %s v%s\n", manifest.DisplayName, manifest.Version)

	return ext, nil
}

func (m *extensionManager) RemoveExtension(extensionID string) error {
	ext, err := m.GetExtension(extensionID)
	if err != nil {
		return err
	}

	if err := m.UnloadExtension(extensionID); err != nil {
		return err
	}

	if ext.SourceDir != "" {
		if err := os.RemoveAll(ext.SourceDir); err != nil {
			GoLog("[Extension] Warning: failed to remove source dir: %v\n", err)
		}
	}

	return nil
}

// Only allows upgrades (new version > current version), not downgrades
func (m *extensionManager) UpgradeExtension(filePath string) (*loadedExtension, error) {
	if !strings.HasSuffix(strings.ToLower(filePath), ".spotiflac-ext") {
		return nil, fmt.Errorf("Invalid file format. Please select a .spotiflac-ext file")
	}

	zipReader, err := zip.OpenReader(filePath)
	if err != nil {
		return nil, fmt.Errorf("Cannot open extension file. The file may be corrupted or not a valid extension package")
	}
	defer zipReader.Close()

	var manifestData []byte
	var hasIndexJS bool
	for _, file := range zipReader.File {
		name := filepath.Base(file.Name)
		if name == "manifest.json" {
			rc, err := file.Open()
			if err != nil {
				return nil, fmt.Errorf("failed to open manifest.json: %w", err)
			}
			manifestData, err = io.ReadAll(rc)
			rc.Close()
			if err != nil {
				return nil, fmt.Errorf("failed to read manifest.json: %w", err)
			}
		}
		if name == "index.js" {
			hasIndexJS = true
		}
	}

	if manifestData == nil {
		return nil, fmt.Errorf("Invalid extension package: manifest.json not found")
	}

	if !hasIndexJS {
		return nil, fmt.Errorf("Invalid extension package: index.js not found")
	}

	newManifest, err := ParseManifest(manifestData)
	if err != nil {
		return nil, fmt.Errorf("Invalid extension manifest: %w", err)
	}

	m.mu.RLock()
	existing, exists := m.extensions[newManifest.Name]
	m.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("Extension '%s' is not installed. Use install instead of upgrade.", newManifest.DisplayName)
	}

	versionCompare := compareVersions(newManifest.Version, existing.Manifest.Version)
	if versionCompare < 0 {
		return nil, fmt.Errorf("Cannot downgrade extension. Current version: %s, New version: %s", existing.Manifest.Version, newManifest.Version)
	}
	if versionCompare == 0 {
		return nil, fmt.Errorf("Extension is already at version %s", existing.Manifest.Version)
	}

	GoLog("[Extension] Upgrading %s from v%s to v%s\n", newManifest.DisplayName, existing.Manifest.Version, newManifest.Version)

	extDataDir := existing.DataDir
	extDir := existing.SourceDir
	wasEnabled := existing.Enabled

	m.UnloadExtension(existing.ID)

	if extDir != "" {
		if err := os.RemoveAll(extDir); err != nil {
			GoLog("[Extension] Warning: failed to remove old source dir: %v\n", err)
		}
	}

	if err := os.MkdirAll(extDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create extension directory: %w", err)
	}

	for _, file := range zipReader.File {
		if file.FileInfo().IsDir() {
			continue
		}

		relPath := filepath.Clean(file.Name)
		if strings.HasPrefix(relPath, "..") || filepath.IsAbs(relPath) {
			GoLog("[Extension] Skipping unsafe path in archive: %s\n", file.Name)
			continue
		}
		destPath := filepath.Join(extDir, relPath)

		destDir := filepath.Dir(destPath)
		if err := os.MkdirAll(destDir, 0755); err != nil {
			return nil, fmt.Errorf("failed to create directory %s: %w", destDir, err)
		}

		destFile, err := os.Create(destPath)
		if err != nil {
			return nil, fmt.Errorf("failed to create file %s: %w", destPath, err)
		}

		srcFile, err := file.Open()
		if err != nil {
			destFile.Close()
			return nil, fmt.Errorf("failed to open file in archive: %w", err)
		}

		_, err = io.Copy(destFile, srcFile)
		srcFile.Close()
		destFile.Close()
		if err != nil {
			return nil, fmt.Errorf("failed to extract file: %w", err)
		}
	}

	ext := &loadedExtension{
		ID:        newManifest.Name,
		Manifest:  newManifest,
		Enabled:   wasEnabled, // Preserve enabled state from before upgrade
		DataDir:   extDataDir,
		SourceDir: extDir,
	}

	if wasEnabled {
		if err := ext.ensureRuntimeReady(); err != nil {
			GoLog("[Extension] Failed to initialize upgraded extension %s: %v\n", newManifest.Name, err)
		}
	} else if err := validateExtensionLoad(ext); err != nil {
		ext.Error = err.Error()
		ext.Enabled = false
		GoLog("[Extension] Failed to validate upgraded extension %s: %v\n", newManifest.Name, err)
	}

	m.mu.Lock()
	m.extensions[newManifest.Name] = ext
	m.mu.Unlock()

	GoLog("[Extension] Upgraded extension: %s to v%s\n", newManifest.DisplayName, newManifest.Version)

	return ext, nil
}

type ExtensionUpgradeInfo struct {
	ExtensionID    string `json:"extension_id"`
	CurrentVersion string `json:"current_version"`
	NewVersion     string `json:"new_version"`
	CanUpgrade     bool   `json:"can_upgrade"`
	IsInstalled    bool   `json:"is_installed"`
}

func (m *extensionManager) checkExtensionUpgradeInternal(filePath string) (*ExtensionUpgradeInfo, error) {
	if !strings.HasSuffix(strings.ToLower(filePath), ".spotiflac-ext") {
		return nil, fmt.Errorf("Invalid file format. Please select a .spotiflac-ext file")
	}

	zipReader, err := zip.OpenReader(filePath)

	if err != nil {
		return nil, fmt.Errorf("Cannot open extension file")
	}
	defer zipReader.Close()

	var manifestData []byte
	for _, file := range zipReader.File {
		name := filepath.Base(file.Name)
		if name == "manifest.json" {
			rc, err := file.Open()
			if err != nil {
				return nil, fmt.Errorf("failed to open manifest.json")
			}
			manifestData, err = io.ReadAll(rc)
			rc.Close()
			if err != nil {
				return nil, fmt.Errorf("failed to read manifest.json")
			}
			break
		}
	}

	if manifestData == nil {
		return nil, fmt.Errorf("manifest.json not found")
	}

	newManifest, err := ParseManifest(manifestData)
	if err != nil {
		return nil, fmt.Errorf("Invalid manifest: %w", err)
	}

	m.mu.RLock()
	existing, exists := m.extensions[newManifest.Name]
	m.mu.RUnlock()

	info := &ExtensionUpgradeInfo{
		ExtensionID: newManifest.Name,
		NewVersion:  newManifest.Version,
		IsInstalled: exists,
	}

	if !exists {
		info.CurrentVersion = ""
		info.CanUpgrade = false
	} else {
		info.CurrentVersion = existing.Manifest.Version
		info.CanUpgrade = compareVersions(newManifest.Version, existing.Manifest.Version) > 0
	}

	return info, nil
}

func (m *extensionManager) CheckExtensionUpgradeJSON(filePath string) (string, error) {
	info, err := m.checkExtensionUpgradeInternal(filePath)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(info)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func (m *extensionManager) GetInstalledExtensionsJSON() (string, error) {
	extensions := m.GetAllExtensions()

	type ExtensionInfo struct {
		ID                     string                 `json:"id"`
		Name                   string                 `json:"name"`
		DisplayName            string                 `json:"display_name"`
		Version                string                 `json:"version"`
		Description            string                 `json:"description"`
		Homepage               string                 `json:"homepage,omitempty"`
		IconPath               string                 `json:"icon_path,omitempty"`
		Types                  []ExtensionType        `json:"types"`
		Enabled                bool                   `json:"enabled"`
		Status                 string                 `json:"status"`
		Error                  string                 `json:"error_message,omitempty"`
		Settings               []ExtensionSetting     `json:"settings,omitempty"`
		QualityOptions         []QualityOption        `json:"quality_options,omitempty"`
		Permissions            []string               `json:"permissions"`
		HasMetadataProvider    bool                   `json:"has_metadata_provider"`
		HasDownloadProvider    bool                   `json:"has_download_provider"`
		HasLyricsProvider      bool                   `json:"has_lyrics_provider"`
		SkipMetadataEnrichment bool                   `json:"skip_metadata_enrichment"`
		SkipLyrics             bool                   `json:"skip_lyrics"`
		SearchBehavior         *SearchBehaviorConfig  `json:"search_behavior,omitempty"`
		TrackMatching          *TrackMatchingConfig   `json:"track_matching,omitempty"`
		PostProcessing         *PostProcessingConfig  `json:"post_processing,omitempty"`
		Capabilities           map[string]interface{} `json:"capabilities,omitempty"`
	}

	infos := make([]ExtensionInfo, len(extensions))
	for i, ext := range extensions {
		permissions := []string{}
		for _, domain := range ext.Manifest.Permissions.Network {
			permissions = append(permissions, "network:"+domain)
		}
		if ext.Manifest.Permissions.Storage {
			permissions = append(permissions, "storage:enabled")
		}

		status := "loaded"
		if ext.Error != "" {
			status = "error"
		} else if !ext.Enabled {
			status = "disabled"
		}

		iconPath := ""
		if ext.Manifest.Icon != "" && ext.SourceDir != "" {
			possibleIcon := filepath.Join(ext.SourceDir, ext.Manifest.Icon)
			if _, err := os.Stat(possibleIcon); err == nil {
				iconPath = possibleIcon
			}
		}
		if iconPath == "" && ext.SourceDir != "" {
			possibleIcon := filepath.Join(ext.SourceDir, "icon.png")
			if _, err := os.Stat(possibleIcon); err == nil {
				iconPath = possibleIcon
			}
		}

		infos[i] = ExtensionInfo{
			ID:                     ext.ID,
			Name:                   ext.Manifest.Name,
			DisplayName:            ext.Manifest.DisplayName,
			Version:                ext.Manifest.Version,
			Description:            ext.Manifest.Description,
			Homepage:               ext.Manifest.Homepage,
			IconPath:               iconPath,
			Types:                  ext.Manifest.Types,
			Enabled:                ext.Enabled,
			Status:                 status,
			Error:                  ext.Error,
			Settings:               ext.Manifest.Settings,
			QualityOptions:         ext.Manifest.QualityOptions,
			Permissions:            permissions,
			HasMetadataProvider:    ext.Manifest.IsMetadataProvider(),
			HasDownloadProvider:    ext.Manifest.IsDownloadProvider(),
			HasLyricsProvider:      ext.Manifest.IsLyricsProvider(),
			SkipMetadataEnrichment: ext.Manifest.SkipMetadataEnrichment,
			SkipLyrics:             ext.Manifest.SkipLyrics,
			SearchBehavior:         ext.Manifest.SearchBehavior,
			TrackMatching:          ext.Manifest.TrackMatching,
			PostProcessing:         ext.Manifest.PostProcessing,
			Capabilities:           ext.Manifest.Capabilities,
		}
	}

	jsonBytes, err := json.Marshal(infos)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func (m *extensionManager) InitializeExtension(extensionID string, settings map[string]interface{}) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	ext, exists := m.extensions[extensionID]
	if !exists {
		return fmt.Errorf("Extension not found")
	}

	ext.VMMu.Lock()
	defer ext.VMMu.Unlock()

	if err := ensureRuntimeReadyLocked(ext, false); err != nil {
		return err
	}
	return initializeExtensionWithSettingsLocked(ext, settings)
}

func (m *extensionManager) CleanupExtension(extensionID string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	ext, exists := m.extensions[extensionID]
	if !exists {
		return fmt.Errorf("Extension not found")
	}

	if ext.VM == nil {
		return nil
	}
	ext.VMMu.Lock()
	defer ext.VMMu.Unlock()
	if err := runCleanupLocked(ext); err != nil {
		GoLog("[Extension] Cleanup error for %s: %v\n", extensionID, err)
		return err
	}
	GoLog("[Extension] Cleaned up %s\n", extensionID)
	return nil
}

func (m *extensionManager) UnloadAllExtensions() {
	m.mu.Lock()
	extensionIDs := make([]string, 0, len(m.extensions))
	for id := range m.extensions {
		extensionIDs = append(extensionIDs, id)
	}
	m.mu.Unlock()

	for _, id := range extensionIDs {
		m.UnloadExtension(id)
	}

	GoLog("[Extension] All extensions unloaded\n")
}

func (m *extensionManager) InvokeAction(extensionID string, actionName string) (map[string]interface{}, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	ext, exists := m.extensions[extensionID]
	if !exists {
		return nil, fmt.Errorf("extension not found: %s", extensionID)
	}

	if !ext.Enabled {
		return nil, fmt.Errorf("extension is disabled")
	}
	vm, err := ext.lockReadyVM()
	if err != nil {
		return nil, err
	}
	defer ext.VMMu.Unlock()

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.%s === 'function') {
				try {
					var result = extension.%s();
					if (result && typeof result.then === 'function') {
						// Handle promise - return pending status
						return { success: true, pending: true, message: 'Action started' };
					}
					return { success: true, result: result };
				} catch (e) {
					return { success: false, error: e.toString() };
				}
			}
			return { success: false, error: 'Action function not found: %s' };
		})()
	`, actionName, actionName, actionName)

	result, err := RunWithTimeoutAndRecover(vm, script, DefaultJSTimeout)
	if err != nil {
		GoLog("[Extension] InvokeAction error for %s.%s: %v\n", extensionID, actionName, err)
		return nil, fmt.Errorf("action failed: %v", err)
	}

	if result == nil || goja.IsUndefined(result) {
		return map[string]interface{}{"success": true}, nil
	}

	exported := result.Export()
	if resultMap, ok := exported.(map[string]interface{}); ok {
		GoLog("[Extension] InvokeAction %s.%s result: %v\n", extensionID, actionName, resultMap)
		return resultMap, nil
	}

	return map[string]interface{}{"success": true, "result": exported}, nil
}
