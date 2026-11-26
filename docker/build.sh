#!/usr/bin/env bash
# Builds the Omix Docker image from the repo root.
#
# For the full CI emulation (Dockerfile lint check + this build), use
# scripts/docker-ci-check.sh instead.
#
# Usage:
#   docker/build.sh [tag]   # defaults to omix:latest
#
# GH_TOKEN is passed into the build as a BuildKit secret (used by devtools::check()
# for GitHub-hosted remote dependencies). Set it in the environment to use a real
# token; otherwise a placeholder value is used.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

TAG="${1:-omix:latest}"

GH_TOKEN_FILE="$(mktemp)"
trap 'rm -f "${GH_TOKEN_FILE}"' EXIT
printf '%s' "${GH_TOKEN:-dummy}" >"${GH_TOKEN_FILE}"

echo "==> docker buildx build -t ${TAG}"
DOCKER_BUILDKIT=1 docker buildx build \
	-f docker/Dockerfile \
	--secret id=GH_TOKEN,src="${GH_TOKEN_FILE}" \
	-t "${TAG}" \
	--load \
	.

echo "==> build succeeded: image tagged ${TAG}"
