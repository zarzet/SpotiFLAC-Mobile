package gobackend

import (
	"fmt"
	"os"
	"strings"
)

func isFDOutput(outputFD int) bool {
	return outputFD > 0
}

func openOutputForWrite(outputPath string, outputFD int) (*os.File, error) {
	if isFDOutput(outputFD) {
		return os.NewFile(uintptr(outputFD), fmt.Sprintf("saf_fd_%d", outputFD)), nil
	}
	return os.Create(outputPath)
}

func cleanupOutputOnError(outputPath string, outputFD int) {
	if isFDOutput(outputFD) {
		return
	}

	path := strings.TrimSpace(outputPath)
	if path == "" || strings.HasPrefix(path, "/proc/self/fd/") {
		return
	}

	_ = os.Remove(path)
}
