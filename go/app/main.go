package main

import (
	"os"

	"github.com/fatih/color"
	"github.com/mike-boquard/bazel-intro/go/greeter"
)

func main() {
	name := "World"
	if len(os.Args) > 1 {
		name = os.Args[1]
	}
	color.Green(greeter.Hello(name))
}
