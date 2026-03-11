package gobackend

import (
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/dop251/goja"
)

// FFmpegCommand holds a pending FFmpeg command for Flutter to execute.
type FFmpegCommand struct {
	ExtensionID string
	Command     string
	InputPath   string
	OutputPath  string
	Completed   bool
	Success     bool
	Error       string
	Output      string
}

var (
	ffmpegCommands   = make(map[string]*FFmpegCommand)
	ffmpegCommandsMu sync.RWMutex
	ffmpegCommandID  int64
)

func GetPendingFFmpegCommand(commandID string) *FFmpegCommand {
	ffmpegCommandsMu.RLock()
	defer ffmpegCommandsMu.RUnlock()
	return ffmpegCommands[commandID]
}

func SetFFmpegCommandResult(commandID string, success bool, output, errorMsg string) {
	ffmpegCommandsMu.Lock()
	defer ffmpegCommandsMu.Unlock()
	if cmd, exists := ffmpegCommands[commandID]; exists {
		cmd.Completed = true
		cmd.Success = success
		cmd.Output = output
		cmd.Error = errorMsg
	}
}

func ClearFFmpegCommand(commandID string) {
	ffmpegCommandsMu.Lock()
	defer ffmpegCommandsMu.Unlock()
	delete(ffmpegCommands, commandID)
}

func (r *ExtensionRuntime) ffmpegExecute(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "command is required",
		})
	}

	command := call.Arguments[0].String()

	ffmpegCommandsMu.Lock()
	ffmpegCommandID++
	cmdID := fmt.Sprintf("%s_%d", r.extensionID, ffmpegCommandID)
	ffmpegCommands[cmdID] = &FFmpegCommand{
		ExtensionID: r.extensionID,
		Command:     command,
		Completed:   false,
	}
	ffmpegCommandsMu.Unlock()

	GoLog("[Extension:%s] FFmpeg command queued: %s\n", r.extensionID, cmdID)

	timeout := 5 * time.Minute
	start := time.Now()
	for {
		ffmpegCommandsMu.RLock()
		cmd := ffmpegCommands[cmdID]
		completed := cmd != nil && cmd.Completed
		ffmpegCommandsMu.RUnlock()

		if completed {
			ffmpegCommandsMu.RLock()
			result := map[string]interface{}{
				"success": cmd.Success,
				"output":  cmd.Output,
			}
			if cmd.Error != "" {
				result["error"] = cmd.Error
			}
			ffmpegCommandsMu.RUnlock()

			ClearFFmpegCommand(cmdID)
			return r.vm.ToValue(result)
		}

		if time.Since(start) > timeout {
			ClearFFmpegCommand(cmdID)
			return r.vm.ToValue(map[string]interface{}{
				"success": false,
				"error":   "FFmpeg command timed out",
			})
		}

		time.Sleep(100 * time.Millisecond)
	}
}

func (r *ExtensionRuntime) ffmpegGetInfo(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 1 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "file path is required",
		})
	}

	filePath := call.Arguments[0].String()

	quality, err := GetAudioQuality(filePath)
	if err != nil {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   err.Error(),
		})
	}

	return r.vm.ToValue(map[string]interface{}{
		"success":       true,
		"bit_depth":     quality.BitDepth,
		"sample_rate":   quality.SampleRate,
		"total_samples": quality.TotalSamples,
		"duration":      float64(quality.TotalSamples) / float64(quality.SampleRate),
	})
}

func (r *ExtensionRuntime) ffmpegConvert(call goja.FunctionCall) goja.Value {
	if len(call.Arguments) < 2 {
		return r.vm.ToValue(map[string]interface{}{
			"success": false,
			"error":   "input and output paths are required",
		})
	}

	inputPath := call.Arguments[0].String()
	outputPath := call.Arguments[1].String()

	options := map[string]interface{}{}
	if len(call.Arguments) > 2 && !goja.IsUndefined(call.Arguments[2]) && !goja.IsNull(call.Arguments[2]) {
		if opts, ok := call.Arguments[2].Export().(map[string]interface{}); ok {
			options = opts
		}
	}

	var cmdParts []string
	cmdParts = append(cmdParts, "-i", fmt.Sprintf("%q", inputPath))

	if codec, ok := options["codec"].(string); ok {
		cmdParts = append(cmdParts, "-c:a", codec)
	}

	if bitrate, ok := options["bitrate"].(string); ok {
		cmdParts = append(cmdParts, "-b:a", bitrate)
	}

	if sampleRate, ok := options["sample_rate"].(float64); ok {
		cmdParts = append(cmdParts, "-ar", fmt.Sprintf("%d", int(sampleRate)))
	}

	if channels, ok := options["channels"].(float64); ok {
		cmdParts = append(cmdParts, "-ac", fmt.Sprintf("%d", int(channels)))
	}

	cmdParts = append(cmdParts, "-y", fmt.Sprintf("%q", outputPath))

	command := strings.Join(cmdParts, " ")

	execCall := goja.FunctionCall{
		Arguments: []goja.Value{r.vm.ToValue(command)},
	}
	return r.ffmpegExecute(execCall)
}
