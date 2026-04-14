package gobackend

import (
	"os"
	"path/filepath"
	"testing"
)

func TestSetMetadataProviderPriorityAddsBuiltIns(t *testing.T) {
	original := GetMetadataProviderPriority()
	defer SetMetadataProviderPriority(original)

	SetMetadataProviderPriority([]string{"tidal"})
	got := GetMetadataProviderPriority()
	want := []string{"tidal", "qobuz"}
	if len(got) != len(want) {
		t.Fatalf("unexpected priority length: got %v want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("unexpected priority at %d: got %v want %v", i, got, want)
		}
	}
}

func TestSetExtensionFallbackProviderIDsSkipsBuiltInsAndDuplicates(t *testing.T) {
	original := GetExtensionFallbackProviderIDs()
	defer SetExtensionFallbackProviderIDs(original)

	SetExtensionFallbackProviderIDs([]string{"ext-a", "tidal", "ext-a", " ext-b "})

	got := GetExtensionFallbackProviderIDs()
	want := []string{"ext-a", "ext-b"}
	if len(got) != len(want) {
		t.Fatalf("unexpected fallback provider length: got %v want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("unexpected fallback provider at %d: got %v want %v", i, got, want)
		}
	}
}

func TestIsExtensionFallbackAllowedDefaultsToAllExtensions(t *testing.T) {
	original := GetExtensionFallbackProviderIDs()
	defer SetExtensionFallbackProviderIDs(original)

	SetExtensionFallbackProviderIDs(nil)

	if !isExtensionFallbackAllowed("custom-ext") {
		t.Fatal("expected custom extension to be allowed when no fallback allowlist is configured")
	}
	if !isExtensionFallbackAllowed("qobuz") {
		t.Fatal("expected built-in provider to remain allowed")
	}
}

func TestIsExtensionFallbackAllowedRespectsAllowlist(t *testing.T) {
	original := GetExtensionFallbackProviderIDs()
	defer SetExtensionFallbackProviderIDs(original)

	SetExtensionFallbackProviderIDs([]string{"allowed-ext"})

	if !isExtensionFallbackAllowed("allowed-ext") {
		t.Fatal("expected explicitly allowed extension to be permitted")
	}
	if isExtensionFallbackAllowed("blocked-ext") {
		t.Fatal("expected extension outside allowlist to be blocked")
	}
	if isExtensionFallbackAllowed("deezer") {
		t.Fatal("expected retired Deezer downloader to respect extension fallback allowlist")
	}
}

func TestSetProviderPriorityRemovesRetiredDeezerDownloader(t *testing.T) {
	original := GetProviderPriority()
	defer SetProviderPriority(original)

	SetProviderPriority([]string{"deezer", "qobuz", "custom-ext"})

	got := GetProviderPriority()
	want := []string{"qobuz", "custom-ext", "tidal"}
	if len(got) != len(want) {
		t.Fatalf("unexpected priority length: got %v want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("unexpected priority at %d: got %v want %v", i, got, want)
		}
	}
}

func TestNormalizeDownloadDecryptionInfoPromotesLegacyKey(t *testing.T) {
	normalized := normalizeDownloadDecryptionInfo(nil, " 001122 ")
	if normalized == nil {
		t.Fatal("expected legacy decryption key to produce normalized descriptor")
	}
	if normalized.Strategy != genericFFmpegMOVDecryptionStrategy {
		t.Fatalf("strategy = %q", normalized.Strategy)
	}
	if normalized.Key != "001122" {
		t.Fatalf("key = %q", normalized.Key)
	}
	if normalized.InputFormat != "mov" {
		t.Fatalf("input format = %q", normalized.InputFormat)
	}
}

func TestNormalizeDownloadDecryptionInfoCanonicalizesMovAliases(t *testing.T) {
	normalized := normalizeDownloadDecryptionInfo(&DownloadDecryptionInfo{
		Strategy:    "mp4_decryption_key",
		Key:         "abcd",
		InputFormat: "",
	}, "")
	if normalized == nil {
		t.Fatal("expected descriptor to remain available")
	}
	if normalized.Strategy != genericFFmpegMOVDecryptionStrategy {
		t.Fatalf("strategy = %q", normalized.Strategy)
	}
	if normalized.InputFormat != "mov" {
		t.Fatalf("input format = %q", normalized.InputFormat)
	}
}

func TestBuildOutputPathAddsExplicitOutputDirToAllowedDirs(t *testing.T) {
	SetAllowedDownloadDirs(nil)

	outputDir := t.TempDir()
	outputPath := buildOutputPath(DownloadRequest{
		TrackName:      "Song",
		ArtistName:     "Artist",
		OutputDir:      outputDir,
		OutputExt:      ".flac",
		FilenameFormat: "",
	})

	if !isPathInAllowedDirs(outputPath) {
		t.Fatalf("expected output path %q to be allowed", outputPath)
	}
}

func TestBuildOutputPathForExtensionAddsExplicitOutputPathDirToAllowedDirs(t *testing.T) {
	SetAllowedDownloadDirs(nil)

	outputDir := t.TempDir()
	outputPath := filepath.Join(outputDir, "custom.flac")
	ext := &loadedExtension{DataDir: t.TempDir()}

	resolved := buildOutputPathForExtension(DownloadRequest{
		OutputPath: outputPath,
	}, ext)

	if resolved != outputPath {
		t.Fatalf("resolved output path = %q", resolved)
	}
	if !isPathInAllowedDirs(outputPath) {
		t.Fatalf("expected output path %q to be allowed", outputPath)
	}
}

func TestBuildOutputPathForExtensionUsesTempDirForFDOutput(t *testing.T) {
	SetAllowedDownloadDirs(nil)

	ext := &loadedExtension{DataDir: t.TempDir()}
	resolved := buildOutputPathForExtension(DownloadRequest{
		TrackName:  "Song",
		ArtistName: "Artist",
		OutputDir:  filepath.Join("Artist", "Album"),
		OutputFD:   123,
		OutputExt:  ".flac",
	}, ext)

	expectedBase := filepath.Join(ext.DataDir, "downloads")
	if !isPathWithinBase(expectedBase, resolved) {
		t.Fatalf("expected SAF extension output under %q, got %q", expectedBase, resolved)
	}
	if !isPathInAllowedDirs(resolved) {
		t.Fatalf("expected resolved output path %q to be allowed", resolved)
	}
}

func TestCanEmbedGenreLabelRequiresExistingAbsoluteLocalFile(t *testing.T) {
	tempFile := filepath.Join(t.TempDir(), "track.flac")
	if err := os.WriteFile(tempFile, []byte("fLaC"), 0644); err != nil {
		t.Fatalf("failed to create temp file: %v", err)
	}
	tempM4A := filepath.Join(t.TempDir(), "track.m4a")
	if err := os.WriteFile(tempM4A, []byte("not-flac"), 0644); err != nil {
		t.Fatalf("failed to create temp m4a file: %v", err)
	}

	if canEmbedGenreLabel("relative.flac") {
		t.Fatal("expected relative path to be rejected")
	}
	if canEmbedGenreLabel("content://example") {
		t.Fatal("expected content URI to be rejected")
	}
	if canEmbedGenreLabel(filepath.Join(t.TempDir(), "missing.flac")) {
		t.Fatal("expected missing file to be rejected")
	}
	if canEmbedGenreLabel(tempM4A) {
		t.Fatalf("expected non-FLAC file %q to be rejected", tempM4A)
	}
	if !canEmbedGenreLabel(tempFile) {
		t.Fatalf("expected existing absolute file %q to be accepted", tempFile)
	}
}

func TestSearchTracksWithMetadataProvidersUsesPriorityAndDedupes(t *testing.T) {
	originalPriority := GetMetadataProviderPriority()
	originalSearch := searchBuiltInMetadataTracksFunc
	defer func() {
		SetMetadataProviderPriority(originalPriority)
		searchBuiltInMetadataTracksFunc = originalSearch
	}()

	SetMetadataProviderPriority([]string{"qobuz", "tidal"})

	var calls []string
	searchBuiltInMetadataTracksFunc = func(providerID, query string, limit int) ([]ExtTrackMetadata, error) {
		calls = append(calls, providerID)
		switch providerID {
		case "qobuz":
			return []ExtTrackMetadata{
				{ProviderID: "qobuz", SpotifyID: "qobuz:1", ISRC: "AAA111", Name: "First"},
			}, nil
		case "tidal":
			return []ExtTrackMetadata{
				{ProviderID: "tidal", SpotifyID: "tidal:2", ISRC: "AAA111", Name: "Duplicate"},
				{ProviderID: "tidal", SpotifyID: "tidal:3", ISRC: "BBB222", Name: "Second"},
			}, nil
		default:
			return nil, nil
		}
	}

	manager := getExtensionManager()
	tracks, err := manager.SearchTracksWithMetadataProviders("query", 3, false)
	if err != nil {
		t.Fatalf("SearchTracksWithMetadataProviders returned error: %v", err)
	}
	if len(tracks) != 2 {
		t.Fatalf("unexpected track count: got %d want 2", len(tracks))
	}
	if tracks[0].ProviderID != "qobuz" || tracks[1].ProviderID != "tidal" {
		t.Fatalf("unexpected track provider order: %+v", tracks)
	}
	if len(calls) != 2 || calls[0] != "qobuz" || calls[1] != "tidal" {
		t.Fatalf("unexpected provider call order: %v", calls)
	}
}
