package gobackend

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/dop251/goja"
)

var (
	allowedDownloadDirs   []string
	allowedDownloadDirsMu sync.RWMutex
)

func SetAllowedDownloadDirs(dirs []string) {
	allowedDownloadDirsMu.Lock()
	defer allowedDownloadDirsMu.Unlock()
	allowedDownloadDirs = dirs
	GoLog("[Extension] Allowed download directories set: %v\n", dirs)
}

func AddAllowedDownloadDir(dir string) {
	allowedDownloadDirsMu.Lock()
	defer allowedDownloadDirsMu.Unlock()
	absDir, err := filepath.Abs(dir)
	if err == nil {
		allowedDownloadDirs = append(allowedDownloadDirs, absDir)
	}
}

func isPathInAllowedDirs(absPath string) bool {
	allowedDownloadDirsMu.RLock()
	defer allowedDownloadDirsMu.RUnlock()

	for _, allowedDir := range allowedDownloadDirs {
		if isPathWithinBase(allowedDir, absPath) {
			return true
		}
	}
	return false
}

func isPathWithinBase(baseDir, targetPath string) bool {
	baseAbs, err := filepath.Abs(baseDir)
	if err != nil {
		return false
	}
	targetAbs, err := filepath.Abs(targetPath)
	if err != nil {
		return false
	}

	rel, err := filepath.Rel(baseAbs, targetAbs)
	if err != nil {
		return false
	}
	rel = filepath.Clean(rel)
	if rel == "." {
		return true
	}

	prefix := ".." + string(filepath.Separator)
	if rel == ".." || strings.HasPrefix(rel, prefix) {
		return false
	}
	return true
}

func (r *extensionRuntime) validatePath(path string) (string, error) {
	if !r.manifest.Permissions.File {
		return "", fmt.Errorf("file access denied: extension does not have 'file' permission")
	}

	cleanPath := filepath.Clean(path)

	if filepath.IsAbs(cleanPath) {
		absPath, err := filepath.Abs(cleanPath)
		if err != nil {
			return "", fmt.Errorf("invalid path: %w", err)
		}

		if isPathInAllowedDirs(absPath) {
			return absPath, nil
		}

		return "", fmt.Errorf("file access denied: absolute paths are not allowed. Use relative paths within extension sandbox")
	}

	fullPath := filepath.Join(r.dataDir, cleanPath)

	absPath, err := filepath.Abs(fullPath)
	if err != nil {
		return "", fmt.Errorf("invalid path: %w", err)
	}

	absDataDir, _ := filepath.Abs(r.dataDir)
	if !isPathWithinBase(absDataDir, absPath) {
		return "", fmt.Errorf("file access denied: path '%s' is outside sandbox", path)
	}

	return absPath, nil
}

func (r *extensionRuntime) fileDownload(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "URL and output path are required",
		})
	}

	urlStr := call.Arguments[0].String()
	outputPath := call.Arguments[1].String()

	if err := r.validateDomain(urlStr); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	fullPath, err := r.validatePath(outputPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	var onProgress goja.Callable
	var headers map[string]string
	if len(call.Arguments) > 2 && !goja.IsUndefined(call.Arguments[2]) && !goja.IsNull(call.Arguments[2]) {
		optionsObj := call.Arguments[2].Export()
		if opts, ok := optionsObj.(map[string]interface{}); ok {
			if h, ok := opts["headers"].(map[string]interface{}); ok {
				headers = make(map[string]string)
				for k, v := range h {
					headers[k] = fmt.Sprintf("%v", v)
				}
			}
			if progressVal, ok := opts["onProgress"]; ok {
				if callable, ok := goja.AssertFunction(r.vm.ToValue(progressVal)); ok {
					onProgress = callable
				}
			}
		}
	}

	dir := filepath.Dir(fullPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create directory: %v", err),
		})
	}

	req, err := http.NewRequest("GET", urlStr, nil)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}
	req = r.bindDownloadCancelContext(req)

	for k, v := range headers {
		req.Header.Set(k, v)
	}
	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", "SpotiFLAC-Extension/1.0")
	}

	client := r.downloadClient
	if client == nil {
		client = r.httpClient
	}

	resp, err := client.Do(req)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("HTTP error: %d", resp.StatusCode),
		})
	}

	out, err := os.Create(fullPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create file: %v", err),
		})
	}
	defer out.Close()

	contentLength := resp.ContentLength
	activeItemID := r.getActiveDownloadItemID()
	if activeItemID != "" && contentLength > 0 {
		SetItemBytesTotal(activeItemID, contentLength)
	}

	var progressWriter interface{ Write([]byte) (int, error) } = out
	if activeItemID != "" {
		progressWriter = NewItemProgressWriter(out, activeItemID)
	}

	var written int64
	buf := make([]byte, 32*1024)
	for {
		nr, er := resp.Body.Read(buf)
		if nr > 0 {
			nw, ew := progressWriter.Write(buf[0:nr])
			if nw < 0 || nr < nw {
				nw = 0
				if ew == nil {
					ew = fmt.Errorf("invalid write result")
				}
			}
			written += int64(nw)
			if ew != nil {
				if ew == ErrDownloadCancelled {
					return r.vm.ToValue(map[string]interface{}{
						"success": false,
						"error":   "download cancelled",
					})
				}
				return r.vm.ToValue(map[string]interface{}{
					"success": false,
					"error":   fmt.Sprintf("failed to write file: %v", ew),
				})
			}
			if nr != nw {
				return r.vm.ToValue(map[string]interface{}{
					"success": false,
					"error":   "short write",
				})
			}

			if onProgress != nil && contentLength > 0 {
				_, _ = onProgress(goja.Undefined(), r.vm.ToValue(written), r.vm.ToValue(contentLength))
			}
		}
		if er != nil {
			if er != io.EOF {
				return r.vm.ToValue(map[string]interface{}{
					"success": false,
					"error":   fmt.Sprintf("failed to read response: %v", er),
				})
			}
			break
		}
	}

	GoLog("[Extension:%s] Downloaded %d bytes to %s\n", r.extensionID, written, fullPath)

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"path":    fullPath,
		"size":    written,
	})
}

func (r *extensionRuntime) fileExists(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(false)
	}

	path := call.Arguments[0].String()
	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(false)
	}

	_, err = os.Stat(fullPath)
	return r.vm.ToValue(err == nil)
}

func (r *extensionRuntime) fileDelete(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "path is required",
		})
	}

	path := call.Arguments[0].String()
	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	if err := os.Remove(fullPath); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
	})
}

func (r *extensionRuntime) fileRead(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "path is required",
		})
	}

	path := call.Arguments[0].String()
	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	data, err := os.ReadFile(fullPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"data":    string(data),
	})
}

func (r *extensionRuntime) fileReadBytes(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "path is required",
		})
	}

	path := call.Arguments[0].String()
	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	options := parseRuntimeOptionsArgument(call, 1)
	offset := runtimeOptionInt64(options, "offset", 0)
	length := runtimeOptionInt64(options, "length", -1)
	encoding := runtimeOptionString(options, "encoding", "base64")
	if offset < 0 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "offset must be >= 0",
		})
	}

	file, err := os.Open(fullPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}
	defer file.Close()

	info, err := file.Stat()
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	size := info.Size()
	if offset > size {
		offset = size
	}
	if _, err := file.Seek(offset, io.SeekStart); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to seek file: %v", err),
		})
	}

	var data []byte
	switch {
	case length == 0:
		data = []byte{}
	case length > 0:
		buf := make([]byte, int(length))
		n, readErr := file.Read(buf)
		if readErr != nil && readErr != io.EOF {
			return r.vm.ToValue(map[string]interface{}{
				"success": false,
				"error":   fmt.Sprintf("failed to read file: %v", readErr),
			})
		}
		data = buf[:n]
	default:
		data, err = io.ReadAll(file)
		if err != nil {
			return r.vm.ToValue(map[string]interface{}{
				"success": false,
				"error":   fmt.Sprintf("failed to read file: %v", err),
			})
		}
	}

	encoded, err := encodeRuntimeBytes(data, encoding)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success":    true,
		"data":       encoded,
		"bytes_read": len(data),
		"offset":     offset,
		"size":       size,
		"eof":        offset+int64(len(data)) >= size,
	})
}

func (r *extensionRuntime) fileWrite(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "path and data are required",
		})
	}

	path := call.Arguments[0].String()
	data := call.Arguments[1].String()

	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	dir := filepath.Dir(fullPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create directory: %v", err),
		})
	}

	if err := os.WriteFile(fullPath, []byte(data), 0644); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"path":    fullPath,
	})
}

func (r *extensionRuntime) fileWriteBytes(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "path and data are required",
		})
	}

	path := call.Arguments[0].String()
	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	options := parseRuntimeOptionsArgument(call, 2)
	appendMode := runtimeOptionBool(options, "append", false)
	truncate := runtimeOptionBool(options, "truncate", false)
	hasOffset := runtimeOptionHasKey(options, "offset")
	offset := runtimeOptionInt64(options, "offset", 0)
	encoding := runtimeOptionString(options, "encoding", "base64")

	if appendMode && hasOffset {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "append and offset cannot be used together",
		})
	}
	if offset < 0 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "offset must be >= 0",
		})
	}

	data, err := decodeRuntimeBytesValue(call.Arguments[1].Export(), encoding)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	dir := filepath.Dir(fullPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create directory: %v", err),
		})
	}

	flags := os.O_CREATE | os.O_WRONLY
	if appendMode {
		flags |= os.O_APPEND
	}
	if truncate {
		flags |= os.O_TRUNC
	}

	file, err := os.OpenFile(fullPath, flags, 0644)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}
	defer file.Close()

	if hasOffset && !appendMode {
		if _, err := file.Seek(offset, io.SeekStart); err != nil {
			return r.vm.ToValue(map[string]interface{}{
				"success": false,
				"error":   fmt.Sprintf("failed to seek file: %v", err),
			})
		}
	}

	written, err := file.Write(data)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	info, statErr := file.Stat()
	size := int64(0)
	if statErr == nil {
		size = info.Size()
	}

	return r.vm.ToValue(map[string]interface{}{
		"success":       true,
		"path":          fullPath,
		"bytes_written": written,
		"size":          size,
	})
}

func (r *extensionRuntime) fileCopy(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "source and destination paths are required",
		})
	}

	srcPath := call.Arguments[0].String()
	dstPath := call.Arguments[1].String()

	fullSrc, err := r.validatePath(srcPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	fullDst, err := r.validatePath(dstPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	srcFile, err := os.Open(fullSrc)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to read source: %v", err),
		})
	}
	defer srcFile.Close()

	dir := filepath.Dir(fullDst)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create directory: %v", err),
		})
	}

	dstFile, err := os.OpenFile(fullDst, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to open destination: %v", err),
		})
	}

	if _, err := io.Copy(dstFile, srcFile); err != nil {
		_ = dstFile.Close()
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to copy file: %v", err),
		})
	}

	if err := dstFile.Close(); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to finalize destination: %v", err),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"path":    fullDst,
	})
}

func (r *extensionRuntime) fileMove(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "source and destination paths are required",
		})
	}

	srcPath := call.Arguments[0].String()
	dstPath := call.Arguments[1].String()

	fullSrc, err := r.validatePath(srcPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	fullDst, err := r.validatePath(dstPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	dir := filepath.Dir(fullDst)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to create directory: %v", err),
		})
	}

	if err := os.Rename(fullSrc, fullDst); err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("failed to move file: %v", err),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"path":    fullDst,
	})
}

func (r *extensionRuntime) fileGetSize(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "path is required",
		})
	}

	path := call.Arguments[0].String()
	fullPath, err := r.validatePath(path)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	info, err := os.Stat(fullPath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success": true,
		"size":    info.Size(),
	})
}
