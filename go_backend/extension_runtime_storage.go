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

	"github.com/dop251/goja"
)

// ==================== Storage API ====================

func (r *ExtensionRuntime) getStoragePath() string {
	return filepath.Join(r.dataDir, "storage.json")
}

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

func (r *ExtensionRuntime) saveStorage(storage map[string]interface{}) error {
	storagePath := r.getStoragePath()
	data, err := json.MarshalIndent(storage, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(storagePath, data, 0600)
}

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

func (r *ExtensionRuntime) loadCredentials() (map[string]interface{}, error) {
	credPath := r.getCredentialsPath()
	data, err := os.ReadFile(credPath)
	if err != nil {
		if os.IsNotExist(err) {
			return make(map[string]interface{}), nil
		}
		return nil, err
	}

	key, err := r.getEncryptionKey()
	if err != nil {
		return nil, fmt.Errorf("failed to get encryption key: %w", err)
	}
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
	return os.WriteFile(credPath, encrypted, 0600)
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
