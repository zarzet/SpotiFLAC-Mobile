package gobackend

import (
	"crypto/aes"
	"crypto/cipher"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"strings"

	"github.com/dop251/goja"
	"golang.org/x/crypto/blowfish"
)

type runtimeBlockCipherOptions struct {
	Algorithm      string
	Mode           string
	Key            []byte
	IV             []byte
	InputEncoding  string
	OutputEncoding string
	Padding        string
}

func parseRuntimeOptionsArgument(call goja.FunctionCall, index int) map[string]interface{} {
	if len(call.Arguments) <= index {
		return nil
	}

	value := call.Arguments[index]
	if goja.IsUndefined(value) || goja.IsNull(value) {
		return nil
	}

	exported := value.Export()
	if options, ok := exported.(map[string]interface{}); ok {
		return options
	}
	return nil
}

func runtimeOptionString(options map[string]interface{}, key, defaultValue string) string {
	if options == nil {
		return defaultValue
	}
	raw, ok := options[key]
	if !ok || raw == nil {
		return defaultValue
	}
	switch value := raw.(type) {
	case string:
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			return trimmed
		}
	case []byte:
		if len(value) > 0 {
			return string(value)
		}
	}
	return defaultValue
}

func runtimeOptionBool(options map[string]interface{}, key string, defaultValue bool) bool {
	if options == nil {
		return defaultValue
	}
	raw, ok := options[key]
	if !ok || raw == nil {
		return defaultValue
	}
	switch value := raw.(type) {
	case bool:
		return value
	case int:
		return value != 0
	case int64:
		return value != 0
	case float64:
		return value != 0
	case string:
		switch strings.ToLower(strings.TrimSpace(value)) {
		case "1", "true", "yes", "on":
			return true
		case "0", "false", "no", "off":
			return false
		}
	}
	return defaultValue
}

func runtimeOptionInt64(options map[string]interface{}, key string, defaultValue int64) int64 {
	if options == nil {
		return defaultValue
	}
	raw, ok := options[key]
	if !ok || raw == nil {
		return defaultValue
	}
	switch value := raw.(type) {
	case int:
		return int64(value)
	case int32:
		return int64(value)
	case int64:
		return value
	case float32:
		return int64(value)
	case float64:
		return int64(value)
	case string:
		value = strings.TrimSpace(value)
		if value == "" {
			return defaultValue
		}
		var parsed int64
		if _, err := fmt.Sscanf(value, "%d", &parsed); err == nil {
			return parsed
		}
	}
	return defaultValue
}

func runtimeOptionHasKey(options map[string]interface{}, key string) bool {
	if options == nil {
		return false
	}
	_, exists := options[key]
	return exists
}

func decodeRuntimeBytesString(input, encoding string) ([]byte, error) {
	switch strings.ToLower(strings.TrimSpace(encoding)) {
	case "", "utf8", "utf-8", "text":
		return []byte(input), nil
	case "base64":
		decoded, err := base64.StdEncoding.DecodeString(strings.TrimSpace(input))
		if err != nil {
			return nil, fmt.Errorf("invalid base64 data: %w", err)
		}
		return decoded, nil
	case "hex":
		decoded, err := hex.DecodeString(strings.TrimSpace(input))
		if err != nil {
			return nil, fmt.Errorf("invalid hex data: %w", err)
		}
		return decoded, nil
	default:
		return nil, fmt.Errorf("unsupported byte encoding: %s", encoding)
	}
}

func decodeRuntimeBytesValue(raw interface{}, encoding string) ([]byte, error) {
	switch value := raw.(type) {
	case string:
		return decodeRuntimeBytesString(value, encoding)
	case []byte:
		cloned := make([]byte, len(value))
		copy(cloned, value)
		return cloned, nil
	case []interface{}:
		decoded := make([]byte, len(value))
		for i, item := range value {
			switch num := item.(type) {
			case int:
				decoded[i] = byte(num)
			case int64:
				decoded[i] = byte(num)
			case float64:
				decoded[i] = byte(int(num))
			default:
				return nil, fmt.Errorf("unsupported byte array item at index %d", i)
			}
		}
		return decoded, nil
	default:
		return nil, fmt.Errorf("unsupported byte payload type")
	}
}

func encodeRuntimeBytes(data []byte, encoding string) (string, error) {
	switch strings.ToLower(strings.TrimSpace(encoding)) {
	case "", "base64":
		return base64.StdEncoding.EncodeToString(data), nil
	case "hex":
		return hex.EncodeToString(data), nil
	case "utf8", "utf-8", "text":
		return string(data), nil
	default:
		return "", fmt.Errorf("unsupported byte encoding: %s", encoding)
	}
}

func parseRuntimeBlockCipherOptions(options map[string]interface{}) (*runtimeBlockCipherOptions, error) {
	parsed := &runtimeBlockCipherOptions{
		Algorithm:      strings.ToLower(runtimeOptionString(options, "algorithm", "")),
		Mode:           strings.ToLower(runtimeOptionString(options, "mode", "cbc")),
		InputEncoding:  strings.ToLower(runtimeOptionString(options, "inputEncoding", "base64")),
		OutputEncoding: strings.ToLower(runtimeOptionString(options, "outputEncoding", "base64")),
		Padding:        strings.ToLower(runtimeOptionString(options, "padding", "none")),
	}
	if parsed.Algorithm == "" {
		return nil, fmt.Errorf("algorithm is required")
	}
	if parsed.Mode == "" {
		return nil, fmt.Errorf("mode is required")
	}

	key, err := decodeRuntimeBytesString(runtimeOptionString(options, "key", ""), runtimeOptionString(options, "keyEncoding", "utf8"))
	if err != nil {
		return nil, fmt.Errorf("invalid key: %w", err)
	}
	if len(key) == 0 {
		return nil, fmt.Errorf("key is required")
	}
	parsed.Key = key

	iv, err := decodeRuntimeBytesString(runtimeOptionString(options, "iv", ""), runtimeOptionString(options, "ivEncoding", "utf8"))
	if err != nil {
		return nil, fmt.Errorf("invalid iv: %w", err)
	}
	parsed.IV = iv
	return parsed, nil
}

func newRuntimeBlockCipher(options *runtimeBlockCipherOptions) (cipher.Block, error) {
	switch options.Algorithm {
	case "blowfish":
		return blowfish.NewCipher(options.Key)
	case "aes":
		return aes.NewCipher(options.Key)
	default:
		return nil, fmt.Errorf("unsupported block cipher algorithm: %s", options.Algorithm)
	}
}

func applyPKCS7Padding(data []byte, blockSize int) []byte {
	padding := blockSize - (len(data) % blockSize)
	if padding == 0 {
		padding = blockSize
	}
	out := make([]byte, len(data)+padding)
	copy(out, data)
	for i := len(data); i < len(out); i++ {
		out[i] = byte(padding)
	}
	return out
}

func removePKCS7Padding(data []byte, blockSize int) ([]byte, error) {
	if len(data) == 0 || len(data)%blockSize != 0 {
		return nil, fmt.Errorf("invalid padded payload length")
	}
	padding := int(data[len(data)-1])
	if padding <= 0 || padding > blockSize || padding > len(data) {
		return nil, fmt.Errorf("invalid PKCS7 padding")
	}
	for i := len(data) - padding; i < len(data); i++ {
		if int(data[i]) != padding {
			return nil, fmt.Errorf("invalid PKCS7 padding")
		}
	}
	return data[:len(data)-padding], nil
}

func (r *extensionRuntime) transformBlockCipher(call goja.FunctionCall, decrypt bool) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "data and options are required",
		})
	}

	options := parseRuntimeOptionsArgument(call, 1)
	parsedOptions, err := parseRuntimeBlockCipherOptions(options)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}
	if parsedOptions.Mode != "cbc" {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("unsupported block cipher mode: %s", parsedOptions.Mode),
		})
	}

	inputData, err := decodeRuntimeBytesValue(call.Arguments[0].Export(), parsedOptions.InputEncoding)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	block, err := newRuntimeBlockCipher(parsedOptions)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	if len(parsedOptions.IV) != block.BlockSize() {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("iv must be %d bytes for %s", block.BlockSize(), parsedOptions.Algorithm),
		})
	}

	data := inputData
	if !decrypt && parsedOptions.Padding == "pkcs7" {
		data = applyPKCS7Padding(data, block.BlockSize())
	}
	if len(data)%block.BlockSize() != 0 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   fmt.Sprintf("input length must be a multiple of %d bytes", block.BlockSize()),
		})
	}

	output := make([]byte, len(data))
	if decrypt {
		cipher.NewCBCDecrypter(block, parsedOptions.IV).CryptBlocks(output, data)
		if parsedOptions.Padding == "pkcs7" {
			output, err = removePKCS7Padding(output, block.BlockSize())
			if err != nil {
				return r.vm.ToValue(map[string]interface{}{
					"success": false,
					"error":   err.Error(),
				})
			}
		}
	} else {
		cipher.NewCBCEncrypter(block, parsedOptions.IV).CryptBlocks(output, data)
	}

	encoded, err := encodeRuntimeBytes(output, parsedOptions.OutputEncoding)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success":    true,
		"data":       encoded,
		"block_size": block.BlockSize(),
	})
}

func (r *extensionRuntime) encryptBlockCipher(call goja.FunctionCall) goja.Value {
	return r.transformBlockCipher(call, false)
}

func (r *extensionRuntime) decryptBlockCipher(call goja.FunctionCall) goja.Value {
	return r.transformBlockCipher(call, true)
}
