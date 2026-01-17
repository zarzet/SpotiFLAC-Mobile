package gobackend

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/go-flac/flacpicture"
	"github.com/go-flac/flacvorbis"
	"github.com/go-flac/go-flac"
)

// Metadata represents track metadata for embedding
type Metadata struct {
	Title       string
	Artist      string
	Album       string
	AlbumArtist string
	Date        string
	TrackNumber int
	TotalTracks int
	DiscNumber  int
	ISRC        string
	Description string
	Lyrics      string
}

// EmbedMetadata embeds metadata into a FLAC file
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

	setComment(cmt, "TITLE", metadata.Title)
	setComment(cmt, "ARTIST", metadata.Artist)
	setComment(cmt, "ALBUM", metadata.Album)
	setComment(cmt, "ALBUMARTIST", metadata.AlbumArtist)
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

				picture, err := flacpicture.NewFromImageData(
					flacpicture.PictureTypeFrontCover,
					"Front Cover",
					coverData,
					"image/jpeg",
				)
				if err != nil {
					fmt.Printf("[Metadata] Warning: Failed to create picture block: %v\n", err)
				} else {
					picBlock := picture.Marshal()
					f.Meta = append(f.Meta, &picBlock)
					fmt.Printf("[Metadata] Cover art embedded successfully (%d bytes)\n", len(coverData))
				}
			}
		} else {
			fmt.Printf("[Metadata] Warning: Cover file does not exist: %s\n", coverPath)
		}
	}

	return f.Save(filePath)
}

// EmbedMetadataWithCoverData embeds metadata into a FLAC file with cover data as bytes
// This avoids file permission issues on Android by not requiring a temp file
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

	setComment(cmt, "TITLE", metadata.Title)
	setComment(cmt, "ARTIST", metadata.Artist)
	setComment(cmt, "ALBUM", metadata.Album)
	setComment(cmt, "ALBUMARTIST", metadata.AlbumArtist)
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

		picture, err := flacpicture.NewFromImageData(
			flacpicture.PictureTypeFrontCover,
			"Front Cover",
			coverData,
			"image/jpeg",
		)
		if err != nil {
			fmt.Printf("[Metadata] Warning: Failed to create picture block: %v\n", err)
		} else {
			picBlock := picture.Marshal()
			f.Meta = append(f.Meta, &picBlock)
			fmt.Printf("[Metadata] Cover art embedded successfully (%d bytes)\n", len(coverData))
		}
	}

	return f.Save(filePath)
}

// ReadMetadata reads metadata from a FLAC file
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
			metadata.Artist = getComment(cmt, "ARTIST")
			metadata.Album = getComment(cmt, "ALBUM")
			metadata.AlbumArtist = getComment(cmt, "ALBUMARTIST")
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

			break
		}
	}

	return metadata, nil
}

func setComment(cmt *flacvorbis.MetaDataBlockVorbisComment, key, value string) {
	if value == "" {
		return
	}
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
	cmt.Comments = append(cmt.Comments, key+"="+value)
}

func getComment(cmt *flacvorbis.MetaDataBlockVorbisComment, key string) string {
	keyUpper := strings.ToUpper(key) + "="
	for _, comment := range cmt.Comments {
		if len(comment) > len(key) {
			commentUpper := strings.ToUpper(comment[:len(key)+1])
			if commentUpper == keyUpper {
				return comment[len(key)+1:]
			}
		}
	}
	return ""
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// EmbedLyrics embeds lyrics into a FLAC file as a separate operation
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

// ExtractLyrics extracts embedded lyrics from a FLAC file
func ExtractLyrics(filePath string) (string, error) {
	f, err := flac.ParseFile(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to parse FLAC file: %w", err)
	}

	for _, meta := range f.Meta {
		if meta.Type == flac.VorbisComment {
			cmt, err := flacvorbis.ParseFromMetaDataBlock(*meta)
			if err != nil {
				continue
			}

			lyrics, err := cmt.Get("LYRICS")
			if err == nil && len(lyrics) > 0 && lyrics[0] != "" {
				return lyrics[0], nil
			}

			lyrics, err = cmt.Get("UNSYNCEDLYRICS")
			if err == nil && len(lyrics) > 0 && lyrics[0] != "" {
				return lyrics[0], nil
			}
		}
	}

	return "", fmt.Errorf("no lyrics found in file")
}

// AudioQuality represents audio quality info from a FLAC file
type AudioQuality struct {
	BitDepth     int   `json:"bit_depth"`
	SampleRate   int   `json:"sample_rate"`
	TotalSamples int64 `json:"total_samples"`
}

// GetAudioQuality reads bit depth and sample rate from a FLAC file's StreamInfo block
// FLAC StreamInfo is always the first metadata block after the 4-byte "fLaC" marker
// For M4A files, it delegates to GetM4AQuality
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

// ========================================
// M4A (MP4/AAC) Metadata Embedding
// ========================================

// EmbedM4AMetadata embeds metadata into an M4A file using iTunes-style atoms
func EmbedM4AMetadata(filePath string, metadata Metadata, coverData []byte) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read M4A file: %w", err)
	}

	moovPos := findAtom(data, "moov", 0)
	if moovPos < 0 {
		return fmt.Errorf("moov atom not found in M4A file")
	}

	moovSize := int(uint32(data[moovPos])<<24 | uint32(data[moovPos+1])<<16 | uint32(data[moovPos+2])<<8 | uint32(data[moovPos+3]))
	udtaPos := findAtom(data, "udta", moovPos+8)

	metaAtom := buildMetaAtom(metadata, coverData)

	var newData []byte
	if udtaPos >= 0 && udtaPos < moovPos+moovSize {
		udtaSize := int(uint32(data[udtaPos])<<24 | uint32(data[udtaPos+1])<<16 | uint32(data[udtaPos+2])<<8 | uint32(data[udtaPos+3]))
		metaPos := findAtom(data, "meta", udtaPos+8)

		if metaPos >= 0 && metaPos < udtaPos+udtaSize {
			metaSize := int(uint32(data[metaPos])<<24 | uint32(data[metaPos+1])<<16 | uint32(data[metaPos+2])<<8 | uint32(data[metaPos+3]))
			newData = append(newData, data[:metaPos]...)
			newData = append(newData, metaAtom...)
			newData = append(newData, data[metaPos+metaSize:]...)
		} else {
			newUdtaContent := append(data[udtaPos+8:udtaPos+udtaSize], metaAtom...)
			newUdtaSize := 8 + len(newUdtaContent)
			newUdta := make([]byte, 4)
			newUdta[0] = byte(newUdtaSize >> 24)
			newUdta[1] = byte(newUdtaSize >> 16)
			newUdta[2] = byte(newUdtaSize >> 8)
			newUdta[3] = byte(newUdtaSize)
			newUdta = append(newUdta, []byte("udta")...)
			newUdta = append(newUdta, newUdtaContent...)

			newData = append(newData, data[:udtaPos]...)
			newData = append(newData, newUdta...)
			newData = append(newData, data[udtaPos+udtaSize:]...)
		}
	} else {
		udtaContent := metaAtom
		udtaSize := 8 + len(udtaContent)
		newUdta := make([]byte, 4)
		newUdta[0] = byte(udtaSize >> 24)
		newUdta[1] = byte(udtaSize >> 16)
		newUdta[2] = byte(udtaSize >> 8)
		newUdta[3] = byte(udtaSize)
		newUdta = append(newUdta, []byte("udta")...)
		newUdta = append(newUdta, udtaContent...)

		insertPos := moovPos + moovSize
		newData = append(newData, data[:insertPos]...)
		newData = append(newData, newUdta...)
		newData = append(newData, data[insertPos:]...)
	}

	newMoovSize := moovSize + len(newData) - len(data)
	newData[moovPos] = byte(newMoovSize >> 24)
	newData[moovPos+1] = byte(newMoovSize >> 16)
	newData[moovPos+2] = byte(newMoovSize >> 8)
	newData[moovPos+3] = byte(newMoovSize)

	if err := os.WriteFile(filePath, newData, 0644); err != nil {
		return fmt.Errorf("failed to write M4A file: %w", err)
	}

	fmt.Printf("[M4A] Metadata embedded successfully\n")
	return nil
}

// findAtom finds an atom by name starting from offset
func findAtom(data []byte, name string, offset int) int {
	for i := offset; i < len(data)-8; {
		size := int(uint32(data[i])<<24 | uint32(data[i+1])<<16 | uint32(data[i+2])<<8 | uint32(data[i+3]))
		if size < 8 {
			break
		}
		atomName := string(data[i+4 : i+8])
		if atomName == name {
			return i
		}
		i += size
	}
	return -1
}

// buildMetaAtom builds a complete meta atom with ilst containing metadata
func buildMetaAtom(metadata Metadata, coverData []byte) []byte {
	var ilst []byte

	if metadata.Title != "" {
		ilst = append(ilst, buildTextAtom("©nam", metadata.Title)...)
	}

	if metadata.Artist != "" {
		ilst = append(ilst, buildTextAtom("©ART", metadata.Artist)...)
	}

	if metadata.Album != "" {
		ilst = append(ilst, buildTextAtom("©alb", metadata.Album)...)
	}

	if metadata.AlbumArtist != "" {
		ilst = append(ilst, buildTextAtom("aART", metadata.AlbumArtist)...)
	}

	if metadata.Date != "" {
		ilst = append(ilst, buildTextAtom("©day", metadata.Date)...)
	}

	if metadata.TrackNumber > 0 {
		ilst = append(ilst, buildTrackNumberAtom(metadata.TrackNumber, metadata.TotalTracks)...)
	}

	if metadata.DiscNumber > 0 {
		ilst = append(ilst, buildDiscNumberAtom(metadata.DiscNumber, 0)...)
	}

	if metadata.Lyrics != "" {
		ilst = append(ilst, buildTextAtom("©lyr", metadata.Lyrics)...)
	}

	if len(coverData) > 0 {
		ilst = append(ilst, buildCoverAtom(coverData)...)
	}

	ilstSize := 8 + len(ilst)
	ilstAtom := make([]byte, 4)
	ilstAtom[0] = byte(ilstSize >> 24)
	ilstAtom[1] = byte(ilstSize >> 16)
	ilstAtom[2] = byte(ilstSize >> 8)
	ilstAtom[3] = byte(ilstSize)
	ilstAtom = append(ilstAtom, []byte("ilst")...)
	ilstAtom = append(ilstAtom, ilst...)

	hdlr := []byte{
		0, 0, 0, 33, // size = 33
		'h', 'd', 'l', 'r',
		0, 0, 0, 0, // version + flags
		0, 0, 0, 0, // predefined
		'm', 'd', 'i', 'r', // handler type
		'a', 'p', 'p', 'l', // manufacturer
		0, 0, 0, 0, // component flags
		0, 0, 0, 0, // component flags mask
		0, // null terminator
	}

	metaContent := append([]byte{0, 0, 0, 0}, hdlr...) // version + flags + hdlr
	metaContent = append(metaContent, ilstAtom...)

	metaSize := 8 + len(metaContent)
	metaAtom := make([]byte, 4)
	metaAtom[0] = byte(metaSize >> 24)
	metaAtom[1] = byte(metaSize >> 16)
	metaAtom[2] = byte(metaSize >> 8)
	metaAtom[3] = byte(metaSize)
	metaAtom = append(metaAtom, []byte("meta")...)
	metaAtom = append(metaAtom, metaContent...)

	return metaAtom
}

// buildTextAtom builds a text metadata atom (©nam, ©ART, etc.)
func buildTextAtom(name, value string) []byte {
	valueBytes := []byte(value)

	dataSize := 16 + len(valueBytes)
	dataAtom := make([]byte, 4)
	dataAtom[0] = byte(dataSize >> 24)
	dataAtom[1] = byte(dataSize >> 16)
	dataAtom[2] = byte(dataSize >> 8)
	dataAtom[3] = byte(dataSize)
	dataAtom = append(dataAtom, []byte("data")...)
	dataAtom = append(dataAtom, 0, 0, 0, 1) // type = UTF-8
	dataAtom = append(dataAtom, 0, 0, 0, 0) // locale
	dataAtom = append(dataAtom, valueBytes...)

	atomSize := 8 + len(dataAtom)
	atom := make([]byte, 4)
	atom[0] = byte(atomSize >> 24)
	atom[1] = byte(atomSize >> 16)
	atom[2] = byte(atomSize >> 8)
	atom[3] = byte(atomSize)
	atom = append(atom, []byte(name)...)
	atom = append(atom, dataAtom...)

	return atom
}

// buildTrackNumberAtom builds trkn atom
func buildTrackNumberAtom(track, total int) []byte {
	dataAtom := []byte{
		0, 0, 0, 24, // size
		'd', 'a', 't', 'a',
		0, 0, 0, 0, // type = implicit
		0, 0, 0, 0, // locale
		0, 0, // padding
		byte(track >> 8), byte(track), // track number
		byte(total >> 8), byte(total), // total tracks
		0, 0, // padding
	}

	atomSize := 8 + len(dataAtom)
	atom := make([]byte, 4)
	atom[0] = byte(atomSize >> 24)
	atom[1] = byte(atomSize >> 16)
	atom[2] = byte(atomSize >> 8)
	atom[3] = byte(atomSize)
	atom = append(atom, []byte("trkn")...)
	atom = append(atom, dataAtom...)

	return atom
}

// buildDiscNumberAtom builds disk atom
func buildDiscNumberAtom(disc, total int) []byte {
	dataAtom := []byte{
		0, 0, 0, 22, // size
		'd', 'a', 't', 'a',
		0, 0, 0, 0, // type = implicit
		0, 0, 0, 0, // locale
		0, 0, // padding
		byte(disc >> 8), byte(disc), // disc number
		byte(total >> 8), byte(total), // total discs
	}

	atomSize := 8 + len(dataAtom)
	atom := make([]byte, 4)
	atom[0] = byte(atomSize >> 24)
	atom[1] = byte(atomSize >> 16)
	atom[2] = byte(atomSize >> 8)
	atom[3] = byte(atomSize)
	atom = append(atom, []byte("disk")...)
	atom = append(atom, dataAtom...)

	return atom
}

// buildCoverAtom builds covr atom with image data
func buildCoverAtom(coverData []byte) []byte {
	imageType := byte(13) // default JPEG
	if len(coverData) > 8 && coverData[0] == 0x89 && coverData[1] == 'P' && coverData[2] == 'N' && coverData[3] == 'G' {
		imageType = 14 // PNG
	}

	dataSize := 16 + len(coverData)
	dataAtom := make([]byte, 4)
	dataAtom[0] = byte(dataSize >> 24)
	dataAtom[1] = byte(dataSize >> 16)
	dataAtom[2] = byte(dataSize >> 8)
	dataAtom[3] = byte(dataSize)
	dataAtom = append(dataAtom, []byte("data")...)
	dataAtom = append(dataAtom, 0, 0, 0, imageType) // type = JPEG or PNG
	dataAtom = append(dataAtom, 0, 0, 0, 0)         // locale
	dataAtom = append(dataAtom, coverData...)

	atomSize := 8 + len(dataAtom)
	atom := make([]byte, 4)
	atom[0] = byte(atomSize >> 24)
	atom[1] = byte(atomSize >> 16)
	atom[2] = byte(atomSize >> 8)
	atom[3] = byte(atomSize)
	atom = append(atom, []byte("covr")...)
	atom = append(atom, dataAtom...)

	return atom
}

// GetM4AQuality reads audio quality from M4A file
func GetM4AQuality(filePath string) (AudioQuality, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return AudioQuality{}, fmt.Errorf("failed to read M4A file: %w", err)
	}

	moovPos := findAtom(data, "moov", 0)
	if moovPos < 0 {
		return AudioQuality{}, fmt.Errorf("moov atom not found")
	}

	for i := moovPos; i < len(data)-20; i++ {
		if string(data[i:i+4]) == "mp4a" || string(data[i:i+4]) == "alac" {
			if i+24 < len(data) {
				sampleRate := int(data[i+22])<<8 | int(data[i+23])
				bitDepth := 16
				if string(data[i:i+4]) == "alac" {
					bitDepth = 24
				}
				return AudioQuality{BitDepth: bitDepth, SampleRate: sampleRate}, nil
			}
		}
	}

	return AudioQuality{}, fmt.Errorf("audio info not found in M4A file")
}
