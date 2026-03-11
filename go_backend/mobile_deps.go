// This file ensures gomobile dependencies are not removed by go mod tidy.
// These packages are required by gomobile bind but not directly imported in code.

package gobackend

import (
	_ "golang.org/x/mobile/bind"
)
