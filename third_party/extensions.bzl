# extensions.bzl — Bzlmod module extension for non-BCR C++ dependencies.
#
# A module extension lets a Bazel module fetch repositories that are not
# listed in the Bazel Central Registry.  This extension uses http_archive()
# to download C++ libraries directly from GitHub releases.
#
# To expose a repo defined here, list it in MODULE.bazel:
#   non_registry = use_extension("//third_party:extensions.bzl", "non_registry")
#   use_repo(non_registry, "<name>")
#
# Docs: https://bazel.build/external/extension
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _non_registry_deps_impl(ctx):
    # spdlog: fast C++ logging library, header-only mode.
    # Not in the BCR, so fetched directly from the GitHub release tarball.
    # build_file injects //third_party:spdlog.BUILD so Bazel can compile it.
    # Docs: https://github.com/gabime/spdlog
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
