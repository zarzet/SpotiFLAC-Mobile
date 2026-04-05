package gobackend

import "testing"

func TestSetMetadataProviderPriorityAddsBuiltIns(t *testing.T) {
	original := GetMetadataProviderPriority()
	defer SetMetadataProviderPriority(original)

	SetMetadataProviderPriority([]string{"tidal"})
	got := GetMetadataProviderPriority()
	want := []string{"tidal", "deezer", "qobuz"}
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
	if !isExtensionFallbackAllowed("deezer") {
		t.Fatal("expected built-in provider to ignore extension allowlist")
	}
}

func TestSearchTracksWithMetadataProvidersUsesPriorityAndDedupes(t *testing.T) {
	originalPriority := GetMetadataProviderPriority()
	originalSearch := searchBuiltInMetadataTracksFunc
	defer func() {
		SetMetadataProviderPriority(originalPriority)
		searchBuiltInMetadataTracksFunc = originalSearch
	}()

	SetMetadataProviderPriority([]string{"qobuz", "tidal", "deezer"})

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
		case "deezer":
			return []ExtTrackMetadata{
				{ProviderID: "deezer", SpotifyID: "deezer:4", ISRC: "CCC333", Name: "Third"},
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
	if len(tracks) != 3 {
		t.Fatalf("unexpected track count: got %d want 3", len(tracks))
	}
	if tracks[0].ProviderID != "qobuz" || tracks[1].ProviderID != "tidal" || tracks[2].ProviderID != "deezer" {
		t.Fatalf("unexpected track provider order: %+v", tracks)
	}
	if len(calls) != 3 || calls[0] != "qobuz" || calls[1] != "tidal" || calls[2] != "deezer" {
		t.Fatalf("unexpected provider call order: %v", calls)
	}
}
