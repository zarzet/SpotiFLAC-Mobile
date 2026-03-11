package gobackend

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

// CueSheet represents a parsed .cue file
type CueSheet struct {
	// Album-level metadata
	Performer string     `json:"performer"`
	Title     string     `json:"title"`
	FileName  string     `json:"file_name"`
	FileType  string     `json:"file_type"` // WAVE, FLAC, MP3, AIFF, etc.
	Genre     string     `json:"genre,omitempty"`
	Date      string     `json:"date,omitempty"`
	Comment   string     `json:"comment,omitempty"`
	Composer  string     `json:"composer,omitempty"`
	Tracks    []CueTrack `json:"tracks"`
}

// CueTrack represents a single track in a cue sheet
type CueTrack struct {
	Number    int    `json:"number"`
	Title     string `json:"title"`
	Performer string `json:"performer"`
	ISRC      string `json:"isrc,omitempty"`
	Composer  string `json:"composer,omitempty"`
	// Index positions in seconds (fractional)
	StartTime float64 `json:"start_time"` // INDEX 01 in seconds
	PreGap    float64 `json:"pre_gap"`    // INDEX 00 in seconds (or -1 if not present)
}

// CueSplitInfo represents the information needed to split a CUE+audio file
type CueSplitInfo struct {
	CuePath   string          `json:"cue_path"`
	AudioPath string          `json:"audio_path"`
	Album     string          `json:"album"`
	Artist    string          `json:"artist"`
	Genre     string          `json:"genre,omitempty"`
	Date      string          `json:"date,omitempty"`
	Tracks    []CueSplitTrack `json:"tracks"`
}

// CueSplitTrack has the FFmpeg split parameters for a single track
type CueSplitTrack struct {
	Number   int     `json:"number"`
	Title    string  `json:"title"`
	Artist   string  `json:"artist"`
	ISRC     string  `json:"isrc,omitempty"`
	Composer string  `json:"composer,omitempty"`
	StartSec float64 `json:"start_sec"`
	EndSec   float64 `json:"end_sec"` // -1 means until end of file
}

var (
	reRemCommand = regexp.MustCompile(`^REM\s+(\S+)\s+(.+)$`)
	reQuoted     = regexp.MustCompile(`"([^"]*)"`)
)

// ParseCueFile parses a .cue file and returns a CueSheet
func ParseCueFile(cuePath string) (*CueSheet, error) {
	f, err := os.Open(cuePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open cue file: %w", err)
	}
	defer f.Close()

	sheet := &CueSheet{}
	var currentTrack *CueTrack

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		// Handle BOM at start of file
		if strings.HasPrefix(line, "\xef\xbb\xbf") {
			line = strings.TrimPrefix(line, "\xef\xbb\xbf")
			line = strings.TrimSpace(line)
		}

		upper := strings.ToUpper(line)

		// REM commands (album-level metadata)
		if strings.HasPrefix(upper, "REM ") {
			matches := reRemCommand.FindStringSubmatch(line)
			if len(matches) == 3 {
				key := strings.ToUpper(matches[1])
				value := unquoteCue(matches[2])
				switch key {
				case "GENRE":
					sheet.Genre = value
				case "DATE":
					sheet.Date = value
				case "COMMENT":
					sheet.Comment = value
				case "COMPOSER":
					if currentTrack != nil {
						currentTrack.Composer = value
					} else {
						sheet.Composer = value
					}
				}
			}
			continue
		}

		// PERFORMER
		if strings.HasPrefix(upper, "PERFORMER ") {
			value := unquoteCue(line[len("PERFORMER "):])
			if currentTrack != nil {
				currentTrack.Performer = value
			} else {
				sheet.Performer = value
			}
			continue
		}

		// TITLE
		if strings.HasPrefix(upper, "TITLE ") {
			value := unquoteCue(line[len("TITLE "):])
			if currentTrack != nil {
				currentTrack.Title = value
			} else {
				sheet.Title = value
			}
			continue
		}

		// FILE
		if strings.HasPrefix(upper, "FILE ") {
			rest := line[len("FILE "):]
			// Extract filename and type
			// Format: FILE "filename.flac" WAVE
			// or: FILE filename.flac WAVE
			fname, ftype := parseCueFileLine(rest)
			sheet.FileName = fname
			sheet.FileType = ftype
			continue
		}

		// TRACK
		if strings.HasPrefix(upper, "TRACK ") {
			// Save previous track
			if currentTrack != nil {
				sheet.Tracks = append(sheet.Tracks, *currentTrack)
			}

			parts := strings.Fields(line)
			trackNum := 0
			if len(parts) >= 2 {
				trackNum, _ = strconv.Atoi(parts[1])
			}

			currentTrack = &CueTrack{
				Number: trackNum,
				PreGap: -1,
			}
			continue
		}

		// INDEX
		if strings.HasPrefix(upper, "INDEX ") && currentTrack != nil {
			parts := strings.Fields(line)
			if len(parts) >= 3 {
				indexNum, _ := strconv.Atoi(parts[1])
				timeSec := parseCueTimestamp(parts[2])
				switch indexNum {
				case 0:
					currentTrack.PreGap = timeSec
				case 1:
					currentTrack.StartTime = timeSec
				}
			}
			continue
		}

		// ISRC
		if strings.HasPrefix(upper, "ISRC ") && currentTrack != nil {
			currentTrack.ISRC = strings.TrimSpace(line[len("ISRC "):])
			continue
		}

		// SONGWRITER (used as composer sometimes)
		if strings.HasPrefix(upper, "SONGWRITER ") {
			value := unquoteCue(line[len("SONGWRITER "):])
			if currentTrack != nil {
				currentTrack.Composer = value
			} else {
				sheet.Composer = value
			}
			continue
		}
	}

	// Don't forget the last track
	if currentTrack != nil {
		sheet.Tracks = append(sheet.Tracks, *currentTrack)
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("error reading cue file: %w", err)
	}

	if len(sheet.Tracks) == 0 {
		return nil, fmt.Errorf("no tracks found in cue file")
	}

	return sheet, nil
}

// parseCueTimestamp converts MM:SS:FF (frames at 75fps) to seconds
func parseCueTimestamp(ts string) float64 {
	parts := strings.Split(ts, ":")
	if len(parts) != 3 {
		return 0
	}

	minutes, _ := strconv.Atoi(parts[0])
	seconds, _ := strconv.Atoi(parts[1])
	frames, _ := strconv.Atoi(parts[2])

	return float64(minutes)*60 + float64(seconds) + float64(frames)/75.0
}

// formatCueTimestamp converts seconds to HH:MM:SS.mmm format for FFmpeg
func formatCueTimestamp(seconds float64) string {
	if seconds < 0 {
		return "0"
	}
	hours := int(seconds) / 3600
	mins := (int(seconds) % 3600) / 60
	secs := seconds - float64(hours*3600) - float64(mins*60)
	return fmt.Sprintf("%02d:%02d:%06.3f", hours, mins, secs)
}

// unquoteCue removes surrounding quotes from a CUE value
func unquoteCue(s string) string {
	s = strings.TrimSpace(s)
	if matches := reQuoted.FindStringSubmatch(s); len(matches) == 2 {
		return matches[1]
	}
	return s
}

// parseCueFileLine parses the FILE command's filename and type
func parseCueFileLine(rest string) (string, string) {
	rest = strings.TrimSpace(rest)

	var filename, ftype string

	if strings.HasPrefix(rest, "\"") {
		// Quoted filename
		endQuote := strings.Index(rest[1:], "\"")
		if endQuote >= 0 {
			filename = rest[1 : endQuote+1]
			remaining := strings.TrimSpace(rest[endQuote+2:])
			ftype = remaining
		} else {
			filename = rest
		}
	} else {
		// Unquoted filename - last word is the type
		parts := strings.Fields(rest)
		if len(parts) >= 2 {
			ftype = parts[len(parts)-1]
			filename = strings.Join(parts[:len(parts)-1], " ")
		} else if len(parts) == 1 {
			filename = parts[0]
		}
	}

	return filename, strings.TrimSpace(ftype)
}

// ResolveCueAudioPath finds the actual audio file referenced by a .cue sheet.
// It checks relative to the cue file's directory.
func ResolveCueAudioPath(cuePath string, cueFileName string) string {
	cueDir := filepath.Dir(cuePath)

	// 1. Try the exact filename from the .cue
	candidate := filepath.Join(cueDir, cueFileName)
	if _, err := os.Stat(candidate); err == nil {
		return candidate
	}

	// 2. Try common case variations
	baseName := strings.TrimSuffix(cueFileName, filepath.Ext(cueFileName))
	commonExts := []string{".flac", ".wav", ".ape", ".mp3", ".ogg", ".wv", ".m4a"}
	for _, ext := range commonExts {
		candidate = filepath.Join(cueDir, baseName+ext)
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
		// Try uppercase ext
		candidate = filepath.Join(cueDir, baseName+strings.ToUpper(ext))
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
	}

	// 3. Try to find any audio file with the same base name as the .cue file
	cueBase := strings.TrimSuffix(filepath.Base(cuePath), filepath.Ext(cuePath))
	for _, ext := range commonExts {
		candidate = filepath.Join(cueDir, cueBase+ext)
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
	}

	// 4. If there's only one audio file in the directory, use that
	entries, err := os.ReadDir(cueDir)
	if err == nil {
		audioExts := map[string]bool{
			".flac": true, ".wav": true, ".ape": true, ".mp3": true,
			".ogg": true, ".wv": true, ".m4a": true, ".aiff": true,
		}
		var audioFiles []string
		for _, entry := range entries {
			if entry.IsDir() {
				continue
			}
			ext := strings.ToLower(filepath.Ext(entry.Name()))
			if audioExts[ext] {
				audioFiles = append(audioFiles, filepath.Join(cueDir, entry.Name()))
			}
		}
		if len(audioFiles) == 1 {
			return audioFiles[0]
		}
	}

	return ""
}

// BuildCueSplitInfo creates the split information from a parsed CUE sheet.
// This is returned to the Dart side so FFmpeg can perform the splitting.
// audioDir, if non-empty, overrides the directory for audio file resolution.
func BuildCueSplitInfo(cuePath string, sheet *CueSheet, audioDir string) (*CueSplitInfo, error) {
	resolveDir := cuePath
	if audioDir != "" {
		// Create a virtual path in audioDir so ResolveCueAudioPath looks there
		resolveDir = filepath.Join(audioDir, filepath.Base(cuePath))
	}
	audioPath := ResolveCueAudioPath(resolveDir, sheet.FileName)
	if audioPath == "" {
		return nil, fmt.Errorf("audio file not found for cue sheet: %s (referenced: %s)", cuePath, sheet.FileName)
	}

	info := &CueSplitInfo{
		CuePath:   cuePath,
		AudioPath: audioPath,
		Album:     sheet.Title,
		Artist:    sheet.Performer,
		Genre:     sheet.Genre,
		Date:      sheet.Date,
	}

	for i, track := range sheet.Tracks {
		performer := track.Performer
		if performer == "" {
			performer = sheet.Performer
		}

		composer := track.Composer
		if composer == "" {
			composer = sheet.Composer
		}

		// End time is the start of the next track, or -1 for the last track
		endSec := float64(-1)
		if i+1 < len(sheet.Tracks) {
			nextTrack := sheet.Tracks[i+1]
			// Use pre-gap of next track if available, otherwise its start time
			if nextTrack.PreGap >= 0 {
				endSec = nextTrack.PreGap
			} else {
				endSec = nextTrack.StartTime
			}
		}

		info.Tracks = append(info.Tracks, CueSplitTrack{
			Number:   track.Number,
			Title:    track.Title,
			Artist:   performer,
			ISRC:     track.ISRC,
			Composer: composer,
			StartSec: track.StartTime,
			EndSec:   endSec,
		})
	}

	return info, nil
}

// ParseCueFileJSON parses a .cue file and returns JSON with split info.
// This is the main entry point called from Dart via the platform bridge.
// audioDir, if non-empty, overrides the directory used for resolving the
// referenced audio file (useful when the .cue was copied to a temp dir
// but the audio still lives in the original location, e.g. SAF).
func ParseCueFileJSON(cuePath string, audioDir string) (string, error) {
	sheet, err := ParseCueFile(cuePath)
	if err != nil {
		return "", fmt.Errorf("failed to parse cue file: %w", err)
	}

	info, err := BuildCueSplitInfo(cuePath, sheet, audioDir)
	if err != nil {
		return "", err
	}

	jsonBytes, err := json.Marshal(info)
	if err != nil {
		return "", fmt.Errorf("failed to marshal cue split info: %w", err)
	}

	return string(jsonBytes), nil
}

// ScanCueFileForLibrary parses a .cue file and returns multiple LibraryScanResult
// entries, one per track. This is used by the library scanner to populate the
// library with individual track entries from a single CUE+FLAC album.
func ScanCueFileForLibrary(cuePath string, scanTime string) ([]LibraryScanResult, error) {
	return scanCueFileForLibraryInternal(cuePath, "", "", 0, scanTime)
}

// ScanCueFileForLibraryExt is like ScanCueFileForLibrary but with extra parameters
// for SAF (Storage Access Framework) scenarios:
//   - audioDir: if non-empty, overrides the directory used to find the audio file
//   - virtualPathPrefix: if non-empty, used instead of cuePath as the base for
//     virtual file paths (e.g. a content:// URI). IDs are also based on this.
//   - fileModTime: if > 0, used as the FileModTime for all results instead of
//     stat-ing the cuePath on disk (useful when the real file lives behind SAF)
func ScanCueFileForLibraryExt(cuePath, audioDir, virtualPathPrefix string, fileModTime int64, scanTime string) ([]LibraryScanResult, error) {
	return scanCueFileForLibraryInternal(cuePath, audioDir, virtualPathPrefix, fileModTime, scanTime)
}

func scanCueFileForLibraryInternal(cuePath, audioDir, virtualPathPrefix string, fileModTime int64, scanTime string) ([]LibraryScanResult, error) {
	sheet, err := ParseCueFile(cuePath)
	if err != nil {
		return nil, err
	}

	// Resolve audio file — optionally in an overridden directory
	resolveBase := cuePath
	if audioDir != "" {
		resolveBase = filepath.Join(audioDir, filepath.Base(cuePath))
	}
	audioPath := ResolveCueAudioPath(resolveBase, sheet.FileName)
	if audioPath == "" {
		return nil, fmt.Errorf("audio file not found for cue: %s (referenced: %s)", cuePath, sheet.FileName)
	}

	// Try to get quality info from the audio file
	var bitDepth, sampleRate int
	var totalDurationSec float64
	audioExt := strings.ToLower(filepath.Ext(audioPath))
	switch audioExt {
	case ".flac":
		quality, qErr := GetAudioQuality(audioPath)
		if qErr == nil {
			bitDepth = quality.BitDepth
			sampleRate = quality.SampleRate
			if quality.SampleRate > 0 && quality.TotalSamples > 0 {
				totalDurationSec = float64(quality.TotalSamples) / float64(quality.SampleRate)
			}
		}
	case ".mp3":
		quality, qErr := GetMP3Quality(audioPath)
		if qErr == nil {
			sampleRate = quality.SampleRate
			totalDurationSec = float64(quality.Duration)
		}
	}

	// Extract cover from audio file for all tracks
	var coverPath string
	libraryCoverCacheMu.RLock()
	coverCacheDir := libraryCoverCacheDir
	libraryCoverCacheMu.RUnlock()
	if coverCacheDir != "" {
		cp, err := SaveCoverToCache(audioPath, coverCacheDir)
		if err == nil && cp != "" {
			coverPath = cp
		}
	}

	// Determine the base path for virtual paths and IDs
	pathBase := cuePath
	if virtualPathPrefix != "" {
		pathBase = virtualPathPrefix
	}

	// Determine fileModTime
	modTime := fileModTime
	if modTime <= 0 {
		if info, err := os.Stat(cuePath); err == nil {
			modTime = info.ModTime().UnixMilli()
		}
	}

	var results []LibraryScanResult
	for i, track := range sheet.Tracks {
		performer := track.Performer
		if performer == "" {
			performer = sheet.Performer
		}
		if performer == "" {
			performer = "Unknown Artist"
		}

		title := track.Title
		if title == "" {
			title = fmt.Sprintf("Track %02d", track.Number)
		}

		album := sheet.Title
		if album == "" {
			album = "Unknown Album"
		}

		// Calculate duration for this track
		var duration int
		if i+1 < len(sheet.Tracks) {
			nextStart := sheet.Tracks[i+1].StartTime
			if sheet.Tracks[i+1].PreGap >= 0 {
				nextStart = sheet.Tracks[i+1].PreGap
			}
			duration = int(nextStart - track.StartTime)
		} else if totalDurationSec > 0 {
			duration = int(totalDurationSec - track.StartTime)
		}

		// Use a unique ID based on pathBase + track number
		id := generateLibraryID(fmt.Sprintf("%s#track%d", pathBase, track.Number))

		// Use a virtual file path that includes the track number to ensure
		// uniqueness in the database (file_path has a UNIQUE constraint).
		// Format: /path/to/album.cue#track01 or content://...album.cue#track01
		virtualFilePath := fmt.Sprintf("%s#track%02d", pathBase, track.Number)

		result := LibraryScanResult{
			ID:          id,
			TrackName:   title,
			ArtistName:  performer,
			AlbumName:   album,
			AlbumArtist: sheet.Performer,
			FilePath:    virtualFilePath,
			CoverPath:   coverPath,
			ScannedAt:   scanTime,
			ISRC:        track.ISRC,
			TrackNumber: track.Number,
			DiscNumber:  1,
			Duration:    duration,
			ReleaseDate: sheet.Date,
			BitDepth:    bitDepth,
			SampleRate:  sampleRate,
			Genre:       sheet.Genre,
			Format:      "cue+" + strings.TrimPrefix(audioExt, "."),
		}

		result.FileModTime = modTime

		results = append(results, result)
	}

	return results, nil
}
