// Package gobackend provides Utility functions for extension runtime
package gobackend

import (
	"crypto/hmac"
	"crypto/md5"
	"crypto/rand"
	"crypto/sha1"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/dop251/goja"
)

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

// hmacSHA256 computes HMAC-SHA256 of a message with a key
func (r *ExtensionRuntime) hmacSHA256(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue("")
	}
	message := call.Arguments[0].String()
	key := call.Arguments[1].String()

	mac := hmac.New(sha256.New, []byte(key))
	mac.Write([]byte(message))
	return r.vm.ToValue(hex.EncodeToString(mac.Sum(nil)))
}

// hmacSHA256Base64 computes HMAC-SHA256 and returns base64 encoded result
func (r *ExtensionRuntime) hmacSHA256Base64(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue("")
	}
	message := call.Arguments[0].String()
	key := call.Arguments[1].String()

	mac := hmac.New(sha256.New, []byte(key))
	mac.Write([]byte(message))
	return r.vm.ToValue(base64.StdEncoding.EncodeToString(mac.Sum(nil)))
}

// hmacSHA1 computes HMAC-SHA1 of a message with a key (for TOTP)
// Arguments: message (string or array of bytes), key (string or array of bytes)
// Returns: array of bytes (for TOTP dynamic truncation)
func (r *ExtensionRuntime) hmacSHA1(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue([]byte{})
	}

	// Get key - can be string or array of bytes
	var keyBytes []byte
	keyArg := call.Arguments[0].Export()
	switch k := keyArg.(type) {
	case string:
		keyBytes = []byte(k)
	case []interface{}:
		keyBytes = make([]byte, len(k))
		for i, v := range k {
			if num, ok := v.(int64); ok {
				keyBytes[i] = byte(num)
			} else if num, ok := v.(float64); ok {
				keyBytes[i] = byte(int(num))
			}
		}
	default:
		return r.vm.ToValue([]byte{})
	}

	// Get message - can be string or array of bytes
	var msgBytes []byte
	msgArg := call.Arguments[1].Export()
	switch m := msgArg.(type) {
	case string:
		msgBytes = []byte(m)
	case []interface{}:
		msgBytes = make([]byte, len(m))
		for i, v := range m {
			if num, ok := v.(int64); ok {
				msgBytes[i] = byte(num)
			} else if num, ok := v.(float64); ok {
				msgBytes[i] = byte(int(num))
			}
		}
	default:
		return r.vm.ToValue([]byte{})
	}

	mac := hmac.New(sha1.New, keyBytes)
	mac.Write(msgBytes)
	result := mac.Sum(nil)

	// Convert to array of numbers for JavaScript
	jsArray := make([]interface{}, len(result))
	for i, b := range result {
		jsArray[i] = int(b)
	}
	return r.vm.ToValue(jsArray)
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

// ==================== Crypto Utilities for Extensions ====================

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

// randomUserAgent returns a random Chrome User-Agent string
func (r *ExtensionRuntime) randomUserAgent(call goja.FunctionCall) goja.Value {
	return r.vm.ToValue(getRandomUserAgent())
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
