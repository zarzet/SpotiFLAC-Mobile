package gobackend

import (
	"strings"
	"unicode"
)

// normalizeLooseTitle collapses separators/punctuation so titles like
// "Doctor / Cops" and "Doctor _ Cops" can still match.
func normalizeLooseTitle(title string) string {
	trimmed := strings.TrimSpace(strings.ToLower(title))
	if trimmed == "" {
		return ""
	}

	var b strings.Builder
	b.Grow(len(trimmed))

	for _, r := range trimmed {
		switch {
		case unicode.IsLetter(r), unicode.IsNumber(r):
			b.WriteRune(r)
		case unicode.IsSpace(r):
			b.WriteByte(' ')
		// Treat common separators as spaces.
		case r == '/', r == '\\', r == '_', r == '-', r == '|', r == '.', r == '&', r == '+':
			b.WriteByte(' ')
		default:
			// Drop other punctuation/symbols (including emoji) for loose matching.
		}
	}

	return strings.Join(strings.Fields(b.String()), " ")
}

func hasAlphaNumericRunes(value string) bool {
	for _, r := range value {
		if unicode.IsLetter(r) || unicode.IsNumber(r) {
			return true
		}
	}
	return false
}
