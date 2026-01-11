package gobackend

import (
	"encoding/json"
	"sync"
	"time"
)

// DownloadProgress represents current download progress
// Now unified - returns data from multi-progress system
type DownloadProgress struct {
	CurrentFile   string  `json:"current_file"`
	Progress      float64 `json:"progress"`
	Speed         float64 `json:"speed_mbps"`
	BytesTotal    int64   `json:"bytes_total"`
	BytesReceived int64   `json:"bytes_received"`
	IsDownloading bool    `json:"is_downloading"`
	Status        string  `json:"status"` // "downloading", "finalizing", "completed"
}

// ItemProgress represents progress for a single download item
type ItemProgress struct {
	ItemID        string  `json:"item_id"`
	BytesTotal    int64   `json:"bytes_total"`
	BytesReceived int64   `json:"bytes_received"`
	Progress      float64 `json:"progress"`   // 0.0 to 1.0
	SpeedMBps     float64 `json:"speed_mbps"` // Download speed in MB/s
	IsDownloading bool    `json:"is_downloading"`
	Status        string  `json:"status"` // "downloading", "finalizing", "completed"
}

// MultiProgress holds progress for multiple concurrent downloads
type MultiProgress struct {
	Items map[string]*ItemProgress `json:"items"`
}

var (
	downloadDir   string
	downloadDirMu sync.RWMutex

	// Multi-download progress tracking (unified system)
	multiProgress = MultiProgress{Items: make(map[string]*ItemProgress)}
	multiMu       sync.RWMutex
)

// getProgress returns current download progress from multi-progress system
// Returns first active item's progress for backward compatibility
func getProgress() DownloadProgress {
	multiMu.RLock()
	defer multiMu.RUnlock()

	// Find first active item
	for _, item := range multiProgress.Items {
		return DownloadProgress{
			CurrentFile:   item.ItemID,
			Progress:      item.Progress * 100, // Convert to percentage
			BytesTotal:    item.BytesTotal,
			BytesReceived: item.BytesReceived,
			IsDownloading: item.IsDownloading,
			Status:        item.Status,
		}
	}

	return DownloadProgress{}
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
		Status:        "downloading",
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

// SetItemBytesReceivedWithSpeed sets bytes received and speed for an item
func SetItemBytesReceivedWithSpeed(itemID string, received int64, speedMBps float64) {
	multiMu.Lock()
	defer multiMu.Unlock()

	if item, ok := multiProgress.Items[itemID]; ok {
		item.BytesReceived = received
		item.SpeedMBps = speedMBps
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
		item.Status = "completed"
	}
}

// SetItemProgress sets progress for an item directly
func SetItemProgress(itemID string, progress float64, bytesReceived, bytesTotal int64) {
	multiMu.Lock()
	defer multiMu.Unlock()

	if item, ok := multiProgress.Items[itemID]; ok {
		item.Progress = progress
		if bytesReceived > 0 {
			item.BytesReceived = bytesReceived
		}
		if bytesTotal > 0 {
			item.BytesTotal = bytesTotal
		}
	}
}

// SetItemFinalizing marks an item as finalizing (embedding metadata)
func SetItemFinalizing(itemID string) {
	multiMu.Lock()
	defer multiMu.Unlock()

	if item, ok := multiProgress.Items[itemID]; ok {
		item.Progress = 1.0
		item.Status = "finalizing"
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

// setDownloadDir sets the default download directory
func setDownloadDir(path string) error {
	downloadDirMu.Lock()
	defer downloadDirMu.Unlock()
	downloadDir = path
	return nil
}

// getDownloadDir returns the default download directory
// Kept for potential future use
// func getDownloadDir() string {
// 	downloadDirMu.RLock()
// 	defer downloadDirMu.RUnlock()
// 	return downloadDir
// }

// ItemProgressWriter wraps io.Writer to track download progress for a specific item
type ItemProgressWriter struct {
	writer       interface{ Write([]byte) (int, error) }
	itemID       string
	current      int64
	lastReported int64     // Track last reported bytes for threshold-based updates
	startTime    time.Time // Track start time for speed calculation
	lastTime     time.Time // Track last update time for speed calculation
	lastBytes    int64     // Track bytes at last speed calculation
}

const progressUpdateThreshold = 64 * 1024 // Update progress every 64KB

// NewItemProgressWriter creates a new progress writer for a specific item
func NewItemProgressWriter(w interface{ Write([]byte) (int, error) }, itemID string) *ItemProgressWriter {
	now := time.Now()
	return &ItemProgressWriter{
		writer:       w,
		itemID:       itemID,
		current:      0,
		lastReported: 0,
		startTime:    now,
		lastTime:     now,
		lastBytes:    0,
	}
}

// Write implements io.Writer with threshold-based progress updates and speed tracking
func (pw *ItemProgressWriter) Write(p []byte) (int, error) {
	n, err := pw.writer.Write(p)
	if err != nil {
		return n, err
	}
	pw.current += int64(n)

	// Update progress when we've received at least 64KB since last update
	// Also update on first write to show download has started
	if pw.lastReported == 0 || pw.current-pw.lastReported >= progressUpdateThreshold {
		// Calculate speed (MB/s) based on bytes received since last update
		now := time.Now()
		elapsed := now.Sub(pw.lastTime).Seconds()
		var speedMBps float64
		if elapsed > 0 {
			bytesInInterval := pw.current - pw.lastBytes
			speedMBps = float64(bytesInInterval) / (1024 * 1024) / elapsed
		}

		SetItemBytesReceivedWithSpeed(pw.itemID, pw.current, speedMBps)
		pw.lastReported = pw.current
		pw.lastTime = now
		pw.lastBytes = pw.current
	}
	return n, nil
}
