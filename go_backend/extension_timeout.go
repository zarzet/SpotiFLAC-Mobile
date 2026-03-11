package gobackend

import (
	"context"
	"fmt"
	"runtime/debug"
	"sync"
	"time"

	"github.com/dop251/goja"
)

type JSExecutionError struct {
	Message   string
	IsTimeout bool
}

func (e *JSExecutionError) Error() string {
	return e.Message
}

func RunWithTimeout(vm *goja.Runtime, script string, timeout time.Duration) (goja.Value, error) {
	if timeout <= 0 {
		timeout = DefaultJSTimeout
	}

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	type result struct {
		value goja.Value
		err   error
	}
	resultCh := make(chan result, 1)

	var interrupted bool
	var interruptMu sync.Mutex

	go func() {
		defer func() {
			if r := recover(); r != nil {
				interruptMu.Lock()
				wasInterrupted := interrupted
				interruptMu.Unlock()

				if wasInterrupted {
					resultCh <- result{nil, &JSExecutionError{
						Message:   "execution timeout exceeded",
						IsTimeout: true,
					}}
				} else {
					GoLog("[ExtensionRuntime] panic during JS execution: %v\n%s\n", r, string(debug.Stack()))
					resultCh <- result{nil, fmt.Errorf("panic during execution: %v", r)}
				}
			}
		}()

		val, err := vm.RunString(script)
		resultCh <- result{val, err}
	}()

	select {
	case res := <-resultCh:
		return res.value, res.err
	case <-ctx.Done():
		interruptMu.Lock()
		interrupted = true
		interruptMu.Unlock()

		vm.Interrupt("execution timeout")

		select {
		case res := <-resultCh:
			if res.err != nil {
				return nil, res.err
			}
			return nil, &JSExecutionError{
				Message:   "execution timeout exceeded",
				IsTimeout: true,
			}
		case <-time.After(1 * time.Second):
			return nil, &JSExecutionError{
				Message:   "execution timeout exceeded (force)",
				IsTimeout: true,
			}
		}
	}
}

// RunWithTimeoutAndRecover runs JS with timeout and clears interrupt state after
// This should be used when you want to continue using the VM after a timeout
func RunWithTimeoutAndRecover(vm *goja.Runtime, script string, timeout time.Duration) (goja.Value, error) {
	result, err := RunWithTimeout(vm, script, timeout)

	// Clear any interrupt state so VM can be reused
	vm.ClearInterrupt()

	return result, err
}

func IsTimeoutError(err error) bool {
	if jsErr, ok := err.(*JSExecutionError); ok {
		return jsErr.IsTimeout
	}
	return false
}
