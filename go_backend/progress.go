package gobackend

import (
	"encoding/json"
	"sync"
	"time"
)

type DownloadProgress struct {
	CurrentFile   string  `json:"current_file"`
	Progress      float64 `json:"progress"`
	Speed         float64 `json:"speed_mbps"`
	BytesTotal    int64   `json:"bytes_total"`
	BytesReceived int64   `json:"bytes_received"`
	IsDownloading bool    `json:"is_downloading"`
	Status        string  `json:"status"`
}

type ItemProgress struct {
	ItemID        string  `json:"item_id"`
	BytesTotal    int64   `json:"bytes_total"`
	BytesReceived int64   `json:"bytes_received"`
	Progress      float64 `json:"progress"`
	SpeedMBps     float64 `json:"speed_mbps"`
	IsDownloading bool    `json:"is_downloading"`
	Status        string  `json:"status"`
}

type MultiProgress struct {
	Items map[string]*ItemProgress `json:"items"`
}

var (
	downloadDir   string
	downloadDirMu sync.RWMutex

	multiProgress = MultiProgress{Items: make(map[string]*ItemProgress)}
	multiMu       sync.RWMutex
)

func getProgress() DownloadProgress {
	multiMu.RLock()
	defer multiMu.RUnlock()

	for _, item := range multiProgress.Items {
		return DownloadProgress{
			CurrentFile:   item.ItemID,
			Progress:      item.Progress * 100,
			BytesTotal:    item.BytesTotal,
			BytesReceived: item.BytesReceived,
			IsDownloading: item.IsDownloading,
			Status:        item.Status,
		}
	}

	return DownloadProgress{}
}

func GetMultiProgress() string {
	multiMu.RLock()
	defer multiMu.RUnlock()

	jsonBytes, err := json.Marshal(multiProgress)
	if err != nil {
		return "{\"items\":{}}"
	}
	return string(jsonBytes)
}

func GetItemProgress(itemID string) string {
	multiMu.RLock()
	defer multiMu.RUnlock()

	if item, ok := multiProgress.Items[itemID]; ok {
		jsonBytes, _ := json.Marshal(item)
		return string(jsonBytes)
	}
	return "{}"
}

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

func SetItemBytesTotal(itemID string, total int64) {
	multiMu.Lock()
	defer multiMu.Unlock()

	if item, ok := multiProgress.Items[itemID]; ok {
		item.BytesTotal = total
	}
}

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

func CompleteItemProgress(itemID string) {
	multiMu.Lock()
	defer multiMu.Unlock()

	if item, ok := multiProgress.Items[itemID]; ok {
		item.Progress = 1.0
		item.IsDownloading = false
		item.Status = "completed"
	}
}

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

func SetItemFinalizing(itemID string) {
	multiMu.Lock()
	defer multiMu.Unlock()

	if item, ok := multiProgress.Items[itemID]; ok {
		item.Progress = 1.0
		item.Status = "finalizing"
	}
}

func RemoveItemProgress(itemID string) {
	multiMu.Lock()
	defer multiMu.Unlock()

	delete(multiProgress.Items, itemID)
}

func ClearAllItemProgress() {
	multiMu.Lock()
	defer multiMu.Unlock()

	multiProgress.Items = make(map[string]*ItemProgress)
}

func setDownloadDir(path string) error {
	downloadDirMu.Lock()
	defer downloadDirMu.Unlock()
	downloadDir = path
	return nil
}

type ItemProgressWriter struct {
	writer       interface{ Write([]byte) (int, error) }
	itemID       string
	current      int64
	lastReported int64
	startTime    time.Time
	lastTime     time.Time
	lastBytes    int64
}

const progressUpdateThreshold = 64 * 1024

// NewItemProgressWriter creates a progress writer.
// Accepts startByte to correctly report progress when resuming.
func NewItemProgressWriter(w interface{ Write([]byte) (int, error) }, itemID string, startByte int64) *ItemProgressWriter {
	now := time.Now()
	return &ItemProgressWriter{
		writer:       w,
		itemID:       itemID,
		current:      startByte, // Start counting from existing offset
		lastReported: startByte,
		startTime:    now,
		lastTime:     now,
		lastBytes:    startByte,
	}
}

func (pw *ItemProgressWriter) Write(p []byte) (int, error) {
	if pw.itemID != "" && isDownloadCancelled(pw.itemID) {
		return 0, ErrDownloadCancelled
	}
	n, err := pw.writer.Write(p)
	if err != nil {
		return n, err
	}
	pw.current += int64(n)

	if pw.lastReported == 0 || pw.current-pw.lastReported >= progressUpdateThreshold {
		now := time.Now()
		elapsed := now.Sub(pw.lastTime).Seconds()
		var speedMBps float64
		// Ensure elapsed time is significant to avoid speed spikes or div by zero
		if elapsed > 0.1 {
			bytesInInterval := pw.current - pw.lastBytes
			speedMBps = float64(bytesInInterval) / (1024 * 1024) / elapsed

			// Update lastTime and lastBytes for the next interval
			pw.lastTime = now
			pw.lastBytes = pw.current
		} else if pw.lastBytes == 0 {
			// Special case for the very first chunk if fast
			totalElapsed := now.Sub(pw.startTime).Seconds()
			if totalElapsed > 0 {
				speedMBps = float64(pw.current) / (1024 * 1024) / totalElapsed
			}
		}

		SetItemBytesReceivedWithSpeed(pw.itemID, pw.current, speedMBps)
		pw.lastReported = pw.current
	}
	return n, nil
}