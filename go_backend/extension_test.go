package gobackend

import (
	"path/filepath"
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
	ext := &loadedExtension{
		ID: "test-ext",
		Manifest: &ExtensionManifest{
			Name: "test-ext",
			Permissions: ExtensionPermissions{
				Network: []string{"api.allowed.com", "*.wildcard.com"},
			},
		},
		DataDir: t.TempDir(),
	}

	runtime := newExtensionRuntime(ext)

	if err := runtime.validateDomain("https://api.allowed.com/path"); err != nil {
		t.Errorf("Expected api.allowed.com to be allowed, got error: %v", err)
	}

	if err := runtime.validateDomain("https://sub.wildcard.com/path"); err != nil {
		t.Errorf("Expected sub.wildcard.com to be allowed (wildcard), got error: %v", err)
	}

	if err := runtime.validateDomain("https://blocked.com/path"); err == nil {
		t.Error("Expected blocked.com to be denied")
	}

	if err := runtime.validateDomain("https://notallowed.com/path"); err == nil {
		t.Error("Expected notallowed.com to be denied")
	}
}

func TestExtensionRuntime_FileSandbox(t *testing.T) {
	tempDir := t.TempDir()

	ext := &loadedExtension{
		ID: "test-ext",
		Manifest: &ExtensionManifest{
			Name: "test-ext",
			Permissions: ExtensionPermissions{
				File: true,
			},
		},
		DataDir: tempDir,
	}

	runtime := newExtensionRuntime(ext)

	validPath, err := runtime.validatePath("test.txt")
	if err != nil {
		t.Errorf("Expected relative path to be valid, got error: %v", err)
	}
	if validPath == "" {
		t.Error("Expected non-empty path")
	}

	_, err = runtime.validatePath("../../../etc/passwd")
	if err == nil {
		t.Error("Expected path traversal to be blocked")
	}

	nestedPath, err := runtime.validatePath("subdir/file.txt")
	if err != nil {
		t.Errorf("Expected nested path to be valid, got error: %v", err)
	}
	if nestedPath == "" {
		t.Error("Expected non-empty nested path")
	}

	var absPath string
	if filepath.IsAbs("C:\\Windows\\System32") {
		absPath = "C:\\Windows\\System32\\test.txt"
	} else {
		absPath = "/etc/passwd"
	}
	_, err = runtime.validatePath(absPath)
	if err == nil {
		t.Error("Expected absolute path to be blocked")
	}

	extNoFile := &loadedExtension{
		ID: "test-ext-no-file",
		Manifest: &ExtensionManifest{
			Name: "test-ext-no-file",
			Permissions: ExtensionPermissions{
				File: false,
			},
		},
		DataDir: tempDir,
	}
	runtimeNoFile := newExtensionRuntime(extNoFile)
	_, err = runtimeNoFile.validatePath("test.txt")
	if err == nil {
		t.Error("Expected file access to be denied without file permission")
	}
}

func TestExtensionRuntime_UtilityFunctions(t *testing.T) {
	ext := &loadedExtension{
		ID: "test-ext",
		Manifest: &ExtensionManifest{
			Name: "test-ext",
		},
		DataDir: t.TempDir(),
	}

	runtime := newExtensionRuntime(ext)
	vm := goja.New()
	runtime.RegisterAPIs(vm)

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

	result, err = vm.RunString(`utils.md5("hello")`)
	if err != nil {
		t.Fatalf("md5 failed: %v", err)
	}
	if result.String() != "5d41402abc4b2a76b9719d911017c592" {
		t.Errorf("Expected '5d41402abc4b2a76b9719d911017c592', got '%s'", result.String())
	}

	result, err = vm.RunString(`utils.stringifyJSON({name: "test", value: 123})`)
	if err != nil {
		t.Fatalf("stringifyJSON failed: %v", err)
	}
	// JSON output may vary in order, just check it's valid
	if result.String() == "" {
		t.Error("Expected non-empty JSON string")
	}

	result, err = vm.RunString(`utils.sleep(1)`)
	if err != nil {
		t.Fatalf("sleep failed: %v", err)
	}
	if !result.ToBoolean() {
		t.Error("Expected sleep to complete successfully")
	}

	runtime.setActiveDownloadItemID("test-item")
	cancelDownload("test-item")
	t.Cleanup(func() {
		clearDownloadCancel("test-item")
		runtime.clearActiveDownloadItemID()
	})

	result, err = vm.RunString(`utils.isDownloadCancelled()`)
	if err != nil {
		t.Fatalf("isDownloadCancelled failed: %v", err)
	}
	if !result.ToBoolean() {
		t.Error("Expected active download cancellation to be visible to JS")
	}

	SetAppVersion("4.2.2")
	t.Cleanup(func() {
		SetAppVersion("")
	})

	result, err = vm.RunString(`utils.appVersion()`)
	if err != nil {
		t.Fatalf("appVersion failed: %v", err)
	}
	if got := result.String(); got != "4.2.2" {
		t.Fatalf("Expected appVersion 4.2.2, got %q", got)
	}

	result, err = vm.RunString(`utils.appUserAgent()`)
	if err != nil {
		t.Fatalf("appUserAgent failed: %v", err)
	}
	if got := result.String(); got != "SpotiFLAC-Mobile/4.2.2" {
		t.Fatalf("Expected appUserAgent SpotiFLAC-Mobile/4.2.2, got %q", got)
	}

	result, err = vm.RunString(`utils.sleep(50)`)
	if err != nil {
		t.Fatalf("cancel-aware sleep failed: %v", err)
	}
	if result.ToBoolean() {
		t.Error("Expected sleep to abort when download is cancelled")
	}
}

func TestExtensionRuntime_SSRFProtection(t *testing.T) {
	// Create extension with limited network permissions
	ext := &loadedExtension{
		ID: "test-ext",
		Manifest: &ExtensionManifest{
			Name: "test-ext",
			Permissions: ExtensionPermissions{
				Network: []string{"api.example.com"},
			},
		},
		DataDir: t.TempDir(),
	}

	runtime := newExtensionRuntime(ext)

	privateIPs := []string{
		"http://localhost/admin",
		"http://127.0.0.1/admin",
		"http://192.168.1.1/admin",
		"http://10.0.0.1/admin",
		"http://172.16.0.1/admin",
		"http://169.254.169.254/latest/meta-data/", // AWS metadata
		"http://router.local/admin",
	}

	for _, url := range privateIPs {
		err := runtime.validateDomain(url)
		if err == nil {
			t.Errorf("Expected private IP/host '%s' to be blocked", url)
		}
	}

	if err := runtime.validateDomain("https://api.example.com/path"); err != nil {
		t.Errorf("Expected api.example.com to be allowed, got error: %v", err)
	}
}

func TestIsPrivateIP(t *testing.T) {
	tests := []struct {
		host     string
		expected bool
	}{
		{"localhost", true},
		{"127.0.0.1", true},
		{"127.0.0.2", true},
		{"10.0.0.1", true},
		{"10.255.255.255", true},
		{"172.16.0.1", true},
		{"172.31.255.255", true},
		{"192.168.0.1", true},
		{"192.168.255.255", true},
		{"169.254.169.254", true},
		{"router.local", true},
		{"mydevice.local", true},

		{"8.8.8.8", false},
		{"1.1.1.1", false},
		{"api.example.com", false},
		{"google.com", false},
		{"172.15.0.1", false},
		{"172.32.0.1", false},
		{"192.167.0.1", false},
	}

	for _, tt := range tests {
		result := isPrivateIP(tt.host)
		if result != tt.expected {
			t.Errorf("isPrivateIP(%s) = %v, expected %v", tt.host, result, tt.expected)
		}
	}
}
