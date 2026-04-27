#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
SUBMODULE_PATH="vendor/hermes-agent"
SUBMODULE_DIR="$ROOT/$SUBMODULE_PATH"

cd "$ROOT"
git submodule update --init --recursive "$SUBMODULE_PATH"

git -C "$SUBMODULE_DIR" fetch --tags --all >/dev/null

current_sha="$(git -C "$SUBMODULE_DIR" rev-parse --short HEAD)"
current_desc="$(git -C "$SUBMODULE_DIR" describe --tags --always --dirty 2>/dev/null || git -C "$SUBMODULE_DIR" rev-parse --short HEAD)"
latest_tag="$(git -C "$SUBMODULE_DIR" tag --sort=-version:refname | head -n1)"

if [[ $# -eq 0 ]]; then
  cat <<EOF
Current Hermes upstream pin: $current_desc ($current_sha)
Latest upstream tag: ${latest_tag:-<none>}

Usage:
  scripts/update-hermes-upstream.sh --latest-tag
  scripts/update-hermes-upstream.sh --main
  scripts/update-hermes-upstream.sh <git-ref>

After changing the pin:
  git add $SUBMODULE_PATH
  python3 -m unittest -v
  docker build -t hermes-agent .
EOF
  exit 0
fi

target="$1"
case "$target" in
  --latest-tag)
    if [[ -z "$latest_tag" ]]; then
      echo "No tags found in upstream hermes-agent repo." >&2
      exit 1
    fi
    target="$latest_tag"
    ;;
  --main)
    target="origin/main"
    ;;
esac

git -C "$SUBMODULE_DIR" checkout "$target"

new_sha="$(git -C "$SUBMODULE_DIR" rev-parse --short HEAD)"
new_desc="$(git -C "$SUBMODULE_DIR" describe --tags --always --dirty 2>/dev/null || git -C "$SUBMODULE_DIR" rev-parse --short HEAD)"

cat <<EOF
Pinned $SUBMODULE_PATH to $new_desc ($new_sha)

Next steps:
  git add $SUBMODULE_PATH
  python3 -m unittest -v
  docker build -t hermes-agent .
EOF
