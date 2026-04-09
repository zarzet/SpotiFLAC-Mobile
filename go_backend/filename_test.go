package gobackend

import "testing"

func TestBuildFilenameFromTemplate_WithRawTrackAndDisc(t *testing.T) {
	metadata := map[string]interface{}{
		"title":  "Song Name",
		"artist": "Artist Name",
		"album":  "Album Name",
		"track":  1,
		"disc":   2,
		"year":   "2025",
	}

	formatted := buildFilenameFromTemplate(
		"{artist} - {track} - {track_raw} - d{disc} - d{disc_raw} - {title}",
		metadata,
	)

	expected := "Artist Name - 01 - 1 - d2 - d2 - Song Name"
	if formatted != expected {
		t.Fatalf("expected %q, got %q", expected, formatted)
	}
}

func TestBuildFilenameFromTemplate_RawPlaceholdersEmptyWhenZero(t *testing.T) {
	metadata := map[string]interface{}{
		"title":  "Song Name",
		"artist": "Artist Name",
		"track":  0,
		"disc":   0,
	}

	formatted := buildFilenameFromTemplate("{track_raw}-{disc_raw}-{title}", metadata)
	expected := "--Song Name"
	if formatted != expected {
		t.Fatalf("expected %q, got %q", expected, formatted)
	}
}

func TestBuildFilenameFromTemplate_InlineNumberFormatting(t *testing.T) {
	metadata := map[string]interface{}{
		"track": 3,
		"disc":  2,
	}

	formatted := buildFilenameFromTemplate("{track:1}-{track:02}-{disc:03}", metadata)
	expected := "3-03-002"
	if formatted != expected {
		t.Fatalf("expected %q, got %q", expected, formatted)
	}
}

func TestBuildFilenameFromTemplate_DateStrftimeFormatting(t *testing.T) {
	metadata := map[string]interface{}{
		"artist":       "Artist Name",
		"title":        "Song Name",
		"release_date": "2024-03-09",
		"track_number": 7,
		"disc_number":  1,
	}

	formatted := buildFilenameFromTemplate(
		"{artist} - {track:02} - {title} - {date:%Y-%m-%d} - {year}",
		metadata,
	)
	expected := "Artist Name - 07 - Song Name - 2024-03-09 - 2024"
	if formatted != expected {
		t.Fatalf("expected %q, got %q", expected, formatted)
	}
}

func TestBuildFilenameFromTemplate_DateStrftimeFormattingWithYearOnly(t *testing.T) {
	metadata := map[string]interface{}{
		"artist": "Artist Name",
		"title":  "Song Name",
		"date":   "2019",
	}

	formatted := buildFilenameFromTemplate("{date:%Y}-{date:%m}-{date:%d}", metadata)
	expected := "2019-01-01"
	if formatted != expected {
		t.Fatalf("expected %q, got %q", expected, formatted)
	}
}

func TestSanitizeFilenameMatchesDesktopSpacingBehavior(t *testing.T) {
	got := sanitizeFilename(`  "Text In Quotes"?%* / Demo  `)
	want := "Text In Quotes % Demo"
	if got != want {
		t.Fatalf("expected %q, got %q", want, got)
	}
}

func TestSanitizeFilenameFallsBackToUnknownWhenEmpty(t *testing.T) {
	got := sanitizeFilename(`<>:"/\|?*`)
	if got != "Unknown" {
		t.Fatalf("expected %q, got %q", "Unknown", got)
	}
}
