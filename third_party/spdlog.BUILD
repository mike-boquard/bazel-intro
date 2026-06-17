# spdlog.BUILD — build rules for the spdlog C++ logging library (non-BCR dep).
#
# This file is injected into the spdlog external repository by extensions.bzl
# via build_file = Label("//third_party:spdlog.BUILD").  Bazel uses it in
# place of any BUILD file that might exist inside the spdlog source tree.
#
# spdlog supports a header-only mode (SPDLOG_HEADER_ONLY) that avoids a
# separate compilation step.  All implementation is included at usage sites,
# which keeps this BUILD file simple: no srcs, just hdrs and a define.
#
# Docs: https://bazel.build/reference/be/c-cpp#cc_library
#       https://github.com/gabime/spdlog/wiki/0.-FAQ
load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "spdlog",
    # Glob all headers from spdlog's include directory.
    hdrs = glob(["include/**/*.h"]),
    # Activate header-only mode — disables the precompiled spdlog.cpp.
    defines = ["SPDLOG_HEADER_ONLY"],
    # Make #include "spdlog/spdlog.h" resolvable without a path prefix.
    includes = ["include"],
    visibility = ["//visibility:public"],
)
