#!/usr/bin/env bash
# install.sh - one-line installer for a clinic Mac:
#   curl -fsSL https://updates.<your-domain>/install.sh | bash
#JJQR - AI (Nov 22, 2026) - owner: free installer, no Apple subscription. Files downloaded by curl are NOT quarantined, so macOS opens the app without the "unidentified developer" block.
# Downloads the latest build named in latest.json, checks its SHA-256, installs to ~/Applications (no admin password needed) and opens it.
set -euo pipefail
BASE="${CLINIC_NODE_UPDATES:-https://raw.githubusercontent.com/jessiejek/Project02-releases/main}"
CH="${CLINIC_NODE_CHANNEL:-stable}"
ARCH="$(uname -m)"; case "$ARCH" in arm64) KEY=mac_arm64;; x86_64) KEY=mac_x64;; *) echo "Unsupported Mac: $ARCH"; exit 1;; esac
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
echo "==> Looking for the latest Clinic Node ($CH)..."
curl -fsSL "$BASE/latest.json" -o "$TMP/latest.json"
curl -fsSL "$BASE/latest.json.sig" -o "$TMP/latest.json.sig"
# the feed must be signed by the owner's key (public half embedded here); a tampered or fake feed is refused
PUBKEY_B64="MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEQaz1jcISQrz+RPpqWkeE/uVVe+EISQ7Rq3/0PZMhVvHsJSROqleum2pfEIgUOPQqSDR+n3h48bgIKqb/OHtFLA=="
printf '%s' "$PUBKEY_B64" | base64 -d > "$TMP/pub.der"
openssl ec -pubin -inform DER -in "$TMP/pub.der" -out "$TMP/pub.pem" 2>/dev/null
base64 -d < "$TMP/latest.json.sig" > "$TMP/sig.bin"
openssl dgst -sha256 -verify "$TMP/pub.pem" -signature "$TMP/sig.bin" "$TMP/latest.json" >/dev/null 2>&1 || { echo "The update information is not signed correctly. Nothing was installed."; exit 1; }
URL="$(/usr/bin/python3 -c "import json,sys;print(json.load(open('$TMP/latest.json'))['$KEY']['url'])")"
SHA="$(/usr/bin/python3 -c "import json,sys;print(json.load(open('$TMP/latest.json'))['$KEY']['sha256'])")"
VER="$(/usr/bin/python3 -c "import json,sys;print(json.load(open('$TMP/latest.json'))['version'])")"
echo "==> Downloading version $VER..."
curl -fL --progress-bar "$URL" -o "$TMP/app.zip"
echo "$SHA  $TMP/app.zip" | shasum -a 256 -c - >/dev/null || { echo "The download is damaged or not genuine. Nothing was installed."; exit 1; }
mkdir -p "$HOME/Applications"
pkill -f "Clinic Node.app/Contents/MacOS" 2>/dev/null || true
rm -rf "$HOME/Applications/Clinic Node.app"
ditto -x -k "$TMP/app.zip" "$HOME/Applications"
open "$HOME/Applications/Clinic Node.app"
echo "==> Clinic Node $VER is installed in ~/Applications and starting."
#JJQR - END
