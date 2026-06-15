package greeter_test

import (
	"testing"

	"github.com/mike-boquard/bazel-intro/go/greeter"
)

func TestHello(t *testing.T) {
	cases := []struct {
		input string
		want  string
	}{
		{"World", "Hello, World!"},
		{"", "Hello, !"},
		{"日本語", "Hello, 日本語!"},
	}
	for _, c := range cases {
		got := greeter.Hello(c.input)
		if got != c.want {
			t.Errorf("Hello(%q) = %q, want %q", c.input, got, c.want)
		}
	}
}
