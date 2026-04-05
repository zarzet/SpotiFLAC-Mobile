package gobackend

import (
	"encoding/json"
	"testing"
)

func buildTestQobuzAlbum(id, title, artist string, tracks ...QobuzTrack) *qobuzAlbumDetails {
	album := &qobuzAlbumDetails{
		ID:                  id,
		Title:               title,
		ReleaseDateOriginal: "2013-05-20",
		TracksCount:         len(tracks),
		ProductType:         "album",
		ReleaseType:         "album",
	}
	album.Artist = qobuzArtistRef{ID: 1, Name: artist}
	album.Artists = []qobuzArtistRef{{ID: 1, Name: artist}}
	album.Tracks.Items = tracks
	return album
}

func TestParseQobuzURL(t *testing.T) {
	tests := []struct {
		name      string
		input     string
		wantType  string
		wantID    string
		expectErr bool
	}{
		{
			name:     "store album url",
			input:    "https://www.qobuz.com/us-en/album/harry-styles-harry-styles/0886446451985",
			wantType: "album",
			wantID:   "0886446451985",
		},
		{
			name:     "store playlist url",
			input:    "https://www.qobuz.com/us-en/playlists/new-releases/2049430",
			wantType: "playlist",
			wantID:   "2049430",
		},
		{
			name:     "store artist url",
			input:    "https://www.qobuz.com/us-en/interpreter/harry-styles/729886",
			wantType: "artist",
			wantID:   "729886",
		},
		{
			name:     "play track url",
			input:    "https://play.qobuz.com/track/40681594",
			wantType: "track",
			wantID:   "40681594",
		},
		{
			name:     "custom scheme playlist url",
			input:    "qobuzapp://playlist/2049430",
			wantType: "playlist",
			wantID:   "2049430",
		},
		{
			name:      "unsupported url",
			input:     "https://example.com/not-qobuz",
			expectErr: true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			gotType, gotID, err := parseQobuzURL(test.input)
			if test.expectErr {
				if err == nil {
					t.Fatalf("expected error, got none")
				}
				return
			}
			if err != nil {
				t.Fatalf("expected no error, got %v", err)
			}
			if gotType != test.wantType || gotID != test.wantID {
				t.Fatalf("parseQobuzURL(%q) = (%q, %q), want (%q, %q)", test.input, gotType, gotID, test.wantType, test.wantID)
			}
		})
	}
}

func TestExtractQobuzArtistAlbumIDs(t *testing.T) {
	body := []byte(`
<div class="product__item">
  <button data-itemtype="album" data-itemId="yrpbt0lwm3g0y"></button>
</div>
<div class="product__item">
  <button data-itemtype="album" data-itemId="yrpbt0lwm3g0y"></button>
</div>
<div class="product__item">
  <button data-itemtype="album" data-itemId="0886446451985"></button>
</div>
`)

	matches := qobuzArtistAlbumIDRegex.FindAllSubmatch(body, -1)
	if len(matches) != 3 {
		t.Fatalf("expected 3 regex matches, got %d", len(matches))
	}
	if string(matches[0][1]) != "yrpbt0lwm3g0y" {
		t.Fatalf("unexpected first album id: %q", matches[0][1])
	}
	if string(matches[2][1]) != "0886446451985" {
		t.Fatalf("unexpected last album id: %q", matches[2][1])
	}
}

func TestExtractQobuzDownloadURLFromBody(t *testing.T) {
	t.Run("reads top-level download_url and quality metadata", func(t *testing.T) {
		body := []byte(`{"success":true,"download_url":"https://example.test/new.flac","bit_depth":24,"sampling_rate":96}`)

		info, err := extractQobuzDownloadInfoFromBody(body)
		if err != nil {
			t.Fatalf("expected no error, got %v", err)
		}
		if info.DownloadURL != "https://example.test/new.flac" {
			t.Fatalf("unexpected URL: %q", info.DownloadURL)
		}
		if info.BitDepth != 24 {
			t.Fatalf("unexpected bit depth: %d", info.BitDepth)
		}
		if info.SampleRate != 96000 {
			t.Fatalf("unexpected sample rate: %d", info.SampleRate)
		}
	})

	t.Run("reads nested data.url", func(t *testing.T) {
		body := []byte(`{"success":true,"data":{"url":"https://example.test/audio.flac"}}`)

		got, err := extractQobuzDownloadURLFromBody(body)
		if err != nil {
			t.Fatalf("expected no error, got %v", err)
		}
		if got != "https://example.test/audio.flac" {
			t.Fatalf("unexpected URL: %q", got)
		}
	})

	t.Run("reads top-level url", func(t *testing.T) {
		body := []byte(`{"url":"https://example.test/top.flac"}`)

		got, err := extractQobuzDownloadURLFromBody(body)
		if err != nil {
			t.Fatalf("expected no error, got %v", err)
		}
		if got != "https://example.test/top.flac" {
			t.Fatalf("unexpected URL: %q", got)
		}
	})

	t.Run("returns API error", func(t *testing.T) {
		body := []byte(`{"error":"track not found"}`)

		_, err := extractQobuzDownloadURLFromBody(body)
		if err == nil || err.Error() != "track not found" {
			t.Fatalf("expected track-not-found error, got %v", err)
		}
	})

	t.Run("returns message when success false", func(t *testing.T) {
		body := []byte(`{"success":false,"message":"blocked"}`)

		_, err := extractQobuzDownloadURLFromBody(body)
		if err == nil || err.Error() != "blocked" {
			t.Fatalf("expected blocked error, got %v", err)
		}
	})

	t.Run("returns detail error", func(t *testing.T) {
		body := []byte(`{"detail":"Invalid quality 'lossless'. Choose from: ['mp3', 'cd', 'hi-res', 'hi-res-max']"}`)

		_, err := extractQobuzDownloadURLFromBody(body)
		if err == nil || err.Error() != "Invalid quality 'lossless'. Choose from: ['mp3', 'cd', 'hi-res', 'hi-res-max']" {
			t.Fatalf("expected detail error, got %v", err)
		}
	})
}

func TestNormalizeQobuzQualityCode(t *testing.T) {
	tests := map[string]string{
		"":           "6",
		"5":          "6",
		"6":          "6",
		"cd":         "6",
		"lossless":   "6",
		"7":          "7",
		"hi-res":     "7",
		"27":         "27",
		"hi-res-max": "27",
		"unexpected": "6",
	}

	for input, want := range tests {
		if got := normalizeQobuzQualityCode(input); got != want {
			t.Fatalf("normalizeQobuzQualityCode(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestBuildQobuzMusicDLPayloadUsesOpenTrackURL(t *testing.T) {
	payloadBytes, err := buildQobuzMusicDLPayload(374610875, "7")
	if err != nil {
		t.Fatalf("buildQobuzMusicDLPayload returned error: %v", err)
	}

	var payload map[string]any
	if err := json.Unmarshal(payloadBytes, &payload); err != nil {
		t.Fatalf("payload is not valid JSON: %v", err)
	}

	if got := payload["url"]; got != "https://open.qobuz.com/track/374610875" {
		t.Fatalf("payload url = %v, want open.qobuz.com track URL", got)
	}
	if got := payload["quality"]; got != "hi-res" {
		t.Fatalf("payload quality = %v, want hi-res", got)
	}
	if got := payload["upload_to_r2"]; got != false {
		t.Fatalf("payload upload_to_r2 = %v, want false", got)
	}
}

func TestExtractQobuzAlbumIDsFromArtistHTML(t *testing.T) {
	body := []byte(`
		<button data-itemtype="album" data-itemId="0886446451985"></button>
		<button data-itemtype="album" data-itemId="0886446451985"></button>
		<button data-itemtype="album" data-itemId="pvv406bth40ya"></button>
	`)

	got := extractQobuzAlbumIDsFromArtistHTML(body)
	if len(got) != 2 {
		t.Fatalf("expected 2 unique album IDs, got %d (%v)", len(got), got)
	}
	if got[0] != "0886446451985" || got[1] != "pvv406bth40ya" {
		t.Fatalf("unexpected album IDs: %v", got)
	}
}

func TestQobuzAvailableProviders(t *testing.T) {
	providers := NewQobuzDownloader().GetAvailableProviders()
	if len(providers) != 6 {
		t.Fatalf("expected 6 Qobuz providers, got %d", len(providers))
	}

	want := map[string]string{
		"musicdl":  qobuzAPIKindMusicDL,
		"zarz":     qobuzAPIKindMusicDL,
		"dabmusic": qobuzAPIKindStandard,
		"deeb":     qobuzAPIKindStandard,
		"qbz":      qobuzAPIKindStandard,
		"squid":    qobuzAPIKindStandard,
	}

	for _, provider := range providers {
		wantKind, ok := want[provider.Name]
		if !ok {
			t.Fatalf("unexpected provider %q", provider.Name)
		}
		if provider.Kind != wantKind {
			t.Fatalf("provider %q has kind %q, want %q", provider.Name, provider.Kind, wantKind)
		}
		delete(want, provider.Name)
	}

	if len(want) != 0 {
		t.Fatalf("missing providers: %v", want)
	}
}

func testQobuzTrack(id int64, title, artist string, duration int) *QobuzTrack {
	track := &QobuzTrack{
		ID:       id,
		Title:    title,
		Duration: duration,
	}
	track.Performer.Name = artist
	return track
}

func TestSelectQobuzTracksFromAlbumSearchResultsPrefersMatchingTrack(t *testing.T) {
	summaries := []qobuzAlbumDetails{
		{ID: "album-a"},
		{ID: "album-b"},
	}

	match := *testQobuzTrack(1, "Get Lucky", "Daft Punk", 369)
	other := *testQobuzTrack(2, "Fragments of Time", "Daft Punk", 280)
	fallback := *testQobuzTrack(3, "Da Funk", "Daft Punk", 330)

	albums := map[string]*qobuzAlbumDetails{
		"album-a": buildTestQobuzAlbum("album-a", "Random Access Memories", "Daft Punk", match, other),
		"album-b": buildTestQobuzAlbum("album-b", "Homework", "Daft Punk", fallback),
	}

	tracks, err := selectQobuzTracksFromAlbumSearchResults(
		"daft punk get lucky",
		3,
		summaries,
		func(id string) (*qobuzAlbumDetails, error) { return albums[id], nil },
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(tracks) == 0 {
		t.Fatal("expected tracks, got none")
	}
	if tracks[0].ID != 1 {
		t.Fatalf("expected Get Lucky to rank first, got track id %d", tracks[0].ID)
	}
}

func TestSelectQobuzTracksFromAlbumSearchResultsDedupesTracks(t *testing.T) {
	summaries := []qobuzAlbumDetails{
		{ID: "album-a"},
		{ID: "album-b"},
	}

	shared := *testQobuzTrack(42, "Get Lucky", "Daft Punk", 369)

	albums := map[string]*qobuzAlbumDetails{
		"album-a": buildTestQobuzAlbum("album-a", "Random Access Memories", "Daft Punk", shared),
		"album-b": buildTestQobuzAlbum("album-b", "Random Access Memories Deluxe", "Daft Punk", shared),
	}

	tracks, err := selectQobuzTracksFromAlbumSearchResults(
		"daft punk get lucky",
		5,
		summaries,
		func(id string) (*qobuzAlbumDetails, error) { return albums[id], nil },
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(tracks) != 1 {
		t.Fatalf("expected 1 deduped track, got %d", len(tracks))
	}
	if tracks[0].ID != 42 {
		t.Fatalf("unexpected deduped track id: %d", tracks[0].ID)
	}
}

func TestResolveQobuzTrackForRequestRejectsSongLinkMismatch(t *testing.T) {
	origGetTrackByID := qobuzGetTrackByIDFunc
	origSearchISRC := qobuzSearchTrackByISRCWithDurationFunc
	origSearchMetadata := qobuzSearchTrackByMetadataWithDurationFunc
	origSongLinkCheck := songLinkCheckTrackAvailabilityFunc
	t.Cleanup(func() {
		qobuzGetTrackByIDFunc = origGetTrackByID
		qobuzSearchTrackByISRCWithDurationFunc = origSearchISRC
		qobuzSearchTrackByMetadataWithDurationFunc = origSearchMetadata
		songLinkCheckTrackAvailabilityFunc = origSongLinkCheck
		GetTrackIDCache().Clear()
	})
	GetTrackIDCache().Clear()

	qobuzGetTrackByIDFunc = func(_ *QobuzDownloader, trackID int64) (*QobuzTrack, error) {
		if trackID != 111 {
			t.Fatalf("unexpected track ID lookup: %d", trackID)
		}
		return testQobuzTrack(111, "Aperture", "Harry Styles", 180), nil
	}
	qobuzSearchTrackByISRCWithDurationFunc = func(_ *QobuzDownloader, isrc string, expectedDurationSec int) (*QobuzTrack, error) {
		if isrc != "TESTISRC1" {
			t.Fatalf("unexpected ISRC lookup: %q", isrc)
		}
		if expectedDurationSec != 180 {
			t.Fatalf("unexpected duration: %d", expectedDurationSec)
		}
		return testQobuzTrack(222, "Taste Back", "Harry Styles", 180), nil
	}
	qobuzSearchTrackByMetadataWithDurationFunc = func(_ *QobuzDownloader, _, _ string, _ int) (*QobuzTrack, error) {
		t.Fatal("metadata fallback should not run when ISRC fallback succeeds")
		return nil, nil
	}
	songLinkCheckTrackAvailabilityFunc = func(_ *SongLinkClient, spotifyTrackID string, isrc string) (*TrackAvailability, error) {
		if spotifyTrackID != "spotify-track-id" {
			t.Fatalf("unexpected spotify ID: %q", spotifyTrackID)
		}
		if isrc != "TESTISRC1" {
			t.Fatalf("unexpected SongLink ISRC: %q", isrc)
		}
		return &TrackAvailability{QobuzID: "111"}, nil
	}

	req := DownloadRequest{
		ISRC:       "TESTISRC1",
		SpotifyID:  "spotify-track-id",
		TrackName:  "Taste Back",
		ArtistName: "Harry Styles",
		DurationMS: 180000,
	}

	track, err := resolveQobuzTrackForRequest(req, &QobuzDownloader{}, "Test")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if track == nil || track.ID != 222 || track.Title != "Taste Back" {
		t.Fatalf("unexpected resolved track: %+v", track)
	}

	cached := GetTrackIDCache().Get(req.ISRC)
	if cached == nil || cached.QobuzTrackID != 222 {
		t.Fatalf("expected validated fallback track to be cached, got %+v", cached)
	}
}

func TestResolveQobuzTrackForRequestRejectsOdesliMismatch(t *testing.T) {
	origGetTrackByID := qobuzGetTrackByIDFunc
	origSearchISRC := qobuzSearchTrackByISRCWithDurationFunc
	origSearchMetadata := qobuzSearchTrackByMetadataWithDurationFunc
	origSongLinkCheck := songLinkCheckTrackAvailabilityFunc
	t.Cleanup(func() {
		qobuzGetTrackByIDFunc = origGetTrackByID
		qobuzSearchTrackByISRCWithDurationFunc = origSearchISRC
		qobuzSearchTrackByMetadataWithDurationFunc = origSearchMetadata
		songLinkCheckTrackAvailabilityFunc = origSongLinkCheck
	})

	qobuzGetTrackByIDFunc = func(_ *QobuzDownloader, trackID int64) (*QobuzTrack, error) {
		if trackID != 333 {
			t.Fatalf("unexpected track ID lookup: %d", trackID)
		}
		return testQobuzTrack(333, "American Girls", "Harry Styles", 181), nil
	}
	qobuzSearchTrackByISRCWithDurationFunc = func(_ *QobuzDownloader, _ string, _ int) (*QobuzTrack, error) {
		t.Fatal("ISRC fallback should not run without an ISRC")
		return nil, nil
	}
	qobuzSearchTrackByMetadataWithDurationFunc = func(_ *QobuzDownloader, trackName, artistName string, expectedDurationSec int) (*QobuzTrack, error) {
		if trackName != "Taste Back" || artistName != "Harry Styles" || expectedDurationSec != 181 {
			t.Fatalf("unexpected metadata fallback arguments: %q / %q / %d", trackName, artistName, expectedDurationSec)
		}
		return testQobuzTrack(444, "Taste Back", "Harry Styles", 181), nil
	}
	songLinkCheckTrackAvailabilityFunc = func(_ *SongLinkClient, _, _ string) (*TrackAvailability, error) {
		t.Fatal("SongLink should not run when Odesli QobuzID is provided")
		return nil, nil
	}

	req := DownloadRequest{
		QobuzID:    "333",
		TrackName:  "Taste Back",
		ArtistName: "Harry Styles",
		DurationMS: 181000,
	}

	track, err := resolveQobuzTrackForRequest(req, &QobuzDownloader{}, "Test")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if track == nil || track.ID != 444 || track.Title != "Taste Back" {
		t.Fatalf("unexpected resolved track: %+v", track)
	}
}

func TestResolveQobuzTrackForRequestUsesPrefixedQobuzIDWithoutSongLink(t *testing.T) {
	origGetTrackByID := qobuzGetTrackByIDFunc
	origSearchISRC := qobuzSearchTrackByISRCWithDurationFunc
	origSearchMetadata := qobuzSearchTrackByMetadataWithDurationFunc
	origSongLinkCheck := songLinkCheckTrackAvailabilityFunc
	t.Cleanup(func() {
		qobuzGetTrackByIDFunc = origGetTrackByID
		qobuzSearchTrackByISRCWithDurationFunc = origSearchISRC
		qobuzSearchTrackByMetadataWithDurationFunc = origSearchMetadata
		songLinkCheckTrackAvailabilityFunc = origSongLinkCheck
	})

	qobuzGetTrackByIDFunc = func(_ *QobuzDownloader, trackID int64) (*QobuzTrack, error) {
		if trackID != 40681594 {
			t.Fatalf("unexpected track ID lookup: %d", trackID)
		}
		return testQobuzTrack(40681594, "Sign of the Times", "Harry Styles", 341), nil
	}
	qobuzSearchTrackByISRCWithDurationFunc = func(_ *QobuzDownloader, _ string, _ int) (*QobuzTrack, error) {
		t.Fatal("ISRC fallback should not run when request qobuz id succeeds")
		return nil, nil
	}
	qobuzSearchTrackByMetadataWithDurationFunc = func(_ *QobuzDownloader, _, _ string, _ int) (*QobuzTrack, error) {
		t.Fatal("metadata fallback should not run when request qobuz id succeeds")
		return nil, nil
	}
	songLinkCheckTrackAvailabilityFunc = func(_ *SongLinkClient, _, _ string) (*TrackAvailability, error) {
		t.Fatal("SongLink should not run when request qobuz id is provided")
		return nil, nil
	}

	req := DownloadRequest{
		QobuzID:    "qobuz:40681594",
		TrackName:  "Sign of the Times",
		ArtistName: "Harry Styles",
		DurationMS: 341000,
	}

	track, err := resolveQobuzTrackForRequest(req, &QobuzDownloader{}, "Test")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if track == nil || track.ID != 40681594 {
		t.Fatalf("unexpected resolved track: %+v", track)
	}
}

func TestQobuzTrackMatchesRequest_SongLinkBypassesArtistAndTitle(t *testing.T) {
	req := DownloadRequest{
		TrackName:  "Ringišpil",
		ArtistName: "Djordje Balasevic",
	}

	track := &QobuzTrack{
		Title:    "Different Title",
		Duration: 0,
	}
	track.Performer.Name = "Different Artist"

	if !qobuzTrackMatchesRequest(req, track, "Qobuz", "SongLink Qobuz ID", true) {
		t.Fatal("expected SongLink Qobuz source to bypass artist/title verification")
	}
}

func TestQobuzTrackMetadataIncludesComposer(t *testing.T) {
	track := &QobuzTrack{
		ID:          40681594,
		Title:       "Sign of the Times",
		ISRC:        "USSM11703595",
		Duration:    340,
		TrackNumber: 1,
		MediaNumber: 1,
	}
	track.Performer.ID = 729886
	track.Performer.Name = "Harry Styles"
	track.Composer.ID = 729886
	track.Composer.Name = "Harry Styles"
	track.Album.ID = "0886446451985"
	track.Album.Title = "Harry Styles"
	track.Album.ReleaseDate = "2017-05-12"
	track.Album.TracksCount = 10
	track.Album.ReleaseType = "album"
	track.Album.ProductType = "album"
	track.Album.Artist.ID = 729886
	track.Album.Artist.Name = "Harry Styles"
	track.Album.Artists = []qobuzArtistRef{{ID: 729886, Name: "Harry Styles"}}

	trackMeta := qobuzTrackToTrackMetadata(track)
	if trackMeta.Composer != "Harry Styles" {
		t.Fatalf("track composer = %q", trackMeta.Composer)
	}

	albumTrackMeta := qobuzTrackToAlbumTrackMetadata(track)
	if albumTrackMeta.Composer != "Harry Styles" {
		t.Fatalf("album track composer = %q", albumTrackMeta.Composer)
	}
}
