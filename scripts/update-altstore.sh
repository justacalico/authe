#!/usr/bin/env bash
set -euo pipefail

# Regenerate the AltStore source (altstore/apps.json) from the release that
# github-release-sync just created, then commit it back to main with ci.skip
# so the source always points at the newest GitLab release package links.
# Skips the rolling nightly release; only v* tags produce entries.

RELEASE_TAG="${RELEASE_TAG:-}"
PROJECT_DIR="${CI_PROJECT_DIR:-$PWD}"
cd "$PROJECT_DIR"

if [ -z "$RELEASE_TAG" ] || ! echo "$RELEASE_TAG" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+'; then
  echo "Skipping AltStore update for tag '${RELEASE_TAG:-unset}'"
  exit 0
fi

VERSION="${RELEASE_TAG#v}"
IPA_NAME="authe-ios-arm64-unsigned.ipa"
BASE_URL="https://gitlab.com/${CI_PROJECT_PATH}"
IPA_URL="${BASE_URL}/-/releases/${RELEASE_TAG}/downloads/${IPA_NAME}"
ICON_URL="${BASE_URL}/-/raw/main/assets/icon.png"

# Find the ipa size from the generic package registry listing.
SIZE=$(glab api "projects/${CI_PROJECT_ID}/packages?package_name=release-assets&package_version=${RELEASE_TAG}&package_type=generic" 2>/dev/null \
  | jq -r --arg name "$IPA_NAME" '.[0].package_files[]? | select(.file_name == $name) | .size' | head -n1)
SIZE="${SIZE:-0}"

mkdir -p altstore
TODAY=$(date -u +%Y-%m-%d)
jq -n \
  --arg version "$VERSION" \
  --arg today "$TODAY" \
  --arg ipa "$IPA_URL" \
  --arg icon "$ICON_URL" \
  --argjson size "$SIZE" '
{
  name: "Authe",
  identifier: "com.httpanimations.authe.source",
  sourceURL: "https://httpanimations.gitlab.io/authe/altstore/apps.json",
  apps: [
    {
      name: "Authe",
      bundleIdentifier: "com.httpanimations.authe",
      developerName: "HttpAnimations",
      subtitle: "Two-factor authenticator",
      localizedDescription: "Open two-factor authentication for every screen you own.",
      iconURL: $icon,
      tintedIconURL: $icon,
      versions: [
        {
          version: $version,
          date: $today,
          downloadURL: $ipa,
          size: $size,
          minOSVersion: "13.0"
        }
      ],
      versionDate: $today,
      appPermissions: {
        entitlements: [],
        privacy: [
          {
            name: "NSCameraUsageDescription",
            usageDescription: "Authe uses the camera to scan two-factor QR codes."
          }
        ]
      },
      screenshots: []
    }
  ],
  news: [
    {
      identifier: ("release-" + $version),
      title: ("Authe " + $version),
      caption: ("Release " + $version + " is now available."),
      date: $today,
      appID: "com.httpanimations.authe",
      notify: false
    }
  ]
}' > altstore/apps.json

git config user.name "GitLab CI"
git config user.email "ci@gitlab.com"
git remote add gitlab-ssh "git@gitlab.com:${CI_PROJECT_PATH}.git" 2>/dev/null || true

git add altstore/apps.json
if git diff --cached --quiet; then
  echo "AltStore source already up to date"
  exit 0
fi
git commit -m "chore: 更新 AltStore 源"
if ! git push -o ci.skip gitlab-ssh HEAD:main; then
  git fetch gitlab-ssh main
  git rebase gitlab-ssh/main
  git push -o ci.skip gitlab-ssh HEAD:main
fi
echo "AltStore source updated for $RELEASE_TAG"
