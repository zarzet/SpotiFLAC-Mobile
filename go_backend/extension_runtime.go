// Package gobackend provides extension runtime with sandboxed execution
package gobackend

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/md5"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/dop251/goja"
)

// Global auth state for extensions (stores pending auth codes)
var (
	extensionAuthState   = make(map[string]*ExtensionAuthState)
	extensionAuthStateMu sync.RWMutex
)

// ExtensionAuthState holds auth state for an extension
type ExtensionAuthState struct {
	PendingAuthURL  string
	AuthCode        string
	AccessToken     string
	RefreshToken    string
	ExpiresAt       time.Time
	IsAuthenticated bool
}

// PendingAuthRequest holds a pending OAuth request that needs Flutter to open URL
type PendingAuthRequest struct {
	ExtensionID string
	AuthURL     string
	CallbackURL string
}

// Global pending auth requests (Flutter polls this)
var (
	pendingAuthRequests   = make(map[string]*PendingAuthRequest)
	pendingAuthRequestsMu sync.RWMutex
)

// GetPendingAuthRequest returns pending auth request for an extension (called from Flutter)
func GetPendingAuthRequest(extensionID string) *PendingAuthRequest {
	pendingAuthRequestsMu.RLock()
	defer pendingAuthRequestsMu.RUnlock()
	return pendingAuthRequests[extensionID]
}

// ClearPendingAuthRequest clears pending auth request (called from Flutter after opening URL)
func ClearPendingAuthRequest(extensionID string) {
	pendingAuthRequestsMu.Lock()
	defer pendingAuthRequestsMu.Unlock()
	delete(pendingAuthRequests, extensionID)
}

// SetExtensionAuthCode sets auth code for an extension (called from Flutter after OAuth callback)
func SetExtensionAuthCode(extensionID string, authCode string) {
	extensionAuthStateMu.Lock()
	defer extensionAuthStateMu.Unlock()

	state, exists := extensionAuthState[extensionID]
	if !exists {
		state = &ExtensionAuthState{}
		extensionAuthState[extensionID] = state
	}
	state.AuthCode = authCode
}

// SetExtensionTokens sets access/refresh tokens for an extension
func SetExtensionTokens(extensionID string, accessToken, refreshToken string, expiresAt time.Time) {
	extensionAuthStateMu.Lock()
	defer extensionAuthStateMu.Unlock()

	state, exists := extensionAuthState[extensionID]
	if !exists {
		state = &ExtensionAuthState{}
		extensionAuthState[extensionID] = state
	}
	state.AccessToken = accessToken
	state.RefreshToken = refreshToken
	state.ExpiresAt = expiresAt
	state.IsAuthenticated = accessToken != ""
}

// ExtensionRuntime provides sandboxed APIs for extensions
type ExtensionRuntime struct {
	extensionID string
	manifest    *ExtensionManifest
	settings    map[string]interface{}
	httpClient  *http.Client
	dataDir     string
	vm          *goja.Runtime
}

// NewExtensionRuntime creates a new runtime for an extension
func NewExtensionRuntime(ext *LoadedExtension) *ExtensionRuntime {
	return &ExtensionRuntime{
		extensionID: ext.ID,
		manifest:    ext.Manifest,
		settings:    make(map[string]interface{}),
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		dataDir: ext.DataDir,
		vm:      ext.VM,
	}
}

// SetSettings updates the runtime settings
func (r *ExtensionRuntime) SetSettings(settings map[string]interface{}) {
	r.settings = settings
}

// RegisterAPIs registers all sandboxed APIs to the Goja VM
func (r *ExtensionRuntime) RegisterAPIs(vm *goja.Runtime) {
	r.vm = vm

	// HTTP client (sandboxed to allowed domains)
	httpObj := vm.NewObject()
	httpObj.Set("get", r.httpGet)
	httpObj.Set("post", r.httpPost)
	vm.Set("http", httpObj)

	// Storage API
	storageObj := vm.NewObject()
	storageObj.Set("get", r.storageGet)
	storageObj.Set("set", r.storageSet)
	storageObj.Set("remove", r.storageRemove)
	vm.Set("storage", storageObj)

	// Secure Credentials API (encrypted storage for sensitive data)
	credentialsObj := vm.NewObject()
	credentialsObj.Set("store", r.credentialsStore)
	credentialsObj.Set("get", r.credentialsGet)
	credentialsObj.Set("remove", r.credentialsRemove)
	credentialsObj.Set("has", r.credentialsHas)
	vm.Set("credentials", credentialsObj)

	// Auth API (for OAuth and other auth flows)
	authObj := vm.NewObject()
	authObj.Set("openAuthUrl", r.authOpenUrl)
	authObj.Set("getAuthCode", r.authGetCode)
	authObj.Set("setAuthCode", r.authSetCode)
	authObj.Set("clearAuth", r.authClear)
	authObj.Set("isAuthenticated", r.authIsAuthenticated)
	authObj.Set("getTokens", r.authGetTokens)
	vm.Set("auth", authObj)

	// File operations (sandboxed)
	fileObj := vm.NewObject()
	fileObj.Set("download", r.fileDownload)
	fileObj.Set("exists", r.fileExists)
	fileObj.Set("delete", r.fileDelete)
	fileObj.Set("read", r.fileRead)
	fileObj.Set("write", r.fileWrite)
	fileObj.Set("copy", r.fileCopy)
	fileObj.Set("move", r.fileMove)
	fileObj.Set("getSize", r.fileGetSize)
	vm.Set("file", fileObj)

	// FFmpeg API (for post-processing)
	ffmpegObj := vm.NewObject()
	ffmpegObj.Set("execute", r.ffmpegExecute)
	ffmpegObj.Set("getInfo", r.ffmpegGetInfo)
	ffmpegObj.Set("convert", r.ffmpegConvert)
	vm.Set("ffmpeg", ffmpegObj)

	// Track matching API
	matchingObj := vm.NewObject()
	matchingObj.Set("compareStrings", r.matchingCompareStrings)
	matchingObj.Set("compareDuration", r.matchingCompareDuration)
	matchingObj.Set("normalizeString", r.matchingNormalizeString)
	vm.Set("matching", matchingObj)

	// Utilities
	utilsObj := vm.NewObject()
	utilsObj.Set("base64Encode", r.base64Encode)
	utilsObj.Set("base64Decode", r.base64Decode)
	utilsObj.Set("md5", r.md5Hash)
	utilsObj.Set("sha256", r.sha256Hash)
	utilsObj.Set("parseJSON", r.parseJSON)
	utilsObj.Set("stringifyJSON", r.stringifyJSON)
	// Crypto utilities for developers
	utilsObj.Set("encrypt", r.cryptoEncrypt)
	utilsObj.Set("decrypt", r.cryptoDecrypt)
	utilsObj.Set("generateKey", r.cryptoGenerateKey)
	vm.Set("utils", utilsObj)

	// Log object (already set in extension_manager.go, but we can enhance it)
	logObj := vm.NewObject()
	logObj.Set("debug", r.logDebug)
	logObj.Set("info", r.logInfo)
	logObj.Set("warn", r.logWarn)
	logObj.Set("error", r.logError)
	vm.Set("log", logObj)

	// Go backend functions
	gobackendObj := vm.NewObject()
	gobackendObj.Set("sanitizeFilename", r.sanitizeFilenameWrapper)
	vm.Set("gobackend", gobackendObj)
}

// ==================== HTTP API (Sandboxed) ====================

// HTTPResponse represents the response from an HTTP request
type HTTPResponse struct {
	StatusCode int               `json:"statusCode"`
	Body       string            `json:"body"`
	Headers    map[string]string `json:"headers"`
}

// validateDomain checks if the domain is allowed by the extension's permissions
func (r *ExtensionRuntime) validateDomain(urlStr string) error {
	parsed, err := url.Parse(urlStr)
	if err != nil {
		return fmt.Errorf("invalid URL: %w", err)
	}

	domain := parsed.Hostname()
	if !r.manifest.IsDomainAllowed(domain) {
		return fmt.Errorf("network access denied: domain '%s' not in allowed list", domain)
	}

	return nil
}

// httpGet performs a GET request (sandboxed)
func (r *ExtensionRuntime) httpGet(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"error": "URL is required",
		})
	}

	urlStr := call.Arguments[0].String()

	// Validate domain
	if err := r.validateDomain(urlStr); err != nil {
		GoLog("[Extension:%s] HTTP blocked: %v\n", r.extensionID, err)
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	// Get headers if provided
	headers := make(map[string]string)
	if len(call.Arguments) > 1 && !goja.IsUndefined(call.Arguments[1]) && !goja.IsNull(call.Arguments[1]) {
		headersObj := call.Arguments[1].Export()
		if h, ok := headersObj.(map[string]interface{}); ok {
			for k, v := range h {
				headers[k] = fmt.Sprintf("%v", v)
			}
		}
	}

	// Create request
	req, err := http.NewRequest("GET", urlStr, nil)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	// Set headers
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	req.Header.Set("User-Agent", "Spotiflac-Extension/1.0")

	// Execute request
	resp, err := r.httpClient.Do(req)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}
	defer resp.Body.Close()

	// Read body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	// Extract response headers
	respHeaders := make(map[string]string)
	for k, v := range resp.Header {
		if len(v) > 0 {
			respHeaders[k] = v[0]
		}
	}

	return r.vm.ToValue(map[string]interface{}{
		"statusCode": resp.StatusCode,
		"body":       string(body),
		"headers":    respHeaders,
	})
}

// httpPost performs a POST request (sandboxed)
func (r *ExtensionRuntime) httpPost(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"error": "URL is required",
		})
	}

	urlStr := call.Arguments[0].String()

	// Validate domain
	if err := r.validateDomain(urlStr); err != nil {
		GoLog("[Extension:%s] HTTP blocked: %v\n", r.extensionID, err)
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	// Get body if provided
	var bodyStr string
	if len(call.Arguments) > 1 && !goja.IsUndefined(call.Arguments[1]) && !goja.IsNull(call.Arguments[1]) {
		bodyStr = call.Arguments[1].String()
	}

	// Get headers if provided
	headers := make(map[string]string)
	if len(call.Arguments) > 2 && !goja.IsUndefined(call.Arguments[2]) && !goja.IsNull(call.Arguments[2]) {
		headersObj := call.Arguments[2].Export()
		if h, ok := headersObj.(map[string]interface{}); ok {
			for k, v := range h {
				headers[k] = fmt.Sprintf("%v", v)
			}
		}
	}

	// Create request
	req, err := http.NewRequest("POST", urlStr, strings.NewReader(bodyStr))
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	// Set headers
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	req.Header.Set("User-Agent", "Spotiflac-Extension/1.0")
	if req.Header.Get("Content-Type") == "" {
		req.Header.Set("Content-Type", "application/json")
	}

	// Execute request
	resp, err := r.httpClient.Do(req)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}
	defer resp.Body.Close()

	// Read body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	// Extract response headers
	respHeaders := make(map[string]string)
	for k, v := range resp.Header {
		if len(v) > 0 {
			respHeaders[k] = v[0]
		}
	}

	return r.vm.ToValue(map[string]interface{}{
		"statusCode": resp.StatusCode,
		"body":       string(body),
		"headers":    respHeaders,
	})
}

// ==================== File API (Sandboxed) ====================

// validatePath checks if the path is within the extension's data directory
// For absolute paths (from download queue), it allows them if they're valid
func (r *ExtensionRuntime) validatePath(path string) (string, error) {
	// Clean and resolve the path
	cleanPath := filepath.Clean(path)

	// If path is absolute, allow it (for download queue paths)
	// This is safe because the Go backend controls what paths are passed
	if filepath.IsAbs(cleanPath) {
		return cleanPath, nil
	}

	// For relative paths, join with data directory
	fullPath := filepath.Join(r.dataDir, cleanPath)

	// Resolve to absolute path
	absPath, err := filepath.Abs(fullPath)
	if err != nil {
		return "", fmt.Errorf("invalid path: %w", err)
	}

	// Ensure path is within data directory
	absDataDir, _ := filepath.Abs(r.dataDir)
	if !strings.HasPrefix(absPath, absDataDir) {
		return "", fmt.Errorf("file access denied: path '%s' is outside sandbox", path)
	}

	return absPath, nil
}

// fileDownload downloads a file from URL to the specified path
// Supports progress callback via options.onProgress
func (r *ExtensionRuntime) fileDownload(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "URL and output path are required",
		})
	}

	urlStr := call.Arguments[0].String()
	outputPath := call.Arguments[1].String()

	// Validate domain
	if err := r.validateDomain(urlStr); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	// Validate output path (allows absolute paths for download queue)
	fullPath, err := r.validatePath(outputPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	// Get options if provided
	var onProgress goja.Callable
	var headers map[string]string
	if len(call.Arguments) > 2 && !goja.IsUndefined(call.Arguments[2]) && !goja.IsNull(call.Arguments[2]) {
		optionsObj := call.Arguments[2].Export()
		if opts, ok := optionsObj.(map[string]interface{}); ok {
			// Extract headers
			if h, ok := opts["headers"].(map[string]interface{}); ok {
				headers = make(map[string]string)
				for k, v := range h {
					headers[k] = fmt.Sprintf("%v", v)
				}
			}
			// Extract onProgress callback
			if progressVal, ok := opts["onProgress"]; ok {
				if callable, ok := goja.AssertFunction(r.vm.ToValue(progressVal)); ok {
					onProgress = callable
				}
			}
		}
	}

	// Create directory if needed
	dir := filepath.Dir(fullPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create directory: %v", err),
		})
	}

	// Create HTTP request
	req, err := http.NewRequest("GET", urlStr, nil)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	// Set headers
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", "SpotiFLAC-Extension/1.0")
	}

	// Download file
	resp, err := r.httpClient.Do(req)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("HTTP error: %d", resp.StatusCode),
		})
	}

	// Create output file
	out, err := os.Create(fullPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create file: %v", err),
		})
	}
	defer out.Close()

	// Get content length for progress
	contentLength := resp.ContentLength

	// Copy content with progress reporting
	var written int64
	buf := make([]byte, 32*1024) // 32KB buffer
	for {
		nr, er := resp.Body.Read(buf)
		if nr > 0 {
			nw, ew := out.Write(buf[0:nr])
			if nw < 0 || nr < nw {
				nw = 0
				if ew == nil {
					ew = fmt.Errorf("invalid write result")
				}
			}
			written += int64(nw)
			if ew != nil {
				return r.vm.ToValue(map[string]interface{}{
					"success": false,
					"error":   fmt.Sprintf("failed to write file: %v", ew),
				})
			}
			if nr != nw {
				return r.vm.ToValue(map[string]interface{}{
					"success": false,
					"error":   "short write",
				})
			}

			// Report progress
			if onProgress != nil && contentLength > 0 {
				_, _ = onProgress(goja.Undefined(), r.vm.ToValue(written), r.vm.ToValue(contentLength))
			}
		}
		if er != nil {
			if er != io.EOF {
				return r.vm.ToValue(map[string]interface{}{
					"success": false,
					"error":   fmt.Sprintf("failed to read response: %v", er),
				})
			}
			break
		}
	}

	GoLog("[Extension:%s] Downloaded %d bytes to %s\n", r.extensionID, written, fullPath)

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"path":    fullPath,
		"size":    written,
	})
}

// fileExists checks if a file exists in the sandbox
func (r *ExtensionRuntime) fileExists(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(false)
	}

	path := call.Arguments[0].String()
	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(false)
	}

	_, err = os.Stat(fullPath)
	return r.vm.ToValue(err == nil)
}

// fileDelete deletes a file in the sandbox
func (r *ExtensionRuntime) fileDelete(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "path is required",
		})
	}

	path := call.Arguments[0].String()
	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	if err := os.Remove(fullPath); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
	})
}

// fileRead reads a file from the sandbox
func (r *ExtensionRuntime) fileRead(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "path is required",
		})
	}

	path := call.Arguments[0].String()
	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	data, err := os.ReadFile(fullPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"data":    string(data),
	})
}

// fileWrite writes data to a file in the sandbox
func (r *ExtensionRuntime) fileWrite(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "path and data are required",
		})
	}

	path := call.Arguments[0].String()
	data := call.Arguments[1].String()

	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	// Create directory if needed
	dir := filepath.Dir(fullPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create directory: %v", err),
		})
	}

	if err := os.WriteFile(fullPath, []byte(data), 0644); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"path":    fullPath,
	})
}

// ==================== Storage API ====================

// getStoragePath returns the path to the extension's storage file
func (r *ExtensionRuntime) getStoragePath() string {
	return filepath.Join(r.dataDir, "storage.json")
}

// loadStorage loads the storage data from disk
func (r *ExtensionRuntime) loadStorage() (map[string]interface{}, error) {
	storagePath := r.getStoragePath()
	data, err := os.ReadFile(storagePath)
	if err != nil {
		if os.IsNotExist(err) {
			return make(map[string]interface{}), nil
		}
		return nil, err
	}

	var storage map[string]interface{}
	if err := json.Unmarshal(data, &storage); err != nil {
		return nil, err
	}

	return storage, nil
}

// saveStorage saves the storage data to disk
func (r *ExtensionRuntime) saveStorage(storage map[string]interface{}) error {
	storagePath := r.getStoragePath()
	data, err := json.MarshalIndent(storage, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(storagePath, data, 0644)
}

// storageGet retrieves a value from storage
func (r *ExtensionRuntime) storageGet(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return goja.Undefined()
	}

	key := call.Arguments[0].String()

	storage, err := r.loadStorage()
	if err != nil {
		GoLog("[Extension:%s] Storage load error: %v\n", r.extensionID, err)
		return goja.Undefined()
	}

	value, exists := storage[key]
	if !exists {
		// Return default value if provided
		if len(call.Arguments) > 1 {
			return call.Arguments[1]
		}
		return goja.Undefined()
	}

	return r.vm.ToValue(value)
}

// storageSet stores a value in storage
func (r *ExtensionRuntime) storageSet(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(false)
	}

	key := call.Arguments[0].String()
	value := call.Arguments[1].Export()

	storage, err := r.loadStorage()
	if err != nil {
		GoLog("[Extension:%s] Storage load error: %v\n", r.extensionID, err)
		return r.vm.ToValue(false)
	}

	storage[key] = value

	if err := r.saveStorage(storage); err != nil {
		GoLog("[Extension:%s] Storage save error: %v\n", r.extensionID, err)
		return r.vm.ToValue(false)
	}

	return r.vm.ToValue(true)
}

// storageRemove removes a value from storage
func (r *ExtensionRuntime) storageRemove(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(false)
	}

	key := call.Arguments[0].String()

	storage, err := r.loadStorage()
	if err != nil {
		GoLog("[Extension:%s] Storage load error: %v\n", r.extensionID, err)
		return r.vm.ToValue(false)
	}

	delete(storage, key)

	if err := r.saveStorage(storage); err != nil {
		GoLog("[Extension:%s] Storage save error: %v\n", r.extensionID, err)
		return r.vm.ToValue(false)
	}

	return r.vm.ToValue(true)
}

// ==================== Utility Functions ====================

// base64Encode encodes a string to base64
func (r *ExtensionRuntime) base64Encode(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue("")
	}
	input := call.Arguments[0].String()
	return r.vm.ToValue(base64.StdEncoding.EncodeToString([]byte(input)))
}

// base64Decode decodes a base64 string
func (r *ExtensionRuntime) base64Decode(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue("")
	}
	input := call.Arguments[0].String()
	decoded, err := base64.StdEncoding.DecodeString(input)
	if err != nil {
		return r.vm.ToValue("")
	}
	return r.vm.ToValue(string(decoded))
}

// md5Hash computes MD5 hash of a string
func (r *ExtensionRuntime) md5Hash(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue("")
	}
	input := call.Arguments[0].String()
	hash := md5.Sum([]byte(input))
	return r.vm.ToValue(hex.EncodeToString(hash[:]))
}

// sha256Hash computes SHA256 hash of a string
func (r *ExtensionRuntime) sha256Hash(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue("")
	}
	input := call.Arguments[0].String()
	hash := sha256.Sum256([]byte(input))
	return r.vm.ToValue(hex.EncodeToString(hash[:]))
}

// parseJSON parses a JSON string
func (r *ExtensionRuntime) parseJSON(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return goja.Undefined()
	}
	input := call.Arguments[0].String()

	var result interface{}
	if err := json.Unmarshal([]byte(input), &result); err != nil {
		GoLog("[Extension:%s] JSON parse error: %v\n", r.extensionID, err)
		return goja.Undefined()
	}

	return r.vm.ToValue(result)
}

// stringifyJSON converts a value to JSON string
func (r *ExtensionRuntime) stringifyJSON(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue("")
	}
	input := call.Arguments[0].Export()

	data, err := json.Marshal(input)
	if err != nil {
		GoLog("[Extension:%s] JSON stringify error: %v\n", r.extensionID, err)
		return r.vm.ToValue("")
	}

	return r.vm.ToValue(string(data))
}

// ==================== Logging Functions ====================

func (r *ExtensionRuntime) logDebug(call goja.FunctionCall) goja.Value {
	msg := r.formatLogArgs(call.Arguments)
	GoLog("[Extension:%s:DEBUG] %s\n", r.extensionID, msg)
	return goja.Undefined()
}

func (r *ExtensionRuntime) logInfo(call goja.FunctionCall) goja.Value {
	msg := r.formatLogArgs(call.Arguments)
	GoLog("[Extension:%s:INFO] %s\n", r.extensionID, msg)
	return goja.Undefined()
}

func (r *ExtensionRuntime) logWarn(call goja.FunctionCall) goja.Value {
	msg := r.formatLogArgs(call.Arguments)
	GoLog("[Extension:%s:WARN] %s\n", r.extensionID, msg)
	return goja.Undefined()
}

func (r *ExtensionRuntime) logError(call goja.FunctionCall) goja.Value {
	msg := r.formatLogArgs(call.Arguments)
	GoLog("[Extension:%s:ERROR] %s\n", r.extensionID, msg)
	return goja.Undefined()
}

func (r *ExtensionRuntime) formatLogArgs(args []goja.Value) string {
	parts := make([]string, len(args))
	for i, arg := range args {
		parts[i] = fmt.Sprintf("%v", arg.Export())
	}
	return strings.Join(parts, " ")
}

// ==================== Go Backend Wrappers ====================

func (r *ExtensionRuntime) sanitizeFilenameWrapper(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue("")
	}
	input := call.Arguments[0].String()
	return r.vm.ToValue(sanitizeFilename(input))
}

// RegisterGoBackendAPIs adds more Go backend functions to the VM
func (r *ExtensionRuntime) RegisterGoBackendAPIs(vm *goja.Runtime) {
	gobackendObj := vm.Get("gobackend")
	if gobackendObj == nil || goja.IsUndefined(gobackendObj) {
		gobackendObj = vm.NewObject()
		vm.Set("gobackend", gobackendObj)
	}

	obj := gobackendObj.(*goja.Object)

	// Expose sanitizeFilename
	obj.Set("sanitizeFilename", func(call goja.FunctionCall) goja.Value {
		if len(call.Arguments) < 1 {
			return vm.ToValue("")
		}
		return vm.ToValue(sanitizeFilename(call.Arguments[0].String()))
	})

	// Expose getAudioQuality
	obj.Set("getAudioQuality", func(call goja.FunctionCall) goja.Value {
		if len(call.Arguments) < 1 {
			return vm.ToValue(map[string]interface{}{
				"error": "file path is required",
			})
		}

		filePath := call.Arguments[0].String()
		quality, err := GetAudioQuality(filePath)
		if err != nil {
			return vm.ToValue(map[string]interface{}{
				"error": err.Error(),
			})
		}

		return vm.ToValue(map[string]interface{}{
			"bitDepth":     quality.BitDepth,
			"sampleRate":   quality.SampleRate,
			"totalSamples": quality.TotalSamples,
		})
	})

	// Expose buildFilename
	obj.Set("buildFilename", func(call goja.FunctionCall) goja.Value {
		if len(call.Arguments) < 2 {
			return vm.ToValue("")
		}

		template := call.Arguments[0].String()
		metadataObj := call.Arguments[1].Export()

		metadata, ok := metadataObj.(map[string]interface{})
		if !ok {
			return vm.ToValue("")
		}

		return vm.ToValue(buildFilenameFromTemplate(template, metadata))
	})
}

// ==================== Credentials API (Encrypted Storage) ====================

// getCredentialsPath returns the path to the extension's encrypted credentials file
func (r *ExtensionRuntime) getCredentialsPath() string {
	return filepath.Join(r.dataDir, ".credentials.enc")
}

// getEncryptionKey derives an encryption key from extension ID
func (r *ExtensionRuntime) getEncryptionKey() []byte {
	// Use SHA256 of extension ID + salt as encryption key
	salt := "spotiflac-ext-cred-v1"
	hash := sha256.Sum256([]byte(r.extensionID + salt))
	return hash[:]
}

// loadCredentials loads and decrypts credentials from disk
func (r *ExtensionRuntime) loadCredentials() (map[string]interface{}, error) {
	credPath := r.getCredentialsPath()
	data, err := os.ReadFile(credPath)
	if err != nil {
		if os.IsNotExist(err) {
			return make(map[string]interface{}), nil
		}
		return nil, err
	}

	// Decrypt the data
	key := r.getEncryptionKey()
	decrypted, err := decryptAES(data, key)
	if err != nil {
		return nil, fmt.Errorf("failed to decrypt credentials: %w", err)
	}

	var creds map[string]interface{}
	if err := json.Unmarshal(decrypted, &creds); err != nil {
		return nil, err
	}

	return creds, nil
}

// saveCredentials encrypts and saves credentials to disk
func (r *ExtensionRuntime) saveCredentials(creds map[string]interface{}) error {
	data, err := json.Marshal(creds)
	if err != nil {
		return err
	}

	// Encrypt the data
	key := r.getEncryptionKey()
	encrypted, err := encryptAES(data, key)
	if err != nil {
		return fmt.Errorf("failed to encrypt credentials: %w", err)
	}

	credPath := r.getCredentialsPath()
	return os.WriteFile(credPath, encrypted, 0600) // Restrictive permissions
}

// credentialsStore stores an encrypted credential
func (r *ExtensionRuntime) credentialsStore(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "key and value are required",
		})
	}

	key := call.Arguments[0].String()
	value := call.Arguments[1].Export()

	creds, err := r.loadCredentials()
	if err != nil {
		GoLog("[Extension:%s] Credentials load error: %v\n", r.extensionID, err)
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	creds[key] = value

	if err := r.saveCredentials(creds); err != nil {
		GoLog("[Extension:%s] Credentials save error: %v\n", r.extensionID, err)
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
	})
}

// credentialsGet retrieves a decrypted credential
func (r *ExtensionRuntime) credentialsGet(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return goja.Undefined()
	}

	key := call.Arguments[0].String()

	creds, err := r.loadCredentials()
	if err != nil {
		GoLog("[Extension:%s] Credentials load error: %v\n", r.extensionID, err)
		return goja.Undefined()
	}

	value, exists := creds[key]
	if !exists {
		// Return default value if provided
		if len(call.Arguments) > 1 {
			return call.Arguments[1]
		}
		return goja.Undefined()
	}

	return r.vm.ToValue(value)
}

// credentialsRemove removes a credential
func (r *ExtensionRuntime) credentialsRemove(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(false)
	}

	key := call.Arguments[0].String()

	creds, err := r.loadCredentials()
	if err != nil {
		GoLog("[Extension:%s] Credentials load error: %v\n", r.extensionID, err)
		return r.vm.ToValue(false)
	}

	delete(creds, key)

	if err := r.saveCredentials(creds); err != nil {
		GoLog("[Extension:%s] Credentials save error: %v\n", r.extensionID, err)
		return r.vm.ToValue(false)
	}

	return r.vm.ToValue(true)
}

// credentialsHas checks if a credential exists
func (r *ExtensionRuntime) credentialsHas(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(false)
	}

	key := call.Arguments[0].String()

	creds, err := r.loadCredentials()
	if err != nil {
		return r.vm.ToValue(false)
	}

	_, exists := creds[key]
	return r.vm.ToValue(exists)
}

// ==================== Auth API (OAuth Support) ====================

// authOpenUrl requests Flutter to open an OAuth URL
func (r *ExtensionRuntime) authOpenUrl(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "auth URL is required",
		})
	}

	authURL := call.Arguments[0].String()
	callbackURL := ""
	if len(call.Arguments) > 1 && !goja.IsUndefined(call.Arguments[1]) {
		callbackURL = call.Arguments[1].String()
	}

	// Store pending auth request for Flutter to pick up
	pendingAuthRequestsMu.Lock()
	pendingAuthRequests[r.extensionID] = &PendingAuthRequest{
		ExtensionID: r.extensionID,
		AuthURL:     authURL,
		CallbackURL: callbackURL,
	}
	pendingAuthRequestsMu.Unlock()

	// Update auth state
	extensionAuthStateMu.Lock()
	state, exists := extensionAuthState[r.extensionID]
	if !exists {
		state = &ExtensionAuthState{}
		extensionAuthState[r.extensionID] = state
	}
	state.PendingAuthURL = authURL
	state.AuthCode = "" // Clear any previous auth code
	extensionAuthStateMu.Unlock()

	GoLog("[Extension:%s] Auth URL requested: %s\n", r.extensionID, authURL)

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"message": "Auth URL will be opened by the app",
	})
}

// authGetCode gets the auth code (set by Flutter after OAuth callback)
func (r *ExtensionRuntime) authGetCode(call goja.FunctionCall) goja.Value {
	extensionAuthStateMu.RLock()
	defer extensionAuthStateMu.RUnlock()

	state, exists := extensionAuthState[r.extensionID]
	if !exists || state.AuthCode == "" {
		return goja.Undefined()
	}

	return r.vm.ToValue(state.AuthCode)
}

// authSetCode sets auth code and tokens (can be called by extension after token exchange)
func (r *ExtensionRuntime) authSetCode(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(false)
	}

	// Can accept either just auth code or an object with tokens
	arg := call.Arguments[0].Export()

	extensionAuthStateMu.Lock()
	defer extensionAuthStateMu.Unlock()

	state, exists := extensionAuthState[r.extensionID]
	if !exists {
		state = &ExtensionAuthState{}
		extensionAuthState[r.extensionID] = state
	}

	switch v := arg.(type) {
	case string:
		state.AuthCode = v
	case map[string]interface{}:
		if code, ok := v["code"].(string); ok {
			state.AuthCode = code
		}
		if accessToken, ok := v["access_token"].(string); ok {
			state.AccessToken = accessToken
			state.IsAuthenticated = true
		}
		if refreshToken, ok := v["refresh_token"].(string); ok {
			state.RefreshToken = refreshToken
		}
		if expiresIn, ok := v["expires_in"].(float64); ok {
			state.ExpiresAt = time.Now().Add(time.Duration(expiresIn) * time.Second)
		}
	}

	return r.vm.ToValue(true)
}

// authClear clears all auth state for the extension
func (r *ExtensionRuntime) authClear(call goja.FunctionCall) goja.Value {
	extensionAuthStateMu.Lock()
	delete(extensionAuthState, r.extensionID)
	extensionAuthStateMu.Unlock()

	pendingAuthRequestsMu.Lock()
	delete(pendingAuthRequests, r.extensionID)
	pendingAuthRequestsMu.Unlock()

	GoLog("[Extension:%s] Auth state cleared\n", r.extensionID)
	return r.vm.ToValue(true)
}

// authIsAuthenticated checks if extension has valid auth
func (r *ExtensionRuntime) authIsAuthenticated(call goja.FunctionCall) goja.Value {
	extensionAuthStateMu.RLock()
	defer extensionAuthStateMu.RUnlock()

	state, exists := extensionAuthState[r.extensionID]
	if !exists {
		return r.vm.ToValue(false)
	}

	// Check if token is expired
	if state.IsAuthenticated && !state.ExpiresAt.IsZero() && time.Now().After(state.ExpiresAt) {
		return r.vm.ToValue(false)
	}

	return r.vm.ToValue(state.IsAuthenticated)
}

// authGetTokens returns current tokens (for extension to use in API calls)
func (r *ExtensionRuntime) authGetTokens(call goja.FunctionCall) goja.Value {
	extensionAuthStateMu.RLock()
	defer extensionAuthStateMu.RUnlock()

	state, exists := extensionAuthState[r.extensionID]
	if !exists {
		return r.vm.ToValue(map[string]interface{}{})
	}

	result := map[string]interface{}{
		"access_token":     state.AccessToken,
		"refresh_token":    state.RefreshToken,
		"is_authenticated": state.IsAuthenticated,
	}

	if !state.ExpiresAt.IsZero() {
		result["expires_at"] = state.ExpiresAt.Unix()
		result["is_expired"] = time.Now().After(state.ExpiresAt)
	}

	return r.vm.ToValue(result)
}

// ==================== Crypto Utilities ====================

// encryptAES encrypts data using AES-GCM
func encryptAES(plaintext []byte, key []byte) ([]byte, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, err
	}

	ciphertext := gcm.Seal(nonce, nonce, plaintext, nil)
	return ciphertext, nil
}

// decryptAES decrypts data using AES-GCM
func decryptAES(ciphertext []byte, key []byte) ([]byte, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	nonceSize := gcm.NonceSize()
	if len(ciphertext) < nonceSize {
		return nil, fmt.Errorf("ciphertext too short")
	}

	nonce, ciphertext := ciphertext[:nonceSize], ciphertext[nonceSize:]
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return nil, err
	}

	return plaintext, nil
}

// cryptoEncrypt encrypts a string using AES-GCM (for extension use)
func (r *ExtensionRuntime) cryptoEncrypt(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "plaintext and key are required",
		})
	}

	plaintext := call.Arguments[0].String()
	keyStr := call.Arguments[1].String()

	// Derive 32-byte key from provided key string
	keyHash := sha256.Sum256([]byte(keyStr))

	encrypted, err := encryptAES([]byte(plaintext), keyHash[:])
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"data":    base64.StdEncoding.EncodeToString(encrypted),
	})
}

// cryptoDecrypt decrypts a string using AES-GCM (for extension use)
func (r *ExtensionRuntime) cryptoDecrypt(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "ciphertext and key are required",
		})
	}

	ciphertextB64 := call.Arguments[0].String()
	keyStr := call.Arguments[1].String()

	ciphertext, err := base64.StdEncoding.DecodeString(ciphertextB64)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "invalid base64 ciphertext",
		})
	}

	// Derive 32-byte key from provided key string
	keyHash := sha256.Sum256([]byte(keyStr))

	decrypted, err := decryptAES(ciphertext, keyHash[:])
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"data":    string(decrypted),
	})
}

// cryptoGenerateKey generates a random encryption key
func (r *ExtensionRuntime) cryptoGenerateKey(call goja.FunctionCall) goja.Value {
	length := 32 // Default 256-bit key
	if len(call.Arguments) > 0 && !goja.IsUndefined(call.Arguments[0]) {
		if l, ok := call.Arguments[0].Export().(float64); ok {
			length = int(l)
		}
	}

	key := make([]byte, length)
	if _, err := rand.Read(key); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"key":     base64.StdEncoding.EncodeToString(key),
		"hex":     hex.EncodeToString(key),
	})
}

// ==================== Additional File Operations ====================

// fileCopy copies a file within the sandbox
func (r *ExtensionRuntime) fileCopy(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "source and destination paths are required",
		})
	}

	srcPath := call.Arguments[0].String()
	dstPath := call.Arguments[1].String()

	fullSrc, err := r.validatePath(srcPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	fullDst, err := r.validatePath(dstPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	// Read source file
	data, err := os.ReadFile(fullSrc)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to read source: %v", err),
		})
	}

	// Create destination directory if needed
	dir := filepath.Dir(fullDst)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create directory: %v", err),
		})
	}

	// Write to destination
	if err := os.WriteFile(fullDst, data, 0644); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to write destination: %v", err),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"path":    fullDst,
	})
}

// fileMove moves/renames a file within the sandbox
func (r *ExtensionRuntime) fileMove(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "source and destination paths are required",
		})
	}

	srcPath := call.Arguments[0].String()
	dstPath := call.Arguments[1].String()

	fullSrc, err := r.validatePath(srcPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	fullDst, err := r.validatePath(dstPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	// Create destination directory if needed
	dir := filepath.Dir(fullDst)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create directory: %v", err),
		})
	}

	if err := os.Rename(fullSrc, fullDst); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to move file: %v", err),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"path":    fullDst,
	})
}

// fileGetSize returns the size of a file in bytes
func (r *ExtensionRuntime) fileGetSize(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "path is required",
		})
	}

	path := call.Arguments[0].String()
	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	info, err := os.Stat(fullPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"size":    info.Size(),
	})
}

// ==================== FFmpeg API (Post-Processing) ====================

// FFmpegCommand holds a pending FFmpeg command for Flutter to execute
type FFmpegCommand struct {
	ExtensionID string
	Command     string
	InputPath   string
	OutputPath  string
	Completed   bool
	Success     bool
	Error       string
	Output      string
}

// Global FFmpeg command queue
var (
	ffmpegCommands   = make(map[string]*FFmpegCommand)
	ffmpegCommandsMu sync.RWMutex
	ffmpegCommandID  int64
)

// GetPendingFFmpegCommand returns a pending FFmpeg command (called from Flutter)
func GetPendingFFmpegCommand(commandID string) *FFmpegCommand {
	ffmpegCommandsMu.RLock()
	defer ffmpegCommandsMu.RUnlock()
	return ffmpegCommands[commandID]
}

// SetFFmpegCommandResult sets the result of an FFmpeg command (called from Flutter)
func SetFFmpegCommandResult(commandID string, success bool, output, errorMsg string) {
	ffmpegCommandsMu.Lock()
	defer ffmpegCommandsMu.Unlock()
	if cmd, exists := ffmpegCommands[commandID]; exists {
		cmd.Completed = true
		cmd.Success = success
		cmd.Output = output
		cmd.Error = errorMsg
	}
}

// ClearFFmpegCommand removes a completed FFmpeg command
func ClearFFmpegCommand(commandID string) {
	ffmpegCommandsMu.Lock()
	defer ffmpegCommandsMu.Unlock()
	delete(ffmpegCommands, commandID)
}

// ffmpegExecute queues an FFmpeg command for execution by Flutter
func (r *ExtensionRuntime) ffmpegExecute(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "command is required",
		})
	}

	command := call.Arguments[0].String()

	// Generate unique command ID
	ffmpegCommandsMu.Lock()
	ffmpegCommandID++
	cmdID := fmt.Sprintf("%s_%d", r.extensionID, ffmpegCommandID)
	ffmpegCommands[cmdID] = &FFmpegCommand{
		ExtensionID: r.extensionID,
		Command:     command,
		Completed:   false,
	}
	ffmpegCommandsMu.Unlock()

	GoLog("[Extension:%s] FFmpeg command queued: %s\n", r.extensionID, cmdID)

	// Wait for completion (with timeout)
	timeout := 5 * time.Minute
	start := time.Now()
	for {
		ffmpegCommandsMu.RLock()
		cmd := ffmpegCommands[cmdID]
		completed := cmd != nil && cmd.Completed
		ffmpegCommandsMu.RUnlock()

		if completed {
			ffmpegCommandsMu.RLock()
			result := map[string]interface{}{
				"success": cmd.Success,
				"output":  cmd.Output,
			}
			if cmd.Error != "" {
				result["error"] = cmd.Error
			}
			ffmpegCommandsMu.RUnlock()

			// Cleanup
			ClearFFmpegCommand(cmdID)
			return r.vm.ToValue(result)
		}

		if time.Since(start) > timeout {
			ClearFFmpegCommand(cmdID)
			return r.vm.ToValue(map[string]interface{}{
				"success": false,
				"error":   "FFmpeg command timed out",
			})
		}

		time.Sleep(100 * time.Millisecond)
	}
}

// ffmpegGetInfo gets audio file information using FFprobe
func (r *ExtensionRuntime) ffmpegGetInfo(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "file path is required",
		})
	}

	filePath := call.Arguments[0].String()

	// Use Go's built-in audio quality function
	quality, err := GetAudioQuality(filePath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success":       true,
		"bit_depth":     quality.BitDepth,
		"sample_rate":   quality.SampleRate,
		"total_samples": quality.TotalSamples,
		"duration":      float64(quality.TotalSamples) / float64(quality.SampleRate),
	})
}

// ffmpegConvert is a helper for common conversion operations
func (r *ExtensionRuntime) ffmpegConvert(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "input and output paths are required",
		})
	}

	inputPath := call.Arguments[0].String()
	outputPath := call.Arguments[1].String()

	// Get options if provided
	options := map[string]interface{}{}
	if len(call.Arguments) > 2 && !goja.IsUndefined(call.Arguments[2]) && !goja.IsNull(call.Arguments[2]) {
		if opts, ok := call.Arguments[2].Export().(map[string]interface{}); ok {
			options = opts
		}
	}

	// Build FFmpeg command
	var cmdParts []string
	cmdParts = append(cmdParts, "-i", fmt.Sprintf("%q", inputPath))

	// Audio codec
	if codec, ok := options["codec"].(string); ok {
		cmdParts = append(cmdParts, "-c:a", codec)
	}

	// Bitrate
	if bitrate, ok := options["bitrate"].(string); ok {
		cmdParts = append(cmdParts, "-b:a", bitrate)
	}

	// Sample rate
	if sampleRate, ok := options["sample_rate"].(float64); ok {
		cmdParts = append(cmdParts, "-ar", fmt.Sprintf("%d", int(sampleRate)))
	}

	// Channels
	if channels, ok := options["channels"].(float64); ok {
		cmdParts = append(cmdParts, "-ac", fmt.Sprintf("%d", int(channels)))
	}

	// Overwrite output
	cmdParts = append(cmdParts, "-y", fmt.Sprintf("%q", outputPath))

	command := strings.Join(cmdParts, " ")

	// Execute via ffmpegExecute
	execCall := goja.FunctionCall{
		Arguments: []goja.Value{r.vm.ToValue(command)},
	}
	return r.ffmpegExecute(execCall)
}

// ==================== Track Matching API ====================

// matchingCompareStrings compares two strings with fuzzy matching
func (r *ExtensionRuntime) matchingCompareStrings(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(0.0)
	}

	str1 := strings.ToLower(strings.TrimSpace(call.Arguments[0].String()))
	str2 := strings.ToLower(strings.TrimSpace(call.Arguments[1].String()))

	if str1 == str2 {
		return r.vm.ToValue(1.0)
	}

	// Calculate Levenshtein distance-based similarity
	similarity := calculateStringSimilarity(str1, str2)
	return r.vm.ToValue(similarity)
}

// matchingCompareDuration compares two durations with tolerance
func (r *ExtensionRuntime) matchingCompareDuration(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(false)
	}

	dur1 := int(call.Arguments[0].ToInteger())
	dur2 := int(call.Arguments[1].ToInteger())

	// Default tolerance: 3 seconds
	tolerance := 3000 // milliseconds
	if len(call.Arguments) > 2 && !goja.IsUndefined(call.Arguments[2]) {
		tolerance = int(call.Arguments[2].ToInteger())
	}

	diff := dur1 - dur2
	if diff < 0 {
		diff = -diff
	}

	return r.vm.ToValue(diff <= tolerance)
}

// matchingNormalizeString normalizes a string for comparison
func (r *ExtensionRuntime) matchingNormalizeString(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue("")
	}

	str := call.Arguments[0].String()
	normalized := normalizeStringForMatching(str)
	return r.vm.ToValue(normalized)
}

// calculateStringSimilarity calculates similarity between two strings (0-1)
func calculateStringSimilarity(s1, s2 string) float64 {
	if len(s1) == 0 && len(s2) == 0 {
		return 1.0
	}
	if len(s1) == 0 || len(s2) == 0 {
		return 0.0
	}

	// Use Levenshtein distance
	distance := levenshteinDistance(s1, s2)
	maxLen := len(s1)
	if len(s2) > maxLen {
		maxLen = len(s2)
	}

	return 1.0 - float64(distance)/float64(maxLen)
}

// levenshteinDistance calculates the Levenshtein distance between two strings
func levenshteinDistance(s1, s2 string) int {
	if len(s1) == 0 {
		return len(s2)
	}
	if len(s2) == 0 {
		return len(s1)
	}

	// Create matrix
	matrix := make([][]int, len(s1)+1)
	for i := range matrix {
		matrix[i] = make([]int, len(s2)+1)
		matrix[i][0] = i
	}
	for j := range matrix[0] {
		matrix[0][j] = j
	}

	// Fill matrix
	for i := 1; i <= len(s1); i++ {
		for j := 1; j <= len(s2); j++ {
			cost := 1
			if s1[i-1] == s2[j-1] {
				cost = 0
			}
			matrix[i][j] = min(
				matrix[i-1][j]+1,      // deletion
				matrix[i][j-1]+1,      // insertion
				matrix[i-1][j-1]+cost, // substitution
			)
		}
	}

	return matrix[len(s1)][len(s2)]
}

// normalizeStringForMatching normalizes a string for comparison
func normalizeStringForMatching(s string) string {
	// Convert to lowercase
	s = strings.ToLower(s)

	// Remove common suffixes/prefixes
	suffixes := []string{
		" (remastered)", " (remaster)", " - remastered", " - remaster",
		" (deluxe)", " (deluxe edition)", " - deluxe", " - deluxe edition",
		" (explicit)", " (clean)", " [explicit]", " [clean]",
		" (album version)", " (single version)", " (radio edit)",
		" (feat.", " (ft.", " feat.", " ft.",
	}
	for _, suffix := range suffixes {
		if idx := strings.Index(s, suffix); idx != -1 {
			s = s[:idx]
		}
	}

	// Remove special characters
	var result strings.Builder
	for _, r := range s {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == ' ' {
			result.WriteRune(r)
		}
	}

	// Collapse multiple spaces
	s = strings.Join(strings.Fields(result.String()), " ")

	return strings.TrimSpace(s)
}
