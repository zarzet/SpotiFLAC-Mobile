package gobackend

import (
	"encoding/json"
	"sync"
)

// DownloadProgress represents current download progress (legacy single download)
type DownloadProgress struct {
	CurrentFile   string  `json:"current_file"`
	Progress      float64 `json:"progress"`
	Speed         float64 `json:"speed_mbps"`
	BytesTotal    int64   `json:"bytes_total"`
	BytesReceived int64   `json:"bytes_received"`
	IsDownloading bool    `json:"is_downloading"`
}

// ItemProgress represents progress for a single download item
type ItemProgress struct {
	ItemID        string  `json:"item_id"`
	BytesTotal    int64   `json:"bytes_total"`
	BytesReceived int64   `json:"bytes_received"`
	Progress      float64 `json:"progress"` // 0.0 to 1.0
	IsDownloading bool    `json:"is_downloading"`
}

// MultiProgress holds progress for multiple concurrent downloads
type MultiProgress struct {
	Items map[string]*ItemProgress `json:"items"`
}

var (
	currentProgress DownloadProgress
	progressMu      sync.RWMutex
	downloadDir     string
	downloadDirMu   sync.RWMutex
	
	// Multi-download progress tracking
	multiProgress = MultiProgress{Items: make(map[string]*ItemProgress)}
	multiMu       sync.RWMutex
)

// getProgress returns current download progress (legacy)
func getProgress() DownloadProgress {
	progressMu.RLock()
	defer progressMu.RUnlock()
	return currentProgress
}

// GetMultiProgress returns progress for all active downloads as JSON
func GetMultiProgress() string {
	multiMu.RLock()
	defer multiMu.RUnlock()
	
	jsonBytes, err := json.Marshal(multiProgress)
	if err != nil {
		return "{\"items\":{}}"
	}
	return string(jsonBytes)
}

// GetItemProgress returns progress for a specific item as JSON
func GetItemProgress(itemID string) string {
	multiMu.RLock()
	defer multiMu.RUnlock()
	
	if item, ok := multiProgress.Items[itemID]; ok {
		jsonBytes, _ := json.Marshal(item)
		return string(jsonBytes)
	}
	return "{}"
}

// StartItemProgress initializes progress tracking for an item
func StartItemProgress(itemID string) {
	multiMu.Lock()
	defer multiMu.Unlock()
	
	multiProgress.Items[itemID] = &ItemProgress{
		ItemID:        itemID,
		BytesTotal:    0,
		BytesReceived: 0,
		Progress:      0,
		IsDownloading: true,
	}
}

// SetItemBytesTotal sets total bytes for an item
func SetItemBytesTotal(itemID string, total int64) {
	multiMu.Lock()
	defer multiMu.Unlock()
	
	if item, ok := multiProgress.Items[itemID]; ok {
		item.BytesTotal = total
	}
}

// SetItemBytesReceived sets bytes received for an item
func SetItemBytesReceived(itemID string, received int64) {
	multiMu.Lock()
	defer multiMu.Unlock()
	
	if item, ok := multiProgress.Items[itemID]; ok {
		item.BytesReceived = received
		if item.BytesTotal > 0 {
			item.Progress = float64(received) / float64(item.BytesTotal)
		}
	}
}

// CompleteItemProgress marks an item as complete
func CompleteItemProgress(itemID string) {
	multiMu.Lock()
	defer multiMu.Unlock()
	
	if item, ok := multiProgress.Items[itemID]; ok {
		item.Progress = 1.0
		item.IsDownloading = false
	}
}

// RemoveItemProgress removes progress tracking for an item
func RemoveItemProgress(itemID string) {
	multiMu.Lock()
	defer multiMu.Unlock()
	
	delete(multiProgress.Items, itemID)
}

// ClearAllItemProgress clears all item progress
func ClearAllItemProgress() {
	multiMu.Lock()
	defer multiMu.Unlock()
	
	multiProgress.Items = make(map[string]*ItemProgress)
}

// Legacy functions for backward compatibility

// SetDownloadProgress sets the current download progress (MB downloaded)
func SetDownloadProgress(mbDownloaded float64) {
	progressMu.Lock()
	defer progressMu.Unlock()
	currentProgress.Progress = mbDownloaded
	currentProgress.IsDownloading = true
}

// SetDownloadSpeed sets the current download speed
func SetDownloadSpeed(speedMBps float64) {
	progressMu.Lock()
	defer progressMu.Unlock()
	currentProgress.Speed = speedMBps
}

// SetCurrentFile sets the current file being downloaded and resets progress
func SetCurrentFile(filename string) {
	progressMu.Lock()
	defer progressMu.Unlock()
	currentProgress.BytesReceived = 0
	currentProgress.BytesTotal = 0
	currentProgress.Progress = 0
	currentProgress.CurrentFile = filename
	currentProgress.IsDownloading = true
}

// ResetProgress resets the download progress
func ResetProgress() {
	progressMu.Lock()
	defer progressMu.Unlock()
	currentProgress = DownloadProgress{}
}

// setDownloadDir sets the default download directory
func setDownloadDir(path string) error {
	downloadDirMu.Lock()
	defer downloadDirMu.Unlock()
	downloadDir = path
	return nil
}

// getDownloadDir returns the default download directory
func getDownloadDir() string {
	downloadDirMu.RLock()
	defer downloadDirMu.RUnlock()
	return downloadDir
}

// SetDownloading sets the download status
func SetDownloading(status bool) {
	progressMu.Lock()
	defer progressMu.Unlock()
	currentProgress.IsDownloading = status
}

// SetBytesTotal sets total bytes to download
func SetBytesTotal(total int64) {
	progressMu.Lock()
	defer progressMu.Unlock()
	currentProgress.BytesTotal = total
}

// SetBytesReceived sets bytes received so far
func SetBytesReceived(received int64) {
	progressMu.Lock()
	defer progressMu.Unlock()
	currentProgress.BytesReceived = received
	if currentProgress.BytesTotal > 0 {
		currentProgress.Progress = float64(received) / float64(currentProgress.BytesTotal) * 100
	}
}

// ProgressWriter wraps io.Writer to track download progress (legacy single)
type ProgressWriter struct {
	writer  interface{ Write([]byte) (int, error) }
	total   int64
	current int64
}

// NewProgressWriter creates a new progress writer wrapping an io.Writer
func NewProgressWriter(w interface{ Write([]byte) (int, error) }) *ProgressWriter {
	SetBytesReceived(0)
	return &ProgressWriter{
		writer:  w,
		current: 0,
		total:   0,
	}
}

// Write implements io.Writer
func (pw *ProgressWriter) Write(p []byte) (int, error) {
	n, err := pw.writer.Write(p)
	if err != nil {
		return n, err
	}
	pw.current += int64(n)
	pw.total += int64(n)
	SetBytesReceived(pw.current)
	return n, nil
}

// GetTotal returns total bytes written
func (pw *ProgressWriter) GetTotal() int64 {
	return pw.total
}

// ItemProgressWriter wraps io.Writer to track download progress for a specific item
type ItemProgressWriter struct {
	writer  interface{ Write([]byte) (int, error) }
	itemID  string
	current int64
}

// NewItemProgressWriter creates a new progress writer for a specific item
func NewItemProgressWriter(w interface{ Write([]byte) (int, error) }, itemID string) *ItemProgressWriter {
	return &ItemProgressWriter{
		writer:  w,
		itemID:  itemID,
		current: 0,
	}
}

// Write implements io.Writer
func (pw *ItemProgressWriter) Write(p []byte) (int, error) {
	n, err := pw.writer.Write(p)
	if err != nil {
		return n, err
	}
	pw.current += int64(n)
	SetItemBytesReceived(pw.itemID, pw.current)
	// Also update legacy progress for backward compatibility
	SetBytesReceived(pw.current)
	return n, nil
}
