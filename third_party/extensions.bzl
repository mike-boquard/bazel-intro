load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _non_registry_deps_impl(ctx):
    http_archive(
        name = "spdlog",
        url = "https://github.com/gabime/spdlog/archive/refs/tags/v1.14.1.tar.gz",
        sha256 = "1586508029a7d0670dfcb2d97575dcdc242d3868a259742b69f100801ab4e16b",
        strip_prefix = "spdlog-1.14.1",
        build_file = Label("//third_party:spdlog.BUILD"),
    )

non_registry = module_extension(
    implementation = _non_registry_deps_impl,
)
