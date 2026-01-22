/*usr/bin/env go run "$0" "$@"; exit; */

package main

import (
	"encoding/json"
	"os"
	"strings"
)

func main() {
	envMap := make(map[string]string)
	for _, env := range os.Environ() {
		k, v, _ := strings.Cut(env, "=")
		envMap[k] = v
	}
	json.NewEncoder(os.Stdout).Encode(envMap)
}

