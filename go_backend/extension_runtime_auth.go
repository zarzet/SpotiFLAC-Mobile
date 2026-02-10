// Package gobackend provides Auth API and PKCE support for extension runtime
package gobackend

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/dop251/goja"
)

// ==================== Auth API (OAuth Support) ====================

func validateExtensionAuthURL(urlStr string) error {
	parsed, err := url.Parse(urlStr)
	if err != nil {
		return fmt.Errorf("invalid auth URL: %w", err)
	}

	if parsed.Scheme != "https" {
		return fmt.Errorf("invalid auth URL: only https is allowed")
	}

	host := parsed.Hostname()
	if host == "" {
		return fmt.Errorf("invalid auth URL: hostname is required")
	}

	if parsed.User != nil {
		return fmt.Errorf("invalid auth URL: embedded credentials are not allowed")
	}

	if isPrivateIP(host) {
		return fmt.Errorf("invalid auth URL: private/local network is not allowed")
	}

	return nil
}

func summarizeURLForLog(urlStr string) string {
	parsed, err := url.Parse(urlStr)
	if err != nil {
		return urlStr
	}
	if parsed.Host == "" {
		return parsed.Scheme + "://"
	}
	return fmt.Sprintf("%s://%s%s", parsed.Scheme, parsed.Host, parsed.Path)
}

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

	if err := validateExtensionAuthURL(authURL); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	pendingAuthRequestsMu.Lock()
	pendingAuthRequests[r.extensionID] = &PendingAuthRequest{
		ExtensionID: r.extensionID,
		AuthURL:     authURL,
		CallbackURL: callbackURL,
	}
	pendingAuthRequestsMu.Unlock()

	extensionAuthStateMu.Lock()
	state, exists := extensionAuthState[r.extensionID]
	if !exists {
		state = &ExtensionAuthState{}
		extensionAuthState[r.extensionID] = state
	}
	state.PendingAuthURL = authURL
	state.AuthCode = ""
	extensionAuthStateMu.Unlock()

	GoLog("[Extension:%s] Auth URL requested: %s\n", r.extensionID, summarizeURLForLog(authURL))

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"message": "Auth URL will be opened by the app",
	})
}

func (r *ExtensionRuntime) authGetCode(call goja.FunctionCall) goja.Value {
	extensionAuthStateMu.RLock()
	defer extensionAuthStateMu.RUnlock()

	state, exists := extensionAuthState[r.extensionID]
	if !exists || state.AuthCode == "" {
		return goja.Undefined()
	}

	return r.vm.ToValue(state.AuthCode)
}

func (r *ExtensionRuntime) authSetCode(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(false)
	}

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

func (r *ExtensionRuntime) authIsAuthenticated(call goja.FunctionCall) goja.Value {
	extensionAuthStateMu.RLock()
	defer extensionAuthStateMu.RUnlock()

	state, exists := extensionAuthState[r.extensionID]
	if !exists {
		return r.vm.ToValue(false)
	}

	if state.IsAuthenticated && !state.ExpiresAt.IsZero() && time.Now().After(state.ExpiresAt) {
		return r.vm.ToValue(false)
	}

	return r.vm.ToValue(state.IsAuthenticated)
}

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

// ==================== PKCE Support ====================

// generatePKCEVerifier generates a cryptographically random code verifier
// Length should be between 43-128 characters (RFC 7636)
func generatePKCEVerifier(length int) (string, error) {
	if length < 43 {
		length = 43
	}
	if length > 128 {
		length = 128
	}

	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}

	verifier := base64.RawURLEncoding.EncodeToString(bytes)

	if len(verifier) > length {
		verifier = verifier[:length]
	}

	return verifier, nil
}

func generatePKCEChallenge(verifier string) string {
	hash := sha256.Sum256([]byte(verifier))
	// Base64url encode without padding (RFC 7636)
	return base64.RawURLEncoding.EncodeToString(hash[:])
}

func (r *ExtensionRuntime) authGeneratePKCE(call goja.FunctionCall) goja.Value {
	length := 64
	if len(call.Arguments) > 0 && !goja.IsUndefined(call.Arguments[0]) {
		if l, ok := call.Arguments[0].Export().(float64); ok && l >= 43 && l <= 128 {
			length = int(l)
		}
	}

	verifier, err := generatePKCEVerifier(length)
	if err != nil {
		GoLog("[Extension:%s] PKCE generation error: %v\n", r.extensionID, err)
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	challenge := generatePKCEChallenge(verifier)

	extensionAuthStateMu.Lock()
	state, exists := extensionAuthState[r.extensionID]
	if !exists {
		state = &ExtensionAuthState{}
		extensionAuthState[r.extensionID] = state
	}
	state.PKCEVerifier = verifier
	state.PKCEChallenge = challenge
	extensionAuthStateMu.Unlock()

	GoLog("[Extension:%s] PKCE generated (verifier length: %d)\n", r.extensionID, len(verifier))

	return r.vm.ToValue(map[string]interface{}{
		"verifier":  verifier,
		"challenge": challenge,
		"method":    "S256",
	})
}

func (r *ExtensionRuntime) authGetPKCE(call goja.FunctionCall) goja.Value {
	extensionAuthStateMu.RLock()
	defer extensionAuthStateMu.RUnlock()

	state, exists := extensionAuthState[r.extensionID]
	if !exists || state.PKCEVerifier == "" {
		return r.vm.ToValue(map[string]interface{}{})
	}

	return r.vm.ToValue(map[string]interface{}{
		"verifier":  state.PKCEVerifier,
		"challenge": state.PKCEChallenge,
		"method":    "S256",
	})
}

// config: { authUrl, clientId, redirectUri, scope, extraParams }
func (r *ExtensionRuntime) authStartOAuthWithPKCE(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "config object is required",
		})
	}

	configObj := call.Arguments[0].Export()
	config, ok := configObj.(map[string]interface{})
	if !ok {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "config must be an object",
		})
	}

	authURL, _ := config["authUrl"].(string)
	clientID, _ := config["clientId"].(string)
	redirectURI, _ := config["redirectUri"].(string)

	if authURL == "" || clientID == "" || redirectURI == "" {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "authUrl, clientId, and redirectUri are required",
		})
	}
	if err := validateExtensionAuthURL(authURL); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	scope, _ := config["scope"].(string)
	extraParams, _ := config["extraParams"].(map[string]interface{})

	verifier, err := generatePKCEVerifier(64)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to generate PKCE: %v", err),
		})
	}
	challenge := generatePKCEChallenge(verifier)

	extensionAuthStateMu.Lock()
	state, exists := extensionAuthState[r.extensionID]
	if !exists {
		state = &ExtensionAuthState{}
		extensionAuthState[r.extensionID] = state
	}
	state.PKCEVerifier = verifier
	state.PKCEChallenge = challenge
	state.AuthCode = ""
	extensionAuthStateMu.Unlock()

	parsedURL, err := url.Parse(authURL)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("invalid authUrl: %v", err),
		})
	}

	query := parsedURL.Query()
	query.Set("client_id", clientID)
	query.Set("redirect_uri", redirectURI)
	query.Set("response_type", "code")
	query.Set("code_challenge", challenge)
	query.Set("code_challenge_method", "S256")

	if scope != "" {
		query.Set("scope", scope)
	}

	for k, v := range extraParams {
		query.Set(k, fmt.Sprintf("%v", v))
	}

	parsedURL.RawQuery = query.Encode()
	fullAuthURL := parsedURL.String()

	pendingAuthRequestsMu.Lock()
	pendingAuthRequests[r.extensionID] = &PendingAuthRequest{
		ExtensionID: r.extensionID,
		AuthURL:     fullAuthURL,
		CallbackURL: redirectURI,
	}
	pendingAuthRequestsMu.Unlock()

	GoLog("[Extension:%s] PKCE OAuth started: %s\n", r.extensionID, summarizeURLForLog(fullAuthURL))

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"authUrl": fullAuthURL,
		"pkce": map[string]interface{}{
			"verifier":  verifier,
			"challenge": challenge,
			"method":    "S256",
		},
	})
}

// authExchangeCodeWithPKCE exchanges auth code for tokens using PKCE
// config: { tokenUrl, clientId, redirectUri, code, extraParams }
// Uses the stored PKCE verifier automatically
func (r *ExtensionRuntime) authExchangeCodeWithPKCE(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "config object is required",
		})
	}

	configObj := call.Arguments[0].Export()
	config, ok := configObj.(map[string]interface{})
	if !ok {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "config must be an object",
		})
	}

	// Required fields
	tokenURL, _ := config["tokenUrl"].(string)
	clientID, _ := config["clientId"].(string)
	redirectURI, _ := config["redirectUri"].(string)
	code, _ := config["code"].(string)

	if tokenURL == "" || clientID == "" || code == "" {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "tokenUrl, clientId, and code are required",
		})
	}

	extensionAuthStateMu.RLock()
	state, exists := extensionAuthState[r.extensionID]
	var verifier string
	if exists {
		verifier = state.PKCEVerifier
	}
	extensionAuthStateMu.RUnlock()

	if verifier == "" {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "no PKCE verifier found - call generatePKCE or startOAuthWithPKCE first",
		})
	}

	if err := r.validateDomain(tokenURL); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	formData := url.Values{}
	formData.Set("grant_type", "authorization_code")
	formData.Set("client_id", clientID)
	formData.Set("code", code)
	formData.Set("code_verifier", verifier)
	if redirectURI != "" {
		formData.Set("redirect_uri", redirectURI)
	}

	if extraParams, ok := config["extraParams"].(map[string]interface{}); ok {
		for k, v := range extraParams {
			formData.Set(k, fmt.Sprintf("%v", v))
		}
	}

	req, err := http.NewRequest("POST", tokenURL, strings.NewReader(formData.Encode()))
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("User-Agent", "SpotiFLAC-Extension/1.0")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}
	bodyPreview := sanitizeSensitiveLogText(string(body))
	if len(bodyPreview) > 1000 {
		bodyPreview = bodyPreview[:1000] + "...[truncated]"
	}

	var tokenResp map[string]interface{}
	if err := json.Unmarshal(body, &tokenResp); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to parse token response: %v", err),
			"body":    bodyPreview,
		})
	}

	if errMsg, ok := tokenResp["error"].(string); ok {
		errDesc, _ := tokenResp["error_description"].(string)
		return r.vm.ToValue(map[string]interface{}{
			"success":           false,
			"error":             errMsg,
			"error_description": errDesc,
		})
	}

	accessToken, _ := tokenResp["access_token"].(string)
	refreshToken, _ := tokenResp["refresh_token"].(string)
	expiresIn, _ := tokenResp["expires_in"].(float64)

	if accessToken == "" {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "no access_token in response",
			"body":    bodyPreview,
		})
	}

	extensionAuthStateMu.Lock()
	state, exists = extensionAuthState[r.extensionID]
	if !exists {
		state = &ExtensionAuthState{}
		extensionAuthState[r.extensionID] = state
	}
	state.AccessToken = accessToken
	state.RefreshToken = refreshToken
	state.IsAuthenticated = true
	if expiresIn > 0 {
		state.ExpiresAt = time.Now().Add(time.Duration(expiresIn) * time.Second)
	}
	state.PKCEVerifier = ""
	state.PKCEChallenge = ""
	extensionAuthStateMu.Unlock()

	GoLog("[Extension:%s] PKCE token exchange successful\n", r.extensionID)

	result := map[string]interface{}{
		"success":       true,
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"token_type":    tokenResp["token_type"],
	}
	if expiresIn > 0 {
		result["expires_in"] = expiresIn
	}
	if scope, ok := tokenResp["scope"].(string); ok {
		result["scope"] = scope
	}

	return r.vm.ToValue(result)
}
