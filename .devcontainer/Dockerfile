# syntax=docker/dockerfile:1
#
# Dev container image for building and testing bazel-intro on Linux.
#
# Based on the most recent Ubuntu LTS.  Bazel itself (9.1.1, pinned by
# .bazelversion) plus the Go, Rust, Python, and LLVM toolchains are all
# downloaded hermetically by Bazel, so this image only needs bazelisk, a host
# C/C++ compiler, and the handful of utilities the build and tests shell out to.
ARG UBUNTU_VERSION=26.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

# build-essential — host C/C++ compiler (Bazel's default Linux C++ toolchain).
# git             — scripts call `git rev-parse --show-toplevel`.
# curl, ca-certs  — fetch bazelisk; let Bazel download deps over TLS.
# netcat-openbsd  — the integration test polls the server with `nc -z`.
# unzip, zip      — used by Bazel while extracting some archives.
# sudo            — convenience for the non-root dev user.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        netcat-openbsd \
        sudo \
        unzip \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Install bazelisk as `bazel`.  It reads .bazelversion and fetches the matching
# Bazel release (9.1.1) on first invocation.  Pinned to match the version used
# in .github/workflows/ci.yml.
ARG BAZELISK_VERSION=v1.29.0
RUN arch="$(dpkg --print-architecture)" \
    && curl -fsSL -o /usr/local/bin/bazel \
        "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-${arch}" \
    && chmod 0755 /usr/local/bin/bazel

# Non-root dev user.  Ubuntu 24.04+ images ship a default UID 1000 user named
# "ubuntu"; remove it so we can use the conventional "vscode" user at UID 1000.
# VS Code re-maps this UID to the host user automatically (updateRemoteUserUID).
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
