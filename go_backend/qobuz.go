package gobackend

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

type QobuzDownloader struct {
	client *http.Client
	appID  string
	apiURL string
}

var (
	globalQobuzDownloader *QobuzDownloader
	qobuzDownloaderOnce   sync.Once
	qobuzGetTrackByIDFunc = func(q *QobuzDownloader, trackID int64) (*QobuzTrack, error) {
		return q.GetTrackByID(trackID)
	}
	qobuzSearchTrackByISRCWithDurationFunc = func(q *QobuzDownloader, isrc string, expectedDurationSec int) (*QobuzTrack, error) {
		return q.SearchTrackByISRCWithDuration(isrc, expectedDurationSec)
	}
	qobuzSearchTrackByMetadataWithDurationFunc = func(q *QobuzDownloader, trackName, artistName string, expectedDurationSec int) (*QobuzTrack, error) {
		return q.SearchTrackByMetadataWithDuration(trackName, artistName, expectedDurationSec)
	}
	songLinkCheckTrackAvailabilityFunc = func(client *SongLinkClient, spotifyTrackID string, isrc string) (*TrackAvailability, error) {
		return client.CheckTrackAvailability(spotifyTrackID, isrc)
	}
)

const (
	qobuzAPIBaseURL         = "https://api.zarz.moe/v1/qbz/"
	qobuzTrackGetBaseURL    = qobuzAPIBaseURL + "track/get?track_id="
	qobuzTrackSearchBaseURL = qobuzAPIBaseURL + "track/search?query="
	qobuzAlbumGetBaseURL    = qobuzAPIBaseURL + "album/get?album_id="
	qobuzArtistGetBaseURL   = qobuzAPIBaseURL + "artist/get?artist_id="
	qobuzPlaylistGetBaseURL = qobuzAPIBaseURL + "playlist/get?playlist_id="
	qobuzStoreSearchBaseURL = "https://www.qobuz.com/us-en/search/tracks/"
	qobuzTrackOpenBaseURL   = "https://open.qobuz.com/track/"
	qobuzTrackPlayBaseURL   = "https://play.qobuz.com/track/"
	qobuzStoreBaseURL       = "https://www.qobuz.com/us-en"
	qobuzDownloadAPIURL     = "https://dl.musicdl.me/qobuz/download"
	qobuzZarzDownloadAPIURL = "https://api.zarz.moe/dl/qbz"
	qobuzDabMusicAPIURL     = "https://dabmusic.xyz/api/stream?trackId="
	qobuzDeebAPIURL         = "https://dab.yeet.su/api/stream?trackId="
	qobuzAfkarAPIURL        = "https://qbz.afkarxyz.qzz.io/api/track/"
	qobuzSquidAPIURL        = "https://qobuz.squid.wtf/api/download-music?country=US&track_id="

	qobuzFallbackAPIBaseURL         = "https://api.zarz.moe/v1/qbz2/"
	qobuzFallbackTrackGetBaseURL    = qobuzFallbackAPIBaseURL + "track/get?track_id="
	qobuzFallbackTrackSearchBaseURL = qobuzFallbackAPIBaseURL + "track/search?query="
	qobuzFallbackAlbumGetBaseURL    = qobuzFallbackAPIBaseURL + "album/get?album_id="
	qobuzFallbackArtistGetBaseURL   = qobuzFallbackAPIBaseURL + "artist/get?artist_id="
	qobuzFallbackPlaylistGetBaseURL = qobuzFallbackAPIBaseURL + "playlist/get?playlist_id="
)

var qobuzStoreTrackIDRegex = regexp.MustCompile(`/v4/ajax/popin-add-cart/track/([0-9]+)`)
var qobuzArtistAlbumIDRegex = regexp.MustCompile(`data-itemtype="album"\s+data-itemId="([A-Za-z0-9]+)"`)
var qobuzLocaleSegmentRegex = regexp.MustCompile(`^[a-z]{2}-[a-z]{2}$`)

type QobuzTrack struct {
	ID                  int64   `json:"id"`
	Title               string  `json:"title"`
	ISRC                string  `json:"isrc"`
	Duration            int     `json:"duration"`
	TrackNumber         int     `json:"track_number"`
	MediaNumber         int     `json:"media_number"`
	MaximumBitDepth     int     `json:"maximum_bit_depth"`
	MaximumSamplingRate float64 `json:"maximum_sampling_rate"`
	Version             string  `json:"version"`
	Album               struct {
		ID          string `json:"id"`
		QobuzID     int64  `json:"qobuz_id"`
		TracksCount int    `json:"tracks_count"`
		Title       string `json:"title"`
		ReleaseDate string `json:"release_date_original"`
		ProductType string `json:"product_type"`
		ReleaseType string `json:"release_type"`
		Artist      struct {
			ID   int64  `json:"id"`
			Name string `json:"name"`
		} `json:"artist"`
		Artists []qobuzArtistRef `json:"artists"`
		Image   struct {
			Thumbnail string `json:"thumbnail"`
			Small     string `json:"small"`
			Large     string `json:"large"`
		} `json:"image"`
	} `json:"album"`
	Performer struct {
		ID   int64  `json:"id"`
		Name string `json:"name"`
	} `json:"performer"`
	Composer struct {
		ID   int64  `json:"id"`
		Name string `json:"name"`
	} `json:"composer"`
}

type qobuzImageSet struct {
	Thumbnail string `json:"thumbnail"`
	Small     string `json:"small"`
	Large     string `json:"large"`
}

type qobuzArtistRef struct {
	ID   int64  `json:"id"`
	Name string `json:"name"`
	Slug string `json:"slug"`
}

type qobuzLabelRef struct {
	Name string `json:"name"`
}

type qobuzGenreRef struct {
	Name string `json:"name"`
}

type qobuzAlbumDetails struct {
	ID                  string           `json:"id"`
	QobuzID             int64            `json:"qobuz_id"`
	Title               string           `json:"title"`
	ReleaseDateOriginal string           `json:"release_date_original"`
	TracksCount         int              `json:"tracks_count"`
	ProductType         string           `json:"product_type"`
	ReleaseType         string           `json:"release_type"`
	Image               qobuzImageSet    `json:"image"`
	Artist              qobuzArtistRef   `json:"artist"`
	Artists             []qobuzArtistRef `json:"artists"`
	Genre               qobuzGenreRef    `json:"genre"`
	Label               qobuzLabelRef    `json:"label"`
	Copyright           string           `json:"copyright"`
	Tracks              struct {
		Items []QobuzTrack `json:"items"`
	} `json:"tracks"`
}

type qobuzArtistDetails struct {
	ID    int64         `json:"id"`
	Name  string        `json:"name"`
	Slug  string        `json:"slug"`
	Image qobuzImageSet `json:"image"`
}

type qobuzPlaylistDetails struct {
	ID                 int64    `json:"id"`
	Name               string   `json:"name"`
	Description        string   `json:"description"`
	ImageRectangle     []string `json:"image_rectangle"`
	ImageRectangleMini []string `json:"image_rectangle_mini"`
	TracksCount        int      `json:"tracks_count"`
	Owner              struct {
		ID   int64  `json:"id"`
		Name string `json:"name"`
	} `json:"owner"`
	Tracks struct {
		Total  int          `json:"total"`
		Offset int          `json:"offset"`
		Limit  int          `json:"limit"`
		Items  []QobuzTrack `json:"items"`
	} `json:"tracks"`
}

func qobuzFirstNonEmpty(values ...string) string {
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed != "" {
			return trimmed
		}
	}
	return ""
}

func qobuzPrefixedID(id string) string {
	trimmed := strings.TrimSpace(id)
	if trimmed == "" {
		return ""
	}
	if strings.HasPrefix(trimmed, "qobuz:") {
		return trimmed
	}
	return "qobuz:" + trimmed
}

func qobuzPrefixedNumericID(id int64) string {
	if id <= 0 {
		return ""
	}
	return fmt.Sprintf("qobuz:%d", id)
}

func qobuzNormalizeReleaseDate(value string) string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return ""
	}
	if _, err := time.Parse("2006-01-02", trimmed); err == nil {
		return trimmed
	}
	if parsed, err := time.Parse("Jan 2, 2006", trimmed); err == nil {
		return parsed.Format("2006-01-02")
	}
	return trimmed
}

func qobuzNormalizeAlbumType(releaseType, productType string, totalTracks int) string {
	kind := strings.ToLower(strings.TrimSpace(releaseType))
	if kind == "" {
		kind = strings.ToLower(strings.TrimSpace(productType))
	}
	switch kind {
	case "album", "single", "ep", "compilation":
		return kind
	}
	if totalTracks > 0 && totalTracks <= 3 {
		return "single"
	}
	return "album"
}

func qobuzArtistsDisplayName(artists []qobuzArtistRef, fallback string) string {
	names := make([]string, 0, len(artists))
	seen := make(map[string]struct{}, len(artists))
	for _, artist := range artists {
		name := strings.TrimSpace(artist.Name)
		if name == "" {
			continue
		}
		key := strings.ToLower(name)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		names = append(names, name)
	}
	if len(names) == 0 {
		return strings.TrimSpace(fallback)
	}
	return strings.Join(names, ", ")
}

func qobuzTrackDisplayTitle(track *QobuzTrack) string {
	if track == nil {
		return ""
	}
	title := strings.TrimSpace(track.Title)
	version := strings.TrimSpace(track.Version)
	if title == "" || version == "" {
		return title
	}
	return fmt.Sprintf("%s (%s)", title, version)
}

var qobuzImageSizeRe = regexp.MustCompile(`_\d+\.jpg$`)

func qobuzUpscaleImageURL(url string) string {
	if url == "" {
		return ""
	}
	return qobuzImageSizeRe.ReplaceAllString(url, "_max.jpg")
}

func qobuzTrackAlbumImage(track *QobuzTrack) string {
	if track == nil {
		return ""
	}
	return qobuzUpscaleImageURL(qobuzFirstNonEmpty(
		track.Album.Image.Large,
		track.Album.Image.Small,
		track.Album.Image.Thumbnail,
	))
}

func qobuzAlbumImage(album *qobuzAlbumDetails) string {
	if album == nil {
		return ""
	}
	return qobuzUpscaleImageURL(qobuzFirstNonEmpty(
		album.Image.Large,
		album.Image.Small,
		album.Image.Thumbnail,
	))
}

func qobuzTrackArtistID(track *QobuzTrack) string {
	if track == nil {
		return ""
	}
	if track.Performer.ID > 0 {
		return qobuzPrefixedNumericID(track.Performer.ID)
	}
	return qobuzPrefixedNumericID(track.Album.Artist.ID)
}

func qobuzTrackArtistName(track *QobuzTrack) string {
	if track == nil {
		return ""
	}
	return strings.TrimSpace(track.Performer.Name)
}

func qobuzTrackAlbumArtist(track *QobuzTrack) string {
	if track == nil {
		return ""
	}
	return qobuzArtistsDisplayName(track.Album.Artists, track.Album.Artist.Name)
}

func qobuzTrackAlbumType(track *QobuzTrack) string {
	if track == nil {
		return "album"
	}
	return qobuzNormalizeAlbumType(
		track.Album.ReleaseType,
		track.Album.ProductType,
		track.Album.TracksCount,
	)
}

func qobuzTrackToTrackMetadata(track *QobuzTrack) TrackMetadata {
	if track == nil {
		return TrackMetadata{}
	}
	return TrackMetadata{
		SpotifyID:   qobuzPrefixedNumericID(track.ID),
		Artists:     qobuzTrackArtistName(track),
		Name:        qobuzTrackDisplayTitle(track),
		AlbumName:   strings.TrimSpace(track.Album.Title),
		AlbumArtist: qobuzTrackAlbumArtist(track),
		DurationMS:  track.Duration * 1000,
		Images:      qobuzTrackAlbumImage(track),
		ReleaseDate: qobuzNormalizeReleaseDate(track.Album.ReleaseDate),
		TrackNumber: track.TrackNumber,
		TotalTracks: track.Album.TracksCount,
		DiscNumber:  track.MediaNumber,
		ExternalURL: fmt.Sprintf("%s%d", qobuzTrackPlayBaseURL, track.ID),
		ISRC:        strings.TrimSpace(track.ISRC),
		AlbumID:     qobuzPrefixedID(track.Album.ID),
		ArtistID:    qobuzTrackArtistID(track),
		AlbumType:   qobuzTrackAlbumType(track),
		Composer:    strings.TrimSpace(track.Composer.Name),
	}
}

func qobuzTrackToAlbumTrackMetadata(track *QobuzTrack) AlbumTrackMetadata {
	if track == nil {
		return AlbumTrackMetadata{}
	}
	return AlbumTrackMetadata{
		SpotifyID:   qobuzPrefixedNumericID(track.ID),
		Artists:     qobuzTrackArtistName(track),
		Name:        qobuzTrackDisplayTitle(track),
		AlbumName:   strings.TrimSpace(track.Album.Title),
		AlbumArtist: qobuzTrackAlbumArtist(track),
		DurationMS:  track.Duration * 1000,
		Images:      qobuzTrackAlbumImage(track),
		ReleaseDate: qobuzNormalizeReleaseDate(track.Album.ReleaseDate),
		TrackNumber: track.TrackNumber,
		TotalTracks: track.Album.TracksCount,
		DiscNumber:  track.MediaNumber,
		ExternalURL: fmt.Sprintf("%s%d", qobuzTrackPlayBaseURL, track.ID),
		ISRC:        strings.TrimSpace(track.ISRC),
		AlbumID:     qobuzPrefixedID(track.Album.ID),
		AlbumURL:    fmt.Sprintf("https://play.qobuz.com/album/%s", strings.TrimSpace(track.Album.ID)),
		AlbumType:   qobuzTrackAlbumType(track),
		Composer:    strings.TrimSpace(track.Composer.Name),
	}
}

func qobuzAlbumToAlbumInfo(album *qobuzAlbumDetails) AlbumInfoMetadata {
	if album == nil {
		return AlbumInfoMetadata{}
	}
	return AlbumInfoMetadata{
		TotalTracks: album.TracksCount,
		Name:        strings.TrimSpace(album.Title),
		ReleaseDate: qobuzNormalizeReleaseDate(album.ReleaseDateOriginal),
		Artists:     qobuzArtistsDisplayName(album.Artists, album.Artist.Name),
		ArtistId:    qobuzPrefixedNumericID(album.Artist.ID),
		Images:      qobuzAlbumImage(album),
		Genre:       strings.TrimSpace(album.Genre.Name),
		Label:       strings.TrimSpace(album.Label.Name),
		Copyright:   strings.TrimSpace(album.Copyright),
	}
}

func qobuzAlbumToArtistAlbum(album *qobuzAlbumDetails) ArtistAlbumMetadata {
	if album == nil {
		return ArtistAlbumMetadata{}
	}
	return ArtistAlbumMetadata{
		ID:          qobuzPrefixedID(album.ID),
		Name:        strings.TrimSpace(album.Title),
		ReleaseDate: qobuzNormalizeReleaseDate(album.ReleaseDateOriginal),
		TotalTracks: album.TracksCount,
		Images:      qobuzAlbumImage(album),
		AlbumType:   qobuzNormalizeAlbumType(album.ReleaseType, album.ProductType, album.TracksCount),
		Artists:     qobuzArtistsDisplayName(album.Artists, album.Artist.Name),
	}
}

func qobuzSplitPathSegments(path string) []string {
	rawSegments := strings.Split(strings.TrimSpace(path), "/")
	segments := make([]string, 0, len(rawSegments))
	for _, segment := range rawSegments {
		trimmed := strings.TrimSpace(segment)
		if trimmed == "" {
			continue
		}
		segments = append(segments, trimmed)
	}
	if len(segments) > 0 && qobuzLocaleSegmentRegex.MatchString(strings.ToLower(segments[0])) {
		return segments[1:]
	}
	return segments
}

func qobuzResourceTypeFromSegment(segment string) string {
	switch strings.ToLower(strings.TrimSpace(segment)) {
	case "album":
		return "album"
	case "interpreter", "artist":
		return "artist"
	case "playlist", "playlists":
		return "playlist"
	case "track":
		return "track"
	default:
		return ""
	}
}

func parseQobuzURL(input string) (string, string, error) {
	raw := strings.TrimSpace(input)
	if raw == "" {
		return "", "", fmt.Errorf("empty Qobuz URL")
	}

	if strings.HasPrefix(strings.ToLower(raw), "qobuzapp://") {
		parsed, err := url.Parse(raw)
		if err != nil {
			return "", "", err
		}
		resourceType := qobuzResourceTypeFromSegment(parsed.Host)
		resourceID := strings.Trim(strings.TrimSpace(parsed.Path), "/")
		if resourceType == "" || resourceID == "" {
			return "", "", fmt.Errorf("invalid or unsupported Qobuz URL")
		}
		return resourceType, resourceID, nil
	}

	parsed, err := url.Parse(raw)
	if err != nil || parsed.Host == "" {
		if !strings.Contains(raw, "://") {
			parsed, err = url.Parse("https://" + raw)
		}
	}
	if err != nil || parsed == nil || parsed.Host == "" {
		return "", "", fmt.Errorf("invalid or unsupported Qobuz URL")
	}

	host := strings.ToLower(parsed.Host)
	if host != "qobuz.com" && host != "www.qobuz.com" && host != "play.qobuz.com" {
		return "", "", fmt.Errorf("invalid or unsupported Qobuz URL")
	}

	segments := qobuzSplitPathSegments(parsed.Path)
	if len(segments) < 2 {
		return "", "", fmt.Errorf("invalid or unsupported Qobuz URL")
	}

	resourceType := qobuzResourceTypeFromSegment(segments[0])
	resourceID := strings.TrimSpace(segments[len(segments)-1])
	if resourceType == "" || resourceID == "" {
		return "", "", fmt.Errorf("invalid or unsupported Qobuz URL")
	}

	return resourceType, resourceID, nil
}

func qobuzArtistsMatch(expectedArtist, foundArtist string) bool {
	normExpected := normalizeLooseArtistName(expectedArtist)
	normFound := normalizeLooseArtistName(foundArtist)

	if normExpected == normFound {
		return true
	}

	if strings.Contains(normExpected, normFound) || strings.Contains(normFound, normExpected) {
		return true
	}

	expectedArtists := qobuzSplitArtists(normExpected)
	foundArtists := qobuzSplitArtists(normFound)

	for _, exp := range expectedArtists {
		for _, fnd := range foundArtists {
			if exp == fnd {
				return true
			}
			if strings.Contains(exp, fnd) || strings.Contains(fnd, exp) {
				return true
			}
			if qobuzSameWordsUnordered(exp, fnd) {
				GoLog("[Qobuz] Artist names have same words in different order: '%s' vs '%s'\n", exp, fnd)
				return true
			}
		}
	}

	expectedLatin := qobuzIsLatinScript(expectedArtist)
	foundLatin := qobuzIsLatinScript(foundArtist)
	if expectedLatin != foundLatin {
		GoLog("[Qobuz] Artist names in different scripts, assuming match: '%s' vs '%s'\n", expectedArtist, foundArtist)
		return true
	}

	return false
}

func qobuzSplitArtists(artists string) []string {
	normalized := artists
	normalized = strings.ReplaceAll(normalized, " feat. ", "|")
	normalized = strings.ReplaceAll(normalized, " feat ", "|")
	normalized = strings.ReplaceAll(normalized, " ft. ", "|")
	normalized = strings.ReplaceAll(normalized, " ft ", "|")
	normalized = strings.ReplaceAll(normalized, " & ", "|")
	normalized = strings.ReplaceAll(normalized, " and ", "|")
	normalized = strings.ReplaceAll(normalized, ", ", "|")
	normalized = strings.ReplaceAll(normalized, " x ", "|")

	parts := strings.Split(normalized, "|")
	result := make([]string, 0, len(parts))
	for _, p := range parts {
		trimmed := strings.TrimSpace(p)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func qobuzSameWordsUnordered(a, b string) bool {
	wordsA := strings.Fields(a)
	wordsB := strings.Fields(b)

	if len(wordsA) != len(wordsB) || len(wordsA) == 0 {
		return false
	}

	sortedA := make([]string, len(wordsA))
	sortedB := make([]string, len(wordsB))
	copy(sortedA, wordsA)
	copy(sortedB, wordsB)

	for i := 0; i < len(sortedA)-1; i++ {
		for j := i + 1; j < len(sortedA); j++ {
			if sortedA[i] > sortedA[j] {
				sortedA[i], sortedA[j] = sortedA[j], sortedA[i]
			}
			if sortedB[i] > sortedB[j] {
				sortedB[i], sortedB[j] = sortedB[j], sortedB[i]
			}
		}
	}

	for i := range sortedA {
		if sortedA[i] != sortedB[i] {
			return false
		}
	}
	return true
}

func qobuzTitlesMatch(expectedTitle, foundTitle string) bool {
	normExpected := strings.ToLower(strings.TrimSpace(expectedTitle))
	normFound := strings.ToLower(strings.TrimSpace(foundTitle))

	if normExpected == normFound {
		return true
	}

	if strings.Contains(normExpected, normFound) || strings.Contains(normFound, normExpected) {
		return true
	}

	cleanExpected := qobuzCleanTitle(normExpected)
	cleanFound := qobuzCleanTitle(normFound)

	if cleanExpected == cleanFound {
		return true
	}

	if cleanExpected != "" && cleanFound != "" {
		if strings.Contains(cleanExpected, cleanFound) || strings.Contains(cleanFound, cleanExpected) {
			return true
		}
	}

	coreExpected := qobuzExtractCoreTitle(normExpected)
	coreFound := qobuzExtractCoreTitle(normFound)

	if coreExpected != "" && coreFound != "" && coreExpected == coreFound {
		return true
	}

	looseExpected := normalizeLooseTitle(normExpected)
	looseFound := normalizeLooseTitle(normFound)
	if looseExpected != "" && looseFound != "" {
		if looseExpected == looseFound {
			return true
		}
		if strings.Contains(looseExpected, looseFound) || strings.Contains(looseFound, looseExpected) {
			return true
		}
	}

	// Emoji/symbol-only titles must be matched strictly to avoid false positives
	// like mapping "🪐" to unrelated textual tracks.
	if (!hasAlphaNumericRunes(expectedTitle) || !hasAlphaNumericRunes(foundTitle)) &&
		strings.TrimSpace(expectedTitle) != "" &&
		strings.TrimSpace(foundTitle) != "" {
		expectedSymbols := normalizeSymbolOnlyTitle(expectedTitle)
		foundSymbols := normalizeSymbolOnlyTitle(foundTitle)
		if expectedSymbols != "" && foundSymbols != "" && expectedSymbols == foundSymbols {
			GoLog("[Qobuz] Symbol-heavy title matched strictly: '%s' vs '%s'\n", expectedTitle, foundTitle)
			return true
		}
		GoLog("[Qobuz] Symbol-heavy title mismatch: '%s' vs '%s'\n", expectedTitle, foundTitle)
		return false
	}

	expectedLatin := qobuzIsLatinScript(expectedTitle)
	foundLatin := qobuzIsLatinScript(foundTitle)
	if expectedLatin != foundLatin {
		GoLog("[Qobuz] Titles in different scripts, assuming match: '%s' vs '%s'\n", expectedTitle, foundTitle)
		return true
	}

	return false
}

func qobuzExtractCoreTitle(title string) string {
	parenIdx := strings.Index(title, "(")
	bracketIdx := strings.Index(title, "[")
	dashIdx := strings.Index(title, " - ")

	cutIdx := len(title)
	if parenIdx > 0 && parenIdx < cutIdx {
		cutIdx = parenIdx
	}
	if bracketIdx > 0 && bracketIdx < cutIdx {
		cutIdx = bracketIdx
	}
	if dashIdx > 0 && dashIdx < cutIdx {
		cutIdx = dashIdx
	}

	return strings.TrimSpace(title[:cutIdx])
}

func qobuzCleanTitle(title string) string {
	cleaned := title

	versionPatterns := []string{
		"remaster", "remastered", "deluxe", "bonus", "single",
		"album version", "radio edit", "original mix", "extended",
		"club mix", "remix", "live", "acoustic", "demo",
	}

	for {
		startParen := strings.LastIndex(cleaned, "(")
		endParen := strings.LastIndex(cleaned, ")")
		if startParen >= 0 && endParen > startParen {
			content := strings.ToLower(cleaned[startParen+1 : endParen])
			isVersionIndicator := false
			for _, pattern := range versionPatterns {
				if strings.Contains(content, pattern) {
					isVersionIndicator = true
					break
				}
			}
			if isVersionIndicator {
				cleaned = strings.TrimSpace(cleaned[:startParen]) + cleaned[endParen+1:]
				continue
			}
		}
		break
	}

	for {
		startBracket := strings.LastIndex(cleaned, "[")
		endBracket := strings.LastIndex(cleaned, "]")
		if startBracket >= 0 && endBracket > startBracket {
			content := strings.ToLower(cleaned[startBracket+1 : endBracket])
			isVersionIndicator := false
			for _, pattern := range versionPatterns {
				if strings.Contains(content, pattern) {
					isVersionIndicator = true
					break
				}
			}
			if isVersionIndicator {
				cleaned = strings.TrimSpace(cleaned[:startBracket]) + cleaned[endBracket+1:]
				continue
			}
		}
		break
	}

	dashPatterns := []string{
		" - remaster", " - remastered", " - single version", " - radio edit",
		" - live", " - acoustic", " - demo", " - remix",
	}
	for _, pattern := range dashPatterns {
		if strings.HasSuffix(strings.ToLower(cleaned), pattern) {
			cleaned = cleaned[:len(cleaned)-len(pattern)]
		}
	}

	for strings.Contains(cleaned, "  ") {
		cleaned = strings.ReplaceAll(cleaned, "  ", " ")
	}

	return strings.TrimSpace(cleaned)
}

func qobuzIsLatinScript(s string) bool {
	for _, r := range s {
		if r < 128 {
			continue
		}
		if (r >= 0x0100 && r <= 0x024F) ||
			(r >= 0x1E00 && r <= 0x1EFF) ||
			(r >= 0x00C0 && r <= 0x00FF) {
			continue
		}
		if (r >= 0x4E00 && r <= 0x9FFF) ||
			(r >= 0x3040 && r <= 0x309F) ||
			(r >= 0x30A0 && r <= 0x30FF) ||
			(r >= 0xAC00 && r <= 0xD7AF) ||
			(r >= 0x0600 && r <= 0x06FF) ||
			(r >= 0x0400 && r <= 0x04FF) {
			return false
		}
	}
	return true
}

func containsQueryQobuz(queries []string, query string) bool {
	for _, q := range queries {
		if q == query {
			return true
		}
	}
	return false
}

func NewQobuzDownloader() *QobuzDownloader {
	qobuzDownloaderOnce.Do(func() {
		globalQobuzDownloader = &QobuzDownloader{
			client: NewHTTPClientWithTimeout(DefaultTimeout),
			appID:  "798273057",
		}
	})
	return globalQobuzDownloader
}

func (q *QobuzDownloader) GetTrackByID(trackID int64) (*QobuzTrack, error) {
	trackURL := fmt.Sprintf("%s%d&app_id=%s", qobuzTrackGetBaseURL, trackID, q.appID)

	req, err := http.NewRequest("GET", trackURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		if isQobuzPrimaryUnavailable(err) {
			GoLog("[Qobuz] Primary API unavailable for track %d, trying qbz2 fallback: %v\n", trackID, err)
			return q.getTrackByIDViaMusicDL(trackID)
		}
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		primaryErr := fmt.Errorf("get track failed: HTTP %d", resp.StatusCode)
		if isQobuzPrimaryUnavailable(primaryErr) {
			GoLog("[Qobuz] Primary API unavailable for track %d, trying qbz2 fallback: %v\n", trackID, primaryErr)
			return q.getTrackByIDViaMusicDL(trackID)
		}
		return nil, primaryErr
	}

	var track QobuzTrack
	if err := json.NewDecoder(resp.Body).Decode(&track); err != nil {
		return nil, err
	}

	return &track, nil
}

func (q *QobuzDownloader) getTrackByIDViaMusicDL(trackID int64) (*QobuzTrack, error) {
	requestURL := fmt.Sprintf("%s%d", qobuzFallbackTrackGetBaseURL, trackID)
	var track QobuzTrack
	if err := q.getQobuzJSON(requestURL, &track); err != nil {
		return nil, fmt.Errorf("qbz2 fallback also failed for track %d: %w", trackID, err)
	}
	GoLog("[Qobuz] qbz2 fallback succeeded for track %d\n", trackID)
	return &track, nil
}

func (q *QobuzDownloader) getQobuzJSON(requestURL string, target interface{}) error {
	req, err := http.NewRequest("GET", requestURL, nil)
	if err != nil {
		return err
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return fmt.Errorf("qobuz request failed: HTTP %d (%s)", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	return json.NewDecoder(resp.Body).Decode(target)
}

func (q *QobuzDownloader) getQobuzBody(requestURL string) ([]byte, error) {
	req, err := http.NewRequest("GET", requestURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return nil, fmt.Errorf("qobuz request failed: HTTP %d (%s)", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	return io.ReadAll(resp.Body)
}

func isQobuzPrimaryUnavailable(err error) bool {
	if err == nil {
		return false
	}
	errStr := err.Error()
	return strings.Contains(errStr, "HTTP 429") ||
		strings.Contains(errStr, "HTTP 5") ||
		strings.Contains(errStr, "rate limit") ||
		strings.Contains(errStr, "connection refused") ||
		strings.Contains(errStr, "no such host") ||
		strings.Contains(errStr, "i/o timeout") ||
		strings.Contains(errStr, "deadline exceeded") ||
		strings.Contains(errStr, "EOF") ||
		strings.Contains(errStr, "connection reset") ||
		strings.Contains(errStr, "TLS handshake") ||
		strings.Contains(errStr, "server misbehaving") ||
		strings.Contains(errStr, "network is unreachable")
}

func extractQobuzAlbumIDsFromArtistHTML(body []byte) []string {
	matches := qobuzArtistAlbumIDRegex.FindAllSubmatch(body, -1)
	if len(matches) == 0 {
		return nil
	}

	albumIDs := make([]string, 0, len(matches))
	seen := make(map[string]struct{}, len(matches))
	for _, match := range matches {
		if len(match) < 2 {
			continue
		}
		albumID := strings.TrimSpace(string(match[1]))
		if albumID == "" {
			continue
		}
		if _, ok := seen[albumID]; ok {
			continue
		}
		seen[albumID] = struct{}{}
		albumIDs = append(albumIDs, albumID)
	}
	return albumIDs
}

func (q *QobuzDownloader) getAlbumDetails(albumID string) (*qobuzAlbumDetails, error) {
	requestURL := fmt.Sprintf("%s%s&app_id=%s", qobuzAlbumGetBaseURL, url.QueryEscape(strings.TrimSpace(albumID)), q.appID)
	var album qobuzAlbumDetails
	if err := q.getQobuzJSON(requestURL, &album); err != nil {
		if isQobuzPrimaryUnavailable(err) {
			GoLog("[Qobuz] Primary API unavailable for album %s, trying qbz2 fallback: %v\n", albumID, err)
			return q.getAlbumDetailsViaMusicDL(albumID)
		}
		return nil, err
	}
	return &album, nil
}

func (q *QobuzDownloader) getAlbumDetailsViaMusicDL(albumID string) (*qobuzAlbumDetails, error) {
	requestURL := fmt.Sprintf("%s%s", qobuzFallbackAlbumGetBaseURL, url.QueryEscape(strings.TrimSpace(albumID)))
	var album qobuzAlbumDetails
	if err := q.getQobuzJSON(requestURL, &album); err != nil {
		return nil, fmt.Errorf("qbz2 fallback also failed for album %s: %w", albumID, err)
	}
	GoLog("[Qobuz] qbz2 fallback succeeded for album %s\n", albumID)
	return &album, nil
}

func (q *QobuzDownloader) getArtistDetails(artistID string) (*qobuzArtistDetails, error) {
	requestURL := fmt.Sprintf("%s%s&app_id=%s", qobuzArtistGetBaseURL, url.QueryEscape(strings.TrimSpace(artistID)), q.appID)
	var artist qobuzArtistDetails
	if err := q.getQobuzJSON(requestURL, &artist); err != nil {
		if isQobuzPrimaryUnavailable(err) {
			GoLog("[Qobuz] Primary API unavailable for artist %s, trying qbz2 fallback: %v\n", artistID, err)
			return q.getArtistDetailsViaMusicDL(artistID)
		}
		return nil, err
	}
	return &artist, nil
}

func (q *QobuzDownloader) getArtistDetailsViaMusicDL(artistID string) (*qobuzArtistDetails, error) {
	requestURL := fmt.Sprintf("%s%s", qobuzFallbackArtistGetBaseURL, url.QueryEscape(strings.TrimSpace(artistID)))
	var artist qobuzArtistDetails
	if err := q.getQobuzJSON(requestURL, &artist); err != nil {
		return nil, fmt.Errorf("qbz2 fallback also failed for artist %s: %w", artistID, err)
	}
	GoLog("[Qobuz] qbz2 fallback succeeded for artist %s\n", artistID)
	return &artist, nil
}

func (q *QobuzDownloader) getPlaylistDetailsPage(playlistID string, limit, offset int) (*qobuzPlaylistDetails, error) {
	requestURL := fmt.Sprintf(
		"%s%s&extra=tracks&limit=%d&offset=%d&app_id=%s",
		qobuzPlaylistGetBaseURL,
		url.QueryEscape(strings.TrimSpace(playlistID)),
		limit,
		offset,
		q.appID,
	)
	var playlist qobuzPlaylistDetails
	if err := q.getQobuzJSON(requestURL, &playlist); err != nil {
		if isQobuzPrimaryUnavailable(err) {
			GoLog("[Qobuz] Primary API unavailable for playlist %s, trying qbz2 fallback: %v\n", playlistID, err)
			return q.getPlaylistDetailsPageViaMusicDL(playlistID, limit, offset)
		}
		return nil, err
	}
	return &playlist, nil
}

func (q *QobuzDownloader) getPlaylistDetailsPageViaMusicDL(playlistID string, limit, offset int) (*qobuzPlaylistDetails, error) {
	requestURL := fmt.Sprintf(
		"%s%s&limit=%d&offset=%d",
		qobuzFallbackPlaylistGetBaseURL,
		url.QueryEscape(strings.TrimSpace(playlistID)),
		limit,
		offset,
	)
	var playlist qobuzPlaylistDetails
	if err := q.getQobuzJSON(requestURL, &playlist); err != nil {
		return nil, fmt.Errorf("qbz2 fallback also failed for playlist %s: %w", playlistID, err)
	}
	GoLog("[Qobuz] qbz2 fallback succeeded for playlist %s (offset=%d)\n", playlistID, offset)
	return &playlist, nil
}

func (q *QobuzDownloader) getArtistAlbumIDs(artistID string) ([]string, error) {
	artist, err := q.getArtistDetails(artistID)
	if err != nil {
		return nil, err
	}

	slug := strings.TrimSpace(artist.Slug)
	if slug == "" {
		slug = "artist"
	}
	requestURL := fmt.Sprintf("%s/interpreter/%s/%d", qobuzStoreBaseURL, url.PathEscape(slug), artist.ID)
	body, err := q.getQobuzBody(requestURL)
	if err != nil {
		return nil, err
	}

	albumIDs := extractQobuzAlbumIDsFromArtistHTML(body)
	if len(albumIDs) == 0 {
		return nil, fmt.Errorf("artist page did not contain album IDs")
	}
	return albumIDs, nil
}

func (q *QobuzDownloader) GetTrackMetadata(resourceID string) (*TrackResponse, error) {
	trackID, err := strconv.ParseInt(strings.TrimSpace(resourceID), 10, 64)
	if err != nil || trackID <= 0 {
		return nil, fmt.Errorf("invalid Qobuz track ID: %s", resourceID)
	}

	track, err := q.GetTrackByID(trackID)
	if err != nil {
		return nil, err
	}

	return &TrackResponse{Track: qobuzTrackToTrackMetadata(track)}, nil
}

func (q *QobuzDownloader) GetAlbumMetadata(resourceID string) (*AlbumResponsePayload, error) {
	album, err := q.getAlbumDetails(resourceID)
	if err != nil {
		return nil, err
	}

	tracks := make([]AlbumTrackMetadata, 0, len(album.Tracks.Items))
	totalDiscs := 0
	for i := range album.Tracks.Items {
		track := &album.Tracks.Items[i]
		track.Album.ID = album.ID
		track.Album.Title = album.Title
		track.Album.ReleaseDate = album.ReleaseDateOriginal
		track.Album.Image = qobuzImageSet{
			Thumbnail: album.Image.Thumbnail,
			Small:     album.Image.Small,
			Large:     album.Image.Large,
		}
		track.Album.TracksCount = album.TracksCount
		if track.MediaNumber > totalDiscs {
			totalDiscs = track.MediaNumber
		}
		tracks = append(tracks, qobuzTrackToAlbumTrackMetadata(track))
	}
	for i := range tracks {
		tracks[i].TotalDiscs = totalDiscs
	}

	return &AlbumResponsePayload{
		AlbumInfo: qobuzAlbumToAlbumInfo(album),
		TrackList: tracks,
	}, nil
}

func (q *QobuzDownloader) GetPlaylistMetadata(resourceID string) (*PlaylistResponsePayload, error) {
	const pageSize = 50

	offset := 0
	var playlistInfo PlaylistInfoMetadata
	tracks := make([]AlbumTrackMetadata, 0, pageSize)

	for {
		page, err := q.getPlaylistDetailsPage(resourceID, pageSize, offset)
		if err != nil {
			return nil, err
		}

		if offset == 0 {
			total := page.Tracks.Total
			if total == 0 {
				total = page.TracksCount
			}
			playlistInfo.Tracks.Total = total
			playlistInfo.Owner.DisplayName = strings.TrimSpace(page.Owner.Name)
			playlistInfo.Owner.Name = strings.TrimSpace(page.Name)
			playlistInfo.Owner.Images = qobuzFirstNonEmpty(page.ImageRectangle...)
		}

		for i := range page.Tracks.Items {
			tracks = append(tracks, qobuzTrackToAlbumTrackMetadata(&page.Tracks.Items[i]))
		}

		if len(page.Tracks.Items) == 0 ||
			offset+len(page.Tracks.Items) >= playlistInfo.Tracks.Total ||
			len(page.Tracks.Items) < pageSize {
			break
		}
		offset += len(page.Tracks.Items)
	}

	return &PlaylistResponsePayload{
		PlaylistInfo: playlistInfo,
		TrackList:    tracks,
	}, nil
}

func (q *QobuzDownloader) GetArtistMetadata(resourceID string) (*ArtistResponsePayload, error) {
	artist, err := q.getArtistDetails(resourceID)
	if err != nil {
		return nil, err
	}

	albumIDs, err := q.getArtistAlbumIDs(resourceID)
	if err != nil {
		return nil, err
	}

	albums := make([]ArtistAlbumMetadata, 0, len(albumIDs))
	for _, albumID := range albumIDs {
		album, albumErr := q.getAlbumDetails(albumID)
		if albumErr != nil {
			GoLog("[Qobuz] Skipping artist album %s: %v\n", albumID, albumErr)
			continue
		}
		albums = append(albums, qobuzAlbumToArtistAlbum(album))
	}

	return &ArtistResponsePayload{
		ArtistInfo: ArtistInfoMetadata{
			ID:     qobuzPrefixedNumericID(artist.ID),
			Name:   strings.TrimSpace(artist.Name),
			Images: qobuzFirstNonEmpty(artist.Image.Large, artist.Image.Small, artist.Image.Thumbnail),
		},
		Albums: albums,
	}, nil
}

func (q *QobuzDownloader) GetAvailableAPIs() []string {
	return []string{
		qobuzDownloadAPIURL,
		qobuzZarzDownloadAPIURL,
		qobuzDabMusicAPIURL,
		qobuzDeebAPIURL,
		qobuzAfkarAPIURL,
		qobuzSquidAPIURL,
	}
}

type qobuzAPIProvider struct {
	Name string
	URL  string
	Kind string
}

const (
	qobuzAPIKindMusicDL  = "musicdl"
	qobuzAPIKindStandard = "standard"
)

func (q *QobuzDownloader) GetAvailableProviders() []qobuzAPIProvider {
	return []qobuzAPIProvider{
		{Name: "musicdl", URL: qobuzDownloadAPIURL, Kind: qobuzAPIKindMusicDL},
		{Name: "zarz", URL: qobuzZarzDownloadAPIURL, Kind: qobuzAPIKindMusicDL},
		{Name: "dabmusic", URL: qobuzDabMusicAPIURL, Kind: qobuzAPIKindStandard},
		{Name: "deeb", URL: qobuzDeebAPIURL, Kind: qobuzAPIKindStandard},
		{Name: "qbz", URL: qobuzAfkarAPIURL, Kind: qobuzAPIKindStandard},
		{Name: "squid", URL: qobuzSquidAPIURL, Kind: qobuzAPIKindStandard},
	}
}

type qobuzDownloadInfo struct {
	DownloadURL string
	BitDepth    int
	SampleRate  int
}

func extractQobuzDownloadInfoFromBody(body []byte) (qobuzDownloadInfo, error) {
	var raw map[string]any
	if err := json.Unmarshal(body, &raw); err != nil {
		return qobuzDownloadInfo{}, fmt.Errorf("invalid JSON: %v", err)
	}

	if errMsg, ok := raw["error"].(string); ok && strings.TrimSpace(errMsg) != "" {
		return qobuzDownloadInfo{}, fmt.Errorf("%s", errMsg)
	}
	if detail, ok := raw["detail"].(string); ok && strings.TrimSpace(detail) != "" {
		return qobuzDownloadInfo{}, fmt.Errorf("%s", detail)
	}

	if success, ok := raw["success"].(bool); ok && !success {
		if msg, ok := raw["message"].(string); ok && strings.TrimSpace(msg) != "" {
			return qobuzDownloadInfo{}, fmt.Errorf("%s", msg)
		}
		return qobuzDownloadInfo{}, fmt.Errorf("api returned success=false")
	}

	info := qobuzDownloadInfo{
		BitDepth:   qobuzParseBitDepth(raw["bit_depth"]),
		SampleRate: qobuzParseSampleRate(raw["sampling_rate"]),
	}
	if urlVal, ok := raw["download_url"].(string); ok && strings.TrimSpace(urlVal) != "" {
		info.DownloadURL = strings.TrimSpace(urlVal)
		return info, nil
	}
	if urlVal, ok := raw["url"].(string); ok && strings.TrimSpace(urlVal) != "" {
		info.DownloadURL = strings.TrimSpace(urlVal)
		return info, nil
	}
	if linkVal, ok := raw["link"].(string); ok && strings.TrimSpace(linkVal) != "" {
		info.DownloadURL = strings.TrimSpace(linkVal)
		return info, nil
	}

	if data, ok := raw["data"].(map[string]any); ok {
		if info.BitDepth == 0 {
			info.BitDepth = qobuzParseBitDepth(data["bit_depth"])
		}
		if info.SampleRate == 0 {
			info.SampleRate = qobuzParseSampleRate(data["sampling_rate"])
		}
		if urlVal, ok := data["download_url"].(string); ok && strings.TrimSpace(urlVal) != "" {
			info.DownloadURL = strings.TrimSpace(urlVal)
			return info, nil
		}
		if urlVal, ok := data["url"].(string); ok && strings.TrimSpace(urlVal) != "" {
			info.DownloadURL = strings.TrimSpace(urlVal)
			return info, nil
		}
		if linkVal, ok := data["link"].(string); ok && strings.TrimSpace(linkVal) != "" {
			info.DownloadURL = strings.TrimSpace(linkVal)
			return info, nil
		}
	}

	return qobuzDownloadInfo{}, fmt.Errorf("no download URL in response")
}

func extractQobuzDownloadURLFromBody(body []byte) (string, error) {
	info, err := extractQobuzDownloadInfoFromBody(body)
	if err != nil {
		return "", err
	}
	return info.DownloadURL, nil
}

func qobuzParseBitDepth(value any) int {
	switch v := value.(type) {
	case float64:
		return int(v)
	case int:
		return v
	case int64:
		return int(v)
	case json.Number:
		n, _ := v.Int64()
		return int(n)
	default:
		return 0
	}
}

func qobuzParseSampleRate(value any) int {
	switch v := value.(type) {
	case float64:
		if v > 0 && v < 1000 {
			return int(v * 1000)
		}
		return int(v)
	case int:
		if v > 0 && v < 1000 {
			return v * 1000
		}
		return v
	case int64:
		if v > 0 && v < 1000 {
			return int(v * 1000)
		}
		return int(v)
	case json.Number:
		if n, err := v.Float64(); err == nil {
			if n > 0 && n < 1000 {
				return int(n * 1000)
			}
			return int(n)
		}
		return 0
	default:
		return 0
	}
}

func normalizeQobuzQualityCode(quality string) string {
	switch strings.ToLower(strings.TrimSpace(quality)) {
	case "", "5", "6", "cd", "lossless":
		return "6"
	case "7", "hi-res":
		return "7"
	case "27", "hi-res-max":
		return "27"
	default:
		return "6"
	}
}

func mapQobuzQualityCodeToAPI(qualityCode string) string {
	switch normalizeQobuzQualityCode(qualityCode) {
	case "27":
		return "hi-res-max"
	case "7":
		return "hi-res"
	default:
		return "cd"
	}
}

func (q *QobuzDownloader) SearchTrackByISRC(isrc string) (*QobuzTrack, error) {
	candidates, err := q.searchQobuzTracksWithFallback(isrc, 50)
	if err != nil {
		return nil, err
	}

	for i := range candidates {
		if candidates[i].ISRC == isrc {
			return &candidates[i], nil
		}
	}

	if len(candidates) == 0 {
		return nil, fmt.Errorf("no tracks found for ISRC: %s", isrc)
	}

	return nil, fmt.Errorf("no exact ISRC match found for: %s", isrc)
}

func (q *QobuzDownloader) SearchTrackByISRCWithDuration(isrc string, expectedDurationSec int) (*QobuzTrack, error) {
	GoLog("[Qobuz] Searching by ISRC: %s\n", isrc)

	candidates, err := q.searchQobuzTracksWithFallback(isrc, 50)
	if err != nil {
		return nil, err
	}

	GoLog("[Qobuz] ISRC search returned %d results\n", len(candidates))

	var isrcMatches []*QobuzTrack
	for i := range candidates {
		if candidates[i].ISRC == isrc {
			isrcMatches = append(isrcMatches, &candidates[i])
		}
	}

	GoLog("[Qobuz] Found %d exact ISRC matches\n", len(isrcMatches))

	if len(isrcMatches) > 0 {
		if expectedDurationSec > 0 {
			var durationVerifiedMatches []*QobuzTrack
			for _, track := range isrcMatches {
				durationDiff := track.Duration - expectedDurationSec
				if durationDiff < 0 {
					durationDiff = -durationDiff
				}
				if durationDiff <= 10 {
					durationVerifiedMatches = append(durationVerifiedMatches, track)
				}
			}

			if len(durationVerifiedMatches) > 0 {
				GoLog("[Qobuz] ISRC match with duration verification: '%s' (expected %ds, found %ds)\n",
					durationVerifiedMatches[0].Title, expectedDurationSec, durationVerifiedMatches[0].Duration)
				return durationVerifiedMatches[0], nil
			}

			GoLog("[Qobuz] WARNING: ISRC %s found but duration mismatch. Expected=%ds, Found=%ds. Rejecting.\n",
				isrc, expectedDurationSec, isrcMatches[0].Duration)
			return nil, fmt.Errorf("ISRC found but duration mismatch: expected %ds, found %ds (likely different version)",
				expectedDurationSec, isrcMatches[0].Duration)
		}

		GoLog("[Qobuz] ISRC match (no duration verification): '%s'\n", isrcMatches[0].Title)
		return isrcMatches[0], nil
	}

	if len(candidates) == 0 {
		return nil, fmt.Errorf("no tracks found for ISRC: %s", isrc)
	}

	return nil, fmt.Errorf("no exact ISRC match found for: %s", isrc)
}

func (q *QobuzDownloader) SearchTrackByISRCWithTitle(isrc, expectedTitle string) (*QobuzTrack, error) {
	return q.SearchTrackByISRCWithDuration(isrc, 0)
}

func (q *QobuzDownloader) SearchTrackByMetadata(trackName, artistName string) (*QobuzTrack, error) {
	return q.SearchTrackByMetadataWithDuration(trackName, artistName, 0)
}

func (q *QobuzDownloader) SearchTracks(query string, limit int) ([]ExtTrackMetadata, error) {
	cleanQuery := strings.TrimSpace(query)
	if cleanQuery == "" {
		return nil, fmt.Errorf("empty qobuz search query")
	}
	if limit <= 0 {
		limit = 20
	}

	tracks, err := q.searchQobuzTracksWithFallback(cleanQuery, limit)
	if err != nil {
		return nil, err
	}

	results := make([]ExtTrackMetadata, 0, len(tracks))
	for i := range tracks {
		results = append(results, normalizeBuiltInMetadataTrack(qobuzTrackToTrackMetadata(&tracks[i]), "qobuz"))
	}
	return results, nil
}

// SearchAll searches Qobuz for tracks, artists, and albums matching the query.
// Returns results in the same SearchAllResult format as Deezer's SearchAll.
func (q *QobuzDownloader) SearchAll(query string, trackLimit, artistLimit int, filter string) (*SearchAllResult, error) {
	GoLog("[Qobuz] SearchAll: query=%q, trackLimit=%d, artistLimit=%d, filter=%q\n", query, trackLimit, artistLimit, filter)

	cleanQuery := strings.TrimSpace(query)
	if cleanQuery == "" {
		return nil, fmt.Errorf("empty qobuz search query")
	}

	albumLimit := 5

	if filter != "" {
		switch filter {
		case "track":
			trackLimit = 50
			artistLimit = 0
			albumLimit = 0
		case "artist":
			trackLimit = 0
			artistLimit = 20
			albumLimit = 0
		case "album":
			trackLimit = 0
			artistLimit = 0
			albumLimit = 20
		}
	}

	result := &SearchAllResult{
		Tracks:    make([]TrackMetadata, 0, trackLimit),
		Artists:   make([]SearchArtistResult, 0, artistLimit),
		Albums:    make([]SearchAlbumResult, 0, albumLimit),
		Playlists: make([]SearchPlaylistResult, 0),
	}

	if trackLimit > 0 {
		tracks, err := q.searchQobuzTracksWithFallback(cleanQuery, trackLimit)
		if err != nil {
			GoLog("[Qobuz] Track search failed: %v\n", err)
			return nil, fmt.Errorf("qobuz track search failed: %w", err)
		}
		GoLog("[Qobuz] Got %d tracks from API\n", len(tracks))
		for i := range tracks {
			result.Tracks = append(result.Tracks, qobuzTrackToTrackMetadata(&tracks[i]))
		}
	}

	if artistLimit > 0 {
		searchURL := fmt.Sprintf("%sartist/search?query=%s&limit=%d&app_id=%s",
			qobuzAPIBaseURL, url.QueryEscape(cleanQuery), artistLimit, q.appID)
		req, err := http.NewRequest("GET", searchURL, nil)
		artistSearchDone := false
		if err == nil {
			resp, reqErr := DoRequestWithUserAgent(q.client, req)
			if reqErr == nil {
				defer resp.Body.Close()
				if resp.StatusCode == 200 {
					var artistResp struct {
						Artists struct {
							Items []struct {
								ID    int64         `json:"id"`
								Name  string        `json:"name"`
								Image qobuzImageSet `json:"image"`
							} `json:"items"`
						} `json:"artists"`
					}
					if decErr := json.NewDecoder(resp.Body).Decode(&artistResp); decErr == nil {
						GoLog("[Qobuz] Got %d artists from API\n", len(artistResp.Artists.Items))
						for _, artist := range artistResp.Artists.Items {
							imageURL := qobuzFirstNonEmpty(artist.Image.Large, artist.Image.Small, artist.Image.Thumbnail)
							result.Artists = append(result.Artists, SearchArtistResult{
								ID:     qobuzPrefixedNumericID(artist.ID),
								Name:   strings.TrimSpace(artist.Name),
								Images: imageURL,
							})
						}
						artistSearchDone = true
					} else {
						GoLog("[Qobuz] Artist search decode failed: %v\n", decErr)
					}
				} else if isQobuzPrimaryUnavailable(fmt.Errorf("HTTP %d", resp.StatusCode)) {
					GoLog("[Qobuz] Artist search primary API returned HTTP %d, will try qbz2 fallback\n", resp.StatusCode)
				}
			} else {
				GoLog("[Qobuz] Artist search request failed: %v\n", reqErr)
				if isQobuzPrimaryUnavailable(reqErr) {
					GoLog("[Qobuz] Primary API unavailable for artist search, will try qbz2 fallback\n")
				}
			}
		}
		if !artistSearchDone {
			q.searchAllArtistsViaMusicDL(cleanQuery, artistLimit, result)
		}
	}

	if albumLimit > 0 {
		searchURL := fmt.Sprintf("%salbum/search?query=%s&limit=%d&app_id=%s",
			qobuzAPIBaseURL, url.QueryEscape(cleanQuery), albumLimit, q.appID)
		req, err := http.NewRequest("GET", searchURL, nil)
		albumSearchDone := false
		if err == nil {
			resp, reqErr := DoRequestWithUserAgent(q.client, req)
			if reqErr == nil {
				defer resp.Body.Close()
				if resp.StatusCode == 200 {
					var albumResp struct {
						Albums struct {
							Items []qobuzAlbumDetails `json:"items"`
						} `json:"albums"`
					}
					if decErr := json.NewDecoder(resp.Body).Decode(&albumResp); decErr == nil {
						GoLog("[Qobuz] Got %d albums from API\n", len(albumResp.Albums.Items))
						for i := range albumResp.Albums.Items {
							album := &albumResp.Albums.Items[i]
							result.Albums = append(result.Albums, SearchAlbumResult{
								ID:          qobuzPrefixedID(album.ID),
								Name:        strings.TrimSpace(album.Title),
								Artists:     qobuzArtistsDisplayName(album.Artists, album.Artist.Name),
								Images:      qobuzAlbumImage(album),
								ReleaseDate: qobuzNormalizeReleaseDate(album.ReleaseDateOriginal),
								TotalTracks: album.TracksCount,
								AlbumType:   qobuzNormalizeAlbumType(album.ReleaseType, album.ProductType, album.TracksCount),
							})
						}
						albumSearchDone = true
					} else {
						GoLog("[Qobuz] Album search decode failed: %v\n", decErr)
					}
				} else if isQobuzPrimaryUnavailable(fmt.Errorf("HTTP %d", resp.StatusCode)) {
					GoLog("[Qobuz] Album search primary API returned HTTP %d, will try qbz2 fallback\n", resp.StatusCode)
				}
			} else {
				GoLog("[Qobuz] Album search request failed: %v\n", reqErr)
				if isQobuzPrimaryUnavailable(reqErr) {
					GoLog("[Qobuz] Primary API unavailable for album search, will try qbz2 fallback\n")
				}
			}
		}
		if !albumSearchDone {
			q.searchAllAlbumsViaMusicDL(cleanQuery, albumLimit, result)
		}
	}

	GoLog("[Qobuz] SearchAll complete: %d tracks, %d artists, %d albums\n", len(result.Tracks), len(result.Artists), len(result.Albums))
	return result, nil
}

func (q *QobuzDownloader) searchAllArtistsViaMusicDL(query string, limit int, result *SearchAllResult) {
	requestURL := fmt.Sprintf("%sartist/search?query=%s&limit=%d", qobuzFallbackAPIBaseURL, url.QueryEscape(query), limit)
	var searchResp struct {
		Artists struct {
			Items []struct {
				ID    int64         `json:"id"`
				Name  string        `json:"name"`
				Image qobuzImageSet `json:"image"`
			} `json:"items"`
		} `json:"artists"`
	}
	if err := q.getQobuzJSON(requestURL, &searchResp); err != nil {
		GoLog("[Qobuz] qbz2 fallback artist search also failed: %v\n", err)
		return
	}
	GoLog("[Qobuz] qbz2 fallback artist search succeeded: %d artists\n", len(searchResp.Artists.Items))
	for _, artist := range searchResp.Artists.Items {
		imageURL := qobuzFirstNonEmpty(artist.Image.Large, artist.Image.Small, artist.Image.Thumbnail)
		result.Artists = append(result.Artists, SearchArtistResult{
			ID:     qobuzPrefixedNumericID(artist.ID),
			Name:   strings.TrimSpace(artist.Name),
			Images: imageURL,
		})
	}
}

func (q *QobuzDownloader) searchAllAlbumsViaMusicDL(query string, limit int, result *SearchAllResult) {
	requestURL := fmt.Sprintf("%salbum/search?query=%s&limit=%d", qobuzFallbackAPIBaseURL, url.QueryEscape(query), limit)
	var searchResp struct {
		Albums struct {
			Items []qobuzAlbumDetails `json:"items"`
		} `json:"albums"`
	}
	if err := q.getQobuzJSON(requestURL, &searchResp); err != nil {
		GoLog("[Qobuz] qbz2 fallback album search also failed: %v\n", err)
		return
	}
	GoLog("[Qobuz] qbz2 fallback album search succeeded: %d albums\n", len(searchResp.Albums.Items))
	for i := range searchResp.Albums.Items {
		album := &searchResp.Albums.Items[i]
		result.Albums = append(result.Albums, SearchAlbumResult{
			ID:          qobuzPrefixedID(album.ID),
			Name:        strings.TrimSpace(album.Title),
			Artists:     qobuzArtistsDisplayName(album.Artists, album.Artist.Name),
			Images:      qobuzAlbumImage(album),
			ReleaseDate: qobuzNormalizeReleaseDate(album.ReleaseDateOriginal),
			TotalTracks: album.TracksCount,
			AlbumType:   qobuzNormalizeAlbumType(album.ReleaseType, album.ProductType, album.TracksCount),
		})
	}
}

func (q *QobuzDownloader) SearchTrackByMetadataWithDuration(trackName, artistName string, expectedDurationSec int) (*QobuzTrack, error) {
	queries := []string{}

	if artistName != "" && trackName != "" {
		queries = append(queries, artistName+" "+trackName)
	}

	if trackName != "" {
		queries = append(queries, trackName)
	}

	if ContainsJapanese(trackName) || ContainsJapanese(artistName) {
		romajiTrack := JapaneseToRomaji(trackName)
		romajiArtist := JapaneseToRomaji(artistName)

		cleanRomajiTrack := CleanToASCII(romajiTrack)
		cleanRomajiArtist := CleanToASCII(romajiArtist)

		if cleanRomajiArtist != "" && cleanRomajiTrack != "" {
			romajiQuery := cleanRomajiArtist + " " + cleanRomajiTrack
			if !containsQueryQobuz(queries, romajiQuery) {
				queries = append(queries, romajiQuery)
				GoLog("[Qobuz] Japanese detected, adding romaji query: %s\n", romajiQuery)
			}
		}

		if cleanRomajiTrack != "" && cleanRomajiTrack != trackName {
			if !containsQueryQobuz(queries, cleanRomajiTrack) {
				queries = append(queries, cleanRomajiTrack)
			}
		}
	}

	if artistName != "" {
		artistOnly := CleanToASCII(JapaneseToRomaji(artistName))
		if artistOnly != "" && !containsQueryQobuz(queries, artistOnly) {
			queries = append(queries, artistOnly)
		}
	}

	var allTracks []QobuzTrack
	searchedQueries := make(map[string]bool)
	seenTrackIDs := make(map[int64]struct{})

	for _, query := range queries {
		cleanQuery := strings.TrimSpace(query)
		if cleanQuery == "" || searchedQueries[cleanQuery] {
			continue
		}
		searchedQueries[cleanQuery] = true

		GoLog("[Qobuz] Searching for: %s\n", cleanQuery)

		result, err := q.searchQobuzTracksWithFallback(cleanQuery, 50)
		if err != nil {
			GoLog("[Qobuz] Search error for '%s': %v\n", cleanQuery, err)
			continue
		}

		if len(result) > 0 {
			GoLog("[Qobuz] Found %d results for '%s'\n", len(result), cleanQuery)
			for i := range result {
				trackID := result[i].ID
				if trackID <= 0 {
					allTracks = append(allTracks, result[i])
					continue
				}
				if _, ok := seenTrackIDs[trackID]; ok {
					continue
				}
				seenTrackIDs[trackID] = struct{}{}
				allTracks = append(allTracks, result[i])
			}
		}
	}

	if len(allTracks) == 0 {
		return nil, fmt.Errorf("no tracks found for: %s - %s", artistName, trackName)
	}

	var titleMatches []*QobuzTrack
	for i := range allTracks {
		track := &allTracks[i]
		if qobuzTitlesMatch(trackName, track.Title) {
			titleMatches = append(titleMatches, track)
		}
	}

	GoLog("[Qobuz] Title matches: %d out of %d results\n", len(titleMatches), len(allTracks))

	tracksToCheck := titleMatches
	if len(titleMatches) == 0 {
		GoLog("[Qobuz] WARNING: No title matches for '%s', checking all %d results\n", trackName, len(allTracks))
		for i := range allTracks {
			tracksToCheck = append(tracksToCheck, &allTracks[i])
		}
	}

	if expectedDurationSec > 0 {
		var durationMatches []*QobuzTrack
		for _, track := range tracksToCheck {
			durationDiff := track.Duration - expectedDurationSec
			if durationDiff < 0 {
				durationDiff = -durationDiff
			}
			if durationDiff <= 10 {
				durationMatches = append(durationMatches, track)
			}
		}

		if len(durationMatches) > 0 {
			for _, track := range durationMatches {
				if track.MaximumBitDepth >= 24 {
					GoLog("[Qobuz] Match found: '%s' by '%s' (title+duration verified, hi-res)\n",
						track.Title, track.Performer.Name)
					return track, nil
				}
			}
			GoLog("[Qobuz] Match found: '%s' by '%s' (title+duration verified)\n",
				durationMatches[0].Title, durationMatches[0].Performer.Name)
			return durationMatches[0], nil
		}

		return nil, fmt.Errorf("no tracks found with matching title and duration (expected '%s', %ds)", trackName, expectedDurationSec)
	}

	for _, track := range tracksToCheck {
		if track.MaximumBitDepth >= 24 {
			GoLog("[Qobuz] Match found: '%s' by '%s' (title verified, hi-res)\n",
				track.Title, track.Performer.Name)
			return track, nil
		}
	}

	if len(tracksToCheck) > 0 {
		GoLog("[Qobuz] Match found: '%s' by '%s' (title verified)\n",
			tracksToCheck[0].Title, tracksToCheck[0].Performer.Name)
		return tracksToCheck[0], nil
	}

	return nil, fmt.Errorf("no matching track found for: %s - %s", artistName, trackName)
}

func qobuzTrackMatchesRequest(req DownloadRequest, track *QobuzTrack, logPrefix, source string, skipNameVerification bool) bool {
	if track == nil {
		return false
	}

	exactISRCMatch := req.ISRC != "" &&
		track.ISRC != "" &&
		strings.EqualFold(strings.TrimSpace(req.ISRC), strings.TrimSpace(track.ISRC))

	if !exactISRCMatch && !skipNameVerification {
		if req.ArtistName != "" && !qobuzArtistsMatch(req.ArtistName, track.Performer.Name) {
			GoLog("[%s] Artist mismatch from %s: expected '%s', got '%s'. Rejecting.\n",
				logPrefix, source, req.ArtistName, track.Performer.Name)
			return false
		}

		if req.TrackName != "" && !qobuzTitlesMatch(req.TrackName, track.Title) {
			GoLog("[%s] Title mismatch from %s: expected '%s', got '%s'. Rejecting.\n",
				logPrefix, source, req.TrackName, track.Title)
			return false
		}
	}

	expectedDurationSec := req.DurationMS / 1000
	if expectedDurationSec > 0 && track.Duration > 0 {
		durationDiff := track.Duration - expectedDurationSec
		if durationDiff < 0 {
			durationDiff = -durationDiff
		}
		if durationDiff > 10 {
			GoLog("[%s] Duration mismatch from %s: expected %ds, got %ds. Rejecting.\n",
				logPrefix, source, expectedDurationSec, track.Duration)
			return false
		}
	}

	return true
}

func (q *QobuzDownloader) searchQobuzTracksViaAPI(query string, limit int) ([]QobuzTrack, error) {
	searchURL := fmt.Sprintf("%s%s&limit=%d&app_id=%s", qobuzTrackSearchBaseURL, url.QueryEscape(query), limit, q.appID)
	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		if isQobuzPrimaryUnavailable(err) {
			GoLog("[Qobuz] Primary API unavailable for track search, trying qbz2 fallback: %v\n", err)
			return q.searchQobuzTracksViaMusicDL(query, limit)
		}
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		primaryErr := fmt.Errorf("search failed: HTTP %d (%s)", resp.StatusCode, strings.TrimSpace(string(body)))
		if isQobuzPrimaryUnavailable(primaryErr) {
			GoLog("[Qobuz] Primary API unavailable for track search, trying qbz2 fallback: %v\n", primaryErr)
			return q.searchQobuzTracksViaMusicDL(query, limit)
		}
		return nil, primaryErr
	}

	var result struct {
		Tracks struct {
			Items []QobuzTrack `json:"items"`
		} `json:"tracks"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}
	return result.Tracks.Items, nil
}

func (q *QobuzDownloader) searchQobuzTracksViaMusicDL(query string, limit int) ([]QobuzTrack, error) {
	requestURL := fmt.Sprintf("%s%s&limit=%d", qobuzFallbackTrackSearchBaseURL, url.QueryEscape(query), limit)
	var result struct {
		Tracks struct {
			Items []QobuzTrack `json:"items"`
		} `json:"tracks"`
	}
	if err := q.getQobuzJSON(requestURL, &result); err != nil {
		return nil, fmt.Errorf("qbz2 fallback search also failed: %w", err)
	}
	GoLog("[Qobuz] qbz2 fallback search succeeded: %d tracks for '%s'\n", len(result.Tracks.Items), query)
	return result.Tracks.Items, nil
}

type qobuzTrackSearchCandidate struct {
	score int
	track QobuzTrack
}

func qobuzNormalizedSearchText(value string) string {
	return normalizeLooseArtistName(value)
}

func qobuzSearchTokens(value string) []string {
	normalized := qobuzNormalizedSearchText(value)
	if normalized == "" {
		return nil
	}

	parts := strings.Fields(normalized)
	tokens := make([]string, 0, len(parts))
	seen := make(map[string]struct{}, len(parts))
	for _, part := range parts {
		if len(part) < 2 {
			continue
		}
		if _, ok := seen[part]; ok {
			continue
		}
		seen[part] = struct{}{}
		tokens = append(tokens, part)
	}
	return tokens
}

func qobuzScoreTrackSearchCandidate(query string, track *QobuzTrack) int {
	if track == nil {
		return 0
	}

	queryNorm := qobuzNormalizedSearchText(query)
	if queryNorm == "" {
		return 0
	}

	titleNorm := qobuzNormalizedSearchText(track.Title)
	displayNorm := qobuzNormalizedSearchText(qobuzTrackDisplayTitle(track))
	artistNorm := qobuzNormalizedSearchText(qobuzTrackArtistName(track))
	albumNorm := qobuzNormalizedSearchText(strings.TrimSpace(track.Album.Title))

	score := 0

	if qobuzTitlesMatch(query, track.Title) || qobuzTitlesMatch(query, qobuzTrackDisplayTitle(track)) {
		score += 900
	}

	switch {
	case queryNorm == titleNorm, queryNorm == displayNorm:
		score += 1200
	case (titleNorm != "" && strings.Contains(titleNorm, queryNorm)) ||
		(displayNorm != "" && strings.Contains(displayNorm, queryNorm)):
		score += 420
	case (titleNorm != "" && strings.Contains(queryNorm, titleNorm)) ||
		(displayNorm != "" && strings.Contains(queryNorm, displayNorm)):
		score += 260
	}

	if artistNorm != "" && strings.Contains(queryNorm, artistNorm) {
		score += 180
	}
	if albumNorm != "" && strings.Contains(queryNorm, albumNorm) {
		score += 100
	}

	for _, token := range qobuzSearchTokens(query) {
		switch {
		case strings.Contains(titleNorm, token), strings.Contains(displayNorm, token):
			score += 180
		case strings.Contains(artistNorm, token):
			score += 70
		case strings.Contains(albumNorm, token):
			score += 35
		}
	}

	if track.ISRC != "" {
		score += 15
	}
	if track.MaximumBitDepth >= 24 {
		score += 10
	}
	if track.MaximumSamplingRate >= 88.2 {
		score += 10
	}

	return score
}

func selectQobuzTracksFromAlbumSearchResults(
	query string,
	limit int,
	albumSummaries []qobuzAlbumDetails,
	loadAlbum func(string) (*qobuzAlbumDetails, error),
) ([]QobuzTrack, error) {
	if strings.TrimSpace(query) == "" {
		return nil, fmt.Errorf("empty qobuz album-search fallback query")
	}
	if len(albumSummaries) == 0 {
		return nil, fmt.Errorf("album search returned no albums")
	}

	candidates := make([]qobuzTrackSearchCandidate, 0, limit)
	seenTrackIDs := make(map[int64]struct{})

	for _, summary := range albumSummaries {
		albumID := strings.TrimSpace(summary.ID)
		if albumID == "" {
			continue
		}

		album, err := loadAlbum(albumID)
		if err != nil || album == nil {
			continue
		}

		for i := range album.Tracks.Items {
			track := album.Tracks.Items[i]
			track.Album.ID = album.ID
			track.Album.QobuzID = album.QobuzID
			track.Album.Title = album.Title
			track.Album.ReleaseDate = album.ReleaseDateOriginal
			track.Album.TracksCount = album.TracksCount
			track.Album.ProductType = album.ProductType
			track.Album.ReleaseType = album.ReleaseType
			track.Album.Artist.ID = album.Artist.ID
			track.Album.Artist.Name = album.Artist.Name
			track.Album.Artists = album.Artists
			track.Album.Image = album.Image

			if track.ID > 0 {
				if _, ok := seenTrackIDs[track.ID]; ok {
					continue
				}
				seenTrackIDs[track.ID] = struct{}{}
			}

			score := qobuzScoreTrackSearchCandidate(query, &track)
			if score <= 0 {
				continue
			}

			candidates = append(candidates, qobuzTrackSearchCandidate{
				score: score,
				track: track,
			})
		}
	}

	if len(candidates) == 0 {
		return nil, fmt.Errorf("album-search fallback returned no scored track candidates")
	}

	sort.SliceStable(candidates, func(i, j int) bool {
		if candidates[i].score != candidates[j].score {
			return candidates[i].score > candidates[j].score
		}
		if candidates[i].track.MaximumBitDepth != candidates[j].track.MaximumBitDepth {
			return candidates[i].track.MaximumBitDepth > candidates[j].track.MaximumBitDepth
		}
		return candidates[i].track.ID < candidates[j].track.ID
	})

	if limit > 0 && len(candidates) > limit {
		candidates = candidates[:limit]
	}

	tracks := make([]QobuzTrack, 0, len(candidates))
	for _, candidate := range candidates {
		tracks = append(tracks, candidate.track)
	}
	return tracks, nil
}

func (q *QobuzDownloader) searchQobuzTracksViaAlbumSearch(query string, limit int) ([]QobuzTrack, error) {
	albumLimit := limit
	if albumLimit < 3 {
		albumLimit = 3
	}
	if albumLimit > 8 {
		albumLimit = 8
	}

	searchURL := fmt.Sprintf(
		"%salbum/search?query=%s&limit=%d&app_id=%s",
		qobuzAPIBaseURL,
		url.QueryEscape(strings.TrimSpace(query)),
		albumLimit,
		q.appID,
	)

	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		if isQobuzPrimaryUnavailable(err) {
			GoLog("[Qobuz] Primary API unavailable for album search fallback, trying qbz2: %v\n", err)
			return q.searchQobuzTracksViaAlbumSearchMusicDL(query, limit, albumLimit)
		}
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		primaryErr := fmt.Errorf("album search failed: HTTP %d (%s)", resp.StatusCode, strings.TrimSpace(string(body)))
		if isQobuzPrimaryUnavailable(primaryErr) {
			GoLog("[Qobuz] Primary API unavailable for album search fallback, trying qbz2: %v\n", primaryErr)
			return q.searchQobuzTracksViaAlbumSearchMusicDL(query, limit, albumLimit)
		}
		return nil, primaryErr
	}

	var albumResp struct {
		Albums struct {
			Items []qobuzAlbumDetails `json:"items"`
		} `json:"albums"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&albumResp); err != nil {
		return nil, err
	}

	return selectQobuzTracksFromAlbumSearchResults(
		query,
		limit,
		albumResp.Albums.Items,
		q.getAlbumDetails,
	)
}

func (q *QobuzDownloader) searchQobuzTracksViaAlbumSearchMusicDL(query string, limit, albumLimit int) ([]QobuzTrack, error) {
	requestURL := fmt.Sprintf("%salbum/search?query=%s&limit=%d", qobuzFallbackAPIBaseURL, url.QueryEscape(strings.TrimSpace(query)), albumLimit)
	var searchResp struct {
		Albums struct {
			Items []qobuzAlbumDetails `json:"items"`
		} `json:"albums"`
	}
	if err := q.getQobuzJSON(requestURL, &searchResp); err != nil {
		return nil, fmt.Errorf("qbz2 fallback album search also failed: %w", err)
	}
	GoLog("[Qobuz] qbz2 fallback album search returned %d albums\n", len(searchResp.Albums.Items))
	return selectQobuzTracksFromAlbumSearchResults(
		query,
		limit,
		searchResp.Albums.Items,
		q.getAlbumDetails,
	)
}

func extractQobuzTrackIDsFromStoreSearchHTML(body []byte) []int64 {
	matches := qobuzStoreTrackIDRegex.FindAllSubmatch(body, -1)
	if len(matches) == 0 {
		return nil
	}

	trackIDs := make([]int64, 0, len(matches))
	seen := make(map[int64]struct{}, len(matches))
	for _, match := range matches {
		if len(match) < 2 {
			continue
		}
		id, err := strconv.ParseInt(string(match[1]), 10, 64)
		if err != nil || id <= 0 {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		trackIDs = append(trackIDs, id)
	}
	return trackIDs
}

func (q *QobuzDownloader) searchQobuzTracksViaStore(query string, limit int) ([]QobuzTrack, error) {
	searchURL := qobuzStoreSearchBaseURL + url.PathEscape(query)
	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("store search failed: HTTP %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	trackIDs := extractQobuzTrackIDsFromStoreSearchHTML(body)
	if len(trackIDs) == 0 {
		return nil, fmt.Errorf("store search did not contain track IDs")
	}

	if limit > 0 && len(trackIDs) > limit {
		trackIDs = trackIDs[:limit]
	}

	tracks := make([]QobuzTrack, 0, len(trackIDs))
	for _, id := range trackIDs {
		track, trackErr := q.GetTrackByID(id)
		if trackErr != nil || track == nil {
			continue
		}
		tracks = append(tracks, *track)
	}

	if len(tracks) == 0 {
		return nil, fmt.Errorf("store fallback returned IDs but no track metadata could be loaded")
	}
	return tracks, nil
}

func (q *QobuzDownloader) searchQobuzTracksWithFallback(query string, limit int) ([]QobuzTrack, error) {
	apiTracks, apiErr := q.searchQobuzTracksViaAPI(query, limit)
	if apiErr == nil {
		if len(apiTracks) > 0 {
			return apiTracks, nil
		}
		GoLog("[Qobuz] API search returned 0 results for '%s', trying album-search fallback\n", query)
	} else {
		GoLog("[Qobuz] API search failed for '%s': %v. Trying album-search fallback.\n", query, apiErr)
	}

	albumTracks, albumErr := q.searchQobuzTracksViaAlbumSearch(query, limit)
	if albumErr == nil && len(albumTracks) > 0 {
		GoLog("[Qobuz] Album-search fallback returned %d candidate tracks for '%s'\n", len(albumTracks), query)
		return albumTracks, nil
	}
	if albumErr != nil {
		GoLog("[Qobuz] Album-search fallback failed for '%s': %v. Trying store fallback.\n", query, albumErr)
	}

	storeTracks, storeErr := q.searchQobuzTracksViaStore(query, limit)
	if storeErr == nil && len(storeTracks) > 0 {
		GoLog("[Qobuz] Store fallback returned %d candidate tracks for '%s'\n", len(storeTracks), query)
		return storeTracks, nil
	}

	if apiErr != nil && albumErr != nil && storeErr != nil {
		return nil, fmt.Errorf(
			"api search failed (%v); album-search fallback failed (%v); store fallback failed (%v)",
			apiErr,
			albumErr,
			storeErr,
		)
	}
	if albumErr == nil && len(albumTracks) == 0 && storeErr != nil {
		return nil, storeErr
	}
	if storeErr != nil {
		if albumErr != nil {
			return nil, albumErr
		}
		return nil, storeErr
	}
	return nil, fmt.Errorf("no tracks found for query: %s", query)
}

type qobuzAPIResult struct {
	provider qobuzAPIProvider
	info     qobuzDownloadInfo
	err      error
	duration time.Duration
}

// Mobile networks are more unstable, so we use longer timeouts
const (
	qobuzAPITimeoutMobile = 25 * time.Second
	qobuzMaxRetries       = 2
	qobuzRetryDelay       = 500 * time.Millisecond
)

func getQobuzAPITimeout() time.Duration {
	// The Go backend is only used on mobile (Android/iOS)
	return qobuzAPITimeoutMobile
}

// fetchQobuzURLWithRetry fetches download URL from a single Qobuz API with retry logic
func fetchQobuzURLWithRetry(provider qobuzAPIProvider, trackID int64, quality string, timeout time.Duration) (qobuzDownloadInfo, error) {
	return fetchQobuzURLSingleAttempt(provider, trackID, quality, timeout, "")
}

func buildQobuzMusicDLPayload(trackID int64, quality string) ([]byte, error) {
	requestQuality := mapQobuzQualityCodeToAPI(quality)
	payload := map[string]any{
		"quality":      requestQuality,
		"upload_to_r2": false,
		"url":          fmt.Sprintf("%s%d", qobuzTrackOpenBaseURL, trackID),
	}
	return json.Marshal(payload)
}

func fetchQobuzURLSingleAttempt(provider qobuzAPIProvider, trackID int64, quality string, timeout time.Duration, country string) (qobuzDownloadInfo, error) {
	var lastErr error
	retryDelay := qobuzRetryDelay
	var payloadBytes []byte
	if provider.Kind == qobuzAPIKindMusicDL {
		var err error
		payloadBytes, err = buildQobuzMusicDLPayload(trackID, quality)
		if err != nil {
			return qobuzDownloadInfo{}, fmt.Errorf("failed to encode qobuz request: %w", err)
		}
	}

	for attempt := 0; attempt <= qobuzMaxRetries; attempt++ {
		if attempt > 0 {
			GoLog("[Qobuz] Retry %d/%d for %s after %v\n", attempt, qobuzMaxRetries, provider.Name, retryDelay)
			time.Sleep(retryDelay)
			retryDelay *= 2
		}

		client := NewHTTPClientWithTimeout(timeout)
		reqURL := provider.URL
		if country != "" {
			reqURL += "?country=" + url.QueryEscape(country)
		}

		var (
			req *http.Request
			err error
		)
		if provider.Kind == qobuzAPIKindStandard {
			separator := "&"
			if !strings.Contains(reqURL, "?") {
				separator = "?"
			}
			reqURL = fmt.Sprintf(
				"%s%d%squality=%s",
				reqURL,
				trackID,
				separator,
				url.QueryEscape(normalizeQobuzQualityCode(quality)),
			)
			req, err = http.NewRequest("GET", reqURL, nil)
		} else {
			req, err = http.NewRequest("POST", reqURL, bytes.NewReader(payloadBytes))
		}
		if err != nil {
			lastErr = err
			continue
		}
		if provider.Kind == qobuzAPIKindMusicDL {
			req.Header.Set("Content-Type", "application/json")
		}

		resp, err := DoRequestWithUserAgent(client, req)
		if err != nil {
			lastErr = err
			// Check for retryable errors (timeout, connection reset)
			errStr := strings.ToLower(err.Error())
			if strings.Contains(errStr, "timeout") ||
				strings.Contains(errStr, "reset") ||
				strings.Contains(errStr, "connection refused") ||
				strings.Contains(errStr, "eof") {
				continue
			}
			break
		}
		if resp.StatusCode >= 500 {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			lastErr = fmt.Errorf("HTTP %d", resp.StatusCode)
			continue
		}

		// 429 rate limit - wait and retry
		if resp.StatusCode == 429 {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			lastErr = fmt.Errorf("rate limited")
			retryDelay = 2 * time.Second
			continue
		}

		if resp.StatusCode != 200 {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			return qobuzDownloadInfo{}, fmt.Errorf("HTTP %d", resp.StatusCode)
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			lastErr = err
			continue
		}

		if len(body) > 0 && body[0] == '<' {
			return qobuzDownloadInfo{}, fmt.Errorf("received HTML instead of JSON")
		}

		info, parseErr := extractQobuzDownloadInfoFromBody(body)
		if parseErr == nil {
			return info, nil
		}
		lastErr = parseErr
		continue
	}

	if lastErr != nil {
		return qobuzDownloadInfo{}, lastErr
	}
	return qobuzDownloadInfo{}, fmt.Errorf("all retries failed")
}

func getQobuzDownloadURLParallel(providers []qobuzAPIProvider, trackID int64, quality string) (qobuzAPIProvider, qobuzDownloadInfo, error) {
	if len(providers) == 0 {
		return qobuzAPIProvider{}, qobuzDownloadInfo{}, fmt.Errorf("no APIs available")
	}

	GoLog("[Qobuz] Requesting download URL from %d APIs in parallel (with retry)...\n", len(providers))

	resultChan := make(chan qobuzAPIResult, len(providers))
	startTime := time.Now()
	timeout := getQobuzAPITimeout()

	for _, provider := range providers {
		go func(provider qobuzAPIProvider) {
			reqStart := time.Now()
			info, err := fetchQobuzURLWithRetry(provider, trackID, quality, timeout)
			resultChan <- qobuzAPIResult{
				provider: provider,
				info:     info,
				err:      err,
				duration: time.Since(reqStart),
			}
		}(provider)
	}

	var errors []string

	for i := 0; i < len(providers); i++ {
		result := <-resultChan
		if result.err == nil {
			GoLog("[Qobuz] [Parallel] Got response from %s in %v\n", result.provider.Name, result.duration)

			go func(remaining int) {
				for j := 0; j < remaining; j++ {
					<-resultChan
				}
			}(len(providers) - i - 1)

			GoLog("[Qobuz] [Parallel] Total time: %v (first success)\n", time.Since(startTime))
			return result.provider, result.info, nil
		}
		errMsg := result.err.Error()
		if len(errMsg) > 50 {
			errMsg = errMsg[:50] + "..."
		}
		errors = append(errors, fmt.Sprintf("%s: %s", result.provider.Name, errMsg))
	}

	GoLog("[Qobuz] [Parallel] All %d APIs failed in %v\n", len(providers), time.Since(startTime))
	return qobuzAPIProvider{}, qobuzDownloadInfo{}, fmt.Errorf("all %d Qobuz APIs failed. Errors: %v", len(providers), errors)
}

func (q *QobuzDownloader) GetDownloadURL(trackID int64, quality string) (qobuzDownloadInfo, error) {
	providers := q.GetAvailableProviders()
	if len(providers) == 0 {
		return qobuzDownloadInfo{}, fmt.Errorf("no Qobuz API available")
	}

	qualityCode := normalizeQobuzQualityCode(quality)

	downloadFunc := func(qual string) (qobuzDownloadInfo, error) {
		provider, info, err := getQobuzDownloadURLParallel(providers, trackID, qual)
		if err != nil {
			return qobuzDownloadInfo{}, err
		}
		GoLog("[Qobuz] Download URL resolved via %s\n", provider.Name)
		return info, nil
	}

	downloadInfo, err := downloadFunc(qualityCode)
	if err == nil {
		return downloadInfo, nil
	}

	currentQuality := qualityCode
	if currentQuality == "27" {
		GoLog("[Qobuz] Hi-res (27) failed, trying 24-bit (7)...\n")
		downloadInfo, err = downloadFunc("7")
		if err == nil {
			return downloadInfo, nil
		}
		currentQuality = "7"
	}

	if currentQuality == "7" {
		GoLog("[Qobuz] 24-bit failed, trying 16-bit (6)...\n")
		downloadInfo, err = downloadFunc("6")
		if err == nil {
			return downloadInfo, nil
		}
	}

	return qobuzDownloadInfo{}, fmt.Errorf("all Qobuz APIs failed: %w", err)
}

func (q *QobuzDownloader) DownloadFile(downloadURL, outputPath string, outputFD int, itemID string) error {
	ctx := context.Background()

	if itemID != "" {
		StartItemProgress(itemID)
		defer CompleteItemProgress(itemID)
		ctx = initDownloadCancel(itemID)
		defer clearDownloadCancel(itemID)
	}

	if isDownloadCancelled(itemID) {
		return ErrDownloadCancelled
	}

	req, err := http.NewRequestWithContext(ctx, "GET", downloadURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := DoRequestWithUserAgent(q.client, req)
	if err != nil {
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("download failed: HTTP %d", resp.StatusCode)
	}

	expectedSize := resp.ContentLength
	if expectedSize > 0 && itemID != "" {
		SetItemBytesTotal(itemID, expectedSize)
	}

	out, err := openOutputForWrite(outputPath, outputFD)
	if err != nil {
		return err
	}

	bufWriter := bufio.NewWriterSize(out, 256*1024)

	var written int64
	if itemID != "" {
		progressWriter := NewItemProgressWriter(bufWriter, itemID)
		written, err = io.Copy(progressWriter, resp.Body)
	} else {
		written, err = io.Copy(bufWriter, resp.Body)
	}

	flushErr := bufWriter.Flush()
	closeErr := out.Close()

	if err != nil {
		cleanupOutputOnError(outputPath, outputFD)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return fmt.Errorf("download interrupted: %w", err)
	}
	if flushErr != nil {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("failed to flush buffer: %w", flushErr)
	}
	if closeErr != nil {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("failed to close file: %w", closeErr)
	}

	if expectedSize > 0 && written != expectedSize {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
	}

	return nil
}

type QobuzDownloadResult struct {
	FilePath    string
	BitDepth    int
	SampleRate  int
	Title       string
	Artist      string
	Album       string
	ReleaseDate string
	TrackNumber int
	DiscNumber  int
	ISRC        string
	CoverURL    string
	LyricsLRC   string
}

func parseQobuzRequestTrackID(raw string) int64 {
	trimmed := strings.TrimSpace(raw)
	trimmed = strings.TrimPrefix(trimmed, "qobuz:")
	if trimmed == "" {
		return 0
	}
	var trackID int64
	if _, err := fmt.Sscanf(trimmed, "%d", &trackID); err != nil || trackID <= 0 {
		return 0
	}
	return trackID
}

func resolveQobuzTrackForRequest(req DownloadRequest, downloader *QobuzDownloader, logPrefix string) (*QobuzTrack, error) {
	if downloader == nil {
		downloader = NewQobuzDownloader()
	}
	if strings.TrimSpace(logPrefix) == "" {
		logPrefix = "Qobuz"
	}

	expectedDurationSec := req.DurationMS / 1000

	var track *QobuzTrack
	var err error

	// Strategy 1: Use Qobuz ID from request payload (fastest, most accurate)
	if req.QobuzID != "" {
		GoLog("[%s] Using Qobuz ID from request payload: %s\n", logPrefix, req.QobuzID)
		if trackID := parseQobuzRequestTrackID(req.QobuzID); trackID > 0 {
			track, err = qobuzGetTrackByIDFunc(downloader, trackID)
			if err != nil {
				GoLog("[%s] Failed to get track by request Qobuz ID %d: %v\n", logPrefix, trackID, err)
				track = nil
			} else if track != nil {
				if qobuzTrackMatchesRequest(req, track, logPrefix, "request Qobuz ID", false) {
					GoLog("[%s] Successfully found track via request Qobuz ID: '%s' by '%s'\n", logPrefix, track.Title, track.Performer.Name)
				} else {
					track = nil
				}
			}
		}
	}

	// Strategy 2: Use cached Qobuz Track ID (fast, no search needed)
	if track == nil && req.ISRC != "" {
		if cached := GetTrackIDCache().Get(req.ISRC); cached != nil && cached.QobuzTrackID > 0 {
			GoLog("[%s] Cache hit! Using cached track ID: %d\n", logPrefix, cached.QobuzTrackID)
			track, err = qobuzGetTrackByIDFunc(downloader, cached.QobuzTrackID)
			if err != nil {
				GoLog("[%s] Cache hit but GetTrackByID failed: %v\n", logPrefix, err)
				track = nil
			} else if track != nil && !qobuzTrackMatchesRequest(req, track, logPrefix, "cached Qobuz ID", false) {
				track = nil
			}
		}
	}

	// Strategy 3: Try to get QobuzID from SongLink if we have SpotifyID but no ISRC
	if track == nil && req.SpotifyID != "" && req.QobuzID == "" && req.ISRC == "" {
		GoLog("[%s] Trying to get Qobuz ID from SongLink for Spotify ID: %s\n", logPrefix, req.SpotifyID)
		songLinkClient := NewSongLinkClient()
		availability, slErr := songLinkCheckTrackAvailabilityFunc(songLinkClient, req.SpotifyID, req.ISRC)
		if slErr == nil && availability != nil && availability.QobuzID != "" {
			var trackID int64
			if _, parseErr := fmt.Sscanf(availability.QobuzID, "%d", &trackID); parseErr == nil && trackID > 0 {
				GoLog("[%s] Got Qobuz ID %d from SongLink\n", logPrefix, trackID)
				track, err = qobuzGetTrackByIDFunc(downloader, trackID)
				if err != nil {
					GoLog("[%s] Failed to get track by SongLink ID %d: %v\n", logPrefix, trackID, err)
					track = nil
				} else if track != nil {
					if qobuzTrackMatchesRequest(req, track, logPrefix, "SongLink Qobuz ID", true) {
						GoLog("[%s] Successfully found track via SongLink ID: '%s' by '%s'\n", logPrefix, track.Title, track.Performer.Name)
						if req.ISRC != "" {
							GetTrackIDCache().SetQobuz(req.ISRC, track.ID)
						}
					} else {
						track = nil
					}
				}
			}
		}
	}

	// Strategy 4: ISRC search with duration verification
	if track == nil && req.ISRC != "" {
		GoLog("[%s] Trying ISRC search: %s\n", logPrefix, req.ISRC)
		track, err = qobuzSearchTrackByISRCWithDurationFunc(downloader, req.ISRC, expectedDurationSec)
		if track != nil && !qobuzTrackMatchesRequest(req, track, logPrefix, "ISRC search", false) {
			track = nil
		}
	}

	// Strategy 5: Metadata search with strict matching (duration tolerance: 10 seconds)
	if track == nil {
		GoLog("[%s] Trying metadata search: '%s' by '%s'\n", logPrefix, req.TrackName, req.ArtistName)
		track, err = qobuzSearchTrackByMetadataWithDurationFunc(downloader, req.TrackName, req.ArtistName, expectedDurationSec)
		if track != nil && !qobuzTrackMatchesRequest(req, track, logPrefix, "metadata search", false) {
			track = nil
		}
	}

	if track == nil {
		errMsg := "could not find matching track on Qobuz (artist/duration mismatch)"
		if err != nil {
			errMsg = err.Error()
		}
		return nil, fmt.Errorf("qobuz search failed: %s", errMsg)
	}

	GoLog("[%s] Match found: '%s' by '%s' (duration: %ds)\n", logPrefix, track.Title, track.Performer.Name, track.Duration)
	if req.ISRC != "" {
		GetTrackIDCache().SetQobuz(req.ISRC, track.ID)
	}

	return track, nil
}

func downloadFromQobuz(req DownloadRequest) (QobuzDownloadResult, error) {
	downloader := NewQobuzDownloader()

	isSafOutput := isFDOutput(req.OutputFD) || strings.TrimSpace(req.OutputPath) != ""
	if !isSafOutput {
		if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
			return QobuzDownloadResult{FilePath: "EXISTS:" + existingFile}, nil
		}
	}

	track, err := resolveQobuzTrackForRequest(req, downloader, "Qobuz")
	if err != nil {
		return QobuzDownloadResult{}, err
	}

	filename := buildFilenameFromTemplate(req.FilenameFormat, map[string]interface{}{
		"title":  req.TrackName,
		"artist": req.ArtistName,
		"album":  req.AlbumName,
		"track":  req.TrackNumber,
		"year":   extractYear(req.ReleaseDate),
		"date":   req.ReleaseDate,
		"disc":   req.DiscNumber,
	})
	var outputPath string
	if isSafOutput {
		outputPath = strings.TrimSpace(req.OutputPath)
		if outputPath == "" && isFDOutput(req.OutputFD) {
			outputPath = fmt.Sprintf("/proc/self/fd/%d", req.OutputFD)
		}
	} else {
		filename = sanitizeFilename(filename) + ".flac"
		outputPath = filepath.Join(req.OutputDir, filename)
		if fileInfo, statErr := os.Stat(outputPath); statErr == nil && fileInfo.Size() > 0 {
			return QobuzDownloadResult{FilePath: "EXISTS:" + outputPath}, nil
		}
	}

	qobuzQuality := "27"
	switch req.Quality {
	case "LOSSLESS":
		qobuzQuality = "6"
	case "HI_RES":
		qobuzQuality = "7"
	case "HI_RES_LOSSLESS", "", "DEFAULT":
		qobuzQuality = "27"
	}
	GoLog("[Qobuz] Using quality: %s (mapped from %s)\n", qobuzQuality, req.Quality)

	actualBitDepth := track.MaximumBitDepth
	actualSampleRate := int(track.MaximumSamplingRate * 1000)
	GoLog("[Qobuz] Actual quality: %d-bit/%.1fkHz\n", actualBitDepth, track.MaximumSamplingRate)

	downloadInfo, err := downloader.GetDownloadURL(track.ID, qobuzQuality)
	if err != nil {
		return QobuzDownloadResult{}, fmt.Errorf("failed to get download URL: %w", err)
	}
	if downloadInfo.BitDepth > 0 {
		actualBitDepth = downloadInfo.BitDepth
	}
	if downloadInfo.SampleRate > 0 {
		actualSampleRate = downloadInfo.SampleRate
	}
	if actualBitDepth > 0 || actualSampleRate > 0 {
		GoLog("[Qobuz] API returned quality: %d-bit/%dHz\n", actualBitDepth, actualSampleRate)
	}

	var parallelResult *ParallelDownloadResult
	parallelDone := make(chan struct{})
	go func() {
		defer close(parallelDone)
		coverURL := strings.TrimSpace(req.CoverURL)
		if coverURL == "" {
			coverURL = strings.TrimSpace(qobuzTrackAlbumImage(track))
		}
		embedLyrics := req.EmbedLyrics
		if !req.EmbedMetadata {
			coverURL = ""
			embedLyrics = false
		}
		parallelResult = FetchCoverAndLyricsParallel(
			coverURL,
			req.EmbedMaxQualityCover,
			req.SpotifyID,
			req.TrackName,
			req.ArtistName,
			embedLyrics,
			int64(req.DurationMS),
		)
	}()

	if err := downloader.DownloadFile(downloadInfo.DownloadURL, outputPath, req.OutputFD, req.ItemID); err != nil {
		if errors.Is(err, ErrDownloadCancelled) {
			return QobuzDownloadResult{}, ErrDownloadCancelled
		}
		return QobuzDownloadResult{}, fmt.Errorf("download failed: %w", err)
	}

	<-parallelDone

	if req.ItemID != "" {
		SetItemProgress(req.ItemID, 1.0, 0, 0)
		SetItemFinalizing(req.ItemID)
	}

	albumName := track.Album.Title
	if req.AlbumName != "" {
		albumName = req.AlbumName
	}
	releaseDate := track.Album.ReleaseDate
	if req.ReleaseDate != "" {
		releaseDate = req.ReleaseDate
	}

	actualTrackNumber := req.TrackNumber
	if actualTrackNumber == 0 {
		actualTrackNumber = track.TrackNumber
	}

	metadata := Metadata{
		Title:         track.Title,
		Artist:        req.ArtistName,
		Album:         albumName,
		AlbumArtist:   req.AlbumArtist,
		ArtistTagMode: req.ArtistTagMode,
		Date:          releaseDate,
		TrackNumber:   actualTrackNumber,
		TotalTracks:   req.TotalTracks,
		DiscNumber:    req.DiscNumber,
		TotalDiscs:    req.TotalDiscs,
		ISRC:          track.ISRC,
		Genre:         req.Genre,
		Label:         req.Label,
		Copyright:     req.Copyright,
		Composer:      req.Composer,
	}

	var coverData []byte
	if parallelResult != nil && parallelResult.CoverData != nil {
		coverData = parallelResult.CoverData
		GoLog("[Qobuz] Using parallel-fetched cover (%d bytes)\n", len(coverData))
	}

	if isSafOutput || !req.EmbedMetadata {
		if !req.EmbedMetadata {
			GoLog("[Qobuz] Metadata embedding disabled by settings, skipping in-backend metadata/lyrics embedding\n")
		} else {
			GoLog("[Qobuz] SAF output detected - skipping in-backend metadata/lyrics embedding (handled in Flutter)\n")
		}
	} else {
		if err := EmbedMetadataWithCoverData(outputPath, metadata, coverData); err != nil {
			fmt.Printf("Warning: failed to embed metadata: %v\n", err)
		}

		if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
			lyricsMode := req.LyricsMode
			if lyricsMode == "" {
				lyricsMode = "embed"
			}

			if lyricsMode == "external" || lyricsMode == "both" {
				GoLog("[Qobuz] Saving external LRC file...\n")
				if lrcPath, lrcErr := SaveLRCFile(outputPath, parallelResult.LyricsLRC); lrcErr != nil {
					GoLog("[Qobuz] Warning: failed to save LRC file: %v\n", lrcErr)
				} else {
					GoLog("[Qobuz] LRC file saved: %s\n", lrcPath)
				}
			}

			if lyricsMode == "embed" || lyricsMode == "both" {
				GoLog("[Qobuz] Embedding parallel-fetched lyrics (%d lines)...\n", len(parallelResult.LyricsData.Lines))
				if embedErr := EmbedLyrics(outputPath, parallelResult.LyricsLRC); embedErr != nil {
					GoLog("[Qobuz] Warning: failed to embed lyrics: %v\n", embedErr)
				} else {
					fmt.Println("[Qobuz] Lyrics embedded successfully")
				}
			}
		} else if req.EmbedLyrics {
			fmt.Println("[Qobuz] No lyrics available from parallel fetch")
		}
	}

	if !isSafOutput {
		AddToISRCIndex(req.OutputDir, req.ISRC, outputPath)
	}

	lyricsLRC := ""
	if req.EmbedMetadata && req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
		lyricsLRC = parallelResult.LyricsLRC
	}

	resultAlbum, resultReleaseDate, resultTrackNumber, resultDiscNumber := preferredReleaseMetadata(
		req,
		track.Album.Title,
		track.Album.ReleaseDate,
		actualTrackNumber,
		req.DiscNumber,
	)

	// Prefer the cover URL the frontend sent (user-selected album) over the
	// track's default album cover returned by the Qobuz track/get API, which
	// may belong to a different album when the same track appears on multiple
	// releases.
	resultCoverURL := strings.TrimSpace(req.CoverURL)
	if resultCoverURL == "" {
		resultCoverURL = strings.TrimSpace(qobuzTrackAlbumImage(track))
	}

	return QobuzDownloadResult{
		FilePath:    outputPath,
		BitDepth:    actualBitDepth,
		SampleRate:  actualSampleRate,
		Title:       track.Title,
		Artist:      track.Performer.Name,
		Album:       resultAlbum,
		ReleaseDate: resultReleaseDate,
		TrackNumber: resultTrackNumber,
		DiscNumber:  resultDiscNumber,
		ISRC:        track.ISRC,
		CoverURL:    resultCoverURL,
		LyricsLRC:   lyricsLRC,
	}, nil
}
