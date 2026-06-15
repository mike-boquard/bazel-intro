load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "spdlog",
    hdrs = glob(["include/**/*.h"]),
    includes = ["include"],
    defines = ["SPDLOG_HEADER_ONLY"],
    visibility = ["//visibility:public"],
)
