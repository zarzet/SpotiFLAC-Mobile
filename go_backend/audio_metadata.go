package gobackend

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

// AudioMetadata represents common audio file metadata
type AudioMetadata struct {
	Title       string
	Artist      string
	Album       string
	AlbumArtist string
	Genre       string
	Year        string
	Date        string
	TrackNumber int
	DiscNumber  int
	ISRC        string
	Lyrics      string
	Label       string
	Copyright   string
	Composer    string
	Comment     string
}

// MP3Quality represents MP3 specific quality info
type MP3Quality struct {
	SampleRate int
	BitDepth   int
	Duration   int
	Bitrate    int
}

// OggQuality represents Ogg/Opus specific quality info
type OggQuality struct {
	SampleRate int
	BitDepth   int
	Duration   int
}

// =============================================================================
// ID3 Tag Reading (MP3)
// =============================================================================

func ReadID3Tags(filePath string) (*AudioMetadata, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	metadata := &AudioMetadata{}

	id3v2, err := readID3v2(file)
	if err == nil && id3v2 != nil {
		metadata = id3v2
	}

	if metadata.Title == "" || metadata.Artist == "" {
		id3v1, err := readID3v1(file)
		if err == nil && id3v1 != nil {
			if metadata.Title == "" {
				metadata.Title = id3v1.Title
			}
			if metadata.Artist == "" {
				metadata.Artist = id3v1.Artist
			}
			if metadata.Album == "" {
				metadata.Album = id3v1.Album
			}
			if metadata.Year == "" {
				metadata.Year = id3v1.Year
			}
			if metadata.Genre == "" {
				metadata.Genre = id3v1.Genre
			}
		}
	}

	if metadata.Title == "" && metadata.Artist == "" {
		return nil, fmt.Errorf("no ID3 tags found")
	}

	return metadata, nil
}

func readID3v2(file *os.File) (*AudioMetadata, error) {
	file.Seek(0, io.SeekStart)

	header := make([]byte, 10)
	if _, err := io.ReadFull(file, header); err != nil {
		return nil, err
	}

	if string(header[0:3]) != "ID3" {
		return nil, fmt.Errorf("no ID3v2 header")
	}

	majorVersion := header[3]
	flags := header[5]
	unsync := (flags & 0x80) != 0
	extendedHeader := (flags & 0x40) != 0
	footerPresent := (flags & 0x10) != 0

	size := int(header[6])<<21 | int(header[7])<<14 | int(header[8])<<7 | int(header[9])

	tagData := make([]byte, size)
	if _, err := io.ReadFull(file, tagData); err != nil {
		return nil, err
	}

	if footerPresent && len(tagData) >= 10 {
		footerStart := len(tagData) - 10
		if footerStart >= 0 && string(tagData[footerStart:footerStart+3]) == "3DI" {
			tagData = tagData[:footerStart]
		}
	}

	if extendedHeader {
		if skip := extendedHeaderSize(tagData, majorVersion); skip > 0 && skip < len(tagData) {
			tagData = tagData[skip:]
		}
	}

	metadata := &AudioMetadata{}

	if majorVersion == 2 {
		parseID3v22Frames(tagData, metadata, unsync)
	} else {
		parseID3v23Frames(tagData, metadata, majorVersion, unsync)
	}

	return metadata, nil
}

func parseID3v22Frames(data []byte, metadata *AudioMetadata, tagUnsync bool) {
	pos := 0
	for pos+6 < len(data) {
		frameID := string(data[pos : pos+3])
		if frameID[0] == 0 {
			break
		}

		frameSize := int(data[pos+3])<<16 | int(data[pos+4])<<8 | int(data[pos+5])
		if frameSize <= 0 || pos+6+frameSize > len(data) {
			break
		}

		frameData := data[pos+6 : pos+6+frameSize]
		if tagUnsync {
			frameData = removeUnsync(frameData)
		}
		value := firstTextValue(extractTextFrame(frameData))

		switch frameID {
		case "TT2":
			metadata.Title = value
		case "TP1":
			metadata.Artist = value
		case "TP2":
			metadata.AlbumArtist = value
		case "TAL":
			metadata.Album = value
		case "TYE":
			metadata.Year = value
		case "TCO":
			metadata.Genre = cleanGenre(value)
		case "TRK":
			metadata.TrackNumber = parseTrackNumber(value)
		case "TPA":
			metadata.DiscNumber = parseTrackNumber(value)
		case "TCM":
			metadata.Composer = value
		case "TPB":
			metadata.Label = value
		case "TCR":
			metadata.Copyright = value
		case "ULT":
			if v := extractLyricsFrame(frameData); v != "" && metadata.Lyrics == "" {
				metadata.Lyrics = v
			}
		case "TXX":
			desc, userValue := extractUserTextFrame(frameData)
			if isLyricsDescription(desc) && userValue != "" && metadata.Lyrics == "" {
				metadata.Lyrics = userValue
			}
		}

		pos += 6 + frameSize
	}
}

func parseID3v23Frames(data []byte, metadata *AudioMetadata, version byte, tagUnsync bool) {
	pos := 0
	for pos+10 < len(data) {
		frameID := string(data[pos : pos+4])
		if frameID[0] == 0 {
			break
		}

		var frameSize int
		if version == 4 {
			frameSize = int(data[pos+4])<<21 | int(data[pos+5])<<14 | int(data[pos+6])<<7 | int(data[pos+7])
		} else {
			frameSize = int(data[pos+4])<<24 | int(data[pos+5])<<16 | int(data[pos+6])<<8 | int(data[pos+7])
		}

		if frameSize <= 0 || pos+10+frameSize > len(data) {
			break
		}

		frameData := data[pos+10 : pos+10+frameSize]

		statusFlags := data[pos+8]
		_ = statusFlags
		formatFlags := data[pos+9]

		if version == 3 {
			const (
				id3v23FlagCompression = 0x80
				id3v23FlagEncryption  = 0x40
				id3v23FlagGrouping    = 0x20
			)
			if formatFlags&(id3v23FlagCompression|id3v23FlagEncryption) != 0 {
				pos += 10 + frameSize
				continue
			}
			if formatFlags&id3v23FlagGrouping != 0 {
				if len(frameData) < 1 {
					pos += 10 + frameSize
					continue
				}
				frameData = frameData[1:]
			}
			if tagUnsync {
				frameData = removeUnsync(frameData)
			}
		} else if version == 4 {
			const (
				id3v24FlagGrouping    = 0x40
				id3v24FlagCompression = 0x08
				id3v24FlagEncryption  = 0x04
				id3v24FlagUnsync      = 0x02
				id3v24FlagDataLen     = 0x01
			)
			if formatFlags&id3v24FlagGrouping != 0 {
				if len(frameData) < 1 {
					pos += 10 + frameSize
					continue
				}
				frameData = frameData[1:]
			}
			if formatFlags&id3v24FlagDataLen != 0 {
				if len(frameData) < 4 {
					pos += 10 + frameSize
					continue
				}
				frameData = frameData[4:]
			}
			if formatFlags&id3v24FlagUnsync != 0 || tagUnsync {
				frameData = removeUnsync(frameData)
			}
			if formatFlags&(id3v24FlagCompression|id3v24FlagEncryption) != 0 {
				pos += 10 + frameSize
				continue
			}
		}

		value := firstTextValue(extractTextFrame(frameData))

		switch frameID {
		case "TIT2":
			metadata.Title = value
		case "TPE1":
			metadata.Artist = value
		case "TPE2":
			metadata.AlbumArtist = value
		case "TALB":
			metadata.Album = value
		case "TYER", "TDRC":
			metadata.Year = value
			if len(value) >= 4 {
				metadata.Date = value
			}
		case "TCON":
			metadata.Genre = cleanGenre(value)
		case "TRCK":
			metadata.TrackNumber = parseTrackNumber(value)
		case "TPOS":
			metadata.DiscNumber = parseTrackNumber(value)
		case "TSRC":
			metadata.ISRC = value
		case "TCOM":
			metadata.Composer = value
		case "TPUB":
			metadata.Label = value
		case "TCOP":
			metadata.Copyright = value
		case "COMM":
			if v := extractCommentFrame(frameData); v != "" {
				metadata.Comment = v
			}
		case "USLT":
			if v := extractLyricsFrame(frameData); v != "" && metadata.Lyrics == "" {
				metadata.Lyrics = v
			}
		case "TXXX":
			desc, userValue := extractUserTextFrame(frameData)
			if isLyricsDescription(desc) && userValue != "" && metadata.Lyrics == "" {
				metadata.Lyrics = userValue
			}
		}

		pos += 10 + frameSize
	}
}

func readID3v1(file *os.File) (*AudioMetadata, error) {
	if _, err := file.Seek(-128, io.SeekEnd); err != nil {
		return nil, err
	}

	tag := make([]byte, 128)
	if _, err := io.ReadFull(file, tag); err != nil {
		return nil, err
	}

	if string(tag[0:3]) != "TAG" {
		return nil, fmt.Errorf("no ID3v1 tag")
	}

	metadata := &AudioMetadata{
		Title:  strings.TrimRight(string(tag[3:33]), " \x00"),
		Artist: strings.TrimRight(string(tag[33:63]), " \x00"),
		Album:  strings.TrimRight(string(tag[63:93]), " \x00"),
		Year:   strings.TrimRight(string(tag[93:97]), " \x00"),
	}

	// ID3v1.1 track number (if byte 125 is 0 and byte 126 is not)
	if tag[125] == 0 && tag[126] != 0 {
		metadata.TrackNumber = int(tag[126])
	}

	genreIndex := int(tag[127])
	if genreIndex < len(id3v1Genres) {
		metadata.Genre = id3v1Genres[genreIndex]
	}

	return metadata, nil
}

func extractTextFrame(data []byte) string {
	if len(data) == 0 {
		return ""
	}

	encoding := data[0]
	text := data[1:]

	switch encoding {
	case 0: // ISO-8859-1
		return strings.TrimRight(string(text), "\x00")
	case 1: // UTF-16 with BOM
		return decodeUTF16(text)
	case 2: // UTF-16BE
		return decodeUTF16BE(text)
	case 3: // UTF-8
		return strings.TrimRight(string(text), "\x00")
	default:
		return strings.TrimRight(string(text), "\x00")
	}
}

// extractCommentFrame parses an ID3v2 COMM frame.
// Format: encoding(1) + language(3) + description(null-terminated) + text
func extractCommentFrame(data []byte) string {
	if len(data) < 5 {
		return ""
	}
	encoding := data[0]
	// skip 3-byte language code
	rest := data[4:]

	// find null terminator separating description from text
	var text []byte
	switch encoding {
	case 1, 2: // UTF-16 variants use double-null terminator
		for i := 0; i+1 < len(rest); i += 2 {
			if rest[i] == 0 && rest[i+1] == 0 {
				text = rest[i+2:]
				break
			}
		}
	default: // ISO-8859-1 or UTF-8
		idx := bytes.IndexByte(rest, 0)
		if idx >= 0 && idx+1 < len(rest) {
			text = rest[idx+1:]
		} else {
			text = rest
		}
	}

	if len(text) == 0 {
		return ""
	}

	// re-prepend encoding byte so extractTextFrame can decode properly
	framed := make([]byte, 1+len(text))
	framed[0] = encoding
	copy(framed[1:], text)
	return extractTextFrame(framed)
}

// extractLyricsFrame parses ID3 unsynchronized lyrics frames (USLT/ULT).
// Format: encoding(1) + language(3) + description(null-terminated) + lyrics text.
func extractLyricsFrame(data []byte) string {
	if len(data) < 5 {
		return ""
	}

	encoding := data[0]
	rest := data[4:] // skip 3-byte language code

	var text []byte
	switch encoding {
	case 1, 2: // UTF-16 variants use double-null terminator
		for i := 0; i+1 < len(rest); i += 2 {
			if rest[i] == 0 && rest[i+1] == 0 {
				text = rest[i+2:]
				break
			}
		}
	default: // ISO-8859-1 or UTF-8
		idx := bytes.IndexByte(rest, 0)
		if idx >= 0 && idx+1 < len(rest) {
			text = rest[idx+1:]
		} else {
			text = rest
		}
	}

	if len(text) == 0 {
		return ""
	}

	framed := make([]byte, 1+len(text))
	framed[0] = encoding
	copy(framed[1:], text)
	return extractTextFrame(framed)
}

// extractUserTextFrame parses ID3 TXXX/TXX user text frame:
// encoding(1) + description + separator + value.
func extractUserTextFrame(data []byte) (string, string) {
	if len(data) < 2 {
		return "", ""
	}

	encoding := data[0]
	payload := data[1:]

	var descRaw, valueRaw []byte
	switch encoding {
	case 1, 2: // UTF-16 variants
		for i := 0; i+1 < len(payload); i += 2 {
			if payload[i] == 0 && payload[i+1] == 0 {
				descRaw = payload[:i]
				valueRaw = payload[i+2:]
				break
			}
		}
	default: // ISO-8859-1 or UTF-8
		idx := bytes.IndexByte(payload, 0)
		if idx >= 0 {
			descRaw = payload[:idx]
			if idx+1 <= len(payload) {
				valueRaw = payload[idx+1:]
			}
		}
	}

	if len(valueRaw) == 0 {
		return "", ""
	}

	descFramed := make([]byte, 1+len(descRaw))
	descFramed[0] = encoding
	copy(descFramed[1:], descRaw)

	valueFramed := make([]byte, 1+len(valueRaw))
	valueFramed[0] = encoding
	copy(valueFramed[1:], valueRaw)

	return strings.TrimSpace(extractTextFrame(descFramed)), strings.TrimSpace(extractTextFrame(valueFramed))
}

func isLyricsDescription(description string) bool {
	switch strings.ToLower(strings.TrimSpace(description)) {
	case "lyrics", "lyric", "unsyncedlyrics", "unsynced lyrics", "lrc":
		return true
	default:
		return false
	}
}

func decodeUTF16(data []byte) string {
	if len(data) < 2 {
		return ""
	}

	var littleEndian bool
	if data[0] == 0xFF && data[1] == 0xFE {
		littleEndian = true
		data = data[2:]
	} else if data[0] == 0xFE && data[1] == 0xFF {
		littleEndian = false
		data = data[2:]
	}

	return decodeUTF16Data(data, littleEndian)
}

func decodeUTF16BE(data []byte) string {
	return decodeUTF16Data(data, false)
}

func decodeUTF16Data(data []byte, littleEndian bool) string {
	if len(data) < 2 {
		return ""
	}

	var runes []rune
	for i := 0; i+1 < len(data); i += 2 {
		var r uint16
		if littleEndian {
			r = uint16(data[i]) | uint16(data[i+1])<<8
		} else {
			r = uint16(data[i])<<8 | uint16(data[i+1])
		}
		if r == 0 {
			break
		}
		runes = append(runes, rune(r))
	}
	return string(runes)
}

func cleanGenre(genre string) string {
	if len(genre) == 0 {
		return ""
	}

	if genre[0] == '(' {
		end := strings.Index(genre, ")")
		if end > 0 {
			numStr := genre[1:end]
			if num, err := strconv.Atoi(numStr); err == nil && num < len(id3v1Genres) {
				if end+1 < len(genre) {
					return genre[end+1:]
				}
				return id3v1Genres[num]
			}
		}
	}
	return genre
}

func parseTrackNumber(s string) int {
	s = strings.TrimSpace(s)
	if idx := strings.Index(s, "/"); idx > 0 {
		s = s[:idx]
	}
	num, _ := strconv.Atoi(s)
	return num
}

func removeUnsync(data []byte) []byte {
	if len(data) == 0 {
		return data
	}
	out := make([]byte, 0, len(data))
	for i := 0; i < len(data); i++ {
		b := data[i]
		out = append(out, b)
		if b == 0xFF && i+1 < len(data) && data[i+1] == 0x00 {
			i++
		}
	}
	return out
}

func extendedHeaderSize(data []byte, version byte) int {
	if len(data) < 4 {
		return 0
	}
	var size int
	switch version {
	case 3:
		size = int(binary.BigEndian.Uint32(data[:4]))
	case 4:
		size = syncsafeToInt(data[:4])
	default:
		return 0
	}
	if size <= 0 {
		return 0
	}
	total := size + 4
	if total <= len(data) {
		return total
	}
	if size <= len(data) {
		return size
	}
	return 0
}

func syncsafeToInt(b []byte) int {
	if len(b) < 4 {
		return 0
	}
	return int(b[0])<<21 | int(b[1])<<14 | int(b[2])<<7 | int(b[3])
}

func firstTextValue(s string) string {
	if idx := strings.IndexByte(s, 0); idx >= 0 {
		return s[:idx]
	}
	return s
}

func GetMP3Quality(filePath string) (*MP3Quality, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	quality := &MP3Quality{}

	stat, err := file.Stat()
	if err != nil {
		return nil, err
	}
	fileSize := stat.Size()

	header := make([]byte, 10)
	if _, err := io.ReadFull(file, header); err != nil {
		return nil, err
	}

	var audioStart int64 = 0
	if string(header[0:3]) == "ID3" {
		tagSize := int64(header[6])<<21 | int64(header[7])<<14 | int64(header[8])<<7 | int64(header[9])
		audioStart = 10 + tagSize
	}

	file.Seek(audioStart, io.SeekStart)

	frameHeader := make([]byte, 4)
	for i := 0; i < 10000; i++ { // Search first 10KB
		if _, err := io.ReadFull(file, frameHeader); err != nil {
			break
		}

		if frameHeader[0] == 0xFF && (frameHeader[1]&0xE0) == 0xE0 {
			version := (frameHeader[1] >> 3) & 0x03
			layer := (frameHeader[1] >> 1) & 0x03
			bitrateIdx := (frameHeader[2] >> 4) & 0x0F
			sampleRateIdx := (frameHeader[2] >> 2) & 0x03

			sampleRates := [][]int{
				{11025, 12000, 8000},
				{0, 0, 0},
				{22050, 24000, 16000},
				{44100, 48000, 32000},
			}
			if version < 4 && sampleRateIdx < 3 {
				quality.SampleRate = sampleRates[version][sampleRateIdx]
			}

			if version == 3 && layer == 1 {
				bitrates := []int{0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0}
				if bitrateIdx < 16 {
					quality.Bitrate = bitrates[bitrateIdx] * 1000
				}
			}

			quality.BitDepth = 16

			if quality.Bitrate > 0 {
				audioSize := fileSize - audioStart - 128
				if audioSize > 0 {
					quality.Duration = int(audioSize * 8 / int64(quality.Bitrate))
				}
			}

			break
		}

		file.Seek(-3, io.SeekCurrent)
	}

	return quality, nil
}

func ReadOggVorbisComments(filePath string) (*AudioMetadata, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	metadata := &AudioMetadata{}

	packets, err := collectOggPackets(file, 30, 80)
	if err != nil && len(packets) == 0 {
		return nil, err
	}

	streamType := detectOggStreamType(packets)
	for _, pkt := range packets {
		if streamType == oggStreamOpus {
			if len(pkt) > 8 && string(pkt[0:8]) == "OpusTags" {
				parseVorbisComments(pkt[8:], metadata)
				break
			}
			continue
		}
		if streamType == oggStreamVorbis || streamType == oggStreamUnknown {
			if len(pkt) > 7 && pkt[0] == 0x03 && string(pkt[1:7]) == "vorbis" {
				parseVorbisComments(pkt[7:], metadata)
				break
			}
		}
		if streamType == oggStreamUnknown {
			if len(pkt) > 8 && string(pkt[0:8]) == "OpusTags" {
				parseVorbisComments(pkt[8:], metadata)
				break
			}
		}
	}

	if metadata.Title == "" && metadata.Artist == "" {
		return nil, fmt.Errorf("no Vorbis comments found")
	}

	return metadata, nil
}

type oggPage struct {
	headerType   byte
	segmentTable []byte
	data         []byte
}

func readOggPageWithHeader(file *os.File) (*oggPage, error) {
	header := make([]byte, 27)
	if _, err := io.ReadFull(file, header); err != nil {
		return nil, err
	}

	if string(header[0:4]) != "OggS" {
		return nil, fmt.Errorf("not an Ogg page")
	}

	headerType := header[5]
	numSegments := int(header[26])

	segmentTable := make([]byte, numSegments)
	if _, err := io.ReadFull(file, segmentTable); err != nil {
		return nil, err
	}

	var pageSize int
	for _, seg := range segmentTable {
		pageSize += int(seg)
	}

	pageData := make([]byte, pageSize)
	if _, err := io.ReadFull(file, pageData); err != nil {
		return nil, err
	}

	return &oggPage{
		headerType:   headerType,
		segmentTable: segmentTable,
		data:         pageData,
	}, nil
}

func collectOggPackets(file *os.File, maxPackets, maxPages int) ([][]byte, error) {
	const maxPacketSize = 10 * 1024 * 1024
	var packets [][]byte
	var cur []byte
	skipPacket := false

	for pageNum := 0; pageNum < maxPages && len(packets) < maxPackets; pageNum++ {
		page, err := readOggPageWithHeader(file)
		if err != nil {
			if len(packets) > 0 {
				return packets, nil
			}
			return nil, err
		}

		if page.headerType&0x01 == 0 && len(cur) > 0 {
			cur = nil
			skipPacket = false
		}

		offset := 0
		for _, seg := range page.segmentTable {
			segLen := int(seg)
			if offset+segLen > len(page.data) {
				return packets, fmt.Errorf("invalid ogg segment size")
			}

			if skipPacket {
				offset += segLen
				if segLen < 255 {
					skipPacket = false
				}
				continue
			}

			if len(cur)+segLen > maxPacketSize {
				cur = nil
				skipPacket = true
				offset += segLen
				if segLen < 255 {
					skipPacket = false
				}
				continue
			}

			cur = append(cur, page.data[offset:offset+segLen]...)
			offset += segLen

			if segLen < 255 {
				if len(cur) > 0 {
					packets = append(packets, cur)
				}
				cur = nil
				if len(packets) >= maxPackets {
					return packets, nil
				}
			}
		}
	}

	return packets, nil
}

type oggStreamType int

const (
	oggStreamUnknown oggStreamType = iota
	oggStreamOpus
	oggStreamVorbis
)

func detectOggStreamType(packets [][]byte) oggStreamType {
	for _, p := range packets {
		if len(p) >= 8 && string(p[0:8]) == "OpusHead" {
			return oggStreamOpus
		}
		if len(p) > 7 && p[0] == 0x01 && string(p[1:7]) == "vorbis" {
			return oggStreamVorbis
		}
	}
	return oggStreamUnknown
}

func parseVorbisComments(data []byte, metadata *AudioMetadata) {
	if len(data) < 4 {
		return
	}

	reader := bytes.NewReader(data)

	// Read vendor string length
	var vendorLen uint32
	if err := binary.Read(reader, binary.LittleEndian, &vendorLen); err != nil {
		return
	}

	if vendorLen > uint32(len(data)-4) {
		return
	}
	vendor := make([]byte, vendorLen)
	if _, err := reader.Read(vendor); err != nil {
		return
	}

	var commentCount uint32
	if err := binary.Read(reader, binary.LittleEndian, &commentCount); err != nil {
		return
	}

	for i := uint32(0); i < commentCount && i < 100; i++ {
		var commentLen uint32
		if err := binary.Read(reader, binary.LittleEndian, &commentLen); err != nil {
			break
		}

		remaining := uint32(reader.Len())
		if commentLen > remaining {
			break
		}
		// Large comment entries are typically METADATA_BLOCK_PICTURE.
		// Skip them so we can continue parsing normal text tags after/before.
		if commentLen > 512*1024 {
			reader.Seek(int64(commentLen), io.SeekCurrent)
			continue
		}

		comment := make([]byte, commentLen)
		if _, err := reader.Read(comment); err != nil {
			break
		}

		parts := strings.SplitN(string(comment), "=", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.ToUpper(parts[0])
		value := parts[1]

		switch key {
		case "TITLE":
			metadata.Title = value
		case "ARTIST":
			metadata.Artist = value
		case "ALBUMARTIST", "ALBUM_ARTIST", "ALBUM ARTIST":
			metadata.AlbumArtist = value
		case "ALBUM":
			metadata.Album = value
		case "DATE", "YEAR":
			metadata.Date = value
			if len(value) >= 4 {
				metadata.Year = value[:4]
			}
		case "GENRE":
			metadata.Genre = value
		case "TRACKNUMBER", "TRACK":
			metadata.TrackNumber = parseTrackNumber(value)
		case "DISCNUMBER", "DISC":
			metadata.DiscNumber = parseTrackNumber(value)
		case "ISRC":
			metadata.ISRC = value
		case "COMPOSER":
			metadata.Composer = value
		case "COMMENT", "DESCRIPTION":
			metadata.Comment = value
		case "LYRICS", "UNSYNCEDLYRICS":
			if metadata.Lyrics == "" {
				metadata.Lyrics = value
			}
		case "ORGANIZATION", "LABEL", "PUBLISHER":
			metadata.Label = value
		case "COPYRIGHT":
			metadata.Copyright = value
		}
	}
}

func GetOggQuality(filePath string) (*OggQuality, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	quality := &OggQuality{}
	isOpus := false

	packets, err := collectOggPackets(file, 5, 10)
	if err != nil && len(packets) == 0 {
		return nil, err
	}

	streamType := detectOggStreamType(packets)
	if streamType == oggStreamUnknown {
		if strings.HasSuffix(strings.ToLower(filePath), ".opus") {
			streamType = oggStreamOpus
		} else {
			streamType = oggStreamVorbis
		}
	}

	if streamType == oggStreamOpus {
		isOpus = true
		for _, pkt := range packets {
			if len(pkt) >= 19 && string(pkt[0:8]) == "OpusHead" {
				quality.SampleRate = int(binary.LittleEndian.Uint32(pkt[12:16]))
				if quality.SampleRate == 0 {
					quality.SampleRate = 48000
				}
				quality.BitDepth = 16
				break
			}
		}
	} else {
		for _, pkt := range packets {
			if len(pkt) > 29 && pkt[0] == 0x01 && string(pkt[1:7]) == "vorbis" {
				quality.SampleRate = int(binary.LittleEndian.Uint32(pkt[12:16]))
				quality.BitDepth = 16
				break
			}
		}
	}

	stat, err := file.Stat()
	if err == nil {
		// Very rough duration estimate based on file size
		// Assume ~128kbps average for Opus, ~160kbps for Vorbis
		avgBitrate := 128000
		if !isOpus {
			avgBitrate = 160000
		}
		quality.Duration = int(stat.Size() * 8 / int64(avgBitrate))
	}

	return quality, nil
}

// =============================================================================
// ID3v1 Genre List
// =============================================================================

var id3v1Genres = []string{
	"Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge",
	"Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B",
	"Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska",
	"Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient",
	"Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical",
	"Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel",
	"Noise", "AlternRock", "Bass", "Soul", "Punk", "Space", "Meditative",
	"Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic",
	"Darkwave", "Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance",
	"Dream", "Southern Rock", "Comedy", "Cult", "Gangsta", "Top 40",
	"Christian Rap", "Pop/Funk", "Jungle", "Native American", "Cabaret",
	"New Wave", "Psychedelic", "Rave", "Showtunes", "Trailer", "Lo-Fi",
	"Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical",
	"Rock & Roll", "Hard Rock", "Folk", "Folk-Rock", "National Folk",
	"Swing", "Fast Fusion", "Bebop", "Latin", "Revival", "Celtic",
	"Bluegrass", "Avantgarde", "Gothic Rock", "Progressive Rock",
	"Psychedelic Rock", "Symphonic Rock", "Slow Rock", "Big Band",
	"Chorus", "Easy Listening", "Acoustic", "Humour", "Speech", "Chanson",
	"Opera", "Chamber Music", "Sonata", "Symphony", "Booty Bass", "Primus",
	"Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba",
	"Folklore", "Ballad", "Power Ballad", "Rhythmic Soul", "Freestyle",
	"Duet", "Punk Rock", "Drum Solo", "A capella", "Euro-House",
	"Dance Hall", "Goa", "Drum & Bass", "Club-House", "Hardcore",
	"Terror", "Indie", "BritPop", "Negerpunk", "Polsk Punk", "Beat",
	"Christian Gangsta Rap", "Heavy Metal", "Black Metal", "Crossover",
	"Contemporary Christian", "Christian Rock", "Merengue", "Salsa",
	"Thrash Metal", "Anime", "J-Pop", "Synthpop",
}

// =============================================================================
// Cover Art Extraction
// =============================================================================

func extractMP3CoverArt(filePath string) ([]byte, string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, "", err
	}
	defer file.Close()

	header := make([]byte, 10)
	if _, err := io.ReadFull(file, header); err != nil {
		return nil, "", err
	}

	if string(header[0:3]) != "ID3" {
		return nil, "", fmt.Errorf("no ID3v2 header")
	}

	majorVersion := header[3]
	size := int(header[6])<<21 | int(header[7])<<14 | int(header[8])<<7 | int(header[9])

	tagData := make([]byte, size)
	if _, err := io.ReadFull(file, tagData); err != nil {
		return nil, "", err
	}

	// Parse frames looking for APIC (Attached Picture)
	pos := 0
	var frameIDLen, headerLen int
	if majorVersion == 2 {
		frameIDLen = 3
		headerLen = 6
	} else {
		frameIDLen = 4
		headerLen = 10
	}

	for pos+headerLen < len(tagData) {
		frameID := string(tagData[pos : pos+frameIDLen])
		if frameID[0] == 0 {
			break
		}

		var frameSize int
		switch majorVersion {
		case 2:
			frameSize = int(tagData[pos+3])<<16 | int(tagData[pos+4])<<8 | int(tagData[pos+5])
		case 4:
			frameSize = int(tagData[pos+4])<<21 | int(tagData[pos+5])<<14 | int(tagData[pos+6])<<7 | int(tagData[pos+7])
		default:
			frameSize = int(tagData[pos+4])<<24 | int(tagData[pos+5])<<16 | int(tagData[pos+6])<<8 | int(tagData[pos+7])
		}

		if frameSize <= 0 || pos+headerLen+frameSize > len(tagData) {
			break
		}

		// Check for APIC (ID3v2.3/2.4) or PIC (ID3v2.2)
		if (frameIDLen == 4 && frameID == "APIC") || (frameIDLen == 3 && frameID == "PIC") {
			frameData := tagData[pos+headerLen : pos+headerLen+frameSize]
			imageData, mimeType := parseAPICFrame(frameData, majorVersion)
			if len(imageData) > 0 {
				return imageData, mimeType, nil
			}
		}

		pos += headerLen + frameSize
	}

	return nil, "", fmt.Errorf("no cover art found")
}

func parseAPICFrame(data []byte, version byte) ([]byte, string) {
	if len(data) < 4 {
		return nil, ""
	}

	pos := 0
	encoding := data[pos]
	pos++

	var mimeType string
	if version == 2 {
		if pos+3 > len(data) {
			return nil, ""
		}
		format := string(data[pos : pos+3])
		pos += 3
		switch format {
		case "JPG":
			mimeType = "image/jpeg"
		case "PNG":
			mimeType = "image/png"
		default:
			mimeType = "image/jpeg"
		}
	} else {
		end := pos
		for end < len(data) && data[end] != 0 {
			end++
		}
		mimeType = string(data[pos:end])
		pos = end + 1
	}

	if pos >= len(data) {
		return nil, ""
	}

	pos++

	if encoding == 0 || encoding == 3 {
		for pos < len(data) && data[pos] != 0 {
			pos++
		}
		pos++
	} else {
		for pos+1 < len(data) {
			if data[pos] == 0 && data[pos+1] == 0 {
				pos += 2
				break
			}
			pos++
		}
	}

	if pos >= len(data) {
		return nil, ""
	}

	return data[pos:], mimeType
}

func extractOggCoverArt(filePath string) ([]byte, string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, "", err
	}
	defer file.Close()

	packets, err := collectOggPackets(file, 30, 80)
	if err != nil && len(packets) == 0 {
		return nil, "", err
	}

	streamType := detectOggStreamType(packets)
	for _, pkt := range packets {
		var comments []byte
		if streamType == oggStreamOpus {
			if len(pkt) > 8 && string(pkt[0:8]) == "OpusTags" {
				comments = pkt[8:]
			}
		} else {
			if len(pkt) > 7 && pkt[0] == 0x03 && string(pkt[1:7]) == "vorbis" {
				comments = pkt[7:]
			}
		}
		if len(comments) == 0 && streamType == oggStreamUnknown {
			if len(pkt) > 8 && string(pkt[0:8]) == "OpusTags" {
				comments = pkt[8:]
			} else if len(pkt) > 7 && pkt[0] == 0x03 && string(pkt[1:7]) == "vorbis" {
				comments = pkt[7:]
			}
		}

		if len(comments) > 0 {
			imageData, mimeType := extractPictureFromVorbisComments(comments)
			if len(imageData) > 0 {
				return imageData, mimeType, nil
			}
		}
	}

	return nil, "", fmt.Errorf("no cover art found")
}

func extractPictureFromVorbisComments(data []byte) ([]byte, string) {
	if len(data) < 8 {
		return nil, ""
	}

	reader := bytes.NewReader(data)

	var vendorLen uint32
	if err := binary.Read(reader, binary.LittleEndian, &vendorLen); err != nil {
		return nil, ""
	}
	if vendorLen > uint32(len(data)-4) {
		return nil, ""
	}
	reader.Seek(int64(vendorLen), io.SeekCurrent)

	var commentCount uint32
	if err := binary.Read(reader, binary.LittleEndian, &commentCount); err != nil {
		return nil, ""
	}

	for i := uint32(0); i < commentCount && i < 100; i++ {
		var commentLen uint32
		if err := binary.Read(reader, binary.LittleEndian, &commentLen); err != nil {
			break
		}
		if commentLen > 10000000 {
			break
		}

		comment := make([]byte, commentLen)
		if _, err := reader.Read(comment); err != nil {
			break
		}

		key := "METADATA_BLOCK_PICTURE="
		if len(comment) > len(key) && strings.ToUpper(string(comment[:len(key)])) == key {
			b64Data := comment[len(key):]
			decoded := make([]byte, base64StdDecodeLen(len(b64Data)))
			n, err := base64StdDecode(decoded, b64Data)
			if err != nil {
				continue
			}
			decoded = decoded[:n]

			imageData, mimeType := parseFLACPictureBlock(decoded)
			if len(imageData) > 0 {
				return imageData, mimeType
			}
		}
	}

	return nil, ""
}

func parseFLACPictureBlock(data []byte) ([]byte, string) {
	if len(data) < 32 {
		return nil, ""
	}

	reader := bytes.NewReader(data)

	var pictureType uint32
	binary.Read(reader, binary.BigEndian, &pictureType)

	var mimeLen uint32
	binary.Read(reader, binary.BigEndian, &mimeLen)
	if mimeLen > 256 {
		return nil, ""
	}

	mimeBytes := make([]byte, mimeLen)
	reader.Read(mimeBytes)
	mimeType := string(mimeBytes)

	var descLen uint32
	binary.Read(reader, binary.BigEndian, &descLen)
	if descLen > 10000 {
		return nil, ""
	}

	reader.Seek(int64(descLen), io.SeekCurrent)

	reader.Seek(16, io.SeekCurrent)

	var dataLen uint32
	binary.Read(reader, binary.BigEndian, &dataLen)
	if dataLen > 10000000 {
		return nil, ""
	}

	imageData := make([]byte, dataLen)
	reader.Read(imageData)

	return imageData, mimeType
}

func base64StdDecodeLen(n int) int {
	return n * 6 / 8
}

func base64StdDecode(dst, src []byte) (int, error) {
	const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

	decodeMap := make([]byte, 256)
	for i := range decodeMap {
		decodeMap[i] = 0xFF
	}
	for i := 0; i < len(alphabet); i++ {
		decodeMap[alphabet[i]] = byte(i)
	}

	si, di := 0, 0
	for si < len(src) {
		for si < len(src) && (src[si] == '\n' || src[si] == '\r' || src[si] == ' ' || src[si] == '\t') {
			si++
		}
		if si >= len(src) {
			break
		}

		var vals [4]byte
		var valCount int
		for valCount < 4 && si < len(src) {
			c := src[si]
			si++
			if c == '=' {
				vals[valCount] = 0
				valCount++
			} else if c == '\n' || c == '\r' || c == ' ' || c == '\t' {
				continue
			} else if decodeMap[c] != 0xFF {
				vals[valCount] = decodeMap[c]
				valCount++
			}
		}

		if valCount < 2 {
			break
		}

		if di < len(dst) {
			dst[di] = vals[0]<<2 | vals[1]>>4
			di++
		}
		if valCount >= 3 && di < len(dst) {
			dst[di] = vals[1]<<4 | vals[2]>>2
			di++
		}
		if valCount >= 4 && di < len(dst) {
			dst[di] = vals[2]<<6 | vals[3]
			di++
		}
	}

	return di, nil
}

func extractAnyCoverArt(filePath string) ([]byte, string, error) {
	ext := strings.ToLower(filepath.Ext(filePath))

	switch ext {
	case ".flac":
		data, err := ExtractCoverArt(filePath)
		if err != nil {
			return nil, "", err
		}
		mimeType := "image/jpeg"
		if len(data) > 8 && string(data[1:4]) == "PNG" {
			mimeType = "image/png"
		}
		return data, mimeType, nil

	case ".mp3":
		return extractMP3CoverArt(filePath)

	case ".opus", ".ogg":
		return extractOggCoverArt(filePath)

	case ".m4a":
		return nil, "", fmt.Errorf("M4A cover extraction not yet supported")

	default:
		return nil, "", fmt.Errorf("unsupported format: %s", ext)
	}
}

func SaveCoverToCache(filePath, cacheDir string) (string, error) {
	cacheKey := filePath
	if stat, err := os.Stat(filePath); err == nil {
		cacheKey = fmt.Sprintf("%s|%d|%d", filePath, stat.Size(), stat.ModTime().UnixNano())
	}
	hash := hashString(cacheKey)

	jpgPath := filepath.Join(cacheDir, fmt.Sprintf("cover_%x.jpg", hash))
	pngPath := filepath.Join(cacheDir, fmt.Sprintf("cover_%x.png", hash))

	if _, err := os.Stat(jpgPath); err == nil {
		return jpgPath, nil
	}
	if _, err := os.Stat(pngPath); err == nil {
		return pngPath, nil
	}

	imageData, mimeType, err := extractAnyCoverArt(filePath)
	if err != nil {
		return "", err
	}

	if err := os.MkdirAll(cacheDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create cache dir: %w", err)
	}

	var cachePath string
	if strings.Contains(mimeType, "png") {
		cachePath = pngPath
	} else {
		cachePath = jpgPath
	}

	if err := os.WriteFile(cachePath, imageData, 0644); err != nil {
		return "", fmt.Errorf("failed to write cover: %w", err)
	}

	return cachePath, nil
}
