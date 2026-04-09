package gobackend

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"
)

var (
	invalidChars                   = regexp.MustCompile(`[<>:"/\\|?*\x00-\x1f]`)
	multiUnderscore                = regexp.MustCompile(`_+`)
	formattedNumberPlaceholderExpr = regexp.MustCompile(`\{(track|disc):([0-9]+)\}`)
	dateFormatPlaceholderExpr      = regexp.MustCompile(`\{date:([^{}]+)\}`)
	yearPattern                    = regexp.MustCompile(`\d{4}`)
)

func sanitizeFilename(filename string) string {
	sanitized := strings.ReplaceAll(filename, "/", " ")
	sanitized = invalidChars.ReplaceAllString(sanitized, " ")

	var builder strings.Builder
	for _, r := range sanitized {
		if r < 0x20 && r != 0x09 && r != 0x0A && r != 0x0D {
			continue
		}
		if r == 0x7F {
			continue
		}
		if unicode.IsControl(r) && r != 0x09 && r != 0x0A && r != 0x0D {
			continue
		}
		builder.WriteRune(r)
	}

	sanitized = builder.String()
	sanitized = strings.TrimSpace(sanitized)
	sanitized = strings.Trim(sanitized, ". ")
	sanitized = strings.Join(strings.Fields(sanitized), " ")
	sanitized = multiUnderscore.ReplaceAllString(sanitized, "_")
	sanitized = strings.Trim(sanitized, "_ ")

	if !utf8.ValidString(sanitized) {
		sanitized = strings.ToValidUTF8(sanitized, "_")
	}

	if len(sanitized) > 200 {
		sanitized = sanitized[:200]
		sanitized = strings.TrimSpace(strings.Trim(sanitized, ". "))
		sanitized = strings.Trim(sanitized, "_ ")
	}

	if sanitized == "" {
		return "Unknown"
	}

	return sanitized
}

func buildFilenameFromTemplate(template string, metadata map[string]interface{}) string {
	if template == "" {
		template = "{artist} - {title}"
	}

	result := replaceFormattedNumberPlaceholders(template, metadata)
	result = replaceDateFormatPlaceholders(result, metadata)

	dateValue := getDateValue(metadata)
	yearValue := getString(metadata, "year")
	if yearValue == "" {
		yearValue = extractYear(dateValue)
	}

	placeholders := map[string]string{
		"{title}":     getString(metadata, "title"),
		"{artist}":    getString(metadata, "artist"),
		"{album}":     getString(metadata, "album"),
		"{track}":     formatTrackNumber(getInt(metadata, "track")),
		"{track_raw}": formatRawNumber(getInt(metadata, "track")),
		"{year}":      yearValue,
		"{date}":      dateValue,
		"{disc}":      formatDiscNumber(getInt(metadata, "disc")),
		"{disc_raw}":  formatRawNumber(getInt(metadata, "disc")),
	}

	for placeholder, value := range placeholders {
		result = strings.ReplaceAll(result, placeholder, value)
	}

	return result
}

func replaceFormattedNumberPlaceholders(template string, metadata map[string]interface{}) string {
	return formattedNumberPlaceholderExpr.ReplaceAllStringFunc(template, func(match string) string {
		parts := formattedNumberPlaceholderExpr.FindStringSubmatch(match)
		if len(parts) != 3 {
			return ""
		}

		number := getInt(metadata, parts[1])
		width, err := strconv.Atoi(parts[2])
		if err != nil {
			return ""
		}

		return formatNumberWithWidth(number, width)
	})
}

func replaceDateFormatPlaceholders(template string, metadata map[string]interface{}) string {
	return dateFormatPlaceholderExpr.ReplaceAllStringFunc(template, func(match string) string {
		parts := dateFormatPlaceholderExpr.FindStringSubmatch(match)
		if len(parts) != 2 {
			return ""
		}

		return formatDateWithPattern(getDateValue(metadata), parts[1])
	})
}

func getDateValue(metadata map[string]interface{}) string {
	date := getString(metadata, "date")
	if date != "" {
		return date
	}

	releaseDate := getString(metadata, "release_date")
	if releaseDate != "" {
		return releaseDate
	}

	return getString(metadata, "year")
}

func getString(m map[string]interface{}, key string) string {
	if v, ok := m[key]; ok {
		switch value := v.(type) {
		case string:
			return strings.TrimSpace(value)
		case int:
			return strconv.Itoa(value)
		case int64:
			return strconv.FormatInt(value, 10)
		case float64:
			return strconv.Itoa(int(value))
		}
	}
	return ""
}

func getInt(m map[string]interface{}, key string) int {
	candidateKeys := []string{key}
	switch key {
	case "track":
		candidateKeys = append(candidateKeys, "track_number")
	case "disc":
		candidateKeys = append(candidateKeys, "disc_number")
	}

	for _, candidate := range candidateKeys {
		if v, ok := m[candidate]; ok {
			switch n := v.(type) {
			case int:
				return n
			case int64:
				return int(n)
			case float64:
				return int(n)
			case string:
				parsed, err := strconv.Atoi(strings.TrimSpace(n))
				if err == nil {
					return parsed
				}
			}
		}
	}

	return 0
}

func formatTrackNumber(n int) string {
	if n <= 0 {
		return ""
	}
	return fmt.Sprintf("%02d", n)
}

func formatDiscNumber(n int) string {
	if n <= 0 {
		return ""
	}
	return fmt.Sprintf("%d", n)
}

func formatRawNumber(n int) string {
	if n <= 0 {
		return ""
	}
	return fmt.Sprintf("%d", n)
}

func formatNumberWithWidth(n int, width int) string {
	if n <= 0 || width <= 0 {
		return ""
	}
	if width <= 1 {
		return formatRawNumber(n)
	}
	return fmt.Sprintf("%0*d", width, n)
}

func formatDateWithPattern(rawDate string, strftimePattern string) string {
	if rawDate == "" || strftimePattern == "" {
		return ""
	}

	parsedDate, ok := parseMetadataDate(rawDate)
	if !ok {
		return ""
	}

	goLayout := convertStrftimeToGoLayout(strftimePattern)
	if goLayout == "" {
		return ""
	}

	return parsedDate.Format(goLayout)
}

func parseMetadataDate(rawDate string) (time.Time, bool) {
	clean := strings.TrimSpace(rawDate)
	if clean == "" {
		return time.Time{}, false
	}

	layouts := []string{
		time.RFC3339Nano,
		time.RFC3339,
		"2006-01-02",
		"2006-01",
		"2006",
		"2006/01/02",
		"2006/01",
		"2006.01.02",
		"2006.01",
	}

	for _, layout := range layouts {
		parsed, err := time.Parse(layout, clean)
		if err == nil {
			return parsed, true
		}
	}

	if len(clean) >= 10 {
		parsed, err := time.Parse("2006-01-02", clean[:10])
		if err == nil {
			return parsed, true
		}
	}

	yearMatch := yearPattern.FindString(clean)
	if yearMatch == "" {
		return time.Time{}, false
	}

	year, err := strconv.Atoi(yearMatch)
	if err != nil || year <= 0 {
		return time.Time{}, false
	}

	return time.Date(year, time.January, 1, 0, 0, 0, 0, time.UTC), true
}

func convertStrftimeToGoLayout(pattern string) string {
	if pattern == "" {
		return ""
	}

	var builder strings.Builder
	for i := 0; i < len(pattern); i++ {
		ch := pattern[i]
		if ch != '%' {
			builder.WriteByte(ch)
			continue
		}

		if i+1 >= len(pattern) {
			builder.WriteByte('%')
			break
		}

		i++
		switch pattern[i] {
		case 'Y':
			builder.WriteString("2006")
		case 'y':
			builder.WriteString("06")
		case 'm':
			builder.WriteString("01")
		case 'd':
			builder.WriteString("02")
		case 'b':
			builder.WriteString("Jan")
		case 'B':
			builder.WriteString("January")
		case '%':
			builder.WriteByte('%')
		default:
			builder.WriteByte('%')
			builder.WriteByte(pattern[i])
		}
	}

	return builder.String()
}

func extractYear(date string) string {
	if len(date) >= 4 {
		return date[:4]
	}
	return date
}
