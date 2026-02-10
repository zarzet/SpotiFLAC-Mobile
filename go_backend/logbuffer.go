package gobackend

import (
	"encoding/json"
	"fmt"
	"regexp"
	"strings"
	"sync"
	"time"
)

type LogEntry struct {
	Timestamp string `json:"timestamp"`
	Level     string `json:"level"`
	Tag       string `json:"tag"`
	Message   string `json:"message"`
}

type LogBuffer struct {
	entries        []LogEntry
	maxSize        int
	mu             sync.RWMutex
	loggingEnabled bool
}

const (
	defaultLogBufferSize = 500
	maxLogMessageLength  = 500
)

var (
	globalLogBuffer *LogBuffer
	logBufferOnce   sync.Once

	authorizationBearerPattern = regexp.MustCompile(`(?i)\bAuthorization\b\s*[:=]\s*Bearer\s+[A-Za-z0-9._~+/\-]+=*`)
	genericKeyValuePattern     = regexp.MustCompile(`(?i)\b(access[_\s-]?token|refresh[_\s-]?token|id[_\s-]?token|client[_\s-]?secret|authorization|password|api[_\s-]?key)\b(\s*[:=]\s*)([^\s,;]+)`)
	queryTokenPattern          = regexp.MustCompile(`(?i)([?&](?:access_token|refresh_token|id_token|token|client_secret|api_key|apikey|password)=)[^&\s]+`)
	bearerTokenPattern         = regexp.MustCompile(`(?i)\bBearer\s+[A-Za-z0-9._~+/\-]+=*`)
)

func sanitizeSensitiveLogText(message string) string {
	redacted := message
	redacted = authorizationBearerPattern.ReplaceAllString(redacted, "Authorization: Bearer [REDACTED]")
	redacted = genericKeyValuePattern.ReplaceAllString(redacted, `${1}${2}[REDACTED]`)
	redacted = queryTokenPattern.ReplaceAllString(redacted, `${1}[REDACTED]`)
	redacted = bearerTokenPattern.ReplaceAllString(redacted, "Bearer [REDACTED]")
	return redacted
}

func GetLogBuffer() *LogBuffer {
	logBufferOnce.Do(func() {
		globalLogBuffer = &LogBuffer{
			entries:        make([]LogEntry, 0, defaultLogBufferSize),
			maxSize:        defaultLogBufferSize,
			loggingEnabled: false, // Default: disabled for performance (user can enable in settings)
		}
	})
	return globalLogBuffer
}

func truncateLogMessage(message string) string {
	runes := []rune(message)
	if len(runes) <= maxLogMessageLength {
		return message
	}
	return string(runes[:maxLogMessageLength]) + "...[truncated]"
}

func (lb *LogBuffer) SetLoggingEnabled(enabled bool) {
	lb.mu.Lock()
	defer lb.mu.Unlock()
	lb.loggingEnabled = enabled
}

func (lb *LogBuffer) IsLoggingEnabled() bool {
	lb.mu.RLock()
	defer lb.mu.RUnlock()
	return lb.loggingEnabled
}

func (lb *LogBuffer) Add(level, tag, message string) {
	lb.mu.Lock()
	defer lb.mu.Unlock()

	if !lb.loggingEnabled && level != "ERROR" && level != "FATAL" {
		return
	}

	message = sanitizeSensitiveLogText(message)
	message = truncateLogMessage(message)

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

func (lb *LogBuffer) Clear() {
	lb.mu.Lock()
	defer lb.mu.Unlock()
	lb.entries = lb.entries[:0]
}

func (lb *LogBuffer) Count() int {
	lb.mu.RLock()
	defer lb.mu.RUnlock()
	return len(lb.entries)
}

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
	if strings.Contains(msgLower, "error") || strings.Contains(msgLower, "failed") {
		level = "ERROR"
	} else if strings.Contains(msgLower, "warning") || strings.Contains(msgLower, "warn") {
		level = "WARN"
	} else if strings.Contains(msgLower, "success") || strings.Contains(msgLower, "match found") {
		level = "INFO"
	} else if strings.Contains(msgLower, "searching") || strings.Contains(msgLower, "trying") || strings.Contains(msgLower, "found") {
		level = "DEBUG"
	}

	GetLogBuffer().Add(level, tag, message)
}

func GetLogs() string {
	return GetLogBuffer().GetAll()
}

func GetLogsSince(index int) string {
	entries, nextIndex := GetLogBuffer().getSince(index)
	logsJson, _ := json.Marshal(entries)
	result := fmt.Sprintf(`{"logs":%s,"next_index":%d}`, string(logsJson), nextIndex)
	return result
}

func ClearLogs() {
	GetLogBuffer().Clear()
}

func GetLogCount() int {
	return GetLogBuffer().Count()
}

func SetLoggingEnabled(enabled bool) {
	GetLogBuffer().SetLoggingEnabled(enabled)
}
