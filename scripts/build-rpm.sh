#!/usr/bin/env bash
set -euo pipefail

# Build an .rpm package from a flutter linux bundle.
# Usage: build-rpm.sh <bundle-dir> <version> <rpm-arch> <output.rpm> [release]

BUNDLE="${1:?bundle dir required}"
VERSION="${2:?version required}"
ARCH="${3:?rpm arch required}"
OUT="${4:?output path required}"
RELEASE="${5:-1}"

TOP=$(mktemp -d)
trap 'rm -rf "$TOP"' EXIT

mkdir -p "$TOP/SPECS" "$TOP/SOURCES" "$TOP/RPMS" "$TOP/BUILD" "$TOP/BUILDROOT"
cp -r "$BUNDLE" "$TOP/SOURCES/authe"
cp packaging/linux/authe.desktop packaging/linux/authe.png "$TOP/SOURCES/"

cat > "$TOP/SPECS/authe.spec" <<SPEC
Name: authe
Version: $VERSION
Release: $RELEASE%{?dist}
Summary: Authe two-factor authenticator
License: AGPL-3.0-only

%description
Open two-factor authentication codes for every screen.

%install
mkdir -p %{buildroot}/opt/authe %{buildroot}/usr/bin \
  %{buildroot}/usr/share/applications \
  %{buildroot}/usr/share/icons/hicolor/512x512/apps
cp -r %{_sourcedir}/authe/. %{buildroot}/opt/authe/
ln -sf /opt/authe/authe %{buildroot}/usr/bin/authe
install -m644 %{_sourcedir}/authe.desktop %{buildroot}/usr/share/applications/authe.desktop
install -m644 %{_sourcedir}/authe.png %{buildroot}/usr/share/icons/hicolor/512x512/apps/authe.png

%files
/opt/authe
/usr/bin/authe
/usr/share/applications/authe.desktop
/usr/share/icons/hicolor/512x512/apps/authe.png
SPEC

rpmbuild --define "_topdir $TOP" --define "_rpmdir $TOP/RPMS" \
  --target "$ARCH" -bb "$TOP/SPECS/authe.spec"
find "$TOP/RPMS" -name '*.rpm' -exec cp {} "$OUT" \;
