package gobackend

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// ISRCIndex holds a cached map of ISRC -> file path for fast duplicate checking
type ISRCIndex struct {
	index     map[string]string // ISRC (uppercase) -> file path
	outputDir string
	buildTime time.Time
	mu        sync.RWMutex
}

var (
	isrcIndexCache   = make(map[string]*ISRCIndex)
	isrcIndexCacheMu sync.RWMutex
	isrcIndexTTL     = 5 * time.Minute
)

// GetISRCIndex returns or builds an ISRC index for the given directory
func GetISRCIndex(outputDir string) *ISRCIndex {
	isrcIndexCacheMu.RLock()
	idx, exists := isrcIndexCache[outputDir]
	isrcIndexCacheMu.RUnlock()

	if exists && time.Since(idx.buildTime) < isrcIndexTTL {
		return idx
	}

	return buildISRCIndex(outputDir)
}

// buildISRCIndex scans a directory and builds a map of ISRC -> file path
func buildISRCIndex(outputDir string) *ISRCIndex {
	idx := &ISRCIndex{
		index:     make(map[string]string),
		outputDir: outputDir,
		buildTime: time.Now(),
	}

	if outputDir == "" {
		return idx
	}

	startTime := time.Now()
	fileCount := 0

	filepath.Walk(outputDir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return nil
		}

		ext := strings.ToLower(filepath.Ext(path))
		if ext != ".flac" {
			return nil
		}

		metadata, err := ReadMetadata(path)
		if err != nil || metadata.ISRC == "" {
			return nil
		}

		idx.index[strings.ToUpper(metadata.ISRC)] = path
		fileCount++
		return nil
	})

	fmt.Printf("[ISRCIndex] Built index for %s: %d files in %v\n", 
		outputDir, fileCount, time.Since(startTime).Round(time.Millisecond))

	isrcIndexCacheMu.Lock()
	isrcIndexCache[outputDir] = idx
	isrcIndexCacheMu.Unlock()

	return idx
}

func (idx *ISRCIndex) lookup(isrc string) (string, bool) {
	if isrc == "" {
		return "", false
	}

	idx.mu.RLock()
	defer idx.mu.RUnlock()

	path, exists := idx.index[strings.ToUpper(isrc)]
	return path, exists
}

// remove deletes an ISRC entry from the index (internal use)
func (idx *ISRCIndex) remove(isrc string) {
	if isrc == "" {
		return
	}

	idx.mu.Lock()
	defer idx.mu.Unlock()

	delete(idx.index, strings.ToUpper(isrc))
}

// Lookup checks if an ISRC exists in the index (gomobile compatible)
// Returns filepath if found, empty string if not found
func (idx *ISRCIndex) Lookup(isrc string) (string, error) {
	path, _ := idx.lookup(isrc)
	return path, nil
}

// Add adds a new ISRC to the index (call after successful download)
func (idx *ISRCIndex) Add(isrc, filePath string) {
	if isrc == "" || filePath == "" {
		return
	}

	idx.mu.Lock()
	defer idx.mu.Unlock()

	idx.index[strings.ToUpper(isrc)] = filePath
}

// InvalidateCache clears the ISRC index cache for a directory
func InvalidateISRCCache(outputDir string) {
	isrcIndexCacheMu.Lock()
	delete(isrcIndexCache, outputDir)
	isrcIndexCacheMu.Unlock()
}

// checkISRCExistsInternal checks if a file with the given ISRC exists (internal use)
// Uses ISRC index for fast lookup
func checkISRCExistsInternal(outputDir, isrc string) (string, bool) {
	if isrc == "" || outputDir == "" {
		return "", false
	}

	// Use index for fast lookup
	idx := GetISRCIndex(outputDir)
	filePath, exists := idx.lookup(isrc)
	if !exists {
		return "", false
	}

	if !CheckFileExists(filePath) {
		// Stale index entry; remove it and return not found.
		idx.remove(isrc)
		return "", false
	}

	return filePath, true
}

// CheckISRCExists is the exported version for gomobile (returns string, error)
// Returns the filepath if exists, empty string if not
func CheckISRCExists(outputDir, isrc string) (string, error) {
	filepath, _ := checkISRCExistsInternal(outputDir, isrc)
	return filepath, nil
}

// CheckFileExists checks if a file with the given name exists
func CheckFileExists(filePath string) bool {
	info, err := os.Stat(filePath)
	if err != nil {
		return false
	}
	return !info.IsDir() && info.Size() > 0
}

// FileExistenceResult represents the result of checking if a file exists
type FileExistenceResult struct {
	ISRC       string `json:"isrc"`
	Exists     bool   `json:"exists"`
	FilePath   string `json:"file_path,omitempty"`
	TrackName  string `json:"track_name,omitempty"`
	ArtistName string `json:"artist_name,omitempty"`
}

// CheckFilesExistParallel checks if multiple files exist in parallel
// It builds an ISRC index from the output directory once, then checks all tracks against it
// Same implementation as PC version for consistency
func CheckFilesExistParallel(outputDir string, tracksJSON string) (string, error) {
	var tracks []struct {
		ISRC       string `json:"isrc"`
		TrackName  string `json:"track_name"`
		ArtistName string `json:"artist_name"`
	}
	if err := json.Unmarshal([]byte(tracksJSON), &tracks); err != nil {
		return "", fmt.Errorf("failed to parse tracks JSON: %w", err)
	}

	results := make([]FileExistenceResult, len(tracks))

	isrcIdx := GetISRCIndex(outputDir)

	var wg sync.WaitGroup
	for i, track := range tracks {
		wg.Add(1)
		go func(resultIdx int, t struct {
			ISRC       string `json:"isrc"`
			TrackName  string `json:"track_name"`
			ArtistName string `json:"artist_name"`
		}) {
			defer wg.Done()

			result := FileExistenceResult{
				ISRC:       t.ISRC,
				TrackName:  t.TrackName,
				ArtistName: t.ArtistName,
				Exists:     false,
			}

			if t.ISRC != "" {
				if filePath, exists := isrcIdx.lookup(t.ISRC); exists {
					result.Exists = true
					result.FilePath = filePath
				}
			}

			results[resultIdx] = result
		}(i, track)
	}

	wg.Wait()

	resultJSON, err := json.Marshal(results)
	if err != nil {
		return "", fmt.Errorf("failed to marshal results: %w", err)
	}

	return string(resultJSON), nil
}

// PreBuildISRCIndex pre-builds the ISRC index for a directory
// Call this when app starts or when entering album/playlist screen
func PreBuildISRCIndex(outputDir string) error {
	if outputDir == "" {
		return fmt.Errorf("output directory is required")
	}

	buildISRCIndex(outputDir)
	return nil
}

// AddToISRCIndex adds a new file to the ISRC index after successful download
// This avoids rebuilding the entire index
func AddToISRCIndex(outputDir, isrc, filePath string) {
	if outputDir == "" || isrc == "" || filePath == "" {
		return
	}

	isrcIndexCacheMu.RLock()
	idx, exists := isrcIndexCache[outputDir]
	isrcIndexCacheMu.RUnlock()

	if exists {
		idx.Add(isrc, filePath)
	}
}
