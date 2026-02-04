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
	"strings"
	"sync"
	"time"
)

type TidalDownloader struct {
	client         *http.Client
	clientID       string
	clientSecret   string
	apiURL         string
	cachedToken    string
	tokenExpiresAt time.Time
	tokenMu        sync.Mutex
}

var (
	globalTidalDownloader *TidalDownloader
	tidalDownloaderOnce   sync.Once
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
		Title       string `json:"title"`
		Cover       string `json:"cover"`
		ReleaseDate string `json:"releaseDate"`
	} `json:"album"`
	Artists []struct {
		Name string `json:"name"`
	} `json:"artists"`
	Artist struct {
		Name string `json:"name"`
	} `json:"artist"`
	MediaMetadata struct {
		Tags []string `json:"tags"`
	} `json:"mediaMetadata"`
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

func NewTidalDownloader() *TidalDownloader {
	tidalDownloaderOnce.Do(func() {
		clientID, _ := base64.StdEncoding.DecodeString("NkJEU1JkcEs5aHFFQlRnVQ==")
		clientSecret, _ := base64.StdEncoding.DecodeString("eGV1UG1ZN25icFo5SUliTEFjUTkzc2hrYTFWTmhlVUFxTjZJY3N6alRHOD0=")

		globalTidalDownloader = &TidalDownloader{
			client:       NewHTTPClientWithTimeout(DefaultTimeout), // 60s timeout
			clientID:     string(clientID),
			clientSecret: string(clientSecret),
		}

		apis := globalTidalDownloader.GetAvailableAPIs()
		if len(apis) > 0 {
			globalTidalDownloader.apiURL = apis[0]
		}
	})
	return globalTidalDownloader
}

func (t *TidalDownloader) GetAvailableAPIs() []string {
	encodedAPIs := []string{
		"dGlkYWwtYXBpLmJpbmltdW0ub3Jn",     // tidal-api.binimum.org (priority)
		"dGlkYWwua2lub3BsdXMub25saW5l",     // tidal.kinoplus.online
		"dHJpdG9uLnNxdWlkLnd0Zg==",         // triton.squid.wtf
		"dm9nZWwucXFkbC5zaXRl",             // vogel.qqdl.site
		"bWF1cy5xcWRsLnNpdGU=",             // maus.qqdl.site
		"aHVuZC5xcWRsLnNpdGU=",             // hund.qqdl.site
		"a2F0emUucXFkbC5zaXRl",             // katze.qqdl.site
		"d29sZi5xcWRsLnNpdGU=",             // wolf.qqdl.site
		"aGlmaS1vbmUuc3BvdGlzYXZlci5uZXQ=", // hifi-one.spotisaver.net
		"aGlmaS10d28uc3BvdGlzYXZlci5uZXQ=", // hifi-two.spotisaver.net
	}

	var apis []string
	for _, encoded := range encodedAPIs {
		decoded, err := base64.StdEncoding.DecodeString(encoded)
		if err != nil {
			continue
		}
		apis = append(apis, "https://"+string(decoded))
	}

	return apis
}

func (t *TidalDownloader) GetAccessToken() (string, error) {
	t.tokenMu.Lock()
	defer t.tokenMu.Unlock()

	if t.cachedToken != "" && time.Now().Add(60*time.Second).Before(t.tokenExpiresAt) {
		return t.cachedToken, nil
	}

	data := fmt.Sprintf("client_id=%s&grant_type=client_credentials", t.clientID)

	authURL, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hdXRoLnRpZGFsLmNvbS92MS9vYXV0aDIvdG9rZW4=")
	req, err := http.NewRequest("POST", string(authURL), strings.NewReader(data))
	if err != nil {
		return "", err
	}

	req.SetBasicAuth(t.clientID, t.clientSecret)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("failed to get access token: HTTP %d", resp.StatusCode)
	}

	var result struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}

	t.cachedToken = result.AccessToken
	if result.ExpiresIn > 0 {
		t.tokenExpiresAt = time.Now().Add(time.Duration(result.ExpiresIn) * time.Second)
	} else {
		t.tokenExpiresAt = time.Now().Add(55 * time.Minute) // Default 55 min
	}

	return result.AccessToken, nil
}

func (t *TidalDownloader) GetTidalURLFromSpotify(spotifyTrackID string) (string, error) {
	spotifyBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9vcGVuLnNwb3RpZnkuY29tL3RyYWNrLw==")
	spotifyURL := fmt.Sprintf("%s%s", string(spotifyBase), spotifyTrackID)

	apiBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkuc29uZy5saW5rL3YxLWFscGhhLjEvbGlua3M/dXJsPQ==")
	apiURL := fmt.Sprintf("%s%s", string(apiBase), url.QueryEscape(spotifyURL))

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
	token, err := t.GetAccessToken()
	if err != nil {
		return nil, fmt.Errorf("failed to get access token: %w", err)
	}

	trackBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkudGlkYWwuY29tL3YxL3RyYWNrcy8=")
	trackURL := fmt.Sprintf("%s%d?countryCode=US", string(trackBase), trackID)

	req, err := http.NewRequest("GET", trackURL, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("failed to get track info: HTTP %d", resp.StatusCode)
	}

	var trackInfo TidalTrack
	if err := json.NewDecoder(resp.Body).Decode(&trackInfo); err != nil {
		return nil, err
	}

	return &trackInfo, nil
}

func (t *TidalDownloader) SearchTrackByISRC(isrc string) (*TidalTrack, error) {
	token, err := t.GetAccessToken()
	if err != nil {
		return nil, err
	}

	searchBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkudGlkYWwuY29tL3YxL3NlYXJjaC90cmFja3M/cXVlcnk9")
	searchURL := fmt.Sprintf("%s%s&limit=50&countryCode=US", string(searchBase), url.QueryEscape(isrc))

	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := DoRequestWithUserAgent(t.client, req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("search failed: HTTP %d", resp.StatusCode)
	}

	var result struct {
		Items []TidalTrack `json:"items"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	for i := range result.Items {
		if result.Items[i].ISRC == isrc {
			return &result.Items[i], nil
		}
	}

	if len(result.Items) == 0 {
		return nil, fmt.Errorf("no tracks found for ISRC: %s", isrc)
	}

	return nil, fmt.Errorf("no exact ISRC match found for: %s", isrc)
}

// Now includes romaji conversion for Japanese text (4 search strategies like PC)
func (t *TidalDownloader) SearchTrackByMetadataWithISRC(trackName, artistName, spotifyISRC string, expectedDuration int) (*TidalTrack, error) {
	token, err := t.GetAccessToken()
	if err != nil {
		return nil, err
	}

	// Build search queries - multiple strategies (same as PC version)
	queries := []string{}

	if artistName != "" && trackName != "" {
		queries = append(queries, artistName+" "+trackName)
	}

	if trackName != "" {
		queries = append(queries, trackName)
	}

	if ContainsJapanese(trackName) || ContainsJapanese(artistName) {
		romajiTrack := JapaneseToRomaji(trackName)
		romajiArtist := JapaneseToRomaji(artistName)

		cleanRomajiTrack := CleanToASCII(romajiTrack)
		cleanRomajiArtist := CleanToASCII(romajiArtist)

		if cleanRomajiArtist != "" && cleanRomajiTrack != "" {
			romajiQuery := cleanRomajiArtist + " " + cleanRomajiTrack
			if !containsQuery(queries, romajiQuery) {
				queries = append(queries, romajiQuery)
				GoLog("[Tidal] Japanese detected, adding romaji query: %s\n", romajiQuery)
			}
		}

		if cleanRomajiTrack != "" && cleanRomajiTrack != trackName {
			if !containsQuery(queries, cleanRomajiTrack) {
				queries = append(queries, cleanRomajiTrack)
			}
		}

		if artistName != "" && cleanRomajiTrack != "" {
			partialQuery := artistName + " " + cleanRomajiTrack
			if !containsQuery(queries, partialQuery) {
				queries = append(queries, partialQuery)
			}
		}
	}

	if artistName != "" {
		artistOnly := CleanToASCII(JapaneseToRomaji(artistName))
		if artistOnly != "" && !containsQuery(queries, artistOnly) {
			queries = append(queries, artistOnly)
		}
	}

	searchBase, _ := base64.StdEncoding.DecodeString("aHR0cHM6Ly9hcGkudGlkYWwuY29tL3YxL3NlYXJjaC90cmFja3M/cXVlcnk9")

	var allTracks []TidalTrack
	searchedQueries := make(map[string]bool)

	for _, query := range queries {
		cleanQuery := strings.TrimSpace(query)
		if cleanQuery == "" || searchedQueries[cleanQuery] {
			continue
		}
		searchedQueries[cleanQuery] = true

		GoLog("[Tidal] Searching for: %s\n", cleanQuery)

		searchURL := fmt.Sprintf("%s%s&limit=100&countryCode=US", string(searchBase), url.QueryEscape(cleanQuery))

		req, err := http.NewRequest("GET", searchURL, nil)
		if err != nil {
			continue
		}

		req.Header.Set("Authorization", "Bearer "+token)

		resp, err := DoRequestWithUserAgent(t.client, req)
		if err != nil {
			GoLog("[Tidal] Search error for '%s': %v\n", cleanQuery, err)
			continue
		}

		if resp.StatusCode != 200 {
			resp.Body.Close()
			continue
		}

		var result struct {
			Items []TidalTrack `json:"items"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			resp.Body.Close()
			continue
		}
		resp.Body.Close()

		if len(result.Items) > 0 {
			GoLog("[Tidal] Found %d results for '%s'\n", len(result.Items), cleanQuery)

			if spotifyISRC != "" {
				for i := range result.Items {
					if result.Items[i].ISRC == spotifyISRC {
						track := &result.Items[i]
						if expectedDuration > 0 {
							durationDiff := track.Duration - expectedDuration
							if durationDiff < 0 {
								durationDiff = -durationDiff
							}
							if durationDiff <= 3 {
								GoLog("[Tidal] ISRC match: '%s' (duration verified)\n", track.Title)
								return track, nil
							}
							GoLog("[Tidal] ISRC match but duration mismatch (expected %ds, got %ds), continuing...\n",
								expectedDuration, track.Duration)
						} else {
							GoLog("[Tidal] ISRC match: '%s'\n", track.Title)
							return track, nil
						}
					}
				}
			}

			allTracks = append(allTracks, result.Items...)
		}
	}

	if len(allTracks) == 0 {
		return nil, fmt.Errorf("no tracks found for any search query")
	}

	if spotifyISRC != "" {
		GoLog("[Tidal] Looking for ISRC match: %s\n", spotifyISRC)
		var isrcMatches []*TidalTrack
		for i := range allTracks {
			track := &allTracks[i]
			if track.ISRC == spotifyISRC {
				isrcMatches = append(isrcMatches, track)
			}
		}

		if len(isrcMatches) > 0 {
			if expectedDuration > 0 {
				var durationVerifiedMatches []*TidalTrack
				for _, track := range isrcMatches {
					durationDiff := track.Duration - expectedDuration
					if durationDiff < 0 {
						durationDiff = -durationDiff
					}
					if durationDiff <= 3 {
						durationVerifiedMatches = append(durationVerifiedMatches, track)
					}
				}

				if len(durationVerifiedMatches) > 0 {
					GoLog("[Tidal] ISRC match with duration verification: '%s' (expected %ds, found %ds)\n",
						durationVerifiedMatches[0].Title, expectedDuration, durationVerifiedMatches[0].Duration)
					return durationVerifiedMatches[0], nil
				}

				GoLog("[Tidal] WARNING: ISRC %s found but duration mismatch. Expected=%ds, Found=%ds. Rejecting.\n",
					spotifyISRC, expectedDuration, isrcMatches[0].Duration)
				return nil, fmt.Errorf("ISRC found but duration mismatch: expected %ds, found %ds (likely different version/edit)",
					expectedDuration, isrcMatches[0].Duration)
			}

			GoLog("[Tidal] ISRC match (no duration verification): '%s'\n", isrcMatches[0].Title)
			return isrcMatches[0], nil
		}

		GoLog("[Tidal] No ISRC match found for: %s\n", spotifyISRC)
		return nil, fmt.Errorf("ISRC mismatch: no track found with ISRC %s on Tidal", spotifyISRC)
	}

	if expectedDuration > 0 {
		tolerance := 3 // 3 seconds tolerance
		var durationMatches []*TidalTrack

		for i := range allTracks {
			track := &allTracks[i]
			durationDiff := track.Duration - expectedDuration
			if durationDiff < 0 {
				durationDiff = -durationDiff
			}
			if durationDiff <= tolerance {
				durationMatches = append(durationMatches, track)
			}
		}

		if len(durationMatches) > 0 {
			bestMatch := durationMatches[0]
			for _, track := range durationMatches {
				for _, tag := range track.MediaMetadata.Tags {
					if tag == "HIRES_LOSSLESS" {
						bestMatch = track
						break
					}
				}
			}
			GoLog("[Tidal] Found via duration match: %s - %s (%s)\n",
				bestMatch.Artist.Name, bestMatch.Title, bestMatch.AudioQuality)
			return bestMatch, nil
		}
	}

	bestMatch := &allTracks[0]
	for i := range allTracks {
		track := &allTracks[i]
		for _, tag := range track.MediaMetadata.Tags {
			if tag == "HIRES_LOSSLESS" {
				bestMatch = track
				break
			}
		}
		if bestMatch != &allTracks[0] {
			break
		}
	}

	GoLog("[Tidal] Found via search (no ISRC provided): %s - %s (ISRC: %s, Quality: %s)\n",
		bestMatch.Artist.Name, bestMatch.Title, bestMatch.ISRC, bestMatch.AudioQuality)

	return bestMatch, nil
}

func containsQuery(queries []string, query string) bool {
	for _, q := range queries {
		if q == query {
			return true
		}
	}
	return false
}

func (t *TidalDownloader) SearchTrackByMetadata(trackName, artistName string) (*TidalTrack, error) {
	return t.SearchTrackByMetadataWithISRC(trackName, artistName, "", 0)
}

// TidalDownloadInfo contains download URL and quality info
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

func getDownloadURLParallel(apis []string, trackID int64, quality string) (string, TidalDownloadInfo, error) {
	if len(apis) == 0 {
		return "", TidalDownloadInfo{}, fmt.Errorf("no APIs available")
	}

	GoLog("[Tidal] Requesting download URL from %d APIs in parallel...\n", len(apis))

	resultChan := make(chan tidalAPIResult, len(apis))
	startTime := time.Now()

	for _, apiURL := range apis {
		go func(api string) {
			reqStart := time.Now()

			client := NewHTTPClientWithTimeout(15 * time.Second)

			reqURL := fmt.Sprintf("%s/track/?id=%d&quality=%s", api, trackID, quality)

			req, err := http.NewRequest("GET", reqURL, nil)
			if err != nil {
				resultChan <- tidalAPIResult{apiURL: api, err: err, duration: time.Since(reqStart)}
				return
			}

			resp, err := client.Do(req)
			if err != nil {
				resultChan <- tidalAPIResult{apiURL: api, err: err, duration: time.Since(reqStart)}
				return
			}
			defer resp.Body.Close()

			if resp.StatusCode != 200 {
				resultChan <- tidalAPIResult{apiURL: api, err: fmt.Errorf("HTTP %d", resp.StatusCode), duration: time.Since(reqStart)}
				return
			}

			body, err := io.ReadAll(resp.Body)
			if err != nil {
				resultChan <- tidalAPIResult{apiURL: api, err: err, duration: time.Since(reqStart)}
				return
			}

			var v2Response TidalAPIResponseV2
			if err := json.Unmarshal(body, &v2Response); err == nil && v2Response.Data.Manifest != "" {
				if v2Response.Data.AssetPresentation == "PREVIEW" {
					resultChan <- tidalAPIResult{apiURL: api, err: fmt.Errorf("returned PREVIEW instead of FULL"), duration: time.Since(reqStart)}
					return
				}

				info := TidalDownloadInfo{
					URL:        "MANIFEST:" + v2Response.Data.Manifest,
					BitDepth:   v2Response.Data.BitDepth,
					SampleRate: v2Response.Data.SampleRate,
				}
				resultChan <- tidalAPIResult{apiURL: api, info: info, err: nil, duration: time.Since(reqStart)}
				return
			}

			var v1Responses []struct {
				OriginalTrackURL string `json:"OriginalTrackUrl"`
			}
			if err := json.Unmarshal(body, &v1Responses); err == nil {
				for _, item := range v1Responses {
					if item.OriginalTrackURL != "" {
						info := TidalDownloadInfo{
							URL:        item.OriginalTrackURL,
							BitDepth:   16,
							SampleRate: 44100,
						}
						resultChan <- tidalAPIResult{apiURL: api, info: info, err: nil, duration: time.Since(reqStart)}
						return
					}
				}
			}

			resultChan <- tidalAPIResult{apiURL: api, err: fmt.Errorf("no download URL or manifest in response"), duration: time.Since(reqStart)}
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

	for i := 1; i <= segmentCount; i++ {
		mediaURL := strings.ReplaceAll(mediaTemplate, "$Number$", fmt.Sprintf("%d", i))
		mediaURLs = append(mediaURLs, mediaURL)
	}

	return "", initURL, mediaURLs, nil
}

func (t *TidalDownloader) DownloadFile(downloadURL, outputPath, itemID string) error {
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
		return t.downloadFromManifest(ctx, strings.TrimPrefix(downloadURL, "MANIFEST:"), outputPath, itemID)
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

	out, err := os.Create(outputPath)
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
		os.Remove(outputPath)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		return fmt.Errorf("download interrupted: %w", err)
	}
	if flushErr != nil {
		os.Remove(outputPath)
		return fmt.Errorf("failed to flush buffer: %w", flushErr)
	}
	if closeErr != nil {
		os.Remove(outputPath)
		return fmt.Errorf("failed to close file: %w", closeErr)
	}

	if expectedSize > 0 && written != expectedSize {
		os.Remove(outputPath)
		return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
	}

	return nil
}

func (t *TidalDownloader) downloadFromManifest(ctx context.Context, manifestB64, outputPath, itemID string) error {
	fmt.Println("[Tidal] Parsing manifest...")
	directURL, initURL, mediaURLs, err := parseManifest(manifestB64)
	if err != nil {
		GoLog("[Tidal] Manifest parse error: %v\n", err)
		return fmt.Errorf("failed to parse manifest: %w", err)
	}
	GoLog("[Tidal] Manifest parsed - directURL: %v, initURL: %v, mediaURLs count: %d\n",
		directURL != "", initURL != "", len(mediaURLs))

	client := NewHTTPClientWithTimeout(120 * time.Second)

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

		out, err := os.Create(outputPath)
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
			os.Remove(outputPath)
			if isDownloadCancelled(itemID) {
				return ErrDownloadCancelled
			}
			return fmt.Errorf("download interrupted: %w", err)
		}
		if closeErr != nil {
			os.Remove(outputPath)
			return fmt.Errorf("failed to close file: %w", closeErr)
		}

		if expectedSize > 0 && written != expectedSize {
			os.Remove(outputPath)
			return fmt.Errorf("incomplete download: expected %d bytes, got %d bytes", expectedSize, written)
		}

		return nil
	}

	// For DASH format, determine correct M4A path
	// If outputPath already ends with .m4a, use it directly
	// Otherwise, convert .flac to .m4a
	var m4aPath string
	if strings.HasSuffix(outputPath, ".m4a") {
		m4aPath = outputPath
	} else {
		m4aPath = strings.TrimSuffix(outputPath, ".flac") + ".m4a"
	}
	GoLog("[Tidal] DASH format - downloading %d segments directly to: %s\n", len(mediaURLs), m4aPath)

	out, err := os.Create(m4aPath)
	if err != nil {
		GoLog("[Tidal] Failed to create M4A file: %v\n", err)
		return fmt.Errorf("failed to create M4A file: %w", err)
	}

	GoLog("[Tidal] Downloading init segment...\n")
	if isDownloadCancelled(itemID) {
		out.Close()
		os.Remove(m4aPath)
		return ErrDownloadCancelled
	}
	req, err := http.NewRequestWithContext(ctx, "GET", initURL, nil)
	if err != nil {
		out.Close()
		os.Remove(m4aPath)
		GoLog("[Tidal] Init segment request failed: %v\n", err)
		return fmt.Errorf("failed to create init segment request: %w", err)
	}
	resp, err := client.Do(req)
	if err != nil {
		out.Close()
		os.Remove(m4aPath)
		if isDownloadCancelled(itemID) {
			return ErrDownloadCancelled
		}
		GoLog("[Tidal] Init segment download failed: %v\n", err)
		return fmt.Errorf("failed to download init segment: %w", err)
	}
	if resp.StatusCode != 200 {
		resp.Body.Close()
		out.Close()
		os.Remove(m4aPath)
		GoLog("[Tidal] Init segment HTTP error: %d\n", resp.StatusCode)
		return fmt.Errorf("init segment download failed with status %d", resp.StatusCode)
	}
	_, err = io.Copy(out, resp.Body)
	resp.Body.Close()
	if err != nil {
		out.Close()
		os.Remove(m4aPath)
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
			os.Remove(m4aPath)
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
			os.Remove(m4aPath)
			GoLog("[Tidal] Segment %d request failed: %v\n", i+1, err)
			return fmt.Errorf("failed to create segment %d request: %w", i+1, err)
		}
		resp, err := client.Do(req)
		if err != nil {
			out.Close()
			os.Remove(m4aPath)
			if isDownloadCancelled(itemID) {
				return ErrDownloadCancelled
			}
			GoLog("[Tidal] Segment %d download failed: %v\n", i+1, err)
			return fmt.Errorf("failed to download segment %d: %w", i+1, err)
		}
		if resp.StatusCode != 200 {
			resp.Body.Close()
			out.Close()
			os.Remove(m4aPath)
			GoLog("[Tidal] Segment %d HTTP error: %d\n", i+1, resp.StatusCode)
			return fmt.Errorf("segment %d download failed with status %d", i+1, resp.StatusCode)
		}
		_, err = io.Copy(out, resp.Body)
		resp.Body.Close()
		if err != nil {
			out.Close()
			os.Remove(m4aPath)
			if isDownloadCancelled(itemID) {
				return ErrDownloadCancelled
			}
			GoLog("[Tidal] Segment %d write failed: %v\n", i+1, err)
			return fmt.Errorf("failed to write segment %d: %w", i+1, err)
		}
	}

	if err := out.Close(); err != nil {
		os.Remove(m4aPath)
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
	normSpotify := strings.ToLower(strings.TrimSpace(spotifyArtist))
	normTidal := strings.ToLower(strings.TrimSpace(tidalArtist))

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

func downloadFromTidal(req DownloadRequest) (TidalDownloadResult, error) {
	downloader := NewTidalDownloader()

	if existingFile, exists := checkISRCExistsInternal(req.OutputDir, req.ISRC); exists {
		return TidalDownloadResult{FilePath: "EXISTS:" + existingFile}, nil
	}

	expectedDurationSec := req.DurationMS / 1000

	var track *TidalTrack
	var err error

	if req.TidalID != "" {
		GoLog("[Tidal] Using Tidal ID from Odesli enrichment: %s\n", req.TidalID)
		var trackID int64
		if _, parseErr := fmt.Sscanf(req.TidalID, "%d", &trackID); parseErr == nil && trackID > 0 {
			track, err = downloader.GetTrackInfoByID(trackID)
			if err != nil {
				GoLog("[Tidal] Failed to get track by Odesli ID %d: %v\n", trackID, err)
				track = nil
			} else if track != nil {
				GoLog("[Tidal] Successfully found track via Odesli ID: '%s' by '%s'\n", track.Title, track.Artist.Name)
			}
		}
	}

	if track == nil && req.ISRC != "" {
		if cached := GetTrackIDCache().Get(req.ISRC); cached != nil && cached.TidalTrackID > 0 {
			GoLog("[Tidal] Cache hit! Using cached track ID: %d\n", cached.TidalTrackID)
			track, err = downloader.GetTrackInfoByID(cached.TidalTrackID)
			if err != nil {
				GoLog("[Tidal] Cache hit but failed to get track info: %v\n", err)
				track = nil // Fall through to normal search
			}
		}
	}

	if track == nil && req.ISRC != "" {
		GoLog("[Tidal] Trying ISRC search: %s\n", req.ISRC)
		track, err = downloader.SearchTrackByMetadataWithISRC(req.TrackName, req.ArtistName, req.ISRC, expectedDurationSec)
		if track != nil {
			// Verify artist only (ISRC match is already accurate)
			tidalArtist := track.Artist.Name
			if len(track.Artists) > 0 {
				var artistNames []string
				for _, a := range track.Artists {
					artistNames = append(artistNames, a.Name)
				}
				tidalArtist = strings.Join(artistNames, ", ")
			}
			if !artistsMatch(req.ArtistName, tidalArtist) {
				GoLog("[Tidal] Artist mismatch from ISRC search: expected '%s', got '%s'. Rejecting.\n",
					req.ArtistName, tidalArtist)
				track = nil
			}
		}
	}

	if track == nil && req.SpotifyID != "" {
		GoLog("[Tidal] ISRC search failed, trying SongLink...\n")
		var tidalURL string
		var slErr error

		if strings.HasPrefix(req.SpotifyID, "deezer:") {
			deezerID := strings.TrimPrefix(req.SpotifyID, "deezer:")
			GoLog("[Tidal] Using Deezer ID for SongLink lookup: %s\n", deezerID)
			songlink := NewSongLinkClient()
			tidalURL, slErr = songlink.GetTidalURLFromDeezer(deezerID)
		} else {
			tidalURL, slErr = downloader.GetTidalURLFromSpotify(req.SpotifyID)
		}

		if slErr == nil && tidalURL != "" {
			trackID, idErr := downloader.GetTrackIDFromURL(tidalURL)
			if idErr == nil {
				track, err = downloader.GetTrackInfoByID(trackID)
				if track != nil {
					tidalArtist := track.Artist.Name
					if len(track.Artists) > 0 {
						var artistNames []string
						for _, a := range track.Artists {
							artistNames = append(artistNames, a.Name)
						}
						tidalArtist = strings.Join(artistNames, ", ")
					}

					if !artistsMatch(req.ArtistName, tidalArtist) {
						GoLog("[Tidal] Artist mismatch from SongLink: expected '%s', got '%s'. Rejecting.\n",
							req.ArtistName, tidalArtist)
						track = nil
					}

					if track != nil && expectedDurationSec > 0 {
						durationDiff := track.Duration - expectedDurationSec
						if durationDiff < 0 {
							durationDiff = -durationDiff
						}
						if durationDiff > 3 {
							GoLog("[Tidal] Duration mismatch from SongLink: expected %ds, got %ds. Rejecting.\n",
								expectedDurationSec, track.Duration)
							track = nil // Reject this match
						}
					}
				}
			}
		}
	}

	if track == nil {
		GoLog("[Tidal] Trying metadata search as last resort...\n")
		track, err = downloader.SearchTrackByMetadataWithISRC(req.TrackName, req.ArtistName, "", expectedDurationSec)
		if track != nil {
			tidalArtist := track.Artist.Name
			if len(track.Artists) > 0 {
				var artistNames []string
				for _, a := range track.Artists {
					artistNames = append(artistNames, a.Name)
				}
				tidalArtist = strings.Join(artistNames, ", ")
			}

			if !titlesMatch(req.TrackName, track.Title) {
				GoLog("[Tidal] Title mismatch from metadata search: expected '%s', got '%s'. Rejecting.\n",
					req.TrackName, track.Title)
				track = nil
			} else if !artistsMatch(req.ArtistName, tidalArtist) {
				GoLog("[Tidal] Artist mismatch from metadata search: expected '%s', got '%s'. Rejecting.\n",
					req.ArtistName, tidalArtist)
				track = nil
			}
		}
	}

	if track == nil {
		errMsg := "could not find matching track on Tidal (artist/duration mismatch)"
		if err != nil {
			errMsg = err.Error()
		}
		return TidalDownloadResult{}, fmt.Errorf("tidal search failed: %s", errMsg)
	}

	tidalArtist := track.Artist.Name
	if len(track.Artists) > 0 {
		var artistNames []string
		for _, a := range track.Artists {
			artistNames = append(artistNames, a.Name)
		}
		tidalArtist = strings.Join(artistNames, ", ")
	}
	GoLog("[Tidal] Match found: '%s' by '%s' (duration: %ds)\n", track.Title, tidalArtist, track.Duration)

	if req.ISRC != "" {
		GetTrackIDCache().SetTidal(req.ISRC, track.ID)
	}

	quality := req.Quality
	if quality == "" {
		quality = "LOSSLESS"
	}

	filename := buildFilenameFromTemplate(req.FilenameFormat, map[string]interface{}{
		"title":  req.TrackName,
		"artist": req.ArtistName,
		"album":  req.AlbumName,
		"track":  req.TrackNumber,
		"year":   extractYear(req.ReleaseDate),
		"disc":   req.DiscNumber,
	})

	var outputPath string
	var m4aPath string
	if quality == "HIGH" {
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

	tmpPath := outputPath + ".m4a.tmp"
	if _, err := os.Stat(tmpPath); err == nil {
		GoLog("[Tidal] Cleaning up leftover temp file: %s\n", tmpPath)
		os.Remove(tmpPath)
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
		parallelResult = FetchCoverAndLyricsParallel(
			req.CoverURL,
			req.EmbedMaxQualityCover,
			req.SpotifyID,
			req.TrackName,
			req.ArtistName,
			req.EmbedLyrics,
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

	if err := downloader.DownloadFile(downloadInfo.URL, outputPath, req.ItemID); err != nil {
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
	if _, err := os.Stat(m4aPath); err == nil {
		actualOutputPath = m4aPath
		GoLog("[Tidal] File saved as M4A (DASH stream): %s\n", actualOutputPath)
	} else if _, err := os.Stat(outputPath); err != nil {
		return TidalDownloadResult{}, fmt.Errorf("download completed but file not found at %s or %s", outputPath, m4aPath)
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
		Title:       req.TrackName,
		Artist:      req.ArtistName,
		Album:       req.AlbumName,
		AlbumArtist: req.AlbumArtist,
		Date:        releaseDate,
		TrackNumber: actualTrackNumber,
		TotalTracks: req.TotalTracks,
		DiscNumber:  actualDiscNumber,
		ISRC:        track.ISRC,
		Genre:       req.Genre,
		Label:       req.Label,
		Copyright:   req.Copyright,
	}

	var coverData []byte
	if parallelResult != nil && parallelResult.CoverData != nil {
		coverData = parallelResult.CoverData
		GoLog("[Tidal] Using parallel-fetched cover (%d bytes)\n", len(coverData))
	}

	if strings.HasSuffix(actualOutputPath, ".flac") {
		if err := EmbedMetadataWithCoverData(actualOutputPath, metadata, coverData); err != nil {
			fmt.Printf("Warning: failed to embed metadata: %v\n", err)
		}

		if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
			lyricsMode := req.LyricsMode
			if lyricsMode == "" {
				lyricsMode = "embed"
			}

			if lyricsMode == "external" || lyricsMode == "both" {
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
		} else if req.EmbedLyrics {
			fmt.Println("[Tidal] No lyrics available from parallel fetch")
		}
	} else if strings.HasSuffix(actualOutputPath, ".m4a") {
		if quality == "HIGH" {
			GoLog("[Tidal] HIGH quality M4A - skipping metadata embedding (file from server is already valid)\n")

			if req.EmbedLyrics && parallelResult != nil && parallelResult.LyricsLRC != "" {
				lyricsMode := req.LyricsMode
				if lyricsMode == "" {
					lyricsMode = "embed"
				}

				if lyricsMode == "external" || lyricsMode == "both" {
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

	AddToISRCIndex(req.OutputDir, req.ISRC, actualOutputPath)

	bitDepth := downloadInfo.BitDepth
	sampleRate := downloadInfo.SampleRate
	lyricsLRC := ""
	if quality == "HIGH" {
		bitDepth = 0
		sampleRate = 44100
		if parallelResult != nil && parallelResult.LyricsLRC != "" {
			lyricsMode := req.LyricsMode
			if lyricsMode == "" {
				lyricsMode = "embed"
			}
			if lyricsMode == "embed" || lyricsMode == "both" {
				lyricsLRC = parallelResult.LyricsLRC
			}
		}
	}

	return TidalDownloadResult{
		FilePath:    actualOutputPath,
		BitDepth:    bitDepth,
		SampleRate:  sampleRate,
		Title:       track.Title,
		Artist:      track.Artist.Name,
		Album:       track.Album.Title,
		ReleaseDate: track.Album.ReleaseDate,
		TrackNumber: actualTrackNumber,
		DiscNumber:  actualDiscNumber,
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

	// Handle /browse/track/123 format
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
