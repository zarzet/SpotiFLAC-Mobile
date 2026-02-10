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
	"strconv"
	"strings"

	"github.com/go-flac/flacpicture/v2"
	"github.com/go-flac/flacvorbis/v2"
	"github.com/go-flac/go-flac/v2"
)

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
	Genre       string
	Label       string
	Copyright   string
	Composer    string
	Comment     string
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

			metadata.Genre = getComment(cmt, "GENRE")
			metadata.Label = getComment(cmt, "ORGANIZATION")
			metadata.Copyright = getComment(cmt, "COPYRIGHT")
			metadata.Composer = getComment(cmt, "COMPOSER")
			metadata.Comment = getComment(cmt, "COMMENT")

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
		return extractLyricsFromFlac(filePath)
	}

	if strings.HasSuffix(lower, ".mp3") {
		meta, err := ReadID3Tags(filePath)
		if err != nil || meta == nil {
			return "", fmt.Errorf("no lyrics found in file")
		}
		if strings.TrimSpace(meta.Lyrics) != "" {
			return meta.Lyrics, nil
		}
		if looksLikeEmbeddedLyrics(meta.Comment) {
			return meta.Comment, nil
		}
		return "", fmt.Errorf("no lyrics found in file")
	}

	if strings.HasSuffix(lower, ".opus") || strings.HasSuffix(lower, ".ogg") {
		meta, err := ReadOggVorbisComments(filePath)
		if err != nil || meta == nil {
			return "", fmt.Errorf("no lyrics found in file")
		}
		if strings.TrimSpace(meta.Lyrics) != "" {
			return meta.Lyrics, nil
		}
		if looksLikeEmbeddedLyrics(meta.Comment) {
			return meta.Comment, nil
		}
		return "", fmt.Errorf("no lyrics found in file")
	}

	return "", fmt.Errorf("unsupported file format for lyrics extraction")
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

	buf := make([]byte, 24)
	if _, err := f.ReadAt(buf, sampleOffset); err != nil {
		return AudioQuality{}, fmt.Errorf("failed to read audio sample entry: %w", err)
	}

	sampleRate := int(buf[22])<<8 | int(buf[23])
	bitDepth := 16
	if atomType == "alac" {
		bitDepth = 24
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
			if absolute+24 > fileSize {
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
