package gobackend

import (
	"sync"
	"time"
)

// RateLimiter implements a sliding window rate limiter
type RateLimiter struct {
	mu          sync.Mutex
	maxRequests int
	window      time.Duration
	timestamps  []time.Time
}

// NewRateLimiter creates a new rate limiter with specified max requests per window
func NewRateLimiter(maxRequests int, window time.Duration) *RateLimiter {
	return &RateLimiter{
		maxRequests: maxRequests,
		window:      window,
		timestamps:  make([]time.Time, 0, maxRequests),
	}
}

// WaitForSlot blocks until a request is allowed under the rate limit
// Returns immediately if under the limit, otherwise waits until a slot is available
func (r *RateLimiter) WaitForSlot() {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now()

	r.cleanOldTimestamps(now)

	if len(r.timestamps) < r.maxRequests {
		r.timestamps = append(r.timestamps, now)
		return
	}

	oldestTimestamp := r.timestamps[0]
	waitUntil := oldestTimestamp.Add(r.window)
	waitDuration := waitUntil.Sub(now)

	if waitDuration > 0 {
		r.mu.Unlock()
		time.Sleep(waitDuration)
		r.mu.Lock()

		r.cleanOldTimestamps(time.Now())
	}

	r.timestamps = append(r.timestamps, time.Now())
}

// cleanOldTimestamps removes timestamps that are outside the current window
func (r *RateLimiter) cleanOldTimestamps(now time.Time) {
	cutoff := now.Add(-r.window)
	validStart := 0

	for i, ts := range r.timestamps {
		if ts.After(cutoff) {
			validStart = i
			break
		}
		validStart = i + 1
	}

	if validStart > 0 {
		r.timestamps = r.timestamps[validStart:]
	}
}

// TryAcquire attempts to acquire a slot without blocking
// Returns true if successful, false if rate limit would be exceeded
func (r *RateLimiter) TryAcquire() bool {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now()
	r.cleanOldTimestamps(now)

	if len(r.timestamps) < r.maxRequests {
		r.timestamps = append(r.timestamps, now)
		return true
	}

	return false
}

// Available returns the number of requests available in the current window
func (r *RateLimiter) Available() int {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.cleanOldTimestamps(time.Now())
	return r.maxRequests - len(r.timestamps)
}

// Global SongLink rate limiter - 9 requests per minute (to be safe, limit is 10)
var songLinkRateLimiter = NewRateLimiter(9, time.Minute)

// GetSongLinkRateLimiter returns the global SongLink rate limiter
func GetSongLinkRateLimiter() *RateLimiter {
	return songLinkRateLimiter
}
