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

"""Bzlmod module extension for non-BCR C++ dependencies."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _non_registry_deps_impl(_ctx):
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

    # hedron_compile_commands: generates compile_commands.json for clangd.
    # Not in the BCR, so fetched from GitHub.  The repo ships its own BUILD
    # file so no build_file injection is needed.
    # Docs: https://github.com/hedronvision/bazel-compile-commands-extractor
    http_archive(
        name = "hedron_compile_commands",
        url = "https://github.com/hedronvision/bazel-compile-commands-extractor/archive/abb61a688167623088f8768cc9264798df6a9d10.tar.gz",
        sha256 = "1b08abffbfbe89f6dbee6a5b33753792e8004f6a36f37c0f72115bec86e68724",
        strip_prefix = "bazel-compile-commands-extractor-abb61a688167623088f8768cc9264798df6a9d10",
    )

non_registry = module_extension(
    implementation = _non_registry_deps_impl,
)
