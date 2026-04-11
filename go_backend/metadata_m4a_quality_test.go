package gobackend

import "testing"

func TestParseALACSpecificConfigStandardPayload(t *testing.T) {
	payload := make([]byte, 24)
	payload[5] = 24
	payload[20] = 0x00
	payload[21] = 0x00
	payload[22] = 0xac
	payload[23] = 0x44

	bitDepth, sampleRate, ok := parseALACSpecificConfig(payload)
	if !ok {
		t.Fatal("expected standard ALAC payload to parse")
	}
	if bitDepth != 24 {
		t.Fatalf("bitDepth = %d, want 24", bitDepth)
	}
	if sampleRate != 44100 {
		t.Fatalf("sampleRate = %d, want 44100", sampleRate)
	}
}

func TestParseALACSpecificConfigPayloadWithLeadingFourBytes(t *testing.T) {
	payload := make([]byte, 28)
	payload[9] = 16
	payload[24] = 0x00
	payload[25] = 0x00
	payload[26] = 0xbb
	payload[27] = 0x80

	bitDepth, sampleRate, ok := parseALACSpecificConfig(payload)
	if !ok {
		t.Fatal("expected offset ALAC payload to parse")
	}
	if bitDepth != 16 {
		t.Fatalf("bitDepth = %d, want 16", bitDepth)
	}
	if sampleRate != 48000 {
		t.Fatalf("sampleRate = %d, want 48000", sampleRate)
	}
}

func TestParseALACSpecificConfigRejectsShortPayload(t *testing.T) {
	if _, _, ok := parseALACSpecificConfig(make([]byte, 12)); ok {
		t.Fatal("expected short ALAC payload to be rejected")
	}
}
