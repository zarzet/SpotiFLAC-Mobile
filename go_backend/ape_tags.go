package gobackend

import (
	"encoding/binary"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
)

// APEv2 tag format constants.
const (
	apeTagPreamble     = "APETAGEX"
	apeTagHeaderSize   = 32
	apeTagVersion2     = 2000
	apeTagFlagHeader   = 1 << 29 // bit 29: this is the header, not the footer
	apeTagFlagReadOnly = 1 << 0
	// Item flags: bits 1-2 encode content type
	apeItemFlagUTF8   = 0 << 1 // 00: UTF-8 text
	apeItemFlagBinary = 1 << 1 // 01: binary data
	apeItemFlagLink   = 2 << 1 // 10: external link
)

// APETagItem represents a single key-value item in an APEv2 tag.
type APETagItem struct {
	Key   string
	Value string
	Flags uint32
}

// APETag represents a complete APEv2 tag block.
type APETag struct {
	Version  uint32
	Items    []APETagItem
	ReadOnly bool
}

// ReadAPETags reads APEv2 tags from a file.
// APEv2 tags are typically appended at the end of the file.
// The layout is: [audio data] [APEv2 header (optional)] [items...] [APEv2 footer]
// We locate the footer first (last 32 bytes), then read the tag block.
func ReadAPETags(filePath string) (*APETag, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer f.Close()

	fi, err := f.Stat()
	if err != nil {
		return nil, fmt.Errorf("failed to stat file: %w", err)
	}
	fileSize := fi.Size()

	if fileSize < apeTagHeaderSize {
		return nil, fmt.Errorf("file too small for APE tag")
	}

	// Try to find APE tag footer at the end of file.
	// The footer is the last 32 bytes before any ID3v1 tag (128 bytes).
	tag, err := readAPETagAtOffset(f, fileSize, fileSize-apeTagHeaderSize)
	if err == nil {
		return tag, nil
	}

	// Retry: skip ID3v1 tag (128 bytes) if present
	if fileSize > apeTagHeaderSize+128 {
		tag, err = readAPETagAtOffset(f, fileSize, fileSize-apeTagHeaderSize-128)
		if err == nil {
			return tag, nil
		}
	}

	return nil, fmt.Errorf("no APEv2 tag found")
}

func readAPETagAtOffset(f *os.File, fileSize, footerOffset int64) (*APETag, error) {
	if footerOffset < 0 || footerOffset+apeTagHeaderSize > fileSize {
		return nil, fmt.Errorf("invalid footer offset")
	}

	footer := make([]byte, apeTagHeaderSize)
	if _, err := f.ReadAt(footer, footerOffset); err != nil {
		return nil, fmt.Errorf("failed to read APE footer: %w", err)
	}

	if string(footer[0:8]) != apeTagPreamble {
		return nil, fmt.Errorf("APE preamble not found")
	}

	version := binary.LittleEndian.Uint32(footer[8:12])
	tagSize := binary.LittleEndian.Uint32(footer[12:16]) // size of items + footer (32 bytes)
	itemCount := binary.LittleEndian.Uint32(footer[16:20])
	flags := binary.LittleEndian.Uint32(footer[20:24])

	if version != apeTagVersion2 && version != 1000 {
		return nil, fmt.Errorf("unsupported APE tag version: %d", version)
	}
	if tagSize < apeTagHeaderSize {
		return nil, fmt.Errorf("APE tag size too small: %d", tagSize)
	}
	if itemCount > 1000 {
		return nil, fmt.Errorf("APE tag item count too large: %d", itemCount)
	}

	// This should be the footer (bit 29 clear)
	isHeader := (flags & apeTagFlagHeader) != 0
	if isHeader {
		return nil, fmt.Errorf("expected APE footer but found header")
	}

	// tagSize includes items + footer (32 bytes), but NOT the header.
	itemsSize := int64(tagSize) - apeTagHeaderSize
	if itemsSize < 0 {
		return nil, fmt.Errorf("invalid APE tag: items size negative")
	}

	itemsOffset := footerOffset - itemsSize
	if itemsOffset < 0 {
		return nil, fmt.Errorf("APE tag items extend before file start")
	}

	itemsData := make([]byte, itemsSize)
	if _, err := f.ReadAt(itemsData, itemsOffset); err != nil {
		return nil, fmt.Errorf("failed to read APE items: %w", err)
	}

	items, err := parseAPEItems(itemsData, int(itemCount))
	if err != nil {
		return nil, fmt.Errorf("failed to parse APE items: %w", err)
	}

	return &APETag{
		Version:  version,
		Items:    items,
		ReadOnly: (flags & apeTagFlagReadOnly) != 0,
	}, nil
}

func parseAPEItems(data []byte, count int) ([]APETagItem, error) {
	items := make([]APETagItem, 0, count)
	pos := 0

	for i := 0; i < count && pos < len(data); i++ {
		if pos+8 > len(data) {
			break
		}

		valueSize := int(binary.LittleEndian.Uint32(data[pos : pos+4]))
		itemFlags := binary.LittleEndian.Uint32(data[pos+4 : pos+8])
		pos += 8

		// Key is null-terminated ASCII (2-255 bytes, case-insensitive)
		keyEnd := pos
		for keyEnd < len(data) && data[keyEnd] != 0 {
			keyEnd++
		}
		if keyEnd >= len(data) {
			break
		}

		key := string(data[pos:keyEnd])
		pos = keyEnd + 1

		if pos+valueSize > len(data) {
			break
		}
		value := string(data[pos : pos+valueSize])
		pos += valueSize

		items = append(items, APETagItem{
			Key:   key,
			Value: value,
			Flags: itemFlags,
		})
	}

	return items, nil
}

// WriteAPETags writes APEv2 tags to the end of a file.
// If the file already has APEv2 tags, they are replaced.
// The tag is written with both header and footer.
func WriteAPETags(filePath string, tag *APETag) error {
	existingSize, err := findExistingAPETagSize(filePath)
	if err != nil {
		return fmt.Errorf("failed to check existing APE tag: %w", err)
	}

	tagData, err := marshalAPETag(tag)
	if err != nil {
		return fmt.Errorf("failed to marshal APE tag: %w", err)
	}

	if existingSize > 0 {
		fi, err := os.Stat(filePath)
		if err != nil {
			return fmt.Errorf("failed to stat file: %w", err)
		}
		newSize := fi.Size() - int64(existingSize)
		if err := os.Truncate(filePath, newSize); err != nil {
			return fmt.Errorf("failed to truncate existing APE tag: %w", err)
		}
	}

	f, err := os.OpenFile(filePath, os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return fmt.Errorf("failed to open file for writing: %w", err)
	}
	defer f.Close()

	if _, err := f.Write(tagData); err != nil {
		return fmt.Errorf("failed to write APE tag: %w", err)
	}

	return nil
}

// findExistingAPETagSize returns the total size of an existing APE tag
// (header + items + footer) at the end of the file, or 0 if none exists.
func findExistingAPETagSize(filePath string) (int64, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return 0, err
	}
	defer f.Close()

	fi, err := f.Stat()
	if err != nil {
		return 0, err
	}
	fileSize := fi.Size()

	offsets := []int64{fileSize - apeTagHeaderSize}
	if fileSize > apeTagHeaderSize+128 {
		offsets = append(offsets, fileSize-apeTagHeaderSize-128)
	}

	for _, offset := range offsets {
		if offset < 0 {
			continue
		}
		footer := make([]byte, apeTagHeaderSize)
		if _, err := f.ReadAt(footer, offset); err != nil {
			continue
		}
		if string(footer[0:8]) != apeTagPreamble {
			continue
		}

		flags := binary.LittleEndian.Uint32(footer[20:24])
		if (flags & apeTagFlagHeader) != 0 {
			continue
		}

		tagSize := int64(binary.LittleEndian.Uint32(footer[12:16]))

		// Check if there's also a header (tagSize only covers items + footer)
		hasHeader := (flags & (1 << 31)) != 0 // bit 31 = tag contains header
		totalSize := tagSize
		if hasHeader {
			totalSize += apeTagHeaderSize
		}

		// Include any trailing data after the footer (e.g. ID3v1 128-byte tag).
		// When truncating, we must remove the APE tag AND everything after it.
		trailingBytes := fileSize - (offset + apeTagHeaderSize)
		totalSize += trailingBytes

		return totalSize, nil
	}

	return 0, nil
}

// marshalAPETag serializes an APETag into bytes (header + items + footer).
func marshalAPETag(tag *APETag) ([]byte, error) {
	if tag == nil || len(tag.Items) == 0 {
		return nil, fmt.Errorf("empty APE tag")
	}

	var itemsData []byte
	for _, item := range tag.Items {
		keyBytes := []byte(item.Key)
		valueBytes := []byte(item.Value)

		// 4 bytes: value size (LE)
		sizeBuf := make([]byte, 4)
		binary.LittleEndian.PutUint32(sizeBuf, uint32(len(valueBytes)))

		// 4 bytes: item flags (LE)
		flagsBuf := make([]byte, 4)
		binary.LittleEndian.PutUint32(flagsBuf, item.Flags)

		itemsData = append(itemsData, sizeBuf...)
		itemsData = append(itemsData, flagsBuf...)
		itemsData = append(itemsData, keyBytes...)
		itemsData = append(itemsData, 0)
		itemsData = append(itemsData, valueBytes...)
	}

	// tagSize = items data + footer (32 bytes)
	tagSize := uint32(len(itemsData) + apeTagHeaderSize)
	itemCount := uint32(len(tag.Items))

	version := uint32(apeTagVersion2)
	if tag.Version != 0 {
		version = tag.Version
	}

	// flags: bit 29 = 1 (is header), bit 31 = 1 (contains header)
	headerFlags := uint32(apeTagFlagHeader | (1 << 31))
	header := buildAPEHeaderFooter(version, tagSize, itemCount, headerFlags)

	// flags: bit 29 = 0 (is footer), bit 31 = 1 (contains header)
	footerFlags := uint32(1 << 31)
	footer := buildAPEHeaderFooter(version, tagSize, itemCount, footerFlags)

	// Final layout: header + items + footer
	result := make([]byte, 0, len(header)+len(itemsData)+len(footer))
	result = append(result, header...)
	result = append(result, itemsData...)
	result = append(result, footer...)

	return result, nil
}

func buildAPEHeaderFooter(version, tagSize, itemCount, flags uint32) []byte {
	buf := make([]byte, apeTagHeaderSize)
	copy(buf[0:8], apeTagPreamble)
	binary.LittleEndian.PutUint32(buf[8:12], version)
	binary.LittleEndian.PutUint32(buf[12:16], tagSize)
	binary.LittleEndian.PutUint32(buf[16:20], itemCount)
	binary.LittleEndian.PutUint32(buf[20:24], flags)
	// bytes 24-31 are reserved (zeros)
	return buf
}

// APETagToAudioMetadata converts an APETag to our unified AudioMetadata struct.
func APETagToAudioMetadata(tag *APETag) *AudioMetadata {
	if tag == nil {
		return nil
	}

	metadata := &AudioMetadata{}
	for _, item := range tag.Items {
		key := strings.ToUpper(strings.TrimSpace(item.Key))
		value := strings.TrimSpace(item.Value)
		if value == "" {
			continue
		}

		switch key {
		case "TITLE":
			metadata.Title = value
		case "ARTIST":
			metadata.Artist = value
		case "ALBUM":
			metadata.Album = value
		case "ALBUMARTIST", "ALBUM ARTIST":
			metadata.AlbumArtist = value
		case "GENRE":
			metadata.Genre = value
		case "YEAR":
			metadata.Year = value
		case "DATE":
			metadata.Date = value
		case "TRACK", "TRACKNUMBER":
			// APE track format can be "3" or "3/12"
			trackNum, _ := strconv.Atoi(strings.Split(value, "/")[0])
			metadata.TrackNumber = trackNum
		case "DISC", "DISCNUMBER":
			discNum, _ := strconv.Atoi(strings.Split(value, "/")[0])
			metadata.DiscNumber = discNum
		case "ISRC":
			metadata.ISRC = value
		case "LYRICS", "UNSYNCEDLYRICS":
			if metadata.Lyrics == "" {
				metadata.Lyrics = value
			}
		case "LABEL", "PUBLISHER":
			metadata.Label = value
		case "COPYRIGHT":
			metadata.Copyright = value
		case "COMPOSER":
			metadata.Composer = value
		case "COMMENT":
			metadata.Comment = value
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

	return metadata
}

// AudioMetadataToAPEItems converts metadata fields to APE tag items.
func AudioMetadataToAPEItems(metadata *AudioMetadata) []APETagItem {
	if metadata == nil {
		return nil
	}

	var items []APETagItem
	addItem := func(key, value string) {
		if value != "" {
			items = append(items, APETagItem{Key: key, Value: value})
		}
	}

	addItem("Title", metadata.Title)
	addItem("Artist", metadata.Artist)
	addItem("Album", metadata.Album)
	addItem("Album Artist", metadata.AlbumArtist)
	addItem("Genre", metadata.Genre)
	if metadata.Date != "" {
		addItem("Year", metadata.Date)
	} else if metadata.Year != "" {
		addItem("Year", metadata.Year)
	}
	if metadata.TrackNumber > 0 {
		addItem("Track", strconv.Itoa(metadata.TrackNumber))
	}
	if metadata.DiscNumber > 0 {
		addItem("Disc", strconv.Itoa(metadata.DiscNumber))
	}
	addItem("ISRC", metadata.ISRC)
	addItem("Lyrics", metadata.Lyrics)
	addItem("Label", metadata.Label)
	addItem("Copyright", metadata.Copyright)
	addItem("Composer", metadata.Composer)
	addItem("Comment", metadata.Comment)
	addItem("REPLAYGAIN_TRACK_GAIN", metadata.ReplayGainTrackGain)
	addItem("REPLAYGAIN_TRACK_PEAK", metadata.ReplayGainTrackPeak)
	addItem("REPLAYGAIN_ALBUM_GAIN", metadata.ReplayGainAlbumGain)
	addItem("REPLAYGAIN_ALBUM_PEAK", metadata.ReplayGainAlbumPeak)

	return items
}

// apeKeysFromFields builds a set of upper-case APE tag keys corresponding to
// the metadata fields map sent by the editor.  This is used during merge to
// ensure that even empty (cleared) fields override old values.
func apeKeysFromFields(fields map[string]string) map[string]struct{} {
	mapping := map[string]string{
		"title":                 "TITLE",
		"artist":                "ARTIST",
		"album":                 "ALBUM",
		"album_artist":          "ALBUM ARTIST",
		"date":                  "YEAR",
		"genre":                 "GENRE",
		"track_number":          "TRACK",
		"disc_number":           "DISC",
		"isrc":                  "ISRC",
		"lyrics":                "LYRICS",
		"label":                 "LABEL",
		"copyright":             "COPYRIGHT",
		"composer":              "COMPOSER",
		"comment":               "COMMENT",
		"replaygain_track_gain": "REPLAYGAIN_TRACK_GAIN",
		"replaygain_track_peak": "REPLAYGAIN_TRACK_PEAK",
		"replaygain_album_gain": "REPLAYGAIN_ALBUM_GAIN",
		"replaygain_album_peak": "REPLAYGAIN_ALBUM_PEAK",
	}
	result := make(map[string]struct{})
	for fk, apeKey := range mapping {
		if _, present := fields[fk]; present {
			result[strings.ToUpper(apeKey)] = struct{}{}
		}
	}
	// Some fields have reader aliases that must also be cleared when the
	// canonical key is updated (e.g. "Year" writer ↔ DATE/YEAR reader,
	// DISC ↔ DISCNUMBER, TRACK ↔ TRACKNUMBER, "ALBUM ARTIST" ↔ ALBUMARTIST,
	// LABEL ↔ PUBLISHER, LYRICS ↔ UNSYNCEDLYRICS).
	if _, present := fields["date"]; present {
		result["DATE"] = struct{}{}
	}
	if _, present := fields["disc_number"]; present {
		result["DISCNUMBER"] = struct{}{}
	}
	if _, present := fields["track_number"]; present {
		result["TRACKNUMBER"] = struct{}{}
	}
	if _, present := fields["album_artist"]; present {
		result["ALBUMARTIST"] = struct{}{}
	}
	if _, present := fields["label"]; present {
		result["PUBLISHER"] = struct{}{}
	}
	if _, present := fields["lyrics"]; present {
		result["UNSYNCEDLYRICS"] = struct{}{}
	}
	return result
}

// MergeAPEItems overlays newItems on top of existing items.
// For each new item, if a matching key exists (case-insensitive) in existing,
// it is replaced. New keys are appended. Existing items whose keys are NOT
// in newItems are preserved (cover art, ReplayGain, custom tags, etc.).
//
// overrideKeys is an optional set of upper-case keys that should be removed
// from existing even if they do not appear in newItems.  This handles field
// deletion: the caller sends an empty value which is not serialized into
// newItems, but the old value must still be dropped.
func MergeAPEItems(existing, newItems []APETagItem, overrideKeys map[string]struct{}) []APETagItem {
	// Build a set of keys being updated (upper-case for case-insensitive match)
	combined := make(map[string]struct{}, len(newItems)+len(overrideKeys))
	for k := range overrideKeys {
		combined[strings.ToUpper(k)] = struct{}{}
	}
	for _, item := range newItems {
		combined[strings.ToUpper(item.Key)] = struct{}{}
	}

	var merged []APETagItem
	for _, item := range existing {
		if _, overwritten := combined[strings.ToUpper(item.Key)]; !overwritten {
			merged = append(merged, item)
		}
	}

	merged = append(merged, newItems...)

	return merged
}

// ReadAPETagsFromReader reads APEv2 tags from an io.ReaderAt + size.
// This is useful for reading APE tags from files opened via SAF or other abstractions.
func ReadAPETagsFromReader(r io.ReaderAt, fileSize int64) (*APETag, error) {
	if fileSize < apeTagHeaderSize {
		return nil, fmt.Errorf("file too small for APE tag")
	}

	// Try footer at end of file
	footer := make([]byte, apeTagHeaderSize)
	if _, err := r.ReadAt(footer, fileSize-apeTagHeaderSize); err != nil {
		return nil, fmt.Errorf("failed to read APE footer: %w", err)
	}

	if string(footer[0:8]) == apeTagPreamble {
		tag, err := parseAPETagFromFooter(r, fileSize, fileSize-apeTagHeaderSize, footer)
		if err == nil {
			return tag, nil
		}
	}

	// Retry: skip ID3v1 tag (128 bytes)
	if fileSize > apeTagHeaderSize+128 {
		offset := fileSize - apeTagHeaderSize - 128
		if _, err := r.ReadAt(footer, offset); err == nil {
			if string(footer[0:8]) == apeTagPreamble {
				tag, err := parseAPETagFromFooter(r, fileSize, offset, footer)
				if err == nil {
					return tag, nil
				}
			}
		}
	}

	return nil, fmt.Errorf("no APEv2 tag found")
}

func parseAPETagFromFooter(r io.ReaderAt, fileSize, footerOffset int64, footer []byte) (*APETag, error) {
	version := binary.LittleEndian.Uint32(footer[8:12])
	tagSize := binary.LittleEndian.Uint32(footer[12:16])
	itemCount := binary.LittleEndian.Uint32(footer[16:20])
	flags := binary.LittleEndian.Uint32(footer[20:24])

	if version != apeTagVersion2 && version != 1000 {
		return nil, fmt.Errorf("unsupported APE tag version: %d", version)
	}
	if tagSize < apeTagHeaderSize {
		return nil, fmt.Errorf("APE tag size too small: %d", tagSize)
	}
	if itemCount > 1000 {
		return nil, fmt.Errorf("APE tag item count too large: %d", itemCount)
	}
	if (flags & apeTagFlagHeader) != 0 {
		return nil, fmt.Errorf("expected footer, found header")
	}

	itemsSize := int64(tagSize) - apeTagHeaderSize
	itemsOffset := footerOffset - itemsSize
	if itemsOffset < 0 {
		return nil, fmt.Errorf("APE items extend before file start")
	}

	itemsData := make([]byte, itemsSize)
	if _, err := r.ReadAt(itemsData, itemsOffset); err != nil {
		return nil, fmt.Errorf("failed to read APE items: %w", err)
	}

	items, err := parseAPEItems(itemsData, int(itemCount))
	if err != nil {
		return nil, fmt.Errorf("failed to parse APE items: %w", err)
	}

	return &APETag{
		Version:  version,
		Items:    items,
		ReadOnly: (flags & apeTagFlagReadOnly) != 0,
	}, nil
}
