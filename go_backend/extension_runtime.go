package gobackend

import (
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/dop251/goja"
)

const DefaultJSTimeout = 30 * time.Second

var (
	extensionAuthState   = make(map[string]*ExtensionAuthState)
	extensionAuthStateMu sync.RWMutex
)

type ExtensionAuthState struct {
	PendingAuthURL  string
	AuthCode        string
	AccessToken     string
	RefreshToken    string
	ExpiresAt       time.Time
	IsAuthenticated bool
	PKCEVerifier    string
	PKCEChallenge   string
}

type PendingAuthRequest struct {
	ExtensionID string
	AuthURL     string
	CallbackURL string
}

var (
	pendingAuthRequests   = make(map[string]*PendingAuthRequest)
	pendingAuthRequestsMu sync.RWMutex
)

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

type ExtensionRuntime struct {
	extensionID string
	manifest    *ExtensionManifest
	settings    map[string]interface{}
	httpClient  *http.Client
	cookieJar   http.CookieJar
	dataDir     string
	vm          *goja.Runtime

	storageMu      sync.RWMutex
	storageCache   map[string]interface{}
	storageLoaded  bool
	storageDirty   bool
	storageClosed  bool
	storageTimer   *time.Timer
	storageWriteMu sync.Mutex

	credentialsMu     sync.RWMutex
	credentialsCache  map[string]interface{}
	credentialsLoaded bool
	storageFlushDelay time.Duration
}

type privateIPCacheEntry struct {
	isPrivate bool
	expiresAt time.Time
}

const (
	privateIPCacheTTL      = 5 * time.Minute
	privateIPErrorCacheTTL = 30 * time.Second
	maxPrivateIPCacheSize  = 1024
)

var (
	privateIPCache   = make(map[string]privateIPCacheEntry)
	privateIPCacheMu sync.RWMutex
)

func NewExtensionRuntime(ext *LoadedExtension) *ExtensionRuntime {
	jar, _ := newSimpleCookieJar()

	runtime := &ExtensionRuntime{
		extensionID:       ext.ID,
		manifest:          ext.Manifest,
		settings:          make(map[string]interface{}),
		cookieJar:         jar,
		dataDir:           ext.DataDir,
		vm:                ext.VM,
		storageFlushDelay: defaultStorageFlushDelay,
	}

	// Extension sandbox enforces HTTPS-only domains. Do not apply global
	// allow_http scheme downgrade here, because some extension APIs (e.g.
	// spotify-web) will redirect http -> https and can end up in 301 loops.
	// We still reuse sharedTransport so insecure TLS compatibility mode remains effective.
	client := &http.Client{
		Transport: sharedTransport,
		Timeout:   30 * time.Second,
		Jar:       jar,
	}
	client.CheckRedirect = func(req *http.Request, via []*http.Request) error {
		if req.URL.Scheme != "https" {
			GoLog("[Extension:%s] Redirect blocked: non-https scheme '%s'\n", ext.ID, req.URL.Scheme)
			return fmt.Errorf("redirect blocked: only https is allowed")
		}

		domain := req.URL.Hostname()
		if domain == "" {
			GoLog("[Extension:%s] Redirect blocked: missing hostname\n", ext.ID)
			return fmt.Errorf("redirect blocked: hostname is required")
		}
		if !ext.Manifest.IsDomainAllowed(domain) {
			GoLog("[Extension:%s] Redirect blocked: domain '%s' not in allowed list\n", ext.ID, domain)
			return &RedirectBlockedError{Domain: domain}
		}
		if isPrivateIP(domain) {
			GoLog("[Extension:%s] Redirect blocked: private IP '%s'\n", ext.ID, domain)
			return &RedirectBlockedError{Domain: domain, IsPrivate: true}
		}
		if len(via) >= 10 {
			return http.ErrUseLastResponse
		}
		return nil
	}
	runtime.httpClient = client

	return runtime
}

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

func isPrivateIP(host string) bool {
	hostLower := strings.ToLower(strings.TrimSpace(host))
	if hostLower == "" {
		return false
	}

	if hostLower == "localhost" || strings.HasSuffix(hostLower, ".local") {
		return true
	}

	if ip := net.ParseIP(hostLower); ip != nil {
		return isPrivateIPAddr(ip)
	}

	if cached, ok := getPrivateIPCache(hostLower); ok {
		return cached
	}

	ips, err := net.LookupIP(hostLower)
	if err != nil {
		setPrivateIPCache(hostLower, false, privateIPErrorCacheTTL)
		return false
	}

	isPrivate := false
	for _, ip := range ips {
		if isPrivateIPAddr(ip) {
			isPrivate = true
			break
		}
	}

	setPrivateIPCache(hostLower, isPrivate, privateIPCacheTTL)
	return isPrivate
}

func getPrivateIPCache(host string) (bool, bool) {
	now := time.Now()

	privateIPCacheMu.RLock()
	entry, exists := privateIPCache[host]
	privateIPCacheMu.RUnlock()
	if !exists {
		return false, false
	}

	if now.Before(entry.expiresAt) {
		return entry.isPrivate, true
	}

	privateIPCacheMu.Lock()
	delete(privateIPCache, host)
	privateIPCacheMu.Unlock()
	return false, false
}

func setPrivateIPCache(host string, isPrivate bool, ttl time.Duration) {
	expiresAt := time.Now().Add(ttl)

	privateIPCacheMu.Lock()
	if len(privateIPCache) >= maxPrivateIPCacheSize {
		now := time.Now()
		for key, entry := range privateIPCache {
			if now.After(entry.expiresAt) {
				delete(privateIPCache, key)
			}
		}
		if len(privateIPCache) >= maxPrivateIPCacheSize {
			privateIPCache = make(map[string]privateIPCacheEntry)
		}
	}
	privateIPCache[host] = privateIPCacheEntry{
		isPrivate: isPrivate,
		expiresAt: expiresAt,
	}
	privateIPCacheMu.Unlock()
}

func isPrivateIPAddr(ip net.IP) bool {
	if ip == nil {
		return false
	}
	if ip.IsLoopback() ||
		ip.IsPrivate() ||
		ip.IsLinkLocalUnicast() ||
		ip.IsLinkLocalMulticast() ||
		ip.IsMulticast() ||
		ip.IsUnspecified() {
		return true
	}
	if !ip.IsGlobalUnicast() {
		return true
	}
	return false
}

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

func (r *ExtensionRuntime) SetSettings(settings map[string]interface{}) {
	r.settings = settings
}

func (r *ExtensionRuntime) RegisterAPIs(vm *goja.Runtime) {
	r.vm = vm

	httpObj := vm.NewObject()
	httpObj.Set("get", r.httpGet)
	httpObj.Set("post", r.httpPost)
	httpObj.Set("put", r.httpPut)
	httpObj.Set("delete", r.httpDelete)
	httpObj.Set("patch", r.httpPatch)
	httpObj.Set("request", r.httpRequest)
	httpObj.Set("clearCookies", r.httpClearCookies)
	vm.Set("http", httpObj)

	storageObj := vm.NewObject()
	storageObj.Set("get", r.storageGet)
	storageObj.Set("set", r.storageSet)
	storageObj.Set("remove", r.storageRemove)
	vm.Set("storage", storageObj)

	credentialsObj := vm.NewObject()
	credentialsObj.Set("store", r.credentialsStore)
	credentialsObj.Set("get", r.credentialsGet)
	credentialsObj.Set("remove", r.credentialsRemove)
	credentialsObj.Set("has", r.credentialsHas)
	vm.Set("credentials", credentialsObj)

	authObj := vm.NewObject()
	authObj.Set("openAuthUrl", r.authOpenUrl)
	authObj.Set("getAuthCode", r.authGetCode)
	authObj.Set("setAuthCode", r.authSetCode)
	authObj.Set("clearAuth", r.authClear)
	authObj.Set("isAuthenticated", r.authIsAuthenticated)
	authObj.Set("getTokens", r.authGetTokens)
	authObj.Set("generatePKCE", r.authGeneratePKCE)
	authObj.Set("getPKCE", r.authGetPKCE)
	authObj.Set("startOAuthWithPKCE", r.authStartOAuthWithPKCE)
	authObj.Set("exchangeCodeWithPKCE", r.authExchangeCodeWithPKCE)
	vm.Set("auth", authObj)

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

	ffmpegObj := vm.NewObject()
	ffmpegObj.Set("execute", r.ffmpegExecute)
	ffmpegObj.Set("getInfo", r.ffmpegGetInfo)
	ffmpegObj.Set("convert", r.ffmpegConvert)
	vm.Set("ffmpeg", ffmpegObj)

	matchingObj := vm.NewObject()
	matchingObj.Set("compareStrings", r.matchingCompareStrings)
	matchingObj.Set("compareDuration", r.matchingCompareDuration)
	matchingObj.Set("normalizeString", r.matchingNormalizeString)
	vm.Set("matching", matchingObj)

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
	utilsObj.Set("encrypt", r.cryptoEncrypt)
	utilsObj.Set("decrypt", r.cryptoDecrypt)
	utilsObj.Set("generateKey", r.cryptoGenerateKey)
	utilsObj.Set("randomUserAgent", r.randomUserAgent)
	vm.Set("utils", utilsObj)

	logObj := vm.NewObject()
	logObj.Set("debug", r.logDebug)
	logObj.Set("info", r.logInfo)
	logObj.Set("warn", r.logWarn)
	logObj.Set("error", r.logError)
	vm.Set("log", logObj)

	gobackendObj := vm.NewObject()
	gobackendObj.Set("sanitizeFilename", r.sanitizeFilenameWrapper)
	vm.Set("gobackend", gobackendObj)

	vm.Set("fetch", r.fetchPolyfill)

	vm.Set("atob", r.atobPolyfill)
	vm.Set("btoa", r.btoaPolyfill)

	r.registerTextEncoderDecoder(vm)

	r.registerURLClass(vm)

	r.registerJSONGlobal(vm)
}
