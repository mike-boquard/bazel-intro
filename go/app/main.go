package main

import (
	"fmt"
	"os"

	"github.com/mike-boquard/bazel-intro/go/greeter"
)

func main() {
	name := "World"
	if len(os.Args) > 1 {
		name = os.Args[1]
	}
	fmt.Println(greeter.Hello(name))
}
