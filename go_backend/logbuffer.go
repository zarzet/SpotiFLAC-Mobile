package gobackend

import (
	"encoding/json"
	"fmt"
	"strings"
	"sync"
	"time"
)

// LogEntry represents a single log entry
type LogEntry struct {
	Timestamp string `json:"timestamp"`
	Level     string `json:"level"`
	Tag       string `json:"tag"`
	Message   string `json:"message"`
}

// LogBuffer stores logs in a circular buffer for retrieval by Flutter
type LogBuffer struct {
	entries        []LogEntry
	maxSize        int
	mu             sync.RWMutex
	loggingEnabled bool
}

var (
	globalLogBuffer *LogBuffer
	logBufferOnce   sync.Once
)

// GetLogBuffer returns the singleton log buffer instance
func GetLogBuffer() *LogBuffer {
	logBufferOnce.Do(func() {
		globalLogBuffer = &LogBuffer{
			entries:        make([]LogEntry, 0, 1000),
			maxSize:        1000,
			loggingEnabled: false, // Default: disabled for performance (user can enable in settings)
		}
	})
	return globalLogBuffer
}

// SetLoggingEnabled enables or disables logging
func (lb *LogBuffer) SetLoggingEnabled(enabled bool) {
	lb.mu.Lock()
	defer lb.mu.Unlock()
	lb.loggingEnabled = enabled
}

// IsLoggingEnabled returns whether logging is enabled
func (lb *LogBuffer) IsLoggingEnabled() bool {
	lb.mu.RLock()
	defer lb.mu.RUnlock()
	return lb.loggingEnabled
}

// Add adds a log entry to the buffer
func (lb *LogBuffer) Add(level, tag, message string) {
	lb.mu.Lock()
	defer lb.mu.Unlock()

	if !lb.loggingEnabled && level != "ERROR" && level != "FATAL" {
		return
	}

	entry := LogEntry{
		Timestamp: time.Now().Format("15:04:05.000"),
		Level:     level,
		Tag:       tag,
		Message:   message,
	}

	if len(lb.entries) >= lb.maxSize {
		lb.entries = lb.entries[1:]
	}
	lb.entries = append(lb.entries, entry)

	fmt.Printf("[%s] %s\n", tag, message)
}

// GetAll returns all log entries as JSON
func (lb *LogBuffer) GetAll() string {
	lb.mu.RLock()
	defer lb.mu.RUnlock()

	jsonBytes, _ := json.Marshal(lb.entries)
	return string(jsonBytes)
}

func (lb *LogBuffer) getSince(index int) ([]LogEntry, int) {
	lb.mu.RLock()
	defer lb.mu.RUnlock()

	if index < 0 {
		index = 0
	}
	if index >= len(lb.entries) {
		return []LogEntry{}, len(lb.entries)
	}

	entries := lb.entries[index:]
	return entries, len(lb.entries)
}

// Clear clears all log entries
func (lb *LogBuffer) Clear() {
	lb.mu.Lock()
	defer lb.mu.Unlock()
	lb.entries = lb.entries[:0]
}

// Count returns the number of log entries
func (lb *LogBuffer) Count() int {
	lb.mu.RLock()
	defer lb.mu.RUnlock()
	return len(lb.entries)
}

// Helper functions for logging with different levels
func LogDebug(tag, format string, args ...interface{}) {
	GetLogBuffer().Add("DEBUG", tag, fmt.Sprintf(format, args...))
}

func LogInfo(tag, format string, args ...interface{}) {
	GetLogBuffer().Add("INFO", tag, fmt.Sprintf(format, args...))
}

func LogWarn(tag, format string, args ...interface{}) {
	GetLogBuffer().Add("WARN", tag, fmt.Sprintf(format, args...))
}

func LogError(tag, format string, args ...interface{}) {
	GetLogBuffer().Add("ERROR", tag, fmt.Sprintf(format, args...))
}

// GoLog is a drop-in replacement for fmt.Printf that also logs to buffer
// It parses the tag from the format string if it starts with [Tag]
func GoLog(format string, args ...interface{}) {
	message := fmt.Sprintf(format, args...)
	message = strings.TrimSuffix(message, "\n")

	// Extract tag from message if present (e.g., "[Tidal] message")
	tag := "Go"
	level := "INFO"

	if strings.HasPrefix(message, "[") {
		endBracket := strings.Index(message, "]")
		if endBracket > 1 {
			tag = message[1:endBracket]
			message = strings.TrimSpace(message[endBracket+1:])
		}
	}

	// Determine level from message content
	msgLower := strings.ToLower(message)
	if strings.Contains(msgLower, "error") || strings.Contains(msgLower, "failed") || strings.HasPrefix(message, "✗") {
		level = "ERROR"
	} else if strings.Contains(msgLower, "warning") || strings.Contains(msgLower, "warn") {
		level = "WARN"
	} else if strings.HasPrefix(message, "✓") || strings.Contains(msgLower, "success") || strings.Contains(msgLower, "match found") {
		level = "INFO"
	} else if strings.Contains(msgLower, "searching") || strings.Contains(msgLower, "trying") || strings.Contains(msgLower, "found") {
		level = "DEBUG"
	}

	GetLogBuffer().Add(level, tag, message)
}

// Exported functions for Flutter

// GetLogs returns all logs as JSON array
func GetLogs() string {
	return GetLogBuffer().GetAll()
}

// GetLogsSince returns logs since the given index
// Returns JSON: {"logs": [...], "next_index": N}
func GetLogsSince(index int) string {
	entries, nextIndex := GetLogBuffer().getSince(index)
	logsJson, _ := json.Marshal(entries)
	result := fmt.Sprintf(`{"logs":%s,"next_index":%d}`, string(logsJson), nextIndex)
	return result
}

// ClearLogs clears all logs
func ClearLogs() {
	GetLogBuffer().Clear()
}

// GetLogCount returns the number of log entries
func GetLogCount() int {
	return GetLogBuffer().Count()
}

// SetLoggingEnabled enables or disables logging from Flutter
func SetLoggingEnabled(enabled bool) {
	GetLogBuffer().SetLoggingEnabled(enabled)
}
