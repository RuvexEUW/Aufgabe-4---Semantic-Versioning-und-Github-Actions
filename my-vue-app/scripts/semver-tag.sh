#!/usr/bin/env bash
set -euo pipefail
MSG="${1:-$(git log -1 --pretty=%B)}"
LATEST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")"
LATEST_TAG="${LATEST_TAG#v}"
IFS='.' read -r MAJOR MINOR PATCH <<<"$LATEST_TAG"

is_breaking() {
  [[ "$MSG" =~ BREAKING[[:space:]]CHANGE ]] || [[ "$MSG" =~ ^[a-zA-Z]+(\([^)]+\))?!: ]]
}

if is_breaking; then
  ((MAJOR++)); MINOR=0; PATCH=0
elif [[ "$MSG" =~ ^feat(\([^)]+\))?: ]]; then
  ((MINOR++)); PATCH=0
else
  ((PATCH++))
fi

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
NEW_TAG="v${NEW_VERSION}"

if git rev-parse "${NEW_TAG}" >/dev/null 2>&1; then
  echo "Tag ${NEW_TAG} existiert bereits."
  exit 0
fi

git tag -a "${NEW_TAG}" -m "${NEW_TAG}: ${MSG}"
echo "Lokaler Tag ${NEW_TAG} erstellt."
