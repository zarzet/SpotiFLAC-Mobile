//go:build ios

package gobackend

import (
	"net/http"
)

func GetCloudflareBypassClient() *http.Client {
	return sharedClient
}

func DoRequestWithCloudflareBypass(req *http.Request) (*http.Response, error) {
	req.Header.Set("User-Agent", userAgentForURL(req.URL))
	resp, err := sharedClient.Do(req)
	if err != nil {
		CheckAndLogISPBlocking(err, req.URL.String(), "HTTP")
	}
	return resp, err
}
