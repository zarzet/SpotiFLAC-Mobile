package gobackend

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/dop251/goja"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

func CheckAvailability(spotifyID, isrc string) (string, error) {
	client := NewSongLinkClient()
	availability, err := client.CheckTrackAvailability(spotifyID, isrc)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(availability)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// SetSongLinkNetworkOptions is kept for backward compatibility.
func SetSongLinkNetworkOptions(allowHTTP, insecureTLS bool) {
	SetNetworkCompatibilityOptions(allowHTTP, insecureTLS)
}

const musicBrainzAPIBase = "https://musicbrainz.org/ws/2"

type musicBrainzTag struct {
	Count int    `json:"count"`
	Name  string `json:"name"`
}

type musicBrainzRecordingResponse struct {
	Recordings []struct {
		Tags []musicBrainzTag `json:"tags"`
	} `json:"recordings"`
}

func formatMusicBrainzGenre(tags []musicBrainzTag) string {
	if len(tags) == 0 {
		return ""
	}

	caser := cases.Title(language.English)
	seen := make(map[string]struct{}, len(tags))
	maxCount := -1
	bestTag := ""

	for _, tag := range tags {
		name := strings.TrimSpace(tag.Name)
		if name == "" {
			continue
		}

		key := strings.ToLower(name)
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}

		formatted := caser.String(name)
		if tag.Count > maxCount {
			maxCount = tag.Count
			bestTag = formatted
		}
	}

	return bestTag
}

func FetchMusicBrainzGenreByISRC(isrc string) (string, error) {
	normalizedISRC := strings.ToUpper(strings.TrimSpace(isrc))
	if normalizedISRC == "" {
		return "", fmt.Errorf("no ISRC provided")
	}

	client := NewMetadataHTTPClient(10 * time.Second)
	query := fmt.Sprintf("isrc:%s", normalizedISRC)
	reqURL := fmt.Sprintf(
		"%s/recording?query=%s&fmt=json&inc=tags",
		musicBrainzAPIBase,
		url.QueryEscape(query),
	)

	req, err := http.NewRequest(http.MethodGet, reqURL, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", getRandomUserAgent())

	var resp *http.Response
	var lastErr error
	for attempt := 0; attempt < 3; attempt++ {
		resp, lastErr = client.Do(req)
		if lastErr == nil && resp.StatusCode == http.StatusOK {
			break
		}
		if resp != nil {
			resp.Body.Close()
		}
		if attempt < 2 {
			time.Sleep(2 * time.Second)
		}
	}

	if lastErr != nil {
		return "", lastErr
	}
	if resp == nil {
		return "", fmt.Errorf("MusicBrainz request failed without response")
	}
	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return "", fmt.Errorf("MusicBrainz API returned status: %d", resp.StatusCode)
	}
	defer resp.Body.Close()

	var payload musicBrainzRecordingResponse
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		return "", err
	}
	if len(payload.Recordings) == 0 {
		return "", fmt.Errorf("no recordings found for ISRC: %s", normalizedISRC)
	}

	genre := formatMusicBrainzGenre(payload.Recordings[0].Tags)
	if genre == "" {
		return "", fmt.Errorf("no MusicBrainz genre tags found for ISRC: %s", normalizedISRC)
	}
	return genre, nil
}

type DownloadRequest struct {
	ISRC                 string `json:"isrc"`
	Service              string `json:"service"`
	SpotifyID            string `json:"spotify_id"`
	TrackName            string `json:"track_name"`
	ArtistName           string `json:"artist_name"`
	AlbumName            string `json:"album_name"`
	AlbumArtist          string `json:"album_artist"`
	CoverURL             string `json:"cover_url"`
	OutputDir            string `json:"output_dir"`
	OutputPath           string `json:"output_path,omitempty"`
	OutputFD             int    `json:"output_fd,omitempty"`
	OutputExt            string `json:"output_ext,omitempty"`
	FilenameFormat       string `json:"filename_format"`
	Quality              string `json:"quality"`
	EmbedMetadata        bool   `json:"embed_metadata"`
	ArtistTagMode        string `json:"artist_tag_mode,omitempty"`
	EmbedLyrics          bool   `json:"embed_lyrics"`
	EmbedMaxQualityCover bool   `json:"embed_max_quality_cover"`
	TrackNumber          int    `json:"track_number"`
	DiscNumber           int    `json:"disc_number"`
	TotalTracks          int    `json:"total_tracks"`
	TotalDiscs           int    `json:"total_discs,omitempty"`
	ReleaseDate          string `json:"release_date"`
	ItemID               string `json:"item_id"`
	DurationMS           int    `json:"duration_ms"`
	Source               string `json:"source"`
	Genre                string `json:"genre,omitempty"`
	Label                string `json:"label,omitempty"`
	Copyright            string `json:"copyright,omitempty"`
	Composer             string `json:"composer,omitempty"`
	TidalID              string `json:"tidal_id,omitempty"`
	QobuzID              string `json:"qobuz_id,omitempty"`
	DeezerID             string `json:"deezer_id,omitempty"`
	LyricsMode           string `json:"lyrics_mode,omitempty"`
	UseExtensions        bool   `json:"use_extensions,omitempty"`
	UseFallback          bool   `json:"use_fallback,omitempty"`
	SongLinkRegion       string `json:"songlink_region,omitempty"`
}

type DownloadResponse struct {
	Success                bool                    `json:"success"`
	Message                string                  `json:"message"`
	FilePath               string                  `json:"file_path,omitempty"`
	Error                  string                  `json:"error,omitempty"`
	ErrorType              string                  `json:"error_type,omitempty"`
	AlreadyExists          bool                    `json:"already_exists,omitempty"`
	ActualBitDepth         int                     `json:"actual_bit_depth,omitempty"`
	ActualSampleRate       int                     `json:"actual_sample_rate,omitempty"`
	Service                string                  `json:"service,omitempty"`
	Title                  string                  `json:"title,omitempty"`
	Artist                 string                  `json:"artist,omitempty"`
	Album                  string                  `json:"album,omitempty"`
	AlbumArtist            string                  `json:"album_artist,omitempty"`
	ReleaseDate            string                  `json:"release_date,omitempty"`
	TrackNumber            int                     `json:"track_number,omitempty"`
	DiscNumber             int                     `json:"disc_number,omitempty"`
	TotalTracks            int                     `json:"total_tracks,omitempty"`
	TotalDiscs             int                     `json:"total_discs,omitempty"`
	ISRC                   string                  `json:"isrc,omitempty"`
	CoverURL               string                  `json:"cover_url,omitempty"`
	Genre                  string                  `json:"genre,omitempty"`
	Label                  string                  `json:"label,omitempty"`
	Copyright              string                  `json:"copyright,omitempty"`
	Composer               string                  `json:"composer,omitempty"`
	SkipMetadataEnrichment bool                    `json:"skip_metadata_enrichment,omitempty"`
	LyricsLRC              string                  `json:"lyrics_lrc,omitempty"`
	DecryptionKey          string                  `json:"decryption_key,omitempty"`
	Decryption             *DownloadDecryptionInfo `json:"decryption,omitempty"`
}

type DownloadResult struct {
	FilePath      string
	BitDepth      int
	SampleRate    int
	Title         string
	Artist        string
	Album         string
	ReleaseDate   string
	TrackNumber   int
	TotalTracks   int
	DiscNumber    int
	TotalDiscs    int
	ISRC          string
	CoverURL      string
	Genre         string
	Label         string
	Copyright     string
	Composer      string
	LyricsLRC     string
	DecryptionKey string
	Decryption    *DownloadDecryptionInfo
}

var fetchDeezerExtendedMetadataByISRC = func(ctx context.Context, isrc string) (*AlbumExtendedMetadata, error) {
	return GetDeezerClient().GetExtendedMetadataByISRC(ctx, isrc)
}

var fetchMusicBrainzGenreByISRC = FetchMusicBrainzGenreByISRC

type reEnrichRequest struct {
	FilePath      string   `json:"file_path"`
	CoverURL      string   `json:"cover_url"`
	MaxQuality    bool     `json:"max_quality"`
	EmbedLyrics   bool     `json:"embed_lyrics"`
	ArtistTagMode string   `json:"artist_tag_mode,omitempty"`
	SpotifyID     string   `json:"spotify_id"`
	TrackName     string   `json:"track_name"`
	ArtistName    string   `json:"artist_name"`
	AlbumName     string   `json:"album_name"`
	AlbumArtist   string   `json:"album_artist"`
	TrackNumber   int      `json:"track_number"`
	DiscNumber    int      `json:"disc_number"`
	TotalTracks   int      `json:"total_tracks,omitempty"`
	TotalDiscs    int      `json:"total_discs,omitempty"`
	ReleaseDate   string   `json:"release_date"`
	ISRC          string   `json:"isrc"`
	Genre         string   `json:"genre"`
	Label         string   `json:"label"`
	Copyright     string   `json:"copyright"`
	Composer      string   `json:"composer"`
	DurationMs    int64    `json:"duration_ms"`
	SearchOnline  bool     `json:"search_online"`
	UpdateFields  []string `json:"update_fields,omitempty"`
}

// shouldUpdateField returns true if the given field group should be updated.
// When UpdateFields is empty/nil, all fields are updated (backward compatible).
func (r *reEnrichRequest) shouldUpdateField(field string) bool {
	if len(r.UpdateFields) == 0 {
		return true
	}
	for _, f := range r.UpdateFields {
		if f == field {
			return true
		}
	}
	return false
}

func applyReEnrichTrackMetadata(req *reEnrichRequest, track ExtTrackMetadata) {
	if req == nil {
		return
	}

	if track.SpotifyID != "" {
		req.SpotifyID = track.SpotifyID
	} else if track.DeezerID != "" {
		req.SpotifyID = "deezer:" + track.DeezerID
	} else if track.QobuzID != "" {
		req.SpotifyID = "qobuz:" + track.QobuzID
	} else if track.TidalID != "" {
		req.SpotifyID = "tidal:" + track.TidalID
	} else if track.ID != "" {
		req.SpotifyID = track.ID
	}

	if req.shouldUpdateField("basic_tags") {
		if track.Name != "" {
			req.TrackName = track.Name
		}
		if track.Artists != "" {
			req.ArtistName = track.Artists
		}
		if track.AlbumName != "" {
			req.AlbumName = track.AlbumName
		}
		if track.AlbumArtist != "" {
			req.AlbumArtist = track.AlbumArtist
		}
	}
	if req.shouldUpdateField("track_info") {
		if track.TrackNumber > 0 {
			req.TrackNumber = track.TrackNumber
		}
		if track.TotalTracks > 0 {
			req.TotalTracks = track.TotalTracks
		}
		if track.DiscNumber > 0 {
			req.DiscNumber = track.DiscNumber
		}
		if track.TotalDiscs > 0 {
			req.TotalDiscs = track.TotalDiscs
		}
	}
	if req.shouldUpdateField("release_info") {
		if track.ReleaseDate != "" {
			req.ReleaseDate = track.ReleaseDate
		}
		if track.ISRC != "" {
			req.ISRC = track.ISRC
		}
	}
	if req.shouldUpdateField("cover") {
		if coverURL := track.ResolvedCoverURL(); coverURL != "" {
			req.CoverURL = coverURL
		}
	}
	if track.DurationMS > 0 {
		req.DurationMs = int64(track.DurationMS)
	}
	if req.shouldUpdateField("extra") {
		if track.Genre != "" {
			req.Genre = track.Genre
		}
		if track.Label != "" {
			req.Label = track.Label
		}
		if track.Copyright != "" {
			req.Copyright = track.Copyright
		}
		if track.Composer != "" {
			req.Composer = track.Composer
		}
	}
}

func isPlaceholderReEnrichValue(value string) bool {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "", "unknown", "unknown artist", "unknown title", "unknown album":
		return true
	default:
		return false
	}
}

func buildReEnrichSearchQuery(req reEnrichRequest) string {
	parts := make([]string, 0, 2)
	if !isPlaceholderReEnrichValue(req.TrackName) {
		parts = append(parts, strings.TrimSpace(req.TrackName))
	}
	if !isPlaceholderReEnrichValue(req.ArtistName) {
		parts = append(parts, strings.TrimSpace(req.ArtistName))
	}
	if len(parts) == 0 && !isPlaceholderReEnrichValue(req.AlbumName) {
		parts = append(parts, strings.TrimSpace(req.AlbumName))
	}
	return strings.TrimSpace(strings.Join(parts, " "))
}

func reEnrichDownloadRequest(req reEnrichRequest) DownloadRequest {
	return DownloadRequest{
		TrackName:     req.TrackName,
		ArtistName:    req.ArtistName,
		AlbumName:     req.AlbumName,
		ReleaseDate:   req.ReleaseDate,
		ISRC:          req.ISRC,
		DurationMS:    int(req.DurationMs),
		ArtistTagMode: req.ArtistTagMode,
		TrackNumber:   req.TrackNumber,
		TotalTracks:   req.TotalTracks,
		DiscNumber:    req.DiscNumber,
		TotalDiscs:    req.TotalDiscs,
		Composer:      req.Composer,
	}
}

func buildReEnrichFFmpegMetadata(req *reEnrichRequest, lyricsLRC string) map[string]string {
	metadata := map[string]string{}
	if req.shouldUpdateField("basic_tags") {
		if req.TrackName != "" {
			metadata["TITLE"] = req.TrackName
		}
		if req.ArtistName != "" {
			metadata["ARTIST"] = req.ArtistName
		}
		if req.AlbumName != "" {
			metadata["ALBUM"] = req.AlbumName
		}
		if req.AlbumArtist != "" {
			metadata["ALBUMARTIST"] = req.AlbumArtist
		}
	}
	if req.shouldUpdateField("release_info") {
		if req.ReleaseDate != "" {
			metadata["DATE"] = req.ReleaseDate
		}
		if req.ISRC != "" {
			metadata["ISRC"] = req.ISRC
		}
	}
	if req.shouldUpdateField("extra") {
		if req.Genre != "" {
			metadata["GENRE"] = req.Genre
		}
		if req.Label != "" {
			metadata["ORGANIZATION"] = req.Label
		}
		if req.Copyright != "" {
			metadata["COPYRIGHT"] = req.Copyright
		}
		if req.Composer != "" {
			metadata["COMPOSER"] = req.Composer
		}
	}
	if req.shouldUpdateField("track_info") {
		if req.TrackNumber > 0 {
			metadata["TRACKNUMBER"] = formatIndexValue(req.TrackNumber, req.TotalTracks)
		}
		if req.DiscNumber > 0 {
			metadata["DISCNUMBER"] = formatIndexValue(req.DiscNumber, req.TotalDiscs)
		}
	}
	if req.shouldUpdateField("lyrics") {
		if lyricsLRC != "" {
			metadata["LYRICS"] = lyricsLRC
			metadata["UNSYNCEDLYRICS"] = lyricsLRC
		}
	}
	return metadata
}

func selectBestReEnrichTrack(req reEnrichRequest, tracks []ExtTrackMetadata) *ExtTrackMetadata {
	if len(tracks) == 0 {
		return nil
	}

	downloadReq := reEnrichDownloadRequest(req)
	currentISRC := strings.TrimSpace(req.ISRC)
	currentAlbum := strings.TrimSpace(req.AlbumName)
	var best *ExtTrackMetadata
	bestScore := -1 << 30

	for i := range tracks {
		track := &tracks[i]
		score := 0

		resolved := resolvedTrackInfo{
			Title:      track.Name,
			ArtistName: track.Artists,
			ISRC:       track.ISRC,
			Duration:   track.DurationMS / 1000,
		}
		if trackMatchesRequest(downloadReq, resolved, "ReEnrich") {
			score += 2000
		}

		if currentISRC != "" && strings.EqualFold(currentISRC, strings.TrimSpace(track.ISRC)) {
			score += 10000
		}
		if req.TrackName != "" && track.Name != "" && titlesMatch(req.TrackName, track.Name) {
			score += 400
		}
		if req.ArtistName != "" && track.Artists != "" && artistsMatch(req.ArtistName, track.Artists) {
			score += 320
		}
		if currentAlbum != "" && track.AlbumName != "" {
			switch {
			case titlesMatch(currentAlbum, track.AlbumName):
				score += 120
			case strings.Contains(strings.ToLower(track.AlbumName), strings.ToLower(currentAlbum)),
				strings.Contains(strings.ToLower(currentAlbum), strings.ToLower(track.AlbumName)):
				score += 50
			}
		}

		if req.DurationMs > 0 && track.DurationMS > 0 {
			diff := int(req.DurationMs/1000) - (track.DurationMS / 1000)
			if diff < 0 {
				diff = -diff
			}
			if diff <= 10 {
				score += 80
			}
		}

		if track.ReleaseDate != "" {
			score += 70
		}
		if track.TrackNumber > 0 {
			score += 20
		}
		if track.DiscNumber > 0 {
			score += 10
		}
		if track.ISRC != "" {
			score += 40
		}

		if best == nil || score > bestScore {
			best = track
			bestScore = score
		}
	}

	return best
}

func extTrackFromTrackMetadata(track *TrackMetadata, providerID string) *ExtTrackMetadata {
	if track == nil {
		return nil
	}

	deezerID := strings.TrimSpace(strings.TrimPrefix(track.SpotifyID, "deezer:"))
	return &ExtTrackMetadata{
		ID:          track.SpotifyID,
		Name:        track.Name,
		Artists:     track.Artists,
		AlbumName:   track.AlbumName,
		AlbumArtist: track.AlbumArtist,
		DurationMS:  track.DurationMS,
		CoverURL:    track.Images,
		Images:      track.Images,
		ReleaseDate: track.ReleaseDate,
		TrackNumber: track.TrackNumber,
		TotalTracks: track.TotalTracks,
		DiscNumber:  track.DiscNumber,
		TotalDiscs:  track.TotalDiscs,
		ISRC:        track.ISRC,
		ProviderID:  providerID,
		DeezerID:    deezerID,
		SpotifyID:   track.SpotifyID,
		Composer:    track.Composer,
	}
}

func normalizeReEnrichSpotifyTrackID(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return ""
	}
	if extracted := extractSpotifyIDFromURL(trimmed); extracted != "" {
		return extracted
	}
	if len(trimmed) == 22 && !strings.Contains(trimmed, ":") && !strings.Contains(trimmed, "/") {
		return trimmed
	}
	return ""
}

func resolveReEnrichTrackFromIdentifiers(req reEnrichRequest) (*ExtTrackMetadata, error) {
	deezerClient := GetDeezerClient()
	downloadReq := reEnrichDownloadRequest(req)

	if isrc := strings.TrimSpace(req.ISRC); isrc != "" {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		track, err := deezerClient.SearchByISRC(ctx, isrc)
		cancel()
		if err == nil && track != nil {
			resolved := resolvedTrackInfo{
				Title:      track.Name,
				ArtistName: track.Artists,
				ISRC:       track.ISRC,
				Duration:   track.DurationMS / 1000,
			}
			if trackMatchesRequest(downloadReq, resolved, "ReEnrich") {
				return extTrackFromTrackMetadata(track, "deezer"), nil
			}
		}
	}

	sourceTrackID := strings.TrimSpace(req.SpotifyID)
	if sourceTrackID == "" {
		return nil, nil
	}

	deezerID := strings.TrimSpace(strings.TrimPrefix(sourceTrackID, "deezer:"))
	if deezerID == sourceTrackID {
		deezerID = extractDeezerIDFromURL(sourceTrackID)
	}
	if deezerID == "" {
		spotifyID := normalizeReEnrichSpotifyTrackID(sourceTrackID)
		if spotifyID != "" {
			resolvedDeezerID, err := NewSongLinkClient().GetDeezerIDFromSpotify(spotifyID)
			if err == nil {
				deezerID = strings.TrimSpace(resolvedDeezerID)
			}
		}
	}
	if deezerID == "" {
		return nil, nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	trackResp, err := deezerClient.GetTrack(ctx, deezerID)
	if err != nil || trackResp == nil {
		return nil, err
	}

	track := &trackResp.Track
	resolved := resolvedTrackInfo{
		Title:      track.Name,
		ArtistName: track.Artists,
		ISRC:       track.ISRC,
		Duration:   track.DurationMS / 1000,
	}
	if !trackMatchesRequest(downloadReq, resolved, "ReEnrich") {
		return nil, nil
	}

	return extTrackFromTrackMetadata(track, "deezer"), nil
}

func preferredReleaseMetadata(
	req DownloadRequest,
	album string,
	releaseDate string,
	trackNumber int,
	discNumber int,
) (string, string, int, int) {
	preferredAlbum := strings.TrimSpace(req.AlbumName)
	if preferredAlbum == "" {
		preferredAlbum = album
	}

	preferredReleaseDate := strings.TrimSpace(req.ReleaseDate)
	if preferredReleaseDate == "" {
		preferredReleaseDate = releaseDate
	}

	preferredTrackNumber := req.TrackNumber
	if preferredTrackNumber == 0 {
		preferredTrackNumber = trackNumber
	}

	preferredDiscNumber := req.DiscNumber
	if preferredDiscNumber == 0 {
		preferredDiscNumber = discNumber
	}

	return preferredAlbum, preferredReleaseDate, preferredTrackNumber, preferredDiscNumber
}

func buildDownloadSuccessResponse(
	req DownloadRequest,
	result DownloadResult,
	service string,
	message string,
	filePath string,
	alreadyExists bool,
) DownloadResponse {
	title := result.Title
	if title == "" {
		title = req.TrackName
	}

	artist := result.Artist
	if artist == "" {
		artist = req.ArtistName
	}

	// Preserve requested release metadata when available so mixed-provider
	// fallback downloads from the same source album do not get split into
	// different albums just because Tidal/Qobuz report variant titles/dates.
	album, releaseDate, trackNumber, discNumber := preferredReleaseMetadata(
		req,
		result.Album,
		result.ReleaseDate,
		result.TrackNumber,
		result.DiscNumber,
	)

	isrc := result.ISRC
	if isrc == "" {
		isrc = req.ISRC
	}

	genre := result.Genre
	if genre == "" {
		genre = req.Genre
	}

	label := result.Label
	if label == "" {
		label = req.Label
	}

	copyright := result.Copyright
	if copyright == "" {
		copyright = req.Copyright
	}

	composer := result.Composer
	if composer == "" {
		composer = req.Composer
	}

	coverURL := strings.TrimSpace(result.CoverURL)
	if coverURL == "" {
		coverURL = strings.TrimSpace(req.CoverURL)
	}

	return DownloadResponse{
		Success:          true,
		Message:          message,
		FilePath:         filePath,
		AlreadyExists:    alreadyExists,
		ActualBitDepth:   result.BitDepth,
		ActualSampleRate: result.SampleRate,
		Service:          service,
		Title:            title,
		Artist:           artist,
		Album:            album,
		AlbumArtist:      req.AlbumArtist,
		ReleaseDate:      releaseDate,
		TrackNumber:      trackNumber,
		TotalTracks:      req.TotalTracks,
		DiscNumber:       discNumber,
		TotalDiscs:       req.TotalDiscs,
		ISRC:             isrc,
		CoverURL:         coverURL,
		Genre:            genre,
		Label:            label,
		Copyright:        copyright,
		Composer:         composer,
		LyricsLRC:        result.LyricsLRC,
		DecryptionKey:    result.DecryptionKey,
		Decryption:       normalizeDownloadDecryptionInfo(result.Decryption, result.DecryptionKey),
	}
}

func shouldSkipQualityProbe(filePath string) bool {
	path := strings.TrimSpace(filePath)
	if path == "" {
		return true
	}
	if strings.HasPrefix(path, "/proc/self/fd/") {
		return true
	}
	// Content URI and other non-filesystem schemes cannot be read directly by os.Open.
	if strings.Contains(path, "://") {
		return true
	}
	return false
}

func enrichResultQualityFromFile(result *DownloadResult) {
	if result == nil {
		return
	}

	path := strings.TrimSpace(result.FilePath)
	if shouldSkipQualityProbe(path) {
		if strings.HasPrefix(path, "/proc/self/fd/") {
			LogDebug("Download", "Skipping quality probe for ephemeral SAF FD output: %s", path)
		}
		return
	}

	quality, qErr := GetAudioQuality(path)
	if qErr == nil {
		result.BitDepth = quality.BitDepth
		result.SampleRate = quality.SampleRate
		GoLog("[Download] Actual quality from file: %d-bit/%dHz\n", quality.BitDepth, quality.SampleRate)
		return
	}

	LogDebug("Download", "Post-download quality probe unavailable for %s: %v", path, qErr)
}

func applyExtendedMetadataFields(
	genre *string,
	label *string,
	copyright *string,
	extMeta *AlbumExtendedMetadata,
) {
	if extMeta == nil {
		return
	}

	if genre != nil && *genre == "" && extMeta.Genre != "" {
		*genre = extMeta.Genre
	}
	if label != nil && *label == "" && extMeta.Label != "" {
		*label = extMeta.Label
	}
	if copyright != nil && *copyright == "" && extMeta.Copyright != "" {
		*copyright = extMeta.Copyright
	}
}

func enrichExtraMetadataByISRC(
	logPrefix string,
	isrc string,
	genre *string,
	label *string,
	copyright *string,
) {
	normalizedISRC := strings.TrimSpace(isrc)
	if normalizedISRC == "" {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	extMeta, err := fetchDeezerExtendedMetadataByISRC(ctx, normalizedISRC)
	if err != nil {
		GoLog("[%s] Failed to get extended metadata from Deezer: %v\n", logPrefix, err)
	}
	applyExtendedMetadataFields(genre, label, copyright, extMeta)

	if genre != nil && *genre == "" {
		musicBrainzGenre, err := fetchMusicBrainzGenreByISRC(normalizedISRC)
		if err != nil {
			GoLog("[%s] Failed to get genre from MusicBrainz: %v\n", logPrefix, err)
		} else if musicBrainzGenre != "" {
			*genre = musicBrainzGenre
			GoLog("[%s] Genre fallback from MusicBrainz: %s\n", logPrefix, *genre)
		}
	}

	currentGenre := ""
	currentLabel := ""
	currentCopyright := ""
	if genre != nil {
		currentGenre = *genre
	}
	if label != nil {
		currentLabel = *label
	}
	if copyright != nil {
		currentCopyright = *copyright
	}
	if currentGenre != "" || currentLabel != "" || currentCopyright != "" {
		GoLog("[%s] Extended metadata ready: genre=%s, label=%s, copyright=%s\n", logPrefix, currentGenre, currentLabel, currentCopyright)
	}
}

func enrichRequestExtendedMetadata(req *DownloadRequest) {
	if req == nil {
		return
	}

	if req.ISRC == "" || (req.Genre != "" && req.Label != "" && req.Copyright != "") {
		return
	}

	enrichExtraMetadataByISRC(
		"DownloadWithFallback",
		req.ISRC,
		&req.Genre,
		&req.Label,
		&req.Copyright,
	)
}

func applySongLinkRegionFromRequest(req *DownloadRequest) {
	if req == nil {
		return
	}
	SetSongLinkRegion(req.SongLinkRegion)
}

func DownloadTrack(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return errorResponse("Invalid request: " + err.Error())
	}
	applySongLinkRegionFromRequest(&req)
	defer closeOwnedOutputFD(req.OutputFD)

	req.TrackName = strings.TrimSpace(req.TrackName)
	req.ArtistName = strings.TrimSpace(req.ArtistName)
	req.AlbumName = strings.TrimSpace(req.AlbumName)
	req.AlbumArtist = strings.TrimSpace(req.AlbumArtist)
	req.OutputDir = strings.TrimSpace(req.OutputDir)
	req.OutputPath = strings.TrimSpace(req.OutputPath)
	req.OutputExt = strings.TrimSpace(req.OutputExt)

	if req.OutputPath == "" && req.OutputFD <= 0 && req.OutputDir != "" {
		AddAllowedDownloadDir(req.OutputDir)
	}

	enrichRequestExtendedMetadata(&req)

	var result DownloadResult
	var err error

	switch req.Service {
	case "tidal":
		tidalResult, tidalErr := downloadFromTidal(req)
		if tidalErr == nil {
			result = DownloadResult{
				FilePath:    tidalResult.FilePath,
				BitDepth:    tidalResult.BitDepth,
				SampleRate:  tidalResult.SampleRate,
				Title:       tidalResult.Title,
				Artist:      tidalResult.Artist,
				Album:       tidalResult.Album,
				ReleaseDate: tidalResult.ReleaseDate,
				TrackNumber: tidalResult.TrackNumber,
				DiscNumber:  tidalResult.DiscNumber,
				ISRC:        tidalResult.ISRC,
				LyricsLRC:   tidalResult.LyricsLRC,
			}
		}
		err = tidalErr
	case "qobuz":
		qobuzResult, qobuzErr := downloadFromQobuz(req)
		if qobuzErr == nil {
			result = DownloadResult{
				FilePath:    qobuzResult.FilePath,
				BitDepth:    qobuzResult.BitDepth,
				SampleRate:  qobuzResult.SampleRate,
				Title:       qobuzResult.Title,
				Artist:      qobuzResult.Artist,
				Album:       qobuzResult.Album,
				ReleaseDate: qobuzResult.ReleaseDate,
				TrackNumber: qobuzResult.TrackNumber,
				DiscNumber:  qobuzResult.DiscNumber,
				ISRC:        qobuzResult.ISRC,
				CoverURL:    qobuzResult.CoverURL,
				LyricsLRC:   qobuzResult.LyricsLRC,
			}
		}
		err = qobuzErr
	default:
		return errorResponse("Unknown service: " + req.Service)
	}

	if err != nil {
		return errorResponse(err.Error())
	}

	if len(result.FilePath) > 7 && result.FilePath[:7] == "EXISTS:" {
		actualPath := result.FilePath[7:]
		result.FilePath = actualPath
		enrichResultQualityFromFile(&result)
		resp := buildDownloadSuccessResponse(
			req,
			result,
			req.Service,
			"File already exists",
			actualPath,
			true,
		)
		jsonBytes, _ := json.Marshal(resp)
		return string(jsonBytes), nil
	}

	enrichResultQualityFromFile(&result)

	resp := buildDownloadSuccessResponse(
		req,
		result,
		req.Service,
		"Download complete",
		result.FilePath,
		false,
	)

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

// DownloadByStrategy routes download requests with priority: YouTube > extension fallback > built-in fallback > direct service.
func DownloadByStrategy(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return errorResponse("Invalid request: " + err.Error())
	}

	serviceRaw := strings.TrimSpace(req.Service)
	serviceNormalized := strings.ToLower(serviceRaw)

	normalizedReq := req
	if isBuiltInDownloadProvider(serviceNormalized) {
		normalizedReq.Service = serviceNormalized
	}

	normalizedBytes, err := json.Marshal(normalizedReq)
	if err != nil {
		return errorResponse("Invalid request: " + err.Error())
	}
	normalizedJSON := string(normalizedBytes)

	if req.UseExtensions {
		// Respect strict mode when auto fallback is disabled:
		// for built-in providers, route directly to selected service only.
		if !req.UseFallback && isBuiltInDownloadProvider(serviceNormalized) {
			return DownloadTrack(normalizedJSON)
		}
		resp, err := DownloadWithExtensionsJSON(normalizedJSON)
		if err != nil {
			return errorResponse(err.Error())
		}
		return resp, nil
	}

	if req.UseFallback {
		return DownloadWithFallback(normalizedJSON)
	}

	return DownloadTrack(normalizedJSON)
}

func DownloadWithFallback(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return errorResponse("Invalid request: " + err.Error())
	}
	applySongLinkRegionFromRequest(&req)
	defer closeOwnedOutputFD(req.OutputFD)

	req.TrackName = strings.TrimSpace(req.TrackName)
	req.ArtistName = strings.TrimSpace(req.ArtistName)
	req.AlbumName = strings.TrimSpace(req.AlbumName)
	req.AlbumArtist = strings.TrimSpace(req.AlbumArtist)
	req.OutputDir = strings.TrimSpace(req.OutputDir)
	req.OutputPath = strings.TrimSpace(req.OutputPath)
	req.OutputExt = strings.TrimSpace(req.OutputExt)

	if req.OutputPath == "" && req.OutputFD <= 0 && req.OutputDir != "" {
		AddAllowedDownloadDir(req.OutputDir)
	}

	enrichRequestExtendedMetadata(&req)

	allServices := []string{"tidal", "qobuz"}
	preferredService := req.Service
	if !isBuiltInDownloadProvider(preferredService) {
		preferredService = "tidal"
	}

	GoLog("[DownloadWithFallback] Preferred service from request: '%s'\n", req.Service)

	services := []string{preferredService}
	for _, s := range allServices {
		if s != preferredService {
			services = append(services, s)
		}
	}

	GoLog("[DownloadWithFallback] Service order: %v\n", services)

	var lastErr error

	for _, service := range services {
		GoLog("[DownloadWithFallback] Trying service: %s\n", service)
		req.Service = service

		var result DownloadResult
		var err error

		switch service {
		case "tidal":
			tidalResult, tidalErr := downloadFromTidal(req)
			if tidalErr == nil {
				result = DownloadResult{
					FilePath:    tidalResult.FilePath,
					BitDepth:    tidalResult.BitDepth,
					SampleRate:  tidalResult.SampleRate,
					Title:       tidalResult.Title,
					Artist:      tidalResult.Artist,
					Album:       tidalResult.Album,
					ReleaseDate: tidalResult.ReleaseDate,
					TrackNumber: tidalResult.TrackNumber,
					DiscNumber:  tidalResult.DiscNumber,
					ISRC:        tidalResult.ISRC,
					LyricsLRC:   tidalResult.LyricsLRC,
				}
			} else if !errors.Is(tidalErr, ErrDownloadCancelled) {
				GoLog("[DownloadWithFallback] Tidal error: %v\n", tidalErr)
			}
			err = tidalErr
		case "qobuz":
			qobuzResult, qobuzErr := downloadFromQobuz(req)
			if qobuzErr == nil {
				result = DownloadResult{
					FilePath:    qobuzResult.FilePath,
					BitDepth:    qobuzResult.BitDepth,
					SampleRate:  qobuzResult.SampleRate,
					Title:       qobuzResult.Title,
					Artist:      qobuzResult.Artist,
					Album:       qobuzResult.Album,
					ReleaseDate: qobuzResult.ReleaseDate,
					TrackNumber: qobuzResult.TrackNumber,
					DiscNumber:  qobuzResult.DiscNumber,
					ISRC:        qobuzResult.ISRC,
					CoverURL:    qobuzResult.CoverURL,
					LyricsLRC:   qobuzResult.LyricsLRC,
				}
			} else if !errors.Is(qobuzErr, ErrDownloadCancelled) {
				GoLog("[DownloadWithFallback] Qobuz error: %v\n", qobuzErr)
			}
			err = qobuzErr
		}

		if err != nil && errors.Is(err, ErrDownloadCancelled) {
			return errorResponse("Download cancelled")
		}

		if err == nil {
			if len(result.FilePath) > 7 && result.FilePath[:7] == "EXISTS:" {
				actualPath := result.FilePath[7:]
				result.FilePath = actualPath
				enrichResultQualityFromFile(&result)
				resp := buildDownloadSuccessResponse(
					req,
					result,
					service,
					"File already exists",
					actualPath,
					true,
				)
				jsonBytes, _ := json.Marshal(resp)
				return string(jsonBytes), nil
			}

			enrichResultQualityFromFile(&result)

			resp := buildDownloadSuccessResponse(
				req,
				result,
				service,
				"Downloaded from "+service,
				result.FilePath,
				false,
			)
			jsonBytes, _ := json.Marshal(resp)
			return string(jsonBytes), nil
		}

		lastErr = err
	}

	return errorResponse("All services failed. Last error: " + lastErr.Error())
}

func GetDownloadProgress() string {
	progress := getProgress()
	jsonBytes, _ := json.Marshal(progress)
	return string(jsonBytes)
}

func GetAllDownloadProgress() string {
	return GetMultiProgress()
}

func InitItemProgress(itemID string) {
	StartItemProgress(itemID)
}

func FinishItemProgress(itemID string) {
	CompleteItemProgress(itemID)
}

func ClearItemProgress(itemID string) {
	RemoveItemProgress(itemID)
}

func CancelDownload(itemID string) {
	cancelDownload(itemID)
}

func CleanupConnections() {
	CloseIdleConnections()
}

func ReadFileMetadata(filePath string) (string, error) {
	lower := strings.ToLower(filePath)
	isFlac := strings.HasSuffix(lower, ".flac")
	isM4A := strings.HasSuffix(lower, ".m4a") || strings.HasSuffix(lower, ".aac")
	isMp3 := strings.HasSuffix(lower, ".mp3")
	isOgg := strings.HasSuffix(lower, ".opus") || strings.HasSuffix(lower, ".ogg")
	isApe := strings.HasSuffix(lower, ".ape")
	isWv := strings.HasSuffix(lower, ".wv")
	isMpc := strings.HasSuffix(lower, ".mpc")

	result := map[string]interface{}{
		"title":        "",
		"artist":       "",
		"album":        "",
		"album_artist": "",
		"date":         "",
		"track_number": 0,
		"total_tracks": 0,
		"disc_number":  0,
		"total_discs":  0,
		"isrc":         "",
		"lyrics":       "",
		"genre":        "",
		"label":        "",
		"copyright":    "",
		"composer":     "",
		"comment":      "",
		"duration":     0,
	}

	if isFlac {
		metadata, err := ReadMetadata(filePath)
		if err != nil {
			// File may have wrong extension (e.g. opus saved as .flac).
			// Try Ogg/Opus parser as fallback before giving up.
			GoLog("[ReadFileMetadata] FLAC parse failed for %s, trying Ogg fallback: %v\n", filePath, err)
			oggMeta, oggErr := ReadOggVorbisComments(filePath)
			if oggErr == nil && oggMeta != nil {
				result["title"] = oggMeta.Title
				result["artist"] = oggMeta.Artist
				result["album"] = oggMeta.Album
				result["album_artist"] = oggMeta.AlbumArtist
				result["date"] = oggMeta.Date
				if oggMeta.Date == "" {
					result["date"] = oggMeta.Year
				}
				result["track_number"] = oggMeta.TrackNumber
				result["total_tracks"] = oggMeta.TotalTracks
				result["disc_number"] = oggMeta.DiscNumber
				result["total_discs"] = oggMeta.TotalDiscs
				result["isrc"] = oggMeta.ISRC
				result["lyrics"] = oggMeta.Lyrics
				result["genre"] = oggMeta.Genre
				result["composer"] = oggMeta.Composer
				result["comment"] = oggMeta.Comment
				quality, qualityErr := GetOggQuality(filePath)
				if qualityErr == nil {
					result["sample_rate"] = quality.SampleRate
					result["duration"] = quality.Duration
				}
			} else {
				return "", fmt.Errorf("failed to read metadata: %w", err)
			}
		} else {
			result["title"] = metadata.Title
			result["artist"] = metadata.Artist
			result["album"] = metadata.Album
			result["album_artist"] = metadata.AlbumArtist
			result["date"] = metadata.Date
			result["track_number"] = metadata.TrackNumber
			result["total_tracks"] = metadata.TotalTracks
			result["disc_number"] = metadata.DiscNumber
			result["total_discs"] = metadata.TotalDiscs
			result["isrc"] = metadata.ISRC
			result["lyrics"] = metadata.Lyrics
			result["genre"] = metadata.Genre
			result["label"] = metadata.Label
			result["copyright"] = metadata.Copyright
			result["composer"] = metadata.Composer
			result["comment"] = metadata.Comment
			result["replaygain_track_gain"] = metadata.ReplayGainTrackGain
			result["replaygain_track_peak"] = metadata.ReplayGainTrackPeak
			result["replaygain_album_gain"] = metadata.ReplayGainAlbumGain
			result["replaygain_album_peak"] = metadata.ReplayGainAlbumPeak

			quality, qualityErr := GetAudioQuality(filePath)
			if qualityErr == nil {
				result["bit_depth"] = quality.BitDepth
				result["sample_rate"] = quality.SampleRate
				if quality.SampleRate > 0 && quality.TotalSamples > 0 {
					result["duration"] = int(quality.TotalSamples / int64(quality.SampleRate))
				}
			}
		}
	} else if isM4A {
		meta, err := ReadM4ATags(filePath)
		if err == nil && meta != nil {
			result["title"] = meta.Title
			result["artist"] = meta.Artist
			result["album"] = meta.Album
			result["album_artist"] = meta.AlbumArtist
			result["date"] = meta.Date
			if meta.Date == "" {
				result["date"] = meta.Year
			}
			result["track_number"] = meta.TrackNumber
			result["total_tracks"] = meta.TotalTracks
			result["disc_number"] = meta.DiscNumber
			result["total_discs"] = meta.TotalDiscs
			result["isrc"] = meta.ISRC
			result["lyrics"] = meta.Lyrics
			result["genre"] = meta.Genre
			result["label"] = meta.Label
			result["copyright"] = meta.Copyright
			result["composer"] = meta.Composer
			result["comment"] = meta.Comment
			result["replaygain_track_gain"] = meta.ReplayGainTrackGain
			result["replaygain_track_peak"] = meta.ReplayGainTrackPeak
			result["replaygain_album_gain"] = meta.ReplayGainAlbumGain
			result["replaygain_album_peak"] = meta.ReplayGainAlbumPeak
		}
		quality, qualityErr := GetM4AQuality(filePath)
		if qualityErr == nil {
			result["bit_depth"] = quality.BitDepth
			result["sample_rate"] = quality.SampleRate
		}
	} else if isMp3 {
		meta, err := ReadID3Tags(filePath)
		if err == nil && meta != nil {
			result["title"] = meta.Title
			result["artist"] = meta.Artist
			result["album"] = meta.Album
			result["album_artist"] = meta.AlbumArtist
			result["date"] = meta.Date
			if meta.Date == "" {
				result["date"] = meta.Year
			}
			result["track_number"] = meta.TrackNumber
			result["total_tracks"] = meta.TotalTracks
			result["disc_number"] = meta.DiscNumber
			result["total_discs"] = meta.TotalDiscs
			result["isrc"] = meta.ISRC
			result["lyrics"] = meta.Lyrics
			result["genre"] = meta.Genre
			result["label"] = meta.Label
			result["copyright"] = meta.Copyright
			result["composer"] = meta.Composer
			result["comment"] = meta.Comment
			result["replaygain_track_gain"] = meta.ReplayGainTrackGain
			result["replaygain_track_peak"] = meta.ReplayGainTrackPeak
			result["replaygain_album_gain"] = meta.ReplayGainAlbumGain
			result["replaygain_album_peak"] = meta.ReplayGainAlbumPeak
		}
		quality, qualityErr := GetMP3Quality(filePath)
		if qualityErr == nil {
			result["bit_depth"] = quality.BitDepth
			result["sample_rate"] = quality.SampleRate
			result["duration"] = quality.Duration
		}
	} else if isOgg {
		meta, err := ReadOggVorbisComments(filePath)
		if err == nil && meta != nil {
			result["title"] = meta.Title
			result["artist"] = meta.Artist
			result["album"] = meta.Album
			result["album_artist"] = meta.AlbumArtist
			result["date"] = meta.Date
			if meta.Date == "" {
				result["date"] = meta.Year
			}
			result["track_number"] = meta.TrackNumber
			result["total_tracks"] = meta.TotalTracks
			result["disc_number"] = meta.DiscNumber
			result["total_discs"] = meta.TotalDiscs
			result["isrc"] = meta.ISRC
			result["lyrics"] = meta.Lyrics
			result["genre"] = meta.Genre
			result["label"] = meta.Label
			result["copyright"] = meta.Copyright
			result["composer"] = meta.Composer
			result["comment"] = meta.Comment
			result["replaygain_track_gain"] = meta.ReplayGainTrackGain
			result["replaygain_track_peak"] = meta.ReplayGainTrackPeak
			result["replaygain_album_gain"] = meta.ReplayGainAlbumGain
			result["replaygain_album_peak"] = meta.ReplayGainAlbumPeak
		}
		quality, qualityErr := GetOggQuality(filePath)
		if qualityErr == nil {
			result["sample_rate"] = quality.SampleRate
			result["duration"] = quality.Duration
		}
	} else if isApe || isWv || isMpc {
		// APE, WavPack, Musepack: read APEv2 tags
		apeTag, apeErr := ReadAPETags(filePath)
		if apeErr == nil && apeTag != nil {
			meta := APETagToAudioMetadata(apeTag)
			if meta != nil {
				result["title"] = meta.Title
				result["artist"] = meta.Artist
				result["album"] = meta.Album
				result["album_artist"] = meta.AlbumArtist
				result["date"] = meta.Date
				if meta.Date == "" {
					result["date"] = meta.Year
				}
				result["track_number"] = meta.TrackNumber
				result["total_tracks"] = meta.TotalTracks
				result["disc_number"] = meta.DiscNumber
				result["total_discs"] = meta.TotalDiscs
				result["isrc"] = meta.ISRC
				result["lyrics"] = meta.Lyrics
				result["genre"] = meta.Genre
				result["label"] = meta.Label
				result["copyright"] = meta.Copyright
				result["composer"] = meta.Composer
				result["comment"] = meta.Comment
				result["replaygain_track_gain"] = meta.ReplayGainTrackGain
				result["replaygain_track_peak"] = meta.ReplayGainTrackPeak
				result["replaygain_album_gain"] = meta.ReplayGainAlbumGain
				result["replaygain_album_peak"] = meta.ReplayGainAlbumPeak
			}
		}
	} else {
		return "", fmt.Errorf("unsupported file format: %s", filePath)
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

// ParseCueSheet is called from Dart to get track listing and timing data for CUE splitting.
// audioDir, if non-empty, overrides the directory used for resolving the
// referenced audio file (useful for SAF temp file scenarios).
func ParseCueSheet(cuePath string, audioDir string) (string, error) {
	return ParseCueFileJSON(cuePath, audioDir)
}

// ScanCueSheetForLibrary parses a .cue file and returns a JSON array of
// LibraryScanResult entries (one per track). This is the SAF-friendly variant:
//   - audioDir overrides where the referenced audio file is resolved
//   - virtualPathPrefix replaces cuePath in filePath / id fields (e.g. a content:// URI)
//   - fileModTime is stamped on every result (pass 0 to stat cuePath instead)
func ScanCueSheetForLibrary(cuePath, audioDir, virtualPathPrefix string, fileModTime int64) (string, error) {
	scanTime := time.Now().UTC().Format(time.RFC3339)
	results, err := ScanCueFileForLibraryExt(cuePath, audioDir, virtualPathPrefix, fileModTime, scanTime)
	if err != nil {
		return "[]", err
	}
	jsonBytes, err := json.Marshal(results)
	if err != nil {
		return "[]", fmt.Errorf("failed to marshal cue scan results: %w", err)
	}
	return string(jsonBytes), nil
}

func ScanCueSheetForLibraryWithCoverCacheKey(cuePath, audioDir, virtualPathPrefix string, fileModTime int64, coverCacheKey string) (string, error) {
	scanTime := time.Now().UTC().Format(time.RFC3339)
	results, err := ScanCueFileForLibraryExtWithCoverCacheKey(
		cuePath,
		audioDir,
		virtualPathPrefix,
		fileModTime,
		coverCacheKey,
		scanTime,
	)
	if err != nil {
		return "[]", err
	}
	jsonBytes, err := json.Marshal(results)
	if err != nil {
		return "[]", fmt.Errorf("failed to marshal cue scan results: %w", err)
	}
	return string(jsonBytes), nil
}

// EditFileMetadata writes audio file tags: FLAC via native Go library, MP3/Opus returns map for Dart/FFmpeg.
func EditFileMetadata(filePath, metadataJSON string) (string, error) {
	var fields map[string]string
	if err := json.Unmarshal([]byte(metadataJSON), &fields); err != nil {
		return "", fmt.Errorf("invalid metadata JSON: %w", err)
	}

	lower := strings.ToLower(filePath)
	isFlac := strings.HasSuffix(lower, ".flac")
	isApeFile := strings.HasSuffix(lower, ".ape") || strings.HasSuffix(lower, ".wv") || strings.HasSuffix(lower, ".mpc")
	coverPath := strings.TrimSpace(fields["cover_path"])

	if isFlac {
		if err := EditFlacFields(filePath, fields); err != nil {
			return "", fmt.Errorf("failed to write FLAC metadata: %w", err)
		}

		resp := map[string]any{
			"success": true,
			"method":  "native",
		}
		jsonBytes, _ := json.Marshal(resp)
		return string(jsonBytes), nil
	}

	// APE/WV/MPC: write APEv2 tags natively
	if isApeFile {
		trackNum := 0
		totalTracks := 0
		discNum := 0
		totalDiscs := 0
		if v, ok := fields["track_number"]; ok && v != "" {
			fmt.Sscanf(v, "%d", &trackNum)
		}
		if v, ok := fields["track_total"]; ok && v != "" {
			fmt.Sscanf(v, "%d", &totalTracks)
		}
		if v, ok := fields["disc_number"]; ok && v != "" {
			fmt.Sscanf(v, "%d", &discNum)
		}
		if v, ok := fields["disc_total"]; ok && v != "" {
			fmt.Sscanf(v, "%d", &totalDiscs)
		}

		meta := &AudioMetadata{
			Title:               fields["title"],
			Artist:              fields["artist"],
			Album:               fields["album"],
			AlbumArtist:         fields["album_artist"],
			Date:                fields["date"],
			TrackNumber:         trackNum,
			TotalTracks:         totalTracks,
			DiscNumber:          discNum,
			TotalDiscs:          totalDiscs,
			ISRC:                fields["isrc"],
			Lyrics:              fields["lyrics"],
			Genre:               fields["genre"],
			Label:               fields["label"],
			Copyright:           fields["copyright"],
			Composer:            fields["composer"],
			Comment:             fields["comment"],
			ReplayGainTrackGain: fields["replaygain_track_gain"],
			ReplayGainTrackPeak: fields["replaygain_track_peak"],
			ReplayGainAlbumGain: fields["replaygain_album_gain"],
			ReplayGainAlbumPeak: fields["replaygain_album_peak"],
		}

		newItems := AudioMetadataToAPEItems(meta)

		// If a cover image was provided, embed it as a binary APE item.
		// APEv2 cover format: "cover.jpg\0<binary image data>", flagged binary.
		if coverPath != "" {
			coverData, coverErr := os.ReadFile(coverPath)
			if coverErr == nil && len(coverData) > 0 {
				// The value is "filename\0" + raw bytes.  We store the
				// description as the Value field, but since the item is
				// flagged binary, the writer serializes it verbatim.
				desc := "cover.jpg\x00"
				binaryValue := desc + string(coverData)
				newItems = append(newItems, APETagItem{
					Key:   "Cover Art (Front)",
					Value: binaryValue,
					Flags: apeItemFlagBinary,
				})
			}
		}

		// Build the set of APE keys that the edit explicitly controls.
		// Even if the value is empty (user cleared the field), the old
		// value must be removed during merge.
		overrideKeys := apeKeysFromFields(fields)
		if coverPath != "" {
			overrideKeys["COVER ART (FRONT)"] = struct{}{}
		}

		// Read existing tags so we can merge rather than replace.
		// This preserves cover art and custom items not in the edit set.
		existingTag, _ := ReadAPETags(filePath)
		var finalItems []APETagItem
		if existingTag != nil && len(existingTag.Items) > 0 {
			finalItems = MergeAPEItems(existingTag.Items, newItems, overrideKeys)
		} else {
			finalItems = newItems
		}

		tag := &APETag{
			Version: apeTagVersion2,
			Items:   finalItems,
		}

		if err := WriteAPETags(filePath, tag); err != nil {
			return "", fmt.Errorf("failed to write APE tags: %w", err)
		}

		resp := map[string]any{
			"success": true,
			"method":  "native_ape",
		}
		jsonBytes, _ := json.Marshal(resp)
		return string(jsonBytes), nil
	}

	resp := map[string]any{
		"success": true,
		"method":  "ffmpeg",
		"fields":  fields,
	}
	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

func SetDownloadDirectory(path string) error {
	return setDownloadDir(path)
}

func AllowDownloadDir(path string) {
	if strings.TrimSpace(path) == "" {
		return
	}
	AddAllowedDownloadDir(path)
}

func CheckDuplicate(outputDir, isrc string) (string, error) {
	existingFile, exists := CheckISRCExists(outputDir, isrc)

	result := map[string]interface{}{
		"exists":   exists,
		"filepath": existingFile,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func CheckDuplicatesBatch(outputDir, tracksJSON string) (string, error) {
	return CheckFilesExistParallel(outputDir, tracksJSON)
}

func PreBuildDuplicateIndex(outputDir string) error {
	return PreBuildISRCIndex(outputDir)
}

func InvalidateDuplicateIndex(outputDir string) {
	InvalidateISRCCache(outputDir)
}

func BuildFilename(template string, metadataJSON string) (string, error) {
	var metadata map[string]interface{}
	if err := json.Unmarshal([]byte(metadataJSON), &metadata); err != nil {
		return "", err
	}

	filename := buildFilenameFromTemplate(template, metadata)
	return filename, nil
}

func SanitizeFilename(filename string) string {
	return sanitizeFilename(filename)
}

func FetchLyrics(spotifyID, trackName, artistName string, durationMs int64) (string, error) {
	client := NewLyricsClient()
	durationSec := float64(durationMs) / 1000.0
	lyrics, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName, durationSec)
	if err != nil {
		return "", err
	}

	result := map[string]interface{}{
		"success":      true,
		"source":       lyrics.Source,
		"sync_type":    lyrics.SyncType,
		"lines":        lyrics.Lines,
		"instrumental": lyrics.Instrumental,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetLyricsLRC(spotifyID, trackName, artistName string, filePath string, durationMs int64) (string, error) {
	if filePath != "" {
		lyrics, err := ExtractLyrics(filePath)
		if err == nil && lyrics != "" {
			return lyrics, nil
		}
		return "", nil
	}

	client := NewLyricsClient()
	durationSec := float64(durationMs) / 1000.0
	lyricsData, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName, durationSec)
	if err != nil {
		return "", err
	}

	if lyricsData.Instrumental {
		return "[instrumental:true]", nil
	}

	lrcContent := convertToLRCWithMetadata(lyricsData, trackName, artistName)
	return lrcContent, nil
}

func GetLyricsLRCWithSource(spotifyID, trackName, artistName string, filePath string, durationMs int64) (string, error) {
	if filePath != "" {
		lyrics, err := ExtractLyrics(filePath)
		if err == nil && lyrics != "" {
			result := map[string]interface{}{
				"lyrics":       lyrics,
				"source":       "Embedded",
				"sync_type":    "EMBEDDED",
				"instrumental": false,
			}
			jsonBytes, err := json.Marshal(result)
			if err != nil {
				return "", err
			}
			return string(jsonBytes), nil
		}

		result := map[string]interface{}{
			"lyrics":       "",
			"source":       "",
			"sync_type":    "",
			"instrumental": false,
		}
		jsonBytes, err := json.Marshal(result)
		if err != nil {
			return "", err
		}
		return string(jsonBytes), nil
	}

	client := NewLyricsClient()
	durationSec := float64(durationMs) / 1000.0
	lyricsData, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName, durationSec)
	if err != nil {
		return "", err
	}

	lrcContent := ""
	if lyricsData.Instrumental {
		lrcContent = "[instrumental:true]"
	} else {
		lrcContent = convertToLRCWithMetadata(lyricsData, trackName, artistName)
	}

	result := map[string]interface{}{
		"lyrics":       lrcContent,
		"source":       lyricsData.Source,
		"sync_type":    lyricsData.SyncType,
		"instrumental": lyricsData.Instrumental,
	}
	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func EmbedLyricsToFile(filePath, lyrics string) (string, error) {
	err := EmbedLyrics(filePath, lyrics)
	if err != nil {
		return errorResponse("Failed to embed lyrics: " + err.Error())
	}

	resp := map[string]interface{}{
		"success": true,
		"message": "Lyrics embedded successfully",
	}

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

// RewriteSplitArtistTagsExport rewrites ARTIST and ALBUMARTIST Vorbis
// comments in a FLAC file as multiple separate entries (one per artist).
// Call this after FFmpeg metadata embedding to fix split artist tags,
// since FFmpeg deduplicates -metadata keys and only keeps the last value.
func RewriteSplitArtistTagsExport(filePath, artist, albumArtist string) (string, error) {
	err := RewriteSplitArtistTags(filePath, artist, albumArtist)
	if err != nil {
		return errorResponse("Failed to rewrite artist tags: " + err.Error())
	}

	resp := map[string]interface{}{
		"success": true,
		"message": "Split artist tags written successfully",
	}

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

func PreWarmTrackCacheJSON(tracksJSON string) (string, error) {
	var tracks []struct {
		ISRC       string `json:"isrc"`
		TrackName  string `json:"track_name"`
		ArtistName string `json:"artist_name"`
		SpotifyID  string `json:"spotify_id"`
		Service    string `json:"service"`
	}

	if err := json.Unmarshal([]byte(tracksJSON), &tracks); err != nil {
		return errorResponse("Invalid JSON: " + err.Error())
	}

	requests := make([]PreWarmCacheRequest, len(tracks))
	for i, t := range tracks {
		requests[i] = PreWarmCacheRequest{
			ISRC:       t.ISRC,
			TrackName:  t.TrackName,
			ArtistName: t.ArtistName,
			SpotifyID:  t.SpotifyID,
			Service:    t.Service,
		}
	}

	go PreWarmTrackCache(requests)

	resp := map[string]interface{}{
		"success": true,
		"message": fmt.Sprintf("Pre-warming cache for %d tracks in background", len(tracks)),
	}

	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

func GetTrackCacheSize() int {
	return GetCacheSize()
}

func ClearTrackIDCache() {
	ClearTrackCache()
}

func SearchDeezerAll(query string, trackLimit, artistLimit int, filter string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client := GetDeezerClient()
	results, err := client.SearchAll(ctx, query, trackLimit, artistLimit, filter)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(results)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func SearchTidalAll(query string, trackLimit, artistLimit int, filter string) (string, error) {
	downloader := NewTidalDownloader()
	results, err := downloader.SearchAll(query, trackLimit, artistLimit, filter)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(results)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func SearchQobuzAll(query string, trackLimit, artistLimit int, filter string) (string, error) {
	downloader := NewQobuzDownloader()
	results, err := downloader.SearchAll(query, trackLimit, artistLimit, filter)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(results)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetDeezerRelatedArtists(artistID string, limit int) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	client := GetDeezerClient()
	artists, err := client.GetRelatedArtists(ctx, artistID, limit)
	if err != nil {
		return "", err
	}

	resp := map[string]interface{}{
		"artists": artists,
	}
	jsonBytes, err := json.Marshal(resp)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

func GetDeezerMetadata(resourceType, resourceID string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client := GetDeezerClient()
	var data interface{}
	var err error

	switch resourceType {
	case "track":
		data, err = client.GetTrack(ctx, resourceID)
	case "album":
		data, err = client.GetAlbum(ctx, resourceID)
	case "artist":
		data, err = client.GetArtist(ctx, resourceID)
	case "playlist":
		data, err = client.GetPlaylist(ctx, resourceID)
	default:
		return "", fmt.Errorf("unsupported Deezer resource type: %s", resourceType)
	}

	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(data)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetQobuzMetadata(resourceType, resourceID string) (string, error) {
	downloader := NewQobuzDownloader()

	var data interface{}
	var err error

	switch resourceType {
	case "track":
		data, err = downloader.GetTrackMetadata(resourceID)
	case "album":
		data, err = downloader.GetAlbumMetadata(resourceID)
	case "artist":
		data, err = downloader.GetArtistMetadata(resourceID)
	case "playlist":
		data, err = downloader.GetPlaylistMetadata(resourceID)
	default:
		return "", fmt.Errorf("unsupported Qobuz resource type: %s", resourceType)
	}
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(data)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetTidalMetadata(resourceType, resourceID string) (string, error) {
	downloader := NewTidalDownloader()

	var data interface{}
	var err error

	switch resourceType {
	case "track":
		data, err = downloader.GetTrackMetadata(resourceID)
	case "album":
		data, err = downloader.GetAlbumMetadata(resourceID)
	case "artist":
		data, err = downloader.GetArtistMetadata(resourceID)
	case "playlist":
		data, err = downloader.GetPlaylistMetadata(resourceID)
	default:
		return "", fmt.Errorf("unsupported Tidal resource type: %s", resourceType)
	}
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(data)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func ParseDeezerURLExport(url string) (string, error) {
	resourceType, resourceID, err := parseDeezerURL(url)
	if err != nil {
		return "", err
	}

	result := map[string]string{
		"type": resourceType,
		"id":   resourceID,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func ParseQobuzURLExport(url string) (string, error) {
	resourceType, resourceID, err := parseQobuzURL(url)
	if err != nil {
		return "", err
	}

	result := map[string]string{
		"type": resourceType,
		"id":   resourceID,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func ParseTidalURLExport(url string) (string, error) {
	resourceType, resourceID, err := parseTidalURL(url)
	if err != nil {
		return "", err
	}

	result := map[string]string{
		"type": resourceType,
		"id":   resourceID,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func ConvertTidalToSpotifyDeezer(tidalURL string) (string, error) {
	client := NewSongLinkClient()
	availability, err := client.CheckAvailabilityFromURL(tidalURL)
	if err != nil {
		return "", err
	}

	result := map[string]string{
		"spotify_id":  availability.SpotifyID,
		"deezer_id":   availability.DeezerID,
		"deezer_url":  availability.DeezerURL,
		"spotify_url": "",
	}

	if availability.SpotifyID != "" {
		result["spotify_url"] = "https://open.spotify.com/track/" + availability.SpotifyID
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetDeezerExtendedMetadata(trackID string) (string, error) {
	if trackID == "" {
		return "", fmt.Errorf("empty track ID")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client := GetDeezerClient()
	metadata, err := client.GetExtendedMetadataByTrackID(ctx, trackID)
	if err != nil {
		GoLog("[Deezer] Failed to get extended metadata: %v\n", err)
		return "", err
	}

	result := buildDeezerExtendedMetadataResult(metadata)

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func SearchDeezerByISRC(isrc string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client := GetDeezerClient()
	track, err := client.SearchByISRC(ctx, isrc)
	if err != nil {
		return "", err
	}

	result := buildDeezerISRCSearchResult(track)
	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func buildDeezerExtendedMetadataResult(metadata *AlbumExtendedMetadata) map[string]string {
	if metadata == nil {
		return map[string]string{
			"genre":     "",
			"label":     "",
			"copyright": "",
		}
	}

	return map[string]string{
		"genre":     metadata.Genre,
		"label":     metadata.Label,
		"copyright": metadata.Copyright,
	}
}

func buildDeezerISRCSearchResult(track *TrackMetadata) map[string]interface{} {
	if track == nil {
		return map[string]interface{}{}
	}

	result := map[string]interface{}{
		"spotify_id":    track.SpotifyID,
		"artists":       track.Artists,
		"name":          track.Name,
		"album_name":    track.AlbumName,
		"album_artist":  track.AlbumArtist,
		"duration_ms":   track.DurationMS,
		"images":        track.Images,
		"release_date":  track.ReleaseDate,
		"track_number":  track.TrackNumber,
		"total_tracks":  track.TotalTracks,
		"disc_number":   track.DiscNumber,
		"total_discs":   track.TotalDiscs,
		"external_urls": track.ExternalURL,
		"isrc":          track.ISRC,
		"album_id":      track.AlbumID,
		"artist_id":     track.ArtistID,
		"album_type":    track.AlbumType,
		"composer":      track.Composer,
	}

	if deezerID := strings.TrimSpace(strings.TrimPrefix(track.SpotifyID, "deezer:")); deezerID != "" {
		result["id"] = deezerID
		result["track_id"] = deezerID
		result["success"] = true
	}

	return result
}

func ConvertSpotifyToDeezer(resourceType, spotifyID string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	songlink := NewSongLinkClient()
	deezerClient := GetDeezerClient()

	if resourceType == "track" {
		deezerID, err := songlink.GetDeezerIDFromSpotify(spotifyID)
		if err != nil {
			return "", fmt.Errorf("could not find Deezer equivalent: %w", err)
		}

		trackResp, err := deezerClient.GetTrack(ctx, deezerID)
		if err != nil {
			return "", fmt.Errorf("failed to fetch Deezer metadata: %w", err)
		}

		jsonBytes, err := json.Marshal(trackResp)
		if err != nil {
			return "", err
		}

		return string(jsonBytes), nil
	}

	if resourceType == "album" {
		deezerID, err := songlink.GetDeezerAlbumIDFromSpotify(spotifyID)
		if err != nil {
			return "", fmt.Errorf("could not find Deezer album: %w", err)
		}

		albumResp, err := deezerClient.GetAlbum(ctx, deezerID)
		if err != nil {
			return "", fmt.Errorf("failed to fetch Deezer album metadata: %w", err)
		}

		jsonBytes, err := json.Marshal(albumResp)
		if err != nil {
			return "", err
		}

		return string(jsonBytes), nil
	}

	return "", fmt.Errorf("Spotify to Deezer conversion only supported for tracks and albums. Please search by name for %s", resourceType)
}

func CheckAvailabilityFromDeezerID(deezerTrackID string) (string, error) {
	client := NewSongLinkClient()
	availability, err := client.CheckAvailabilityFromDeezer(deezerTrackID)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(availability)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func CheckAvailabilityByPlatformID(platform, entityType, entityID string) (string, error) {
	client := NewSongLinkClient()
	availability, err := client.CheckAvailabilityByPlatform(platform, entityType, entityID)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(availability)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetSpotifyIDFromDeezerTrack(deezerTrackID string) (string, error) {
	client := NewSongLinkClient()
	return client.GetSpotifyIDFromDeezer(deezerTrackID)
}

func GetTidalURLFromDeezerTrack(deezerTrackID string) (string, error) {
	client := NewSongLinkClient()
	return client.GetTidalURLFromDeezer(deezerTrackID)
}

func errorResponse(msg string) (string, error) {
	errorType := "unknown"
	lowerMsg := strings.ToLower(msg)

	if strings.Contains(lowerMsg, "isp blocking") ||
		strings.Contains(lowerMsg, "try using vpn") ||
		strings.Contains(lowerMsg, "change dns") {
		errorType = "isp_blocked"
	} else if strings.Contains(lowerMsg, "cancel") {
		errorType = "cancelled"
	} else if strings.Contains(lowerMsg, "permission") ||
		strings.Contains(lowerMsg, "operation not permitted") ||
		strings.Contains(lowerMsg, "access denied") ||
		strings.Contains(lowerMsg, "failed to create file") ||
		strings.Contains(lowerMsg, "failed to create directory") {
		errorType = "permission"
	} else if strings.Contains(lowerMsg, "not found") ||
		strings.Contains(lowerMsg, "not available") ||
		strings.Contains(lowerMsg, "no results") ||
		strings.Contains(lowerMsg, "track not found") ||
		strings.Contains(lowerMsg, "all services failed") {
		errorType = "not_found"
	} else if strings.Contains(lowerMsg, "rate limit") ||
		strings.Contains(lowerMsg, "429") ||
		strings.Contains(lowerMsg, "too many requests") {
		errorType = "rate_limit"
	} else if strings.Contains(lowerMsg, "network") ||
		strings.Contains(lowerMsg, "connection") ||
		strings.Contains(lowerMsg, "timeout") ||
		strings.Contains(lowerMsg, "dial") {
		errorType = "network"
	}

	resp := DownloadResponse{
		Success:   false,
		Error:     msg,
		ErrorType: errorType,
	}
	jsonBytes, _ := json.Marshal(resp)
	return string(jsonBytes), nil
}

func DownloadCoverToFile(coverURL string, outputPath string, maxQuality bool) error {
	if coverURL == "" {
		return fmt.Errorf("no cover URL provided")
	}

	data, err := downloadCoverToMemory(coverURL, maxQuality)
	if err != nil {
		return fmt.Errorf("failed to download cover: %w", err)
	}

	if err := os.WriteFile(outputPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write cover file: %w", err)
	}

	GoLog("[Cover] Downloaded cover to: %s (%d KB)\n", outputPath, len(data)/1024)
	return nil
}

func ExtractCoverToFile(audioPath string, outputPath string) error {
	lower := strings.ToLower(audioPath)

	var coverData []byte
	var err error

	if strings.HasSuffix(lower, ".flac") {
		coverData, err = ExtractCoverArt(audioPath)
	} else if strings.HasSuffix(lower, ".m4a") || strings.HasSuffix(lower, ".aac") {
		coverData, err = extractCoverFromM4A(audioPath)
	} else if strings.HasSuffix(lower, ".mp3") {
		coverData, _, err = extractMP3CoverArt(audioPath)
	} else if strings.HasSuffix(lower, ".opus") || strings.HasSuffix(lower, ".ogg") {
		coverData, _, err = extractOggCoverArt(audioPath)
	} else {
		return fmt.Errorf("unsupported audio format for cover extraction")
	}

	if err != nil {
		return fmt.Errorf("failed to extract cover: %w", err)
	}

	if err := os.WriteFile(outputPath, coverData, 0644); err != nil {
		return fmt.Errorf("failed to write cover file: %w", err)
	}

	GoLog("[Cover] Extracted cover art to: %s (%d KB)\n", outputPath, len(coverData)/1024)
	return nil
}

func FetchAndSaveLyrics(trackName, artistName, spotifyID string, durationMs int64, outputPath string, audioFilePath string) error {
	// If the audio file already has embedded lyrics or a sidecar .lrc,
	// use those directly instead of making redundant network requests.
	if audioFilePath != "" {
		existing, err := ExtractLyrics(audioFilePath)
		if err == nil && strings.TrimSpace(existing) != "" {
			if err := os.WriteFile(outputPath, []byte(existing), 0644); err != nil {
				return fmt.Errorf("failed to write LRC file: %w", err)
			}
			GoLog("[Lyrics] Saved LRC from embedded/sidecar to: %s\n", outputPath)
			return nil
		}
	}

	client := NewLyricsClient()
	durationSec := float64(durationMs) / 1000.0

	lyrics, err := client.FetchLyricsAllSources(spotifyID, trackName, artistName, durationSec)
	if err != nil {
		return fmt.Errorf("lyrics not found: %w", err)
	}

	if lyrics.Instrumental {
		return fmt.Errorf("track is instrumental, no lyrics available")
	}

	lrcContent := convertToLRCWithMetadata(lyrics, trackName, artistName)
	if lrcContent == "" {
		return fmt.Errorf("failed to generate LRC content")
	}

	if err := os.WriteFile(outputPath, []byte(lrcContent), 0644); err != nil {
		return fmt.Errorf("failed to write LRC file: %w", err)
	}

	GoLog("[Lyrics] Saved LRC to: %s (%d lines)\n", outputPath, len(lyrics.Lines))
	return nil
}

func SetLyricsProvidersJSON(providersJSON string) error {
	var providers []string
	if err := json.Unmarshal([]byte(providersJSON), &providers); err != nil {
		return err
	}

	SetLyricsProviderOrder(providers)
	return nil
}

func GetLyricsProvidersJSON() (string, error) {
	providers := GetLyricsProviderOrder()
	jsonBytes, err := json.Marshal(providers)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

func GetAvailableLyricsProvidersJSON() (string, error) {
	providers := GetAvailableLyricsProviders()
	jsonBytes, err := json.Marshal(providers)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

func SetLyricsFetchOptionsJSON(optionsJSON string) error {
	opts := GetLyricsFetchOptions()
	if strings.TrimSpace(optionsJSON) != "" {
		if err := json.Unmarshal([]byte(optionsJSON), &opts); err != nil {
			return err
		}
	}

	SetLyricsFetchOptions(opts)
	return nil
}

func GetLyricsFetchOptionsJSON() (string, error) {
	opts := GetLyricsFetchOptions()
	jsonBytes, err := json.Marshal(opts)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

// ReEnrichFile re-embeds metadata, cover art, and lyrics into an existing audio file.
// When search_online is true, searches Spotify/Deezer by track name + artist to fetch
// complete metadata from the internet before embedding.
func ReEnrichFile(requestJSON string) (string, error) {
	var req reEnrichRequest

	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return "", fmt.Errorf("failed to parse request: %w", err)
	}

	if req.FilePath == "" {
		return "", fmt.Errorf("file_path is required")
	}

	GoLog("[ReEnrich] Starting re-enrichment for: %s\n", req.FilePath)

	// When search_online is true, search for metadata from internet using the
	// configured metadata-provider priority.
	if req.SearchOnline {
		found := false

		GoLog("[ReEnrich] Trying metadata providers in configured priority...\n")
		manager := getExtensionManager()
		if identifierTrack, err := resolveReEnrichTrackFromIdentifiers(req); err == nil && identifierTrack != nil {
			GoLog("[ReEnrich] Identifier-first metadata match (%s): %s - %s (album: %s, date: %s)\n",
				identifierTrack.ProviderID, identifierTrack.Name, identifierTrack.Artists, identifierTrack.AlbumName, identifierTrack.ReleaseDate)
			applyReEnrichTrackMetadata(&req, *identifierTrack)
			found = true
		}

		searchQuery := buildReEnrichSearchQuery(req)
		if searchQuery != "" {
			GoLog("[ReEnrich] Searching online metadata for query: %s\n", searchQuery)
			tracks, searchErr := manager.SearchTracksWithMetadataProviders(searchQuery, 5, true)
			if searchErr == nil && len(tracks) > 0 {
				track := selectBestReEnrichTrack(req, tracks)
				if track != nil {
					GoLog("[ReEnrich] Metadata match (%s): %s - %s (album: %s, date: %s)\n",
						track.ProviderID, track.Name, track.Artists, track.AlbumName, track.ReleaseDate)
					applyReEnrichTrackMetadata(&req, *track)
					found = true
				}
			} else if searchErr != nil {
				GoLog("[ReEnrich] Metadata provider search failed: %v\n", searchErr)
			}
		} else {
			GoLog("[ReEnrich] Skipping provider search: no usable title/artist/album query\n")
		}

		// Try to enrich extra metadata from ISRC if not already set.
		if found && req.ISRC != "" && req.shouldUpdateField("extra") && (req.Genre == "" || req.Label == "" || req.Copyright == "") {
			enrichExtraMetadataByISRC("ReEnrich", req.ISRC, &req.Genre, &req.Label, &req.Copyright)
		}

		if !found {
			GoLog("[ReEnrich] No online match found, using existing metadata\n")
		}
	}

	GoLog("[ReEnrich] Metadata to embed: title=%s, artist=%s, album=%s, albumArtist=%s\n",
		req.TrackName, req.ArtistName, req.AlbumName, req.AlbumArtist)
	GoLog("[ReEnrich] track=%d, disc=%d, date=%s, isrc=%s, genre=%s, label=%s\n",
		req.TrackNumber, req.DiscNumber, req.ReleaseDate, req.ISRC, req.Genre, req.Label)

	lower := strings.ToLower(req.FilePath)
	isFlac := strings.HasSuffix(lower, ".flac")

	// Download cover art to temp file
	var coverTempPath string
	var coverDataBytes []byte
	if req.CoverURL != "" && req.shouldUpdateField("cover") {
		coverData, err := downloadCoverToMemory(req.CoverURL, req.MaxQuality)
		if err != nil {
			GoLog("[ReEnrich] Failed to download cover: %v\n", err)
		} else {
			coverDataBytes = coverData
			GoLog("[ReEnrich] Cover downloaded: %d KB\n", len(coverData)/1024)
			// MP3/Opus requires a real image file path for Dart FFmpeg.
			// FLAC uses in-memory embed and does not require temp files.
			if !isFlac {
				tmpFile, err := os.CreateTemp("", "reenrich_cover_*.jpg")
				if err != nil {
					fallbackDir := filepath.Dir(req.FilePath)
					if fallbackDir == "" || fallbackDir == "." {
						GoLog("[ReEnrich] Failed to create cover temp file: %v\n", err)
					} else {
						tmpFile, err = os.CreateTemp(fallbackDir, "reenrich_cover_*.jpg")
						if err != nil {
							GoLog("[ReEnrich] Failed to create cover temp file (fallback dir %s): %v\n", fallbackDir, err)
						}
					}
				}
				if err == nil && tmpFile != nil {
					coverTempPath = tmpFile.Name()
					if _, writeErr := tmpFile.Write(coverData); writeErr != nil {
						GoLog("[ReEnrich] Failed writing cover temp file: %v\n", writeErr)
						tmpFile.Close()
						os.Remove(coverTempPath)
						coverTempPath = ""
					} else if closeErr := tmpFile.Close(); closeErr != nil {
						GoLog("[ReEnrich] Failed closing cover temp file: %v\n", closeErr)
						os.Remove(coverTempPath)
						coverTempPath = ""
					}
				}
			}
		}
	}
	// Only cleanup cover temp for FLAC (native embed).
	// For MP3/Opus, Dart needs the file for FFmpeg — Dart handles cleanup.
	cleanupCover := true

	defer func() {
		if cleanupCover && coverTempPath != "" {
			os.Remove(coverTempPath)
		}
	}()

	// Preserve existing lyrics when online enrichment does not return a replacement.
	var lyricsLRC string
	if req.shouldUpdateField("lyrics") {
		existingLyrics, existingLyricsErr := ExtractLyrics(req.FilePath)
		if existingLyricsErr == nil && strings.TrimSpace(existingLyrics) != "" {
			lyricsLRC = existingLyrics
			GoLog("[ReEnrich] Preserving existing embedded/sidecar lyrics\n")
		}
	}

	// Fetch lyrics
	if req.EmbedLyrics && req.shouldUpdateField("lyrics") {
		client := NewLyricsClient()
		durationSec := float64(req.DurationMs) / 1000.0
		lyrics, err := client.FetchLyricsAllSources(req.SpotifyID, req.TrackName, req.ArtistName, durationSec)
		if err != nil {
			GoLog("[ReEnrich] Lyrics not found: %v\n", err)
		} else if !lyrics.Instrumental {
			lyricsLRC = convertToLRCWithMetadata(lyrics, req.TrackName, req.ArtistName)
			GoLog("[ReEnrich] Lyrics fetched: %d lines\n", len(lyrics.Lines))
		} else {
			GoLog("[ReEnrich] Track is instrumental\n")
		}
	}

	// Build enrichedMeta map: only include fields from selected update groups
	// so that the caller (Dart) does not overwrite non-selected metadata in its
	// local library database with potentially stale cached values.
	enrichedMeta := map[string]interface{}{
		"spotify_id":  req.SpotifyID,
		"duration_ms": req.DurationMs,
	}
	if req.shouldUpdateField("basic_tags") {
		enrichedMeta["track_name"] = req.TrackName
		enrichedMeta["artist_name"] = req.ArtistName
		enrichedMeta["album_name"] = req.AlbumName
		enrichedMeta["album_artist"] = req.AlbumArtist
	}
	if req.shouldUpdateField("track_info") {
		enrichedMeta["track_number"] = req.TrackNumber
		enrichedMeta["total_tracks"] = req.TotalTracks
		enrichedMeta["disc_number"] = req.DiscNumber
		enrichedMeta["total_discs"] = req.TotalDiscs
	}
	if req.shouldUpdateField("release_info") {
		enrichedMeta["release_date"] = req.ReleaseDate
		enrichedMeta["isrc"] = req.ISRC
	}
	if req.shouldUpdateField("cover") {
		enrichedMeta["cover_url"] = req.CoverURL
	}
	if req.shouldUpdateField("extra") {
		enrichedMeta["genre"] = req.Genre
		enrichedMeta["label"] = req.Label
		enrichedMeta["copyright"] = req.Copyright
		enrichedMeta["composer"] = req.Composer
	}

	if isFlac {
		// Native Go FLAC metadata embedding.
		// Only populate Metadata fields for selected update groups; empty/zero
		// values cause EmbedMetadata's setComment() to skip those tags,
		// preserving whatever is already in the file.
		metadata := Metadata{
			ArtistTagMode: req.ArtistTagMode,
		}
		if req.shouldUpdateField("basic_tags") {
			metadata.Title = req.TrackName
			metadata.Artist = req.ArtistName
			metadata.Album = req.AlbumName
			metadata.AlbumArtist = req.AlbumArtist
		}
		if req.shouldUpdateField("track_info") {
			metadata.TrackNumber = req.TrackNumber
			metadata.TotalTracks = req.TotalTracks
			metadata.DiscNumber = req.DiscNumber
			metadata.TotalDiscs = req.TotalDiscs
		}
		if req.shouldUpdateField("release_info") {
			metadata.Date = req.ReleaseDate
			metadata.ISRC = req.ISRC
		}
		if req.shouldUpdateField("lyrics") {
			metadata.Lyrics = lyricsLRC
		}
		if req.shouldUpdateField("extra") {
			metadata.Genre = req.Genre
			metadata.Label = req.Label
			metadata.Copyright = req.Copyright
			metadata.Composer = req.Composer
		}

		if len(coverDataBytes) > 0 {
			if err := EmbedMetadataWithCoverData(req.FilePath, metadata, coverDataBytes); err != nil {
				return "", fmt.Errorf("failed to embed metadata with cover: %w", err)
			}
		} else {
			if err := EmbedMetadata(req.FilePath, metadata, ""); err != nil {
				return "", fmt.Errorf("failed to embed metadata: %w", err)
			}
		}
		if len(coverDataBytes) > 0 {
			embeddedCover, err := ExtractCoverArt(req.FilePath)
			if err != nil || len(embeddedCover) == 0 {
				if err != nil {
					return "", fmt.Errorf("metadata embedded but cover verification failed: %w", err)
				}
				return "", fmt.Errorf("metadata embedded but cover verification failed: empty embedded cover")
			}
			GoLog("[ReEnrich] Cover verified after embed (%d bytes)\n", len(embeddedCover))
		}

		GoLog("[ReEnrich] FLAC metadata embedded successfully\n")

		result := map[string]interface{}{
			"method":            "native",
			"success":           true,
			"enriched_metadata": enrichedMeta,
		}
		jsonBytes, _ := json.Marshal(result)
		return string(jsonBytes), nil
	}

	// Don't cleanup cover temp — Dart needs it for FFmpeg embed
	cleanupCover = false
	ffmpegMetadata := buildReEnrichFFmpegMetadata(&req, lyricsLRC)

	result := map[string]interface{}{
		"method":            "ffmpeg",
		"cover_path":        coverTempPath,
		"lyrics":            lyricsLRC,
		"enriched_metadata": enrichedMeta,
		"metadata":          ffmpegMetadata,
	}

	jsonBytes, _ := json.Marshal(result)
	return string(jsonBytes), nil
}

func InitExtensionSystem(extensionsDir, dataDir string) error {
	manager := getExtensionManager()
	if err := manager.SetDirectories(extensionsDir, dataDir); err != nil {
		return err
	}

	settingsStore := GetExtensionSettingsStore()
	if err := settingsStore.SetDataDir(dataDir); err != nil {
		return err
	}

	return nil
}

func LoadExtensionsFromDir(dirPath string) (string, error) {
	manager := getExtensionManager()
	loaded, errors := manager.LoadExtensionsFromDirectory(dirPath)

	result := map[string]interface{}{
		"loaded": loaded,
		"errors": make([]string, len(errors)),
	}

	for i, err := range errors {
		result["errors"].([]string)[i] = err.Error()
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func LoadExtensionFromPath(filePath string) (string, error) {
	manager := getExtensionManager()
	ext, err := manager.LoadExtensionFromFile(filePath)
	if err != nil {
		return "", err
	}

	result := map[string]interface{}{
		"id":           ext.ID,
		"name":         ext.Manifest.Name,
		"display_name": ext.Manifest.DisplayName,
		"version":      ext.Manifest.Version,
		"enabled":      ext.Enabled,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func UnloadExtensionByID(extensionID string) error {
	manager := getExtensionManager()
	return manager.UnloadExtension(extensionID)
}

func RemoveExtensionByID(extensionID string) error {
	manager := getExtensionManager()
	return manager.RemoveExtension(extensionID)
}

func UpgradeExtensionFromPath(filePath string) (string, error) {
	manager := getExtensionManager()
	ext, err := manager.UpgradeExtension(filePath)
	if err != nil {
		return "", err
	}

	result := map[string]interface{}{
		"id":           ext.ID,
		"display_name": ext.Manifest.DisplayName,
		"version":      ext.Manifest.Version,
		"enabled":      ext.Enabled,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func CheckExtensionUpgradeFromPath(filePath string) (string, error) {
	manager := getExtensionManager()
	return manager.CheckExtensionUpgradeJSON(filePath)
}

func GetInstalledExtensions() (string, error) {
	manager := getExtensionManager()
	return manager.GetInstalledExtensionsJSON()
}

func SetExtensionEnabledByID(extensionID string, enabled bool) error {
	manager := getExtensionManager()
	return manager.SetExtensionEnabled(extensionID, enabled)
}

func SetProviderPriorityJSON(priorityJSON string) error {
	var priority []string
	if err := json.Unmarshal([]byte(priorityJSON), &priority); err != nil {
		return err
	}

	SetProviderPriority(priority)
	return nil
}

func GetProviderPriorityJSON() (string, error) {
	priority := GetProviderPriority()
	jsonBytes, err := json.Marshal(priority)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

func SetExtensionFallbackProviderIDsJSON(providerIDsJSON string) error {
	if strings.TrimSpace(providerIDsJSON) == "" {
		SetExtensionFallbackProviderIDs(nil)
		return nil
	}

	var providerIDs []string
	if err := json.Unmarshal([]byte(providerIDsJSON), &providerIDs); err != nil {
		return err
	}

	SetExtensionFallbackProviderIDs(providerIDs)
	return nil
}

func GetExtensionFallbackProviderIDsJSON() (string, error) {
	providerIDs := GetExtensionFallbackProviderIDs()
	jsonBytes, err := json.Marshal(providerIDs)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

func SetMetadataProviderPriorityJSON(priorityJSON string) error {
	var priority []string
	if err := json.Unmarshal([]byte(priorityJSON), &priority); err != nil {
		return err
	}

	SetMetadataProviderPriority(priority)
	return nil
}

func GetMetadataProviderPriorityJSON() (string, error) {
	priority := GetMetadataProviderPriority()
	jsonBytes, err := json.Marshal(priority)
	if err != nil {
		return "", err
	}
	return string(jsonBytes), nil
}

func GetExtensionSettingsJSON(extensionID string) (string, error) {
	store := GetExtensionSettingsStore()
	settings := store.GetAll(extensionID)

	jsonBytes, err := json.Marshal(settings)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func SetExtensionSettingsJSON(extensionID, settingsJSON string) error {
	var settings map[string]interface{}
	if err := json.Unmarshal([]byte(settingsJSON), &settings); err != nil {
		return err
	}

	store := GetExtensionSettingsStore()
	if err := store.SetAll(extensionID, settings); err != nil {
		return err
	}

	manager := getExtensionManager()
	return manager.InitializeExtension(extensionID, settings)
}

func SearchTracksWithExtensionsJSON(query string, limit int) (string, error) {
	manager := getExtensionManager()
	tracks, err := manager.SearchTracksWithExtensions(query, limit)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(tracks)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func SearchTracksWithMetadataProvidersJSON(query string, limit int, includeExtensions bool) (string, error) {
	manager := getExtensionManager()
	tracks, err := manager.SearchTracksWithMetadataProviders(query, limit, includeExtensions)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(tracks)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func DownloadWithExtensionsJSON(requestJSON string) (string, error) {
	var req DownloadRequest
	if err := json.Unmarshal([]byte(requestJSON), &req); err != nil {
		return "", fmt.Errorf("invalid request: %w", err)
	}
	applySongLinkRegionFromRequest(&req)
	defer closeOwnedOutputFD(req.OutputFD)

	req.TrackName = strings.TrimSpace(req.TrackName)
	req.ArtistName = strings.TrimSpace(req.ArtistName)
	req.AlbumName = strings.TrimSpace(req.AlbumName)
	req.AlbumArtist = strings.TrimSpace(req.AlbumArtist)
	req.OutputDir = strings.TrimSpace(req.OutputDir)
	req.OutputPath = strings.TrimSpace(req.OutputPath)
	req.OutputExt = strings.TrimSpace(req.OutputExt)
	if req.OutputPath == "" && req.OutputFD <= 0 && req.OutputDir != "" {
		AddAllowedDownloadDir(req.OutputDir)
	}

	result, err := DownloadWithExtensionFallback(req)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func CleanupExtensions() {
	manager := getExtensionManager()
	manager.UnloadAllExtensions()
}

func InvokeExtensionActionJSON(extensionID, actionName string) (string, error) {
	manager := getExtensionManager()
	result, err := manager.InvokeAction(extensionID, actionName)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetExtensionPendingAuthJSON(extensionID string) (string, error) {
	req := GetPendingAuthRequest(extensionID)
	if req == nil {
		return "", nil
	}

	result := map[string]interface{}{
		"extension_id": req.ExtensionID,
		"auth_url":     req.AuthURL,
		"callback_url": req.CallbackURL,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func SetExtensionAuthCodeByID(extensionID, authCode string) {
	SetExtensionAuthCode(extensionID, authCode)
}

func SetExtensionTokensByID(extensionID, accessToken, refreshToken string, expiresIn int) {
	var expiresAt time.Time
	if expiresIn > 0 {
		expiresAt = time.Now().Add(time.Duration(expiresIn) * time.Second)
	}
	SetExtensionTokens(extensionID, accessToken, refreshToken, expiresAt)
}

func ClearExtensionPendingAuthByID(extensionID string) {
	ClearPendingAuthRequest(extensionID)
}

func IsExtensionAuthenticatedByID(extensionID string) bool {
	extensionAuthStateMu.RLock()
	defer extensionAuthStateMu.RUnlock()

	state, exists := extensionAuthState[extensionID]
	if !exists {
		return false
	}

	if state.IsAuthenticated && !state.ExpiresAt.IsZero() && time.Now().After(state.ExpiresAt) {
		return false
	}

	return state.IsAuthenticated
}

func GetAllPendingAuthRequestsJSON() (string, error) {
	pendingAuthRequestsMu.RLock()
	defer pendingAuthRequestsMu.RUnlock()

	requests := make([]map[string]interface{}, 0, len(pendingAuthRequests))
	for _, req := range pendingAuthRequests {
		requests = append(requests, map[string]interface{}{
			"extension_id": req.ExtensionID,
			"auth_url":     req.AuthURL,
			"callback_url": req.CallbackURL,
		})
	}

	jsonBytes, err := json.Marshal(requests)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetPendingFFmpegCommandJSON(commandID string) (string, error) {
	cmd := GetPendingFFmpegCommand(commandID)
	if cmd == nil {
		return "", nil
	}

	result := map[string]interface{}{
		"command_id":   commandID,
		"extension_id": cmd.ExtensionID,
		"command":      cmd.Command,
		"input_path":   cmd.InputPath,
		"output_path":  cmd.OutputPath,
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func SetFFmpegCommandResultByID(commandID string, success bool, output, errorMsg string) {
	SetFFmpegCommandResult(commandID, success, output, errorMsg)
}

func GetAllPendingFFmpegCommandsJSON() (string, error) {
	ffmpegCommandsMu.RLock()
	defer ffmpegCommandsMu.RUnlock()

	commands := make([]map[string]interface{}, 0)
	for cmdID, cmd := range ffmpegCommands {
		if !cmd.Completed {
			commands = append(commands, map[string]interface{}{
				"command_id":   cmdID,
				"extension_id": cmd.ExtensionID,
				"command":      cmd.Command,
			})
		}
	}

	jsonBytes, err := json.Marshal(commands)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func EnrichTrackWithExtensionJSON(extensionID, trackJSON string) (string, error) {
	manager := getExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return trackJSON, nil
	}

	if !ext.Manifest.IsMetadataProvider() {
		return trackJSON, nil
	}

	var track ExtTrackMetadata
	if err := json.Unmarshal([]byte(trackJSON), &track); err != nil {
		return trackJSON, fmt.Errorf("failed to parse track: %w", err)
	}

	provider := newExtensionProviderWrapper(ext)
	enrichedTrack, err := provider.EnrichTrack(&track)
	if err != nil {
		return trackJSON, nil
	}

	jsonBytes, err := json.Marshal(enrichedTrack)
	if err != nil {
		return trackJSON, nil
	}

	return string(jsonBytes), nil
}

func CustomSearchWithExtensionJSON(extensionID, query string, optionsJSON string) (string, error) {
	manager := getExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return "", err
	}

	if !ext.Manifest.HasCustomSearch() {
		return "", fmt.Errorf("extension '%s' does not support custom search", extensionID)
	}

	var options map[string]interface{}
	if optionsJSON != "" {
		if err := json.Unmarshal([]byte(optionsJSON), &options); err != nil {
			options = make(map[string]interface{})
		}
	}

	provider := newExtensionProviderWrapper(ext)
	tracks, err := provider.CustomSearch(query, options)
	if err != nil {
		return "", err
	}

	result := make([]map[string]interface{}, len(tracks))
	for i, track := range tracks {
		result[i] = map[string]interface{}{
			"id":           track.ID,
			"name":         track.Name,
			"artists":      track.Artists,
			"album_name":   track.AlbumName,
			"album_artist": track.AlbumArtist,
			"duration_ms":  track.DurationMS,
			"images":       track.ResolvedCoverURL(),
			"release_date": track.ReleaseDate,
			"track_number": track.TrackNumber,
			"total_tracks": track.TotalTracks,
			"disc_number":  track.DiscNumber,
			"total_discs":  track.TotalDiscs,
			"isrc":         track.ISRC,
			"provider_id":  track.ProviderID,
			"item_type":    track.ItemType,
			"album_type":   track.AlbumType,
			"composer":     track.Composer,
		}
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetSearchProvidersJSON() (string, error) {
	manager := getExtensionManager()
	providers := manager.GetSearchProviders()

	result := make([]map[string]interface{}, 0, len(providers))
	for _, p := range providers {
		result = append(result, map[string]interface{}{
			"id":           p.extension.ID,
			"display_name": p.extension.Manifest.DisplayName,
			"placeholder":  p.extension.Manifest.SearchBehavior.Placeholder,
			"primary":      p.extension.Manifest.SearchBehavior.Primary,
			"icon":         p.extension.Manifest.SearchBehavior.Icon,
		})
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func HandleURLWithExtensionJSON(url string) (string, error) {
	manager := getExtensionManager()
	resultWithID, err := manager.HandleURLWithExtension(url)
	if err != nil {
		return "", err
	}

	result := resultWithID.Result
	extensionID := resultWithID.ExtensionID

	if result == nil {
		return "", fmt.Errorf("extension %s failed to handle URL", extensionID)
	}

	response := map[string]interface{}{
		"type":         result.Type,
		"extension_id": extensionID,
		"name":         result.Name,
		"cover_url":    result.CoverURL,
	}

	if result.Track != nil {
		response["track"] = map[string]interface{}{
			"id":           result.Track.ID,
			"name":         result.Track.Name,
			"artists":      result.Track.Artists,
			"album_name":   result.Track.AlbumName,
			"album_artist": result.Track.AlbumArtist,
			"duration_ms":  result.Track.DurationMS,
			"images":       result.Track.ResolvedCoverURL(),
			"release_date": result.Track.ReleaseDate,
			"track_number": result.Track.TrackNumber,
			"total_tracks": result.Track.TotalTracks,
			"disc_number":  result.Track.DiscNumber,
			"total_discs":  result.Track.TotalDiscs,
			"isrc":         result.Track.ISRC,
			"provider_id":  result.Track.ProviderID,
			"composer":     result.Track.Composer,
		}
	}

	if len(result.Tracks) > 0 {
		tracks := make([]map[string]interface{}, len(result.Tracks))
		for i, track := range result.Tracks {
			tracks[i] = map[string]interface{}{
				"id":           track.ID,
				"name":         track.Name,
				"artists":      track.Artists,
				"album_name":   track.AlbumName,
				"album_artist": track.AlbumArtist,
				"duration_ms":  track.DurationMS,
				"images":       track.ResolvedCoverURL(),
				"release_date": track.ReleaseDate,
				"track_number": track.TrackNumber,
				"total_tracks": track.TotalTracks,
				"disc_number":  track.DiscNumber,
				"total_discs":  track.TotalDiscs,
				"isrc":         track.ISRC,
				"provider_id":  track.ProviderID,
				"item_type":    track.ItemType,
				"album_type":   track.AlbumType,
				"composer":     track.Composer,
			}
		}
		response["tracks"] = tracks
	}

	if result.Album != nil {
		response["album"] = map[string]interface{}{
			"id":           result.Album.ID,
			"name":         result.Album.Name,
			"artists":      result.Album.Artists,
			"cover_url":    result.Album.CoverURL,
			"release_date": result.Album.ReleaseDate,
			"total_tracks": result.Album.TotalTracks,
			"album_type":   result.Album.AlbumType,
			"provider_id":  result.Album.ProviderID,
		}
	}

	if result.Artist != nil {
		artistResponse := map[string]interface{}{
			"id":           result.Artist.ID,
			"name":         result.Artist.Name,
			"image_url":    result.Artist.ImageURL,
			"header_image": result.Artist.HeaderImage,
			"listeners":    result.Artist.Listeners,
			"provider_id":  result.Artist.ProviderID,
		}

		if len(result.Artist.Albums) > 0 {
			albums := make([]map[string]interface{}, len(result.Artist.Albums))
			for i, album := range result.Artist.Albums {
				albumType := album.AlbumType
				if albumType == "" {
					albumType = "album"
				}
				albums[i] = map[string]interface{}{
					"id":           album.ID,
					"name":         album.Name,
					"artists":      album.Artists,
					"images":       album.CoverURL,
					"cover_url":    album.CoverURL,
					"release_date": album.ReleaseDate,
					"total_tracks": album.TotalTracks,
					"album_type":   albumType,
					"provider_id":  album.ProviderID,
				}
			}
			artistResponse["albums"] = albums
		}

		if len(result.Artist.Releases) > 0 {
			releases := make([]map[string]interface{}, len(result.Artist.Releases))
			for i, release := range result.Artist.Releases {
				releaseType := release.AlbumType
				if releaseType == "" {
					releaseType = "album"
				}
				releases[i] = map[string]interface{}{
					"id":           release.ID,
					"name":         release.Name,
					"artists":      release.Artists,
					"images":       release.CoverURL,
					"cover_url":    release.CoverURL,
					"release_date": release.ReleaseDate,
					"total_tracks": release.TotalTracks,
					"album_type":   releaseType,
					"provider_id":  release.ProviderID,
				}
			}
			artistResponse["releases"] = releases
		}

		if len(result.Artist.TopTracks) > 0 {
			topTracks := make([]map[string]interface{}, len(result.Artist.TopTracks))
			for i, track := range result.Artist.TopTracks {
				topTracks[i] = map[string]interface{}{
					"id":           track.ID,
					"name":         track.Name,
					"artists":      track.Artists,
					"album_name":   track.AlbumName,
					"album_artist": track.AlbumArtist,
					"duration_ms":  track.DurationMS,
					"images":       track.ResolvedCoverURL(),
					"release_date": track.ReleaseDate,
					"track_number": track.TrackNumber,
					"total_tracks": track.TotalTracks,
					"disc_number":  track.DiscNumber,
					"total_discs":  track.TotalDiscs,
					"isrc":         track.ISRC,
					"provider_id":  track.ProviderID,
					"spotify_id":   track.SpotifyID,
					"composer":     track.Composer,
				}
			}
			artistResponse["top_tracks"] = topTracks
		}

		response["artist"] = artistResponse
	}

	jsonBytes, err := json.Marshal(response)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func FindURLHandlerJSON(url string) string {
	manager := getExtensionManager()
	handler := manager.FindURLHandler(url)
	if handler == nil {
		return ""
	}
	return handler.extension.ID
}

func GetAlbumWithExtensionJSON(extensionID, albumID string) (string, error) {
	manager := getExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return "", err
	}

	if !ext.Manifest.IsMetadataProvider() {
		return "", fmt.Errorf("extension '%s' is not a metadata provider", extensionID)
	}
	if !ext.Enabled {
		return "", fmt.Errorf("extension '%s' is disabled", extensionID)
	}

	provider := newExtensionProviderWrapper(ext)
	album, err := provider.GetAlbum(albumID)
	if err != nil {
		return "", err
	}

	if album == nil {
		return "", fmt.Errorf("album not found")
	}

	tracks := make([]map[string]interface{}, len(album.Tracks))
	for i, track := range album.Tracks {
		trackCover := track.ResolvedCoverURL()
		if trackCover == "" {
			trackCover = album.CoverURL
		}
		trackNum := track.TrackNumber
		if trackNum == 0 {
			trackNum = i + 1
		}
		tracks[i] = map[string]interface{}{
			"id":           track.ID,
			"name":         track.Name,
			"artists":      track.Artists,
			"album_name":   track.AlbumName,
			"album_artist": track.AlbumArtist,
			"duration_ms":  track.DurationMS,
			"cover_url":    trackCover,
			"release_date": track.ReleaseDate,
			"track_number": trackNum,
			"total_tracks": track.TotalTracks,
			"disc_number":  track.DiscNumber,
			"total_discs":  track.TotalDiscs,
			"isrc":         track.ISRC,
			"provider_id":  track.ProviderID,
			"item_type":    track.ItemType,
			"album_type":   track.AlbumType,
			"composer":     track.Composer,
		}
	}

	response := map[string]interface{}{
		"id":           album.ID,
		"name":         album.Name,
		"artists":      album.Artists,
		"artist_id":    album.ArtistID,
		"cover_url":    album.CoverURL,
		"release_date": album.ReleaseDate,
		"total_tracks": album.TotalTracks,
		"album_type":   album.AlbumType,
		"tracks":       tracks,
		"provider_id":  album.ProviderID,
	}

	jsonBytes, err := json.Marshal(response)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetPlaylistWithExtensionJSON(extensionID, playlistID string) (string, error) {
	manager := getExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return "", err
	}

	if !ext.Manifest.IsMetadataProvider() {
		return "", fmt.Errorf("extension '%s' is not a metadata provider", extensionID)
	}
	if !ext.Enabled {
		return "", fmt.Errorf("extension '%s' is disabled", extensionID)
	}

	vm, err := ext.lockReadyVM()
	if err != nil {
		return "", err
	}
	defer ext.VMMu.Unlock()

	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.getPlaylist === 'function') {
				return extension.getPlaylist(%q);
			}
			if (typeof extension !== 'undefined' && typeof extension.getAlbum === 'function') {
				return extension.getAlbum(%q);
			}
			return null;
		})()
	`, playlistID, playlistID)

	result, err := RunWithTimeoutAndRecover(vm, script, DefaultJSTimeout)
	if err != nil {
		return "", fmt.Errorf("getPlaylist failed: %w", err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return "", fmt.Errorf("playlist not found")
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return "", fmt.Errorf("failed to marshal result: %w", err)
	}

	var album ExtAlbumMetadata
	if err := json.Unmarshal(jsonBytes, &album); err != nil {
		return "", fmt.Errorf("failed to parse playlist: %w", err)
	}
	album.ProviderID = ext.ID
	for i := range album.Tracks {
		album.Tracks[i].ProviderID = ext.ID
	}

	tracks := make([]map[string]interface{}, len(album.Tracks))
	for i, track := range album.Tracks {
		trackCover := track.ResolvedCoverURL()
		if trackCover == "" {
			trackCover = album.CoverURL
		}
		tracks[i] = map[string]interface{}{
			"id":           track.ID,
			"name":         track.Name,
			"artists":      track.Artists,
			"album_name":   track.AlbumName,
			"album_artist": track.AlbumArtist,
			"duration_ms":  track.DurationMS,
			"cover_url":    trackCover,
			"release_date": track.ReleaseDate,
			"track_number": track.TrackNumber,
			"total_tracks": track.TotalTracks,
			"disc_number":  track.DiscNumber,
			"total_discs":  track.TotalDiscs,
			"isrc":         track.ISRC,
			"provider_id":  track.ProviderID,
			"item_type":    track.ItemType,
			"album_type":   track.AlbumType,
			"composer":     track.Composer,
		}
	}

	response := map[string]interface{}{
		"id":           album.ID,
		"name":         album.Name,
		"owner":        album.Artists,
		"cover_url":    album.CoverURL,
		"total_tracks": album.TotalTracks,
		"tracks":       tracks,
		"provider_id":  album.ProviderID,
	}

	jsonBytes, err = json.Marshal(response)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetArtistWithExtensionJSON(extensionID, artistID string) (string, error) {
	manager := getExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return "", err
	}

	if !ext.Manifest.IsMetadataProvider() {
		return "", fmt.Errorf("extension '%s' is not a metadata provider", extensionID)
	}

	provider := newExtensionProviderWrapper(ext)
	artist, err := provider.GetArtist(artistID)
	if err != nil {
		return "", err
	}

	if artist == nil {
		return "", fmt.Errorf("artist not found")
	}

	albums := make([]map[string]interface{}, len(artist.Albums))
	for i, album := range artist.Albums {
		albums[i] = map[string]interface{}{
			"id":           album.ID,
			"name":         album.Name,
			"artists":      album.Artists,
			"cover_url":    album.CoverURL,
			"release_date": album.ReleaseDate,
			"total_tracks": album.TotalTracks,
			"album_type":   album.AlbumType,
			"provider_id":  album.ProviderID,
		}
	}

	response := map[string]interface{}{
		"id":          artist.ID,
		"name":        artist.Name,
		"cover_url":   artist.ImageURL,
		"albums":      albums,
		"provider_id": artist.ProviderID,
	}

	if len(artist.Releases) > 0 {
		releases := make([]map[string]interface{}, len(artist.Releases))
		for i, release := range artist.Releases {
			releaseType := release.AlbumType
			if releaseType == "" {
				releaseType = "album"
			}
			releases[i] = map[string]interface{}{
				"id":           release.ID,
				"name":         release.Name,
				"artists":      release.Artists,
				"cover_url":    release.CoverURL,
				"release_date": release.ReleaseDate,
				"total_tracks": release.TotalTracks,
				"album_type":   releaseType,
				"provider_id":  release.ProviderID,
			}
		}
		response["releases"] = releases
	}

	if artist.HeaderImage != "" {
		response["header_image"] = artist.HeaderImage
	}

	if artist.Listeners > 0 {
		response["listeners"] = artist.Listeners
	}

	if len(artist.TopTracks) > 0 {
		topTracks := make([]map[string]interface{}, len(artist.TopTracks))
		for i, track := range artist.TopTracks {
			topTracks[i] = map[string]interface{}{
				"id":           track.ID,
				"name":         track.Name,
				"artists":      track.Artists,
				"album_name":   track.AlbumName,
				"album_artist": track.AlbumArtist,
				"duration_ms":  track.DurationMS,
				"images":       track.ResolvedCoverURL(),
				"release_date": track.ReleaseDate,
				"track_number": track.TrackNumber,
				"total_tracks": track.TotalTracks,
				"disc_number":  track.DiscNumber,
				"total_discs":  track.TotalDiscs,
				"isrc":         track.ISRC,
				"provider_id":  track.ProviderID,
				"spotify_id":   track.SpotifyID,
				"composer":     track.Composer,
			}
		}
		response["top_tracks"] = topTracks
	}

	jsonBytes, err := json.Marshal(response)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetURLHandlersJSON() (string, error) {
	manager := getExtensionManager()
	handlers := manager.GetURLHandlers()

	result := make([]map[string]interface{}, 0, len(handlers))
	for _, h := range handlers {
		result = append(result, map[string]interface{}{
			"id":           h.extension.ID,
			"display_name": h.extension.Manifest.DisplayName,
			"patterns":     h.extension.Manifest.URLHandler.Patterns,
		})
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func RunPostProcessingJSON(filePath, metadataJSON string) (string, error) {
	var metadata map[string]interface{}
	if metadataJSON != "" {
		if err := json.Unmarshal([]byte(metadataJSON), &metadata); err != nil {
			metadata = make(map[string]interface{})
		}
	}

	manager := getExtensionManager()
	result, err := manager.RunPostProcessing(filePath, metadata)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func RunPostProcessingV2JSON(inputJSON, metadataJSON string) (string, error) {
	var metadata map[string]interface{}
	if metadataJSON != "" {
		if err := json.Unmarshal([]byte(metadataJSON), &metadata); err != nil {
			metadata = make(map[string]interface{})
		}
	}

	var input PostProcessInput
	if inputJSON != "" {
		if err := json.Unmarshal([]byte(inputJSON), &input); err != nil {
			input = PostProcessInput{}
		}
	}

	manager := getExtensionManager()
	result, err := manager.RunPostProcessingV2(input, metadata)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetPostProcessingProvidersJSON() (string, error) {
	manager := getExtensionManager()
	providers := manager.GetPostProcessingProviders()

	result := make([]map[string]interface{}, 0, len(providers))
	for _, p := range providers {
		hooks := make([]map[string]interface{}, 0)
		for _, h := range p.extension.Manifest.GetPostProcessingHooks() {
			hooks = append(hooks, map[string]interface{}{
				"id":                h.ID,
				"name":              h.Name,
				"description":       h.Description,
				"default_enabled":   h.DefaultEnabled,
				"supported_formats": h.SupportedFormats,
			})
		}

		result = append(result, map[string]interface{}{
			"id":           p.extension.ID,
			"display_name": p.extension.Manifest.DisplayName,
			"hooks":        hooks,
		})
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func InitExtensionStoreJSON(cacheDir string) error {
	initExtensionStore(cacheDir)
	return nil
}

func SetStoreRegistryURLJSON(registryURL string) error {
	store := getExtensionStore()
	if store == nil {
		return fmt.Errorf("extension store not initialized")
	}

	resolved, err := resolveRegistryURL(registryURL)
	if err != nil {
		return err
	}

	if err := requireHTTPSURL(resolved, "registry"); err != nil {
		return err
	}

	store.setRegistryURL(resolved)
	return nil
}

func ClearStoreRegistryURLJSON() error {
	store := getExtensionStore()
	if store == nil {
		return fmt.Errorf("extension store not initialized")
	}

	store.setRegistryURL("")
	store.clearCache()
	return nil
}

func GetStoreRegistryURLJSON() (string, error) {
	store := getExtensionStore()
	if store == nil {
		return "", fmt.Errorf("extension store not initialized")
	}

	return store.getRegistryURL(), nil
}

func GetStoreExtensionsJSON(forceRefresh bool) (string, error) {
	store := getExtensionStore()
	if store == nil {
		return "", fmt.Errorf("extension store not initialized")
	}

	extensions, err := store.getExtensionsWithStatus(forceRefresh)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(extensions)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func SearchStoreExtensionsJSON(query, category string) (string, error) {
	store := getExtensionStore()
	if store == nil {
		return "", fmt.Errorf("extension store not initialized")
	}

	extensions, err := store.searchExtensions(query, category)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(extensions)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func GetStoreCategoriesJSON() (string, error) {
	store := getExtensionStore()
	if store == nil {
		return "", fmt.Errorf("extension store not initialized")
	}

	categories := store.getCategories()
	jsonBytes, err := json.Marshal(categories)
	if err != nil {
		return "", err
	}

	return string(jsonBytes), nil
}

func buildStoreExtensionDestPath(destDir, extensionID string) (string, error) {
	if strings.TrimSpace(extensionID) == "" {
		return "", fmt.Errorf("invalid extension id")
	}

	safeExtensionID := sanitizeFilename(extensionID)
	return filepath.Join(destDir, safeExtensionID+".spotiflac-ext"), nil
}

func DownloadStoreExtensionJSON(extensionID, destDir string) (string, error) {
	store := getExtensionStore()
	if store == nil {
		return "", fmt.Errorf("extension store not initialized")
	}

	destPath, err := buildStoreExtensionDestPath(destDir, extensionID)
	if err != nil {
		return "", err
	}
	err = store.downloadExtension(extensionID, destPath)
	if err != nil {
		return "", err
	}

	return destPath, nil
}

func ClearStoreCacheJSON() error {
	store := getExtensionStore()
	if store == nil {
		return fmt.Errorf("extension store not initialized")
	}

	store.clearCache()
	return nil
}

func callExtensionFunctionJSON(extensionID, functionName string, timeout time.Duration) (string, error) {
	manager := getExtensionManager()
	ext, err := manager.GetExtension(extensionID)
	if err != nil {
		return "", err
	}

	if !ext.Enabled {
		return "", fmt.Errorf("extension '%s' is disabled", extensionID)
	}
	vm, err := ext.lockReadyVM()
	if err != nil {
		return "", err
	}
	defer ext.VMMu.Unlock()

	// Goja runtime is not thread-safe; guard direct extension.*() calls with VMMu
	// to avoid races with other provider calls (e.g. getAlbum/getPlaylist).
	script := fmt.Sprintf(`
		(function() {
			if (typeof extension !== 'undefined' && typeof extension.%s === 'function') {
				return extension.%s();
			}
			return null;
		})()
	`, functionName, functionName)

	result, err := RunWithTimeoutAndRecover(vm, script, timeout)
	if err != nil {
		return "", fmt.Errorf("%s failed: %w", functionName, err)
	}

	if result == nil || goja.IsUndefined(result) || goja.IsNull(result) {
		return "", fmt.Errorf("%s returned null", functionName)
	}

	exported := result.Export()
	jsonBytes, err := json.Marshal(exported)
	if err != nil {
		return "", fmt.Errorf("failed to marshal result: %w", err)
	}

	return string(jsonBytes), nil
}

func GetExtensionHomeFeedJSON(extensionID string) (string, error) {
	return callExtensionFunctionJSON(extensionID, "getHomeFeed", 60*time.Second)
}

func GetExtensionBrowseCategoriesJSON(extensionID string) (string, error) {
	return callExtensionFunctionJSON(extensionID, "getBrowseCategories", 30*time.Second)
}

func SetLibraryCoverCacheDirJSON(cacheDir string) {
	SetLibraryCoverCacheDir(cacheDir)
}

func ScanLibraryFolderJSON(folderPath string) (string, error) {
	return ScanLibraryFolder(folderPath)
}

func ScanLibraryFolderIncrementalJSON(folderPath, existingFilesJSON string) (string, error) {
	return ScanLibraryFolderIncremental(folderPath, existingFilesJSON)
}

func ScanLibraryFolderIncrementalFromSnapshotJSON(folderPath, snapshotPath string) (string, error) {
	return ScanLibraryFolderIncrementalFromSnapshot(folderPath, snapshotPath)
}

func GetLibraryScanProgressJSON() string {
	return GetLibraryScanProgress()
}

func CancelLibraryScanJSON() {
	CancelLibraryScan()
}

func ReadAudioMetadataJSON(filePath string) (string, error) {
	return ReadAudioMetadata(filePath)
}

func ReadAudioMetadataWithHintJSON(filePath, displayName string) (string, error) {
	return ReadAudioMetadataWithDisplayName(filePath, displayName)
}

func ReadAudioMetadataWithHintAndCoverCacheKeyJSON(filePath, displayName, coverCacheKey string) (string, error) {
	return ReadAudioMetadataWithDisplayNameAndCoverCacheKey(filePath, displayName, coverCacheKey)
}
