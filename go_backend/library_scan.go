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

// LibraryScanResult represents metadata from a scanned audio file
type LibraryScanResult struct {
	ID          string `json:"id"`
	TrackName   string `json:"trackName"`
	ArtistName  string `json:"artistName"`
	AlbumName   string `json:"albumName"`
	AlbumArtist string `json:"albumArtist,omitempty"`
	FilePath    string `json:"filePath"`
	CoverPath   string `json:"coverPath,omitempty"`
	ScannedAt   string `json:"scannedAt"`
	FileModTime int64  `json:"fileModTime,omitempty"` // Unix timestamp in milliseconds
	ISRC        string `json:"isrc,omitempty"`
	TrackNumber int    `json:"trackNumber,omitempty"`
	DiscNumber  int    `json:"discNumber,omitempty"`
	Duration    int    `json:"duration,omitempty"`
	ReleaseDate string `json:"releaseDate,omitempty"`
	BitDepth    int    `json:"bitDepth,omitempty"`
	SampleRate  int    `json:"sampleRate,omitempty"`
	Genre       string `json:"genre,omitempty"`
	Format      string `json:"format,omitempty"`
}

type LibraryScanProgress struct {
	TotalFiles   int     `json:"total_files"`
	ScannedFiles int     `json:"scanned_files"`
	CurrentFile  string  `json:"current_file"`
	ErrorCount   int     `json:"error_count"`
	ProgressPct  float64 `json:"progress_pct"`
	IsComplete   bool    `json:"is_complete"`
}

// IncrementalScanResult contains results of an incremental library scan
type IncrementalScanResult struct {
	Scanned      []LibraryScanResult `json:"scanned"`      // New or updated files
	DeletedPaths []string            `json:"deletedPaths"` // Files that no longer exist
	SkippedCount int                 `json:"skippedCount"` // Files that were unchanged
	TotalFiles   int                 `json:"totalFiles"`   // Total files in folder
}

var (
	libraryScanProgress   LibraryScanProgress
	libraryScanProgressMu sync.RWMutex
	libraryScanCancel     chan struct{}
	libraryScanCancelMu   sync.Mutex
	libraryCoverCacheDir  string
	libraryCoverCacheMu   sync.RWMutex
)

var supportedAudioFormats = map[string]bool{
	".flac": true,
	".m4a":  true,
	".mp3":  true,
	".opus": true,
	".ogg":  true,
}

func SetLibraryCoverCacheDir(cacheDir string) {
	libraryCoverCacheMu.Lock()
	libraryCoverCacheDir = cacheDir
	libraryCoverCacheMu.Unlock()
}

func ScanLibraryFolder(folderPath string) (string, error) {
	if folderPath == "" {
		return "[]", fmt.Errorf("folder path is empty")
	}

	info, err := os.Stat(folderPath)
	if err != nil {
		return "[]", fmt.Errorf("folder not found: %w", err)
	}
	if !info.IsDir() {
		return "[]", fmt.Errorf("path is not a folder: %s", folderPath)
	}

	libraryScanProgressMu.Lock()
	libraryScanProgress = LibraryScanProgress{}
	libraryScanProgressMu.Unlock()

	libraryScanCancelMu.Lock()
	if libraryScanCancel != nil {
		close(libraryScanCancel)
	}
	libraryScanCancel = make(chan struct{})
	cancelCh := libraryScanCancel
	libraryScanCancelMu.Unlock()

	var audioFiles []string
	err = filepath.Walk(folderPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		select {
		case <-cancelCh:
			return fmt.Errorf("scan cancelled")
		default:
		}

		if !info.IsDir() {
			ext := strings.ToLower(filepath.Ext(path))
			if supportedAudioFormats[ext] {
				audioFiles = append(audioFiles, path)
			}
		}
		return nil
	})

	if err != nil {
		return "[]", err
	}

	totalFiles := len(audioFiles)
	libraryScanProgressMu.Lock()
	libraryScanProgress.TotalFiles = totalFiles
	libraryScanProgressMu.Unlock()

	if totalFiles == 0 {
		libraryScanProgressMu.Lock()
		libraryScanProgress.IsComplete = true
		libraryScanProgressMu.Unlock()
		return "[]", nil
	}

	GoLog("[LibraryScan] Found %d audio files to scan\n", totalFiles)

	results := make([]LibraryScanResult, 0, totalFiles)
	scanTime := time.Now().UTC().Format(time.RFC3339)
	errorCount := 0

	for i, filePath := range audioFiles {
		select {
		case <-cancelCh:
			return "[]", fmt.Errorf("scan cancelled")
		default:
		}

		libraryScanProgressMu.Lock()
		libraryScanProgress.ScannedFiles = i + 1
		libraryScanProgress.CurrentFile = filepath.Base(filePath)
		libraryScanProgress.ProgressPct = float64(i+1) / float64(totalFiles) * 100
		libraryScanProgressMu.Unlock()

		result, err := scanAudioFile(filePath, scanTime)
		if err != nil {
			errorCount++
			GoLog("[LibraryScan] Error scanning %s: %v\n", filePath, err)
			continue
		}

		results = append(results, *result)
	}

	libraryScanProgressMu.Lock()
	libraryScanProgress.ErrorCount = errorCount
	libraryScanProgress.IsComplete = true
	libraryScanProgressMu.Unlock()

	GoLog("[LibraryScan] Scan complete: %d tracks found, %d errors\n", len(results), errorCount)

	jsonBytes, err := json.Marshal(results)
	if err != nil {
		return "[]", fmt.Errorf("failed to marshal results: %w", err)
	}

	return string(jsonBytes), nil
}

func scanAudioFile(filePath, scanTime string) (*LibraryScanResult, error) {
	ext := strings.ToLower(filepath.Ext(filePath))

	result := &LibraryScanResult{
		ID:        generateLibraryID(filePath),
		FilePath:  filePath,
		ScannedAt: scanTime,
		Format:    strings.TrimPrefix(ext, "."),
	}

	// Get file modification time
	if info, err := os.Stat(filePath); err == nil {
		result.FileModTime = info.ModTime().UnixMilli()
	}

	libraryCoverCacheMu.RLock()
	coverCacheDir := libraryCoverCacheDir
	libraryCoverCacheMu.RUnlock()
	if coverCacheDir != "" && ext != ".m4a" {
		coverPath, err := SaveCoverToCache(filePath, coverCacheDir)
		if err == nil && coverPath != "" {
			result.CoverPath = coverPath
		}
	}

	switch ext {
	case ".flac":
		return scanFLACFile(filePath, result)
	case ".m4a":
		return scanM4AFile(filePath, result)
	case ".mp3":
		return scanMP3File(filePath, result)
	case ".opus", ".ogg":
		return scanOggFile(filePath, result)
	default:
		return scanFromFilename(filePath, result)
	}
}

func scanFLACFile(filePath string, result *LibraryScanResult) (*LibraryScanResult, error) {
	metadata, err := ReadMetadata(filePath)
	if err != nil {
		return scanFromFilename(filePath, result)
	}

	result.TrackName = metadata.Title
	result.ArtistName = metadata.Artist
	result.AlbumName = metadata.Album
	result.AlbumArtist = metadata.AlbumArtist
	result.ISRC = metadata.ISRC
	result.TrackNumber = metadata.TrackNumber
	result.DiscNumber = metadata.DiscNumber
	result.ReleaseDate = metadata.Date
	result.Genre = metadata.Genre

	quality, err := GetAudioQuality(filePath)
	if err == nil {
		result.BitDepth = quality.BitDepth
		result.SampleRate = quality.SampleRate
		if quality.SampleRate > 0 && quality.TotalSamples > 0 {
			result.Duration = int(quality.TotalSamples / int64(quality.SampleRate))
		}
	}

	if result.TrackName == "" {
		result.TrackName = strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))
	}
	if result.ArtistName == "" {
		result.ArtistName = "Unknown Artist"
	}
	if result.AlbumName == "" {
		result.AlbumName = "Unknown Album"
	}

	return result, nil
}

func scanM4AFile(filePath string, result *LibraryScanResult) (*LibraryScanResult, error) {
	quality, err := GetM4AQuality(filePath)
	if err == nil {
		result.BitDepth = quality.BitDepth
		result.SampleRate = quality.SampleRate
	}

	return scanFromFilename(filePath, result)
}

func scanMP3File(filePath string, result *LibraryScanResult) (*LibraryScanResult, error) {
	metadata, err := ReadID3Tags(filePath)
	if err != nil {
		GoLog("[LibraryScan] ID3 read error for %s: %v\n", filePath, err)
		return scanFromFilename(filePath, result)
	}

	result.TrackName = metadata.Title
	result.ArtistName = metadata.Artist
	result.AlbumName = metadata.Album
	result.AlbumArtist = metadata.AlbumArtist
	result.TrackNumber = metadata.TrackNumber
	result.DiscNumber = metadata.DiscNumber
	result.Genre = metadata.Genre
	if metadata.Date != "" {
		result.ReleaseDate = metadata.Date
	} else {
		result.ReleaseDate = metadata.Year
	}
	result.ISRC = metadata.ISRC

	quality, err := GetMP3Quality(filePath)
	if err == nil {
		result.SampleRate = quality.SampleRate
		result.BitDepth = quality.BitDepth
		result.Duration = quality.Duration
	}

	if result.TrackName == "" {
		result.TrackName = strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))
	}
	if result.ArtistName == "" {
		result.ArtistName = "Unknown Artist"
	}
	if result.AlbumName == "" {
		result.AlbumName = "Unknown Album"
	}

	return result, nil
}

func scanOggFile(filePath string, result *LibraryScanResult) (*LibraryScanResult, error) {
	metadata, err := ReadOggVorbisComments(filePath)
	if err != nil {
		GoLog("[LibraryScan] Ogg/Opus read error for %s: %v\n", filePath, err)
		return scanFromFilename(filePath, result)
	}

	result.TrackName = metadata.Title
	result.ArtistName = metadata.Artist
	result.AlbumName = metadata.Album
	result.AlbumArtist = metadata.AlbumArtist
	result.ISRC = metadata.ISRC
	result.TrackNumber = metadata.TrackNumber
	result.DiscNumber = metadata.DiscNumber
	result.Genre = metadata.Genre
	result.ReleaseDate = metadata.Date

	quality, err := GetOggQuality(filePath)
	if err == nil {
		result.SampleRate = quality.SampleRate
		result.BitDepth = quality.BitDepth
		result.Duration = quality.Duration
	}

	if result.TrackName == "" {
		result.TrackName = strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))
	}
	if result.ArtistName == "" {
		result.ArtistName = "Unknown Artist"
	}
	if result.AlbumName == "" {
		result.AlbumName = "Unknown Album"
	}

	return result, nil
}

func scanFromFilename(filePath string, result *LibraryScanResult) (*LibraryScanResult, error) {
	filename := strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))

	parts := strings.SplitN(filename, " - ", 2)
	if len(parts) == 2 {
		if len(parts[0]) <= 3 && isNumeric(parts[0]) {
			result.TrackName = parts[1]
			result.ArtistName = "Unknown Artist"
		} else {
			result.ArtistName = parts[0]
			result.TrackName = parts[1]
		}
	} else {
		if len(filename) > 3 && isNumeric(filename[:2]) {
			title := strings.TrimLeft(filename[2:], " .-")
			result.TrackName = title
		} else {
			result.TrackName = filename
		}
		result.ArtistName = "Unknown Artist"
	}

	dir := filepath.Dir(filePath)
	result.AlbumName = filepath.Base(dir)
	if result.AlbumName == "." || result.AlbumName == "" {
		result.AlbumName = "Unknown Album"
	}

	return result, nil
}

func isNumeric(s string) bool {
	for _, c := range s {
		if c < '0' || c > '9' {
			return false
		}
	}
	return len(s) > 0
}

func generateLibraryID(filePath string) string {
	return fmt.Sprintf("lib_%x", hashString(filePath))
}

func hashString(s string) uint32 {
	var hash uint32 = 5381
	for _, c := range s {
		hash = ((hash << 5) + hash) + uint32(c)
	}
	return hash
}

func GetLibraryScanProgress() string {
	libraryScanProgressMu.RLock()
	defer libraryScanProgressMu.RUnlock()

	jsonBytes, _ := json.Marshal(libraryScanProgress)
	return string(jsonBytes)
}

func CancelLibraryScan() {
	libraryScanCancelMu.Lock()
	defer libraryScanCancelMu.Unlock()

	if libraryScanCancel != nil {
		close(libraryScanCancel)
		libraryScanCancel = nil
	}
}

func ReadAudioMetadata(filePath string) (string, error) {
	scanTime := time.Now().UTC().Format(time.RFC3339)
	result, err := scanAudioFile(filePath, scanTime)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", fmt.Errorf("failed to marshal result: %w", err)
	}

	return string(jsonBytes), nil
}

// ScanLibraryFolderIncremental performs an incremental scan of the library folder
// existingFilesJSON is a JSON object mapping filePath -> modTime (unix millis)
// Only files that are new or have changed modification time will be scanned
func ScanLibraryFolderIncremental(folderPath, existingFilesJSON string) (string, error) {
	if folderPath == "" {
		return "{}", fmt.Errorf("folder path is empty")
	}

	info, err := os.Stat(folderPath)
	if err != nil {
		return "{}", fmt.Errorf("folder not found: %w", err)
	}
	if !info.IsDir() {
		return "{}", fmt.Errorf("path is not a folder: %s", folderPath)
	}

	// Parse existing files map
	existingFiles := make(map[string]int64)
	if existingFilesJSON != "" && existingFilesJSON != "{}" {
		if err := json.Unmarshal([]byte(existingFilesJSON), &existingFiles); err != nil {
			GoLog("[LibraryScan] Warning: failed to parse existing files JSON: %v\n", err)
		}
	}

	GoLog("[LibraryScan] Incremental scan starting, %d existing files in database\n", len(existingFiles))

	// Reset progress
	libraryScanProgressMu.Lock()
	libraryScanProgress = LibraryScanProgress{}
	libraryScanProgressMu.Unlock()

	// Setup cancellation
	libraryScanCancelMu.Lock()
	if libraryScanCancel != nil {
		close(libraryScanCancel)
	}
	libraryScanCancel = make(chan struct{})
	cancelCh := libraryScanCancel
	libraryScanCancelMu.Unlock()

	// Collect all audio files with their mod times
	type fileInfo struct {
		path    string
		modTime int64
	}
	var currentFiles []fileInfo
	currentPathSet := make(map[string]bool)

	err = filepath.Walk(folderPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		select {
		case <-cancelCh:
			return fmt.Errorf("scan cancelled")
		default:
		}

		if !info.IsDir() {
			ext := strings.ToLower(filepath.Ext(path))
			if supportedAudioFormats[ext] {
				currentFiles = append(currentFiles, fileInfo{
					path:    path,
					modTime: info.ModTime().UnixMilli(),
				})
				currentPathSet[path] = true
			}
		}
		return nil
	})

	if err != nil {
		return "{}", err
	}

	totalFiles := len(currentFiles)
	libraryScanProgressMu.Lock()
	libraryScanProgress.TotalFiles = totalFiles
	libraryScanProgressMu.Unlock()

	// Find files to scan (new or modified)
	var filesToScan []fileInfo
	skippedCount := 0

	for _, f := range currentFiles {
		existingModTime, exists := existingFiles[f.path]
		if !exists {
			// New file
			filesToScan = append(filesToScan, f)
		} else if f.modTime != existingModTime {
			// Modified file
			filesToScan = append(filesToScan, f)
		} else {
			// Unchanged file - skip
			skippedCount++
		}
	}

	// Find deleted files
	var deletedPaths []string
	for existingPath := range existingFiles {
		if !currentPathSet[existingPath] {
			deletedPaths = append(deletedPaths, existingPath)
		}
	}

	GoLog("[LibraryScan] Incremental: %d to scan, %d skipped, %d deleted\n",
		len(filesToScan), skippedCount, len(deletedPaths))

	if len(filesToScan) == 0 {
		libraryScanProgressMu.Lock()
		libraryScanProgress.ScannedFiles = totalFiles
		libraryScanProgress.IsComplete = true
		libraryScanProgress.ProgressPct = 100
		libraryScanProgressMu.Unlock()

		result := IncrementalScanResult{
			Scanned:      []LibraryScanResult{},
			DeletedPaths: deletedPaths,
			SkippedCount: skippedCount,
			TotalFiles:   totalFiles,
		}
		jsonBytes, _ := json.Marshal(result)
		return string(jsonBytes), nil
	}

	// Scan the files that need scanning
	results := make([]LibraryScanResult, 0, len(filesToScan))
	scanTime := time.Now().UTC().Format(time.RFC3339)
	errorCount := 0

	for i, f := range filesToScan {
		select {
		case <-cancelCh:
			return "{}", fmt.Errorf("scan cancelled")
		default:
		}

		libraryScanProgressMu.Lock()
		libraryScanProgress.ScannedFiles = skippedCount + i + 1
		libraryScanProgress.CurrentFile = filepath.Base(f.path)
		libraryScanProgress.ProgressPct = float64(skippedCount+i+1) / float64(totalFiles) * 100
		libraryScanProgressMu.Unlock()

		result, err := scanAudioFile(f.path, scanTime)
		if err != nil {
			errorCount++
			GoLog("[LibraryScan] Error scanning %s: %v\n", f.path, err)
			continue
		}

		results = append(results, *result)
	}

	libraryScanProgressMu.Lock()
	libraryScanProgress.ErrorCount = errorCount
	libraryScanProgress.IsComplete = true
	libraryScanProgress.ScannedFiles = totalFiles
	libraryScanProgress.ProgressPct = 100
	libraryScanProgressMu.Unlock()

	GoLog("[LibraryScan] Incremental scan complete: %d scanned, %d skipped, %d deleted, %d errors\n",
		len(results), skippedCount, len(deletedPaths), errorCount)

	scanResult := IncrementalScanResult{
		Scanned:      results,
		DeletedPaths: deletedPaths,
		SkippedCount: skippedCount,
		TotalFiles:   totalFiles,
	}

	jsonBytes, err := json.Marshal(scanResult)
	if err != nil {
		return "{}", fmt.Errorf("failed to marshal results: %w", err)
	}

	return string(jsonBytes), nil
}
