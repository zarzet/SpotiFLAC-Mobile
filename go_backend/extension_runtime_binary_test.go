package gobackend

import (
	"encoding/json"
	"testing"

	"github.com/dop251/goja"
)

func newBinaryTestRuntime(t *testing.T, withFilePermission bool) *goja.Runtime {
	t.Helper()

	ext := &loadedExtension{
		ID: "binary-test-ext",
		Manifest: &ExtensionManifest{
			Name: "binary-test-ext",
			Permissions: ExtensionPermissions{
				File: withFilePermission,
			},
		},
		DataDir: t.TempDir(),
	}

	runtime := newExtensionRuntime(ext)
	vm := goja.New()
	runtime.RegisterAPIs(vm)
	return vm
}

func decodeJSONResult[T any](t *testing.T, value goja.Value) T {
	t.Helper()

	var decoded T
	if err := json.Unmarshal([]byte(value.String()), &decoded); err != nil {
		t.Fatalf("failed to decode JSON result: %v", err)
	}
	return decoded
}

func TestExtensionRuntime_FileByteAPIs(t *testing.T) {
	vm := newBinaryTestRuntime(t, true)

	result, err := vm.RunString(`
		(function() {
			var first = file.writeBytes("bytes.bin", "AAEC", {encoding: "base64", truncate: true});
			if (!first.success) throw new Error(first.error);

			var second = file.writeBytes("bytes.bin", "0304ff", {encoding: "hex", append: true});
			if (!second.success) throw new Error(second.error);

			var all = file.readBytes("bytes.bin", {encoding: "hex"});
			if (!all.success) throw new Error(all.error);

			var slice = file.readBytes("bytes.bin", {offset: 2, length: 2, encoding: "hex"});
			if (!slice.success) throw new Error(slice.error);

			var tail = file.readBytes("bytes.bin", {offset: 6, length: 4, encoding: "hex"});
			if (!tail.success) throw new Error(tail.error);

			return JSON.stringify({
				all: all.data,
				slice: slice.data,
				size: all.size,
				sliceBytes: slice.bytes_read,
				sliceEof: slice.eof,
				tailBytes: tail.bytes_read,
				tailEof: tail.eof
			});
		})()
	`)
	if err != nil {
		t.Fatalf("file byte APIs failed: %v", err)
	}

	decoded := decodeJSONResult[struct {
		All        string `json:"all"`
		Slice      string `json:"slice"`
		Size       int64  `json:"size"`
		SliceBytes int    `json:"sliceBytes"`
		SliceEof   bool   `json:"sliceEof"`
		TailBytes  int    `json:"tailBytes"`
		TailEof    bool   `json:"tailEof"`
	}](t, result)

	if decoded.All != "0001020304ff" {
		t.Fatalf("all = %q", decoded.All)
	}
	if decoded.Slice != "0203" {
		t.Fatalf("slice = %q", decoded.Slice)
	}
	if decoded.Size != 6 {
		t.Fatalf("size = %d", decoded.Size)
	}
	if decoded.SliceBytes != 2 {
		t.Fatalf("slice bytes = %d", decoded.SliceBytes)
	}
	if decoded.SliceEof {
		t.Fatal("slice should not be EOF")
	}
	if decoded.TailBytes != 0 || !decoded.TailEof {
		t.Fatalf("tail read mismatch: bytes=%d eof=%v", decoded.TailBytes, decoded.TailEof)
	}
}

func TestExtensionRuntime_BlockCipherCBCSupportsBlowfish(t *testing.T) {
	vm := newBinaryTestRuntime(t, false)

	result, err := vm.RunString(`
		(function() {
			var options = {
				algorithm: "blowfish",
				mode: "cbc",
				key: "0123456789ABCDEFF0E1D2C3B4A59687",
				keyEncoding: "hex",
				iv: "0001020304050607",
				ivEncoding: "hex",
				inputEncoding: "hex",
				outputEncoding: "hex",
				padding: "none"
			};
			var enc = utils.encryptBlockCipher("00112233445566778899aabbccddeeff", options);
			if (!enc.success) throw new Error(enc.error);
			var dec = utils.decryptBlockCipher(enc.data, options);
			if (!dec.success) throw new Error(dec.error);
			return JSON.stringify({enc: enc.data, dec: dec.data});
		})()
	`)
	if err != nil {
		t.Fatalf("blowfish block cipher failed: %v", err)
	}

	decoded := decodeJSONResult[struct {
		Enc string `json:"enc"`
		Dec string `json:"dec"`
	}](t, result)

	if decoded.Dec != "00112233445566778899aabbccddeeff" {
		t.Fatalf("dec = %q", decoded.Dec)
	}
	if decoded.Enc == decoded.Dec {
		t.Fatal("expected ciphertext to differ from plaintext")
	}
}

func TestExtensionRuntime_BlockCipherCBCSupportsAES(t *testing.T) {
	vm := newBinaryTestRuntime(t, false)

	result, err := vm.RunString(`
		(function() {
			var options = {
				algorithm: "aes",
				mode: "cbc",
				key: "000102030405060708090a0b0c0d0e0f",
				keyEncoding: "hex",
				iv: "0f0e0d0c0b0a09080706050403020100",
				ivEncoding: "hex",
				inputEncoding: "utf8",
				outputEncoding: "base64",
				padding: "pkcs7"
			};
			var enc = utils.encryptBlockCipher("hello generic cbc", options);
			if (!enc.success) throw new Error(enc.error);
			var dec = utils.decryptBlockCipher(enc.data, {
				algorithm: "aes",
				mode: "cbc",
				key: options.key,
				keyEncoding: options.keyEncoding,
				iv: options.iv,
				ivEncoding: options.ivEncoding,
				inputEncoding: "base64",
				outputEncoding: "utf8",
				padding: "pkcs7"
			});
			if (!dec.success) throw new Error(dec.error);
			return dec.data;
		})()
	`)
	if err != nil {
		t.Fatalf("aes block cipher failed: %v", err)
	}

	if result.String() != "hello generic cbc" {
		t.Fatalf("unexpected decrypted value: %q", result.String())
	}
}
