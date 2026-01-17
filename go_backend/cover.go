package gobackend

import (
	"fmt"
	"io"
	"net/http"
	"strings"
)

// Spotify image size codes (same as PC version)
const (
	spotifySize300 = "ab67616d00001e02" // 300x300 (small)
	spotifySize640 = "ab67616d0000b273" // 640x640 (medium)
	spotifySizeMax = "ab67616d000082c1" // Max resolution (~2000x2000)
)

// convertSmallToMedium upgrades 300x300 cover URL to 640x640
// Same logic as PC version for consistency
func convertSmallToMedium(imageURL string) string {
	if strings.Contains(imageURL, spotifySize300) {
		return strings.Replace(imageURL, spotifySize300, spotifySize640, 1)
	}
	return imageURL
}

// downloadCoverToMemory downloads cover art and returns as bytes (no file creation)
// This avoids file permission issues on Android
func downloadCoverToMemory(coverURL string, maxQuality bool) ([]byte, error) {
	if coverURL == "" {
		return nil, fmt.Errorf("no cover URL provided")
	}

	GoLog("[Cover] Original URL: %s", coverURL)

	downloadURL := convertSmallToMedium(coverURL)
	if downloadURL != coverURL {
		GoLog("[Cover] Upgraded 300x300 → 640x640")
	}

	if maxQuality {
		maxURL := upgradeToMaxQuality(downloadURL)
		if maxURL != downloadURL {
			downloadURL = maxURL
			GoLog("[Cover] Upgraded to max resolution (~2000x2000)")
		} else {
			GoLog("[Cover] Max resolution not available, using 640x640")
		}
	}

	GoLog("[Cover] Final URL: %s", downloadURL)

	client := NewHTTPClientWithTimeout(DefaultTimeout)

	req, err := http.NewRequest("GET", downloadURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := DoRequestWithUserAgent(client, req)
	if err != nil {
		return nil, fmt.Errorf("failed to download cover: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("cover download failed: HTTP %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read cover data: %w", err)
	}

	sizeKB := len(data) / 1024
	var resolution string
	if sizeKB > 200 {
		resolution = "~2000x2000 (hi-res)"
	} else if sizeKB > 50 {
		resolution = "~640x640"
	} else {
		resolution = "~300x300"
	}
	GoLog("[Cover] Downloaded %d KB (%s)", sizeKB, resolution)

	return data, nil
}

// upgradeToMaxQuality upgrades Spotify cover URL to maximum quality
// Same logic as PC version - directly replaces 640x640 size code with max resolution
// No HEAD verification needed - Spotify CDN always serves max resolution if available
func upgradeToMaxQuality(coverURL string) string {

	if strings.Contains(coverURL, spotifySize640) {
		return strings.Replace(coverURL, spotifySize640, spotifySizeMax, 1)
	}

	return coverURL
}

// GetCoverFromSpotify gets cover URL from Spotify metadata
func GetCoverFromSpotify(imageURL string, maxQuality bool) string {
	if imageURL == "" {
		return ""
	}

	// Always upgrade small to medium first
	result := convertSmallToMedium(imageURL)

	if maxQuality {
		result = upgradeToMaxQuality(result)
	}

	return result
}
