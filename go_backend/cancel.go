package gobackend

import (
	"context"
	"errors"
	"sync"
)

// ErrDownloadCancelled is returned when a download is cancelled by the user.
var ErrDownloadCancelled = errors.New("download cancelled")

type cancelEntry struct {
	cancel   context.CancelFunc
	canceled bool
}

var (
	cancelMu  sync.Mutex
	cancelMap = make(map[string]*cancelEntry)
)

func initDownloadCancel(itemID string) context.Context {
	if itemID == "" {
		return context.Background()
	}

	cancelMu.Lock()
	defer cancelMu.Unlock()

	ctx, cancel := context.WithCancel(context.Background())
	cancelMap[itemID] = &cancelEntry{
		cancel:   cancel,
		canceled: false,
	}
	return ctx
}

func cancelDownload(itemID string) {
	if itemID == "" {
		return
	}

	cancelMu.Lock()
	entry, ok := cancelMap[itemID]
	if ok {
		entry.canceled = true
		if entry.cancel != nil {
			entry.cancel()
		}
	} else {
		cancelMap[itemID] = &cancelEntry{canceled: true}
	}
	cancelMu.Unlock()

	RemoveItemProgress(itemID)
}

func isDownloadCancelled(itemID string) bool {
	if itemID == "" {
		return false
	}

	cancelMu.Lock()
	entry, ok := cancelMap[itemID]
	canceled := ok && entry.canceled
	cancelMu.Unlock()
	return canceled
}

func clearDownloadCancel(itemID string) {
	if itemID == "" {
		return
	}

	cancelMu.Lock()
	delete(cancelMap, itemID)
	cancelMu.Unlock()
}
