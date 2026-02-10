package gobackend

import (
	"path/filepath"
	"strings"
	"testing"
)

func TestSanitizeSensitiveLogText(t *testing.T) {
	input := "access_token=abc123 Authorization:Bearer xyz456 https://api.example.com/cb?refresh_token=zzz"
	redacted := sanitizeSensitiveLogText(input)

	if strings.Contains(redacted, "abc123") || strings.Contains(redacted, "xyz456") || strings.Contains(redacted, "zzz") {
		t.Fatalf("expected sensitive values to be redacted, got: %s", redacted)
	}
	if !strings.Contains(redacted, "[REDACTED]") {
		t.Fatalf("expected redaction marker in output, got: %s", redacted)
	}
}

func TestValidateExtensionAuthURL(t *testing.T) {
	if err := validateExtensionAuthURL("https://accounts.example.com/oauth/authorize"); err != nil {
		t.Fatalf("expected valid auth URL, got error: %v", err)
	}

	blocked := []string{
		"http://accounts.example.com/oauth/authorize",
		"https://user:pass@accounts.example.com/oauth/authorize",
		"https://localhost/oauth/authorize",
	}

	for _, rawURL := range blocked {
		if err := validateExtensionAuthURL(rawURL); err == nil {
			t.Fatalf("expected URL to be blocked: %s", rawURL)
		}
	}
}

func TestValidateDomainRejectsEmbeddedCredentials(t *testing.T) {
	ext := &LoadedExtension{
		ID: "test-ext",
		Manifest: &ExtensionManifest{
			Name: "test-ext",
			Permissions: ExtensionPermissions{
				Network: []string{"api.example.com"},
			},
		},
		DataDir: t.TempDir(),
	}

	runtime := NewExtensionRuntime(ext)
	if err := runtime.validateDomain("https://user:pass@api.example.com/resource"); err == nil {
		t.Fatal("expected embedded URL credentials to be rejected")
	}
}

func TestBuildStoreExtensionDestPath(t *testing.T) {
	baseDir := t.TempDir()

	destPath, err := buildStoreExtensionDestPath(baseDir, "../evil/name")
	if err != nil {
		t.Fatalf("expected sanitized path to be generated, got error: %v", err)
	}

	if !isPathWithinBase(baseDir, destPath) {
		t.Fatalf("expected destination path to remain under base dir: %s", destPath)
	}

	baseName := filepath.Base(destPath)
	if strings.Contains(baseName, "/") || strings.Contains(baseName, `\`) {
		t.Fatalf("expected filename to be sanitized, got: %s", baseName)
	}
	if !strings.HasSuffix(baseName, ".spotiflac-ext") {
		t.Fatalf("expected .spotiflac-ext suffix, got: %s", baseName)
	}

	if _, err := buildStoreExtensionDestPath(baseDir, "   "); err == nil {
		t.Fatal("expected empty extension id to be rejected")
	}
}
