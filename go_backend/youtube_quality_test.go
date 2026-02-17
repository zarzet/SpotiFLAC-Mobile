package gobackend

import "testing"

func TestParseYouTubeQualityInput_OpusNormalizesToSupportedBitrates(t *testing.T) {
	format, bitrate, normalized := parseYouTubeQualityInput("opus_160")
	if format != "opus" {
		t.Fatalf("expected opus format, got %s", format)
	}
	if bitrate != 128 {
		t.Fatalf("expected 128 bitrate, got %d", bitrate)
	}
	if normalized != YouTubeQualityOpus128 {
		t.Fatalf("expected %s normalized, got %s", YouTubeQualityOpus128, normalized)
	}
}

func TestParseYouTubeQualityInput_Mp3NormalizesToSupportedBitrates(t *testing.T) {
	format, bitrate, normalized := parseYouTubeQualityInput("mp3_192")
	if format != "mp3" {
		t.Fatalf("expected mp3 format, got %s", format)
	}
	if bitrate != 256 {
		t.Fatalf("expected 256 bitrate, got %d", bitrate)
	}
	if normalized != YouTubeQualityMP3256 {
		t.Fatalf("expected %s normalized, got %s", YouTubeQualityMP3256, normalized)
	}
}

func TestParseYouTubeQualityInput_PicksNearestSupportedBitrate(t *testing.T) {
	_, opusBitrate, _ := parseYouTubeQualityInput("opus_999")
	if opusBitrate != 256 {
		t.Fatalf("expected opus normalization to 256, got %d", opusBitrate)
	}

	_, mp3Bitrate, _ := parseYouTubeQualityInput("mp3_1")
	if mp3Bitrate != 128 {
		t.Fatalf("expected mp3 normalization to 128, got %d", mp3Bitrate)
	}
}
