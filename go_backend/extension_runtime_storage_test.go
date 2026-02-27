package gobackend

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/dop251/goja"
)

func setStorageValue(t *testing.T, runtime *ExtensionRuntime, key string, value interface{}) {
	t.Helper()
	result := runtime.storageSet(goja.FunctionCall{
		Arguments: []goja.Value{
			runtime.vm.ToValue(key),
			runtime.vm.ToValue(value),
		},
	})
	if !result.ToBoolean() {
		t.Fatalf("storage.set(%q) returned false", key)
	}
}

func readStorageMap(t *testing.T, storagePath string) map[string]interface{} {
	t.Helper()
	data, err := os.ReadFile(storagePath)
	if err != nil {
		t.Fatalf("failed to read storage file: %v", err)
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("failed to unmarshal storage file: %v", err)
	}
	return parsed
}

func TestExtensionRuntimeStorage_DebouncedWriteCompactJSON(t *testing.T) {
	ext := &LoadedExtension{
		ID: "storage-test",
		Manifest: &ExtensionManifest{
			Name: "storage-test",
		},
		DataDir: t.TempDir(),
	}

	runtime := NewExtensionRuntime(ext)
	runtime.storageFlushDelay = 25 * time.Millisecond
	runtime.RegisterAPIs(goja.New())

	setStorageValue(t, runtime, "k1", "v1")
	setStorageValue(t, runtime, "k2", 2)

	storagePath := filepath.Join(ext.DataDir, "storage.json")
	deadline := time.Now().Add(1500 * time.Millisecond)

	var raw []byte
	for time.Now().Before(deadline) {
		data, err := os.ReadFile(storagePath)
		if err == nil {
			raw = data
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	if len(raw) == 0 {
		t.Fatalf("storage.json was not written within timeout")
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal(raw, &parsed); err != nil {
		t.Fatalf("failed to unmarshal storage file: %v", err)
	}
	if parsed["k1"] != "v1" {
		t.Fatalf("expected k1=v1, got %v", parsed["k1"])
	}
	if parsed["k2"] != float64(2) {
		t.Fatalf("expected k2=2, got %v", parsed["k2"])
	}
	if bytes.Contains(raw, []byte("\n")) {
		t.Fatalf("expected compact JSON without indentation, got: %q", string(raw))
	}
}

func TestUnloadExtension_FlushesPendingStorage(t *testing.T) {
	ext := &LoadedExtension{
		ID: "unload-storage-test",
		Manifest: &ExtensionManifest{
			Name: "unload-storage-test",
		},
		DataDir: t.TempDir(),
		VM:      goja.New(),
	}

	runtime := NewExtensionRuntime(ext)
	runtime.storageFlushDelay = time.Hour
	runtime.RegisterAPIs(ext.VM)
	ext.runtime = runtime

	manager := &ExtensionManager{
		extensions: map[string]*LoadedExtension{
			ext.ID: ext,
		},
	}

	setStorageValue(t, runtime, "persist_on_unload", true)

	if err := manager.UnloadExtension(ext.ID); err != nil {
		t.Fatalf("UnloadExtension failed: %v", err)
	}

	storagePath := filepath.Join(ext.DataDir, "storage.json")
	parsed := readStorageMap(t, storagePath)
	if parsed["persist_on_unload"] != true {
		t.Fatalf("expected pending storage value to be flushed on unload, got %v", parsed["persist_on_unload"])
	}
}
