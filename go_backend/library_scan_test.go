package gobackend

import "testing"

func TestScanFromFilenameMarksMetadataFallback(t *testing.T) {
	result := &LibraryScanResult{}

	scanned, err := scanFromFilename(
		"/proc/self/fd/209",
		"189.mp3",
		result,
	)
	if err != nil {
		t.Fatalf("scanFromFilename returned error: %v", err)
	}
	if !scanned.MetadataFromFilename {
		t.Fatal("expected filename fallback marker to be set")
	}
	if scanned.TrackName != "189" {
		t.Fatalf("unexpected track name: %q", scanned.TrackName)
	}
	if scanned.ArtistName != "Unknown Artist" {
		t.Fatalf("unexpected artist name: %q", scanned.ArtistName)
	}
}
