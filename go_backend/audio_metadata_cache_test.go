package gobackend

import (
	"os"
	"strings"
	"testing"
)

func TestResolveLibraryCoverCacheKeyUsesExplicitKey(t *testing.T) {
	t.Parallel()

	const explicitKey = "content://media/external/audio/media/42|123456"
	got := resolveLibraryCoverCacheKey("/tmp/saf_random.flac", explicitKey)
	if got != explicitKey {
		t.Fatalf("expected explicit cache key %q, got %q", explicitKey, got)
	}
}

func TestResolveLibraryCoverCacheKeyUsesFilePathAndStatWhenNoExplicitKey(t *testing.T) {
	t.Parallel()

	tempFile, err := os.CreateTemp("", "cover-cache-*.flac")
	if err != nil {
		t.Fatalf("CreateTemp failed: %v", err)
	}
	tempPath := tempFile.Name()
	tempFile.Close()
	defer os.Remove(tempPath)

	got := resolveLibraryCoverCacheKey(tempPath, "")
	if !strings.HasPrefix(got, tempPath+"|") {
		t.Fatalf("expected stat-based cache key to start with %q, got %q", tempPath+"|", got)
	}
}
