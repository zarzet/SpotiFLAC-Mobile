// Package gobackend provides Storage and Credentials API for extension runtime
package gobackend

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"reflect"
	"time"

	"github.com/dop251/goja"
)

// ==================== Storage API ====================

const (
	defaultStorageFlushDelay = 400 * time.Millisecond
	storageFlushRetryDelay   = 2 * time.Second
)

func (r *ExtensionRuntime) getStoragePath() string {
	return filepath.Join(r.dataDir, "storage.json")
}

func cloneInterfaceMap(src map[string]interface{}) map[string]interface{} {
	if len(src) == 0 {
		return make(map[string]interface{})
	}
	dst := make(map[string]interface{}, len(src))
	for k, v := range src {
		dst[k] = v
	}
	return dst
}

func (r *ExtensionRuntime) ensureStorageLoaded() error {
	r.storageMu.RLock()
	if r.storageLoaded {
		r.storageMu.RUnlock()
		return nil
	}
	r.storageMu.RUnlock()

	r.storageMu.Lock()
	defer r.storageMu.Unlock()
	if r.storageLoaded {
		return nil
	}

	storagePath := r.getStoragePath()
	data, err := os.ReadFile(storagePath)
	if err != nil {
		if os.IsNotExist(err) {
			r.storageCache = make(map[string]interface{})
			r.storageLoaded = true
			return nil
		}
		return err
	}

	var storage map[string]interface{}
	if err := json.Unmarshal(data, &storage); err != nil {
		return err
	}
	if storage == nil {
		storage = make(map[string]interface{})
	}

	r.storageCache = storage
	r.storageLoaded = true
	return nil
}

func (r *ExtensionRuntime) loadStorage() (map[string]interface{}, error) {
	if err := r.ensureStorageLoaded(); err != nil {
		return nil, err
	}

	r.storageMu.RLock()
	defer r.storageMu.RUnlock()
	return cloneInterfaceMap(r.storageCache), nil
}

func (r *ExtensionRuntime) queueStorageFlushLocked(delay time.Duration) {
	if r.storageClosed {
		return
	}
	if r.storageTimer != nil {
		return
	}
	r.storageTimer = time.AfterFunc(delay, r.flushStorageDirtyAsync)
}

func (r *ExtensionRuntime) persistStorageSnapshot(storage map[string]interface{}) error {
	data, err := json.Marshal(storage)
	if err != nil {
		return err
	}

	r.storageWriteMu.Lock()
	defer r.storageWriteMu.Unlock()

	return os.WriteFile(r.getStoragePath(), data, 0600)
}

func (r *ExtensionRuntime) flushStorageDirtyAsync() {
	if err := r.flushStorageDirty(); err != nil {
		GoLog("[Extension:%s] Storage flush error: %v\n", r.extensionID, err)
	}
}

func (r *ExtensionRuntime) flushStorageDirty() error {
	r.storageMu.Lock()
	if r.storageClosed {
		r.storageTimer = nil
		r.storageMu.Unlock()
		return nil
	}
	if !r.storageDirty {
		r.storageTimer = nil
		r.storageMu.Unlock()
		return nil
	}
	snapshot := cloneInterfaceMap(r.storageCache)
	r.storageDirty = false
	r.storageTimer = nil
	r.storageMu.Unlock()

	if err := r.persistStorageSnapshot(snapshot); err != nil {
		r.storageMu.Lock()
		r.storageDirty = true
		r.queueStorageFlushLocked(storageFlushRetryDelay)
		r.storageMu.Unlock()
		return err
	}

	return nil
}

func (r *ExtensionRuntime) flushStorageNow() error {
	r.storageMu.Lock()
	if r.storageTimer != nil {
		r.storageTimer.Stop()
		r.storageTimer = nil
	}
	if !r.storageLoaded || r.storageClosed {
		r.storageMu.Unlock()
		return nil
	}
	snapshot := cloneInterfaceMap(r.storageCache)
	r.storageDirty = false
	r.storageMu.Unlock()

	return r.persistStorageSnapshot(snapshot)
}

func (r *ExtensionRuntime) closeStorageFlusher() {
	r.storageMu.Lock()
	r.storageClosed = true
	r.storageDirty = false
	if r.storageTimer != nil {
		r.storageTimer.Stop()
		r.storageTimer = nil
	}
	r.storageMu.Unlock()
}

func (r *ExtensionRuntime) storageGet(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return goja.Undefined()
	}

	key := call.Arguments[0].String()

	if err := r.ensureStorageLoaded(); err != nil {
		GoLog("[Extension:%s] Storage load error: %v\n", r.extensionID, err)
		return goja.Undefined()
	}

	r.storageMu.RLock()
	value, exists := r.storageCache[key]
	r.storageMu.RUnlock()
	if !exists {
		if len(call.Arguments) > 1 {
			return call.Arguments[1]
		}
		return goja.Undefined()
	}

	return r.vm.ToValue(value)
}

func (r *ExtensionRuntime) storageSet(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(false)
	}

	key := call.Arguments[0].String()
	value := call.Arguments[1].Export()

	if err := r.ensureStorageLoaded(); err != nil {
		GoLog("[Extension:%s] Storage load error: %v\n", r.extensionID, err)
		return r.vm.ToValue(false)
	}

	r.storageMu.Lock()
	if r.storageClosed {
		r.storageMu.Unlock()
		return r.vm.ToValue(false)
	}
	if existing, exists := r.storageCache[key]; exists {
		if reflect.DeepEqual(existing, value) {
			r.storageMu.Unlock()
			return r.vm.ToValue(true)
		}
	}
	r.storageCache[key] = value
	r.storageDirty = true
	r.queueStorageFlushLocked(r.storageFlushDelay)
	r.storageMu.Unlock()

	return r.vm.ToValue(true)
}

func (r *ExtensionRuntime) storageRemove(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(false)
	}

	key := call.Arguments[0].String()

	if err := r.ensureStorageLoaded(); err != nil {
		GoLog("[Extension:%s] Storage load error: %v\n", r.extensionID, err)
		return r.vm.ToValue(false)
	}

	r.storageMu.Lock()
	if r.storageClosed {
		r.storageMu.Unlock()
		return r.vm.ToValue(false)
	}
	if _, exists := r.storageCache[key]; !exists {
		r.storageMu.Unlock()
		return r.vm.ToValue(true)
	}
	delete(r.storageCache, key)
	r.storageDirty = true
	r.queueStorageFlushLocked(r.storageFlushDelay)
	r.storageMu.Unlock()

	return r.vm.ToValue(true)
}

func (r *ExtensionRuntime) getCredentialsPath() string {
	return filepath.Join(r.dataDir, ".credentials.enc")
}

func (r *ExtensionRuntime) getSaltPath() string {
	return filepath.Join(r.dataDir, ".cred_salt")
}

func (r *ExtensionRuntime) getOrCreateSalt() ([]byte, error) {
	saltPath := r.getSaltPath()

	salt, err := os.ReadFile(saltPath)
	if err == nil && len(salt) == 32 {
		return salt, nil
	}

	salt = make([]byte, 32)
	if _, err := io.ReadFull(rand.Reader, salt); err != nil {
		return nil, fmt.Errorf("failed to generate salt: %w", err)
	}

	if err := os.WriteFile(saltPath, salt, 0600); err != nil {
		return nil, fmt.Errorf("failed to save salt: %w", err)
	}

	return salt, nil
}

func (r *ExtensionRuntime) getEncryptionKey() ([]byte, error) {
	salt, err := r.getOrCreateSalt()
	if err != nil {
		return nil, err
	}

	combined := append([]byte(r.extensionID), salt...)
	hash := sha256.Sum256(combined)
	return hash[:], nil
}

func (r *ExtensionRuntime) ensureCredentialsLoaded() error {
	r.credentialsMu.RLock()
	if r.credentialsLoaded {
		r.credentialsMu.RUnlock()
		return nil
	}
	r.credentialsMu.RUnlock()

	r.credentialsMu.Lock()
	defer r.credentialsMu.Unlock()
	if r.credentialsLoaded {
		return nil
	}

	credPath := r.getCredentialsPath()
	data, err := os.ReadFile(credPath)
	if err != nil {
		if os.IsNotExist(err) {
			r.credentialsCache = make(map[string]interface{})
			r.credentialsLoaded = true
			return nil
		}
		return err
	}

	key, err := r.getEncryptionKey()
	if err != nil {
		return fmt.Errorf("failed to get encryption key: %w", err)
	}
	decrypted, err := decryptAES(data, key)
	if err != nil {
		return fmt.Errorf("failed to decrypt credentials: %w", err)
	}

	var creds map[string]interface{}
	if err := json.Unmarshal(decrypted, &creds); err != nil {
		return err
	}
	if creds == nil {
		creds = make(map[string]interface{})
	}

	r.credentialsCache = creds
	r.credentialsLoaded = true
	return nil
}

func (r *ExtensionRuntime) loadCredentials() (map[string]interface{}, error) {
	if err := r.ensureCredentialsLoaded(); err != nil {
		return nil, err
	}

	r.credentialsMu.RLock()
	defer r.credentialsMu.RUnlock()
	return cloneInterfaceMap(r.credentialsCache), nil
}

func (r *ExtensionRuntime) saveCredentials(creds map[string]interface{}) error {
	data, err := json.Marshal(creds)
	if err != nil {
		return err
	}

	key, err := r.getEncryptionKey()
	if err != nil {
		return fmt.Errorf("failed to get encryption key: %w", err)
	}
	encrypted, err := encryptAES(data, key)
	if err != nil {
		return fmt.Errorf("failed to encrypt credentials: %w", err)
	}

	credPath := r.getCredentialsPath()
	if err := os.WriteFile(credPath, encrypted, 0600); err != nil {
		return err
	}

	r.credentialsMu.Lock()
	r.credentialsCache = cloneInterfaceMap(creds)
	r.credentialsLoaded = true
	r.credentialsMu.Unlock()
	return nil
}

func (r *ExtensionRuntime) credentialsStore(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "key and value are required",
		})
	}

	key := call.Arguments[0].String()
	value := call.Arguments[1].Export()

	if err := r.ensureCredentialsLoaded(); err != nil {
		GoLog("[Extension:%s] Credentials load error: %v\n", r.extensionID, err)
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	r.credentialsMu.RLock()
	nextCreds := cloneInterfaceMap(r.credentialsCache)
	r.credentialsMu.RUnlock()
	nextCreds[key] = value

	if err := r.saveCredentials(nextCreds); err != nil {
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

func (r *ExtensionRuntime) credentialsGet(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return goja.Undefined()
	}

	key := call.Arguments[0].String()

	if err := r.ensureCredentialsLoaded(); err != nil {
		GoLog("[Extension:%s] Credentials load error: %v\n", r.extensionID, err)
		return goja.Undefined()
	}

	r.credentialsMu.RLock()
	value, exists := r.credentialsCache[key]
	r.credentialsMu.RUnlock()
	if !exists {
		if len(call.Arguments) > 1 {
			return call.Arguments[1]
		}
		return goja.Undefined()
	}

	return r.vm.ToValue(value)
}

func (r *ExtensionRuntime) credentialsRemove(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(false)
	}

	key := call.Arguments[0].String()

	if err := r.ensureCredentialsLoaded(); err != nil {
		GoLog("[Extension:%s] Credentials load error: %v\n", r.extensionID, err)
		return r.vm.ToValue(false)
	}

	r.credentialsMu.RLock()
	nextCreds := cloneInterfaceMap(r.credentialsCache)
	r.credentialsMu.RUnlock()
	delete(nextCreds, key)

	if err := r.saveCredentials(nextCreds); err != nil {
		GoLog("[Extension:%s] Credentials save error: %v\n", r.extensionID, err)
		return r.vm.ToValue(false)
	}

	return r.vm.ToValue(true)
}

func (r *ExtensionRuntime) credentialsHas(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(false)
	}

	key := call.Arguments[0].String()

	if err := r.ensureCredentialsLoaded(); err != nil {
		return r.vm.ToValue(false)
	}

	r.credentialsMu.RLock()
	_, exists := r.credentialsCache[key]
	r.credentialsMu.RUnlock()
	return r.vm.ToValue(exists)
}

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
