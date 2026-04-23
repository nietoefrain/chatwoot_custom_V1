#!/usr/bin/env sh

set -eu

REF="${1:-HEAD}"
IMAGE_TAG="${2:-}"
PLATFORM="${PLATFORM:-linux/amd64}"

if [ -z "$IMAGE_TAG" ]; then
  echo "Usage: docker/build-from-git.sh [git-ref] <image-tag>" >&2
  exit 1
fi

ROOT_DIR="$(git rev-parse --show-toplevel)"
COMMIT_SHA="$(git -C "$ROOT_DIR" rev-parse "$REF")"
SHORT_SHA="$(git -C "$ROOT_DIR" rev-parse --short "$REF")"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT INT TERM

echo "Exporting $REF ($COMMIT_SHA) to temporary build context..."
git -C "$ROOT_DIR" archive "$COMMIT_SHA" | tar -x -C "$TMP_DIR"

echo "Building $IMAGE_TAG for $PLATFORM from clean git snapshot..."
docker build \
  --platform "$PLATFORM" \
  --build-arg SOURCE_COMMIT="$COMMIT_SHA" \
  --label org.opencontainers.image.revision="$COMMIT_SHA" \
  --label org.opencontainers.image.version="$SHORT_SHA" \
  -t "$IMAGE_TAG" \
  -f "$TMP_DIR/docker/Dockerfile" \
  "$TMP_DIR"

echo "Built $IMAGE_TAG from $COMMIT_SHA"
