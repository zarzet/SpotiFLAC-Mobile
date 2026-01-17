// Package gobackend provides extension runtime with sandboxed execution
package gobackend

import (
	"net/http"
	"net/url"
	"sync"
	"time"

	"github.com/dop251/goja"
)

const DefaultJSTimeout = 30 * time.Second

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
	// PKCE support
	PKCEVerifier  string
	PKCEChallenge string
}

// PendingAuthRequest holds a pending OAuth request that needs Flutter to open URL
type PendingAuthRequest struct {
	ExtensionID string
	AuthURL     string
	CallbackURL string
}

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
	cookieJar   http.CookieJar
	dataDir     string
	vm          *goja.Runtime
}

// NewExtensionRuntime creates a new runtime for an extension
func NewExtensionRuntime(ext *LoadedExtension) *ExtensionRuntime {
	jar, _ := newSimpleCookieJar()

	runtime := &ExtensionRuntime{
		extensionID: ext.ID,
		manifest:    ext.Manifest,
		settings:    make(map[string]interface{}),
		cookieJar:   jar,
		dataDir:     ext.DataDir,
		vm:          ext.VM,
	}

	// Create HTTP client with redirect validation to prevent SSRF via open redirect
	client := &http.Client{
		Timeout: 30 * time.Second,
		Jar:     jar,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			// Validate redirect target domain against allowed domains
			domain := req.URL.Hostname()
			if !ext.Manifest.IsDomainAllowed(domain) {
				GoLog("[Extension:%s] Redirect blocked: domain '%s' not in allowed list\n", ext.ID, domain)
				return &RedirectBlockedError{Domain: domain}
			}
			// Also block redirects to private/local networks (SSRF protection)
			if isPrivateIP(domain) {
				GoLog("[Extension:%s] Redirect blocked: private IP '%s'\n", ext.ID, domain)
				return &RedirectBlockedError{Domain: domain, IsPrivate: true}
			}
			// Default redirect limit (10)
			if len(via) >= 10 {
				return http.ErrUseLastResponse
			}
			return nil
		},
	}
	runtime.httpClient = client

	return runtime
}

// RedirectBlockedError is returned when a redirect is blocked due to domain validation
type RedirectBlockedError struct {
	Domain    string
	IsPrivate bool
}

func (e *RedirectBlockedError) Error() string {
	if e.IsPrivate {
		return "redirect blocked: private/local network access denied"
	}
	return "redirect blocked: domain '" + e.Domain + "' not in allowed list"
}

// isPrivateIP checks if a hostname resolves to a private/local IP address
func isPrivateIP(host string) bool {
	// Block common private network patterns
	// This is a simple check - for production, consider DNS resolution
	privatePatterns := []string{
		"localhost",
		"127.",
		"10.",
		"172.16.", "172.17.", "172.18.", "172.19.",
		"172.20.", "172.21.", "172.22.", "172.23.",
		"172.24.", "172.25.", "172.26.", "172.27.",
		"172.28.", "172.29.", "172.30.", "172.31.",
		"192.168.",
		"169.254.", // Link-local
		"::1",      // IPv6 localhost
		"fc00:",    // IPv6 private
		"fe80:",    // IPv6 link-local
	}

	hostLower := host
	for _, pattern := range privatePatterns {
		if hostLower == pattern || len(hostLower) > len(pattern) && hostLower[:len(pattern)] == pattern {
			return true
		}
	}

	// Also block .local domains
	if len(host) > 6 && host[len(host)-6:] == ".local" {
		return true
	}

	return false
}

// simpleCookieJar is a simple in-memory cookie jar
type simpleCookieJar struct {
	cookies map[string][]*http.Cookie
	mu      sync.RWMutex
}

func newSimpleCookieJar() (*simpleCookieJar, error) {
	return &simpleCookieJar{
		cookies: make(map[string][]*http.Cookie),
	}, nil
}

func (j *simpleCookieJar) SetCookies(u *url.URL, cookies []*http.Cookie) {
	j.mu.Lock()
	defer j.mu.Unlock()
	key := u.Host
	j.cookies[key] = append(j.cookies[key], cookies...)
}

func (j *simpleCookieJar) Cookies(u *url.URL) []*http.Cookie {
	j.mu.RLock()
	defer j.mu.RUnlock()
	return j.cookies[u.Host]
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
	httpObj.Set("put", r.httpPut)
	httpObj.Set("delete", r.httpDelete)
	httpObj.Set("patch", r.httpPatch)
	httpObj.Set("request", r.httpRequest) // Generic HTTP request (GET, POST, PUT, DELETE, etc.)
	httpObj.Set("clearCookies", r.httpClearCookies)
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
	// PKCE support
	authObj.Set("generatePKCE", r.authGeneratePKCE)
	authObj.Set("getPKCE", r.authGetPKCE)
	authObj.Set("startOAuthWithPKCE", r.authStartOAuthWithPKCE)
	authObj.Set("exchangeCodeWithPKCE", r.authExchangeCodeWithPKCE)
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
	utilsObj.Set("hmacSHA256", r.hmacSHA256)
	utilsObj.Set("hmacSHA256Base64", r.hmacSHA256Base64)
	utilsObj.Set("hmacSHA1", r.hmacSHA1)
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

	// ==================== Browser-like Polyfills ====================
	// These make porting browser/Node.js libraries easier

	// Global fetch() - Promise-style HTTP API (browser-compatible)
	vm.Set("fetch", r.fetchPolyfill)

	// Global atob/btoa - Base64 encoding (browser-compatible)
	vm.Set("atob", r.atobPolyfill)
	vm.Set("btoa", r.btoaPolyfill)

	// TextEncoder/TextDecoder constructors
	r.registerTextEncoderDecoder(vm)

	// URL class for URL parsing
	r.registerURLClass(vm)

	// JSON global (browser-compatible)
	r.registerJSONGlobal(vm)
}
