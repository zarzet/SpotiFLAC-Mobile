package gobackend

import "testing"

func TestSetExtensionFallbackProviderIDsJSONEmptyStringResetsDefault(t *testing.T) {
	original := GetExtensionFallbackProviderIDs()
	defer SetExtensionFallbackProviderIDs(original)

	SetExtensionFallbackProviderIDs([]string{"custom-ext"})

	if err := SetExtensionFallbackProviderIDsJSON(""); err != nil {
		t.Fatalf("SetExtensionFallbackProviderIDsJSON returned error: %v", err)
	}

	if got := GetExtensionFallbackProviderIDs(); got != nil {
		t.Fatalf("expected nil fallback provider list after reset, got %v", got)
	}
}

func TestBuildDownloadSuccessResponsePrefersRequestedAlbumMetadata(t *testing.T) {
	req := DownloadRequest{
		TrackName:   "Bonus Track",
		ArtistName:  "Artist",
		AlbumName:   "Album (Deluxe)",
		AlbumArtist: "Artist",
		ReleaseDate: "2024-01-01",
		TrackNumber: 14,
		DiscNumber:  1,
		ISRC:        "REQ123",
		CoverURL:    "https://example.com/cover.jpg",
		Genre:       "Pop",
		Label:       "Label",
		Copyright:   "Copyright",
	}

	result := DownloadResult{
		Title:       "Bonus Track",
		Artist:      "Artist",
		Album:       "Album",
		ReleaseDate: "2023-12-01",
		TrackNumber: 2,
		DiscNumber:  9,
		ISRC:        "RES456",
	}

	resp := buildDownloadSuccessResponse(
		req,
		result,
		"tidal",
		"ok",
		"/tmp/test.flac",
		false,
	)

	if resp.Album != req.AlbumName {
		t.Fatalf("album = %q, want %q", resp.Album, req.AlbumName)
	}
	if resp.ReleaseDate != req.ReleaseDate {
		t.Fatalf("release date = %q, want %q", resp.ReleaseDate, req.ReleaseDate)
	}
	if resp.TrackNumber != req.TrackNumber {
		t.Fatalf("track number = %d, want %d", resp.TrackNumber, req.TrackNumber)
	}
	if resp.DiscNumber != req.DiscNumber {
		t.Fatalf("disc number = %d, want %d", resp.DiscNumber, req.DiscNumber)
	}
	if resp.Artist != result.Artist {
		t.Fatalf("artist = %q, want provider artist %q", resp.Artist, result.Artist)
	}
	if resp.ISRC != result.ISRC {
		t.Fatalf("isrc = %q, want provider isrc %q", resp.ISRC, result.ISRC)
	}
}

func TestPreferredReleaseMetadataPrefersRequestValues(t *testing.T) {
	album, releaseDate, trackNumber, discNumber := preferredReleaseMetadata(
		DownloadRequest{
			AlbumName:   "Album (Deluxe Edition)",
			ReleaseDate: "2024-01-01",
			TrackNumber: 13,
			DiscNumber:  2,
		},
		"Album",
		"2023-01-01",
		3,
		1,
	)

	if album != "Album (Deluxe Edition)" {
		t.Fatalf("album = %q", album)
	}
	if releaseDate != "2024-01-01" {
		t.Fatalf("release date = %q", releaseDate)
	}
	if trackNumber != 13 {
		t.Fatalf("track number = %d", trackNumber)
	}
	if discNumber != 2 {
		t.Fatalf("disc number = %d", discNumber)
	}
}

func TestBuildDownloadSuccessResponsePrefersProviderCoverURL(t *testing.T) {
	req := DownloadRequest{
		TrackName:   "Track",
		ArtistName:  "Artist",
		AlbumName:   "Album",
		AlbumArtist: "Artist",
	}

	result := DownloadResult{
		Title:    "Track",
		Artist:   "Artist",
		Album:    "Album",
		CoverURL: "https://cdn.qobuz.test/cover.jpg",
	}

	resp := buildDownloadSuccessResponse(
		req,
		result,
		"qobuz",
		"ok",
		"/tmp/test.flac",
		false,
	)

	if resp.CoverURL != result.CoverURL {
		t.Fatalf("cover url = %q, want %q", resp.CoverURL, result.CoverURL)
	}
}

func TestApplyReEnrichTrackMetadataPreservesExistingReleaseDateWhenCandidateMissing(t *testing.T) {
	req := reEnrichRequest{
		SpotifyID:   "spotify-track-id",
		AlbumName:   "Original Album",
		ReleaseDate: "2024-01-01",
		ISRC:        "REQ123",
	}

	applyReEnrichTrackMetadata(&req, ExtTrackMetadata{
		AlbumName:   "Resolved Album",
		ReleaseDate: "",
		ISRC:        "",
	})

	if req.ReleaseDate != "2024-01-01" {
		t.Fatalf("release date = %q, want existing value preserved", req.ReleaseDate)
	}
	if req.AlbumName != "Resolved Album" {
		t.Fatalf("album = %q, want updated album", req.AlbumName)
	}
	if req.ISRC != "REQ123" {
		t.Fatalf("isrc = %q, want existing value preserved", req.ISRC)
	}
}

func TestSelectBestReEnrichTrackPrefersCandidateWithReleaseDate(t *testing.T) {
	req := reEnrichRequest{
		TrackName:   "Song Title",
		ArtistName:  "Artist Name",
		AlbumName:   "Album Name",
		ReleaseDate: "",
		DurationMs:  180000,
	}

	tracks := []ExtTrackMetadata{
		{
			ID:          "first",
			Name:        "Song Title",
			Artists:     "Artist Name",
			AlbumName:   "Album Name",
			DurationMS:  180000,
			ReleaseDate: "",
			ProviderID:  "spotify",
		},
		{
			ID:          "second",
			Name:        "Song Title",
			Artists:     "Artist Name",
			AlbumName:   "Album Name",
			DurationMS:  180000,
			ReleaseDate: "2024-03-09",
			ProviderID:  "deezer",
		},
	}

	best := selectBestReEnrichTrack(req, tracks)
	if best == nil {
		t.Fatal("expected a selected track")
	}
	if best.ID != "second" {
		t.Fatalf("selected track = %q, want candidate with release date", best.ID)
	}
}

func TestBuildReEnrichFFmpegMetadataOmitsEmptyFields(t *testing.T) {
	req := reEnrichRequest{
		TrackName:   "Song",
		ArtistName:  "Artist",
		AlbumName:   "Album",
		AlbumArtist: "",
		ReleaseDate: "",
		TrackNumber: 0,
		DiscNumber:  0,
		ISRC:        "",
		Genre:       "",
		Label:       "",
		Copyright:   "",
	}

	metadata := buildReEnrichFFmpegMetadata(&req, "")

	if metadata["TITLE"] != "Song" {
		t.Fatalf("title = %q", metadata["TITLE"])
	}
	if metadata["ARTIST"] != "Artist" {
		t.Fatalf("artist = %q", metadata["ARTIST"])
	}
	if metadata["ALBUM"] != "Album" {
		t.Fatalf("album = %q", metadata["ALBUM"])
	}

	for _, key := range []string{
		"ALBUMARTIST",
		"DATE",
		"TRACKNUMBER",
		"DISCNUMBER",
		"ISRC",
		"GENRE",
		"ORGANIZATION",
		"COPYRIGHT",
		"LYRICS",
		"UNSYNCEDLYRICS",
	} {
		if _, exists := metadata[key]; exists {
			t.Fatalf("did not expect key %s in metadata: %#v", key, metadata)
		}
	}
}

func TestBuildReEnrichSearchQuerySkipsPlaceholderArtist(t *testing.T) {
	req := reEnrichRequest{
		TrackName:  "Sign of the Times",
		ArtistName: "Unknown Artist",
		AlbumName:  "Harry Styles",
	}

	query := buildReEnrichSearchQuery(req)
	if query != "Sign of the Times" {
		t.Fatalf("query = %q", query)
	}

	req = reEnrichRequest{
		TrackName:  "Unknown Title",
		ArtistName: "Unknown Artist",
		AlbumName:  "Harry Styles",
	}
	query = buildReEnrichSearchQuery(req)
	if query != "Harry Styles" {
		t.Fatalf("fallback album query = %q", query)
	}
}

func TestApplyReEnrichTrackMetadataCopiesComposerAndTotals(t *testing.T) {
	req := reEnrichRequest{}

	applyReEnrichTrackMetadata(&req, ExtTrackMetadata{
		Name:        "Resolved Song",
		Artists:     "Resolved Artist",
		TrackNumber: 7,
		TotalTracks: 12,
		DiscNumber:  2,
		TotalDiscs:  3,
		Composer:    "Composer",
	})

	if req.TrackNumber != 7 || req.TotalTracks != 12 {
		t.Fatalf("track metadata = %d/%d", req.TrackNumber, req.TotalTracks)
	}
	if req.DiscNumber != 2 || req.TotalDiscs != 3 {
		t.Fatalf("disc metadata = %d/%d", req.DiscNumber, req.TotalDiscs)
	}
	if req.TrackName != "Resolved Song" || req.ArtistName != "Resolved Artist" {
		t.Fatalf("basic tags = %q / %q", req.TrackName, req.ArtistName)
	}
	if req.Composer != "Composer" {
		t.Fatalf("composer = %q", req.Composer)
	}
}

func TestBuildReEnrichFFmpegMetadataFormatsTotalsAndComposer(t *testing.T) {
	req := reEnrichRequest{
		TrackNumber: 7,
		TotalTracks: 12,
		DiscNumber:  2,
		TotalDiscs:  3,
		Composer:    "Composer",
	}

	metadata := buildReEnrichFFmpegMetadata(&req, "")

	if metadata["TRACKNUMBER"] != "7/12" {
		t.Fatalf("TRACKNUMBER = %q", metadata["TRACKNUMBER"])
	}
	if metadata["DISCNUMBER"] != "2/3" {
		t.Fatalf("DISCNUMBER = %q", metadata["DISCNUMBER"])
	}
	if metadata["COMPOSER"] != "Composer" {
		t.Fatalf("COMPOSER = %q", metadata["COMPOSER"])
	}
}
