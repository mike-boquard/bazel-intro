#include "cpp/greeter/greeter.h"
#include "absl/strings/str_cat.h"

namespace greeter {
std::string Hello(const std::string &name) { return absl::StrCat("Hello, ", name, "!"); }
} // namespace greeter
