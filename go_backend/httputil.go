package gobackend

import (
	"crypto/tls"
	"errors"
	"fmt"
	"io"
	"math/rand"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// HTTP utility functions for consistent request handling across all downloaders

// getRandomUserAgent generates a random Windows Chrome User-Agent string
// Uses same format as PC version (referensi/backend/spotify_metadata.go) for better API compatibility
func getRandomUserAgent() string {
	winMajor := rand.Intn(2) + 10

	chromeVersion := rand.Intn(25) + 100
	chromeBuild := rand.Intn(1500) + 3000
	chromePatch := rand.Intn(65) + 60

	return fmt.Sprintf(
		"Mozilla/5.0 (Windows NT %d.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%d.0.%d.%d Safari/537.36",
		winMajor,
		chromeVersion,
		chromeBuild,
		chromePatch,
	)
}

// getRandomMacUserAgent generates a random Mac Chrome User-Agent string
// Alternative format matching referensi/backend/spotify_metadata.go exactly
// func getRandomMacUserAgent() string {
// 	macMajor := rand.Intn(4) + 11 // macOS 11-14
// 	macMinor := rand.Intn(5) + 4  // Minor 4-8
// 	webkitMajor := rand.Intn(7) + 530
// 	webkitMinor := rand.Intn(7) + 30
// 	chromeMajor := rand.Intn(25) + 80
// 	chromeBuild := rand.Intn(1500) + 3000
// 	chromePatch := rand.Intn(65) + 60
// 	safariMajor := rand.Intn(7) + 530
// 	safariMinor := rand.Intn(6) + 30
//
// 	return fmt.Sprintf(
// 		"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_%d_%d) AppleWebKit/%d.%d (KHTML, like Gecko) Chrome/%d.0.%d.%d Safari/%d.%d",
// 		macMajor,
// 		macMinor,
// 		webkitMajor,
// 		webkitMinor,
// 		chromeMajor,
// 		chromeBuild,
// 		chromePatch,
// 		safariMajor,
// 		safariMinor,
// 	)
// }

// getRandomDesktopUserAgent randomly picks between Windows and Mac User-Agent
// func getRandomDesktopUserAgent() string {
// 	if rand.Intn(2) == 0 {
// 		return getRandomUserAgent() // Windows
// 	}
// 	return getRandomMacUserAgent() // Mac
// }

const (
	DefaultTimeout    = 60 * time.Second
	DownloadTimeout   = 120 * time.Second
	SongLinkTimeout   = 30 * time.Second
	DefaultMaxRetries = 3
	DefaultRetryDelay = 1 * time.Second
)

// Shared transport with connection pooling to prevent TCP exhaustion
var sharedTransport = &http.Transport{
	DialContext: (&net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 30 * time.Second,
	}).DialContext,
	MaxIdleConns:          100,
	MaxIdleConnsPerHost:   10,
	MaxConnsPerHost:       20,
	IdleConnTimeout:       90 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ExpectContinueTimeout: 1 * time.Second,
	DisableKeepAlives:     false,
	ForceAttemptHTTP2:     true,
	WriteBufferSize:       64 * 1024,
	ReadBufferSize:        64 * 1024,
	DisableCompression:    true,
}

var sharedClient = &http.Client{
	Transport: sharedTransport,
	Timeout:   DefaultTimeout,
}

var downloadClient = &http.Client{
	Transport: sharedTransport,
	Timeout:   DownloadTimeout,
}

// NewHTTPClientWithTimeout creates an HTTP client with specified timeout
func NewHTTPClientWithTimeout(timeout time.Duration) *http.Client {
	return &http.Client{
		Transport: sharedTransport,
		Timeout:   timeout,
	}
}

func GetSharedClient() *http.Client {
	return sharedClient
}

func GetDownloadClient() *http.Client {
	return downloadClient
}

// CloseIdleConnections closes idle connections in the shared transport
func CloseIdleConnections() {
	sharedTransport.CloseIdleConnections()
}

// DoRequestWithUserAgent executes an HTTP request with a random User-Agent header
// Also checks for ISP blocking on errors
func DoRequestWithUserAgent(client *http.Client, req *http.Request) (*http.Response, error) {
	req.Header.Set("User-Agent", getRandomUserAgent())
	resp, err := client.Do(req)
	if err != nil {
		CheckAndLogISPBlocking(err, req.URL.String(), "HTTP")
	}
	return resp, err
}

// RetryConfig holds configuration for retry logic
type RetryConfig struct {
	MaxRetries    int
	InitialDelay  time.Duration
	MaxDelay      time.Duration
	BackoffFactor float64
}

// DefaultRetryConfig returns default retry configuration
func DefaultRetryConfig() RetryConfig {
	return RetryConfig{
		MaxRetries:    DefaultMaxRetries,
		InitialDelay:  DefaultRetryDelay,
		MaxDelay:      16 * time.Second,
		BackoffFactor: 2.0,
	}
}

// DoRequestWithRetry executes an HTTP request with retry logic and exponential backoff
// Handles 429 (Too Many Requests) responses with Retry-After header
// Also detects and logs ISP blocking
func DoRequestWithRetry(client *http.Client, req *http.Request, config RetryConfig) (*http.Response, error) {
	var lastErr error
	delay := config.InitialDelay
	requestURL := req.URL.String()

	for attempt := 0; attempt <= config.MaxRetries; attempt++ {
		// Clone request for retry (body needs to be re-readable)
		reqCopy := req.Clone(req.Context())
		reqCopy.Header.Set("User-Agent", getRandomUserAgent())

		resp, err := client.Do(reqCopy)
		if err != nil {
			lastErr = err

			// Check for ISP blocking on network errors
			if CheckAndLogISPBlocking(err, requestURL, "HTTP") {
				// Don't retry if ISP blocking is detected - it won't help
				return nil, WrapErrorWithISPCheck(err, requestURL, "HTTP")
			}

			if attempt < config.MaxRetries {
				GoLog("[HTTP] Request failed (attempt %d/%d): %v, retrying in %v...\n",
					attempt+1, config.MaxRetries+1, err, delay)
				time.Sleep(delay)
				delay = calculateNextDelay(delay, config)
			}
			continue
		}

		// Success
		if resp.StatusCode >= 200 && resp.StatusCode < 300 {
			return resp, nil
		}

		// Handle rate limiting (429)
		if resp.StatusCode == 429 {
			resp.Body.Close()
			retryAfter := getRetryAfterDuration(resp)
			if retryAfter > 0 {
				delay = retryAfter
			}
			lastErr = fmt.Errorf("rate limited (429)")
			if attempt < config.MaxRetries {
				GoLog("[HTTP] Rate limited, waiting %v before retry...\n", delay)
				time.Sleep(delay)
				delay = calculateNextDelay(delay, config)
			}
			continue
		}

		// Check for ISP blocking via HTTP status codes
		// Some ISPs return 403 or 451 when blocking content
		if resp.StatusCode == 403 || resp.StatusCode == 451 {
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			bodyStr := strings.ToLower(string(body))

			// Check if response looks like ISP blocking page
			ispBlockingIndicators := []string{
				"blocked", "forbidden", "access denied", "not available in your",
				"restricted", "censored", "unavailable for legal", "blocked by",
			}

			for _, indicator := range ispBlockingIndicators {
				if strings.Contains(bodyStr, indicator) {
					LogError("HTTP", "ISP BLOCKING DETECTED via HTTP %d response", resp.StatusCode)
					LogError("HTTP", "Domain: %s", req.URL.Host)
					LogError("HTTP", "Response contains: %s", indicator)
					LogError("HTTP", "Suggestion: Try using a VPN or changing your DNS to 1.1.1.1 or 8.8.8.8")
					return nil, fmt.Errorf("ISP blocking detected for %s (HTTP %d) - try using VPN or change DNS", req.URL.Host, resp.StatusCode)
				}
			}
		}

		// Server errors (5xx) - retry
		if resp.StatusCode >= 500 {
			resp.Body.Close()
			lastErr = fmt.Errorf("server error: HTTP %d", resp.StatusCode)
			if attempt < config.MaxRetries {
				GoLog("[HTTP] Server error %d, retrying in %v...\n", resp.StatusCode, delay)
				time.Sleep(delay)
				delay = calculateNextDelay(delay, config)
			}
			continue
		}

		// Client errors (4xx except 429) - don't retry
		return resp, nil
	}

	return nil, fmt.Errorf("request failed after %d retries: %w", config.MaxRetries+1, lastErr)
}

// calculateNextDelay calculates the next delay with exponential backoff
func calculateNextDelay(currentDelay time.Duration, config RetryConfig) time.Duration {
	nextDelay := time.Duration(float64(currentDelay) * config.BackoffFactor)
	return min(nextDelay, config.MaxDelay)
}

// getRetryAfterDuration parses Retry-After header and returns duration
// Returns 60 seconds as default if header is missing or invalid
func getRetryAfterDuration(resp *http.Response) time.Duration {
	retryAfter := resp.Header.Get("Retry-After")
	if retryAfter == "" {
		return 60 * time.Second // Default wait time
	}

	// Try parsing as seconds
	if seconds, err := strconv.Atoi(retryAfter); err == nil {
		return time.Duration(seconds) * time.Second
	}

	// Try parsing as HTTP date
	if t, err := http.ParseTime(retryAfter); err == nil {
		duration := time.Until(t)
		if duration > 0 {
			return duration
		}
	}

	return 60 * time.Second // Default
}

// ReadResponseBody reads and returns the response body
// Returns error if body is empty
func ReadResponseBody(resp *http.Response) ([]byte, error) {
	if resp == nil {
		return nil, fmt.Errorf("response is nil")
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	if len(body) == 0 {
		return nil, fmt.Errorf("response body is empty")
	}

	return body, nil
}

// ValidateResponse checks if response is valid (non-nil, status 2xx)
func ValidateResponse(resp *http.Response) error {
	if resp == nil {
		return fmt.Errorf("response is nil")
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
	}

	return nil
}

// BuildErrorMessage creates a detailed error message for API failures
func BuildErrorMessage(apiURL string, statusCode int, responsePreview string) string {
	msg := fmt.Sprintf("API %s failed", apiURL)
	if statusCode > 0 {
		msg += fmt.Sprintf(" (HTTP %d)", statusCode)
	}
	if responsePreview != "" {
		// Truncate preview if too long
		if len(responsePreview) > 100 {
			responsePreview = responsePreview[:100] + "..."
		}
		msg += fmt.Sprintf(": %s", responsePreview)
	}
	return msg
}

// ISPBlockingError represents an error caused by ISP blocking
type ISPBlockingError struct {
	Domain      string
	Reason      string
	OriginalErr error
}

func (e *ISPBlockingError) Error() string {
	return fmt.Sprintf("ISP blocking detected for %s: %s", e.Domain, e.Reason)
}

// IsISPBlocking checks if an error is likely caused by ISP blocking
// Returns the ISPBlockingError if detected, nil otherwise
func IsISPBlocking(err error, requestURL string) *ISPBlockingError {
	if err == nil {
		return nil
	}

	// Extract domain from URL
	domain := extractDomain(requestURL)
	errStr := strings.ToLower(err.Error())

	// Check for DNS resolution failure (common ISP blocking method)
	var dnsErr *net.DNSError
	if errors.As(err, &dnsErr) {
		if dnsErr.IsNotFound || dnsErr.IsTemporary {
			return &ISPBlockingError{
				Domain:      domain,
				Reason:      "DNS resolution failed - domain may be blocked by ISP",
				OriginalErr: err,
			}
		}
	}

	// Check for connection refused (ISP firewall blocking)
	var opErr *net.OpError
	if errors.As(err, &opErr) {
		if opErr.Op == "dial" {
			// Check for specific syscall errors
			var syscallErr syscall.Errno
			if errors.As(opErr.Err, &syscallErr) {
				switch syscallErr {
				case syscall.ECONNREFUSED:
					return &ISPBlockingError{
						Domain:      domain,
						Reason:      "Connection refused - port may be blocked by ISP/firewall",
						OriginalErr: err,
					}
				case syscall.ECONNRESET:
					return &ISPBlockingError{
						Domain:      domain,
						Reason:      "Connection reset - ISP may be intercepting traffic",
						OriginalErr: err,
					}
				case syscall.ETIMEDOUT:
					return &ISPBlockingError{
						Domain:      domain,
						Reason:      "Connection timed out - ISP may be blocking access",
						OriginalErr: err,
					}
				case syscall.ENETUNREACH:
					return &ISPBlockingError{
						Domain:      domain,
						Reason:      "Network unreachable - ISP may be blocking route",
						OriginalErr: err,
					}
				case syscall.EHOSTUNREACH:
					return &ISPBlockingError{
						Domain:      domain,
						Reason:      "Host unreachable - ISP may be blocking destination",
						OriginalErr: err,
					}
				}
			}
		}
	}

	// Check for TLS handshake failure (ISP MITM or blocking HTTPS)
	var tlsErr *tls.RecordHeaderError
	if errors.As(err, &tlsErr) {
		return &ISPBlockingError{
			Domain:      domain,
			Reason:      "TLS handshake failed - ISP may be intercepting HTTPS traffic",
			OriginalErr: err,
		}
	}

	// Check error message patterns for common ISP blocking indicators
	blockingPatterns := []struct {
		pattern string
		reason  string
	}{
		{"connection reset by peer", "Connection reset - ISP may be intercepting traffic"},
		{"connection refused", "Connection refused - port may be blocked"},
		{"no such host", "DNS lookup failed - domain may be blocked by ISP"},
		{"i/o timeout", "Connection timed out - ISP may be blocking access"},
		{"network is unreachable", "Network unreachable - ISP may be blocking route"},
		{"tls: ", "TLS error - ISP may be intercepting HTTPS traffic"},
		{"certificate", "Certificate error - ISP may be using MITM proxy"},
		{"eof", "Connection closed unexpectedly - ISP may be blocking"},
		{"context deadline exceeded", "Request timed out - ISP may be throttling"},
	}

	for _, bp := range blockingPatterns {
		if strings.Contains(errStr, bp.pattern) {
			return &ISPBlockingError{
				Domain:      domain,
				Reason:      bp.reason,
				OriginalErr: err,
			}
		}
	}

	return nil
}

// CheckAndLogISPBlocking checks for ISP blocking and logs if detected
// Returns true if ISP blocking was detected
func CheckAndLogISPBlocking(err error, requestURL string, tag string) bool {
	ispErr := IsISPBlocking(err, requestURL)
	if ispErr != nil {
		LogError(tag, "ISP BLOCKING DETECTED: %s", ispErr.Error())
		LogError(tag, "Domain: %s", ispErr.Domain)
		LogError(tag, "Reason: %s", ispErr.Reason)
		LogError(tag, "Original error: %v", ispErr.OriginalErr)
		LogError(tag, "Suggestion: Try using a VPN or changing your DNS to 1.1.1.1 or 8.8.8.8")
		return true
	}
	return false
}

// extractDomain extracts the domain from a URL string
func extractDomain(rawURL string) string {
	if rawURL == "" {
		return "unknown"
	}

	parsed, err := url.Parse(rawURL)
	if err != nil {
		// Try to extract domain manually
		rawURL = strings.TrimPrefix(rawURL, "https://")
		rawURL = strings.TrimPrefix(rawURL, "http://")
		if idx := strings.Index(rawURL, "/"); idx > 0 {
			return rawURL[:idx]
		}
		return rawURL
	}

	if parsed.Host != "" {
		return parsed.Host
	}
	return "unknown"
}

// WrapErrorWithISPCheck wraps an error with ISP blocking detection
// If ISP blocking is detected, returns a more descriptive error
func WrapErrorWithISPCheck(err error, requestURL string, tag string) error {
	if err == nil {
		return nil
	}

	if CheckAndLogISPBlocking(err, requestURL, tag) {
		domain := extractDomain(requestURL)
		return fmt.Errorf("ISP blocking detected for %s - try using VPN or change DNS to 1.1.1.1/8.8.8.8: %w", domain, err)
	}

	return err
}
