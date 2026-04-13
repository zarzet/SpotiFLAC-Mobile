package gobackend

import (
	"bufio"
	"context"
	"encoding/base64"
	"encoding/json"
	"encoding/xml"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

type TidalDownloader struct {
	client *http.Client
	apiURL string
}

var (
	globalTidalDownloader       *TidalDownloader
	tidalDownloaderOnce         sync.Once
	tidalGetTrackSearchPageFunc = func(t *TidalDownloader, query string, limit int) (*tidalPublicTrackSearchResponse, error) {
		return t.getTrackSearchPage(query, limit)
	}
	tidalGetPublicTrackFunc = func(t *TidalDownloader, resourceID string) (*TidalTrack, error) {
		return t.getPublicTrack(resourceID)
	}
)

const (
	spotifyTrackBaseURL   = "https://open.spotify.com/track/"
	songLinkLookupBaseURL = "https://api.song.link/v1-alpha.1/links?url="
	tidalPublicAPIBaseURL = "https://tidal.com/v1"
	tidalPublicToken      = "txNoH4kkV41MfH25"
	tidalResourceBaseURL  = "https://resources.tidal.com"
	tidalCountryCode      = "US"
	tidalLocale           = "en_US"
	tidalDeviceType       = "BROWSER"
)

type TidalTrack struct {
	ID           int64  `json:"id"`
	Title        string `json:"title"`
	ISRC         string `json:"isrc"`
	AudioQuality string `json:"audioQuality"`
	TrackNumber  int    `json:"trackNumber"`
	VolumeNumber int    `json:"volumeNumber"`
	Duration     int    `json:"duration"`
	Album        struct {
		ID          int64  `json:"id"`
		Title       string `json:"title"`
		Cover       string `json:"cover"`
		ReleaseDate string `json:"releaseDate"`
		URL         string `json:"url"`
	} `json:"album"`
	Artists []struct {
		ID      int64  `json:"id"`
		Name    string `json:"name"`
		Type    string `json:"type"`
		Picture string `json:"picture"`
	} `json:"artists"`
	Artist struct {
		ID      int64  `json:"id"`
		Name    string `json:"name"`
		Type    string `json:"type"`
		Picture string `json:"picture"`
	} `json:"artist"`
	MediaMetadata struct {
		Tags []string `json:"tags"`
	} `json:"mediaMetadata"`
	URL string `json:"url"`
}

type TidalAPIResponseV2 struct {
	Version string `json:"version"`
	Data    struct {
		TrackID           int64  `json:"trackId"`
		AssetPresentation string `json:"assetPresentation"`
		AudioMode         string `json:"audioMode"`
		AudioQuality      string `json:"audioQuality"`
		ManifestMimeType  string `json:"manifestMimeType"`
		ManifestHash      string `json:"manifestHash"`
		Manifest          string `json:"manifest"`
		BitDepth          int    `json:"bitDepth"`
		SampleRate        int    `json:"sampleRate"`
	} `json:"data"`
}

type TidalBTSManifest struct {
	MimeType       string   `json:"mimeType"`
	Codecs         string   `json:"codecs"`
	EncryptionType string   `json:"encryptionType"`
	URLs           []string `json:"urls"`
}

type MPD struct {
	XMLName xml.Name `xml:"MPD"`
	Period  struct {
		AdaptationSet struct {
			Representation struct {
				SegmentTemplate struct {
					Initialization string `xml:"initialization,attr"`
					Media          string `xml:"media,attr"`
					Timeline       struct {
						Segments []struct {
							Duration int `xml:"d,attr"`
							Repeat   int `xml:"r,attr"`
						} `xml:"S"`
					} `xml:"SegmentTimeline"`
				} `xml:"SegmentTemplate"`
			} `xml:"Representation"`
		} `xml:"AdaptationSet"`
	} `xml:"Period"`
}

type tidalPublicArtist struct {
	ID      int64  `json:"id"`
	Name    string `json:"name"`
	Type    string `json:"type"`
	Picture string `json:"picture"`
}

type tidalPublicAlbum struct {
	ID             int64               `json:"id"`
	Title          string              `json:"title"`
	Type           string              `json:"type"`
	Cover          string              `json:"cover"`
	ReleaseDate    string              `json:"releaseDate"`
	URL            string              `json:"url"`
	NumberOfTracks int                 `json:"numberOfTracks"`
	Explicit       bool                `json:"explicit"`
	Artists        []tidalPublicArtist `json:"artists"`
}

type tidalPublicAlbumPage struct {
	Rows []struct {
		Modules []struct {
			Type      string           `json:"type"`
			Album     tidalPublicAlbum `json:"album"`
			PagedList struct {
				DataAPIPath        string `json:"dataApiPath"`
				Limit              int    `json:"limit"`
				Offset             int    `json:"offset"`
				TotalNumberOfItems int    `json:"totalNumberOfItems"`
				Items              []struct {
					Item TidalTrack `json:"item"`
					Type string     `json:"type"`
				} `json:"items"`
			} `json:"pagedList"`
		} `json:"modules"`
	} `json:"rows"`
}

type tidalPublicArtistPage struct {
	Rows []struct {
		Modules []struct {
			Type   string `json:"type"`
			Title  string `json:"title"`
			Artist struct {
				ID      int64  `json:"id"`
				Name    string `json:"name"`
				URL     string `json:"url"`
				Picture string `json:"picture"`
			} `json:"artist"`
			PagedList struct {
				DataAPIPath        string             `json:"dataApiPath"`
				Limit              int                `json:"limit"`
				Offset             int                `json:"offset"`
				TotalNumberOfItems int                `json:"totalNumberOfItems"`
				Items              []tidalPublicAlbum `json:"items"`
			} `json:"pagedList"`
		} `json:"modules"`
	} `json:"rows"`
}

type tidalPublicArtistAlbumsPage struct {
	Limit              int                `json:"limit"`
	Offset             int                `json:"offset"`
	TotalNumberOfItems int                `json:"totalNumberOfItems"`
	Items              []tidalPublicAlbum `json:"items"`
}

type tidalPublicPlaylist struct {
	UUID           string `json:"uuid"`
	Title          string `json:"title"`
	Description    string `json:"description"`
	Type           string `json:"type"`
	URL            string `json:"url"`
	Image          string `json:"image"`
	SquareImage    string `json:"squareImage"`
	NumberOfTracks int    `json:"numberOfTracks"`
	Creator        struct {
		ID   int64  `json:"id"`
		Name string `json:"name"`
	} `json:"creator"`
}

type tidalPublicPlaylistItemsPage struct {
	Limit              int `json:"limit"`
	Offset             int `json:"offset"`
	TotalNumberOfItems int `json:"totalNumberOfItems"`
	Items              []struct {
		Item TidalTrack `json:"item"`
		Type string     `json:"type"`
	} `json:"items"`
}

type tidalPublicTrackSearchResponse struct {
	Limit              int          `json:"limit"`
	Offset             int          `json:"offset"`
	TotalNumberOfItems int          `json:"totalNumberOfItems"`
	Items              []TidalTrack `json:"items"`
}

func NewTidalDownloader() *TidalDownloader {
	tidalDownloaderOnce.Do(func() {
		globalTidalDownloader = &TidalDownloader{
			client: NewHTTPClientWithTimeout(DefaultTimeout),
		}

		apis := globalTidalDownloader.GetAvailableAPIs()
		if len(apis) > 0 {
			globalTidalDownloader.apiURL = apis[0]
		}
	})
	return globalTidalDownloader
}

func tidalPrefixedID(id string) string {
	trimmed := strings.TrimSpace(id)
	if trimmed == "" {
		return ""
	}
	return "tidal:" + trimmed
}

func tidalPrefixedNumericID(id int64) string {
	if id <= 0 {
		return ""
	}
	return fmt.Sprintf("tidal:%d", id)
}

func tidalImageURL(imageID, size string) string {
	normalizedID := strings.TrimSpace(imageID)
	if normalizedID == "" || strings.TrimSpace(size) == "" {
		return ""
	}
	return fmt.Sprintf(
		"%s/images/%s/%s.jpg",
		tidalResourceBaseURL,
		strings.ReplaceAll(normalizedID, "-", "/"),
		size,
	)
}

func tidalFirstNonEmpty(values ...string) string {
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			return trimmed
		}
	}
	return ""
}

func tidalJoinArtistNames(artists []tidalPublicArtist) string {
	if len(artists) == 0 {
		return ""
	}

	names := make([]string, 0, len(artists))
	for _, artist := range artists {
		if trimmed := strings.TrimSpace(artist.Name); trimmed != "" {
			names = append(names, trimmed)
		}
	}
	return strings.Join(names, ", ")
}

func tidalTrackArtistsDisplay(track *TidalTrack) string {
	if track == nil {
		return ""
	}

	if len(track.Artists) > 0 {
		names := make([]string, 0, len(track.Artists))
		for _, artist := range track.Artists {
			if trimmed := strings.TrimSpace(artist.Name); trimmed != "" {
				names = append(names, trimmed)
			}
		}
		if len(names) > 0 {
			return strings.Join(names, ", ")
		}
	}

	return strings.TrimSpace(track.Artist.Name)
}

func tidalAlbumArtistsDisplay(album *tidalPublicAlbum) string {
	if album == nil {
		return ""
	}
	return tidalJoinArtistNames(album.Artists)
}

func tidalTrackExternalURL(track *TidalTrack) string {
	if track == nil {
		return ""
	}
	if trimmed := strings.TrimSpace(track.URL); trimmed != "" {
		return strings.Replace(trimmed, "http://", "https://", 1)
	}
	if track.ID > 0 {
		return fmt.Sprintf("https://tidal.com/browse/track/%d", track.ID)
	}
	return ""
}

func tidalAlbumExternalURL(album *tidalPublicAlbum) string {
	if album == nil {
		return ""
	}
	if trimmed := strings.TrimSpace(album.URL); trimmed != "" {
		return strings.Replace(trimmed, "http://", "https://", 1)
	}
	if album.ID > 0 {
		return fmt.Sprintf("https://tidal.com/browse/album/%d", album.ID)
	}
	return ""
}

func tidalTrackToTrackMetadata(track *TidalTrack) TrackMetadata {
	if track == nil {
		return TrackMetadata{}
	}

	artistID := tidalPrefixedNumericID(track.Artist.ID)
	if artistID == "" && len(track.Artists) > 0 {
		artistID = tidalPrefixedNumericID(track.Artists[0].ID)
	}

	return TrackMetadata{
		SpotifyID:   tidalPrefixedNumericID(track.ID),
		Artists:     tidalTrackArtistsDisplay(track),
		Name:        strings.TrimSpace(track.Title),
		AlbumName:   strings.TrimSpace(track.Album.Title),
		AlbumArtist: strings.TrimSpace(track.Artist.Name),
		DurationMS:  track.Duration * 1000,
		Images:      tidalImageURL(track.Album.Cover, "1280x1280"),
		ReleaseDate: strings.TrimSpace(track.Album.ReleaseDate),
		TrackNumber: track.TrackNumber,
		DiscNumber:  track.VolumeNumber,
		ExternalURL: tidalTrackExternalURL(track),
		ISRC:        strings.TrimSpace(track.ISRC),
		AlbumID:     tidalPrefixedNumericID(track.Album.ID),
		ArtistID:    artistID,
	}
}

func tidalTrackToAlbumTrackMetadata(track *TidalTrack) AlbumTrackMetadata {
	if track == nil {
		return AlbumTrackMetadata{}
	}

	return AlbumTrackMetadata{
		SpotifyID:   tidalPrefixedNumericID(track.ID),
		Artists:     tidalTrackArtistsDisplay(track),
		Name:        strings.TrimSpace(track.Title),
		AlbumName:   strings.TrimSpace(track.Album.Title),
		AlbumArtist: strings.TrimSpace(track.Artist.Name),
		DurationMS:  track.Duration * 1000,
		Images:      tidalImageURL(track.Album.Cover, "1280x1280"),
		ReleaseDate: strings.TrimSpace(track.Album.ReleaseDate),
		TrackNumber: track.TrackNumber,
		DiscNumber:  track.VolumeNumber,
		ExternalURL: tidalTrackExternalURL(track),
		ISRC:        strings.TrimSpace(track.ISRC),
		AlbumID:     tidalPrefixedNumericID(track.Album.ID),
		AlbumURL:    strings.Replace(strings.TrimSpace(track.Album.URL), "http://", "https://", 1),
	}
}

func tidalAlbumToAlbumInfo(album *tidalPublicAlbum) AlbumInfoMetadata {
	if album == nil {
		return AlbumInfoMetadata{}
	}

	artistID := ""
	if len(album.Artists) > 0 {
		artistID = tidalPrefixedNumericID(album.Artists[0].ID)
	}

	return AlbumInfoMetadata{
		TotalTracks: album.NumberOfTracks,
		Name:        strings.TrimSpace(album.Title),
		ReleaseDate: strings.TrimSpace(album.ReleaseDate),
		Artists:     tidalAlbumArtistsDisplay(album),
		ArtistId:    artistID,
		Images:      tidalImageURL(album.Cover, "1280x1280"),
	}
}

func tidalAlbumToArtistAlbum(album *tidalPublicAlbum) ArtistAlbumMetadata {
	return tidalAlbumToArtistAlbumWithType(album, "")
}

func tidalAlbumToArtistAlbumWithType(album *tidalPublicAlbum, fallbackType string) ArtistAlbumMetadata {
	if album == nil {
		return ArtistAlbumMetadata{}
	}

	albumType := strings.ToLower(strings.TrimSpace(album.Type))
	if albumType == "" {
		albumType = strings.ToLower(strings.TrimSpace(fallbackType))
	}
	if albumType == "" {
		albumType = "album"
	}

	return ArtistAlbumMetadata{
		ID:          tidalPrefixedNumericID(album.ID),
		Name:        strings.TrimSpace(album.Title),
		ReleaseDate: strings.TrimSpace(album.ReleaseDate),
		TotalTracks: album.NumberOfTracks,
		Images:      tidalImageURL(album.Cover, "1280x1280"),
		AlbumType:   albumType,
		Artists:     tidalAlbumArtistsDisplay(album),
	}
}

func tidalPlaylistOwnerName(playlist *tidalPublicPlaylist) string {
	if playlist == nil {
		return ""
	}
	if trimmed := strings.TrimSpace(playlist.Creator.Name); trimmed != "" {
		return trimmed
	}
	if strings.EqualFold(strings.TrimSpace(playlist.Type), "ARTIST") {
		return "Artist"
	}
	return "TIDAL"
}

func tidalArtistAlbumTypeFromModuleTitle(title string) string {
	normalized := strings.ToLower(strings.TrimSpace(title))
	switch normalized {
	case "albums", "compilations", "appears on":
		return "album"
	case "ep & singles", "eps & singles", "singles", "ep", "eps":
		return "single"
	default:
		return ""
	}
}

func tidalBuildMetadataURL(path string, extraQuery url.Values) string {
	trimmedPath := strings.TrimLeft(strings.TrimSpace(path), "/")
	if trimmedPath == "" {
		return tidalPublicAPIBaseURL
	}

	baseURL, err := url.Parse(tidalPublicAPIBaseURL + "/" + trimmedPath)
	if err != nil {
		return tidalPublicAPIBaseURL + "/" + trimmedPath
	}

	query := baseURL.Query()
	query.Set("countryCode", tidalCountryCode)
	query.Set("locale", tidalLocale)
	query.Set("deviceType", tidalDeviceType)
	for key, values := range extraQuery {
		query.Del(key)
		for _, value := range values {
			query.Add(key, value)
		}
	}
	baseURL.RawQuery = query.Encode()
	return baseURL.String()
}

func (t *TidalDownloader) getTidalMetadataJSON(requestURL string, target interface{}) error {
	req, err := http.NewRequest("GET", requestURL, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("x-tidal-token", tidalPublicToken)

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return fmt.Errorf("tidal metadata request failed: HTTP %d (%s)", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	return json.NewDecoder(resp.Body).Decode(target)
}

func (t *TidalDownloader) getPublicTrack(resourceID string) (*TidalTrack, error) {
	trackID, err := strconv.ParseInt(strings.TrimSpace(resourceID), 10, 64)
	if err != nil || trackID <= 0 {
		return nil, fmt.Errorf("invalid tidal track ID: %s", resourceID)
	}

	requestURL := tidalBuildMetadataURL(fmt.Sprintf("tracks/%d", trackID), nil)
	var track TidalTrack
	if err := t.getTidalMetadataJSON(requestURL, &track); err != nil {
		return nil, err
	}
	return &track, nil
}

func (t *TidalDownloader) getAlbumPage(resourceID string) (*tidalPublicAlbumPage, error) {
	albumID := strings.TrimSpace(resourceID)
	if albumID == "" {
		return nil, fmt.Errorf("invalid tidal album ID")
	}

	requestURL := tidalBuildMetadataURL("pages/album", url.Values{"albumId": {albumID}})
	var page tidalPublicAlbumPage
	if err := t.getTidalMetadataJSON(requestURL, &page); err != nil {
		return nil, err
	}
	return &page, nil
}

func (t *TidalDownloader) getArtistPage(resourceID string) (*tidalPublicArtistPage, error) {
	artistID := strings.TrimSpace(resourceID)
	if artistID == "" {
		return nil, fmt.Errorf("invalid tidal artist ID")
	}

	requestURL := tidalBuildMetadataURL("pages/artist", url.Values{"artistId": {artistID}})
	var page tidalPublicArtistPage
	if err := t.getTidalMetadataJSON(requestURL, &page); err != nil {
		return nil, err
	}
	return &page, nil
}

func (t *TidalDownloader) getArtistAlbumsPage(dataAPIPath string, offset, limit int) (*tidalPublicArtistAlbumsPage, error) {
	extraQuery := url.Values{}
	if offset >= 0 {
		extraQuery.Set("offset", strconv.Itoa(offset))
	}
	if limit > 0 {
		extraQuery.Set("limit", strconv.Itoa(limit))
	}

	requestURL := tidalBuildMetadataURL(dataAPIPath, extraQuery)
	var page tidalPublicArtistAlbumsPage
	if err := t.getTidalMetadataJSON(requestURL, &page); err != nil {
		return nil, err
	}
	return &page, nil
}

func (t *TidalDownloader) getPlaylist(resourceID string) (*tidalPublicPlaylist, error) {
	playlistID := strings.TrimSpace(resourceID)
	if playlistID == "" {
		return nil, fmt.Errorf("invalid tidal playlist ID")
	}

	requestURL := tidalBuildMetadataURL("playlists/"+url.PathEscape(playlistID), nil)
	var playlist tidalPublicPlaylist
	if err := t.getTidalMetadataJSON(requestURL, &playlist); err != nil {
		return nil, err
	}
	return &playlist, nil
}

func (t *TidalDownloader) getPlaylistItemsPage(resourceID string, offset, limit int) (*tidalPublicPlaylistItemsPage, error) {
	playlistID := strings.TrimSpace(resourceID)
	if playlistID == "" {
		return nil, fmt.Errorf("invalid tidal playlist ID")
	}

	requestURL := tidalBuildMetadataURL(
		"playlists/"+url.PathEscape(playlistID)+"/items",
		url.Values{
			"offset": {strconv.Itoa(offset)},
			"limit":  {strconv.Itoa(limit)},
		},
	)
	var page tidalPublicPlaylistItemsPage
	if err := t.getTidalMetadataJSON(requestURL, &page); err != nil {
		return nil, err
	}
	return &page, nil
}

func (t *TidalDownloader) getTrackSearchPage(query string, limit int) (*tidalPublicTrackSearchResponse, error) {
	cleanQuery := strings.TrimSpace(query)
	if cleanQuery == "" {
		return nil, fmt.Errorf("empty tidal search query")
	}
	if limit <= 0 {
		limit = 20
	}

	requestURL := tidalBuildMetadataURL(
		"search/tracks",
		url.Values{
			"query":  {cleanQuery},
			"limit":  {strconv.Itoa(limit)},
			"offset": {"0"},
		},
	)
	var page tidalPublicTrackSearchResponse
	if err := t.getTidalMetadataJSON(requestURL, &page); err != nil {
		return nil, err
	}
	return &page, nil
}

func findTidalAlbumPageModule(page *tidalPublicAlbumPage, moduleType string) *struct {
	Type      string           `json:"type"`
	Album     tidalPublicAlbum `json:"album"`
	PagedList struct {
		DataAPIPath        string `json:"dataApiPath"`
		Limit              int    `json:"limit"`
		Offset             int    `json:"offset"`
		TotalNumberOfItems int    `json:"totalNumberOfItems"`
		Items              []struct {
			Item TidalTrack `json:"item"`
			Type string     `json:"type"`
		} `json:"items"`
	} `json:"pagedList"`
} {
	if page == nil {
		return nil
	}
	for rowIndex := range page.Rows {
		for moduleIndex := range page.Rows[rowIndex].Modules {
			module := &page.Rows[rowIndex].Modules[moduleIndex]
			if module.Type == moduleType {
				return module
			}
		}
	}
	return nil
}

func findTidalArtistPageModule(page *tidalPublicArtistPage, moduleType string) *struct {
	Type   string `json:"type"`
	Title  string `json:"title"`
	Artist struct {
		ID      int64  `json:"id"`
		Name    string `json:"name"`
		URL     string `json:"url"`
		Picture string `json:"picture"`
	} `json:"artist"`
	PagedList struct {
		DataAPIPath        string             `json:"dataApiPath"`
		Limit              int                `json:"limit"`
		Offset             int                `json:"offset"`
		TotalNumberOfItems int                `json:"totalNumberOfItems"`
		Items              []tidalPublicAlbum `json:"items"`
	} `json:"pagedList"`
} {
	if page == nil {
		return nil
	}
	for rowIndex := range page.Rows {
		for moduleIndex := range page.Rows[rowIndex].Modules {
			module := &page.Rows[rowIndex].Modules[moduleIndex]
			if module.Type == moduleType {
				return module
			}
		}
	}
	return nil
}

func (t *TidalDownloader) GetAvailableAPIs() []string {
	return []string{
		"https://eu-central.monochrome.tf",
		"https://us-west.monochrome.tf",
		"https://api.monochrome.tf",
		"https://monochrome-api.samidy.com",
		"https://tidal-api.binimum.org",
		"https://tidal.kinoplus.online",
		"https://triton.squid.wtf",
		"https://vogel.qqdl.site",
		"https://maus.qqdl.site",
		"https://hund.qqdl.site",
		"https://katze.qqdl.site",
		"https://wolf.qqdl.site",
		"https://hifi-one.spotisaver.net",
		"https://hifi-two.spotisaver.net",
	}
}

func (t *TidalDownloader) GetAccessToken() (string, error) {
	return "", fmt.Errorf("tidal official metadata API disabled: no client credentials mode")
}

func (t *TidalDownloader) GetTidalURLFromSpotify(spotifyTrackID string) (string, error) {
	spotifyURL := fmt.Sprintf("%s%s", spotifyTrackBaseURL, spotifyTrackID)
	apiURL := fmt.Sprintf("%s%s", songLinkLookupBaseURL, url.QueryEscape(spotifyURL))

	req, err := http.NewRequest("GET", apiURL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		return "", fmt.Errorf("failed to get Tidal URL: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("SongLink API returned status %d", resp.StatusCode)
	}

	var songLinkResp struct {
		LinksByPlatform map[string]struct {
			URL string `json:"url"`
		} `json:"linksByPlatform"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&songLinkResp); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	tidalLink, ok := songLinkResp.LinksByPlatform["tidal"]
	if !ok || tidalLink.URL == "" {
		return "", fmt.Errorf("tidal link not found in SongLink")
	}

	return tidalLink.URL, nil
}

func (t *TidalDownloader) GetTrackIDFromURL(tidalURL string) (int64, error) {
	parts := strings.Split(tidalURL, "/track/")
	if len(parts) < 2 {
		return 0, fmt.Errorf("invalid tidal URL format")
	}

	trackIDStr := strings.Split(parts[1], "?")[0]
	trackIDStr = strings.TrimSpace(trackIDStr)

	var trackID int64
	_, err := fmt.Sscanf(trackIDStr, "%d", &trackID)
	if err != nil {
		return 0, fmt.Errorf("failed to parse track ID: %w", err)
	}

	return trackID, nil
}

func (t *TidalDownloader) GetTrackInfoByID(trackID int64) (*TidalTrack, error) {
	return nil, fmt.Errorf("tidal track lookup API disabled: no client credentials mode")
}

func (t *TidalDownloader) SearchTrackByISRC(isrc string) (*TidalTrack, error) {
	normalizedISRC := strings.ToUpper(strings.TrimSpace(isrc))
	if normalizedISRC == "" {
		return nil, fmt.Errorf("empty tidal ISRC")
	}

	page, err := tidalGetTrackSearchPageFunc(t, normalizedISRC, 20)
	if err != nil {
		return nil, err
	}

	for i := range page.Items {
		if strings.EqualFold(strings.TrimSpace(page.Items[i].ISRC), normalizedISRC) {
			return &page.Items[i], nil
		}
	}

	return nil, fmt.Errorf("no exact tidal ISRC match found for %s", normalizedISRC)
}

func (t *TidalDownloader) SearchTrackByMetadataWithISRC(trackName, artistName, albumName, spotifyISRC string, expectedDuration int) (*TidalTrack, error) {
	queryParts := make([]string, 0, 3)
	if trimmed := strings.TrimSpace(trackName); trimmed != "" {
		queryParts = append(queryParts, trimmed)
	}
	if trimmed := strings.TrimSpace(artistName); trimmed != "" {
		queryParts = append(queryParts, trimmed)
	}
	if len(queryParts) == 0 {
		return nil, fmt.Errorf("tidal metadata search requires track or artist name")
	}

	queries := []string{strings.Join(queryParts, " ")}
	if trimmedAlbum := strings.TrimSpace(albumName); trimmedAlbum != "" {
		queries = append(queries, strings.Join(append(queryParts, trimmedAlbum), " "))
	}

	req := DownloadRequest{
		TrackName:  strings.TrimSpace(trackName),
		ArtistName: strings.TrimSpace(artistName),
		AlbumName:  strings.TrimSpace(albumName),
		ISRC:       strings.ToUpper(strings.TrimSpace(spotifyISRC)),
		DurationMS: expectedDuration * 1000,
	}

	seenQueries := make(map[string]struct{}, len(queries))
	for _, query := range queries {
		if _, seen := seenQueries[query]; seen {
			continue
		}
		seenQueries[query] = struct{}{}

		page, err := tidalGetTrackSearchPageFunc(t, query, 20)
		if err != nil {
			return nil, err
		}

		var candidates []*TidalTrack
		for i := range page.Items {
			track := &page.Items[i]
			if req.ISRC != "" && !strings.EqualFold(strings.TrimSpace(track.ISRC), req.ISRC) {
				continue
			}
			resolved := resolvedTrackInfo{
				Title:      strings.TrimSpace(track.Title),
				ArtistName: tidalTrackArtistsDisplay(track),
				ISRC:       strings.TrimSpace(track.ISRC),
				Duration:   track.Duration,
			}
			if trackMatchesRequest(req, resolved, "Tidal search") {
				candidates = append(candidates, track)
			}
		}

		if len(candidates) == 0 {
			continue
		}

		if req.AlbumName != "" {
			for _, candidate := range candidates {
				if titlesMatch(req.AlbumName, candidate.Album.Title) {
					return candidate, nil
				}
			}
		}

		return candidates[0], nil
	}

	if req.ISRC != "" {
		return nil, fmt.Errorf("no tidal metadata match found for exact ISRC %s", req.ISRC)
	}
	return nil, fmt.Errorf("no tidal metadata match found")
}

func (t *TidalDownloader) SearchTrackByMetadata(trackName, artistName string) (*TidalTrack, error) {
	return t.SearchTrackByMetadataWithISRC(trackName, artistName, "", "", 0)
}

func (t *TidalDownloader) SearchTracks(query string, limit int) ([]ExtTrackMetadata, error) {
	page, err := t.getTrackSearchPage(query, limit)
	if err != nil {
		return nil, err
	}

	results := make([]ExtTrackMetadata, 0, len(page.Items))
	for i := range page.Items {
		results = append(results, normalizeBuiltInMetadataTrack(tidalTrackToTrackMetadata(&page.Items[i]), "tidal"))
	}
	return results, nil
}

func (t *TidalDownloader) SearchAll(query string, trackLimit, artistLimit int, filter string) (*SearchAllResult, error) {
	GoLog("[Tidal] SearchAll: query=%q, trackLimit=%d, artistLimit=%d, filter=%q\n", query, trackLimit, artistLimit, filter)

	cleanQuery := strings.TrimSpace(query)
	if cleanQuery == "" {
		return nil, fmt.Errorf("empty tidal search query")
	}

	albumLimit := 5

	if filter != "" {
		switch filter {
		case "track":
			trackLimit = 50
			artistLimit = 0
			albumLimit = 0
		case "artist":
			trackLimit = 0
			artistLimit = 20
			albumLimit = 0
		case "album":
			trackLimit = 0
			artistLimit = 0
			albumLimit = 20
		}
	}

	result := &SearchAllResult{
		Tracks:    make([]TrackMetadata, 0, trackLimit),
		Artists:   make([]SearchArtistResult, 0, artistLimit),
		Albums:    make([]SearchAlbumResult, 0, albumLimit),
		Playlists: make([]SearchPlaylistResult, 0),
	}

	if trackLimit > 0 {
		page, err := t.getTrackSearchPage(cleanQuery, trackLimit)
		if err != nil {
			GoLog("[Tidal] Track search failed: %v\n", err)
			return nil, fmt.Errorf("tidal track search failed: %w", err)
		}
		GoLog("[Tidal] Got %d tracks from API\n", len(page.Items))
		for i := range page.Items {
			result.Tracks = append(result.Tracks, tidalTrackToTrackMetadata(&page.Items[i]))
		}
	}

	if artistLimit > 0 {
		requestURL := tidalBuildMetadataURL("search/artists", url.Values{
			"query":  {cleanQuery},
			"limit":  {strconv.Itoa(artistLimit)},
			"offset": {"0"},
		})
		var artistResp struct {
			Items []struct {
				ID         int64  `json:"id"`
				Name       string `json:"name"`
				Picture    string `json:"picture"`
				Popularity int    `json:"popularity"`
				URL        string `json:"url"`
			} `json:"items"`
		}
		if err := t.getTidalMetadataJSON(requestURL, &artistResp); err == nil {
			GoLog("[Tidal] Got %d artists from API\n", len(artistResp.Items))
			for _, artist := range artistResp.Items {
				result.Artists = append(result.Artists, SearchArtistResult{
					ID:         tidalPrefixedNumericID(artist.ID),
					Name:       strings.TrimSpace(artist.Name),
					Images:     tidalImageURL(artist.Picture, "750x750"),
					Followers:  0,
					Popularity: artist.Popularity,
				})
			}
		} else {
			GoLog("[Tidal] Artist search failed: %v\n", err)
		}
	}

	if albumLimit > 0 {
		requestURL := tidalBuildMetadataURL("search/albums", url.Values{
			"query":  {cleanQuery},
			"limit":  {strconv.Itoa(albumLimit)},
			"offset": {"0"},
		})
		var albumResp struct {
			Items []tidalPublicAlbum `json:"items"`
		}
		if err := t.getTidalMetadataJSON(requestURL, &albumResp); err == nil {
			GoLog("[Tidal] Got %d albums from API\n", len(albumResp.Items))
			for i := range albumResp.Items {
				album := &albumResp.Items[i]
				albumType := strings.ToLower(strings.TrimSpace(album.Type))
				if albumType == "" {
					albumType = "album"
				}
				result.Albums = append(result.Albums, SearchAlbumResult{
					ID:          tidalPrefixedNumericID(album.ID),
					Name:        strings.TrimSpace(album.Title),
					Artists:     tidalAlbumArtistsDisplay(album),
					Images:      tidalImageURL(album.Cover, "1280x1280"),
					ReleaseDate: strings.TrimSpace(album.ReleaseDate),
					TotalTracks: album.NumberOfTracks,
					AlbumType:   albumType,
				})
			}
		} else {
			GoLog("[Tidal] Album search failed: %v\n", err)
		}
	}

	GoLog("[Tidal] SearchAll complete: %d tracks, %d artists, %d albums\n", len(result.Tracks), len(result.Artists), len(result.Albums))
	return result, nil
}

func (t *TidalDownloader) GetTrackMetadata(resourceID string) (*TrackResponse, error) {
	track, err := t.getPublicTrack(resourceID)
	if err != nil {
		return nil, err
	}
	return &TrackResponse{Track: tidalTrackToTrackMetadata(track)}, nil
}

func (t *TidalDownloader) GetAlbumMetadata(resourceID string) (*AlbumResponsePayload, error) {
	page, err := t.getAlbumPage(resourceID)
	if err != nil {
		return nil, err
	}

	headerModule := findTidalAlbumPageModule(page, "ALBUM_HEADER")
	itemsModule := findTidalAlbumPageModule(page, "ALBUM_ITEMS")
	if headerModule == nil {
		return nil, fmt.Errorf("tidal album page missing album header")
	}
	if itemsModule == nil {
		return nil, fmt.Errorf("tidal album page missing track list")
	}

	tracks := make([]AlbumTrackMetadata, 0, len(itemsModule.PagedList.Items))
	totalDiscs := 0
	for _, item := range itemsModule.PagedList.Items {
		track := item.Item
		track.Album.ID = headerModule.Album.ID
		track.Album.Title = headerModule.Album.Title
		track.Album.Cover = headerModule.Album.Cover
		track.Album.ReleaseDate = headerModule.Album.ReleaseDate
		track.Album.URL = headerModule.Album.URL
		if track.VolumeNumber > totalDiscs {
			totalDiscs = track.VolumeNumber
		}
		tracks = append(tracks, tidalTrackToAlbumTrackMetadata(&track))
	}
	for i := range tracks {
		tracks[i].TotalDiscs = totalDiscs
	}

	return &AlbumResponsePayload{
		AlbumInfo: tidalAlbumToAlbumInfo(&headerModule.Album),
		TrackList: tracks,
	}, nil
}

func (t *TidalDownloader) GetPlaylistMetadata(resourceID string) (*PlaylistResponsePayload, error) {
	playlist, err := t.getPlaylist(resourceID)
	if err != nil {
		return nil, err
	}

	const pageSize = 50
	offset := 0
	totalTracks := playlist.NumberOfTracks
	tracks := make([]AlbumTrackMetadata, 0, totalTracks)

	for {
		page, pageErr := t.getPlaylistItemsPage(resourceID, offset, pageSize)
		if pageErr != nil {
			return nil, pageErr
		}
		if totalTracks == 0 && page.TotalNumberOfItems > 0 {
			totalTracks = page.TotalNumberOfItems
		}

		for _, item := range page.Items {
			if item.Type != "track" {
				continue
			}
			tracks = append(tracks, tidalTrackToAlbumTrackMetadata(&item.Item))
		}

		if len(page.Items) == 0 || offset+len(page.Items) >= totalTracks || len(page.Items) < pageSize {
			break
		}
		offset += len(page.Items)
	}

	var info PlaylistInfoMetadata
	info.Tracks.Total = totalTracks
	info.Name = strings.TrimSpace(playlist.Title)
	info.Images = tidalImageURL(tidalFirstNonEmpty(playlist.SquareImage, playlist.Image), "origin")
	info.Owner.DisplayName = tidalPlaylistOwnerName(playlist)
	info.Owner.Name = strings.TrimSpace(playlist.Title)
	info.Owner.Images = info.Images

	return &PlaylistResponsePayload{
		PlaylistInfo: info,
		TrackList:    tracks,
	}, nil
}

func (t *TidalDownloader) GetArtistMetadata(resourceID string) (*ArtistResponsePayload, error) {
	page, err := t.getArtistPage(resourceID)
	if err != nil {
		return nil, err
	}

	headerModule := findTidalArtistPageModule(page, "ARTIST_HEADER")
	albumsModule := findTidalArtistPageModule(page, "ALBUM_LIST")
	if headerModule == nil {
		return nil, fmt.Errorf("tidal artist page missing artist header")
	}
	if albumsModule == nil {
		return nil, fmt.Errorf("tidal artist page missing albums list")
	}

	albums := make([]ArtistAlbumMetadata, 0, albumsModule.PagedList.TotalNumberOfItems)
	seenAlbumIDs := make(map[string]struct{})

	appendArtistAlbum := func(album tidalPublicAlbum, fallbackType string) {
		mapped := tidalAlbumToArtistAlbumWithType(&album, fallbackType)
		if mapped.ID == "" {
			return
		}
		if _, exists := seenAlbumIDs[mapped.ID]; exists {
			return
		}
		seenAlbumIDs[mapped.ID] = struct{}{}
		albums = append(albums, mapped)
	}

	for rowIndex := range page.Rows {
		for moduleIndex := range page.Rows[rowIndex].Modules {
			module := &page.Rows[rowIndex].Modules[moduleIndex]
			if module.Type != "ALBUM_LIST" {
				continue
			}

			fallbackType := tidalArtistAlbumTypeFromModuleTitle(module.Title)
			for _, album := range module.PagedList.Items {
				appendArtistAlbum(album, fallbackType)
			}

			pageSize := module.PagedList.Limit
			if pageSize <= 0 {
				pageSize = 50
			}
			offset := len(module.PagedList.Items)
			for offset < module.PagedList.TotalNumberOfItems && strings.TrimSpace(module.PagedList.DataAPIPath) != "" {
				albumsPage, pageErr := t.getArtistAlbumsPage(module.PagedList.DataAPIPath, offset, pageSize)
				if pageErr != nil {
					return nil, pageErr
				}

				for _, album := range albumsPage.Items {
					appendArtistAlbum(album, fallbackType)
				}

				if len(albumsPage.Items) == 0 || offset+len(albumsPage.Items) >= albumsPage.TotalNumberOfItems {
					break
				}
				offset += len(albumsPage.Items)
			}
		}
	}

	return &ArtistResponsePayload{
		ArtistInfo: ArtistInfoMetadata{
			ID:     tidalPrefixedNumericID(headerModule.Artist.ID),
			Name:   strings.TrimSpace(headerModule.Artist.Name),
			Images: tidalImageURL(headerModule.Artist.Picture, "750x750"),
		},
		Albums: albums,
	}, nil
}

type TidalDownloadInfo struct {
	URL        string
	BitDepth   int
	SampleRate int
}

type tidalAPIResult struct {
	apiURL   string
	info     TidalDownloadInfo
	err      error
	duration time.Duration
}

const (
	tidalAPITimeoutMobile = 25 * time.Second
	tidalMaxRetries       = 2
	tidalRetryDelay       = 500 * time.Millisecond
)

func fetchTidalURLWithRetry(api string, trackID int64, quality string, timeout time.Duration) (TidalDownloadInfo, error) {
	var lastErr error
	retryDelay := tidalRetryDelay

	for attempt := 0; attempt <= tidalMaxRetries; attempt++ {
		if attempt > 0 {
			GoLog("[Tidal] Retry %d/%d for %s after %v\n", attempt, tidalMaxRetries, api, retryDelay)
			time.Sleep(retryDelay)
			retryDelay *= 2
		}

		client := NewHTTPClientWithTimeout(timeout)
		reqURL := fmt.Sprintf("%s/track/?id=%d&quality=%s", api, trackID, quality)

		req, err := http.NewRequest("GET", reqURL, nil)
		if err != nil {
			lastErr = err
			continue
		}

		resp, err := client.Do(req)
		if err != nil {
			lastErr = err
			errStr := strings.ToLower(err.Error())
			if strings.Contains(errStr, "timeout") ||
				strings.Contains(errStr, "reset") ||
				strings.Contains(errStr, "connection refused") ||
				strings.Contains(errStr, "eof") {
				continue
			}
			break
		}
		if resp.StatusCode >= 500 {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			lastErr = fmt.Errorf("HTTP %d", resp.StatusCode)
			continue
		}

		if resp.StatusCode == 429 {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			lastErr = fmt.Errorf("rate limited")
			retryDelay = 2 * time.Second
			continue
		}

		if resp.StatusCode != 200 {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			return TidalDownloadInfo{}, fmt.Errorf("HTTP %d", resp.StatusCode)
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			lastErr = err
			continue
		}

		var v2Response TidalAPIResponseV2
		if err := json.Unmarshal(body, &v2Response); err == nil && v2Response.Data.Manifest != "" {
			if v2Response.Data.AssetPresentation == "PREVIEW" {
				return TidalDownloadInfo{}, fmt.Errorf("returned PREVIEW instead of FULL")
			}

			return TidalDownloadInfo{
				URL:        "MANIFEST:" + v2Response.Data.Manifest,
				BitDepth:   v2Response.Data.BitDepth,
				SampleRate: v2Response.Data.SampleRate,
			}, nil
		}

		var v1Responses []struct {
			OriginalTrackURL string `json:"OriginalTrackUrl"`
		}
		if err := json.Unmarshal(body, &v1Responses); err == nil {
			for _, item := range v1Responses {
				if item.OriginalTrackURL != "" {
					return TidalDownloadInfo{
						URL:        item.OriginalTrackURL,
						BitDepth:   16,
						SampleRate: 44100,
					}, nil
				}
			}
		}

		return TidalDownloadInfo{}, fmt.Errorf("no download URL or manifest in response")
	}

	if lastErr != nil {
		return TidalDownloadInfo{}, lastErr
	}
	return TidalDownloadInfo{}, fmt.Errorf("all retries failed")
}

func getDownloadURLParallel(apis []string, trackID int64, quality string) (string, TidalDownloadInfo, error) {
	if len(apis) == 0 {
		return "", TidalDownloadInfo{}, fmt.Errorf("no APIs available")
	}

	GoLog("[Tidal] Requesting download URL from %d APIs in parallel (with retry)...\n", len(apis))

	resultChan := make(chan tidalAPIResult, len(apis))
	startTime := time.Now()

	for _, apiURL := range apis {
		go func(api string) {
			reqStart := time.Now()
			info, err := fetchTidalURLWithRetry(api, trackID, quality, tidalAPITimeoutMobile)
			resultChan <- tidalAPIResult{
				apiURL:   api,
				info:     info,
				err:      err,
				duration: time.Since(reqStart),
			}
		}(apiURL)
	}

	var errors []string

	for i := 0; i < len(apis); i++ {
		result := <-resultChan
		if result.err == nil {
			GoLog("[Tidal] [Parallel] Got response from %s (%d-bit/%dHz) in %v\n",
				result.apiURL, result.info.BitDepth, result.info.SampleRate, result.duration)

			go func(remaining int) {
				for j := 0; j < remaining; j++ {
					<-resultChan
				}
			}(len(apis) - i - 1)

			GoLog("[Tidal] [Parallel] Total time: %v (first success)\n", time.Since(startTime))
			return result.apiURL, result.info, nil
		}
		errMsg := result.err.Error()
		if len(errMsg) > 50 {
			errMsg = errMsg[:50] + "..."
		}
		errors = append(errors, fmt.Sprintf("%s: %s", result.apiURL, errMsg))
	}

	GoLog("[Tidal] [Parallel] All %d APIs failed in %v\n", len(apis), time.Since(startTime))
	return "", TidalDownloadInfo{}, fmt.Errorf("all %d Tidal APIs failed. Errors: %v", len(apis), errors)
}

func (t *TidalDownloader) GetDownloadURL(trackID int64, quality string) (TidalDownloadInfo, error) {
	apis := t.GetAvailableAPIs()
	if len(apis) == 0 {
		return TidalDownloadInfo{}, fmt.Errorf("no API URL configured")
	}

	_, info, err := getDownloadURLParallel(apis, trackID, quality)
	if err != nil {
		return TidalDownloadInfo{}, fmt.Errorf("failed to get download URL: %w", err)
	}

	return info, nil
}

func parseManifest(manifestB64 string) (directURL string, initURL string, mediaURLs []string, err error) {
	manifestBytes, err := base64.StdEncoding.DecodeString(manifestB64)
	if err != nil {
		return "", "", nil, fmt.Errorf("failed to decode manifest: %w", err)
	}

	manifestStr := string(manifestBytes)

	manifestPreview := manifestStr
	if len(manifestPreview) > 500 {
		manifestPreview = manifestPreview[:500] + "..."
	}
	GoLog("[Tidal] Manifest content: %s\n", manifestPreview)

	if strings.HasPrefix(manifestStr, "{") {
		var btsManifest TidalBTSManifest
		if err := json.Unmarshal(manifestBytes, &btsManifest); err != nil {
			return "", "", nil, fmt.Errorf("failed to parse BTS manifest: %w", err)
		}

		if len(btsManifest.URLs) == 0 {
			return "", "", nil, fmt.Errorf("no URLs in BTS manifest")
		}

		return btsManifest.URLs[0], "", nil, nil
	}

	var mpd MPD
	if err := xml.Unmarshal(manifestBytes, &mpd); err != nil {
		return "", "", nil, fmt.Errorf("failed to parse manifest XML: %w", err)
	}

	segTemplate := mpd.Period.AdaptationSet.Representation.SegmentTemplate
	initURL = segTemplate.Initialization
	mediaTemplate := segTemplate.Media

	if initURL == "" || mediaTemplate == "" {
		initRe := regexp.MustCompile(`initialization="([^"]+)"`)
		mediaRe := regexp.MustCompile(`media="([^"]+)"`)

		if match := initRe.FindStringSubmatch(manifestStr); len(match) > 1 {
			initURL = match[1]
		}
		if match := mediaRe.FindStringSubmatch(manifestStr); len(match) > 1 {
			mediaTemplate = match[1]
		}
	}

	if initURL == "" {
		return "", "", nil, fmt.Errorf("no initialization URL found in manifest")
	}

	initURL = strings.ReplaceAll(initURL, "&amp;", "&")
	mediaTemplate = strings.ReplaceAll(mediaTemplate, "&amp;", "&")

	segmentCount := 0
	GoLog("[Tidal] XML parsed segments: %d entries in timeline\n", len(segTemplate.Timeline.Segments))
	for i, seg := range segTemplate.Timeline.Segments {
		GoLog("[Tidal] Segment[%d]: d=%d, r=%d\n", i, seg.Duration, seg.Repeat)
		segmentCount += seg.Repeat + 1
	}
	GoLog("[Tidal] Segment count from XML: %d\n", segmentCount)

	if segmentCount == 0 {
		fmt.Println("[Tidal] No segments from XML, trying regex...")
		segRe := regexp.MustCompile(`<S\s+d="(\d+)"(?:\s+r="(\d+)")?`)
		matches := segRe.FindAllStringSubmatch(manifestStr, -1)
		GoLog("[Tidal] Regex found %d segment entries\n", len(matches))
		for i, match := range matches {
			repeat := 0
			if len(match) > 2 && match[2] != "" {
				fmt.Sscanf(match[2], "%d", &repeat)
			}
			if i < 5 || i == len(matches)-1 {
				GoLog("[Tidal] Regex segment[%d]: d=%s, r=%d\n", i, match[1], repeat)
			}
			segmentCount += repeat + 1
		}
		GoLog("[Tidal] Total segments from regex: %d\n", segmentCount)
	}

	if segmentCount == 0 {
		return "", "", nil, fmt.Errorf("no segments found in manifest")
	}

	for i := 1; i <= segmentCount; i++ {
		mediaURL := strings.ReplaceAll(mediaTemplate, "$Number$", fmt.Sprintf("%d", i))
		mediaURLs = append(mediaURLs, mediaURL)
	}

	return "", initURL, mediaURLs, nil
}

func (t *TidalDownloader) DownloadFile(downloadURL, outputPath string, outputFD int, itemID string) error {
	ctx := context.Background()

	if strings.HasPrefix(downloadURL, "MANIFEST:") {
		if itemID != "" {
			StartItemProgress(itemID)
			defer CompleteItemProgress(itemID)
			ctx = initDownloadCancel(itemID)
			defer clearDownloadCancel(itemID)
		}
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return t.downloadFromManifest(ctx, strings.TrimPrefix(downloadURL, "MANIFEST:"), outputPath, outputFD, itemID)
	}

	if itemID != "" {
		StartItemProgress(itemID)
		defer CompleteItemProgress(itemID)
		ctx = initDownloadCancel(itemID)
		defer clearDownloadCancel(itemID)
	}

	if isDownloadCancelled(itemID) {
		return ErrDownloadCancelled
	}

	req, err := http.NewRequestWithContext(ctx, "GET", downloadURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("download failed: HTTP %d", resp.StatusCode)
	}

	expectedSize := resp.ContentLength
	if expectedSize > 0 && itemID != "" {
		SetItemBytesTotal(itemID, expectedSize)
	}

	out, err := openOutputForWrite(outputPath, outputFD)
	if err != nil {
		return err
	}

	bufWriter := bufio.NewWriterSize(out, 256*1024)

	var written int64
	if itemID != "" {
		progressWriter := NewItemProgressWriter(bufWriter, itemID)
		written, err = io.Copy(progressWriter, resp.Body)
	} else {
		written, err = io.Copy(bufWriter, resp.Body)
	}

	flushErr := bufWriter.Flush()
	closeErr := out.Close()

	if err != nil {
		cleanupOutputOnError(outputPath, outputFD)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return fmt.Errorf("download interrupted: %w", err)
	}
	if flushErr != nil {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("failed to flush buffer: %w", flushErr)
	}
	if closeErr != nil {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("failed to close file: %w", closeErr)
	}

	if expectedSize > 0 && written != expectedSize {
		cleanupOutputOnError(outputPath, outputFD)
		return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
	}

	return nil
}

func (t *TidalDownloader) downloadFromManifest(ctx context.Context, manifestB64, outputPath string, outputFD int, itemID string) error {
	fmt.Println("[Tidal] Parsing manifest...")
	directURL, initURL, mediaURLs, err := parseManifest(manifestB64)
	if err != nil {
		GoLog("[Tidal] Manifest parse error: %v\n", err)
		return fmt.Errorf("failed to parse manifest: %w", err)
	}
	GoLog("[Tidal] Manifest parsed - directURL: %v, initURL: %v, mediaURLs count: %d\n",
		directURL != "", initURL != "", len(mediaURLs))

	client := NewHTTPClientWithTimeout(DownloadTimeout)

	if directURL != "" {
		GoLog("[Tidal] BTS format - downloading from direct URL: %s...\n", directURL[:min(80, len(directURL))])
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}

		req, err := http.NewRequestWithContext(ctx, "GET", directURL, nil)
		if err != nil {
			GoLog("[Tidal] BTS request creation failed: %v\n", err)
			return fmt.Errorf("failed to create request: %w", err)
		}

		resp, err := client.Do(req)
		if err != nil {
			if isDownloadCancelled(itemID) {
				return ErrDownloadCancelled
			}
			GoLog("[Tidal] BTS download failed: %v\n", err)
			return fmt.Errorf("failed to download file: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			GoLog("[Tidal] BTS download HTTP error: %d\n", resp.StatusCode)
			return fmt.Errorf("download failed with status %d", resp.StatusCode)
		}
		GoLog("[Tidal] BTS response OK, Content-Length: %d\n", resp.ContentLength)

		expectedSize := resp.ContentLength
		if expectedSize > 0 && itemID != "" {
			SetItemBytesTotal(itemID, expectedSize)
		}

		out, err := openOutputForWrite(outputPath, outputFD)
		if err != nil {
			return fmt.Errorf("failed to create file: %w", err)
		}

		var written int64
		if itemID != "" {
			progressWriter := NewItemProgressWriter(out, itemID)
			written, err = io.Copy(progressWriter, resp.Body)
		} else {
			written, err = io.Copy(out, resp.Body)
		}

		closeErr := out.Close()

		if err != nil {
			cleanupOutputOnError(outputPath, outputFD)
			if isDownloadCancelled(itemID) {
				return ErrDownloadCancelled
			}
			return fmt.Errorf("download interrupted: %w", err)
		}
		if closeErr != nil {
			cleanupOutputOnError(outputPath, outputFD)
			return fmt.Errorf("failed to close file: %w", closeErr)
		}

		if expectedSize > 0 && written != expectedSize {
			cleanupOutputOnError(outputPath, outputFD)
			return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
		}

		return nil
	}

	var m4aPath string
	if strings.HasSuffix(outputPath, ".m4a") {
		m4aPath = outputPath
	} else if strings.HasSuffix(outputPath, ".flac") {
		m4aPath = strings.TrimSuffix(outputPath, ".flac") + ".m4a"
	} else {
		m4aPath = outputPath
	}
	GoLog("[Tidal] DASH format - downloading %d segments directly to: %s\n", len(mediaURLs), m4aPath)

	out, err := openOutputForWrite(m4aPath, outputFD)
	if err != nil {
		GoLog("[Tidal] Failed to create M4A file: %v\n", err)
		return fmt.Errorf("failed to create M4A file: %w", err)
	}

	GoLog("[Tidal] Downloading init segment...\n")
	if isDownloadCancelled(itemID) {
		out.Close()
		cleanupOutputOnError(m4aPath, outputFD)
		return ErrDownloadCancelled
	}
	req, err := http.NewRequestWithContext(ctx, "GET", initURL, nil)
	if err != nil {
		out.Close()
		cleanupOutputOnError(m4aPath, outputFD)
		GoLog("[Tidal] Init segment request failed: %v\n", err)
		return fmt.Errorf("failed to create init segment request: %w", err)
	}
	resp, err := client.Do(req)
	if err != nil {
		out.Close()
		cleanupOutputOnError(m4aPath, outputFD)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		GoLog("[Tidal] Init segment download failed: %v\n", err)
		return fmt.Errorf("failed to download init segment: %w", err)
	}
	if resp.StatusCode != 200 {
		resp.Body.Close()
		out.Close()
		cleanupOutputOnError(m4aPath, outputFD)
		GoLog("[Tidal] Init segment HTTP error: %d\n", resp.StatusCode)
		return fmt.Errorf("init segment download failed with status %d", resp.StatusCode)
	}
	_, err = io.Copy(out, resp.Body)
	resp.Body.Close()
	if err != nil {
		out.Close()
		cleanupOutputOnError(m4aPath, outputFD)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		GoLog("[Tidal] Init segment write failed: %v\n", err)
		return fmt.Errorf("failed to write init segment: %w", err)
	}

	totalSegments := len(mediaURLs)
	for i, mediaURL := range mediaURLs {
		if isDownloadCancelled(itemID) {
			out.Close()
			cleanupOutputOnError(m4aPath, outputFD)
			return ErrDownloadCancelled
		}

		if i%10 == 0 || i == totalSegments-1 {
			GoLog("[Tidal] Downloading segment %d/%d...\n", i+1, totalSegments)
		}

		if itemID != "" {
			progress := float64(i+1) / float64(totalSegments)
			SetItemProgress(itemID, progress, 0, 0)
		}

		req, err := http.NewRequestWithContext(ctx, "GET", mediaURL, nil)
		if err != nil {
			out.Close()
			cleanupOutputOnError(m4aPath, outputFD)
			GoLog("[Tidal] Segment %d request failed: %v\n", i+1, err)
			return fmt.Errorf("failed to create segment %d request: %w", i+1, err)
		}
		resp, err := client.Do(req)
		if err != nil {
			out.Close()
			cleanupOutputOnError(m4aPath, outputFD)
			if isDownloadCancelled(itemID) {
				return ErrDownloadCancelled
			}
			GoLog("[Tidal] Segment %d download failed: %v\n", i+1, err)
			return fmt.Errorf("failed to download segment %d: %w", i+1, err)
		}
		if resp.StatusCode != 200 {
			resp.Body.Close()
			out.Close()
			cleanupOutputOnError(m4aPath, outputFD)
			GoLog("[Tidal] Segment %d HTTP error: %d\n", i+1, resp.StatusCode)
			return fmt.Errorf("segment %d download failed with status %d", i+1, resp.StatusCode)
		}
		_, err = io.Copy(out, resp.Body)
		resp.Body.Close()
		if err != nil {
			out.Close()
			cleanupOutputOnError(m4aPath, outputFD)
			if isDownloadCancelled(itemID) {
				return ErrDownloadCancelled
			}
			GoLog("[Tidal] Segment %d write failed: %v\n", i+1, err)
			return fmt.Errorf("failed to write segment %d: %w", i+1, err)
		}
	}

	if err := out.Close(); err != nil {
		cleanupOutputOnError(m4aPath, outputFD)
		GoLog("[Tidal] Failed to close M4A file: %v\n", err)
		return fmt.Errorf("failed to close M4A file: %w", err)
	}

	GoLog("[Tidal] DASH download completed: %s\n", m4aPath)
	return nil
}

type TidalDownloadResult struct {
	FilePath    string
	BitDepth    int
	SampleRate  int
	Title       string
	Artist      string
	Album       string
	ReleaseDate string
	TrackNumber int
	DiscNumber  int
	ISRC        string
	LyricsLRC   string // LRC content for embedding in converted files
}

func artistsMatch(spotifyArtist, tidalArtist string) bool {
	normSpotify := normalizeLooseArtistName(spotifyArtist)
	normTidal := normalizeLooseArtistName(tidalArtist)

	if normSpotify == normTidal {
		return true
	}

	if strings.Contains(normSpotify, normTidal) || strings.Contains(normTidal, normSpotify) {
		return true
	}

	spotifyArtists := splitArtists(normSpotify)
	tidalArtists := splitArtists(normTidal)

	for _, exp := range spotifyArtists {
		for _, fnd := range tidalArtists {
			if exp == fnd {
				return true
			}
			if strings.Contains(exp, fnd) || strings.Contains(fnd, exp) {
				return true
			}
			if sameWordsUnordered(exp, fnd) {
				GoLog("[Tidal] Artist names have same words in different order: '%s' vs '%s'\n", exp, fnd)
				return true
			}
		}
	}

	spotifyLatin := isLatinScript(spotifyArtist)
	tidalLatin := isLatinScript(tidalArtist)
	if spotifyLatin != tidalLatin {
		GoLog("[Tidal] Artist names in different scripts, assuming match: '%s' vs '%s'\n", spotifyArtist, tidalArtist)
		return true
	}

	return false
}

func splitArtists(artists string) []string {
	normalized := artists
	normalized = strings.ReplaceAll(normalized, " feat. ", "|")
	normalized = strings.ReplaceAll(normalized, " feat ", "|")
	normalized = strings.ReplaceAll(normalized, " ft. ", "|")
	normalized = strings.ReplaceAll(normalized, " ft ", "|")
	normalized = strings.ReplaceAll(normalized, " & ", "|")
	normalized = strings.ReplaceAll(normalized, " and ", "|")
	normalized = strings.ReplaceAll(normalized, ", ", "|")
	normalized = strings.ReplaceAll(normalized, " x ", "|")

	parts := strings.Split(normalized, "|")
	result := make([]string, 0, len(parts))
	for _, p := range parts {
		trimmed := strings.TrimSpace(p)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func sameWordsUnordered(a, b string) bool {
	wordsA := strings.Fields(a)
	wordsB := strings.Fields(b)

	if len(wordsA) != len(wordsB) || len(wordsA) == 0 {
		return false
	}

	sortedA := make([]string, len(wordsA))
	sortedB := make([]string, len(wordsB))
	copy(sortedA, wordsA)
	copy(sortedB, wordsB)

	for i := 0; i < len(sortedA)-1; i++ {
		for j := i + 1; j < len(sortedA); j++ {
			if sortedA[i] > sortedA[j] {
				sortedA[i], sortedA[j] = sortedA[j], sortedA[i]
			}
			if sortedB[i] > sortedB[j] {
				sortedB[i], sortedB[j] = sortedB[j], sortedB[i]
			}
		}
	}

	for i := range sortedA {
		if sortedA[i] != sortedB[i] {
			return false
		}
	}
	return true
}

func titlesMatch(expectedTitle, foundTitle string) bool {
	normExpected := strings.ToLower(strings.TrimSpace(expectedTitle))
	normFound := strings.ToLower(strings.TrimSpace(foundTitle))

	if normExpected == normFound {
		return true
	}

	if strings.Contains(normExpected, normFound) || strings.Contains(normFound, normExpected) {
		return true
	}

	cleanExpected := cleanTitle(normExpected)
	cleanFound := cleanTitle(normFound)

	if cleanExpected == cleanFound {
		return true
	}

	if cleanExpected != "" && cleanFound != "" {
		if strings.Contains(cleanExpected, cleanFound) || strings.Contains(cleanFound, cleanExpected) {
			return true
		}
	}

	coreExpected := extractCoreTitle(normExpected)
	coreFound := extractCoreTitle(normFound)

	if coreExpected != "" && coreFound != "" && coreExpected == coreFound {
		return true
	}

	looseExpected := normalizeLooseTitle(normExpected)
	looseFound := normalizeLooseTitle(normFound)
	if looseExpected != "" && looseFound != "" {
		if looseExpected == looseFound {
			return true
		}
		if strings.Contains(looseExpected, looseFound) || strings.Contains(looseFound, looseExpected) {
			return true
		}
	}

	if (!hasAlphaNumericRunes(expectedTitle) || !hasAlphaNumericRunes(foundTitle)) &&
		strings.TrimSpace(expectedTitle) != "" &&
		strings.TrimSpace(foundTitle) != "" {
		expectedSymbols := normalizeSymbolOnlyTitle(expectedTitle)
		foundSymbols := normalizeSymbolOnlyTitle(foundTitle)
		if expectedSymbols != "" && foundSymbols != "" && expectedSymbols == foundSymbols {
			GoLog("[Tidal] Symbol-heavy title matched strictly: '%s' vs '%s'\n", expectedTitle, foundTitle)
			return true
		}
		GoLog("[Tidal] Symbol-heavy title mismatch: '%s' vs '%s'\n", expectedTitle, foundTitle)
		return false
	}

	expectedLatin := isLatinScript(expectedTitle)
	foundLatin := isLatinScript(foundTitle)
	if expectedLatin != foundLatin {
		GoLog("[Tidal] Titles in different scripts, assuming match: '%s' vs '%s'\n", expectedTitle, foundTitle)
		return true
	}

	return false
}

func extractCoreTitle(title string) string {
	parenIdx := strings.Index(title, "(")
	bracketIdx := strings.Index(title, "[")
	dashIdx := strings.Index(title, " - ")

	cutIdx := len(title)
	if parenIdx > 0 && parenIdx < cutIdx {
		cutIdx = parenIdx
	}
	if bracketIdx > 0 && bracketIdx < cutIdx {
		cutIdx = bracketIdx
	}
	if dashIdx > 0 && dashIdx < cutIdx {
		cutIdx = dashIdx
	}

	return strings.TrimSpace(title[:cutIdx])
}

func cleanTitle(title string) string {
	cleaned := title

	versionPatterns := []string{
		"remaster", "remastered", "deluxe", "bonus", "single",
		"album version", "radio edit", "original mix", "extended",
		"club mix", "remix", "live", "acoustic", "demo",
	}

	for {
		startParen := strings.LastIndex(cleaned, "(")
		endParen := strings.LastIndex(cleaned, ")")
		if startParen >= 0 && endParen > startParen {
			content := strings.ToLower(cleaned[startParen+1 : endParen])
			isVersionIndicator := false
			for _, pattern := range versionPatterns {
				if strings.Contains(content, pattern) {
					isVersionIndicator = true
					break
				}
			}
			if isVersionIndicator {
				cleaned = strings.TrimSpace(cleaned[:startParen]) + cleaned[endParen+1:]
				continue
			}
		}
		break
	}

	for {
		startBracket := strings.LastIndex(cleaned, "[")
		endBracket := strings.LastIndex(cleaned, "]")
		if startBracket >= 0 && endBracket > startBracket {
			content := strings.ToLower(cleaned[startBracket+1 : endBracket])
			isVersionIndicator := false
			for _, pattern := range versionPatterns {
				if strings.Contains(content, pattern) {
					isVersionIndicator = true
					break
				}
			}
			if isVersionIndicator {
				cleaned = strings.TrimSpace(cleaned[:startBracket]) + cleaned[endBracket+1:]
				continue
			}
		}
		break
	}

	dashPatterns := []string{
		" - remaster", " - remastered", " - single version", " - radio edit",
		" - live", " - acoustic", " - demo", " - remix",
	}
	for _, pattern := range dashPatterns {
		if strings.HasSuffix(strings.ToLower(cleaned), pattern) {
			cleaned = cleaned[:len(cleaned)-len(pattern)]
		}
	}

	for strings.Contains(cleaned, "  ") {
		cleaned = strings.ReplaceAll(cleaned, "  ", " ")
	}

	return strings.TrimSpace(cleaned)
}

func isLatinScript(s string) bool {
	for _, r := range s {
		if r < 128 {
			continue
		}
		if (r >= 0x0100 && r <= 0x024F) ||
			(r >= 0x1E00 && r <= 0x1EFF) ||
			(r >= 0x00C0 && r <= 0x00FF) {
			continue
		}
		if (r >= 0x4E00 && r <= 0x9FFF) ||
			(r >= 0x3040 && r <= 0x309F) ||
			(r >= 0x30A0 && r <= 0x30FF) ||
			(r >= 0xAC00 && r <= 0xD7AF) ||
			(r >= 0x0600 && r <= 0x06FF) ||
			(r >= 0x0400 && r <= 0x04FF) {
			return false
		}
	}
	return true
}

func parseTidalRequestTrackID(raw string) (int64, bool) {
	trimmed := strings.TrimSpace(raw)
	trimmed = strings.TrimPrefix(trimmed, "tidal:")
	if trimmed == "" {
		return 0, false
	}

	trackID, err := strconv.ParseInt(trimmed, 10, 64)
	if err != nil || trackID <= 0 {
		return 0, false
	}
	return trackID, true
}

func resolveTidalTrackForRequest(req DownloadRequest, downloader *TidalDownloader, logPrefix string) (*TidalTrack, error) {
	if downloader == nil {
		downloader = NewTidalDownloader()
	}
	if strings.TrimSpace(logPrefix) == "" {
		logPrefix = "Tidal"
	}

	expectedDurationSec := req.DurationMS / 1000
	var trackID int64
	var gotTidalID bool
	var resolvedViaSongLink bool

	if req.TidalID != "" {
		GoLog("[%s] Using Tidal ID from request payload: %s\n", logPrefix, req.TidalID)
		if parsedTrackID, ok := parseTidalRequestTrackID(req.TidalID); ok {
			trackID = parsedTrackID
			gotTidalID = true
		}
	}

	if !gotTidalID && req.ISRC != "" {
		if cached := GetTrackIDCache().Get(req.ISRC); cached != nil && cached.TidalTrackID > 0 {
			GoLog("[%s] Cache hit! Using cached track ID: %d\n", logPrefix, cached.TidalTrackID)
			trackID = cached.TidalTrackID
			gotTidalID = true
		}
	}

	if !gotTidalID && req.ISRC != "" && req.TrackName != "" && req.ArtistName != "" {
		GoLog("[%s] Trying Tidal public metadata search with ISRC\n", logPrefix)
		searchTrack, searchErr := downloader.SearchTrackByMetadataWithISRC(
			req.TrackName,
			req.ArtistName,
			req.AlbumName,
			req.ISRC,
			expectedDurationSec,
		)
		if searchErr == nil && searchTrack != nil && searchTrack.ID > 0 {
			trackID = searchTrack.ID
			gotTidalID = true
			GoLog("[%s] Got Tidal ID %d from public metadata search\n", logPrefix, trackID)
		} else if searchErr != nil {
			GoLog("[%s] Tidal public metadata search failed: %v\n", logPrefix, searchErr)
		}
	}

	if !gotTidalID && (req.SpotifyID != "" || req.DeezerID != "") {
		GoLog("[%s] Trying SongLink for Tidal ID...\n", logPrefix)

		resolveFromAvailability := func(availability *TrackAvailability) {
			if availability == nil || gotTidalID {
				return
			}
			if availability.TidalID != "" {
				if parsedTrackID, ok := parseTidalRequestTrackID(availability.TidalID); ok {
					trackID = parsedTrackID
					GoLog("[%s] Got Tidal ID %d directly from SongLink\n", logPrefix, trackID)
					gotTidalID = true
					resolvedViaSongLink = true
					return
				}
			}
			if availability.TidalURL != "" {
				var idErr error
				trackID, idErr = downloader.GetTrackIDFromURL(availability.TidalURL)
				if idErr == nil && trackID > 0 {
					GoLog("[%s] Got Tidal ID %d from URL parsing\n", logPrefix, trackID)
					gotTidalID = true
					resolvedViaSongLink = true
				}
			}
		}

		if req.DeezerID != "" {
			GoLog("[%s] Using Deezer ID for SongLink lookup: %s\n", logPrefix, req.DeezerID)
			songlink := NewSongLinkClient()
			availability, slErr := songlink.CheckAvailabilityFromDeezer(req.DeezerID)
			if slErr == nil {
				resolveFromAvailability(availability)
			} else {
				GoLog("[%s] SongLink Deezer lookup failed: %v\n", logPrefix, slErr)
			}
		}

		if !gotTidalID && req.SpotifyID != "" {
			if strings.HasPrefix(req.SpotifyID, "deezer:") {
				deezerID := strings.TrimPrefix(req.SpotifyID, "deezer:")
				GoLog("[%s] Using Deezer ID for SongLink lookup: %s\n", logPrefix, deezerID)
				songlink := NewSongLinkClient()
				availability, slErr := songlink.CheckAvailabilityFromDeezer(deezerID)
				if slErr == nil {
					resolveFromAvailability(availability)
				} else {
					GoLog("[%s] SongLink Deezer lookup failed: %v\n", logPrefix, slErr)
				}
			}
		}

		if !gotTidalID && req.SpotifyID != "" && !strings.HasPrefix(req.SpotifyID, "deezer:") {
			songlink := NewSongLinkClient()
			availability, slErr := songlink.CheckTrackAvailability(req.SpotifyID, req.ISRC)
			if slErr == nil {
				resolveFromAvailability(availability)
			}
		}
	}

	if !gotTidalID || trackID <= 0 {
		return nil, fmt.Errorf("failed to find tidal track id from request/cache/songlink")
	}

	actualTrack, fetchErr := tidalGetPublicTrackFunc(downloader, strconv.FormatInt(trackID, 10))
	if fetchErr != nil {
		GoLog("[%s] Warning: could not fetch Tidal track %d for verification: %v\n", logPrefix, trackID, fetchErr)
	} else {
		providerArtist := actualTrack.Artist.Name
		if providerArtist == "" && len(actualTrack.Artists) > 0 {
			providerArtist = actualTrack.Artists[0].Name
		}
		resolved := resolvedTrackInfo{
			Title:                actualTrack.Title,
			ArtistName:           providerArtist,
			ISRC:                 strings.TrimSpace(actualTrack.ISRC),
			Duration:             actualTrack.Duration,
			SkipNameVerification: resolvedViaSongLink,
		}
		if !trackMatchesRequest(req, resolved, logPrefix) {
			if req.ISRC != "" {
				GetTrackIDCache().SetTidal(req.ISRC, 0)
			}
			return nil, fmt.Errorf("tidal track %d does not match request: expected '%s - %s', got '%s - %s'",
				trackID, req.ArtistName, req.TrackName, resolved.ArtistName, resolved.Title)
		}
		GoLog("[%s] Track %d verified: '%s - %s' ✓\n", logPrefix, trackID, resolved.ArtistName, resolved.Title)
	}

	// Use track_number / disc_number from the actual Tidal API data when the
	// request doesn't carry them (e.g. downloads from search results / popular).
	resolvedTrackNumber := req.TrackNumber
	resolvedDiscNumber := req.DiscNumber
	if actualTrack != nil {
		if resolvedTrackNumber == 0 && actualTrack.TrackNumber > 0 {
			resolvedTrackNumber = actualTrack.TrackNumber
		}
		if resolvedDiscNumber == 0 && actualTrack.VolumeNumber > 0 {
			resolvedDiscNumber = actualTrack.VolumeNumber
		}
	}

	track := &TidalTrack{
		ID:           trackID,
		Title:        strings.TrimSpace(req.TrackName),
		ISRC:         strings.TrimSpace(req.ISRC),
		Duration:     expectedDurationSec,
		TrackNumber:  resolvedTrackNumber,
		VolumeNumber: resolvedDiscNumber,
	}
	track.Artist.Name = strings.TrimSpace(req.ArtistName)
	track.Album.Title = strings.TrimSpace(req.AlbumName)
	track.Album.ReleaseDate = strings.TrimSpace(req.ReleaseDate)

	if req.ISRC != "" {
		GetTrackIDCache().SetTidal(req.ISRC, trackID)
	}
	return track, nil
}

func downloadFromTidal(req DownloadRequest) (TidalDownloadResult, error) {
	downloader := NewTidalDownloader()

	isSafOutput := isFDOutput(req.OutputFD) || strings.TrimSpace(req.OutputPath) != ""
	if !isSafOutput {
		if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
			return TidalDownloadResult{FilePath: "EXISTS:" + existingFile}, nil
		}
	}

	track, err := resolveTidalTrackForRequest(req, downloader, "Tidal")
	if err != nil {
		return TidalDownloadResult{}, err
	}

	quality := req.Quality
	if quality == "" || quality == "DEFAULT" {
		quality = "LOSSLESS"
	}

	filename := buildFilenameFromTemplate(req.FilenameFormat, map[string]interface{}{
		"title":  req.TrackName,
		"artist": req.ArtistName,
		"album":  req.AlbumName,
		"track":  req.TrackNumber,
		"year":   extractYear(req.ReleaseDate),
		"date":   req.ReleaseDate,
		"disc":   req.DiscNumber,
	})

	outputExt := strings.TrimSpace(req.OutputExt)
	if outputExt == "" {
		if quality == "HIGH" {
			outputExt = ".m4a"
		} else {
			outputExt = ".flac"
		}
	} else if !strings.HasPrefix(outputExt, ".") {
		outputExt = "." + outputExt
	}

	var outputPath string
	var m4aPath string
	if isSafOutput {
		outputPath = strings.TrimSpace(req.OutputPath)
		if outputPath == "" && isFDOutput(req.OutputFD) {
			outputPath = fmt.Sprintf("/proc/self/fd/%d", req.OutputFD)
		}
		m4aPath = outputPath
	} else {
		if outputExt == ".m4a" || quality == "HIGH" {
			filename = sanitizeFilename(filename) + ".m4a"
			outputPath = filepath.Join(req.OutputDir, filename)
			m4aPath = outputPath
		} else {
			filename = sanitizeFilename(filename) + ".flac"
			outputPath = filepath.Join(req.OutputDir, filename)
			m4aPath = strings.TrimSuffix(outputPath, ".flac") + ".m4a"
		}

		if fileInfo, statErr := os.Stat(outputPath); statErr == nil && fileInfo.Size() > 0 {
			return TidalDownloadResult{FilePath: "EXISTS:" + outputPath}, nil
		}
		if quality != "HIGH" {
			if fileInfo, statErr := os.Stat(m4aPath); statErr == nil && fileInfo.Size() > 0 {
				return TidalDownloadResult{FilePath: "EXISTS:" + m4aPath}, nil
			}
		}
	}

	if !isSafOutput {
		tmpPath := outputPath + ".m4a.tmp"
		if _, err := os.Stat(tmpPath); err == nil {
			GoLog("[Tidal] Cleaning up leftover temp file: %s\n", tmpPath)
			os.Remove(tmpPath)
		}
	}

	GoLog("[Tidal] Using quality: %s\n", quality)

	downloadInfo, err := downloader.GetDownloadURL(track.ID, quality)
	if err != nil {
		return TidalDownloadResult{}, fmt.Errorf("failed to get download URL: %w", err)
	}

	GoLog("[Tidal] Actual quality: %d-bit/%dHz\n", downloadInfo.BitDepth, downloadInfo.SampleRate)

	var parallelResult *ParallelDownloadResult
	parallelDone := make(chan struct{})
	go func() {
		defer close(parallelDone)
		coverURL := req.CoverURL
		embedLyrics := req.EmbedLyrics
		if !req.EmbedMetadata {
			coverURL = ""
			embedLyrics = false
		}
		parallelResult = FetchCoverAndLyricsParallel(
			coverURL,
			req.EmbedMaxQualityCover,
			req.SpotifyID,
			req.TrackName,
			req.ArtistName,
			embedLyrics,
			int64(req.DurationMS),
		)
	}()

	GoLog("[Tidal] Starting download to: %s\n", outputPath)
	GoLog("[Tidal] Download URL type: %s\n", func() string {
		if strings.HasPrefix(downloadInfo.URL, "MANIFEST:") {
			return "MANIFEST (DASH/BTS)"
		}
		return "Direct URL"
	}())

	if err := downloader.DownloadFile(downloadInfo.URL, outputPath, req.OutputFD, req.ItemID); err != nil {
		if errors.Is(err, ErrDownloadCancelled) {
			return TidalDownloadResult{}, ErrDownloadCancelled
		}
		GoLog("[Tidal] Download failed with error: %v\n", err)
		return TidalDownloadResult{}, fmt.Errorf("download failed: %w", err)
	}
	fmt.Println("[Tidal] Download completed successfully")

	<-parallelDone

	if req.ItemID != "" {
		SetItemProgress(req.ItemID, 1.0, 0, 0)
		SetItemFinalizing(req.ItemID)
	}

	actualOutputPath := outputPath
	if !isSafOutput {
		if _, err := os.Stat(m4aPath); err == nil {
			actualOutputPath = m4aPath
			GoLog("[Tidal] File saved as M4A (DASH stream): %s\n", actualOutputPath)
		} else if _, err := os.Stat(outputPath); err != nil {
			return TidalDownloadResult{}, fmt.Errorf("download completed but file not found at %s or %s", outputPath, m4aPath)
		}
	}

	releaseDate := req.ReleaseDate
	if releaseDate == "" && track.Album.ReleaseDate != "" {
		releaseDate = track.Album.ReleaseDate
		GoLog("[Tidal] Using release date from Tidal API: %s\n", releaseDate)
	}

	actualTrackNumber := req.TrackNumber
	actualDiscNumber := req.DiscNumber
	if actualTrackNumber == 0 {
		actualTrackNumber = track.TrackNumber
	}
	if actualDiscNumber == 0 {
		actualDiscNumber = track.VolumeNumber
	}

	metadata := Metadata{
		Title:         req.TrackName,
		Artist:        req.ArtistName,
		Album:         req.AlbumName,
		AlbumArtist:   req.AlbumArtist,
		ArtistTagMode: req.ArtistTagMode,
		Date:          releaseDate,
		TrackNumber:   actualTrackNumber,
		TotalTracks:   req.TotalTracks,
		DiscNumber:    actualDiscNumber,
		TotalDiscs:    req.TotalDiscs,
		ISRC:          track.ISRC,
		Genre:         req.Genre,
		Label:         req.Label,
		Copyright:     req.Copyright,
		Composer:      req.Composer,
	}

	var coverData []byte
	if parallelResult != nil && parallelResult.CoverData != nil {
		coverData = parallelResult.CoverData
		GoLog("[Tidal] Using parallel-fetched cover (%d bytes)\n", len(coverData))
	}

	actualExt := outputExt
	if strings.HasPrefix(downloadInfo.URL, "MANIFEST:") {
		actualExt = ".m4a"
	}
	if actualExt == "" && !isSafOutput {
		actualExt = strings.ToLower(filepath.Ext(actualOutputPath))
	}

	if (isSafOutput && actualExt == ".flac") || (!isSafOutput && strings.HasSuffix(actualOutputPath, ".flac")) {
		if req.EmbedMetadata {
			if err := EmbedMetadataWithCoverData(actualOutputPath, metadata, coverData); err != nil {
				fmt.Printf("Warning: failed to embed metadata: %v\n", err)
			}
		} else {
			GoLog("[Tidal] Metadata embedding disabled by settings, skipping FLAC metadata/lyrics embedding\n")
		}

		if req.EmbedMetadata && req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
			lyricsMode := req.LyricsMode
			if lyricsMode == "" {
				lyricsMode = "embed"
			}

			if !isSafOutput && (lyricsMode == "external" || lyricsMode == "both") {
				GoLog("[Tidal] Saving external LRC file...\n")
				if lrcPath, lrcErr := SaveLRCFile(actualOutputPath, parallelResult.LyricsLRC); lrcErr != nil {
					GoLog("[Tidal] Warning: failed to save LRC file: %v\n", lrcErr)
				} else {
					GoLog("[Tidal] LRC file saved: %s\n", lrcPath)
				}
			}

			if lyricsMode == "embed" || lyricsMode == "both" {
				GoLog("[Tidal] Embedding parallel-fetched lyrics (%d lines)...\n", len(parallelResult.LyricsData.Lines))
				if embedErr := EmbedLyrics(actualOutputPath, parallelResult.LyricsLRC); embedErr != nil {
					GoLog("[Tidal] Warning: failed to embed lyrics: %v\n", embedErr)
				} else {
					fmt.Println("[Tidal] Lyrics embedded successfully")
				}
			}
		} else if req.EmbedMetadata && req.EmbedLyrics {
			fmt.Println("[Tidal] No lyrics available from parallel fetch")
		}
	} else if (isSafOutput && actualExt == ".m4a") || (!isSafOutput && strings.HasSuffix(actualOutputPath, ".m4a")) {
		if quality == "HIGH" {
			GoLog("[Tidal] HIGH quality M4A - skipping metadata embedding (file from server is already valid)\n")

			if req.EmbedMetadata && req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
				lyricsMode := req.LyricsMode
				if lyricsMode == "" {
					lyricsMode = "embed"
				}

				if !isSafOutput && (lyricsMode == "external" || lyricsMode == "both") {
					GoLog("[Tidal] Saving external LRC file for M4A (mode: %s)...\n", lyricsMode)
					if lrcPath, lrcErr := SaveLRCFile(actualOutputPath, parallelResult.LyricsLRC); lrcErr != nil {
						GoLog("[Tidal] Warning: failed to save LRC file: %v\n", lrcErr)
					} else {
						GoLog("[Tidal] LRC file saved: %s\n", lrcPath)
					}
				}
			}
		} else {
			fmt.Println("[Tidal] Skipping metadata embedding for M4A file (will be handled after FFmpeg conversion)")
		}
	}

	if !isSafOutput {
		AddToISRCIndex(req.OutputDir, req.ISRC, actualOutputPath)
	}

	bitDepth := downloadInfo.BitDepth
	sampleRate := downloadInfo.SampleRate
	if quality == "HIGH" {
		bitDepth = 0
		sampleRate = 44100
	}
	lyricsLRC := ""
	if req.EmbedMetadata && req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
		lyricsLRC = parallelResult.LyricsLRC
	}

	resultAlbum, resultReleaseDate, resultTrackNumber, resultDiscNumber := preferredReleaseMetadata(
		req,
		track.Album.Title,
		track.Album.ReleaseDate,
		actualTrackNumber,
		actualDiscNumber,
	)

	return TidalDownloadResult{
		FilePath:    actualOutputPath,
		BitDepth:    bitDepth,
		SampleRate:  sampleRate,
		Title:       track.Title,
		Artist:      track.Artist.Name,
		Album:       resultAlbum,
		ReleaseDate: resultReleaseDate,
		TrackNumber: resultTrackNumber,
		DiscNumber:  resultDiscNumber,
		ISRC:        track.ISRC,
		LyricsLRC:   lyricsLRC,
	}, nil
}

func parseTidalURL(input string) (string, string, error) {
	trimmed := strings.TrimSpace(input)
	if trimmed == "" {
		return "", "", fmt.Errorf("empty URL")
	}

	parsed, err := url.Parse(trimmed)
	if err != nil {
		return "", "", err
	}

	if parsed.Host != "tidal.com" && parsed.Host != "listen.tidal.com" && parsed.Host != "www.tidal.com" {
		return "", "", fmt.Errorf("not a Tidal URL")
	}

	parts := strings.Split(strings.Trim(parsed.Path, "/"), "/")

	if len(parts) > 0 && parts[0] == "browse" {
		parts = parts[1:]
	}

	if len(parts) < 2 {
		return "", "", fmt.Errorf("invalid Tidal URL format")
	}

	resourceType := parts[0]
	resourceID := parts[1]

	switch resourceType {
	case "track", "album", "artist", "playlist":
		return resourceType, resourceID, nil
	default:
		return "", "", fmt.Errorf("unsupported Tidal resource type: %s", resourceType)
	}
}
