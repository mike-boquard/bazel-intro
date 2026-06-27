# spdlog.BUILD — build rules for the spdlog C++ logging library (non-BCR dep).
#
# This file is injected into the spdlog external repository by extensions.bzl
# via build_file = Label("//third_party:spdlog.BUILD").  Bazel uses it in
# place of any BUILD file that might exist inside the spdlog source tree.
#
# spdlog is header-only by default: when SPDLOG_COMPILED_LIB is not defined,
# spdlog/common.h defines SPDLOG_HEADER_ONLY itself.  We therefore do NOT pass
# -DSPDLOG_HEADER_ONLY — doing so collides with spdlog's own #define (empty vs
# 1) and trips -Wmacro-redefined on newer Clang.  No srcs, just hdrs.
#
# Docs: https://bazel.build/reference/be/c-cpp#cc_library
#       https://github.com/gabime/spdlog/wiki/0.-FAQ
load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "spdlog",
    # Glob all headers from spdlog's include directory.
    hdrs = glob(["include/**/*.h"]),
    # Make #include "spdlog/spdlog.h" resolvable without a path prefix.
    includes = ["include"],
    visibility = ["//visibility:public"],
)
