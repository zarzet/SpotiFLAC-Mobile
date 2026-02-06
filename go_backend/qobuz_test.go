package gobackend

import "testing"

func TestExtractQobuzDownloadURLFromBody(t *testing.T) {
	t.Run("reads nested data.url", func(t *testing.T) {
		body := []byte(`{"success":true,"data":{"url":"https://example.test/audio.flac"}}`)

		got, err := extractQobuzDownloadURLFromBody(body)
		if err != nil {
			t.Fatalf("expected no error, got %v", err)
		}
		if got != "https://example.test/audio.flac" {
			t.Fatalf("unexpected URL: %q", got)
		}
	})

	t.Run("reads top-level url", func(t *testing.T) {
		body := []byte(`{"url":"https://example.test/top.flac"}`)

		got, err := extractQobuzDownloadURLFromBody(body)
		if err != nil {
			t.Fatalf("expected no error, got %v", err)
		}
		if got != "https://example.test/top.flac" {
			t.Fatalf("unexpected URL: %q", got)
		}
	})

	t.Run("returns API error", func(t *testing.T) {
		body := []byte(`{"error":"track not found"}`)

		_, err := extractQobuzDownloadURLFromBody(body)
		if err == nil || err.Error() != "track not found" {
			t.Fatalf("expected track-not-found error, got %v", err)
		}
	})

	t.Run("returns message when success false", func(t *testing.T) {
		body := []byte(`{"success":false,"message":"blocked"}`)

		_, err := extractQobuzDownloadURLFromBody(body)
		if err == nil || err.Error() != "blocked" {
			t.Fatalf("expected blocked error, got %v", err)
		}
	})
}
