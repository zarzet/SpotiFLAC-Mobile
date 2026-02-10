// Package gobackend provides HTTP API for extension runtime
package gobackend

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/dop251/goja"
)

// ==================== HTTP API (Sandboxed) ====================

type HTTPResponse struct {
	StatusCode int               `json:"statusCode"`
	Body       string            `json:"body"`
	Headers    map[string]string `json:"headers"`
}

func (r *ExtensionRuntime) validateDomain(urlStr string) error {
	parsed, err := url.Parse(urlStr)
	if err != nil {
		return fmt.Errorf("invalid URL: %w", err)
	}

	if parsed.Scheme == "" {
		return fmt.Errorf("invalid URL: scheme is required")
	}
	if parsed.Scheme != "https" {
		return fmt.Errorf("network access denied: only https is allowed")
	}
	if parsed.User != nil {
		return fmt.Errorf("invalid URL: embedded credentials are not allowed")
	}

	domain := parsed.Hostname()
	if domain == "" {
		return fmt.Errorf("invalid URL: hostname is required")
	}

	if isPrivateIP(domain) {
		return fmt.Errorf("network access denied: private/local network '%s' not allowed", domain)
	}

	if !r.manifest.IsDomainAllowed(domain) {
		return fmt.Errorf("network access denied: domain '%s' not in allowed list", domain)
	}

	return nil
}

func (r *ExtensionRuntime) httpGet(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"error": "URL is required",
		})
	}

	urlStr := call.Arguments[0].String()

	if err := r.validateDomain(urlStr); err != nil {
		GoLog("[Extension:%s] HTTP blocked: %v\n", r.extensionID, err)
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	headers := make(map[string]string)
	if len(call.Arguments) > 1 && !goja.IsUndefined(call.Arguments[1]) && !goja.IsNull(call.Arguments[1]) {
		headersObj := call.Arguments[1].Export()
		if h, ok := headersObj.(map[string]interface{}); ok {
			for k, v := range h {
				headers[k] = fmt.Sprintf("%v", v)
			}
		}
	}

	req, err := http.NewRequest("GET", urlStr, nil)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	for k, v := range headers {
		req.Header.Set(k, v)
	}

	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", "Spotiflac-Extension/1.0")
	}

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	respHeaders := make(map[string]interface{})
	for k, v := range resp.Header {
		if len(v) == 1 {
			respHeaders[k] = v[0]
		} else {
			respHeaders[k] = v
		}
	}

	return r.vm.ToValue(map[string]interface{}{
		"statusCode": resp.StatusCode,
		"status":     resp.StatusCode,
		"ok":         resp.StatusCode >= 200 && resp.StatusCode < 300,
		"body":       string(body),
		"headers":    respHeaders,
	})
}

func (r *ExtensionRuntime) httpPost(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"error": "URL is required",
		})
	}

	urlStr := call.Arguments[0].String()

	if err := r.validateDomain(urlStr); err != nil {
		GoLog("[Extension:%s] HTTP blocked: %v\n", r.extensionID, err)
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	var bodyStr string
	if len(call.Arguments) > 1 && !goja.IsUndefined(call.Arguments[1]) && !goja.IsNull(call.Arguments[1]) {
		bodyArg := call.Arguments[1].Export()
		switch v := bodyArg.(type) {
		case string:
			bodyStr = v
		case map[string]interface{}, []interface{}:
			jsonBytes, err := json.Marshal(v)
			if err != nil {
				return r.vm.ToValue(map[string]interface{}{
					"error": fmt.Sprintf("failed to stringify body: %v", err),
				})
			}
			bodyStr = string(jsonBytes)
		default:
			bodyStr = call.Arguments[1].String()
		}
	}

	headers := make(map[string]string)
	if len(call.Arguments) > 2 && !goja.IsUndefined(call.Arguments[2]) && !goja.IsNull(call.Arguments[2]) {
		headersObj := call.Arguments[2].Export()
		if h, ok := headersObj.(map[string]interface{}); ok {
			for k, v := range h {
				headers[k] = fmt.Sprintf("%v", v)
			}
		}
	}

	req, err := http.NewRequest("POST", urlStr, strings.NewReader(bodyStr))
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	for k, v := range headers {
		req.Header.Set(k, v)
	}

	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", "Spotiflac-Extension/1.0")
	}
	if req.Header.Get("Content-Type") == "" {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	respHeaders := make(map[string]interface{})
	for k, v := range resp.Header {
		if len(v) == 1 {
			respHeaders[k] = v[0]
		} else {
			respHeaders[k] = v
		}
	}

	return r.vm.ToValue(map[string]interface{}{
		"statusCode": resp.StatusCode,
		"status":     resp.StatusCode,
		"ok":         resp.StatusCode >= 200 && resp.StatusCode < 300,
		"body":       string(body),
		"headers":    respHeaders,
	})
}

func (r *ExtensionRuntime) httpRequest(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"error": "URL is required",
		})
	}

	urlStr := call.Arguments[0].String()

	if err := r.validateDomain(urlStr); err != nil {
		GoLog("[Extension:%s] HTTP blocked: %v\n", r.extensionID, err)
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	method := "GET"
	var bodyStr string
	headers := make(map[string]string)

	if len(call.Arguments) > 1 && !goja.IsUndefined(call.Arguments[1]) && !goja.IsNull(call.Arguments[1]) {
		optionsObj := call.Arguments[1].Export()
		if opts, ok := optionsObj.(map[string]interface{}); ok {
			if m, ok := opts["method"].(string); ok {
				method = strings.ToUpper(m)
			}

			if bodyArg, ok := opts["body"]; ok && bodyArg != nil {
				switch v := bodyArg.(type) {
				case string:
					bodyStr = v
				case map[string]interface{}, []interface{}:
					jsonBytes, err := json.Marshal(v)
					if err != nil {
						return r.vm.ToValue(map[string]interface{}{
							"error": fmt.Sprintf("failed to stringify body: %v", err),
						})
					}
					bodyStr = string(jsonBytes)
				default:
					bodyStr = fmt.Sprintf("%v", v)
				}
			}

			if h, ok := opts["headers"].(map[string]interface{}); ok {
				for k, v := range h {
					headers[k] = fmt.Sprintf("%v", v)
				}
			}
		}
	}

	var reqBody io.Reader
	if bodyStr != "" {
		reqBody = strings.NewReader(bodyStr)
	}

	req, err := http.NewRequest(method, urlStr, reqBody)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	for k, v := range headers {
		req.Header.Set(k, v)
	}

	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", "Spotiflac-Extension/1.0")
	}
	if bodyStr != "" && req.Header.Get("Content-Type") == "" {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	respHeaders := make(map[string]interface{})
	for k, v := range resp.Header {
		if len(v) == 1 {
			respHeaders[k] = v[0]
		} else {
			respHeaders[k] = v
		}
	}

	return r.vm.ToValue(map[string]interface{}{
		"statusCode": resp.StatusCode,
		"status":     resp.StatusCode,
		"ok":         resp.StatusCode >= 200 && resp.StatusCode < 300,
		"body":       string(body),
		"headers":    respHeaders,
	})
}

func (r *ExtensionRuntime) httpPut(call goja.FunctionCall) goja.Value {
	return r.httpMethodShortcut("PUT", call)
}

func (r *ExtensionRuntime) httpDelete(call goja.FunctionCall) goja.Value {
	return r.httpMethodShortcut("DELETE", call)
}

func (r *ExtensionRuntime) httpPatch(call goja.FunctionCall) goja.Value {
	return r.httpMethodShortcut("PATCH", call)
}

func (r *ExtensionRuntime) httpMethodShortcut(method string, call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"error": "URL is required",
		})
	}

	urlStr := call.Arguments[0].String()

	if err := r.validateDomain(urlStr); err != nil {
		GoLog("[Extension:%s] HTTP blocked: %v\n", r.extensionID, err)
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	var bodyStr string
	headers := make(map[string]string)

	if method == "DELETE" {
		if len(call.Arguments) > 1 && !goja.IsUndefined(call.Arguments[1]) && !goja.IsNull(call.Arguments[1]) {
			headersObj := call.Arguments[1].Export()
			if h, ok := headersObj.(map[string]interface{}); ok {
				for k, v := range h {
					headers[k] = fmt.Sprintf("%v", v)
				}
			}
		}
	} else {
		if len(call.Arguments) > 1 && !goja.IsUndefined(call.Arguments[1]) && !goja.IsNull(call.Arguments[1]) {
			bodyArg := call.Arguments[1].Export()
			switch v := bodyArg.(type) {
			case string:
				bodyStr = v
			case map[string]interface{}, []interface{}:
				jsonBytes, err := json.Marshal(v)
				if err != nil {
					return r.vm.ToValue(map[string]interface{}{
						"error": fmt.Sprintf("failed to stringify body: %v", err),
					})
				}
				bodyStr = string(jsonBytes)
			default:
				bodyStr = call.Arguments[1].String()
			}
		}

		if len(call.Arguments) > 2 && !goja.IsUndefined(call.Arguments[2]) && !goja.IsNull(call.Arguments[2]) {
			headersObj := call.Arguments[2].Export()
			if h, ok := headersObj.(map[string]interface{}); ok {
				for k, v := range h {
					headers[k] = fmt.Sprintf("%v", v)
				}
			}
		}
	}

	var reqBody io.Reader
	if bodyStr != "" {
		reqBody = strings.NewReader(bodyStr)
	}

	req, err := http.NewRequest(method, urlStr, reqBody)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	for k, v := range headers {
		req.Header.Set(k, v)
	}
	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", "Spotiflac-Extension/1.0")
	}
	if bodyStr != "" && req.Header.Get("Content-Type") == "" {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"error": err.Error(),
		})
	}

	respHeaders := make(map[string]interface{})
	for k, v := range resp.Header {
		if len(v) == 1 {
			respHeaders[k] = v[0]
		} else {
			respHeaders[k] = v
		}
	}

	return r.vm.ToValue(map[string]interface{}{
		"statusCode": resp.StatusCode,
		"status":     resp.StatusCode,
		"ok":         resp.StatusCode >= 200 && resp.StatusCode < 300,
		"body":       string(body),
		"headers":    respHeaders,
	})
}

func (r *ExtensionRuntime) httpClearCookies(call goja.FunctionCall) goja.Value {
	if jar, ok := r.cookieJar.(*simpleCookieJar); ok {
		jar.mu.Lock()
		jar.cookies = make(map[string][]*http.Cookie)
		jar.mu.Unlock()
		GoLog("[Extension:%s] Cookies cleared\n", r.extensionID)
		return r.vm.ToValue(true)
	}
	return r.vm.ToValue(false)
}
