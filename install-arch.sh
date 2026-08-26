#!/usr/bin/env bash
# Installs (or uninstalls) a TuxGuitar "linux-swt" build produced by the
# Dockerfile in this repo, mirroring the layout of the official .deb package
# (see desktop/build-scripts/tuxguitar-linux-swt-deb/pom.xml):
#   /opt/tuxguitar             <- the built app
#   /usr/bin/tuxguitar         -> /opt/tuxguitar/tuxguitar.sh
#   /usr/share/{applications,templates,man/man1,mime/packages,metainfo,pixmaps}
#
# Usage:
#   sudo ./install-arch.sh ./dist/tuxguitar-9.99-SNAPSHOT-linux-swt
#   sudo ./install-arch.sh --uninstall

set -euo pipefail

PREFIX=/opt/tuxguitar

if [ "${1:-}" = "--uninstall" ]; then
    rm -rf "$PREFIX"
    rm -f /usr/bin/tuxguitar \
          /usr/share/applications/TuxGuitar.desktop \
          /usr/share/templates/TuxGuitar.desktop \
          /usr/share/templates/.source/tuxguitar \
          /usr/share/man/man1/tuxguitar.1 \
          /usr/share/mime/packages/tuxguitar.xml \
          /usr/share/metainfo/app.tuxguitar.tuxguitar.metainfo.xml \
          /usr/share/pixmaps/tuxguitar.png
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
    update-mime-database /usr/share/mime >/dev/null 2>&1 || true
    echo "TuxGuitar uninstalled."
    exit 0
fi

SRC="${1:?Usage: $0 <path-to-tuxguitar-*-linux-swt build dir> | --uninstall}"
SRC="$(cd "$SRC" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root (sudo), or use --uninstall the same way." >&2
    exit 1
fi

if ! command -v java >/dev/null 2>&1; then
    echo "Note: no 'java' found on PATH. Install a JRE, e.g.:" >&2
    echo "  pacman -S --needed jre-openjdk" >&2
fi

rm -rf "$PREFIX"
mkdir -p "$PREFIX"
cp -a "$SRC/." "$PREFIX/"
chmod 755 "$PREFIX/tuxguitar.sh"
[ -d "$PREFIX/lv2-client" ] && chmod 755 "$PREFIX"/lv2-client/*.bin 2>/dev/null || true

mkdir -p /usr/bin /usr/share/applications /usr/share/templates/.source \
         /usr/share/man/man1 /usr/share/mime/packages /usr/share/metainfo \
         /usr/share/pixmaps

ln -sf "$PREFIX/tuxguitar.sh" /usr/bin/tuxguitar
ln -sf "$PREFIX/share/applications/TuxGuitar.desktop" /usr/share/applications/TuxGuitar.desktop
ln -sf "$PREFIX/share/templates" /usr/share/templates/.source/tuxguitar
ln -sf ".source/tuxguitar/TuxGuitar.desktop" /usr/share/templates/TuxGuitar.desktop
ln -sf "$PREFIX/share/man/man1/tuxguitar.1" /usr/share/man/man1/tuxguitar.1
ln -sf "$PREFIX/share/mime/packages/tuxguitar.xml" /usr/share/mime/packages/tuxguitar.xml
ln -sf "$PREFIX/share/metainfo/app.tuxguitar.tuxguitar.metainfo.xml" /usr/share/metainfo/app.tuxguitar.tuxguitar.metainfo.xml
ln -sf "$PREFIX/share/pixmaps/tuxguitar.png" /usr/share/pixmaps/tuxguitar.png

update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
update-mime-database /usr/share/mime >/dev/null 2>&1 || true

echo "TuxGuitar installed. Runtime deps, if not already present:"
echo "  pacman -S --needed jre-openjdk alsa-lib fluidsynth jack2 lilv suil webkit2gtk-4.1"
echo "Run it with: tuxguitar"
