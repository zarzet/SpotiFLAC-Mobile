package gobackend

import (
	"bytes"
	"encoding/binary"
	"fmt"
	stdimage "image"
	_ "image/gif"
	_ "image/jpeg"
	_ "image/png"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"github.com/go-flac/flacpicture/v2"
	"github.com/go-flac/flacvorbis/v2"
	"github.com/go-flac/go-flac/v2"
)

const artistTagModeSplitVorbis = "split_vorbis"

var artistTagSplitPattern = regexp.MustCompile(`\s*(?:,|&|\bx\b)\s*|\s+\b(?:feat(?:uring)?|ft|with)\.?\s*`)

func detectCoverMIME(coverPath string, coverData []byte) string {
	// Prefer magic-byte detection over file extension.
	// Some providers return non-JPEG data behind .jpg URLs.
	if len(coverData) >= 8 &&
		coverData[0] == 0x89 &&
		coverData[1] == 0x50 &&
		coverData[2] == 0x4E &&
		coverData[3] == 0x47 &&
		coverData[4] == 0x0D &&
		coverData[5] == 0x0A &&
		coverData[6] == 0x1A &&
		coverData[7] == 0x0A {
		return "image/png"
	}
	if len(coverData) >= 3 &&
		coverData[0] == 0xFF &&
		coverData[1] == 0xD8 &&
		coverData[2] == 0xFF {
		return "image/jpeg"
	}
	if len(coverData) >= 6 {
		header := string(coverData[:6])
		if header == "GIF87a" || header == "GIF89a" {
			return "image/gif"
		}
	}
	if len(coverData) >= 12 &&
		string(coverData[:4]) == "RIFF" &&
		string(coverData[8:12]) == "WEBP" {
		return "image/webp"
	}

	switch strings.ToLower(filepath.Ext(strings.TrimSpace(coverPath))) {
	case ".png":
		return "image/png"
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".webp":
		return "image/webp"
	case ".gif":
		return "image/gif"
	}

	return "image/jpeg"
}

func buildPictureBlock(coverPath string, coverData []byte) (flac.MetaDataBlock, error) {
	if len(coverData) == 0 {
		return flac.MetaDataBlock{}, fmt.Errorf("empty cover data")
	}

	mime := detectCoverMIME(coverPath, coverData)
	picture := &flacpicture.MetadataBlockPicture{
		PictureType: flacpicture.PictureTypeFrontCover,
		MIME:        mime,
		Description: "Front Cover",
		ImageData:   coverData,
	}

	// Width/height/depth are optional in practice; keep zero when decode fails.
	if cfg, format, err := stdimage.DecodeConfig(bytes.NewReader(coverData)); err == nil {
		picture.Width = uint32(cfg.Width)
		picture.Height = uint32(cfg.Height)
		switch format {
		case "png":
			picture.ColorDepth = 32
		case "jpeg":
			picture.ColorDepth = 24
		default:
			picture.ColorDepth = 0
		}
	}

	return picture.Marshal(), nil
}

type Metadata struct {
	Title         string
	Artist        string
	Album         string
	AlbumArtist   string
	ArtistTagMode string
	Date          string
	TrackNumber   int
	TotalTracks   int
	DiscNumber    int
	ISRC          string
	Description   string
	Lyrics        string
	Genre         string
	Label         string
	Copyright     string
	Composer      string
	Comment       string

	// ReplayGain fields (stored as Vorbis Comments in FLAC)
	ReplayGainTrackGain string // e.g. "-6.50 dB"
	ReplayGainTrackPeak string // e.g. "0.988831"
	ReplayGainAlbumGain string // e.g. "-7.20 dB"
	ReplayGainAlbumPeak string // e.g. "1.000000"
}

func EmbedMetadata(filePath string, metadata Metadata, coverPath string) error {
	f, err := flac.ParseFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to parse FLAC file: %w", err)
	}

	var cmtIdx int = -1
	var cmt *flacvorbis.MetaDataBlockVorbisComment

	for idx, meta := range f.Meta {
		if meta.Type == flac.VorbisComment {
			cmtIdx = idx
			cmt, err = flacvorbis.ParseFromMetaDataBlock(*meta)
			if err != nil {
				return fmt.Errorf("failed to parse vorbis comment: %w", err)
			}
			break
		}
	}

	if cmt == nil {
		cmt = flacvorbis.New()
	}

	writeVorbisMetadata(cmt, metadata)

	cmtBlock := cmt.Marshal()
	if cmtIdx >= 0 {
		f.Meta[cmtIdx] = &cmtBlock
	} else {
		f.Meta = append(f.Meta, &cmtBlock)
	}

	if coverPath != "" {
		if fileExists(coverPath) {
			coverData, err := os.ReadFile(coverPath)
			if err != nil {
				fmt.Printf("[Metadata] Warning: Failed to read cover file %s: %v\n", coverPath, err)
			} else {
				for i := len(f.Meta) - 1; i >= 0; i-- {
					if f.Meta[i].Type == flac.Picture {
						f.Meta = append(f.Meta[:i], f.Meta[i+1:]...)
					}
				}

				picBlock, err := buildPictureBlock(coverPath, coverData)
				if err != nil {
					return fmt.Errorf("failed to create picture block: %w", err)
				}
				f.Meta = append(f.Meta, &picBlock)
				fmt.Printf("[Metadata] Cover art embedded successfully (%d bytes)\n", len(coverData))
			}
		} else {
			fmt.Printf("[Metadata] Warning: Cover file does not exist: %s\n", coverPath)
		}
	}

	return f.Save(filePath)
}

func EmbedMetadataWithCoverData(filePath string, metadata Metadata, coverData []byte) error {
	f, err := flac.ParseFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to parse FLAC file: %w", err)
	}

	var cmtIdx int = -1
	var cmt *flacvorbis.MetaDataBlockVorbisComment

	for idx, meta := range f.Meta {
		if meta.Type == flac.VorbisComment {
			cmtIdx = idx
			cmt, err = flacvorbis.ParseFromMetaDataBlock(*meta)
			if err != nil {
				return fmt.Errorf("failed to parse vorbis comment: %w", err)
			}
			break
		}
	}

	if cmt == nil {
		cmt = flacvorbis.New()
	}

	writeVorbisMetadata(cmt, metadata)

	cmtBlock := cmt.Marshal()
	if cmtIdx >= 0 {
		f.Meta[cmtIdx] = &cmtBlock
	} else {
		f.Meta = append(f.Meta, &cmtBlock)
	}

	if len(coverData) > 0 {
		for i := len(f.Meta) - 1; i >= 0; i-- {
			if f.Meta[i].Type == flac.Picture {
				f.Meta = append(f.Meta[:i], f.Meta[i+1:]...)
			}
		}

		picBlock, err := buildPictureBlock("", coverData)
		if err != nil {
			return fmt.Errorf("failed to create picture block: %w", err)
		}
		f.Meta = append(f.Meta, &picBlock)
		fmt.Printf("[Metadata] Cover art embedded successfully (%d bytes)\n", len(coverData))
	}

	return f.Save(filePath)
}

func ReadMetadata(filePath string) (*Metadata, error) {
	f, err := flac.ParseFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to parse FLAC file: %w", err)
	}

	metadata := &Metadata{}

	for _, meta := range f.Meta {
		if meta.Type == flac.VorbisComment {
			cmt, err := flacvorbis.ParseFromMetaDataBlock(*meta)
			if err != nil {
				continue
			}

			metadata.Title = getComment(cmt, "TITLE")
			metadata.Artist = getJoinedComment(cmt, "ARTIST")
			metadata.Album = getComment(cmt, "ALBUM")
			metadata.AlbumArtist = getJoinedComment(cmt, "ALBUMARTIST")
			if metadata.AlbumArtist == "" {
				metadata.AlbumArtist = getJoinedComment(cmt, "ALBUM ARTIST")
			}
			if metadata.AlbumArtist == "" {
				metadata.AlbumArtist = getJoinedComment(cmt, "ALBUM_ARTIST")
			}
			metadata.Date = getComment(cmt, "DATE")
			metadata.ISRC = getComment(cmt, "ISRC")
			metadata.Description = getComment(cmt, "DESCRIPTION")

			metadata.Lyrics = getComment(cmt, "LYRICS")
			if metadata.Lyrics == "" {
				metadata.Lyrics = getComment(cmt, "UNSYNCEDLYRICS")
			}

			trackNum := getComment(cmt, "TRACKNUMBER")
			if trackNum != "" {
				fmt.Sscanf(trackNum, "%d", &metadata.TrackNumber)
			}
			if metadata.TrackNumber == 0 {
				trackNum = getComment(cmt, "TRACK")
				if trackNum != "" {
					fmt.Sscanf(trackNum, "%d", &metadata.TrackNumber)
				}
			}

			discNum := getComment(cmt, "DISCNUMBER")
			if discNum != "" {
				fmt.Sscanf(discNum, "%d", &metadata.DiscNumber)
			}
			if metadata.DiscNumber == 0 {
				discNum = getComment(cmt, "DISC")
				if discNum != "" {
					fmt.Sscanf(discNum, "%d", &metadata.DiscNumber)
				}
			}

			if metadata.Date == "" {
				metadata.Date = getComment(cmt, "YEAR")
			}

			metadata.Genre = getComment(cmt, "GENRE")
			metadata.Label = getComment(cmt, "ORGANIZATION")
			if metadata.Label == "" {
				metadata.Label = getComment(cmt, "LABEL")
			}
			if metadata.Label == "" {
				metadata.Label = getComment(cmt, "PUBLISHER")
			}
			metadata.Copyright = getComment(cmt, "COPYRIGHT")
			metadata.Composer = getComment(cmt, "COMPOSER")
			metadata.Comment = getComment(cmt, "COMMENT")

			metadata.ReplayGainTrackGain = getComment(cmt, "REPLAYGAIN_TRACK_GAIN")
			metadata.ReplayGainTrackPeak = getComment(cmt, "REPLAYGAIN_TRACK_PEAK")
			metadata.ReplayGainAlbumGain = getComment(cmt, "REPLAYGAIN_ALBUM_GAIN")
			metadata.ReplayGainAlbumPeak = getComment(cmt, "REPLAYGAIN_ALBUM_PEAK")

			break
		}
	}

	return metadata, nil
}

// EditFlacFields opens a FLAC file and updates only the Vorbis Comment keys
// that are explicitly present in the fields map.  Keys present with a non-empty
// value are set; keys present with an empty value are removed (cleared).  Keys
// absent from the map are left untouched.  This is the correct function for
// partial edits (e.g. writing only ReplayGain tags) and full editor saves alike.
func EditFlacFields(filePath string, fields map[string]string) error {
	f, err := flac.ParseFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to parse FLAC file: %w", err)
	}

	var cmtIdx int = -1
	var cmt *flacvorbis.MetaDataBlockVorbisComment

	for idx, meta := range f.Meta {
		if meta.Type == flac.VorbisComment {
			cmtIdx = idx
			cmt, err = flacvorbis.ParseFromMetaDataBlock(*meta)
			if err != nil {
				return fmt.Errorf("failed to parse vorbis comment: %w", err)
			}
			break
		}
	}
	if cmt == nil {
		cmt = flacvorbis.New()
	}

	artistMode := fields["artist_tag_mode"]

	// Mapping from fields-map key → one or more Vorbis Comment keys.
	// Each entry is handled with set-or-clear semantics.
	simpleKeys := map[string]string{
		"title":                 "TITLE",
		"album":                 "ALBUM",
		"date":                  "DATE",
		"isrc":                  "ISRC",
		"genre":                 "GENRE",
		"label":                 "ORGANIZATION",
		"copyright":             "COPYRIGHT",
		"composer":              "COMPOSER",
		"comment":               "COMMENT",
		"replaygain_track_gain": "REPLAYGAIN_TRACK_GAIN",
		"replaygain_track_peak": "REPLAYGAIN_TRACK_PEAK",
		"replaygain_album_gain": "REPLAYGAIN_ALBUM_GAIN",
		"replaygain_album_peak": "REPLAYGAIN_ALBUM_PEAK",
	}

	for fieldKey, vorbisKey := range simpleKeys {
		if v, ok := fields[fieldKey]; ok {
			setOrClearComment(cmt, vorbisKey, v)
		}
	}

	// Remove known aliases for fields that were just written/cleared, so that
	// tags from other taggers (e.g. LABEL, PUBLISHER, ALBUM ARTIST) don't
	// conflict with the canonical keys we use.
	aliasCleanup := map[string][]string{
		"label":     {"LABEL", "PUBLISHER"}, // canonical: ORGANIZATION
		"date":      {"YEAR"},               // canonical: DATE
		"genre":     {},                     // no common aliases
		"copyright": {},
	}
	for fieldKey, aliases := range aliasCleanup {
		if _, ok := fields[fieldKey]; ok {
			for _, alias := range aliases {
				removeCommentKey(cmt, alias)
			}
		}
	}

	// Artist fields: use split-artist logic when mode is set.
	if v, ok := fields["artist"]; ok {
		setOrClearArtistComments(cmt, "ARTIST", v, artistMode)
	}
	if v, ok := fields["album_artist"]; ok {
		setOrClearArtistComments(cmt, "ALBUMARTIST", v, artistMode)
		// Remove aliases from other taggers.
		removeCommentKey(cmt, "ALBUM ARTIST")
		removeCommentKey(cmt, "ALBUM_ARTIST")
	}

	// Track/disc numbers: present + empty → clear; present + "0" → clear.
	if v, ok := fields["track_number"]; ok {
		trackNum := 0
		if v != "" {
			fmt.Sscanf(v, "%d", &trackNum)
		}
		if trackNum > 0 {
			setOrClearComment(cmt, "TRACKNUMBER", strconv.Itoa(trackNum))
		} else {
			removeCommentKey(cmt, "TRACKNUMBER")
		}
		removeCommentKey(cmt, "TRACK") // alias
	}
	if v, ok := fields["disc_number"]; ok {
		discNum := 0
		if v != "" {
			fmt.Sscanf(v, "%d", &discNum)
		}
		if discNum > 0 {
			setOrClearComment(cmt, "DISCNUMBER", strconv.Itoa(discNum))
		} else {
			removeCommentKey(cmt, "DISCNUMBER")
		}
		removeCommentKey(cmt, "DISC") // alias
	}

	// Lyrics: set both LYRICS + UNSYNCEDLYRICS, or clear both.
	if v, ok := fields["lyrics"]; ok {
		if v != "" {
			setOrClearComment(cmt, "LYRICS", v)
			setOrClearComment(cmt, "UNSYNCEDLYRICS", v)
		} else {
			removeCommentKey(cmt, "LYRICS")
			removeCommentKey(cmt, "UNSYNCEDLYRICS")
		}
	}

	cmtBlock := cmt.Marshal()
	if cmtIdx >= 0 {
		f.Meta[cmtIdx] = &cmtBlock
	} else {
		f.Meta = append(f.Meta, &cmtBlock)
	}

	coverPath := strings.TrimSpace(fields["cover_path"])
	if coverPath != "" && fileExists(coverPath) {
		coverData, err := os.ReadFile(coverPath)
		if err == nil && len(coverData) > 0 {
			for i := len(f.Meta) - 1; i >= 0; i-- {
				if f.Meta[i].Type == flac.Picture {
					f.Meta = append(f.Meta[:i], f.Meta[i+1:]...)
				}
			}
			picBlock, err := buildPictureBlock("", coverData)
			if err == nil {
				f.Meta = append(f.Meta, &picBlock)
			}
		}
	}

	return f.Save(filePath)
}

// writeVorbisMetadata writes all metadata fields to a Vorbis Comment block.
// Empty/zero values are simply skipped (not written, not cleared).  This is
// used by the download embedding path where absent fields should preserve any
// existing values.  The editor path uses EditFlacFields() instead.
func writeVorbisMetadata(cmt *flacvorbis.MetaDataBlockVorbisComment, metadata Metadata) {
	setComment(cmt, "TITLE", metadata.Title)
	setArtistComments(cmt, "ARTIST", metadata.Artist, metadata.ArtistTagMode)
	setComment(cmt, "ALBUM", metadata.Album)
	setArtistComments(cmt, "ALBUMARTIST", metadata.AlbumArtist, metadata.ArtistTagMode)
	setComment(cmt, "DATE", metadata.Date)

	if metadata.TrackNumber > 0 {
		if metadata.TotalTracks > 0 {
			setComment(cmt, "TRACKNUMBER", fmt.Sprintf("%d/%d", metadata.TrackNumber, metadata.TotalTracks))
		} else {
			setComment(cmt, "TRACKNUMBER", strconv.Itoa(metadata.TrackNumber))
		}
	}

	if metadata.DiscNumber > 0 {
		setComment(cmt, "DISCNUMBER", strconv.Itoa(metadata.DiscNumber))
	}

	if metadata.ISRC != "" {
		setComment(cmt, "ISRC", metadata.ISRC)
	}

	if metadata.Description != "" {
		setComment(cmt, "DESCRIPTION", metadata.Description)
	}

	if metadata.Lyrics != "" {
		setComment(cmt, "LYRICS", metadata.Lyrics)
		setComment(cmt, "UNSYNCEDLYRICS", metadata.Lyrics)
	}

	if metadata.Genre != "" {
		setComment(cmt, "GENRE", metadata.Genre)
	}

	if metadata.Label != "" {
		setComment(cmt, "ORGANIZATION", metadata.Label)
	}

	if metadata.Copyright != "" {
		setComment(cmt, "COPYRIGHT", metadata.Copyright)
	}

	if metadata.Composer != "" {
		setComment(cmt, "COMPOSER", metadata.Composer)
	}

	if metadata.Comment != "" {
		setComment(cmt, "COMMENT", metadata.Comment)
	}

	setComment(cmt, "REPLAYGAIN_TRACK_GAIN", metadata.ReplayGainTrackGain)
	setComment(cmt, "REPLAYGAIN_TRACK_PEAK", metadata.ReplayGainTrackPeak)
	setComment(cmt, "REPLAYGAIN_ALBUM_GAIN", metadata.ReplayGainAlbumGain)
	setComment(cmt, "REPLAYGAIN_ALBUM_PEAK", metadata.ReplayGainAlbumPeak)
}

func setComment(cmt *flacvorbis.MetaDataBlockVorbisComment, key, value string) {
	if value == "" {
		return
	}
	removeCommentKey(cmt, key)
	cmt.Comments = append(cmt.Comments, key+"="+value)
}

// setOrClearComment writes a Vorbis Comment, or removes the key if value is
// empty.  Used by the metadata editor path where empty means "delete this tag".
func setOrClearComment(cmt *flacvorbis.MetaDataBlockVorbisComment, key, value string) {
	if value == "" {
		removeCommentKey(cmt, key)
		return
	}
	removeCommentKey(cmt, key)
	cmt.Comments = append(cmt.Comments, key+"="+value)
}

func setArtistComments(cmt *flacvorbis.MetaDataBlockVorbisComment, key, value, mode string) {
	if value == "" {
		return
	}
	values := []string{value}
	if shouldSplitVorbisArtistTags(mode) {
		values = splitArtistTagValues(value)
	}
	if len(values) == 0 {
		return
	}
	removeCommentKey(cmt, key)
	for _, artist := range values {
		if strings.TrimSpace(artist) == "" {
			continue
		}
		cmt.Comments = append(cmt.Comments, key+"="+artist)
	}
}

// setOrClearArtistComments writes artist Vorbis Comments, or removes the key
// if value is empty.  Used by the metadata editor path.
func setOrClearArtistComments(cmt *flacvorbis.MetaDataBlockVorbisComment, key, value, mode string) {
	if value == "" {
		removeCommentKey(cmt, key)
		return
	}
	values := []string{value}
	if shouldSplitVorbisArtistTags(mode) {
		values = splitArtistTagValues(value)
	}
	if len(values) == 0 {
		removeCommentKey(cmt, key)
		return
	}
	removeCommentKey(cmt, key)
	for _, artist := range values {
		if strings.TrimSpace(artist) == "" {
			continue
		}
		cmt.Comments = append(cmt.Comments, key+"="+artist)
	}
}

// RewriteSplitArtistTags opens a FLAC file and rewrites the ARTIST and
// ALBUMARTIST Vorbis comments as multiple separate entries (one per artist).
// This is needed because FFmpeg's -metadata flag deduplicates keys, so only
// the last value survives when multiple -metadata ARTIST=X flags are used.
// The native go-flac writer correctly handles multiple Vorbis comments.
func RewriteSplitArtistTags(filePath, artist, albumArtist string) error {
	if !shouldSplitVorbisArtistTags(artistTagModeSplitVorbis) {
		return nil
	}

	f, err := flac.ParseFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to parse FLAC file: %w", err)
	}

	var cmtIdx int = -1
	var cmt *flacvorbis.MetaDataBlockVorbisComment

	for idx, meta := range f.Meta {
		if meta.Type == flac.VorbisComment {
			cmtIdx = idx
			cmt, err = flacvorbis.ParseFromMetaDataBlock(*meta)
			if err != nil {
				return fmt.Errorf("failed to parse vorbis comment: %w", err)
			}
			break
		}
	}

	if cmt == nil {
		cmt = flacvorbis.New()
	}

	setArtistComments(cmt, "ARTIST", artist, artistTagModeSplitVorbis)
	setArtistComments(cmt, "ALBUMARTIST", albumArtist, artistTagModeSplitVorbis)

	cmtMeta := cmt.Marshal()
	if cmtIdx >= 0 {
		f.Meta[cmtIdx] = &cmtMeta
	} else {
		f.Meta = append(f.Meta, &cmtMeta)
	}

	return f.Save(filePath)
}

func removeCommentKey(cmt *flacvorbis.MetaDataBlockVorbisComment, key string) {
	keyUpper := strings.ToUpper(key)
	for i := len(cmt.Comments) - 1; i >= 0; i-- {
		comment := cmt.Comments[i]
		eqIdx := strings.Index(comment, "=")
		if eqIdx > 0 {
			existingKey := strings.ToUpper(comment[:eqIdx])
			if existingKey == keyUpper {
				cmt.Comments = append(cmt.Comments[:i], cmt.Comments[i+1:]...)
			}
		}
	}
}

func getComment(cmt *flacvorbis.MetaDataBlockVorbisComment, key string) string {
	values := getCommentValues(cmt, key)
	if len(values) == 0 {
		return ""
	}
	return values[0]
}

func getJoinedComment(cmt *flacvorbis.MetaDataBlockVorbisComment, key string) string {
	return joinVorbisCommentValues(getCommentValues(cmt, key))
}

func getCommentValues(cmt *flacvorbis.MetaDataBlockVorbisComment, key string) []string {
	keyUpper := strings.ToUpper(key) + "="
	values := make([]string, 0, 1)
	for _, comment := range cmt.Comments {
		if len(comment) > len(key) {
			commentUpper := strings.ToUpper(comment[:len(key)+1])
			if commentUpper == keyUpper {
				values = append(values, comment[len(key)+1:])
			}
		}
	}
	return values
}

func shouldSplitVorbisArtistTags(mode string) bool {
	return strings.EqualFold(strings.TrimSpace(mode), artistTagModeSplitVorbis)
}

func splitArtistTagValues(rawArtists string) []string {
	trimmed := strings.TrimSpace(rawArtists)
	if trimmed == "" {
		return nil
	}

	parts := artistTagSplitPattern.Split(trimmed, -1)
	values := make([]string, 0, len(parts))
	seen := make(map[string]struct{}, len(parts))
	for _, part := range parts {
		artist := strings.TrimSpace(part)
		if artist == "" {
			continue
		}
		key := strings.ToLower(artist)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		values = append(values, artist)
	}
	if len(values) > 0 {
		return values
	}
	return []string{trimmed}
}

func joinVorbisCommentValues(values []string) string {
	if len(values) == 0 {
		return ""
	}

	joined := make([]string, 0, len(values))
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			continue
		}
		key := strings.ToLower(trimmed)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		joined = append(joined, trimmed)
	}
	return strings.Join(joined, ", ")
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func ExtractCoverArt(filePath string) ([]byte, error) {
	f, err := flac.ParseFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to parse FLAC file: %w", err)
	}

	for _, meta := range f.Meta {
		if meta.Type == flac.Picture {
			pic, err := flacpicture.ParseFromMetaDataBlock(*meta)
			if err != nil {
				continue
			}
			if pic.PictureType == flacpicture.PictureTypeFrontCover && len(pic.ImageData) > 0 {
				return pic.ImageData, nil
			}
		}
	}

	for _, meta := range f.Meta {
		if meta.Type == flac.Picture {
			pic, err := flacpicture.ParseFromMetaDataBlock(*meta)
			if err != nil {
				continue
			}
			if len(pic.ImageData) > 0 {
				return pic.ImageData, nil
			}
		}
	}

	return nil, fmt.Errorf("no cover art found in file")
}

func EmbedLyrics(filePath string, lyrics string) error {
	f, err := flac.ParseFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to parse FLAC file: %w", err)
	}

	var cmtIdx int = -1
	var cmt *flacvorbis.MetaDataBlockVorbisComment

	for idx, meta := range f.Meta {
		if meta.Type == flac.VorbisComment {
			cmtIdx = idx
			cmt, err = flacvorbis.ParseFromMetaDataBlock(*meta)
			if err != nil {
				return fmt.Errorf("failed to parse vorbis comment: %w", err)
			}
			break
		}
	}

	if cmt == nil {
		cmt = flacvorbis.New()
	}

	setComment(cmt, "LYRICS", lyrics)
	setComment(cmt, "UNSYNCEDLYRICS", lyrics)

	cmtBlock := cmt.Marshal()
	if cmtIdx >= 0 {
		f.Meta[cmtIdx] = &cmtBlock
	} else {
		f.Meta = append(f.Meta, &cmtBlock)
	}

	return f.Save(filePath)
}

func EmbedGenreLabel(filePath string, genre, label string) error {
	if genre == "" && label == "" {
		return nil
	}

	f, err := flac.ParseFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to parse FLAC file: %w", err)
	}

	var cmtIdx int = -1
	var cmt *flacvorbis.MetaDataBlockVorbisComment

	for idx, meta := range f.Meta {
		if meta.Type == flac.VorbisComment {
			cmtIdx = idx
			cmt, err = flacvorbis.ParseFromMetaDataBlock(*meta)
			if err != nil {
				return fmt.Errorf("failed to parse vorbis comment: %w", err)
			}
			break
		}
	}

	if cmt == nil {
		cmt = flacvorbis.New()
	}

	if genre != "" {
		setComment(cmt, "GENRE", genre)
	}
	if label != "" {
		setComment(cmt, "ORGANIZATION", label)
	}

	cmtBlock := cmt.Marshal()
	if cmtIdx >= 0 {
		f.Meta[cmtIdx] = &cmtBlock
	} else {
		f.Meta = append(f.Meta, &cmtBlock)
	}

	return f.Save(filePath)
}

func ExtractLyrics(filePath string) (string, error) {
	lower := strings.ToLower(filePath)

	if strings.HasSuffix(lower, ".flac") {
		lyrics, err := extractLyricsFromFlac(filePath)
		if err == nil && strings.TrimSpace(lyrics) != "" {
			return lyrics, nil
		}
		return extractLyricsFromSidecarLRC(filePath)
	}

	if strings.HasSuffix(lower, ".m4a") || strings.HasSuffix(lower, ".aac") {
		lyrics, err := extractLyricsFromM4A(filePath)
		if err == nil && strings.TrimSpace(lyrics) != "" {
			return lyrics, nil
		}
		return extractLyricsFromSidecarLRC(filePath)
	}

	if strings.HasSuffix(lower, ".mp3") {
		meta, err := ReadID3Tags(filePath)
		if err == nil && meta != nil {
			if strings.TrimSpace(meta.Lyrics) != "" {
				return meta.Lyrics, nil
			}
			if looksLikeEmbeddedLyrics(meta.Comment) {
				return meta.Comment, nil
			}
		}
		return extractLyricsFromSidecarLRC(filePath)
	}

	if strings.HasSuffix(lower, ".opus") || strings.HasSuffix(lower, ".ogg") {
		meta, err := ReadOggVorbisComments(filePath)
		if err == nil && meta != nil {
			if strings.TrimSpace(meta.Lyrics) != "" {
				return meta.Lyrics, nil
			}
			if looksLikeEmbeddedLyrics(meta.Comment) {
				return meta.Comment, nil
			}
		}
		return extractLyricsFromSidecarLRC(filePath)
	}

	return extractLyricsFromSidecarLRC(filePath)
}

func ReadM4ATags(filePath string) (*AudioMetadata, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	fi, err := f.Stat()
	if err != nil {
		return nil, err
	}

	ilst, err := findM4AIlstAtom(f, fi.Size())
	if err != nil {
		return nil, err
	}

	metadata := &AudioMetadata{}
	start := ilst.offset + ilst.headerSize
	end := ilst.offset + ilst.size
	for pos := start; pos+8 <= end; {
		header, err := readAtomHeaderAt(f, pos, fi.Size())
		if err != nil {
			return nil, err
		}
		if header.size == 0 {
			header.size = end - pos
		}
		if header.size < header.headerSize {
			return nil, fmt.Errorf("invalid atom size for %s", header.typ)
		}

		switch header.typ {
		case "\xa9nam":
			metadata.Title, _ = readM4ATextValue(f, header, fi.Size())
		case "\xa9ART":
			metadata.Artist, _ = readM4ATextValue(f, header, fi.Size())
		case "\xa9alb":
			metadata.Album, _ = readM4ATextValue(f, header, fi.Size())
		case "aART":
			metadata.AlbumArtist, _ = readM4ATextValue(f, header, fi.Size())
		case "\xa9day":
			metadata.Date, _ = readM4ATextValue(f, header, fi.Size())
			metadata.Year = metadata.Date
		case "\xa9gen":
			metadata.Genre, _ = readM4ATextValue(f, header, fi.Size())
		case "\xa9wrt":
			metadata.Composer, _ = readM4ATextValue(f, header, fi.Size())
		case "\xa9cmt":
			metadata.Comment, _ = readM4ATextValue(f, header, fi.Size())
		case "cprt":
			metadata.Copyright, _ = readM4ATextValue(f, header, fi.Size())
		case "\xa9lyr":
			metadata.Lyrics, _ = readM4ATextValue(f, header, fi.Size())
		case "trkn":
			metadata.TrackNumber, _ = readM4AIndexValue(f, header, fi.Size())
		case "disk":
			metadata.DiscNumber, _ = readM4AIndexValue(f, header, fi.Size())
		case "----":
			name, value, freeformErr := readM4AFreeformValue(f, header, fi.Size())
			if freeformErr == nil {
				switch strings.ToUpper(strings.TrimSpace(name)) {
				case "ISRC":
					metadata.ISRC = value
				case "LABEL", "ORGANIZATION":
					metadata.Label = value
				case "COMMENT":
					if metadata.Comment == "" {
						metadata.Comment = value
					}
				case "COMPOSER":
					if metadata.Composer == "" {
						metadata.Composer = value
					}
				case "COPYRIGHT":
					if metadata.Copyright == "" {
						metadata.Copyright = value
					}
				case "LYRICS", "UNSYNCEDLYRICS":
					if metadata.Lyrics == "" {
						metadata.Lyrics = value
					}
				case "REPLAYGAIN_TRACK_GAIN":
					metadata.ReplayGainTrackGain = value
				case "REPLAYGAIN_TRACK_PEAK":
					metadata.ReplayGainTrackPeak = value
				case "REPLAYGAIN_ALBUM_GAIN":
					metadata.ReplayGainAlbumGain = value
				case "REPLAYGAIN_ALBUM_PEAK":
					metadata.ReplayGainAlbumPeak = value
				}
			}
		}

		pos += header.size
	}

	if metadata.Title == "" &&
		metadata.Artist == "" &&
		metadata.Album == "" &&
		metadata.AlbumArtist == "" &&
		metadata.Lyrics == "" &&
		metadata.TrackNumber == 0 &&
		metadata.DiscNumber == 0 {
		return nil, fmt.Errorf("no M4A tags found")
	}

	return metadata, nil
}

func extractLyricsFromM4A(filePath string) (string, error) {
	metadata, err := ReadM4ATags(filePath)
	if err != nil {
		return "", err
	}
	if metadata == nil || strings.TrimSpace(metadata.Lyrics) == "" {
		return "", fmt.Errorf("no lyrics found in file")
	}
	return metadata.Lyrics, nil
}

func extractCoverFromM4A(filePath string) ([]byte, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	fi, err := f.Stat()
	if err != nil {
		return nil, err
	}
	fileSize := fi.Size()

	ilst, err := findM4AIlstAtom(f, fileSize)
	if err != nil {
		return nil, err
	}

	bodyStart := ilst.offset + ilst.headerSize
	bodySize := ilst.size - ilst.headerSize

	covr, found, err := findAtomInRange(f, bodyStart, bodySize, "covr", fileSize)
	if err != nil || !found {
		return nil, fmt.Errorf("cover atom not found")
	}

	dataStart := covr.offset + covr.headerSize
	dataSize := covr.size - covr.headerSize

	dataAtom, found, err := findAtomInRange(f, dataStart, dataSize, "data", fileSize)
	if err != nil || !found {
		return nil, fmt.Errorf("data atom not found in cover")
	}

	// data atom: header + 4 bytes type indicator + 4 bytes locale
	imgStart := dataAtom.offset + dataAtom.headerSize + 8
	imgLen := dataAtom.size - dataAtom.headerSize - 8
	if imgLen <= 0 {
		return nil, fmt.Errorf("empty cover data")
	}

	buf := make([]byte, imgLen)
	if _, err := f.ReadAt(buf, imgStart); err != nil {
		return nil, err
	}

	return buf, nil
}

// findM4AIlstAtom locates the ilst atom that holds all iTunes-style tags.
// It tries two common layouts:
//  1. moov > udta > meta > ilst  (iTunes, FFmpeg default)
//  2. moov > meta > ilst         (some encoders omit the udta wrapper)
func findM4AIlstAtom(f *os.File, fileSize int64) (atomHeader, error) {
	moov, found, err := findAtomInRange(f, 0, fileSize, "moov", fileSize)
	if err != nil || !found {
		return atomHeader{}, fmt.Errorf("moov not found")
	}

	moovBodyStart := moov.offset + moov.headerSize
	moovBodySize := moov.size - moov.headerSize

	// Path 1: moov > udta > meta > ilst
	if udta, ok, _ := findAtomInRange(f, moovBodyStart, moovBodySize, "udta", fileSize); ok {
		udtaBodyStart := udta.offset + udta.headerSize
		udtaBodySize := udta.size - udta.headerSize
		if meta, ok2, _ := findAtomInRange(f, udtaBodyStart, udtaBodySize, "meta", fileSize); ok2 {
			metaBodyStart := meta.offset + meta.headerSize + 4
			metaBodySize := meta.size - meta.headerSize - 4
			if ilst, ok3, _ := findAtomInRange(f, metaBodyStart, metaBodySize, "ilst", fileSize); ok3 {
				return ilst, nil
			}
		}
	}

	// Path 2: moov > meta > ilst (no udta wrapper)
	if meta, ok, _ := findAtomInRange(f, moovBodyStart, moovBodySize, "meta", fileSize); ok {
		metaBodyStart := meta.offset + meta.headerSize + 4
		metaBodySize := meta.size - meta.headerSize - 4
		if ilst, ok2, _ := findAtomInRange(f, metaBodyStart, metaBodySize, "ilst", fileSize); ok2 {
			return ilst, nil
		}
	}

	return atomHeader{}, fmt.Errorf("ilst not found (tried moov>udta>meta>ilst and moov>meta>ilst)")
}

func readM4ADataAtomPayload(f *os.File, dataAtom atomHeader) ([]byte, error) {
	payloadStart := dataAtom.offset + dataAtom.headerSize + 8
	payloadLen := dataAtom.size - dataAtom.headerSize - 8
	if payloadLen <= 0 {
		return nil, fmt.Errorf("empty data atom in %s", dataAtom.typ)
	}

	buf := make([]byte, payloadLen)
	if _, err := f.ReadAt(buf, payloadStart); err != nil {
		return nil, err
	}
	return buf, nil
}

func readM4ADataPayload(f *os.File, parent atomHeader, fileSize int64) ([]byte, error) {
	dataStart := parent.offset + parent.headerSize
	dataSize := parent.size - parent.headerSize

	dataAtom, found, err := findAtomInRange(f, dataStart, dataSize, "data", fileSize)
	if err != nil || !found {
		return nil, fmt.Errorf("data atom not found in %s", parent.typ)
	}
	return readM4ADataAtomPayload(f, dataAtom)
}

func readM4ATextValue(f *os.File, parent atomHeader, fileSize int64) (string, error) {
	payload, err := readM4ADataPayload(f, parent, fileSize)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(strings.TrimRight(string(payload), "\x00")), nil
}

func readM4AIndexValue(f *os.File, parent atomHeader, fileSize int64) (int, error) {
	payload, err := readM4ADataPayload(f, parent, fileSize)
	if err != nil {
		return 0, err
	}
	if len(payload) < 4 {
		return 0, fmt.Errorf("index payload too short in %s", parent.typ)
	}
	return int(binary.BigEndian.Uint16(payload[2:4])), nil
}

func readM4AFreeformValue(f *os.File, parent atomHeader, fileSize int64) (string, string, error) {
	start := parent.offset + parent.headerSize
	end := parent.offset + parent.size

	var nameValue string
	var dataValue string
	for pos := start; pos+8 <= end; {
		header, err := readAtomHeaderAt(f, pos, fileSize)
		if err != nil {
			return "", "", err
		}
		if header.size == 0 {
			header.size = end - pos
		}
		if header.size < header.headerSize {
			return "", "", fmt.Errorf("invalid atom size for %s", header.typ)
		}

		switch header.typ {
		case "mean":
			// Domain qualifier (e.g. "com.apple.iTunes") — not needed, skip.
		case "name":
			// The "name" atom payload is: 4-byte version/flags, then raw UTF-8 text.
			// It does NOT contain a nested "data" atom, so read the payload directly.
			payloadStart := header.offset + header.headerSize + 4
			payloadLen := header.size - header.headerSize - 4
			if payloadLen > 0 {
				buf := make([]byte, payloadLen)
				if _, readErr := f.ReadAt(buf, payloadStart); readErr == nil {
					nameValue = strings.TrimSpace(strings.TrimRight(string(buf), "\x00"))
				}
			}
		case "data":
			payload, payloadErr := readM4ADataAtomPayload(f, header)
			if payloadErr == nil {
				dataValue = strings.TrimSpace(strings.TrimRight(string(payload), "\x00"))
			}
		}

		pos += header.size
	}

	if nameValue == "" || dataValue == "" {
		return "", "", fmt.Errorf("freeform M4A tag incomplete")
	}

	return nameValue, dataValue, nil
}

func extractLyricsFromSidecarLRC(filePath string) (string, error) {
	ext := filepath.Ext(filePath)
	base := strings.TrimSuffix(filePath, ext)
	if strings.TrimSpace(base) == "" {
		return "", fmt.Errorf("no lyrics found in file")
	}

	lrcPath := base + ".lrc"
	data, err := os.ReadFile(lrcPath)
	if err != nil {
		return "", fmt.Errorf("no lyrics found in file")
	}

	lyrics := strings.TrimSpace(string(data))
	if lyrics == "" {
		return "", fmt.Errorf("no lyrics found in file")
	}
	return lyrics, nil
}

func extractLyricsFromFlac(filePath string) (string, error) {
	f, err := flac.ParseFile(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to parse FLAC file: %w", err)
	}

	for _, meta := range f.Meta {
		if meta.Type != flac.VorbisComment {
			continue
		}

		cmt, err := flacvorbis.ParseFromMetaDataBlock(*meta)
		if err != nil {
			continue
		}

		lyrics, err := cmt.Get("LYRICS")
		if err == nil && len(lyrics) > 0 && strings.TrimSpace(lyrics[0]) != "" {
			return lyrics[0], nil
		}

		lyrics, err = cmt.Get("UNSYNCEDLYRICS")
		if err == nil && len(lyrics) > 0 && strings.TrimSpace(lyrics[0]) != "" {
			return lyrics[0], nil
		}
	}

	return "", fmt.Errorf("no lyrics found in file")
}

func looksLikeEmbeddedLyrics(value string) bool {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return false
	}

	lower := strings.ToLower(trimmed)
	if strings.Contains(lower, "[ar:") || strings.Contains(lower, "[ti:") {
		return true
	}

	if strings.Contains(trimmed, "\n") && strings.Contains(trimmed, "[") && strings.Contains(trimmed, "]") {
		return true
	}

	return false
}

type AudioQuality struct {
	BitDepth     int   `json:"bit_depth"`
	SampleRate   int   `json:"sample_rate"`
	TotalSamples int64 `json:"total_samples"`
}

func GetAudioQuality(filePath string) (AudioQuality, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return AudioQuality{}, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	marker := make([]byte, 4)
	if _, err := file.Read(marker); err != nil {
		return AudioQuality{}, fmt.Errorf("failed to read marker: %w", err)
	}

	if string(marker) == "fLaC" {
		header := make([]byte, 4)
		if _, err := file.Read(header); err != nil {
			return AudioQuality{}, fmt.Errorf("failed to read header: %w", err)
		}

		blockType := header[0] & 0x7F
		if blockType != 0 {
			return AudioQuality{}, fmt.Errorf("first block is not STREAMINFO")
		}

		streamInfo := make([]byte, 34)
		if _, err := file.Read(streamInfo); err != nil {
			return AudioQuality{}, fmt.Errorf("failed to read STREAMINFO: %w", err)
		}

		sampleRate := (int(streamInfo[10]) << 12) | (int(streamInfo[11]) << 4) | (int(streamInfo[12]) >> 4)

		bitsPerSample := ((int(streamInfo[12]) & 0x01) << 4) | (int(streamInfo[13]) >> 4) + 1

		totalSamples := int64(streamInfo[13]&0x0F)<<32 |
			int64(streamInfo[14])<<24 |
			int64(streamInfo[15])<<16 |
			int64(streamInfo[16])<<8 |
			int64(streamInfo[17])

		return AudioQuality{
			BitDepth:     bitsPerSample,
			SampleRate:   sampleRate,
			TotalSamples: totalSamples,
		}, nil
	}

	file.Seek(0, 0)
	header8 := make([]byte, 8)
	if _, err := file.Read(header8); err != nil {
		return AudioQuality{}, fmt.Errorf("failed to read header: %w", err)
	}

	if string(header8[4:8]) == "ftyp" {
		file.Close()
		return GetM4AQuality(filePath)
	}

	return AudioQuality{}, fmt.Errorf("unsupported file format (not FLAC or M4A)")
}

func GetM4AQuality(filePath string) (AudioQuality, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return AudioQuality{}, fmt.Errorf("failed to open M4A file: %w", err)
	}
	defer f.Close()

	info, err := f.Stat()
	if err != nil {
		return AudioQuality{}, fmt.Errorf("failed to stat M4A file: %w", err)
	}
	fileSize := info.Size()

	moovHeader, moovFound, err := findAtomInRange(f, 0, fileSize, "moov", fileSize)
	if err != nil {
		return AudioQuality{}, fmt.Errorf("failed to find moov atom: %w", err)
	}
	if !moovFound {
		return AudioQuality{}, fmt.Errorf("moov atom not found")
	}

	moovStart := moovHeader.offset
	moovEnd := moovHeader.offset + moovHeader.size

	sampleOffset, atomType, err := findAudioSampleEntry(f, moovStart, moovEnd, fileSize)
	if err != nil {
		return AudioQuality{}, err
	}

	buf := make([]byte, 32)
	if _, err := f.ReadAt(buf, sampleOffset); err != nil {
		return AudioQuality{}, fmt.Errorf("failed to read audio sample entry: %w", err)
	}

	// AudioSampleEntry layout from the box type field:
	//   [0:4]   type ("mp4a"/"alac")
	//   [4:10]  SampleEntry.reserved
	//   [10:12] data_reference_index
	//   [12:20] reserved[8]
	//   [20:22] channelcount
	//   [22:24] samplesize (bit depth)
	//   [24:26] pre_defined
	//   [26:28] reserved
	//   [28:32] samplerate (16.16 fixed-point)
	sampleRate := int(buf[28])<<8 | int(buf[29])
	bitDepth := int(buf[22])<<8 | int(buf[23])
	if bitDepth <= 0 {
		bitDepth = 16
		if atomType == "alac" {
			bitDepth = 24
		}
	}

	return AudioQuality{BitDepth: bitDepth, SampleRate: sampleRate}, nil
}

type atomHeader struct {
	offset     int64
	size       int64
	headerSize int64
	typ        string
}

func readAtomHeaderAt(f *os.File, offset, fileSize int64) (atomHeader, error) {
	if offset+8 > fileSize {
		return atomHeader{}, io.ErrUnexpectedEOF
	}

	headerBuf := make([]byte, 8)
	if _, err := f.ReadAt(headerBuf, offset); err != nil {
		return atomHeader{}, err
	}

	size32 := binary.BigEndian.Uint32(headerBuf[0:4])
	typ := string(headerBuf[4:8])

	if size32 == 1 {
		if offset+16 > fileSize {
			return atomHeader{}, io.ErrUnexpectedEOF
		}
		extBuf := make([]byte, 8)
		if _, err := f.ReadAt(extBuf, offset+8); err != nil {
			return atomHeader{}, err
		}
		size64 := binary.BigEndian.Uint64(extBuf)
		return atomHeader{offset: offset, size: int64(size64), headerSize: 16, typ: typ}, nil
	}

	return atomHeader{offset: offset, size: int64(size32), headerSize: 8, typ: typ}, nil
}

func findAtomInRange(f *os.File, start, size int64, target string, fileSize int64) (atomHeader, bool, error) {
	if size <= 0 {
		return atomHeader{}, false, nil
	}

	end := start + size
	pos := start

	for pos+8 <= end {
		header, err := readAtomHeaderAt(f, pos, fileSize)
		if err != nil {
			return atomHeader{}, false, err
		}

		atomSize := header.size
		if atomSize == 0 {
			atomSize = end - pos
		}

		if atomSize < header.headerSize {
			return atomHeader{}, false, fmt.Errorf("invalid atom size for %s", header.typ)
		}

		header.size = atomSize
		if header.typ == target {
			return header, true, nil
		}

		pos += atomSize
	}

	return atomHeader{}, false, nil
}

func findAudioSampleEntry(f *os.File, start, end, fileSize int64) (int64, string, error) {
	const chunkSize = 64 * 1024
	patternMP4A := []byte("mp4a")
	patternALAC := []byte("alac")

	var tail []byte
	readPos := start

	for readPos < end {
		toRead := end - readPos
		if toRead > chunkSize {
			toRead = chunkSize
		}

		buf := make([]byte, toRead)
		n, err := f.ReadAt(buf, readPos)
		if err != nil && err != io.EOF {
			return 0, "", fmt.Errorf("failed to read M4A atom data: %w", err)
		}
		if n == 0 {
			break
		}

		data := append(tail, buf[:n]...)
		mp4aIdx := bytes.Index(data, patternMP4A)
		alacIdx := bytes.Index(data, patternALAC)

		bestIdx := -1
		bestType := ""
		switch {
		case mp4aIdx >= 0 && alacIdx >= 0:
			if mp4aIdx <= alacIdx {
				bestIdx = mp4aIdx
				bestType = "mp4a"
			} else {
				bestIdx = alacIdx
				bestType = "alac"
			}
		case mp4aIdx >= 0:
			bestIdx = mp4aIdx
			bestType = "mp4a"
		case alacIdx >= 0:
			bestIdx = alacIdx
			bestType = "alac"
		}

		if bestIdx >= 0 {
			absolute := readPos - int64(len(tail)) + int64(bestIdx)
			if absolute+32 > fileSize {
				return 0, "", fmt.Errorf("audio info not found in M4A file")
			}
			return absolute, bestType, nil
		}

		if len(data) >= 3 {
			tail = append([]byte{}, data[len(data)-3:]...)
		} else {
			tail = append([]byte{}, data...)
		}

		readPos += int64(n)
	}

	return 0, "", fmt.Errorf("audio info not found in M4A file")
}
