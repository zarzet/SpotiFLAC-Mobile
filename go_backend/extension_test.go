package gobackend

import (
	"testing"

	"github.com/dop251/goja"
)

func TestParseManifest_Valid(t *testing.T) {
	validManifest := `{
		"name": "test-provider",
		"displayName": "Test Provider",
		"version": "1.0.0",
		"author": "Test Author",
		"description": "A test extension",
		"type": ["metadata_provider"],
		"permissions": {
			"network": ["api.test.com"],
			"storage": true
		}
	}`

	manifest, err := ParseManifest([]byte(validManifest))
	if err != nil {
		t.Fatalf("Expected valid manifest to parse, got error: %v", err)
	}

	if manifest.Name != "test-provider" {
		t.Errorf("Expected name 'test-provider', got '%s'", manifest.Name)
	}

	if manifest.Version != "1.0.0" {
		t.Errorf("Expected version '1.0.0', got '%s'", manifest.Version)
	}

	if !manifest.IsMetadataProvider() {
		t.Error("Expected IsMetadataProvider() to return true")
	}

	if manifest.IsDownloadProvider() {
		t.Error("Expected IsDownloadProvider() to return false")
	}
}

func TestParseManifest_MissingName(t *testing.T) {
	invalidManifest := `{
		"version": "1.0.0",
		"author": "Test Author",
		"description": "A test extension",
		"type": ["metadata_provider"]
	}`

	_, err := ParseManifest([]byte(invalidManifest))
	if err == nil {
		t.Fatal("Expected error for missing name")
	}
}

func TestParseManifest_MissingType(t *testing.T) {
	invalidManifest := `{
		"name": "test-provider",
		"version": "1.0.0",
		"author": "Test Author",
		"description": "A test extension"
	}`

	_, err := ParseManifest([]byte(invalidManifest))
	if err == nil {
		t.Fatal("Expected error for missing type")
	}
}

func TestIsDomainAllowed(t *testing.T) {
	manifest := &ExtensionManifest{
		Permissions: ExtensionPermissions{
			Network: []string{"api.test.com", "*.example.com"},
		},
	}

	tests := []struct {
		domain   string
		expected bool
	}{
		{"api.test.com", true},
		{"api.example.com", true},
		{"sub.example.com", true},
		{"notallowed.com", false},
		{"test.com", false},
	}

	for _, tt := range tests {
		result := manifest.IsDomainAllowed(tt.domain)
		if result != tt.expected {
			t.Errorf("IsDomainAllowed(%s) = %v, expected %v", tt.domain, result, tt.expected)
		}
	}
}

func TestExtensionRuntime_NetworkSandbox(t *testing.T) {
	// Create a mock extension with limited network permissions
	ext := &LoadedExtension{
		ID: "test-ext",
		Manifest: &ExtensionManifest{
			Name: "test-ext",
			Permissions: ExtensionPermissions{
				Network: []string{"api.allowed.com", "*.wildcard.com"},
			},
		},
		DataDir: t.TempDir(),
	}

	runtime := NewExtensionRuntime(ext)

	// Test allowed domains
	if err := runtime.validateDomain("https://api.allowed.com/path"); err != nil {
		t.Errorf("Expected api.allowed.com to be allowed, got error: %v", err)
	}

	if err := runtime.validateDomain("https://sub.wildcard.com/path"); err != nil {
		t.Errorf("Expected sub.wildcard.com to be allowed (wildcard), got error: %v", err)
	}

	// Test blocked domains
	if err := runtime.validateDomain("https://blocked.com/path"); err == nil {
		t.Error("Expected blocked.com to be denied")
	}

	if err := runtime.validateDomain("https://notallowed.com/path"); err == nil {
		t.Error("Expected notallowed.com to be denied")
	}
}

func TestExtensionRuntime_FileSandbox(t *testing.T) {
	tempDir := t.TempDir()

	ext := &LoadedExtension{
		ID: "test-ext",
		Manifest: &ExtensionManifest{
			Name: "test-ext",
		},
		DataDir: tempDir,
	}

	runtime := NewExtensionRuntime(ext)

	// Test valid path within sandbox
	validPath, err := runtime.validatePath("test.txt")
	if err != nil {
		t.Errorf("Expected relative path to be valid, got error: %v", err)
	}
	if validPath == "" {
		t.Error("Expected non-empty path")
	}

	// Test path traversal attack
	_, err = runtime.validatePath("../../../etc/passwd")
	if err == nil {
		t.Error("Expected path traversal to be blocked")
	}

	// Test nested path within sandbox (should be allowed)
	nestedPath, err := runtime.validatePath("subdir/file.txt")
	if err != nil {
		t.Errorf("Expected nested path to be valid, got error: %v", err)
	}
	if nestedPath == "" {
		t.Error("Expected non-empty nested path")
	}
}

func TestExtensionRuntime_UtilityFunctions(t *testing.T) {
	ext := &LoadedExtension{
		ID: "test-ext",
		Manifest: &ExtensionManifest{
			Name: "test-ext",
		},
		DataDir: t.TempDir(),
	}

	runtime := NewExtensionRuntime(ext)
	vm := goja.New()
	runtime.RegisterAPIs(vm)

	// Test base64 encode/decode
	result, err := vm.RunString(`utils.base64Encode("hello")`)
	if err != nil {
		t.Fatalf("base64Encode failed: %v", err)
	}
	if result.String() != "aGVsbG8=" {
		t.Errorf("Expected 'aGVsbG8=', got '%s'", result.String())
	}

	result, err = vm.RunString(`utils.base64Decode("aGVsbG8=")`)
	if err != nil {
		t.Fatalf("base64Decode failed: %v", err)
	}
	if result.String() != "hello" {
		t.Errorf("Expected 'hello', got '%s'", result.String())
	}

	// Test MD5
	result, err = vm.RunString(`utils.md5("hello")`)
	if err != nil {
		t.Fatalf("md5 failed: %v", err)
	}
	if result.String() != "5d41402abc4b2a76b9719d911017c592" {
		t.Errorf("Expected '5d41402abc4b2a76b9719d911017c592', got '%s'", result.String())
	}

	// Test JSON parse/stringify
	result, err = vm.RunString(`utils.stringifyJSON({name: "test", value: 123})`)
	if err != nil {
		t.Fatalf("stringifyJSON failed: %v", err)
	}
	// JSON output may vary in order, just check it's valid
	if result.String() == "" {
		t.Error("Expected non-empty JSON string")
	}
}
