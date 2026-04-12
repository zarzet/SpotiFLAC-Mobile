//go:build !ios

package gobackend

import (
	"context"
	"crypto/tls"
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
	"sync"

	utls "github.com/refraction-networking/utls"
	"golang.org/x/net/http2"
)

type utlsTransport struct {
	dialer       *net.Dialer
	mu           sync.Mutex
	h2Transports map[string]*http2.Transport
}

func newUTLSTransport() *utlsTransport {
	return &utlsTransport{
		dialer: &net.Dialer{
			Timeout:   30 * Second,
			KeepAlive: 30 * Second,
		},
		h2Transports: make(map[string]*http2.Transport),
	}
}

func (t *utlsTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	if req.URL.Scheme != "https" {
		return sharedTransport.RoundTrip(req)
	}

	host := req.URL.Hostname()
	port := t.getPort(req.URL)
	addr := net.JoinHostPort(host, port)

	conn, err := t.dialer.DialContext(req.Context(), "tcp", addr)
	if err != nil {
		return nil, err
	}

	tlsConn := utls.UClient(conn, &utls.Config{
		ServerName: host,
		NextProtos: []string{"h2", "http/1.1"},
	}, utls.HelloChrome_Auto)

	if err := tlsConn.Handshake(); err != nil {
		conn.Close()
		return nil, err
	}

	negotiatedProto := tlsConn.ConnectionState().NegotiatedProtocol

	if negotiatedProto == "h2" {
		h2Transport := &http2.Transport{
			DialTLSContext: func(ctx context.Context, network, addr string, cfg *tls.Config) (net.Conn, error) {
				return tlsConn, nil
			},
			AllowHTTP:          false,
			DisableCompression: false,
		}
		return h2Transport.RoundTrip(req)
	}

	transport := &http.Transport{
		DialTLSContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			return tlsConn, nil
		},
		DisableKeepAlives: true,
	}

	return transport.RoundTrip(req)
}

func (t *utlsTransport) getPort(u *url.URL) string {
	if u.Port() != "" {
		return u.Port()
	}
	if u.Scheme == "https" {
		return "443"
	}
	return "80"
}

var cloudflareBypassTransport = newUTLSTransport()

var cloudflareBypassClient = &http.Client{
	Transport: cloudflareBypassTransport,
	Timeout:   DefaultTimeout,
}

func GetCloudflareBypassClient() *http.Client {
	return cloudflareBypassClient
}

func DoRequestWithCloudflareBypass(req *http.Request) (*http.Response, error) {
	req.Header.Set("User-Agent", userAgentForURL(req.URL))

	resp, err := sharedClient.Do(req)
	if err == nil {
		if resp.StatusCode == 403 || resp.StatusCode == 503 {
			body, readErr := io.ReadAll(resp.Body)
			resp.Body.Close()

			if readErr == nil {
				bodyStr := strings.ToLower(string(body))
				cloudflareMarkers := []string{
					"cloudflare", "cf-ray", "checking your browser",
					"please wait", "ddos protection", "ray id",
					"enable javascript", "challenge-platform",
				}

				isCloudflare := false
				for _, marker := range cloudflareMarkers {
					if strings.Contains(bodyStr, marker) {
						isCloudflare = true
						break
					}
				}

				if isCloudflare {
					LogDebug("HTTP", "Cloudflare detected, retrying with Chrome TLS fingerprint...")

					reqCopy := req.Clone(req.Context())
					reqCopy.Header.Set("User-Agent", userAgentForURL(reqCopy.URL))

					return cloudflareBypassClient.Do(reqCopy)
				}
			}

			return &http.Response{
				Status:     resp.Status,
				StatusCode: resp.StatusCode,
				Header:     resp.Header,
				Body:       io.NopCloser(strings.NewReader(string(body))),
			}, nil
		}
		return resp, nil
	}

	errStr := strings.ToLower(err.Error())
	tlsRelated := strings.Contains(errStr, "tls") ||
		strings.Contains(errStr, "handshake") ||
		strings.Contains(errStr, "certificate") ||
		strings.Contains(errStr, "connection reset")

	if tlsRelated {
		LogDebug("HTTP", "TLS error detected, retrying with Chrome TLS fingerprint: %v", err)

		reqCopy := req.Clone(req.Context())
		reqCopy.Header.Set("User-Agent", userAgentForURL(reqCopy.URL))

		return cloudflareBypassClient.Do(reqCopy)
	}

	CheckAndLogISPBlocking(err, req.URL.String(), "HTTP")
	return nil, err
}
