package gobackend

import "testing"

func TestNormalizeLooseTitle_Separators(t *testing.T) {
	got := normalizeLooseTitle("Doctor / Cops")
	if got != "doctor cops" {
		t.Fatalf("expected doctor cops, got %q", got)
	}

	got = normalizeLooseTitle("Doctor _ Cops")
	if got != "doctor cops" {
		t.Fatalf("expected doctor cops, got %q", got)
	}
}

func TestNormalizeLooseTitle_EmojiAndSymbols(t *testing.T) {
	got := normalizeLooseTitle("Music Of The Spheres 🌎✨")
	if got != "music of the spheres" {
		t.Fatalf("expected music of the spheres, got %q", got)
	}
}

func TestTitlesMatch_SeparatorVariants(t *testing.T) {
	if !titlesMatch("Doctor / Cops", "Doctor _ Cops") {
		t.Fatal("expected tidal titlesMatch to accept / vs _ variant")
	}
}

func TestQobuzTitlesMatch_SeparatorVariants(t *testing.T) {
	if !qobuzTitlesMatch("Doctor / Cops", "Doctor _ Cops") {
		t.Fatal("expected qobuzTitlesMatch to accept / vs _ variant")
	}
}
