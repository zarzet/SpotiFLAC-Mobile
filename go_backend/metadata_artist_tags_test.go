package gobackend

import (
	"bytes"
	"encoding/binary"
	"slices"
	"testing"

	"github.com/go-flac/flacvorbis/v2"
)

func TestSplitArtistTagValues(t *testing.T) {
	got := splitArtistTagValues("Artist A, Artist B feat. Artist C & Artist B")
	want := []string{"Artist A", "Artist B", "Artist C"}
	if !slices.Equal(got, want) {
		t.Fatalf("splitArtistTagValues() = %#v, want %#v", got, want)
	}
}

func TestSetArtistCommentsSplitVorbis(t *testing.T) {
	cmt := flacvorbis.New()
	setArtistComments(cmt, "ARTIST", "Artist A, Artist B", artistTagModeSplitVorbis)

	got := getCommentValues(cmt, "ARTIST")
	want := []string{"Artist A", "Artist B"}
	if !slices.Equal(got, want) {
		t.Fatalf("getCommentValues(ARTIST) = %#v, want %#v", got, want)
	}
}

func TestParseVorbisCommentsJoinsRepeatedArtists(t *testing.T) {
	metadata := &AudioMetadata{}
	parseVorbisComments(
		buildVorbisCommentPayload(
			[]string{
				"TITLE=Song",
				"ARTIST=Artist A",
				"ARTIST=Artist B",
				"ALBUMARTIST=Album Artist A",
				"ALBUMARTIST=Album Artist B",
			},
		),
		metadata,
	)

	if metadata.Title != "Song" {
		t.Fatalf("title = %q", metadata.Title)
	}
	if metadata.Artist != "Artist A, Artist B" {
		t.Fatalf("artist = %q", metadata.Artist)
	}
	if metadata.AlbumArtist != "Album Artist A, Album Artist B" {
		t.Fatalf("album artist = %q", metadata.AlbumArtist)
	}
}

func buildVorbisCommentPayload(comments []string) []byte {
	var buf bytes.Buffer
	_ = binary.Write(&buf, binary.LittleEndian, uint32(len("spotiflac")))
	buf.WriteString("spotiflac")
	_ = binary.Write(&buf, binary.LittleEndian, uint32(len(comments)))
	for _, comment := range comments {
		_ = binary.Write(&buf, binary.LittleEndian, uint32(len(comment)))
		buf.WriteString(comment)
	}
	return buf.Bytes()
}
