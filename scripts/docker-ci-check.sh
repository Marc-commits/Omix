#!/usr/bin/env bash
# Emulates the GitHub Actions CI for this repo locally.
#
# All of check-standard.yaml / r_package_dev*.yaml do is build ./Dockerfile;
# the final layer of that Dockerfile runs `devtools::check(error_on = 'error')`,
# so the Docker build *is* the CI. This script reproduces it:
#   1. `docker build --check`  -- fast Dockerfile lint/best-practice check
#   2. a full `docker buildx build` -- runs the actual R CMD check inside the image
#
# Usage:
#   scripts/docker-ci-check.sh              # lint check + full build
#   scripts/docker-ci-check.sh --check-only  # lint check only, skip the full build
#
# GH_TOKEN is passed into the build as a BuildKit secret (used by devtools::check()
# for GitHub-hosted remote dependencies). Set it in the environment to use a real
# token; otherwise a placeholder value is used.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

CHECK_ONLY=false
if [[ "${1:-}" == "--check-only" ]]; then
	CHECK_ONLY=true
fi

echo "==> docker build --check (Dockerfile lint)"
DOCKER_BUILDKIT=1 docker build --check -f Dockerfile .

if ${CHECK_ONLY}; then
	echo "==> --check-only requested, skipping full build"
	exit 0
fi

GH_TOKEN_FILE="$(mktemp)"
trap 'rm -f "${GH_TOKEN_FILE}"' EXIT
printf '%s' "${GH_TOKEN:-dummy}" >"${GH_TOKEN_FILE}"

echo "==> docker buildx build (full build, runs devtools::check() inside the image)"
DOCKER_BUILDKIT=1 docker buildx build \
	-f Dockerfile \
	--secret id=GH_TOKEN,src="${GH_TOKEN_FILE}" \
	-t omix-ci-local:latest \
	--load \
	.

echo "==> build succeeded: image tagged omix-ci-local:latest"
